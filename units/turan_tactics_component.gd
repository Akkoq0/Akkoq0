class_name TuranTacticsComponent
extends Node
## Units (rank 3). 5-stage deterministic Turan Tactic finite state machine:
##  0. `RECON_DUST_SCREEN`        — Vanguard dust clouds narrow enemy vision.
##  1. `WHISTLING_ARROW_HARASSMENT` — Consumes `quiver_ammo`, erodes cohesion & morale; forces transition when ammo <= 0.
##  2. `FEIGNED_RETREAT_LURE`     — `calculate_lure_overextension()` builds enemy `formation_entropy`, `fatigue`, and collapses armor by up to 45%.
##  3. `CRESCENT_ENCIRCLEMENT_TRAP` — Wing `Vector3.dot` pincer angle (`>= PI * 0.65`) + ambush terrain seals escape vector.
##  4. `BORU_SHOCK_ANNIHILATION`  — Momentum (`mass * speed`) + Steel & Meteoric Iron final heavy-lance shock.

const KEY_REMAINING_AMMO: StringName = &"remaining_ammo"
const KEY_PHYSICAL_DAMAGE: StringName = &"physical_damage"
const KEY_COHESION_DAMAGE: StringName = &"cohesion_damage"
const KEY_MORALE_DAMAGE: StringName = &"morale_damage"
const KEY_FORMATION_ENTROPY: StringName = &"formation_entropy"
const KEY_FATIGUE: StringName = &"fatigue"
const KEY_ARMOR_COLLAPSE_RATIO: StringName = &"armor_collapse_ratio"

signal phase_changed(previous_phase: GameEnums.TuranTacticPhase, new_phase: GameEnums.TuranTacticPhase)

@export var doctrine: TacticalDoctrineData

var _army_id: int = 0
var _phase: GameEnums.TuranTacticPhase = GameEnums.TuranTacticPhase.RECON_DUST_SCREEN
var _quiver_ammo: float = 100.0
var _target_entropy: float = 0.0
var _target_fatigue: float = 0.0
var _target_armor_collapse: float = 0.0
var _is_escape_vector_sealed: bool = false
var _last_flank_angle_rad: float = 0.0


## Configures the FSM with `p_army_id`, `p_doctrine`, and initial quiver ammo.
func configure(p_army_id: int, p_doctrine: TacticalDoctrineData, initial_quiver_ammo: float = 100.0) -> bool:
	_army_id = p_army_id
	if p_doctrine != null:
		doctrine = p_doctrine
	if doctrine == null:
		push_error("TuranTacticsComponent '%s': doctrine is not assigned." % get_path())
		return false
	var errors: PackedStringArray = doctrine.get_validation_errors()
	for error: String in errors:
		push_error("TuranTacticsComponent '%s': %s" % [get_path(), error])
	if not errors.is_empty():
		return false
	_quiver_ammo = maxf(initial_quiver_ammo, 0.0)
	_phase = GameEnums.TuranTacticPhase.RECON_DUST_SCREEN
	_target_entropy = 0.0
	_target_fatigue = 0.0
	_target_armor_collapse = 0.0
	_is_escape_vector_sealed = false
	return true


func get_current_phase() -> GameEnums.TuranTacticPhase:
	return _phase


func get_quiver_ammo() -> float:
	return _quiver_ammo


func set_quiver_ammo(amount: float) -> void:
	_quiver_ammo = maxf(amount, 0.0)


func is_escape_vector_sealed() -> bool:
	return _is_escape_vector_sealed


func get_target_armor_collapse_ratio() -> float:
	return _target_armor_collapse


func get_target_formation_entropy() -> float:
	return _target_entropy


## Deterministically transitions the FSM to `next_phase`.
func advance_to_phase(next_phase: GameEnums.TuranTacticPhase) -> void:
	if next_phase == _phase:
		return
	var previous: GameEnums.TuranTacticPhase = _phase
	_phase = next_phase
	phase_changed.emit(previous, _phase)
	EventBus.turan_phase_changed.emit(_army_id, previous, _phase)


# --- Stage 1: RECON_DUST_SCREEN ---------------------------------------------

## Multiplier applied to enemy vision range while vanguard dust screen is active.
func get_enemy_vision_multiplier() -> float:
	if doctrine == null or _phase != GameEnums.TuranTacticPhase.RECON_DUST_SCREEN:
		return 1.0
	return clampf(1.0 - doctrine.dust_screen_vision_reduction_ratio, 0.05, 1.0)


