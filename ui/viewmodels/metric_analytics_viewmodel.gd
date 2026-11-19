class_name MetricAnalyticsViewModel
extends RefCounted
## UI ViewModel (rank 4). Strictly read-only telemetry, time-series buffer,
## 3-season linear projection, +/- factor attribution, Bozkır Vakanüvisi event
## chronicle, and sortable Devlet Defteri aggregator for Faz A.
##
## Architectural Guarantee:
##   - NEVER mutates any core autoload, simulation state, or unit component.
##   - Holds optional scene objects (`MacroWorldState`, `ArmyRegistry`,
##     `ArmyController`) strictly through `WeakRef`.
##   - Rival tribe ledger entries strictly obey Fog-of-War & `AIBeliefModel`
##     public/espionage exposure rules without leaking hidden internal states.

const MAX_HISTORY_POINTS: int = 24
const MAX_CHRONICLE_ENTRIES: int = 80
const PROJECTION_SEASONS_COUNT: int = 3
const DEFAULT_REGION_SIZE_M: float = 16.0
const DEFAULT_GRID_SIZE: Vector2i = Vector2i(8, 8)

const METRIC_NUFUS: StringName = &"nufus"
const METRIC_KUT: StringName = &"kut"
const METRIC_ULUS: StringName = &"ulus"
const METRIC_YILKI: StringName = &"yilki"
const METRIC_SU: StringName = &"su"
const METRIC_HAZINE: StringName = &"hazine"
const METRIC_ORDU: StringName = &"ordu"

const METRIC_ORDER: Array[StringName] = [
	METRIC_NUFUS,
	METRIC_KUT,
	METRIC_ULUS,
	METRIC_YILKI,
	METRIC_SU,
	METRIC_HAZINE,
	METRIC_ORDU,
]

const CHRONICLE_ALL: StringName = &"all"
const CHRONICLE_BATTLE: StringName = &"battle"
const CHRONICLE_AMBUSH_SABOTAGE: StringName = &"ambush_sabotage"
const CHRONICLE_ZUD_ECOLOGY: StringName = &"zud_ecology"
const CHRONICLE_KURULTAY_DIPLOMACY: StringName = &"kurultay_diplomacy"

const LEDGER_TAB_REGIONS: StringName = &"regions"
const LEDGER_TAB_ARMIES: StringName = &"armies"
const LEDGER_TAB_COMMANDERS: StringName = &"commanders"
const LEDGER_TAB_ROUTES: StringName = &"routes"
const LEDGER_TAB_RIVALS: StringName = &"rivals"

const KNOWN_RIVAL_DYNASTY_IDS: Array[StringName] = [
	&"karluk",
	&"kipchak",
	&"oghuz",
]


class TimeSeriesPoint:
	extends RefCounted
	var season_index: int = 0
	var season_label: String = ""
	var value: float = 0.0
	var is_projection: bool = false
	var delta_from_prev: float = 0.0

	func _init(
			p_idx: int = 0,
			p_label: String = "",
			p_value: float = 0.0,
			p_proj: bool = false,
			p_delta: float = 0.0) -> void:
		season_index = p_idx
		season_label = p_label
		value = p_value
		is_projection = p_proj
		delta_from_prev = p_delta


class FactorContribution:
	extends RefCounted
	var factor_id: StringName = &""
	var label: String = ""
	var delta_value: float = 0.0
	var percent_text: String = "0%"
	var is_positive: bool = true
	var tone_id: StringName = &"jade"

	func _init(
			p_id: StringName = &"",
			p_label: String = "",
			p_delta: float = 0.0,
			p_pct_text: String = "0%",
			p_pos: bool = true,
			p_tone: StringName = &"jade") -> void:
		factor_id = p_id
		label = p_label
		delta_value = p_delta
		percent_text = p_pct_text
		is_positive = p_pos
		tone_id = p_tone


class MetricBreakdownSnapshot:
	extends RefCounted
	var metric_id: StringName = &"kut"
	var title: String = ""
	var subtitle: String = ""
	var unit_suffix: String = ""
	var current_value: float = 0.0
	var formatted_value: String = ""
	var min_value: float = 0.0
	var max_value: float = 0.0
	var min_label: String = ""
	var max_label: String = ""
	var trend_delta: float = 0.0
	var tone_id: StringName = &"jade"
	var primary_drawer_slot: StringName = OtukenHudViewModel.SLOT_GOVERNANCE_DYNASTY
	var fallback_drawer_slot: StringName = OtukenHudViewModel.SLOT_GOVERNANCE_DYNASTY
	var quick_action_label: String = ""
	var glossary_term: StringName = &"kut"
	var history_points: Array[TimeSeriesPoint] = []
	var projection_points: Array[TimeSeriesPoint] = []
	var factors: Array[FactorContribution] = []


class ChronicleEntry:
	extends RefCounted
	var entry_id: int = 0
	var category: StringName = &"battle"
	var category_label: String = ""
	var title: String = ""
	var detail: String = ""
	var region_coord: Vector2i = Vector2i.ZERO
	var world_pos: Vector3 = Vector3.ZERO
	var season_label: String = ""
	var tick: int = 0
	var tone_id: StringName = &"gold"


class LedgerColumn:
	extends RefCounted
	var key: String = ""
	var title: String = ""
	var is_numeric: bool = false

	func _init(p_key: String = "", p_title: String = "", p_num: bool = false) -> void:
		key = p_key
		title = p_title
		is_numeric = p_num


class LedgerRow:
	extends RefCounted
	var row_id: String = ""
	var values: Dictionary[String, String] = {}
	var sort_keys: Dictionary[String, float] = {}
	var focus_coord: Vector2i = Vector2i.ZERO
	var has_focus_coord: bool = false
	var tone_id: StringName = &"gold"


class LedgerTableSnapshot:
	extends RefCounted
	var tab_id: StringName = &"regions"
	var tab_title: String = ""
	var columns: Array[LedgerColumn] = []
	var rows: Array[LedgerRow] = []


class TimeSeriesBuffer:
	extends RefCounted
	var points: Array[TimeSeriesPoint] = []


var _player_id: int = 1
var _tracked_army_id: int = 1
var _selected_region: Vector2i = Vector2i.ZERO
var _world_state_ref: WeakRef = null
var _army_registry_ref: WeakRef = null
var _tracked_army_ref: WeakRef = null

var _history_by_metric: Dictionary[StringName, TimeSeriesBuffer] = {}
var _chronicle_entries: Array[ChronicleEntry] = []
var _next_chronicle_id: int = 1
var _season_counter: int = 1
var _last_season_signature: String = ""
var _event_remount_ratio: float = 1.0
var _event_water_crisis: bool = false


func _init(p_player_id: int = 1, p_army_id: int = 1) -> void:
	_player_id = maxi(p_player_id, 1)
	_tracked_army_id = maxi(p_army_id, 1)
	_seed_baseline_histories()


func set_context(p_player_id: int, p_army_id: int = -1, p_region: Vector2i = Vector2i(-999, -999)) -> void:
	_player_id = maxi(p_player_id, 1)
	if p_army_id > 0:
		_tracked_army_id = p_army_id
	if p_region != Vector2i(-999, -999):
		_selected_region = p_region


func bind_world_state(world_state: MacroWorldState) -> void:
	_world_state_ref = weakref(world_state) if world_state != null else null


func bind_army_registry(registry: ArmyRegistry) -> void:
	_army_registry_ref = weakref(registry) if registry != null else null


func bind_tracked_army(army: ArmyController) -> void:
	_tracked_army_ref = weakref(army) if army != null else null
	if army != null:
		if army.army_id > 0:
			_tracked_army_id = army.army_id
		if army.owner_id > 0:
			_player_id = army.owner_id


func notify_remount_ratio_observed(ratio: float) -> void:
	if not is_nan(ratio) and not is_inf(ratio):
		_event_remount_ratio = clampf(ratio, 0.0, 1.0)


func notify_water_crisis_observed(active: bool) -> void:
	_event_water_crisis = active


func reset_history_and_chronicle() -> void:
	_history_by_metric.clear()
	_chronicle_entries.clear()
	_next_chronicle_id = 1
	_season_counter = 1
	_last_season_signature = ""
	_seed_baseline_histories()


