class_name SwitchLayerCommand
extends GameCommand
## Requests a macro <-> micro world layer switch.

const ID: StringName = &"switch_layer"

var target_layer: GameEnums.WorldLayer = GameEnums.WorldLayer.MACRO


func _init(p_target_layer: GameEnums.WorldLayer) -> void:
	target_layer = p_target_layer


func get_command_id() -> StringName:
	return ID
