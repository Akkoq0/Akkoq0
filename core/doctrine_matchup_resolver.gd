class_name DoctrineMatchupResolver
extends RefCounted
## Core pure evaluator (rank 2). Evaluates realistic Faz 27B modular steppe
## doctrine matchups without introducing circular dependencies between managers.
##
## Integrates:
##   1. Kurt Kapanı (Feigned Retreat) vs Commander Legacy (`SuccessionManager`) & Dread (`ReputationAndPactSystem`)
##   2. Börü Heavy Wedge vs Thin-Center (`< 0.30`) Encirclement vs Mud/Slope/Storm Fatigue Physics
##   3. Araba Kalesi (Wagon Circle Laager) Mobility Tradeoff & Flank/Rear Encirclement Damping
##   4. Tonyukuk Attrition (`WaterRouteManager` & `CaravanLogisticsManager`) vs Large Armies vs Raiding Bands
##   5. Ülüş Silent Sabotage Flank Shrinkage (`GovernanceManager`), Courier Exposure (`CourierDispatchSystem`),
##      and Phase 26A `SystemicSynergyMatrix` closed-form multipliers.


static func _safe_float(val: float, fallback: float, min_val: float, max_val: float) -> float:
	if is_nan(val) or is_inf(val):
		return clampf(fallback, min_val, max_val)
	return clampf(val, min_val, max_val)


static func _sanitize_ratios(doc: BattleDoctrineResource) -> Vector3:
	if doc == null:
		return Vector3(0.34, 0.46, 0.20)
	var c: float = 0.0 if (is_nan(doc.center_ratio) or is_inf(doc.center_ratio)) else maxf(doc.center_ratio, 0.0)
	var f: float = 0.0 if (is_nan(doc.flank_ratio) or is_inf(doc.flank_ratio)) else maxf(doc.flank_ratio, 0.0)
	var r: float = 0.0 if (is_nan(doc.reserve_ratio) or is_inf(doc.reserve_ratio)) else maxf(doc.reserve_ratio, 0.0)
	var total: float = c + f + r
	if total <= 0.0001:
		return Vector3(0.34, 0.46, 0.20)
	return Vector3(clampf(c / total, 0.0, 1.0), clampf(f / total, 0.0, 1.0), clampf(r / total, 0.0, 1.0))


static func _compute_ulus_sabotage_ratio(player_id: int) -> float:
	if player_id <= 0:
		return 0.0
	var vassals: Array[VassalBeyAssignment] = GovernanceManager.get_vassals_for_suzerain(player_id)
	if vassals.is_empty():
		return 0.0
	var sab_sum: float = 0.0
	var active_sab: int = 0
	for v: VassalBeyAssignment in vassals:
		if v == null:
			continue
		if v.silent_sabotage_active:
			var troop_drop: float = clampf(1.0 - v.reinforcement_troop_mult, 0.0, 0.75)
			var delay_factor: float = clampf(v.reinforcement_delay_hours / 48.0, 0.0, 0.25)
			sab_sum += clampf(troop_drop + delay_factor, 0.08, 0.85)
			active_sab += 1
	if active_sab <= 0:
		return 0.0
	return clampf(sab_sum / float(vassals.size()), 0.0, 0.75)


static func _compute_heavy_armor_fatigue_factor(
		is_heavy_armor: bool,
		is_mud: bool,
		is_steep_slope: bool,
		is_storm: bool,
		rules: CourierAndCaravanRules) -> float:
	var mud_m: float = rules.heavy_armor_mud_fatigue_mult if rules != null else 2.10
	var slope_m: float = rules.heavy_armor_slope_fatigue_mult if rules != null else 1.90
	var storm_m: float = rules.heavy_armor_storm_fatigue_mult if rules != null else 1.75
	var exp_pow: float = rules.heavy_armor_exponential_power if rules != null else 1.35
	var light_res: float = rules.light_cavalry_terrain_resilience if rules != null else 0.65

	var compound: float = 1.0
	if is_mud:
		compound *= (mud_m if is_heavy_armor else 1.15)
	if is_steep_slope:
		compound *= (slope_m if is_heavy_armor else 1.12)
	if is_storm:
		compound *= (storm_m if is_heavy_armor else 1.10)
	return pow(compound, exp_pow) if is_heavy_armor else compound * light_res


