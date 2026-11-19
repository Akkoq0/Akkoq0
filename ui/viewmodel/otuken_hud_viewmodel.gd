class_name OtukenHudViewModel
extends RefCounted
## UI ViewModel (rank 4). Strictly read-only telemetry aggregator over core
## simulation autoloads (`GameManager`, `SeasonManager`, `ResourceManager`,
## `GovernanceManager`, `SuccessionManager`, `WaterRouteManager`, etc.).
##
## Architectural Guarantee: NEVER mutates any core manager state and NEVER
## dispatches commands. UI components read snapshots or glossary lines here and
## route any gameplay actions exclusively through `CommandBus`.

const KUT_RULES_PATH: String = "res://data/governance/kut_rules.tres"
const SLOT_ECONOMY_WATER: StringName = &"economy_water"
const SLOT_GOVERNANCE_DYNASTY: StringName = &"governance_dynasty"
const SLOT_MILITARY_HERD: StringName = &"military_herd"
const SLOT_WORLD_DIPLOMACY: StringName = &"world_diplomacy"
const SLOT_TERRITORY_ECOLOGY: StringName = &"territory_ecology"


class PulseSummarySnapshot:
	var player_id: int = 1
	var tracked_army_id: int = 1
	var camp_coord: Vector2i = Vector2i.ZERO

	# Card 1: Erzak / Su & Kış Ufku
	var food_reserve: int = 0
	var winter_horizon_seasons: float = 0.0
	var usable_water_sources: int = 1
	var water_crisis_active: bool = false
	var silver_bullion: int = 0
	var steel_stockpile: int = 0
	var jade_stockpile: int = 0
	var market_scarcity_steel: float = 1.0
	var economy_tone: StringName = &"jade"

	# Card 2: Kut & Veraset Dengesi
	var kut_score: float = 75.0
	var legitimacy_multiplier: float = 1.0
	var council_active: bool = false
	var regency_status: GameEnums.RegencyStatus = GameEnums.RegencyStatus.STABLE_RULE
	var regency_tax_multiplier: float = 1.0
	var ruler_name: String = "Kağan"
	var generation: int = 1
	var heir_ready: bool = true
	var heir_amanat_locked: bool = false
	var direct_regions: int = 0
	var direct_cap: int = 3
	var delegated_regions: int = 0
	var silent_sabotage_beys: int = 0
	var kut_tone: StringName = &"jade"

	# Card 3: Yılkı & Manevra Gücü
	var yilki_herd_count: int = 60
	var remount_horse_ratio: float = 1.0
	var supply_isolated: bool = false
	var courier_in_transit: bool = false
	var dust_decoy_active: bool = false
	var caravan_ammo_deficit: float = 0.0
	var expedition_speed_mult: float = 1.0
	var migration_required: bool = false
	var yilki_tone: StringName = &"jade"

	# Card 4: Mevsim / Töre Barışı
	var season_type: GameEnums.SeasonType = GameEnums.SeasonType.SPRING
	var season_display_name: String = "Bahar (Spring)"
	var season_progress: float = 0.0
	var persistent_mode_active: bool = false
	var tore_stage: GameEnums.TorePeaceStage = GameEnums.TorePeaceStage.STAGE_1_FULL_TORE_PEACE
	var personal_peace_hours: float = 0.0
	var owned_regions: int = 0
	var player_kurgans: int = 0
	var total_kurgans: int = 0
	var coalition_active: bool = false
	var collapse_state: GameEnums.CollapseState = GameEnums.CollapseState.SOVEREIGN
	var season_tone: StringName = &"jade"

	# Extra metrics for glossary & drawer telemetry
	var tug_radius_m: float = 120.0
	var jade_authority_mult: float = 1.0
	var word_reliability: float = 80.0
	var dread_score: float = 0.0
	var honor_score: float = 50.0
	var artisan_count: int = 8
	var active_cataclysm_id: StringName = &""
	var active_intrigue_plots: int = 0
	var plague_active: bool = false

	# Phase 26A Unified Systemic Synergy read-only telemetry
	var synergy_combat_power_mult: float = 1.0
	var synergy_black_market_mult: float = 1.0
	var synergy_kut_drift: float = 0.0
	var synergy_courier_tempo_mult: float = 1.0
	var synergy_coalition_pressure: float = 0.0
	var synergy_active_resonance_count: int = 0
	var synergy_primary_resonance_name: String = "Yok"


