class_name WorkerGatheringComponent
extends Node
## Units (rank 3). Phase 6 **Nomadic Worker Detachments (`Oymak İşçileri`) &
## Caravan Resource Gathering Pipeline** (`res://units/worker_gathering_component.gd`).
##
## Responsibilities:
##  * Dispatches nomadic worker columns from the `GerCamp` depot to the nearest
##    7-ore vein (`stone`, `iron`, `coal`, `silver_gold`, `jade`, `sulfur`,
##    `meteoric_iron`) or `FOREST` timber zone (`wood`).
##  * Simulates physical 3D caravan movement (`WALKING_TO_RESOURCE` ->
##    `HARVESTING` -> `HAULING_TO_GER_CAMP`) and deposits gathered cargo into
##    the player's `GerCamp` stockpile via `CommandBus`.

const DEFAULT_PROFILE_PATH: String = "res://data/units/default_worker_gathering_profile.tres"
const WOOD_RESOURCE_ID: StringName = &"wood"

@export var profile: WorkerGatheringProfile

var _worker_id: int = 1
var _player_id: int = 1
var _state: GameEnums.WorkerGatherState = GameEnums.WorkerGatherState.IDLE
var _ger_camp_position: Vector3 = Vector3.ZERO
var _current_position: Vector3 = Vector3.ZERO
var _target_tile: MicroTile = null
var _target_position: Vector3 = Vector3.ZERO
var _target_resource_id: StringName = &""
var _carried_resource_id: StringName = &""
var _carried_amount: int = 0
var _harvest_elapsed_sec: float = 0.0
var _delivered_totals: Dictionary[StringName, int] = {}


func _ready() -> void:
	if profile == null:
		profile = ResourceLoader.load(DEFAULT_PROFILE_PATH) as WorkerGatheringProfile


## Configures the worker detachment anchored at `p_ger_camp_position`.
func configure(p_worker_id: int, p_player_id: int, p_ger_camp_position: Vector3, p_profile: WorkerGatheringProfile = null) -> void:
	_worker_id = p_worker_id
	_player_id = p_player_id
	_ger_camp_position = p_ger_camp_position
	_current_position = p_ger_camp_position
	if p_profile != null:
		profile = p_profile
	elif profile == null:
		profile = ResourceLoader.load(DEFAULT_PROFILE_PATH) as WorkerGatheringProfile
	_state = GameEnums.WorkerGatherState.IDLE
	_target_tile = null
	_carried_resource_id = &""
	_carried_amount = 0
	_harvest_elapsed_sec = 0.0


## Finds the nearest micro tile containing a 7-ore vein or forest timber zone
## matching `preferred_resource_id` (empty string = any ore or forest).
func find_nearest_resource_tile(zone: MicroZoneState, preferred_resource_id: StringName = &"") -> MicroTile:
	if zone == null:
		return null
	var best_tile: MicroTile = null
	var best_dist_sq: float = INF
	for tile: MicroTile in zone.get_tiles():
		if tile == null:
			continue
		if not _tile_matches_resource(tile, preferred_resource_id):
			continue
		var tile_world: Vector3 = zone.tile_to_world(tile.coord)
		var dist_sq: float = _ger_camp_position.distance_squared_to(tile_world)
		if dist_sq < best_dist_sq:
			best_dist_sq = dist_sq
			best_tile = tile
	return best_tile


## Orders the worker detachment to march from `GerCamp` to `tile` in `zone`.
func assign_gather_target(zone: MicroZoneState, tile: MicroTile) -> bool:
	if zone == null or tile == null or profile == null:
		return false
	var res_id: StringName = _resolve_tile_resource_id(tile)
	if res_id == &"":
		return false
	_target_tile = tile
	_target_position = zone.tile_to_world(tile.coord)
	_target_resource_id = res_id
	_harvest_elapsed_sec = 0.0
	_state = GameEnums.WorkerGatherState.WALKING_TO_RESOURCE
	EventBus.worker_gathering_started.emit(_worker_id, _player_id, _target_resource_id, tile.coord, _target_position)
	return true


## Locates and assigns the nearest matching 7-ore node or forest timber tile.
func assign_nearest_gather_job(zone: MicroZoneState, preferred_resource_id: StringName = &"") -> bool:
	var nearest: MicroTile = find_nearest_resource_tile(zone, preferred_resource_id)
	if nearest == null:
		return false
	return assign_gather_target(zone, nearest)


