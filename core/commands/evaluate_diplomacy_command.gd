class_name EvaluateDiplomacyCommand
extends GameCommand
## Core command (rank 2). Re-evaluates all rival dynasties' attitudes against
## the Khaganate's current Kut score, army strength, and raid frequency, and
## checks whether a low-Kut (`< 30`) Coalition War is triggered.

const ID: StringName = &"evaluate_diplomacy"

var player_kut: float = 75.0
var player_army_size: float = 1000.0
var raid_frequency: float = 0.0

var stances: Dictionary[StringName, GameEnums.DynastyAttitude] = {}
var coalition_triggered: bool = false
var coalition_members: PackedStringArray = PackedStringArray()


func _init(p_player_kut: float, p_player_army_size: float, p_raid_frequency: float) -> void:
	player_kut = p_player_kut
	player_army_size = p_player_army_size
	raid_frequency = p_raid_frequency


func get_command_id() -> StringName:
	return ID
