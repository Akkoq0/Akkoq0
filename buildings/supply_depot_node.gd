class_name SupplyDepotNode
extends Node3D
## Buildings (rank 3). Announces a supply depot on the EventBus using the
## radius from its `BuildingData` resource. Responds to resync requests so
## armies spawned after the depot still discover it without coupling.

@export var depot_id: int = 0
@export var owner_id: int = 0
@export var building_data: BuildingData

var _is_registered: bool = false


func _ready() -> void:
	if building_data == null or not building_data.is_supply_depot():
		push_error("SupplyDepotNode '%s' requires a BuildingData with supply_radius_m > 0." % get_path())
		return
	EventBus.supply_depots_resync_requested.connect(_announce)
	_is_registered = true
	_announce()


func _exit_tree() -> void:
	if _is_registered:
		EventBus.supply_depot_unregistered.emit(depot_id)


func _announce() -> void:
	EventBus.supply_depot_registered.emit(depot_id, owner_id, global_position, building_data.supply_radius_m)
