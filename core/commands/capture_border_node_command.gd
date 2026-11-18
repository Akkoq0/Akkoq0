class_name CaptureBorderNodeCommand
extends GameCommand
## Request command (rank 2). Instantaneous frontier capture & Bozkır Tuğu
## banner planting on a strategic BorderNode (Ore Quarry, Caravan Pass,
## River Crossing, or Watchtower Hill).

const ID: StringName = &"capture_border_node"

var actor_id: int = 0
var region_coord: Vector2i = Vector2i.ZERO
var node_id: StringName = &""
var plant_tug: bool = true

# Written by TerritoryManager
var previous_owner_id: int = 0
var tug_radius_m: float = 0.0
var overlapping_enemy_tug_count: int = 0
var caravan_disruption_ratio: float = 0.0


func _init(p_actor_id: int, p_region_coord: Vector2i, p_node_id: StringName, p_plant_tug: bool = true) -> void:
	actor_id = p_actor_id
	region_coord = p_region_coord
	node_id = p_node_id
	plant_tug = p_plant_tug


func get_command_id() -> StringName:
	return ID
