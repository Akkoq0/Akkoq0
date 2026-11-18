extends Node
## Autoload `CombatCalculator` (rank 2). Implements the Phase 3 **Triple
## Collapse Model (Physical Casualties + Formation Cohesion + Battle Will/Fear)**,
## vectorial dot-product flanking (`1.0x` Front, `1.45x` Flank, `2.1x` Rear),
## 7-Ore combat integration (Steel armor penetration, Sulfur fire traps,
## Meteoric Iron Divine Dread), Terrain/Totem/Kut synergy, and Rout -> Toy loot capture.

const COMBAT_RULES_PATH: String = "res://data/combat/combat_rules.tres"
const SULFUR_ORE_PATH: String = "res://data/ores/sulfur.tres"

var _rules: CombatRules = null
var _season: SeasonData = null
var _sulfur_ore: OreData = null
var _pending_toy_loot_pool: float = 0.0
var _captured_slave_worker_pool: int = 0


func _ready() -> void:
	_rules = ResourceLoader.load(COMBAT_RULES_PATH) as CombatRules
	if _rules == null:
		push_error("CombatCalculator: failed to load CombatRules at %s." % COMBAT_RULES_PATH)
		return
	_sulfur_ore = ResourceLoader.load(SULFUR_ORE_PATH) as OreData
	EventBus.season_changed.connect(_on_season_changed)
	CommandBus.register_handler(ResolveCombatCommand.ID, _handle_resolve)
	CommandBus.register_handler(SulfurFireTrapCommand.ID, _handle_sulfur_fire_trap)


func _exit_tree() -> void:
	CommandBus.unregister_handler(ResolveCombatCommand.ID, _handle_resolve)
	CommandBus.unregister_handler(SulfurFireTrapCommand.ID, _handle_sulfur_fire_trap)


## Accumulated Toy loot value captured from annihilated or routed enemy armies.
func get_pending_toy_loot_pool() -> float:
	return _pending_toy_loot_pool


## Total enslaved prisoner workers captured from fleeing (`cascade_rout`) armies for the Toy economy.
func get_captured_slave_worker_pool() -> int:
	return _captured_slave_worker_pool


