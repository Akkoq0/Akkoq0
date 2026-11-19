class_name ResolveSuccessionCrisisCommand
extends GameCommand
## Resolves an active Ak Sakallılar Regency or Kurultay Succession Crisis via
## Council Regency, Armed Claimant Purge (Dread + Silver), or Autonomy/Ülüş Concession.

const ID: StringName = &"resolve_succession_crisis"

var player_id: int = 1
var response: GameEnums.SuccessionCrisisResponse = GameEnums.SuccessionCrisisResponse.COUNCIL_REGENCY_TRANSITION

var resolved: bool = false
var resulting_status: GameEnums.RegencyStatus = GameEnums.RegencyStatus.STABLE_RULE
var silver_spent: int = 0
var dread_gained: float = 0.0
var kut_delta: float = 0.0


func _init(
		p_player_id: int = 1,
		p_response: GameEnums.SuccessionCrisisResponse = GameEnums.SuccessionCrisisResponse.COUNCIL_REGENCY_TRANSITION) -> void:
	player_id = p_player_id
	response = p_response


func get_command_id() -> StringName:
	return ID
