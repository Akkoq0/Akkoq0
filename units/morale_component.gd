class_name MoraleComponent
extends Node
## Units (rank 3). Phase 4 **Psychological Warfare, Battle Fatigue & Cascade
## Rout Dynamics (`cascade_rout`)** component.
##
## Responsibilities:
##  * Accumulates battle fatigue (`0..100`) per second of prolonged combat,
##    progressively degrading charge speed and lance impact momentum.
##  * Evaluates psychological shock when front-line elite units (e.g. Bozkurt
##    cavalry) are destroyed, triggering a chain panic (`cascade_rout`) across
##    rear rookie formations.

const DEFAULT_RULES_PATH: String = "res://data/combat/combat_rules.tres"

signal battle_fatigue_changed(new_fatigue: float, speed_mult: float, momentum_mult: float)
signal cascade_rout_started(army_id: int, destroyed_elite_unit_id: StringName, remaining_morale: float)

@export var rules: CombatRules
@export_range(0.0, 1.5, 0.05) var rookie_troop_ratio: float = 0.65

var _army_id: int = 1
var _current_morale: float = 100.0
var _current_cohesion: float = 100.0
var _battle_fatigue: float = 0.0
var _is_elite_vanguard_alive: bool = true
var _is_in_cascade_rout: bool = false
var _commander_rout_resistance: float = 0.0


func _ready() -> void:
	if rules == null:
		rules = ResourceLoader.load(DEFAULT_RULES_PATH) as CombatRules
	if not EventBus.water_crisis_inflicted.is_connected(_on_water_crisis_inflicted):
		EventBus.water_crisis_inflicted.connect(_on_water_crisis_inflicted)
	if not EventBus.commander_fallen_in_battle.is_connected(_on_commander_fallen_in_battle):
		EventBus.commander_fallen_in_battle.connect(_on_commander_fallen_in_battle)


func _exit_tree() -> void:
	if EventBus.water_crisis_inflicted.is_connected(_on_water_crisis_inflicted):
		EventBus.water_crisis_inflicted.disconnect(_on_water_crisis_inflicted)
	if EventBus.commander_fallen_in_battle.is_connected(_on_commander_fallen_in_battle):
		EventBus.commander_fallen_in_battle.disconnect(_on_commander_fallen_in_battle)


## Configures the component for `p_army_id` and resets morale/fatigue state.
func configure(p_army_id: int, p_rules: CombatRules = null) -> void:
	_army_id = p_army_id
	if p_rules != null:
		rules = p_rules
	elif rules == null:
		rules = ResourceLoader.load(DEFAULT_RULES_PATH) as CombatRules
	_current_morale = 100.0
	_current_cohesion = 100.0
	_battle_fatigue = 0.0
	_is_elite_vanguard_alive = true
	_is_in_cascade_rout = false
	_commander_rout_resistance = 0.0


static func _safe_float(val: float, fallback: float) -> float:
	if is_nan(val) or is_inf(val):
		return fallback
	return val


## Accumulates battle fatigue over `combat_duration_sec` seconds of combat.
## Returns the updated fatigue score (`0..100`).
func accumulate_battle_fatigue(combat_duration_sec: float) -> float:
	var dt: float = _safe_float(combat_duration_sec, 0.0)
	if rules == null or dt <= 0.0:
		return _battle_fatigue
	_battle_fatigue = clampf(_battle_fatigue + dt * rules.fatigue_accumulation_per_sec, 0.0, 100.0)
	battle_fatigue_changed.emit(_battle_fatigue, get_fatigue_speed_multiplier(), get_fatigue_momentum_multiplier())
	if _is_staggered_hold and not _is_in_cascade_rout and _battle_fatigue >= 85.0:
		_is_staggered_hold = false
		_is_in_cascade_rout = true
		cascade_rout_started.emit(_army_id, &"extreme_fatigue_collapse", _current_morale)
		EventBus.cascade_rout_triggered.emit(_army_id, &"extreme_fatigue_collapse", _current_morale)
	return _battle_fatigue


