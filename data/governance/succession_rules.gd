class_name SuccessionRules
extends Resource
## Data layer (rank 1). Calibrated parameters for Phase 24 **Generational
## Transitions, Khagan/Commander Aging & Battle Scars, Veteran Turan Legacy,
## and Kurultay Succession Crisis / Ak Sakallılar Regency**.

@export var rules_id: StringName = &"succession_rules"

@export_group("Aging & Heir Maturity")
@export_range(1, 8) var seasons_per_year: int = 4
@export_range(35, 80) var natural_decline_age_years: int = 58
@export_range(50, 95) var max_natural_lifespan_years: int = 76
@export_range(12, 25) var heir_majority_age_years: int = 18
@export_range(20.0, 90.0, 1.0) var strong_heir_competence_threshold: float = 55.0
@export_range(2.0, 30.0, 1.0) var heir_training_competence_gain: float = 12.0
@export_range(5, 100) var heir_training_bullion_cost: int = 20

@export_group("Commander Legacy & Battle Trauma")
@export_range(0.002, 0.05, 0.001) var commander_turan_bonus_per_vet: float = 0.015
@export_range(0.05, 0.45, 0.01) var commander_turan_bonus_max: float = 0.25
@export_range(0.002, 0.03, 0.001) var commander_rout_resistance_per_vet: float = 0.008
@export_range(0.10, 0.55, 0.05) var commander_rout_resistance_max: float = 0.40
@export_range(5.0, 60.0, 1.0) var commander_death_morale_shock: float = 28.0
@export_range(5.0, 60.0, 1.0) var commander_death_cohesion_shock: float = 24.0
@export_range(0.01, 0.25, 0.01) var veteran_scar_combat_bonus: float = 0.10
@export_range(0.01, 0.20, 0.01) var veteran_scar_speed_penalty: float = 0.06
@export_range(1, 6) var max_battle_scars: int = 3

@export_group("Succession Crisis & Regency")
@export_range(0.40, 1.0, 0.05) var regency_tax_efficiency_mult: float = 0.80
@export_range(35.0, 95.0, 1.0) var regency_kut_cap: float = 65.0
@export_range(5.0, 45.0, 1.0) var crisis_ambitious_vassal_loyalty_drop: float = 22.0
@export_range(10, 200) var crisis_purge_silver_cost: int = 50
@export_range(5.0, 40.0, 1.0) var crisis_purge_dread_gain: float = 18.0
@export_range(10, 200) var crisis_appease_silver_cost: int = 65
@export_range(2.0, 30.0, 1.0) var crisis_appease_kut_cost: float = 10.0


func get_validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if rules_id == &"":
		errors.append("SuccessionRules: rules_id cannot be empty.")
	if seasons_per_year <= 0:
		errors.append("SuccessionRules: seasons_per_year must be positive.")
	if max_natural_lifespan_years <= natural_decline_age_years:
		errors.append("SuccessionRules: max_natural_lifespan_years must exceed natural_decline_age_years.")
	if strong_heir_competence_threshold <= 0.0 or strong_heir_competence_threshold > 100.0:
		errors.append("SuccessionRules: strong_heir_competence_threshold must be within (0, 100].")
	if regency_tax_efficiency_mult <= 0.0 or regency_tax_efficiency_mult > 1.0:
		errors.append("SuccessionRules: regency_tax_efficiency_mult must be within (0, 1].")
	if commander_death_morale_shock <= 0.0 or commander_death_cohesion_shock <= 0.0:
		errors.append("SuccessionRules: commander_death shocks must be positive.")
	return errors
