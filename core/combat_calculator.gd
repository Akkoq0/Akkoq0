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
var _assigned_doctrines: Dictionary[int, BattleDoctrineResource] = {}
var _last_matchup_result: DoctrineMatchupResult = null


func _ready() -> void:
	_rules = ResourceLoader.load(COMBAT_RULES_PATH) as CombatRules
	if _rules == null:
		push_error("CombatCalculator: failed to load CombatRules at %s." % COMBAT_RULES_PATH)
		return
	_sulfur_ore = ResourceLoader.load(SULFUR_ORE_PATH) as OreData
	EventBus.season_changed.connect(_on_season_changed)
	CommandBus.register_handler(ResolveCombatCommand.ID, _handle_resolve)
	CommandBus.register_handler(SulfurFireTrapCommand.ID, _handle_sulfur_fire_trap)
	CommandBus.register_handler(AssignBattleDoctrineCommand.ID, _handle_assign_battle_doctrine)
	CommandBus.register_handler(EvaluateDoctrineMatchupCommand.ID, _handle_evaluate_doctrine_matchup)


func _exit_tree() -> void:
	CommandBus.unregister_handler(ResolveCombatCommand.ID, _handle_resolve)
	CommandBus.unregister_handler(SulfurFireTrapCommand.ID, _handle_sulfur_fire_trap)
	CommandBus.unregister_handler(AssignBattleDoctrineCommand.ID, _handle_assign_battle_doctrine)
	CommandBus.unregister_handler(EvaluateDoctrineMatchupCommand.ID, _handle_evaluate_doctrine_matchup)


## Clears stored Phase 27B modular battle doctrines and cached matchup outcome.
func reset_doctrine_state() -> void:
	_assigned_doctrines.clear()
	_last_matchup_result = null


## Read-only accessor returning the modular BattleDoctrineResource assigned to `army_id`, or null.
func get_assigned_doctrine(army_id: int) -> BattleDoctrineResource:
	if _assigned_doctrines.has(army_id):
		return _assigned_doctrines[army_id]
	return null


## Read-only accessor returning the latest Phase 27B DoctrineMatchupResult.
func get_last_matchup_result() -> DoctrineMatchupResult:
	return _last_matchup_result


## Accumulated Toy loot value captured from annihilated or routed enemy armies.
func get_pending_toy_loot_pool() -> float:
	return _pending_toy_loot_pool


## Claims and drains the accumulated pending Toy loot pool back to 0.0.
func claim_pending_toy_loot_pool() -> float:
	var claimed: float = _pending_toy_loot_pool
	_pending_toy_loot_pool = 0.0
	return claimed


## Total enslaved prisoner workers captured from fleeing (`cascade_rout`) armies for the Toy economy.
func get_captured_slave_worker_pool() -> int:
	return _captured_slave_worker_pool


func _ensure_rules_loaded() -> bool:
	if _rules == null:
		_rules = ResourceLoader.load(COMBAT_RULES_PATH) as CombatRules
		if _rules == null:
			_rules = CombatRules.new()
	return _rules != null


static func _safe_float(value: float, fallback: float, min_val: float = -INF, max_val: float = INF) -> float:
	if is_nan(value) or is_inf(value):
		return fallback
	return clampf(value, min_val, max_val)


func _resolve_combatant_doctrine(stats: CombatantStats) -> BattleDoctrineResource:
	if stats == null:
		return null
	if stats.battle_doctrine != null:
		return stats.battle_doctrine
	var lookup_id: int = stats.army_id if stats.army_id > 0 else stats.entity_id
	if lookup_id > 0:
		return get_assigned_doctrine(lookup_id)
	return null


