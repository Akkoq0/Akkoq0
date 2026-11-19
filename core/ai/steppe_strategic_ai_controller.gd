class_name SteppeStrategicAIController
extends RefCounted
## Core Strategic AI Director & Controller (rank 2). Coordinates one AI tribal
## faction's bounded-rationality decision loop (`AIBeliefModel`,
## `AIUtilityEvaluator`, `AISchemePlanner`, `AINarrativeAgendaHook`), routing
## 100% of gameplay actions exclusively through authorized `CommandEnvelope`
## submissions on `CommandBus` with zero simulation cheats.

static var _registered_agents: Dictionary[int, SteppeStrategicAIController] = {}

var agent_id: StringName = &"karluk_ai"
var ai_player_id: int = 2
var ai_army_id: int = 201
var home_coord: Vector2i = Vector2i.ZERO
var target_player_id: int = 1
var target_army_id: int = 1
var target_coord: Vector2i = Vector2i.ZERO
var remount_ratio: float = 1.0

var difficulty_profile: AIDifficultyProfile = null
var personality_profile: SteppeAIPersonalityProfile = null
var belief_model: AIBeliefModel = null
var scheme_planner: AISchemePlanner = null
var agenda_hook: AINarrativeAgendaHook = null
var personality_evolution: AIPersonalityEvolution = AIPersonalityEvolution.new()
var theory_of_mind: AITheoryOfMindModel = AITheoryOfMindModel.new()
var deception_engine: AIDeceptionEngine = AIDeceptionEngine.new()
var _evolution_synced_with_base: bool = false

var _rng: RandomNumberGenerator = null
var _rng_seed: int = 32001
var _rng_draws: int = 0
var _envelope_sequence: int = 0

var _decisions_made: int = 0
var _envelopes_accepted: int = 0
var _envelopes_rejected: int = 0
var _last_action_category: GameEnums.AIActionCategory = GameEnums.AIActionCategory.HOLD_AND_GATHER
var _last_action_id: StringName = &""
var _last_doctrine_preset: GameEnums.BattleDoctrinePresetId = GameEnums.BattleDoctrinePresetId.KURT_KAPANI
var _last_decision_score: float = 0.0
var _last_outcome: AIUtilityEvaluator.EvaluationOutcome = null
var _last_envelope: CommandEnvelope = null


func _init(
		p_agent_id: StringName = &"karluk_ai",
		p_ai_player_id: int = 2,
		p_ai_army_id: int = 201,
		p_home_coord: Vector2i = Vector2i(2, 2),
		p_difficulty: GameEnums.AIDifficultyTier = GameEnums.AIDifficultyTier.SANCAK_BEYI,
		p_personality: GameEnums.SteppeAIPersonality = GameEnums.SteppeAIPersonality.AKINCI_BASKINCI,
		p_seed: int = 32001,
		p_target_player_id: int = 1,
		p_target_army_id: int = 1,
		p_target_coord: Vector2i = Vector2i.ZERO) -> void:
	agent_id = p_agent_id
	ai_player_id = maxi(p_ai_player_id, 1)
	ai_army_id = maxi(p_ai_army_id, 1)
	home_coord = p_home_coord
	target_player_id = maxi(p_target_player_id, 1)
	target_army_id = maxi(p_target_army_id, 1)
	target_coord = p_target_coord

	difficulty_profile = AIDifficultyProfile.create_preset(p_difficulty)
	personality_profile = SteppeAIPersonalityProfile.create_preset(p_personality)
	belief_model = AIBeliefModel.new(ai_player_id, target_player_id, target_army_id)
	belief_model.set_target(target_player_id, target_army_id, target_coord)
	scheme_planner = AISchemePlanner.new()
	agenda_hook = AINarrativeAgendaHook.new()

	_rng_seed = clampi(absi(p_seed), 1, 2147483647)
	_rng = RandomNumberGenerator.new()
	_rng.seed = _rng_seed
	_rng_draws = 0


