class_name BuildingData
extends Resource
## Data layer (rank 1). Schema for a constructible building.
##
## Supports nomadic (packable / relocatable via `Sefer Arabası`) structures and
## exposes derived economic ROI metrics computed purely from this resource.

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

@export_group("Nomadic Mobility (Sefer Arabası)")
## When true the building can be packed into a Sefer Arabası and relocated.
@export var is_nomadic_movable: bool = false
## Identifier of the migration cart archetype used when packed.
@export var migration_cart_id: StringName = &"sefer_arabasi"
@export_range(0.0, 3600.0, 0.1) var pack_time_sec: float = 0.0
@export_range(0.0, 3600.0, 0.1) var unpack_time_sec: float = 0.0
## Weight added to the carrying army / migration cart while packed.
@export_range(0.0, 100000.0, 0.1) var packed_weight: float = 0.0
## Base fraction (0..1) of the construction cost charged on every relocation.
@export_range(0.0, 1.0, 0.01) var relocation_cost_ratio: float = 0.0
## Additional trade value charged per meter of migration distance.
@export_range(0.0, 100.0, 0.01) var relocation_distance_cost_per_meter: float = 0.25
## Base travel speed (m/s) of the Sefer Arabası when hauling this packed structure.
@export_range(0.1, 200.0, 0.1) var migration_cart_speed_m_per_sec: float = 6.0

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


## Net value generated per minute (gross * modifiers - upkeep).
func get_net_income_per_minute(authority_multiplier: float = 1.0, season_production_multiplier: float = 1.0) -> float:
	var effective_gross: float = get_gross_income_per_minute() * maxf(authority_multiplier, 0.0) * maxf(season_production_multiplier, 0.0)
	return effective_gross - get_upkeep_value_per_minute()


## Minutes until the construction cost is repaid. INF when never profitable.
func get_payback_minutes(authority_multiplier: float = 1.0, season_production_multiplier: float = 1.0) -> float:
	var net: float = get_net_income_per_minute(authority_multiplier, season_production_multiplier)
	if net <= 0.0:
		return INF
	return get_construction_value() / net


## Return on investment over `horizon_minutes` factoring in optional relocation
## count and Tamga/Authority multiplier:
##   ROI = (net_income * horizon - build_cost - relocation_count * reloc_cost) / build_cost
func get_roi_ratio(horizon_minutes: float, relocation_count: int = 0, authority_multiplier: float = 1.0) -> float:
	var cost: float = get_construction_value()
	if cost <= 0.0:
		return 0.0
	var reloc_penalty: float = 0.0
	if relocation_count > 0:
		if not is_nomadic_movable:
			return -INF
		reloc_penalty = float(relocation_count) * get_relocation_cost_value()
	var net_total: float = get_net_income_per_minute(authority_multiplier, 1.0) * horizon_minutes
	return (net_total - cost - reloc_penalty) / cost


## Base trade value charged when a nomadic building is relocated (distance = 0).
func get_relocation_cost_value() -> float:
	if not is_nomadic_movable:
		return INF
	return get_construction_value() * relocation_cost_ratio


## Base seconds a relocation takes (pack + unpack, distance = 0). INF for static buildings.
func get_relocation_time_sec() -> float:
	if not is_nomadic_movable:
		return INF
	return pack_time_sec + unpack_time_sec


## Dynamic relocation cost when packing into a `Sefer Arabası` and migrating `distance_m` meters.
func calculate_dynamic_relocation_cost_value(distance_m: float, terrain_movement_multiplier: float = 1.0, season_attrition_multiplier: float = 1.0) -> float:
	if not is_nomadic_movable:
		return INF
	var base_cost: float = get_relocation_cost_value()
	var distance_cost: float = maxf(distance_m, 0.0) * relocation_distance_cost_per_meter
	var terrain_factor: float = 1.0 / maxf(terrain_movement_multiplier, 0.1)
	var season_factor: float = maxf(season_attrition_multiplier, 0.1)
	return (base_cost + distance_cost) * terrain_factor * season_factor


## Dynamic relocation duration (seconds) when packing into a `Sefer Arabası`
## and hauling `distance_m` meters across terrain and season conditions.
func calculate_dynamic_relocation_time_sec(distance_m: float, terrain_movement_multiplier: float = 1.0, season_movement_multiplier: float = 1.0) -> float:
	if not is_nomadic_movable:
		return INF
	var effective_speed: float = migration_cart_speed_m_per_sec * maxf(terrain_movement_multiplier * season_movement_multiplier, 0.1)
	var travel_time_sec: float = maxf(distance_m, 0.0) / maxf(effective_speed, 0.1)
	return pack_time_sec + unpack_time_sec + travel_time_sec


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
