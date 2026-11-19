extends Node
## Autoload `CollapseRecoveryFSM` (rank 2). Implements Phase 20 **Asymmetric
## Losing Experience, Two-Way Truce Withdrawal, Vassal Beylik Constraints,
## Yersiz Yurtsuz Exile Kingmaker, Frontier March & Extinction/Rebirth**.

const RULES_PATH: String = "res://data/governance/collapse_recovery_rules.tres"
const BULLION_ORE_PATH: String = "res://data/ores/silver_gold.tres"

var _rules: CollapseRecoveryRules = null
var _bullion_ore: OreData = null
var _records: Dictionary[int, CollapseRecord] = {}
var _exile_intel_sales_count: Dictionary[int, int] = {}


func _ready() -> void:
	_rules = ResourceLoader.load(RULES_PATH) as CollapseRecoveryRules
	if _rules == null:
		push_error("CollapseRecoveryFSM: failed to load CollapseRecoveryRules at %s." % RULES_PATH)
	else:
		for err: String in _rules.get_validation_errors():
			push_error("CollapseRecoveryFSM: %s" % err)
	_bullion_ore = ResourceLoader.load(BULLION_ORE_PATH) as OreData
	CommandBus.register_handler(TriggerCollapseCommand.ID, _handle_trigger_collapse)
	CommandBus.register_handler(SelectCollapsePathCommand.ID, _handle_select_collapse_path)


func _exit_tree() -> void:
	CommandBus.unregister_handler(TriggerCollapseCommand.ID, _handle_trigger_collapse)
	CommandBus.unregister_handler(SelectCollapsePathCommand.ID, _handle_select_collapse_path)


func reset_collapse_state() -> void:
	_records.clear()
	_exile_intel_sales_count.clear()


func get_exile_intel_sales_count(player_id: int) -> int:
	return _exile_intel_sales_count.get(player_id, 0)


func get_rules() -> CollapseRecoveryRules:
	return _rules


func get_or_create_record(player_id: int) -> CollapseRecord:
	if _records.has(player_id):
		return _records[player_id]
	var rec: CollapseRecord = CollapseRecord.new(player_id)
	_records[player_id] = rec
	return rec


func get_player_state(player_id: int) -> GameEnums.CollapseState:
	if not _records.has(player_id):
		return GameEnums.CollapseState.SOVEREIGN
	return _records[player_id].state


func is_in_collapse_truce(player_id: int) -> bool:
	if not _records.has(player_id):
		return false
	var rec: CollapseRecord = _records[player_id]
	return rec.state == GameEnums.CollapseState.TRUCE_WITHDRAWAL and rec.truce_remaining_hours > 0.0


## Two-way truce check: while `actor_id` OR `target_id` is in `TRUCE_WITHDRAWAL`
## (`18h` fallback protection), neither side may attack or run covert/retaliation actions.
func is_action_blocked_by_collapse_truce(actor_id: int, target_id: int = 0) -> bool:
	if is_in_collapse_truce(actor_id):
		return true
	if target_id > 0 and target_id != actor_id and is_in_collapse_truce(target_id):
		return true
	return false


func advance_collapse_hours(hours: float) -> void:
	var dt: float = maxf(hours, 0.0)
	if dt <= 0.0:
		return
	for pid: int in _records:
		var rec: CollapseRecord = _records[pid]
		if rec.state == GameEnums.CollapseState.TRUCE_WITHDRAWAL and rec.truce_remaining_hours > 0.0:
			rec.truce_remaining_hours = maxf(rec.truce_remaining_hours - dt, 0.0)
			if rec.truce_remaining_hours <= 0.0:
				EventBus.collapse_truce_ended.emit(pid)


func get_kut_ceiling_for_player(player_id: int) -> float:
	if not _records.has(player_id):
		return 100.0
	var rec: CollapseRecord = _records[player_id]
	if rec.state == GameEnums.CollapseState.VASSAL_BEYLIK:
		return _rules.vassal_max_kut_cap if _rules != null else 50.0
	return 100.0


func can_overlord_observe_vassal(overlord_id: int, vassal_id: int) -> bool:
	if not _records.has(vassal_id):
		return false
	var rec: CollapseRecord = _records[vassal_id]
	return rec.state == GameEnums.CollapseState.VASSAL_BEYLIK and rec.overlord_id == overlord_id