static func register_ai_agent(ctrl: SteppeStrategicAIController) -> void:
	if ctrl == null or ctrl.ai_player_id <= 0:
		return
	_registered_agents[ctrl.ai_player_id] = ctrl
	CommandBus.register_envelope_army_owner(ctrl.ai_army_id, ctrl.ai_player_id)


static func unregister_ai_agent(p_player_id: int) -> void:
	_registered_agents.erase(p_player_id)


static func get_ai_agent(p_player_id: int) -> SteppeStrategicAIController:
	return _registered_agents.get(p_player_id, null)


static func get_all_ai_agents() -> Array[SteppeStrategicAIController]:
	var out: Array[SteppeStrategicAIController] = []
	var keys: Array[int] = _registered_agents.keys()
	keys.sort()
	for pid: int in keys:
		var ctrl: SteppeStrategicAIController = _registered_agents.get(pid, null)
		if ctrl != null:
			out.append(ctrl)
	return out


static func reset_strategic_ai_state() -> void:
	_registered_agents.clear()


static func notify_doctrine_matchup(
		attacker_id: int,
		attacker_army_id: int,
		defender_id: int,
		defender_army_id: int,
		result: DoctrineMatchupResult) -> void:
	if result == null:
		return
	for ctrl: SteppeStrategicAIController in get_all_ai_agents():
		var lr: float = ctrl.difficulty_profile.adaptation_learning_rate if ctrl.difficulty_profile != null else 0.60
		var ai_is_atk: bool = attacker_id == ctrl.ai_player_id or attacker_id == ctrl.ai_army_id or attacker_army_id == ctrl.ai_army_id
		var target_is_def: bool = defender_id == ctrl.target_player_id or defender_id == ctrl.target_army_id or defender_army_id == ctrl.target_army_id
		var ai_is_def: bool = defender_id == ctrl.ai_player_id or defender_id == ctrl.ai_army_id or defender_army_id == ctrl.ai_army_id
		var target_is_atk: bool = attacker_id == ctrl.target_player_id or attacker_id == ctrl.target_army_id or attacker_army_id == ctrl.target_army_id
		if ai_is_atk and target_is_def and result.defender_doctrine_id != &"":
			ctrl.belief_model.observe_doctrine_id_string(result.defender_doctrine_id, lr)
			if ctrl.theory_of_mind != null:
				ctrl.theory_of_mind.observe_opponent_matchup_doctrine(result.defender_doctrine_id, ctrl.difficulty_profile)
		elif ai_is_def and target_is_atk and result.attacker_doctrine_id != &"":
			ctrl.belief_model.observe_doctrine_id_string(result.attacker_doctrine_id, lr)
			if ctrl.theory_of_mind != null:
				ctrl.theory_of_mind.observe_opponent_matchup_doctrine(result.attacker_doctrine_id, ctrl.difficulty_profile)


static func notify_espionage_report(report: EspionageReport) -> void:
	if report == null or not report.succeeded:
		return
	var ctrl: SteppeStrategicAIController = get_ai_agent(report.spy_owner_id)
	if ctrl == null or ctrl.target_player_id != report.target_faction_id:
		return
	var lr: float = ctrl.difficulty_profile.adaptation_learning_rate if ctrl.difficulty_profile != null else 0.60
	ctrl.belief_model.observe_tactic_intent(report.revealed_tactic_intent, lr)


static func notify_courier_ambushed(
		victim_player_id: int,
		ambusher_faction_id: int,
		leaked_plan: GameEnums.TuranTacticPhase) -> void:
	var ctrl: SteppeStrategicAIController = get_ai_agent(ambusher_faction_id)
	if ctrl == null or ctrl.target_player_id != victim_player_id:
		return
	var lr: float = ctrl.difficulty_profile.adaptation_learning_rate if ctrl.difficulty_profile != null else 0.60
	ctrl.belief_model.observe_tactic_intent(leaked_plan, lr)


