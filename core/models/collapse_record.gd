class_name CollapseRecord
extends RefCounted
## Core model (rank 2). Per-player Phase 20 collapse, retreat truce,
## Vassal Beylik, Homeless Exile, Frontier March, and Extinction state.

var player_id: int = 0
var conqueror_id: int = 0
var overlord_id: int = 0
var state: GameEnums.CollapseState = GameEnums.CollapseState.SOVEREIGN
var truce_remaining_hours: float = 0.0
var tribute_rate: float = 0.20
var exile_hope_loyalty: float = 80.0
var exile_caravans_remaining: int = 1
var frontier_coord: Vector2i = Vector2i.ZERO
var extinction_seasons_elapsed: int = 0
var glory_reset_count: int = 0
var current_glory: float = 0.0


func _init(p_player_id: int = 0) -> void:
	player_id = p_player_id
