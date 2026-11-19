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

const EXTREME_FATIGUE_THRESHOLD: float = 85.0
const MAX_LURE_STALL_ATTEMPTS: int = 3
const MAX_ENCIRCLEMENT_STALL_ATTEMPTS: int = 2

signal phase_changed(previous_phase: GameEnums.TuranTacticPhase, new_phase: GameEnums.TuranTacticPhase)
signal tactical_fallback_triggered(previous_phase: GameEnums.TuranTacticPhase, fallback_phase: GameEnums.TuranTacticPhase, reason: StringName)

@export var doctrine: TacticalDoctrineData

var _army_id: int = 0
var _phase: GameEnums.TuranTacticPhase = GameEnums.TuranTacticPhase.RECON_DUST_SCREEN
var _quiver_ammo: float = 100.0
var _target_entropy: float = 0.0
var _target_fatigue: float = 0.0
var _target_armor_collapse: float = 0.0
var _is_escape_vector_sealed: bool = false
var _last_flank_angle_rad: float = 0.0
var _own_fatigue: float = 0.0
var _remount_horse_ratio: float = 1.0
var _commander_alive: bool = true
var _commander_readiness_multiplier: float = 1.0
var _consecutive_stalled_steps: int = 0
var _last_fallback_reason: StringName = &""


func _ready() -> void:
	EventBus.army_caravan_resupply_delivered.connect(_on_army_caravan_resupply_delivered)


func _exit_tree() -> void:
	if EventBus.army_caravan_resupply_delivered.is_connected(_on_army_caravan_resupply_delivered):
		EventBus.army_caravan_resupply_delivered.disconnect(_on_army_caravan_resupply_delivered)


func _on_army_caravan_resupply_delivered(p_army_id: int, quiver_ammo_amt: float, _food_amt: int) -> void:
	if _army_id > 0 and p_army_id == _army_id and quiver_ammo_amt > 0.0:
		set_quiver_ammo(_quiver_ammo + quiver_ammo_amt)


static func _safe_float(val: float, fallback: float) -> float:
	if is_nan(val) or is_inf(val):
		return fallback
	return val


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
	_quiver_ammo = maxf(_safe_float(initial_quiver_ammo, 100.0), 0.0)
	_phase = GameEnums.TuranTacticPhase.RECON_DUST_SCREEN
	_own_fatigue = 0.0
	_remount_horse_ratio = 1.0
	_commander_alive = true
	_commander_readiness_multiplier = 1.0
	_target_entropy = 0.0
	_target_fatigue = 0.0
	_target_armor_collapse = 0.0
	_is_escape_vector_sealed = false
	_last_flank_angle_rad = 0.0
	_consecutive_stalled_steps = 0
	_last_fallback_reason = &""
	return true


func get_current_phase() -> GameEnums.TuranTacticPhase:
	return _phase


func get_quiver_ammo() -> float:
	return _quiver_ammo


func set_quiver_ammo(amount: float) -> void:
	_quiver_ammo = clampf(_safe_float(amount, _quiver_ammo), 0.0, 100.0)
	if _phase == GameEnums.TuranTacticPhase.WHISTLING_ARROW_HARASSMENT and _quiver_ammo <= 0.0:
		EventBus.quiver_ammo_depleted.emit(_army_id)
		if not _commander_alive or _own_fatigue >= EXTREME_FATIGUE_THRESHOLD:
			evaluate_tactical_fallback(false, &"quiver_depleted_abort")
		else:
			advance_to_phase(GameEnums.TuranTacticPhase.FEIGNED_RETREAT_LURE)


func set_commander_alive(alive: bool) -> void:
	_commander_alive = alive


func is_commander_alive() -> bool:
	return _commander_alive


func get_last_fallback_reason() -> StringName:
	return _last_fallback_reason


func is_escape_vector_sealed() -> bool:
	return _is_escape_vector_sealed


func get_target_armor_collapse_ratio() -> float:
	return _target_armor_collapse


