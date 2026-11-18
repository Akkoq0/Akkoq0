class_name EnactCouncilDecreeCommand
extends GameCommand
## Core command (rank 2). Enacts one of the 3 strategic dilemmas presented by
## the **Ak Sakallılar Konseyi** (`TRADITION`, `EXPANSION`, `SACRIFICE`).

const ID: StringName = &"enact_council_decree"

var player_id: int = 1
var choice: GameEnums.CouncilDilemmaChoice = GameEnums.CouncilDilemmaChoice.TRADITION

var kut_delta_applied: float = 0.0
var resulting_kut: float = 0.0
var income_multiplier: float = 1.0
var speed_multiplier: float = 1.0
var morale_bonus: float = 0.0
var loot_multiplier: float = 1.0
var diplomacy_trust_delta: float = 0.0
var popular_loyalty_bonus: float = 0.0


func _init(p_player_id: int, p_choice: GameEnums.CouncilDilemmaChoice) -> void:
	player_id = p_player_id
	choice = p_choice


func get_command_id() -> StringName:
	return ID
