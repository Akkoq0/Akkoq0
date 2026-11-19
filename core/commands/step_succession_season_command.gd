class_name StepSuccessionSeasonCommand
extends GameCommand
## Advances seasonal age across rulers and commanders (`seasons_to_advance`),
## optionally resolving a ruler's death (`force_ruler_death`) and triggering either
## smooth succession, Ak Sakallılar Regency, or a Kurultay Succession Crisis.

const ID: StringName = &"step_succession_season"

var player_id: int = 1
var seasons_to_advance: int = 1
var force_ruler_death: bool = false
var death_cause: StringName = &"natural_aging"

var succession_occurred: bool = false
var crisis_triggered: bool = false
var resulting_regency_status: GameEnums.RegencyStatus = GameEnums.RegencyStatus.STABLE_RULE
var new_ruler_name: StringName = &""
var generation_after: int = 1
var claimant_bey_id: StringName = &""
var contested_coord: Vector2i = Vector2i.ZERO


func _init(
		p_player_id: int = 1,
		p_seasons_to_advance: int = 1,
		p_force_ruler_death: bool = false,
		p_death_cause: StringName = &"natural_aging") -> void:
	player_id = p_player_id
	seasons_to_advance = maxi(p_seasons_to_advance, 1)
	force_ruler_death = p_force_ruler_death
	death_cause = p_death_cause


func get_command_id() -> StringName:
	return ID