func get_target_formation_entropy() -> float:
	return _target_entropy


## Marks the commander lost mid-engagement and safely breaks any active
## Stage 1–3 tactical commitment via tactical withdrawal or desperate shock.
func notify_commander_lost(allow_desperate_melee: bool = false) -> GameEnums.TuranTacticPhase:
	_commander_alive = false
	if _phase == GameEnums.TuranTacticPhase.RECON_DUST_SCREEN or _phase == GameEnums.TuranTacticPhase.BORU_SHOCK_ANNIHILATION:
		return _phase
	if allow_desperate_melee:
		var prev: GameEnums.TuranTacticPhase = _phase
		_consecutive_stalled_steps = 0
		_is_escape_vector_sealed = false
		_last_fallback_reason = &"commander_lost_desperate_charge"
		advance_to_phase(GameEnums.TuranTacticPhase.BORU_SHOCK_ANNIHILATION)
		tactical_fallback_triggered.emit(prev, _phase, _last_fallback_reason)
		return _phase
	return evaluate_tactical_fallback(false, &"commander_lost_withdrawal")


## Deterministically breaks out of mid-battle Stages 1–3 (`HARASSMENT`, `LURE`, `CRESCENT`)
## into close-quarters melee (`BORU_SHOCK_ANNIHILATION`) or orderly tactical withdrawal (`RECON_DUST_SCREEN`)
## when tactical conditions stall, storms rage, fatigue spikes, or leadership falls.
func evaluate_tactical_fallback(allow_melee_charge: bool = false, reason: StringName = &"tactical_fallback") -> GameEnums.TuranTacticPhase:
	if _phase == GameEnums.TuranTacticPhase.RECON_DUST_SCREEN or _phase == GameEnums.TuranTacticPhase.BORU_SHOCK_ANNIHILATION:
		return _phase
	var prev: GameEnums.TuranTacticPhase = _phase
	_consecutive_stalled_steps = 0
	_last_fallback_reason = reason
	if allow_melee_charge and _commander_alive and _own_fatigue < EXTREME_FATIGUE_THRESHOLD:
		_is_escape_vector_sealed = false
		advance_to_phase(GameEnums.TuranTacticPhase.BORU_SHOCK_ANNIHILATION)
	else:
		reset_tactical_engagement_cycle(true)
	tactical_fallback_triggered.emit(prev, _phase, reason)
	return _phase


## Clears accumulated target entropy, fatigue, and encirclement lock to start a fresh battle cycle.
func reset_tactical_engagement_cycle(reset_to_recon: bool = true) -> void:
	_target_entropy = 0.0
	_target_fatigue = 0.0
	_target_armor_collapse = 0.0
	_is_escape_vector_sealed = false
	_last_flank_angle_rad = 0.0
	_consecutive_stalled_steps = 0
	if reset_to_recon and _phase != GameEnums.TuranTacticPhase.RECON_DUST_SCREEN:
		advance_to_phase(GameEnums.TuranTacticPhase.RECON_DUST_SCREEN)


## Deterministically transitions the FSM to `next_phase`.
func advance_to_phase(next_phase: GameEnums.TuranTacticPhase) -> void:
	if next_phase == _phase:
		return
	var previous: GameEnums.TuranTacticPhase = _phase
	_phase = next_phase
	_consecutive_stalled_steps = 0
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

func _get_weather_storm_modifiers() -> Array[float]:
	var is_storm: bool = BallisticsEngine != null and BallisticsEngine.is_pre_zud_storm_active()
	if not is_storm:
		return [0.0, 1.0, 1.0]
	var b_rules: BallisticsRules = BallisticsEngine.get_rules()
	var ammo_mult: float = b_rules.storm_ammo_consumption_multiplier if b_rules != null else 1.35
	var morale_mult: float = b_rules.storm_whistling_morale_multiplier if b_rules != null else 0.60
	return [1.0, ammo_mult, morale_mult]


