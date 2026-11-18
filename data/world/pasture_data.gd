class_name PastureData
extends Resource
## Data layer (rank 1). Schema for Phase 7 **Seasonal Steppe Pasture &
## Overgrazing (`Aşırı Otlatma`) Ecology** (`res://data/world/pasture_data.tres`).

@export var pasture_id: StringName = &"steppe_seasonal_pasture"
@export_range(10.0, 1000.0, 5.0) var max_pasture_capacity: float = 100.0
## Depletion per livestock animal (`Yılkı` horses & sheep) per grazing tick.
@export_range(0.001, 5.0, 0.005) var pasture_depletion_rate: float = 0.08
## Regeneration per tick for rested waterside pastures after camp migration.
@export_range(0.5, 50.0, 0.5) var waterside_regeneration_per_tick: float = 15.0
@export_range(0.0, 80.0, 1.0) var grazed_warning_threshold: float = 40.0
@export_range(1, 20) var rebellion_grace_ticks_after_depletion: int = 2
@export_range(1.0, 50.0, 1.0) var rebellion_kut_penalty: float = 14.0


## Computes total pasture capacity consumed by `herd_size` animals during one grazing tick.
func compute_depletion_delta(herd_size: int, season_depletion_multiplier: float = 1.0) -> float:
	if herd_size <= 0:
		return 0.0
	return float(herd_size) * pasture_depletion_rate * maxf(season_depletion_multiplier, 0.1)


## Classifies pasture health from remaining capacity (`0..max_pasture_capacity`).
func classify_condition(remaining_capacity: float) -> GameEnums.PastureCondition:
	if remaining_capacity <= 0.001:
		return GameEnums.PastureCondition.DEPLETED_STARVING
	if remaining_capacity <= grazed_warning_threshold:
		return GameEnums.PastureCondition.GRAZED
	return GameEnums.PastureCondition.LUSH


## Returns schema violations (empty when valid).
func get_validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if pasture_id == &"":
		errors.append("PastureData: pasture_id cannot be empty.")
	if max_pasture_capacity <= 0.0 or pasture_depletion_rate <= 0.0:
		errors.append("PastureData: max_pasture_capacity and pasture_depletion_rate must be > 0.")
	return errors