## Pure resolution of one exchange under the Triple Collapse & Phase 4 Psychological Warfare Model.
func calculate(attacker: CombatantStats, defender: CombatantStats, defender_terrain: TerrainData, season: SeasonData, rng: RandomNumberGenerator) -> CombatResult:
	var result: CombatResult = CombatResult.new()
	if attacker == null or defender == null or not _ensure_rules_loaded():
		return result
	var safe_rng: RandomNumberGenerator = rng if rng != null else RandomNumberGenerator.new()

	result.attacker_id = attacker.entity_id
	result.defender_id = defender.entity_id

	attacker.health = _safe_float(attacker.health, 0.0, 0.0, 10000000.0)
	defender.health = _safe_float(defender.health, 0.0, 0.0, 10000000.0)
	attacker.cohesion = _safe_float(attacker.cohesion, 100.0, 0.0, 100.0)
	attacker.morale = _safe_float(attacker.morale, 100.0, 0.0, 100.0)
	defender.cohesion = _safe_float(defender.cohesion, 100.0, 0.0, 100.0)
	defender.morale = _safe_float(defender.morale, 100.0, 0.0, 100.0)

	if attacker.health <= 0.0 or defender.health <= 0.0:
		result.attacker_remaining_health = maxf(attacker.health, 0.0)
		result.defender_remaining_health = maxf(defender.health, 0.0)
		result.defender_remaining_cohesion = clampf(defender.cohesion, 0.0, 100.0)
		result.defender_remaining_morale = clampf(defender.morale, 0.0, 100.0)
		return result

	attacker.fatigue = _safe_float(attacker.fatigue, 0.0, 0.0, 100.0)
	defender.fatigue = _safe_float(defender.fatigue, 0.0, 0.0, 100.0)
	attacker.supply_ratio = _safe_float(attacker.supply_ratio, 1.0, 0.0, 1.0)
	defender.supply_ratio = _safe_float(defender.supply_ratio, 1.0, 0.0, 1.0)
	defender.armor_collapse_ratio = _safe_float(defender.armor_collapse_ratio, 0.0, 0.0, 0.9)
	defender.rookie_troop_ratio = _safe_float(defender.rookie_troop_ratio, 0.65, 0.05, 1.5)
	attacker.quiver_ammo_ratio = _safe_float(attacker.quiver_ammo_ratio, 1.0, 0.0, 1.0)
	attacker.remount_horse_ratio = _safe_float(attacker.remount_horse_ratio, 1.0, 0.0, 1.0)
	attacker.combat_duration_sec = _safe_float(attacker.combat_duration_sec, 0.0, 0.0, 36000.0)
	defender.combat_duration_sec = _safe_float(defender.combat_duration_sec, 0.0, 0.0, 36000.0)

	var pre_defender_health: float = defender.health

	# --- Phase 4 & Phase 27B Angle Classification & Modular Doctrine Matchup --
	var angle: GameEnums.CombatEngagementAngle = _rules.classify_engagement_angle(
		attacker.attack_vector, defender.facing_vector)
	if defender.elite_vanguard_destroyed or defender.is_fleeing_rout:
		result.cascade_rout_triggered = true
		angle = GameEnums.CombatEngagementAngle.REAR

	var atk_doc: BattleDoctrineResource = _resolve_combatant_doctrine(attacker)
	var def_doc: BattleDoctrineResource = _resolve_combatant_doctrine(defender)
	var matchup: DoctrineMatchupResult = null
	if atk_doc != null or def_doc != null:
		matchup = DoctrineMatchupResolver.evaluate(
			attacker, defender, atk_doc, def_doc, defender_terrain, season, angle)
		result.doctrine_matchup = matchup
		_last_matchup_result = matchup

	# --- Phase 4 Battle Fatigue accumulation & lance momentum decay ----------
	var atk_fatigue_mult: float = matchup.attacker_fatigue_multiplier if matchup != null else 1.0
	if attacker.combat_duration_sec > 0.0:
		attacker.fatigue = clampf(attacker.fatigue + attacker.combat_duration_sec * _rules.fatigue_accumulation_per_sec * atk_fatigue_mult, 0.0, 100.0)
	if defender.combat_duration_sec > 0.0:
		defender.fatigue = clampf(defender.fatigue + defender.combat_duration_sec * _rules.fatigue_accumulation_per_sec, 0.0, 100.0)
	var fatigue_momentum_mult: float = _rules.compute_fatigue_momentum_multiplier(attacker.fatigue)
	result.attacker_fatigue_momentum_multiplier = fatigue_momentum_mult

	# --- Phase 4 Elite Vanguard Destruction -> Cascade Rout & 2.1x Rear Strike
	if matchup != null and matchup.force_rear_exposure and not result.cascade_rout_triggered and not matchup.laager_encirclement_damped:
		angle = GameEnums.CombatEngagementAngle.REAR

	var dir_damage_mult: float = _rules.get_directional_damage_multiplier(angle)
	var dir_cohesion_mult: float = _rules.get_directional_cohesion_multiplier(angle)
	if matchup != null and matchup.laager_encirclement_damped and (angle == GameEnums.CombatEngagementAngle.FLANK or angle == GameEnums.CombatEngagementAngle.REAR):
		var damping: float = clampf(matchup.flank_rear_damping_ratio, 0.0, 0.95)
		dir_damage_mult = lerpf(1.0, dir_damage_mult, 1.0 - damping)
		dir_cohesion_mult = lerpf(1.0, dir_cohesion_mult, 1.0 - damping)
	result.engagement_angle = angle
	result.directional_damage_multiplier = dir_damage_mult

	var terrain_defense: float = _compute_terrain_defense(defender_terrain)
	var terrain_attack: float = _compute_terrain_attack(attacker, defender_terrain)
	var season_defense: float = maxf(season.defense_multiplier, 0.1) if season != null else 1.0

	var effective_collapse: float = defender.armor_collapse_ratio
	if matchup != null and matchup.bonus_defender_armor_collapse_ratio > 0.0:
		effective_collapse = clampf(effective_collapse + matchup.bonus_defender_armor_collapse_ratio, 0.0, 0.9)
	var armor_collapse_factor: float = clampf(1.0 - effective_collapse, 0.1, 1.0)
	var steel_pen_factor: float = (1.0 - _rules.steel_armor_penetration_ratio) if attacker.has_steel_weapons else 1.0

	var doc_atk_mult: float = matchup.attacker_attack_multiplier if matchup != null else 1.0
	var doc_def_mult: float = matchup.defender_defense_multiplier if matchup != null else 1.0
	var attacker_power: float = _effective_attack(attacker) * fatigue_momentum_mult * terrain_attack * dir_damage_mult * doc_atk_mult
	var defender_def_base: float = _safe_float(defender.defense, 0.0, 0.0, 1000000.0)
	var defender_totem_def: float = maxf(1.0 + _safe_float(defender.totem_defense_bonus, 0.0, -0.95, 10.0), 0.05)
	var defender_armor: float = defender_def_base * defender_totem_def \
		* terrain_defense * season_defense * armor_collapse_factor * steel_pen_factor * doc_def_mult
	result.damage_to_defender = _mitigated_damage(attacker_power, defender_armor, safe_rng)

	var defender_power: float = _effective_attack(defender) * _rules.compute_fatigue_momentum_multiplier(defender.fatigue)
	var attacker_def_base: float = _safe_float(attacker.defense, 0.0, 0.0, 1000000.0)
	var attacker_totem_def: float = maxf(1.0 + _safe_float(attacker.totem_defense_bonus, 0.0, -0.95, 10.0), 0.05)
	var attacker_armor: float = attacker_def_base * attacker_totem_def * season_defense
	var counter_mult: float = 0.0 if result.cascade_rout_triggered else _rules.counter_attack_ratio
	result.damage_to_attacker = _mitigated_damage(defender_power, attacker_armor, safe_rng) * counter_mult

	result.defender_remaining_health = maxf(defender.health - result.damage_to_defender, 0.0)
	result.attacker_remaining_health = maxf(attacker.health - result.damage_to_attacker, 0.0)

	# --- Formation Cohesion & Battle Will / Fear collapse -------------------
	var steel_break_mult: float = _rules.steel_shield_break_multiplier if attacker.has_steel_weapons else 1.0
	var doc_coh_mult: float = matchup.defender_cohesion_damage_multiplier if matchup != null else 1.0
	var doc_mor_mult: float = matchup.defender_morale_damage_multiplier if matchup != null else 1.0
	var cohesion_loss: float = result.damage_to_defender * _rules.base_cohesion_damage_ratio * dir_cohesion_mult * steel_break_mult * doc_coh_mult
	var morale_loss: float = result.damage_to_defender * _rules.base_morale_damage_ratio
	if angle == GameEnums.CombatEngagementAngle.REAR:
		var rear_panic: float = _rules.rear_panic_morale_drop
		if matchup != null and matchup.laager_encirclement_damped:
			rear_panic *= clampf(1.0 - matchup.flank_rear_damping_ratio, 0.05, 1.0)
		morale_loss += rear_panic
	if attacker.has_meteoric_iron_weapon:
		morale_loss += _rules.meteoric_iron_dread_morale_drop
	if result.cascade_rout_triggered:
		cohesion_loss += _rules.elite_vanguard_loss_cohesion_shock
		morale_loss += _rules.elite_vanguard_loss_morale_shock * clampf(defender.rookie_troop_ratio, 0.2, 1.5)

	var dread_shock_mult: float = 1.0 + _safe_float(attacker.attacker_dread_morale_shock_ratio, 0.0, 0.0, 0.25)
	morale_loss *= dread_shock_mult * doc_mor_mult

	result.cohesion_damage_to_defender = maxf(cohesion_loss, 0.0)
	result.morale_damage_to_defender = maxf(morale_loss, 0.0)
	result.defender_remaining_cohesion = clampf(defender.cohesion - result.cohesion_damage_to_defender, 0.0, 100.0)
	result.defender_remaining_morale = clampf(defender.morale - result.morale_damage_to_defender, 0.0, 100.0)

	defender.health = result.defender_remaining_health
	defender.cohesion = result.defender_remaining_cohesion
	defender.morale = result.defender_remaining_morale
	attacker.health = result.attacker_remaining_health

	if result.cascade_rout_triggered \
			or result.defender_remaining_cohesion < _rules.rout_cohesion_threshold \
			or result.defender_remaining_morale < _rules.rout_morale_threshold:
		result.defender_routed = true
		var targeted_health: float = minf(pre_defender_health, result.damage_to_defender + result.defender_remaining_health)
		targeted_health = maxf(targeted_health, 0.0)
		result.captured_slave_workers = maxi(int(roundf(targeted_health * _rules.slave_capture_per_routed_health)), 1) if targeted_health > 0.0 else 0
		var slave_toy_value: float = float(result.captured_slave_workers) * _rules.slave_worker_toy_value
		result.captured_toy_loot_value += slave_toy_value
		if defender.is_escape_vector_sealed or result.cascade_rout_triggered:
			result.defender_annihilated_in_crescent = defender.is_escape_vector_sealed
			result.captured_toy_loot_value += targeted_health * _rules.annihilation_loot_per_health
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
	if resolve.result.doctrine_matchup != null:
		EventBus.doctrine_matchup_evaluated.emit(
			resolve.result.attacker_id,
			resolve.result.defender_id,
			resolve.result.doctrine_matchup)
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


