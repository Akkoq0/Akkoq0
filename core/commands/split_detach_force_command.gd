class_name SplitDetachForceCommand
extends GameCommand
## Core command (rank 2). Splits an independent detachment (`FAST_CAVALRY_RECON_RAIDER`,
## `SUPPLY_ESCORT_GUARD`, or `OUTPOST_GARRISON`) from a parent army, transferring
## riders and proportional `quiver_ammo` while granting fast cavalry detachments
## a mobility speed bonus.

const ID: StringName = &"split_detach_force"

var parent_army_id: int = 1
var detachment_army_id: int = 100
var detached_riders: int = 200
var role: GameEnums.DetachmentRole = GameEnums.DetachmentRole.FAST_CAVALRY_RECON_RAIDER
var initial_parent_riders_if_unregistered: int = 1000
var initial_parent_quiver_if_unregistered: float = 24.0

var remaining_parent_riders: int = 0
var remaining_parent_quiver: float = 0.0
var detached_quiver_ammo: float = 0.0
var speed_bonus_multiplier: float = 1.0


func _init(p_parent_army_id: int, p_detachment_army_id: int, p_detached_riders: int, p_role: GameEnums.DetachmentRole = GameEnums.DetachmentRole.FAST_CAVALRY_RECON_RAIDER, p_initial_parent_riders: int = 1000) -> void:
	parent_army_id = p_parent_army_id
	detachment_army_id = p_detachment_army_id
	detached_riders = p_detached_riders
	role = p_role
	initial_parent_riders_if_unregistered = p_initial_parent_riders


func get_command_id() -> StringName:
	return ID
