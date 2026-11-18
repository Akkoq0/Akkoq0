class_name ProcessNobleCaptivesCommand
extends GameCommand
## Core command (rank 2). Processes captured enemy nobles and Beys under Töre
## law: either converts them into `silver_gold` treasury bullion via ransom
## (`&"ransom"`) or uses them for diplomatic envoy exchange (`&"envoy_exchange"`).

const ID: StringName = &"process_noble_captives"
const MODE_RANSOM: StringName = &"ransom"
const MODE_ENVOY_EXCHANGE: StringName = &"envoy_exchange"

var player_id: int = 1
var noble_count: int = 1
var mode: StringName = MODE_RANSOM

var bullion_gained: int = 0
var diplomatic_trust_gained: float = 0.0


func _init(p_player_id: int, p_noble_count: int, p_mode: StringName = MODE_RANSOM) -> void:
	player_id = p_player_id
	noble_count = p_noble_count
	mode = p_mode


func get_command_id() -> StringName:
	return ID
