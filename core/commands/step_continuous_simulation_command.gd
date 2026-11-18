class_name StepContinuousSimulationCommand
extends GameCommand
## Core command (rank 2). Advances the continuous time-stepped causal pressure
## accumulation, decay, and counterplay recovery loop in `CausalChainEngine`.

const ID: StringName = &"step_continuous_simulation"

var player_id: int = 1
var army_id: int = 1
var delta_sec: float = 1.0
var is_pasture_depleted: bool = false
var is_migrating_sefer_arabasi: bool = false
var has_supply_line: bool = true
var is_zud_winter: bool = false
var fair_toy_ratio: float = 0.60
var is_resting_out_of_combat: bool = false

# --- Resulting Continuous State ---------------------------------------------
var ecological_pressure: float = 0.0
var logistics_strain: float = 0.0
var morale_panic_pressure: float = 0.0
var political_fracture_pressure: float = 0.0
var effective_remount_ratio: float = 1.0
var effective_maneuver_speed_mult: float = 1.0
var transition_records_emitted: int = 0


func _init(p_player_id: int, p_army_id: int, p_delta_sec: float, p_is_pasture_depleted: bool, p_is_migrating: bool, p_has_supply_line: bool, p_is_zud_winter: bool, p_fair_toy_ratio: float = 0.60, p_is_resting: bool = false) -> void:
	player_id = p_player_id
	army_id = p_army_id
	delta_sec = maxf(p_delta_sec, 0.0)
	is_pasture_depleted = p_is_pasture_depleted
	is_migrating_sefer_arabasi = p_is_migrating
	has_supply_line = p_has_supply_line
	is_zud_winter = p_is_zud_winter
	fair_toy_ratio = clampf(p_fair_toy_ratio, 0.0, 1.0)
	is_resting_out_of_combat = p_is_resting


func get_command_id() -> StringName:
	return ID