## Pure resolution of one exchange under the Triple Collapse & Phase 4 Psychological Warfare Model.
func calculate(attacker: CombatantStats, defender: CombatantStats, defender_terrain: TerrainData, season: SeasonData, rng: RandomNumberGenerator) -> CombatResult:
	var result: CombatResult = CombatResult.new()
	result.attacker_id = attacker.entity_id
	result.defender_id = defender.entity_id

	# --- Phase 4 Battle Fatigue accumulation & lance momentum decay ----------
	if attacker.combat_duration_sec > 0.0:
		attacker.fatigue = clampf(attacker.fatigue + attacker.combat_duration_sec * _rules.fatigue_accumulation_per_sec, 0.0, 100.0)
	if defender.combat_duration_sec > 0.0:
		defender.fatigue = clampf(defender.fatigue + defender.combat_duration_sec * _rules.fatigue_accumulation_per_sec, 0.0, 100.0)
	var fatigue_momentum_mult: float = _rules.compute_fatigue_momentum_multiplier(attacker.fatigue)
	result.attacker_fatigue_momentum_multiplier = fatigue_momentum_mult

	# --- Phase 4 Elite Vanguard Destruction -> Cascade Rout & 2.1x Rear Strike
	var angle: GameEnums.CombatEngagementAngle = _rules.classify_engagement_angle(
		attacker.attack_vector, defender.facing_vector)
	if defender.elite_vanguard_destroyed or defender.is_fleeing_rout:
		result.cascade_rout_triggered = true
		angle = GameEnums.CombatEngagementAngle.REAR

	var dir_damage_mult: float = _rules.get_directional_damage_multiplier(angle)
	var dir_cohesion_mult: float = _rules.get_directional_cohesion_multiplier(angle)
	result.engagement_angle = angle
	result.directional_damage_multiplier = dir_damage_mult

	var terrain_defense: float = _compute_terrain_defense(defender_terrain)
	var terrain_attack: float = _compute_terrain_attack(attacker, defender_terrain)
	var season_defense: float = season.defense_multiplier if season != null else 1.0

	var armor_collapse_factor: float = clampf(1.0 - defender.armor_collapse_ratio, 0.1, 1.0)
	var steel_pen_factor: float = (1.0 - _rules.steel_armor_penetration_ratio) if attacker.has_steel_weapons else 1.0

	var attacker_power: float = _effective_attack(attacker) * fatigue_momentum_mult * terrain_attack * dir_damage_mult
	var defender_armor: float = defender.defense * (1.0 + defender.totem_defense_bonus) \
		* terrain_defense * season_defense * armor_collapse_factor * steel_pen_factor
	result.damage_to_defender = _mitigated_damage(attacker_power, defender_armor, rng)

	var defender_power: float = _effective_attack(defender) * _rules.compute_fatigue_momentum_multiplier(defender.fatigue)
	var attacker_armor: float = attacker.defense * (1.0 + attacker.totem_defense_bonus) * season_defense
	var counter_mult: float = 0.0 if result.cascade_rout_triggered else _rules.counter_attack_ratio
	result.damage_to_attacker = _mitigated_damage(defender_power, attacker_armor, rng) * counter_mult

	result.defender_remaining_health = maxf(defender.health - result.damage_to_defender, 0.0)
	result.attacker_remaining_health = maxf(attacker.health - result.damage_to_attacker, 0.0)

	# --- Formation Cohesion & Battle Will / Fear collapse -------------------
	var steel_break_mult: float = _rules.steel_shield_break_multiplier if attacker.has_steel_weapons else 1.0
	var cohesion_loss: float = result.damage_to_defender * _rules.base_cohesion_damage_ratio * dir_cohesion_mult * steel_break_mult
	var morale_loss: float = result.damage_to_defender * _rules.base_morale_damage_ratio
	if angle == GameEnums.CombatEngagementAngle.REAR:
		morale_loss += _rules.rear_panic_morale_drop
	if attacker.has_meteoric_iron_weapon:
		morale_loss += _rules.meteoric_iron_dread_morale_drop
	if result.cascade_rout_triggered:
		cohesion_loss += _rules.elite_vanguard_loss_cohesion_shock
		morale_loss += _rules.elite_vanguard_loss_morale_shock * clampf(defender.rookie_troop_ratio, 0.2, 1.5)

	result.cohesion_damage_to_defender = cohesion_loss
	result.morale_damage_to_defender = morale_loss
	result.defender_remaining_cohesion = clampf(defender.cohesion - cohesion_loss, 0.0, 100.0)
	result.defender_remaining_morale = clampf(defender.morale - morale_loss, 0.0, 100.0)

	defender.health = result.defender_remaining_health
	defender.cohesion = result.defender_remaining_cohesion
	defender.morale = result.defender_remaining_morale
	attacker.health = result.attacker_remaining_health

	if result.cascade_rout_triggered \
			or result.defender_remaining_cohesion < _rules.rout_cohesion_threshold \
			or result.defender_remaining_morale < _rules.rout_morale_threshold:
		result.defender_routed = true
		var total_targeted_health: float = result.damage_to_defender + result.defender_remaining_health
		result.captured_slave_workers = maxi(int(roundf(total_targeted_health * _rules.slave_capture_per_routed_health)), 1)
		var slave_toy_value: float = float(result.captured_slave_workers) * _rules.slave_worker_toy_value
		result.captured_toy_loot_value += slave_toy_value
		if defender.is_escape_vector_sealed or result.cascade_rout_triggered:
			result.defender_annihilated_in_crescent = defender.is_escape_vector_sealed
			result.captured_toy_loot_value += total_targeted_health * _rules.annihilation_loot_per_health
			result.defender_remaining_health = 0.0
			defender.health = 0.0
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
	if resolve.result.cascade_rout_triggered:
		EventBus.cascade_rout_triggered.emit(
			resolve.result.defender_id,
			resolve.defender.elite_vanguard_id,
			resolve.result.defender_remaining_morale)
	if resolve.result.defender_routed:
		_pending_toy_loot_pool += resolve.result.captured_toy_loot_value
		if resolve.result.captured_slave_workers > 0:
			_captured_slave_worker_pool += resolve.result.captured_slave_workers
			EventBus.routed_troops_enslaved_to_toy.emit(
				resolve.result.defender_id,
				resolve.result.captured_slave_workers,
				resolve.result.captured_toy_loot_value)
		EventBus.army_routed.emit(
			resolve.result.defender_id,
			resolve.result.defender_annihilated_in_crescent,
			resolve.result.captured_toy_loot_value)
	EventBus.combat_resolved.emit(resolve.result)
	return true


