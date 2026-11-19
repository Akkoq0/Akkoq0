class_name SteppeEntropyCalculator
extends RefCounted
## Core layer (rank 2). Deterministic Phase 18 non-linear anti-snowball equations.
## Mirrors calibrated formulas in `PersistentWorldRules` without allocating state.


static func compute_exponential_consumption(base_amount: float, unit_count: int, coeff: float = 0.002, exponent: float = 1.25) -> float:
	if is_nan(base_amount) or is_inf(base_amount) or base_amount <= 0.0:
		return 0.0
	var count_f: float = float(maxi(unit_count, 0))
	return base_amount * (1.0 + maxf(coeff, 0.0) * pow(count_f, maxf(exponent, 1.0)))


static func compute_food_spoilage(current_food: int, days_elapsed: float, daily_rate: float = 0.08, flat_floor: int = 2) -> int:
	if current_food <= 0 or days_elapsed <= 0.0 or is_nan(days_elapsed) or is_inf(days_elapsed):
		return 0
	var proportional: int = int(floorf(float(current_food) * clampf(daily_rate, 0.0, 1.0) * days_elapsed))
	var floor_amt: int = int(floorf(float(maxi(flat_floor, 0)) * days_elapsed))
	return clampi(maxi(proportional, floor_amt), 0, current_food)


static func compute_steel_upkeep(available_steel: int, steel_troops: int, days_elapsed: float, armor_ratio: float = 0.03) -> int:
	if available_steel <= 0 or steel_troops <= 0 or days_elapsed <= 0.0 or is_nan(days_elapsed) or is_inf(days_elapsed):
		return 0
	var raw: float = compute_exponential_consumption(armor_ratio * float(steel_troops) * 0.1, steel_troops) * days_elapsed
	var min_cost: int = 1 if steel_troops >= 50 and days_elapsed >= 1.0 else 0
	return clampi(int(roundf(raw)), min_cost, available_steel)


static func compute_idle_kut_stagnation(unit_count: int, idle_days: float, days_step: float, threshold_days: float = 3.0, army_threshold: int = 300, drain_per_day: float = 2.5) -> float:
	if unit_count < maxi(army_threshold, 1) or idle_days < threshold_days or days_step <= 0.0:
		return 0.0
	var size_ratio: float = clampf(float(unit_count) / float(maxi(army_threshold, 1)), 1.0, 4.0)
	return clampf(drain_per_day * size_ratio * days_step, 0.0, 25.0)
