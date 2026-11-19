class_name DoctrineMatchupResult
extends RefCounted
## Core model (rank 2). Strictly typed outcome produced by `DoctrineMatchupResolver`
## capturing realistic steppe counter-tactics, Ülüş flank shrinkage, courier exposure
## counter-penalties, and bounded Phase 26A synergy scaling.

var attacker_doctrine_id: StringName = &""
var defender_doctrine_id: StringName = &""

## Final bounded multipliers consumed by `CombatCalculator` & maneuver checks.
var attacker_attack_multiplier: float = 1.0
var defender_defense_multiplier: float = 1.0
var defender_cohesion_damage_multiplier: float = 1.0
var defender_morale_damage_multiplier: float = 1.0
var attacker_fatigue_multiplier: float = 1.0
var attacker_mobility_multiplier: float = 1.0
var defender_mobility_multiplier: float = 1.0

## Cross-domain & directional adjustments.
var attacker_effective_flank_ratio: float = 0.0
var defender_effective_flank_ratio: float = 0.0
var bonus_defender_armor_collapse_ratio: float = 0.0
var force_rear_exposure: bool = false
var flank_rear_damping_ratio: float = 0.0
var exposed_counter_penalty: float = 0.0
var ulus_flank_penalty: float = 0.0
var synergy_power_factor: float = 1.0
var attacker_synergy_power_mult: float = 1.0
var defender_synergy_power_mult: float = 1.0
var attacker_courier_tempo_mult: float = 1.0
var defender_courier_tempo_mult: float = 1.0
var tonyukuk_attrition_drain: float = 0.0

## Realistic matchup flags.
var feigned_retreat_lure_succeeded: bool = false
var feigned_retreat_broken_off_early: bool = false
var wedge_pierced_thin_center: bool = false
var heavy_armor_terrain_collapse: bool = false
var laager_encirclement_damped: bool = false
var tonyukuk_attrition_triggered: bool = false
var plan_exposed_by_courier: bool = false

## Structured diagnostic trace.
var tactical_tags: PackedStringArray = PackedStringArray()
var summary_reasons: PackedStringArray = PackedStringArray()


func has_tag(tag: String) -> bool:
	return tactical_tags.has(tag)


func add_tag(tag: String, reason: String = "") -> void:
	if not tag.is_empty() and not tactical_tags.has(tag):
		tactical_tags.append(tag)
	if not reason.is_empty():
		summary_reasons.append(reason)


func is_finite_and_bounded() -> bool:
	var floats: Array[float] = [
		attacker_attack_multiplier,
		defender_defense_multiplier,
		defender_cohesion_damage_multiplier,
		defender_morale_damage_multiplier,
		attacker_fatigue_multiplier,
		attacker_mobility_multiplier,
		defender_mobility_multiplier,
		attacker_effective_flank_ratio,
		defender_effective_flank_ratio,
		bonus_defender_armor_collapse_ratio,
		flank_rear_damping_ratio,
		exposed_counter_penalty,
		ulus_flank_penalty,
		synergy_power_factor,
		attacker_synergy_power_mult,
		defender_synergy_power_mult,
		attacker_courier_tempo_mult,
		defender_courier_tempo_mult,
		tonyukuk_attrition_drain,
	]
	for val: float in floats:
		if is_nan(val) or is_inf(val):
			return false
	if attacker_attack_multiplier < 0.25 or attacker_attack_multiplier > 3.0:
		return false
	if defender_defense_multiplier < 0.40 or defender_defense_multiplier > 3.0:
		return false
	if defender_cohesion_damage_multiplier < 0.25 or defender_cohesion_damage_multiplier > 3.0:
		return false
	if defender_morale_damage_multiplier < 0.25 or defender_morale_damage_multiplier > 3.0:
		return false
	if attacker_fatigue_multiplier < 0.30 or attacker_fatigue_multiplier > 15.0:
		return false
	if attacker_mobility_multiplier < 0.20 or attacker_mobility_multiplier > 2.0:
		return false
	if defender_mobility_multiplier < 0.20 or defender_mobility_multiplier > 2.0:
		return false
	if attacker_effective_flank_ratio < 0.0 or attacker_effective_flank_ratio > 1.0:
		return false
	if defender_effective_flank_ratio < 0.0 or defender_effective_flank_ratio > 1.0:
		return false
	if bonus_defender_armor_collapse_ratio < 0.0 or bonus_defender_armor_collapse_ratio > 0.4501:
		return false
	if flank_rear_damping_ratio < 0.0 or flank_rear_damping_ratio > 0.9501:
		return false
	if exposed_counter_penalty < 0.0 or exposed_counter_penalty > 0.75:
		return false
	if ulus_flank_penalty < 0.0 or ulus_flank_penalty > 0.75:
		return false
	if synergy_power_factor < 0.40 or synergy_power_factor > 1.60:
		return false
	if tonyukuk_attrition_drain < 0.0 or tonyukuk_attrition_drain > 0.60:
		return false
	return true