## Phase 21 Heavy Armor vs Light Horse-Archer terrain & weather fatigue physics.
## Iron/Steel heavy cavalry suffer exponential fatigue spikes in mud, steep slopes,
## and storms (`pow(compound_factor, 1.35)`), while light riders remain agile (`0.65x`).
func accumulate_armored_terrain_fatigue(
		duration_sec: float,
		is_heavy_armor: bool,
		is_mud: bool = false,
		is_steep_slope: bool = false,
		is_storm: bool = false,
		armor_mass_ratio: float = 1.0,
		logistics_rules: CourierAndCaravanRules = null) -> float:
	var dt: float = maxf(_safe_float(duration_sec, 0.0), 0.0)
	if rules == null or dt <= 0.0:
		return _battle_fatigue
	var mud_m: float = logistics_rules.heavy_armor_mud_fatigue_mult if logistics_rules != null else 2.10
	var slope_m: float = logistics_rules.heavy_armor_slope_fatigue_mult if logistics_rules != null else 1.90
	var storm_m: float = logistics_rules.heavy_armor_storm_fatigue_mult if logistics_rules != null else 1.75
	var exp_pow: float = logistics_rules.heavy_armor_exponential_power if logistics_rules != null else 1.35
	var light_res: float = logistics_rules.light_cavalry_terrain_resilience if logistics_rules != null else 0.65

	var compound: float = 1.0
	if is_mud:
		compound *= (mud_m if is_heavy_armor else 1.15)
	if is_steep_slope:
		compound *= (slope_m if is_heavy_armor else 1.12)
	if is_storm:
		compound *= (storm_m if is_heavy_armor else 1.10)

	var armor_factor: float = pow(compound, exp_pow) * clampf(_safe_float(armor_mass_ratio, 1.0), 0.75, 1.50) if is_heavy_armor else compound * light_res
	var delta_fatigue: float = dt * rules.fatigue_accumulation_per_sec * armor_factor
	_battle_fatigue = clampf(_battle_fatigue + delta_fatigue, 0.0, 100.0)
	battle_fatigue_changed.emit(_battle_fatigue, get_fatigue_speed_multiplier(), get_fatigue_momentum_multiplier())
	return _battle_fatigue


## Current charge speed multiplier after battle fatigue degradation (`0.55..1.0`).
func get_fatigue_speed_multiplier() -> float:
	if rules == null:
		return 1.0
	return rules.compute_fatigue_speed_multiplier(_battle_fatigue)


## Current lance impact momentum multiplier after battle fatigue degradation (`0.50..1.0`).
func get_fatigue_momentum_multiplier() -> float:
	if rules == null:
		return 1.0
	return rules.compute_fatigue_momentum_multiplier(_battle_fatigue)


## Effective charge speed for `base_charge_speed` after battle fatigue penalty.
func get_effective_charge_speed(base_charge_speed: float) -> float:
	return maxf(_safe_float(base_charge_speed, 0.0), 0.0) * get_fatigue_speed_multiplier()


## Effective lance charge momentum for `base_momentum` after battle fatigue penalty.
func get_effective_charge_momentum(base_momentum: float) -> float:
	return maxf(_safe_float(base_momentum, 0.0), 0.0) * get_fatigue_momentum_multiplier()


## Notifies that front-line elite vanguard troops (e.g. `bozkurt_cavalry`) were
## wiped out, triggering a chain panic wave (`cascade_rout`) among rear rookies.
## Idempotent while vanguard remains destroyed.
func notify_elite_vanguard_destroyed(elite_unit_id: StringName = &"bozkurt_cavalry") -> bool:
	if rules == null:
		return false
	if not _is_elite_vanguard_alive:
		return _is_in_cascade_rout
	_is_elite_vanguard_alive = false
	var morale_shock: float = rules.elite_vanguard_loss_morale_shock * clampf(rookie_troop_ratio, 0.2, 1.5)
	_current_morale = clampf(_current_morale - morale_shock, 0.0, 100.0)
	_current_cohesion = clampf(_current_cohesion - rules.elite_vanguard_loss_cohesion_shock, 0.0, 100.0)
	_is_in_cascade_rout = true
	_is_staggered_hold = false
	cascade_rout_started.emit(_army_id, elite_unit_id, _current_morale)
	EventBus.cascade_rout_triggered.emit(_army_id, elite_unit_id, _current_morale)
	return _is_in_cascade_rout


