class_name SignUlusContractCommand
extends GameCommand
## Request command (rank 2). Settles a promised vs delivered Ülüş share agreement
## with a delegated Vassal Bey. Shortfalls trigger Silent Sabotage (`delay_hours`, `troop_mult`)
## rather than binary instant rebellion.

const ID: StringName = &"sign_ulus_contract"

var bey_id: StringName = &""
var promised_share: float = 0.0
var delivered_share: float = 0.0

# Written by GovernanceManager
var fulfilled: bool = false
var silent_sabotage_triggered: bool = false
var reinforcement_delay_hours: float = 0.0
var reinforcement_troop_mult: float = 1.0
var resulting_loyalty: float = 75.0


func _init(p_bey_id: StringName, p_promised_share: float, p_delivered_share: float) -> void:
	bey_id = p_bey_id
	promised_share = maxf(p_promised_share, 0.0)
	delivered_share = maxf(p_delivered_share, 0.0)


func get_command_id() -> StringName:
	return ID
