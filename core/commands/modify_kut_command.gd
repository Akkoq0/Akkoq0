class_name ModifyKutCommand
extends GameCommand
## Adjusts the Khaganate's Kut (Divine Mandate) score on the 0-100 scale.

const ID: StringName = &"modify_kut"

var delta_kut: float = 0.0
var reason: StringName = &""
var resulting_kut: float = 0.0
var council_triggered: bool = false


func _init(p_delta_kut: float, p_reason: StringName) -> void:
	delta_kut = p_delta_kut
	reason = p_reason


func get_command_id() -> StringName:
	return ID
