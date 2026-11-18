extends Node
## Autoload `CombatCalculator` (rank 2). Stateless combat math driven by
## `CombatRules` data. Caches the active season from the EventBus so it never
## queries SeasonManager directly.

const COMBAT_RULES_PATH: String = "res://data/combat/combat_rules.tres"

var _rules: CombatRules = null
var _season: SeasonData = null


func _ready() -> void:
	_rules = ResourceLoader.load(COMBAT_RULES_PATH) as CombatRules
	if _rules == null:
		push_error("CombatCalculator: failed to load CombatRules at %s." % COMBAT_RULES_PATH)
		return
	EventBus.season_changed.connect(_on_season_changed)
	CommandBus.register_handler(ResolveCombatCommand.ID, _handle_resolve)


func _exit_tree() -> void:
	CommandBus.unregister_handler(ResolveCombatCommand.ID, _handle_resolve)


## Pure resolution of one exchange. Does not emit events.
func calculate(attacker: CombatantStats, defender: CombatantStats, defender_terrain: TerrainData, season: SeasonData, rng: RandomNumberGenerator) -> CombatResult:
	var result: CombatResult = CombatResult.new()
	result.attacker_id = attacker.entity_id
	result.defender_id = defender.entity_id

	var terrain_defense: float = defender_terrain.defense_multiplier if defender_terrain != null else 1.0
	var season_defense: float = season.defense_multiplier if season != null else 1.0

	var attacker_power: float = _effective_attack(attacker)
	var defender_armor: float = defender.defense * (1.0 + defender.totem_defense_bonus) * terrain_defense * season_defense
	result.damage_to_defender = _mitigated_damage(attacker_power, defender_armor, rng)

	var defender_power: float = _effective_attack(defender)
	var attacker_armor: float = attacker.defense * (1.0 + attacker.totem_defense_bonus) * season_defense
	result.damage_to_attacker = _mitigated_damage(defender_power, attacker_armor, rng) * _rules.counter_attack_ratio

	result.defender_remaining_health = maxf(defender.health - result.damage_to_defender, 0.0)
	result.attacker_remaining_health = maxf(attacker.health - result.damage_to_attacker, 0.0)
	return result


func _handle_resolve(command: GameCommand) -> bool:
	var resolve: ResolveCombatCommand = command as ResolveCombatCommand
	if resolve == null:
		return command.reject("Expected ResolveCombatCommand.")
	if resolve.attacker == null or resolve.defender == null:
		return command.reject("Combat requires both attacker and defender stats.")
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = resolve.rng_seed
	resolve.result = calculate(resolve.attacker, resolve.defender, resolve.defender_terrain, _season, rng)
	EventBus.combat_resolved.emit(resolve.result)
	return true


func _effective_attack(stats: CombatantStats) -> float:
	var supply_factor: float = lerpf(_rules.out_of_supply_attack_factor, 1.0, stats.supply_ratio)
	return stats.attack * (1.0 + stats.totem_offense_bonus) * supply_factor


func _mitigated_damage(power: float, armor: float, rng: RandomNumberGenerator) -> float:
	var k: float = _rules.mitigation_constant
	var raw: float = power * _rules.damage_multiplier * k / (k + maxf(armor, 0.0))
	var spread: float = rng.randf_range(1.0 - _rules.random_spread, 1.0 + _rules.random_spread)
	return maxf(_rules.minimum_damage, raw) * spread


func _on_season_changed(season: SeasonData, _cycle_index: int) -> void:
	_season = season
