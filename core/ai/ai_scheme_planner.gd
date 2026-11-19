class_name AISchemePlanner
extends RefCounted
## Core Multi-Step AI Scheme Planner (rank 2). Plans and executes multi-tick
## deception and crisis exploitation combos strictly via CommandEnvelope steps:
##   1. POISONED_WINTER_TRAP (Zehirli Kış Kapanı)
##   2. DUST_VEIL_COURIER_AMBUSH (Toz Perdesi & Ulak Pususu)
##   3. OPPORTUNISTIC_CRISIS_STRIKE (Fırsatçı Kriz Vuruşu)

const DEFAULT_TIMEOUT_TICKS: int = 8
const TOTAL_STEPS: int = 3


class SchemeStepIntent:
	extends RefCounted
	var scheme_type: GameEnums.AISchemeType = GameEnums.AISchemeType.NONE
	var step_index: int = 0
	var command_type: String = ""
	var payload: Dictionary = {}
	var step_action_id: StringName = &""
	var is_final_step: bool = false
	var target_doctrine_preset: int = -1
	var description: String = ""


var _active_scheme: GameEnums.AISchemeType = GameEnums.AISchemeType.NONE
var _current_step: int = 0
var _target_player_id: int = 1
var _target_army_id: int = 1
var _target_coord: Vector2i = Vector2i.ZERO
var _started_tick: int = 0
var _ticks_in_scheme: int = 0
var _completed_steps: PackedStringArray = PackedStringArray()
var _schemes_completed: int = 0
var _schemes_aborted: int = 0
var _last_completed_scheme: GameEnums.AISchemeType = GameEnums.AISchemeType.NONE


func has_active_scheme() -> bool:
	return _active_scheme != GameEnums.AISchemeType.NONE


func get_active_scheme() -> GameEnums.AISchemeType:
	return _active_scheme


func get_current_step() -> int:
	return _current_step


func get_schemes_completed_count() -> int:
	return _schemes_completed


func get_schemes_aborted_count() -> int:
	return _schemes_aborted


func get_last_completed_scheme() -> GameEnums.AISchemeType:
	return _last_completed_scheme


func get_completed_steps() -> PackedStringArray:
	return _completed_steps


func begin_scheme(
		scheme: GameEnums.AISchemeType,
		p_target_pid: int,
		p_target_army: int,
		p_target_coord: Vector2i,
		p_tick: int) -> void:
	if scheme == GameEnums.AISchemeType.NONE:
		return
	_active_scheme = scheme
	_current_step = 0
	_target_player_id = maxi(p_target_pid, 1)
	_target_army_id = maxi(p_target_army, 1)
	_target_coord = p_target_coord
	_started_tick = p_tick
	_ticks_in_scheme = 0
	_completed_steps = PackedStringArray()


func abort_scheme() -> void:
	if _active_scheme != GameEnums.AISchemeType.NONE:
		_schemes_aborted += 1
	_active_scheme = GameEnums.AISchemeType.NONE
	_current_step = 0
	_ticks_in_scheme = 0


func advance_step(step_succeeded: bool, step_tag: StringName = &"step") -> bool:
	if _active_scheme == GameEnums.AISchemeType.NONE:
		return false
	_ticks_in_scheme += 1
	if step_succeeded:
		_completed_steps.append(String(step_tag))
		_current_step += 1
		if _current_step >= TOTAL_STEPS:
			_last_completed_scheme = _active_scheme
			_schemes_completed += 1
			_active_scheme = GameEnums.AISchemeType.NONE
			_current_step = 0
			_ticks_in_scheme = 0
			return true
	elif _ticks_in_scheme >= DEFAULT_TIMEOUT_TICKS:
		abort_scheme()
	return false


