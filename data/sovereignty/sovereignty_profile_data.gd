class_name SovereigntyProfileData
extends Resource
## Data layer (rank 1). Schema for Phase 8 **Dynamic Behavioral Sovereignty
## Alignment & Free Sandbox Evolution** (`res://data/sovereignty/sovereignty_profile_data.tres`).
##
## Evaluates the player's actual actions (telemetry) without ever locking out
## alternative paths (`zero quest lock-in`).

@export var profile_id: StringName = &"steppe_sandbox_sovereignty"

@export_group("Telemetry Weights — Ulu Kağan & Töre Koruyucusu")
@export_range(0.1, 10.0, 0.1) var kut_weight: float = 1.0
@export_range(1.0, 50.0, 1.0) var tore_decree_action_weight: float = 18.0

@export_group("Telemetry Weights — Bozkır Akıncısı & Yağma Beyi")
@export_range(1.0, 50.0, 1.0) var raid_and_interdiction_weight: float = 22.0
@export_range(0.1, 10.0, 0.1) var glory_weight: float = 1.15
@export_range(1.0, 50.0, 1.0) var toy_loot_distribution_weight: float = 14.0

@export_group("Telemetry Weights — Göçebe Tüccar & Demirci Hanedanı")
@export_range(1.0, 50.0, 1.0) var seven_ore_refining_weight: float = 20.0
@export_range(1.0, 50.0, 1.0) var tax_and_trade_weight: float = 16.0
@export_range(1.0, 50.0, 1.0) var sefer_arabasi_migration_weight: float = 18.0

@export_group("Telemetry Weights — Asi / Bağımsız Oymak")
@export_range(1.0, 60.0, 1.0) var council_defiance_weight: float = 25.0
@export_range(0.1, 10.0, 0.1) var low_kut_autonomy_weight: float = 1.10


## Computes the 4 alignment scores from behavioral telemetry counters.
func compute_alignment_scores(kut_score: float, tore_actions: int, raid_actions: int, glory_score: float, toy_actions: int, refining_actions: int, trade_actions: int, migration_actions: int, defiance_actions: int) -> Dictionary[GameEnums.SovereigntyAlignment, float]:
	var ulu_kagan: float = clampf(kut_score, 0.0, 100.0) * kut_weight + float(maxi(tore_actions, 0)) * tore_decree_action_weight
	var raider: float = float(maxi(raid_actions, 0)) * raid_and_interdiction_weight + clampf(glory_score, 0.0, 100.0) * glory_weight + float(maxi(toy_actions, 0)) * toy_loot_distribution_weight
	var merchant: float = float(maxi(refining_actions, 0)) * seven_ore_refining_weight + float(maxi(trade_actions, 0)) * tax_and_trade_weight + float(maxi(migration_actions, 0)) * sefer_arabasi_migration_weight
	var rebel: float = float(maxi(defiance_actions, 0)) * council_defiance_weight + maxf(50.0 - clampf(kut_score, 0.0, 100.0), 0.0) * low_kut_autonomy_weight

	var scores: Dictionary[GameEnums.SovereigntyAlignment, float] = {
		GameEnums.SovereigntyAlignment.ULU_KAGAN_TORE_GUARDIAN: ulu_kagan,
		GameEnums.SovereigntyAlignment.STEPPE_RAIDER_WARLORD: raider,
		GameEnums.SovereigntyAlignment.NOMADIC_MERCHANT_FORGEMASTER: merchant,
		GameEnums.SovereigntyAlignment.REBEL_INDEPENDENT_CLAN: rebel,
	}
	return scores


## Returns open-ended strategic actions emphasized by `alignment` (while keeping all base actions open).
func get_alignment_strategic_options(alignment: GameEnums.SovereigntyAlignment) -> PackedStringArray:
	if alignment == GameEnums.SovereigntyAlignment.ULU_KAGAN_TORE_GUARDIAN:
		return PackedStringArray(["peaceful_vassal_integration", "kurultai_confederation_call", "sacred_kurgan_blessing"])
	if alignment == GameEnums.SovereigntyAlignment.STEPPE_RAIDER_WARLORD:
		return PackedStringArray(["free_rogue_warband_rally", "deep_steppe_convoy_ambush", "great_toy_feast_decree"])
	if alignment == GameEnums.SovereigntyAlignment.NOMADIC_MERCHANT_FORGEMASTER:
		return PackedStringArray(["mobile_sefer_forge_caravan", "seven_ore_masterwork_contract", "neutral_war_arms_profiteering"])
	return PackedStringArray(["defy_ak_sakallilar_council", "autonomous_steppe_law", "break_all_dynasty_treaties"])


## Returns schema violations (empty when valid).
func get_validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if profile_id == &"":
		errors.append("SovereigntyProfileData: profile_id cannot be empty.")
	if kut_weight <= 0.0 or raid_and_interdiction_weight <= 0.0 or seven_ore_refining_weight <= 0.0 or council_defiance_weight <= 0.0:
		errors.append("SovereigntyProfileData: all telemetry weights must be > 0.")
	return errors
