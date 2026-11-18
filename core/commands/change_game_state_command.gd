class_name ChangeGameStateCommand
extends GameCommand
## Requests a transition of the global game state machine.

const ID: StringName = &"change_game_state"

var target_state: GameEnums.GameState = GameEnums.GameState.BOOT


func _init(p_target_state: GameEnums.GameState) -> void:
	target_state = p_target_state


func get_command_id() -> StringName:
	return ID
