class_name GrazePastureCommand
extends GameCommand
## Core command (rank 2). Advances one grazing cycle of `Yılkı` horse and sheep
## herds on a macro region's seasonal pasture (`PastureEcologyManager`).

const ID: StringName = &"graze_pasture"

var player_id: int = 1
var region_coord: Vector2i = Vector2i.ZERO
var herd_size: int = 500
var season_depletion_multiplier: float = 1.0

var remaining_capacity: float = 100.0
var condition: GameEnums.PastureCondition = GameEnums.PastureCondition.LUSH
var starving_livestock: bool = false
var meat_milk_production_multiplier: float = 1.0
var migration_required: bool = false
var rebellion_triggered: bool = false


func _init(p_player_id: int, p_region_coord: Vector2i, p_herd_size: int, p_season_depletion_multiplier: float = 1.0) -> void:
	player_id = p_player_id
	region_coord = p_region_coord
	herd_size = p_herd_size
	season_depletion_multiplier = p_season_depletion_multiplier


func get_command_id() -> StringName:
	return ID