## Apparent size multiplier projected by false dust trails during Stage 1.
func get_deceptive_army_size_multiplier() -> float:
	if doctrine == null or _phase != GameEnums.TuranTacticPhase.RECON_DUST_SCREEN:
		return 1.0
	return doctrine.deceptive_army_size_multiplier


# --- Stage 2: WHISTLING_ARROW_HARASSMENT ------------------------------------

## Fires a whistling-arrow volley, consuming `quiver_ammo` and eroding target
## `cohesion` and `morale`. Forces exit from `WHISTLING_ARROW_HARASSMENT` into
## `FEIGNED_RETREAT_LURE` when `quiver_ammo <= 0`.
func execute_whistling_arrow_volley(target: CombatantStats = null) -> Dictionary[StringName, float]:
	var result: Dictionary[StringName, float] = {
		KEY_REMAINING_AMMO: _quiver_ammo,
		KEY_PHYSICAL_DAMAGE: 0.0,
		KEY_COHESION_DAMAGE: 0.0,
		KEY_MORALE_DAMAGE: 0.0,
	}
	if doctrine == null:
		return result
	if _phase == GameEnums.TuranTacticPhase.RECON_DUST_SCREEN:
		advance_to_phase(GameEnums.TuranTacticPhase.WHISTLING_ARROW_HARASSMENT)
	if _quiver_ammo <= 0.0:
		EventBus.quiver_ammo_depleted.emit(_army_id)
		advance_to_phase(GameEnums.TuranTacticPhase.FEIGNED_RETREAT_LURE)
		return result

	var consumed: float = minf(_quiver_ammo, doctrine.quiver_ammo_consumption_per_volley)
	var volley_ratio: float = consumed / doctrine.quiver_ammo_consumption_per_volley
	_quiver_ammo = maxf(_quiver_ammo - consumed, 0.0)

	var phys_dmg: float = doctrine.whistling_arrow_physical_damage * volley_ratio
	var coh_dmg: float = doctrine.whistling_arrow_cohesion_damage * volley_ratio
	var mor_dmg: float = doctrine.whistling_arrow_morale_damage * volley_ratio

	if target != null:
		target.health = maxf(target.health - phys_dmg, 0.0)
		target.cohesion = clampf(target.cohesion - coh_dmg, 0.0, 100.0)
		target.morale = clampf(target.morale - mor_dmg, 0.0, 100.0)

	result[KEY_REMAINING_AMMO] = _quiver_ammo
	result[KEY_PHYSICAL_DAMAGE] = phys_dmg
	result[KEY_COHESION_DAMAGE] = coh_dmg
	result[KEY_MORALE_DAMAGE] = mor_dmg

	if _quiver_ammo <= 0.0:
		EventBus.quiver_ammo_depleted.emit(_army_id)
		advance_to_phase(GameEnums.TuranTacticPhase.FEIGNED_RETREAT_LURE)
	return result


# --- Stage 3: FEIGNED_RETREAT_LURE ------------------------------------------

## Evaluates enemy overextension during a feigned retreat against the enemy
## commander's `ambition / discipline` ratio across `retreat_distance_m`.
## Collapses enemy armor defense multiplier by up to `max_armor_collapse_ratio` (45%).
func calculate_lure_overextension(pursuer_ambition: float, pursuer_discipline: float, retreat_distance_m: float, pursuer: CombatantStats = null) -> Dictionary[StringName, float]:
	var out: Dictionary[StringName, float] = {
		KEY_FORMATION_ENTROPY: _target_entropy,
		KEY_FATIGUE: _target_fatigue,
		KEY_ARMOR_COLLAPSE_RATIO: _target_armor_collapse,
	}
	if doctrine == null:
		return out
	if _phase != GameEnums.TuranTacticPhase.FEIGNED_RETREAT_LURE:
		advance_to_phase(GameEnums.TuranTacticPhase.FEIGNED_RETREAT_LURE)

	var susceptibility: float = (maxf(pursuer_ambition, 0.0) / maxf(pursuer_discipline, 0.05)) * doctrine.lure_ambition_weight
	var dist: float = maxf(retreat_distance_m, 0.0)
	_target_entropy = clampf(_target_entropy + dist * doctrine.entropy_gain_per_meter * susceptibility, 0.0, 1.0)
	_target_fatigue = clampf(_target_fatigue + dist * doctrine.fatigue_gain_per_meter * susceptibility, 0.0, 1.0)
	_target_armor_collapse = clampf(_target_entropy * doctrine.max_armor_collapse_ratio, 0.0, doctrine.max_armor_collapse_ratio)

	var pursuer_id: int = pursuer.entity_id if pursuer != null else 0
	if pursuer != null:
		pursuer.formation_entropy = _target_entropy
		pursuer.fatigue = _target_fatigue
		pursuer.armor_collapse_ratio = _target_armor_collapse

	EventBus.feigned_retreat_lured.emit(_army_id, pursuer_id, dist, _target_entropy, _target_armor_collapse)
	if _target_entropy >= doctrine.critical_entropy_threshold:
		EventBus.formation_entropy_critical.emit(_army_id, _target_entropy, _target_armor_collapse)
		advance_to_phase(GameEnums.TuranTacticPhase.CRESCENT_ENCIRCLEMENT_TRAP)

	out[KEY_FORMATION_ENTROPY] = _target_entropy
	out[KEY_FATIGUE] = _target_fatigue
	out[KEY_ARMOR_COLLAPSE_RATIO] = _target_armor_collapse
	return out


