class_name TriggerCollapseCommand
extends GameCommand
## Request command (rank 2). Transitions a defeated player into the
## two-way `TRUCE_WITHDRAWAL` retreat protection window before choosing
## a recovery path (Vassal Beylik, Homeless Exile, or Frontier March Lord).

const ID: StringName = &"trigger_collapse"

var victim_id: int = 0
var conqueror_id: int = 0

# Written by CollapseRecoveryFSM
var truce_hours: float = 0.0
var resulting_state: GameEnums.CollapseState = GameEnums.CollapseState.SOVEREIGN


func _init(p_victim_id: int, p_conqueror_id: int) -> void:
	victim_id = p_victim_id
	conqueror_id = p_conqueror_id


func get_command_id() -> StringName:
	return ID
