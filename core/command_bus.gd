extends Node
## Autoload `CommandBus` (rank 2). Routes typed `GameCommand` objects to
## exactly one registered handler `Callable(command: GameCommand) -> bool`,
## executes **Toy & Meat Distribution Siyaseti** (`DistributeToyLootCommand`),
## and handles **Supply Convoy Interdiction** (`InterdictSupplyLineCommand`)
## by enemy formations or rogue `Yersiz Yurtsuz Çeriler` warbands.

const TOY_RULES_PATH: String = "res://data/governance/toy_distribution_rules.tres"
const DEFAULT_CONVOY_PATH: String = "res://data/units/default_supply_convoy.tres"

signal command_dispatched(command: GameCommand)
signal command_rejected(command: GameCommand, reason: String)

var _handlers: Dictionary[StringName, Callable] = {}
var _toy_rules: ToyDistributionRules = null
var _default_convoy: SupplyConvoyData = null
var _bey_satisfaction: Dictionary[StringName, float] = {}
var _rogue_warbands: Dictionary[StringName, String] = {}
var _isolated_armies: Dictionary[int, bool] = {}
var _raider_seized_loot: Dictionary[StringName, float] = {}


func _ready() -> void:
	_toy_rules = ResourceLoader.load(TOY_RULES_PATH) as ToyDistributionRules
	if _toy_rules == null:
		push_error("CommandBus: failed to load ToyDistributionRules at %s." % TOY_RULES_PATH)
	else:
		for error: String in _toy_rules.get_validation_errors():
			push_error("CommandBus: %s" % error)
	_default_convoy = ResourceLoader.load(DEFAULT_CONVOY_PATH) as SupplyConvoyData
	register_handler(DistributeToyLootCommand.ID, _handle_distribute_toy_loot)
	register_handler(InterdictSupplyLineCommand.ID, _handle_interdict_supply_line)


func _exit_tree() -> void:
	unregister_handler(DistributeToyLootCommand.ID, _handle_distribute_toy_loot)
	unregister_handler(InterdictSupplyLineCommand.ID, _handle_interdict_supply_line)


## Registers `handler` as the single owner of `command_id`.
## Returns false (and logs) when the id is empty, taken, or the handler invalid.
func register_handler(command_id: StringName, handler: Callable) -> bool:
	if command_id == &"":
		push_error("CommandBus: cannot register an empty command id.")
		return false
	if not handler.is_valid():
		push_error("CommandBus: invalid handler for '%s'." % command_id)
		return false
	if _handlers.has(command_id) and _handlers[command_id].is_valid():
		push_error("CommandBus: '%s' already has a handler." % command_id)
		return false
	_handlers[command_id] = handler
	return true


## Removes the handler for `command_id` if it is `handler`.
func unregister_handler(command_id: StringName, handler: Callable) -> void:
	if _handlers.has(command_id) and _handlers[command_id] == handler:
		_handlers.erase(command_id)


## True when a valid handler exists for `command_id`.
func has_handler(command_id: StringName) -> bool:
	return _handlers.has(command_id) and _handlers[command_id].is_valid()


## Executes `command` synchronously. Returns true on success.
func dispatch(command: GameCommand) -> bool:
	if command == null:
		push_error("CommandBus: dispatch called with null command.")
		return false
	var command_id: StringName = command.get_command_id()
	if not has_handler(command_id):
		_handlers.erase(command_id)
		return _fail(command, "No handler registered for '%s'." % command_id)
	var handler: Callable = _handlers[command_id]
	var outcome: Variant = handler.call(command)
	if typeof(outcome) != TYPE_BOOL:
		return _fail(command, "Handler for '%s' did not return bool." % command_id)
	var succeeded: bool = outcome
	if not succeeded:
		var reason: String = command.rejection_reason
		if reason.is_empty():
			reason = "Rejected by handler."
		return _fail(command, reason)
	command_dispatched.emit(command)
	return true


## Current satisfaction of `bey_id` on the 0-100 scale.
func get_bey_satisfaction(bey_id: StringName) -> float:
	if _bey_satisfaction.has(bey_id):
		return _bey_satisfaction[bey_id]
	var initial: float = _toy_rules.initial_bey_satisfaction if _toy_rules != null else 65.0
	_bey_satisfaction[bey_id] = initial
	return initial


## True when `bey_id` has rebelled into an independent `Yersiz Yurtsuz Çeriler` warband.
func is_bey_rogue_warband(bey_id: StringName) -> bool:
	return _rogue_warbands.has(bey_id)


