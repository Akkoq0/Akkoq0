class_name BallisticsRules
extends Resource
## Data layer (rank 1). Schema for Phase 7 **Vectorial Steppe Wind &
## Atmospheric Arrow Ballistics** (`res://data/combat/ballistics_rules.tres`).

@export var rules_id: StringName = &"steppe_atmospheric_ballistics"
@export_range(10.0, 500.0, 5.0) var base_bow_range_m: float = 120.0
## Minimum `Vector3.dot(shot_dir, wind_dir)` (`>= 0.50`) to qualify as a tailwind (`Arkadan Esen Rüzgar`).
@export_range(0.1, 0.99, 0.05) var tailwind_dot_threshold: float = 0.50
## Minimum wind speed (m/s) required for wind to alter arrow trajectory.
@export_range(0.5, 30.0, 0.5) var min_effective_wind_speed_m_per_sec: float = 2.0
## Wind speed (m/s) above which headwinds/crosswinds become a severe gale (`Şiddetli Fırtına`).
@export_range(5.0, 50.0, 1.0) var storm_wind_speed_threshold_m_per_sec: float = 12.0
## Temperature threshold (Celsius) below which pre-Zud freezing air degrades bowstring tension.
@export_range(-40.0, 5.0, 1.0) var pre_zud_freezing_temp_celsius: float = -5.0

@export_group("Tailwind Modifiers (Arkadan Esen Rüzgar)")
## Exact +25% range increase (`1.25x`) when shooting with a steppe tailwind.
@export_range(1.05, 2.0, 0.01) var tailwind_range_multiplier: float = 1.25
@export_range(1.01, 2.0, 0.01) var tailwind_accuracy_multiplier: float = 1.20
@export_range(1.0, 2.0, 0.01) var tailwind_whistling_morale_multiplier: float = 1.10
@export_range(0.5, 1.5, 0.01) var tailwind_ammo_consumption_multiplier: float = 1.00

@export_group("Headwind / Crosswind Pre-Zud Storm Modifiers")
@export_range(0.30, 0.95, 0.01) var storm_range_multiplier: float = 0.70
@export_range(0.30, 0.95, 0.01) var storm_accuracy_multiplier: float = 0.65
## Severe wind dampens the acoustic terror of whistling arrows (`Islıklı Ok`).
@export_range(0.20, 0.95, 0.01) var storm_whistling_morale_multiplier: float = 0.60
## Archers expend more arrows from their quivers (`Sadak`) to compensate for gale drift.
@export_range(1.05, 2.50, 0.05) var storm_ammo_consumption_multiplier: float = 1.35


## Returns schema violations (empty when valid).
func get_validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if rules_id == &"":
		errors.append("BallisticsRules: rules_id cannot be empty.")
	if not is_equal_approx(tailwind_range_multiplier, 1.25):
		errors.append("BallisticsRules: tailwind_range_multiplier must be 1.25 (+25% range).")
	if storm_range_multiplier >= 1.0 or storm_whistling_morale_multiplier >= 1.0 or storm_ammo_consumption_multiplier <= 1.0:
		errors.append("BallisticsRules: storm modifiers must reduce range/morale and increase ammo consumption.")
	return errors
