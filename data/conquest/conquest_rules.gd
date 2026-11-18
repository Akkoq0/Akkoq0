class_name ConquestRules
extends Resource
## Data layer (rank 1). Calibrated schema for Phase 19 **Hybrid Steppe
## Conquest, Seasonal Yaylak/Kışlak Shift, Bozkır Tuğu & Sacred Kurgans**
## (`res://data/conquest/conquest_rules.tres`).

@export var rules_id: StringName = &"steppe_conquest_rules"

@export_group("Seasonal Yaylak / Kislak Shift")
@export_range(0.5, 3.0, 0.05) var yaylak_warm_regen_mult: float = 1.65
@export_range(0.5, 3.0, 0.05) var yaylak_warm_yilki_breed_mult: float = 1.40
@export_range(1.0, 5.0, 0.05) var yaylak_winter_freeze_attrition_mult: float = 2.40
@export_range(0.5, 3.0, 0.05) var yaylak_winter_supply_drain_mult: float = 1.80
@export_range(0.2, 1.5, 0.05) var kislak_winter_shelter_attrition_mult: float = 0.55
@export_range(0.2, 1.5, 0.05) var kislak_winter_supply_drain_mult: float = 0.65
@export_range(0.0, 1.5, 0.05) var kislak_winter_regen_mult: float = 0.50
@export_range(0.5, 10.0, 0.5) var sacred_core_kurgan_kut_per_season: float = 2.0
@export_range(0.0, 0.9, 0.05) var sacred_core_epidemic_resistance: float = 0.45

@export_group("Border Nodes & Bozkir Tugu")
@export_range(25.0, 500.0, 5.0) var base_tug_radius_m: float = 120.0
@export_range(0.05, 0.85, 0.05) var overlap_caravan_disruption_ratio: float = 0.35

@export_group("Yurt Claims & 3 Defense Responses")
@export_range(1.0, 40.0, 1.0) var claim_kut_cost: float = 8.0
@export_range(0.0, 50.0, 1.0) var claim_glory_cost: float = 10.0
@export_range(4.0, 48.0, 1.0) var claim_contestation_hours: float = 18.0
@export_range(6.0, 72.0, 1.0) var tribute_freeze_hours: float = 24.0
@export_range(1, 50) var tribute_steel_cost: int = 8
@export_range(0, 20) var tribute_meteoric_cost: int = 2
@export_range(0.05, 0.60, 0.05) var tribute_yilki_drop: float = 0.20
@export_range(-80.0, -5.0, 1.0) var kan_davasi_trust_penalty: float = -35.0
@export_range(5.0, 80.0, 1.0) var kan_davasi_coalition_threat_boost: float = 35.0

@export_group("Post-Conquest Control, Scorched Earth & Kurgans")
@export_range(5.0, 60.0, 1.0) var initial_conquest_control: float = 20.0
@export_range(10.0, 70.0, 1.0) var low_control_rebellion_threshold: float = 40.0
@export_range(5.0, 40.0, 1.0) var garrison_control_gain_per_step: float = 15.0
@export_range(5.0, 50.0, 1.0) var toy_festival_control_gain: float = 20.0
@export_range(5.0, 50.0, 1.0) var vassal_appointment_control_bonus: float = 25.0
@export_range(0.25, 0.95, 0.05) var scorched_earth_speed_penalty_mult: float = 0.60
@export_range(0.20, 0.95, 0.05) var scorched_earth_supply_penalty_mult: float = 0.50
@export_range(1, 12) var scorched_earth_duration_seasons: int = 4
@export_range(10, 500) var scorched_earth_pillage_bullion: int = 55
@export_range(5, 200) var scorched_earth_captive_workers: int = 35
@export_range(0.50, 0.90, 0.01) var kurgan_majority_threshold_ratio: float = 0.51
@export_range(10.0, 80.0, 1.0) var kurgan_hegemon_threat_spike: float = 40.0


func get_validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if rules_id == &"":
		errors.append("ConquestRules: rules_id cannot be empty.")
	if base_tug_radius_m <= 0.0:
		errors.append("ConquestRules: base_tug_radius_m must be > 0.")
	if initial_conquest_control <= 0.0 or initial_conquest_control > 100.0:
		errors.append("ConquestRules: initial_conquest_control must lie in (0, 100].")
	if kurgan_majority_threshold_ratio <= 0.50 or kurgan_majority_threshold_ratio > 1.0:
		errors.append("ConquestRules: kurgan_majority_threshold_ratio must exceed 0.50.")
	return errors
