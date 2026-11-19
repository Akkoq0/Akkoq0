class_name WaterSourceNode
extends RefCounted
## Core model (rank 2). Represents a strategic steppe water route node (well,
## steppe stream, or oasis spring) used for hydration and scorched-earth defense.

var source_id: StringName = &""
var region_coord: Vector2i = Vector2i.ZERO
var source_type: GameEnums.WaterSourceType = GameEnums.WaterSourceType.WELL
var base_capacity: float = 100.0
var contaminated_seasons_remaining: int = 0
var frozen_in_winter: bool = false
var owner_id: int = 0


func _init(
		p_source_id: StringName = &"",
		p_coord: Vector2i = Vector2i.ZERO,
		p_type: GameEnums.WaterSourceType = GameEnums.WaterSourceType.WELL,
		p_owner_id: int = 0) -> void:
	source_id = p_source_id
	region_coord = p_coord
	source_type = p_type
	owner_id = p_owner_id
	frozen_in_winter = p_type == GameEnums.WaterSourceType.STEPPE_STREAM


func is_usable(is_winter_zud: bool) -> bool:
	if contaminated_seasons_remaining > 0:
		return false
	if is_winter_zud and source_type == GameEnums.WaterSourceType.STEPPE_STREAM:
		return false
	return true
