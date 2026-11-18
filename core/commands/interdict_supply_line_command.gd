class_name InterdictSupplyLineCommand
extends GameCommand
## Severs the active supply convoy between a `SupplyDepotNode` / `GerCamp` and
## a field army, transferring the convoy's rations/horses to the raider and
## isolating (`ISOLATED`) the target army.

const ID: StringName = &"interdict_supply_line"

var target_army_id: int = 0
var depot_id: int = 0
var raider_id: StringName = &""
var convoy_data: SupplyConvoyData = null
var captured_loot_value: float = 0.0
var captured_food_ration: int = 0
var captured_remount_ratio: float = 0.0
var target_isolated: bool = false


func _init(p_target_army_id: int, p_depot_id: int, p_raider_id: StringName, p_convoy_data: SupplyConvoyData = null) -> void:
	target_army_id = p_target_army_id
	depot_id = p_depot_id
	raider_id = p_raider_id
	convoy_data = p_convoy_data


func get_command_id() -> StringName:
	return ID
