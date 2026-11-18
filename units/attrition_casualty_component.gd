class_name AttritionCasualtyComponent
extends Node

const DEFAULT_PROFILE_PATH: String = "res://data/units/default_attrition_casualty_profile.tres"

var army_id: int = 1
var profile: AttritionCasualtyProfile = null

var _active_troops: int = 200
var _wounded_pool: int = 0
var _permanent_dead: int = 0
var _veteran_ratio: float = 0.75
var _commander_fatigue: float = 0.0
var _raw_recruit_cohesion_penalty: float = 0.0


func _ready() -> void:
	_ensure_profile_loaded()


func _ensure_profile_loaded() -> void:
	if profile != null:
		return
	var loaded: Resource = ResourceLoader.load(DEFAULT_PROFILE_PATH)
	if loaded is AttritionCasualtyProfile:
		profile = loaded as AttritionCasualtyProfile
	else:
		profile = AttritionCasualtyProfile.new()


static func _sanitize_float(val: float, fallback: float) -> float:
	if is_nan(val) or is_inf(val):
		return fallback
	return val


func configure(p_army_id: int, initial_troops: int, initial_veteran_ratio: float, custom_profile: AttritionCasualtyProfile = null) -> void:
	if custom_profile != null:
		profile = custom_profile
	else:
		_ensure_profile_loaded()
	army_id = p_army_id
	_active_troops = maxi(1, initial_troops)
	_wounded_pool = 0
	_permanent_dead = 0
	_veteran_ratio = clampf(_sanitize_float(initial_veteran_ratio, 0.75), 0.0, 1.0)
	_commander_fatigue = 0.0
	_raw_recruit_cohesion_penalty = 0.0


func record_battle_casualties(total_fallen: int, veteran_casualty_bias: float = 1.25, commander_fatigue_added: float = 0.18) -> Dictionary:
	_ensure_profile_loaded()
	var actual_fallen: int = clampi(total_fallen, 0, _active_troops)
	if actual_fallen <= 0:
		return {
			"wounded_added": 0,
			"immediate_dead": 0,
			"wounded_pool": _wounded_pool,
			"active_troops": _active_troops
		}
	var safe_bias: float = _sanitize_float(veteran_casualty_bias, 1.25)
	var safe_fat_add: float = _sanitize_float(commander_fatigue_added, 0.18)
	var pre_troops: int = _active_troops
	var new_wounded: int = clampi(roundi(float(actual_fallen) * profile.wounded_survival_ratio), 0, actual_fallen)
	var immediate_dead: int = actual_fallen - new_wounded

	_active_troops = maxi(0, _active_troops - actual_fallen)
	_wounded_pool += new_wounded
	_permanent_dead += immediate_dead

	var casualty_fraction: float = float(actual_fallen) / float(maxi(1, pre_troops))
	var vet_drop: float = casualty_fraction * maxf(0.1, safe_bias) * 0.45
	var vet_floor: float = minf(_veteran_ratio, 0.05)
	_veteran_ratio = clampf(_veteran_ratio - vet_drop, vet_floor, 1.0)
	_commander_fatigue = clampf(_commander_fatigue + maxf(0.0, safe_fat_add), 0.0, 1.0)

	var speed_mult: float = get_wounded_speed_multiplier()
	var tac_mult: float = get_tactical_efficiency_multiplier()
	var cohesion_cap: float = get_effective_cohesion_cap()

	EventBus.battle_wounded_recorded.emit(army_id, new_wounded, _wounded_pool, speed_mult)
	EventBus.veteran_casualty_shock_applied.emit(army_id, _veteran_ratio, tac_mult, cohesion_cap)

	return {
		"wounded_added": new_wounded,
		"immediate_dead": immediate_dead,
		"wounded_pool": _wounded_pool,
		"active_troops": _active_troops
	}


