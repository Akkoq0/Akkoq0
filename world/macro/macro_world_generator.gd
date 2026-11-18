class_name MacroWorldGenerator
extends Node
## World / macro (rank 3). Generates the strategic region map from
## `MacroWorldConfig` and broadcasts it via `EventBus.macro_world_generated`.
## Generation only; rendering lives in `MacroWorldRenderer`.

@export var config: MacroWorldConfig
@export var generate_on_ready: bool = true

var _state: MacroWorldState = null


func _ready() -> void:
	if config == null:
		push_error("MacroWorldGenerator: config is not assigned.")
		return
	if generate_on_ready:
		# Deferred so every scene node has connected to the EventBus first.
		generate.call_deferred()


## Last generated state (null before generation).
func get_state() -> MacroWorldState:
	return _state


## Generates (deterministically from `config.world_seed`) and broadcasts the map.
func generate() -> MacroWorldState:
	var errors: PackedStringArray = config.get_validation_errors()
	if not errors.is_empty():
		for error: String in errors:
			push_error("MacroWorldGenerator: %s" % error)
		return null

	var elevation_noise: FastNoiseLite = TerrainClassifier.build_noise(
		config.world_seed, config.elevation_frequency, config.elevation_octaves)
	var moisture_noise: FastNoiseLite = TerrainClassifier.build_noise(
		config.world_seed + config.moisture_seed_offset, config.moisture_frequency, config.moisture_octaves)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = config.world_seed

	var state: MacroWorldState = MacroWorldState.new(config.grid_size, config.region_size_m, config.world_seed)
	for z: int in range(config.grid_size.y):
		for x: int in range(config.grid_size.x):
			var coord: Vector2i = Vector2i(x, z)
			var elevation: float = TerrainClassifier.sample01(elevation_noise, float(x), float(z))
			var moisture: float = TerrainClassifier.sample01(moisture_noise, float(x), float(z))
			var terrain: TerrainData = TerrainClassifier.classify(
				config.terrain_rules, elevation, moisture, GameEnums.WorldLayer.MACRO, config.fallback_terrain)
			var region: MacroRegion = MacroRegion.new(coord, state.coord_to_world(coord), elevation, moisture, terrain)
			_seed_ore_deposits(region, rng)
			state.set_region(region)

	_state = state
	EventBus.macro_world_generated.emit(state)
	return state


func _seed_ore_deposits(region: MacroRegion, rng: RandomNumberGenerator) -> void:
	for ore: OreData in config.ore_registry.ores:
		if ore == null or not ore.can_spawn_on(region.terrain.terrain_type):
			continue
		if rng.randf() < ore.spawn_chance:
			region.ore_deposits[ore.id] = rng.randi_range(ore.deposit_min_amount, ore.deposit_max_amount)