static func notify_water_sabotaged(region_coord: Vector2i, saboteur_id: int) -> void:
	var reg: RegionData = TerritoryManager.get_region(region_coord)
	var owner_pid: int = reg.owner_id if reg != null else 0
	for ctrl: SteppeStrategicAIController in get_all_ai_agents():
		if ctrl == null:
			continue
		if (owner_pid > 0 and ctrl.ai_player_id == owner_pid) or ctrl.home_coord == region_coord:
			if ctrl.ai_player_id != saboteur_id:
				ctrl.record_trauma(GameEnums.AITraumaType.WELL_SABOTAGED, saboteur_id, 1.0, str(region_coord))


static func notify_zud_starvation(food_remaining: int) -> void:
	if food_remaining > 25:
		return
	var severity: float = 1.0 if food_remaining <= 10 else 0.60
	for ctrl: SteppeStrategicAIController in get_all_ai_agents():
		if ctrl != null:
			ctrl.record_trauma(GameEnums.AITraumaType.ZUD_HEAVY_LOSS, 0, severity, "food_%d" % food_remaining)


static func notify_amanat_pact_broken(
		pact_id: StringName,
		betrayer_id: int,
		party_a: int = 0,
		party_b: int = 0) -> void:
	for ctrl: SteppeStrategicAIController in get_all_ai_agents():
		if ctrl == null or ctrl.ai_player_id == betrayer_id:
			continue
		var is_victim: bool = (ctrl.ai_player_id == party_a or ctrl.ai_player_id == party_b)
		if is_victim or (party_a == 0 and party_b == 0 and ctrl.target_player_id == betrayer_id):
			ctrl.record_trauma(GameEnums.AITraumaType.AMANAT_BETRAYAL, betrayer_id, 1.0, String(pact_id))


static func notify_commander_fallen(victim_player_id: int, killer_player_id: int = 0) -> void:
	var ctrl: SteppeStrategicAIController = get_ai_agent(victim_player_id)
	if ctrl == null:
		return
	var eff_killer: int = killer_player_id if killer_player_id > 0 else ctrl.target_player_id
	ctrl.record_trauma(GameEnums.AITraumaType.VETERAN_COMMANDER_FALLEN, eff_killer, 1.0, "commander_fallen")


func _ensure_cognitive_modules() -> void:
	if personality_evolution == null:
		personality_evolution = AIPersonalityEvolution.new(personality_profile)
		_evolution_synced_with_base = personality_profile != null
	elif not _evolution_synced_with_base and personality_profile != null:
		personality_evolution.apply_base_profile(personality_profile)
		_evolution_synced_with_base = true
	if theory_of_mind == null:
		theory_of_mind = AITheoryOfMindModel.new()
	if deception_engine == null:
		deception_engine = AIDeceptionEngine.new()


func get_personality_evolution() -> AIPersonalityEvolution:
	_ensure_cognitive_modules()
	return personality_evolution


func get_theory_of_mind() -> AITheoryOfMindModel:
	_ensure_cognitive_modules()
	return theory_of_mind


func get_deception_engine() -> AIDeceptionEngine:
	_ensure_cognitive_modules()
	return deception_engine


func record_trauma(
		trauma_type: GameEnums.AITraumaType,
		instigator_pid: int,
		severity: float = 1.0,
		detail_tag: String = "") -> float:
	_ensure_cognitive_modules()
	var eff_tick: int = SessionClockAuthority.get_current_tick()
	var prev_zud_tick: int = personality_evolution._last_zud_tick_recorded
	var vendetta_after: float = personality_evolution.record_trauma(trauma_type, instigator_pid, severity, eff_tick, detail_tag)
	if trauma_type != GameEnums.AITraumaType.ZUD_HEAVY_LOSS or personality_evolution._last_zud_tick_recorded != prev_zud_tick:
		EventBus.ai_personality_evolved.emit(
			agent_id,
			ai_player_id,
			trauma_type,
			instigator_pid,
			vendetta_after,
			personality_evolution.trauma_score)
	return vendetta_after