func score_scheme_viability(
		scheme: GameEnums.AISchemeType,
		ai_pid: int,
		ai_army_id: int,
		target_pid: int,
		target_coord: Vector2i,
		belief: AIBeliefModel,
		personality: SteppeAIPersonalityProfile,
		difficulty: AIDifficultyProfile,
		narrative: AINarrativeAgendaHook.NarrativeWeightDirective) -> float:
	if scheme == GameEnums.AISchemeType.NONE:
		return 0.0
	var plan_w: float = difficulty.scheme_planning_weight if difficulty != null else 0.55
	var zud_w: float = difficulty.foresight_zud_horizon_weight if difficulty != null else 0.65
	var sab_p: float = personality.sabotage_weight if personality != null else 1.0
	var dec_p: float = personality.deception_weight if personality != null else 1.0
	var agg_p: float = personality.aggression_weight if personality != null else 1.0
	var pref_bonus: float = 18.0 if (personality != null and personality.preferred_scheme == scheme) else 0.0

	var cur_season: SeasonData = SeasonManager.get_current_season()
	var s_type: GameEnums.SeasonType = cur_season.season_type if cur_season != null else GameEnums.SeasonType.SPRING
	var is_winter_or_autumn: bool = s_type == GameEnums.SeasonType.WINTER or s_type == GameEnums.SeasonType.AUTUMN
	var is_storm: bool = BallisticsEngine.is_pre_zud_storm_active()
	var raid_allowed: bool = GracePeriodManager.can_perform_action(ai_pid, GameEnums.ToreActionType.BORDER_NODE_RAID, target_pid)

	var score: float = 0.0
	match scheme:
		GameEnums.AISchemeType.POISONED_WINTER_TRAP:
			var usable_target_wells: int = WaterRouteManager.count_usable_water_sources(target_coord, s_type, s_type == GameEnums.SeasonType.WINTER)
			var sabotaged_wells: int = WaterRouteManager.count_sabotaged_water_sources(target_coord)
			var silver: int = ResourceManager.get_amount(ai_pid, &"silver_gold")
			var caravans_cnt: int = belief.get_observed_enemy_caravan_ids().size()
			var base: float = 28.0
			if is_winter_or_autumn or is_storm:
				base += 34.0 * zud_w
			if usable_target_wells > 0 and raid_allowed:
				base += 26.0 * sab_p
			elif sabotaged_wells > 0:
				base += 22.0 * sab_p
			if caravans_cnt > 0 or silver >= 45:
				base += 24.0
			if not raid_allowed and sabotaged_wells <= 0 and caravans_cnt <= 0:
				base *= 0.25
			score = (base + pref_bonus) * plan_w * (0.65 + 0.35 * sab_p)

		GameEnums.AISchemeType.DUST_VEIL_COURIER_AMBUSH:
			var dust_on: bool = CourierDispatchSystem.has_dust_decoy(ai_army_id)
			var couriers_cnt: int = belief.get_observed_enemy_courier_ids().size()
			var exposed_already: bool = belief.is_enemy_plan_exposed()
			var base_d: float = 26.0
			if not dust_on:
				base_d += 24.0 * dec_p
			if couriers_cnt > 0:
				base_d += 38.0 * dec_p
			elif not exposed_already:
				base_d += 24.0
			if not belief.is_enemy_doctrine_known():
				base_d += 18.0
			score = (base_d + pref_bonus) * plan_w * (0.65 + 0.35 * dec_p)

		GameEnums.AISchemeType.OPPORTUNISTIC_CRISIS_STRIKE:
			var dread: float = belief.get_observed_enemy_dread()
			var regency_crisis: bool = belief.get_observed_enemy_regency() != GameEnums.RegencyStatus.STABLE_RULE
			var ulus_strained: bool = belief.is_observed_enemy_ulus_strained()
			var overext: bool = belief.is_observed_enemy_overextended()
			var base_o: float = 20.0
			if dread >= 45.0:
				base_o += 28.0 + clampf((dread - 45.0) * 0.5, 0.0, 25.0)
			if regency_crisis:
				base_o += 32.0
			if ulus_strained:
				base_o += 24.0
			if overext:
				base_o += 22.0
			if not raid_allowed and dread < 45.0 and not regency_crisis and not ulus_strained:
				base_o *= 0.40
			score = (base_o + pref_bonus) * plan_w * (0.65 + 0.35 * agg_p)

	if narrative != null and narrative.has_active_agenda and narrative.preferred_scheme == scheme:
		score += narrative.scheme_bonus
	return maxf(score, 0.0)


