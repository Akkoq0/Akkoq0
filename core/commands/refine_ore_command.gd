class_name RefineOreCommand
extends GameCommand
## Executes a data-driven ore transformation recipe inside a building
## (e.g. 2 Iron + 1 Coal = 1 Steel inside `NomadicForge`).

const ID: StringName = &"refine_ore"

var player_id: int = 0
var building_id: StringName = &""
var recipe_id: StringName = &""
var batches: int = 1
var produced_amount: int = 0


func _init(p_player_id: int, p_building_id: StringName, p_recipe_id: StringName, p_batches: int = 1) -> void:
	player_id = p_player_id
	building_id = p_building_id
	recipe_id = p_recipe_id
	batches = p_batches


func get_command_id() -> StringName:
	return ID