class CrisisChipDescriptor:
	var crisis_id: StringName = &""
	var title: String = ""
	var detail: String = ""
	var tone_id: StringName = &"ember"
	var target_drawer_slot: StringName = SLOT_ECONOMY_WATER
	var glossary_term: StringName = &"kut"
	var is_urgent: bool = true

	func _init(
			p_id: StringName,
			p_title: String,
			p_detail: String,
			p_tone: StringName,
			p_slot: StringName,
			p_glossary: StringName,
			p_urgent: bool = true) -> void:
		crisis_id = p_id
		title = p_title
		detail = p_detail
		tone_id = p_tone
		target_drawer_slot = p_slot
		glossary_term = p_glossary
		is_urgent = p_urgent


var _player_id: int = 1
var _tracked_army_id: int = 1
var _cached_kut_rules: KutRules = null
var _event_remount_ratio: float = 1.0
var _event_water_crisis: bool = false
var _event_coalition_triggered: bool = false
var _latest_synergy_snapshot: SynergyEvaluationSnapshot = null
var _synergy_cache_fresh: bool = false


func _init(p_player_id: int = 1, p_tracked_army_id: int = 1) -> void:
	_player_id = maxi(p_player_id, 1)
	_tracked_army_id = maxi(p_tracked_army_id, 1)


func set_player_context(p_player_id: int, p_tracked_army_id: int = -1) -> void:
	var prev_pid: int = _player_id
	var prev_aid: int = _tracked_army_id
	_player_id = maxi(p_player_id, 1)
	if p_tracked_army_id > 0:
		_tracked_army_id = p_tracked_army_id
	if _player_id != prev_pid or _tracked_army_id != prev_aid:
		_latest_synergy_snapshot = null
		_synergy_cache_fresh = false


func get_player_id() -> int:
	return _player_id


func get_tracked_army_id() -> int:
	return _tracked_army_id


func notify_remount_ratio_observed(ratio: float) -> void:
	if not is_nan(ratio) and not is_inf(ratio):
		_event_remount_ratio = clampf(ratio, 0.0, 1.0)


func notify_water_crisis_observed(active: bool) -> void:
	_event_water_crisis = active


func notify_coalition_observed(active: bool) -> void:
	_event_coalition_triggered = active


func notify_synergy_snapshot_observed(snapshot: SynergyEvaluationSnapshot) -> void:
	if snapshot == null or not snapshot.is_finite_and_bounded():
		return
	if snapshot.player_id == _player_id:
		_latest_synergy_snapshot = snapshot
		_synergy_cache_fresh = snapshot.army_id == _tracked_army_id


func invalidate_synergy_cache() -> void:
	_synergy_cache_fresh = false


func get_latest_synergy_snapshot() -> SynergyEvaluationSnapshot:
	return _latest_synergy_snapshot


