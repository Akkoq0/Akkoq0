class_name SummonTotemCommand
extends GameCommand
## Requests that a player summons a totem at a world position.

const ID: StringName = &"summon_totem"

var player_id: int = 0
var totem_id: StringName = &""
var position: Vector3 = Vector3.ZERO


func _init(p_player_id: int, p_totem_id: StringName, p_position: Vector3) -> void:
	player_id = p_player_id
	totem_id = p_totem_id
	position = p_position


func get_command_id() -> StringName:
	return ID