func tick_wounded_treatment(has_healer_or_supply_support: bool) -> Dictionary:
	_ensure_profile_loaded()
	if _wounded_pool <= 0:
		return {
			"recovered": 0,
			"died_from_neglect": 0,
			"remaining_wounded": 0
		}
	var recovered: int = 0
	var died_from_neglect: int = 0
	if has_healer_or_supply_support:
		recovered = clampi(maxi(1, roundi(float(_wounded_pool) * profile.healer_recovery_ratio_per_tick)), 1, _wounded_pool)
		_wounded_pool -= recovered
		_active_troops += recovered
	else:
		died_from_neglect = clampi(maxi(1, roundi(float(_wounded_pool) * profile.neglect_mortality_ratio_per_tick)), 1, _wounded_pool)
		_wounded_pool -= died_from_neglect
		_permanent_dead += died_from_neglect

	EventBus.wounded_troops_recovered.emit(army_id, recovered, _wounded_pool)
	return {
		"recovered": recovered,
		"died_from_neglect": died_from_neglect,
		"remaining_wounded": _wounded_pool
	}


func reinforce_with_raw_recruits(recruit_count: int) -> void:
	_ensure_profile_loaded()
	var added: int = maxi(0, recruit_count)
	if added <= 0:
		return
	var current_veterans: float = float(_active_troops) * _veteran_ratio
	var new_total: int = _active_troops + added
	_veteran_ratio = clampf(current_veterans / float(maxi(1, new_total)), 0.0, 1.0)

	var recruit_share: float = float(added) / float(maxi(1, new_total))
	_raw_recruit_cohesion_penalty = clampf(
		_raw_recruit_cohesion_penalty + recruit_share * profile.raw_recruit_cohesion_cap_penalty_max,
		0.0,
		profile.raw_recruit_cohesion_cap_penalty_max
	)
	_active_troops = new_total

	EventBus.veteran_casualty_shock_applied.emit(
		army_id,
		_veteran_ratio,
		get_tactical_efficiency_multiplier(),
		get_effective_cohesion_cap()
	)


func tick_cohesion_acclimation(delta_sec: float) -> void:
	_ensure_profile_loaded()
	var dt: float = maxf(0.0, _sanitize_float(delta_sec, 0.0))
	_raw_recruit_cohesion_penalty = maxf(0.0, _raw_recruit_cohesion_penalty - profile.cohesion_acclimation_recovery_per_sec * dt)
	_commander_fatigue = maxf(0.0, _commander_fatigue - 0.02 * dt)


func get_active_troops() -> int:
	return _active_troops


func get_wounded_pool() -> int:
	return _wounded_pool


func get_permanent_dead() -> int:
	return _permanent_dead


func get_veteran_ratio() -> float:
	return _veteran_ratio


func get_commander_fatigue() -> float:
	return _commander_fatigue


func get_wounded_speed_multiplier() -> float:
	_ensure_profile_loaded()
	if _wounded_pool <= 0:
		return 1.0
	var burden_ratio: float = clampf(float(_wounded_pool) / float(maxi(1, _active_troops + _wounded_pool)), 0.0, 1.0)
	var penalty: float = clampf(burden_ratio * 1.4, 0.0, profile.max_wounded_speed_penalty)
	return clampf(1.0 - penalty, 1.0 - profile.max_wounded_speed_penalty, 1.0)


func get_tactical_efficiency_multiplier() -> float:
	_ensure_profile_loaded()
	var vet_deficit: float = clampf(1.0 - _veteran_ratio, 0.0, 1.0)
	var penalty: float = vet_deficit * profile.veteran_loss_tactical_penalty_weight + _commander_fatigue * profile.commander_fatigue_efficiency_penalty_weight
	return clampf(1.0 - penalty, 0.35, 1.15)


func get_morale_resistance_multiplier() -> float:
	_ensure_profile_loaded()
	var vet_deficit: float = clampf(1.0 - _veteran_ratio, 0.0, 1.0)
	var penalty: float = vet_deficit * profile.veteran_loss_morale_penalty_weight + _commander_fatigue * 0.15
	return clampf(1.0 - penalty, 0.40, 1.15)


func get_effective_cohesion_cap() -> float:
	_ensure_profile_loaded()
	return clampf(100.0 - _raw_recruit_cohesion_penalty, 45.0, 100.0)
