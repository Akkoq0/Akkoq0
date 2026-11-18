class_name StepAntiSnowballTickCommand
extends GameCommand
## Executes a Phase 18 non-linear anti-snowball maintenance tick (exponential
## pasture drain, Food spoilage, Steel/Iron upkeep with Jade/Meteoric Iron
## preservation, and passive Kut erosion on stagnant large Khaganates).

const ID: StringName = &"step_anti_snowball_tick"

var player_id: int = 1
var days_elapsed: float = 1.0
var unit_count: int = 100
var steel_equipped_troops: int = 0
var herd_size: int = 250
var pasture_coord: Vector2i = Vector2i.ZERO
var is_actively_campaigning: bool = true

# Results populated by GracePeriodManager
var exponential_pasture_multiplier: float = 1.0
var food_spoiled: int = 0
var steel_upkeep_consumed: int = 0
var iron_upkeep_consumed: int = 0
var kut_stagnation_drain: float = 0.0
var idle_days_accumulated: float = 0.0


func _init(
		p_player_id: int = 1,
		p_days_elapsed: float = 1.0,
		p_unit_count: int = 100,
		p_steel_equipped_troops: int = 0,
		p_herd_size: int = 250,
		p_pasture_coord: Vector2i = Vector2i.ZERO,
		p_is_campaigning: bool = true) -> void:
	player_id = p_player_id
	days_elapsed = p_days_elapsed
	unit_count = p_unit_count
	steel_equipped_troops = p_steel_equipped_troops
	herd_size = p_herd_size
	pasture_coord = p_pasture_coord
	is_actively_campaigning = p_is_campaigning


func get_command_id() -> StringName:
	return ID
