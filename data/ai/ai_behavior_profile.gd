class_name AIBehaviorProfile
extends Resource
## Data layer (rank 1). Deterministic decision thresholds and Turan tactic
## selection parameters for Phase 6 **AI Commander & Steppe Raider AI
## (`1. GATHER_RESOURCES -> 2. UPGRADE_FORGE -> 3. LAUNCH_RAID`)**.

@export var profile_id: StringName = &"steppe_warlord_ai"
@export_range(5.0, 500.0, 1.0) var base_gather_rate_per_tick: float = 55.0
@export_range(10.0, 1000.0, 5.0) var forge_upgrade_resource_threshold: float = 100.0
@export_range(20.0, 2000.0, 5.0) var base_raid_readiness_threshold: float = 190.0
## How much high `ambition` (`0..1`) lowers the readiness threshold required to trigger `LAUNCH_RAID`.
@export_range(0.0, 500.0, 5.0) var ambition_raid_threshold_reduction: float = 70.0
## Discipline threshold (`>= 0.75`) above which the AI selects `CRESCENT_ENCIRCLEMENT_TRAP` Turan formation.
@export_range(0.1, 0.99, 0.01) var high_discipline_crescent_threshold: float = 0.75
## Discipline threshold (`>= 0.55`) above which the AI selects `FEIGNED_RETREAT_LURE` Turan formation.
@export_range(0.1, 0.95, 0.01) var medium_discipline_feigned_retreat_threshold: float = 0.55
## Ambition threshold (`>= 0.75`) above which the AI directly raids the player's `ger_camp` instead of `supply_line`.
@export_range(0.1, 0.99, 0.01) var high_ambition_camp_assault_threshold: float = 0.75
@export_range(0.1, 1.0, 0.01) var rogue_warband_default_ambition: float = 0.85
@export_range(0.1, 1.0, 0.01) var rogue_warband_default_discipline: float = 0.60


## Deterministic resource threshold required to advance from `GATHER_RESOURCES` to `UPGRADE_FORGE`.
func compute_effective_forge_threshold(ambition: float) -> float:
	var amb: float = clampf(ambition, 0.0, 1.0)
	return maxf(forge_upgrade_resource_threshold * (1.0 - amb * 0.25), 25.0)


## Deterministic readiness threshold required to advance from `UPGRADE_FORGE` to `LAUNCH_RAID`.
func compute_effective_raid_threshold(ambition: float, discipline: float) -> float:
	var amb: float = clampf(ambition, 0.0, 1.0)
	var disc: float = clampf(discipline, 0.0, 1.0)
	return maxf(base_raid_readiness_threshold - amb * ambition_raid_threshold_reduction + (1.0 - disc) * 20.0, 40.0)


## Deterministically selects the Turan Tactic formation for `LAUNCH_RAID`
## based on the dynasty/warband's `ambition` and `discipline`.
func select_deterministic_turan_phase(ambition: float, discipline: float) -> GameEnums.TuranTacticPhase:
	if discipline >= high_discipline_crescent_threshold:
		return GameEnums.TuranTacticPhase.CRESCENT_ENCIRCLEMENT_TRAP
	if discipline >= medium_discipline_feigned_retreat_threshold:
		return GameEnums.TuranTacticPhase.FEIGNED_RETREAT_LURE
	if ambition >= high_ambition_camp_assault_threshold:
		return GameEnums.TuranTacticPhase.BORU_SHOCK_ANNIHILATION
	return GameEnums.TuranTacticPhase.WHISTLING_ARROW_HARASSMENT


## Deterministically selects the raid target (`&"ger_camp"` or `&"supply_line"`)
## based on `ambition` and `discipline`.
func select_deterministic_raid_target(ambition: float, discipline: float) -> StringName:
	if ambition >= high_ambition_camp_assault_threshold and discipline >= medium_discipline_feigned_retreat_threshold:
		return &"ger_camp"
	return &"supply_line"


## Returns schema violations (empty when valid).
func get_validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if profile_id == &"":
		errors.append("AIBehaviorProfile: profile_id cannot be empty.")
	if base_gather_rate_per_tick <= 0.0 or forge_upgrade_resource_threshold <= 0.0:
		errors.append("AIBehaviorProfile: gather rate and thresholds must be > 0.")
	return errors
