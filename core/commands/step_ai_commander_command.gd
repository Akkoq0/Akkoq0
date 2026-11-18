class_name StepAICommanderCommand
extends GameCommand
## Core command (rank 2). Advances one deterministic decision cycle of the
## Phase 6 **AI Commander** for a rival dynasty (`karluk`, `kipchak`, `oghuz`)
## or a roaming rogue warband (`Yersiz Yurtsuz Çeriler`).

const ID: StringName = &"step_ai_commander"

var agent_id: StringName = &""
var is_rogue_warband: bool = false
var target_player_army_id: int = 1
var target_depot_id: int = 1

var previous_phase: GameEnums.AICommanderPhase = GameEnums.AICommanderPhase.GATHER_RESOURCES
var new_phase: GameEnums.AICommanderPhase = GameEnums.AICommanderPhase.GATHER_RESOURCES
var raid_launched: bool = false
var chosen_turan_phase: GameEnums.TuranTacticPhase = GameEnums.TuranTacticPhase.RECON_DUST_SCREEN
var raid_target_type: StringName = &""


func _init(p_agent_id: StringName, p_is_rogue_warband: bool = false, p_target_player_army_id: int = 1, p_target_depot_id: int = 1) -> void:
	agent_id = p_agent_id
	is_rogue_warband = p_is_rogue_warband
	target_player_army_id = p_target_player_army_id
	target_depot_id = p_target_depot_id


func get_command_id() -> StringName:
	return ID
