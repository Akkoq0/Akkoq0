class_name AmbushCourierCommand
extends GameCommand
## Request command (rank 2). Ambushes an in-transit courier order; kills/captures
## the rider, blocks delivery (`AMBUSHED_LOST`), and exposes the tactical intent
## in `IntelligenceManager`.

const ID: StringName = &"ambush_courier"

var order_id: StringName = &""
var ambusher_faction_id: int = 0

# Written by CourierDispatchSystem
var intercepted: bool = false
var victim_player_id: int = 0
var target_army_id: int = 0
var leaked_tactic: GameEnums.TuranTacticPhase = GameEnums.TuranTacticPhase.RECON_DUST_SCREEN


func _init(p_order_id: StringName, p_ambusher_id: int) -> void:
	order_id = p_order_id
	ambusher_faction_id = p_ambusher_id


func get_command_id() -> StringName:
	return ID
