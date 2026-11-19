class_name SystemicSynergyMatrix
extends RefCounted
## Core pure evaluator (rank 2). Stateless Unified Systemic Synergy & Equilibrium
## Matrix connecting Water/Yılkı/Artisans/Commander/Ülüş/Töre/BlackMarket/
## Couriers/Dread/Exile without creating any circular references between
## existing managers.

const RULES_PATH: String = "res://data/rules/systemic_synergy_rules.tres"


class SynergyEvaluationInputs:
	extends RefCounted
	var player_id: int = 1
	var army_id: int = 1
	var region_coord: Vector2i = Vector2i.ZERO
	var season_index: int = 0

	# Eq 1 inputs
	var water_ratio: float = 1.0
	var yilki_ratio: float = 1.0
	var artisan_count: int = 8
	var commander_veteran_score: float = 0.0
	var commander_wound_trauma_pct: float = 0.0
	var commander_age_years: float = 26.0
	var commander_alive: bool = true
	var armor_weather_penalty: float = 0.0
	var ulus_sabotage_penalty: float = 0.0

	# Eq 2 inputs
	var tug_disruption: float = 0.0
	var well_sabotage_severity: float = 0.0
	var zud_severity: float = 0.0
	var direct_regions: int = 1
	var direct_cap: int = 3
	var excess_regions: int = 0
	var regional_market_scarcity: float = 1.0

	# Eq 3 inputs
	var glory_score: float = 0.0
	var kurgan_count: int = 0
	var active_troops: int = 200
	var regency_status: GameEnums.RegencyStatus = GameEnums.RegencyStatus.STABLE_RULE
	var ulus_resentment_ratio: float = 0.0

	# Eq 4 inputs
	var mirage_magnification: float = 1.0
	var commander_legacy_norm: float = 0.0
	var courier_delay_sec: float = 0.0
	var doctrine_exposed_ratio: float = 0.0

	# Eq 5 inputs
	var dread_score: float = 0.0
	var honor_score: float = 50.0
	var threat_events_sum: float = 0.0

	# Resonance triggers
	var has_covert_proxy_war: bool = false
	var has_well_sabotage: bool = false
	var dust_screen_active: bool = false
	var crescent_encirclement_active: bool = false
	var has_steel_or_meteoric_iron: bool = false
	var collapse_state: GameEnums.CollapseState = GameEnums.CollapseState.SOVEREIGN
	var has_intercepted_courier: bool = false
	var has_exile_intel_trade: bool = false


static func _resolve_rules(rules: SystemicSynergyRules = null) -> SystemicSynergyRules:
	if rules != null:
		return rules
	var loaded: SystemicSynergyRules = ResourceLoader.load(RULES_PATH) as SystemicSynergyRules
	if loaded != null:
		return loaded
	return SystemicSynergyRules.new()


static func _safe_ratio(val: float, nan_fallback: float = 0.0) -> float:
	if is_nan(val):
		return clampf(nan_fallback, 0.0, 1.0)
	if is_inf(val):
		return 1.0 if val > 0.0 else 0.0
	return clampf(val, 0.0, 1.0)


static func _safe_finite_nonneg(val: float, max_cap: float = 1000000.0) -> float:
	if is_nan(val):
		return 0.0
	if is_inf(val):
		return max_cap if val > 0.0 else 0.0
	return clampf(val, 0.0, max_cap)


static func _safe_tanh(x: float) -> float:
	if is_nan(x):
		return 0.0
	if is_inf(x):
		return 1.0 if x > 0.0 else -1.0
	var ax: float = absf(x)
	if ax >= 20.0:
		return 1.0 if x > 0.0 else -1.0
	var exp_neg: float = exp(-2.0 * ax)
	var val: float = (1.0 - exp_neg) / (1.0 + exp_neg)
	return val if x >= 0.0 else -val


