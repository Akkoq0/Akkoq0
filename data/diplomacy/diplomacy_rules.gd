class_name DiplomacyRules
extends Resource
## Data layer (rank 1). Balancing parameters for Phase 4 **Espionage Networks,
## Intelligence Infiltration, and Envoy Assassination / Provocation**.

@export_group("Espionage Infiltration Math")
## Base probability of infiltrating an enemy camp on open steppe.
@export_range(0.01, 1.0, 0.01) var base_espionage_success_chance: float = 0.35
## Extra infiltration probability per point of commander leadership (0..100).
@export_range(0.0, 0.02, 0.0005) var leadership_skill_weight: float = 0.0045
## Stealth multiplier granted when infiltrating through `SIK_ORMAN` (Dense Forest).
@export_range(1.0, 3.0, 0.01) var sik_orman_stealth_multiplier: float = 1.35
@export_range(0.01, 0.50, 0.01) var min_espionage_chance: float = 0.05
@export_range(0.50, 0.99, 0.01) var max_espionage_chance: float = 0.95

@export_group("Envoy Assassination & Provocation")
## Instant Kut spike awarded to the Khagan when executing a rival dynasty's envoy.
@export_range(1.0, 50.0, 0.5) var envoy_assassination_kut_gain: float = 15.0
## Raid loot multiplier active during the inevitable Total War (Büyük Yağma) period.
@export_range(1.0, 3.0, 0.05) var great_raid_loot_multiplier: float = 1.40

@export_group("Phase 5 Khagan Glory & Free Warband Recruitment")
@export_range(1.0, 100.0, 0.5) var glory_per_turan_tactic: float = 18.0
@export_range(1.0, 100.0, 0.5) var glory_per_feigned_retreat_lure: float = 16.0
@export_range(1.0, 100.0, 0.5) var glory_per_envoy_assassination: float = 14.0
## Glory threshold above which rogue `Yersiz Yurtsuz Çeriler` warbands join the Khagan's army directly without hostages.
@export_range(5.0, 100.0, 1.0) var free_warband_recruitment_glory_threshold: float = 40.0
@export_range(10, 5000) var rogue_warband_troop_size: int = 250
@export_range(10.0, 500.0, 1.0) var max_glory_score: float = 100.0


## Pure calculation of spy infiltration success probability from commander
## leadership (`0..100`), terrain stealth (`SIK_ORMAN` multiplier), and enemy
## counter-espionage vigilance (`0..1`).
func calculate_espionage_success_chance(commander_leadership: float, terrain: TerrainData, counter_espionage: float = 0.0) -> float:
	var base: float = base_espionage_success_chance \
		+ clampf(commander_leadership, 0.0, 100.0) * leadership_skill_weight \
		- clampf(counter_espionage, 0.0, 0.85)
	var stealth_mult: float = 1.0
	if terrain != null and terrain.terrain_class == GameEnums.TerrainClass.SIK_ORMAN:
		stealth_mult = sik_orman_stealth_multiplier * (1.0 + maxf(terrain.ambush_concealment_bonus, 0.0))
	return clampf(base * stealth_mult, min_espionage_chance, max_espionage_chance)


## Returns schema violations (empty when valid).
func get_validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if min_espionage_chance <= 0.0 or min_espionage_chance >= max_espionage_chance:
		errors.append("DiplomacyRules: min_espionage_chance must be in (0, max_espionage_chance).")
	if sik_orman_stealth_multiplier < 1.0:
		errors.append("DiplomacyRules: sik_orman_stealth_multiplier must be >= 1.0.")
	if envoy_assassination_kut_gain <= 0.0:
		errors.append("DiplomacyRules: envoy_assassination_kut_gain must be > 0.")
	if free_warband_recruitment_glory_threshold <= 0.0 or free_warband_recruitment_glory_threshold > max_glory_score:
		errors.append("DiplomacyRules: free_warband_recruitment_glory_threshold must lie in (0, max_glory_score].")
	return errors