# --- Stage 4: CRESCENT_ENCIRCLEMENT_TRAP ------------------------------------

## Evaluates wing vectors using `Vector3.dot`. When `flank_angle_rad >= PI * 0.65`,
## springs the Crescent Trap, seals the escape vector if on `Sık Orman` or
## `Damarlı Yamaç`, and advances to `BORU_SHOCK_ANNIHILATION`.
func evaluate_crescent_trap(left_wing_dir: Vector3, right_wing_dir: Vector3, terrain: TerrainData, target: CombatantStats = null) -> bool:
	if doctrine == null:
		return false
	var left_n: Vector3 = left_wing_dir.normalized() if left_wing_dir.length_squared() > 0.0001 else Vector3.LEFT
	var right_n: Vector3 = right_wing_dir.normalized() if right_wing_dir.length_squared() > 0.0001 else Vector3.RIGHT
	var dot_val: float = clampf(left_n.dot(right_n), -1.0, 1.0)
	_last_flank_angle_rad = acos(dot_val)
	if _last_flank_angle_rad < doctrine.min_crescent_flank_angle_rad:
		return false

	if _phase != GameEnums.TuranTacticPhase.CRESCENT_ENCIRCLEMENT_TRAP:
		advance_to_phase(GameEnums.TuranTacticPhase.CRESCENT_ENCIRCLEMENT_TRAP)

	_is_escape_vector_sealed = terrain != null and doctrine.can_seal_escape_on(terrain.terrain_class)
	var target_id: int = target.entity_id if target != null else 0
	if target != null:
		target.is_escape_vector_sealed = _is_escape_vector_sealed
		target.cohesion = clampf(target.cohesion - doctrine.encirclement_cohesion_shock, 0.0, 100.0)

	EventBus.crescent_trap_sprung.emit(_army_id, target_id, _last_flank_angle_rad, _is_escape_vector_sealed)
	advance_to_phase(GameEnums.TuranTacticPhase.BORU_SHOCK_ANNIHILATION)
	return true


# --- Stage 5: BORU_SHOCK_ANNIHILATION ---------------------------------------

## Computes the momentum-based (`mass * speed`) shock multiplier of Börü heavy
## lancers equipped with Steel (`steel.tres`) and Meteoric Iron (`meteoric_iron.tres`).
func compute_boru_shock_momentum(cavalry_mass: float, current_speed: float, has_steel: bool, has_meteoric_iron: bool) -> float:
	if doctrine == null:
		return 1.0
	if _phase != GameEnums.TuranTacticPhase.BORU_SHOCK_ANNIHILATION:
		advance_to_phase(GameEnums.TuranTacticPhase.BORU_SHOCK_ANNIHILATION)
	var raw_momentum: float = maxf(cavalry_mass, 1.0) * maxf(current_speed, 0.1) * 0.001 * doctrine.boru_charge_mass_factor
	var steel_mult: float = doctrine.boru_steel_shock_multiplier if has_steel else 1.0
	var meteoric_mult: float = doctrine.boru_meteoric_iron_shock_multiplier if has_meteoric_iron else 1.0
	return maxf(raw_momentum * steel_mult * meteoric_mult, 1.0)
