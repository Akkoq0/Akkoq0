class_name WorkerGatheringProfile
extends Resource
## Data layer (rank 1). Balancing parameters for Phase 6 **Nomadic Worker
## Detachments (`Oymak İşçileri`) & Caravan Resource Gathering Pipeline**.

@export var worker_title: String = "Oymak İşçileri"
@export_range(0.5, 100.0, 0.1) var walk_speed_m_per_sec: float = 12.0
@export_range(0.5, 100.0, 0.1) var caravan_haul_speed_m_per_sec: float = 8.0
@export_range(0.1, 120.0, 0.1) var harvest_duration_sec: float = 2.0
@export_range(1, 5000) var carry_capacity_per_trip: int = 20
@export_range(0.05, 5.0, 0.05) var arrival_tolerance_m: float = 0.75
## Ore stockpile ID credited when forest wood is converted into charcoal/fuel at GerCamp.
@export var forest_wood_deposit_ore_id: StringName = &"coal"


## Returns schema violations (empty when valid).
func get_validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if worker_title.is_empty():
		errors.append("WorkerGatheringProfile: worker_title cannot be empty.")
	if walk_speed_m_per_sec <= 0.0 or caravan_haul_speed_m_per_sec <= 0.0:
		errors.append("WorkerGatheringProfile: speeds must be > 0.")
	if harvest_duration_sec <= 0.0 or carry_capacity_per_trip <= 0:
		errors.append("WorkerGatheringProfile: harvest_duration_sec and carry_capacity_per_trip must be > 0.")
	return errors
