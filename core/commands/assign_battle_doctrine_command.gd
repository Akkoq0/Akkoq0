class_name AssignBattleDoctrineCommand
extends GameCommand
## Request command (rank 2). Assigns a modular 4-layer `BattleDoctrineResource`
## (or instantiates one from `preset_id` via `DoctrinePresetCatalog`) to `army_id`
## and optionally synchronizes its Layer 4 standby contingency rule onto
## `OfflineDoctrineConfig` via `CommandBus`.

const ID: StringName = &"assign_battle_doctrine"

var army_id: int = 1
var player_id: int = 1
var doctrine: BattleDoctrineResource = null
var preset_id: GameEnums.BattleDoctrinePresetId = GameEnums.BattleDoctrinePresetId.KURT_KAPANI
var sync_offline_contingency: bool = true

# Written by CombatCalculator handler
var applied: bool = false
var applied_doctrine: BattleDoctrineResource = null
var applied_summary: String = ""
var synced_offline_config: OfflineDoctrineConfig = null


func _init(
		p_army_id: int = 1,
		p_player_id: int = 1,
		p_doctrine: BattleDoctrineResource = null,
		p_preset_id: GameEnums.BattleDoctrinePresetId = GameEnums.BattleDoctrinePresetId.KURT_KAPANI,
		p_sync_offline_contingency: bool = true) -> void:
	army_id = p_army_id
	player_id = p_player_id
	doctrine = p_doctrine
	preset_id = p_preset_id
	sync_offline_contingency = p_sync_offline_contingency


func get_command_id() -> StringName:
	return ID
