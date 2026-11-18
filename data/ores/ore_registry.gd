class_name OreRegistry
extends Resource
## Data layer (rank 1). Authoritative list of every ore available in a match.

@export var ores: Array[OreData] = []
## Exact number of ores the design requires (guards against missing files).
@export_range(0, 64) var expected_ore_count: int = 0


## Returns the ore with `ore_id`, or null when unknown.
func find_ore(ore_id: StringName) -> OreData:
	for ore: OreData in ores:
		if ore != null and ore.id == ore_id:
			return ore
	return null


## Returns true when `ore_id` is registered.
func has_ore(ore_id: StringName) -> bool:
	return find_ore(ore_id) != null


## Returns a list of human-readable registry violations (empty when valid).
func get_validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if ores.size() != expected_ore_count:
		errors.append("OreRegistry: expected %d ores, found %d." % [expected_ore_count, ores.size()])
	var seen: Dictionary[StringName, bool] = {}
	for ore: OreData in ores:
		if ore == null:
			errors.append("OreRegistry contains a null entry.")
			continue
		if seen.has(ore.id):
			errors.append("OreRegistry: duplicate ore id '%s'." % ore.id)
		seen[ore.id] = true
		errors.append_array(ore.get_validation_errors())
	return errors
