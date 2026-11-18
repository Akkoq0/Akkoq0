class_name SupplyLineComponent
extends Node
## Units (rank 3). Tracks an army's connection to friendly supply depots,
## carried supply, **Yılkı spare horse ratio (`remount_horse_ratio`)**,
## **quiver ammo reserve (`quiver_ammo_reserve`)**, supply interdiction
## (`ISOLATED`), and the Winter/Zud emergency **Yılkı horse sacrifice**
## (`consume_yilki_horses_for_ration()`).

const REASON_YILKI_SACRIFICE: StringName = &"yilki_horse_sacrifice"
const ISOLATION_RELIEF_DELAY_SEC: float = 4.0

signal supply_changed(supply_ratio: float, is_connected: bool)
signal remount_horse_ratio_changed(new_ratio: float)

## Node whose position is checked against depot ranges.
@export var body: Node3D
@export var convoy_data: SupplyConvoyData


class DepotRecord:
	var position: Vector3
	var radius_m: float

	func _init(p_position: Vector3, p_radius_m: float) -> void:
		position = p_position
		radius_m = p_radius_m


var _profile: SupplyProfile = null
var _army_id: int = 0
var _owner_id: int = 0
var _consumption_per_sec: float = 0.0
var _supply: float = 0.0
var _remount_horse_ratio: float = 1.0
var _quiver_ammo_reserve: float = 100.0
var _battle_morale: float = 100.0
var _supply_status: GameEnums.SupplyLineStatus = GameEnums.SupplyLineStatus.CONNECTED
var _is_connected: bool = false
var _last_reported_ratio: float = -1.0
var _terrain_attrition: float = 1.0
var _season_attrition: float = 1.0
var _isolation_relief_elapsed_sec: float = 0.0
var _depots: Dictionary[int, DepotRecord] = {}


func _ready() -> void:
	set_physics_process(false)
	EventBus.supply_depot_registered.connect(_on_depot_registered)
	EventBus.supply_depot_unregistered.connect(_on_depot_unregistered)
	EventBus.season_changed.connect(_on_season_changed)
	EventBus.supply_line_severed.connect(_on_supply_line_severed)
	EventBus.supply_line_restored.connect(_on_supply_line_restored)
	EventBus.zud_starvation_ticked.connect(_on_zud_starvation_ticked)
	EventBus.army_caravan_resupply_delivered.connect(_on_army_caravan_resupply_delivered)


func _exit_tree() -> void:
	if EventBus.army_caravan_resupply_delivered.is_connected(_on_army_caravan_resupply_delivered):
		EventBus.army_caravan_resupply_delivered.disconnect(_on_army_caravan_resupply_delivered)


## Reads logistics data. Returns false when required data is missing.
func configure(template: ArmyTemplate, owner_id: int, p_army_id: int = 1) -> bool:
	if body == null:
		push_error("SupplyLineComponent '%s': body is not assigned." % get_path())
		return false
	if template == null or template.supply_profile == null:
		push_error("SupplyLineComponent '%s': template or supply_profile missing." % get_path())
		return false
	_profile = template.supply_profile
	_owner_id = owner_id
	_army_id = p_army_id
	_consumption_per_sec = template.get_supply_consumption_per_minute() / 60.0
	_supply = _profile.supply_capacity
	_remount_horse_ratio = _profile.initial_remount_horse_ratio
	_quiver_ammo_reserve = _profile.initial_quiver_ammo_reserve
	_battle_morale = 100.0
	_supply_status = GameEnums.SupplyLineStatus.CONNECTED
	_isolation_relief_elapsed_sec = 0.0
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


## Current Yılkı spare-horse ratio (`remount_horse_ratio`).
func get_remount_horse_ratio() -> float:
	return _remount_horse_ratio


## Replenishes Yılkı spare-horse herds at a friendly pasture or depot.
func replenish_yilki_herd(restored_ratio: float) -> float:
	if _profile == null:
		return _remount_horse_ratio
	var gained: float = maxf(restored_ratio, 0.0)
	var prev: float = _remount_horse_ratio
	_remount_horse_ratio = clampf(_remount_horse_ratio + gained, 0.0, _profile.initial_remount_horse_ratio)
	if _remount_horse_ratio > prev:
		_battle_morale = clampf(_battle_morale + gained * 20.0, 0.0, 100.0)
		remount_horse_ratio_changed.emit(_remount_horse_ratio)
	return _remount_horse_ratio


## Current quiver arrow reserve (`quiver_ammo_reserve`).
func get_quiver_ammo_reserve() -> float:
	return _quiver_ammo_reserve


## Replenishes `amount` into quiver ammo reserve from an arriving caravan or depot.
func replenish_quiver_ammo(amount: float) -> float:
	var cap: float = _profile.max_quiver_ammo_reserve if _profile != null else 100.0
	_quiver_ammo_reserve = clampf(_quiver_ammo_reserve + maxf(amount, 0.0), 0.0, cap)
	return _quiver_ammo_reserve


## Consumes `amount` from quiver ammo reserve and returns remaining ammo.
func consume_quiver_ammo(amount: float) -> float:
	_quiver_ammo_reserve = maxf(_quiver_ammo_reserve - maxf(amount, 0.0), 0.0)
	if _quiver_ammo_reserve <= 0.0:
		EventBus.quiver_ammo_depleted.emit(_army_id)
	return _quiver_ammo_reserve


## Current battle morale of the army (`0..100`).
func get_battle_morale() -> float:
	return _battle_morale


## Operational connectivity status of the supply line (`CONNECTED`, `UNCONNECTED`, `ISOLATED`).
func get_supply_status() -> GameEnums.SupplyLineStatus:
	return _supply_status