## Eq 1A: Harmonic Bottleneck for Water (`R_su`) & Cavalry Yılkı (`R_yilki`).
## L_ikmal = 0.25 + 0.75 / (0.55 / max(0.05, R_su) + 0.45 / max(0.05, R_yilki))
static func compute_harmonic_supply_factor(
		water_ratio: float,
		yilki_ratio: float,
		rules: SystemicSynergyRules = null) -> float:
	var r: SystemicSynergyRules = _resolve_rules(rules)
	var r_su: float = _safe_ratio(water_ratio, 0.0)
	var r_yilki: float = _safe_ratio(yilki_ratio, 0.0)
	var denom: float = (r.supply_water_weight / maxf(r.supply_ratio_floor, r_su)) \
		+ (r.supply_yilki_weight / maxf(r.supply_ratio_floor, r_yilki))
	var val: float = r.supply_floor_intercept + (r.supply_harmonic_span / maxf(denom, 0.0001))
	return clampf(val, r.supply_floor_intercept, 1.0)


## Eq 1B: Michaelis-Menten saturation curve for Master Artisans (`A_usta`).
## Q_usta = 1.0 + 0.45 * A_usta / (A_usta + 12.0)
static func compute_artisan_quality_factor(
		artisan_count: int,
		rules: SystemicSynergyRules = null) -> float:
	var r: SystemicSynergyRules = _resolve_rules(rules)
	var a: float = maxf(float(artisan_count), 0.0)
	var val: float = 1.0 + r.artisan_max_bonus * (a / (a + maxf(r.artisan_half_saturation, 0.001)))
	return clampf(val, 1.0, 1.0 + r.artisan_max_bonus)


## Eq 1C: Inverted-U Commander Career Curve (experience gain minus battle scars & aging after 48).
## M_komutan = clamp(1.0 + 0.38*E/(E+50) - 0.30*(W/100)^1.3 - 0.22*(max(0, (age-48)/30))^1.5, 0.55, 1.38)
static func compute_commander_career_factor(
		veteran_score: float,
		wound_trauma_pct: float,
		age_years: float,
		commander_alive: bool = true,
		rules: SystemicSynergyRules = null) -> float:
	var r: SystemicSynergyRules = _resolve_rules(rules)
	if not commander_alive:
		return r.commander_factor_min
	var e: float = _safe_finite_nonneg(veteran_score, 1000000.0)
	var w: float = _safe_finite_nonneg(wound_trauma_pct, 100.0)
	var age: float = _safe_finite_nonneg(age_years, 250.0)

	var exp_term: float = r.commander_exp_max_bonus * (e / (e + maxf(r.commander_exp_half_saturation, 0.001)))
	var wound_term: float = r.commander_wound_penalty_coeff * pow(clampf(w / 100.0, 0.0, 1.0), r.commander_wound_exponent)
	var excess_age_norm: float = clampf((age - r.commander_age_decline_start_years) / maxf(r.commander_age_decline_scale_years, 1.0), 0.0, 10.0)
	var age_term: float = r.commander_age_decline_coeff * pow(excess_age_norm, r.commander_age_decline_exponent)
	return clampf(1.0 + exp_term - wound_term - age_term, r.commander_factor_min, r.commander_factor_max)


## Eq 1 Full: `(1.0 - S_ulus) * Q_usta * L_ikmal * clamp(M_komutan - Y_zirh_hava, 0.35, 1.45)`.
static func compute_combat_power_components(
		ulus_sabotage: float,
		artisan_count: int,
		water_ratio: float,
		yilki_ratio: float,
		veteran_score: float,
		wound_trauma_pct: float,
		age_years: float,
		armor_weather_penalty: float,
		commander_alive: bool = true,
		rules: SystemicSynergyRules = null) -> Dictionary[StringName, float]:
	var r: SystemicSynergyRules = _resolve_rules(rules)
	var l_ikmal: float = compute_harmonic_supply_factor(water_ratio, yilki_ratio, r)
	var q_usta: float = compute_artisan_quality_factor(artisan_count, r)
	var m_komutan: float = compute_commander_career_factor(veteran_score, wound_trauma_pct, age_years, commander_alive, r)
	var s_ulus: float = clampf(_safe_finite_nonneg(ulus_sabotage, r.max_ulus_sabotage_penalty), 0.0, r.max_ulus_sabotage_penalty)
	var y_pen: float = clampf(_safe_finite_nonneg(armor_weather_penalty, r.max_armor_weather_penalty), 0.0, r.max_armor_weather_penalty)
	var env_cmdr: float = clampf(m_komutan - y_pen, r.effective_commander_env_min, r.effective_commander_env_max)
	var total_mult: float = clampf((1.0 - s_ulus) * q_usta * l_ikmal * env_cmdr, 0.0, 3.0)
	return {
		&"L_ikmal": l_ikmal,
		&"Q_usta": q_usta,
		&"M_komutan": m_komutan,
		&"effective_power_mult": total_mult,
	}


