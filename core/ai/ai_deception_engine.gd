class_name AIDeceptionEngine
extends RefCounted
## Core psychological deception evaluator (rank 2, level 2B).
## Evaluates 3 zero-cheat psychological vectors using public observations,
## 2nd-order Theory of Mind, living personality evolution, and systemic
## Kara Borsa (tanh) & Zud tension:
##   1. FALSE_WEAKNESS_KURT_KAPANI (Sahte Zayıflık / Toz Perdesi + Kurt Kapanı)
##   2. ECONOMIC_CHOKE_SABOTAGE (Zud Öncesi Kuyu + Kervan + Kara Borsa Boğması)
##   3. OPPORTUNISTIC_COALITION_BETRAYAL (Dehşet/Ülüş Krizinde Vekalet & İhanet)


class DeceptionEvaluation:
	extends RefCounted
	var recommended_vector: GameEnums.AIDeceptionVector = GameEnums.AIDeceptionVector.NONE
	var vector_scores: Dictionary[int, float] = {}
	var category_bonuses: Dictionary[int, float] = {}
	var preferred_doctrine: int = -1
	var preferred_scheme: GameEnums.AISchemeType = GameEnums.AISchemeType.NONE
	var scheme_bonus: float = 0.0
	var black_market_pressure_index: float = 0.0
	var projected_posture: StringName = &"neutral"
	var lure_stage_active: bool = false
	var wants_pact_betrayal: bool = false
	var rationale: String = ""


var last_vector: GameEnums.AIDeceptionVector = GameEnums.AIDeceptionVector.NONE
var lure_primed: bool = false
var lure_armed_tick: int = -1
var deceptions_triggered: int = 0


func reset() -> void:
	last_vector = GameEnums.AIDeceptionVector.NONE
	lure_primed = false
	lure_armed_tick = -1
	deceptions_triggered = 0