## True when the army's supply corridor was severed by raiders (`ISOLATED`).
func is_isolated() -> bool:
	return _supply_status == GameEnums.SupplyLineStatus.ISOLATED


## True when inside range of at least one friendly depot and not isolated.
func is_connected_to_supply() -> bool:
	return _is_connected and not is_isolated()


## True when supply fell under the profile's starvation threshold.
func is_starving() -> bool:
	return _profile != null and get_supply_ratio() < _profile.low_supply_threshold


## Clears `ISOLATED` state and restores operational supply corridor status.
func restore_supply_corridor(restored_supply_ratio: float = 0.35) -> bool:
	if _profile == null:
		return false
	_isolation_relief_elapsed_sec = 0.0
	var inside_perimeter: bool = body != null and _is_in_depot_range(body.global_position)
	_supply_status = GameEnums.SupplyLineStatus.CONNECTED if inside_perimeter else GameEnums.SupplyLineStatus.UNCONNECTED
	_is_connected = inside_perimeter
	_supply = maxf(_supply, clampf(restored_supply_ratio, 0.0, 1.0) * _profile.supply_capacity)
	_last_reported_ratio = get_supply_ratio()
	supply_changed.emit(_last_reported_ratio, _is_connected)
	return true


## Slaughters the army's own Yılkı spare horses during Winter/Zud starvation
## (`Food <= 0`) when isolated from supply. Permanently destroys cavalry speed,
## collapses battle morale, and drains the Khagan's Kut score.
func consume_yilki_horses_for_ration() -> bool:
	if _profile == null or _remount_horse_ratio <= 0.0:
		return false
	_remount_horse_ratio = maxf(_remount_horse_ratio - _profile.yilki_sacrifice_ratio_per_starvation, 0.0)
	_supply = clampf(_supply + _profile.yilki_sacrifice_supply_restored, 0.0, _profile.supply_capacity)
	_battle_morale = maxf(_battle_morale - _profile.yilki_sacrifice_morale_drop, 0.0)

	remount_horse_ratio_changed.emit(_remount_horse_ratio)
	CommandBus.dispatch(ModifyKutCommand.new(-_profile.yilki_sacrifice_kut_penalty, REASON_YILKI_SACRIFICE))
	EventBus.yilki_horses_sacrificed_for_ration.emit(
		_army_id, _remount_horse_ratio, _profile.yilki_sacrifice_morale_drop, _profile.yilki_sacrifice_kut_penalty)
	return true


func _physics_process(delta: float) -> void:
	if _profile == null:
		return
	var inside_perimeter: bool = _is_in_depot_range(body.global_position)
	if is_isolated():
		if inside_perimeter:
			_isolation_relief_elapsed_sec += delta
			if _isolation_relief_elapsed_sec >= ISOLATION_RELIEF_DELAY_SEC:
				CommandBus.dispatch(RestoreSupplyLineCommand.new(_army_id, 1, 0.35))
		else:
			_isolation_relief_elapsed_sec = 0.0

	var in_range: bool = not is_isolated() and inside_perimeter
	if in_range:
		_supply += _profile.resupply_rate_per_sec * delta
		_quiver_ammo_reserve = minf(
			_quiver_ammo_reserve + _profile.quiver_resupply_rate_per_sec * delta,
			_profile.max_quiver_ammo_reserve)
		_supply_status = GameEnums.SupplyLineStatus.CONNECTED
	else:
		_supply -= _consumption_per_sec * _terrain_attrition * _season_attrition * delta
		if not is_isolated():
			_supply_status = GameEnums.SupplyLineStatus.UNCONNECTED
	_supply = clampf(_supply, 0.0, _profile.supply_capacity)

	var ratio: float = get_supply_ratio()
	var crossed_step: bool = absf(ratio - _last_reported_ratio) >= _profile.report_step_ratio
	var hit_bound: bool = (ratio <= 0.0 or ratio >= 1.0) and ratio != _last_reported_ratio
	if in_range != _is_connected or crossed_step or hit_bound:
		_is_connected = in_range
		_last_reported_ratio = ratio
		supply_changed.emit(ratio, in_range)


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
	if season != null and season.season_type != GameEnums.SeasonType.WINTER \
			and _profile != null and not is_isolated() \
			and SeasonManager.get_food_reserve() > 0 \
			and _remount_horse_ratio < _profile.initial_remount_horse_ratio:
		if _is_connected or (body != null and _is_in_depot_range(body.global_position)):
			replenish_yilki_herd(_profile.benign_season_yilki_recovery_ratio)


func _on_supply_line_severed(army_id: int, _depot_id: int, _raider_id: StringName, _captured_loot_value: float) -> void:
	if army_id == _army_id:
		_isolation_relief_elapsed_sec = 0.0
		_supply_status = GameEnums.SupplyLineStatus.ISOLATED
		_is_connected = false
		_supply = 0.0
		supply_changed.emit(0.0, false)


func _on_supply_line_restored(army_id: int, _depot_id: int) -> void:
	if army_id == _army_id:
		restore_supply_corridor(0.35)


func _on_zud_starvation_ticked(food_remaining: int, _season: SeasonData) -> void:
	if food_remaining <= 0 and is_isolated():
		consume_yilki_horses_for_ration()


func _on_army_caravan_resupply_delivered(p_army_id: int, quiver_ammo_amt: float, _food_amt: int) -> void:
	if _army_id > 0 and p_army_id == _army_id and quiver_ammo_amt > 0.0:
		replenish_quiver_ammo(quiver_ammo_amt)

