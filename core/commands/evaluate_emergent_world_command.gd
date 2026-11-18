class_name EvaluateEmergentWorldCommand
extends GameCommand
## Core command (rank 2). Evaluates multi-variable world state conditions
## (`pasture_depleted`, `is_zud_winter`, `supply_line_severed`, `kut_score`,
## `quiver_ammo`, `captured_slave_workers`, `clan_population`) and triggers
## non-linear emergent causal chains (`EmergentChain`) without quest lock-in.

const ID: StringName = &"evaluate_emergent_world"

var region_coord: Vector2i = Vector2i.ZERO
var pasture_depleted: bool = false
var is_zud_winter: bool = false
var supply_line_severed: bool = false
var kut_score: float = 75.0
var quiver_ammo: float = 24.0
var hostile_neighbor_present: bool = false
var captured_slave_workers: int = 0
var clan_population: int = 120

var triggered_chain_ids: PackedStringArray = PackedStringArray()
var available_responses: PackedStringArray = PackedStringArray()
var yilki_herd_attrition_ratio: float = 0.0
var rogue_warband_split_triggered: bool = false
var spawned_rogue_warband_id: StringName = &""


func _init(p_region_coord: Vector2i, p_pasture_depleted: bool, p_is_zud_winter: bool, p_supply_line_severed: bool) -> void:
	region_coord = p_region_coord
	pasture_depleted = p_pasture_depleted
	is_zud_winter = p_is_zud_winter
	supply_line_severed = p_supply_line_severed


func get_command_id() -> StringName:
	return ID
