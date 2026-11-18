class_name StepKinshipIntrigueCommand
extends GameCommand
## Core command (rank 2). Advances kinship intrigue and grievance evaluation
## for `bey_id` based on unfair Toy/Ülüş shares, loot neglect, and low Kut.

const ID: StringName = &"step_kinship_intrigue"

var bey_id: StringName = &"tarkan_bey"
var kinship_branch: StringName = &"eastern_wing_kin"
var ambition_override: float = -1.0
var unfair_toy_share: bool = false
var low_kut_crisis: bool = false
var target_army_id_for_sabotage: int = 1

var resulting_loyalty: float = 70.0
var resulting_grievance: float = 10.0
var resulting_stage: GameEnums.IntriguePlotStage = GameEnums.IntriguePlotStage.LOYAL_CALM
var defected_troops: int = 0
var supply_sabotaged: bool = false


func _init(p_bey_id: StringName, p_unfair_toy_share: bool = false, p_low_kut_crisis: bool = false, p_ambition_override: float = -1.0, p_target_army_id: int = 1) -> void:
	bey_id = p_bey_id
	unfair_toy_share = p_unfair_toy_share
	low_kut_crisis = p_low_kut_crisis
	ambition_override = p_ambition_override
	target_army_id_for_sabotage = p_target_army_id


func get_command_id() -> StringName:
	return ID
