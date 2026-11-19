class_name AIUtilityEvaluator
extends RefCounted
## Core Utility AI Scorer (rank 2). Scores all strategic, economic, sabotage,
## intelligence, synergy, and battle doctrine actions using closed-form
## SystemSynergy/DoctrineMatchup evaluations, bounded-rationality decision
## temperature, personality weights, and optional story narrative injections.
## Uses ZERO global randf() — accepts an explicit seeded RandomNumberGenerator.

class AIActionCandidate:
	extends RefCounted
	var category: GameEnums.AIActionCategory = GameEnums.AIActionCategory.HOLD_AND_GATHER
	var sub_action_id: StringName = &""
	var command_type: String = ""
	var payload: Dictionary = {}
	var doctrine_preset: int = -1
	var scheme_to_start: GameEnums.AISchemeType = GameEnums.AISchemeType.NONE
	var base_score: float = 0.0
	var effective_score: float = 0.0
	var rationale: String = ""


class EvaluationOutcome:
	extends RefCounted
	var chosen: AIActionCandidate = null
	var candidates: Array[AIActionCandidate] = []
	var recommended_doctrine: GameEnums.BattleDoctrinePresetId = GameEnums.BattleDoctrinePresetId.KURT_KAPANI
	var doctrine_scores: Dictionary[int, float] = {}
	var draws_consumed: int = 0
	var predicted_enemy_doctrine: int = -1


