class_name PlacedBuildingRecord
extends RefCounted
## Core model (rank 2). Immutable record of a building placed on the micro
## settlement grid (`MicroZoneState`).

var instance_id: int = 0
var player_id: int = 1
var building_id: StringName = &""
var building_data: BuildingData = null
var zone_id: StringName = &""
var origin_coord: Vector2i = Vector2i.ZERO
var footprint: Vector2i = Vector2i.ONE
var world_position: Vector3 = Vector3.ZERO
