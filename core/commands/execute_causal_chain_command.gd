class_name ExecuteCausalChainCommand
extends GameCommand
## Core command (rank 2). Executes and propagates one of the 4 multi-step
## causal chains across ecology, Yılkı logistics, Turan tactics, battle fatigue,
## cascade rout, Kut/Toy governance, diplomacy coalitions, and Zud epidemics,
## with optional player counterplay (`counterplay_action`).

const ID: StringName = &"execute_causal_chain"

var archetype: GameEnums.CausalChainArchetype = GameEnums.CausalChainArchetype.ECOLOGICAL_LOGISTICS_COLLAPSE
var counterplay_action: GameEnums.CausalCounterplayAction = GameEnums.CausalCounterplayAction.NONE
var player_id: int = 1
var army_id: int = 1
var region_coord: Vector2i = Vector2i(3, 3)
var target_migration_coord: Vector2i = Vector2i(4, 3)
var combat_duration_sec: float = 28.0
var glory_score: float = 0.0
var commander_leadership: float = 85.0
var initial_troops: int = 200
var bey_id: StringName = &"bozkir_akinci_bey"

# --- Output Telemetry Across Chain Steps ------------------------------------
var steps_executed: PackedStringArray = PackedStringArray()
var counterplay_broke_chain: bool = false
var resulting_remount_ratio: float = 1.0
var effective_crescent_wing_angle_rad: float = 0.0
var crescent_trap_succeeded: bool = false
var rogue_warband_split: bool = false
var accumulated_battle_fatigue: float = 0.0
var fatigue_momentum_multiplier: float = 1.0
var cascade_rout_triggered: bool = false
var rear_strike_damage_multiplier: float = 1.0
var captured_toy_loot_value: float = 0.0
var resulting_kut: float = 75.0
var coalition_formed: bool = false
var coalition_broken_by_espionage_or_glory: bool = false
var warband_reintegrated_by_glory: bool = false
var epidemic_active: bool = false
var epidemic_purified: bool = false
var remaining_troops_after_epidemic: int = 200


func _init(p_archetype: GameEnums.CausalChainArchetype, p_counterplay: GameEnums.CausalCounterplayAction = GameEnums.CausalCounterplayAction.NONE, p_player_id: int = 1, p_army_id: int = 1) -> void:
	archetype = p_archetype
	counterplay_action = p_counterplay
	player_id = p_player_id
	army_id = p_army_id


func get_command_id() -> StringName:
	return ID
