extends Node
## Autoload `BuildingPlacementManager` (rank 2). Manages Phase 6 **Micro-Map
## Building Placement & Grid Snapping (`can_place_at_grid`)** for `ger_camp.tres`,
## `nomadic_forge.tres`, `quarry.tres`, and `kurgan_shrine.tres`, enforcing
## footprint collision checks and deducting construction costs via `CommandBus`.

const GER_CAMP_PATH: String = "res://data/buildings/ger_camp.tres"
const NOMADIC_FORGE_PATH: String = "res://data/buildings/nomadic_forge.tres"
const QUARRY_PATH: String = "res://data/buildings/quarry.tres"
const KURGAN_SHRINE_PATH: String = "res://data/buildings/kurgan_shrine.tres"

var _catalog: Dictionary[StringName, BuildingData] = {}
var _active_zone: MicroZoneState = null
var _placed_buildings: Dictionary[int, PlacedBuildingRecord] = {}
var _next_instance_id: int = 1


func _ready() -> void:
	_register_catalog_building(GER_CAMP_PATH)
	_register_catalog_building(NOMADIC_FORGE_PATH)
	_register_catalog_building(QUARRY_PATH)
	_register_catalog_building(KURGAN_SHRINE_PATH)
	EventBus.micro_zone_generated.connect(_on_micro_zone_generated)
	CommandBus.register_handler(PlaceBuildingCommand.ID, _handle_place_building)


func _exit_tree() -> void:
	CommandBus.unregister_handler(PlaceBuildingCommand.ID, _handle_place_building)


func set_active_zone(zone: MicroZoneState) -> void:
	_active_zone = zone


func get_active_zone() -> MicroZoneState:
	return _active_zone


func get_building_data(building_id: StringName) -> BuildingData:
	return _catalog.get(building_id, null)


func get_placed_building(instance_id: int) -> PlacedBuildingRecord:
	return _placed_buildings.get(instance_id, null)


func get_placed_building_count() -> int:
	return _placed_buildings.size()


## True when `building`'s entire `footprint` starting at `origin_coord` lies
## inside `zone`, sits on allowed buildable tiles, and does not overlap any
## existing building or ore vein.
func can_place_at_grid(zone: MicroZoneState, building: BuildingData, origin_coord: Vector2i) -> bool:
	if zone == null or building == null:
		return false
	if building.footprint.x <= 0 or building.footprint.y <= 0:
		return false
	for dy: int in range(building.footprint.y):
		for dx: int in range(building.footprint.x):
			var tile_coord: Vector2i = Vector2i(origin_coord.x + dx, origin_coord.y + dy)
			if not zone.is_in_bounds(tile_coord):
				return false
			var tile: MicroTile = zone.get_tile(tile_coord)
			if tile == null or not tile.is_buildable():
				return false
			if not building.allowed_terrains.has(tile.terrain.terrain_type):
				return false
	return true


func _handle_place_building(command: GameCommand) -> bool:
	var place: PlaceBuildingCommand = command as PlaceBuildingCommand
	if place == null:
		return command.reject("Expected PlaceBuildingCommand.")
	if place.building_data == null:
		return command.reject("PlaceBuildingCommand requires non-null building_data.")
	var zone: MicroZoneState = place.zone_override if place.zone_override != null else _active_zone
	if zone == null:
		return command.reject("No active MicroZoneState available for building placement.")

	var target_coord: Vector2i = zone.world_to_tile(place.world_click_position) if place.use_world_click else place.grid_coord
	if not can_place_at_grid(zone, place.building_data, target_coord):
		return command.reject("Cannot place '%s' at grid %s: tile blocked, out of bounds, or overlapping another building." % [
			place.building_data.id, target_coord])

	if not place.building_data.construction_cost.is_empty():
		var spend_cmd: SpendResourcesCommand = SpendResourcesCommand.new(place.player_id, place.building_data.construction_cost)
		if not CommandBus.dispatch(spend_cmd):
			return command.reject("Insufficient treasury resources to construct '%s': %s" % [
				place.building_data.id, spend_cmd.rejection_reason])

	var instance_id: int = _next_instance_id
	_next_instance_id += 1
	for dy: int in range(place.building_data.footprint.y):
		for dx: int in range(place.building_data.footprint.x):
			var tile_coord: Vector2i = Vector2i(target_coord.x + dx, target_coord.y + dy)
			var tile: MicroTile = zone.get_tile(tile_coord)
			tile.occupied_building_id = place.building_data.id
			tile.occupied_instance_id = instance_id

	var rec: PlacedBuildingRecord = PlacedBuildingRecord.new()
	rec.instance_id = instance_id
	rec.player_id = place.player_id
	rec.building_id = place.building_data.id
	rec.building_data = place.building_data
	rec.zone_id = zone.zone_id
	rec.origin_coord = target_coord
	rec.footprint = place.building_data.footprint
	rec.world_position = zone.tile_to_world(target_coord)

	_placed_buildings[instance_id] = rec
	place.placed_instance_id = instance_id
	place.snapped_grid_coord = target_coord
	place.snapped_world_position = rec.world_position
	place.record = rec

	EventBus.building_placed_on_micro_grid.emit(
		rec.instance_id,
		rec.player_id,
		rec.building_id,
		rec.zone_id,
		rec.origin_coord,
		rec.world_position)
	return true


func _register_catalog_building(path: String) -> void:
	var data: BuildingData = ResourceLoader.load(path) as BuildingData
	if data == null:
		push_error("BuildingPlacementManager: failed to load BuildingData at %s." % path)
		return
	_catalog[data.id] = data


func _on_micro_zone_generated(zone_state: MicroZoneState) -> void:
	_active_zone = zone_state
