extends Node
## Autoload `GameManager` (rank 2). Owns the game state machine and the
## authoritative active world layer. Nothing else.

## Legal state transitions (engine flow, not balance data).
const ALLOWED_TRANSITIONS: Dictionary[GameEnums.GameState, Array] = {
	GameEnums.GameState.BOOT: [GameEnums.GameState.LOADING],
	GameEnums.GameState.LOADING: [GameEnums.GameState.PLAYING],
	GameEnums.GameState.PLAYING: [GameEnums.GameState.PAUSED, GameEnums.GameState.GAME_OVER],
	GameEnums.GameState.PAUSED: [GameEnums.GameState.PLAYING, GameEnums.GameState.GAME_OVER],
	GameEnums.GameState.GAME_OVER: [GameEnums.GameState.LOADING],
}

var _state: GameEnums.GameState = GameEnums.GameState.BOOT
var _layer: GameEnums.WorldLayer = GameEnums.WorldLayer.MACRO
var _is_layer_transitioning: bool = false


func _ready() -> void:
	CommandBus.register_handler(ChangeGameStateCommand.ID, _handle_change_state)
	CommandBus.register_handler(SwitchLayerCommand.ID, _handle_switch_layer)
	EventBus.layer_transition_started.connect(_on_layer_transition_started)
	EventBus.layer_transition_finished.connect(_on_layer_transition_finished)
	_set_state(GameEnums.GameState.LOADING)


func _exit_tree() -> void:
	CommandBus.unregister_handler(ChangeGameStateCommand.ID, _handle_change_state)
	CommandBus.unregister_handler(SwitchLayerCommand.ID, _handle_switch_layer)


## Current game state.
func get_state() -> GameEnums.GameState:
	return _state


## Authoritative active world layer.
func get_world_layer() -> GameEnums.WorldLayer:
	return _layer


## True when `from` -> `to` is a legal transition.
func can_transition(from: GameEnums.GameState, to: GameEnums.GameState) -> bool:
	var targets: Array = ALLOWED_TRANSITIONS.get(from, [])
	return targets.has(to)


func _handle_change_state(command: GameCommand) -> bool:
	var change: ChangeGameStateCommand = command as ChangeGameStateCommand
	if change == null:
		return command.reject("Expected ChangeGameStateCommand.")
	if not can_transition(_state, change.target_state):
		return command.reject("Illegal transition %s -> %s." % [
			GameEnums.GameState.keys()[_state], GameEnums.GameState.keys()[change.target_state]])
	_set_state(change.target_state)
	return true


func _handle_switch_layer(command: GameCommand) -> bool:
	var request: SwitchLayerCommand = command as SwitchLayerCommand
	if request == null:
		return command.reject("Expected SwitchLayerCommand.")
	if _state != GameEnums.GameState.PLAYING:
		return command.reject("Layer switching is only allowed while PLAYING.")
	if _is_layer_transitioning:
		return command.reject("A layer transition is already running.")
	if request.target_layer == _layer:
		return command.reject("Already on the requested layer.")
	var previous: GameEnums.WorldLayer = _layer
	_layer = request.target_layer
	EventBus.world_layer_changed.emit(previous, _layer)
	return true


func _set_state(next_state: GameEnums.GameState) -> void:
	var previous: GameEnums.GameState = _state
	_state = next_state
	get_tree().paused = _state == GameEnums.GameState.PAUSED
	EventBus.game_state_changed.emit(previous, _state)


func _on_layer_transition_started(_target_layer: GameEnums.WorldLayer, _focus_position: Vector3) -> void:
	_is_layer_transitioning = true


func _on_layer_transition_finished(_layer_reached: GameEnums.WorldLayer) -> void:
	_is_layer_transitioning = false