## Fires a whistling-arrow volley, consuming `quiver_ammo` and eroding target
## `cohesion` and `morale`. Forces exit from `WHISTLING_ARROW_HARASSMENT` when
## `quiver_ammo <= 0`, leadership falls, or extreme fatigue occurs in storm conditions.
func execute_whistling_arrow_volley(target: CombatantStats = null) -> Dictionary[StringName, float]:
	var result: Dictionary[StringName, float] = {
		KEY_REMAINING_AMMO: _quiver_ammo,
		KEY_PHYSICAL_DAMAGE: 0.0,
		KEY_COHESION_DAMAGE: 0.0,
		KEY_MORALE_DAMAGE: 0.0,
	}
	if doctrine == null:
		return result
	if not _commander_alive:
		if _phase != GameEnums.TuranTacticPhase.RECON_DUST_SCREEN and _phase != GameEnums.TuranTacticPhase.BORU_SHOCK_ANNIHILATION:
			evaluate_tactical_fallback(false, &"commander_lost_volley_abort")
		return result
	if _phase == GameEnums.TuranTacticPhase.BORU_SHOCK_ANNIHILATION and _quiver_ammo > 0.0:
		reset_tactical_engagement_cycle(false)
		advance_to_phase(GameEnums.TuranTacticPhase.WHISTLING_ARROW_HARASSMENT)
	elif _phase == GameEnums.TuranTacticPhase.RECON_DUST_SCREEN:
		advance_to_phase(GameEnums.TuranTacticPhase.WHISTLING_ARROW_HARASSMENT)

	var storm_mods: Array[float] = _get_weather_storm_modifiers()
	var in_storm: bool = storm_mods[0] > 0.5
	var storm_ammo_mult: float = storm_mods[1]
	var storm_morale_mult: float = storm_mods[2]

	if _quiver_ammo <= 0.0:
		EventBus.quiver_ammo_depleted.emit(_army_id)
		if in_storm or _own_fatigue >= EXTREME_FATIGUE_THRESHOLD:
			evaluate_tactical_fallback(not in_storm, &"zero_ammo_storm_or_fatigue_fallback")
		else:
			advance_to_phase(GameEnums.TuranTacticPhase.FEIGNED_RETREAT_LURE)
		return result

	if in_storm and _own_fatigue >= EXTREME_FATIGUE_THRESHOLD:
		evaluate_tactical_fallback(false, &"pre_zud_storm_fatigue_withdrawal")
		return result

	var effective_cost: float = doctrine.quiver_ammo_consumption_per_volley * storm_ammo_mult
	var consumed: float = minf(_quiver_ammo, effective_cost)
	var volley_ratio: float = clampf(consumed / maxf(effective_cost, 0.1), 0.0, 1.0)
	_quiver_ammo = maxf(_quiver_ammo - consumed, 0.0)

	var phys_dmg: float = doctrine.whistling_arrow_physical_damage * volley_ratio
	var coh_dmg: float = doctrine.whistling_arrow_cohesion_damage * volley_ratio
	var mor_dmg: float = doctrine.whistling_arrow_morale_damage * volley_ratio * storm_morale_mult

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
		if in_storm and _own_fatigue >= EXTREME_FATIGUE_THRESHOLD:
			evaluate_tactical_fallback(false, &"quiver_depleted_in_storm_withdrawal")
		else:
			advance_to_phase(GameEnums.TuranTacticPhase.FEIGNED_RETREAT_LURE)
	return result


# --- Stage 3: FEIGNED_RETREAT_LURE ------------------------------------------

