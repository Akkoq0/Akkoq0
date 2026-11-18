class_name SelectCollapsePathCommand
extends GameCommand
## Request command (rank 2). Commits the defeated player to one of the 3
## asymmetric recovery paths (`SUBMIT_VASSAL`, `FLEE_HOMELESS_EXILE`,
## `REBUILD_AT_FRONTIER`).

const ID: StringName = &"select_collapse_path"

var player_id: int = 0
var choice: GameEnums.CollapsePathChoice = GameEnums.CollapsePathChoice.FLEE_HOMELESS_EXILE
var requested_tribute_rate: float = 0.20
var slot_seed: int = 0
var frontier_grid_size: Vector2i = Vector2i(12, 12)

# Written by CollapseRecoveryFSM
var resulting_state: GameEnums.CollapseState = GameEnums.CollapseState.SOVEREIGN
var overlord_id: int = 0
var applied_tribute_rate: float = 0.0
var frontier_coord: Vector2i = Vector2i.ZERO
var kut_cap: float = 100.0
var exile_army_cap: int = 0
var can_use_fixed_refining: bool = true


func _init(
		p_player_id: int,
		p_choice: GameEnums.CollapsePathChoice,
		p_requested_tribute_rate: float = 0.20,
		p_slot_seed: int = 0,
		p_frontier_grid_size: Vector2i = Vector2i(12, 12)) -> void:
	player_id = p_player_id
	choice = p_choice
	requested_tribute_rate = p_requested_tribute_rate
	slot_seed = p_slot_seed
	frontier_grid_size = p_frontier_grid_size


func get_command_id() -> StringName:
	return ID
