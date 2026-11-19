class_name CombatResult
extends RefCounted
## Core model (rank 2). Outcome of one exchange under the Phase 3 **Triple
## Collapse Model** (Physical Casualties + Formation Cohesion + Battle Will).

var attacker_id: int = 0
var defender_id: int = 0
var damage_to_defender: float = 0.0
var damage_to_attacker: float = 0.0
var defender_remaining_health: float = 0.0
var attacker_remaining_health: float = 0.0

## Phase 3 vectorial & Triple Collapse outcomes.
var engagement_angle: GameEnums.CombatEngagementAngle = GameEnums.CombatEngagementAngle.FRONT
var directional_damage_multiplier: float = 1.0
var cohesion_damage_to_defender: float = 0.0
var morale_damage_to_defender: float = 0.0
var defender_remaining_cohesion: float = 100.0
var defender_remaining_morale: float = 100.0
var defender_routed: bool = false
var defender_annihilated_in_crescent: bool = false
var captured_toy_loot_value: float = 0.0

## Phase 4 Battle Fatigue & Cascade Rout outcomes.
var attacker_fatigue_momentum_multiplier: float = 1.0
var cascade_rout_triggered: bool = false
var captured_slave_workers: int = 0

## Phase 27B Modular Battle Doctrine matchup outcome (null when no BattleDoctrineResource is active).
var doctrine_matchup: DoctrineMatchupResult = null



## True when the defender has no health left.
func is_defender_destroyed() -> bool:
	return defender_remaining_health <= 0.0


## True when the attacker has no health left.
func is_attacker_destroyed() -> bool:
	return attacker_remaining_health <= 0.0
