class_name RestoreWaterSourceCommand
extends GameCommand
## Cleanses contaminated wells or digs/reopens a water source in `region_coord`.

const ID: StringName = &"restore_water_source"

var actor_id: int = 1
var region_coord: Vector2i = Vector2i.ZERO
var source_id: StringName = &""

var restored: bool = false
var remaining_usable_sources: int = 0


func _init(p_actor_id: int = 1, p_region_coord: Vector2i = Vector2i.ZERO, p_source_id: StringName = &"") -> void:
	actor_id = p_actor_id
	region_coord = p_region_coord
	source_id = p_source_id


func get_command_id() -> StringName:
	return ID
