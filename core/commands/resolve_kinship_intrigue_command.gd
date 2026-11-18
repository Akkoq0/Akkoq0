class_name ResolveKinshipIntrigueCommand
extends GameCommand
## Core command (rank 2). Executes the player's chosen response to a Bey's
## faction plot or internal uprising (`BESTOW_TITLE_AND_TOY_SHARE`,
## `SUPPRESS_WITH_LOYAL_GUARD`, or `NEGOTIATE_KINSHIP_BALANCE`).

const ID: StringName = &"resolve_kinship_intrigue"

var player_id: int = 1
var bey_id: StringName = &"tarkan_bey"
var action: GameEnums.IntrigueResolutionAction = GameEnums.IntrigueResolutionAction.BESTOW_TITLE_AND_TOY_SHARE

var restored_loyalty: float = 70.0
var remaining_grievance: float = 0.0
var resulting_stage: GameEnums.IntriguePlotStage = GameEnums.IntriguePlotStage.LOYAL_CALM


func _init(p_player_id: int, p_bey_id: StringName, p_action: GameEnums.IntrigueResolutionAction) -> void:
	player_id = p_player_id
	bey_id = p_bey_id
	action = p_action


func get_command_id() -> StringName:
	return ID
