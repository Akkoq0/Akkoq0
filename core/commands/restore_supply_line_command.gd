class_name RestoreSupplyLineCommand
extends GameCommand
## Core command (rank 2). Re-establishes a supply corridor between a friendly
## depot / nomadic GerCamp and an `ISOLATED` army after raiders are cleared
## or the army returns inside depot range.

const ID: StringName = &"restore_supply_line"

var army_id: int = 0
var depot_id: int = 1
var restored_supply_ratio: float = 0.35
var was_isolated: bool = false
var restored: bool = false


func _init(p_army_id: int, p_depot_id: int = 1, p_restored_supply_ratio: float = 0.35) -> void:
	army_id = p_army_id
	depot_id = p_depot_id
	restored_supply_ratio = clampf(p_restored_supply_ratio, 0.0, 1.0)


func get_command_id() -> StringName:
	return ID
