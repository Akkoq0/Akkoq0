class_name ResolveCombatCommand
extends GameCommand
## Resolves one combat exchange. The handler writes `result`.

const ID: StringName = &"resolve_combat"

var attacker: CombatantStats = null
var defender: CombatantStats = null
## Terrain the defender stands on (null = neutral).
var defender_terrain: TerrainData = null
## Seed for deterministic, replayable resolution.
var rng_seed: int = 0
## Result: filled by the handler on success.
var result: CombatResult = null


func _init(p_attacker: CombatantStats, p_defender: CombatantStats, p_defender_terrain: TerrainData, p_rng_seed: int) -> void:
	attacker = p_attacker
	defender = p_defender
	defender_terrain = p_defender_terrain
	rng_seed = p_rng_seed


func get_command_id() -> StringName:
	return ID