## Advances the physical caravan movement and harvesting state machine by `delta_sec`.
func tick_gathering(delta_sec: float) -> void:
	if profile == null or delta_sec <= 0.0 or _state == GameEnums.WorkerGatherState.IDLE:
		return
	if _state == GameEnums.WorkerGatherState.WALKING_TO_RESOURCE:
		_current_position = _CurrentMoveToward(_current_position, _target_position, profile.walk_speed_m_per_sec * delta_sec)
		if _current_position.distance_to(_target_position) <= profile.arrival_tolerance_m:
			_current_position = _target_position
			_harvest_elapsed_sec = 0.0
			_state = GameEnums.WorkerGatherState.HARVESTING
	elif _state == GameEnums.WorkerGatherState.HARVESTING:
		_harvest_elapsed_sec += delta_sec
		if _harvest_elapsed_sec >= profile.harvest_duration_sec:
			_extract_from_target_tile()
			if _carried_amount > 0:
				_state = GameEnums.WorkerGatherState.HAULING_TO_GER_CAMP
			else:
				_state = GameEnums.WorkerGatherState.IDLE
	elif _state == GameEnums.WorkerGatherState.HAULING_TO_GER_CAMP:
		_current_position = _CurrentMoveToward(_current_position, _ger_camp_position, profile.caravan_haul_speed_m_per_sec * delta_sec)
		if _current_position.distance_to(_ger_camp_position) <= profile.arrival_tolerance_m:
			_current_position = _ger_camp_position
			_deposit_cargo_at_ger_camp()


func get_state() -> GameEnums.WorkerGatherState:
	return _state


func get_current_position() -> Vector3:
	return _current_position


func get_carried_resource_id() -> StringName:
	return _carried_resource_id


func get_carried_amount() -> int:
	return _carried_amount


func get_total_delivered(resource_id: StringName) -> int:
	return _delivered_totals.get(resource_id, 0)


func _tile_matches_resource(tile: MicroTile, preferred_resource_id: StringName) -> bool:
	var res_id: StringName = _resolve_tile_resource_id(tile)
	if res_id == &"":
		return false
	if preferred_resource_id == &"":
		return true
	return res_id == preferred_resource_id


func _resolve_tile_resource_id(tile: MicroTile) -> StringName:
	if tile.has_ore():
		return tile.ore.id
	if tile.terrain != null and tile.terrain.terrain_type == GameEnums.TerrainType.FOREST:
		return WOOD_RESOURCE_ID
	return &""


func _extract_from_target_tile() -> void:
	if _target_tile == null or profile == null:
		return
	var cap: int = profile.carry_capacity_per_trip
	if _target_tile.ore != null:
		var extracted: int = mini(cap, maxi(_target_tile.ore_amount, 0))
		_target_tile.ore_amount = maxi(_target_tile.ore_amount - extracted, 0)
		_carried_resource_id = _target_tile.ore.id if extracted > 0 else &""
		_carried_amount = extracted
	elif _target_tile.terrain != null and _target_tile.terrain.terrain_type == GameEnums.TerrainType.FOREST:
		_carried_resource_id = WOOD_RESOURCE_ID
		_carried_amount = cap


func _deposit_cargo_at_ger_camp() -> void:
	if _carried_amount <= 0 or _carried_resource_id == &"":
		_state = GameEnums.WorkerGatherState.IDLE
		return
	var delivered_id: StringName = _carried_resource_id
	var delivered_amt: int = _carried_amount
	var deposit_ore_id: StringName = profile.forest_wood_deposit_ore_id if delivered_id == WOOD_RESOURCE_ID else delivered_id
	CommandBus.dispatch(DepositResourcesCommand.new(_player_id, deposit_ore_id, delivered_amt))
	_delivered_totals[delivered_id] = _delivered_totals.get(delivered_id, 0) + delivered_amt
	_carried_resource_id = &""
	_carried_amount = 0
	_state = GameEnums.WorkerGatherState.IDLE
	EventBus.worker_caravan_delivered.emit(_worker_id, _player_id, delivered_id, delivered_amt, _ger_camp_position)


func _CurrentMoveToward(from_pos: Vector3, to_pos: Vector3, max_step: float) -> Vector3:
	var delta_vec: Vector3 = to_pos - from_pos
	var dist: float = delta_vec.length()
	if dist <= max_step or dist <= 0.0001:
		return to_pos
	return from_pos + (delta_vec / dist) * max_step
