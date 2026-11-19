extends Node
## Autoload `DiplomacyManager` (rank 2). Manages Phase 5 **Dynamic Dynasty
## Relations & Threat Matrix (`calculate_dynasty_stance`)** for rival steppe
## powers (Karluk, Kıpçak, Oğuz Beylikleri) and triggers opportunistic
## **Coalition Wars (`EventBus.coalition_war_declared`)** when the Khaganate's
## Kut drops below the critical threshold (`< 30`).

const DEFAULT_DYNASTY_PATH: String = "res://data/diplomacy/dynasty_profile.tres"
const KARLUK_PATH: String = "res://data/diplomacy/karluk_dynasty.tres"
const KIPCHAK_PATH: String = "res://data/diplomacy/kipchak_dynasty.tres"
const OGHUZ_PATH: String = "res://data/diplomacy/oghuz_dynasty.tres"

var _profiles: Dictionary[StringName, DynastyProfile] = {}
var _trust_scores: Dictionary[StringName, float] = {}
var _stances: Dictionary[StringName, GameEnums.DynastyAttitude] = {}
var _player_army_size: float = 1000.0
var _raid_frequency: float = 0.0
var _coalition_war_active: bool = false
var _coalition_members: PackedStringArray = PackedStringArray()
var _espionage_deterrence_bonus: float = 0.0
var _spy_exposure_penalty: float = 0.0
var _recent_assassination_infamy: float = 0.0
var _tracked_kagan_glory: float = 0.0


func _ready() -> void:
	_load_profile(DEFAULT_DYNASTY_PATH)
	_load_profile(KARLUK_PATH)
	_load_profile(KIPCHAK_PATH)
	_load_profile(OGHUZ_PATH)
	CommandBus.register_handler(EvaluateDiplomacyCommand.ID, _handle_evaluate_diplomacy)
	EventBus.kut_changed.connect(_on_kut_changed)
	EventBus.espionage_mission_completed.connect(_on_espionage_mission_completed)
	EventBus.envoy_assassinated.connect(_on_envoy_assassinated)
	EventBus.kagan_glory_changed.connect(_on_kagan_glory_changed)
	EventBus.season_changed.connect(_on_season_changed)


func _exit_tree() -> void:
	CommandBus.unregister_handler(EvaluateDiplomacyCommand.ID, _handle_evaluate_diplomacy)


static func _safe_float(val: float, fallback: float, min_val: float = -INF, max_val: float = INF) -> float:
	if is_nan(val) or is_inf(val):
		return fallback
	return clampf(val, min_val, max_val)


## Computes and records the attitude (`ALLY`, `NEUTRAL`, `THREATENING`, `HOSTILE`)
## of `dynasty_id` given `player_kut`, `player_army_size`, and `raid_frequency`.
func calculate_dynasty_stance(dynasty_id: StringName, player_kut: float, player_army_size: float, raid_frequency: float) -> GameEnums.DynastyAttitude:
	var profile: DynastyProfile = _profiles.get(dynasty_id, null)
	if profile == null:
		return GameEnums.DynastyAttitude.NEUTRAL
	var safe_kut: float = _safe_float(player_kut, 50.0, 0.0, 100.0)
	var safe_army: float = _safe_float(player_army_size, 1000.0, 0.0, 10000000.0)
	var safe_raids: float = _safe_float(raid_frequency, 0.0, 0.0, 100.0)
	var current_trust: float = _trust_scores.get(dynasty_id, profile.trust_index)
	var previous: GameEnums.DynastyAttitude = _stances.get(dynasty_id, GameEnums.DynastyAttitude.NEUTRAL)
	var next_stance: GameEnums.DynastyAttitude = profile.calculate_dynasty_stance(
		safe_kut, safe_army, safe_raids, current_trust)
	_stances[dynasty_id] = next_stance
	if previous != next_stance:
		EventBus.dynasty_stance_changed.emit(dynasty_id, previous, next_stance, current_trust)
	return next_stance