func _handle_sulfur_fire_trap(command: GameCommand) -> bool:
	var trap: SulfurFireTrapCommand = command as SulfurFireTrapCommand
	if trap == null:
		return command.reject("Expected SulfurFireTrapCommand.")
	if _rules == null or trap.target == null:
		return command.reject("SulfurFireTrapCommand requires valid target and rules.")
	if _sulfur_ore != null:
		var cost_entry: ResourceAmount = ResourceAmount.new()
		cost_entry.ore = _sulfur_ore
		cost_entry.amount = _rules.sulfur_ore_cost_per_trap
		var costs: Array[ResourceAmount] = [cost_entry]
		var spend: SpendResourcesCommand = SpendResourcesCommand.new(trap.player_id, costs)
		if not CommandBus.dispatch(spend):
			return command.reject("Insufficient Sulfur for fire trap: %s" % spend.rejection_reason)

	var chokepoint_mult: float = trap.terrain.chokepoint_defense_multiplier if trap.terrain != null else 1.0
	var cavalry_panic: float = _rules.sulfur_cavalry_panic_multiplier if trap.target.is_cavalry else 1.0
	trap.area_damage_dealt = _rules.sulfur_trap_area_damage * chokepoint_mult
	trap.cohesion_drop_dealt = _rules.sulfur_base_cohesion_drop * cavalry_panic
	trap.morale_drop_dealt = _rules.sulfur_base_morale_drop * cavalry_panic

	trap.target.health = maxf(trap.target.health - trap.area_damage_dealt, 0.0)
	trap.target.cohesion = clampf(trap.target.cohesion - trap.cohesion_drop_dealt, 0.0, 100.0)
	trap.target.morale = clampf(trap.target.morale - trap.morale_drop_dealt, 0.0, 100.0)

	EventBus.sulfur_fire_trap_detonated.emit(
		trap.player_id, trap.target.entity_id, trap.area_damage_dealt, trap.cohesion_drop_dealt, trap.morale_drop_dealt)
	return true


## Computes tactical readiness scaling (`0.45..1.0`) from quiver ammunition
## during arrow harassment and Yılkı spare-horse ratio during cavalry phases.
func compute_maneuver_readiness_multiplier(stats: CombatantStats) -> float:
	if stats == null:
		return 1.0
	var ammo_factor: float = 1.0
	if stats.active_tactic_phase == GameEnums.TuranTacticPhase.WHISTLING_ARROW_HARASSMENT:
		ammo_factor = lerpf(0.55, 1.0, clampf(stats.quiver_ammo_ratio, 0.0, 1.0))
	var remount_factor: float = 1.0
	if stats.is_cavalry and stats.remount_horse_ratio < 0.55:
		remount_factor = lerpf(0.60, 1.0, clampf(stats.remount_horse_ratio / 0.55, 0.0, 1.0))
	return clampf(ammo_factor * remount_factor, 0.45, 1.0)


func _effective_attack(stats: CombatantStats) -> float:
	var supply_factor: float = lerpf(_rules.out_of_supply_attack_factor, 1.0, stats.supply_ratio)
	var steel_mult: float = _rules.steel_shield_break_multiplier if stats.has_steel_weapons else 1.0
	var meteoric_mult: float = _rules.meteoric_iron_crit_shock_multiplier if stats.has_meteoric_iron_weapon else 1.0
	var kut_mult: float = maxf(stats.kut_legitimacy_multiplier, 0.1)
	var momentum_mult: float = maxf(stats.charge_mass_momentum, 0.1)
	var readiness_mult: float = compute_maneuver_readiness_multiplier(stats)
	return stats.attack * (1.0 + stats.totem_offense_bonus) * supply_factor * steel_mult * meteoric_mult * kut_mult * momentum_mult * readiness_mult


func _compute_terrain_defense(terrain: TerrainData) -> float:
	if terrain == null:
		return 1.0
	var mult: float = terrain.defense_multiplier
	if terrain.terrain_class == GameEnums.TerrainClass.DAMARLI_YAMAC:
		mult *= terrain.chokepoint_defense_multiplier
	return mult


func _compute_terrain_attack(attacker: CombatantStats, terrain: TerrainData) -> float:
	if terrain == null:
		return 1.0
	if terrain.terrain_class == GameEnums.TerrainClass.BEREKET_HAVZASI and attacker.is_cavalry:
		return terrain.cavalry_momentum_multiplier
	if terrain.terrain_class == GameEnums.TerrainClass.HAKIMIYET_PLATOSU \
			and attacker.active_tactic_phase == GameEnums.TuranTacticPhase.WHISTLING_ARROW_HARASSMENT:
		return terrain.ranged_elevation_bonus_multiplier
	if (terrain.terrain_class == GameEnums.TerrainClass.SIK_ORMAN \
			or terrain.terrain_class == GameEnums.TerrainClass.DAMARLI_YAMAC) \
			and attacker.active_tactic_phase == GameEnums.TuranTacticPhase.CRESCENT_ENCIRCLEMENT_TRAP:
		return 1.0 + terrain.ambush_concealment_bonus
	return 1.0


func _mitigated_damage(power: float, armor: float, rng: RandomNumberGenerator) -> float:
	var k: float = _rules.mitigation_constant
	var raw: float = power * _rules.damage_multiplier * k / (k + maxf(armor, 0.0))
	var spread: float = rng.randf_range(1.0 - _rules.random_spread, 1.0 + _rules.random_spread)
	return maxf(_rules.minimum_damage, raw) * spread


func _on_season_changed(season: SeasonData, _cycle_index: int) -> void:
	_season = season