func coord_to_world_pos(coord: Vector2i) -> Vector3:
	if _world_state_ref != null:
		var ws_obj: Object = _world_state_ref.get_ref()
		if ws_obj != null:
			var ws: MacroWorldState = ws_obj as MacroWorldState
			if ws != null:
				return ws.coord_to_world(coord)
	return Vector3(
		(float(coord.x) + 0.5 - float(DEFAULT_GRID_SIZE.x) * 0.5) * DEFAULT_REGION_SIZE_M,
		0.0,
		(float(coord.y) + 0.5 - float(DEFAULT_GRID_SIZE.y) * 0.5) * DEFAULT_REGION_SIZE_M)


func _current_season_label(suffix_idx: int = -1) -> String:
	var s: SeasonData = SeasonManager.get_current_season()
	var base: String = "Bahar"
	if s != null:
		if s.season_type == GameEnums.SeasonType.SPRING:
			base = "Bahar"
		elif s.season_type == GameEnums.SeasonType.SUMMER:
			base = "Yaz"
		elif s.season_type == GameEnums.SeasonType.AUTUMN:
			base = "Güz"
		else:
			base = "Kış"
	var num: int = suffix_idx if suffix_idx > 0 else _season_counter
	return "%s M%d" % [base, num]


func _season_short_from_index(idx: int) -> String:
	var m: int = posmod(idx, 4)
	if m == 0:
		return "Bahar"
	elif m == 1:
		return "Yaz"
	elif m == 2:
		return "Güz"
	return "Kış"


func _resolve_tracked_army() -> ArmyController:
	if _tracked_army_ref != null:
		var direct_obj: Object = _tracked_army_ref.get_ref()
		if direct_obj != null and is_instance_valid(direct_obj):
			var direct: ArmyController = direct_obj as ArmyController
			if direct != null:
				return direct
	if _army_registry_ref != null:
		var reg_obj: Object = _army_registry_ref.get_ref()
		if reg_obj != null and is_instance_valid(reg_obj):
			var reg: ArmyRegistry = reg_obj as ArmyRegistry
			if reg != null:
				return reg.get_army(_tracked_army_id)
	return null


func _compute_live_metric_value(metric_id: StringName) -> float:
	var pid: int = _player_id
	var aid: int = _tracked_army_id
	var camp_coord: Vector2i = PastureEcologyManager.get_player_camp_region(pid)
	var cur_season: SeasonData = SeasonManager.get_current_season()
	var s_type: GameEnums.SeasonType = cur_season.season_type if cur_season != null else GameEnums.SeasonType.SPRING
	var is_winter: bool = s_type == GameEnums.SeasonType.WINTER

	match metric_id:
		METRIC_NUFUS:
			var core_pop: int = CaptiveLaborManager.get_core_clan_population(pid)
			var artisans: int = CaravanLogisticsManager.get_artisan_count(pid)
			var captives: int = CaptiveLaborManager.get_captured_slave_workers(pid)
			return float(core_pop + artisans + int(roundf(float(captives) * 0.5)))
		METRIC_KUT:
			return clampf(GameManager.get_kut_score(), 0.0, 100.0)
		METRIC_ULUS:
			return _compute_ulus_fulfillment_pct(pid)
		METRIC_YILKI:
			return float(RegionalMarketEngine.get_player_yilki_herd(pid))
		METRIC_SU:
			var reg_wells: int = WaterRouteManager.count_registered_water_sources(camp_coord)
			if reg_wells <= 0:
				return 35.0 if (_event_water_crisis or is_winter) else 100.0
			var usable: int = WaterRouteManager.count_usable_water_sources(camp_coord, s_type, is_winter)
			var ratio: float = clampf(float(usable) / float(reg_wells), 0.0, 1.0)
			if _event_water_crisis:
				ratio = minf(ratio, 0.35)
			return ratio * 100.0
		METRIC_HAZINE:
			var silver: int = ResourceManager.get_amount(pid, &"silver_gold")
			var steel: int = ResourceManager.get_amount(pid, &"steel")
			return float(silver) + float(steel) * 2.0
		METRIC_ORDU:
			return _compute_army_readiness_pct(pid, aid)
	return 0.0


func _compute_ulus_fulfillment_pct(pid: int) -> float:
	var vassals: Array[VassalBeyAssignment] = GovernanceManager.get_vassals_for_suzerain(pid)
	var strain: Dictionary[StringName, float] = GovernanceManager.evaluate_governance_strain(pid, false)
	var tax_eff: float = 1.0
	if strain.has(&"tax_efficiency"):
		tax_eff = strain[&"tax_efficiency"]
	if vassals.is_empty():
		return clampf(tax_eff * 100.0, 0.0, 100.0)
	var total_share_ratio: float = 0.0
	var active_count: int = 0
	for v: VassalBeyAssignment in vassals:
		if v == null:
			continue
		active_count += 1
		var promised: float = maxf(v.promised_ulus_share, 0.01)
		var delivery_ratio: float = clampf(v.delivered_ulus_share / promised, 0.0, 1.2)
		var sabotage_pen: float = 0.28 if v.silent_sabotage_active else 0.0
		var loyalty_factor: float = clampf(v.loyalty / 100.0, 0.25, 1.0)
		total_share_ratio += clampf((delivery_ratio * 0.65 + loyalty_factor * 0.35) - sabotage_pen, 0.0, 1.0)
	var avg_vassal: float = (total_share_ratio / float(active_count)) if active_count > 0 else 1.0
	return clampf((avg_vassal * 0.75 + tax_eff * 0.25) * 100.0, 0.0, 100.0)


func _compute_army_readiness_pct(pid: int, aid: int) -> float:
	var army_ctrl: ArmyController = _resolve_tracked_army()
	var supply_ratio: float = 0.0 if CommandBus.is_army_supply_isolated(aid) else 1.0
	var morale_ratio: float = 0.85
	var ammo_deficit: float = CaravanLogisticsManager.get_army_front_ammo_deficit(aid)
	var quiver_ratio: float = clampf(1.0 - ammo_deficit / 100.0, 0.0, 1.0)
	var remount: float = _event_remount_ratio
	if army_ctrl != null:
		var c_stats: CombatantStats = army_ctrl.get_combatant_stats()
		if c_stats != null:
			supply_ratio = clampf(c_stats.supply_ratio, 0.0, 1.0)
			morale_ratio = clampf(c_stats.morale / 100.0, 0.0, 1.0)
			quiver_ratio = clampf(c_stats.quiver_ammo_ratio, 0.0, 1.0)
			remount = clampf(c_stats.remount_horse_ratio, 0.0, 1.0)
		elif army_ctrl.supply != null:
			supply_ratio = clampf(army_ctrl.supply.get_supply_ratio(), 0.0, 1.0)
			remount = clampf(army_ctrl.supply.get_remount_horse_ratio(), 0.0, 1.0)
			quiver_ratio = clampf(army_ctrl.supply.get_quiver_ammo_reserve() / 100.0, 0.0, 1.0)
	var deficit: float = CaravanLogisticsManager.get_army_front_supply_deficit(aid)
	var exposed: bool = CourierDispatchSystem.is_player_plan_exposed_by_courier(pid, aid)
	var base_pct: float = (supply_ratio * 0.35 + morale_ratio * 0.30 + quiver_ratio * 0.20 + remount * 0.15) * 100.0
	base_pct -= clampf(deficit * 45.0, 0.0, 30.0)
	if exposed:
		base_pct -= 12.0
	return clampf(base_pct, 0.0, 100.0)


func _seed_baseline_histories() -> void:
	for metric_id: StringName in METRIC_ORDER:
		var live_val: float = _compute_live_metric_value(metric_id)
		var buf: TimeSeriesBuffer = TimeSeriesBuffer.new()
		var prev_val: float = live_val
		var offsets: Array[float] = [-0.10, -0.07, -0.04, -0.05, -0.02, 0.0]
		for i: int in range(offsets.size()):
			var val: float = maxf(live_val * (1.0 + offsets[i]), 0.0)
			if metric_id == METRIC_KUT or metric_id == METRIC_ULUS or metric_id == METRIC_SU or metric_id == METRIC_ORDU:
				val = clampf(live_val + offsets[i] * 60.0, 0.0, 100.0)
			elif metric_id == METRIC_NUFUS or metric_id == METRIC_YILKI:
				val = roundf(maxf(live_val + offsets[i] * 80.0, 1.0))
			var d: float = (val - prev_val) if i > 0 else 0.0
			prev_val = val
			buf.points.append(TimeSeriesPoint.new(i + 1, "%s M%d" % [_season_short_from_index(i), i + 1], val, false, d))
		_history_by_metric[metric_id] = buf
	_season_counter = 6


