class_name ArmyTemplate
extends Resource
## Data layer (rank 1). Composition + logistics profiles of an army.
##
## Aggregations are pure functions of the data so every system derives the
## same totals without duplicating formulas.

@export var id: StringName = &""
@export var display_name: String = ""
@export var stacks: Array[UnitStack] = []
@export var mobility_profile: MobilityProfile
@export var supply_profile: SupplyProfile


## Sum of unit gear weight.
func get_total_unit_weight() -> float:
	var total: float = 0.0
	for stack: UnitStack in stacks:
		if stack != null and stack.is_populated():
			total += stack.unit.weight * float(stack.count)
	return total


## Sum of unit carry capacity.
func get_total_carry_capacity() -> float:
	var total: float = 0.0
	for stack: UnitStack in stacks:
		if stack != null and stack.is_populated():
			total += stack.unit.carry_capacity * float(stack.count)
	return total


## Unloaded speed of the slowest populated stack (armies march together).
func get_slowest_base_speed() -> float:
	var slowest: float = INF
	for stack: UnitStack in stacks:
		if stack != null and stack.is_populated():
			slowest = minf(slowest, stack.unit.base_speed)
	return 0.0 if is_inf(slowest) else slowest


## Total attack of all units.
func get_total_attack() -> float:
	var total: float = 0.0
	for stack: UnitStack in stacks:
		if stack != null and stack.is_populated():
			total += stack.unit.attack * float(stack.count)
	return total


## Total defense of all units.
func get_total_defense() -> float:
	var total: float = 0.0
	for stack: UnitStack in stacks:
		if stack != null and stack.is_populated():
			total += stack.unit.defense * float(stack.count)
	return total


## Total hit points of all units.
func get_total_health() -> float:
	var total: float = 0.0
	for stack: UnitStack in stacks:
		if stack != null and stack.is_populated():
			total += stack.unit.max_health * float(stack.count)
	return total


## Supply consumed per minute by the whole army.
func get_supply_consumption_per_minute() -> float:
	var total: float = 0.0
	for stack: UnitStack in stacks:
		if stack != null and stack.is_populated():
			total += stack.unit.supply_consumption_per_minute * float(stack.count)
	return total


## Returns a list of human-readable schema violations (empty when valid).
func get_validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if id == &"":
		errors.append("ArmyTemplate '%s' has an empty id." % resource_path)
	if mobility_profile == null:
		errors.append("ArmyTemplate '%s' has no mobility_profile." % id)
	if supply_profile == null:
		errors.append("ArmyTemplate '%s' has no supply_profile." % id)
	if get_slowest_base_speed() <= 0.0:
		errors.append("ArmyTemplate '%s' has no populated stacks with speed." % id)
	for stack: UnitStack in stacks:
		if stack == null or stack.unit == null:
			errors.append("ArmyTemplate '%s' has an empty stack." % id)
		else:
			errors.append_array(stack.unit.get_validation_errors())
	return errors