func can_vassal_observe_overlord(vassal_id: int, overlord_id: int) -> bool:
	if not _records.has(vassal_id):
		return false
	var rec: CollapseRecord = _records[vassal_id]
	return rec.state == GameEnums.CollapseState.VASSAL_BEYLIK and rec.overlord_id == overlord_id


func get_observed_overlord_status(vassal_id: int, overlord_army_id: int = 1) -> Dictionary[StringName, float]:
	if not _records.has(vassal_id):
		return {}
	var rec: CollapseRecord = _records[vassal_id]
	if rec.state != GameEnums.CollapseState.VASSAL_BEYLIK or rec.overlord_id <= 0:
		return {}
	var overlord_kut: float = GameManager.get_kut_score() if rec.overlord_id == 1 else 75.0
	var supply_isolated: float = 1.0 if CommandBus.is_army_supply_isolated(overlord_army_id) else 0.0
	return {
		&"overlord_id": float(rec.overlord_id),
		&"overlord_kut": overlord_kut,
		&"overlord_supply_isolated": supply_isolated,
	}


func can_use_fixed_refining(player_id: int) -> bool:
	var st: GameEnums.CollapseState = get_player_state(player_id)
	return st != GameEnums.CollapseState.HOMELESS_EXILE and st != GameEnums.CollapseState.DYNASTY_EXTINCT


func get_effective_speed_multiplier(player_id: int) -> float:
	if get_player_state(player_id) == GameEnums.CollapseState.HOMELESS_EXILE:
		return _rules.exile_speed_multiplier if _rules != null else 1.45
	return 1.0


func get_effective_upkeep_multiplier(player_id: int) -> float:
	if get_player_state(player_id) == GameEnums.CollapseState.HOMELESS_EXILE:
		return _rules.exile_upkeep_multiplier if _rules != null else 0.40
	return 1.0


func get_forest_concealment_bonus(player_id: int) -> float:
	if get_player_state(player_id) == GameEnums.CollapseState.HOMELESS_EXILE:
		return _rules.exile_forest_concealment_bonus if _rules != null else 0.45
	return 0.0


func get_effective_army_cap(player_id: int, normal_cap: int = 1000) -> int:
	if get_player_state(player_id) == GameEnums.CollapseState.HOMELESS_EXILE:
		return _rules.exile_max_army_cap if _rules != null else 160
	return normal_cap


func get_frontier_constraints(player_id: int) -> Dictionary[StringName, float]:
	if get_player_state(player_id) != GameEnums.CollapseState.FRONTIER_MARCH_LORD or _rules == null:
		return {
			&"pasture_cap": 100.0,
			&"winter_zud_multiplier": 1.0,
			&"ore_richness_multiplier": 1.0,
		}
	return {
		&"pasture_cap": _rules.frontier_edge_pasture_cap,
		&"winter_zud_multiplier": _rules.frontier_winter_zud_multiplier,
		&"ore_richness_multiplier": _rules.frontier_ore_richness_multiplier,
	}


## Executes Vassal tribute payment from `vassal_id` to overlord (clamped strictly to [15%, 25%]).
func transfer_vassal_tribute(vassal_id: int, gross_bullion_income: int) -> int:
	if not _records.has(vassal_id) or gross_bullion_income <= 0:
		return 0
	var rec: CollapseRecord = _records[vassal_id]
	if rec.state != GameEnums.CollapseState.VASSAL_BEYLIK or rec.overlord_id <= 0:
		return 0
	var min_r: float = _rules.vassal_tribute_rate_min if _rules != null else 0.15
	var max_r: float = _rules.vassal_tribute_rate_max if _rules != null else 0.25
	var clamped_rate: float = clampf(rec.tribute_rate, min_r, max_r)
	var due: int = clampi(int(roundf(float(gross_bullion_income) * clamped_rate)), 0, gross_bullion_income)
	var available: int = ResourceManager.get_amount(vassal_id, &"silver_gold")
	due = mini(due, available)
	if due > 0 and _bullion_ore != null:
		var cost: ResourceAmount = ResourceAmount.new()
		cost.ore = _bullion_ore
		cost.amount = due
		var costs: Array[ResourceAmount] = [cost]
		if CommandBus.dispatch(SpendResourcesCommand.new(vassal_id, costs)):
			CommandBus.dispatch(DepositResourcesCommand.new(rec.overlord_id, &"silver_gold", due))
			return due
	return 0