func evaluate_vectors(
		ai_pid: int,
		ai_army_id: int,
		target_pid: int,
		target_army_id: int,
		target_coord: Vector2i,
		belief: AIBeliefModel,
		tom: AITheoryOfMindModel,
		evolution: AIPersonalityEvolution,
		diff: AIDifficultyProfile,
		personality: SteppeAIPersonalityProfile,
		stress_dir: AIPersonalityEvolution.StressDirective = null) -> DeceptionEvaluation:
	var eval: DeceptionEvaluation = DeceptionEvaluation.new()
	if belief == null:
		return eval

	var cur_season: SeasonData = SeasonManager.get_current_season()
	var s_type: GameEnums.SeasonType = cur_season.season_type if cur_season != null else GameEnums.SeasonType.SPRING
	var is_pre_zud_or_winter: bool = s_type == GameEnums.SeasonType.AUTUMN or s_type == GameEnums.SeasonType.WINTER or BallisticsEngine.is_pre_zud_storm_active()
	var raid_allowed: bool = GracePeriodManager.can_perform_action(ai_pid, GameEnums.ToreActionType.BORDER_NODE_RAID, target_pid)

	var dec_w: float = evolution.evolved_deception if evolution != null else (personality.deception_weight if personality != null else 1.0)
	var sab_w: float = evolution.evolved_sabotage if evolution != null else (personality.sabotage_weight if personality != null else 1.0)
	var dip_w: float = evolution.evolved_diplomacy if evolution != null else (personality.diplomacy_weight if personality != null else 1.0)
	var vendetta_mult: float = evolution.get_vendetta_multiplier(target_pid) if evolution != null else 1.0
	var plan_w: float = diff.scheme_planning_weight if diff != null else 0.55
	var zud_w: float = diff.foresight_zud_horizon_weight if diff != null else 0.65
	var tom_depth: float = tom.get_tier_tom_depth_weight(diff) if tom != null else 0.25
	var gambit_boost: float = 16.0 if (stress_dir != null and stress_dir.in_cold_gambit_mode) else 0.0

	# Vector 1: False Weakness & Kurt Kapanı Lure
	var dust_active: bool = CourierDispatchSystem.has_dust_decoy(ai_army_id)
	var v1_score: float = 12.0 * dec_w * (0.50 + 0.50 * plan_w)
	if not dust_active:
		v1_score += 20.0 * dec_w
	else:
		v1_score += 24.0 * dec_w
	if belief.is_observed_enemy_overextended():
		v1_score += 18.0
	if tom != null and (tom.predicted_opponent_counter_doctrine == int(GameEnums.BattleDoctrinePresetId.BORU_KAMASI) \
			or tom.predicted_opponent_counter_doctrine == int(GameEnums.BattleDoctrinePresetId.TOLGAMA_KISKACI)):
		v1_score += 22.0 * tom_depth
	v1_score += gambit_boost

	# Vector 2: Economic Choke (Pre-Zud Well Sabotage + Caravan Interdiction + Kara Borsa tanh Scarcity)
	var target_syn: SynergyEvaluationSnapshot = SystemicSynergyMatrix.evaluate_player(target_pid, target_army_id, target_coord, false)
	var bm_mult: float = target_syn.black_market_scarcity_mult if target_syn != null else 1.0
	var reg_scarcity: float = RegionalMarketEngine.get_regional_scarcity(target_coord, &"food")
	eval.black_market_pressure_index = maxf(bm_mult, reg_scarcity)
	var usable_target_wells: int = WaterRouteManager.count_usable_water_sources(target_coord, s_type, s_type == GameEnums.SeasonType.WINTER)
	var target_caravans: int = belief.get_observed_enemy_caravan_ids().size()
	var v2_score: float = 10.0 * sab_w * vendetta_mult
	if is_pre_zud_or_winter:
		v2_score += 24.0 * zud_w
	if usable_target_wells > 0 and raid_allowed:
		v2_score += 22.0 * sab_w
	if target_caravans > 0:
		v2_score += 20.0 * sab_w
	if eval.black_market_pressure_index >= 1.25:
		v2_score += minf((eval.black_market_pressure_index - 1.0) * 26.0, 28.0)

	# Vector 3: Opportunistic Coalition & Betrayal (Dread / Ülüş / Regency Crisis / High Vendetta)
	var opp_dread: float = belief.get_observed_enemy_dread()
	var ulus_strained: bool = belief.is_observed_enemy_ulus_strained()
	var reg_crisis: bool = belief.get_observed_enemy_regency() != GameEnums.RegencyStatus.STABLE_RULE
	var has_pact_with_target: bool = false
	for pr: AmanatPactRecord in ReputationAndPactSystem.get_active_pacts_for_player(ai_pid):
		if pr != null and (pr.party_a == target_pid or pr.party_b == target_pid):
			has_pact_with_target = true
			break
	var vendetta_raw: float = evolution.get_vendetta_score(target_pid) if evolution != null else 0.0
	var v3_score: float = 8.0 * (2.0 - clampf(dip_w, 0.4, 1.5)) * vendetta_mult
	if opp_dread >= 45.0:
		v3_score += 22.0 + minf((opp_dread - 45.0) * 0.45, 22.0)
	if ulus_strained:
		v3_score += 20.0
	if reg_crisis:
		v3_score += 22.0
	if has_pact_with_target and (opp_dread >= 55.0 or vendetta_raw >= 35.0):
		v3_score += 44.0
	if vendetta_raw >= 25.0:
		v3_score += minf(vendetta_raw * 0.55, 34.0)

	# Suppress low-difficulty deception sharpness naturally
	if diff != null and diff.difficulty_tier == GameEnums.AIDifficultyTier.OYMAK_BEYI:
		v1_score *= 0.45
		v2_score *= 0.55
		v3_score *= 0.55

	eval.vector_scores = {
		int(GameEnums.AIDeceptionVector.FALSE_WEAKNESS_KURT_KAPANI): v1_score,
		int(GameEnums.AIDeceptionVector.ECONOMIC_CHOKE_SABOTAGE): v2_score,
		int(GameEnums.AIDeceptionVector.OPPORTUNISTIC_COALITION_BETRAYAL): v3_score,
	}

	var best_vec: GameEnums.AIDeceptionVector = GameEnums.AIDeceptionVector.FALSE_WEAKNESS_KURT_KAPANI
	var best_sc: float = v1_score
	if v2_score > best_sc:
		best_sc = v2_score
		best_vec = GameEnums.AIDeceptionVector.ECONOMIC_CHOKE_SABOTAGE
	if v3_score > best_sc:
		best_sc = v3_score
		best_vec = GameEnums.AIDeceptionVector.OPPORTUNISTIC_COALITION_BETRAYAL
	if best_sc < 20.0:
		eval.recommended_vector = GameEnums.AIDeceptionVector.NONE
		return eval

	eval.recommended_vector = best_vec
	match best_vec:
		GameEnums.AIDeceptionVector.FALSE_WEAKNESS_KURT_KAPANI:
			eval.projected_posture = &"dust_feigned_weakness"
			eval.preferred_scheme = GameEnums.AISchemeType.DUST_VEIL_COURIER_AMBUSH
			eval.scheme_bonus = 18.0
			if not dust_active:
				eval.category_bonuses[int(GameEnums.AIActionCategory.RAISE_DUST_DECEPTION)] = 22.0 * dec_w
			else:
				eval.lure_stage_active = true
				eval.preferred_doctrine = int(GameEnums.BattleDoctrinePresetId.KURT_KAPANI)
				eval.category_bonuses[int(GameEnums.AIActionCategory.ASSIGN_COUNTER_DOCTRINE)] = 20.0 * dec_w
			eval.rationale = "Toz Perdesi ile sahte zayıflık gösterip Kurt Kapanı'na çekme"
		GameEnums.AIDeceptionVector.ECONOMIC_CHOKE_SABOTAGE:
			eval.projected_posture = &"economic_stranglehold"
			eval.preferred_scheme = GameEnums.AISchemeType.POISONED_WINTER_TRAP
			eval.scheme_bonus = 20.0
			eval.category_bonuses[int(GameEnums.AIActionCategory.SABOTAGE_ENEMY_WATER)] = 24.0 * sab_w
			eval.category_bonuses[int(GameEnums.AIActionCategory.INTERCEPT_CARAVAN_OR_INTERDICT)] = 20.0 * sab_w
			eval.preferred_doctrine = int(GameEnums.BattleDoctrinePresetId.TONYUKUK_YIPRATMASI)
			eval.rationale = "Zud öncesi kuyu + kervan + Kara Borsa kıtlık boğması"
		GameEnums.AIDeceptionVector.OPPORTUNISTIC_COALITION_BETRAYAL:
			eval.projected_posture = &"opportunistic_predator"
			eval.preferred_scheme = GameEnums.AISchemeType.OPPORTUNISTIC_CRISIS_STRIKE
			eval.scheme_bonus = 22.0
			eval.category_bonuses[int(GameEnums.AIActionCategory.SPONSOR_PROXY_OR_COALITION)] = 26.0 * vendetta_mult
			if has_pact_with_target and (opp_dread >= 55.0 or vendetta_raw >= 35.0):
				eval.wants_pact_betrayal = true
			eval.rationale = "Rakip Dehşet/Ülüş krizinde antlaşma bozup vekalet & baskın başlat"
	return eval