static func _estimate_troop_count(stats: CombatantStats, army_id: int) -> int:
	if stats != null and stats.troop_count > 0:
		return stats.troop_count
	if army_id > 0:
		var reg_riders: int = CommandBus.get_army_rider_count(army_id)
		if reg_riders > 0:
			return reg_riders
	if stats != null and stats.health > 0.0:
		var hp: float = _safe_float(stats.health, 140.0, 1.0, 10000000.0)
		return maxi(int(roundf(hp / 140.0)), 1)
	return 20


static func _compute_synergy_scale(snap: SynergyEvaluationSnapshot) -> float:
	if snap == null:
		return 1.0
	var power_rel: float = clampf(_safe_float(snap.effective_combat_power_mult, 1.18, 0.1, 3.0) / 1.18, 0.45, 1.45)
	var tempo_rel: float = clampf(1.0 + (_safe_float(snap.courier_tempo_mult, 1.0, 0.35, 1.85) - 1.0) * 0.35, 0.75, 1.25)
	return clampf(power_rel * tempo_rel, 0.45, 1.50)


static func _falls_for_feigned_retreat(
		target_cmdr: CommanderProfile,
		target_dread: float,
		lurer_plan_exposed: bool,
		lurer_dust_active: bool) -> bool:
	if lurer_plan_exposed:
		return false
	var vet: float = 0.0
	var trait_bonus: float = 0.0
	var leadership_bonus: float = 0.0
	if target_cmdr != null and target_cmdr.is_alive:
		vet = clampf(_safe_float(target_cmdr.veteran_score, 0.0, 0.0, 200.0), 0.0, 200.0)
		if target_cmdr.commander_trait == GameEnums.CommanderTrait.KERVAN_GAZISI \
				or target_cmdr.commander_trait == GameEnums.CommanderTrait.BORU_YUREK:
			trait_bonus = 0.18
		elif target_cmdr.commander_trait == GameEnums.CommanderTrait.BOZKIR_KURDU:
			trait_bonus = 0.10
		if target_cmdr.leadership >= 82.0:
			leadership_bonus = 0.08
	var safe_dread: float = clampf(_safe_float(target_dread, 0.0, 0.0, 100.0), 0.0, 100.0)
	var recognition_score: float = clampf(vet / 85.0, 0.0, 1.0) * 0.65 \
		+ trait_bonus \
		+ leadership_bonus \
		- clampf(safe_dread / 100.0, 0.0, 1.0) * 0.50 \
		- (0.06 if lurer_dust_active else 0.0)
	return recognition_score < 0.45