func capture_snapshot() -> PulseSummarySnapshot:
	var snap: PulseSummarySnapshot = PulseSummarySnapshot.new()
	snap.player_id = _player_id
	snap.tracked_army_id = _tracked_army_id

	var kut_rules: KutRules = _get_kut_rules()
	var winter_burn: float = float(kut_rules.winter_food_consumption_per_cycle) if kut_rules != null else 60.0
	var camp_coord: Vector2i = PastureEcologyManager.get_player_camp_region(_player_id)
	snap.camp_coord = camp_coord

	# --- 1. Economy, Food, Water & Winter Horizon ----------------------------
	snap.food_reserve = SeasonManager.get_food_reserve()
	snap.winter_horizon_seasons = float(snap.food_reserve) / maxf(winter_burn, 1.0)
	var cur_season: SeasonData = SeasonManager.get_current_season()
	snap.season_type = cur_season.season_type if cur_season != null else GameEnums.SeasonType.SPRING
	snap.season_display_name = cur_season.display_name if cur_season != null else "Bahar (Spring)"
	snap.season_progress = SeasonManager.get_season_progress()
	var is_winter: bool = snap.season_type == GameEnums.SeasonType.WINTER

	snap.usable_water_sources = WaterRouteManager.count_usable_water_sources(camp_coord, snap.season_type, is_winter)
	snap.water_crisis_active = _event_water_crisis
	snap.silver_bullion = ResourceManager.get_amount(_player_id, &"silver_gold")
	snap.steel_stockpile = ResourceManager.get_amount(_player_id, &"steel")
	snap.jade_stockpile = ResourceManager.get_amount(_player_id, &"jade")
	snap.jade_authority_mult = ResourceManager.calculate_jade_authority_multiplier(_player_id)
	snap.market_scarcity_steel = RegionalMarketEngine.get_regional_scarcity(camp_coord, &"steel")
	snap.artisan_count = CaravanLogisticsManager.get_artisan_count(_player_id)

	if (is_winter and snap.food_reserve <= 0) or snap.water_crisis_active or snap.winter_horizon_seasons < 0.75:
		snap.economy_tone = &"ember"
	elif is_winter or snap.winter_horizon_seasons < 1.5 or snap.market_scarcity_steel >= 1.4:
		snap.economy_tone = &"ice"
	else:
		snap.economy_tone = &"jade"

	# --- 2. Kut, Governance Cap & Succession Balance -------------------------
	snap.kut_score = GameManager.get_kut_score()
	snap.legitimacy_multiplier = GameManager.get_legitimacy_multiplier()
	snap.council_active = GameManager.is_ak_sakallilar_council_active() or CouncilEventEngine.is_crisis_dilemma_pending()
	snap.regency_status = SuccessionManager.get_regency_status(_player_id)
	snap.regency_tax_multiplier = SuccessionManager.get_regency_tax_multiplier(_player_id)

	var dynasty: DynastyRulerProfile = SuccessionManager.get_dynasty(_player_id)
	if dynasty != null:
		snap.ruler_name = String(dynasty.ruler_name)
		snap.generation = dynasty.generation
		snap.heir_amanat_locked = dynasty.heir_held_as_amanat
		snap.heir_ready = dynasty.is_heir_ready(SuccessionManager.get_rules())

	snap.direct_regions = GovernanceManager.get_direct_region_count(_player_id)
	snap.direct_cap = GovernanceManager.get_direct_cap(_player_id)
	snap.delegated_regions = GovernanceManager.get_delegated_region_count(_player_id)
	var vassals: Array[VassalBeyAssignment] = GovernanceManager.get_vassals_for_suzerain(_player_id)
	var sabotage_beys: int = 0
	for v: VassalBeyAssignment in vassals:
		if v != null and v.silent_sabotage_active:
			sabotage_beys += 1
	snap.silent_sabotage_beys = sabotage_beys

	if snap.kut_score < 30.0 or snap.council_active or snap.regency_status == GameEnums.RegencyStatus.KURULTAY_SUCCESSION_CRISIS or snap.silent_sabotage_beys > 0:
		snap.kut_tone = &"ember"
	elif snap.regency_status == GameEnums.RegencyStatus.AK_SAKALLILAR_REGENCY or snap.direct_regions > snap.direct_cap or snap.kut_score < 55.0:
		snap.kut_tone = &"gold"
	else:
		snap.kut_tone = &"jade"

	# --- 3. Yılkı, Supply, Courier & Maneuver Power --------------------------
	snap.yilki_herd_count = RegionalMarketEngine.get_player_yilki_herd(_player_id)
	snap.remount_horse_ratio = _event_remount_ratio
	snap.supply_isolated = CommandBus.is_army_supply_isolated(_tracked_army_id) or ResourceManager.is_camp_supply_cut(_player_id)
	snap.courier_in_transit = CourierDispatchSystem.is_army_awaiting_courier(_tracked_army_id)
	snap.dust_decoy_active = CourierDispatchSystem.has_dust_decoy(_tracked_army_id)
	snap.caravan_ammo_deficit = CaravanLogisticsManager.get_army_front_ammo_deficit(_tracked_army_id)
	snap.expedition_speed_mult = CollapseRecoveryFSM.get_effective_speed_multiplier(_player_id)
	snap.migration_required = PastureEcologyManager.is_migration_required(_player_id) or PastureEcologyManager.is_overgrazing_rebellion_active(_player_id)
	snap.plague_active = SeasonManager.is_army_infected(_tracked_army_id)

	if snap.supply_isolated or snap.remount_horse_ratio < 0.45 or snap.plague_active or snap.migration_required:
		snap.yilki_tone = &"ember"
	elif snap.courier_in_transit or snap.caravan_ammo_deficit > 0.0 or is_winter:
		snap.yilki_tone = &"ice"
	else:
		snap.yilki_tone = &"jade"

	# --- 4. Season, Töre Peace, Territory & Hegemony -------------------------
	snap.persistent_mode_active = GracePeriodManager.is_persistent_mode_active()
	snap.tore_stage = GracePeriodManager.get_global_stage()
	snap.personal_peace_hours = GracePeriodManager.get_remaining_personal_peace_hours(_player_id)
	snap.owned_regions = TerritoryManager.count_owned_regions(_player_id)
	snap.player_kurgans = TerritoryManager.count_player_kurgans(_player_id)
	snap.total_kurgans = TerritoryManager.count_sacred_kurgans()
	snap.tug_radius_m = TerritoryManager.compute_effective_tug_radius(_player_id)
	snap.coalition_active = DiplomacyManager.is_coalition_war_active()
	if not snap.coalition_active and snap.kut_score >= 30.0:
		_event_coalition_triggered = false
	elif _event_coalition_triggered:
		snap.coalition_active = true
	snap.collapse_state = CollapseRecoveryFSM.get_player_state(_player_id)
	snap.word_reliability = ReputationAndPactSystem.get_word_reliability(_player_id)
	snap.dread_score = ReputationAndPactSystem.get_dread_score(_player_id)
	snap.honor_score = ReputationAndPactSystem.get_honor_score(_player_id)
	snap.active_intrigue_plots = KinshipIntrigueManager.get_active_plot_count()

	var cat: CataclysmEventData = CataclysmEngine.get_active_region_cataclysm(camp_coord)
	snap.active_cataclysm_id = cat.cataclysm_id if cat != null else &""

	if snap.coalition_active or snap.active_cataclysm_id != &"" or snap.collapse_state == GameEnums.CollapseState.DYNASTY_EXTINCT:
		snap.season_tone = &"ember"
	elif is_winter:
		snap.season_tone = &"ice"
	elif snap.tore_stage == GameEnums.TorePeaceStage.STAGE_1_FULL_TORE_PEACE or snap.personal_peace_hours > 0.0:
		snap.season_tone = &"jade"
	else:
		snap.season_tone = &"gold"

	# --- 5. Phase 26A Unified Systemic Synergy (Strictly Read-Only) --------
	var syn_snap: SynergyEvaluationSnapshot = null
	if _synergy_cache_fresh \
			and _latest_synergy_snapshot != null \
			and _latest_synergy_snapshot.player_id == _player_id \
			and _latest_synergy_snapshot.army_id == _tracked_army_id:
		syn_snap = _latest_synergy_snapshot
	else:
		syn_snap = SystemicSynergyMatrix.evaluate_player(
			_player_id,
			_tracked_army_id,
			camp_coord,
			false)
	if syn_snap != null:
		snap.synergy_combat_power_mult = syn_snap.effective_combat_power_mult
		snap.synergy_black_market_mult = syn_snap.black_market_scarcity_mult
		snap.synergy_kut_drift = syn_snap.kut_entropy_net_drift
		snap.synergy_courier_tempo_mult = syn_snap.courier_tempo_mult
		snap.synergy_coalition_pressure = syn_snap.coalition_pressure_score
		snap.synergy_active_resonance_count = syn_snap.get_resonance_count()
		snap.synergy_primary_resonance_name = syn_snap.get_primary_resonance_label()

	return snap


