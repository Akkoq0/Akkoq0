class_name CaptiveLaborRules
extends Resource
## Data layer (rank 1). Schema for Phase 7 **Töre Law & Captive Labor
## Integration** (`res://data/governance/captive_labor_rules.tres`).

@export var rules_id: StringName = &"tore_captive_labor_rules"
## Bullion (`silver_gold`) deposited into treasury per ransomed enemy noble/Bey.
@export_range(5, 500, 5) var bullion_ransom_per_noble: int = 35
## Diplomatic trust gained per noble released in an envoy exchange (`elçi takası`).
@export_range(1.0, 50.0, 1.0) var trust_gain_per_exchanged_noble: float = 12.0
## Minimum enslaved workers required in Quarries and NomadicForges to reach the full 30% discount.
@export_range(5, 500, 5) var workers_for_max_efficiency: int = 30
## Maximum construction time and raw material production cost discount (`0.30` = 30% cheaper/faster).
@export_range(0.05, 0.75, 0.05) var max_labor_discount_ratio: float = 0.30
## Default core clan population of a nomadic settlement (`Oba Ana Nüfusu`).
@export_range(20, 5000, 10) var default_core_clan_population: int = 120
## Base revolt risk factor when `captured_slave_workers > core_clan_population`.
@export_range(0.10, 1.0, 0.05) var revolt_risk_per_excess_ratio: float = 0.65
@export_range(1.0, 40.0, 1.0) var slave_revolt_kut_penalty: float = 10.0


## Computes the discount ratio (`0.0 .. 0.30`) applied to `construction_time`
## and raw material production costs based on active `slave_workers`.
func compute_labor_discount_ratio(slave_workers: int) -> float:
	if slave_workers <= 0 or workers_for_max_efficiency <= 0:
		return 0.0
	var fill: float = clampf(float(slave_workers) / float(workers_for_max_efficiency), 0.0, 1.0)
	return max_labor_discount_ratio * fill


## Computes `slave_revolt_risk` (`0.0 .. 1.0`). Positive whenever `slave_workers > core_clan_population`.
func compute_slave_revolt_risk(slave_workers: int, core_clan_population: int) -> float:
	var pop: int = maxi(core_clan_population, 1)
	if slave_workers <= pop:
		return 0.0
	var excess_ratio: float = float(slave_workers - pop) / float(pop)
	return clampf(excess_ratio * revolt_risk_per_excess_ratio, 0.05, 1.0)


## Returns schema violations (empty when valid).
func get_validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if rules_id == &"":
		errors.append("CaptiveLaborRules: rules_id cannot be empty.")
	if not is_equal_approx(max_labor_discount_ratio, 0.30):
		errors.append("CaptiveLaborRules: max_labor_discount_ratio must be 0.30 (30%).")
	if bullion_ransom_per_noble <= 0:
		errors.append("CaptiveLaborRules: bullion_ransom_per_noble must be > 0.")
	return errors
