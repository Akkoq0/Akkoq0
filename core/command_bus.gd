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
var _envelope_queue: Array[CommandEnvelope] = []
var _last_sequence_by_sender: Dictionary[String, int] = {}
var _queued_envelope_keys: Dictionary[String, bool] = {}
var _envelope_army_owners: Dictionary[int, int] = {}


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
	register_handler(StartResearchCommand.ID, TraditionResearchManager.handle_start_research)


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


func reset_envelope_state() -> void:
	_envelope_queue.clear()
	_last_sequence_by_sender.clear()
	_queued_envelope_keys.clear()
	_envelope_army_owners.clear()


func register_envelope_army_owner(army_id: int, player_id: int) -> void:
	if army_id > 0 and player_id > 0:
		_envelope_army_owners[army_id] = player_id


func get_pending_envelope_count() -> int:
	return _envelope_queue.size()


func get_last_sequence_for_sender(sender_player_id: String) -> int:
	return _last_sequence_by_sender.get(sender_player_id, 0)


func _reject_envelope(
		envelope: CommandEnvelope,
		status: GameEnums.CommandEnvelopeStatus,
		reason: String) -> bool:
	if envelope != null:
		envelope.status = status
		envelope.rejection_reason = reason
		EventBus.command_envelope_rejected.emit(envelope.sequence_id, envelope.sender_player_id, status, reason)
	command_rejected.emit(null, reason)
	return false


