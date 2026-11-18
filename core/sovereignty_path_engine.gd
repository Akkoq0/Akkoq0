extends Node
## Autoload `SovereigntyPathEngine` (rank 2). Implements Phase 8 **Dynamic
## Behavioral Sovereignty Alignment & Free Path Evolution**
## (`res://core/sovereignty_path_engine.gd`).
##
## Evaluates the player's emergent actions (`Ulu Kağan & Töre Koruyucusu`,
## `Bozkır Akıncısı & Yağma Beyi`, `Göçebe Tüccar & Demirci Hanedanı`,
## `Asi / Bağımsız Oymak`) from real telemetry without ever locking the player
## into a rigid class or linear quest line (`is_any_path_locked() == false`).

const PROFILE_PATH: String = "res://data/sovereignty/sovereignty_profile_data.tres"
const MAX_ALIGNMENT_ACTION_COUNT: int = 100000

var _profile: SovereigntyProfileData = null
var _active_alignment: Dictionary[int, GameEnums.SovereigntyAlignment] = {}
var _tore_actions: Dictionary[int, int] = {}
var _raid_actions: Dictionary[int, int] = {}
var _toy_actions: Dictionary[int, int] = {}
var _refining_actions: Dictionary[int, int] = {}
var _trade_actions: Dictionary[int, int] = {}
var _migration_actions: Dictionary[int, int] = {}
var _defiance_actions: Dictionary[int, int] = {}


func _ready() -> void:
	_profile = ResourceLoader.load(PROFILE_PATH) as SovereigntyProfileData
	if _profile == null:
		push_error("SovereigntyPathEngine: failed to load SovereigntyProfileData at %s." % PROFILE_PATH)
	else:
		for err: String in _profile.get_validation_errors():
			push_error("SovereigntyPathEngine: %s" % err)
	EventBus.ore_refined.connect(_on_ore_refined)
	EventBus.regional_tax_collected.connect(_on_regional_tax_collected)
	EventBus.camp_migrated_by_sefer_arabasi.connect(_on_camp_migrated)
	EventBus.supply_line_severed.connect(_on_supply_line_severed)
	EventBus.council_decree_enacted.connect(_on_council_decree_enacted)
	EventBus.overgrazing_rebellion_triggered.connect(_on_overgrazing_rebellion)
	CommandBus.register_handler(EvaluateSovereigntyPathCommand.ID, _handle_evaluate_sovereignty)


func _exit_tree() -> void:
	CommandBus.unregister_handler(EvaluateSovereigntyPathCommand.ID, _handle_evaluate_sovereignty)


func get_profile() -> SovereigntyProfileData:
	return _profile


func get_active_alignment(player_id: int) -> GameEnums.SovereigntyAlignment:
	if _active_alignment.has(player_id):
		return _active_alignment[player_id]
	return GameEnums.SovereigntyAlignment.ULU_KAGAN_TORE_GUARDIAN


## Phase 8 Zero-Lock Guarantee: no sovereignty path ever permanently locks out any other path.
func is_any_path_locked(_player_id: int) -> bool:
	return false


func get_unlocked_strategic_options(player_id: int) -> PackedStringArray:
	if _profile == null:
		return PackedStringArray()
	return _profile.get_alignment_strategic_options(get_active_alignment(player_id))


