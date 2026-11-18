extends Node
## Autoload `CausalChainEngine` (rank 2). Connects Ötüken's core simulation
## engines into multi-step, mutually destabilizing **Causal Chains** and a
## **Continuous Accumulation / Decay / Recovery Loop** with calibrated friction
## thresholds (`CausalFrictionCalibration`) and type-safe `CausalTransitionRecord`
## telemetry (`res://core/causal_chain_engine.gd`).

const CALIBRATION_PATH: String = "res://data/world/causal_friction_calibration.tres"
const KUT_RULES_PATH: String = "res://data/governance/kut_rules.tres"
const COMBAT_RULES_PATH: String = "res://data/combat/combat_rules.tres"
const DIPLOMACY_RULES_PATH: String = "res://data/diplomacy/diplomacy_rules.tres"
const DOCTRINE_PATH: String = "res://data/tactics/crescent_encirclement.tres"
const WINTER_SEASON_PATH: String = "res://data/seasons/winter.tres"
const SIK_ORMAN_TERRAIN_PATH: String = "res://data/terrain/forest.tres"
const MAX_TRANSITION_HISTORY: int = 256

var _calibration: CausalFrictionCalibration = null
var _kut_rules: KutRules = null
var _combat_rules: CombatRules = null
var _diplomacy_rules: DiplomacyRules = null
var _doctrine: TacticalDoctrineData = null
var _winter_season: SeasonData = null
var _sik_orman_terrain: TerrainData = null

# --- Continuous Simulation State (Accumulation / Decay / Recovery) ----------
var _ecological_pressure: float = 0.0
var _logistics_strain: float = 0.0
var _morale_panic_pressure: float = 0.0
var _political_fracture_pressure: float = 0.0
var _continuous_remount_ratio: float = 1.0
var _transition_history: Array[CausalTransitionRecord] = []


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
	CommandBus.register_handler(StepContinuousSimulationCommand.ID, _handle_step_continuous_simulation)


func _exit_tree() -> void:
	CommandBus.unregister_handler(ExecuteCausalChainCommand.ID, _handle_execute_causal_chain)
	CommandBus.unregister_handler(StepContinuousSimulationCommand.ID, _handle_step_continuous_simulation)


func get_calibration() -> CausalFrictionCalibration:
	return _calibration


func get_transition_history() -> Array[CausalTransitionRecord]:
	return _transition_history


func reset_continuous_state() -> void:
	_ecological_pressure = 0.0
	_logistics_strain = 0.0
	_morale_panic_pressure = 0.0
	_political_fracture_pressure = 0.0
	_continuous_remount_ratio = 1.0
	_transition_history.clear()


func verify_calibration_parity() -> PackedStringArray:
	if _calibration == null:
		var errs: PackedStringArray = PackedStringArray()
		errs.append("CausalChainEngine: calibration not loaded.")
		return errs
	return _calibration.verify_cross_resource_parity(_kut_rules, _combat_rules, _diplomacy_rules)


func _emit_transition(archetype: GameEnums.CausalChainArchetype, step_id: StringName, cause_src: StringName, effect_tgt: StringName, magnitude: float, pressure: float, is_recovery: bool = false) -> void:
	var rec: CausalTransitionRecord = CausalTransitionRecord.new(
		archetype, step_id, cause_src, effect_tgt, magnitude, pressure, is_recovery)
	while _transition_history.size() >= MAX_TRANSITION_HISTORY:
		_transition_history.pop_front()
	_transition_history.append(rec)
	EventBus.causal_transition_recorded.emit(rec)