func enqueue_envelope(envelope: CommandEnvelope, current_tick: int = -1) -> bool:
	if envelope == null:
		return _reject_envelope(null, GameEnums.CommandEnvelopeStatus.REJECTED_INVALID, "Null CommandEnvelope.")
	if envelope.sender_player_id.strip_edges().is_empty() or envelope.command_type.strip_edges().is_empty():
		return _reject_envelope(envelope, GameEnums.CommandEnvelopeStatus.REJECTED_INVALID, "Missing sender_player_id or command_type.")

	var sender_pid: int = envelope.parse_player_id()
	if sender_pid <= 0:
		return _reject_envelope(envelope, GameEnums.CommandEnvelopeStatus.REJECTED_UNAUTHORIZED, "REJECTED_UNAUTHORIZED: invalid sender_player_id.")

	var effective_tick: int = current_tick if current_tick >= 0 else SessionClockAuthority.get_current_tick()
	var last_seq: int = _last_sequence_by_sender.get(envelope.sender_player_id, 0)
	var env_key: String = "%s:%d" % [envelope.sender_player_id, envelope.sequence_id]
	if envelope.sequence_id <= 0 or envelope.sequence_id <= last_seq or _queued_envelope_keys.has(env_key):
		return _reject_envelope(envelope, GameEnums.CommandEnvelopeStatus.REJECTED_STALE_OR_DUPLICATE, "REJECTED_STALE_OR_DUPLICATE: sequence_id %d." % envelope.sequence_id)
	if envelope.target_tick < effective_tick:
		return _reject_envelope(envelope, GameEnums.CommandEnvelopeStatus.REJECTED_STALE_OR_DUPLICATE, "REJECTED_STALE_OR_DUPLICATE: past target_tick %d < %d." % [envelope.target_tick, effective_tick])

	var payload: Dictionary = envelope.payload
	if payload.has("player_id") and DeterministicStateHasher.v_int(payload.get("player_id"), -1) != sender_pid:
		return _reject_envelope(envelope, GameEnums.CommandEnvelopeStatus.REJECTED_UNAUTHORIZED, "REJECTED_UNAUTHORIZED: player_id mismatch.")
	if payload.has("owner_id") and DeterministicStateHasher.v_int(payload.get("owner_id"), -1) != sender_pid:
		return _reject_envelope(envelope, GameEnums.CommandEnvelopeStatus.REJECTED_UNAUTHORIZED, "REJECTED_UNAUTHORIZED: owner_id mismatch.")
	if payload.has("saboteur_id") and DeterministicStateHasher.v_int(payload.get("saboteur_id"), -1) != sender_pid:
		return _reject_envelope(envelope, GameEnums.CommandEnvelopeStatus.REJECTED_UNAUTHORIZED, "REJECTED_UNAUTHORIZED: saboteur_id mismatch.")
	if payload.has("sponsor_id") and DeterministicStateHasher.v_int(payload.get("sponsor_id"), -1) != sender_pid:
		return _reject_envelope(envelope, GameEnums.CommandEnvelopeStatus.REJECTED_UNAUTHORIZED, "REJECTED_UNAUTHORIZED: sponsor_id mismatch.")
	if payload.has("ambusher_faction_id") and DeterministicStateHasher.v_int(payload.get("ambusher_faction_id"), -1) != sender_pid:
		return _reject_envelope(envelope, GameEnums.CommandEnvelopeStatus.REJECTED_UNAUTHORIZED, "REJECTED_UNAUTHORIZED: ambusher_faction_id mismatch.")
	if payload.has("spy_owner_id") and DeterministicStateHasher.v_int(payload.get("spy_owner_id"), -1) != sender_pid:
		return _reject_envelope(envelope, GameEnums.CommandEnvelopeStatus.REJECTED_UNAUTHORIZED, "REJECTED_UNAUTHORIZED: spy_owner_id mismatch.")
	if payload.has("challenger_id") and DeterministicStateHasher.v_int(payload.get("challenger_id"), -1) != sender_pid:
		return _reject_envelope(envelope, GameEnums.CommandEnvelopeStatus.REJECTED_UNAUTHORIZED, "REJECTED_UNAUTHORIZED: challenger_id mismatch.")
	if payload.has("betrayer_id") and DeterministicStateHasher.v_int(payload.get("betrayer_id"), -1) != sender_pid:
		return _reject_envelope(envelope, GameEnums.CommandEnvelopeStatus.REJECTED_UNAUTHORIZED, "REJECTED_UNAUTHORIZED: betrayer_id mismatch.")
	if envelope.command_type == "intercept_caravan" and payload.has("raider_id") and DeterministicStateHasher.v_int(payload.get("raider_id"), -1) != sender_pid:
		return _reject_envelope(envelope, GameEnums.CommandEnvelopeStatus.REJECTED_UNAUTHORIZED, "REJECTED_UNAUTHORIZED: raider_id mismatch.")
	if envelope.command_type == "interdict_supply_line" and payload.has("raider_player_id") and DeterministicStateHasher.v_int(payload.get("raider_player_id"), -1) != sender_pid:
		return _reject_envelope(envelope, GameEnums.CommandEnvelopeStatus.REJECTED_UNAUTHORIZED, "REJECTED_UNAUTHORIZED: raider_player_id mismatch.")
	if payload.has("army_id"):
		var aid: int = DeterministicStateHasher.v_int(payload.get("army_id"), 0)
		if _envelope_army_owners.has(aid) and _envelope_army_owners[aid] != sender_pid:
			return _reject_envelope(envelope, GameEnums.CommandEnvelopeStatus.REJECTED_UNAUTHORIZED, "REJECTED_UNAUTHORIZED: army %d owned by another player." % aid)
	if payload.has("region_x") and payload.has("region_y"):
		var r_coord: Vector2i = Vector2i(DeterministicStateHasher.v_int(payload.get("region_x"), 0), DeterministicStateHasher.v_int(payload.get("region_y"), 0))
		var reg: RegionData = TerritoryManager.get_region(r_coord)
		if reg != null and reg.owner_id > 0 and reg.owner_id != sender_pid and envelope.command_type != "sabotage_well" and envelope.command_type != "open_yurt_claim":
			return _reject_envelope(envelope, GameEnums.CommandEnvelopeStatus.REJECTED_UNAUTHORIZED, "REJECTED_UNAUTHORIZED: region owned by another player.")

	var cmd_type: String = envelope.command_type
	var wants_pause: bool = (cmd_type == "pause_session" and DeterministicStateHasher.v_bool(payload.get("paused", true), true)) \
		or (cmd_type == "change_game_state" and DeterministicStateHasher.v_int(payload.get("target_state", -1), -1) == int(GameEnums.GameState.PAUSED))
	if wants_pause and not SessionClockAuthority.can_pause():
		SessionClockAuthority.request_pause(true, envelope.sender_player_id)
		return _reject_envelope(envelope, GameEnums.CommandEnvelopeStatus.REJECTED_PAUSE_IN_ONLINE, "REJECTED_PAUSE_IN_ONLINE")

	var stored: CommandEnvelope = envelope.duplicate_envelope()
	stored.status = GameEnums.CommandEnvelopeStatus.ACCEPTED
	_queued_envelope_keys[env_key] = true
	_envelope_queue.append(stored)
	_envelope_queue.sort_custom(func(a: CommandEnvelope, b: CommandEnvelope) -> bool:
		if a.target_tick != b.target_tick:
			return a.target_tick < b.target_tick
		if a.sequence_id != b.sequence_id:
			return a.sequence_id < b.sequence_id
		return a.sender_player_id < b.sender_player_id
	)
	envelope.status = GameEnums.CommandEnvelopeStatus.ACCEPTED
	return true


