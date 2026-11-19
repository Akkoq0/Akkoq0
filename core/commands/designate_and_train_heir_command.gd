class_name DesignateAndTrainHeirCommand
extends GameCommand
## Designates a dynasty heir (or trains the active designated heir using
## bullion) to raise competence and prevent an unprepared Kurultay succession crisis.

const ID: StringName = &"designate_and_train_heir"

var player_id: int = 1
var heir_name: StringName = &""
var heir_age_seasons: int = -1
var invest_training: bool = false

var updated: bool = false
var resulting_competence: float = 0.0
var bullion_spent: int = 0


func _init(
		p_player_id: int = 1,
		p_heir_name: StringName = &"",
		p_heir_age_seasons: int = -1,
		p_invest_training: bool = false) -> void:
	player_id = p_player_id
	heir_name = p_heir_name
	heir_age_seasons = p_heir_age_seasons
	invest_training = p_invest_training


func get_command_id() -> StringName:
	return ID