func record_season_point(custom_label: String = "") -> void:
	_season_counter += 1
	var lbl: String = custom_label if not custom_label.is_empty() else _current_season_label(_season_counter)
	for metric_id: StringName in METRIC_ORDER:
		var val: float = _compute_live_metric_value(metric_id)
		var arr: Array[TimeSeriesPoint] = _get_or_init_series(metric_id)
		var prev_v: float = arr[arr.size() - 1].value if not arr.is_empty() else val
		arr.append(TimeSeriesPoint.new(_season_counter, lbl, val, false, val - prev_v))
		while arr.size() > MAX_HISTORY_POINTS:
			arr.remove_at(0)
		var buf: TimeSeriesBuffer = TimeSeriesBuffer.new()
		buf.points = arr
		_history_by_metric[metric_id] = buf


func _sync_latest_history_point(metric_id: StringName, live_val: float) -> void:
	var cur_s: SeasonData = SeasonManager.get_current_season()
	var sig: String = cur_s.display_name if cur_s != null else "Bahar"
	if not _last_season_signature.is_empty() and sig != _last_season_signature:
		_last_season_signature = sig
		record_season_point()
		return
	_last_season_signature = sig
	var arr: Array[TimeSeriesPoint] = _get_or_init_series(metric_id)
	if arr.is_empty():
		arr.append(TimeSeriesPoint.new(_season_counter, _current_season_label(_season_counter), live_val, false, 0.0))
	else:
		var last_idx: int = arr.size() - 1
		var prev_v: float = arr[last_idx - 1].value if last_idx > 0 else live_val
		arr[last_idx].value = live_val
		arr[last_idx].delta_from_prev = live_val - prev_v
	var buf: TimeSeriesBuffer = TimeSeriesBuffer.new()
	buf.points = arr
	_history_by_metric[metric_id] = buf


func _get_or_init_series(metric_id: StringName) -> Array[TimeSeriesPoint]:
	if _history_by_metric.has(metric_id):
		var buf: TimeSeriesBuffer = _history_by_metric[metric_id]
		if buf != null and not buf.points.is_empty():
			return buf.points
	_seed_baseline_histories()
	if _history_by_metric.has(metric_id):
		var seeded_buf: TimeSeriesBuffer = _history_by_metric[metric_id]
		if seeded_buf != null:
			return seeded_buf.points
	return []


func capture_metric_breakdown(metric_id: StringName) -> MetricBreakdownSnapshot:
	var target_id: StringName = metric_id if METRIC_ORDER.has(metric_id) else METRIC_KUT
	var live_val: float = _compute_live_metric_value(target_id)
	_sync_latest_history_point(target_id, live_val)

	var snap: MetricBreakdownSnapshot = MetricBreakdownSnapshot.new()
	snap.metric_id = target_id
	snap.current_value = live_val
	_populate_metric_metadata(snap)
	snap.factors = _build_factors_for_metric(target_id)
	snap.history_points = _get_or_init_series(target_id).duplicate()

	if not snap.history_points.is_empty():
		var min_v: float = snap.history_points[0].value
		var max_v: float = snap.history_points[0].value
		var min_lbl: String = snap.history_points[0].season_label
		var max_lbl: String = snap.history_points[0].season_label
		for pt: TimeSeriesPoint in snap.history_points:
			if pt.value < min_v:
				min_v = pt.value
				min_lbl = pt.season_label
			if pt.value > max_v:
				max_v = pt.value
				max_lbl = pt.season_label
		snap.min_value = min_v
		snap.max_value = max_v
		snap.min_label = min_lbl
		snap.max_label = max_lbl
		var last_pt: TimeSeriesPoint = snap.history_points[snap.history_points.size() - 1]
		snap.trend_delta = last_pt.delta_from_prev

	var slope: float = _compute_projection_slope(target_id, snap.history_points, snap.factors)
	snap.projection_points = _build_projection_points(target_id, live_val, slope)
	if snap.trend_delta < -0.5 or (snap.unit_suffix == "%" and live_val < 50.0) or (target_id == METRIC_KUT and live_val < 40.0):
		snap.tone_id = &"ember"
	elif slope < 0.0:
		snap.tone_id = &"ice"
	else:
		snap.tone_id = &"jade"
	return snap


func _populate_metric_metadata(snap: MetricBreakdownSnapshot) -> void:
	match snap.metric_id:
		METRIC_NUFUS:
			snap.title = "Nüfus & Zanaatkâr Gücü"
			snap.subtitle = "Çekirdek Boy · Usta Demirciler · Tâbi İşgücü"
			snap.unit_suffix = ""
			snap.formatted_value = "%.0f Kişi" % snap.current_value
			snap.primary_drawer_slot = OtukenHudViewModel.SLOT_GOVERNANCE_DYNASTY
			snap.fallback_drawer_slot = OtukenHudViewModel.SLOT_GOVERNANCE_DYNASTY
			snap.quick_action_label = "Egemenlik & Veraset Çekmecesini Aç"
			snap.glossary_term = &"kut"
		METRIC_KUT:
			snap.title = "Kut & Egemenlik Meşruiyeti"
			snap.subtitle = "İlahi Yetki · Doğrudan Yönetim Sınırı · Meclis Baskısı"
			snap.unit_suffix = ""
			snap.formatted_value = "%.1f / 100" % snap.current_value
			snap.primary_drawer_slot = OtukenHudViewModel.SLOT_GOVERNANCE_DYNASTY
			snap.fallback_drawer_slot = OtukenHudViewModel.SLOT_GOVERNANCE_DYNASTY
			snap.quick_action_label = "Kut & Kurultay Çekmecesini Aç"
			snap.glossary_term = &"kut"
		METRIC_ULUS:
			snap.title = "Ülüş & Tâbi Bey Uyumu"
			snap.subtitle = "Toy Payı Teslimatı · Vergi Verimi · Sessiz Sabotaj Riski"
			snap.unit_suffix = "%"
			snap.formatted_value = "%%%.0f" % snap.current_value
			snap.primary_drawer_slot = OtukenHudViewModel.SLOT_GOVERNANCE_DYNASTY
			snap.fallback_drawer_slot = OtukenHudViewModel.SLOT_GOVERNANCE_DYNASTY
			snap.quick_action_label = "Ülüş & Beyler Çekmecesini Aç"
			snap.glossary_term = &"ulus"
		METRIC_YILKI:
			snap.title = "Yılkı Sürüsü & Yedek At"
			snap.subtitle = "Otlak Kapasitesi · Göç Baskısı · Manevra Yedekleri"
			snap.unit_suffix = "baş"
			snap.formatted_value = "%.0f Baş" % snap.current_value
			snap.primary_drawer_slot = OtukenHudViewModel.SLOT_MILITARY_HERD
			snap.fallback_drawer_slot = OtukenHudViewModel.SLOT_MILITARY_HERD
			snap.quick_action_label = "Yılkı & Ordu Çekmecesini Aç"
			snap.glossary_term = &"yilki"
		METRIC_SU:
			snap.title = "Su Kaynakları & Arılık"
			snap.subtitle = "Kuyular & Bozkır Çayları · Zud Donu · Kuyu Sabotajı"
			snap.unit_suffix = "%"
			snap.formatted_value = "%%%.0f" % snap.current_value
			snap.primary_drawer_slot = OtukenHudViewModel.SLOT_ECONOMY_WATER
			snap.fallback_drawer_slot = OtukenHudViewModel.SLOT_ECONOMY_WATER
			snap.quick_action_label = "Ekoloji & Su Çekmecesini Aç"
			snap.glossary_term = &"zud"
		METRIC_HAZINE:
			snap.title = "Hazine & Bölge Piyasası"
			snap.subtitle = "Gümüş/Altın · Çelik · Piyasa Kıtlığı & Kara Borsa"
			snap.unit_suffix = ""
			snap.formatted_value = "%.0f Gümüş" % snap.current_value
			snap.primary_drawer_slot = OtukenHudViewModel.SLOT_ECONOMY_WATER
			snap.fallback_drawer_slot = OtukenHudViewModel.SLOT_ECONOMY_WATER
			snap.quick_action_label = "Hazine & Piyasa Çekmecesini Aç"
			snap.glossary_term = &"kara_borsa"
		METRIC_ORDU:
			snap.title = "Ordu & İkmal Hazırlığı"
			snap.subtitle = "İkmal Hattı · Sadak Oku · Moral · Ulak Güvenliği"
			snap.unit_suffix = "%"
			snap.formatted_value = "%%%.0f" % snap.current_value
			snap.primary_drawer_slot = &"tactical_command"
			snap.fallback_drawer_slot = OtukenHudViewModel.SLOT_MILITARY_HERD
			snap.quick_action_label = "Taktik & Komuta Çekmecesini Aç"
			snap.glossary_term = &"turan_hilali"


