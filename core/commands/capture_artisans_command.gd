class_name CaptureArtisansCommand
extends GameCommand
## Request command (rank 2). Transfers captive Master Smiths / Artisans
## (`Üstat Zanaatkâr`) from a defeated victim to the raiding captor, boosting
## the captor's Steel quality multiplier and crippling victim Meteoric Iron craft.

const ID: StringName = &"capture_artisans"

var victim_id: int = 0
var captor_id: int = 0
var requested_masters: int = 2

# Written by CaravanLogisticsManager
var captured_masters: int = 0
var victim_remaining_artisans: int = 0
var captor_artisans: int = 0
var victim_can_forge_meteoric: bool = true


func _init(p_victim_id: int, p_captor_id: int, p_requested_masters: int = 2) -> void:
	victim_id = p_victim_id
	captor_id = p_captor_id
	requested_masters = p_requested_masters


func get_command_id() -> StringName:
	return ID
