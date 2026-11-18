extends Node
## Autoload `CausalChainEngine` (rank 2). Connects Ötüken's core simulation
## engines into multi-step, mutually destabilizing **Causal Chains** with
## calibrated friction thresholds (`CausalFrictionCalibration`) and player
## counterplay windows (`res://core/causal_chain_engine.gd`).

const CALIBRATION_PATH: String = "res://data/world/causal_friction_calibration.tres"
const KUT_RULES_PATH: String = "res://data/governance/kut_rules.tres"
const COMBAT_RULES_PATH: String = "res://data/combat/combat_rules.tres"
const DIPLOMACY_RULES_PATH: String = "res://data/diplomacy/diplomacy_rules.tres"
const DOCTRINE_PATH: String = "res://data/tactics/crescent_encirclement.tres"
const WINTER_SEASON_PATH: String = "res://data/seasons/winter.tres"
const SIK_ORMAN_TERRAIN_PATH: String = "res://data/terrain/forest.tres"

var _calibration: CausalFrictionCalibration = null
var _kut_rules: KutRules = null
var _combat_rules: CombatRules = null
var _diplomacy_rules: DiplomacyRules = null
var _doctrine: TacticalDoctrineData = null
var _winter_season: SeasonData = null
var _sik_orman_terrain: TerrainData = null


func _ready() -> void:
	_calibration = ResourceLoader.load(CALIBRATION_PATH) as CausalFrictionCalibration
	_kut_rules = ResourceLoader.load(KUT_RULES_PATH) as KutRules
	_combat_rules = ResourceLoader.load(COMBAT_RULES_PATH) as CombatRules
	_diplomacy_rules = ResourceLoader.load(DIPLOMACY_RULES_PATH) as DiplomacyRules
	_doctrine = ResourceLoader.load(DOCTRINE_PATH) as TacticalDoctrineData
	_winter_season = ResourceLoader.load(WINTER_SEASON_PATH) as SeasonData
	_sik_orman_terrain = ResourceLoader.load(SIK_ORMAN_TERRAIN_PATH) as TerrainData

	if _calibration == null:
		push_error("CausalChainEngine: failed to load CausalFrictionCalibration at %s." % CALIBRATION_PATH)
	else:
		for err: String in _calibration.get_validation_errors():
			push_error("CausalChainEngine: %s" % err)
		for parity_err: String in _calibration.verify_cross_resource_parity(_kut_rules, _combat_rules, _diplomacy_rules):
			push_error("CausalChainEngine parity: %s" % parity_err)

	CommandBus.register_handler(ExecuteCausalChainCommand.ID, _handle_execute_causal_chain)


func _exit_tree() -> void:
	CommandBus.unregister_handler(ExecuteCausalChainCommand.ID, _handle_execute_causal_chain)


func get_calibration() -> CausalFrictionCalibration:
	return _calibration


func verify_calibration_parity() -> PackedStringArray:
	if _calibration == null:
		var errs: PackedStringArray = PackedStringArray()
		errs.append("CausalChainEngine: calibration not loaded.")
		return errs
	return _calibration.verify_cross_resource_parity(_kut_rules, _combat_rules, _diplomacy_rules)


func _handle_execute_causal_chain(command: GameCommand) -> bool:
	var cmd: ExecuteCausalChainCommand = command as ExecuteCausalChainCommand
	if cmd == null or _calibration == null:
		return command.reject("Expected valid ExecuteCausalChainCommand and loaded CausalFrictionCalibration.")

	cmd.steps_executed = PackedStringArray()
	if cmd.archetype == GameEnums.CausalChainArchetype.ECOLOGICAL_LOGISTICS_COLLAPSE:
		_run_ecological_logistics_chain(cmd)
	elif cmd.archetype == GameEnums.CausalChainArchetype.COMBAT_FATIGUE_PSYCHOLOGICAL_ROUT:
		_run_combat_fatigue_rout_chain(cmd)
	elif cmd.archetype == GameEnums.CausalChainArchetype.POLITICAL_ESPIONAGE_COALITION:
		_run_political_espionage_coalition_chain(cmd)
	elif cmd.archetype == GameEnums.CausalChainArchetype.EPIDEMIC_KURGAN_PURIFICATION:
		_run_epidemic_purification_chain(cmd)

	EventBus.causal_chain_step_propagated.emit(
		cmd.archetype,
		cmd.steps_executed.size(),
		cmd.steps_executed,
		cmd.counterplay_broke_chain)
	return true


