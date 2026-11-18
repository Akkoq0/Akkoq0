class_name UnitData
extends Resource
## Data layer (rank 1). Stats of a single unit type.

@export var id: StringName = &""
@export var display_name: String = ""

@export_group("Combat")
@export_range(0.0, 10000.0, 0.1) var attack: float = 0.0
@export_range(0.0, 10000.0, 0.1) var defense: float = 0.0
@export_range(1.0, 100000.0, 0.1) var max_health: float = 1.0

@export_group("Mobility")
## Unloaded travel speed in m/s.
@export_range(0.0, 200.0, 0.01) var base_speed: float = 0.0
## Gear weight carried by the unit itself (counts against capacity).
@export_range(0.0, 1000.0, 0.01) var weight: float = 0.0
## Weight the unit can bear before speed starts collapsing.
@export_range(0.0, 10000.0, 0.01) var carry_capacity: float = 0.0

@export_group("Logistics")
@export_range(0.0, 1000.0, 0.01) var supply_consumption_per_minute: float = 0.0


## Returns a list of human-readable schema violations (empty when valid).
func get_validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if id == &"":
		errors.append("UnitData '%s' has an empty id." % resource_path)
	if base_speed <= 0.0:
		errors.append("UnitData '%s': base_speed must be > 0." % id)
	return errors
