class_name DispatchPhysicalCaravanCommand
extends GameCommand
## Request command (rank 2). Dispatches a non-teleporting physical cargo caravan
## carrying Steel/Ores, Food rations, and Quiver Arrows across macro distances.

const ID: StringName = &"dispatch_physical_caravan"

var caravan_id: StringName = &""
var owner_id: int = 0
var dest_army_id: int = 0
var origin_coord: Vector2i = Vector2i.ZERO
var dest_coord: Vector2i = Vector2i.ZERO
var distance_m: float = 110.0
var ore_cargo: Dictionary[StringName, int] = {}
var food_cargo: int = 0
var quiver_ammo_cargo: float = 0.0

# Written by CaravanLogisticsManager
var computed_eta_sec: float = 0.0
var arrived_immediately: bool = false
var state: GameEnums.CaravanCargoState = GameEnums.CaravanCargoState.EN_ROUTE


func _init(
		p_caravan_id: StringName,
		p_owner_id: int,
		p_dest_army_id: int,
		p_origin: Vector2i,
		p_dest: Vector2i,
		p_distance_m: float,
		p_ore_cargo: Dictionary[StringName, int] = {},
		p_food_cargo: int = 0,
		p_ammo_cargo: float = 0.0) -> void:
	caravan_id = p_caravan_id
	owner_id = p_owner_id
	dest_army_id = p_dest_army_id
	origin_coord = p_origin
	dest_coord = p_dest
	distance_m = p_distance_m
	ore_cargo = p_ore_cargo.duplicate()
	food_cargo = p_food_cargo
	quiver_ammo_cargo = p_ammo_cargo


func get_command_id() -> StringName:
	return ID
