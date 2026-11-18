class_name AssignCaptiveLaborCommand
extends GameCommand
## Core command (rank 2). Assigns captured common soldiers (`captured_slave_workers`)
## to settlement Quarries and `NomadicForge` workshops, reducing construction
## time and raw material production costs by up to 30%, while evaluating
## `slave_revolt_risk` if captives exceed the clan's core population.

const ID: StringName = &"assign_captive_labor"

var player_id: int = 1
var added_slave_workers: int = 0
var core_clan_population: int = 120

var total_slave_workers: int = 0
var discount_ratio: float = 0.0
var construction_time_multiplier: float = 1.0
var production_cost_multiplier: float = 1.0
var slave_revolt_risk: float = 0.0
var revolt_triggered: bool = false


func _init(p_player_id: int, p_added_slave_workers: int, p_core_clan_population: int = 120) -> void:
	player_id = p_player_id
	added_slave_workers = p_added_slave_workers
	core_clan_population = p_core_clan_population


func get_command_id() -> StringName:
	return ID