func _run_ecological_logistics_chain(cmd: ExecuteCausalChainCommand) -> void:
	# Step 1: Regional pasture overgrazing -> starving livestock
	var graze_cmd: GrazePastureCommand = GrazePastureCommand.new(cmd.player_id, cmd.region_coord, 500, 3.0)
	CommandBus.dispatch(graze_cmd)
	cmd.steps_executed.append("pasture_overgrazed_starving_livestock")

	var raw_pincer_angle: float = PI * 0.78
	var min_crescent_angle: float = _doctrine.min_crescent_flank_angle_rad if _doctrine != null else PI * 0.65

	# Counterplay check: Timely Sefer Arabası migration or supply line restoration
	if cmd.counterplay_action == GameEnums.CausalCounterplayAction.MIGRATE_SEFER_ARABASI_OR_RESUPPLY:
		var migrate_cmd: MigrateCampToPastureCommand = MigrateCampToPastureCommand.new(
			cmd.player_id, cmd.target_migration_coord)
		CommandBus.dispatch(migrate_cmd)
		cmd.steps_executed.append("counterplay_sefer_arabasi_migrated")
		cmd.resulting_remount_ratio = 1.0
		cmd.effective_crescent_wing_angle_rad = _calibration.compute_effective_crescent_wing_angle(raw_pincer_angle, 1.0)
		cmd.crescent_trap_succeeded = cmd.effective_crescent_wing_angle_rad >= min_crescent_angle
		cmd.rogue_warband_split = false
		cmd.counterplay_broke_chain = true
		EventBus.causal_chain_counterplay_applied.emit(
			cmd.archetype, cmd.counterplay_action, &"sefer_arabasi_migration_preserved_yilki_mobility")
		return

	# Step 2: Zud winter food depletion + severed supply forces Yılkı horse slaughter
	cmd.steps_executed.append("zud_food_depleted_and_supply_cut")
	cmd.resulting_remount_ratio = 0.20
	CommandBus.dispatch(ModifyKutCommand.new(-8.0, &"yilki_horse_sacrifice"))
	EventBus.yilki_horses_sacrificed_for_ration.emit(cmd.army_id, cmd.resulting_remount_ratio, 25.0, 8.0)
	cmd.steps_executed.append("yilki_horses_sacrificed_for_ration")

	# Step 3: Spare horse depletion damps wing encirclement speed -> Crescent Trap fails
	cmd.effective_crescent_wing_angle_rad = _calibration.compute_effective_crescent_wing_angle(
		raw_pincer_angle, cmd.resulting_remount_ratio)
	cmd.crescent_trap_succeeded = cmd.effective_crescent_wing_angle_rad >= min_crescent_angle
	cmd.steps_executed.append("crescent_trap_failed_due_to_wing_lag")

	# Step 4: Failed trap + morale collapse (-24.0) & denied Toy share spawns Yersiz Yurtsuz Çeriler rogue warband
	CommandBus.dispatch(DistributeToyLootCommand.new(cmd.bey_id, 200.0, 0.0, false))
	CommandBus.dispatch(DistributeToyLootCommand.new(cmd.bey_id, 200.0, 0.0, false))
	cmd.rogue_warband_split = CommandBus.is_bey_rogue_warband(cmd.bey_id)
	cmd.steps_executed.append("morale_collapsed_rogue_warband_split")
	cmd.resulting_kut = GameManager.get_kut_score()