## Eq 2: Capped Black Market & Scarcity Elasticity (`F_piyasa_mult <= 3.4x`).
## F_piyasa_mult = 1.0 + 2.4 * tanh((0.90*K_tug + 1.15*W_kuyu + 0.35*Z_zud + 0.22*excess_regions) / (1.20 + 0.65*O_tore))
static func compute_black_market_multiplier(
		tug_disruption: float,
		well_sabotage: float,
		zud_severity: float,
		excess_regions: int,
		honor_score: float,
		rules: SystemicSynergyRules = null) -> float:
	var r: SystemicSynergyRules = _resolve_rules(rules)
	var k_tug: float = _safe_finite_nonneg(tug_disruption, 100.0)
	var w_kuyu: float = _safe_finite_nonneg(well_sabotage, 100.0)
	var z_zud: float = _safe_finite_nonneg(zud_severity, 100.0)
	var ex_reg: float = float(clampi(excess_regions, 0, 100))
	var o_tore: float = clampf(_safe_finite_nonneg(honor_score, 100.0) / 100.0, 0.0, 1.0)

	var numer: float = r.market_tug_disruption_weight * k_tug \
		+ r.market_well_sabotage_weight * w_kuyu \
		+ r.market_zud_weight * z_zud \
		+ r.market_excess_regions_weight * ex_reg
	var denom: float = maxf(r.market_tore_elasticity_base + r.market_tore_honor_damping * o_tore, 0.1)
	var val: float = r.market_base_mult + r.market_tanh_span * _safe_tanh(numer / denom)
	return clampf(val, r.market_base_mult, r.market_max_scarcity_mult)


## Eq 3: Dynamic Kut Entropy / Anti-Snowball Attractor net drift.
## Logarithmic glory/kurgan/honor inflow minus convex army load (N^1.25),
## convex >3-region overextension (excess^1.65), succession crisis, and Ülüş resentment.
static func compute_kut_entropy_drift(
		glory_score: float,
		kurgan_count: int,
		honor_score: float,
		active_troops: int,
		excess_regions: int,
		regency_status: GameEnums.RegencyStatus = GameEnums.RegencyStatus.STABLE_RULE,
		ulus_resentment_ratio: float = 0.0,
		rules: SystemicSynergyRules = null) -> float:
	var r: SystemicSynergyRules = _resolve_rules(rules)
	var g: float = _safe_finite_nonneg(glory_score, 1000.0)
	var k_cnt: int = clampi(kurgan_count, 0, 100)
	var h_norm: float = clampf(_safe_finite_nonneg(honor_score, 100.0) / 100.0, 0.0, 1.0)

	var inflow: float = r.kut_glory_log_weight * log(1.0 + g) \
		+ r.kut_kurgan_weight * log(1.0 + float(k_cnt)) \
		+ r.kut_honor_weight * h_norm

	var n_norm: float = clampf(maxf(float(active_troops), 0.0) / maxf(r.kut_army_norm_reference, 1.0), 0.0, 500.0)
	var ex_reg: int = clampi(excess_regions, 0, 100)
	var crisis_drag: float = 0.0
	if regency_status == GameEnums.RegencyStatus.KURULTAY_SUCCESSION_CRISIS:
		crisis_drag = r.kut_succession_crisis_drag
	elif regency_status == GameEnums.RegencyStatus.AK_SAKALLILAR_REGENCY:
		crisis_drag = r.kut_regency_drag
	var u_res: float = clampf(_safe_finite_nonneg(ulus_resentment_ratio, 1.0), 0.0, 1.0)

	var outflow: float = r.kut_army_convex_weight * pow(n_norm, r.kut_army_norm_exponent) \
		+ r.kut_overextension_weight * pow(float(ex_reg), r.kut_overextension_exponent) \
		+ crisis_drag \
		+ r.kut_ulus_resentment_weight * u_res

	return clampf(inflow - outflow, r.kut_drift_clamp_min, r.kut_drift_clamp_max)