func flush_envelopes_for_tick(tick: int = -1) -> int:
	var target: int = tick if tick >= 0 else SessionClockAuthority.get_current_tick()
	var executed: int = 0
	var remaining: Array[CommandEnvelope] = []
	for env: CommandEnvelope in _envelope_queue:
		if env.target_tick <= target:
			var env_key: String = "%s:%d" % [env.sender_player_id, env.sequence_id]
			_queued_envelope_keys.erase(env_key)
			var prev_seq: int = _last_sequence_by_sender.get(env.sender_player_id, 0)
			if env.sequence_id > prev_seq:
				_last_sequence_by_sender[env.sender_player_id] = env.sequence_id
			if _execute_envelope(env):
				executed += 1
		else:
			remaining.append(env)
	_envelope_queue = remaining
	return executed


func _execute_envelope(envelope: CommandEnvelope) -> bool:
	var p: Dictionary = envelope.payload
	var sender_pid: int = envelope.parse_player_id()
	match envelope.command_type:
		"deposit_resources":
			var cmd: DepositResourcesCommand = DepositResourcesCommand.new(
				DeterministicStateHasher.v_int(p.get("player_id", sender_pid), sender_pid),
				StringName(DeterministicStateHasher.v_str(p.get("ore_id", "iron"), "iron")),
				DeterministicStateHasher.v_int(p.get("amount", 0)))
			envelope.executed_command = cmd
			return dispatch(cmd)
		"spend_resources":
			var reg_ores: OreRegistry = ResourceManager.get_registry()
			var ore: OreData = reg_ores.find_ore(StringName(DeterministicStateHasher.v_str(p.get("ore_id", "iron"), "iron"))) if reg_ores != null else null
			if ore == null:
				return false
			var cost: ResourceAmount = ResourceAmount.new()
			cost.ore = ore
			cost.amount = DeterministicStateHasher.v_int(p.get("amount", 0))
			var costs: Array[ResourceAmount] = [cost]
			var cmd: SpendResourcesCommand = SpendResourcesCommand.new(DeterministicStateHasher.v_int(p.get("player_id", sender_pid), sender_pid), costs)
			envelope.executed_command = cmd
			return dispatch(cmd)
		"modify_kut":
			var cmd: ModifyKutCommand = ModifyKutCommand.new(
				DeterministicStateHasher.v_float(p.get("delta_kut", 0.0)),
				StringName(DeterministicStateHasher.v_str(p.get("reason", "envelope_kut"), "envelope_kut")))
			envelope.executed_command = cmd
			return dispatch(cmd)
		"assign_battle_doctrine":
			var cmd: AssignBattleDoctrineCommand = AssignBattleDoctrineCommand.new(
				DeterministicStateHasher.v_int(p.get("army_id", 1), 1),
				DeterministicStateHasher.v_int(p.get("player_id", sender_pid), sender_pid),
				null,
				DeterministicStateHasher.v_int(p.get("preset_id", int(GameEnums.BattleDoctrinePresetId.KURT_KAPANI)), int(GameEnums.BattleDoctrinePresetId.KURT_KAPANI)) as GameEnums.BattleDoctrinePresetId,
				DeterministicStateHasher.v_bool(p.get("sync_offline_contingency", true), true))
			envelope.executed_command = cmd
			return dispatch(cmd)
		"toggle_dust_screen":
			var cmd: ToggleDustScreenCommand = ToggleDustScreenCommand.new(
				DeterministicStateHasher.v_int(p.get("army_id", 1), 1),
				DeterministicStateHasher.v_int(p.get("player_id", sender_pid), sender_pid),
				DeterministicStateHasher.v_bool(p.get("enable", true), true),
				DeterministicStateHasher.v_float(p.get("remount_horse_ratio", 1.0), 1.0))
			envelope.executed_command = cmd
			return dispatch(cmd)
		"collect_regional_tax":
			var cmd: CollectRegionalTaxCommand = CollectRegionalTaxCommand.new(
				DeterministicStateHasher.v_int(p.get("player_id", sender_pid), sender_pid),
				DeterministicStateHasher.v_int(p.get("controlled_region_count", 1), 1),
				DeterministicStateHasher.v_int(p.get("rich_region_count", 0), 0))
			envelope.executed_command = cmd
			return dispatch(cmd)
		"sabotage_well":
			var coord_s: Vector2i = Vector2i(DeterministicStateHasher.v_int(p.get("region_x", 0)), DeterministicStateHasher.v_int(p.get("region_y", 0)))
			var cmd: SabotageWellCommand = SabotageWellCommand.new(
				DeterministicStateHasher.v_int(p.get("player_id", sender_pid), sender_pid),
				coord_s,
				StringName(DeterministicStateHasher.v_str(p.get("source_id", ""))),
				DeterministicStateHasher.v_int(p.get("duration_seasons", 3), 3))
			envelope.executed_command = cmd
			return dispatch(cmd)
		"restore_water_source":
			var coord_r: Vector2i = Vector2i(DeterministicStateHasher.v_int(p.get("region_x", 0)), DeterministicStateHasher.v_int(p.get("region_y", 0)))
			var cmd: RestoreWaterSourceCommand = RestoreWaterSourceCommand.new(
				DeterministicStateHasher.v_int(p.get("player_id", sender_pid), sender_pid),
				coord_r,
				StringName(DeterministicStateHasher.v_str(p.get("source_id", ""))))
			envelope.executed_command = cmd
			return dispatch(cmd)
		"execute_barter_trade":
			var coord_b: Vector2i = Vector2i(DeterministicStateHasher.v_int(p.get("region_x", 0)), DeterministicStateHasher.v_int(p.get("region_y", 0)))
			var cmd: ExecuteBarterTradeCommand = ExecuteBarterTradeCommand.new(
				DeterministicStateHasher.v_int(p.get("player_id", sender_pid), sender_pid),
				coord_b,
				StringName(DeterministicStateHasher.v_str(p.get("commodity_id", "iron"), "iron")),
				DeterministicStateHasher.v_int(p.get("direction", int(GameEnums.BarterDirection.BUY_FROM_MARKET)), int(GameEnums.BarterDirection.BUY_FROM_MARKET)) as GameEnums.BarterDirection,
				DeterministicStateHasher.v_int(p.get("quantity", 1), 1),
				DeterministicStateHasher.v_bool(p.get("use_black_market", false)))
			envelope.executed_command = cmd
			return dispatch(cmd)
		"delegate_region":
			var coord_d: Vector2i = Vector2i(DeterministicStateHasher.v_int(p.get("region_x", 0)), DeterministicStateHasher.v_int(p.get("region_y", 0)))
			var cmd: DelegateRegionToVassalCommand = DelegateRegionToVassalCommand.new(
				DeterministicStateHasher.v_int(p.get("player_id", sender_pid), sender_pid),
				coord_d,
				StringName(DeterministicStateHasher.v_str(p.get("bey_id", ""))),
				DeterministicStateHasher.v_int(p.get("personality_trait", int(GameEnums.VassalPersonalityTrait.LOYAL)), int(GameEnums.VassalPersonalityTrait.LOYAL)) as GameEnums.VassalPersonalityTrait)
			envelope.executed_command = cmd
			return dispatch(cmd)
		"resolve_conquest_aftermath":
			var coord_c: Vector2i = Vector2i(DeterministicStateHasher.v_int(p.get("region_x", 0)), DeterministicStateHasher.v_int(p.get("region_y", 0)))
			var cmd: ResolveConquestAftermathCommand = ResolveConquestAftermathCommand.new(
				DeterministicStateHasher.v_int(p.get("player_id", sender_pid), sender_pid),
				coord_c,
				DeterministicStateHasher.v_int(p.get("choice", int(GameEnums.ConquestAftermathChoice.HOLD_GARRISON_CONTROL)), int(GameEnums.ConquestAftermathChoice.HOLD_GARRISON_CONTROL)) as GameEnums.ConquestAftermathChoice,
				StringName(DeterministicStateHasher.v_str(p.get("vassal_bey_id", "appointed_vassal_bey"), "appointed_vassal_bey")))
			envelope.executed_command = cmd
			return dispatch(cmd)
		"select_collapse_path":
			var cmd: SelectCollapsePathCommand = SelectCollapsePathCommand.new(
				DeterministicStateHasher.v_int(p.get("player_id", sender_pid), sender_pid),
				DeterministicStateHasher.v_int(p.get("choice", int(GameEnums.CollapsePathChoice.SUBMIT_VASSAL)), int(GameEnums.CollapsePathChoice.SUBMIT_VASSAL)) as GameEnums.CollapsePathChoice,
				DeterministicStateHasher.v_float(p.get("requested_tribute_rate", 0.20), 0.20),
				DeterministicStateHasher.v_int(p.get("slot_seed", 0)),
				Vector2i(DeterministicStateHasher.v_int(p.get("frontier_w", 12), 12), DeterministicStateHasher.v_int(p.get("frontier_h", 12), 12)))
			envelope.executed_command = cmd
			return dispatch(cmd)
		"resolve_succession_crisis":
			var cmd: ResolveSuccessionCrisisCommand = ResolveSuccessionCrisisCommand.new(
				DeterministicStateHasher.v_int(p.get("player_id", sender_pid), sender_pid),
				DeterministicStateHasher.v_int(p.get("response", int(GameEnums.SuccessionCrisisResponse.COUNCIL_REGENCY_TRANSITION)), int(GameEnums.SuccessionCrisisResponse.COUNCIL_REGENCY_TRANSITION)) as GameEnums.SuccessionCrisisResponse)
			envelope.executed_command = cmd
			return dispatch(cmd)
		"change_game_state":
			var cmd: ChangeGameStateCommand = ChangeGameStateCommand.new(
				DeterministicStateHasher.v_int(p.get("target_state", int(GameEnums.GameState.PLAYING)), int(GameEnums.GameState.PLAYING)) as GameEnums.GameState)
			envelope.executed_command = cmd
			return dispatch(cmd)
		"pause_session":
			return SessionClockAuthority.request_pause(DeterministicStateHasher.v_bool(p.get("paused", true), true), envelope.sender_player_id)
		"resume_session":
			return SessionClockAuthority.request_pause(false, envelope.sender_player_id)
		"set_tempo_speed":
			return SessionClockAuthority.set_speed_scale(DeterministicStateHasher.v_float(p.get("speed_scale", 1.0), 1.0))
		"advance_season":
			SeasonManager.advance_season_cycle(DeterministicStateHasher.v_float(p.get("pasture_yield_multiplier", -1.0), -1.0))
			return true
		"ambush_courier":
			var cmd: AmbushCourierCommand = AmbushCourierCommand.new(
				StringName(DeterministicStateHasher.v_str(p.get("order_id", ""))),
				sender_pid)
			envelope.executed_command = cmd
			return dispatch(cmd)
		"intercept_caravan":
			var cmd: InterceptCaravanCommand = InterceptCaravanCommand.new(
				StringName(DeterministicStateHasher.v_str(p.get("caravan_id", ""))),
				sender_pid)
			envelope.executed_command = cmd
			return dispatch(cmd)
		"sponsor_proxy_war":
			var cmd: SponsorProxyWarCommand = SponsorProxyWarCommand.new(
				sender_pid,
				StringName(DeterministicStateHasher.v_str(p.get("warband_id", "exile_raiders"), "exile_raiders")),
				DeterministicStateHasher.v_int(p.get("target_id", 1), 1),
				DeterministicStateHasher.v_int(p.get("silver_cost", 45), 45),
				DeterministicStateHasher.v_float(p.get("raid_intensity", 0.75), 0.75))
			envelope.executed_command = cmd
			return dispatch(cmd)
		"interdict_supply_line":
			var cmd: InterdictSupplyLineCommand = InterdictSupplyLineCommand.new(
				DeterministicStateHasher.v_int(p.get("target_army_id", 1), 1),
				DeterministicStateHasher.v_int(p.get("depot_id", 1), 1),
				StringName(DeterministicStateHasher.v_str(p.get("raider_id", str(sender_pid)), str(sender_pid))))
			envelope.executed_command = cmd
			return dispatch(cmd)
		"dispatch_spy":
			var terrain_path: String = DeterministicStateHasher.v_str(p.get("terrain_path", "res://data/terrain/steppe.tres"), "res://data/terrain/steppe.tres")
			var terrain_res: TerrainData = ResourceLoader.load(terrain_path) as TerrainData
			var cmd: DispatchSpyCommand = DispatchSpyCommand.new(
				sender_pid,
				DeterministicStateHasher.v_int(p.get("target_faction_id", 1), 1),
				DeterministicStateHasher.v_int(p.get("target_army_id", 1), 1),
				DeterministicStateHasher.v_float(p.get("commander_leadership", 65.0), 65.0),
				terrain_res,
				DeterministicStateHasher.v_float(p.get("target_quiver_ammo", 50.0), 50.0),
				DeterministicStateHasher.v_int(p.get("target_tactic_intent", int(GameEnums.TuranTacticPhase.RECON_DUST_SCREEN)), int(GameEnums.TuranTacticPhase.RECON_DUST_SCREEN)) as GameEnums.TuranTacticPhase,
				DeterministicStateHasher.v_int(p.get("target_doctrine_type", int(GameEnums.TacticalDoctrineType.FEIGNED_RETREAT)), int(GameEnums.TacticalDoctrineType.FEIGNED_RETREAT)) as GameEnums.TacticalDoctrineType,
				DeterministicStateHasher.v_float(p.get("counter_espionage", 0.0), 0.0),
				DeterministicStateHasher.v_int(p.get("rng_seed", 1), 1))
			envelope.executed_command = cmd
			return dispatch(cmd)
		"evaluate_diplomacy":
			var cmd: EvaluateDiplomacyCommand = EvaluateDiplomacyCommand.new(
				DeterministicStateHasher.v_float(p.get("player_kut", 50.0), 50.0),
				DeterministicStateHasher.v_float(p.get("player_army_size", 1000.0), 1000.0),
				DeterministicStateHasher.v_float(p.get("raid_frequency", 0.0), 0.0))
			envelope.executed_command = cmd
			return dispatch(cmd)
		"open_yurt_claim":
			var coord_y: Vector2i = Vector2i(
				DeterministicStateHasher.v_int(p.get("region_x", 0)),
				DeterministicStateHasher.v_int(p.get("region_y", 0)))
			var cmd: OpenYurtClaimCommand = OpenYurtClaimCommand.new(
				StringName(DeterministicStateHasher.v_str(p.get("claim_id", ""))),
				sender_pid,
				coord_y,
				DeterministicStateHasher.v_float(p.get("challenger_glory", 25.0), 25.0))
			envelope.executed_command = cmd
			return dispatch(cmd)
		"break_amanat_pact":
			var cmd: BreakAmanatPactCommand = BreakAmanatPactCommand.new(
				StringName(DeterministicStateHasher.v_str(p.get("pact_id", ""))),
				sender_pid)
			envelope.executed_command = cmd
			return dispatch(cmd)
		"step_ai_commander":
			var cmd: StepAICommanderCommand = StepAICommanderCommand.new(
				StringName(DeterministicStateHasher.v_str(p.get("agent_id", ""))),
				DeterministicStateHasher.v_bool(p.get("is_rogue_warband", false), false),
				DeterministicStateHasher.v_int(p.get("target_player_army_id", 1), 1),
				DeterministicStateHasher.v_int(p.get("target_depot_id", 1), 1))
			envelope.executed_command = cmd
			return dispatch(cmd)
		"start_research":
			var sr_cmd: StartResearchCommand = StartResearchCommand.new(
				DeterministicStateHasher.v_int(p.get("player_id", sender_pid), sender_pid),
				StringName(DeterministicStateHasher.v_str(p.get("node_id", ""))))
			envelope.executed_command = sr_cmd
			return dispatch(sr_cmd)
		_:
			return false


