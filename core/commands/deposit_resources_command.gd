class_name DepositResourcesCommand
extends GameCommand
## Adds ore to a player's stockpile.

const ID: StringName = &"deposit_resources"

var player_id: int = 0
var ore_id: StringName = &""
var amount: int = 0
## Result: stockpile amount after the deposit.
var resulting_amount: int = 0


func _init(p_player_id: int, p_ore_id: StringName, p_amount: int) -> void:
	player_id = p_player_id
	ore_id = p_ore_id
	amount = p_amount


func get_command_id() -> StringName:
	return ID