## Eq 4: Logarithmic Courier & Information Tempo.
## T_tempo = clamp(((1 + 0.35*max(0, E_serap - 1) + 0.30*I_gazi) / (1 + 0.45*ln(1 + delay))) * (1 - 0.55*exposed), 0.35, 1.85)
static func compute_courier_tempo_multiplier(
		mirage_magnification: float,
		commander_legacy_norm: float,
		courier_delay_sec: float,
		doctrine_exposed_ratio: float,
		rules: SystemicSynergyRules = null) -> float:
	var r: SystemicSynergyRules = _resolve_rules(rules)
	var e_serap: float = _safe_finite_nonneg(mirage_magnification, 10.0)
	var i_gazi: float = clampf(_safe_finite_nonneg(commander_legacy_norm, 1.0), 0.0, 1.0)
	var delay: float = _safe_finite_nonneg(courier_delay_sec, 100000.0)
	var exposed: float = clampf(_safe_finite_nonneg(doctrine_exposed_ratio, 1.0), 0.0, 1.0)

	var numer: float = 1.0 \
		+ r.tempo_mirage_bonus_weight * maxf(0.0, e_serap - 1.0) \
		+ r.tempo_gazi_bonus_weight * i_gazi
	var denom: float = maxf(1.0 + r.tempo_courier_delay_log_weight * log(1.0 + delay), 1.0)
	var raw_tempo: float = (numer / denom) * (1.0 - r.tempo_exposed_doctrine_penalty * exposed)
	return clampf(raw_tempo, r.tempo_mult_min, r.tempo_mult_max)


## Eq 5: Multiplicative Dread–Honor Coalition Pressure.
## P_koalisyon = (1 + dread / 100) * threat_events_sum * (1 - 0.35 * (honor / 100))
static func compute_coalition_pressure(
		dread_score: float,
		threat_events_sum: float,
		honor_score: float,
		rules: SystemicSynergyRules = null) -> float:
	var r: SystemicSynergyRules = _resolve_rules(rules)
	var dread: float = clampf(_safe_finite_nonneg(dread_score, r.coalition_dread_scale), 0.0, r.coalition_dread_scale)
	var honor: float = clampf(_safe_finite_nonneg(honor_score, r.coalition_honor_scale), 0.0, r.coalition_honor_scale)
	var threats: float = _safe_finite_nonneg(threat_events_sum, r.coalition_pressure_max)
	var dread_mult: float = 1.0 + (dread / maxf(r.coalition_dread_scale, 1.0))
	var honor_damp: float = clampf(1.0 - r.coalition_honor_damping_max * (honor / maxf(r.coalition_honor_scale, 1.0)), 0.1, 1.0)
	return clampf(dread_mult * threats * honor_damp, 0.0, r.coalition_pressure_max)