func build_next_step_intent(
		ai_pid: int,
		ai_army_id: int,
		_ai_home_coord: Vector2i,
		belief: AIBeliefModel,
		difficulty: AIDifficultyProfile,
		_personality: SteppeAIPersonalityProfile,
		ai_remount_ratio: float,
		current_seed: int) -> SchemeStepIntent:
	var intent: SchemeStepIntent = SchemeStepIntent.new()
	intent.scheme_type = _active_scheme
	intent.step_index = _current_step
	intent.is_final_step = (_current_step >= TOTAL_STEPS - 1)
	if _active_scheme == GameEnums.AISchemeType.NONE:
		return intent

	var cur_season: SeasonData = SeasonManager.get_current_season()
	var s_type: GameEnums.SeasonType = cur_season.season_type if cur_season != null else GameEnums.SeasonType.SPRING
	var target_coord: Vector2i = _target_coord if _target_coord != Vector2i.ZERO else belief.get_observed_target_region_coord()
	var raid_allowed: bool = GracePeriodManager.can_perform_action(ai_pid, GameEnums.ToreActionType.BORDER_NODE_RAID, _target_player_id)
	var hazard_avoid: bool = difficulty == null or difficulty.terrain_trap_awareness >= 0.50

	match _active_scheme:
		GameEnums.AISchemeType.POISONED_WINTER_TRAP:
			if _current_step == 0:
				var usable_w: int = WaterRouteManager.count_usable_water_sources(target_coord, s_type, s_type == GameEnums.SeasonType.WINTER)
				if usable_w > 0 and raid_allowed:
					intent.command_type = "sabotage_well"
					intent.step_action_id = &"sabotage_well"
					intent.payload = {
						"saboteur_id": ai_pid,
						"region_x": target_coord.x,
						"region_y": target_coord.y,
						"source_id": "",
						"duration_seasons": 3,
					}
					intent.description = "Adım 1/3: Hedef kuyularını zehirle"
				else:
					intent.command_type = "evaluate_diplomacy"
					intent.step_action_id = &"winter_pressure_probe"
					intent.payload = {
						"player_kut": 32.0 if s_type == GameEnums.SeasonType.WINTER else 50.0,
						"player_army_size": belief.get_perceived_enemy_power(),
						"raid_frequency": 0.45,
					}
					intent.description = "Adım 1/3: Kış baskısı için diplomatik yoklama"
			elif _current_step == 1:
				var caravans: PackedStringArray = belief.get_observed_enemy_caravan_ids()
				if not caravans.is_empty():
					intent.command_type = "intercept_caravan"
					intent.step_action_id = &"intercept_caravan"
					intent.payload = {
						"caravan_id": caravans[0],
						"raider_id": ai_pid,
					}
					intent.description = "Adım 2/3: İkmal kervanını vur"
				elif ResourceManager.get_amount(ai_pid, &"silver_gold") >= 45 and not ReputationAndPactSystem.has_active_proxy_war_by(ai_pid):
					intent.command_type = "sponsor_proxy_war"
					intent.step_action_id = &"sponsor_proxy_war"
					intent.payload = {
						"sponsor_id": ai_pid,
						"warband_id": "shadow_steppe_raiders_%d" % ai_pid,
						"target_id": _target_player_id,
						"silver_cost": 45,
						"raid_intensity": 0.85,
					}
					intent.description = "Adım 2/3: Örtülü vekalet savaşı başlat"
				else:
					intent.command_type = "interdict_supply_line"
					intent.step_action_id = &"interdict_supply_line"
					intent.payload = {
						"raider_player_id": ai_pid,
						"target_army_id": _target_army_id,
						"depot_id": 1,
						"raider_id": str(ai_pid),
					}
					intent.description = "Adım 2/3: Cephe ikmal hattını kes"
			else:
				intent.command_type = "assign_battle_doctrine"
				intent.step_action_id = &"assign_tonyukuk_attrition"
				intent.target_doctrine_preset = int(GameEnums.BattleDoctrinePresetId.TONYUKUK_YIPRATMASI)
				intent.payload = {
					"player_id": ai_pid,
					"army_id": ai_army_id,
					"preset_id": intent.target_doctrine_preset,
					"sync_offline_contingency": true,
				}
				intent.description = "Adım 3/3: Tonyukuk yıpratma doktriniyle kıtlık darbesi"

		GameEnums.AISchemeType.DUST_VEIL_COURIER_AMBUSH:
			if _current_step == 0:
				if not CourierDispatchSystem.has_dust_decoy(ai_army_id) and ai_remount_ratio >= 0.25:
					intent.command_type = "toggle_dust_screen"
					intent.step_action_id = &"raise_dust_screen"
					intent.payload = {
						"army_id": ai_army_id,
						"player_id": ai_pid,
						"enable": true,
						"remount_horse_ratio": ai_remount_ratio,
					}
					intent.description = "Adım 1/3: Yılkı Toz Perdesi ile nizamı gizle"
				else:
					intent.command_type = "dispatch_spy"
					intent.step_action_id = &"dispatch_spy_recon"
					intent.payload = _build_spy_payload(ai_pid, belief, current_seed)
					intent.description = "Adım 1/3: Toz örtüsü altında casus sızdır"
			elif _current_step == 1:
				var couriers: PackedStringArray = belief.get_observed_enemy_courier_ids()
				if not couriers.is_empty():
					intent.command_type = "ambush_courier"
					intent.step_action_id = &"ambush_courier"
					intent.payload = {
						"order_id": couriers[0],
						"ambusher_faction_id": ai_pid,
					}
					intent.description = "Adım 2/3: Düşman ulak konvoyunu pusuya düşür"
				else:
					intent.command_type = "dispatch_spy"
					intent.step_action_id = &"dispatch_spy_infiltrate"
					intent.payload = _build_spy_payload(ai_pid, belief, current_seed + 17)
					intent.description = "Adım 2/3: Savaş planını deşifre etmek için casus gönder"
			else:
				var counter_p: GameEnums.BattleDoctrinePresetId = belief.recommend_counter_doctrine(hazard_avoid)
				intent.command_type = "assign_battle_doctrine"
				intent.step_action_id = &"assign_counter_doctrine"
				intent.target_doctrine_preset = int(counter_p)
				intent.payload = {
					"player_id": ai_pid,
					"army_id": ai_army_id,
					"preset_id": intent.target_doctrine_preset,
					"sync_offline_contingency": true,
				}
				intent.description = "Adım 3/3: Deşifre edilen plana tam karşı doktrin ata"

		GameEnums.AISchemeType.OPPORTUNISTIC_CRISIS_STRIKE:
			if _current_step == 0:
				var pacts: Array[AmanatPactRecord] = ReputationAndPactSystem.get_active_pacts_for_player(ai_pid)
				var pact_with_target: AmanatPactRecord = null
				for pr: AmanatPactRecord in pacts:
					if pr != null and (pr.party_a == _target_player_id or pr.party_b == _target_player_id):
						pact_with_target = pr
						break
				if pact_with_target != null and belief.get_observed_enemy_dread() >= 55.0:
					intent.command_type = "break_amanat_pact"
					intent.step_action_id = &"break_amanat_pact"
					intent.payload = {
						"pact_id": String(pact_with_target.pact_id),
						"betrayer_id": ai_pid,
					}
					intent.description = "Adım 1/3: Zalim hükümdara karşı Amanat antlaşmasını boz"
				else:
					intent.command_type = "evaluate_diplomacy"
					intent.step_action_id = &"coalition_pressure"
					intent.payload = {
						"player_kut": 26.0 if belief.get_observed_enemy_regency() != GameEnums.RegencyStatus.STABLE_RULE else 40.0,
						"player_army_size": belief.get_perceived_enemy_power(),
						"raid_frequency": 0.70,
					}
					intent.description = "Adım 1/3: Kriz anında koalisyon/diplomasi baskısı kur"
			elif _current_step == 1:
				var caravans_o: PackedStringArray = belief.get_observed_enemy_caravan_ids()
				if not caravans_o.is_empty():
					intent.command_type = "intercept_caravan"
					intent.step_action_id = &"intercept_caravan"
					intent.payload = {
						"caravan_id": caravans_o[0],
						"raider_id": ai_pid,
					}
					intent.description = "Adım 2/3: Kriz sırasında ikmal kervanına baskın"
				else:
					intent.command_type = "interdict_supply_line"
					intent.step_action_id = &"interdict_supply_line"
					intent.payload = {
						"raider_player_id": ai_pid,
						"target_army_id": _target_army_id,
						"depot_id": 1,
						"raider_id": str(ai_pid),
					}
					intent.description = "Adım 2/3: İç karışıklıkta ikmal koridorunu kes"
			else:
				var strike_doc: GameEnums.BattleDoctrinePresetId = belief.recommend_counter_doctrine(hazard_avoid)
				if not belief.is_enemy_doctrine_known():
					strike_doc = GameEnums.BattleDoctrinePresetId.TOLGAMA_KISKACI if belief.is_observed_enemy_ulus_strained() else GameEnums.BattleDoctrinePresetId.BORU_KAMASI
					if strike_doc == GameEnums.BattleDoctrinePresetId.BORU_KAMASI and hazard_avoid and belief.get_hazard_count() >= 2:
						strike_doc = GameEnums.BattleDoctrinePresetId.TOLGAMA_KISKACI
				intent.command_type = "assign_battle_doctrine"
				intent.step_action_id = &"assign_crisis_strike_doctrine"
				intent.target_doctrine_preset = int(strike_doc)
				intent.payload = {
					"player_id": ai_pid,
					"army_id": ai_army_id,
					"preset_id": intent.target_doctrine_preset,
					"sync_offline_contingency": true,
				}
				intent.description = "Adım 3/3: Kriz taarruzu nizamını konuşlandır"

	return intent


