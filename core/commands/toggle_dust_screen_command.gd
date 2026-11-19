class_name ToggleDustScreenCommand
extends GameCommand
## Request command (rank 2). Activates or clears Yılkı Dust Screen Deception
## (`Toz Perdesi`) for an army strictly via `CommandBus`.

const ID: StringName = &"toggle_dust_screen"

var army_id: int = 1
var player_id: int = 1
var enable: bool = true
var remount_horse_ratio: float = 1.0

# Written by CourierDispatchSystem
var active_after: bool = false


func _init(
		p_army_id: int = 1,
		p_player_id: int = 1,
		p_enable: bool = true,
		p_remount_ratio: float = 1.0) -> void:
	army_id = p_army_id
	player_id = p_player_id
	enable = p_enable
	remount_horse_ratio = p_remount_ratio


func get_command_id() -> StringName:
	return ID
