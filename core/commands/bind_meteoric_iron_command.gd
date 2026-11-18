class_name BindMeteoricIronCommand
extends GameCommand
## Validates and consumes Meteoric Iron for commander weapons or totem ascension.

const ID: StringName = &"bind_meteoric_iron"

var player_id: int = 0
var target_id: StringName = &""
var for_totem_ascension: bool = false
var consumed_amount: int = 0


func _init(p_player_id: int, p_target_id: StringName, p_for_totem_ascension: bool = false) -> void:
	player_id = p_player_id
	target_id = p_target_id
	for_totem_ascension = p_for_totem_ascension


func get_command_id() -> StringName:
	return ID