func collect_active_crises(snap: PulseSummarySnapshot = null) -> Array[CrisisChipDescriptor]:
	var s: PulseSummarySnapshot = snap if snap != null else capture_snapshot()
	var crises: Array[CrisisChipDescriptor] = []

	if s.council_active or s.kut_score < 30.0:
		crises.append(CrisisChipDescriptor.new(
			&"ak_sakallilar_council",
			"Konsey Krizi",
			"Kut %.0f (<30) · Meşruiyet %%%.0f" % [s.kut_score, s.legitimacy_multiplier * 100.0],
			&"ember",
			SLOT_GOVERNANCE_DYNASTY,
			&"kut"))

	if s.regency_status != GameEnums.RegencyStatus.STABLE_RULE:
		var reg_label: String = "Kurultay Veraset Krizi" if s.regency_status == GameEnums.RegencyStatus.KURULTAY_SUCCESSION_CRISIS else "Konsey Naibliği"
		crises.append(CrisisChipDescriptor.new(
			&"succession_crisis",
			reg_label,
			"Vergi Çarpanı %%%.0f" % (s.regency_tax_multiplier * 100.0),
			&"ember" if s.regency_status == GameEnums.RegencyStatus.KURULTAY_SUCCESSION_CRISIS else &"gold",
			SLOT_GOVERNANCE_DYNASTY,
			&"veraset"))

	if (s.season_type == GameEnums.SeasonType.WINTER and s.food_reserve <= 0) or s.water_crisis_active or s.plague_active:
		var zud_reason: String = "Bozkır Vebası" if s.plague_active else ("Su Kesintisi" if s.water_crisis_active else "Zud Açlığı")
		crises.append(CrisisChipDescriptor.new(
			&"zud_water_crisis",
			zud_reason,
			"Erzak %d · Kış Ufku %.1f Mevsim" % [s.food_reserve, s.winter_horizon_seasons],
			&"ice" if s.water_crisis_active and not s.plague_active else &"ember",
			SLOT_ECONOMY_WATER,
			&"zud"))

	if s.migration_required:
		crises.append(CrisisChipDescriptor.new(
			&"pasture_migration",
			"Otlak Çöküşü",
			"Sefer Arabası göçü zorunlu",
			&"ember",
			SLOT_TERRITORY_ECOLOGY,
			&"yilki"))

	if s.supply_isolated:
		crises.append(CrisisChipDescriptor.new(
			&"supply_isolated",
			"İkmal Kesildi",
			"Ordu #%d hattı koptu" % s.tracked_army_id,
			&"ember",
			SLOT_MILITARY_HERD,
			&"yilki"))

	if s.coalition_active or s.active_intrigue_plots > 0 or s.silent_sabotage_beys > 0:
		var pol_label: String = "Koalisyon Savaşı" if s.coalition_active else "Sessiz Sabotaj / Hizip"
		crises.append(CrisisChipDescriptor.new(
			&"political_threat",
			pol_label,
			"Sabotaj: %d Boy · Hizip: %d" % [s.silent_sabotage_beys, s.active_intrigue_plots],
			&"ember",
			SLOT_WORLD_DIPLOMACY,
			&"ulus"))

	if s.direct_regions > s.direct_cap:
		crises.append(CrisisChipDescriptor.new(
			&"governance_overcap",
			"Yönetişim Aşımı",
			"Doğrudan %d / %d bölge" % [s.direct_regions, s.direct_cap],
			&"gold",
			SLOT_GOVERNANCE_DYNASTY,
			&"ulus"))

	if s.active_cataclysm_id != &"":
		crises.append(CrisisChipDescriptor.new(
			&"steppe_cataclysm",
			"Bozkır Afeti",
			String(s.active_cataclysm_id),
			&"ember",
			SLOT_TERRITORY_ECOLOGY,
			&"zud"))

	if s.collapse_state != GameEnums.CollapseState.SOVEREIGN:
		crises.append(CrisisChipDescriptor.new(
			&"collapse_recovery",
			"Çöküş Rejimi",
			format_collapse_state_short(s.collapse_state),
			&"gold",
			SLOT_WORLD_DIPLOMACY,
			&"kara_borsa"))

	return crises