func _build_factors_for_metric(metric_id: StringName) -> Array[FactorContribution]:
	var pid: int = _player_id
	var aid: int = _tracked_army_id
	var camp: Vector2i = PastureEcologyManager.get_player_camp_region(pid)
	var syn: SynergyEvaluationSnapshot = SystemicSynergyMatrix.evaluate_player(pid, aid, camp, false)
	var factors: Array[FactorContribution] = []

	match metric_id:
		METRIC_NUFUS:
			var core_pop: int = CaptiveLaborManager.get_core_clan_population(pid)
			var artisans: int = CaravanLogisticsManager.get_artisan_count(pid)
			var captives: int = CaptiveLaborManager.get_captured_slave_workers(pid)
			var revolt_risk: float = CaptiveLaborManager.get_slave_revolt_risk(pid)
			factors.append(FactorContribution.new(&"core_clan", "+ Çekirdek Boy Obası", float(core_pop), "+%d" % core_pop, true, &"jade"))
			factors.append(FactorContribution.new(&"artisans", "+ Usta Zanaatkâr Loncası", float(artisans), "+%d" % artisans, true, &"jade"))
			if captives > 0:
				factors.append(FactorContribution.new(&"captives", "+ Tutsak İşgücü Katkısı", float(captives) * 0.5, "+%d" % int(roundf(float(captives) * 0.5)), true, &"ice"))
			if revolt_risk > 0.20:
				factors.append(FactorContribution.new(&"revolt_risk", "- Tutsak İsyan Baskısı", -revolt_risk * 20.0, "-%%%.0f risk" % (revolt_risk * 100.0), false, &"ember"))
			if SeasonManager.get_food_reserve() < 40:
				factors.append(FactorContribution.new(&"food_strain", "- Kış Erzak Daralması", -12.0, "-%10", false, &"ember"))

		METRIC_KUT:
			var jade_mult: float = ResourceManager.calculate_jade_authority_multiplier(pid)
			var strain: Dictionary[StringName, float] = GovernanceManager.evaluate_governance_strain(pid, false)
			var extra_reg: int = int(strain[&"extra_regions"]) if strain.has(&"extra_regions") else 0
			var kut_drain: float = strain[&"kut_drain"] if strain.has(&"kut_drain") else 0.0
			var drift: float = syn.kut_entropy_net_drift if syn != null else 0.0
			var honor: float = ReputationAndPactSystem.get_honor_score(pid)
			var word_rel: float = ReputationAndPactSystem.get_word_reliability(pid)
			factors.append(FactorContribution.new(&"jade_tamga", "+ Yeşim Tamga Otoritesi", (jade_mult - 1.0) * 15.0, "%.2fx" % jade_mult, true, &"jade"))
			factors.append(FactorContribution.new(&"honor_word", "+ Töre Saygınlığı & Söz Güveni", (honor + word_rel - 100.0) * 0.15, "Onur %.0f" % honor, (honor + word_rel) >= 100.0, &"jade"))
			if extra_reg > 0:
				factors.append(FactorContribution.new(&"overextension", "- Doğrudan Yönetim Aşımı (+%d Bölge)" % extra_reg, -kut_drain, "-%.1f/M" % kut_drain, false, &"ember"))
			if drift < 0.0:
				factors.append(FactorContribution.new(&"synergy_drift", "- Sistemik Kut Kaybı (Entropy)", drift, "%.2f/M" % drift, false, &"ember"))
			elif drift > 0.0:
				factors.append(FactorContribution.new(&"synergy_drift", "+ Sistemik Kut Yükselişi", drift, "+%.2f/M" % drift, true, &"jade"))
			if GameManager.is_ak_sakallilar_council_active():
				factors.append(FactorContribution.new(&"council", "- Ak Sakallılar Meclis Kısıtı", -15.0, "-%15 meşr.", false, &"ember"))

		METRIC_ULUS:
			var vassals: Array[VassalBeyAssignment] = GovernanceManager.get_vassals_for_suzerain(pid)
			var direct_cnt: int = GovernanceManager.get_direct_region_count(pid)
			var cap: int = GovernanceManager.get_direct_cap(pid)
			var g_strain: Dictionary[StringName, float] = GovernanceManager.evaluate_governance_strain(pid, false)
			var tax_eff: float = g_strain[&"tax_efficiency"] if g_strain.has(&"tax_efficiency") else 1.0
			factors.append(FactorContribution.new(&"direct_tax", "+ Doğrudan Oba Vergi Verimi", tax_eff * 100.0 - 100.0, "%%%.0f verim" % (tax_eff * 100.0), tax_eff >= 0.85, &"jade" if tax_eff >= 0.85 else &"ember"))
			var sab_count: int = 0
			var avg_loy: float = 0.0
			for v: VassalBeyAssignment in vassals:
				if v != null:
					avg_loy += v.loyalty
					if v.silent_sabotage_active:
						sab_count += 1
			if not vassals.is_empty():
				avg_loy /= float(vassals.size())
				factors.append(FactorContribution.new(&"vassal_loyalty", "+ Tâbi Bey Sadakat Ort.", (avg_loy - 50.0) * 0.4, "%.0f/100" % avg_loy, avg_loy >= 50.0, &"jade" if avg_loy >= 50.0 else &"ember"))
			else:
				factors.append(FactorContribution.new(&"no_vassals", "+ Merkezî Tek Elden İdare (%d/%d)" % [direct_cnt, cap], 5.0, "Tam", true, &"ice"))
			if sab_count > 0:
				factors.append(FactorContribution.new(&"silent_sabotage", "- Sessiz Ülüş Sabotajı (%d Bey)" % sab_count, -float(sab_count) * 18.0, "-%d bey" % sab_count, false, &"ember"))

		METRIC_YILKI:
			var herd: int = RegionalMarketEngine.get_player_yilki_herd(pid)
			var cap: float = PastureEcologyManager.get_region_pasture_capacity(camp)
			var starving: bool = PastureEcologyManager.is_livestock_starving(pid)
			var dust: bool = CourierDispatchSystem.has_dust_decoy(aid)
			factors.append(FactorContribution.new(&"herd_base", "+ Sürü & Otlak Beslenmesi", float(herd) * (cap / 100.0), "Otlak %.0f%%" % cap, cap >= 40.0, &"jade" if cap >= 40.0 else &"ember"))
			factors.append(FactorContribution.new(&"remount", "+ Savaş Yedek At Oranı", (_event_remount_ratio - 0.5) * 20.0, "%%%.0f" % (_event_remount_ratio * 100.0), _event_remount_ratio >= 0.65, &"jade" if _event_remount_ratio >= 0.65 else &"ember"))
			if starving:
				factors.append(FactorContribution.new(&"pasture_collapse", "- Aşırı Otlatma & Sürü Açlığı", -22.0, "ACİL GÖÇ", false, &"ember"))
			if dust:
				factors.append(FactorContribution.new(&"dust_screen", "- Toz Perdesi Yanıltma Yükü", -6.0, "Aktif", false, &"ice"))

		METRIC_SU:
			var cur_s: SeasonData = SeasonManager.get_current_season()
			var stype: GameEnums.SeasonType = cur_s.season_type if cur_s != null else GameEnums.SeasonType.SPRING
			var is_w: bool = stype == GameEnums.SeasonType.WINTER
			var reg_w: int = WaterRouteManager.count_registered_water_sources(camp)
			var usable_w: int = WaterRouteManager.count_usable_water_sources(camp, stype, is_w)
			var sab_w: int = WaterRouteManager.count_sabotaged_water_sources(camp)
			factors.append(FactorContribution.new(&"usable_wells", "+ Sağlam Su Kuyuları", float(usable_w) * 25.0, "%d/%d" % [usable_w, maxi(reg_w, usable_w)], usable_w > 0, &"jade" if usable_w > 0 else &"ember"))
			if sab_w > 0:
				factors.append(FactorContribution.new(&"sabotaged_wells", "- Kuyu Sabotajı / Kavruk Bozkır", -float(sab_w) * 35.0, "%d kirli" % sab_w, false, &"ember"))
			if is_w:
				factors.append(FactorContribution.new(&"winter_freeze", "- Kış / Zud Çay Donması", -25.0, "Buzul", false, &"ice"))

		METRIC_HAZINE:
			var silver: int = ResourceManager.get_amount(pid, &"silver_gold")
			var steel: int = ResourceManager.get_amount(pid, &"steel")
			var scarcity: float = RegionalMarketEngine.get_regional_scarcity(camp, &"steel")
			var reg_mult: float = SuccessionManager.get_regency_tax_multiplier(pid)
			var g_st: Dictionary[StringName, float] = GovernanceManager.evaluate_governance_strain(pid, false)
			var t_eff: float = g_st[&"tax_efficiency"] if g_st.has(&"tax_efficiency") else 1.0
			factors.append(FactorContribution.new(&"bullion_res", "+ Gümüş/Altın & Çelik Stoğu", float(silver) * 0.25 + float(steel) * 0.4, "%d G · %d Ç" % [silver, steel], true, &"jade"))
			factors.append(FactorContribution.new(&"tax_mult", "+ Vergi & Naiblik Çarpanı", (t_eff * reg_mult - 1.0) * 50.0, "%.2fx" % (t_eff * reg_mult), t_eff * reg_mult >= 0.85, &"jade" if t_eff * reg_mult >= 0.85 else &"ember"))
			if scarcity > 1.10:
				factors.append(FactorContribution.new(&"market_scarcity", "- Kervan Kesintisi & Çelik Kıtlığı", -(scarcity - 1.0) * 30.0, "%.2fx kıtlık" % scarcity, false, &"ember"))

		METRIC_ORDU:
			var army_ctrl: ArmyController = _resolve_tracked_army()
			var c_stats_o: CombatantStats = army_ctrl.get_combatant_stats() if army_ctrl != null else null
			var ctrl_troops: int = c_stats_o.troop_count if c_stats_o != null else 0
			var riders: int = maxi(CommandBus.get_army_rider_count(aid), ctrl_troops)
			var is_iso: bool = CommandBus.is_army_supply_isolated(aid)
			var steel_q: float = CaravanLogisticsManager.get_steel_quality_multiplier(pid)
			var exposed: bool = CourierDispatchSystem.is_player_plan_exposed_by_courier(pid, aid)
			var ammo_def: float = CaravanLogisticsManager.get_army_front_ammo_deficit(aid)
			var power_m: float = syn.effective_combat_power_mult if syn != null else 1.0
			factors.append(FactorContribution.new(&"combat_power", "+ Sistemik Savaş & Demir Kalitesi", (power_m * steel_q - 1.0) * 35.0, "%.2fx · %d atl" % [power_m, riders], power_m >= 0.90, &"jade" if power_m >= 0.90 else &"ember"))
			if is_iso:
				factors.append(FactorContribution.new(&"supply_cut", "- İkmal Hattı Kesik", -35.0, "-%35 hazırlık", false, &"ember"))
			else:
				factors.append(FactorContribution.new(&"supply_ok", "+ Kesintisiz Menzil & Sadak", 15.0, "Bağlı", true, &"jade"))
			if ammo_def > 0.5:
				factors.append(FactorContribution.new(&"ammo_gap", "- Cephe Sadak Mühimmat Açığı", -ammo_def, "-%.1f ok" % ammo_def, false, &"ember"))
			if exposed:
				factors.append(FactorContribution.new(&"plan_leak", "- Ulak Pususuyla Plan İfşası", -18.0, "İFŞA", false, &"ember"))

	return factors


