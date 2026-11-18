class_name TerrainRule
extends Resource
## Data layer (rank 1). Maps an (elevation, moisture) window to a terrain.
##
## Rules are evaluated in array order by the world generators; the first
## matching rule whose terrain is allowed on the target layer wins.

@export var terrain: TerrainData
@export_range(0.0, 1.0, 0.001) var min_elevation: float = 0.0
@export_range(0.0, 1.0, 0.001) var max_elevation: float = 1.0
@export_range(0.0, 1.0, 0.001) var min_moisture: float = 0.0
@export_range(0.0, 1.0, 0.001) var max_moisture: float = 1.0


## True when the sample lies inside this rule's window (inclusive).
func matches(elevation: float, moisture: float) -> bool:
	return elevation >= min_elevation and elevation <= max_elevation \
		and moisture >= min_moisture and moisture <= max_moisture


## Returns a list of human-readable schema violations (empty when valid).
func get_validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if terrain == null:
		errors.append("TerrainRule '%s' has no terrain." % resource_path)
	if min_elevation > max_elevation or min_moisture > max_moisture:
		errors.append("TerrainRule '%s' has an inverted window." % resource_path)
	return errors
