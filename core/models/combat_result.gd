class_name CombatResult
extends RefCounted
## Core model (rank 2). Outcome of one combat exchange.

var attacker_id: int = 0
var defender_id: int = 0
var damage_to_defender: float = 0.0
var damage_to_attacker: float = 0.0
var defender_remaining_health: float = 0.0
var attacker_remaining_health: float = 0.0


## True when the defender has no health left.
func is_defender_destroyed() -> bool:
	return defender_remaining_health <= 0.0


## True when the attacker has no health left.
func is_attacker_destroyed() -> bool:
	return attacker_remaining_health <= 0.0