## Evaluates a dynasty's effective Threat Score and attitude modulated by active
## intelligence deterrence, exposed spies, envoy assassination infamy, and Khagan glory.
func evaluate_dynasty_with_intelligence_and_glory(dynasty_id: StringName, player_kut: float, player_army_size: float, raid_frequency: float, glory_score_override: float = -1.0) -> GameEnums.DynastyAttitude:
	var profile: DynastyProfile = _profiles.get(dynasty_id, null)
	if profile == null:
		return GameEnums.DynastyAttitude.NEUTRAL
	var safe_kut: float = _safe_float(player_kut, 50.0, 0.0, 100.0)
	var safe_army: float = _safe_float(player_army_size, 1000.0, 0.0, 10000000.0)
	var safe_raids: float = _safe_float(raid_frequency, 0.0, 0.0, 100.0)
	var current_trust: float = _trust_scores.get(dynasty_id, profile.trust_index)
	var base_threat: float = profile.calculate_threat_score(safe_kut, safe_army, safe_raids, current_trust)
	var safe_glory_ovr: float = _safe_float(glory_score_override, -1.0, -1.0, 100.0)
	var active_glory: float = safe_glory_ovr if safe_glory_ovr >= 0.0 else _tracked_kagan_glory
	var glory_deterrence: float = clampf((active_glory - 30.0) * 0.45, 0.0, 26.0)
	var effective_threat: float = clampf(
		base_threat - _espionage_deterrence_bonus - glory_deterrence + _spy_exposure_penalty + _recent_assassination_infamy,
		0.0, 100.0)
	if effective_threat <= profile.ally_threshold:
		return GameEnums.DynastyAttitude.ALLY
	if effective_threat <= profile.neutral_threshold:
		return GameEnums.DynastyAttitude.NEUTRAL
	if effective_threat <= profile.threatening_threshold:
		return GameEnums.DynastyAttitude.THREATENING
	return GameEnums.DynastyAttitude.HOSTILE


## Evaluates full coalition warfare likelihood while factoring intelligence advantage
## and Khagan glory deterrence (`glory >= 40` can deter low-Kut coalition war).
func evaluate_coalition_with_political_context(player_kut: float, player_army_size: float, raid_frequency: float, glory_score_override: float = -1.0) -> Dictionary[StringName, float]:
	var safe_kut: float = _safe_float(player_kut, 50.0, 0.0, 100.0)
	var safe_army: float = _safe_float(player_army_size, 1000.0, 0.0, 10000000.0)
	var safe_raids: float = _safe_float(raid_frequency, 0.0, 0.0, 100.0)
	var safe_glory_ovr: float = _safe_float(glory_score_override, -1.0, -1.0, 100.0)
	var active_glory: float = safe_glory_ovr if safe_glory_ovr >= 0.0 else _tracked_kagan_glory
	var hostile_count: int = 0
	var max_effective_threat: float = 0.0
	for dynasty_id: StringName in _profiles:
		var profile: DynastyProfile = _profiles[dynasty_id]
		var current_trust: float = _trust_scores.get(dynasty_id, profile.trust_index)
		var base_threat: float = profile.calculate_threat_score(safe_kut, safe_army, safe_raids, current_trust)
		var glory_det: float = clampf((active_glory - 30.0) * 0.45, 0.0, 26.0)
		var eff_threat: float = clampf(
			base_threat - _espionage_deterrence_bonus - glory_det + _spy_exposure_penalty + _recent_assassination_infamy,
			0.0, 100.0)
		max_effective_threat = maxf(max_effective_threat, eff_threat)
		if eff_threat > profile.neutral_threshold and profile.ambition >= 0.50:
			hostile_count += 1
	var raw_coalition_window: bool = safe_kut < 30.0 and hostile_count > 0
	var deterred: bool = safe_kut < 30.0 and hostile_count == 0
	return {
		&"coalition_active": 1.0 if raw_coalition_window else 0.0,
		&"coalition_deterred": 1.0 if deterred else 0.0,
		&"hostile_member_count": float(hostile_count),
		&"max_effective_threat": max_effective_threat,
		&"espionage_deterrence": _espionage_deterrence_bonus,
		&"assassination_infamy": _recent_assassination_infamy,
	}


## Sets or resets political intelligence & glory modifiers for scenario evaluation.
func set_political_intelligence_context(espionage_deterrence: float, spy_exposure: float, assassination_infamy: float, kagan_glory: float) -> void:
	_espionage_deterrence_bonus = _safe_float(espionage_deterrence, _espionage_deterrence_bonus, 0.0, 30.0)
	_spy_exposure_penalty = _safe_float(spy_exposure, _spy_exposure_penalty, 0.0, 30.0)
	_recent_assassination_infamy = _safe_float(assassination_infamy, _recent_assassination_infamy, 0.0, 45.0)
	_tracked_kagan_glory = _safe_float(kagan_glory, _tracked_kagan_glory, 0.0, 100.0)


