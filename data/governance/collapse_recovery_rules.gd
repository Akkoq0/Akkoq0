class_name CollapseRecoveryRules
extends Resource
## Data layer (rank 1). Calibrated schema for Phase 20 **Asymmetric Losing
## Experience, Two-Way Retreat Truce, Vassal Beylik, Yersiz Yurtsuz Exile
## Kingmaker & Frontier Uç Beyliği Rebirth**.

@export var rules_id: StringName = &"collapse_recovery_rules"

@export_group("Collapse Truce & Vassal Constraints")
@export_range(4.0, 48.0, 1.0) var truce_window_hours: float = 18.0
@export_range(0.05, 0.30, 0.01) var vassal_tribute_rate_min: float = 0.15
@export_range(0.15, 0.45, 0.01) var vassal_tribute_rate_max: float = 0.25
@export_range(0.15, 0.25, 0.01) var vassal_default_tribute_rate: float = 0.20
@export_range(20.0, 80.0, 1.0) var vassal_max_kut_cap: float = 50.0
@export_range(10.0, 50.0, 1.0) var vassal_coup_overlord_kut_threshold: float = 30.0
@export_range(20, 500) var vassal_ransom_bullion_cost: int = 120

@export_group("Homeless Exile & Anti-Troll Extinction")
@export_range(1.0, 2.5, 0.05) var exile_speed_multiplier: float = 1.45
@export_range(0.10, 1.0, 0.05) var exile_upkeep_multiplier: float = 0.40
@export_range(0.0, 0.80, 0.05) var exile_forest_concealment_bonus: float = 0.45
@export_range(40, 400) var exile_max_army_cap: int = 160
@export_range(20.0, 100.0, 1.0) var exile_initial_hope: float = 80.0
@export_range(5.0, 60.0, 1.0) var exile_hope_decay_per_season: float = 22.0
@export_range(5.0, 50.0, 1.0) var exile_hope_gain_per_operation: float = 18.0
@export_range(1, 10) var exile_intel_sale_meteoric_reward: int = 2

@export_group("Frontier March & Rebirth")
@export_range(20.0, 100.0, 1.0) var frontier_edge_pasture_cap: float = 55.0
@export_range(1.0, 2.5, 0.05) var frontier_winter_zud_multiplier: float = 1.35
@export_range(0.25, 1.0, 0.05) var frontier_ore_richness_multiplier: float = 0.65
@export_range(1, 16) var rebirth_cooldown_seasons: int = 4


func get_validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if rules_id == &"":
		errors.append("CollapseRecoveryRules: rules_id cannot be empty.")
	if vassal_tribute_rate_min <= 0.0 or vassal_tribute_rate_max < vassal_tribute_rate_min:
		errors.append("CollapseRecoveryRules: invalid vassal tribute bounds.")
	if exile_max_army_cap <= 0:
		errors.append("CollapseRecoveryRules: exile_max_army_cap must be positive.")
	if rebirth_cooldown_seasons <= 0:
		errors.append("CollapseRecoveryRules: rebirth_cooldown_seasons must be positive.")
	return errors