func bind_story_agenda(agenda: StoryAgendaResource) -> void:
	if agenda_hook == null:
		agenda_hook = AINarrativeAgendaHook.new()
	agenda_hook.bind_agenda(agenda)


func clear_story_agenda() -> void:
	if agenda_hook != null:
		agenda_hook.clear_agenda()


func set_difficulty_tier(tier: GameEnums.AIDifficultyTier) -> void:
	difficulty_profile = AIDifficultyProfile.create_preset(tier)


func set_personality(p: GameEnums.SteppeAIPersonality) -> void:
	personality_profile = SteppeAIPersonalityProfile.create_preset(p)
	if personality_evolution == null:
		personality_evolution = AIPersonalityEvolution.new(personality_profile)
	else:
		personality_evolution.apply_base_profile(personality_profile)
	_evolution_synced_with_base = true


func set_remount_ratio(ratio: float) -> void:
	remount_ratio = clampf(ratio, 0.0, 1.0)


func get_last_outcome() -> AIUtilityEvaluator.EvaluationOutcome:
	return _last_outcome


func get_last_envelope() -> CommandEnvelope:
	return _last_envelope


func get_decisions_made_count() -> int:
	return _decisions_made


func get_envelopes_accepted_count() -> int:
	return _envelopes_accepted


func get_envelopes_rejected_count() -> int:
	return _envelopes_rejected


func get_last_action_category() -> GameEnums.AIActionCategory:
	return _last_action_category


func get_last_action_id() -> StringName:
	return _last_action_id


func get_last_selected_doctrine() -> GameEnums.BattleDoctrinePresetId:
	return _last_doctrine_preset


func get_last_decision_score() -> float:
	return _last_decision_score


func observe_enemy_doctrine(preset_id: GameEnums.BattleDoctrinePresetId) -> void:
	var lr: float = difficulty_profile.adaptation_learning_rate if difficulty_profile != null else 0.60
	belief_model.observe_enemy_doctrine(int(preset_id), lr)


