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

## Phase 4 Battle Fatigue & Psychological Cascade Rout attributes.
var combat_duration_sec: float = 0.0
var elite_vanguard_destroyed: bool = false
var elite_vanguard_id: StringName = &"bozkurt_cavalry"
var rookie_troop_ratio: float = 0.65
var is_fleeing_rout: bool = false

## Phase 11 Turan Doctrine maneuver readiness & leadership damping attributes.
var quiver_ammo_ratio: float = 1.0
var remount_horse_ratio: float = 1.0
var commander_leadership: float = 50.0
var attacker_dread_morale_shock_ratio: float = 0.0

## Phase 27B Modular Battle Doctrine & Matchup Context attributes.
var player_id: int = 0
var army_id: int = 0
var troop_count: int = 0
var region_coord: Vector2i = Vector2i.ZERO
var battle_doctrine: BattleDoctrineResource = null
var is_mud_terrain: bool = false


func _init(p_entity_id: int, p_attack: float, p_defense: float, p_health: float, p_supply_ratio: float) -> void:
	entity_id = p_entity_id
	attack = p_attack
	defense = p_defense
	health = p_health
	supply_ratio = clampf(p_supply_ratio, 0.0, 1.0)

