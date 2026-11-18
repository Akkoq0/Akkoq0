class_name DispatchCourierOrderCommand
extends GameCommand
## Request command (rank 2). Dispatches a mounted courier carrying a tactical
## or strategic order to a detached field army with terrain/weather travel delay.

const ID: StringName = &"dispatch_courier_order"

var order_id: StringName = &""
var player_id: int = 0
var target_army_id: int = 0
var command_type: StringName = &""
var intended_tactic: GameEnums.TuranTacticPhase = GameEnums.TuranTacticPhase.RECON_DUST_SCREEN
var origin_pos: Vector3 = Vector3.ZERO
var target_pos: Vector3 = Vector3.ZERO
var terrain_type: GameEnums.TerrainType = GameEnums.TerrainType.STEPPE
var is_winter_storm: bool = false

# Written by CourierDispatchSystem
var computed_delay_sec: float = 0.0
var status: GameEnums.CourierStatus = GameEnums.CourierStatus.IN_TRANSIT


func _init(
		p_order_id: StringName,
		p_player_id: int,
		p_army_id: int,
		p_cmd_type: StringName,
		p_tactic: GameEnums.TuranTacticPhase,
		p_origin: Vector3,
		p_target: Vector3,
		p_terrain: GameEnums.TerrainType = GameEnums.TerrainType.STEPPE,
		p_storm: bool = false) -> void:
	order_id = p_order_id
	player_id = p_player_id
	target_army_id = p_army_id
	command_type = p_cmd_type
	intended_tactic = p_tactic
	origin_pos = p_origin
	target_pos = p_target
	terrain_type = p_terrain
	is_winter_storm = p_storm


func get_command_id() -> StringName:
	return ID
