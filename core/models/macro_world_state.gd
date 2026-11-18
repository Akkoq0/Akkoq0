class_name MacroWorldState
extends RefCounted
## Core model (rank 2). The generated macro map, centred on the world origin.
##
## Broadcast through `EventBus.macro_world_generated` so consumers never need
## a reference to the generator node.

var grid_size: Vector2i = Vector2i.ZERO
var region_size_m: float = 0.0
var world_seed: int = 0
var _regions: Array[MacroRegion] = []


func _init(p_grid_size: Vector2i, p_region_size_m: float, p_world_seed: int) -> void:
	grid_size = p_grid_size
	region_size_m = p_region_size_m
	world_seed = p_world_seed
	_regions.resize(maxi(grid_size.x * grid_size.y, 0))


## True when `coord` lies inside the grid.
func is_in_bounds(coord: Vector2i) -> bool:
	return coord.x >= 0 and coord.y >= 0 and coord.x < grid_size.x and coord.y < grid_size.y


## Stores `region` at its own coordinate.
func set_region(region: MacroRegion) -> void:
	if region == null or not is_in_bounds(region.coord):
		push_error("MacroWorldState.set_region: invalid region.")
		return
	_regions[_to_index(region.coord)] = region


## Region at `coord`, or null when out of bounds / not generated.
func get_region(coord: Vector2i) -> MacroRegion:
	if not is_in_bounds(coord):
		return null
	return _regions[_to_index(coord)]


## Region containing `world_position`, or null when outside the map.
func get_region_at(world_position: Vector3) -> MacroRegion:
	return get_region(world_to_coord(world_position))


## All regions in row-major order.
func get_regions() -> Array[MacroRegion]:
	return _regions


## Grid coordinate containing `world_position` (may be out of bounds).
func world_to_coord(world_position: Vector3) -> Vector2i:
	if region_size_m <= 0.0:
		return Vector2i(-1, -1)
	var gx: int = floori(world_position.x / region_size_m + float(grid_size.x) * 0.5)
	var gz: int = floori(world_position.z / region_size_m + float(grid_size.y) * 0.5)
	return Vector2i(gx, gz)


## World-space centre (y = 0) of the region at `coord`.
func coord_to_world(coord: Vector2i) -> Vector3:
	return Vector3(
		(float(coord.x) + 0.5 - float(grid_size.x) * 0.5) * region_size_m,
		0.0,
		(float(coord.y) + 0.5 - float(grid_size.y) * 0.5) * region_size_m)


## Clamps `coord` into the grid.
func clamp_coord(coord: Vector2i) -> Vector2i:
	return Vector2i(clampi(coord.x, 0, grid_size.x - 1), clampi(coord.y, 0, grid_size.y - 1))


## Half extents (m) of the whole map on X/Z.
func get_half_extents() -> Vector2:
	return Vector2(float(grid_size.x), float(grid_size.y)) * region_size_m * 0.5


func _to_index(coord: Vector2i) -> int:
	return coord.y * grid_size.x + coord.x
