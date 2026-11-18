extends Node
## Autoload `CommandBus` (rank 2). Routes typed `GameCommand` objects to
## exactly one registered handler `Callable(command: GameCommand) -> bool`,
## and executes the Khaganate's **Toy & Meat Distribution Siyaseti**
## (`DistributeToyLootCommand`), tracking regional Bey satisfaction and
## converting dissatisfied Beys into independent rogue warbands
## (`Yersiz Yurtsuz Çeriler`).

const TOY_RULES_PATH: String = "res://data/governance/toy_distribution_rules.tres"

signal command_dispatched(command: GameCommand)
signal command_rejected(command: GameCommand, reason: String)

var _handlers: Dictionary[StringName, Callable] = {}
var _toy_rules: ToyDistributionRules = null
var _bey_satisfaction: Dictionary[StringName, float] = {}
var _rogue_warbands: Dictionary[StringName, String] = {}


func _ready() -> void:
	_toy_rules = ResourceLoader.load(TOY_RULES_PATH) as ToyDistributionRules
	if _toy_rules == null:
		push_error("CommandBus: failed to load ToyDistributionRules at %s." % TOY_RULES_PATH)
	else:
		for error: String in _toy_rules.get_validation_errors():
			push_error("CommandBus: %s" % error)
	register_handler(DistributeToyLootCommand.ID, _handle_distribute_toy_loot)


func _exit_tree() -> void:
	unregister_handler(DistributeToyLootCommand.ID, _handle_distribute_toy_loot)


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


func _fail(command: GameCommand, reason: String) -> bool:
	if command.rejection_reason.is_empty():
		command.rejection_reason = reason
	command_rejected.emit(command, reason)
	return false
