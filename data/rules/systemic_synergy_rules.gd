class_name SystemicSynergyRules
extends Resource
## Data layer (rank 1). Calibrated closed-form equilibrium coefficients,
## damping thresholds, saturation curves, clamps, and resonance triggers for
## Phase 26A (`SystemicSynergyMatrix`).

@export var rules_id: StringName = &"systemic_synergy_rules"

@export_group("Eq 1: Combat Power & Harmonic Bottleneck")
@export_range(0.05, 0.75, 0.01) var supply_floor_intercept: float = 0.25
@export_range(0.10, 1.00, 0.01) var supply_harmonic_span: float = 0.75
@export_range(0.10, 0.90, 0.01) var supply_water_weight: float = 0.55
@export_range(0.10, 0.90, 0.01) var supply_yilki_weight: float = 0.45
@export_range(0.01, 0.25, 0.01) var supply_ratio_floor: float = 0.05
@export_range(0.05, 1.00, 0.01) var artisan_max_bonus: float = 0.45
@export_range(1.0, 50.0, 0.5) var artisan_half_saturation: float = 12.0
@export_range(0.05, 0.80, 0.01) var commander_exp_max_bonus: float = 0.38
@export_range(5.0, 150.0, 1.0) var commander_exp_half_saturation: float = 50.0
@export_range(0.05, 0.75, 0.01) var commander_wound_penalty_coeff: float = 0.30
@export_range(1.0, 2.5, 0.05) var commander_wound_exponent: float = 1.3
@export_range(35.0, 70.0, 1.0) var commander_age_decline_start_years: float = 48.0
@export_range(10.0, 60.0, 1.0) var commander_age_decline_scale_years: float = 30.0
@export_range(0.05, 0.60, 0.01) var commander_age_decline_coeff: float = 0.22
@export_range(1.0, 2.5, 0.05) var commander_age_decline_exponent: float = 1.5
@export_range(0.25, 0.95, 0.01) var commander_factor_min: float = 0.55
@export_range(1.00, 2.00, 0.01) var commander_factor_max: float = 1.38
@export_range(0.15, 0.80, 0.01) var effective_commander_env_min: float = 0.35
@export_range(1.00, 2.00, 0.01) var effective_commander_env_max: float = 1.45
@export_range(0.05, 0.90, 0.01) var max_armor_weather_penalty: float = 0.65
@export_range(0.05, 0.90, 0.01) var max_ulus_sabotage_penalty: float = 0.75

@export_group("Eq 2: Black Market & Scarcity Elasticity")
@export_range(0.50, 1.50, 0.05) var market_base_mult: float = 1.0
@export_range(0.50, 4.00, 0.05) var market_tanh_span: float = 2.40
@export_range(1.50, 5.00, 0.05) var market_max_scarcity_mult: float = 3.40
@export_range(0.10, 2.50, 0.05) var market_tug_disruption_weight: float = 0.90
@export_range(0.10, 2.50, 0.05) var market_well_sabotage_weight: float = 1.15
@export_range(0.05, 1.50, 0.05) var market_zud_weight: float = 0.35
@export_range(0.05, 1.00, 0.02) var market_excess_regions_weight: float = 0.22
@export_range(0.25, 3.00, 0.05) var market_tore_elasticity_base: float = 1.20
@export_range(0.05, 2.00, 0.05) var market_tore_honor_damping: float = 0.65

@export_group("Eq 3: Dynamic Kut Entropy Anti-Snowball")
@export_range(0.10, 5.00, 0.05) var kut_glory_log_weight: float = 1.45
@export_range(0.10, 5.00, 0.05) var kut_kurgan_weight: float = 1.10
@export_range(0.10, 6.00, 0.05) var kut_honor_weight: float = 2.20
@export_range(0.10, 8.00, 0.05) var kut_army_convex_weight: float = 2.60
@export_range(1.05, 2.00, 0.05) var kut_army_norm_exponent: float = 1.25
@export_range(50.0, 1000.0, 10.0) var kut_army_norm_reference: float = 200.0
@export_range(0.10, 5.00, 0.05) var kut_overextension_weight: float = 1.35
@export_range(1.10, 2.50, 0.05) var kut_overextension_exponent: float = 1.65
@export_range(0.50, 10.0, 0.10) var kut_succession_crisis_drag: float = 2.80
@export_range(0.10, 5.0, 0.05) var kut_regency_drag: float = 1.25
@export_range(0.10, 8.0, 0.10) var kut_ulus_resentment_weight: float = 2.40
@export_range(-30.0, -1.0, 0.5) var kut_drift_clamp_min: float = -18.0
@export_range(1.0, 30.0, 0.5) var kut_drift_clamp_max: float = 18.0

