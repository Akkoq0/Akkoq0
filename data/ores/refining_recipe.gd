class_name RefiningRecipe
extends Resource
## Data layer (rank 1). Data-driven ore transformation recipe (e.g. 2 Iron + 1 Coal = 1 Steel).

@export var recipe_id: StringName = &""
@export var display_name: String = ""
## Building id required to execute this transformation (e.g. &"nomadic_forge").
@export var required_building_id: StringName = &""
@export var inputs: Array[ResourceAmount] = []
@export var outputs: Array[ResourceAmount] = []


## Scales `inputs` by `batches` (minimum 1).
func build_scaled_inputs(batches: int) -> Array[ResourceAmount]:
	var count: int = maxi(batches, 1)
	var scaled: Array[ResourceAmount] = []
	for item: ResourceAmount in inputs:
		if item == null or item.ore == null:
			continue
		var copy: ResourceAmount = ResourceAmount.new()
		copy.ore = item.ore
		copy.amount = item.amount * count
		scaled.append(copy)
	return scaled


## Scales `outputs` by `batches` (minimum 1).
func build_scaled_outputs(batches: int) -> Array[ResourceAmount]:
	var count: int = maxi(batches, 1)
	var scaled: Array[ResourceAmount] = []
	for item: ResourceAmount in outputs:
		if item == null or item.ore == null:
			continue
		var copy: ResourceAmount = ResourceAmount.new()
		copy.ore = item.ore
		copy.amount = item.amount * count
		scaled.append(copy)
	return scaled


## Returns schema violations (empty when valid).
func get_validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if recipe_id == &"":
		errors.append("RefiningRecipe '%s' has an empty recipe_id." % resource_path)
	if required_building_id == &"":
		errors.append("RefiningRecipe '%s' has an empty required_building_id." % recipe_id)
	if inputs.is_empty():
		errors.append("RefiningRecipe '%s' has no inputs." % recipe_id)
	if outputs.is_empty():
		errors.append("RefiningRecipe '%s' has no outputs." % recipe_id)
	errors.append_array(ResourceAmount.validate_list(inputs, "%s.inputs" % recipe_id))
	errors.append_array(ResourceAmount.validate_list(outputs, "%s.outputs" % recipe_id))
	return errors
