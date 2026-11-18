class_name CombatantStats
extends RefCounted
## Core model (rank 2). Snapshot of a combatant for the Phase 3 **Triple
## Collapse Model** (Physical Health + Formation Cohesion + Battle Morale/Will).

var entity_id: int = 0
var attack: float = 0.0
var defense: float = 0.0
var health: float = 0.0
## 0..1 supply ratio at the moment of combat.
var supply_ratio: float = 1.0
## Fractional bonuses granted by active totems (0.1 = +10%).
var totem_offense_bonus: float = 0.0
var totem_defense_bonus: float = 0.0

## Phase 3 Triple Collapse attributes.
var cohesion: float = 100.0
var morale: float = 100.0
var fatigue: float = 0.0
var formation_entropy: float = 0.0
## Fraction (0..0.45) of armor defense lost due to Feigned Retreat overextension.
var armor_collapse_ratio: float = 0.0

## Vectorial orientation: default is a head-on frontal engagement (`dot = -1.0`).
var facing_vector: Vector3 = Vector3.FORWARD
var attack_vector: Vector3 = Vector3.BACK

## 7-Ore & tactical state flags.
var has_steel_weapons: bool = false
var has_meteoric_iron_weapon: bool = false
var is_cavalry: bool = true
var is_escape_vector_sealed: bool = false
var active_tactic_phase: GameEnums.TuranTacticPhase = GameEnums.TuranTacticPhase.RECON_DUST_SCREEN
var kut_legitimacy_multiplier: float = 1.0
var charge_mass_momentum: float = 1.0


func _init(p_entity_id: int, p_attack: float, p_defense: float, p_health: float, p_supply_ratio: float) -> void:
	entity_id = p_entity_id
	attack = p_attack
	defense = p_defense
	health = p_health
	supply_ratio = clampf(p_supply_ratio, 0.0, 1.0)