func _run_combat_fatigue_rout_chain(cmd: ExecuteCausalChainCommand) -> void:
	# Step 1: Prolonged combat accumulates battle fatigue & degrades lance momentum
	var raw_fatigue: float = clampf(cmd.combat_duration_sec * _calibration.fatigue_accumulation_per_sec, 0.0, 100.0)
	cmd.accumulated_battle_fatigue = raw_fatigue
	cmd.fatigue_momentum_multiplier = _combat_rules.compute_fatigue_momentum_multiplier(raw_fatigue) if _combat_rules != null else 0.65
	cmd.steps_executed.append("prolonged_combat_fatigue_momentum_decay")

	# Counterplay check: Reserve rotation or tactical feigned-retreat withdrawal resets fatigue before vanguard collapse
	if cmd.counterplay_action == GameEnums.CausalCounterplayAction.ROTATE_RESERVE_OR_TACTICAL_WITHDRAW:
		cmd.accumulated_battle_fatigue = 0.0
		cmd.fatigue_momentum_multiplier = 1.0
		cmd.cascade_rout_triggered = false
		cmd.rear_strike_damage_multiplier = _calibration.directional_front_multiplier
		cmd.counterplay_broke_chain = true
		cmd.steps_executed.append("counterplay_reserve_rotation_prevented_cascade_rout")
		EventBus.causal_chain_counterplay_applied.emit(
			cmd.archetype, cmd.counterplay_action, &"reserve_rotation_restored_vanguard_cohesion")
		return

	# Step 2: Elite vanguard falls under heavy fatigue -> Cascade Rout -> 2.1x Rear Strike & Toy prisoner capture
	var attacker: CombatantStats = CombatantStats.new(901, 120.0, 60.0, 240.0, 1.0)
	attacker.attack_vector = Vector3.FORWARD

	var defender: CombatantStats = CombatantStats.new(cmd.army_id, 90.0, 55.0, 220.0, 1.0)
	defender.combat_duration_sec = cmd.combat_duration_sec
	defender.elite_vanguard_destroyed = true
	defender.elite_vanguard_id = &"bozkurt_cavalry"
	defender.rookie_troop_ratio = 0.75
	defender.facing_vector = Vector3.FORWARD

	var resolve_cmd: ResolveCombatCommand = ResolveCombatCommand.new(attacker, defender, null, 77)
	CommandBus.dispatch(resolve_cmd)
	if resolve_cmd.result != null:
		cmd.cascade_rout_triggered = resolve_cmd.result.cascade_rout_triggered
		cmd.rear_strike_damage_multiplier = resolve_cmd.result.directional_damage_multiplier
		cmd.captured_toy_loot_value = resolve_cmd.result.captured_toy_loot_value
	cmd.steps_executed.append("elite_vanguard_lost_cascade_rout_and_2_1x_rear_strike")
	cmd.steps_executed.append("routed_prisoners_and_toy_loot_captured")

	# Step 3: Consecutive battle defeat drains Kut score
	cmd.resulting_kut = GameManager.record_battle_outcome(false)
	cmd.steps_executed.append("consecutive_defeat_kut_erosion")


