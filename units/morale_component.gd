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


func _ready() -> void:
	if rules == null:
		rules = ResourceLoader.load(DEFAULT_RULES_PATH) as CombatRules


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


## Accumulates battle fatigue over `combat_duration_sec` seconds of combat.
## Returns the updated fatigue score (`0..100`).
func accumulate_battle_fatigue(combat_duration_sec: float) -> float:
	if rules == null or combat_duration_sec <= 0.0:
		return _battle_fatigue
	_battle_fatigue = clampf(_battle_fatigue + combat_duration_sec * rules.fatigue_accumulation_per_sec, 0.0, 100.0)
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
	return maxf(base_charge_speed, 0.0) * get_fatigue_speed_multiplier()


## Effective lance charge momentum for `base_momentum` after battle fatigue penalty.
func get_effective_charge_momentum(base_momentum: float) -> float:
	return maxf(base_momentum, 0.0) * get_fatigue_momentum_multiplier()


## Notifies that front-line elite vanguard troops (e.g. `bozkurt_cavalry`) were
## wiped out, triggering a chain panic wave (`cascade_rout`) among rear rookies.
func notify_elite_vanguard_destroyed(elite_unit_id: StringName = &"bozkurt_cavalry") -> bool:
	if rules == null:
		return false
	_is_elite_vanguard_alive = false
	var morale_shock: float = rules.elite_vanguard_loss_morale_shock * clampf(rookie_troop_ratio, 0.2, 1.5)
	_current_morale = clampf(_current_morale - morale_shock, 0.0, 100.0)
	_current_cohesion = clampf(_current_cohesion - rules.elite_vanguard_loss_cohesion_shock, 0.0, 100.0)
	_is_in_cascade_rout = true
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
	_veteran_experience_ratio = clampf(p_veteran_ratio, 0.0, 1.0)
	rookie_troop_ratio = clampf(1.0 - _veteran_experience_ratio, 0.05, 1.0)
	_commander_leadership_score = clampf(p_commander_leadership, 0.0, 100.0)
	_current_morale = clampf(p_initial_morale, 0.0, 100.0)
	_current_cohesion = clampf(p_initial_cohesion, 0.0, 100.0)
	_is_in_cascade_rout = false
	_is_staggered_hold = false


func is_in_staggered_hold() -> bool:
	return _is_staggered_hold


## Evaluates front-line elite vanguard loss with layered veteran experience,
## formation cohesion, commander leadership damping, and battle fatigue amplification.
## Experienced formations led by strong commanders absorb the shock into a
## `staggered_hold` (`1.0x` front defense), whereas fatigued or rookie formations
## shatter into a `cascade_rout` (`2.1x` rear strike + Toy prisoner capture).
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
	_is_elite_vanguard_alive = false
	var damping: float = clampf(1.0 - _veteran_experience_ratio * 0.45 - (_commander_leadership_score / 100.0) * 0.30 + (_battle_fatigue / 100.0) * 0.55, 0.25, 1.65)
	var morale_shock: float = rules.elite_vanguard_loss_morale_shock * damping
	var cohesion_shock: float = rules.elite_vanguard_loss_cohesion_shock * damping
	_current_morale = clampf(_current_morale - morale_shock, 0.0, 100.0)
	_current_cohesion = clampf(_current_cohesion - cohesion_shock, 0.0, 100.0)

	if _current_morale < rules.rout_morale_threshold or _current_cohesion < rules.rout_cohesion_threshold or _battle_fatigue >= 65.0:
		_is_in_cascade_rout = true
		_is_staggered_hold = false
		out[&"rear_strike_multiplier"] = rules.rear_damage_multiplier
		out[&"captured_slave_workers"] = float(maxi(int(roundf(maxf(targeted_health, 1.0) * rules.slave_capture_per_routed_health)), 1))
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


## Recovers battle fatigue and rallies morale/cohesion when resting out of combat
## with supply support (`supply_ratio`).
func recover_fatigue_and_rally(rest_sec: float, supply_ratio: float) -> float:
	var dt: float = maxf(rest_sec, 0.0)
	var sup: float = clampf(supply_ratio, 0.1, 1.0)
	var commander_bonus: float = 1.0 + (_commander_leadership_score / 100.0) * 0.40
	_battle_fatigue = maxf(_battle_fatigue - dt * 3.5 * sup * commander_bonus, 0.0)
	_current_morale = clampf(_current_morale + dt * 2.2 * sup * commander_bonus, 0.0, 100.0)
	_current_cohesion = clampf(_current_cohesion + dt * 2.5 * sup * commander_bonus, 0.0, 100.0)
	if _battle_fatigue < 35.0 and _current_morale >= 35.0:
		_is_staggered_hold = false
	return _battle_fatigue
