class_name MicroZoneState
extends RefCounted
## Core model (rank 2). A generated micro settlement zone for one macro region.

var zone_id: StringName = &""
var source_coord: Vector2i = Vector2i.ZERO
var grid_size: Vector2i = Vector2i.ZERO
var tile_size_m: float = 0.0
var world_center: Vector3 = Vector3.ZERO
var _tiles: Array[MicroTile] = []


func _init(p_source_coord: Vector2i, p_grid_size: Vector2i, p_tile_size_m: float, p_world_center: Vector3) -> void:
	source_coord = p_source_coord
	grid_size = p_grid_size
	tile_size_m = p_tile_size_m
	world_center = p_world_center
	zone_id = make_zone_id(p_source_coord)
	_tiles.resize(maxi(grid_size.x * grid_size.y, 0))


## Stable id for the zone generated from macro region `coord`.
static func make_zone_id(coord: Vector2i) -> StringName:
	return StringName("zone_%d_%d" % [coord.x, coord.y])


## True when `coord` lies inside the zone grid.
func is_in_bounds(coord: Vector2i) -> bool:
	return coord.x >= 0 and coord.y >= 0 and coord.x < grid_size.x and coord.y < grid_size.y


## Stores `tile` at its own coordinate.
func set_tile(tile: MicroTile) -> void:
	if tile == null or not is_in_bounds(tile.coord):
		push_error("MicroZoneState.set_tile: invalid tile.")
		return
	_tiles[tile.coord.y * grid_size.x + tile.coord.x] = tile


## Tile at `coord`, or null when out of bounds.
func get_tile(coord: Vector2i) -> MicroTile:
	if not is_in_bounds(coord):
		return null
	return _tiles[coord.y * grid_size.x + coord.x]


## All tiles in row-major order.
func get_tiles() -> Array[MicroTile]:
	return _tiles


## World-space centre (y = 0) of the tile at `coord`.
func tile_to_world(coord: Vector2i) -> Vector3:
	return world_center + Vector3(
		(float(coord.x) + 0.5 - float(grid_size.x) * 0.5) * tile_size_m,
		0.0,
		(float(coord.y) + 0.5 - float(grid_size.y) * 0.5) * tile_size_m)


## Half extents (m) of the zone on X/Z.
func get_half_extents() -> Vector2:
	return Vector2(float(grid_size.x), float(grid_size.y)) * tile_size_m * 0.5
