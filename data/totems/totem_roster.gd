class_name TotemRoster
extends Resource
## Data layer (rank 1). The full set of totems plus the budget rules and the
## point -> gameplay value conversion table.

@export var totems: Array[TotemData] = []
@export_range(0, 64) var expected_totem_count: int = 0

@export_group("Budget Rules")
## Every totem must allocate exactly this many points.
@export_range(1, 1000) var point_budget: int = 1
## No single stat may exceed this many points (prevents one-trick builds).
@export_range(1, 1000) var max_points_per_stat: int = 1

@export_group("Point Scaling")
## Fractional combat attack bonus per offense point (0.01 = +1%).
@export var offense_bonus_per_point: float = 0.0
## Fractional combat defense bonus per defense point.
@export var defense_bonus_per_point: float = 0.0
## Fractional movement speed bonus per mobility point.
@export var mobility_bonus_per_point: float = 0.0
## Hit points granted per vitality point.
@export var health_per_vitality_point: float = 0.0
## Aura radius (m) per aura point.
@export var aura_radius_per_point: float = 0.0
## Fractional production bonus per economy point.
@export var economy_bonus_per_point: float = 0.0


## Returns the totem with `totem_id`, or null when unknown.
func find_totem(totem_id: StringName) -> TotemData:
	for totem: TotemData in totems:
		if totem != null and totem.id == totem_id:
			return totem
	return null


## Converts a totem's point allocation into gameplay values.
func compute_effective_stats(totem: TotemData) -> Dictionary[StringName, float]:
	var stats: Dictionary[StringName, float] = {}
	if totem == null:
		return stats
	stats[TotemData.STAT_OFFENSE] = float(totem.offense_points) * offense_bonus_per_point
	stats[TotemData.STAT_DEFENSE] = float(totem.defense_points) * defense_bonus_per_point
	stats[TotemData.STAT_MOBILITY] = float(totem.mobility_points) * mobility_bonus_per_point
	stats[TotemData.STAT_VITALITY] = float(totem.vitality_points) * health_per_vitality_point
	stats[TotemData.STAT_AURA] = float(totem.aura_points) * aura_radius_per_point
	stats[TotemData.STAT_ECONOMY] = float(totem.economy_points) * economy_bonus_per_point
	return stats


## Returns roster violations: counts, budgets, caps, duplicate ids and
## duplicate distributions (asymmetry rule).
func get_validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if totems.size() != expected_totem_count:
		errors.append("TotemRoster: expected %d totems, found %d." % [expected_totem_count, totems.size()])
	var seen_ids: Dictionary[StringName, bool] = {}
	var seen_signatures: Dictionary[String, StringName] = {}
	for totem: TotemData in totems:
		if totem == null:
			errors.append("TotemRoster contains a null entry.")
			continue
		if seen_ids.has(totem.id):
			errors.append("TotemRoster: duplicate totem id '%s'." % totem.id)
		seen_ids[totem.id] = true
		var signature: String = totem.get_distribution_signature()
		if seen_signatures.has(signature):
			errors.append("TotemRoster: '%s' mirrors '%s' (%s); distributions must be asymmetrical." % [totem.id, seen_signatures[signature], signature])
		seen_signatures[signature] = totem.id
		errors.append_array(totem.get_validation_errors(point_budget, max_points_per_stat))
	return errors