func step_decision_tick(current_tick: int = -1, auto_flush: bool = true) -> CommandEnvelope:
	_ensure_cognitive_modules()
	CommandBus.register_envelope_army_owner(ai_army_id, ai_player_id)
	var eff_tick: int = current_tick if current_tick >= 0 else SessionClockAuthority.get_current_tick()

	belief_model.refresh_public_and_legitimate_observations(difficulty_profile, target_coord)
	if scheme_planner != null and scheme_planner.has_active_scheme():
		var abort_reason: StringName = scheme_planner.evaluate_abort_condition(ai_player_id, belief_model)
		if abort_reason != &"":
			var aborted_type: GameEnums.AISchemeType = scheme_planner.get_active_scheme()
			var aborted_step: int = scheme_planner.get_current_step()
			scheme_planner.abort_scheme()
			EventBus.ai_scheme_step_advanced.emit(
				agent_id,
				aborted_type,
				aborted_step,
				AISchemePlanner.TOTAL_STEPS,
				abort_reason,
				false)

	var narrative_dir: AINarrativeAgendaHook.NarrativeWeightDirective = agenda_hook.evaluate_directive(ai_player_id, target_player_id)
	if narrative_dir.triggered_now:
		EventBus.ai_story_agenda_activated.emit(agent_id, narrative_dir.agenda_id, narrative_dir.trigger_reason)

	var eff_target_coord: Vector2i = target_coord if target_coord != Vector2i.ZERO else belief_model.get_observed_target_region_coord()
	var ai_syn_now: SynergyEvaluationSnapshot = SystemicSynergyMatrix.evaluate_player(ai_player_id, ai_army_id, home_coord, false)
	var own_sabotaged_wells: int = WaterRouteManager.count_sabotaged_water_sources(home_coord)
	var supply_crisis: bool = SeasonManager.get_food_reserve() <= 25 or (ai_syn_now != null and ai_syn_now.water_logistics_ratio < 0.60)
	var stress_dir: AIPersonalityEvolution.StressDirective = personality_evolution.evaluate_stress_directive(
		difficulty_profile, belief_model.get_observed_enemy_dread(), supply_crisis, own_sabotaged_wells)
	var deception_eval: AIDeceptionEngine.DeceptionEvaluation = deception_engine.evaluate_vectors(
		ai_player_id,
		ai_army_id,
		target_player_id,
		target_army_id,
		eff_target_coord,
		belief_model,
		theory_of_mind,
		personality_evolution,
		difficulty_profile,
		personality_profile,
		stress_dir)

	var outcome: AIUtilityEvaluator.EvaluationOutcome = AIUtilityEvaluator.evaluate_candidates(
		agent_id,
		ai_player_id,
		ai_army_id,
		home_coord,
		target_player_id,
		target_army_id,
		belief_model,
		scheme_planner,
		difficulty_profile,
		personality_profile,
		narrative_dir,
		remount_ratio,
		_rng,
		_rng_seed + _decisions_made * 13 + eff_tick,
		personality_evolution,
		theory_of_mind,
		deception_eval)
	_rng_draws += outcome.draws_consumed
	_last_outcome = outcome

	var chosen: AIUtilityEvaluator.AIActionCandidate = outcome.chosen
	if chosen == null:
		return null

	var executing_scheme: bool = false
	var active_scheme_type: GameEnums.AISchemeType = scheme_planner.get_active_scheme()
	var step_idx_before: int = scheme_planner.get_current_step()
	var cmd_type: String = chosen.command_type
	var cmd_payload: Dictionary = chosen.payload.duplicate()
	var action_tag: StringName = chosen.sub_action_id
	var doc_preset_int: int = chosen.doctrine_preset

	if chosen.scheme_to_start != GameEnums.AISchemeType.NONE:
		scheme_planner.begin_scheme(
			chosen.scheme_to_start,
			target_player_id,
			target_army_id,
			eff_target_coord,
			eff_tick)
		active_scheme_type = scheme_planner.get_active_scheme()
		step_idx_before = scheme_planner.get_current_step()
		var first_step: AISchemePlanner.SchemeStepIntent = scheme_planner.build_next_step_intent(
			ai_player_id, ai_army_id, home_coord, belief_model, difficulty_profile, personality_profile, remount_ratio, _rng_seed + _decisions_made * 19)
		cmd_type = first_step.command_type
		cmd_payload = first_step.payload.duplicate()
		action_tag = first_step.step_action_id
		doc_preset_int = first_step.target_doctrine_preset
		executing_scheme = true
	elif chosen.category == GameEnums.AIActionCategory.EXECUTE_SCHEME_STEP and scheme_planner.has_active_scheme():
		executing_scheme = true

	if cmd_type.is_empty():
		cmd_type = "step_ai_commander"
		cmd_payload = {
			"agent_id": String(agent_id),
			"is_rogue_warband": false,
			"target_player_army_id": target_army_id,
			"target_depot_id": 1,
		}
		action_tag = &"step_ai_gather"

	var sender_str: String = str(ai_player_id)
	var bus_last_seq: int = CommandBus.get_last_sequence_for_sender(sender_str)
	_envelope_sequence = maxi(_envelope_sequence, bus_last_seq) + CommandBus.get_pending_envelope_count() + 1

	var env: CommandEnvelope = CommandEnvelope.new(
		_envelope_sequence,
		sender_str,
		eff_tick,
		cmd_type,
		cmd_payload)
	var accepted: bool = CommandBus.enqueue_envelope(env, eff_tick)
	_last_envelope = env
	if accepted:
		_envelopes_accepted += 1
		if auto_flush:
			CommandBus.flush_envelopes_for_tick(eff_tick)
	else:
		_envelopes_rejected += 1

	var cooldown: int = 0
	if chosen.category == GameEnums.AIActionCategory.FORTIFY_AND_SUSTAIN and chosen.sub_action_id == &"barter_steel_zud_prep":
		cooldown = 2
	elif chosen.category == GameEnums.AIActionCategory.SABOTAGE_ENEMY_WATER:
		cooldown = 2
	elif chosen.category == GameEnums.AIActionCategory.ASSIGN_COUNTER_DOCTRINE:
		cooldown = 1
	elif chosen.category == GameEnums.AIActionCategory.AMBUSH_COURIER_OR_SPY:
		cooldown = 2
	elif chosen.category == GameEnums.AIActionCategory.SPONSOR_PROXY_OR_COALITION:
		cooldown = 2
	elif chosen.category == GameEnums.AIActionCategory.RESEARCH_TRADITION:
		cooldown = 1
	belief_model.record_own_action(chosen.category, doc_preset_int, cooldown)

	var posture_tag: StringName = deception_eval.projected_posture if deception_eval != null else &"neutral"
	var eff_doc_for_tom: int = doc_preset_int
	if eff_doc_for_tom < 0:
		var live_doc: BattleDoctrineResource = CombatCalculator.get_assigned_doctrine(ai_army_id)
		if live_doc != null:
			eff_doc_for_tom = int(live_doc.preset_id)
	theory_of_mind.record_ai_visible_action(chosen.category, eff_doc_for_tom, posture_tag, difficulty_profile)
	var deception_fired: bool = deception_engine.record_executed_action(deception_eval, chosen.category, doc_preset_int, eff_tick)
	if deception_fired and deception_eval != null:
		EventBus.ai_deception_triggered.emit(
			agent_id,
			ai_player_id,
			deception_eval.recommended_vector,
			theory_of_mind.predicted_opponent_counter_doctrine,
			theory_of_mind.second_order_optimal_doctrine)

	if executing_scheme:
		var completed_now: bool = scheme_planner.advance_step(accepted, action_tag)
		EventBus.ai_scheme_step_advanced.emit(
			agent_id,
			active_scheme_type,
			step_idx_before,
			AISchemePlanner.TOTAL_STEPS,
			action_tag,
			completed_now)
		if completed_now:
			belief_model.record_own_action(GameEnums.AIActionCategory.EXECUTE_SCHEME_STEP, doc_preset_int, 2)

	_decisions_made += 1
	_last_action_category = chosen.category
	_last_action_id = action_tag
	_last_decision_score = chosen.effective_score
	if doc_preset_int >= 0 and doc_preset_int <= 4:
		_last_doctrine_preset = doc_preset_int as GameEnums.BattleDoctrinePresetId
	else:
		var cur_doc: BattleDoctrineResource = CombatCalculator.get_assigned_doctrine(ai_army_id)
		if cur_doc != null:
			_last_doctrine_preset = cur_doc.preset_id

	var doc_res: BattleDoctrineResource = DoctrinePresetCatalog.create_preset(_last_doctrine_preset)
	var sel_doc_id: StringName = doc_res.doctrine_id if doc_res != null else &"kurt_kapani"
	var diff_tier: GameEnums.AIDifficultyTier = difficulty_profile.difficulty_tier if difficulty_profile != null else GameEnums.AIDifficultyTier.SANCAK_BEYI
	EventBus.ai_utility_decision_made.emit(
		agent_id,
		ai_player_id,
		diff_tier,
		_last_action_category,
		sel_doc_id,
		_last_decision_score,
		env.sequence_id)
	return env


