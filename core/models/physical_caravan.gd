class_name PhysicalCaravan
extends RefCounted
## Core model (rank 2). Non-teleporting physical supply & ore convoy moving
## between steppes under weather, terrain, Scorched Earth, and enemy Tuğ risk.

var caravan_id: StringName = &""
var owner_id: int = 0
var dest_army_id: int = 0
var origin_coord: Vector2i = Vector2i.ZERO
var dest_coord: Vector2i = Vector2i.ZERO
var distance_m: float = 0.0
var total_travel_sec: float = 0.0
var remaining_travel_sec: float = 0.0
var state: GameEnums.CaravanCargoState = GameEnums.CaravanCargoState.EN_ROUTE
var ore_cargo: Dictionary[StringName, int] = {}
var food_cargo: int = 0
var quiver_ammo_cargo: float = 0.0


func _init(
		p_caravan_id: StringName = &"",
		p_owner_id: int = 0,
		p_dest_army_id: int = 0,
		p_origin: Vector2i = Vector2i.ZERO,
		p_dest: Vector2i = Vector2i.ZERO) -> void:
	caravan_id = p_caravan_id
	owner_id = p_owner_id
	dest_army_id = p_dest_army_id
	origin_coord = p_origin
	dest_coord = p_dest