func _handle_assign_battle_doctrine(command: GameCommand) -> bool:
	var cmd: AssignBattleDoctrineCommand = command as AssignBattleDoctrineCommand
	if cmd == null:
		return command.reject("Expected AssignBattleDoctrineCommand.")
	if cmd.army_id <= 0 or cmd.player_id <= 0:
		return command.reject("AssignBattleDoctrineCommand requires positive army_id and player_id.")

	var chosen_doc: BattleDoctrineResource = null
	if cmd.doctrine != null:
		var errs: PackedStringArray = cmd.doctrine.get_validation_errors()
		if not errs.is_empty():
			return command.reject("Invalid BattleDoctrineResource: %s" % "; ".join(errs))
		chosen_doc = cmd.doctrine.duplicate_clean()
	else:
		chosen_doc = DoctrinePresetCatalog.create_preset(cmd.preset_id)

	if chosen_doc == null or not chosen_doc.is_valid():
		return command.reject("Failed to resolve valid BattleDoctrineResource.")

	_assigned_doctrines[cmd.army_id] = chosen_doc
	cmd.applied = true
	cmd.applied_doctrine = chosen_doc
	cmd.applied_summary = chosen_doc.format_summary()

	if cmd.sync_offline_contingency:
		var offline_cfg: OfflineDoctrineConfig = OfflineDoctrineConfig.from_battle_doctrine(chosen_doc, cmd.army_id, cmd.player_id)
		var cfg_cmd: ConfigureOfflineDoctrineCommand = ConfigureOfflineDoctrineCommand.new(
			offline_cfg.army_id,
			offline_cfg.player_id,
			offline_cfg.trigger_condition,
			offline_cfg.power_ratio_threshold,
			offline_cfg.low_supply_threshold,
			offline_cfg.action_tactic,
			offline_cfg.pack_sefer_arabasi,
			offline_cfg.evade_combat,
			offline_cfg.target_terrain_class,
			offline_cfg.target_geography_class)
		if CommandBus.dispatch(cfg_cmd):
			cmd.synced_offline_config = offline_cfg

	EventBus.battle_doctrine_assigned.emit(cmd.army_id, cmd.player_id, chosen_doc.doctrine_id, chosen_doc.preset_id)
	return true


