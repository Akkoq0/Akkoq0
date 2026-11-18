class_name BuildingData
extends Resource
## Data layer (rank 1). Schema for a constructible building.
##
## Supports nomadic (packable / relocatable) structures and exposes derived
## economic ROI metrics computed purely from the data in this resource.

enum Category {
	HOUSING = 0,
	PRODUCTION = 1,
	MILITARY = 2,
	SPIRITUAL = 3,
	STORAGE = 4,
	LOGISTICS = 5,
}

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var category: Category = Category.HOUSING

@export_group("Placement")
@export var allowed_terrains: Array[GameEnums.TerrainType] = []
## Footprint in micro tiles.
@export var footprint: Vector2i = Vector2i.ONE
@export_range(1, 100000) var max_health: int = 1
@export_range(0.0, 3600.0, 0.1) var build_time_sec: float = 0.0

@export_group("Nomadic Mobility")
## When true the building can be packed and carried by an army.
@export var is_nomadic_movable: bool = false
@export_range(0.0, 3600.0, 0.1) var pack_time_sec: float = 0.0
@export_range(0.0, 3600.0, 0.1) var unpack_time_sec: float = 0.0
## Weight added to the carrying army while packed.
@export_range(0.0, 100000.0, 0.1) var packed_weight: float = 0.0
## Fraction (0..1) of the construction cost charged on every relocation.
@export_range(0.0, 1.0, 0.01) var relocation_cost_ratio: float = 0.0

@export_group("Economy")
@export var construction_cost: Array[ResourceAmount] = []
@export var upkeep_per_minute: Array[ResourceAmount] = []
@export var production_per_minute: Array[ResourceAmount] = []
## Radius (m) within which friendly armies are resupplied. 0 = not a depot.
@export_range(0.0, 10000.0, 0.1) var supply_radius_m: float = 0.0


# --- Economic ROI metrics -------------------------------------------------

## Total trade value of the construction cost.
func get_construction_value() -> float:
	return ResourceAmount.sum_value(construction_cost)


## Gross produced value per minute.
func get_gross_income_per_minute() -> float:
	return ResourceAmount.sum_value(production_per_minute)


## Consumed upkeep value per minute.
func get_upkeep_value_per_minute() -> float:
	return ResourceAmount.sum_value(upkeep_per_minute)


## Net value generated per minute (gross - upkeep).
func get_net_income_per_minute() -> float:
	return get_gross_income_per_minute() - get_upkeep_value_per_minute()


## Minutes until the construction cost is repaid. INF when never profitable.
func get_payback_minutes() -> float:
	var net: float = get_net_income_per_minute()
	if net <= 0.0:
		return INF
	return get_construction_value() / net


## Return on investment over `horizon_minutes`: (net * horizon - cost) / cost.
## Returns 0.0 for free buildings to avoid division by zero.
func get_roi_ratio(horizon_minutes: float) -> float:
	var cost: float = get_construction_value()
	if cost <= 0.0:
		return 0.0
	return (get_net_income_per_minute() * horizon_minutes - cost) / cost


## Trade value charged when a nomadic building is relocated.
func get_relocation_cost_value() -> float:
	if not is_nomadic_movable:
		return INF
	return get_construction_value() * relocation_cost_ratio


## Total seconds a relocation takes (pack + unpack). INF for static buildings.
func get_relocation_time_sec() -> float:
	if not is_nomadic_movable:
		return INF
	return pack_time_sec + unpack_time_sec


## True when this building resupplies armies.
func is_supply_depot() -> bool:
	return supply_radius_m > 0.0


## Returns a list of human-readable schema violations (empty when valid).
func get_validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if id == &"":
		errors.append("BuildingData '%s' has an empty id." % resource_path)
	if allowed_terrains.is_empty():
		errors.append("BuildingData '%s': allowed_terrains is empty." % id)
	if footprint.x <= 0 or footprint.y <= 0:
		errors.append("BuildingData '%s': footprint must be positive." % id)
	if is_nomadic_movable and packed_weight <= 0.0:
		errors.append("BuildingData '%s': nomadic buildings need packed_weight > 0." % id)
	if not is_nomadic_movable and (pack_time_sec > 0.0 or relocation_cost_ratio > 0.0):
		errors.append("BuildingData '%s': static building defines nomadic fields." % id)
	errors.append_array(ResourceAmount.validate_list(construction_cost, "%s.construction_cost" % id))
	errors.append_array(ResourceAmount.validate_list(upkeep_per_minute, "%s.upkeep_per_minute" % id))
	errors.append_array(ResourceAmount.validate_list(production_per_minute, "%s.production_per_minute" % id))
	return errors
