class_name VassalBeyAssignment
extends RefCounted
## Core model (rank 2). Tracks a delegated frontier region governed by a named
## Vassal Bey with an autonomous personality trait and Ülüş share fulfillment.

var bey_id: StringName = &""
var suzerain_id: int = 0
var region_coord: Vector2i = Vector2i.ZERO
var personality_trait: GameEnums.VassalPersonalityTrait = GameEnums.VassalPersonalityTrait.LOYAL
var loyalty: float = 75.0
var promised_ulus_share: float = 0.0
var delivered_ulus_share: float = 0.0
var silent_sabotage_active: bool = false
var reinforcement_delay_hours: float = 0.0
var reinforcement_troop_mult: float = 1.0


func _init(
		p_bey_id: StringName,
		p_suzerain_id: int,
		p_coord: Vector2i,
		p_trait: GameEnums.VassalPersonalityTrait = GameEnums.VassalPersonalityTrait.LOYAL) -> void:
	bey_id = p_bey_id
	suzerain_id = p_suzerain_id
	region_coord = p_coord
	personality_trait = p_trait
