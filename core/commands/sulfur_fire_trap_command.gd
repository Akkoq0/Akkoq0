class_name SulfurFireTrapCommand
extends GameCommand
## Detonates a Sulfur (`sulfur.tres`) fire & smoke trap in a choke point,
## dealing area damage and spooking enemy cavalry (`cavalry_panic_multiplier`).

const ID: StringName = &"sulfur_fire_trap"

var player_id: int = 0
var target: CombatantStats = null
var terrain: TerrainData = null
var area_damage_dealt: float = 0.0
var cohesion_drop_dealt: float = 0.0
var morale_drop_dealt: float = 0.0


func _init(p_player_id: int, p_target: CombatantStats, p_terrain: TerrainData = null) -> void:
	player_id = p_player_id
	target = p_target
	terrain = p_terrain


func get_command_id() -> StringName:
	return ID