## Evaluates which of the 5 cross-system Synergy Resonances are simultaneously aligned.
static func detect_resonances(
		inputs: SynergyEvaluationInputs,
		computed_market_mult: float,
		rules: SystemicSynergyRules = null) -> Array[GameEnums.SynergyResonanceId]:
	var list: Array[GameEnums.SynergyResonanceId] = []
	if inputs == null:
		return list
	var r: SystemicSynergyRules = _resolve_rules(rules)

	# 1. SHADOW_FAMINE_STRIKE: Covert Proxy War + Well Sabotage + Black Market Spike
	var eff_market_signal: float = maxf(computed_market_mult, _safe_finite_nonneg(inputs.regional_market_scarcity, 5.0))
	if inputs.has_covert_proxy_war and inputs.has_well_sabotage and eff_market_signal >= r.shadow_famine_min_market_mult:
		list.append(GameEnums.SynergyResonanceId.SHADOW_FAMINE_STRIKE)

	# 2. DREAD_MIRAGE_TRAP: High Dread + Yılkı Dust Screen + Crescent Encirclement
	var dread: float = clampf(_safe_finite_nonneg(inputs.dread_score, 100.0), 0.0, 100.0)
	if dread >= r.dread_mirage_min_dread \
			and (inputs.dust_screen_active or inputs.mirage_magnification > 1.05) \
			and inputs.crescent_encirclement_active:
		list.append(GameEnums.SynergyResonanceId.DREAD_MIRAGE_TRAP)

	# 3. ARTISAN_BORU_SPEARHEAD: Artisan Pool + Veteran Commander + Steel/Meteoric Iron
	var cmdr_vet: float = _safe_finite_nonneg(inputs.commander_veteran_score, 500.0)
	if inputs.artisan_count >= r.artisan_boru_min_artisans \
			and inputs.commander_alive \
			and cmdr_vet >= r.artisan_boru_min_commander_vet \
			and inputs.has_steel_or_meteoric_iron:
		list.append(GameEnums.SynergyResonanceId.ARTISAN_BORU_SPEARHEAD)

	# 4. TORE_KURULTAY_NETWORK: Within Governance Cap (<= 3 regions) + High Honor + Low Ülüş Resentment
	var honor: float = clampf(_safe_finite_nonneg(inputs.honor_score, 100.0), 0.0, 100.0)
	var ulus_res: float = clampf(_safe_finite_nonneg(inputs.ulus_resentment_ratio, 1.0), 0.0, 1.0)
	var not_exile_or_extinct: bool = inputs.collapse_state != GameEnums.CollapseState.HOMELESS_EXILE \
		and inputs.collapse_state != GameEnums.CollapseState.DYNASTY_EXTINCT
	if not_exile_or_extinct \
			and inputs.excess_regions <= 0 \
			and inputs.direct_regions <= r.tore_kurultay_max_direct_regions \
			and honor >= r.tore_kurultay_min_honor \
			and ulus_res <= r.tore_kurultay_max_ulus_resentment:
		list.append(GameEnums.SynergyResonanceId.TORE_KURULTAY_NETWORK)

	# 5. EXILE_KINGMAKER_NET: Homeless Exile + Intercepted Courier + Intelligence Trade
	if inputs.collapse_state == GameEnums.CollapseState.HOMELESS_EXILE \
			and inputs.has_intercepted_courier \
			and inputs.has_exile_intel_trade:
		list.append(GameEnums.SynergyResonanceId.EXILE_KINGMAKER_NET)

	return list


