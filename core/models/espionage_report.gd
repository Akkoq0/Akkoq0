class_name EspionageReport
extends RefCounted
## Core model (rank 2). Intelligence report produced by an infiltration mission
## against an enemy army or camp.

var spy_owner_id: int = 0
var target_faction_id: int = 0
var target_army_id: int = 0
var succeeded: bool = false
var computed_success_chance: float = 0.0
var revealed_quiver_ammo: float = -1.0
var revealed_tactic_intent: GameEnums.TuranTacticPhase = GameEnums.TuranTacticPhase.RECON_DUST_SCREEN
var revealed_doctrine_type: GameEnums.TacticalDoctrineType = GameEnums.TacticalDoctrineType.STANDARD_CHARGE
var spy_captured: bool = false
