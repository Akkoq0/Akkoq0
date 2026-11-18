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