static func evaluate_doctrine_utilities(
		ai_pid: int,
		ai_army_id: int,
		ai_home_coord: Vector2i,
		belief: AIBeliefModel,
		difficulty: AIDifficultyProfile,
		personality: SteppeAIPersonalityProfile,
		narrative: AINarrativeAgendaHook.NarrativeWeightDirective) -> Dictionary[int, float]:
	var scores: Dictionary[int, float] = {}
	var trap_aware: float = difficulty.terrain_trap_awareness if difficulty != null else 0.60
	var counter_w: float = personality.doctrine_counter_weight if personality != null else 1.0
	var syn_w: float = difficulty.synergy_pursuit_weight if difficulty != null else 0.55

	var cur_season: SeasonData = SeasonManager.get_current_season()
	var s_type: GameEnums.SeasonType = cur_season.season_type if cur_season != null else GameEnums.SeasonType.SPRING
	var is_winter: bool = s_type == GameEnums.SeasonType.WINTER
	var is_storm: bool = BallisticsEngine.is_pre_zud_storm_active()
	var target_coord: Vector2i = belief.get_observed_target_region_coord()
	var target_reg: RegionData = TerritoryManager.get_region(target_coord)
	var is_slope: bool = target_reg != null and target_reg.geography_class == GameEnums.RegionGeographyClass.HIGH_PLATEAU_YAYLAK and is_winter
	var is_mud: bool = is_storm and s_type == GameEnums.SeasonType.AUTUMN

	# Hypothetical combatant stats grounded solely in AI's own assets & belief
	var ai_riders: int = maxi(CommandBus.get_army_rider_count(ai_army_id), 120)
	var atk_stats: CombatantStats = CombatantStats.new(ai_army_id, 210.0, 130.0, float(ai_riders) * 10.0, 1.0)
	atk_stats.player_id = ai_pid
	atk_stats.army_id = ai_army_id
	atk_stats.region_coord = ai_home_coord
	atk_stats.troop_count = ai_riders

	var perceived_pow: float = belief.get_perceived_enemy_power()
	var est_def_troops: int = clampi(roundi(perceived_pow * 0.14), 40, 260)
	var def_stats: CombatantStats = CombatantStats.new(1, 210.0, 130.0, perceived_pow, 1.0)
	def_stats.player_id = belief.get_target_player_id()
	def_stats.army_id = belief.get_target_army_id()
	def_stats.region_coord = target_coord
	def_stats.troop_count = est_def_troops

	var pred_enemy: int = belief.get_predicted_enemy_doctrine()
	var believed_enemy_doc: BattleDoctrineResource = null
	if belief.is_enemy_doctrine_known() and pred_enemy >= 0:
		believed_enemy_doc = DoctrinePresetCatalog.create_preset(pred_enemy as GameEnums.BattleDoctrinePresetId)

	var ai_syn: SynergyEvaluationSnapshot = SystemicSynergyMatrix.evaluate_player(
		ai_pid, ai_army_id, ai_home_coord, false, ai_riders)
	var hazard_cnt: int = int(is_mud) + int(is_slope) + int(is_storm)

	for p_enum: GameEnums.BattleDoctrinePresetId in DoctrinePresetCatalog.get_all_preset_ids():
		var cand_doc: BattleDoctrineResource = DoctrinePresetCatalog.create_preset(p_enum)
		var matchup: DoctrineMatchupResult = DoctrineMatchupResolver.evaluate(
			atk_stats, def_stats, cand_doc, believed_enemy_doc,
			null, cur_season, GameEnums.CombatEngagementAngle.FRONT,
			is_mud, is_slope, is_storm, target_coord)

		var expected_power: float = matchup.attacker_attack_multiplier / maxf(matchup.defender_defense_multiplier, 0.35)
		var sc: float = expected_power * 42.0 * counter_w
		if matchup.wedge_pierced_thin_center:
			sc += 28.0 * counter_w
		if matchup.feigned_retreat_lure_succeeded:
			sc += 24.0 * counter_w
		if matchup.tonyukuk_attrition_triggered:
			sc += 26.0 * counter_w
		if matchup.heavy_armor_terrain_collapse:
			sc -= 38.0 * trap_aware
		elif cand_doc.is_heavy_armor_doctrine and hazard_cnt >= 2:
			sc -= 32.0 * trap_aware

		if believed_enemy_doc != null and believed_enemy_doc.decisive_maneuver == GameEnums.DecisiveManeuver.KURT_KAPANI_FEIGNED_RETREAT:
			if p_enum == GameEnums.BattleDoctrinePresetId.ARABA_KALESI:
				sc += 22.0 * counter_w
		if believed_enemy_doc != null and believed_enemy_doc.decisive_maneuver == GameEnums.DecisiveManeuver.BORU_HEAVY_WEDGE:
			if p_enum == GameEnums.BattleDoctrinePresetId.KURT_KAPANI:
				sc += 20.0 * counter_w
		if believed_enemy_doc != null and believed_enemy_doc.decisive_maneuver == GameEnums.DecisiveManeuver.TOLGAMA_DOUBLE_ENVELOPMENT:
			if p_enum == GameEnums.BattleDoctrinePresetId.BORU_KAMASI and hazard_cnt < 2:
				sc += 24.0 * counter_w

		# Synergy pursuit alignment
		if ai_syn != null:
			if p_enum == GameEnums.BattleDoctrinePresetId.BORU_KAMASI and ai_syn.has_resonance(GameEnums.SynergyResonanceId.ARTISAN_BORU_SPEARHEAD):
				sc += 18.0 * syn_w
			if p_enum == GameEnums.BattleDoctrinePresetId.TOLGAMA_KISKACI and CourierDispatchSystem.has_dust_decoy(ai_army_id) and ReputationAndPactSystem.get_dread_score(ai_pid) >= 40.0:
				sc += 18.0 * syn_w

		# Personality & Story agenda doctrine bias
		if personality != null and personality.preferred_doctrine == p_enum:
			sc += 8.0
		if narrative != null and narrative.has_active_agenda and narrative.priority_doctrine == int(p_enum):
			sc += 35.0

		scores[int(p_enum)] = clampf(sc, 1.0, 220.0)
	return scores


