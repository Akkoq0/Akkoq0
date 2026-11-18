class_name ResourceAmount
extends Resource
## Data layer (rank 1). A quantity of a specific ore.
##
## Used for construction costs, upkeep, production yields and summon costs.

@export var ore: OreData
@export_range(0, 1000000) var amount: int = 0


## Returns the id of the referenced ore, or an empty StringName when unset.
func get_ore_id() -> StringName:
	if ore == null:
		return &""
	return ore.id


## Returns `amount * ore.base_value`.
func get_value() -> float:
	if ore == null:
		return 0.0
	return float(amount) * ore.base_value


## Returns `amount * ore.weight_per_unit`.
func get_weight() -> float:
	if ore == null:
		return 0.0
	return float(amount) * ore.weight_per_unit


## Sums the trade value of a list of amounts.
static func sum_value(amounts: Array[ResourceAmount]) -> float:
	var total: float = 0.0
	for entry: ResourceAmount in amounts:
		if entry != null:
			total += entry.get_value()
	return total


## Returns validation errors for a list of amounts (null entries, missing ores).
static func validate_list(amounts: Array[ResourceAmount], context: String) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	for entry: ResourceAmount in amounts:
		if entry == null:
			errors.append("%s: null ResourceAmount entry." % context)
		elif entry.ore == null:
			errors.append("%s: ResourceAmount without ore." % context)
	return errors
