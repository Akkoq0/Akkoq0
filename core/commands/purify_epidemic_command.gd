class_name PurifyEpidemicCommand
extends GameCommand
## Core command (rank 2). Performs a shamanic purification ritual at a
## `Kurgan` (`kurgan_shrine.tres`) or camp infirmary (`sifahane`), spending
## the Khagan's Kut score to halt an active Zud steppe plague (`outbreak_epidemic`).

const ID: StringName = &"purify_epidemic"

var target_army_id: int = 0
var shrine_building_id: StringName = &"kurgan_shrine"

var kut_spent: float = 0.0
var purified: bool = false
var remaining_kut: float = 0.0


func _init(p_target_army_id: int, p_shrine_building_id: StringName = &"kurgan_shrine") -> void:
	target_army_id = p_target_army_id
	shrine_building_id = p_shrine_building_id


func get_command_id() -> StringName:
	return ID
