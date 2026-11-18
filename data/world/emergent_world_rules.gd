class_name EmergentWorldRules
extends Resource
## Data layer (rank 1). Causal thresholds and inter-faction conflict parameters
## for Phase 8 **Emergent Steppe Causality Engine (`EmergentWorldEngine`)**
## (`res://data/world/emergent_world_rules.tres`).

@export var rules_id: StringName = &"steppe_emergent_causality_rules"
## Yılkı herd attrition ratio when Overgrazed Pasture + Zud Winter + Severed Supply Line co-occur.
@export_range(0.05, 0.80, 0.05) var zud_pasture_supply_yilki_attrition: float = 0.25
## Quiver ammo threshold below which low-ammo emergent border pressure can trigger.
@export_range(1.0, 50.0, 1.0) var low_quiver_ammo_threshold: float = 6.0
## Kut threshold below which high captive counts trigger an emergent fracture chain.
@export_range(10.0, 60.0, 1.0) var fracture_kut_threshold: float = 35.0
## Mutual exhaustion ratio inflicted on two AI factions fighting each other over pastures/ores.
@export_range(0.10, 0.85, 0.05) var inter_faction_mutual_exhaustion_ratio: float = 0.45
## Silver/Gold bullion earned when the player stays neutral and sells weapons/ores to warring factions.
@export_range(10, 500, 10) var neutral_trade_profiteer_bullion: int = 80
## Toy loot value captured when the player waits for both warring factions to exhaust each other and strikes both.
@export_range(50.0, 2000.0, 25.0) var opportunistic_double_strike_loot: float = 420.0
## Allied reward value when joining either the attacker or defender in an inter-faction war.
@export_range(25.0, 1000.0, 25.0) var coalition_intervention_reward: float = 210.0


## Returns open-ended sandbox responses for `chain_id` (zero quest lock-in).
func get_open_responses_for_chain(chain_id: StringName) -> PackedStringArray:
	if chain_id == &"zud_pasture_supply_collapse":
		return PackedStringArray(["kurgan_purification_ritual", "migrate_to_fertile_basin", "raid_rival_supply_convoy"])
	if chain_id == &"quiver_famine_border_opportunism":
		return PackedStringArray(["smelt_steel_arrowheads", "feigned_retreat_into_sik_orman", "dispatch_envoy_or_assassin"])
	if chain_id == &"captive_unrest_kut_fracture":
		return PackedStringArray(["integrate_captives_via_toy_feast", "ransom_or_exchange_captives", "enforce_martial_curfew"])
	return PackedStringArray(["free_steppe_maneuver"])


## Returns schema violations (empty when valid).
func get_validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if rules_id == &"":
		errors.append("EmergentWorldRules: rules_id cannot be empty.")
	if zud_pasture_supply_yilki_attrition <= 0.0 or inter_faction_mutual_exhaustion_ratio <= 0.0:
		errors.append("EmergentWorldRules: attrition and exhaustion ratios must be > 0.")
	return errors
