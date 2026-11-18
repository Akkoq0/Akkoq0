class_name MicroZoneConfig
extends Resource
## Data layer (rank 1). Generation parameters for micro settlement zones.
##
## A micro zone refines a single macro region: the region's elevation and
## moisture are perturbed by local detail noise and re-classified with
## micro-layer terrain rules.

## Number of tiles along X and Z.
@export var grid_size: Vector2i = Vector2i.ONE
## Edge length (m) of one tile. grid_size * tile_size_m should equal the macro region size.
@export_range(0.01, 1000.0, 0.01) var tile_size_m: float = 1.0

@export_group("Detail Noise")
@export_range(0.0001, 4.0, 0.0001) var detail_frequency: float = 0.1
@export_range(1, 8) var detail_octaves: int = 1
## Offset added to the zone seed for the moisture field.
@export var moisture_seed_offset: int = 0
## Max perturbation (0..1) applied to the parent region's elevation/moisture.
@export_range(0.0, 1.0, 0.001) var detail_strength: float = 0.0

@export_group("Settlement")
## Tiles within this radius (in tiles) of the centre are cleared for building.
@export_range(0.0, 256.0, 0.1) var settlement_clearing_radius_tiles: float = 0.0
## Terrain forced inside the clearing. Must be Micro-allowed and buildable.
@export var clearing_terrain: TerrainData

@export_group("Terrain")
## Evaluated in order; first match allowed on the Micro layer wins.
@export var terrain_rules: Array[TerrainRule] = []
## Used when no rule matches. Must be allowed on the Micro layer.
@export var fallback_terrain: TerrainData

@export_group("Ore Nodes")
@export var ore_registry: OreRegistry
## How many tiles a single macro deposit is split across.
@export_range(1, 64) var ore_nodes_per_deposit: int = 1


## Returns a list of human-readable schema violations (empty when valid).
func get_validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if grid_size.x <= 0 or grid_size.y <= 0:
		errors.append("MicroZoneConfig: grid_size must be positive.")
	if fallback_terrain == null:
		errors.append("MicroZoneConfig: fallback_terrain is null.")
	elif not fallback_terrain.is_allowed_in_layer(GameEnums.WorldLayer.MICRO):
		errors.append("MicroZoneConfig: fallback_terrain is not allowed on the Micro layer.")
	if clearing_terrain == null:
		errors.append("MicroZoneConfig: clearing_terrain is null.")
	elif not clearing_terrain.is_allowed_in_layer(GameEnums.WorldLayer.MICRO) or not clearing_terrain.is_buildable:
		errors.append("MicroZoneConfig: clearing_terrain must be Micro-allowed and buildable.")
	if ore_registry == null:
		errors.append("MicroZoneConfig: ore_registry is null.")
	for rule: TerrainRule in terrain_rules:
		if rule == null:
			errors.append("MicroZoneConfig: null terrain rule.")
		else:
			errors.append_array(rule.get_validation_errors())
	return errors
