class_name MergeForcesCommand
extends GameCommand
## Core command (rank 2). Merges an independent detachment (`detachment_army_id`)
## back into a target army (`target_army_id`), conserving total riders and
## pooled `quiver_ammo`.

const ID: StringName = &"merge_forces"

var target_army_id: int = 1
var detachment_army_id: int = 100

var merged_total_riders: int = 0
var merged_quiver_ammo: float = 0.0


func _init(p_target_army_id: int, p_detachment_army_id: int) -> void:
	target_army_id = p_target_army_id
	detachment_army_id = p_detachment_army_id


func get_command_id() -> StringName:
	return ID
