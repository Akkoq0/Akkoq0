extends Node3D
## Main scene coordinator (rank 4). Transitions the game from LOADING to
## PLAYING once the macro map has been generated.


func _ready() -> void:
	EventBus.macro_world_generated.connect(_on_macro_world_generated, CONNECT_ONE_SHOT)


func _on_macro_world_generated(_world_state: MacroWorldState) -> void:
	CommandBus.dispatch(ChangeGameStateCommand.new(GameEnums.GameState.PLAYING))