func _handle_step_continuous_simulation(command: GameCommand) -> bool:
	var step_cmd: StepContinuousSimulationCommand = command as StepContinuousSimulationCommand
	if step_cmd == null or _calibration == null:
		return command.reject("Expected valid StepContinuousSimulationCommand and loaded CausalFrictionCalibration.")

	var dt: float = maxf(step_cmd.delta_sec, 0.0)
	var acc_rate: float = _calibration.continuous_pressure_accumulation_per_sec
	var dec_rate: float = _calibration.continuous_pressure_decay_per_sec
	var emitted_count: int = 0

	# 1. Ecological Pressure: accumulates when pasture is depleted and camp refuses to migrate; decays on Sefer Arabası migration
	if step_cmd.is_pasture_depleted and not step_cmd.is_migrating_sefer_arabasi:
		var eco_delta: float = acc_rate * dt * (1.35 if step_cmd.is_zud_winter else 1.0)
		_ecological_pressure = clampf(_ecological_pressure + eco_delta, 0.0, 100.0)
		_emit_transition(
			GameEnums.CausalChainArchetype.ECOLOGICAL_LOGISTICS_COLLAPSE,
			&"continuous_ecological_accumulation",
			&"pasture_ecology",
			&"supply_logistics",
			eco_delta,
			_ecological_pressure,
			false)
		emitted_count += 1
	else:
		var prev_eco: float = _ecological_pressure
		var eco_rec: float = dec_rate * dt
		_ecological_pressure = clampf(_ecological_pressure - eco_rec, 0.0, 100.0)
		if prev_eco > _ecological_pressure:
			_emit_transition(
				GameEnums.CausalChainArchetype.ECOLOGICAL_LOGISTICS_COLLAPSE,
				&"continuous_ecological_recovery",
				&"sefer_arabasi_migration",
				&"pasture_ecology",
				prev_eco - _ecological_pressure,
				_ecological_pressure,
				true)
			emitted_count += 1

	# 2. Logistics & Yılkı Remount Strain: driven by ecological pressure, Zud winter, and supply line state
	if not step_cmd.has_supply_line or (step_cmd.is_zud_winter and _ecological_pressure >= 25.0):
		var log_delta: float = (acc_rate * 0.9 + _ecological_pressure * 0.12) * dt
		_logistics_strain = clampf(_logistics_strain + log_delta, 0.0, 100.0)
		var remount_drop: float = _calibration.remount_drain_per_sec_under_zud_strain * dt
		_continuous_remount_ratio = clampf(_continuous_remount_ratio - remount_drop, 0.15, 1.0)
		_emit_transition(
			GameEnums.CausalChainArchetype.ECOLOGICAL_LOGISTICS_COLLAPSE,
			&"continuous_logistics_and_yilki_decay",
			&"zud_and_supply_cut",
			&"turan_tactics_mobility",
			remount_drop,
			_logistics_strain,
			false)
		emitted_count += 1
	else:
		var prev_log: float = _logistics_strain
		var prev_remount: float = _continuous_remount_ratio
		var log_rec: float = dec_rate * dt
		_logistics_strain = clampf(_logistics_strain - log_rec, 0.0, 100.0)
		var remount_gain: float = _calibration.remount_recovery_per_sec_when_supplied * dt
		_continuous_remount_ratio = clampf(_continuous_remount_ratio + remount_gain, 0.15, 1.0)
		if prev_log > _logistics_strain or _continuous_remount_ratio > prev_remount:
			_emit_transition(
				GameEnums.CausalChainArchetype.ECOLOGICAL_LOGISTICS_COLLAPSE,
				&"continuous_logistics_and_yilki_recovery",
				&"supply_convoy_connected",
				&"turan_tactics_mobility",
				maxf(remount_gain, prev_log - _logistics_strain),
				_logistics_strain,
				true)
			emitted_count += 1

	# 3. Morale & Panic Pressure: feeds from logistics strain and combat vs rest
	if not step_cmd.is_resting_out_of_combat and _logistics_strain >= 20.0:
		var mor_delta: float = (_logistics_strain * 0.18 + (1.0 - _continuous_remount_ratio) * 12.0) * dt
		_morale_panic_pressure = clampf(_morale_panic_pressure + mor_delta, 0.0, 100.0)
		_emit_transition(
			GameEnums.CausalChainArchetype.COMBAT_FATIGUE_PSYCHOLOGICAL_ROUT,
			&"continuous_morale_panic_accumulation",
			&"yilki_mobility_loss_and_fatigue",
			&"army_morale_state",
			mor_delta,
			_morale_panic_pressure,
			false)
		emitted_count += 1
	else:
		var mor_rec: float = dec_rate * 1.1 * dt
		_morale_panic_pressure = clampf(_morale_panic_pressure - mor_rec, 0.0, 100.0)

	# 4. Political Fracture Pressure: feeds from morale panic and unfair Toy/Ülüş distribution
	if step_cmd.fair_toy_ratio < 0.35 or _morale_panic_pressure >= 35.0:
		var pol_delta: float = ((0.50 - step_cmd.fair_toy_ratio) * 18.0 + _morale_panic_pressure * 0.15) * dt
		_political_fracture_pressure = clampf(_political_fracture_pressure + maxf(pol_delta, 2.0 * dt), 0.0, 100.0)
		_emit_transition(
			GameEnums.CausalChainArchetype.POLITICAL_ESPIONAGE_COALITION,
			&"continuous_political_fracture_accumulation",
			&"toy_discontent_and_morale_panic",
			&"kinship_and_diplomacy",
			pol_delta,
			_political_fracture_pressure,
			false)
		emitted_count += 1
	else:
		var pol_rec: float = dec_rate * dt
		_political_fracture_pressure = clampf(_political_fracture_pressure - pol_rec, 0.0, 100.0)

	step_cmd.ecological_pressure = _ecological_pressure
	step_cmd.logistics_strain = _logistics_strain
	step_cmd.morale_panic_pressure = _morale_panic_pressure
	step_cmd.political_fracture_pressure = _political_fracture_pressure
	step_cmd.effective_remount_ratio = _continuous_remount_ratio
	step_cmd.effective_maneuver_speed_mult = clampf(0.45 + 0.55 * _continuous_remount_ratio, 0.45, 1.0)
	step_cmd.transition_records_emitted = emitted_count
	return true


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
	_emit_transition(cmd.archetype, &"pasture_overgrazed_starving_livestock", &"pasture_ecology", &"yilki_herd", 100.0, 45.0, false)

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
		_emit_transition(cmd.archetype, &"counterplay_sefer_arabasi_migrated", &"sefer_arabasi", &"turan_tactics_mobility", 1.0, 0.0, true)
		EventBus.causal_chain_counterplay_applied.emit(
			cmd.archetype, cmd.counterplay_action, &"sefer_arabasi_migration_preserved_yilki_mobility")
		return

	# Step 2: Zud winter food depletion + severed supply forces Yılkı horse slaughter
	cmd.steps_executed.append("zud_food_depleted_and_supply_cut")
	cmd.resulting_remount_ratio = 0.20
	CommandBus.dispatch(ModifyKutCommand.new(-8.0, &"yilki_horse_sacrifice"))
	EventBus.yilki_horses_sacrificed_for_ration.emit(cmd.army_id, cmd.resulting_remount_ratio, 25.0, 8.0)
	cmd.steps_executed.append("yilki_horses_sacrificed_for_ration")
	_emit_transition(cmd.archetype, &"yilki_horses_sacrificed_for_ration", &"supply_logistics", &"remount_horse_ratio", 0.80, 75.0, false)

	# Step 3: Spare horse depletion damps wing encirclement speed -> Crescent Trap fails
	cmd.effective_crescent_wing_angle_rad = _calibration.compute_effective_crescent_wing_angle(
		raw_pincer_angle, cmd.resulting_remount_ratio)
	cmd.crescent_trap_succeeded = cmd.effective_crescent_wing_angle_rad >= min_crescent_angle
	cmd.steps_executed.append("crescent_trap_failed_due_to_wing_lag")
	_emit_transition(cmd.archetype, &"crescent_trap_failed_due_to_wing_lag", &"remount_horse_ratio", &"turan_tactics_mobility", cmd.effective_crescent_wing_angle_rad, 88.0, false)

	# Step 4: Failed trap + morale collapse (-24.0) & denied Toy share spawns Yersiz Yurtsuz Çeriler rogue warband
	CommandBus.dispatch(DistributeToyLootCommand.new(cmd.bey_id, 200.0, 0.0, false))
	CommandBus.dispatch(DistributeToyLootCommand.new(cmd.bey_id, 200.0, 0.0, false))
	cmd.rogue_warband_split = CommandBus.is_bey_rogue_warband(cmd.bey_id)
	cmd.steps_executed.append("morale_collapsed_rogue_warband_split")
	_emit_transition(cmd.archetype, &"morale_collapsed_rogue_warband_split", &"turan_tactics_failure", &"yersiz_yurtsuz_ceriler", 24.0, 100.0, false)
	cmd.resulting_kut = GameManager.get_kut_score()


