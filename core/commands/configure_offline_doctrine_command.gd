class_name ConfigureOfflineDoctrineCommand
extends GameCommand
## Request command (rank 2). Configures an army's conditional **Bozkır Nöbeti**
## (`OfflineDoctrineComponent`) three-block rule via `CommandBus` without
## direct UI mutation of core managers or unit components.

const ID: StringName = &"configure_offline_doctrine"

var army_id: int = 1
var player_id: int = 1
var trigger_condition: GameEnums.OfflineDoctrineTrigger = GameEnums.OfflineDoctrineTrigger.ENEMY_POWER_RATIO_EXCEEDED
var power_ratio_threshold: float = 1.5
var low_supply_threshold: float = 0.20
var action_tactic: GameEnums.TuranTacticPhase = GameEnums.TuranTacticPhase.FEIGNED_RETREAT_LURE
var pack_sefer_arabasi: bool = true
var evade_combat: bool = true
var target_terrain_class: GameEnums.TerrainClass = GameEnums.TerrainClass.SIK_ORMAN
var target_geography_class: GameEnums.RegionGeographyClass = GameEnums.RegionGeographyClass.FOREST_EDGE

# Written by GracePeriodManager handler
var applied: bool = false
var applied_summary: String = ""


func _init(
		p_army_id: int = 1,
		p_player_id: int = 1,
		p_trigger: GameEnums.OfflineDoctrineTrigger = GameEnums.OfflineDoctrineTrigger.ENEMY_POWER_RATIO_EXCEEDED,
		p_power_ratio: float = 1.5,
		p_low_supply: float = 0.20,
		p_action_tactic: GameEnums.TuranTacticPhase = GameEnums.TuranTacticPhase.FEIGNED_RETREAT_LURE,
		p_pack_cart: bool = true,
		p_evade_combat: bool = true,
		p_target_terrain: GameEnums.TerrainClass = GameEnums.TerrainClass.SIK_ORMAN,
		p_target_geo: GameEnums.RegionGeographyClass = GameEnums.RegionGeographyClass.FOREST_EDGE) -> void:
	army_id = p_army_id
	player_id = p_player_id
	trigger_condition = p_trigger
	power_ratio_threshold = p_power_ratio
	low_supply_threshold = p_low_supply
	action_tactic = p_action_tactic
	pack_sefer_arabasi = p_pack_cart
	evade_combat = p_evade_combat
	target_terrain_class = p_target_terrain
	target_geography_class = p_target_geo


func get_command_id() -> StringName:
	return ID
