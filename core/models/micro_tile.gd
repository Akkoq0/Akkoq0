class_name MicroTile
extends RefCounted
## Core model (rank 2). One tile of a micro settlement zone.

var coord: Vector2i = Vector2i.ZERO
var elevation: float = 0.0
var terrain: TerrainData = null
var is_settlement_clearing: bool = false
## Ore node on this tile (null when none).
var ore: OreData = null
var ore_amount: int = 0


func _init(p_coord: Vector2i, p_elevation: float, p_terrain: TerrainData) -> void:
	coord = p_coord
	elevation = p_elevation
	terrain = p_terrain


## True when a building may be placed here.
func is_buildable() -> bool:
	return terrain != null and terrain.is_buildable and ore == null


## True when an ore node is present.
func has_ore() -> bool:
	return ore != null and ore_amount > 0