func _build_spy_payload(ai_pid: int, belief: AIBeliefModel, seed_val: int) -> Dictionary:
	return {
		"spy_owner_id": ai_pid,
		"target_faction_id": _target_player_id,
		"target_army_id": _target_army_id,
		"commander_leadership": 72.0,
		"terrain_path": "res://data/terrain/steppe.tres",
		"target_quiver_ammo": 60.0,
		"target_tactic_intent": int(GameEnums.TuranTacticPhase.FEIGNED_RETREAT_LURE),
		"target_doctrine_type": int(GameEnums.TacticalDoctrineType.FEIGNED_RETREAT),
		"counter_espionage": 0.15 if belief.get_observed_enemy_honor() >= 50.0 else 0.05,
		"rng_seed": maxi(absi(seed_val), 1),
	}


func export_state_dict() -> Dictionary:
	var comp: Array[String] = []
	for s: String in _completed_steps:
		comp.append(s)
	return {
		"active_scheme": int(_active_scheme),
		"completed_steps": comp,
		"current_step": _current_step,
		"last_completed_scheme": int(_last_completed_scheme),
		"schemes_aborted": _schemes_aborted,
		"schemes_completed": _schemes_completed,
		"started_tick": _started_tick,
		"target_army_id": _target_army_id,
		"target_coord_x": _target_coord.x,
		"target_coord_y": _target_coord.y,
		"target_player_id": _target_player_id,
		"ticks_in_scheme": _ticks_in_scheme,
	}