func _handle_evaluate_doctrine_matchup(command: GameCommand) -> bool:
	var cmd: EvaluateDoctrineMatchupCommand = command as EvaluateDoctrineMatchupCommand
	if cmd == null:
		return command.reject("Expected EvaluateDoctrineMatchupCommand.")
	var atk_doc: BattleDoctrineResource = cmd.attacker_doctrine if cmd.attacker_doctrine != null else _resolve_combatant_doctrine(cmd.attacker)
	var def_doc: BattleDoctrineResource = cmd.defender_doctrine if cmd.defender_doctrine != null else _resolve_combatant_doctrine(cmd.defender)
	var eff_season: SeasonData = cmd.season if cmd.season != null else _season

	var res: DoctrineMatchupResult = DoctrineMatchupResolver.evaluate(
		cmd.attacker,
		cmd.defender,
		atk_doc,
		def_doc,
		cmd.terrain,
		eff_season,
		cmd.engagement_angle,
		cmd.is_mud,
		cmd.is_steep_slope,
		cmd.is_storm,
		cmd.region_coord)
	_last_matchup_result = res
	cmd.result = res
	var atk_id: int = cmd.attacker.entity_id if cmd.attacker != null else 0
	var def_id: int = cmd.defender.entity_id if cmd.defender != null else 0
	EventBus.doctrine_matchup_evaluated.emit(atk_id, def_id, res)
	return true


