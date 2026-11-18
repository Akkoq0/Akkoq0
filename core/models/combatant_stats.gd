class_name CombatantStats
extends RefCounted
## Core model (rank 2). Immutable-by-convention snapshot of a combatant.

var entity_id: int = 0
var attack: float = 0.0
var defense: float = 0.0
var health: float = 0.0
## 0..1 supply ratio at the moment of combat.
var supply_ratio: float = 1.0
## Fractional bonuses granted by active totems (0.1 = +10%).
var totem_offense_bonus: float = 0.0
var totem_defense_bonus: float = 0.0


func _init(p_entity_id: int, p_attack: float, p_defense: float, p_health: float, p_supply_ratio: float) -> void:
	entity_id = p_entity_id
	attack = p_attack
	defense = p_defense
	health = p_health
	supply_ratio = clampf(p_supply_ratio, 0.0, 1.0)
