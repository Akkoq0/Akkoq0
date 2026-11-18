class_name Stockpile
extends RefCounted
## Core model (rank 2). Per-player ore amounts. Pure state, no signals.

var player_id: int = 0
var _amounts: Dictionary[StringName, int] = {}
var _max_capacity: int = 0


func _init(p_player_id: int, p_max_capacity: int = 0) -> void:
	player_id = p_player_id
	_max_capacity = maxi(p_max_capacity, 0)


func set_max_capacity(max_capacity: int) -> void:
	_max_capacity = maxi(max_capacity, 0)


func get_max_capacity() -> int:
	return _max_capacity


## Current amount of `ore_id` (0 when never stored).
func get_amount(ore_id: StringName) -> int:
	return _amounts.get(ore_id, 0)


## Adds `delta` (may be negative) and returns the new amount, clamped to [0, _max_capacity].
func add(ore_id: StringName, delta: int) -> int:
	var next: int = maxi(get_amount(ore_id) + delta, 0)
	if _max_capacity > 0:
		next = mini(next, _max_capacity)
	_amounts[ore_id] = next
	return next


## True when every cost entry is covered.
func can_afford(costs: Array[ResourceAmount]) -> bool:
	for cost: ResourceAmount in costs:
		if cost == null or cost.ore == null:
			return false
		if get_amount(cost.get_ore_id()) < cost.amount:
			return false
	return true


## Snapshot copy of all amounts.
func get_snapshot() -> Dictionary[StringName, int]:
	return _amounts.duplicate()
