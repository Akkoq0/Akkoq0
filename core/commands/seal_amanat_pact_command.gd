class_name SealAmanatPactCommand
extends GameCommand
## Request command (rank 2). Seals a bilateral Amanat hostage/pledge truce pact
## between two sovereign rulers or clans.

const ID: StringName = &"seal_amanat_pact"

var pact_id: StringName = &""
var party_a: int = 0
var party_b: int = 0
var hostage_type: GameEnums.AmanatHostageType = GameEnums.AmanatHostageType.COMMANDER_HOSTAGE
var duration_seasons: int = 8

# Written by ReputationAndPactSystem
var sealed: bool = false


func _init(
		p_pact_id: StringName,
		p_party_a: int,
		p_party_b: int,
		p_hostage_type: GameEnums.AmanatHostageType = GameEnums.AmanatHostageType.COMMANDER_HOSTAGE,
		p_duration_seasons: int = 8) -> void:
	pact_id = p_pact_id
	party_a = p_party_a
	party_b = p_party_b
	hostage_type = p_hostage_type
	duration_seasons = maxi(p_duration_seasons, 1)


func get_command_id() -> StringName:
	return ID