## Evaluates enemy overextension during a feigned retreat against the enemy
## commander's `ambition / discipline` ratio across `retreat_distance_m`.
## Collapses enemy armor defense multiplier by up to `max_armor_collapse_ratio` (45%).
## Breaks stalled or leaderless retreats cleanly into fallback melee or withdrawal.
func calculate_lure_overextension(pursuer_ambition: float, pursuer_discipline: float, retreat_distance_m: float, pursuer: CombatantStats = null) -> Dictionary[StringName, float]:
	var out: Dictionary[StringName, float] = {
		KEY_FORMATION_ENTROPY: _target_entropy,
		KEY_FATIGUE: _target_fatigue,
		KEY_ARMOR_COLLAPSE_RATIO: _target_armor_collapse,
	}
	if doctrine == null:
		return out
	if _phase == GameEnums.TuranTacticPhase.BORU_SHOCK_ANNIHILATION:
		reset_tactical_engagement_cycle(false)
	if _phase != GameEnums.TuranTacticPhase.FEIGNED_RETREAT_LURE:
		advance_to_phase(GameEnums.TuranTacticPhase.FEIGNED_RETREAT_LURE)

	var safe_amb: float = _safe_float(pursuer_ambition, 0.5)
	var safe_disc: float = _safe_float(pursuer_discipline, 0.5)
	var safe_dist: float = _safe_float(retreat_distance_m, 0.0)
	var susceptibility: float = (maxf(safe_amb, 0.0) / maxf(safe_disc, 0.05)) * doctrine.lure_ambition_weight
	var dist: float = maxf(safe_dist, 0.0)
	_target_entropy = clampf(_target_entropy + dist * doctrine.entropy_gain_per_meter * susceptibility, 0.0, 1.0)
	_target_fatigue = clampf(_target_fatigue + dist * doctrine.fatigue_gain_per_meter * susceptibility, 0.0, 1.0)
	_target_armor_collapse = clampf(_target_entropy * doctrine.max_armor_collapse_ratio, 0.0, doctrine.max_armor_collapse_ratio)

	var pursuer_id: int = pursuer.entity_id if pursuer != null else 0
	if pursuer != null:
		pursuer.formation_entropy = _target_entropy
		pursuer.fatigue = _target_fatigue
		pursuer.armor_collapse_ratio = _target_armor_collapse

	EventBus.feigned_retreat_lured.emit(_army_id, pursuer_id, dist, _target_entropy, _target_armor_collapse)
	out[KEY_FORMATION_ENTROPY] = _target_entropy
	out[KEY_FATIGUE] = _target_fatigue
	out[KEY_ARMOR_COLLAPSE_RATIO] = _target_armor_collapse

	if not _commander_alive:
		evaluate_tactical_fallback(false, &"commander_lost_lure_withdrawal")
		return out

	if _target_entropy >= doctrine.critical_entropy_threshold:
		_consecutive_stalled_steps = 0
		EventBus.formation_entropy_critical.emit(_army_id, _target_entropy, _target_armor_collapse)
		advance_to_phase(GameEnums.TuranTacticPhase.CRESCENT_ENCIRCLEMENT_TRAP)
	else:
		_consecutive_stalled_steps += 1
		if _own_fatigue >= EXTREME_FATIGUE_THRESHOLD \
				or _consecutive_stalled_steps >= MAX_LURE_STALL_ATTEMPTS \
				or ((dist <= 0.001 or safe_amb <= 0.001) and _consecutive_stalled_steps >= 2):
			evaluate_tactical_fallback(true, &"feigned_retreat_stalled_fallback")
	return out


# --- Stage 4: CRESCENT_ENCIRCLEMENT_TRAP ------------------------------------

func _resolve_failed_crescent_attempt(is_storm: bool) -> bool:
	if not _commander_alive:
		evaluate_tactical_fallback(false, &"commander_lost_crescent_abort")
		return false
	if _own_fatigue >= EXTREME_FATIGUE_THRESHOLD:
		evaluate_tactical_fallback(false, &"extreme_fatigue_crescent_abort")
		return false
	_consecutive_stalled_steps += 1
	if _consecutive_stalled_steps >= MAX_ENCIRCLEMENT_STALL_ATTEMPTS or is_storm:
		evaluate_tactical_fallback(true, &"pre_zud_storm_crescent_melee" if is_storm else &"crescent_encirclement_blocked")
	return false


