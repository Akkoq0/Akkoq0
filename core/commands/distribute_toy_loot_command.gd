class_name DistributeToyLootCommand
extends GameCommand
## Executes post-raid Toy & Meat (Ülüş / Söğüş) loot distribution for a regional Bey.

const ID: StringName = &"distribute_toy_loot"

var bey_id: StringName = &""
var total_loot_value: float = 0.0
var allocated_bey_value: float = 0.0
var sogus_meat_fair: bool = true
var resulting_satisfaction: float = 0.0
var turned_rogue_warband: bool = false
var spawned_warband_title: String = ""


func _init(p_bey_id: StringName, p_total_loot_value: float, p_allocated_bey_value: float, p_sogus_meat_fair: bool = true) -> void:
	bey_id = p_bey_id
	total_loot_value = p_total_loot_value
	allocated_bey_value = p_allocated_bey_value
	sogus_meat_fair = p_sogus_meat_fair


func get_command_id() -> StringName:
	return ID
