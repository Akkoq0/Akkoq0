class_name DispatchSpyCommand
extends GameCommand
## Core command (rank 2). Dispatches a spy into an enemy camp or warband to
## uncover its hidden quiver ammunition (`quiver_ammo`) and Turan tactic intent.

const ID: StringName = &"dispatch_spy"

var spy_owner_id: int = 0
var target_faction_id: int = 0
var target_army_id: int = 0
var commander_leadership: float = 50.0
var terrain: TerrainData = null
var target_quiver_ammo: float = 0.0
var target_tactic_intent: GameEnums.TuranTacticPhase = GameEnums.TuranTacticPhase.RECON_DUST_SCREEN
var target_doctrine_type: GameEnums.TacticalDoctrineType = GameEnums.TacticalDoctrineType.STANDARD_CHARGE
var counter_espionage: float = 0.0
var rng_seed: int = 1
var report: EspionageReport = null


func _init(p_spy_owner_id: int, p_target_faction_id: int, p_target_army_id: int, p_commander_leadership: float, p_terrain: TerrainData, p_target_quiver_ammo: float, p_target_tactic_intent: GameEnums.TuranTacticPhase, p_target_doctrine_type: GameEnums.TacticalDoctrineType = GameEnums.TacticalDoctrineType.FEIGNED_RETREAT, p_counter_espionage: float = 0.0, p_rng_seed: int = 1) -> void:
	spy_owner_id = p_spy_owner_id
	target_faction_id = p_target_faction_id
	target_army_id = p_target_army_id
	commander_leadership = p_commander_leadership
	terrain = p_terrain
	target_quiver_ammo = p_target_quiver_ammo
	target_tactic_intent = p_target_tactic_intent
	target_doctrine_type = p_target_doctrine_type
	counter_espionage = p_counter_espionage
	rng_seed = p_rng_seed


func get_command_id() -> StringName:
	return ID
