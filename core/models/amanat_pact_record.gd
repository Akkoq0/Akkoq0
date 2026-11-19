class_name AmanatPactRecord
extends RefCounted
## Core model (rank 2). Bilateral Amanat pledge / hostage pact tracked across
## seasons by `ReputationAndPactSystem`.

var pact_id: StringName = &""
var party_a: int = 0
var party_b: int = 0
var hostage_type: GameEnums.AmanatHostageType = GameEnums.AmanatHostageType.COMMANDER_HOSTAGE
var duration_seasons: int = 8
var remaining_seasons: int = 8
var active: bool = true
var broken_by_id: int = 0
var hostage_forfeited: bool = false


func _init(
		p_pact_id: StringName,
		p_party_a: int,
		p_party_b: int,
		p_hostage_type: GameEnums.AmanatHostageType,
		p_duration_seasons: int = 8) -> void:
	pact_id = p_pact_id
	party_a = p_party_a
	party_b = p_party_b
	hostage_type = p_hostage_type
	duration_seasons = maxi(p_duration_seasons, 1)
	remaining_seasons = duration_seasons
