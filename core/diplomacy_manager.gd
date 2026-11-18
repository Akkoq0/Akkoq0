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


func _ready() -> void:
	_load_profile(DEFAULT_DYNASTY_PATH)
	_load_profile(KARLUK_PATH)
	_load_profile(KIPCHAK_PATH)
	_load_profile(OGHUZ_PATH)
	CommandBus.register_handler(EvaluateDiplomacyCommand.ID, _handle_evaluate_diplomacy)
	EventBus.kut_changed.connect(_on_kut_changed)


func _exit_tree() -> void:
	CommandBus.unregister_handler(EvaluateDiplomacyCommand.ID, _handle_evaluate_diplomacy)


## Computes and records the attitude (`ALLY`, `NEUTRAL`, `THREATENING`, `HOSTILE`)
## of `dynasty_id` given `player_kut`, `player_army_size`, and `raid_frequency`.
func calculate_dynasty_stance(dynasty_id: StringName, player_kut: float, player_army_size: float, raid_frequency: float) -> GameEnums.DynastyAttitude:
	var profile: DynastyProfile = _profiles.get(dynasty_id, null)
	if profile == null:
		return GameEnums.DynastyAttitude.NEUTRAL
	var current_trust: float = _trust_scores.get(dynasty_id, profile.trust_index)
	var previous: GameEnums.DynastyAttitude = _stances.get(dynasty_id, GameEnums.DynastyAttitude.NEUTRAL)
	var next_stance: GameEnums.DynastyAttitude = profile.calculate_dynasty_stance(
		player_kut, player_army_size, raid_frequency, current_trust)
	_stances[dynasty_id] = next_stance
	if previous != next_stance:
		EventBus.dynasty_stance_changed.emit(dynasty_id, previous, next_stance, current_trust)
	return next_stance


## Evaluates all rival dynasties and triggers `EventBus.coalition_war_declared`
## when `player_kut < 30.0` and ambitious neighbors unite against the weakened Khaganate.
func evaluate_all_dynasties(player_kut: float, player_army_size: float, raid_frequency: float) -> bool:
	_player_army_size = maxf(player_army_size, 0.0)
	_raid_frequency = maxf(raid_frequency, 0.0)
	var members: PackedStringArray = PackedStringArray()
	for dynasty_id: StringName in _profiles:
		var profile: DynastyProfile = _profiles[dynasty_id]
		var current_trust: float = _trust_scores.get(dynasty_id, profile.trust_index)
		calculate_dynasty_stance(dynasty_id, player_kut, _player_army_size, _raid_frequency)
		if profile.should_join_coalition(player_kut, _player_army_size, _raid_frequency, current_trust):
			members.append(String(dynasty_id))
	if not members.is_empty():
		_coalition_war_active = true
		_coalition_members = members
		EventBus.coalition_war_declared.emit(_coalition_members, player_kut)
		return true
	_coalition_war_active = false
	_coalition_members = PackedStringArray()
	return false


## Adjusts the Trust Index (`0..100`) of every rival dynasty by `delta_trust`
## and re-evaluates their stances against the current Khaganate state.
func modify_all_dynasty_trust(delta_trust: float) -> void:
	for dynasty_id: StringName in _profiles:
		var current_trust: float = _trust_scores.get(dynasty_id, _profiles[dynasty_id].trust_index)
		_trust_scores[dynasty_id] = clampf(current_trust + delta_trust, 0.0, 100.0)
	evaluate_all_dynasties(GameManager.get_kut_score(), _player_army_size, _raid_frequency)


## Sets the Trust Index (`0..100`) for a specific `dynasty_id`.
func set_dynasty_trust(dynasty_id: StringName, new_trust: float) -> void:
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


func _on_kut_changed(_previous_kut: float, new_kut: float, _reason: StringName) -> void:
	if new_kut < 30.0:
		evaluate_all_dynasties(new_kut, _player_army_size, _raid_frequency)