func _handle_evaluate_sovereignty(command: GameCommand) -> bool:
	var cmd: EvaluateSovereigntyPathCommand = command as EvaluateSovereigntyPathCommand
	if cmd == null:
		return command.reject("Expected EvaluateSovereigntyPathCommand.")
	if _profile == null:
		return command.reject("SovereigntyProfileData not loaded.")

	var pid: int = cmd.player_id
	if cmd.reset_counters_before_apply:
		_tore_actions[pid] = 0
		_raid_actions[pid] = 0
		_toy_actions[pid] = 0
		_refining_actions[pid] = 0
		_trade_actions[pid] = 0
		_migration_actions[pid] = 0
		_defiance_actions[pid] = 0

	var tore_cnt: int = clampi(_get_count(_tore_actions, pid) + cmd.add_tore_actions, 0, MAX_ALIGNMENT_ACTION_COUNT)
	var raid_cnt: int = clampi(_get_count(_raid_actions, pid) + cmd.add_raid_actions, 0, MAX_ALIGNMENT_ACTION_COUNT)
	var toy_cnt: int = clampi(_get_count(_toy_actions, pid) + cmd.add_toy_actions, 0, MAX_ALIGNMENT_ACTION_COUNT)
	var ref_cnt: int = clampi(_get_count(_refining_actions, pid) + cmd.add_refining_actions, 0, MAX_ALIGNMENT_ACTION_COUNT)
	var trd_cnt: int = clampi(_get_count(_trade_actions, pid) + cmd.add_trade_actions, 0, MAX_ALIGNMENT_ACTION_COUNT)
	var mig_cnt: int = clampi(_get_count(_migration_actions, pid) + cmd.add_migration_actions, 0, MAX_ALIGNMENT_ACTION_COUNT)
	var def_cnt: int = clampi(_get_count(_defiance_actions, pid) + cmd.add_defiance_actions, 0, MAX_ALIGNMENT_ACTION_COUNT)

	_tore_actions[pid] = tore_cnt
	_raid_actions[pid] = raid_cnt
	_trade_actions[pid] = trd_cnt
	_toy_actions[pid] = toy_cnt
	_refining_actions[pid] = ref_cnt
	_migration_actions[pid] = mig_cnt
	_defiance_actions[pid] = def_cnt

	var safe_kut: float = 75.0 if (is_nan(cmd.kut_score) or is_inf(cmd.kut_score)) else clampf(cmd.kut_score, 0.0, 100.0)
	var safe_glory: float = 0.0 if (is_nan(cmd.glory_score) or is_inf(cmd.glory_score)) else clampf(cmd.glory_score, 0.0, 100.0)

	var prev: GameEnums.SovereigntyAlignment = get_active_alignment(pid)
	cmd.previous_alignment = prev

	var scores: Dictionary[GameEnums.SovereigntyAlignment, float] = _profile.compute_alignment_scores(
		safe_kut, tore_cnt, raid_cnt, safe_glory, toy_cnt, ref_cnt, trd_cnt, mig_cnt, def_cnt)

	var best_alignment: GameEnums.SovereigntyAlignment = GameEnums.SovereigntyAlignment.ULU_KAGAN_TORE_GUARDIAN
	var best_score: float = -1.0
	for align: GameEnums.SovereigntyAlignment in scores:
		var val: float = scores[align]
		if val > best_score:
			best_score = val
			best_alignment = align

	_active_alignment[pid] = best_alignment
	cmd.active_alignment = best_alignment
	cmd.dominant_score = best_score
	cmd.unlocked_strategic_options = _profile.get_alignment_strategic_options(best_alignment)

	if prev != best_alignment:
		EventBus.sovereignty_alignment_evolved.emit(pid, prev, best_alignment, best_score)
	return true


func _get_count(table: Dictionary[int, int], player_id: int) -> int:
	if table.has(player_id):
		return table[player_id]
	return 0


func _on_ore_refined(player_id: int, _recipe_id: StringName, _building_id: StringName, batches: int) -> void:
	_refining_actions[player_id] = mini(_get_count(_refining_actions, player_id) + maxi(batches, 1), MAX_ALIGNMENT_ACTION_COUNT)


func _on_regional_tax_collected(player_id: int, _tax_amount: int, _mult: float) -> void:
	_trade_actions[player_id] = mini(_get_count(_trade_actions, player_id) + 1, MAX_ALIGNMENT_ACTION_COUNT)


func _on_camp_migrated(player_id: int, _from: Vector2i, _to: Vector2i, _cap: float) -> void:
	_migration_actions[player_id] = mini(_get_count(_migration_actions, player_id) + 1, MAX_ALIGNMENT_ACTION_COUNT)


func _on_supply_line_severed(_army_id: int, _depot_id: int, _raider_id: StringName, _loot: float) -> void:
	_raid_actions[1] = mini(_get_count(_raid_actions, 1) + 1, MAX_ALIGNMENT_ACTION_COUNT)


func _on_council_decree_enacted(player_id: int, choice: GameEnums.CouncilDilemmaChoice, _kut: float, _inc: float, _spd: float, _loot: float) -> void:
	if choice == GameEnums.CouncilDilemmaChoice.TRADITION:
		_tore_actions[player_id] = mini(_get_count(_tore_actions, player_id) + 1, MAX_ALIGNMENT_ACTION_COUNT)
	elif choice == GameEnums.CouncilDilemmaChoice.EXPANSION:
		_raid_actions[player_id] = mini(_get_count(_raid_actions, player_id) + 1, MAX_ALIGNMENT_ACTION_COUNT)


func _on_overgrazing_rebellion(player_id: int, _coord: Vector2i, _penalty: float) -> void:
	_defiance_actions[player_id] = mini(_get_count(_defiance_actions, player_id) + 1, MAX_ALIGNMENT_ACTION_COUNT)