func _compute_projection_slope(
		metric_id: StringName,
		history: Array[TimeSeriesPoint],
		factors: Array[FactorContribution]) -> float:
	var hist_slope: float = 0.0
	if history.size() >= 2:
		var last: float = history[history.size() - 1].value
		var prev: float = history[history.size() - 2].value
		hist_slope = last - prev
	var factor_bias: float = 0.0
	for f: FactorContribution in factors:
		if not f.is_positive:
			factor_bias += clampf(f.delta_value * 0.12, -8.0, 0.0)
		else:
			factor_bias += clampf(f.delta_value * 0.05, 0.0, 5.0)
	var combined: float = hist_slope * 0.45 + factor_bias * 0.55
	if metric_id == METRIC_NUFUS or metric_id == METRIC_YILKI or metric_id == METRIC_HAZINE:
		return clampf(combined, -45.0, 45.0)
	return clampf(combined, -15.0, 15.0)


func _build_projection_points(metric_id: StringName, current_val: float, slope: float) -> Array[TimeSeriesPoint]:
	var proj: Array[TimeSeriesPoint] = []
	var prev_v: float = current_val
	for step_i: int in range(1, PROJECTION_SEASONS_COUNT + 1):
		var damping: float = pow(0.88, float(step_i - 1))
		var next_v: float = prev_v + slope * damping
		if metric_id == METRIC_KUT or metric_id == METRIC_ULUS or metric_id == METRIC_SU or metric_id == METRIC_ORDU:
			next_v = clampf(next_v, 0.0, 100.0)
		else:
			next_v = maxf(next_v, 0.0)
		var f_idx: int = _season_counter + step_i
		proj.append(TimeSeriesPoint.new(
			f_idx,
			"%s +%d" % [_season_short_from_index(f_idx - 1), step_i],
			next_v,
			true,
			next_v - prev_v))
		prev_v = next_v
	return proj


# ---------------------------------------------------------------------------
# Bozkır Vakanüvisi (Chronicle Feed Ingestion & Query)
# ---------------------------------------------------------------------------

func record_chronicle_entry(
		category: StringName,
		title: String,
		detail: String,
		region_coord: Vector2i = Vector2i.ZERO,
		tone_id: StringName = &"gold") -> ChronicleEntry:
	var e: ChronicleEntry = ChronicleEntry.new()
	e.entry_id = _next_chronicle_id
	_next_chronicle_id += 1
	e.category = category
	e.category_label = format_chronicle_category_label(category)
	e.title = title
	e.detail = detail
	e.region_coord = region_coord
	e.world_pos = coord_to_world_pos(region_coord)
	e.season_label = _current_season_label(_season_counter)
	e.tick = SessionClockAuthority.get_current_tick()
	e.tone_id = tone_id
	_chronicle_entries.insert(0, e)
	while _chronicle_entries.size() > MAX_CHRONICLE_ENTRIES:
		_chronicle_entries.pop_back()
	return e


func get_chronicle_entries(filter_category: StringName = CHRONICLE_ALL) -> Array[ChronicleEntry]:
	if filter_category == CHRONICLE_ALL or filter_category == &"":
		return _chronicle_entries.duplicate()
	var filtered: Array[ChronicleEntry] = []
	for e: ChronicleEntry in _chronicle_entries:
		if e.category == filter_category:
			filtered.append(e)
	return filtered


static func format_chronicle_category_label(category: StringName) -> String:
	match category:
		CHRONICLE_BATTLE:
			return "Savaş"
		CHRONICLE_AMBUSH_SABOTAGE:
			return "Pusu & Sabotaj"
		CHRONICLE_ZUD_ECOLOGY:
			return "Zud & Ekoloji"
		CHRONICLE_KURULTAY_DIPLOMACY:
			return "Kurultay & Diplomasi"
	return "Vaka"


func _resolve_fallback_coord() -> Vector2i:
	var c: Vector2i = PastureEcologyManager.get_player_camp_region(_player_id)
	if c != Vector2i.ZERO:
		return c
	return _selected_region


func ingest_combat_resolved(result: CombatResult) -> void:
	if result == null:
		return
	var coord: Vector2i = _resolve_fallback_coord()
	var tone: StringName = &"jade" if not result.defender_routed else &"gold"
	if result.defender_id == _tracked_army_id and result.defender_routed:
		tone = &"ember"
	var outcome_str: String = "Bozgun!" if result.defender_routed else "Çarpışma"
	var detail_str: String = "Saldıran %d -> Savunan %d · Hasar %.0f · Moral %.0f" % [
		result.attacker_id, result.defender_id, result.damage_to_defender, result.defender_remaining_morale]
	record_chronicle_entry(CHRONICLE_BATTLE, "Meydan Muharebesi: %s" % outcome_str, detail_str, coord, tone)


func ingest_courier_ambush(order_id: StringName, victim_player_id: int, ambusher_id: int, leaked_plan: GameEnums.TuranTacticPhase) -> void:
	var coord: Vector2i = _resolve_fallback_coord()
	record_chronicle_entry(
		CHRONICLE_AMBUSH_SABOTAGE,
		"Ulak Pusuya Düşürüldü (%s)" % String(order_id),
		"Boy %d ulağı Boy %d tarafından yakalandı; taktik niyeti (%d) sızdı." % [victim_player_id, ambusher_id, int(leaked_plan)],
		coord,
		&"ember")