## Adds an external diplomatic threat/infamy spike (e.g. Kan Davası envoy killing
## or Sacred Kurgan hegemon proclamation) and triggers a Coalition check when warranted.
func add_diplomatic_infamy_spike(boost: float, force_coalition_evaluation: bool = false) -> bool:
	var safe_boost: float = _safe_float(boost, 0.0, 0.0, 60.0)
	_recent_assassination_infamy = clampf(_recent_assassination_infamy + safe_boost, 0.0, 60.0)
	if force_coalition_evaluation:
		var was_active: bool = _coalition_war_active
		var members: PackedStringArray = PackedStringArray()
		for dynasty_id: StringName in _profiles:
			var profile: DynastyProfile = _profiles[dynasty_id]
			var current_trust: float = _trust_scores.get(dynasty_id, profile.trust_index)
			var base_threat: float = profile.calculate_threat_score(GameManager.get_kut_score(), _player_army_size, _raid_frequency, current_trust)
			if base_threat + _recent_assassination_infamy > profile.neutral_threshold and profile.ambition >= 0.50:
				members.append(String(dynasty_id))
				_stances[dynasty_id] = GameEnums.DynastyAttitude.HOSTILE
		if not members.is_empty():
			_coalition_war_active = true
			_coalition_members = members
			if not was_active:
				EventBus.coalition_war_declared.emit(_coalition_members, GameManager.get_kut_score())
			return true
	return false


func get_espionage_deterrence_bonus() -> float:
	return _espionage_deterrence_bonus


func get_spy_exposure_penalty() -> float:
	return _spy_exposure_penalty


func get_recent_assassination_infamy() -> float:
	return _recent_assassination_infamy


## Gradually cools temporary diplomatic infamy, spy exposure penalty, and aging
## intelligence deterrence across seasonal cycles, and slowly thaws depressed
## dynasty trust during peaceful high-Kut low-raid seasons.
func step_seasonal_diplomatic_decay(cycles: int = 1) -> void:
	var n: float = float(maxi(cycles, 1))
	_recent_assassination_infamy = maxf(_recent_assassination_infamy - 6.0 * n, 0.0)
	_spy_exposure_penalty = maxf(_spy_exposure_penalty - 4.0 * n, 0.0)
	_espionage_deterrence_bonus = maxf(_espionage_deterrence_bonus - 3.0 * n, 0.0)
	if not _coalition_war_active and GameManager.get_kut_score() >= 50.0 and _raid_frequency <= 0.5:
		for dynasty_id: StringName in _profiles:
			var profile: DynastyProfile = _profiles[dynasty_id]
			var current_trust: float = _trust_scores.get(dynasty_id, profile.trust_index)
			if current_trust < profile.trust_index:
				_trust_scores[dynasty_id] = minf(current_trust + 1.5 * n, profile.trust_index)


## Evaluates all rival dynasties and triggers `EventBus.coalition_war_declared`
## when `player_kut < 30.0` and ambitious neighbors unite against the weakened Khaganate.
func evaluate_all_dynasties(player_kut: float, player_army_size: float, raid_frequency: float) -> bool:
	var safe_kut: float = _safe_float(player_kut, GameManager.get_kut_score(), 0.0, 100.0)
	_player_army_size = _safe_float(player_army_size, _player_army_size, 0.0, 10000000.0)
	_raid_frequency = _safe_float(raid_frequency, _raid_frequency, 0.0, 100.0)
	var was_coalition_active: bool = _coalition_war_active
	var prev_members: PackedStringArray = _coalition_members
	var members: PackedStringArray = PackedStringArray()
	for dynasty_id: StringName in _profiles:
		var profile: DynastyProfile = _profiles[dynasty_id]
		var current_trust: float = _trust_scores.get(dynasty_id, profile.trust_index)
		calculate_dynasty_stance(dynasty_id, safe_kut, _player_army_size, _raid_frequency)
		var joins_by_kut: bool = profile.should_join_coalition(safe_kut, _player_army_size, _raid_frequency, current_trust)
		var joins_by_infamy: bool = false
		if _recent_assassination_infamy >= 20.0 and profile.ambition >= 0.50:
			var eff_threat: float = profile.calculate_threat_score(safe_kut, _player_army_size, _raid_frequency, current_trust) + _recent_assassination_infamy
			if eff_threat > profile.neutral_threshold:
				joins_by_infamy = true
				_stances[dynasty_id] = GameEnums.DynastyAttitude.HOSTILE
		if joins_by_kut or joins_by_infamy:
			members.append(String(dynasty_id))
	if not members.is_empty():
		_coalition_war_active = true
		_coalition_members = members
		if not was_coalition_active or members != prev_members:
			EventBus.coalition_war_declared.emit(_coalition_members, safe_kut)
		return true
	_coalition_war_active = false
	_coalition_members = PackedStringArray()
	return false


