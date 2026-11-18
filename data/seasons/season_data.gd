class_name SeasonData
extends Resource
## Data layer (rank 1). Modifiers applied while a season is active.

@export var season_type: GameEnums.SeasonType = GameEnums.SeasonType.SPRING
@export var display_name: String = ""
@export_range(1.0, 36000.0, 0.1) var duration_sec: float = 1.0

@export_group("Modifiers")
@export_range(0.0, 4.0, 0.01) var movement_multiplier: float = 1.0
@export_range(0.0, 4.0, 0.01) var production_multiplier: float = 1.0
@export_range(0.0, 8.0, 0.01) var attrition_multiplier: float = 1.0
@export_range(0.0, 4.0, 0.01) var defense_multiplier: float = 1.0

@export_group("Presentation")
@export var ambient_tint: Color = Color.WHITE


## Returns a list of human-readable schema violations (empty when valid).
func get_validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if display_name.is_empty():
		errors.append("SeasonData '%s' has no display_name." % resource_path)
	if duration_sec <= 0.0:
		errors.append("SeasonData '%s' must have duration_sec > 0." % display_name)
	return errors