## All Bey ids that have converted into independent rogue warbands.
func get_rogue_warband_beys() -> PackedStringArray:
	var list: PackedStringArray = PackedStringArray()
	for bey_id: StringName in _rogue_warbands:
		list.append(String(bey_id))
	return list


## Reintegrates an independent rogue warband (`Yersiz Yurtsuz Çeriler`) directly
## into the Khagan's army without hostages when recruited via high Khagan Glory.
func reintegrate_rogue_warband(bey_id: StringName) -> bool:
	if not _rogue_warbands.has(bey_id):
		return false
	_rogue_warbands.erase(bey_id)
	var restored_sat: float = _toy_rules.initial_bey_satisfaction if _toy_rules != null else 65.0
	_bey_satisfaction[bey_id] = restored_sat
	return true



## True when `army_id`'s supply corridor has been severed (`ISOLATED`).
func is_army_supply_isolated(army_id: int) -> bool:
	return _isolated_armies.get(army_id, false)


## Total convoy loot value seized by `raider_id`.
func get_raider_seized_loot(raider_id: StringName) -> float:
	return _raider_seized_loot.get(raider_id, 0.0)


func _handle_distribute_toy_loot(command: GameCommand) -> bool:
	var dist: DistributeToyLootCommand = command as DistributeToyLootCommand
	if dist == null:
		return command.reject("Expected DistributeToyLootCommand.")
	if _toy_rules == null:
		return command.reject("ToyDistributionRules not loaded.")
	if dist.bey_id == &"":
		return command.reject("DistributeToyLootCommand requires a non-empty bey_id.")
	if dist.total_loot_value < 0.0 or dist.allocated_bey_value < 0.0:
		return command.reject("Loot values cannot be negative.")
	if dist.allocated_bey_value > dist.total_loot_value:
		return command.reject("allocated_bey_value cannot exceed total_loot_value.")

	var current_sat: float = get_bey_satisfaction(dist.bey_id)
	var delta: float = _toy_rules.compute_satisfaction_delta(
		dist.total_loot_value, dist.allocated_bey_value, dist.sogus_meat_fair)
	var next_sat: float = clampf(current_sat + delta, 0.0, _toy_rules.max_bey_satisfaction)
	_bey_satisfaction[dist.bey_id] = next_sat
	dist.resulting_satisfaction = next_sat

	EventBus.toy_loot_distributed.emit(dist.bey_id, dist.total_loot_value, dist.allocated_bey_value, delta)

	if next_sat < _toy_rules.rebellion_satisfaction_threshold:
		_rogue_warbands[dist.bey_id] = _toy_rules.rogue_warband_title
		dist.turned_rogue_warband = true
		dist.spawned_warband_title = _toy_rules.rogue_warband_title
		EventBus.bey_rebelled_as_rogue_warband.emit(dist.bey_id, _toy_rules.rogue_warband_title, next_sat)
	return true


func _handle_interdict_supply_line(command: GameCommand) -> bool:
	var interdict: InterdictSupplyLineCommand = command as InterdictSupplyLineCommand
	if interdict == null:
		return command.reject("Expected InterdictSupplyLineCommand.")
	if interdict.target_army_id <= 0:
		return command.reject("InterdictSupplyLineCommand requires target_army_id > 0.")
	if interdict.raider_id == &"":
		return command.reject("InterdictSupplyLineCommand requires a non-empty raider_id.")
	var convoy: SupplyConvoyData = interdict.convoy_data if interdict.convoy_data != null else _default_convoy
	if convoy == null:
		return command.reject("No SupplyConvoyData available for interdiction.")

	_isolated_armies[interdict.target_army_id] = true
	interdict.target_isolated = true
	interdict.captured_loot_value = convoy.captured_loot_value
	interdict.captured_food_ration = convoy.carried_food_ration
	interdict.captured_remount_ratio = convoy.carried_remount_ratio
	_raider_seized_loot[interdict.raider_id] = _raider_seized_loot.get(interdict.raider_id, 0.0) + convoy.captured_loot_value

	EventBus.supply_line_severed.emit(
		interdict.target_army_id, interdict.depot_id, interdict.raider_id, convoy.captured_loot_value)
	return true


func _fail(command: GameCommand, reason: String) -> bool:
	if command.rejection_reason.is_empty():
		command.rejection_reason = reason
	command_rejected.emit(command, reason)
	return false