func get_battle_fatigue() -> float:
	return _battle_fatigue


func get_current_morale() -> float:
	return _current_morale


func get_current_cohesion() -> float:
	return _current_cohesion


func is_elite_vanguard_alive() -> bool:
	return _is_elite_vanguard_alive


func is_cascade_routing() -> bool:
	return _is_in_cascade_rout


var _veteran_experience_ratio: float = 0.35
var _commander_leadership_score: float = 50.0
var _is_staggered_hold: bool = false


## Configures unit veteran experience (`0..1`) and commander leadership (`0..100`)
## for layered psychological shock absorption.
func configure_veteran_and_commander_profile(p_veteran_ratio: float, p_commander_leadership: float, p_initial_morale: float = 75.0, p_initial_cohesion: float = 70.0) -> void:
	_veteran_experience_ratio = clampf(_safe_float(p_veteran_ratio, 0.35), 0.0, 1.0)
	rookie_troop_ratio = clampf(1.0 - _veteran_experience_ratio, 0.05, 1.0)
	_commander_leadership_score = clampf(_safe_float(p_commander_leadership, 50.0), 0.0, 100.0)
	_current_morale = clampf(_safe_float(p_initial_morale, 75.0), 0.0, 100.0)
	_current_cohesion = clampf(_safe_float(p_initial_cohesion, 70.0), 0.0, 100.0)
	_is_elite_vanguard_alive = true
	_is_in_cascade_rout = false
	_is_staggered_hold = false


func is_in_staggered_hold() -> bool:
	return _is_staggered_hold


## Evaluates front-line elite vanguard loss with layered veteran experience,
## formation cohesion, commander leadership damping, and battle fatigue amplification.
## Experienced formations led by strong commanders absorb the shock into a
## `staggered_hold` (`1.0x` front defense), whereas fatigued or rookie formations
## shatter into a `cascade_rout` (`2.1x` rear strike + Toy prisoner capture).
## Idempotent if vanguard is already destroyed until restored.
func evaluate_layered_vanguard_loss_shock(elite_unit_id: StringName = &"bozkurt_cavalry", targeted_health: float = 200.0) -> Dictionary[StringName, float]:
	var out: Dictionary[StringName, float] = {
		&"morale_shock": 0.0,
		&"cohesion_shock": 0.0,
		&"remaining_morale": _current_morale,
		&"remaining_cohesion": _current_cohesion,
		&"rear_strike_multiplier": 1.0,
		&"captured_slave_workers": 0.0,
	}
	if rules == null:
		return out
	if not _is_elite_vanguard_alive:
		out[&"rear_strike_multiplier"] = rules.rear_damage_multiplier if _is_in_cascade_rout else rules.front_damage_multiplier
		return out
	_is_elite_vanguard_alive = false
	var safe_hp: float = maxf(_safe_float(targeted_health, 0.0), 0.0)
	var base_damping: float = clampf(1.0 - _veteran_experience_ratio * 0.45 - (_commander_leadership_score / 100.0) * 0.30 + (_battle_fatigue / 100.0) * 0.55, 0.25, 1.65)
	var damping: float = clampf(base_damping * (1.0 - _commander_rout_resistance), 0.20, 1.65)
	var morale_shock: float = rules.elite_vanguard_loss_morale_shock * damping
	var cohesion_shock: float = rules.elite_vanguard_loss_cohesion_shock * damping
	_current_morale = clampf(_current_morale - morale_shock, 0.0, 100.0)
	_current_cohesion = clampf(_current_cohesion - cohesion_shock, 0.0, 100.0)

	if _current_morale < rules.rout_morale_threshold or _current_cohesion < rules.rout_cohesion_threshold or _battle_fatigue >= 65.0:
		_is_in_cascade_rout = true
		_is_staggered_hold = false
		out[&"rear_strike_multiplier"] = rules.rear_damage_multiplier
		out[&"captured_slave_workers"] = float(maxi(int(roundf(safe_hp * rules.slave_capture_per_routed_health)), 1)) if safe_hp > 0.0 else 0.0
		cascade_rout_started.emit(_army_id, elite_unit_id, _current_morale)
		EventBus.cascade_rout_triggered.emit(_army_id, elite_unit_id, _current_morale)
	else:
		_is_in_cascade_rout = false
		_is_staggered_hold = true
		out[&"rear_strike_multiplier"] = rules.front_damage_multiplier
		out[&"captured_slave_workers"] = 0.0

	out[&"morale_shock"] = morale_shock
	out[&"cohesion_shock"] = cohesion_shock
	out[&"remaining_morale"] = _current_morale
	out[&"remaining_cohesion"] = _current_cohesion
	return out


