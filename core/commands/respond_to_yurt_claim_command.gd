class_name RespondToYurtClaimCommand
extends GameCommand
## Request command (rank 2). Executes the defender's response to an open Yurt
## Claim: Pitched Battle, Tribute Freeze (Steel/Meteoric Iron/Yılkı), or
## Kill Envoy -> Kan Davası Total War.

const ID: StringName = &"respond_to_yurt_claim"

var claim_id: StringName = &""
var responder_id: int = 0
var response: GameEnums.ClaimDefenseResponse = GameEnums.ClaimDefenseResponse.ACCEPT_PITCHED_BATTLE
var challenger_won_battle: bool = true
var attacker_stats: CombatantStats = null
var defender_stats: CombatantStats = null
var rng_seed: int = 1901

# Written by TerritoryManager
var resulting_stage: GameEnums.ClaimContestationStage = GameEnums.ClaimContestationStage.NONE
var winner_id: int = 0
var tribute_paid: bool = false
var kan_davasi_triggered: bool = false
var trust_penalty_applied: float = 0.0
var freeze_until_hours: float = 0.0


func _init(
		p_claim_id: StringName,
		p_responder_id: int,
		p_response: GameEnums.ClaimDefenseResponse,
		p_challenger_won_battle: bool = true,
		p_attacker_stats: CombatantStats = null,
		p_defender_stats: CombatantStats = null,
		p_rng_seed: int = 1901) -> void:
	claim_id = p_claim_id
	responder_id = p_responder_id
	response = p_response
	challenger_won_battle = p_challenger_won_battle
	attacker_stats = p_attacker_stats
	defender_stats = p_defender_stats
	rng_seed = p_rng_seed


func get_command_id() -> StringName:
	return ID
