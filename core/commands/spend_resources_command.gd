class_name SpendResourcesCommand
extends GameCommand
## Atomically deducts a list of costs from a player's stockpile (all or nothing).

const ID: StringName = &"spend_resources"

var player_id: int = 0
var costs: Array[ResourceAmount] = []


func _init(p_player_id: int, p_costs: Array[ResourceAmount]) -> void:
	player_id = p_player_id
	costs = p_costs


func get_command_id() -> StringName:
	return ID
