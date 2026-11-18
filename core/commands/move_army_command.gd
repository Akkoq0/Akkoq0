class_name MoveArmyCommand
extends GameCommand
## Orders an army to march to a world position.

const ID: StringName = &"move_army"

var army_id: int = 0
var destination: Vector3 = Vector3.ZERO


func _init(p_army_id: int, p_destination: Vector3) -> void:
	army_id = p_army_id
	destination = p_destination


func get_command_id() -> StringName:
	return ID