static func evaluate_candidates(
		agent_id: StringName,
		ai_pid: int,
		ai_army_id: int,
		ai_home_coord: Vector2i,
		target_pid: int,
		target_army_id: int,
		belief: AIBeliefModel,
		scheme_planner: AISchemePlanner,
		difficulty: AIDifficultyProfile,
		personality: SteppeAIPersonalityProfile,
		narrative: AINarrativeAgendaHook.NarrativeWeightDirective,
		ai_remount_ratio: float,
		rng: RandomNumberGenerator,
		seed_bump: int = 1) -> EvaluationOutcome:
	var out: EvaluationOutcome = EvaluationOutcome.new()
	var cur_season: SeasonData = SeasonManager.get_current_season()
	var s_type: GameEnums.SeasonType = cur_season.season_type if cur_season != null else GameEnums.SeasonType.SPRING
	var is_winter: bool = s_type == GameEnums.SeasonType.WINTER
	var is_autumn: bool = s_type == GameEnums.SeasonType.AUTUMN
	var target_coord: Vector2i = belief.get_observed_target_region_coord()

	var diff: AIDifficultyProfile = difficulty if difficulty != null else AIDifficultyProfile.create_preset(GameEnums.AIDifficultyTier.SANCAK_BEYI)
	var pers: SteppeAIPersonalityProfile = personality if personality != null else SteppeAIPersonalityProfile.create_preset(GameEnums.SteppeAIPersonality.AKINCI_BASKINCI)

	# 1. Score Doctrines
	var doc_scores: Dictionary[int, float] = evaluate_doctrine_utilities(
		ai_pid, ai_army_id, ai_home_coord, belief, diff, pers, narrative)
	out.doctrine_scores = doc_scores
	out.predicted_enemy_doctrine = belief.get_predicted_enemy_doctrine()

	var best_doc_int: int = int(pers.preferred_doctrine)
	var best_doc_score: float = -1.0
	for p_int: int in doc_scores:
		var ds: float = doc_scores[p_int]
		if ds > best_doc_score:
			best_doc_score = ds
			best_doc_int = p_int
	out.recommended_doctrine = best_doc_int as GameEnums.BattleDoctrinePresetId

	var current_doc: BattleDoctrineResource = CombatCalculator.get_assigned_doctrine(ai_army_id)
	var current_doc_int: int = int(current_doc.preset_id) if current_doc != null else -1

	var ai_syn: SynergyEvaluationSnapshot = SystemicSynergyMatrix.evaluate_player(ai_pid, ai_army_id, ai_home_coord, false)
	var ai_silver: int = ResourceManager.get_amount(ai_pid, &"silver_gold")
	var ai_iron: int = ResourceManager.get_amount(ai_pid, &"iron")
	var ai_steel: int = ResourceManager.get_amount(ai_pid, &"steel")
	var market_mult: float = RegionalMarketEngine.get_regional_scarcity(ai_home_coord, &"steel")
	var raid_allowed: bool = GracePeriodManager.can_perform_action(ai_pid, GameEnums.ToreActionType.BORDER_NODE_RAID, target_pid)

	# 2A. Active Scheme Step OR Starting a New Multi-Step Scheme
	if scheme_planner != null and scheme_planner.has_active_scheme():
		var step_intent: AISchemePlanner.SchemeStepIntent = scheme_planner.build_next_step_intent(
			ai_pid, ai_army_id, ai_home_coord, belief, diff, pers, ai_remount_ratio, seed_bump)
		if not step_intent.command_type.is_empty():
			var c_scheme: AIActionCandidate = AIActionCandidate.new()
			c_scheme.category = GameEnums.AIActionCategory.EXECUTE_SCHEME_STEP
			c_scheme.sub_action_id = step_intent.step_action_id
			c_scheme.command_type = step_intent.command_type
			c_scheme.payload = step_intent.payload
			c_scheme.doctrine_preset = step_intent.target_doctrine_preset
			c_scheme.base_score = 135.0 * clampf(diff.scheme_planning_weight, 0.55, 1.50)
			if narrative != null and narrative.has_active_agenda and narrative.preferred_scheme == scheme_planner.get_active_scheme():
				c_scheme.base_score += narrative.scheme_bonus
			c_scheme.rationale = step_intent.description
			out.candidates.append(c_scheme)
	elif scheme_planner != null and belief.get_action_cooldown(GameEnums.AIActionCategory.EXECUTE_SCHEME_STEP) <= 0:
		var best_scheme: GameEnums.AISchemeType = GameEnums.AISchemeType.NONE
		var best_scheme_sc: float = 0.0
		var scheme_list: Array[GameEnums.AISchemeType] = [
			GameEnums.AISchemeType.POISONED_WINTER_TRAP,
			GameEnums.AISchemeType.DUST_VEIL_COURIER_AMBUSH,
			GameEnums.AISchemeType.OPPORTUNISTIC_CRISIS_STRIKE,
		]
		for sc_type: GameEnums.AISchemeType in scheme_list:
			var sc_val: float = scheme_planner.score_scheme_viability(
				sc_type, ai_pid, ai_army_id, target_pid, target_coord, belief, pers, diff, narrative)
			if sc_val > best_scheme_sc:
				best_scheme_sc = sc_val
				best_scheme = sc_type
		if best_scheme != GameEnums.AISchemeType.NONE and best_scheme_sc >= 28.0:
			var c_start: AIActionCandidate = AIActionCandidate.new()
			c_start.category = GameEnums.AIActionCategory.EXECUTE_SCHEME_STEP
			c_start.scheme_to_start = best_scheme
			c_start.sub_action_id = &"start_scheme"
			c_start.base_score = best_scheme_sc
			c_start.rationale = "Çok adımlı sinsilik planı başlat (%d)" % int(best_scheme)
			out.candidates.append(c_start)

	# 2B. Restore own sabotaged wells / Zud economic buffer
	var own_sabotaged_wells: int = WaterRouteManager.count_sabotaged_water_sources(ai_home_coord)
	if own_sabotaged_wells > 0 and ResourceManager.get_amount(ai_pid, &"stone") >= 10:
		var c_fix: AIActionCandidate = AIActionCandidate.new()
		c_fix.category = GameEnums.AIActionCategory.FORTIFY_AND_SUSTAIN
		c_fix.sub_action_id = &"restore_own_water"
		c_fix.command_type = "restore_water_source"
		c_fix.payload = {"player_id": ai_pid, "region_x": ai_home_coord.x, "region_y": ai_home_coord.y, "source_id": ""}
		c_fix.base_score = 220.0 * pers.economy_weight
		c_fix.rationale = "Sabote edilen kendi su kuyularını onar"
		out.candidates.append(c_fix)
	elif (is_autumn or is_winter or market_mult >= 1.45) and ai_silver >= 60 and ai_steel < 30 and belief.get_action_cooldown(GameEnums.AIActionCategory.FORTIFY_AND_SUSTAIN) <= 0:
		var zud_prep_bonus: float = 28.0 if (is_autumn or is_winter) else 10.0
		var c_trade: AIActionCandidate = AIActionCandidate.new()
		c_trade.category = GameEnums.AIActionCategory.FORTIFY_AND_SUSTAIN
		c_trade.sub_action_id = &"barter_steel_zud_prep"
		c_trade.command_type = "execute_barter_trade"
		c_trade.payload = {
			"player_id": ai_pid,
			"region_x": ai_home_coord.x,
			"region_y": ai_home_coord.y,
			"commodity_id": "steel",
			"direction": int(GameEnums.BarterDirection.BUY_FROM_MARKET),
			"quantity": 1,
			"use_black_market": false,
		}
		c_trade.base_score = (26.0 + zud_prep_bonus * diff.foresight_zud_horizon_weight) * pers.economy_weight
		c_trade.rationale = "Zud/kıtlık öncesi pazardan çelik rezervi al"
		out.candidates.append(c_trade)

	# 2C. Assign Counter Doctrine when opponent doctrine known or better matchup exists
	if current_doc_int != best_doc_int and belief.get_action_cooldown(GameEnums.AIActionCategory.ASSIGN_COUNTER_DOCTRINE) <= 0:
		var conf_boost: float = 34.0 * belief.get_doctrine_confidence() * diff.adaptation_learning_rate
		var syn_boost: float = 16.0 * diff.synergy_pursuit_weight if (ai_syn != null and ai_syn.get_resonance_count() > 0) else 0.0
		var c_doc: AIActionCandidate = AIActionCandidate.new()
		c_doc.category = GameEnums.AIActionCategory.ASSIGN_COUNTER_DOCTRINE
		c_doc.sub_action_id = &"assign_counter_doctrine"
		c_doc.doctrine_preset = best_doc_int
		c_doc.command_type = "assign_battle_doctrine"
		c_doc.payload = {
			"player_id": ai_pid,
			"army_id": ai_army_id,
			"preset_id": best_doc_int,
			"sync_offline_contingency": true,
		}
		c_doc.base_score = (32.0 + conf_boost + syn_boost + clampf(best_doc_score * 0.25, 0.0, 28.0)) * pers.doctrine_counter_weight
		c_doc.rationale = "Rakip alışkanlığı ve araziye karşı doktrin adaptasyonu"
		out.candidates.append(c_doc)

	# 2D. Raise Dust Screen (Toz Perdesi)
	if not CourierDispatchSystem.has_dust_decoy(ai_army_id) and ai_remount_ratio >= 0.25 and belief.get_action_cooldown(GameEnums.AIActionCategory.RAISE_DUST_DECEPTION) <= 0:
		var mirage_synergy: float = 24.0 if ReputationAndPactSystem.get_dread_score(ai_pid) >= 40.0 else 10.0
		var c_dust: AIActionCandidate = AIActionCandidate.new()
		c_dust.category = GameEnums.AIActionCategory.RAISE_DUST_DECEPTION
		c_dust.sub_action_id = &"raise_dust_decoy"
		c_dust.command_type = "toggle_dust_screen"
		c_dust.payload = {"army_id": ai_army_id, "player_id": ai_pid, "enable": true, "remount_horse_ratio": ai_remount_ratio}
		c_dust.base_score = (24.0 + mirage_synergy * diff.synergy_pursuit_weight) * pers.deception_weight
		c_dust.rationale = "Yılkı Toz Perdesi ile sahte ordu yoğunluğu oluştur"
		out.candidates.append(c_dust)

	# 2E. Water Sabotage
	var target_usable_wells: int = WaterRouteManager.count_usable_water_sources(target_coord, s_type, is_winter)
	if target_usable_wells > 0 and raid_allowed and belief.get_action_cooldown(GameEnums.AIActionCategory.SABOTAGE_ENEMY_WATER) <= 0:
		var winter_mult: float = 1.45 if (is_winter or is_autumn) else 1.0
		var c_sab: AIActionCandidate = AIActionCandidate.new()
		c_sab.category = GameEnums.AIActionCategory.SABOTAGE_ENEMY_WATER
		c_sab.sub_action_id = &"sabotage_target_well"
		c_sab.command_type = "sabotage_well"
		c_sab.payload = {"saboteur_id": ai_pid, "region_x": target_coord.x, "region_y": target_coord.y, "source_id": "", "duration_seasons": 3}
		c_sab.base_score = (36.0 * winter_mult * diff.foresight_zud_horizon_weight) * pers.sabotage_weight
		c_sab.rationale = "Su kuyularını sabote ederek ikmali ve Kara Borsa'yı sıkıştır"
		out.candidates.append(c_sab)

	# 2F. Ambush Courier OR Dispatch Spy
	var visible_couriers: PackedStringArray = belief.get_observed_enemy_courier_ids()
	if not visible_couriers.is_empty():
		var c_amb: AIActionCandidate = AIActionCandidate.new()
		c_amb.category = GameEnums.AIActionCategory.AMBUSH_COURIER_OR_SPY
		c_amb.sub_action_id = &"ambush_enemy_courier"
		c_amb.command_type = "ambush_courier"
		c_amb.payload = {"order_id": visible_couriers[0], "ambusher_faction_id": ai_pid}
		c_amb.base_score = 52.0 * pers.deception_weight * (0.75 + 0.25 * diff.scheme_planning_weight)
		c_amb.rationale = "Yoldaki düşman ulağını pusuya düşür ve planı deşifre et"
		out.candidates.append(c_amb)
	elif not belief.is_enemy_plan_exposed() and belief.get_action_cooldown(GameEnums.AIActionCategory.AMBUSH_COURIER_OR_SPY) <= 0:
		var c_spy: AIActionCandidate = AIActionCandidate.new()
		c_spy.category = GameEnums.AIActionCategory.AMBUSH_COURIER_OR_SPY
		c_spy.sub_action_id = &"dispatch_spy_agent"
		c_spy.command_type = "dispatch_spy"
		c_spy.payload = {
			"spy_owner_id": ai_pid,
			"target_faction_id": target_pid,
			"target_army_id": target_army_id,
			"commander_leadership": 68.0,
			"terrain_path": "res://data/terrain/steppe.tres",
			"target_quiver_ammo": 60.0,
			"target_tactic_intent": int(GameEnums.TuranTacticPhase.FEIGNED_RETREAT_LURE),
			"target_doctrine_type": int(GameEnums.TacticalDoctrineType.FEIGNED_RETREAT),
			"counter_espionage": 0.12,
			"rng_seed": maxi(absi(seed_bump + ai_pid * 31), 1),
		}
		c_spy.base_score = (28.0 + 14.0 * diff.adaptation_learning_rate) * pers.deception_weight
		c_spy.rationale = "Gizli doktrin niyetini öğrenmek için casus sızdır"
		out.candidates.append(c_spy)

	# 2G. Intercept Caravan OR Interdict Supply Line
	var visible_caravans: PackedStringArray = belief.get_observed_enemy_caravan_ids()
	if not visible_caravans.is_empty() and raid_allowed:
		var c_car: AIActionCandidate = AIActionCandidate.new()
		c_car.category = GameEnums.AIActionCategory.INTERCEPT_CARAVAN_OR_INTERDICT
		c_car.sub_action_id = &"intercept_enemy_caravan"
		c_car.command_type = "intercept_caravan"
		c_car.payload = {"caravan_id": visible_caravans[0], "raider_id": ai_pid}
		c_car.base_score = 54.0 * pers.aggression_weight
		c_car.rationale = "Yoldaki düşman kervanını vur ve ikmal şoku yarat"
		out.candidates.append(c_car)
	elif raid_allowed and belief.get_action_cooldown(GameEnums.AIActionCategory.INTERCEPT_CARAVAN_OR_INTERDICT) <= 0:
		var c_int: AIActionCandidate = AIActionCandidate.new()
		c_int.category = GameEnums.AIActionCategory.INTERCEPT_CARAVAN_OR_INTERDICT
		c_int.sub_action_id = &"interdict_supply_corridor"
		c_int.command_type = "interdict_supply_line"
		c_int.payload = {"raider_player_id": ai_pid, "target_army_id": target_army_id, "depot_id": 1, "raider_id": String(agent_id)}
		c_int.base_score = (29.0 + (15.0 if belief.is_suspected_dust_mirage() and diff.difficulty_tier == GameEnums.AIDifficultyTier.OYMAK_BEYI else 0.0)) * pers.aggression_weight
		c_int.rationale = "Cephe ikmal hattını kes"
		out.candidates.append(c_int)

	# 2H. Covert Proxy War / Coalition Evaluation
	var has_sab_target: bool = WaterRouteManager.count_sabotaged_water_sources(target_coord) > 0
	if ai_silver >= 45 and not ReputationAndPactSystem.has_active_proxy_war_by(ai_pid) and belief.get_action_cooldown(GameEnums.AIActionCategory.SPONSOR_PROXY_OR_COALITION) <= 0:
		var shadow_famine_bonus: float = 34.0 * diff.synergy_pursuit_weight if has_sab_target else 8.0
		var c_proxy: AIActionCandidate = AIActionCandidate.new()
		c_proxy.category = GameEnums.AIActionCategory.SPONSOR_PROXY_OR_COALITION
		c_proxy.sub_action_id = &"sponsor_proxy_war"
		c_proxy.command_type = "sponsor_proxy_war"
		c_proxy.payload = {
			"sponsor_id": ai_pid,
			"warband_id": "exile_proxy_%d" % ai_pid,
			"target_id": target_pid,
			"silver_cost": 45,
			"raid_intensity": 0.85,
		}
		c_proxy.base_score = (24.0 + shadow_famine_bonus) * pers.sabotage_weight * pers.diplomacy_weight
		c_proxy.rationale = "Gölge Kıtlık Darbesi için Yersiz Yurtsuz vekalet savaşı fonla"
		out.candidates.append(c_proxy)
	elif (belief.get_observed_enemy_dread() >= 40.0 or belief.get_observed_enemy_regency() != GameEnums.RegencyStatus.STABLE_RULE) and belief.get_action_cooldown(GameEnums.AIActionCategory.SPONSOR_PROXY_OR_COALITION) <= 0:
		var c_dip: AIActionCandidate = AIActionCandidate.new()
		c_dip.category = GameEnums.AIActionCategory.SPONSOR_PROXY_OR_COALITION
		c_dip.sub_action_id = &"evaluate_coalition_window"
		c_dip.command_type = "evaluate_diplomacy"
		c_dip.payload = {
			"player_kut": 28.0 if belief.get_observed_enemy_regency() != GameEnums.RegencyStatus.STABLE_RULE else 42.0,
			"player_army_size": belief.get_perceived_enemy_power(),
			"raid_frequency": 0.65,
		}
		c_dip.base_score = 42.0 * pers.diplomacy_weight
		c_dip.rationale = "Kriz anında koalisyon/diplomasi değerlendirmesi"
		out.candidates.append(c_dip)

	# 2H-b. Story-Triggered Amanat Betrayal Candidate
	if narrative != null and narrative.has_active_agenda and narrative.wants_break_pact:
		var ai_pacts: Array[AmanatPactRecord] = ReputationAndPactSystem.get_active_pacts_for_player(ai_pid)
		for pr: AmanatPactRecord in ai_pacts:
			if pr != null and (pr.party_a == target_pid or pr.party_b == target_pid):
				var c_break: AIActionCandidate = AIActionCandidate.new()
				c_break.category = GameEnums.AIActionCategory.SPONSOR_PROXY_OR_COALITION
				c_break.sub_action_id = &"story_break_amanat_pact"
				c_break.command_type = "break_amanat_pact"
				c_break.payload = {"pact_id": String(pr.pact_id), "betrayer_id": ai_pid}
				c_break.base_score = 225.0 + narrative.action_bonuses.get(int(GameEnums.AIActionCategory.SPONSOR_PROXY_OR_COALITION), 0.0)
				c_break.rationale = "Hikâye eşiği nedeniyle Amanat antlaşmasını boz"
				out.candidates.append(c_break)
				break

	# 2I. Baseline Economic / Warband Step (Always available zero-cheat fallback)
	var c_hold: AIActionCandidate = AIActionCandidate.new()
	c_hold.category = GameEnums.AIActionCategory.HOLD_AND_GATHER
	c_hold.sub_action_id = &"step_ai_gather"
	c_hold.command_type = "step_ai_commander"
	c_hold.payload = {
		"agent_id": String(agent_id),
		"is_rogue_warband": false,
		"target_player_army_id": target_army_id,
		"target_depot_id": 1,
	}
	c_hold.base_score = (22.0 + (10.0 if ai_iron < 15 else 0.0)) * pers.economy_weight
	c_hold.rationale = "Ekonomik hazırlık ve lojistik biriktirme"
	out.candidates.append(c_hold)

	# 3. Apply Story Agenda Weights, Anti-Spam Penalty, and Bounded-Rationality Noise
	var temp: float = maxf(diff.decision_temperature, 0.01)
	var anti_spam: float = diff.anti_spam_memory_weight
	var max_eff: float = -10000.0
	for cand: AIActionCandidate in out.candidates:
		var sc: float = cand.base_score
		if narrative != null and narrative.has_active_agenda:
			var cat_i: int = int(cand.category)
			if narrative.action_bonuses.has(cat_i):
				sc += narrative.action_bonuses[cat_i]
			if narrative.priority_doctrine >= 0 and cand.doctrine_preset == narrative.priority_doctrine:
				sc += 32.0
			if narrative.wants_break_pact and cand.category == GameEnums.AIActionCategory.SPONSOR_PROXY_OR_COALITION:
				sc += 28.0
		var rep_cnt: int = belief.get_action_recent_repeats(cand.category)
		if rep_cnt > 0 and cand.sub_action_id != &"restore_own_water" and cand.category != GameEnums.AIActionCategory.EXECUTE_SCHEME_STEP:
			sc -= float(rep_cnt) * 14.0 * anti_spam

		var noise_draw: float = rng.randf() if rng != null else 0.5
		out.draws_consumed += 1
		var jitter: float = (noise_draw - 0.5) * 2.0 * diff.mistake_noise_amplitude * temp
		cand.effective_score = maxf(sc + jitter, 0.01)
		if cand.effective_score > max_eff:
			max_eff = cand.effective_score

	# 4. Deterministic Softmax Selection across Candidates
	var weights: Array[float] = []
	var sum_w: float = 0.0
	var denom: float = maxf(temp * 14.0, 0.25)
	for cand: AIActionCandidate in out.candidates:
		var exp_arg: float = clampf((cand.effective_score - max_eff) / denom, -20.0, 0.0)
		var w: float = exp(exp_arg)
		weights.append(w)
		sum_w += w

	var pick_roll: float = (rng.randf() if rng != null else 0.0) * maxf(sum_w, 0.0001)
	out.draws_consumed += 1
	var accum: float = 0.0
	var selected: AIActionCandidate = out.candidates[0]
	for i: int in range(out.candidates.size()):
		accum += weights[i]
		if pick_roll <= accum:
			selected = out.candidates[i]
			break
	out.chosen = selected
	return out
