class_name MicroZoneGenerator
extends Node
## World / micro (rank 3). Generates the settlement zone of the macro region
## under the camera focus when a transition toward the Micro layer starts.
##
## Receives the macro map through the EventBus (never from the macro node) and
## caches zones by id so revisiting a region is stable and free.

@export var config: MicroZoneConfig

var _world_state: MacroWorldState = null
var _zone_cache: Dictionary[StringName, MicroZoneState] = {}


func _ready() -> void:
	if config == null:
		push_error("MicroZoneGenerator: config is not assigned.")
		return
	var errors: PackedStringArray = config.get_validation_errors()
	for error: String in errors:
		push_error("MicroZoneGenerator: %s" % error)
	if not errors.is_empty():
		return
	EventBus.macro_world_generated.connect(_on_macro_world_generated)
	EventBus.layer_transition_started.connect(_on_layer_transition_started)


## Returns (generating if needed) the zone for macro region `coord`.
func get_or_generate_zone(coord: Vector2i) -> MicroZoneState:
	if _world_state == null:
		push_error("MicroZoneGenerator: macro world not generated yet.")
		return null
	var region: MacroRegion = _world_state.get_region(_world_state.clamp_coord(coord))
	if region == null:
		push_error("MicroZoneGenerator: no macro region at %s." % coord)
		return null
	var zone_id: StringName = MicroZoneState.make_zone_id(region.coord)
	if _zone_cache.has(zone_id):
		return _zone_cache[zone_id]
	var zone: MicroZoneState = _generate_zone(region)
	_zone_cache[zone_id] = zone
	return zone


func _on_macro_world_generated(world_state: MacroWorldState) -> void:
	_world_state = world_state
	_zone_cache.clear()


func _on_layer_transition_started(target_layer: GameEnums.WorldLayer, focus_position: Vector3) -> void:
	if target_layer != GameEnums.WorldLayer.MICRO or _world_state == null:
		return
	var zone: MicroZoneState = get_or_generate_zone(_world_state.world_to_coord(focus_position))
	if zone != null:
		EventBus.micro_zone_generated.emit(zone)


func _generate_zone(region: MacroRegion) -> MicroZoneState:
	var zone_seed: int = hash("%d:%d:%d" % [_world_state.world_seed, region.coord.x, region.coord.y])
	var elevation_noise: FastNoiseLite = TerrainClassifier.build_noise(zone_seed, config.detail_frequency, config.detail_octaves)
	var moisture_noise: FastNoiseLite = TerrainClassifier.build_noise(
		zone_seed + config.moisture_seed_offset, config.detail_frequency, config.detail_octaves)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = zone_seed

	var zone: MicroZoneState = MicroZoneState.new(region.coord, config.grid_size, config.tile_size_m, region.world_center)
	var center: Vector2 = Vector2(config.grid_size) * 0.5
	var candidate_ore_tiles: Array[MicroTile] = []

	for y: int in range(config.grid_size.y):
		for x: int in range(config.grid_size.x):
			var coord: Vector2i = Vector2i(x, y)
			var detail_e: float = TerrainClassifier.sample01(elevation_noise, float(x), float(y)) * 2.0 - 1.0
			var detail_m: float = TerrainClassifier.sample01(moisture_noise, float(x), float(y)) * 2.0 - 1.0
			var elevation: float = clampf(region.elevation + detail_e * config.detail_strength, 0.0, 1.0)
			var moisture: float = clampf(region.moisture + detail_m * config.detail_strength, 0.0, 1.0)
			var in_clearing: bool = (Vector2(coord) + Vector2(0.5, 0.5)).distance_to(center) <= config.settlement_clearing_radius_tiles
			var terrain: TerrainData = config.clearing_terrain if in_clearing else TerrainClassifier.classify(
				config.terrain_rules, elevation, moisture, GameEnums.WorldLayer.MICRO, config.fallback_terrain)
			var tile: MicroTile = MicroTile.new(coord, elevation, terrain)
			tile.is_settlement_clearing = in_clearing
			zone.set_tile(tile)
			if not in_clearing and terrain.is_passable:
				candidate_ore_tiles.append(tile)

	_distribute_ore_nodes(region, candidate_ore_tiles, rng)
	return zone


func _distribute_ore_nodes(region: MacroRegion, candidates: Array[MicroTile], rng: RandomNumberGenerator) -> void:
	if candidates.is_empty():
		return
	for ore_id: StringName in region.ore_deposits:
		var ore: OreData = config.ore_registry.find_ore(ore_id)
		if ore == null:
			continue
		var total: int = region.ore_deposits[ore_id]
		var node_count: int = mini(config.ore_nodes_per_deposit, candidates.size())
		var per_node: int = maxi(floori(float(total) / float(maxi(node_count, 1))), 1)
		for _node_index: int in range(node_count):
			if candidates.is_empty():
				return
			var tile: MicroTile = candidates.pop_at(rng.randi_range(0, candidates.size() - 1))
			tile.ore = ore
			tile.ore_amount = per_node

