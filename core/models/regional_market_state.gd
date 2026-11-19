class_name RegionalMarketState
extends RefCounted
## Core model (rank 2). Tracks per-region dynamic scarcity multipliers,
## disrupted trade counts, and black-market activity for Phase 23 barter trading.

var region_coord: Vector2i = Vector2i.ZERO
var scarcity_multipliers: Dictionary[StringName, float] = {}
var local_stocks: Dictionary[StringName, int] = {}
var trade_routes_disrupted: int = 0
var black_market_open: bool = false
var total_volume_traded: int = 0


func _init(p_coord: Vector2i = Vector2i.ZERO) -> void:
	region_coord = p_coord


func get_scarcity(commodity_id: StringName) -> float:
	if scarcity_multipliers.has(commodity_id):
		return scarcity_multipliers[commodity_id]
	return 1.0


func set_scarcity(commodity_id: StringName, val: float) -> void:
	scarcity_multipliers[commodity_id] = val
