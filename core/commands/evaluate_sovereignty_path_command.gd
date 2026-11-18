class_name EvaluateSovereigntyPathCommand
extends GameCommand
## Core command (rank 2). Records behavioral telemetry deltas for a player and
## dynamically re-evaluates their active `SovereigntyAlignment` without locking
## any alternative path (`zero quest lock-in`).

const ID: StringName = &"evaluate_sovereignty_path"

var player_id: int = 1
var kut_score: float = 75.0
var glory_score: float = 25.0
var add_tore_actions: int = 0
var add_raid_actions: int = 0
var add_toy_actions: int = 0
var add_refining_actions: int = 0
var add_trade_actions: int = 0
var add_migration_actions: int = 0
var add_defiance_actions: int = 0
var reset_counters_before_apply: bool = false

var previous_alignment: GameEnums.SovereigntyAlignment = GameEnums.SovereigntyAlignment.ULU_KAGAN_TORE_GUARDIAN
var active_alignment: GameEnums.SovereigntyAlignment = GameEnums.SovereigntyAlignment.ULU_KAGAN_TORE_GUARDIAN
var dominant_score: float = 0.0
var unlocked_strategic_options: PackedStringArray = PackedStringArray()


func _init(p_player_id: int, p_kut_score: float = 75.0, p_glory_score: float = 25.0) -> void:
	player_id = p_player_id
	kut_score = p_kut_score
	glory_score = p_glory_score


func get_command_id() -> StringName:
	return ID
