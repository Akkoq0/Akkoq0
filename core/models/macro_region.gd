class_name MacroRegion
extends RefCounted
## Core model (rank 2). Runtime state of one strategic map region.

var coord: Vector2i = Vector2i.ZERO
var world_center: Vector3 = Vector3.ZERO
var elevation: float = 0.0
var moisture: float = 0.0
var terrain: TerrainData = null
## ore_id -> remaining units in this region.
var ore_deposits: Dictionary[StringName, int] = {}


func _init(p_coord: Vector2i, p_world_center: Vector3, p_elevation: float, p_moisture: float, p_terrain: TerrainData) -> void:
	coord = p_coord
	world_center = p_world_center
	elevation = p_elevation
	moisture = p_moisture
	terrain = p_terrain


## True when this region holds at least one ore deposit.
func has_deposits() -> bool:
	return not ore_deposits.is_empty()
