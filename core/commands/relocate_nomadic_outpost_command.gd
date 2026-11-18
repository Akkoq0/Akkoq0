class_name RelocateNomadicOutpostCommand
extends GameCommand
## Core command (rank 2). Deploys or relocates a nomadic camp, forward forge,
## or outpost (`outpost_id`) to any macro coordinate via `Sefer Arabası`,
## supporting multi-region distributed nomadic networks.

const ID: StringName = &"relocate_nomadic_outpost"

var player_id: int = 1
var outpost_id: StringName = &"main_otağ"
var target_coord: Vector2i = Vector2i.ZERO

var previous_coord: Vector2i = Vector2i.ZERO
var active_outpost_count: int = 0


func _init(p_player_id: int, p_outpost_id: StringName, p_target_coord: Vector2i) -> void:
	player_id = p_player_id
	outpost_id = p_outpost_id
	target_coord = p_target_coord


func get_command_id() -> StringName:
	return ID
