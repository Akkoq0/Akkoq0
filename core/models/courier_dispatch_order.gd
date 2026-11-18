class_name CourierDispatchOrder
extends RefCounted
## Core model (rank 2). Physical dispatched courier order experiencing real
## travel latency over terrain/weather and risk of scout ambush.

var order_id: StringName = &""
var player_id: int = 0
var target_army_id: int = 0
var command_type: StringName = &""
var intended_tactic: GameEnums.TuranTacticPhase = GameEnums.TuranTacticPhase.RECON_DUST_SCREEN
var origin_pos: Vector3 = Vector3.ZERO
var target_pos: Vector3 = Vector3.ZERO
var total_delay_sec: float = 0.0
var remaining_delay_sec: float = 0.0
var status: GameEnums.CourierStatus = GameEnums.CourierStatus.IN_TRANSIT
var exposed_to_faction_id: int = 0


func _init(
		p_order_id: StringName = &"",
		p_player_id: int = 0,
		p_army_id: int = 0,
		p_cmd_type: StringName = &"",
		p_tactic: GameEnums.TuranTacticPhase = GameEnums.TuranTacticPhase.RECON_DUST_SCREEN) -> void:
	order_id = p_order_id
	player_id = p_player_id
	target_army_id = p_army_id
	command_type = p_cmd_type
	intended_tactic = p_tactic
