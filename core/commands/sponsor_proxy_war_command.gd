class_name SponsorProxyWarCommand
extends GameCommand
## Request command (rank 2). Secretly funds a Yersiz Yurtsuz exile warband
## with Silver (`silver_gold`) to raid `target_id` without initial attribution.

const ID: StringName = &"sponsor_proxy_war"

var sponsor_id: int = 0
var warband_id: StringName = &""
var target_id: int = 0
var silver_cost: int = 45
var raid_intensity: float = 0.75

# Written by ReputationAndPactSystem
var sponsored: bool = false
var concealed: bool = true


func _init(
		p_sponsor_id: int,
		p_warband_id: StringName,
		p_target_id: int,
		p_silver_cost: int = 45,
		p_raid_intensity: float = 0.75) -> void:
	sponsor_id = p_sponsor_id
	warband_id = p_warband_id
	target_id = p_target_id
	silver_cost = maxi(p_silver_cost, 1)
	raid_intensity = clampf(p_raid_intensity, 0.1, 2.0)


func get_command_id() -> StringName:
	return ID