static func format_collapse_state_short(state: GameEnums.CollapseState) -> String:
	match state:
		GameEnums.CollapseState.TRUCE_WITHDRAWAL:
			return "Ateşkes Çekilmesi"
		GameEnums.CollapseState.VASSAL_BEYLIK:
			return "Tâbi Beylik"
		GameEnums.CollapseState.HOMELESS_EXILE:
			return "Yersiz Yurtsuz"
		GameEnums.CollapseState.FRONTIER_MARCH_LORD:
			return "Uç Beyliği"
		GameEnums.CollapseState.DYNASTY_EXTINCT:
			return "Hanedan Sönümü"
		_:
			return "Egemen"


static func format_tore_stage_short(stage: GameEnums.TorePeaceStage) -> String:
	match stage:
		GameEnums.TorePeaceStage.STAGE_1_FULL_TORE_PEACE:
			return "1. Aşama Barış"
		GameEnums.TorePeaceStage.STAGE_2_BORDER_SKIRMISH:
			return "2. Aşama Akın"
		_:
			return "Topyekûn Bozkır"


static func format_regency_short(status: GameEnums.RegencyStatus) -> String:
	match status:
		GameEnums.RegencyStatus.AK_SAKALLILAR_REGENCY:
			return "Konsey Naibi"
		GameEnums.RegencyStatus.KURULTAY_SUCCESSION_CRISIS:
			return "Veraset Krizi"
		_:
			return "İstikrarlı"


func _get_kut_rules() -> KutRules:
	if _cached_kut_rules == null:
		_cached_kut_rules = ResourceLoader.load(KUT_RULES_PATH) as KutRules
	return _cached_kut_rules