func import_state_dict(data: Dictionary) -> bool:
	var sch_int: int = clampi(DeterministicStateHasher.v_int(data.get("active_scheme", 0), 0), 0, 3)
	_active_scheme = sch_int as GameEnums.AISchemeType
	var last_int: int = clampi(DeterministicStateHasher.v_int(data.get("last_completed_scheme", 0), 0), 0, 3)
	_last_completed_scheme = last_int as GameEnums.AISchemeType
	_current_step = clampi(DeterministicStateHasher.v_int(data.get("current_step", 0), 0), 0, TOTAL_STEPS)
	_target_player_id = maxi(DeterministicStateHasher.v_int(data.get("target_player_id", 1), 1), 1)
	_target_army_id = maxi(DeterministicStateHasher.v_int(data.get("target_army_id", 1), 1), 1)
	_target_coord = Vector2i(
		DeterministicStateHasher.v_int(data.get("target_coord_x", 0), 0),
		DeterministicStateHasher.v_int(data.get("target_coord_y", 0), 0))
	_started_tick = maxi(DeterministicStateHasher.v_int(data.get("started_tick", 0), 0), 0)
	_ticks_in_scheme = maxi(DeterministicStateHasher.v_int(data.get("ticks_in_scheme", 0), 0), 0)
	_schemes_completed = maxi(DeterministicStateHasher.v_int(data.get("schemes_completed", 0), 0), 0)
	_schemes_aborted = maxi(DeterministicStateHasher.v_int(data.get("schemes_aborted", 0), 0), 0)
	_completed_steps = PackedStringArray()
	for s_v: Variant in DeterministicStateHasher.v_arr(data.get("completed_steps", [])):
		_completed_steps.append(DeterministicStateHasher.v_str(s_v))
	return true