static func evaluate(
		attacker: CombatantStats,
		defender: CombatantStats,
		attacker_doctrine: BattleDoctrineResource = null,
		defender_doctrine: BattleDoctrineResource = null,
		terrain: TerrainData = null,
		season: SeasonData = null,
		engagement_angle: GameEnums.CombatEngagementAngle = GameEnums.CombatEngagementAngle.FRONT,
		is_mud: bool = false,
		is_steep_slope: bool = false,
		is_storm: bool = false,
		region_coord: Vector2i = Vector2i.ZERO) -> DoctrineMatchupResult:
	var result: DoctrineMatchupResult = DoctrineMatchupResult.new()

	var atk_doc: BattleDoctrineResource = attacker_doctrine if attacker_doctrine != null else (attacker.battle_doctrine if attacker != null else null)
	var def_doc: BattleDoctrineResource = defender_doctrine if defender_doctrine != null else (defender.battle_doctrine if defender != null else null)

	if atk_doc != null:
		result.attacker_doctrine_id = atk_doc.doctrine_id
	if def_doc != null:
		result.defender_doctrine_id = def_doc.doctrine_id

	var atk_army_id: int = attacker.army_id if (attacker != null and attacker.army_id > 0) else (attacker.entity_id if attacker != null else 0)
	var def_army_id: int = defender.army_id if (defender != null and defender.army_id > 0) else (defender.entity_id if defender != null else 0)

	var atk_cmdr: CommanderProfile = SuccessionManager.get_commander_for_army(atk_army_id) if atk_army_id > 0 else null
	var def_cmdr: CommanderProfile = SuccessionManager.get_commander_for_army(def_army_id) if def_army_id > 0 else null

	var atk_pid: int = attacker.player_id if (attacker != null and attacker.player_id > 0) else (atk_cmdr.player_id if atk_cmdr != null else 0)
	var def_pid: int = defender.player_id if (defender != null and defender.player_id > 0) else (def_cmdr.player_id if def_cmdr != null else 0)

	var atk_ratios: Vector3 = _sanitize_ratios(atk_doc)
	var def_ratios: Vector3 = _sanitize_ratios(def_doc)
	var atk_center: float = atk_ratios.x
	var atk_flank: float = atk_ratios.y
	var def_center: float = def_ratios.x
	var def_flank: float = def_ratios.y

	# --- 1. Ülüş Silent Sabotage shrinks effective flank wing ratio ---------
	var atk_sab: float = _compute_ulus_sabotage_ratio(atk_pid)
	var def_sab: float = _compute_ulus_sabotage_ratio(def_pid)
	if atk_sab > 0.0:
		var flank_shrink: float = clampf(atk_sab * 0.65, 0.0, 0.55)
		result.ulus_flank_penalty = flank_shrink
		result.attacker_effective_flank_ratio = maxf(atk_flank * (1.0 - flank_shrink), 0.05)
		result.add_tag("ulus_flank_sabotage", "Ülüş sessiz sabotajı kanat oranını %.2f -> %.2f daralttı." % [atk_flank, result.attacker_effective_flank_ratio])
	else:
		result.attacker_effective_flank_ratio = atk_flank

	if def_sab > 0.0:
		var def_shrink: float = clampf(def_sab * 0.65, 0.0, 0.55)
		result.defender_effective_flank_ratio = maxf(def_flank * (1.0 - def_shrink), 0.05)
	else:
		result.defender_effective_flank_ratio = def_flank

	var atk_mult: float = 1.0
	var def_mult: float = 1.0
	var coh_mult: float = 1.0
	var mor_mult: float = 1.0
	var atk_mob_mult: float = 1.0
	var def_mob_mult: float = 1.0

	# --- 2. Courier Plan Exposure Counter-Penalty ----------------------------
	var atk_exposed: bool = CourierDispatchSystem.is_player_plan_exposed_by_courier(atk_pid, atk_army_id) if atk_pid > 0 else false
	var def_exposed: bool = CourierDispatchSystem.is_player_plan_exposed_by_courier(def_pid, def_army_id) if def_pid > 0 else false
	if atk_exposed:
		result.plan_exposed_by_courier = true
		result.exposed_counter_penalty = 0.25
		atk_mult *= (1.0 - result.exposed_counter_penalty)
		def_mult *= 1.15
		result.add_tag("doctrine_plan_exposed", "Esir düşen ulak nedeniyle savaş planı ifşa oldu (-%25 saldırı).")
	if def_exposed:
		atk_mult *= 1.15
		result.add_tag("enemy_doctrine_exposed", "Düşman ulak planı ele geçirildi (+%15 karşı hazırlık).")

	# --- 3. Phase 26A SystemicSynergyMatrix Read-Only Hookup -----------------
	var eff_atk_coord: Vector2i = region_coord
	if eff_atk_coord == Vector2i.ZERO and attacker != null and attacker.region_coord != Vector2i.ZERO:
		eff_atk_coord = attacker.region_coord
	var eff_def_coord: Vector2i = region_coord
	if eff_def_coord == Vector2i.ZERO and defender != null and defender.region_coord != Vector2i.ZERO:
		eff_def_coord = defender.region_coord
	if eff_def_coord == Vector2i.ZERO and def_pid > 0:
		eff_def_coord = PastureEcologyManager.get_player_camp_region(def_pid)

	var atk_troops: int = _estimate_troop_count(attacker, atk_army_id)
	var def_troops: int = _estimate_troop_count(defender, def_army_id)

	var atk_syn_scale: float = 1.0
	if atk_pid > 0:
		var atk_phase: GameEnums.TuranTacticPhase = attacker.active_tactic_phase if attacker != null else GameEnums.TuranTacticPhase.RECON_DUST_SCREEN
		var atk_remount: float = _safe_float(attacker.remount_horse_ratio if attacker != null else 1.0, 1.0, 0.0, 1.0)
		var atk_syn: SynergyEvaluationSnapshot = SystemicSynergyMatrix.evaluate_player(
			atk_pid, maxi(atk_army_id, 1), eff_atk_coord, false, atk_troops, -1.0, atk_phase, -1.0, atk_remount)
		if atk_syn != null and atk_syn.is_finite_and_bounded():
			result.attacker_synergy_power_mult = atk_syn.effective_combat_power_mult
			result.attacker_courier_tempo_mult = atk_syn.courier_tempo_mult
			atk_syn_scale = _compute_synergy_scale(atk_syn)
			result.synergy_power_factor = atk_syn_scale
			atk_mult *= lerpf(1.0, atk_syn_scale, 0.50)

	if def_pid > 0:
		var def_phase: GameEnums.TuranTacticPhase = defender.active_tactic_phase if defender != null else GameEnums.TuranTacticPhase.RECON_DUST_SCREEN
		var def_remount: float = _safe_float(defender.remount_horse_ratio if defender != null else 1.0, 1.0, 0.0, 1.0)
		var def_syn: SynergyEvaluationSnapshot = SystemicSynergyMatrix.evaluate_player(
			def_pid, maxi(def_army_id, 1), eff_def_coord, false, def_troops, -1.0, def_phase, -1.0, def_remount)
		if def_syn != null and def_syn.is_finite_and_bounded():
			result.defender_synergy_power_mult = def_syn.effective_combat_power_mult
			result.defender_courier_tempo_mult = def_syn.courier_tempo_mult
			var def_syn_scale: float = _compute_synergy_scale(def_syn)
			def_mult *= lerpf(1.0, def_syn_scale, 0.50)

	# --- 4. Environment & Terrain Physics ------------------------------------
	var courier_rules: CourierAndCaravanRules = CourierDispatchSystem.get_rules()
	var eff_mud: bool = is_mud or (attacker != null and attacker.is_mud_terrain)
	var eff_slope: bool = is_steep_slope or (terrain != null and terrain.terrain_class == GameEnums.TerrainClass.DAMARLI_YAMAC)
	var eff_storm: bool = is_storm or BallisticsEngine.is_pre_zud_storm_active()
	var hazard_count: int = int(eff_mud) + int(eff_slope) + int(eff_storm)

	var atk_has_maneuver: bool = atk_doc != null
	var def_has_maneuver: bool = def_doc != null
	var atk_maneuver: GameEnums.DecisiveManeuver = atk_doc.decisive_maneuver if atk_has_maneuver else GameEnums.DecisiveManeuver.KURT_KAPANI_FEIGNED_RETREAT
	var def_maneuver: GameEnums.DecisiveManeuver = def_doc.decisive_maneuver if def_has_maneuver else GameEnums.DecisiveManeuver.KURT_KAPANI_FEIGNED_RETREAT
	var def_is_laager: bool = def_has_maneuver and def_maneuver == GameEnums.DecisiveManeuver.WAGON_CIRCLE_LAAGER
	var atk_is_laager: bool = atk_has_maneuver and atk_maneuver == GameEnums.DecisiveManeuver.WAGON_CIRCLE_LAAGER

	# --- Layer 2 Opening Tactics ---------------------------------------------
	if atk_has_maneuver:
		match atk_doc.opening_tactic:
			GameEnums.OpeningTactic.YELME_HARASSMENT:
				var q_ratio: float = _safe_float(attacker.quiver_ammo_ratio if attacker != null else 1.0, 1.0, 0.0, 1.0)
				if q_ratio >= 0.35:
					atk_mult *= 1.06
					coh_mult *= 1.08
			GameEnums.OpeningTactic.DUST_SCREEN_FEINT:
				if not atk_exposed:
					var has_dust: bool = CourierDispatchSystem.has_dust_decoy(atk_army_id) if atk_army_id > 0 else false
					atk_mult *= (1.14 if has_dust else 1.06)
					def_mob_mult *= 0.94
			GameEnums.OpeningTactic.NIGHT_STORM_RAID:
				if eff_storm:
					atk_mult *= 1.18
					mor_mult *= 1.15
				elif def_is_laager:
					atk_mult *= 0.95
			GameEnums.OpeningTactic.DIRECT_WEDGE_CHARGE:
				if hazard_count == 0:
					atk_mult *= 1.10
					coh_mult *= 1.08

	# --- Matchup #1: Kurt Kapanı vs Commander Legacy & Dread -----------------
	if atk_has_maneuver and atk_maneuver == GameEnums.DecisiveManeuver.KURT_KAPANI_FEIGNED_RETREAT:
		var def_dread: float = ReputationAndPactSystem.get_dread_score(def_pid) if def_pid > 0 else 0.0
		var atk_dust: bool = CourierDispatchSystem.has_dust_decoy(atk_army_id) if atk_army_id > 0 else false
		if not def_is_laager and _falls_for_feigned_retreat(def_cmdr, def_dread, atk_exposed, atk_dust):
			var flank_scale: float = clampf(result.attacker_effective_flank_ratio / 0.50, 0.35, 1.15)
			var base_collapse: float = atk_doc.turan_doctrine.max_armor_collapse_ratio if atk_doc.turan_doctrine != null else 0.45
			result.feigned_retreat_lure_succeeded = true
			result.force_rear_exposure = true
			result.bonus_defender_armor_collapse_ratio = clampf(base_collapse * clampf(flank_scale, 0.35, 1.0), 0.15, 0.45)
			atk_mult *= (1.12 + 0.28 * flank_scale)
			coh_mult *= 1.30
			mor_mult *= 1.35
			result.add_tag("kurt_kapani_sprung", "Rakip Kurt Kapanı tuzağına düştü (2.1x arka darbe & zırh çökmesi).")
		elif not def_is_laager:
			result.feigned_retreat_broken_off_early = true
			result.feigned_retreat_lure_succeeded = false
			result.force_rear_exposure = false
			result.bonus_defender_armor_collapse_ratio = 0.0
			def_mult *= 1.18
			atk_mult *= 0.86
			result.add_tag("kurt_kapani_broken_off_early", "Tecrübeli ve ölçülü komutan Kurt Kapanı'nı erken fark edip takibi kesti.")
	elif def_has_maneuver and def_maneuver == GameEnums.DecisiveManeuver.KURT_KAPANI_FEIGNED_RETREAT \
			and atk_has_maneuver and (atk_maneuver == GameEnums.DecisiveManeuver.BORU_HEAVY_WEDGE or atk_doc.opening_tactic == GameEnums.OpeningTactic.DIRECT_WEDGE_CHARGE):
		var atk_dread: float = ReputationAndPactSystem.get_dread_score(atk_pid) if atk_pid > 0 else 0.0
		var def_dust: bool = CourierDispatchSystem.has_dust_decoy(def_army_id) if def_army_id > 0 else false
		if _falls_for_feigned_retreat(atk_cmdr, atk_dread, def_exposed, def_dust):
			result.feigned_retreat_lure_succeeded = true
			atk_mult *= 0.74
			def_mult *= 1.22
			result.add_tag("kurt_kapani_sprung", "Hücum kolu savunmanın sahte ricatına çekilip uzadı.")
		else:
			result.feigned_retreat_broken_off_early = true
			result.add_tag("kurt_kapani_broken_off_early", "Gazi komutan sahte ricat tuzağına karşı takibi kesti.")

	# --- Matchup #2: Börü Heavy Wedge vs Thin Center vs Mud/Slope/Storm -------
	var atk_is_heavy: bool = atk_has_maneuver and (atk_doc.is_heavy_armor_doctrine or atk_maneuver == GameEnums.DecisiveManeuver.BORU_HEAVY_WEDGE)
	var def_is_heavy: bool = def_has_maneuver and (def_doc.is_heavy_armor_doctrine or def_maneuver == GameEnums.DecisiveManeuver.BORU_HEAVY_WEDGE)
	if atk_is_heavy:
		var heavy_fat: float = _compute_heavy_armor_fatigue_factor(true, eff_mud, eff_slope, eff_storm, courier_rules)
		if hazard_count >= 2 or heavy_fat >= 3.0:
			result.heavy_armor_terrain_collapse = true
			result.attacker_fatigue_multiplier = clampf(heavy_fat, 1.0, 14.0)
			var pen: float = clampf(1.0 / pow(heavy_fat, 0.32), 0.38, 0.85)
			atk_mult *= pen
			atk_mob_mult = minf(atk_mob_mult, clampf(0.45 if hazard_count >= 3 else 0.60, 0.30, 1.0))
			if not def_is_heavy:
				def_mult *= 1.25
			result.add_tag("heavy_armor_terrain_collapse", "Ağır zırhlı kama çamur/yamaç/fırtınada üstel yorgunlukla saplandı (%.2fx)." % heavy_fat)
		elif atk_maneuver == GameEnums.DecisiveManeuver.BORU_HEAVY_WEDGE and def_has_maneuver and def_center < BattleDoctrineResource.THIN_CENTER_THRESHOLD:
			result.wedge_pierced_thin_center = true
			var center_gap: float = clampf(atk_center - def_center, 0.10, 0.60)
			atk_mult *= clampf(1.25 + center_gap * 0.85, 1.25, 1.75)
			coh_mult *= 1.45
			mor_mult *= 1.30
			result.add_tag("wedge_pierced_thin_center", "Börü ağır kaması ince savunma merkezini (%%%.0f) yarıp dağıttı." % (def_center * 100.0))

	# --- Matchup #3: Tolgama Double Envelopment & Araba Kalesi Laager --------
	if atk_has_maneuver and atk_maneuver == GameEnums.DecisiveManeuver.TOLGAMA_DOUBLE_ENVELOPMENT:
		if result.wedge_pierced_thin_center:
			atk_mult *= 0.88
		elif not def_is_laager:
			var wing_pow: float = clampf(result.attacker_effective_flank_ratio / 0.45, 0.35, 1.35)
			atk_mult *= (1.0 + 0.28 * wing_pow)
			coh_mult *= (1.0 + 0.32 * wing_pow)
			mor_mult *= (1.0 + 0.20 * wing_pow)
			result.add_tag("tolgama_encirclement_pressure", "Tolgama çift kanat kuşatması etkin kanat oranıyla (%.2f) baskı kurdu." % result.attacker_effective_flank_ratio)

	if atk_is_laager:
		atk_mob_mult = minf(atk_mob_mult, _safe_float(atk_doc.laager_mobility_multiplier, 0.55, 0.20, 1.0))

	if def_is_laager:
		result.laager_encirclement_damped = true
		def_mob_mult = minf(def_mob_mult, _safe_float(def_doc.laager_mobility_multiplier, 0.55, 0.20, 1.0))
		var flank_d: float = _safe_float(def_doc.laager_flank_damping, 0.65, 0.0, 0.95)
		var rear_d: float = _safe_float(def_doc.laager_rear_damping, 0.70, 0.0, 0.95)
		if engagement_angle == GameEnums.CombatEngagementAngle.REAR or result.force_rear_exposure:
			result.flank_rear_damping_ratio = rear_d
		elif engagement_angle == GameEnums.CombatEngagementAngle.FLANK or (atk_has_maneuver and atk_maneuver == GameEnums.DecisiveManeuver.TOLGAMA_DOUBLE_ENVELOPMENT):
			result.flank_rear_damping_ratio = flank_d
		else:
			result.flank_rear_damping_ratio = flank_d * 0.45
		result.force_rear_exposure = false
		result.bonus_defender_armor_collapse_ratio = 0.0
		def_mult *= 1.24
		coh_mult *= clampf(1.0 - result.flank_rear_damping_ratio * 0.55, 0.35, 1.0)
		mor_mult *= clampf(1.0 - result.flank_rear_damping_ratio * 0.50, 0.40, 1.0)
		if atk_has_maneuver and atk_maneuver == GameEnums.DecisiveManeuver.TOLGAMA_DOUBLE_ENVELOPMENT:
			atk_mult *= 0.85
		result.add_tag("laager_encirclement_damped", "Araba Kalesi hareketliliği %.2fx'e düşürerek yan/arka kuşatmayı %%%.0f sönümledi." % [def_mob_mult, result.flank_rear_damping_ratio * 100.0])

	# --- Matchup #4: Tonyukuk Water & Caravan Attrition ----------------------
	if atk_has_maneuver and atk_maneuver == GameEnums.DecisiveManeuver.TONYUKUK_WATER_CARAVAN_ATTRITION:
		var s_type: GameEnums.SeasonType = season.season_type if season != null else GameEnums.SeasonType.SPRING
		var is_winter: bool = s_type == GameEnums.SeasonType.WINTER or eff_storm
		var reg_water: int = WaterRouteManager.count_registered_water_sources(eff_def_coord)
		var usable_water: int = WaterRouteManager.count_usable_water_sources(eff_def_coord, s_type, is_winter)
		var sabotaged_water: int = WaterRouteManager.count_sabotaged_water_sources(eff_def_coord)
		var water_strain: float = 0.0
		if reg_water > 0:
			water_strain = clampf(float(reg_water - usable_water) / float(reg_water), 0.0, 1.0)
			if sabotaged_water > 0:
				water_strain = maxf(water_strain, clampf(float(sabotaged_water) / float(reg_water), 0.0, 1.0))

		var def_isolated: bool = CommandBus.is_army_supply_isolated(def_army_id) if def_army_id > 0 else false
		var def_sup_def: float = CaravanLogisticsManager.get_army_front_supply_deficit(def_army_id) if def_army_id > 0 else 0.0
		var def_ammo_def: float = CaravanLogisticsManager.get_army_front_ammo_deficit(def_army_id) if def_army_id > 0 else 0.0
		var def_sup_ratio: float = _safe_float(defender.supply_ratio if defender != null else 1.0, 1.0, 0.0, 1.0)
		var caravan_strain: float = clampf((0.65 if def_isolated else 0.0) + def_sup_def + clampf(def_ammo_def / 50.0, 0.0, 0.5) * 0.35 + maxf(0.85 - def_sup_ratio, 0.0), 0.0, 1.0)
		var logistics_strain: float = maxf(water_strain, caravan_strain)

		if def_troops <= 50:
			result.tonyukuk_attrition_triggered = false
			result.tonyukuk_attrition_drain = 0.0
			atk_mult *= 0.85
			result.add_tag("tonyukuk_ineffective_vs_raiders", "Tonyukuk yıpratması kervansız küçük akın birliğine (%d asker) karşı etkisiz kaldı." % def_troops)
		elif logistics_strain >= 0.25 or def_isolated or sabotaged_water > 0 or def_sup_ratio < 0.70:
			var size_vuln: float = clampf((float(def_troops) - 50.0) / 150.0, 0.20, 1.0)
			var drain: float = clampf(size_vuln * (0.30 + 0.70 * logistics_strain) * 0.45, 0.14, 0.45)
			result.tonyukuk_attrition_triggered = true
			result.tonyukuk_attrition_drain = drain
			def_mult *= clampf(1.0 - drain * 0.75, 0.55, 0.90)
			atk_mult *= (1.12 + drain * 0.50)
			coh_mult *= (1.0 + drain * 0.85)
			mor_mult *= (1.0 + drain)
			result.add_tag("tonyukuk_attrition_effective", "Su ve kervan baskısı kalabalık orduyu (%d asker) %%%.0f yıprattı." % [def_troops, drain * 100.0])
		else:
			result.tonyukuk_attrition_triggered = false
			result.tonyukuk_attrition_drain = 0.0
			result.add_tag("tonyukuk_logistics_unstrained", "Hedef ordunun su ve kervan hatları sağlam olduğundan yıpratma kısıtlı kaldı.")

	# --- 5. Final Strict Bounds & Finite Guard -------------------------------
	result.attacker_attack_multiplier = clampf(_safe_float(atk_mult, 1.0, 0.25, 3.0), 0.25, 3.0)
	result.defender_defense_multiplier = clampf(_safe_float(def_mult, 1.0, 0.40, 3.0), 0.40, 3.0)
	result.defender_cohesion_damage_multiplier = clampf(_safe_float(coh_mult, 1.0, 0.25, 3.0), 0.25, 3.0)
	result.defender_morale_damage_multiplier = clampf(_safe_float(mor_mult, 1.0, 0.25, 3.0), 0.25, 3.0)
	result.attacker_fatigue_multiplier = clampf(_safe_float(result.attacker_fatigue_multiplier, 1.0, 0.30, 15.0), 0.30, 15.0)
	result.attacker_mobility_multiplier = clampf(_safe_float(atk_mob_mult, 1.0, 0.20, 2.0), 0.20, 2.0)
	result.defender_mobility_multiplier = clampf(_safe_float(def_mob_mult, 1.0, 0.20, 2.0), 0.20, 2.0)
	return result
