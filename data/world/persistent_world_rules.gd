class_name PersistentWorldRules
extends Resource
## Data layer (rank 1). Schema & calibrated math for Phase 18 **Persistent
## World Physics, Graduated Töre Peace & Non-Linear Anti-Snowball Equations**
## (`res://data/world/persistent_world_rules.tres`).

@export var rules_id: StringName = &"steppe_persistent_world_rules"

@export_group("Graduated Tore Peace (Hours)")
@export_range(1.0, 240.0, 1.0) var stage1_end_hours: float = 48.0 ## Gün 1-2 (0..48 saat)
@export_range(2.0, 360.0, 1.0) var stage2_end_hours: float = 72.0 ## Gün 3 (48..72 saat); 72h+ = Gün 4+
@export_range(1.0, 168.0, 1.0) var late_join_personal_peace_hours: float = 48.0
@export_range(0, 4) var late_join_border_margin_cells: int = 1

@export_group("Anti-Snowball Non-Linear Exponential Upkeep")
## Non-linear multiplier coefficient: `base * (1.0 + coeff * pow(unit_count, exponent))`
@export_range(0.0001, 0.1, 0.0001) var exponential_upkeep_coeff: float = 0.002
@export_range(1.0, 2.5, 0.05) var exponential_upkeep_exponent: float = 1.25

@export_group("Spoilage & Maintenance Decay")
## Daily spoilage rate on stored Food (active from Day 1, preventing Töre Peace hoarding).
@export_range(0.0, 0.5, 0.01) var food_daily_spoilage_rate: float = 0.08
@export_range(0, 50) var food_flat_spoilage_floor: int = 2
## Steel & Iron equipment upkeep for active field forces (`meteoric_iron` & `jade` never decay).
@export_range(0.0, 0.25, 0.005) var steel_armor_upkeep_ratio_per_day: float = 0.03
@export_range(0, 25) var iron_upkeep_per_100_units: int = 2

@export_group("Idle Stagnation Kut Erosion")
## Large Khaganate staying idle longer than threshold loses passive Kut from unmet Ülüş expectations.
@export_range(0.5, 30.0, 0.5) var stagnation_threshold_days: float = 3.0
@export_range(50, 2000, 10) var stagnation_large_empire_army_threshold: int = 300
@export_range(0.5, 25.0, 0.5) var stagnation_kut_drain_per_day: float = 2.5


## Maps elapsed persistent server hours onto the 3 graduated Töre Peace stages.
func get_stage_for_hours(elapsed_hours: float) -> GameEnums.TorePeaceStage:
	var h: float = maxf(elapsed_hours, 0.0)
	if h < stage1_end_hours:
		return GameEnums.TorePeaceStage.STAGE_1_FULL_TORE_PEACE
	if h < stage2_end_hours:
		return GameEnums.TorePeaceStage.STAGE_2_BORDER_SKIRMISH
	return GameEnums.TorePeaceStage.STAGE_3_TOTAL_STEPPE


## Non-linear exponential consumption equation:
## `base_amount * (1.0 + 0.002 * pow(unit_count, 1.25))`
func compute_exponential_consumption(base_amount: float, unit_count: int) -> float:
	if is_nan(base_amount) or is_inf(base_amount) or base_amount <= 0.0:
		return 0.0
	var count_f: float = float(maxi(unit_count, 0))
	return base_amount * (1.0 + exponential_upkeep_coeff * pow(count_f, exponential_upkeep_exponent))


## Food spoilage per elapsed day fraction.
func compute_food_spoilage(current_food: int, days_elapsed: float) -> int:
	if current_food <= 0 or days_elapsed <= 0.0 or is_nan(days_elapsed) or is_inf(days_elapsed):
		return 0
	var proportional: int = int(floorf(float(current_food) * food_daily_spoilage_rate * days_elapsed))
	var flat_floor: int = int(floorf(float(food_flat_spoilage_floor) * days_elapsed))
	return clampi(maxi(proportional, flat_floor), 0, current_food)


## Exponentially scaled Steel upkeep for maintaining armored armies (`0` when no armored troops).
func compute_steel_maintenance(available_steel: int, steel_equipped_troops: int, days_elapsed: float) -> int:
	if available_steel <= 0 or steel_equipped_troops <= 0 or days_elapsed <= 0.0 or is_nan(days_elapsed) or is_inf(days_elapsed):
		return 0
	var raw: float = compute_exponential_consumption(steel_armor_upkeep_ratio_per_day * float(steel_equipped_troops) * 0.1, steel_equipped_troops) * days_elapsed
	return clampi(int(roundf(raw)), 1 if steel_equipped_troops >= 50 and days_elapsed >= 1.0 else 0, available_steel)


## Exponentially scaled Iron maintenance upkeep.
func compute_iron_maintenance(available_iron: int, unit_count: int, days_elapsed: float) -> int:
	if available_iron <= 0 or unit_count <= 0 or days_elapsed <= 0.0 or is_nan(days_elapsed) or is_inf(days_elapsed):
		return 0
	var base: float = float(unit_count) / 100.0 * float(iron_upkeep_per_100_units)
	var scaled: float = compute_exponential_consumption(base, unit_count) * days_elapsed
	return clampi(int(roundf(scaled)), 0, available_iron)


## Passive Kut erosion for stagnant mega-empires idling past `stagnation_threshold_days`.
func compute_idle_kut_stagnation_drain(unit_count: int, idle_days: float, days_step: float) -> float:
	if unit_count < stagnation_large_empire_army_threshold or idle_days < stagnation_threshold_days or days_step <= 0.0:
		return 0.0
	var size_ratio: float = clampf(float(unit_count) / float(maxi(stagnation_large_empire_army_threshold, 1)), 1.0, 4.0)
	return clampf(stagnation_kut_drain_per_day * size_ratio * days_step, 0.0, 25.0)


func get_validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if rules_id == &"":
		errors.append("PersistentWorldRules: rules_id cannot be empty.")
	if stage1_end_hours <= 0.0 or stage2_end_hours <= stage1_end_hours:
		errors.append("PersistentWorldRules: require 0 < stage1_end_hours < stage2_end_hours.")
	if late_join_personal_peace_hours <= 0.0:
		errors.append("PersistentWorldRules: late_join_personal_peace_hours must be > 0.")
	if exponential_upkeep_coeff <= 0.0 or exponential_upkeep_exponent <= 1.0:
		errors.append("PersistentWorldRules: non-linear upkeep coeff > 0 and exponent > 1.0 required.")
	return errors
