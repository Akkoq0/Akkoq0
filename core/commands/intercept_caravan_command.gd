class_name InterceptCaravanCommand
extends GameCommand
## Request command (rank 2). Intercepts an in-flight `PhysicalCaravan`, seizing
## cargo for the raider and creating an active front-line ammunition & supply
## crisis on the intended destination army.

const ID: StringName = &"intercept_caravan"

var caravan_id: StringName = &""
var raider_id: int = 0

# Written by CaravanLogisticsManager
var intercepted: bool = false
var dest_army_id: int = 0
var seized_steel: int = 0
var seized_food: int = 0
var front_ammo_lost: float = 0.0
var front_supply_shock: float = 0.0


func _init(p_caravan_id: StringName, p_raider_id: int) -> void:
	caravan_id = p_caravan_id
	raider_id = p_raider_id


func get_command_id() -> StringName:
	return ID
