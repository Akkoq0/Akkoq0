class_name EvaluateDoctrineMatchupCommand
extends GameCommand
## Request command (rank 2). Evaluates a Faz 27B realistic doctrine matchup via
## `CommandBus` (`CombatCalculator` handler -> `DoctrineMatchupResolver`) and
## writes the typed `DoctrineMatchupResult`.

const ID: StringName = &"evaluate_doctrine_matchup"

var attacker: CombatantStats = null
var defender: CombatantStats = null
var attacker_doctrine: BattleDoctrineResource = null
var defender_doctrine: BattleDoctrineResource = null
var terrain: TerrainData = null
var season: SeasonData = null
var engagement_angle: GameEnums.CombatEngagementAngle = GameEnums.CombatEngagementAngle.FRONT
var is_mud: bool = false
var is_steep_slope: bool = false
var is_storm: bool = false
var region_coord: Vector2i = Vector2i.ZERO

# Written by CombatCalculator handler
var result: DoctrineMatchupResult = null


func _init(
		p_attacker: CombatantStats = null,
		p_defender: CombatantStats = null,
		p_attacker_doctrine: BattleDoctrineResource = null,
		p_defender_doctrine: BattleDoctrineResource = null,
		p_terrain: TerrainData = null,
		p_season: SeasonData = null,
		p_engagement_angle: GameEnums.CombatEngagementAngle = GameEnums.CombatEngagementAngle.FRONT,
		p_is_mud: bool = false,
		p_is_steep_slope: bool = false,
		p_is_storm: bool = false,
		p_region_coord: Vector2i = Vector2i.ZERO) -> void:
	attacker = p_attacker
	defender = p_defender
	attacker_doctrine = p_attacker_doctrine
	defender_doctrine = p_defender_doctrine
	terrain = p_terrain
	season = p_season
	engagement_angle = p_engagement_angle
	is_mud = p_is_mud
	is_steep_slope = p_is_steep_slope
	is_storm = p_is_storm
	region_coord = p_region_coord


func get_command_id() -> StringName:
	return ID
