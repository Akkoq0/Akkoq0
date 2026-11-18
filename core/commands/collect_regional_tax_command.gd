class_name CollectRegionalTaxCommand
extends GameCommand
## Routes regional Silver/Gold tax (scaled by Jade Tamga/Authority) to the treasury.

const ID: StringName = &"collect_regional_tax"

var player_id: int = 0
var controlled_region_count: int = 0
var rich_region_count: int = 0
var collected_tax: int = 0
var applied_authority_multiplier: float = 1.0


func _init(p_player_id: int, p_controlled_region_count: int, p_rich_region_count: int = 0) -> void:
	player_id = p_player_id
	controlled_region_count = p_controlled_region_count
	rich_region_count = p_rich_region_count


func get_command_id() -> StringName:
	return ID
