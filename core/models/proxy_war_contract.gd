class_name ProxyWarContract
extends RefCounted
## Core model (rank 2). Covert silver-sponsored Yersiz Yurtsuz proxy raid
## agreement tracked by `ReputationAndPactSystem`.

var warband_id: StringName = &""
var sponsor_id: int = 0
var target_id: int = 0
var silver_cost: int = 45
var raid_intensity: float = 0.75
var exposed: bool = false
var exposed_to_id: int = 0
var casus_belli_granted: bool = false


func _init(
		p_warband_id: StringName,
		p_sponsor_id: int,
		p_target_id: int,
		p_silver_cost: int,
		p_raid_intensity: float = 0.75) -> void:
	warband_id = p_warband_id
	sponsor_id = p_sponsor_id
	target_id = p_target_id
	silver_cost = maxi(p_silver_cost, 0)
	raid_intensity = clampf(p_raid_intensity, 0.1, 2.0)
