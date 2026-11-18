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
var _army_riders: Dictionary[int, int] = {}
var _army_quiver_ammo: Dictionary[int, float] = {}
var _army_roles: Dictionary[int, GameEnums.DetachmentRole] = {}
var _nomadic_outposts: Dictionary[StringName, Vector2i] = {}


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
	register_handler(RestoreSupplyLineCommand.ID, _handle_restore_supply_line)
	register_handler(SplitDetachForceCommand.ID, _handle_split_detach_force)
	register_handler(MergeForcesCommand.ID, _handle_merge_forces)
	register_handler(RelocateNomadicOutpostCommand.ID, _handle_relocate_nomadic_outpost)


func _exit_tree() -> void:
	unregister_handler(DistributeToyLootCommand.ID, _handle_distribute_toy_loot)
	unregister_handler(InterdictSupplyLineCommand.ID, _handle_interdict_supply_line)
	unregister_handler(RestoreSupplyLineCommand.ID, _handle_restore_supply_line)
	unregister_handler(SplitDetachForceCommand.ID, _handle_split_detach_force)
	unregister_handler(MergeForcesCommand.ID, _handle_merge_forces)
	unregister_handler(RelocateNomadicOutpostCommand.ID, _handle_relocate_nomadic_outpost)


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
	if bey_id == &"" or not _rogue_warbands.has(bey_id):
		return false
	_rogue_warbands.erase(bey_id)
	var restored_sat: float = _toy_rules.initial_bey_satisfaction if _toy_rules != null else 65.0
	_bey_satisfaction[bey_id] = restored_sat
	return true


## True when `army_id`'s supply corridor has been severed (`ISOLATED`).
func is_army_supply_isolated(army_id: int) -> bool:
	if _isolated_armies.has(army_id):
		return _isolated_armies[army_id]
	return false


## Total convoy loot value seized by `raider_id`.
func get_raider_seized_loot(raider_id: StringName) -> float:
	if _raider_seized_loot.has(raider_id):
		return _raider_seized_loot[raider_id]
	return 0.0


## Returns the active rider count of `army_id` (or `0` if merged/unregistered).
func get_army_rider_count(army_id: int) -> int:
	if _army_riders.has(army_id):
		return _army_riders[army_id]
	return 0


## Returns the active macro coordinate of `outpost_id`.
func get_nomadic_outpost_coord(outpost_id: StringName) -> Vector2i:
	if _nomadic_outposts.has(outpost_id):
		return _nomadic_outposts[outpost_id]
	return Vector2i.ZERO


## Total number of nomadic outposts / camps deployed across the macro map.
func get_nomadic_outpost_count() -> int:
	return _nomadic_outposts.size()


func _handle_distribute_toy_loot(command: GameCommand) -> bool:
	var dist: DistributeToyLootCommand = command as DistributeToyLootCommand
	if dist == null:
		return command.reject("Expected DistributeToyLootCommand.")
	if _toy_rules == null:
		return command.reject("ToyDistributionRules not loaded.")
	if dist.bey_id == &"":
		return command.reject("DistributeToyLootCommand requires a non-empty bey_id.")
	if is_nan(dist.total_loot_value) or is_inf(dist.total_loot_value) \
			or is_nan(dist.allocated_bey_value) or is_inf(dist.allocated_bey_value):
		return command.reject("Loot values must be finite.")
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

	if next_sat < _toy_rules.rebellion_satisfaction_threshold and not _rogue_warbands.has(dist.bey_id):
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

	var was_isolated: bool = is_army_supply_isolated(interdict.target_army_id)
	_isolated_armies[interdict.target_army_id] = true
	interdict.target_isolated = true
	if not was_isolated:
		interdict.captured_loot_value = convoy.captured_loot_value
		interdict.captured_food_ration = convoy.carried_food_ration
		interdict.captured_remount_ratio = convoy.carried_remount_ratio
		_raider_seized_loot[interdict.raider_id] = get_raider_seized_loot(interdict.raider_id) + convoy.captured_loot_value
	else:
		interdict.captured_loot_value = 0.0
		interdict.captured_food_ration = 0
		interdict.captured_remount_ratio = 0.0

	EventBus.supply_line_severed.emit(
		interdict.target_army_id, interdict.depot_id, interdict.raider_id, interdict.captured_loot_value)
	return true


func _handle_restore_supply_line(command: GameCommand) -> bool:
	var restore: RestoreSupplyLineCommand = command as RestoreSupplyLineCommand
	if restore == null:
		return command.reject("Expected RestoreSupplyLineCommand.")
	if restore.army_id <= 0 or restore.depot_id <= 0:
		return command.reject("RestoreSupplyLineCommand requires positive army_id and depot_id.")
	restore.was_isolated = is_army_supply_isolated(restore.army_id)
	_isolated_armies[restore.army_id] = false
	restore.restored = true
	EventBus.supply_line_restored.emit(restore.army_id, restore.depot_id)
	return true