## Evaluates wing vectors using `Vector3.dot`. When `flank_angle_rad >= PI * 0.65`,
## springs the Crescent Trap, seals the escape vector if on `Sık Orman` or
## `Damarlı Yamaç`, and advances to `BORU_SHOCK_ANNIHILATION`.
func evaluate_crescent_trap(left_wing_dir: Vector3, right_wing_dir: Vector3, terrain: TerrainData, target: CombatantStats = null) -> bool:
	if doctrine == null:
		return false
	if not _commander_alive or _own_fatigue >= EXTREME_FATIGUE_THRESHOLD:
		return _resolve_failed_crescent_attempt(false)

	var left_n: Vector3 = left_wing_dir.normalized() if (left_wing_dir.is_finite() and left_wing_dir.length_squared() > 0.0001) else Vector3.LEFT
	var right_n: Vector3 = right_wing_dir.normalized() if (right_wing_dir.is_finite() and right_wing_dir.length_squared() > 0.0001) else Vector3.RIGHT
	var dot_val: float = clampf(left_n.dot(right_n), -1.0, 1.0)
	var raw_angle: float = acos(dot_val)
	var is_storm: bool = _get_weather_storm_modifiers()[0] > 0.5
	_last_flank_angle_rad = raw_angle * (0.78 if is_storm else 1.0)
	if _last_flank_angle_rad < doctrine.min_crescent_flank_angle_rad:
		return _resolve_failed_crescent_attempt(is_storm)

	if _phase != GameEnums.TuranTacticPhase.CRESCENT_ENCIRCLEMENT_TRAP:
		advance_to_phase(GameEnums.TuranTacticPhase.CRESCENT_ENCIRCLEMENT_TRAP)

	_consecutive_stalled_steps = 0
	_is_escape_vector_sealed = terrain != null and doctrine.can_seal_escape_on(terrain.terrain_class)
	var target_id: int = target.entity_id if target != null else 0
	if target != null:
		target.is_escape_vector_sealed = _is_escape_vector_sealed
		target.cohesion = clampf(target.cohesion - doctrine.encirclement_cohesion_shock, 0.0, 100.0)

	EventBus.crescent_trap_sprung.emit(_army_id, target_id, _last_flank_angle_rad, _is_escape_vector_sealed)
	advance_to_phase(GameEnums.TuranTacticPhase.BORU_SHOCK_ANNIHILATION)
	return true


## Evaluates the Stage 4 Crescent Encirclement Trap while accounting for Yılkı
## spare-horse depletion (`remount_horse_ratio`). When `remount_horse_ratio` drops
## below the calibrated friction threshold, wing cavalry cannot reach the pincer
## angle in time and repeated blocked encirclements safely fall back to melee or retreat.
func evaluate_crescent_trap_with_remount_ratio(left_wing_dir: Vector3, right_wing_dir: Vector3, remount_horse_ratio: float, calibration: CausalFrictionCalibration, terrain: TerrainData, target: CombatantStats = null) -> bool:
	if doctrine == null:
		return false
	if not _commander_alive or _own_fatigue >= EXTREME_FATIGUE_THRESHOLD:
		return _resolve_failed_crescent_attempt(false)

	var left_n: Vector3 = left_wing_dir.normalized() if (left_wing_dir.is_finite() and left_wing_dir.length_squared() > 0.0001) else Vector3.LEFT
	var right_n: Vector3 = right_wing_dir.normalized() if (right_wing_dir.is_finite() and right_wing_dir.length_squared() > 0.0001) else Vector3.RIGHT
	var dot_val: float = clampf(left_n.dot(right_n), -1.0, 1.0)
	var raw_angle_rad: float = acos(dot_val)
	var safe_remount: float = clampf(_safe_float(remount_horse_ratio, 1.0), 0.0, 1.0)
	var is_storm: bool = _get_weather_storm_modifiers()[0] > 0.5
	var weather_mult: float = 0.78 if is_storm else 1.0
	if calibration != null:
		_last_flank_angle_rad = calibration.compute_effective_crescent_wing_angle(raw_angle_rad, safe_remount) * weather_mult
	else:
		_last_flank_angle_rad = raw_angle_rad * weather_mult
	if _last_flank_angle_rad < doctrine.min_crescent_flank_angle_rad:
		return _resolve_failed_crescent_attempt(is_storm)

	if _phase != GameEnums.TuranTacticPhase.CRESCENT_ENCIRCLEMENT_TRAP:
		advance_to_phase(GameEnums.TuranTacticPhase.CRESCENT_ENCIRCLEMENT_TRAP)

	_consecutive_stalled_steps = 0
	_is_escape_vector_sealed = terrain != null and doctrine.can_seal_escape_on(terrain.terrain_class)
	var target_id: int = target.entity_id if target != null else 0
	if target != null:
		target.is_escape_vector_sealed = _is_escape_vector_sealed
		target.cohesion = clampf(target.cohesion - doctrine.encirclement_cohesion_shock, 0.0, 100.0)

	EventBus.crescent_trap_sprung.emit(_army_id, target_id, _last_flank_angle_rad, _is_escape_vector_sealed)
	advance_to_phase(GameEnums.TuranTacticPhase.BORU_SHOCK_ANNIHILATION)
	return true


