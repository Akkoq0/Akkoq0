class_name SabotageWellCommand
extends GameCommand
## Contaminates or collapses water wells inside `region_coord` (or targets `source_id`),
## deducting personal/tiered Töre Peace protection when targeting another player.

const ID: StringName = &"sabotage_well"

var saboteur_id: int = 1
var region_coord: Vector2i = Vector2i.ZERO
var source_id: StringName = &""
var duration_seasons: int = 3

var sabotaged: bool = false
var sources_affected: int = 0
var remaining_usable_sources: int = 0


func _init(
		p_saboteur_id: int = 1,
		p_region_coord: Vector2i = Vector2i.ZERO,
		p_source_id: StringName = &"",
		p_duration_seasons: int = 3) -> void:
	saboteur_id = p_saboteur_id
	region_coord = p_region_coord
	source_id = p_source_id
	duration_seasons = maxi(p_duration_seasons, 1)


func get_command_id() -> StringName:
	return ID