func export_envelope_state_dict() -> Dictionary:
	var seqs: Dictionary = {}
	for k: String in _last_sequence_by_sender:
		seqs[k] = _last_sequence_by_sender[k]
	var sat: Dictionary = {}
	for b: StringName in _bey_satisfaction:
		sat[String(b)] = _bey_satisfaction[b]
	var rogues: Dictionary = {}
	for b: StringName in _rogue_warbands:
		rogues[String(b)] = _rogue_warbands[b]
	var iso: Dictionary = {}
	for aid: int in _isolated_armies:
		iso[str(aid)] = _isolated_armies[aid]
	var riders: Dictionary = {}
	for aid: int in _army_riders:
		riders[str(aid)] = _army_riders[aid]
	var owners: Dictionary = {}
	for aid: int in _envelope_army_owners:
		owners[str(aid)] = _envelope_army_owners[aid]
	return {
		"army_owners": owners,
		"army_riders": riders,
		"bey_satisfaction": sat,
		"isolated_armies": iso,
		"last_sequence_by_sender": seqs,
		"rogue_warbands": rogues,
	}


func import_envelope_state_dict(data: Dictionary) -> bool:
	if not (data.get("last_sequence_by_sender") is Dictionary):
		return false
	reset_envelope_state()
	_bey_satisfaction.clear()
	_rogue_warbands.clear()
	_isolated_armies.clear()
	_army_riders.clear()
	var seqs: Dictionary = DeterministicStateHasher.v_dict(data.get("last_sequence_by_sender"))
	for k: Variant in seqs:
		_last_sequence_by_sender[DeterministicStateHasher.v_str(k)] = DeterministicStateHasher.v_int(seqs[k])
	var sat: Dictionary = DeterministicStateHasher.v_dict(data.get("bey_satisfaction", {}))
	for k: Variant in sat:
		_bey_satisfaction[StringName(DeterministicStateHasher.v_str(k))] = DeterministicStateHasher.v_float(sat[k])
	var rogues: Dictionary = DeterministicStateHasher.v_dict(data.get("rogue_warbands", {}))
	for k: Variant in rogues:
		_rogue_warbands[StringName(DeterministicStateHasher.v_str(k))] = DeterministicStateHasher.v_str(rogues[k])
	var iso: Dictionary = DeterministicStateHasher.v_dict(data.get("isolated_armies", {}))
	for k: Variant in iso:
		_isolated_armies[DeterministicStateHasher.v_str(k).to_int()] = DeterministicStateHasher.v_bool(iso[k])
	var riders: Dictionary = DeterministicStateHasher.v_dict(data.get("army_riders", {}))
	for k: Variant in riders:
		_army_riders[DeterministicStateHasher.v_str(k).to_int()] = DeterministicStateHasher.v_int(riders[k])
	var owners: Dictionary = DeterministicStateHasher.v_dict(data.get("army_owners", {}))
	for k: Variant in owners:
		_envelope_army_owners[DeterministicStateHasher.v_str(k).to_int()] = DeterministicStateHasher.v_int(owners[k])
	return true