func get_last_flank_angle_rad() -> float:
	return _last_flank_angle_rad


## Sets the army's own fatigue (`0..100`), quiver ammo (`0..100`), and Yılkı
## spare-horse ratio (`0..1`) for maneuver readiness evaluation.
func set_readiness_state(p_fatigue: float, p_quiver_ammo: float, p_remount_ratio: float) -> void:
	_own_fatigue = clampf(_safe_float(p_fatigue, _own_fatigue), 0.0, 100.0)
	_quiver_ammo = clampf(_safe_float(p_quiver_ammo, _quiver_ammo), 0.0, 100.0)
	_remount_horse_ratio = clampf(_safe_float(p_remount_ratio, _remount_horse_ratio), 0.0, 1.0)
	if _phase == GameEnums.TuranTacticPhase.WHISTLING_ARROW_HARASSMENT and _quiver_ammo <= 0.0:
		EventBus.quiver_ammo_depleted.emit(_army_id)
		if not _commander_alive or _own_fatigue >= EXTREME_FATIGUE_THRESHOLD:
			evaluate_tactical_fallback(false, &"readiness_quiver_depleted_abort")
		else:
			advance_to_phase(GameEnums.TuranTacticPhase.FEIGNED_RETREAT_LURE)


func get_own_fatigue() -> float:
	return _own_fatigue


func get_remount_horse_ratio() -> float:
	return _remount_horse_ratio


func set_commander_readiness_multiplier(mult: float) -> void:
	_commander_readiness_multiplier = clampf(_safe_float(mult, 1.0), 0.70, 1.45)


func get_commander_readiness_multiplier() -> float:
	return _commander_readiness_multiplier


## Computes the tactical maneuver execution efficiency (`0.35..1.15` baseline,
## scaled by commander veteran readiness) based on fatigue, quiver ammo, remounts, and terrain.
func compute_maneuver_execution_efficiency(terrain: TerrainData = null) -> float:
	var fatigue_penalty: float = (_own_fatigue / 100.0) * 0.35
	var ammo_penalty: float = 0.20 if _quiver_ammo <= 0.0 else clampf((25.0 - _quiver_ammo) / 25.0, 0.0, 1.0) * 0.15
	var remount_penalty: float = 0.0
	if _remount_horse_ratio < 0.55:
		remount_penalty = ((0.55 - _remount_horse_ratio) / 0.55) * 0.30
	var terrain_bonus: float = 0.0
	if terrain != null and (terrain.terrain_class == GameEnums.TerrainClass.BEREKET_HAVZASI or terrain.terrain_class == GameEnums.TerrainClass.SIK_ORMAN):
		terrain_bonus = 0.08
	var base_eff: float = clampf(1.0 - fatigue_penalty - ammo_penalty - remount_penalty + terrain_bonus, 0.35, 1.15)
	if is_equal_approx(_commander_readiness_multiplier, 1.0):
		return base_eff
	return clampf(base_eff * _commander_readiness_multiplier, 0.30, 1.45)