func _run_combat_fatigue_rout_chain(cmd: ExecuteCausalChainCommand) -> void:
	# Step 1: Prolonged combat accumulates battle fatigue & degrades lance momentum
	var raw_fatigue: float = clampf(cmd.combat_duration_sec * _calibration.fatigue_accumulation_per_sec, 0.0, 100.0)
	cmd.accumulated_battle_fatigue = raw_fatigue
	cmd.fatigue_momentum_multiplier = _combat_rules.compute_fatigue_momentum_multiplier(raw_fatigue) if _combat_rules != null else 0.65
	cmd.steps_executed.append("prolonged_combat_fatigue_momentum_decay")
	_emit_transition(cmd.archetype, &"prolonged_combat_fatigue_momentum_decay", &"battle_fatigue", &"lance_momentum", raw_fatigue, raw_fatigue, false)

	# Counterplay check: Reserve rotation or tactical feigned-retreat withdrawal resets fatigue before vanguard collapse
	if cmd.counterplay_action == GameEnums.CausalCounterplayAction.ROTATE_RESERVE_OR_TACTICAL_WITHDRAW:
		cmd.accumulated_battle_fatigue = 0.0
		cmd.fatigue_momentum_multiplier = 1.0
		cmd.cascade_rout_triggered = false
		cmd.rear_strike_damage_multiplier = _calibration.directional_front_multiplier
		cmd.counterplay_broke_chain = true
		cmd.steps_executed.append("counterplay_reserve_rotation_prevented_cascade_rout")
		_emit_transition(cmd.archetype, &"counterplay_reserve_rotation_prevented_cascade_rout", &"reserve_rotation", &"army_morale_state", 100.0, 0.0, true)
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
	_emit_transition(cmd.archetype, &"elite_vanguard_lost_cascade_rout_and_2_1x_rear_strike", &"EliteVanguardLoss", &"CascadeRoutRearStrike", cmd.rear_strike_damage_multiplier, 95.0, false)

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
	_emit_transition(cmd.archetype, &"low_kut_and_unfair_toy_spawned_rogue_warband", &"LowKutAndToyInjustice", &"YersizYurtsuzCeriler", 24.0, 80.0, false)

	# Step 2: Weakened Kut (< 30.0) provokes neighboring dynasties into a coalition war threat
	var coalition_declared: bool = DiplomacyManager.evaluate_all_dynasties(
		GameManager.get_kut_score(), 250.0, 0.85)
	cmd.coalition_formed = coalition_declared or DiplomacyManager.is_coalition_war_active()
	cmd.steps_executed.append("neighboring_dynasties_declared_coalition_war")
	_emit_transition(cmd.archetype, &"neighboring_dynasties_declared_coalition_war", &"KutBelow30", &"CoalitionWar", 30.0, 95.0, false)

	# Counterplay check: High Glory (>= 40.0) re-integrates rogue warband for free & Sık Orman espionage breaks coalition ambush
	if cmd.counterplay_action == GameEnums.CausalCounterplayAction.ESPIONAGE_OR_GLORY_WARBAND_RECRUIT:
		if cmd.glory_score >= _calibration.free_warband_glory_threshold:
			cmd.warband_reintegrated_by_glory = CommandBus.reintegrate_rogue_warband(cmd.bey_id)
			cmd.rogue_warband_split = CommandBus.is_bey_rogue_warband(cmd.bey_id)
			EventBus.rogue_warband_joined_by_glory.emit(cmd.army_id, cmd.bey_id, 250, cmd.glory_score)
			cmd.steps_executed.append("counterplay_high_glory_reintegrated_rogue_warband")
			_emit_transition(cmd.archetype, &"counterplay_high_glory_reintegrated_rogue_warband", &"KhaganGlory", &"ArmyReinforcement", cmd.glory_score, 20.0, true)

		var spy_cmd: DispatchSpyCommand = DispatchSpyCommand.new(
			cmd.player_id, 2, 202, cmd.commander_leadership, _sik_orman_terrain, 95.0, GameEnums.TuranTacticPhase.CRESCENT_ENCIRCLEMENT_TRAP)
		if CommandBus.dispatch(spy_cmd) and spy_cmd.report != null and spy_cmd.report.succeeded:
			CommandBus.dispatch(ModifyKutCommand.new(12.0, &"espionage_foiled_coalition_ambush"))
			DiplomacyManager.evaluate_all_dynasties(GameManager.get_kut_score(), 950.0, 0.10)
			cmd.coalition_broken_by_espionage_or_glory = not DiplomacyManager.is_coalition_war_active()
			cmd.steps_executed.append("counterplay_sik_orman_espionage_broke_coalition")
			_emit_transition(cmd.archetype, &"counterplay_sik_orman_espionage_broke_coalition", &"IntelligenceManager", &"DiplomacyManager", 12.0, 0.0, true)

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
	_emit_transition(cmd.archetype, &"zud_food_zero_triggered_outbreak_epidemic", &"ZudStarvation", &"OutbreakEpidemic", 0.50, 85.0, false)

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
			_emit_transition(cmd.archetype, &"counterplay_kurgan_purification_halted_epidemic", &"KurganShrinePurification", &"SeasonManager", 12.0, 0.0, true)
			EventBus.causal_chain_counterplay_applied.emit(
				cmd.archetype, cmd.counterplay_action, &"kurgan_ritual_purified_steppe_plague")

	cmd.resulting_kut = GameManager.get_kut_score()