func _handle_sulfur_fire_trap(command: GameCommand) -> bool:
	var trap: SulfurFireTrapCommand = command as SulfurFireTrapCommand
	if trap == null:
		return command.reject("Expected SulfurFireTrapCommand.")
	if not _ensure_rules_loaded() or trap.target == null:
		return command.reject("SulfurFireTrapCommand requires valid target and rules.")
	trap.target.health = _safe_float(trap.target.health, 0.0, 0.0, 10000000.0)
	if trap.target.health <= 0.0:
		return command.reject("Target army is already destroyed.")
	if _sulfur_ore != null:
		var cost_entry: ResourceAmount = ResourceAmount.new()
		cost_entry.ore = _sulfur_ore
		cost_entry.amount = _rules.sulfur_ore_cost_per_trap
		var costs: Array[ResourceAmount] = [cost_entry]
		var spend: SpendResourcesCommand = SpendResourcesCommand.new(trap.player_id, costs)
		if not CommandBus.dispatch(spend):
			return command.reject("Insufficient Sulfur for fire trap: %s" % spend.rejection_reason)

	var chokepoint_mult: float = maxf(trap.terrain.chokepoint_defense_multiplier, 0.1) if trap.terrain != null else 1.0
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
	var ammo_ratio: float = _safe_float(stats.quiver_ammo_ratio, 1.0, 0.0, 1.0)
	var remount_ratio: float = _safe_float(stats.remount_horse_ratio, 1.0, 0.0, 1.0)
	var ammo_factor: float = 1.0
	if stats.active_tactic_phase == GameEnums.TuranTacticPhase.WHISTLING_ARROW_HARASSMENT:
		ammo_factor = lerpf(0.55, 1.0, ammo_ratio)
	var remount_factor: float = 1.0
	if stats.is_cavalry and remount_ratio < 0.55:
		remount_factor = lerpf(0.60, 1.0, clampf(remount_ratio / 0.55, 0.0, 1.0))
	return clampf(ammo_factor * remount_factor, 0.45, 1.0)


func _effective_attack(stats: CombatantStats) -> float:
	var base_atk: float = _safe_float(stats.attack, 0.0, 0.0, 1000000.0)
	var supply_val: float = _safe_float(stats.supply_ratio, 1.0, 0.0, 1.0)
	var supply_factor: float = lerpf(_rules.out_of_supply_attack_factor, 1.0, supply_val)
	var totem_off: float = maxf(1.0 + _safe_float(stats.totem_offense_bonus, 0.0, -0.95, 10.0), 0.05)
	var steel_mult: float = _rules.steel_shield_break_multiplier if stats.has_steel_weapons else 1.0
	var meteoric_mult: float = _rules.meteoric_iron_crit_shock_multiplier if stats.has_meteoric_iron_weapon else 1.0
	var kut_mult: float = _safe_float(stats.kut_legitimacy_multiplier, 1.0, 0.1, 10.0)
	var momentum_mult: float = _safe_float(stats.charge_mass_momentum, 1.0, 0.1, 20.0)
	var readiness_mult: float = compute_maneuver_readiness_multiplier(stats)
	return base_atk * totem_off * supply_factor * steel_mult * meteoric_mult * kut_mult * momentum_mult * readiness_mult


