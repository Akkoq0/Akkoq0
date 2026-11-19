class_name PoliticsAndPactsRules
extends Resource
## Data layer (rank 1). Calibrated schema for Phase 22 **Governance Cap &
## Vassal Traits, Ülüş Silent Sabotage, Amanat Pacts, Proxy Warfare, and
## Reputation Memory (Reliability / Dread vs Honor-Töre)**.

@export var rules_id: StringName = &"politics_and_pacts_rules"

@export_group("Direct Governance Cap & Vassal Traits")
@export_range(1, 12) var direct_governance_cap: int = 3
@export_range(0, 4) var jade_cap_bonus_max: int = 1
@export_range(0.5, 20.0, 0.5) var over_cap_kut_drain_per_extra: float = 4.0
@export_range(0.05, 0.40, 0.01) var over_cap_tax_penalty_per_extra: float = 0.15
@export_range(0.10, 0.75, 0.05) var over_cap_tax_floor: float = 0.25

@export_group("Ülüş Contracts & Silent Sabotage")
@export_range(2.0, 48.0, 1.0) var ulus_unmet_silent_delay_hours: float = 12.0
@export_range(0.20, 0.90, 0.05) var ulus_unmet_troop_mult: float = 0.55
@export_range(5.0, 40.0, 1.0) var ulus_fulfillment_loyalty_gain: float = 8.0
@export_range(5.0, 50.0, 1.0) var ulus_shortfall_loyalty_drop: float = 18.0

@export_group("Amanat Pacts & Covert Proxy Wars")
@export_range(10.0, 60.0, 1.0) var amanat_break_reliability_penalty: float = 35.0
@export_range(-60.0, -5.0, 1.0) var amanat_break_trust_penalty: float = -30.0
@export_range(2.0, 25.0, 1.0) var amanat_fulfilled_honor_bonus: float = 8.0
@export_range(10, 200) var proxy_war_sponsor_bullion_cost: int = 45
@export_range(20.0, 100.0, 1.0) var proxy_discovery_scout_threshold: float = 65.0
@export_range(5.0, 40.0, 1.0) var proxy_exposed_infamy_spike: float = 22.0

@export_group("Dread (Dehşet) vs Honor (Töre)")
@export_range(0.05, 0.50, 0.01) var dread_morale_shock_max: float = 0.25
@export_range(20.0, 95.0, 1.0) var dread_truce_block_threshold: float = 60.0
@export_range(1.1, 4.0, 0.1) var dread_coalition_threat_multiplier: float = 2.0
@export_range(0.5, 10.0, 0.5) var honor_glory_per_season_max: float = 4.0
@export_range(30.0, 95.0, 1.0) var honor_voluntary_vassal_threshold: float = 65.0


func get_validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if rules_id == &"":
		errors.append("PoliticsAndPactsRules: rules_id cannot be empty.")
	if direct_governance_cap <= 0:
		errors.append("PoliticsAndPactsRules: direct_governance_cap must be positive.")
	if over_cap_tax_floor <= 0.0 or over_cap_tax_floor > 1.0:
		errors.append("PoliticsAndPactsRules: over_cap_tax_floor must be within (0, 1].")
	if ulus_unmet_troop_mult <= 0.0 or ulus_unmet_troop_mult >= 1.0:
		errors.append("PoliticsAndPactsRules: ulus_unmet_troop_mult must be within (0, 1).")
	if dread_coalition_threat_multiplier < 1.0:
		errors.append("PoliticsAndPactsRules: dread_coalition_threat_multiplier must be >= 1.0.")
	return errors
