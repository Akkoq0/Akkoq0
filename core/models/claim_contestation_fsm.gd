class_name ClaimContestationFSM
extends RefCounted
## Core model (rank 2). Finite State Machine governing a contested Yurt Claim
## (`Yurt İddiası`) and its 3 strategic defense pathways:
## `ACCEPT_PITCHED_BATTLE`, `PAY_ULUS_TRIBUTE`, or `KILL_ENVOY_KAN_DAVASI`.

var claim_id: StringName = &""
var challenger_id: int = 0
var defender_id: int = 0
var target_coord: Vector2i = Vector2i.ZERO
var stage: GameEnums.ClaimContestationStage = GameEnums.ClaimContestationStage.NONE
var remaining_window_hours: float = 0.0
var freeze_until_hours: float = 0.0
var winner_id: int = 0
var response_chosen: GameEnums.ClaimDefenseResponse = GameEnums.ClaimDefenseResponse.ACCEPT_PITCHED_BATTLE
var kan_davasi_active: bool = false


func open_window(
		p_claim_id: StringName,
		p_challenger_id: int,
		p_defender_id: int,
		p_target_coord: Vector2i,
		p_window_hours: float) -> void:
	claim_id = p_claim_id
	challenger_id = p_challenger_id
	defender_id = p_defender_id
	target_coord = p_target_coord
	stage = GameEnums.ClaimContestationStage.WINDOW_OPEN
	remaining_window_hours = clampf(p_window_hours, 12.0, 24.0)
	freeze_until_hours = 0.0
	winner_id = 0
	kan_davasi_active = false


## Advances contestation countdown by `dt_hours`. If window expires unanswered,
## the challenger wins the contested Yurt Claim unopposed.
func step_hours(dt_hours: float) -> bool:
	if stage != GameEnums.ClaimContestationStage.WINDOW_OPEN:
		return false
	remaining_window_hours = maxf(remaining_window_hours - maxf(dt_hours, 0.0), 0.0)
	if remaining_window_hours <= 0.0:
		stage = GameEnums.ClaimContestationStage.RESOLVED
		winner_id = challenger_id
		return true
	return false


## Transitions the FSM based on the defender's response to the challenger's envoy.
func apply_defense_response(
		response: GameEnums.ClaimDefenseResponse,
		current_hours: float,
		tribute_freeze_hours: float,
		challenger_won_battle: bool) -> GameEnums.ClaimContestationStage:
	if stage != GameEnums.ClaimContestationStage.WINDOW_OPEN:
		return stage
	response_chosen = response
	if response == GameEnums.ClaimDefenseResponse.ACCEPT_PITCHED_BATTLE:
		stage = GameEnums.ClaimContestationStage.PITCHED_BATTLE_ACCEPTED
		winner_id = challenger_id if challenger_won_battle else defender_id
	elif response == GameEnums.ClaimDefenseResponse.PAY_ULUS_TRIBUTE:
		stage = GameEnums.ClaimContestationStage.TRIBUTE_FROZEN
		freeze_until_hours = current_hours + maxf(tribute_freeze_hours, 1.0)
		winner_id = defender_id
	elif response == GameEnums.ClaimDefenseResponse.KILL_ENVOY_KAN_DAVASI:
		stage = GameEnums.ClaimContestationStage.BLOOD_FEUD_TOTAL_WAR
		kan_davasi_active = true
		winner_id = 0
	return stage


func mark_resolved(p_winner_id: int) -> void:
	stage = GameEnums.ClaimContestationStage.RESOLVED
	winner_id = p_winner_id
