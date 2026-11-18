class_name CausalFrictionCalibration
extends Resource
## Data layer (rank 1). Unified friction and threshold calibration matrix
## (`res://data/world/causal_friction_calibration.tres`) governing multi-step
## causal chains across ecology, Yılkı logistics, Turan tactics, battle fatigue,
## cascade rout, Kut/Toy governance, diplomacy coalitions, and Zud epidemics.

@export var calibration_id: StringName = &"otuken_causal_friction_matrix_v1"

@export_group("Governance, Glory & Coalition Thresholds")
@export_range(10.0, 50.0, 0.5) var critical_kut_council_threshold: float = 30.0
@export_range(20.0, 80.0, 1.0) var free_warband_glory_threshold: float = 40.0
@export_range(5.0, 45.0, 1.0) var espionage_coalition_trust_recovery: float = 22.0

@export_group("Combat Fatigue & Directional Multipliers")
@export_range(0.5, 10.0, 0.1) var fatigue_accumulation_per_sec: float = 2.5
@export_range(0.1, 0.8, 0.05) var max_fatigue_speed_penalty_ratio: float = 0.45
@export_range(0.1, 0.8, 0.05) var max_fatigue_momentum_penalty_ratio: float = 0.50
@export_range(0.8, 1.5, 0.05) var directional_front_multiplier: float = 1.0
@export_range(1.1, 2.0, 0.05) var directional_flank_multiplier: float = 1.45
@export_range(1.5, 3.0, 0.05) var directional_rear_multiplier: float = 2.1

@export_group("Zud Epidemic & Kurgan Purification")
@export_range(0.2, 0.9, 0.05) var epidemic_speed_multiplier: float = 0.50
@export_range(0.01, 0.30, 0.01) var epidemic_daily_troop_attrition_ratio: float = 0.08
@export_range(2.0, 30.0, 0.5) var kurgan_purification_kut_cost: float = 12.0

@export_group("Yilki Remount Depletion -> Crescent Trap Friction")
@export_range(0.25, 0.85, 0.05) var min_remount_ratio_for_crescent_trap: float = 0.55
@export_range(0.10, 0.75, 0.01) var yilki_depletion_wing_angle_damping: float = 0.56
@export_range(5.0, 45.0, 1.0) var failed_crescent_morale_penalty: float = 24.0
@export_range(5.0, 60.0, 1.0) var counterplay_recovery_window_sec: float = 18.0
@export_range(1.0, 25.0, 0.5) var continuous_pressure_accumulation_per_sec: float = 8.0
@export_range(1.0, 30.0, 0.5) var continuous_pressure_decay_per_sec: float = 10.0
@export_range(0.01, 0.25, 0.01) var remount_recovery_per_sec_when_supplied: float = 0.06
@export_range(0.01, 0.25, 0.01) var remount_drain_per_sec_under_zud_strain: float = 0.05


## Computes the effective wing pincer angle (`radians`) during a Stage 4
## `CRESCENT_ENCIRCLEMENT_TRAP` after accounting for Yılkı spare-horse depletion.
func compute_effective_crescent_wing_angle(raw_angle_rad: float, remount_horse_ratio: float) -> float:
	var clamped_ratio: float = clampf(remount_horse_ratio, 0.0, 1.0)
	if clamped_ratio >= min_remount_ratio_for_crescent_trap:
		return maxf(raw_angle_rad, 0.0)
	var deficit_ratio: float = (min_remount_ratio_for_crescent_trap - clamped_ratio) / maxf(0.05, min_remount_ratio_for_crescent_trap)
	var damping_mult: float = clampf(1.0 - deficit_ratio * yilki_depletion_wing_angle_damping, 0.25, 1.0)
	return maxf(raw_angle_rad, 0.0) * damping_mult


## Audits that `KutRules`, `CombatRules`, and `DiplomacyRules` are synchronized
## with this calibrated friction matrix.
func verify_cross_resource_parity(kut_rules: KutRules, combat_rules: CombatRules, diplomacy_rules: DiplomacyRules) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if kut_rules == null or combat_rules == null or diplomacy_rules == null:
		errors.append("CausalFrictionCalibration: missing one or more rules resources for parity check.")
		return errors
	if not is_equal_approx(kut_rules.critical_kut_threshold, critical_kut_council_threshold):
		errors.append("CausalFrictionCalibration: critical_kut_threshold mismatch.")
	if not is_equal_approx(kut_rules.epidemic_speed_multiplier, epidemic_speed_multiplier):
		errors.append("CausalFrictionCalibration: epidemic_speed_multiplier mismatch.")
	if not is_equal_approx(kut_rules.epidemic_daily_troop_attrition_ratio, epidemic_daily_troop_attrition_ratio):
		errors.append("CausalFrictionCalibration: epidemic_daily_troop_attrition_ratio mismatch.")
	if not is_equal_approx(kut_rules.kurgan_purification_kut_cost, kurgan_purification_kut_cost):
		errors.append("CausalFrictionCalibration: kurgan_purification_kut_cost mismatch.")
	if not is_equal_approx(combat_rules.fatigue_accumulation_per_sec, fatigue_accumulation_per_sec):
		errors.append("CausalFrictionCalibration: fatigue_accumulation_per_sec mismatch.")
	if not is_equal_approx(combat_rules.front_damage_multiplier, directional_front_multiplier):
		errors.append("CausalFrictionCalibration: front_damage_multiplier mismatch.")
	if not is_equal_approx(combat_rules.flank_damage_multiplier, directional_flank_multiplier):
		errors.append("CausalFrictionCalibration: flank_damage_multiplier mismatch.")
	if not is_equal_approx(combat_rules.rear_damage_multiplier, directional_rear_multiplier):
		errors.append("CausalFrictionCalibration: rear_damage_multiplier mismatch.")
	if not is_equal_approx(diplomacy_rules.free_warband_recruitment_glory_threshold, free_warband_glory_threshold):
		errors.append("CausalFrictionCalibration: free_warband_recruitment_glory_threshold mismatch.")
	return errors


func get_validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if calibration_id == &"":
		errors.append("CausalFrictionCalibration: calibration_id cannot be empty.")
	if directional_front_multiplier >= directional_flank_multiplier or directional_flank_multiplier >= directional_rear_multiplier:
		errors.append("CausalFrictionCalibration: directional multipliers must satisfy front < flank < rear.")
	if critical_kut_council_threshold <= 0.0 or free_warband_glory_threshold <= 0.0:
		errors.append("CausalFrictionCalibration: Kut and Glory thresholds must be positive.")
	if epidemic_speed_multiplier <= 0.0 or epidemic_speed_multiplier >= 1.0:
		errors.append("CausalFrictionCalibration: epidemic_speed_multiplier must be in (0, 1).")
	return errors