func record_executed_action(
		eval: DeceptionEvaluation,
		chosen_category: GameEnums.AIActionCategory,
		chosen_doctrine: int,
		tick: int) -> bool:
	if eval == null or eval.recommended_vector == GameEnums.AIDeceptionVector.NONE:
		return false
	last_vector = eval.recommended_vector
	if chosen_category == GameEnums.AIActionCategory.RAISE_DUST_DECEPTION:
		lure_primed = true
		lure_armed_tick = tick
	elif lure_primed and chosen_doctrine == int(GameEnums.BattleDoctrinePresetId.KURT_KAPANI):
		lure_primed = false
	var aligned: bool = chosen_category == GameEnums.AIActionCategory.RAISE_DUST_DECEPTION \
		or chosen_category == GameEnums.AIActionCategory.SABOTAGE_ENEMY_WATER \
		or chosen_category == GameEnums.AIActionCategory.INTERCEPT_CARAVAN_OR_INTERDICT \
		or chosen_category == GameEnums.AIActionCategory.SPONSOR_PROXY_OR_COALITION \
		or chosen_category == GameEnums.AIActionCategory.EXECUTE_SCHEME_STEP \
		or (eval.lure_stage_active and chosen_category == GameEnums.AIActionCategory.ASSIGN_COUNTER_DOCTRINE)
	if aligned:
		deceptions_triggered += 1
	return aligned


func export_state_dict() -> Dictionary:
	return {
		"deceptions_triggered": deceptions_triggered,
		"last_vector": int(last_vector),
		"lure_armed_tick": lure_armed_tick,
		"lure_primed": lure_primed,
	}


func import_state_dict(data: Dictionary) -> bool:
	var lv: int = clampi(DeterministicStateHasher.v_int(data.get("last_vector", 0), 0), 0, 3)
	last_vector = lv as GameEnums.AIDeceptionVector
	lure_primed = DeterministicStateHasher.v_bool(data.get("lure_primed", false), false)
	lure_armed_tick = DeterministicStateHasher.v_int(data.get("lure_armed_tick", -1), -1)
	deceptions_triggered = maxi(DeterministicStateHasher.v_int(data.get("deceptions_triggered", 0), 0), 0)
	return true
