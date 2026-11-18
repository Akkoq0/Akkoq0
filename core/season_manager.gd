extends Node
## Autoload `SeasonManager` (rank 2). Advances the steppe calendar while the
## game is PLAYING, tracks seasonal food reserves, triggers Zud (Winter)
## starvation ticks when Food <= 0 during Winter, and simulates Phase 4
## **Steppe Plague / Zud Epidemic (`outbreak_epidemic`)** and **Kurgan
## Purification Rituals (`PurifyEpidemicCommand`)**.

const SEASON_CYCLE_PATH: String = "res://data/seasons/season_cycle.tres"
const KUT_RULES_PATH: String = "res://data/governance/kut_rules.tres"
const REASON_KURGAN_PURIFICATION: StringName = &"kurgan_epidemic_purification"
const INFIRMARY_BUILDING_ID: StringName = &"sifahane"

var _cycle: SeasonCycle = null
var _kut_rules: KutRules = null
var _index: int = 0
var _elapsed_sec: float = 0.0
var _has_started: bool = false
var _food_reserve: int = 0
var _army_epidemic_states: Dictionary[int, GameEnums.EpidemicState] = {}
var _army_troop_counts: Dictionary[int, int] = {}


func _ready() -> void:
	set_process(false)
	_cycle = ResourceLoader.load(SEASON_CYCLE_PATH) as SeasonCycle
	if _cycle == null:
		push_error("SeasonManager: failed to load SeasonCycle at %s." % SEASON_CYCLE_PATH)
		return
	var errors: PackedStringArray = _cycle.get_validation_errors()
	for error: String in errors:
		push_error("SeasonManager: %s" % error)
	if not errors.is_empty():
		_cycle = null
		return
	_kut_rules = ResourceLoader.load(KUT_RULES_PATH) as KutRules
	if _kut_rules != null:
		_food_reserve = _kut_rules.starting_food_reserve
	_index = _cycle.starting_index
	EventBus.game_state_changed.connect(_on_game_state_changed)
	CommandBus.register_handler(PurifyEpidemicCommand.ID, _handle_purify_epidemic)


func _exit_tree() -> void:
	CommandBus.unregister_handler(PurifyEpidemicCommand.ID, _handle_purify_epidemic)


func _process(delta: float) -> void:
	var season: SeasonData = get_current_season()
	if season == null:
		return
	_elapsed_sec += delta
	if _elapsed_sec >= season.duration_sec:
		_elapsed_sec -= season.duration_sec
		_index = _cycle.get_next_index(_index)
		_broadcast()


## Active season (null until the cycle is loaded).
func get_current_season() -> SeasonData:
	if _cycle == null:
		return null
	return _cycle.get_season(_index)


## Normalised progress (0..1) through the active season.
func get_season_progress() -> float:
	var season: SeasonData = get_current_season()
	if season == null:
		return 0.0
	return clampf(_elapsed_sec / season.duration_sec, 0.0, 1.0)


## Current clan food reserve.
func get_food_reserve() -> int:
	return _food_reserve


## Sets the clan food reserve and evaluates Zud starvation if currently in Winter.
func set_food_reserve(amount: int) -> void:
	_food_reserve = maxi(amount, 0)
	var current: SeasonData = get_current_season()
	if current != null and current.season_type == GameEnums.SeasonType.WINTER and _food_reserve <= 0:
		EventBus.zud_starvation_ticked.emit(_food_reserve, current)


## Evaluates seasonal food consumption and Zud (Winter) starvation for `season`.
## Returns true when Zud starvation occurred (Food <= 0 during Winter).
func evaluate_zud_starvation(season: SeasonData) -> bool:
	if season == null or season.season_type != GameEnums.SeasonType.WINTER:
		return false
	if _kut_rules != null:
		_food_reserve = maxi(_food_reserve - _kut_rules.winter_food_consumption_per_cycle, 0)
	if _food_reserve <= 0:
		EventBus.zud_starvation_ticked.emit(_food_reserve, season)
		return true
	return false


## Probability (`0..1`) of a Bozkır Vebası (`outbreak_epidemic`) outbreak when Food <= 0 during Winter/Zud.
func get_epidemic_outbreak_chance(is_closed_camp: bool = true) -> float:
	if _kut_rules == null:
		return 0.0
	return _kut_rules.compute_epidemic_outbreak_chance(is_closed_camp)


