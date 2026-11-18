extends Node
## Autoload `GameManager` (rank 2). Owns the game state machine, the
## authoritative active world layer, and the Khaganate's **Kut** (Divine
## Mandate, 0-100 scale) & `Ak Sakallılar Konseyi` crisis governance.

const KUT_RULES_PATH: String = "res://data/governance/kut_rules.tres"
const REASON_ZUD_STARVATION: StringName = &"zud_starvation"
const REASON_BATTLE_LOSS: StringName = &"battle_loss"
const REASON_BATTLE_VICTORY: StringName = &"battle_victory"

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

var _kut_rules: KutRules = null
var _kut_score: float = 75.0
var _consecutive_battle_losses: int = 0
var _council_active: bool = false
var _legitimacy_multiplier: float = 1.0


func _ready() -> void:
	_kut_rules = ResourceLoader.load(KUT_RULES_PATH) as KutRules
	if _kut_rules == null:
		push_error("GameManager: failed to load KutRules at %s." % KUT_RULES_PATH)
	else:
		for error: String in _kut_rules.get_validation_errors():
			push_error("GameManager: %s" % error)
		_kut_score = _kut_rules.initial_kut

	CommandBus.register_handler(ChangeGameStateCommand.ID, _handle_change_state)
	CommandBus.register_handler(SwitchLayerCommand.ID, _handle_switch_layer)
	CommandBus.register_handler(ModifyKutCommand.ID, _handle_modify_kut)
	EventBus.layer_transition_started.connect(_on_layer_transition_started)
	EventBus.layer_transition_finished.connect(_on_layer_transition_finished)
	EventBus.zud_starvation_ticked.connect(_on_zud_starvation_ticked)
	EventBus.combat_resolved.connect(_on_combat_resolved)
	_set_state(GameEnums.GameState.LOADING)


func _exit_tree() -> void:
	CommandBus.unregister_handler(ChangeGameStateCommand.ID, _handle_change_state)
	CommandBus.unregister_handler(SwitchLayerCommand.ID, _handle_switch_layer)
	CommandBus.unregister_handler(ModifyKutCommand.ID, _handle_modify_kut)


## Current game state.
func get_state() -> GameEnums.GameState:
	return _state


## Authoritative active world layer.
func get_world_layer() -> GameEnums.WorldLayer:
	return _layer


## Current Kut (Divine Mandate) score in [0, 100].
func get_kut_score() -> float:
	return _kut_score


## Number of consecutive battle losses suffered.
func get_consecutive_battle_losses() -> int:
	return _consecutive_battle_losses


## True when Kut has dropped below the critical threshold (< 30) and the Ak Sakallılar Council is active.
func is_ak_sakallilar_council_active() -> bool:
	return _council_active


## Current internal legitimacy multiplier (reduced when Ak Sakallılar Council convenes).
func get_legitimacy_multiplier() -> float:
	return _legitimacy_multiplier


## Records a battle outcome, updating consecutive loss streaks and Kut.
func record_battle_outcome(is_victory: bool) -> float:
	if _kut_rules == null:
		return _kut_score
	if is_victory:
		_consecutive_battle_losses = 0
		_apply_kut_delta(_kut_rules.victory_kut_gain, REASON_BATTLE_VICTORY)
	else:
		_consecutive_battle_losses += 1
		var drain: float = _kut_rules.compute_battle_loss_drain(_consecutive_battle_losses)
		_apply_kut_delta(-drain, REASON_BATTLE_LOSS)
	return _kut_score


## Applies Zud (Winter starvation) Kut drain directly.
func apply_zud_starvation() -> float:
	if _kut_rules == null:
		return _kut_score
	_apply_kut_delta(-_kut_rules.zud_starvation_kut_drain, REASON_ZUD_STARVATION)
	return _kut_score


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


func _handle_modify_kut(command: GameCommand) -> bool:
	var modify: ModifyKutCommand = command as ModifyKutCommand
	if modify == null:
		return command.reject("Expected ModifyKutCommand.")
	_apply_kut_delta(modify.delta_kut, modify.reason)
	modify.resulting_kut = _kut_score
	modify.council_triggered = _council_active
	return true


func _apply_kut_delta(delta: float, reason: StringName) -> void:
	var max_kut: float = _kut_rules.max_kut if _kut_rules != null else 100.0
	var critical: float = _kut_rules.critical_kut_threshold if _kut_rules != null else 30.0
	var previous: float = _kut_score
	_kut_score = clampf(_kut_score + delta, 0.0, max_kut)
	if not is_equal_approx(previous, _kut_score):
		EventBus.kut_changed.emit(previous, _kut_score, reason)
	if _kut_score < critical:
		var penalty: float = _kut_rules.legitimacy_loss_penalty if _kut_rules != null else 0.25
		var skirmish: bool = _kut_rules.trigger_civil_skirmish_on_critical if _kut_rules != null else true
		_council_active = true
		_legitimacy_multiplier = clampf(1.0 - penalty, 0.0, 1.0)
		EventBus.ak_sakallilar_council_convened.emit(_kut_score, penalty, skirmish)
	else:
		_council_active = false
		_legitimacy_multiplier = 1.0


func _on_zud_starvation_ticked(_food_remaining: int, _season: SeasonData) -> void:
	apply_zud_starvation()


func _on_combat_resolved(result: CombatResult) -> void:
	if result == null:
		return
	if result.is_attacker_destroyed() and not result.is_defender_destroyed():
		record_battle_outcome(false)
	elif result.is_defender_destroyed() and not result.is_attacker_destroyed():
		record_battle_outcome(true)


func _set_state(next_state: GameEnums.GameState) -> void:
	var previous: GameEnums.GameState = _state
	_state = next_state
	get_tree().paused = _state == GameEnums.GameState.PAUSED
	EventBus.game_state_changed.emit(previous, _state)


func _on_layer_transition_started(_target_layer: GameEnums.WorldLayer, _focus_position: Vector3) -> void:
	_is_layer_transitioning = true


func _on_layer_transition_finished(_layer_reached: GameEnums.WorldLayer) -> void:
	_is_layer_transitioning = false