func ingest_water_sabotaged(region_coord: Vector2i, source_id: StringName, saboteur_id: int, duration_seasons: int) -> void:
	record_chronicle_entry(
		CHRONICLE_AMBUSH_SABOTAGE,
		"Kuyu Sabotajı [%d, %d]" % [region_coord.x, region_coord.y],
		"Su kaynağı '%s' Boy %d tarafından %d mevsim zehirlendi." % [String(source_id), saboteur_id, duration_seasons],
		region_coord,
		&"ember")


func ingest_water_restored(region_coord: Vector2i, source_id: StringName, restorer_id: int) -> void:
	record_chronicle_entry(
		CHRONICLE_ZUD_ECOLOGY,
		"Su Kaynağı Arındırıldı [%d, %d]" % [region_coord.x, region_coord.y],
		"'%s' Boy %d ekipleriyle yeniden içilebilir hale getirildi." % [String(source_id), restorer_id],
		region_coord,
		&"jade")


func ingest_zud_starvation(food_remaining: int, season: SeasonData) -> void:
	var coord: Vector2i = _resolve_fallback_coord()
	var s_name: String = season.display_name if season != null else "Kış"
	record_chronicle_entry(
		CHRONICLE_ZUD_ECOLOGY,
		"Zud Kıranı & Açlık Alarmı",
		"%s şartlarında erzak %d seviyesine indi; sürü kaybı riski yükseldi." % [s_name, food_remaining],
		coord,
		&"ember")


func ingest_pasture_depleted(region_coord: Vector2i, herd_size: int, migration_required: bool) -> void:
	record_chronicle_entry(
		CHRONICLE_ZUD_ECOLOGY,
		"Otlak Tükendi [%d, %d]" % [region_coord.x, region_coord.y],
		"%d baş sürü için otlak tükendi (%s)." % [herd_size, "Zorunlu Sefer Göçü" if migration_required else "İzleme"],
		region_coord,
		&"ember")


func ingest_cataclysm_erupted(cataclysm_id: StringName, region_coord: Vector2i) -> void:
	record_chronicle_entry(
		CHRONICLE_ZUD_ECOLOGY,
		"Doğal Afet: %s" % String(cataclysm_id),
		"[%d, %d] bölgesinde bozkır afeti lojistiği ve otlakları vurdu." % [region_coord.x, region_coord.y],
		region_coord,
		&"ember")


func ingest_council_convened(current_kut: float, legitimacy_penalty: float) -> void:
	record_chronicle_entry(
		CHRONICLE_KURULTAY_DIPLOMACY,
		"Ak Sakallılar Meclisi Toplandı",
		"Kut %.1f seviyesine indi; meşruiyet çarpanı -%%%.0f kısıldı." % [current_kut, legitimacy_penalty * 100.0],
		_resolve_fallback_coord(),
		&"ember")


func ingest_succession_crisis(crisis_id: StringName, claimant_bey_id: StringName, contested_coord: Vector2i) -> void:
	record_chronicle_entry(
		CHRONICLE_KURULTAY_DIPLOMACY,
		"Kurultay Veraset İhtilafı (%s)" % String(claimant_bey_id),
		"Kriz '%s' [%d, %d] merkezli taht talebi başlattı." % [String(crisis_id), contested_coord.x, contested_coord.y],
		contested_coord,
		&"ember")


func ingest_diplomacy_event(title: String, detail: String, tone_id: StringName = &"gold") -> void:
	record_chronicle_entry(CHRONICLE_KURULTAY_DIPLOMACY, title, detail, _resolve_fallback_coord(), tone_id)


# ---------------------------------------------------------------------------
# Devlet Defteri (Empire Ledger 5 Sortable Tabs + Fog-of-War Compliance)
# ---------------------------------------------------------------------------

func capture_ledger_tab(tab_id: StringName, sort_column: String = "", sort_ascending: bool = true) -> LedgerTableSnapshot:
	var table: LedgerTableSnapshot = LedgerTableSnapshot.new()
	table.tab_id = tab_id
	match tab_id:
		LEDGER_TAB_REGIONS:
			table.tab_title = "Bölgeler & Otlaklar"
			_build_regions_ledger(table)
		LEDGER_TAB_ARMIES:
			table.tab_title = "Tümenler & İkmal"
			_build_armies_ledger(table)
		LEDGER_TAB_COMMANDERS:
			table.tab_title = "Komutanlar & Gazi Mirası"
			_build_commanders_ledger(table)
		LEDGER_TAB_ROUTES:
			table.tab_title = "Su Kaynakları & Kervanlar"
			_build_routes_ledger(table)
		LEDGER_TAB_RIVALS:
			table.tab_title = "Bilinen Boylar (Sis Korumalı)"
			_build_rivals_ledger(table)
		_:
			table.tab_title = "Bölgeler & Otlaklar"
			table.tab_id = LEDGER_TAB_REGIONS
			_build_regions_ledger(table)

	if not sort_column.is_empty():
		_sort_ledger_rows(table, sort_column, sort_ascending)
	return table


func _sort_ledger_rows(table: LedgerTableSnapshot, sort_col: String, ascending: bool) -> void:
	var is_num: bool = false
	for col: LedgerColumn in table.columns:
		if col.key == sort_col:
			is_num = col.is_numeric
			break
	table.rows.sort_custom(func(a: LedgerRow, b: LedgerRow) -> bool:
		var cmp: int = 0
		if is_num:
			var av: float = a.sort_keys[sort_col] if a.sort_keys.has(sort_col) else 0.0
			var bv: float = b.sort_keys[sort_col] if b.sort_keys.has(sort_col) else 0.0
			if not is_equal_approx(av, bv):
				cmp = -1 if av < bv else 1
		else:
			var as_str: String = (a.values[sort_col] if a.values.has(sort_col) else "").to_lower()
			var bs_str: String = (b.values[sort_col] if b.values.has(sort_col) else "").to_lower()
			if as_str != bs_str:
				cmp = -1 if as_str < bs_str else 1
		if cmp == 0:
			if a.row_id == b.row_id:
				return false
			return a.row_id < b.row_id
		return cmp < 0 if ascending else cmp > 0
	)


func _build_regions_ledger(table: LedgerTableSnapshot) -> void:
	table.columns = [
		LedgerColumn.new("coord", "Bölge", false),
		LedgerColumn.new("geo", "Coğrafya", false),
		LedgerColumn.new("owner", "Sahip / Bey", true),
		LedgerColumn.new("control", "Denetim %", true),
		LedgerColumn.new("pasture", "Otlak", true),
		LedgerColumn.new("water", "Su", true),
	]
	var cur_s: SeasonData = SeasonManager.get_current_season()
	var s_type: GameEnums.SeasonType = cur_s.season_type if cur_s != null else GameEnums.SeasonType.SPRING
	var is_w: bool = s_type == GameEnums.SeasonType.WINTER

	var regions: Array[RegionData] = TerritoryManager.get_all_regions()
	if regions.is_empty():
		var camp: Vector2i = PastureEcologyManager.get_player_camp_region(_player_id)
		var r_fallback: RegionData = RegionData.new(camp, GameEnums.RegionGeographyClass.HIGH_PLATEAU_YAYLAK, _player_id, true, false, 100.0)
		regions.append(r_fallback)

	for reg: RegionData in regions:
		if reg == null:
			continue
		var row: LedgerRow = LedgerRow.new()
		row.row_id = "reg_%d_%d" % [reg.coord.x, reg.coord.y]
		row.focus_coord = reg.coord
		row.has_focus_coord = true
		var p_cap: float = PastureEcologyManager.get_region_pasture_capacity(reg.coord)
		var u_w: int = WaterRouteManager.count_usable_water_sources(reg.coord, s_type, is_w)
		var r_w: int = WaterRouteManager.count_registered_water_sources(reg.coord)
		var owner_txt: String = "Tarafsız" if reg.owner_id <= 0 else ("Oyuncu %d" % reg.owner_id)
		if reg.vassal_bey_id != &"":
			owner_txt = "%s (%s)" % [owner_txt, String(reg.vassal_bey_id)]
		row.values["coord"] = "[%d, %d]" % [reg.coord.x, reg.coord.y]
		row.values["geo"] = _format_geo_name(reg.geography_class)
		row.values["owner"] = owner_txt
		row.values["control"] = "%%%.0f" % reg.control_percent
		row.values["pasture"] = "%.0f" % p_cap
		row.values["water"] = "%d/%d" % [u_w, r_w]
		row.sort_keys["owner"] = float(reg.owner_id)
		row.sort_keys["control"] = reg.control_percent
		row.sort_keys["pasture"] = p_cap
		row.sort_keys["water"] = float(u_w)
		row.tone_id = &"jade" if reg.owner_id == _player_id else (&"ember" if reg.scorched_seasons_remaining > 0 else &"gold")
		table.rows.append(row)


