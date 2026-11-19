class_name BreakAmanatPactCommand
extends GameCommand
## Request command (rank 2). Breaks an active Amanat pact mid-term, forfeiting
## the pledged hostage/seal, slashing `word_reliability` across memory, and spiking coalition infamy.

const ID: StringName = &"break_amanat_pact"

var pact_id: StringName = &""
var betrayer_id: int = 0

# Written by ReputationAndPactSystem
var broken: bool = false
var hostage_forfeited: bool = false
var reliability_after: float = 0.0
var dread_after: float = 0.0


func _init(p_pact_id: StringName, p_betrayer_id: int) -> void:
	pact_id = p_pact_id
	betrayer_id = p_betrayer_id


func get_command_id() -> StringName:
	return ID