## Enables a Vassal Beylik to break free either by coup when overlord Kut < 30
## OR by paying the bullion independence ransom cleanly.
func attempt_vassal_independence(vassal_id: int, overlord_kut: float, pay_bullion_ransom: bool = false) -> bool:
	if not _records.has(vassal_id):
		return false
	var rec: CollapseRecord = _records[vassal_id]
	if rec.state != GameEnums.CollapseState.VASSAL_BEYLIK:
		return false
	var old_overlord: int = rec.overlord_id
	var threshold: float = _rules.vassal_coup_overlord_kut_threshold if _rules != null else 30.0
	var ransom_cost: int = _rules.vassal_ransom_bullion_cost if _rules != null else 120

	if not pay_bullion_ransom:
		if overlord_kut < threshold:
			rec.state = GameEnums.CollapseState.SOVEREIGN
			rec.overlord_id = 0
			EventBus.vassal_coup_attempted.emit(vassal_id, old_overlord, true, &"overlord_weak_kut_coup")
			return true
		EventBus.vassal_coup_attempted.emit(vassal_id, old_overlord, false, &"overlord_kut_too_strong")
		return false

	if _bullion_ore != null:
		var cost: ResourceAmount = ResourceAmount.new()
		cost.ore = _bullion_ore
		cost.amount = ransom_cost
		var costs: Array[ResourceAmount] = [cost]
		if CommandBus.dispatch(SpendResourcesCommand.new(vassal_id, costs)):
			if old_overlord > 0:
				CommandBus.dispatch(DepositResourcesCommand.new(old_overlord, &"silver_gold", ransom_cost))
			rec.state = GameEnums.CollapseState.SOVEREIGN
			rec.overlord_id = 0
			EventBus.vassal_coup_attempted.emit(vassal_id, old_overlord, true, &"bullion_ransom_liberation")
			return true
	EventBus.vassal_coup_attempted.emit(vassal_id, old_overlord, false, &"insufficient_ransom_bullion")
	return false


## Active Homeless Exile operation: sells strategic intelligence to `buyer_id` in exchange
## for Meteoric Iron (`Gök Demiri`) and refreshes the clan's Hope/Loyalty gauge.
func perform_exile_intel_sale(exile_id: int, buyer_id: int, target_army_id: int = 1, terrain: TerrainData = null) -> bool:
	if not _records.has(exile_id):
		return false
	var rec: CollapseRecord = _records[exile_id]
	if rec.state != GameEnums.CollapseState.HOMELESS_EXILE:
		return false
	if buyer_id <= 0 or buyer_id == exile_id:
		return false
	if target_army_id > 0:
		CommandBus.dispatch(DispatchSpyCommand.new(
			exile_id, buyer_id, target_army_id, 90.0, terrain, 75.0,
			GameEnums.TuranTacticPhase.FEIGNED_RETREAT_LURE, GameEnums.TacticalDoctrineType.FEIGNED_RETREAT, 0.0, 1))
	var reward: int = _rules.exile_intel_sale_meteoric_reward if _rules != null else 2
	CommandBus.dispatch(DepositResourcesCommand.new(exile_id, &"meteoric_iron", reward))
	var hope_gain: float = _rules.exile_hope_gain_per_operation if _rules != null else 18.0
	rec.exile_hope_loyalty = clampf(rec.exile_hope_loyalty + hope_gain, 0.0, 100.0)
	_exile_intel_sales_count[exile_id] = _exile_intel_sales_count.get(exile_id, 0) + 1
	return true


## Destroys an exile's Sefer Arabası caravan; losing the last caravan triggers DYNASTY_EXTINCT.
func destroy_exile_sefer_arabasi(exile_id: int) -> bool:
	if not _records.has(exile_id):
		return false
	var rec: CollapseRecord = _records[exile_id]
	if rec.state != GameEnums.CollapseState.HOMELESS_EXILE:
		return false
	rec.exile_caravans_remaining = maxi(rec.exile_caravans_remaining - 1, 0)
	if rec.exile_caravans_remaining <= 0:
		_mark_extinct(rec, &"last_sefer_arabasi_destroyed")
		return true
	return false