func _handle_split_detach_force(command: GameCommand) -> bool:
	var split_cmd: SplitDetachForceCommand = command as SplitDetachForceCommand
	if split_cmd == null:
		return command.reject("Expected SplitDetachForceCommand.")
	if split_cmd.parent_army_id <= 0 or split_cmd.detachment_army_id <= 0 or split_cmd.parent_army_id == split_cmd.detachment_army_id:
		return command.reject("SplitDetachForceCommand requires distinct positive parent and detachment army IDs.")
	if not _army_riders.has(split_cmd.parent_army_id):
		var raw_quiver: float = split_cmd.initial_parent_quiver_if_unregistered
		var safe_init_quiver: float = 0.0 if (is_nan(raw_quiver) or is_inf(raw_quiver)) else maxf(raw_quiver, 0.0)
		_army_riders[split_cmd.parent_army_id] = maxi(split_cmd.initial_parent_riders_if_unregistered, 1)
		_army_quiver_ammo[split_cmd.parent_army_id] = safe_init_quiver
		_army_roles[split_cmd.parent_army_id] = GameEnums.DetachmentRole.VANGUARD_MAIN

	var parent_riders: int = _army_riders[split_cmd.parent_army_id]
	if split_cmd.detached_riders <= 0 or split_cmd.detached_riders >= parent_riders:
		return command.reject("Detached riders (%d) must be > 0 and < parent riders (%d)." % [split_cmd.detached_riders, parent_riders])

	var parent_quiver: float = _army_quiver_ammo[split_cmd.parent_army_id]
	var split_ratio: float = float(split_cmd.detached_riders) / float(parent_riders)
	var det_quiver: float = parent_quiver * split_ratio
	var rem_riders: int = parent_riders - split_cmd.detached_riders
	var rem_quiver: float = maxf(parent_quiver - det_quiver, 0.0)

	_army_riders[split_cmd.parent_army_id] = rem_riders
	_army_quiver_ammo[split_cmd.parent_army_id] = rem_quiver
	_army_riders[split_cmd.detachment_army_id] = split_cmd.detached_riders
	_army_quiver_ammo[split_cmd.detachment_army_id] = det_quiver
	_army_roles[split_cmd.detachment_army_id] = split_cmd.role

	var speed_mult: float = 1.0
	if split_cmd.role == GameEnums.DetachmentRole.FAST_CAVALRY_RECON_RAIDER:
		speed_mult = 1.35
	elif split_cmd.role == GameEnums.DetachmentRole.SUPPLY_ESCORT_GUARD:
		speed_mult = 1.10

	split_cmd.remaining_parent_riders = rem_riders
	split_cmd.remaining_parent_quiver = rem_quiver
	split_cmd.detached_quiver_ammo = det_quiver
	split_cmd.speed_bonus_multiplier = speed_mult

	EventBus.force_detached_from_army.emit(
		split_cmd.parent_army_id, split_cmd.detachment_army_id, split_cmd.role, split_cmd.detached_riders, speed_mult)
	return true


func _handle_merge_forces(command: GameCommand) -> bool:
	var merge_cmd: MergeForcesCommand = command as MergeForcesCommand
	if merge_cmd == null:
		return command.reject("Expected MergeForcesCommand.")
	if not _army_riders.has(merge_cmd.target_army_id) or not _army_riders.has(merge_cmd.detachment_army_id):
		return command.reject("MergeForcesCommand requires both target and detachment armies to exist.")
	if merge_cmd.target_army_id == merge_cmd.detachment_army_id:
		return command.reject("Cannot merge an army into itself.")

	var total_riders: int = _army_riders[merge_cmd.target_army_id] + _army_riders[merge_cmd.detachment_army_id]
	var total_quiver: float = _army_quiver_ammo[merge_cmd.target_army_id] + _army_quiver_ammo[merge_cmd.detachment_army_id]

	_army_riders[merge_cmd.target_army_id] = total_riders
	_army_quiver_ammo[merge_cmd.target_army_id] = total_quiver
	_army_riders.erase(merge_cmd.detachment_army_id)
	_army_quiver_ammo.erase(merge_cmd.detachment_army_id)
	_army_roles.erase(merge_cmd.detachment_army_id)
	_isolated_armies.erase(merge_cmd.detachment_army_id)

	merge_cmd.merged_total_riders = total_riders
	merge_cmd.merged_quiver_ammo = total_quiver

	EventBus.forces_merged_into_army.emit(merge_cmd.target_army_id, merge_cmd.detachment_army_id, total_riders)
	return true


func _handle_relocate_nomadic_outpost(command: GameCommand) -> bool:
	var reloc: RelocateNomadicOutpostCommand = command as RelocateNomadicOutpostCommand
	if reloc == null:
		return command.reject("Expected RelocateNomadicOutpostCommand.")
	if reloc.outpost_id == &"":
		return command.reject("RelocateNomadicOutpostCommand requires non-empty outpost_id.")

	var prev_coord: Vector2i = get_nomadic_outpost_coord(reloc.outpost_id)
	reloc.previous_coord = prev_coord
	_nomadic_outposts[reloc.outpost_id] = reloc.target_coord
	reloc.active_outpost_count = _nomadic_outposts.size()

	EventBus.nomadic_outpost_relocated.emit(reloc.player_id, reloc.outpost_id, prev_coord, reloc.target_coord)
	return true


func _fail(command: GameCommand, reason: String) -> bool:
	if command.rejection_reason.is_empty():
		command.rejection_reason = reason
	command_rejected.emit(command, reason)
	return false

