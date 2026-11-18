class_name MigrateCampToPastureCommand
extends GameCommand
## Core command (rank 2). Relocates the nomadic settlement camp (`GerCamp`) via
## `Sefer Arabası` from an overgrazed macro region to a fresh waterside pasture.

const ID: StringName = &"migrate_camp_to_pasture"

var player_id: int = 1
var target_region_coord: Vector2i = Vector2i.ZERO

var previous_region_coord: Vector2i = Vector2i.ZERO
var new_pasture_capacity: float = 100.0
var starving_livestock_cleared: bool = false
var meat_milk_production_multiplier: float = 1.0
var migration_food_spent: int = 0


func _init(p_player_id: int, p_target_region_coord: Vector2i) -> void:
	player_id = p_player_id
	target_region_coord = p_target_region_coord


func get_command_id() -> StringName:
	return ID
