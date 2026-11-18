class_name InterveneFactionConflictCommand
extends GameCommand
## Core command (rank 2). Simulates an autonomous war between two non-player
## steppe factions (`attacker_faction_id` vs `defender_faction_id`) over
## pasturelands, 7-ore veins, or border corridors, and applies the player's
## chosen open-ended response (`NEUTRAL_TRADE_PROFITEER`, `JOIN_ATTACKER`,
## `JOIN_DEFENDER`, or `OPPORTUNISTIC_STRIKE_BOTH`).

const ID: StringName = &"intervene_faction_conflict"

var player_id: int = 1
var attacker_faction_id: StringName = &"kipchak"
var defender_faction_id: StringName = &"karluk"
var region_coord: Vector2i = Vector2i.ZERO
var contested_driver: StringName = &"fertile_pasture"
var stance: GameEnums.EmergentInterventionStance = GameEnums.EmergentInterventionStance.NEUTRAL_TRADE_PROFITEER

var mutual_exhaustion_ratio: float = 0.0
var bullion_profited: int = 0
var reward_value_gained: float = 0.0


func _init(p_player_id: int, p_attacker_id: StringName, p_defender_id: StringName, p_region_coord: Vector2i, p_contested_driver: StringName, p_stance: GameEnums.EmergentInterventionStance) -> void:
	player_id = p_player_id
	attacker_faction_id = p_attacker_id
	defender_faction_id = p_defender_id
	region_coord = p_region_coord
	contested_driver = p_contested_driver
	stance = p_stance


func get_command_id() -> StringName:
	return ID