## Steps one season for collapse state: decays Hope for inactive Exiles (anti-immortal-troll),
## transitions to DYNASTY_EXTINCT if Hope drops to 0, and increments rebirth cooldown.
func step_collapse_season(player_id: int, exile_performed_active_action: bool = false) -> GameEnums.CollapseState:
	if not _records.has(player_id):
		return GameEnums.CollapseState.SOVEREIGN
	var rec: CollapseRecord = _records[player_id]
	if rec.state == GameEnums.CollapseState.HOMELESS_EXILE:
		if not exile_performed_active_action:
			var decay: float = _rules.exile_hope_decay_per_season if _rules != null else 22.0
			rec.exile_hope_loyalty = maxf(rec.exile_hope_loyalty - decay, 0.0)
			if rec.exile_hope_loyalty <= 0.0:
				_mark_extinct(rec, &"exile_hope_loyalty_exhausted")
	elif rec.state == GameEnums.CollapseState.DYNASTY_EXTINCT:
		rec.extinction_seasons_elapsed += 1
	return rec.state


## Rebirths an extinct dynasty on the outer rim (`Uç Beyliği`) after cooldown expires,
## resetting accumulated Glory strictly to 0.0.
func attempt_dynasty_rebirth(player_id: int, grid_size: Vector2i = Vector2i(12, 12), slot_seed: int = 0) -> bool:
	if not _records.has(player_id):
		return false
	var rec: CollapseRecord = _records[player_id]
	if rec.state != GameEnums.CollapseState.DYNASTY_EXTINCT:
		return false
	var needed: int = _rules.rebirth_cooldown_seasons if _rules != null else 4
	if rec.extinction_seasons_elapsed < needed:
		return false

	var rim: Vector2i = GracePeriodManager.register_player(player_id, true, grid_size, slot_seed + 100 + rec.glory_reset_count)
	rec.state = GameEnums.CollapseState.FRONTIER_MARCH_LORD
	rec.frontier_coord = rim
	rec.overlord_id = 0
	rec.current_glory = 0.0
	rec.glory_reset_count += 1
	rec.extinction_seasons_elapsed = 0
	rec.exile_caravans_remaining = 1
	EventBus.dynasty_reborn_at_frontier.emit(player_id, rim, 0.0)
	return true


func _mark_extinct(rec: CollapseRecord, reason: StringName) -> void:
	rec.state = GameEnums.CollapseState.DYNASTY_EXTINCT
	rec.extinction_seasons_elapsed = 0
	rec.overlord_id = 0
	EventBus.exile_dynasty_extinct.emit(rec.player_id, reason)


func _handle_trigger_collapse(command: GameCommand) -> bool:
	var cmd: TriggerCollapseCommand = command as TriggerCollapseCommand
	if cmd == null:
		return command.reject("Expected TriggerCollapseCommand.")
	if cmd.victim_id <= 0 or cmd.conqueror_id <= 0 or cmd.victim_id == cmd.conqueror_id:
		return command.reject("TriggerCollapseCommand requires distinct positive victim_id and conqueror_id.")
	var rec: CollapseRecord = get_or_create_record(cmd.victim_id)
	var truce_h: float = _rules.truce_window_hours if _rules != null else 18.0
	rec.conqueror_id = cmd.conqueror_id
	rec.state = GameEnums.CollapseState.TRUCE_WITHDRAWAL
	rec.truce_remaining_hours = truce_h
	cmd.truce_hours = truce_h
	cmd.resulting_state = rec.state
	EventBus.collapse_triggered.emit(cmd.victim_id, cmd.conqueror_id, truce_h)
	return true


