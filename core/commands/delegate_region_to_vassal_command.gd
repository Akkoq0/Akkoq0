class_name DelegateRegionToVassalCommand
extends GameCommand
## Request command (rank 2). Delegates direct administrative oversight of an
## owned macro region to a Vassal Bey (`Tâbi Bey`) to relieve Direct Governance Cap strain.

const ID: StringName = &"delegate_region_to_vassal"

var player_id: int = 0
var coord: Vector2i = Vector2i.ZERO
var bey_id: StringName = &""
var personality_trait: GameEnums.VassalPersonalityTrait = GameEnums.VassalPersonalityTrait.LOYAL

# Written by GovernanceManager
var delegated: bool = false
var direct_regions_after: int = 0


func _init(
		p_player_id: int,
		p_coord: Vector2i,
		p_bey_id: StringName,
		p_trait: GameEnums.VassalPersonalityTrait = GameEnums.VassalPersonalityTrait.LOYAL) -> void:
	player_id = p_player_id
	coord = p_coord
	bey_id = p_bey_id
	personality_trait = p_trait


func get_command_id() -> StringName:
	return ID
