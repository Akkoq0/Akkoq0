class_name TacticalDoctrineData
extends Resource
## Data layer (rank 1). Schema for the 5-stage deterministic Turan Tactic FSM
## and nomadic battle doctrines (`standard_charge`, `feigned_retreat`,
## `crescent_encirclement`, `steppe_ambush`).

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var doctrine_type: GameEnums.TacticalDoctrineType = GameEnums.TacticalDoctrineType.FEIGNED_RETREAT

@export_group("Stage 1: Recon & Dust Screen")
## Fraction by which enemy vision range is narrowed by vanguard dust clouds.
@export_range(0.0, 0.95, 0.01) var dust_screen_vision_reduction_ratio: float = 0.45
## Apparent army size factor projected to enemy scouts.
@export_range(0.1, 4.0, 0.01) var deceptive_army_size_multiplier: float = 1.65

@export_group("Stage 2: Whistling Arrow Harassment")
@export_range(5.0, 250.0, 0.5) var optimal_skirmish_range_m: float = 45.0
## Quiver ammo consumed per whistling-arrow volley.
@export_range(0.1, 100.0, 0.1) var quiver_ammo_consumption_per_volley: float = 8.0
@export_range(0.0, 200.0, 0.1) var whistling_arrow_physical_damage: float = 18.0
## Cohesion eroded per volley by whistling çavuş arrows.
@export_range(0.0, 100.0, 0.1) var whistling_arrow_cohesion_damage: float = 14.0
## Morale eroded per volley by whistling çavuş arrows.
@export_range(0.0, 100.0, 0.1) var whistling_arrow_morale_damage: float = 11.0

@export_group("Stage 3: Feigned Retreat Lure")
## Formation entropy added per meter of overextended enemy pursuit.
@export_range(0.0001, 0.5, 0.0001) var entropy_gain_per_meter: float = 0.008
## Fatigue added per meter of overextended enemy pursuit.
@export_range(0.0001, 0.5, 0.0001) var fatigue_gain_per_meter: float = 0.006
## Entropy threshold at which enemy formation order becomes critical.
@export_range(0.05, 1.0, 0.01) var critical_entropy_threshold: float = 0.60
## Maximum fraction of enemy armor defense that collapses at full entropy (0.45 = 45%).
@export_range(0.0, 0.9, 0.01) var max_armor_collapse_ratio: float = 0.45
## Scaling factor applied to enemy commander's ambition / discipline ratio.
@export_range(0.1, 5.0, 0.01) var lure_ambition_weight: float = 1.35

@export_group("Stage 4: Crescent Encirclement Trap")
## Minimum pincer flank angle (rad) required to spring the Crescent Trap (PI * 0.65 ~= 2.042035).
@export_range(0.1, 3.14159, 0.001) var min_crescent_flank_angle_rad: float = 2.042035
## Terrain classes in which concealed flankers seal the enemy escape vector.
@export var ambush_terrain_classes: Array[GameEnums.TerrainClass] = [
	GameEnums.TerrainClass.SIK_ORMAN,
	GameEnums.TerrainClass.DAMARLI_YAMAC,
]
@export_range(0.0, 100.0, 0.1) var encirclement_cohesion_shock: float = 28.0

@export_group("Stage 5: Börü Shock Annihilation")
@export_range(0.1, 10.0, 0.01) var boru_charge_mass_factor: float = 1.45
@export_range(1.0, 5.0, 0.01) var boru_steel_shock_multiplier: float = 1.35
@export_range(1.0, 5.0, 0.01) var boru_meteoric_iron_shock_multiplier: float = 1.50


## True when `terrain_class` allows concealed ambushers to seal the escape vector.
func can_seal_escape_on(terrain_class: GameEnums.TerrainClass) -> bool:
	return ambush_terrain_classes.has(terrain_class)


## Returns human-readable schema violations (empty when valid).
func get_validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if id == &"":
		errors.append("TacticalDoctrineData '%s' has an empty id." % resource_path)
	if quiver_ammo_consumption_per_volley <= 0.0:
		errors.append("TacticalDoctrineData '%s': quiver_ammo_consumption_per_volley must be > 0." % id)
	if max_armor_collapse_ratio <= 0.0 or max_armor_collapse_ratio > 0.9:
		errors.append("TacticalDoctrineData '%s': max_armor_collapse_ratio out of bounds." % id)
	if min_crescent_flank_angle_rad <= 0.0:
		errors.append("TacticalDoctrineData '%s': min_crescent_flank_angle_rad must be > 0." % id)
	return errors