func _handle_select_collapse_path(command: GameCommand) -> bool:
	var cmd: SelectCollapsePathCommand = command as SelectCollapsePathCommand
	if cmd == null:
		return command.reject("Expected SelectCollapsePathCommand.")
	if cmd.player_id <= 0:
		return command.reject("SelectCollapsePathCommand requires player_id > 0.")
	var rec: CollapseRecord = get_or_create_record(cmd.player_id)
	if rec.state != GameEnums.CollapseState.TRUCE_WITHDRAWAL and rec.state != GameEnums.CollapseState.SOVEREIGN:
		return command.reject("Player %d cannot select collapse path from state %d." % [cmd.player_id, rec.state])

	if rec.truce_remaining_hours > 0.0:
		rec.truce_remaining_hours = 0.0
		EventBus.collapse_truce_ended.emit(cmd.player_id)

	var min_r: float = _rules.vassal_tribute_rate_min if _rules != null else 0.15
	var max_r: float = _rules.vassal_tribute_rate_max if _rules != null else 0.25
	var init_hope: float = _rules.exile_initial_hope if _rules != null else 80.0
	var max_kut: float = _rules.vassal_max_kut_cap if _rules != null else 50.0
	var exile_cap: int = _rules.exile_max_army_cap if _rules != null else 160

	if cmd.choice == GameEnums.CollapsePathChoice.SUBMIT_VASSAL:
		rec.state = GameEnums.CollapseState.VASSAL_BEYLIK
		rec.overlord_id = rec.conqueror_id
		rec.tribute_rate = clampf(cmd.requested_tribute_rate, min_r, max_r)
		cmd.overlord_id = rec.overlord_id
		cmd.applied_tribute_rate = rec.tribute_rate
		cmd.kut_cap = max_kut
		cmd.exile_army_cap = 1000
		cmd.can_use_fixed_refining = true
		if cmd.player_id == 1 and GameManager.get_kut_score() > max_kut:
			CommandBus.dispatch(ModifyKutCommand.new(max_kut - GameManager.get_kut_score(), &"vassal_kut_cap"))
	elif cmd.choice == GameEnums.CollapsePathChoice.FLEE_HOMELESS_EXILE:
		rec.state = GameEnums.CollapseState.HOMELESS_EXILE
		rec.overlord_id = 0
		rec.exile_hope_loyalty = init_hope
		rec.exile_caravans_remaining = 1
		cmd.overlord_id = 0
		cmd.applied_tribute_rate = 0.0
		cmd.kut_cap = 100.0
		cmd.exile_army_cap = exile_cap
		cmd.can_use_fixed_refining = false
	elif cmd.choice == GameEnums.CollapsePathChoice.REBUILD_AT_FRONTIER:
		rec.state = GameEnums.CollapseState.FRONTIER_MARCH_LORD
		rec.overlord_id = 0
		var rim: Vector2i = GracePeriodManager.register_player(
			cmd.player_id, true, cmd.frontier_grid_size, cmd.slot_seed)
		rec.frontier_coord = rim
		cmd.frontier_coord = rim
		cmd.overlord_id = 0
		cmd.applied_tribute_rate = 0.0
		cmd.kut_cap = 100.0
		cmd.exile_army_cap = 1000
		cmd.can_use_fixed_refining = true

	cmd.resulting_state = rec.state
	EventBus.collapse_path_selected.emit(cmd.player_id, cmd.choice, rec.state, rec.overlord_id)
	return true


func export_state_dict() -> Dictionary:
	var recs: Dictionary = {}
	for pid: int in _records:
		var r: CollapseRecord = _records[pid]
		recs[str(pid)] = {
			"frontier_x": r.frontier_coord.x,
			"frontier_y": r.frontier_coord.y,
			"overlord_id": r.overlord_id,
			"player_id": r.player_id,
			"state": int(r.state),
			"truce_remaining_hours": r.truce_remaining_hours,
		}
	return {"records": recs}


func import_state_dict(data: Dictionary) -> bool:
	if not (data.get("records") is Dictionary):
		return false
	reset_collapse_state()
	var recs: Dictionary = DeterministicStateHasher.v_dict(data.get("records"))
	for k: Variant in recs:
		var pid: int = DeterministicStateHasher.v_str(k).to_int()
		var rd: Dictionary = DeterministicStateHasher.v_dict(recs[k])
		var r: CollapseRecord = CollapseRecord.new(pid)
		r.state = DeterministicStateHasher.v_int(rd.get("state", 0)) as GameEnums.CollapseState
		r.overlord_id = DeterministicStateHasher.v_int(rd.get("overlord_id", 0))
		r.truce_remaining_hours = DeterministicStateHasher.v_float(rd.get("truce_remaining_hours", 0.0))
		r.frontier_coord = Vector2i(DeterministicStateHasher.v_int(rd.get("frontier_x", 0)), DeterministicStateHasher.v_int(rd.get("frontier_y", 0)))
		_records[pid] = r
	return true
