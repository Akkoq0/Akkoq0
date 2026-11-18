class_name ResolveConquestAftermathCommand
extends GameCommand
## Request command (rank 2). Finalizes conquest of a claimed/seized region
## via Talan / Kavruk Bozkır (Scorched Earth), %20 Denetim Garrison Hold,
## or Local Vassal Bey Appointment + Sacred Kurgan Majority Check.

const ID: StringName = &"resolve_conquest_aftermath"

var actor_id: int = 0
var target_coord: Vector2i = Vector2i.ZERO
var choice: GameEnums.ConquestAftermathChoice = GameEnums.ConquestAftermathChoice.HOLD_GARRISON_CONTROL
var vassal_bey_id: StringName = &"appointed_vassal_bey"

# Written by TerritoryManager
var new_owner_id: int = 0
var resulting_control_percent: float = 0.0
var scorched_seasons: int = 0
var bullion_gained: int = 0
var captives_gained: int = 0
var became_khagan_candidate: bool = false
var coalition_triggered: bool = false


func _init(
		p_actor_id: int,
		p_target_coord: Vector2i,
		p_choice: GameEnums.ConquestAftermathChoice,
		p_vassal_bey_id: StringName = &"appointed_vassal_bey") -> void:
	actor_id = p_actor_id
	target_coord = p_target_coord
	choice = p_choice
	vassal_bey_id = p_vassal_bey_id


func get_command_id() -> StringName:
	return ID
