class_name OreRegistry
extends Resource
## Data layer (rank 1). Authoritative list of raw ores, refined commodities,
## and transformation recipes available in a match.

@export var ores: Array[OreData] = []
## Exact number of core raw ores the design requires (guards against missing files).
@export_range(0, 64) var expected_ore_count: int = 0
## Refined commodities produced by transformation recipes (e.g. Steel).
@export var refined_ores: Array[OreData] = []
## Transformation recipes (e.g. 2 Iron + 1 Coal = 1 Steel in NomadicForge).
@export var refining_recipes: Array[RefiningRecipe] = []


## Returns the raw or refined ore with `ore_id`, or null when unknown.
func find_ore(ore_id: StringName) -> OreData:
	for ore: OreData in ores:
		if ore != null and ore.id == ore_id:
			return ore
	for refined: OreData in refined_ores:
		if refined != null and refined.id == ore_id:
			return refined
	return null


## Returns true when `ore_id` is registered (either raw or refined).
func has_ore(ore_id: StringName) -> bool:
	return find_ore(ore_id) != null


## Returns the recipe with `recipe_id`, or null when unknown.
func find_recipe(recipe_id: StringName) -> RefiningRecipe:
	for recipe: RefiningRecipe in refining_recipes:
		if recipe != null and recipe.recipe_id == recipe_id:
			return recipe
	return null


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
	for refined: OreData in refined_ores:
		if refined == null:
			errors.append("OreRegistry.refined_ores contains a null entry.")
			continue
		if seen.has(refined.id):
			errors.append("OreRegistry: duplicate refined ore id '%s'." % refined.id)
		seen[refined.id] = true
		errors.append_array(refined.get_validation_errors())
	for recipe: RefiningRecipe in refining_recipes:
		if recipe == null:
			errors.append("OreRegistry.refining_recipes contains a null entry.")
		else:
			errors.append_array(recipe.get_validation_errors())
	return errors
