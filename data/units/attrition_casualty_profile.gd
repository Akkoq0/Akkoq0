class_name AttritionCasualtyProfile
extends Resource

@export var profile_id: StringName = &"default_attrition_casualty_profile"
@export_range(0.05, 0.9, 0.01) var wounded_survival_ratio: float = 0.45
@export_range(0.05, 0.7, 0.01) var max_wounded_speed_penalty: float = 0.35
@export_range(0.05, 1.0, 0.01) var healer_recovery_ratio_per_tick: float = 0.40
@export_range(0.05, 1.0, 0.01) var neglect_mortality_ratio_per_tick: float = 0.35
@export_range(0.05, 0.8, 0.01) var veteran_loss_tactical_penalty_weight: float = 0.35
@export_range(0.05, 0.8, 0.01) var veteran_loss_morale_penalty_weight: float = 0.30
@export_range(1.0, 45.0, 0.5) var raw_recruit_cohesion_cap_penalty_max: float = 28.0
@export_range(0.5, 25.0, 0.5) var cohesion_acclimation_recovery_per_sec: float = 3.5
@export_range(0.01, 0.6, 0.01) var commander_fatigue_efficiency_penalty_weight: float = 0.25


func is_valid() -> bool:
	return get_validation_errors().is_empty()


func get_validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if profile_id == &"":
		errors.append("AttritionCasualtyProfile.profile_id cannot be empty.")
	if wounded_survival_ratio <= 0.0 or wounded_survival_ratio >= 1.0:
		errors.append("AttritionCasualtyProfile.wounded_survival_ratio must be in (0, 1).")
	if max_wounded_speed_penalty <= 0.0 or max_wounded_speed_penalty >= 0.9:
		errors.append("AttritionCasualtyProfile.max_wounded_speed_penalty must be in (0, 0.9).")
	return errors