## Executes Stage 3 Feigned Retreat while modulating overextension effectiveness
## by the army's own fatigue, quiver ammo, and Yılkı spare-horse readiness.
func execute_feigned_retreat_with_readiness(pursuer_ambition: float, pursuer_discipline: float, retreat_distance_m: float, terrain: TerrainData = null, pursuer: CombatantStats = null) -> Dictionary[StringName, float]:
	var efficiency: float = compute_maneuver_execution_efficiency(terrain)
	var safe_dist: float = maxf(_safe_float(retreat_distance_m, 0.0), 0.0)
	var effective_dist: float = safe_dist * efficiency
	_own_fatigue = clampf(_own_fatigue + safe_dist * 0.08, 0.0, 100.0)
	return calculate_lure_overextension(pursuer_ambition, pursuer_discipline, effective_dist, pursuer)


## Rests and resupplies the tactical unit out of combat, reducing fatigue and
## restoring quiver ammunition and Yılkı spare horses. Cleans up any completed
## OR aborted mid-battle stage back to `RECON_DUST_SCREEN`.
func rest_and_resupply_tactical_readiness(rest_duration_sec: float, ammo_resupplied: float, remount_restored: float, terrain: TerrainData = null) -> float:
	var dt: float = maxf(_safe_float(rest_duration_sec, 0.0), 0.0)
	var ammo_add: float = maxf(_safe_float(ammo_resupplied, 0.0), 0.0)
	var remount_add: float = maxf(_safe_float(remount_restored, 0.0), 0.0)
	_own_fatigue = maxf(_own_fatigue - dt * 4.0, 0.0)
	_quiver_ammo = clampf(_quiver_ammo + ammo_add, 0.0, 100.0)
	_remount_horse_ratio = clampf(_remount_horse_ratio + remount_add, 0.0, 1.0)
	if dt > 0.0 and _phase != GameEnums.TuranTacticPhase.RECON_DUST_SCREEN:
		reset_tactical_engagement_cycle(true)
	return compute_maneuver_execution_efficiency(terrain)


# --- Stage 5: BORU_SHOCK_ANNIHILATION ---------------------------------------

## Computes the momentum-based (`mass * speed`) shock multiplier of Börü heavy
## lancers equipped with Steel (`steel.tres`) and Meteoric Iron (`meteoric_iron.tres`).
func compute_boru_shock_momentum(cavalry_mass: float, current_speed: float, has_steel: bool, has_meteoric_iron: bool) -> float:
	if doctrine == null:
		return 1.0
	if _phase != GameEnums.TuranTacticPhase.BORU_SHOCK_ANNIHILATION:
		advance_to_phase(GameEnums.TuranTacticPhase.BORU_SHOCK_ANNIHILATION)
	var safe_mass: float = maxf(_safe_float(cavalry_mass, 1.0), 1.0)
	var safe_speed: float = maxf(_safe_float(current_speed, 0.1), 0.1)
	var fatigue_factor: float = lerpf(1.0, 0.55, clampf(_own_fatigue / 100.0, 0.0, 1.0))
	var remount_factor: float = lerpf(0.65, 1.0, clampf(_remount_horse_ratio / 0.55, 0.0, 1.0)) if _remount_horse_ratio < 0.55 else 1.0
	var raw_momentum: float = safe_mass * safe_speed * 0.001 * doctrine.boru_charge_mass_factor * fatigue_factor * remount_factor
	var steel_mult: float = doctrine.boru_steel_shock_multiplier if has_steel else 1.0
	var meteoric_mult: float = doctrine.boru_meteoric_iron_shock_multiplier if has_meteoric_iron else 1.0
	return maxf(raw_momentum * steel_mult * meteoric_mult, 1.0)

