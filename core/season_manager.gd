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
var _epidemic_unpurified_days: Dictionary[int, int] = {}
var _pasture_yield_multipliers: Dictionary[int, float] = {}


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


## Updates the active seasonal meat/milk pasture yield multiplier for `player_id`.
func set_pasture_yield_multiplier(player_id: int, multiplier: float) -> void:
	_pasture_yield_multipliers[player_id] = clampf(multiplier, 0.0, 2.0)


func get_pasture_yield_multiplier(player_id: int) -> float:
	return _pasture_yield_multipliers.get(player_id, 1.0)


## Produces seasonal food reserves from healthy livestock pastures in Spring/Summer/Autumn.
## Healthy pastures replenish ~101 Food across the three mild seasons against 60 Winter draw,
## allowing stabilized clans to sustain Sefer Arabası migrations and rebuild after Zud within 1-2 years,
## whereas overgrazed/starving pastures (`multiplier = 0.0`) yield 0 Food and trigger Zud famine.
func produce_seasonal_pasture_food(season: SeasonData, pasture_yield_multiplier: float = -1.0, max_reserve: int = 300) -> int:
	if season == null or season.season_type == GameEnums.SeasonType.WINTER:
		return 0
	var mult: float = pasture_yield_multiplier if pasture_yield_multiplier >= 0.0 else get_pasture_yield_multiplier(1)
	if mult <= 0.0:
		return 0
	var base_harvest: float = 28.0
	if season.season_type == GameEnums.SeasonType.SUMMER:
		base_harvest = 32.0
	elif season.season_type == GameEnums.SeasonType.AUTUMN:
		base_harvest = 28.0
	var produced: int = maxi(int(roundf(base_harvest * season.production_multiplier * mult)), 0)
	_food_reserve = mini(_food_reserve + produced, maxi(max_reserve, _food_reserve))
	return produced


## Advances one full season synchronously, broadcasting `season_changed`,
## harvesting mild-season pasture food, and evaluating Winter Zud starvation.
func advance_season_cycle(pasture_yield_multiplier: float = -1.0) -> SeasonData:
	if _cycle == null:
		return null
	_index = _cycle.get_next_index(_index)
	_broadcast(pasture_yield_multiplier)
	return get_current_season()


## Consumes up to `amount` Food rations for Sefer Arabası migration logistics. Returns actual Food spent.
func consume_food_for_migration(amount: int) -> int:
	if amount <= 0 or _food_reserve <= 0:
		return 0
	var spent: int = mini(amount, _food_reserve)
	_food_reserve -= spent
	return spent


## Applies Phase 18 food spoilage/rot safely without double-emitting Zud signals.
func apply_food_spoilage(amount: int) -> int:
	if amount <= 0 or _food_reserve <= 0:
		return 0
	var spoiled: int = mini(amount, _food_reserve)
	_food_reserve -= spoiled
	return spoiled


## Sets the clan food reserve strictly without double-emitting Zud starvation events.
func set_food_reserve(amount: int) -> void:
	_food_reserve = maxi(amount, 0)


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


## Probability (`0..1`) of a Bozkır Vebası (`outbreak_epidemic`) when Food <= 0 during Winter/Zud.
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
## Returns the remaining troop headcount after daily deaths and clears plague state if 0 remain.
func simulate_epidemic_day(army_id: int, current_troops: int) -> int:
	var clamped_troops: int = maxi(current_troops, 0)
	if clamped_troops <= 0:
		_army_troop_counts[army_id] = 0
		_clear_dead_army_epidemic(army_id)
		return 0
	if not is_army_infected(army_id) or _kut_rules == null:
		_army_troop_counts[army_id] = clamped_troops
		return clamped_troops
	var casualties: int = maxi(int(ceilf(float(clamped_troops) * _kut_rules.epidemic_daily_troop_attrition_ratio)), 1)
	var remaining: int = maxi(clamped_troops - casualties, 0)
	_army_troop_counts[army_id] = remaining
	EventBus.epidemic_daily_attrition_ticked.emit(army_id, remaining, casualties)
	if remaining <= 0:
		_clear_dead_army_epidemic(army_id)
	return remaining


## Latest recorded troop headcount for `army_id`.
func get_army_troop_count(army_id: int) -> int:
	return _army_troop_counts.get(army_id, 0)


## Effective Kut cost to perform a Kurgan / Şifahane purification ritual for `army_id`.
## Neglecting an active outbreak increases ritual Kut cost (`+3.0` per unpurified day, max `30.0`).
func get_effective_purification_kut_cost(army_id: int) -> float:
	if _kut_rules == null:
		return 12.0
	var days: int = _epidemic_unpurified_days.get(army_id, 0)
	return clampf(_kut_rules.kurgan_purification_kut_cost + float(days) * 3.0, _kut_rules.kurgan_purification_kut_cost, 30.0)


func get_epidemic_unpurified_days(army_id: int) -> int:
	return _epidemic_unpurified_days.get(army_id, 0)


