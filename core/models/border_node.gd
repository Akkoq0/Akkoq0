class_name BorderNode
extends RefCounted
## Core model (rank 2). Strategic frontier sub-node inside a macro region
## (Ore Quarry, Caravan Pass, River Crossing, Watchtower Hill) where riders
## can immediately plant a Bozkır Tuğu without a Yurt Claim.

var node_id: StringName = &""
var region_coord: Vector2i = Vector2i.ZERO
var node_type: GameEnums.BorderNodeType = GameEnums.BorderNodeType.ORE_QUARRY_NODE
var owner_id: int = 0
var position: Vector3 = Vector3.ZERO
var has_tug_planted: bool = false
var tug_radius_m: float = 0.0
var ore_id: StringName = &""


func _init(
		p_node_id: StringName = &"",
		p_region_coord: Vector2i = Vector2i.ZERO,
		p_node_type: GameEnums.BorderNodeType = GameEnums.BorderNodeType.ORE_QUARRY_NODE,
		p_position: Vector3 = Vector3.ZERO,
		p_ore_id: StringName = &"",
		p_owner_id: int = 0) -> void:
	node_id = p_node_id
	region_coord = p_region_coord
	node_type = p_node_type
	position = p_position
	ore_id = p_ore_id
	owner_id = p_owner_id
	has_tug_planted = p_owner_id > 0


## Distance in meters to another BorderNode on the macro plane.
func distance_to(other: BorderNode) -> float:
	if other == null:
		return INF
	return position.distance_to(other.position)


## True when both nodes project active Tuğ spheres from hostile owners and intersect.
func overlaps_enemy_tug(other: BorderNode) -> bool:
	if other == null or other == self:
		return false
	if not has_tug_planted or not other.has_tug_planted:
		return false
	if owner_id <= 0 or other.owner_id <= 0 or owner_id == other.owner_id:
		return false
	if tug_radius_m <= 0.0 or other.tug_radius_m <= 0.0:
		return false
	return position.distance_to(other.position) < (tug_radius_m + other.tug_radius_m)
