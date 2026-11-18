class_name TerrainData
extends Resource
## Data layer (rank 1). Gameplay stats for a single strictly-typed terrain,
## including Phase 3 tactical steppe terrain classes (`Bereket Havzası`,
## `Hakimiyet Platosu`, `Sık Orman`, `Damarlı Yamaç`).

@export var terrain_type: GameEnums.TerrainType = GameEnums.TerrainType.STEPPE
@export var terrain_class: GameEnums.TerrainClass = GameEnums.TerrainClass.BEREKET_HAVZASI
@export var display_name: String = ""
## Which world layers may contain this terrain (bit 0 = Macro, bit 1 = Micro).
@export_flags("Macro", "Micro") var allowed_layers: int = 0

@export_group("Gameplay")
@export var is_passable: bool = true
@export var is_buildable: bool = false
## Multiplier applied to army movement speed.
@export_range(0.0, 4.0, 0.01) var movement_multiplier: float = 1.0
## Multiplier applied to a defender's effective defense.
@export_range(0.0, 4.0, 0.01) var defense_multiplier: float = 1.0
## Multiplier applied to supply consumption while out of supply.
@export_range(0.0, 8.0, 0.01) var supply_attrition_multiplier: float = 1.0

@export_group("Tactical Combat Synergy")
## Cavalry charge momentum multiplier (`Bereket Havzası` > 1.0).
@export_range(0.5, 3.0, 0.01) var cavalry_momentum_multiplier: float = 1.0
## High-altitude bow range and arrow damage multiplier (`Hakimiyet Platosu` > 1.0).
@export_range(0.5, 3.0, 0.01) var ranged_elevation_bonus_multiplier: float = 1.0
## Ambush concealment factor (`Sık Orman` & `Damarlı Yamaç` > 0.0).
@export_range(0.0, 1.0, 0.01) var ambush_concealment_bonus: float = 0.0
## Chokepoint defense multiplier (`Damarlı Yamaç` > 1.0).
@export_range(1.0, 3.0, 0.01) var chokepoint_defense_multiplier: float = 1.0

@export_group("Presentation")
@export var debug_color: Color = Color.WHITE


## True when this terrain may appear on `layer`.
func is_allowed_in_layer(layer: GameEnums.WorldLayer) -> bool:
	return GameEnums.layer_mask_has(allowed_layers, layer)


## Effective movement multiplier (0 when impassable).
func get_effective_movement_multiplier() -> float:
	if not is_passable:
		return 0.0
	return movement_multiplier


## Returns a list of human-readable schema violations (empty when valid).
func get_validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if allowed_layers == 0:
		errors.append("TerrainData '%s' is not allowed in any layer." % display_name)
	if is_passable and movement_multiplier <= 0.0:
		errors.append("TerrainData '%s' is passable but has movement_multiplier <= 0." % display_name)
	if is_buildable and not is_passable:
		errors.append("TerrainData '%s' is buildable but impassable." % display_name)
	return errors
