class_name StartResearchCommand
extends GameCommand
## Request command (rank 2). Validates DAG prerequisites for a Steppe Tradition
## & Military Research node, deducts silver cost via `SpendResourcesCommand`, and
## initiates seasonal progression inside `TraditionResearchManager`.

const ID: StringName = &"start_research"

var player_id: int = 1
var node_id: StringName = &""

# Populated by TraditionResearchManager handler
var started: bool = false
var silver_spent: int = 0
var duration_seasons: int = 0


func _init(p_player_id: int = 1, p_node_id: StringName = &"") -> void:
	player_id = p_player_id
	node_id = p_node_id


func get_command_id() -> StringName:
	return ID