## Adjusts the Trust Index (`0..100`) of every rival dynasty by `delta_trust`
## and re-evaluates their stances against the current Khaganate state.
func modify_all_dynasty_trust(delta_trust: float) -> void:
	var safe_delta: float = _safe_float(delta_trust, 0.0, -100.0, 100.0)
	for dynasty_id: StringName in _profiles:
		var current_trust: float = _trust_scores.get(dynasty_id, _profiles[dynasty_id].trust_index)
		_trust_scores[dynasty_id] = clampf(current_trust + safe_delta, 0.0, 100.0)
	evaluate_all_dynasties(GameManager.get_kut_score(), _player_army_size, _raid_frequency)


## Sets the Trust Index (`0..100`) for a specific `dynasty_id`.
func set_dynasty_trust(dynasty_id: StringName, new_trust: float) -> void:
	if is_nan(new_trust) or is_inf(new_trust):
		return
	if _profiles.has(dynasty_id):
		_trust_scores[dynasty_id] = clampf(new_trust, 0.0, 100.0)


func get_dynasty_trust(dynasty_id: StringName) -> float:
	if _trust_scores.has(dynasty_id):
		return _trust_scores[dynasty_id]
	var profile: DynastyProfile = _profiles.get(dynasty_id, null)
	return profile.trust_index if profile != null else 50.0


func get_dynasty_stance(dynasty_id: StringName) -> GameEnums.DynastyAttitude:
	return _stances.get(dynasty_id, GameEnums.DynastyAttitude.NEUTRAL)


func get_dynasty_profile(dynasty_id: StringName) -> DynastyProfile:
	return _profiles.get(dynasty_id, null)


func is_coalition_war_active() -> bool:
	return _coalition_war_active


func get_active_coalition_members() -> PackedStringArray:
	return _coalition_members


func _handle_evaluate_diplomacy(command: GameCommand) -> bool:
	var eval_cmd: EvaluateDiplomacyCommand = command as EvaluateDiplomacyCommand
	if eval_cmd == null:
		return command.reject("Expected EvaluateDiplomacyCommand.")
	eval_cmd.coalition_triggered = evaluate_all_dynasties(
		eval_cmd.player_kut, eval_cmd.player_army_size, eval_cmd.raid_frequency)
	eval_cmd.stances = _stances.duplicate()
	eval_cmd.coalition_members = _coalition_members
	return true


func _load_profile(path: String) -> void:
	var profile: DynastyProfile = ResourceLoader.load(path) as DynastyProfile
	if profile == null:
		push_error("DiplomacyManager: failed to load DynastyProfile at %s." % path)
		return
	for err: String in profile.get_validation_errors():
		push_error("DiplomacyManager: %s" % err)
	_profiles[profile.dynasty_id] = profile
	_trust_scores[profile.dynasty_id] = profile.trust_index
	_stances[profile.dynasty_id] = GameEnums.DynastyAttitude.NEUTRAL


func _on_kut_changed(previous_kut: float, new_kut: float, _reason: StringName) -> void:
	if is_nan(new_kut) or is_inf(new_kut):
		return
	if new_kut < 30.0 or (previous_kut < 30.0 and new_kut >= 30.0):
		evaluate_all_dynasties(new_kut, _player_army_size, _raid_frequency)


func _on_espionage_mission_completed(report: EspionageReport) -> void:
	if report == null:
		return
	if report.succeeded:
		_espionage_deterrence_bonus = clampf(_espionage_deterrence_bonus + 8.0, 0.0, 24.0)
	elif report.spy_captured:
		_spy_exposure_penalty = clampf(_spy_exposure_penalty + 6.0, 0.0, 24.0)


func _on_envoy_assassinated(_instigator_id: int, _target_id: int, _envoy_id: StringName, _kut_gained: float) -> void:
	_recent_assassination_infamy = clampf(_recent_assassination_infamy + 18.0, 0.0, 40.0)


func _on_kagan_glory_changed(_army_id: int, _previous_glory: float, new_glory: float, _reason: StringName) -> void:
	_tracked_kagan_glory = _safe_float(new_glory, _tracked_kagan_glory, 0.0, 100.0)


func _on_season_changed(_season: SeasonData, _cycle_index: int) -> void:
	step_seasonal_diplomatic_decay(1)
