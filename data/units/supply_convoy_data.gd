class_name SupplyConvoyData
extends Resource
## Data layer (rank 1). Active steppe supply convoy hauling rations, Yılkı
## spare horses, and quiver arrows between a `SupplyDepotNode` / `GerCamp`
## and a field army.

@export var convoy_id: StringName = &"steppe_yilki_convoy"
@export var display_name: String = "Bozkır Yılkı İkmal Kolu"
@export_range(0, 100000) var carried_food_ration: int = 80
@export_range(0.0, 5.0, 0.01) var carried_remount_ratio: float = 0.30
@export_range(0.0, 1000.0, 1.0) var carried_quiver_ammo: float = 60.0
## Trade value of rations, arrows, and Yılkı horses seized if interdicted by raiders.
@export_range(0.0, 100000.0, 1.0) var captured_loot_value: float = 240.0


## Returns schema violations (empty when valid).
func get_validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if convoy_id == &"":
		errors.append("SupplyConvoyData '%s' has an empty convoy_id." % resource_path)
	if captured_loot_value <= 0.0:
		errors.append("SupplyConvoyData '%s': captured_loot_value must be > 0." % convoy_id)
	return errors
