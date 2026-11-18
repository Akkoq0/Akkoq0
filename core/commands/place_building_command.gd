class_name PlaceBuildingCommand
extends GameCommand
## Core command (rank 2). Places a constructible building (`ger_camp.tres`,
## `nomadic_forge.tres`, `quarry.tres`, `kurgan_shrine.tres`) onto a micro
## settlement zone grid with grid snapping, collision checking, and treasury
## construction cost deduction.

const ID: StringName = &"place_building"

var player_id: int = 1
var building_data: BuildingData = null
var grid_coord: Vector2i = Vector2i.ZERO
var zone_override: MicroZoneState = null
var use_world_click: bool = false
var world_click_position: Vector3 = Vector3.ZERO

var placed_instance_id: int = 0
var snapped_grid_coord: Vector2i = Vector2i.ZERO
var snapped_world_position: Vector3 = Vector3.ZERO
var record: PlacedBuildingRecord = null


func _init(p_player_id: int, p_building_data: BuildingData, p_grid_coord: Vector2i, p_zone_override: MicroZoneState = null) -> void:
	player_id = p_player_id
	building_data = p_building_data
	grid_coord = p_grid_coord
	zone_override = p_zone_override


func get_command_id() -> StringName:
	return ID
