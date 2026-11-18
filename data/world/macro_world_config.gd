class_name MacroWorldConfig
extends Resource
## Data layer (rank 1). Generation parameters for the macro (strategic) map.

@export var world_seed: int = 0
## Number of regions along X (columns) and Z (rows).
@export var grid_size: Vector2i = Vector2i.ONE
## Edge length (m) of a single square region.
@export_range(1.0, 10000.0, 0.1) var region_size_m: float = 1.0

@export_group("Noise")
@export_range(0.0001, 1.0, 0.0001) var elevation_frequency: float = 0.05
@export_range(1, 8) var elevation_octaves: int = 1
@export_range(0.0001, 1.0, 0.0001) var moisture_frequency: float = 0.05
@export_range(1, 8) var moisture_octaves: int = 1
## Offset added to world_seed for the moisture field (decorrelates the fields).
@export var moisture_seed_offset: int = 0

@export_group("Terrain")
## Evaluated in order; first match allowed on the Macro layer wins.
@export var terrain_rules: Array[TerrainRule] = []
## Used when no rule matches. Must be allowed on the Macro layer.
@export var fallback_terrain: TerrainData

@export_group("Resources")
@export var ore_registry: OreRegistry


## Returns a list of human-readable schema violations (empty when valid).
func get_validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if grid_size.x <= 0 or grid_size.y <= 0:
		errors.append("MacroWorldConfig: grid_size must be positive.")
	if terrain_rules.is_empty():
		errors.append("MacroWorldConfig: terrain_rules is empty.")
	if fallback_terrain == null:
		errors.append("MacroWorldConfig: fallback_terrain is null.")
	elif not fallback_terrain.is_allowed_in_layer(GameEnums.WorldLayer.MACRO):
		errors.append("MacroWorldConfig: fallback_terrain is not allowed on the Macro layer.")
	if ore_registry == null:
		errors.append("MacroWorldConfig: ore_registry is null.")
	for rule: TerrainRule in terrain_rules:
		if rule == null:
			errors.append("MacroWorldConfig: null terrain rule.")
		else:
			errors.append_array(rule.get_validation_errors())
	return errors
