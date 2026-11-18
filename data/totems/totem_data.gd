class_name TotemData
extends Resource
## Data layer (rank 1). Schema for a mythological totem entity.
##
## Each totem distributes exactly `point_budget` points across six
## stat axes. Asymmetry comes from *how* the budget is spent, never from a
## larger budget, which keeps the 8 entities balanced against each other.

const STAT_OFFENSE: StringName = &"offense"
const STAT_DEFENSE: StringName = &"defense"
const STAT_MOBILITY: StringName = &"mobility"
const STAT_VITALITY: StringName = &"vitality"
const STAT_AURA: StringName = &"aura"
const STAT_ECONOMY: StringName = &"economy"

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var lore: String = ""

@export_group("Budget Allocation (points)")
@export_range(0, 100) var offense_points: int = 0
@export_range(0, 100) var defense_points: int = 0
@export_range(0, 100) var mobility_points: int = 0
@export_range(0, 100) var vitality_points: int = 0
@export_range(0, 100) var aura_points: int = 0
@export_range(0, 100) var economy_points: int = 0

@export_group("Summoning")
@export var summon_cost: Array[ResourceAmount] = []
@export_range(0.0, 3600.0, 0.1) var summon_cooldown_sec: float = 0.0
@export var preferred_season: GameEnums.SeasonType = GameEnums.SeasonType.SPRING
@export var native_terrain: GameEnums.TerrainType = GameEnums.TerrainType.STEPPE

@export_group("Presentation")
@export var debug_color: Color = Color.WHITE


## Sum of all allocated points.
func get_allocated_points() -> int:
	return offense_points + defense_points + mobility_points \
		+ vitality_points + aura_points + economy_points


## Stat name -> allocated points.
func get_point_breakdown() -> Dictionary[StringName, int]:
	var breakdown: Dictionary[StringName, int] = {
		STAT_OFFENSE: offense_points,
		STAT_DEFENSE: defense_points,
		STAT_MOBILITY: mobility_points,
		STAT_VITALITY: vitality_points,
		STAT_AURA: aura_points,
		STAT_ECONOMY: economy_points,
	}
	return breakdown


## Canonical signature of the distribution, used to enforce asymmetry.
func get_distribution_signature() -> String:
	return "%d/%d/%d/%d/%d/%d" % [
		offense_points, defense_points, mobility_points,
		vitality_points, aura_points, economy_points,
	]


## Returns schema violations against the given budget rules.
func get_validation_errors(point_budget: int, max_points_per_stat: int) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if id == &"":
		errors.append("TotemData '%s' has an empty id." % resource_path)
	var allocated: int = get_allocated_points()
	if allocated != point_budget:
		errors.append("Totem '%s' allocates %d points; budget is exactly %d." % [id, allocated, point_budget])
	var breakdown: Dictionary[StringName, int] = get_point_breakdown()
	for stat: StringName in breakdown:
		if breakdown[stat] > max_points_per_stat:
			errors.append("Totem '%s': %s=%d exceeds per-stat cap %d." % [id, stat, breakdown[stat], max_points_per_stat])
	errors.append_array(ResourceAmount.validate_list(summon_cost, "%s.summon_cost" % id))
	return errors
