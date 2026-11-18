class_name CataclysmEventData
extends Resource
## Data layer (rank 1). Schema for Phase 9 **Major Steppe Cataclysms & Natural
## Destruction (`CataclysmEngine`)** (`res://data/cataclysms/`).

@export var cataclysm_id: StringName = &"kara_zud_ice_trap"
@export var display_name: String = "Kara Zud ve Buz Kapanı"
@export var cataclysm_type: GameEnums.CataclysmType = GameEnums.CataclysmType.KARA_ZUD_ICE_TRAP
@export_range(0.0, 1.0, 0.05) var pasture_yield_multiplier: float = 0.20
@export_range(0.1, 1.0, 0.05) var yilki_mobility_multiplier: float = 0.45
@export_range(0.1, 1.0, 0.05) var caravan_speed_multiplier: float = 0.40
## Reduction in `SIK_ORMAN` ambush concealment when scorched by steppe wildfires (`0.0 .. 1.0`).
@export_range(0.0, 1.0, 0.05) var forest_concealment_loss_ratio: float = 0.0
## Structural wear (`0.0 .. 1.0`) inflicted on regional buildings by earthquakes/floods.
@export_range(0.0, 1.0, 0.05) var structural_wear_ratio: float = 0.0
## Displaced nomad refugee population entering the region during exodus/flood cataclysms.
@export_range(0, 2000, 10) var refugee_influx_count: int = 0
@export_range(0.0, 30.0, 1.0) var kut_shock_drain: float = 8.0
@export var open_response_options: PackedStringArray = PackedStringArray()


## Returns schema violations (empty when valid).
func get_validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if cataclysm_id == &"":
		errors.append("CataclysmEventData: cataclysm_id cannot be empty.")
	if cataclysm_type == GameEnums.CataclysmType.NONE:
		errors.append("CataclysmEventData '%s': cataclysm_type cannot be NONE." % cataclysm_id)
	if open_response_options.is_empty():
		errors.append("CataclysmEventData '%s': open_response_options cannot be empty." % cataclysm_id)
	return errors
