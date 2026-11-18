class_name AssassinateEnvoyCommand
extends GameCommand
## Core command (rank 2). Executes a rival dynasty's diplomatic envoy, granting
## an immediate Kut surge to the Khagan while triggering an unavoidable Total War
## (`TOTAL_WAR_GREAT_RAID` / Büyük Yağma dönemi) between the two factions.

const ID: StringName = &"assassinate_envoy"

var instigator_faction_id: int = 0
var target_faction_id: int = 0
var envoy_id: StringName = &""

var kut_gained: float = 0.0
var resulting_kut: float = 0.0
var new_stance: GameEnums.DiplomaticStance = GameEnums.DiplomaticStance.TRUCE
var total_war_triggered: bool = false


func _init(p_instigator_faction_id: int, p_target_faction_id: int, p_envoy_id: StringName) -> void:
	instigator_faction_id = p_instigator_faction_id
	target_faction_id = p_target_faction_id
	envoy_id = p_envoy_id


func get_command_id() -> StringName:
	return ID
