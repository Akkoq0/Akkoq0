class_name InvestigateProxyWarCommand
extends GameCommand
## Request command (rank 2). Dispatches scouting/counter-intelligence against a
## raiding warband to expose the covert sponsor and unlock penalty-free Casus Belli.

const ID: StringName = &"investigate_proxy_war"

var investigator_id: int = 0
var warband_id: StringName = &""
var scout_strength: float = 50.0

# Written by ReputationAndPactSystem
var discovered: bool = false
var revealed_sponsor_id: int = 0
var penalty_free_casus_belli: bool = false


func _init(p_investigator_id: int, p_warband_id: StringName, p_scout_strength: float) -> void:
	investigator_id = p_investigator_id
	warband_id = p_warband_id
	scout_strength = maxf(p_scout_strength, 0.0)


func get_command_id() -> StringName:
	return ID
