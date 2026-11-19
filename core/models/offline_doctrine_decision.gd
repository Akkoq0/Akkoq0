class_name OfflineDoctrineDecision
extends RefCounted
## Core model (rank 2). Result of evaluating `OfflineDoctrineComponent` rules
## for an offline or standby army awaiting orders.

var army_id: int = 0
var triggered: bool = false
var trigger_reason: GameEnums.OfflineDoctrineTrigger = GameEnums.OfflineDoctrineTrigger.NONE
var power_ratio: float = 1.0
var evade_combat: bool = false
var packed_sefer_arabasi: bool = false
var activated_feigned_retreat: bool = false
var retreat_target_terrain_class: GameEnums.TerrainClass = GameEnums.TerrainClass.SIK_ORMAN
var target_terrain: TerrainData = null
var sheltered_in_kislak: bool = false