func export_state_dict() -> Dictionary:
	_ensure_cognitive_modules()
	return {
		"agenda_hook": agenda_hook.export_state_dict() if agenda_hook != null else {},
		"agent_id": String(agent_id),
		"ai_army_id": ai_army_id,
		"ai_player_id": ai_player_id,
		"belief_model": belief_model.export_state_dict() if belief_model != null else {},
		"deception_engine": deception_engine.export_state_dict() if deception_engine != null else {},
		"decisions_made": _decisions_made,
		"difficulty_tier": int(difficulty_profile.difficulty_tier) if difficulty_profile != null else int(GameEnums.AIDifficultyTier.SANCAK_BEYI),
		"envelope_sequence": _envelope_sequence,
		"envelopes_accepted": _envelopes_accepted,
		"envelopes_rejected": _envelopes_rejected,
		"home_coord_x": home_coord.x,
		"home_coord_y": home_coord.y,
		"last_action_category": int(_last_action_category),
		"last_action_id": String(_last_action_id),
		"last_decision_score": _last_decision_score,
		"last_doctrine_preset": int(_last_doctrine_preset),
		"personality": int(personality_profile.personality) if personality_profile != null else int(GameEnums.SteppeAIPersonality.AKINCI_BASKINCI),
		"personality_evolution": personality_evolution.export_state_dict() if personality_evolution != null else {},
		"remount_ratio": remount_ratio,
		"rng_draws": _rng_draws,
		"rng_seed": _rng_seed,
		"scheme_planner": scheme_planner.export_state_dict() if scheme_planner != null else {},
		"target_army_id": target_army_id,
		"target_coord_x": target_coord.x,
		"target_coord_y": target_coord.y,
		"target_player_id": target_player_id,
		"theory_of_mind": theory_of_mind.export_state_dict() if theory_of_mind != null else {},
	}