func _compute_terrain_defense(terrain: TerrainData) -> float:
	if terrain == null:
		return 1.0
	var mult: float = maxf(terrain.defense_multiplier, 0.1)
	if terrain.terrain_class == GameEnums.TerrainClass.DAMARLI_YAMAC:
		mult *= maxf(terrain.chokepoint_defense_multiplier, 0.1)
	return mult


func _compute_terrain_attack(attacker: CombatantStats, terrain: TerrainData) -> float:
	if terrain == null:
		return 1.0
	if terrain.terrain_class == GameEnums.TerrainClass.BEREKET_HAVZASI and attacker.is_cavalry:
		return maxf(terrain.cavalry_momentum_multiplier, 0.1)
	if terrain.terrain_class == GameEnums.TerrainClass.HAKIMIYET_PLATOSU \
			and attacker.active_tactic_phase == GameEnums.TuranTacticPhase.WHISTLING_ARROW_HARASSMENT:
		return maxf(terrain.ranged_elevation_bonus_multiplier, 0.1)
	if (terrain.terrain_class == GameEnums.TerrainClass.SIK_ORMAN \
			or terrain.terrain_class == GameEnums.TerrainClass.DAMARLI_YAMAC) \
			and attacker.active_tactic_phase == GameEnums.TuranTacticPhase.CRESCENT_ENCIRCLEMENT_TRAP:
		return maxf(1.0 + terrain.ambush_concealment_bonus, 0.1)
	return 1.0


func _mitigated_damage(power: float, armor: float, rng: RandomNumberGenerator) -> float:
	var k: float = maxf(_rules.mitigation_constant, 1.0)
	var safe_power: float = _safe_float(power, 0.0, 0.0, 10000000.0)
	var safe_armor: float = _safe_float(armor, 0.0, 0.0, 10000000.0)
	var raw: float = safe_power * _rules.damage_multiplier * k / (k + safe_armor)
	var spread: float = rng.randf_range(1.0 - _rules.random_spread, 1.0 + _rules.random_spread)
	return maxf(_rules.minimum_damage, raw) * spread


func _on_season_changed(season: SeasonData, _cycle_index: int) -> void:
	_season = season


func export_state_dict() -> Dictionary:
	var docs: Dictionary = {}
	for aid: int in _assigned_doctrines:
		var d: BattleDoctrineResource = _assigned_doctrines[aid]
		if d == null:
			continue
		docs[str(aid)] = {
			"center_ratio": d.center_ratio,
			"contingency_action_tactic": int(d.contingency_action_tactic),
			"contingency_evade_combat": d.contingency_evade_combat,
			"contingency_low_supply_threshold": d.contingency_low_supply_threshold,
			"contingency_pack_sefer_arabasi": d.contingency_pack_sefer_arabasi,
			"contingency_power_ratio_threshold": d.contingency_power_ratio_threshold,
			"contingency_target_geography_class": int(d.contingency_target_geography_class),
			"contingency_target_terrain_class": int(d.contingency_target_terrain_class),
			"contingency_trigger": int(d.contingency_trigger),
			"decisive_maneuver": int(d.decisive_maneuver),
			"display_name": d.display_name,
			"doctrine_id": String(d.doctrine_id),
			"flank_ratio": d.flank_ratio,
			"is_heavy_armor_doctrine": d.is_heavy_armor_doctrine,
			"laager_flank_damping": d.laager_flank_damping,
			"laager_mobility_multiplier": d.laager_mobility_multiplier,
			"laager_rear_damping": d.laager_rear_damping,
			"opening_tactic": int(d.opening_tactic),
			"preset_id": int(d.preset_id),
			"reserve_ratio": d.reserve_ratio,
		}
	return {
		"assigned_doctrines": docs,
		"captured_slave_worker_pool": _captured_slave_worker_pool,
		"pending_toy_loot_pool": _pending_toy_loot_pool,
	}


