class_name OreData
extends Resource
## Data layer (rank 1). Schema for a raw strategic resource ("ore").
##
## All balancing numbers live in the `.tres` instances under `res://data/ores/`.

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export_range(1, 5) var tier: int = 1

@export_group("Economy")
## Abstract trade value of one unit. Used for ROI and cost valuation.
@export_range(0.0, 10000.0, 0.01) var base_value: float = 0.0
## Units granted to every player when their stockpile is created.
@export_range(0, 1000000) var starting_amount: int = 0
## True for resources that unlock tier-gated content (totems, elite units).
@export var is_strategic: bool = false

@export_group("Logistics")
## Weight of one carried unit. Feeds the army weight-based speed formula.
@export_range(0.0, 1000.0, 0.01) var weight_per_unit: float = 0.0
## Units extracted per minute by a single worked ore node.
@export_range(0.0, 10000.0, 0.01) var extraction_rate_per_minute: float = 0.0

@export_group("World Generation")
## Terrains on which deposits of this ore may spawn.
@export var spawn_terrains: Array[GameEnums.TerrainType] = []
## Probability (0..1) that an eligible macro region receives a deposit.
@export_range(0.0, 1.0, 0.001) var spawn_chance: float = 0.0
@export_range(0, 1000000) var deposit_min_amount: int = 0
@export_range(0, 1000000) var deposit_max_amount: int = 0

@export_group("Presentation")
@export var debug_color: Color = Color.WHITE


## Returns true when this ore can spawn on `terrain_type`.
func can_spawn_on(terrain_type: GameEnums.TerrainType) -> bool:
	return spawn_terrains.has(terrain_type)


## Returns a list of human-readable schema violations (empty when valid).
func get_validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if id == &"":
		errors.append("OreData '%s' has an empty id." % resource_path)
	if deposit_max_amount < deposit_min_amount:
		errors.append("OreData '%s': deposit_max_amount < deposit_min_amount." % id)
	if spawn_terrains.is_empty():
		errors.append("OreData '%s': spawn_terrains is empty." % id)
	if base_value <= 0.0:
		errors.append("OreData '%s': base_value must be > 0." % id)
	return errors
