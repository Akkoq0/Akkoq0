class_name KinshipLordRecord
extends RefCounted
## Core model (rank 2). Tracks a clan Bey or royal kinsman's blood-tie loyalty,
## ambition, grievance, and active plot stage inside `KinshipIntrigueManager`.

var bey_id: StringName = &""
var kinship_branch: StringName = &"ashina_royal_kin"
var loyalty: float = 70.0
var ambition: float = 55.0
var grievance: float = 10.0
var plot_stage: GameEnums.IntriguePlotStage = GameEnums.IntriguePlotStage.LOYAL_CALM
var defected_troops: int = 0
var supply_sabotaged: bool = false