func import_state_dict(data: Dictionary) -> bool:
	if not (data.get("assigned_doctrines") is Dictionary):
		return false
	reset_doctrine_state()
	_pending_toy_loot_pool = maxf(DeterministicStateHasher.v_float(data.get("pending_toy_loot_pool", 0.0)), 0.0)
	_captured_slave_worker_pool = maxi(DeterministicStateHasher.v_int(data.get("captured_slave_worker_pool", 0)), 0)
	var docs: Dictionary = DeterministicStateHasher.v_dict(data.get("assigned_doctrines"))
	for aid_key: Variant in docs:
		var aid: int = DeterministicStateHasher.v_str(aid_key).to_int()
		var dd: Dictionary = DeterministicStateHasher.v_dict(docs[aid_key])
		var doc: BattleDoctrineResource = DoctrinePresetCatalog.create_preset(
			DeterministicStateHasher.v_int(dd.get("preset_id", int(GameEnums.BattleDoctrinePresetId.KURT_KAPANI)), int(GameEnums.BattleDoctrinePresetId.KURT_KAPANI)) as GameEnums.BattleDoctrinePresetId)
		doc.doctrine_id = StringName(DeterministicStateHasher.v_str(dd.get("doctrine_id", "kurt_kapani"), "kurt_kapani"))
		doc.display_name = DeterministicStateHasher.v_str(dd.get("display_name", doc.display_name), doc.display_name)
		doc.is_heavy_armor_doctrine = DeterministicStateHasher.v_bool(dd.get("is_heavy_armor_doctrine", doc.is_heavy_armor_doctrine), doc.is_heavy_armor_doctrine)
		doc.center_ratio = DeterministicStateHasher.v_float(dd.get("center_ratio", doc.center_ratio), doc.center_ratio)
		doc.flank_ratio = DeterministicStateHasher.v_float(dd.get("flank_ratio", doc.flank_ratio), doc.flank_ratio)
		doc.reserve_ratio = DeterministicStateHasher.v_float(dd.get("reserve_ratio", doc.reserve_ratio), doc.reserve_ratio)
		doc.opening_tactic = DeterministicStateHasher.v_int(dd.get("opening_tactic", int(doc.opening_tactic)), int(doc.opening_tactic)) as GameEnums.OpeningTactic
		doc.decisive_maneuver = DeterministicStateHasher.v_int(dd.get("decisive_maneuver", int(doc.decisive_maneuver)), int(doc.decisive_maneuver)) as GameEnums.DecisiveManeuver
		doc.laager_mobility_multiplier = DeterministicStateHasher.v_float(dd.get("laager_mobility_multiplier", doc.laager_mobility_multiplier), doc.laager_mobility_multiplier)
		doc.laager_flank_damping = DeterministicStateHasher.v_float(dd.get("laager_flank_damping", doc.laager_flank_damping), doc.laager_flank_damping)
		doc.laager_rear_damping = DeterministicStateHasher.v_float(dd.get("laager_rear_damping", doc.laager_rear_damping), doc.laager_rear_damping)
		doc.contingency_trigger = DeterministicStateHasher.v_int(dd.get("contingency_trigger", int(doc.contingency_trigger)), int(doc.contingency_trigger)) as GameEnums.OfflineDoctrineTrigger
		doc.contingency_power_ratio_threshold = DeterministicStateHasher.v_float(dd.get("contingency_power_ratio_threshold", doc.contingency_power_ratio_threshold), doc.contingency_power_ratio_threshold)
		doc.contingency_low_supply_threshold = DeterministicStateHasher.v_float(dd.get("contingency_low_supply_threshold", doc.contingency_low_supply_threshold), doc.contingency_low_supply_threshold)
		doc.contingency_action_tactic = DeterministicStateHasher.v_int(dd.get("contingency_action_tactic", int(doc.contingency_action_tactic)), int(doc.contingency_action_tactic)) as GameEnums.TuranTacticPhase
		doc.contingency_target_terrain_class = DeterministicStateHasher.v_int(dd.get("contingency_target_terrain_class", int(doc.contingency_target_terrain_class)), int(doc.contingency_target_terrain_class)) as GameEnums.TerrainClass
		doc.contingency_target_geography_class = DeterministicStateHasher.v_int(dd.get("contingency_target_geography_class", int(doc.contingency_target_geography_class)), int(doc.contingency_target_geography_class)) as GameEnums.RegionGeographyClass
		doc.contingency_pack_sefer_arabasi = DeterministicStateHasher.v_bool(dd.get("contingency_pack_sefer_arabasi", doc.contingency_pack_sefer_arabasi), doc.contingency_pack_sefer_arabasi)
		doc.contingency_evade_combat = DeterministicStateHasher.v_bool(dd.get("contingency_evade_combat", doc.contingency_evade_combat), doc.contingency_evade_combat)
		_assigned_doctrines[aid] = doc
	return true