## Evaluates daily Zud epidemic contagion and food ration mitigation trade-offs:
##  * Allocating `extra_ration_allocated >= 20` medicinal food rations (when food suffices)
##    consumes food, halves daily troop attrition (`0.04`), and blocks contagion spread.
##  * Withholding rations increments unpurified outbreak duration, infects living `nearby_army_id`,
##    and escalates future Kurgan purification `Kut` cost.
func evaluate_epidemic_contagion_and_ration_strain(army_id: int, nearby_army_id: int, extra_ration_allocated: int, current_troops: int = 200) -> Dictionary[StringName, float]:
	var clamped_troops: int = maxi(current_troops, 0)
	if clamped_troops <= 0:
		_army_troop_counts[army_id] = 0
		_clear_dead_army_epidemic(army_id)
	var metrics: Dictionary[StringName, float] = {
		&"food_consumed": 0.0,
		&"effective_attrition_ratio": 0.0,
		&"remaining_troops": float(clamped_troops),
		&"nearby_infected": 0.0,
		&"next_purification_kut_cost": get_effective_purification_kut_cost(army_id),
		&"unpurified_days": float(get_epidemic_unpurified_days(army_id)),
	}
	if not is_army_infected(army_id) or _kut_rules == null or clamped_troops <= 0:
		_army_troop_counts[army_id] = clamped_troops
		return metrics

	var attrition_ratio: float = _kut_rules.epidemic_daily_troop_attrition_ratio
	if extra_ration_allocated >= 20 and _food_reserve >= 20:
		var consumed: int = mini(extra_ration_allocated, _food_reserve)
		_food_reserve -= consumed
		attrition_ratio *= 0.5
		metrics[&"food_consumed"] = float(consumed)
	else:
		var next_days: int = _epidemic_unpurified_days.get(army_id, 0) + 1
		_epidemic_unpurified_days[army_id] = next_days
		attrition_ratio = minf(attrition_ratio + float(mini(next_days, 4)) * 0.01, 0.20)
		var nearby_alive: bool = not _army_troop_counts.has(nearby_army_id) or _army_troop_counts[nearby_army_id] > 0
		if nearby_army_id > 0 and nearby_army_id != army_id and nearby_alive and not is_army_infected(nearby_army_id):
			_army_epidemic_states[nearby_army_id] = GameEnums.EpidemicState.OUTBREAK_EPIDEMIC
			EventBus.outbreak_epidemic_started.emit(
				nearby_army_id,
				_kut_rules.epidemic_speed_multiplier,
				_kut_rules.epidemic_daily_troop_attrition_ratio)
			metrics[&"nearby_infected"] = 1.0

	var casualties: int = maxi(int(ceilf(float(clamped_troops) * attrition_ratio)), 1)
	var remaining: int = maxi(clamped_troops - casualties, 0)
	_army_troop_counts[army_id] = remaining
	EventBus.epidemic_daily_attrition_ticked.emit(army_id, remaining, casualties)
	if remaining <= 0:
		_clear_dead_army_epidemic(army_id)

	metrics[&"effective_attrition_ratio"] = attrition_ratio
	metrics[&"remaining_troops"] = float(remaining)
	metrics[&"next_purification_kut_cost"] = get_effective_purification_kut_cost(army_id)
	metrics[&"unpurified_days"] = float(get_epidemic_unpurified_days(army_id))
	return metrics


func _clear_dead_army_epidemic(army_id: int) -> void:
	_army_epidemic_states[army_id] = GameEnums.EpidemicState.HEALTHY
	_epidemic_unpurified_days[army_id] = 0


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
	var effective_kut_cost: float = get_effective_purification_kut_cost(purify.target_army_id)
	if GameManager.get_kut_score() < effective_kut_cost:
		return command.reject("Insufficient Kut for Kurgan epidemic purification ritual.")

	var kut_cmd: ModifyKutCommand = ModifyKutCommand.new(-effective_kut_cost, REASON_KURGAN_PURIFICATION)
	CommandBus.dispatch(kut_cmd)

	_army_epidemic_states[purify.target_army_id] = GameEnums.EpidemicState.PURIFIED
	_epidemic_unpurified_days[purify.target_army_id] = 0
	purify.kut_spent = effective_kut_cost
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


func _broadcast(pasture_yield_multiplier: float = -1.0) -> void:
	var season: SeasonData = get_current_season()
	if season != null:
		var eff_yield: float = pasture_yield_multiplier if pasture_yield_multiplier >= 0.0 else get_pasture_yield_multiplier(1)
		produce_seasonal_pasture_food(season, pasture_yield_multiplier)
		EventBus.season_changed.emit(season, _index)
		evaluate_zud_starvation(season)
		if _kut_rules != null and season.season_type != GameEnums.SeasonType.WINTER \
				and eff_yield >= 1.0 and _food_reserve >= _kut_rules.prosperity_food_surplus_threshold:
			var current_kut: float = GameManager.get_kut_score()
			if current_kut < _kut_rules.initial_kut:
				var delta_kut: float = minf(_kut_rules.benign_pasture_prosperity_kut_recovery, _kut_rules.initial_kut - current_kut)
				if delta_kut > 0.0:
					CommandBus.dispatch(ModifyKutCommand.new(delta_kut, &"seasonal_pasture_prosperity"))

