extends Node
## Autoload `BallisticsEngine` (rank 2). Computes Phase 7 **Vectorial Steppe
## Wind & Atmospheric Arrow Ballistics** (`res://core/ballistics_engine.gd`).
##
## Responsibilities:
##  * Maintains the active 3D steppe `wind_vector`, ambient `temperature_celsius`,
##    and `is_pre_zud_storm` state.
##  * Computes vectorial dot-product alignment between archer fire direction and
##    wind vector:
##      - **Tailwind (`Arkadan Esen Rüzgar`):** `+25%` arrow range (`1.25x`),
##        elevated formation hit accuracy (`1.20x`), enhanced whistling terror.
##      - **Headwind / Crosswind Pre-Zud Storm (`Önden/Yandan Şiddetli Fırtına`):**
##        reduced arrow range (`0.70x`), weakened whistling arrow morale shock
##        (`0.60x`), and increased quiver (`Sadak`) ammo consumption (`1.35x`).

const BALLISTICS_RULES_PATH: String = "res://data/combat/ballistics_rules.tres"

var _rules: BallisticsRules = null
var _wind_vector: Vector3 = Vector3(0.0, 0.0, -6.0)
var _temperature_celsius: float = 14.0
var _is_pre_zud_storm: bool = false


func _ready() -> void:
	_rules = ResourceLoader.load(BALLISTICS_RULES_PATH) as BallisticsRules
	if _rules == null:
		push_error("BallisticsEngine: failed to load BallisticsRules at %s." % BALLISTICS_RULES_PATH)
	else:
		for err: String in _rules.get_validation_errors():
			push_error("BallisticsEngine: %s" % err)
	CommandBus.register_handler(EvaluateAtmosphericVolleyCommand.ID, _handle_evaluate_volley)


func _exit_tree() -> void:
	CommandBus.unregister_handler(EvaluateAtmosphericVolleyCommand.ID, _handle_evaluate_volley)


func get_rules() -> BallisticsRules:
	return _rules


func get_wind_vector() -> Vector3:
	return _wind_vector


func get_temperature_celsius() -> float:
	return _temperature_celsius


func is_pre_zud_storm_active() -> bool:
	return _is_pre_zud_storm


## Sets the active steppe wind vector, ambient temperature, and pre-Zud storm state.
func set_steppe_wind_weather(p_wind_vector: Vector3, p_temperature_celsius: float, p_is_pre_zud_storm: bool = false) -> void:
	_wind_vector = p_wind_vector
	_temperature_celsius = p_temperature_celsius
	_is_pre_zud_storm = p_is_pre_zud_storm
	var state: GameEnums.WindWeatherState = GameEnums.WindWeatherState.PRE_ZUD_GALE_STORM if _is_pre_zud_storm else GameEnums.WindWeatherState.CALM
	EventBus.wind_weather_changed.emit(_wind_vector, _temperature_celsius, state)


## Evaluates ballistic trajectory modifiers for a volley fired along `shot_direction`.
func evaluate_volley(shooter_id: int, shot_direction: Vector3) -> BallisticVolleyResult:
	var res: BallisticVolleyResult = BallisticVolleyResult.new()
	res.shooter_id = shooter_id
	var dir_norm: Vector3 = shot_direction.normalized() if shot_direction.length_squared() > 0.0001 else Vector3.FORWARD
	res.shot_direction = dir_norm
	res.wind_vector = _wind_vector
	res.temperature_celsius = _temperature_celsius

	if _rules == null:
		return res

	res.base_range_m = _rules.base_bow_range_m
	var wind_speed: float = _wind_vector.length()
	var wind_dir: Vector3 = (_wind_vector / wind_speed) if wind_speed > 0.0001 else Vector3.ZERO
	var alignment_dot: float = dir_norm.dot(wind_dir) if wind_speed > 0.0001 else 0.0
	res.wind_alignment_dot = alignment_dot

	var is_severe_head_or_cross_storm: bool = _is_pre_zud_storm or (
		wind_speed >= _rules.storm_wind_speed_threshold_m_per_sec
		and alignment_dot < _rules.tailwind_dot_threshold
	) or (
		_temperature_celsius <= _rules.pre_zud_freezing_temp_celsius
		and alignment_dot <= 0.0
		and wind_speed >= _rules.min_effective_wind_speed_m_per_sec
	)

	if is_severe_head_or_cross_storm:
		res.weather_state = GameEnums.WindWeatherState.PRE_ZUD_GALE_STORM
		res.range_multiplier = _rules.storm_range_multiplier
		res.accuracy_multiplier = _rules.storm_accuracy_multiplier
		res.whistling_morale_multiplier = _rules.storm_whistling_morale_multiplier
		res.ammo_consumption_multiplier = _rules.storm_ammo_consumption_multiplier
	elif wind_speed >= _rules.min_effective_wind_speed_m_per_sec and alignment_dot >= _rules.tailwind_dot_threshold:
		res.weather_state = GameEnums.WindWeatherState.TAILWIND_BREEZE
		res.range_multiplier = _rules.tailwind_range_multiplier
		res.accuracy_multiplier = _rules.tailwind_accuracy_multiplier
		res.whistling_morale_multiplier = _rules.tailwind_whistling_morale_multiplier
		res.ammo_consumption_multiplier = _rules.tailwind_ammo_consumption_multiplier
	else:
		res.weather_state = GameEnums.WindWeatherState.CALM
		res.range_multiplier = 1.0
		res.accuracy_multiplier = 1.0
		res.whistling_morale_multiplier = 1.0
		res.ammo_consumption_multiplier = 1.0

	res.effective_range_m = res.base_range_m * res.range_multiplier
	EventBus.atmospheric_volley_resolved.emit(
		shooter_id,
		res.range_multiplier,
		res.accuracy_multiplier,
		res.whistling_morale_multiplier,
		res.ammo_consumption_multiplier)
	return res


func _handle_evaluate_volley(command: GameCommand) -> bool:
	var volley_cmd: EvaluateAtmosphericVolleyCommand = command as EvaluateAtmosphericVolleyCommand
	if volley_cmd == null:
		return command.reject("Expected EvaluateAtmosphericVolleyCommand.")
	var res: BallisticVolleyResult = evaluate_volley(volley_cmd.shooter_id, volley_cmd.shot_direction)
	volley_cmd.result = res
	volley_cmd.effective_morale_shock = volley_cmd.base_morale_shock * res.whistling_morale_multiplier
	volley_cmd.effective_quiver_ammo_cost = volley_cmd.base_quiver_ammo_cost * res.ammo_consumption_multiplier
	return true
