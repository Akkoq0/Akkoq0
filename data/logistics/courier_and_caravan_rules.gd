class_name CourierAndCaravanRules
extends Resource
## Data layer (rank 1). Calibrated schema for Phase 21 **Courier Dispatch
## Latency, Dust Screen Deception, Heavy Armor Terrain Fatigue, Physical
## Non-Teleporting Caravans, and Captured Master Artisans**.

@export var rules_id: StringName = &"courier_and_caravan_rules"

@export_group("Courier Latency & Ambush")
@export_range(5.0, 60.0, 1.0) var courier_base_speed_m_per_sec: float = 18.0
@export_range(1.0, 4.0, 0.05) var mountain_forest_delay_mult: float = 1.65
@export_range(1.0, 3.0, 0.05) var winter_storm_delay_mult: float = 1.45

@export_group("Dust Screen Deception")
@export_range(0.05, 0.40, 0.01) var decoy_yilki_horse_cost: float = 0.15
@export_range(1.2, 4.0, 0.05) var decoy_apparent_power_mult: float = 2.10
@export_range(20.0, 100.0, 1.0) var scout_reveal_threshold: float = 70.0
@export_range(5.0, 100.0, 1.0) var close_contact_reveal_distance_m: float = 35.0

@export_group("Heavy Armor Exponential Terrain Fatigue")
@export_range(1.0, 4.0, 0.05) var heavy_armor_mud_fatigue_mult: float = 2.10
@export_range(1.0, 4.0, 0.05) var heavy_armor_slope_fatigue_mult: float = 1.90
@export_range(1.0, 4.0, 0.05) var heavy_armor_storm_fatigue_mult: float = 1.75
@export_range(1.0, 2.0, 0.05) var heavy_armor_exponential_power: float = 1.35
@export_range(0.30, 1.0, 0.05) var light_cavalry_terrain_resilience: float = 0.65

@export_group("Physical Caravans & Master Artisans")
@export_range(4.0, 40.0, 1.0) var caravan_speed_m_per_sec: float = 11.0
@export_range(5.0, 60.0, 1.0) var interception_ammo_shock: float = 28.0
@export_range(0.05, 0.80, 0.05) var interception_supply_shock: float = 0.35
@export_range(1, 30) var initial_artisans_per_player: int = 8
@export_range(1, 20) var meteoric_forging_min_artisans: int = 6
@export_range(0.01, 0.20, 0.01) var steel_quality_per_artisan: float = 0.05


func get_validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if rules_id == &"":
		errors.append("CourierAndCaravanRules: rules_id cannot be empty.")
	if courier_base_speed_m_per_sec <= 0.0 or caravan_speed_m_per_sec <= 0.0:
		errors.append("CourierAndCaravanRules: speeds must be positive.")
	if initial_artisans_per_player < meteoric_forging_min_artisans:
		errors.append("CourierAndCaravanRules: initial artisans must meet meteoric threshold.")
	return errors