@export_group("Eq 4: Courier & Information Tempo")
@export_range(0.05, 1.00, 0.01) var tempo_mirage_bonus_weight: float = 0.35
@export_range(0.05, 1.00, 0.01) var tempo_gazi_bonus_weight: float = 0.30
@export_range(0.05, 1.50, 0.05) var tempo_courier_delay_log_weight: float = 0.45
@export_range(0.10, 0.90, 0.05) var tempo_exposed_doctrine_penalty: float = 0.55
@export_range(0.10, 0.80, 0.05) var tempo_mult_min: float = 0.35
@export_range(1.10, 3.00, 0.05) var tempo_mult_max: float = 1.85

@export_group("Eq 5: Dread-Honor Coalition Pressure")
@export_range(20.0, 200.0, 5.0) var coalition_dread_scale: float = 100.0
@export_range(20.0, 200.0, 5.0) var coalition_honor_scale: float = 100.0
@export_range(0.05, 0.70, 0.05) var coalition_honor_damping_max: float = 0.35
@export_range(50.0, 1000.0, 10.0) var coalition_pressure_max: float = 500.0

@export_group("Cross-System Resonance Thresholds")
@export_range(1.05, 3.00, 0.05) var shadow_famine_min_market_mult: float = 1.45
@export_range(25.0, 95.0, 1.0) var dread_mirage_min_dread: float = 55.0
@export_range(2, 30) var artisan_boru_min_artisans: int = 8
@export_range(10.0, 150.0, 5.0) var artisan_boru_min_commander_vet: float = 35.0
@export_range(1, 8) var tore_kurultay_max_direct_regions: int = 3
@export_range(35.0, 95.0, 1.0) var tore_kurultay_min_honor: float = 65.0
@export_range(0.0, 0.60, 0.05) var tore_kurultay_max_ulus_resentment: float = 0.20
@export_range(1, 5) var exile_kingmaker_min_ops: int = 1


func get_validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if rules_id == &"":
		errors.append("SystemicSynergyRules: rules_id cannot be empty.")
	if not is_equal_approx(supply_water_weight + supply_yilki_weight, 1.0):
		errors.append("SystemicSynergyRules: supply_water_weight + supply_yilki_weight must sum to 1.0.")
	if not is_equal_approx(supply_floor_intercept + supply_harmonic_span, 1.0):
		errors.append("SystemicSynergyRules: supply_floor_intercept + supply_harmonic_span must sum to 1.0.")
	if supply_ratio_floor <= 0.0 or supply_ratio_floor >= 1.0:
		errors.append("SystemicSynergyRules: supply_ratio_floor must be within (0, 1).")
	if artisan_half_saturation <= 0.0 or commander_exp_half_saturation <= 0.0:
		errors.append("SystemicSynergyRules: Michaelis-Menten half-saturation constants must be positive.")
	if commander_age_decline_scale_years <= 0.0:
		errors.append("SystemicSynergyRules: commander_age_decline_scale_years must be positive.")
	if commander_factor_min <= 0.0 or commander_factor_max < commander_factor_min:
		errors.append("SystemicSynergyRules: invalid commander_factor bounds.")
	if effective_commander_env_min <= 0.0 or effective_commander_env_max < effective_commander_env_min:
		errors.append("SystemicSynergyRules: invalid effective_commander_env bounds.")
	if market_max_scarcity_mult < market_base_mult or market_max_scarcity_mult > 5.0:
		errors.append("SystemicSynergyRules: invalid market_max_scarcity_mult.")
	if not is_equal_approx(market_base_mult + market_tanh_span, market_max_scarcity_mult):
		errors.append("SystemicSynergyRules: market_base_mult + market_tanh_span must equal market_max_scarcity_mult.")
	if market_tore_elasticity_base <= 0.0:
		errors.append("SystemicSynergyRules: market_tore_elasticity_base must be positive.")
	if kut_army_norm_reference <= 0.0 or kut_army_norm_exponent < 1.0 or kut_overextension_exponent < 1.0:
		errors.append("SystemicSynergyRules: invalid Kut entropy convex scaling constants.")
	if kut_drift_clamp_max <= kut_drift_clamp_min:
		errors.append("SystemicSynergyRules: kut_drift_clamp_max must exceed kut_drift_clamp_min.")
	if tempo_mult_min <= 0.0 or tempo_mult_max < tempo_mult_min:
		errors.append("SystemicSynergyRules: invalid courier tempo multiplier bounds.")
	if coalition_dread_scale <= 0.0 or coalition_honor_scale <= 0.0 or coalition_pressure_max <= 0.0:
		errors.append("SystemicSynergyRules: coalition scales and cap must be positive.")
	return errors