func import_state_dict(data: Dictionary) -> bool:
	agent_id = StringName(DeterministicStateHasher.v_str(data.get("agent_id", "karluk_ai"), "karluk_ai"))
	ai_player_id = maxi(DeterministicStateHasher.v_int(data.get("ai_player_id", 2), 2), 1)
	ai_army_id = maxi(DeterministicStateHasher.v_int(data.get("ai_army_id", 201), 201), 1)
	home_coord = Vector2i(
		DeterministicStateHasher.v_int(data.get("home_coord_x", 0), 0),
		DeterministicStateHasher.v_int(data.get("home_coord_y", 0), 0))
	target_player_id = maxi(DeterministicStateHasher.v_int(data.get("target_player_id", 1), 1), 1)
	target_army_id = maxi(DeterministicStateHasher.v_int(data.get("target_army_id", 1), 1), 1)
	target_coord = Vector2i(
		DeterministicStateHasher.v_int(data.get("target_coord_x", 0), 0),
		DeterministicStateHasher.v_int(data.get("target_coord_y", 0), 0))
	remount_ratio = clampf(DeterministicStateHasher.v_float(data.get("remount_ratio", 1.0), 1.0), 0.0, 1.0)

	var diff_int: int = clampi(DeterministicStateHasher.v_int(data.get("difficulty_tier", 1), 1), 0, 3)
	difficulty_profile = AIDifficultyProfile.create_preset(diff_int as GameEnums.AIDifficultyTier)
	var pers_int: int = clampi(DeterministicStateHasher.v_int(data.get("personality", 0), 0), 0, 3)
	personality_profile = SteppeAIPersonalityProfile.create_preset(pers_int as GameEnums.SteppeAIPersonality)

	_envelope_sequence = maxi(DeterministicStateHasher.v_int(data.get("envelope_sequence", 0), 0), 0)
	_decisions_made = maxi(DeterministicStateHasher.v_int(data.get("decisions_made", 0), 0), 0)
	_envelopes_accepted = maxi(DeterministicStateHasher.v_int(data.get("envelopes_accepted", 0), 0), 0)
	_envelopes_rejected = maxi(DeterministicStateHasher.v_int(data.get("envelopes_rejected", 0), 0), 0)
	var cat_int: int = clampi(DeterministicStateHasher.v_int(data.get("last_action_category", 0), 0), 0, 9)
	_last_action_category = cat_int as GameEnums.AIActionCategory
	_last_action_id = StringName(DeterministicStateHasher.v_str(data.get("last_action_id", "")))
	_last_decision_score = DeterministicStateHasher.v_float(data.get("last_decision_score", 0.0), 0.0)
	var doc_int: int = clampi(DeterministicStateHasher.v_int(data.get("last_doctrine_preset", 0), 0), 0, 4)
	_last_doctrine_preset = doc_int as GameEnums.BattleDoctrinePresetId

	_rng_seed = clampi(absi(DeterministicStateHasher.v_int(data.get("rng_seed", 32001), 32001)), 1, 2147483647)
	_rng_draws = maxi(DeterministicStateHasher.v_int(data.get("rng_draws", 0), 0), 0)
	_rng = RandomNumberGenerator.new()
	_rng.seed = _rng_seed
	for _i: int in range(_rng_draws):
		_rng.randf()

	if belief_model == null:
		belief_model = AIBeliefModel.new(ai_player_id, target_player_id, target_army_id)
	belief_model.import_state_dict(DeterministicStateHasher.v_dict(data.get("belief_model", {})))
	if scheme_planner == null:
		scheme_planner = AISchemePlanner.new()
	scheme_planner.import_state_dict(DeterministicStateHasher.v_dict(data.get("scheme_planner", {})))
	if agenda_hook == null:
		agenda_hook = AINarrativeAgendaHook.new()
	agenda_hook.import_state_dict(DeterministicStateHasher.v_dict(data.get("agenda_hook", {})))
	if personality_evolution == null:
		personality_evolution = AIPersonalityEvolution.new(personality_profile)
	var evo_dict: Dictionary = DeterministicStateHasher.v_dict(data.get("personality_evolution", {}))
	if not evo_dict.is_empty():
		personality_evolution.import_state_dict(evo_dict)
	else:
		personality_evolution.apply_base_profile(personality_profile)
		personality_evolution.reset()
	_evolution_synced_with_base = true
	if theory_of_mind == null:
		theory_of_mind = AITheoryOfMindModel.new()
	var tom_dict: Dictionary = DeterministicStateHasher.v_dict(data.get("theory_of_mind", {}))
	if not tom_dict.is_empty():
		theory_of_mind.import_state_dict(tom_dict)
	else:
		theory_of_mind.reset()
	if deception_engine == null:
		deception_engine = AIDeceptionEngine.new()
	var dec_dict: Dictionary = DeterministicStateHasher.v_dict(data.get("deception_engine", {}))
	if not dec_dict.is_empty():
		deception_engine.import_state_dict(dec_dict)
	else:
		deception_engine.reset()
	return true