## Pure evaluation of `SynergyEvaluationInputs` returning a finite, bounded `SynergyEvaluationSnapshot`.
static func evaluate_inputs(
		inputs: SynergyEvaluationInputs,
		rules: SystemicSynergyRules = null) -> SynergyEvaluationSnapshot:
	var r: SystemicSynergyRules = _resolve_rules(rules)
	var safe_in: SynergyEvaluationInputs = inputs if inputs != null else SynergyEvaluationInputs.new()
	var snap: SynergyEvaluationSnapshot = SynergyEvaluationSnapshot.new()
	snap.player_id = safe_in.player_id
	snap.army_id = safe_in.army_id
	snap.region_coord = safe_in.region_coord
	snap.season_index = safe_in.season_index

	snap.water_logistics_ratio = _safe_ratio(safe_in.water_ratio, 0.0)
	snap.yilki_remount_ratio = _safe_ratio(safe_in.yilki_ratio, 0.0)

	var eq1: Dictionary[StringName, float] = compute_combat_power_components(
		safe_in.ulus_sabotage_penalty,
		safe_in.artisan_count,
		safe_in.water_ratio,
		safe_in.yilki_ratio,
		safe_in.commander_veteran_score,
		safe_in.commander_wound_trauma_pct,
		safe_in.commander_age_years,
		safe_in.armor_weather_penalty,
		safe_in.commander_alive,
		r)
	snap.supply_bottleneck_factor = eq1[&"L_ikmal"]
	snap.artisan_quality_factor = eq1[&"Q_usta"]
	snap.commander_career_factor = eq1[&"M_komutan"]
	snap.effective_combat_power_mult = eq1[&"effective_power_mult"]

	snap.black_market_scarcity_mult = compute_black_market_multiplier(
		safe_in.tug_disruption,
		safe_in.well_sabotage_severity,
		safe_in.zud_severity,
		safe_in.excess_regions,
		safe_in.honor_score,
		r)

	snap.kut_entropy_net_drift = compute_kut_entropy_drift(
		safe_in.glory_score,
		safe_in.kurgan_count,
		safe_in.honor_score,
		safe_in.active_troops,
		safe_in.excess_regions,
		safe_in.regency_status,
		safe_in.ulus_resentment_ratio,
		r)

	snap.courier_delay_sec = _safe_finite_nonneg(safe_in.courier_delay_sec, 100000.0)
	snap.doctrine_exposed = safe_in.doctrine_exposed_ratio >= 0.5
	snap.courier_tempo_mult = compute_courier_tempo_multiplier(
		safe_in.mirage_magnification,
		safe_in.commander_legacy_norm,
		safe_in.courier_delay_sec,
		safe_in.doctrine_exposed_ratio,
		r)

	snap.dread_score = clampf(_safe_finite_nonneg(safe_in.dread_score, r.coalition_dread_scale), 0.0, r.coalition_dread_scale)
	snap.honor_score = clampf(_safe_finite_nonneg(safe_in.honor_score, r.coalition_honor_scale), 0.0, r.coalition_honor_scale)
	snap.threat_events_sum = _safe_finite_nonneg(safe_in.threat_events_sum, r.coalition_pressure_max)
	snap.coalition_pressure_score = compute_coalition_pressure(
		snap.dread_score,
		snap.threat_events_sum,
		snap.honor_score,
		r)

	snap.active_resonances = detect_resonances(safe_in, snap.black_market_scarcity_mult, r)
	return snap