func _run_political_espionage_coalition_chain(cmd: ExecuteCausalChainCommand) -> void:
	# Step 1: Low Kut (< 30.0) & unfair Toy share cause Bey defection into Yersiz Yurtsuz Çeriler
	var target_low_kut: float = 24.0
	var current_kut: float = GameManager.get_kut_score()
	CommandBus.dispatch(ModifyKutCommand.new(target_low_kut - current_kut, &"unfair_toy_and_authority_crisis"))
	CommandBus.dispatch(DistributeToyLootCommand.new(cmd.bey_id, 200.0, 0.0, false))
	CommandBus.dispatch(DistributeToyLootCommand.new(cmd.bey_id, 200.0, 0.0, false))
	cmd.rogue_warband_split = CommandBus.is_bey_rogue_warband(cmd.bey_id)
	cmd.steps_executed.append("low_kut_and_unfair_toy_spawned_rogue_warband")

	# Step 2: Weakened Kut (< 30.0) provokes neighboring dynasties into a coalition war threat
	var coalition_declared: bool = DiplomacyManager.evaluate_all_dynasties(
		GameManager.get_kut_score(), 250.0, 0.85)
	cmd.coalition_formed = coalition_declared or DiplomacyManager.is_coalition_war_active()
	cmd.steps_executed.append("neighboring_dynasties_declared_coalition_war")

	# Counterplay check: High Glory (>= 40.0) re-integrates rogue warband for free & Sık Orman espionage breaks coalition ambush
	if cmd.counterplay_action == GameEnums.CausalCounterplayAction.ESPIONAGE_OR_GLORY_WARBAND_RECRUIT:
		if cmd.glory_score >= _calibration.free_warband_glory_threshold:
			cmd.warband_reintegrated_by_glory = CommandBus.reintegrate_rogue_warband(cmd.bey_id)
			cmd.rogue_warband_split = CommandBus.is_bey_rogue_warband(cmd.bey_id)
			EventBus.rogue_warband_joined_by_glory.emit(cmd.army_id, cmd.bey_id, 250, cmd.glory_score)
			cmd.steps_executed.append("counterplay_high_glory_reintegrated_rogue_warband")

		var spy_cmd: DispatchSpyCommand = DispatchSpyCommand.new(
			cmd.player_id, 2, 202, cmd.commander_leadership, _sik_orman_terrain, 95.0, GameEnums.TuranTacticPhase.CRESCENT_ENCIRCLEMENT_TRAP)
		if CommandBus.dispatch(spy_cmd) and spy_cmd.report != null and spy_cmd.report.succeeded:
			CommandBus.dispatch(ModifyKutCommand.new(12.0, &"espionage_foiled_coalition_ambush"))
			DiplomacyManager.evaluate_all_dynasties(GameManager.get_kut_score(), 950.0, 0.10)
			cmd.coalition_broken_by_espionage_or_glory = not DiplomacyManager.is_coalition_war_active()
			cmd.steps_executed.append("counterplay_sik_orman_espionage_broke_coalition")

		cmd.counterplay_broke_chain = cmd.warband_reintegrated_by_glory or cmd.coalition_broken_by_espionage_or_glory
		EventBus.causal_chain_counterplay_applied.emit(
			cmd.archetype, cmd.counterplay_action, &"glory_and_espionage_reversed_coalition_crisis")

	cmd.resulting_kut = GameManager.get_kut_score()


func _run_epidemic_purification_chain(cmd: ExecuteCausalChainCommand) -> void:
	# Step 1: Zud winter + depleted food (Food <= 0) triggers outbreak_epidemic
	SeasonManager.set_food_reserve(0)
	var outbreak_started: bool = SeasonManager.evaluate_zud_epidemic_outbreak(
		cmd.army_id, true, 1, _winter_season)
	cmd.epidemic_active = outbreak_started or SeasonManager.is_army_infected(cmd.army_id)
	cmd.steps_executed.append("zud_food_zero_triggered_outbreak_epidemic")

	# Step 2: Daily troop attrition (8%) and speed penalty (0.50x)
	cmd.remaining_troops_after_epidemic = SeasonManager.simulate_epidemic_day(cmd.army_id, cmd.initial_troops)
	cmd.steps_executed.append("epidemic_daily_attrition_and_half_speed_applied")

	# Counterplay check: Kurgan Shrine purification ritual spends 12.0 Kut to halt epidemic
	if cmd.counterplay_action == GameEnums.CausalCounterplayAction.KURGAN_PURIFICATION_RITUAL:
		if GameManager.get_kut_score() < _calibration.kurgan_purification_kut_cost:
			CommandBus.dispatch(ModifyKutCommand.new(_calibration.kurgan_purification_kut_cost + 5.0, &"shamanic_preparation"))
		var purify_cmd: PurifyEpidemicCommand = PurifyEpidemicCommand.new(cmd.army_id, &"kurgan_shrine")
		if CommandBus.dispatch(purify_cmd) and purify_cmd.purified:
			cmd.epidemic_purified = true
			cmd.epidemic_active = SeasonManager.is_army_infected(cmd.army_id)
			cmd.counterplay_broke_chain = true
			cmd.steps_executed.append("counterplay_kurgan_purification_halted_epidemic")
			EventBus.causal_chain_counterplay_applied.emit(
				cmd.archetype, cmd.counterplay_action, &"kurgan_ritual_purified_steppe_plague")

	cmd.resulting_kut = GameManager.get_kut_score()
