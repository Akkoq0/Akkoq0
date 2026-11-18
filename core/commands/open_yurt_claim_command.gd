class_name OpenYurtClaimCommand
extends GameCommand
## Request command (rank 2). Spends Kut and Khagan Glory to open a
## 12-24h Yurt Claim (`Yurt İddiası`) contestation window against a core Oba
## or Sacred Kurgan region.

const ID: StringName = &"open_yurt_claim"

var claim_id: StringName = &""
var challenger_id: int = 0
var target_coord: Vector2i = Vector2i.ZERO
var challenger_glory: float = 25.0
var contestation_hours_override: float = -1.0

# Written by TerritoryManager
var defender_id: int = 0
var contestation_hours: float = 0.0
var kut_spent: float = 0.0
var glory_spent: float = 0.0
var stage: GameEnums.ClaimContestationStage = GameEnums.ClaimContestationStage.NONE


func _init(
		p_claim_id: StringName,
		p_challenger_id: int,
		p_target_coord: Vector2i,
		p_challenger_glory: float = 25.0,
		p_contestation_hours_override: float = -1.0) -> void:
	claim_id = p_claim_id
	challenger_id = p_challenger_id
	target_coord = p_target_coord
	challenger_glory = p_challenger_glory
	contestation_hours_override = p_contestation_hours_override


func get_command_id() -> StringName:
	return ID