## Read-only collector gathering live inputs from simulation autoloads without
## introducing any cross-manager dependencies inside those managers.
static func collect_inputs_for_player(
		player_id: int,
		army_id: int = 1,
		region_coord: Vector2i = Vector2i.ZERO,
		active_troops_override: int = -1,
		veteran_score_override: float = -1.0,
		tactics_phase_override: GameEnums.TuranTacticPhase = GameEnums.TuranTacticPhase.RECON_DUST_SCREEN,
		glory_override: float = -1.0,
		remount_ratio_override: float = -1.0) -> SynergyEvaluationInputs:
	var inp: SynergyEvaluationInputs = SynergyEvaluationInputs.new()
	var pid: int = maxi(player_id, 1)
	var aid: int = maxi(army_id, 1)
	inp.player_id = pid
	inp.army_id = aid

	var camp_coord: Vector2i = PastureEcologyManager.get_player_camp_region(pid)
	var target_coord: Vector2i = region_coord if region_coord != Vector2i.ZERO else camp_coord
	inp.region_coord = target_coord

	var cur_season: SeasonData = SeasonManager.get_current_season()
	var s_type: GameEnums.SeasonType = cur_season.season_type if cur_season != null else GameEnums.SeasonType.SPRING
	var is_winter: bool = s_type == GameEnums.SeasonType.WINTER

	# Eq 1 inputs
	var reg_sources: int = WaterRouteManager.count_registered_water_sources(target_coord)
	var usable_sources: int = WaterRouteManager.count_usable_water_sources(target_coord, s_type, is_winter)
	var sabotaged_sources: int = WaterRouteManager.count_sabotaged_water_sources(target_coord)
	if reg_sources > 0:
		inp.water_ratio = clampf(float(usable_sources) / float(reg_sources), 0.0, 1.0)
	else:
		inp.water_ratio = 1.0
	inp.has_well_sabotage = sabotaged_sources > 0
	if reg_sources > 0:
		inp.well_sabotage_severity = float(sabotaged_sources) / float(reg_sources)
	else:
		inp.well_sabotage_severity = 0.0

	if remount_ratio_override >= 0.0 and not is_nan(remount_ratio_override) and not is_inf(remount_ratio_override):
		inp.yilki_ratio = clampf(remount_ratio_override, 0.0, 1.0)
	else:
		inp.yilki_ratio = clampf(float(RegionalMarketEngine.get_player_yilki_herd(pid)) / 60.0, 0.0, 1.0)

	inp.artisan_count = CaravanLogisticsManager.get_artisan_count(pid)

	var s_rules: SuccessionRules = SuccessionManager.get_rules()
	var s_per_y: int = s_rules.seasons_per_year if s_rules != null else 4
	var cmdr: CommanderProfile = SuccessionManager.get_commander_for_army(aid)
	if cmdr != null:
		inp.commander_alive = cmdr.is_alive
		inp.commander_age_years = float(cmdr.age_seasons) / float(maxi(s_per_y, 1))
		inp.commander_veteran_score = veteran_score_override if veteran_score_override >= 0.0 else cmdr.veteran_score
		inp.commander_wound_trauma_pct = clampf(float(cmdr.scars) * 28.0 + (0.0 if cmdr.is_alive else 45.0), 0.0, 100.0)
	else:
		inp.commander_alive = true
		inp.commander_age_years = 26.0
		inp.commander_veteran_score = maxf(veteran_score_override, 0.0)
		inp.commander_wound_trauma_pct = 0.0
	inp.commander_legacy_norm = clampf(inp.commander_veteran_score / 100.0, 0.0, 1.0)

	var front_supply_def: float = CaravanLogisticsManager.get_army_front_supply_deficit(aid)
	var storm_pen: float = 0.15 if BallisticsEngine.is_pre_zud_storm_active() else 0.0
	var active_cat: CataclysmEventData = CataclysmEngine.get_active_region_cataclysm(target_coord)
	var cat_pen: float = 0.15 if active_cat != null else 0.0
	inp.armor_weather_penalty = clampf(storm_pen + cat_pen + front_supply_def * 0.25, 0.0, 0.65)

	var vassals: Array[VassalBeyAssignment] = GovernanceManager.get_vassals_for_suzerain(pid)
	if not vassals.is_empty():
		var sab_sum: float = 0.0
		var res_sum: float = 0.0
		for v: VassalBeyAssignment in vassals:
			if v == null:
				continue
			if v.silent_sabotage_active:
				sab_sum += clampf(1.0 - v.reinforcement_troop_mult, 0.0, 0.75)
			res_sum += clampf((75.0 - v.loyalty) / 75.0, 0.0, 1.0)
		var v_cnt: float = float(vassals.size())
		inp.ulus_sabotage_penalty = clampf(sab_sum / v_cnt, 0.0, 0.75)
		inp.ulus_resentment_ratio = clampf(res_sum / v_cnt, 0.0, 1.0)
	else:
		inp.ulus_sabotage_penalty = 0.0
		inp.ulus_resentment_ratio = 0.0

	# Eq 2 inputs
	inp.direct_regions = GovernanceManager.get_direct_region_count(pid)
	inp.direct_cap = GovernanceManager.get_direct_cap(pid)
	inp.excess_regions = maxi(inp.direct_regions - inp.direct_cap, 0)
	inp.tug_disruption = TerritoryManager.get_caravan_disruption_in_region(target_coord, pid)
	inp.regional_market_scarcity = RegionalMarketEngine.get_regional_scarcity(target_coord, &"steel")
	if is_winter and SeasonManager.get_food_reserve() <= 0:
		inp.zud_severity = 1.0
	elif active_cat != null and active_cat.cataclysm_type == GameEnums.CataclysmType.KARA_ZUD_ICE_TRAP:
		inp.zud_severity = 1.0
	elif is_winter:
		inp.zud_severity = 0.35
	else:
		inp.zud_severity = 0.0

	# Eq 3 inputs
	inp.glory_score = maxf(glory_override, 0.0)
	inp.kurgan_count = TerritoryManager.count_player_kurgans(pid)
	inp.active_troops = active_troops_override if active_troops_override >= 0 else 200
	inp.regency_status = SuccessionManager.get_regency_status(pid)

	# Eq 4 inputs
	inp.dust_screen_active = CourierDispatchSystem.has_dust_decoy(aid)
	inp.mirage_magnification = 2.1 if inp.dust_screen_active else 1.0
	var active_ord: CourierDispatchOrder = CourierDispatchSystem.get_active_order_for_army(aid)
	inp.courier_delay_sec = active_ord.remaining_delay_sec if active_ord != null else 0.0
	var plan_exposed: bool = CourierDispatchSystem.is_player_plan_exposed_by_courier(pid, aid)
	inp.doctrine_exposed_ratio = 1.0 if plan_exposed else 0.0

	# Eq 5 inputs
	inp.dread_score = ReputationAndPactSystem.get_dread_score(pid)
	inp.honor_score = ReputationAndPactSystem.get_honor_score(pid)
	inp.threat_events_sum = DiplomacyManager.get_total_hostile_threat_events_sum()

	# Remaining cross-resonance inputs
	inp.has_covert_proxy_war = ReputationAndPactSystem.has_active_proxy_war_by(pid)
	inp.crescent_encirclement_active = tactics_phase_override == GameEnums.TuranTacticPhase.CRESCENT_ENCIRCLEMENT_TRAP
	inp.has_steel_or_meteoric_iron = ResourceManager.get_amount(pid, &"steel") > 0 \
		or ResourceManager.get_amount(pid, &"meteoric_iron") > 0
	inp.collapse_state = CollapseRecoveryFSM.get_player_state(pid)
	inp.has_intercepted_courier = CourierDispatchSystem.has_ambushed_courier_intercepted_by(pid) \
		or IntelligenceManager.has_intercepted_courier_report_by(pid)
	inp.has_exile_intel_trade = CollapseRecoveryFSM.get_exile_intel_sales_count(pid) > 0

	return inp


## Evaluates live state for `player_id` and optionally broadcasts a typed read-only
## `SynergyEvaluationSnapshot` on `EventBus.systemic_synergy_evaluated`.
static func evaluate_player(
		player_id: int,
		army_id: int = 1,
		region_coord: Vector2i = Vector2i.ZERO,
		publish_bus: bool = true,
		active_troops_override: int = -1,
		veteran_score_override: float = -1.0,
		tactics_phase_override: GameEnums.TuranTacticPhase = GameEnums.TuranTacticPhase.RECON_DUST_SCREEN,
		glory_override: float = -1.0,
		remount_ratio_override: float = -1.0,
		rules: SystemicSynergyRules = null) -> SynergyEvaluationSnapshot:
	var inp: SynergyEvaluationInputs = collect_inputs_for_player(
		player_id,
		army_id,
		region_coord,
		active_troops_override,
		veteran_score_override,
		tactics_phase_override,
		glory_override,
		remount_ratio_override)
	var snap: SynergyEvaluationSnapshot = evaluate_inputs(inp, rules)
	if publish_bus:
		EventBus.systemic_synergy_evaluated.emit(snap)
	return snap