func _build_armies_ledger(table: LedgerTableSnapshot) -> void:
	table.columns = [
		LedgerColumn.new("army", "Tümen", true),
		LedgerColumn.new("riders", "Süvari", true),
		LedgerColumn.new("doctrine", "Savaş Nizamı", false),
		LedgerColumn.new("supply", "İkmal %", true),
		LedgerColumn.new("morale", "Moral", true),
		LedgerColumn.new("status", "Durum", false),
	]
	var armies: Array[ArmyController] = []
	if _army_registry_ref != null:
		var reg_obj: Object = _army_registry_ref.get_ref()
		if reg_obj != null and is_instance_valid(reg_obj):
			var reg: ArmyRegistry = reg_obj as ArmyRegistry
			if reg != null:
				armies = reg.get_all_armies()
	var tracked_direct: ArmyController = _resolve_tracked_army()
	if tracked_direct != null and not armies.has(tracked_direct):
		armies.append(tracked_direct)

	if armies.is_empty():
		var row_f: LedgerRow = LedgerRow.new()
		row_f.row_id = "army_%d" % _tracked_army_id
		var r_cnt: int = maxi(CommandBus.get_army_rider_count(_tracked_army_id), 200)
		var iso_f: bool = CommandBus.is_army_supply_isolated(_tracked_army_id)
		var doc_f: BattleDoctrineResource = CombatCalculator.get_assigned_doctrine(_tracked_army_id)
		var doc_name_f: String = String(doc_f.display_name) if doc_f != null else "Standart"
		var sup_pct_f: float = 0.0 if iso_f else 100.0
		row_f.values["army"] = "Tümen #%d" % _tracked_army_id
		row_f.values["riders"] = "%d" % r_cnt
		row_f.values["doctrine"] = doc_name_f
		row_f.values["supply"] = "%%%.0f" % sup_pct_f
		row_f.values["morale"] = "100"
		row_f.values["status"] = "KESİK" if iso_f else "Hazır"
		row_f.sort_keys["army"] = float(_tracked_army_id)
		row_f.sort_keys["riders"] = float(r_cnt)
		row_f.sort_keys["supply"] = sup_pct_f
		row_f.sort_keys["morale"] = 100.0
		row_f.focus_coord = _resolve_fallback_coord()
		row_f.has_focus_coord = true
		row_f.tone_id = &"ember" if iso_f else &"jade"
		table.rows.append(row_f)
		return

	for a: ArmyController in armies:
		if a == null or not is_instance_valid(a):
			continue
		if a.owner_id != _player_id:
			continue
		var row: LedgerRow = LedgerRow.new()
		row.row_id = "army_%d" % a.army_id
		var stats_a: CombatantStats = a.get_combatant_stats()
		var riders_a: int = stats_a.troop_count if stats_a != null else maxi(CommandBus.get_army_rider_count(a.army_id), 0)
		var sup_pct: float = (stats_a.supply_ratio * 100.0) if stats_a != null else ((a.supply.get_supply_ratio() * 100.0) if a.supply != null else 100.0)
		var mor: float = stats_a.morale if stats_a != null else 100.0
		var doc_a: BattleDoctrineResource = CombatCalculator.get_assigned_doctrine(a.army_id)
		var active_doc: BattleDoctrineResource = stats_a.battle_doctrine if (stats_a != null and stats_a.battle_doctrine != null) else doc_a
		var doc_txt: String = String(active_doc.display_name) if active_doc != null else "Standart"
		var iso: bool = CommandBus.is_army_supply_isolated(a.army_id)
		row.values["army"] = "Tümen #%d" % a.army_id
		row.values["riders"] = "%d" % riders_a
		row.values["doctrine"] = doc_txt
		row.values["supply"] = "%%%.0f" % sup_pct
		row.values["morale"] = "%.0f" % mor
		row.values["status"] = "KESİK" if iso else ("Toz Perdesi" if CourierDispatchSystem.has_dust_decoy(a.army_id) else "Hazır")
		row.sort_keys["army"] = float(a.army_id)
		row.sort_keys["riders"] = float(riders_a)
		row.sort_keys["supply"] = sup_pct
		row.sort_keys["morale"] = mor
		row.focus_coord = _resolve_fallback_coord()
		row.has_focus_coord = true
		row.tone_id = &"ember" if iso or mor < 40.0 else &"jade"
		table.rows.append(row)


func _build_commanders_ledger(table: LedgerTableSnapshot) -> void:
	table.columns = [
		LedgerColumn.new("name", "Komutan", false),
		LedgerColumn.new("army", "Tümen", true),
		LedgerColumn.new("age", "Yaş", true),
		LedgerColumn.new("veteran", "Kıdem", true),
		LedgerColumn.new("scars", "Yara", true),
		LedgerColumn.new("trait", "Miras / Durum", false),
	]
	var cids: PackedInt32Array = SuccessionManager.get_registered_commander_ids()
	for cid: int in cids:
		var c: CommanderProfile = SuccessionManager.get_commander(cid)
		if c == null:
			continue
		var row: LedgerRow = LedgerRow.new()
		row.row_id = "cmdr_%d" % cid
		var age_yr: float = float(c.age_seasons) / 4.0
		row.values["name"] = String(c.commander_name)
		row.values["army"] = "#%d" % c.assigned_army_id
		row.values["age"] = "%.0f" % age_yr
		row.values["veteran"] = "%.0f" % c.veteran_score
		row.values["scars"] = "%d" % c.scars
		row.values["trait"] = _format_commander_trait(c.commander_trait) if c.is_alive else "Şehit / Düşmüş"
		row.sort_keys["army"] = float(c.assigned_army_id)
		row.sort_keys["age"] = age_yr
		row.sort_keys["veteran"] = c.veteran_score
		row.sort_keys["scars"] = float(c.scars)
		row.tone_id = &"ember" if not c.is_alive else (&"jade" if c.veteran_score >= 30.0 else &"gold")
		table.rows.append(row)


func _build_routes_ledger(table: LedgerTableSnapshot) -> void:
	table.columns = [
		LedgerColumn.new("kind", "Hat Türü", false),
		LedgerColumn.new("id", "Kayıt ID", false),
		LedgerColumn.new("coord", "Konum / Rota", false),
		LedgerColumn.new("owner", "Sahip", true),
		LedgerColumn.new("cargo", "Durum / Yük", false),
		LedgerColumn.new("health", "Kalan / Puan", true),
	]
	var cur_s: SeasonData = SeasonManager.get_current_season()
	var is_w: bool = cur_s != null and cur_s.season_type == GameEnums.SeasonType.WINTER

	for ws: WaterSourceNode in WaterRouteManager.get_all_water_sources():
		if ws == null:
			continue
		var row_w: LedgerRow = LedgerRow.new()
		row_w.row_id = "water_%s" % String(ws.source_id)
		var usable: bool = ws.is_usable(is_w)
		row_w.values["kind"] = "Su Kaynağı"
		row_w.values["id"] = String(ws.source_id)
		row_w.values["coord"] = "[%d, %d]" % [ws.region_coord.x, ws.region_coord.y]
		row_w.values["owner"] = "Boy %d" % ws.owner_id if ws.owner_id > 0 else "Ortak"
		row_w.values["cargo"] = "Sabotaj (%dM)" % ws.contaminated_seasons_remaining if ws.contaminated_seasons_remaining > 0 else ("Sağlam" if usable else "Donmuş")
		row_w.values["health"] = "%.0f" % (ws.base_capacity if usable else 0.0)
		row_w.sort_keys["owner"] = float(ws.owner_id)
		row_w.sort_keys["health"] = ws.base_capacity if usable else 0.0
		row_w.focus_coord = ws.region_coord
		row_w.has_focus_coord = true
		row_w.tone_id = &"jade" if usable else &"ember"
		table.rows.append(row_w)

	for cv: PhysicalCaravan in CaravanLogisticsManager.get_all_caravans():
		if cv == null:
			continue
		var row_c: LedgerRow = LedgerRow.new()
		row_c.row_id = "caravan_%s" % String(cv.caravan_id)
		var st_str: String = "Yolda" if cv.state == GameEnums.CaravanCargoState.EN_ROUTE else ("Teslim" if cv.state == GameEnums.CaravanCargoState.DELIVERED else "Baskın!")
		row_c.values["kind"] = "Fiziksel Kervan"
		row_c.values["id"] = String(cv.caravan_id)
		row_c.values["coord"] = "[%d,%d]->[%d,%d]" % [cv.origin_coord.x, cv.origin_coord.y, cv.dest_coord.x, cv.dest_coord.y]
		row_c.values["owner"] = "Boy %d" % cv.owner_id
		row_c.values["cargo"] = "%s · %d Erzak" % [st_str, cv.food_cargo]
		row_c.values["health"] = "%.0fs" % cv.remaining_travel_sec
		row_c.sort_keys["owner"] = float(cv.owner_id)
		row_c.sort_keys["health"] = cv.remaining_travel_sec
		row_c.focus_coord = cv.dest_coord
		row_c.has_focus_coord = true
		row_c.tone_id = &"ember" if cv.state == GameEnums.CaravanCargoState.INTERCEPTED else (&"jade" if cv.state == GameEnums.CaravanCargoState.DELIVERED else &"ice")
		table.rows.append(row_c)


