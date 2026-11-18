class_name EvaluateAtmosphericVolleyCommand
extends GameCommand
## Core command (rank 2). Evaluates an archer volley (`Whistling Arrow` & Turan
## harassment) against the active steppe wind vector and pre-Zud storm state.

const ID: StringName = &"evaluate_atmospheric_volley"

var shooter_id: int = 1
var shot_direction: Vector3 = Vector3.FORWARD
var base_morale_shock: float = 12.0
var base_quiver_ammo_cost: float = 8.0

var result: BallisticVolleyResult = null
var effective_morale_shock: float = 12.0
var effective_quiver_ammo_cost: float = 8.0


func _init(p_shooter_id: int, p_shot_direction: Vector3, p_base_morale_shock: float = 12.0, p_base_quiver_ammo_cost: float = 8.0) -> void:
	shooter_id = p_shooter_id
	shot_direction = p_shot_direction
	base_morale_shock = p_base_morale_shock
	base_quiver_ammo_cost = p_base_quiver_ammo_cost


func get_command_id() -> StringName:
	return ID