static func export_all_state_dict() -> Dictionary:
	var agents_dict: Dictionary = {}
	var keys: Array[int] = _registered_agents.keys()
	keys.sort()
	for pid: int in keys:
		var ctrl: SteppeStrategicAIController = _registered_agents.get(pid, null)
		if ctrl != null:
			agents_dict[str(pid)] = ctrl.export_state_dict()
	return {
		"agents": agents_dict,
	}


static func import_all_state_dict(data: Dictionary) -> bool:
	if not (data.get("agents") is Dictionary):
		return false
	var agents_data: Dictionary = DeterministicStateHasher.v_dict(data.get("agents", {}))
	var existing: Dictionary[int, SteppeStrategicAIController] = _registered_agents.duplicate()
	_registered_agents.clear()
	var keys: Array = agents_data.keys()
	keys.sort_custom(func(a: Variant, b: Variant) -> bool:
		return DeterministicStateHasher.v_str(a) < DeterministicStateHasher.v_str(b)
	)
	for k: Variant in keys:
		var k_str: String = DeterministicStateHasher.v_str(k)
		var pid: int = k_str.to_int()
		var sub: Dictionary = DeterministicStateHasher.v_dict(agents_data[k])
		var ctrl: SteppeStrategicAIController = existing.get(pid, null)
		if ctrl == null:
			ctrl = SteppeStrategicAIController.new()
		ctrl.import_state_dict(sub)
		register_ai_agent(ctrl)
	return true
