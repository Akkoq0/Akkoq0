class_name SupplyLineComponent
extends Node
## Units (rank 3). Tracks an army's connection to friendly supply depots and
## its carried supply. Knows nothing about movement or combat.
##
## Depots are learned exclusively through EventBus announcements.

signal supply_changed(supply_ratio: float, is_connected: bool)

## Node whose position is checked against depot ranges.
@export var body: Node3D


class DepotRecord:
	var position: Vector3
	var radius_m: float

	func _init(p_position: Vector3, p_radius_m: float) -> void:
		position = p_position
		radius_m = p_radius_m


var _profile: SupplyProfile = null
var _owner_id: int = 0
var _consumption_per_sec: float = 0.0
var _supply: float = 0.0
var _is_connected: bool = false
var _last_reported_ratio: float = -1.0
var _terrain_attrition: float = 1.0
var _season_attrition: float = 1.0
var _depots: Dictionary[int, DepotRecord] = {}


func _ready() -> void:
	set_physics_process(false)
	EventBus.supply_depot_registered.connect(_on_depot_registered)
	EventBus.supply_depot_unregistered.connect(_on_depot_unregistered)
	EventBus.season_changed.connect(_on_season_changed)


## Reads logistics data. Returns false when required data is missing.
func configure(template: ArmyTemplate, owner_id: int) -> bool:
	if body == null:
		push_error("SupplyLineComponent '%s': body is not assigned." % get_path())
		return false
	if template == null or template.supply_profile == null:
		push_error("SupplyLineComponent '%s': template or supply_profile missing." % get_path())
		return false
	_profile = template.supply_profile
	_owner_id = owner_id
	_consumption_per_sec = template.get_supply_consumption_per_minute() / 60.0
	_supply = _profile.supply_capacity
	set_physics_process(true)
	_request_depot_resync.call_deferred()
	return true


## Applies the attrition multiplier of the terrain currently under the army.
func set_terrain(terrain: TerrainData) -> void:
	_terrain_attrition = terrain.supply_attrition_multiplier if terrain != null else 1.0


## Current supply as a 0..1 ratio.
func get_supply_ratio() -> float:
	if _profile == null:
		return 0.0
	return clampf(_supply / _profile.supply_capacity, 0.0, 1.0)


## True when inside range of at least one friendly depot.
func is_connected_to_supply() -> bool:
	return _is_connected


## True when supply fell under the profile's starvation threshold.
func is_starving() -> bool:
	return _profile != null and get_supply_ratio() < _profile.low_supply_threshold


func _physics_process(delta: float) -> void:
	if _profile == null:
		return
	var connected: bool = _is_in_depot_range(body.global_position)
	if connected:
		_supply += _profile.resupply_rate_per_sec * delta
	else:
		_supply -= _consumption_per_sec * _terrain_attrition * _season_attrition * delta
	_supply = clampf(_supply, 0.0, _profile.supply_capacity)

	var ratio: float = get_supply_ratio()
	var crossed_step: bool = absf(ratio - _last_reported_ratio) >= _profile.report_step_ratio
	var hit_bound: bool = (ratio <= 0.0 or ratio >= 1.0) and ratio != _last_reported_ratio
	if connected != _is_connected or crossed_step or hit_bound:
		_is_connected = connected
		_last_reported_ratio = ratio
		supply_changed.emit(ratio, connected)


func _is_in_depot_range(world_position: Vector3) -> bool:
	var flat_position: Vector2 = Vector2(world_position.x, world_position.z)
	for depot_id: int in _depots:
		var record: DepotRecord = _depots[depot_id]
		var reach: float = record.radius_m + _profile.max_supply_range_m
		if flat_position.distance_to(Vector2(record.position.x, record.position.z)) <= reach:
			return true
	return false


func _request_depot_resync() -> void:
	EventBus.supply_depots_resync_requested.emit()


func _on_depot_registered(depot_id: int, owner_id: int, position: Vector3, radius_m: float) -> void:
	if owner_id == _owner_id:
		_depots[depot_id] = DepotRecord.new(position, radius_m)


func _on_depot_unregistered(depot_id: int) -> void:
	_depots.erase(depot_id)


func _on_season_changed(season: SeasonData, _cycle_index: int) -> void:
	_season_attrition = season.attrition_multiplier if season != null else 1.0