func _build_rivals_ledger(table: LedgerTableSnapshot) -> void:
	table.columns = [
		LedgerColumn.new("tribe", "Boy / Hanlık", false),
		LedgerColumn.new("stance", "Tutum", false),
		LedgerColumn.new("trust", "Güven", true),
		LedgerColumn.new("doctrine", "Bilinen Nizam", false),
		LedgerColumn.new("power", "Güç Tahmini", false),
		LedgerColumn.new("intel", "İstihbarat", false),
	]
	var seen_players: Dictionary[int, bool] = {}

	for ai_ctrl: SteppeStrategicAIController in SteppeStrategicAIController.get_all_ai_agents():
		if ai_ctrl == null or ai_ctrl.ai_player_id == _player_id:
			continue
		seen_players[ai_ctrl.ai_player_id] = true
		var row: LedgerRow = LedgerRow.new()
		row.row_id = "ai_%s" % String(ai_ctrl.agent_id)
		var report: EspionageReport = IntelligenceManager.get_latest_report_for_army(ai_ctrl.ai_army_id)
		var has_valid_intel: bool = report != null and report.succeeded and report.spy_owner_id == _player_id
		var courier_leaked: bool = CourierDispatchSystem.is_player_plan_exposed_by_courier(ai_ctrl.ai_player_id, ai_ctrl.ai_army_id)
		var dust_active: bool = CourierDispatchSystem.has_dust_decoy(ai_ctrl.ai_army_id)

		var doc_text: String = "Bilinmiyor (Sis)"
		var power_text: String = "Sis Altında (Gizli)"
		var intel_text: String = "Keşif Gerekli"
		var tone: StringName = &"gold"

		if courier_leaked:
			doc_text = "Ulak İfşası (Sızdı)"
			intel_text = "Ulak Yakalandı"
			tone = &"jade"
		elif has_valid_intel:
			doc_text = "İzlenen Nizam (%s)" % _format_tactical_doctrine_type(report.revealed_doctrine_type)
			intel_text = "Casus Raporu"
			tone = &"jade"

		if dust_active and not has_valid_intel:
			power_text = "Toz Perdesi Tahmini"
			tone = &"ice"
		elif has_valid_intel:
			power_text = "Sadak ~%.0f" % maxf(report.revealed_quiver_ammo, 0.0)

		var public_trust: float = ReputationAndPactSystem.get_word_reliability(ai_ctrl.ai_player_id)
		var stance_txt: String = "Gözlemde"
		var matched_dyn: StringName = _match_dynasty_id(ai_ctrl.agent_id)
		if matched_dyn != &"":
			stance_txt = _format_dynasty_attitude(DiplomacyManager.get_dynasty_stance(matched_dyn))
			public_trust = DiplomacyManager.get_dynasty_trust(matched_dyn)

		row.values["tribe"] = _format_agent_display_name(ai_ctrl.agent_id, ai_ctrl.ai_player_id)
		row.values["stance"] = stance_txt
		row.values["trust"] = "%.0f" % public_trust
		row.values["doctrine"] = doc_text
		row.values["power"] = power_text
		row.values["intel"] = intel_text
		row.sort_keys["trust"] = public_trust
		row.focus_coord = ai_ctrl.home_coord
		row.has_focus_coord = ai_ctrl.home_coord != Vector2i.ZERO
		row.tone_id = tone
		table.rows.append(row)

	for did: StringName in KNOWN_RIVAL_DYNASTY_IDS:
		var prof: DynastyProfile = DiplomacyManager.get_dynasty_profile(did)
		if prof == null:
			continue
		var dup: bool = false
		for existing: LedgerRow in table.rows:
			if existing.row_id.find(String(did)) != -1:
				dup = true
				break
		if dup:
			continue
		var row_d: LedgerRow = LedgerRow.new()
		row_d.row_id = "dyn_%s" % String(did)
		var trust_val: float = DiplomacyManager.get_dynasty_trust(did)
		var attitude: GameEnums.DynastyAttitude = DiplomacyManager.get_dynasty_stance(did)
		row_d.values["tribe"] = prof.display_name
		row_d.values["stance"] = _format_dynasty_attitude(attitude)
		row_d.values["trust"] = "%.0f" % trust_val
		row_d.values["doctrine"] = "Bilinmiyor (Sis)"
		row_d.values["power"] = "Tahmini ~%.0f" % prof.base_military_power
		row_d.values["intel"] = "Sadece Diplomasi"
		row_d.sort_keys["trust"] = trust_val
		row_d.tone_id = &"ember" if attitude == GameEnums.DynastyAttitude.HOSTILE else (&"jade" if attitude == GameEnums.DynastyAttitude.ALLY else &"gold")
		table.rows.append(row_d)


static func _match_dynasty_id(agent_id: StringName) -> StringName:
	var s: String = String(agent_id).to_lower()
	for did: StringName in KNOWN_RIVAL_DYNASTY_IDS:
		if s.find(String(did)) != -1:
			return did
	return &""


static func _format_agent_display_name(agent_id: StringName, pid: int) -> String:
	var raw: String = String(agent_id).replace("_", " ").capitalize()
	return "%s (#%d)" % [raw, pid]


static func _format_dynasty_attitude(att: GameEnums.DynastyAttitude) -> String:
	match att:
		GameEnums.DynastyAttitude.ALLY:
			return "Müttefik"
		GameEnums.DynastyAttitude.NEUTRAL:
			return "Tarafsız"
		GameEnums.DynastyAttitude.THREATENING:
			return "Tehditkâr"
		GameEnums.DynastyAttitude.HOSTILE:
			return "Düşman"
	return "Tarafsız"


static func _format_geo_name(geo: GameEnums.RegionGeographyClass) -> String:
	match geo:
		GameEnums.RegionGeographyClass.HIGH_PLATEAU_YAYLAK:
			return "Yaylak"
		GameEnums.RegionGeographyClass.SHELTERED_VALLEY_KISLAK:
			return "Kışlak"
		GameEnums.RegionGeographyClass.FOREST_EDGE:
			return "Orman Kenarı"
		GameEnums.RegionGeographyClass.SACRED_CORE:
			return "Ötüken Çekirdeği"
	return "Bozkır"


static func _format_commander_trait(tr: GameEnums.CommanderTrait) -> String:
	match tr:
		GameEnums.CommanderTrait.SAGIR_YARA:
			return "Sağır Yara"
		GameEnums.CommanderTrait.KERVAN_GAZISI:
			return "Kervan Gazisi"
		GameEnums.CommanderTrait.BOZKIR_KURDU:
			return "Bozkır Kurdu"
		GameEnums.CommanderTrait.BORU_YUREK:
			return "Börü Yürek"
	return "Savaşçı Bey"


static func _format_tactical_doctrine_type(doc_type: GameEnums.TacticalDoctrineType) -> String:
	match doc_type:
		GameEnums.TacticalDoctrineType.STANDARD_CHARGE:
			return "Doğrudan Hücum"
		GameEnums.TacticalDoctrineType.FEIGNED_RETREAT:
			return "Sahte Ricat"
		GameEnums.TacticalDoctrineType.CRESCENT_ENCIRCLEMENT:
			return "Hilal Kapanı"
		GameEnums.TacticalDoctrineType.STEPPE_AMBUSH:
			return "Bozkır Pususu"
	return "Standart Nizam"