## Evaluates whether a Zud starvation condition (`Food <= 0` in Winter and closed camp)
## triggers a steppe plague outbreak (`outbreak_epidemic`) on `target_army_id`.
func evaluate_zud_epidemic_outbreak(target_army_id: int, is_closed_camp: bool = true, rng_seed: int = 1, season_override: SeasonData = null) -> bool:
	if _kut_rules == null or target_army_id <= 0 or _food_reserve > 0:
		return false
	var active_season: SeasonData = season_override if season_override != null else get_current_season()
	if active_season != null and active_season.season_type != GameEnums.SeasonType.WINTER:
		return false
	var chance: float = _kut_rules.compute_epidemic_outbreak_chance(is_closed_camp)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = rng_seed
	if rng.randf() <= chance:
		_army_epidemic_states[target_army_id] = GameEnums.EpidemicState.OUTBREAK_EPIDEMIC
		EventBus.outbreak_epidemic_started.emit(
			target_army_id,
			_kut_rules.epidemic_speed_multiplier,
			_kut_rules.epidemic_daily_troop_attrition_ratio)
		return true
	return false


## True when `army_id` is currently suffering from an active `OUTBREAK_EPIDEMIC`.
func is_army_infected(army_id: int) -> bool:
	return _army_epidemic_states.get(army_id, GameEnums.EpidemicState.HEALTHY) == GameEnums.EpidemicState.OUTBREAK_EPIDEMIC


## Current `EpidemicState` of `army_id`.
func get_army_epidemic_state(army_id: int) -> GameEnums.EpidemicState:
	return _army_epidemic_states.get(army_id, GameEnums.EpidemicState.HEALTHY)


## Movement speed multiplier for `army_id` (`0.50` when infected by plague, `1.0` when healthy/purified).
func get_epidemic_speed_multiplier(army_id: int) -> float:
	if is_army_infected(army_id) and _kut_rules != null:
		return _kut_rules.epidemic_speed_multiplier
	return 1.0


## Simulates one day of plague troop attrition for `army_id`.
## Returns the remaining troop headcount after daily deaths.
func simulate_epidemic_day(army_id: int, current_troops: int) -> int:
	var clamped_troops: int = maxi(current_troops, 0)
	if not is_army_infected(army_id) or _kut_rules == null or clamped_troops <= 0:
		_army_troop_counts[army_id] = clamped_troops
		return clamped_troops
	var casualties: int = maxi(int(ceilf(float(clamped_troops) * _kut_rules.epidemic_daily_troop_attrition_ratio)), 1)
	var remaining: int = maxi(clamped_troops - casualties, 0)
	_army_troop_counts[army_id] = remaining
	EventBus.epidemic_daily_attrition_ticked.emit(army_id, remaining, casualties)
	return remaining


## Latest recorded troop headcount for `army_id`.
func get_army_troop_count(army_id: int) -> int:
	return _army_troop_counts.get(army_id, 0)


func _handle_purify_epidemic(command: GameCommand) -> bool:
	var purify: PurifyEpidemicCommand = command as PurifyEpidemicCommand
	if purify == null:
		return command.reject("Expected PurifyEpidemicCommand.")
	if _kut_rules == null:
		return command.reject("KutRules not loaded.")
	if purify.target_army_id <= 0:
		return command.reject("PurifyEpidemicCommand requires target_army_id > 0.")
	if purify.shrine_building_id != _kut_rules.kurgan_shrine_building_id \
			and purify.shrine_building_id != INFIRMARY_BUILDING_ID:
		return command.reject("Epidemic purification requires a Kurgan Shrine ('%s') or Infirmary ('%s')." % [
			_kut_rules.kurgan_shrine_building_id, INFIRMARY_BUILDING_ID])
	if not is_army_infected(purify.target_army_id):
		return command.reject("Target army %d is not infected by an epidemic." % purify.target_army_id)
	if GameManager.get_kut_score() < _kut_rules.kurgan_purification_kut_cost:
		return command.reject("Insufficient Kut for Kurgan epidemic purification ritual.")

	var kut_cmd: ModifyKutCommand = ModifyKutCommand.new(-_kut_rules.kurgan_purification_kut_cost, REASON_KURGAN_PURIFICATION)
	CommandBus.dispatch(kut_cmd)

	_army_epidemic_states[purify.target_army_id] = GameEnums.EpidemicState.PURIFIED
	purify.kut_spent = _kut_rules.kurgan_purification_kut_cost
	purify.purified = true
	purify.remaining_kut = GameManager.get_kut_score()

	EventBus.epidemic_purified_at_kurgan.emit(
		purify.target_army_id, purify.shrine_building_id, purify.kut_spent)
	return true


func _on_game_state_changed(_previous: GameEnums.GameState, new_state: GameEnums.GameState) -> void:
	var is_playing: bool = new_state == GameEnums.GameState.PLAYING
	set_process(is_playing and _cycle != null)
	if is_playing and not _has_started and _cycle != null:
		_has_started = true
		_broadcast()


func _broadcast() -> void:
	var season: SeasonData = get_current_season()
	if season != null:
		EventBus.season_changed.emit(season, _index)
		evaluate_zud_starvation(season)