## Restores the destroyed front-line elite vanguard after reinforcement at camp.
func restore_elite_vanguard() -> void:
	_is_elite_vanguard_alive = true
	_is_in_cascade_rout = false
	_is_staggered_hold = false


## Recovers battle fatigue and rallies morale/cohesion when resting out of combat
## with supply support (`supply_ratio`). Starving armies (`supply_ratio <= 0.0`)
## rest off light muscle fatigue but cannot rally morale or clear `cascade_rout`.
func recover_fatigue_and_rally(rest_sec: float, supply_ratio: float) -> float:
	var dt: float = maxf(_safe_float(rest_sec, 0.0), 0.0)
	var raw_sup: float = clampf(_safe_float(supply_ratio, 0.0), 0.0, 1.0)
	var commander_bonus: float = 1.0 + (_commander_leadership_score / 100.0) * 0.40
	if raw_sup <= 0.0:
		_battle_fatigue = maxf(_battle_fatigue - dt * 1.2 * commander_bonus, 0.0)
		return _battle_fatigue
	var sup: float = clampf(raw_sup, 0.1, 1.0)
	_battle_fatigue = maxf(_battle_fatigue - dt * 3.5 * sup * commander_bonus, 0.0)
	_current_morale = clampf(_current_morale + dt * 2.2 * sup * commander_bonus, 0.0, 100.0)
	_current_cohesion = clampf(_current_cohesion + dt * 2.5 * sup * commander_bonus, 0.0, 100.0)
	if _battle_fatigue < 35.0 and _current_morale >= 35.0:
		_is_staggered_hold = false
	if rules != null:
		var rally_morale: float = minf(rules.rout_morale_threshold + 15.0, 85.0)
		var rally_cohesion: float = minf(rules.rout_cohesion_threshold + 15.0, 85.0)
		if _current_morale >= rally_morale and _current_cohesion >= rally_cohesion and _battle_fatigue < 45.0:
			_is_in_cascade_rout = false
	elif _current_morale >= 45.0 and _current_cohesion >= 45.0 and _battle_fatigue < 45.0:
		_is_in_cascade_rout = false
	return _battle_fatigue


func set_commander_rout_resistance(resistance: float) -> void:
	_commander_rout_resistance = clampf(_safe_float(resistance, 0.0), 0.0, 0.55)


func get_commander_rout_resistance() -> float:
	return _commander_rout_resistance


func apply_commander_death_shock(morale_shock: float, cohesion_shock: float) -> void:
	var m_drop: float = maxf(_safe_float(morale_shock, 0.0), 0.0)
	var c_drop: float = maxf(_safe_float(cohesion_shock, 0.0), 0.0)
	_commander_rout_resistance = 0.0
	_current_morale = clampf(_current_morale - m_drop, 0.0, 100.0)
	_current_cohesion = clampf(_current_cohesion - c_drop, 0.0, 100.0)


func _on_water_crisis_inflicted(p_army_id: int, _coord: Vector2i, _remount_drain: float, morale_penalty: float, _is_zud_frozen: bool) -> void:
	if _army_id > 0 and p_army_id == _army_id and morale_penalty > 0.0:
		_current_morale = clampf(_current_morale - morale_penalty, 0.0, 100.0)


func _on_commander_fallen_in_battle(_commander_id: int, p_army_id: int, _player_id: int, morale_shock: float, cohesion_shock: float) -> void:
	if _army_id > 0 and p_army_id == _army_id:
		apply_commander_death_shock(morale_shock, cohesion_shock)
