class_name CourierAndDoctrinePanel
extends VBoxContainer
## UI Tactical Control Panel (rank 4). Houses:
##   1. Segmented Courier Order Latency Gauge & Dispatch Controls
##   2. Yılkı Dust Screen Deception (`Toz Perdesi`) Meter & Toggle
##   3. 3-Block Conditional **Bozkır Nöbeti** Doctrine Builder (`EĞER -> YAP -> HEDEF`)
##
## Architectural Guarantee: NEVER directly mutates simulation managers or unit
## components; reads via `TacticalCommandViewModel` and dispatches player intent
## exclusively through `CommandBus`.

signal courier_order_dispatched_from_ui(order_id: StringName, delay_sec: float)
signal dust_screen_toggled_from_ui(is_active: bool)
signal doctrine_applied_from_ui(summary: String)


class BusSub:
	var bus_signal: Signal
	var callback: Callable

	func _init(p_sig: Signal, p_cb: Callable) -> void:
		bus_signal = p_sig
		callback = p_cb


static var _global_order_seq: int = 0

var _view_model: TacticalCommandViewModel = null
var _ui_built: bool = false
var _signals_connected: bool = false
var _bus_subs: Array[BusSub] = []
var _btn_callbacks: Dictionary[Button, Callable] = {}

# Courier Route Preview State
var _distance_idx: int = 0
var _terrain_idx: int = 0
var _courier_storm: bool = false
var _tactic_idx: int = 2

# 3-Block Bozkır Nöbeti Builder Indices
var _trigger_idx: int = 0
var _action_idx: int = 0
var _target_idx: int = 0
var _last_status_msg: String = ""

# Sub-widgets
var _courier_card: TamgaCardPanel = null
var _latency_gauge: CourierLatencyGauge = null
var _btn_terrain: Button = null
var _btn_storm: Button = null
var _btn_distance: Button = null
var _btn_tactic: Button = null
var _btn_dispatch_courier: Button = null
var _courier_status_lbl: Label = null

var _dust_card: TamgaCardPanel = null
var _dust_bar: DustDeceptionBar = null
var _btn_toggle_dust: Button = null
var _dust_status_lbl: Label = null

var _doctrine_card: TamgaCardPanel = null
var _btn_if_block: Button = null
var _btn_do_block: Button = null
var _btn_target_block: Button = null
var _doctrine_preview_lbl: Label = null
var _doctrine_active_lbl: Label = null
var _btn_apply_doctrine: Button = null


func _init() -> void:
	name = "CourierAndDoctrinePanel"
	custom_minimum_size = Vector2(260.0, 0.0)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override(&"separation", 8)


func _ready() -> void:
	_ensure_ui()
	_connect_bus()
	refresh_from_viewmodel()


func _exit_tree() -> void:
	_disconnect_bus()
	_disconnect_buttons()


func set_view_model(vm: TacticalCommandViewModel) -> void:
	_view_model = vm
	_ensure_ui()
	_sync_preview_to_viewmodel()
	refresh_from_viewmodel()


func get_view_model() -> TacticalCommandViewModel:
	if _view_model == null:
		_view_model = TacticalCommandViewModel.new(1, 1)
	return _view_model


func get_latency_gauge() -> CourierLatencyGauge:
	_ensure_ui()
	return _latency_gauge


func get_dust_bar() -> DustDeceptionBar:
	_ensure_ui()
	return _dust_bar


func get_doctrine_preview_text() -> String:
	_ensure_ui()
	return _doctrine_preview_lbl.text if _doctrine_preview_lbl != null else ""


func get_status_message() -> String:
	return _last_status_msg


func set_courier_parameters(distance_m: float, terrain_type: GameEnums.TerrainType, is_storm: bool, tactic: GameEnums.TuranTacticPhase) -> void:
	_ensure_ui()
	if distance_m >= 450.0:
		_distance_idx = 2
	elif distance_m >= 270.0:
		_distance_idx = 1
	else:
		_distance_idx = 0

	if terrain_type == GameEnums.TerrainType.MOUNTAIN:
		_terrain_idx = 2
	elif terrain_type == GameEnums.TerrainType.FOREST:
		_terrain_idx = 1
	else:
		_terrain_idx = 0

	_courier_storm = is_storm
	_tactic_idx = clampi(int(tactic), 0, 4)
	_sync_preview_to_viewmodel()
	refresh_from_viewmodel()


func set_doctrine_blocks(trigger_idx: int, action_idx: int, target_idx: int) -> void:
	_ensure_ui()
	_trigger_idx = posmod(trigger_idx, 6)
	_action_idx = posmod(action_idx, 4)
	_target_idx = posmod(target_idx, 4)
	_sync_builder_labels()


func trigger_dispatch_courier(custom_order_id: StringName = &"") -> StringName:
	_ensure_ui()
	var vm: TacticalCommandViewModel = get_view_model()
	var dist_m: float = _current_distance_m()
	var terrain_t: GameEnums.TerrainType = _current_terrain_type()
	var tactic_p: GameEnums.TuranTacticPhase = _current_tactic_phase()

	var order_id: StringName = custom_order_id
	if order_id == &"":
		_global_order_seq += 1
		order_id = StringName("ui_courier_%d_%d" % [vm.get_army_id(), _global_order_seq])

	var cmd: DispatchCourierOrderCommand = DispatchCourierOrderCommand.new(order_id, vm.get_player_id(), vm.get_army_id(), &"turan_maneuver", tactic_p, Vector3.ZERO, Vector3(dist_m, 0.0, 0.0), terrain_t, _courier_storm)
	var ok: bool = CommandBus.dispatch(cmd)
	if ok:
		_last_status_msg = "Ulak çıktı (%s): %.1fs" % [String(order_id), cmd.computed_delay_sec]
		if _courier_status_lbl != null:
			_courier_status_lbl.text = _last_status_msg
			_courier_status_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.ICE_FROST)
		courier_order_dispatched_from_ui.emit(order_id, cmd.computed_delay_sec)
		refresh_from_viewmodel()
		return order_id
	_last_status_msg = "Ulak reddedildi: %s" % cmd.rejection_reason
	if _courier_status_lbl != null:
		_courier_status_lbl.text = _last_status_msg
		_courier_status_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.EMBER_BRIGHT)
	return &""


func trigger_toggle_dust(force_enable: int = -1) -> bool:
	_ensure_ui()
	var vm: TacticalCommandViewModel = get_view_model()
	var snap: TacticalCommandViewModel.TacticalUnitSnapshot = vm.capture_snapshot()
	var desired: bool = (not snap.dust_decoy_active) if force_enable < 0 else (force_enable > 0)
	var cmd: ToggleDustScreenCommand = ToggleDustScreenCommand.new(vm.get_army_id(), vm.get_player_id(), desired, snap.remount_horse_ratio)
	var ok: bool = CommandBus.dispatch(cmd)
	if ok:
		_last_status_msg = "Toz Perdesi %s (~%.2fx algı)" % ["AÇIK" if cmd.active_after else "KAPALI", snap.dust_apparent_mult]
		if _dust_status_lbl != null:
			_dust_status_lbl.text = _last_status_msg
			_dust_status_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.GOLD_PALE if cmd.active_after else NeoSteppePalette.TEXT_SECONDARY)
		dust_screen_toggled_from_ui.emit(cmd.active_after)
		refresh_from_viewmodel()
		return true
	_last_status_msg = "Toz Perdesi Reddedildi: %s" % cmd.rejection_reason
	if _dust_status_lbl != null:
		_dust_status_lbl.text = _last_status_msg
		_dust_status_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.EMBER_BRIGHT)
	return false


func trigger_apply_doctrine() -> bool:
	_ensure_ui()
	var vm: TacticalCommandViewModel = get_view_model()
	var trigger_cond: GameEnums.OfflineDoctrineTrigger = _current_trigger_enum()
	var ratio_thresh: float = 2.0 if _trigger_idx == 1 else 1.5
	var supply_thresh: float = 0.20
	var tactic_act: GameEnums.TuranTacticPhase = _current_action_tactic()
	var pack_cart: bool = _current_action_pack_cart()
	var evade_act: bool = _current_action_evade()
	var tgt_terr: GameEnums.TerrainClass = _current_target_terrain()
	var tgt_geo: GameEnums.RegionGeographyClass = _current_target_geo()

	var cmd: ConfigureOfflineDoctrineCommand = ConfigureOfflineDoctrineCommand.new(vm.get_army_id(), vm.get_player_id(), trigger_cond, ratio_thresh, supply_thresh, tactic_act, pack_cart, evade_act, tgt_terr, tgt_geo)
	var ok: bool = CommandBus.dispatch(cmd)
	if ok:
		_last_status_msg = "Bozkır Nöbeti Uygulandı: %s" % cmd.applied_summary
		doctrine_applied_from_ui.emit(cmd.applied_summary)
		refresh_from_viewmodel()
		return true
	_last_status_msg = "Doktrin Reddedildi: %s" % cmd.rejection_reason
	return false


func refresh_from_viewmodel(provided_snap: TacticalCommandViewModel.TacticalUnitSnapshot = null) -> void:
	_ensure_ui()
	var snap: TacticalCommandViewModel.TacticalUnitSnapshot = provided_snap if provided_snap != null else get_view_model().capture_snapshot()

	# 1. Courier Gauge
	_latency_gauge.apply_metrics(
		snap.courier_base_delay_sec,
		snap.courier_terrain_delay_sec,
		snap.courier_storm_delay_sec,
		snap.courier_total_delay_sec,
		snap.courier_remaining_delay_sec,
		snap.courier_ambush_risk_pct,
		snap.courier_status,
		snap.courier_plan_leaked)
	if snap.courier_plan_leaked:
		_courier_card.set_semantic_tone(&"ember", 0.9)
		_courier_status_lbl.text = "UYARI: Ulak pusuya düştü! Sızan: %s" % TacticalCommandViewModel.format_turan_phase_short(snap.courier_leaked_tactic)
		_courier_status_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.EMBER_BRIGHT)
	elif snap.courier_status == GameEnums.CourierStatus.IN_TRANSIT and snap.courier_has_order:
		_courier_card.set_semantic_tone(&"gold", 0.2)
		_courier_status_lbl.text = "Ulak #%s yolda (%.1fs kaldı)" % [String(snap.courier_order_id), snap.courier_remaining_delay_sec]
		_courier_status_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.GOLD_PALE)
	else:
		_courier_card.set_semantic_tone(&"ice", 0.0)
		if _last_status_msg.is_empty():
			_courier_status_lbl.text = "Öngörülen Gecikme: %.1fs · Pusu %%%.0f" % [snap.courier_total_delay_sec, snap.courier_ambush_risk_pct]
			_courier_status_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.TEXT_SECONDARY)

	# 2. Dust Deception Bar
	_dust_bar.apply_metrics(snap.true_power_estimate, snap.perceived_power_estimate, snap.dust_decoy_active, snap.dust_apparent_mult)
	if snap.dust_decoy_active:
		_dust_card.set_semantic_tone(&"ember", 0.35)
		_btn_toggle_dust.text = "Toz Perdesi: AÇIK (Kapat)"
		OtukenThemeFactory.apply_button_semantic_styles(_btn_toggle_dust, NeoSteppePalette.EMBER_BRIGHT, true, 8, 4)
		_dust_status_lbl.text = "Yedek At %%%.0f · Sahte Süvari İzi (~%.2fx) Aktif" % [snap.remount_horse_ratio * 100.0, snap.dust_apparent_mult]
		_dust_status_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.GOLD_PALE)
	else:
		_dust_card.set_semantic_tone(&"jade", 0.0)
		_btn_toggle_dust.text = "Toz Perdesi: KAPALI (Aç)"
		var can_dust: bool = snap.remount_horse_ratio >= snap.min_remount_for_dust
		OtukenThemeFactory.apply_button_semantic_styles(_btn_toggle_dust, NeoSteppePalette.JADE_PRIMARY if can_dust else NeoSteppePalette.EMBER_RED, false, 8, 4)
		if not can_dust:
			_dust_status_lbl.text = "Yedek At %%%.0f < %%25 — Toz Perdesi yetersiz" % (snap.remount_horse_ratio * 100.0)
			_dust_status_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.EMBER_BRIGHT)
		else:
			_dust_status_lbl.text = "Yedek At %%%.0f (Min %%25 · ~2.1x Aldatma)" % (snap.remount_horse_ratio * 100.0)
			_dust_status_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.TEXT_SECONDARY)

	# 3. 3-Block Bozkır Nöbeti Doctrine Builder & Stored Rule Status
	_sync_builder_labels()
	if _doctrine_active_lbl != null:
		var exec_tag: String = " [TETİKLENDİ]" if snap.last_decision_triggered else ""
		_doctrine_active_lbl.text = "Kayıtlı Nöbet%s: %s" % [exec_tag, snap.doctrine_summary]


func _ensure_ui() -> void:
	if _ui_built:
		return
	_ui_built = true

	# === Card 1: Courier Order Latency & Dispatch ============================
	_courier_card = TamgaCardPanel.new()
	_courier_card.name = "CourierLatencyCard"
	_courier_card.semantic_tone = &"ice"
	add_child(_courier_card)
	var c_box: VBoxContainer = VBoxContainer.new()
	c_box.add_theme_constant_override(&"separation", 5)
	_courier_card.get_content_container().add_child(c_box)

	var c_title: Label = Label.new()
	c_title.theme_type_variation = &"CaptionLabel"
	c_title.text = "ULAK GECİKME KONİSİ & PUSU RİSKİ"
	c_box.add_child(c_title)

	_latency_gauge = CourierLatencyGauge.new()
	c_box.add_child(_latency_gauge)

	var route_flow: HFlowContainer = HFlowContainer.new()
	route_flow.add_theme_constant_override(&"h_separation", 4)
	route_flow.add_theme_constant_override(&"v_separation", 4)
	c_box.add_child(route_flow)

	_btn_terrain = _make_cycle_btn("BtnCourierTerrain", "Arazi: Bozkır", NeoSteppePalette.BRONZE_WEATHERED, _on_terrain_cycle_pressed)
	route_flow.add_child(_btn_terrain)
	_btn_storm = _make_cycle_btn("BtnCourierStorm", "Hava: Açık", NeoSteppePalette.ICE_BLUE, _on_storm_toggle_pressed)
	route_flow.add_child(_btn_storm)
	_btn_distance = _make_cycle_btn("BtnCourierDist", "Menzil: 180m", NeoSteppePalette.BRONZE_WEATHERED, _on_distance_cycle_pressed)
	route_flow.add_child(_btn_distance)
	_btn_tactic = _make_cycle_btn("BtnCourierTactic", "Emir: Sahte Ricat", NeoSteppePalette.GOLD_TAMGA, _on_tactic_cycle_pressed)
	route_flow.add_child(_btn_tactic)

	_btn_dispatch_courier = _make_action_btn("BtnDispatchCourier", "Ulak Çıkar (Emir İlet)", NeoSteppePalette.ICE_BLUE, _on_dispatch_courier_pressed)
	c_box.add_child(_btn_dispatch_courier)

	_courier_status_lbl = Label.new()
	_courier_status_lbl.name = "CourierStatusLabel"
	_courier_status_lbl.theme_type_variation = &"MutedLabel"
	_courier_status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	c_box.add_child(_courier_status_lbl)

	# === Card 2: Yılkı Dust Screen Deception (Toz Perdesi) ===================
	_dust_card = TamgaCardPanel.new()
	_dust_card.name = "DustDeceptionCard"
	_dust_card.semantic_tone = &"jade"
	add_child(_dust_card)
	var d_box: VBoxContainer = VBoxContainer.new()
	d_box.add_theme_constant_override(&"separation", 5)
	_dust_card.get_content_container().add_child(d_box)

	var d_title: Label = Label.new()
	d_title.theme_type_variation = &"CaptionLabel"
	d_title.text = "YILKI TOZ PERDESİ ALDATMACASI (~2.1x)"
	d_box.add_child(d_title)

	_dust_bar = DustDeceptionBar.new()
	d_box.add_child(_dust_bar)

	_btn_toggle_dust = _make_action_btn("BtnToggleDust", "Toz Perdesi: KAPALI (Aç)", NeoSteppePalette.JADE_PRIMARY, _on_toggle_dust_pressed)
	d_box.add_child(_btn_toggle_dust)

	_dust_status_lbl = Label.new()
	_dust_status_lbl.name = "DustStatusLabel"
	_dust_status_lbl.theme_type_variation = &"MutedLabel"
	_dust_status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d_box.add_child(_dust_status_lbl)

	# === Card 3: 3-Block Bozkır Nöbeti Doctrine Builder ======================
	_doctrine_card = TamgaCardPanel.new()
	_doctrine_card.name = "DoctrineBuilderCard"
	_doctrine_card.semantic_tone = &"gold"
	add_child(_doctrine_card)
	var doc_box: VBoxContainer = VBoxContainer.new()
	doc_box.add_theme_constant_override(&"separation", 5)
	_doctrine_card.get_content_container().add_child(doc_box)

	var doc_title: Label = Label.new()
	doc_title.theme_type_variation = &"CaptionLabel"
	doc_title.text = "BOZKIR NÖBETİ DOKTRİN KURUCU"
	doc_box.add_child(doc_title)

	_btn_if_block = _make_cycle_btn("BtnDoctrineIf", "EĞER [...]", NeoSteppePalette.EMBER_RED, _on_if_cycle_pressed)
	doc_box.add_child(_btn_if_block)
	_btn_do_block = _make_cycle_btn("BtnDoctrineDo", "YAP [...]", NeoSteppePalette.GOLD_TAMGA, _on_do_cycle_pressed)
	doc_box.add_child(_btn_do_block)
	_btn_target_block = _make_cycle_btn("BtnDoctrineTarget", "HEDEF [...]", NeoSteppePalette.JADE_PRIMARY, _on_target_cycle_pressed)
	doc_box.add_child(_btn_target_block)

	_doctrine_preview_lbl = Label.new()
	_doctrine_preview_lbl.name = "DoctrinePreviewLabel"
	_doctrine_preview_lbl.theme_type_variation = &"Label"
	_doctrine_preview_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	doc_box.add_child(_doctrine_preview_lbl)

	_btn_apply_doctrine = _make_action_btn("BtnApplyDoctrine", "Doktrini Orduya Mühürle", NeoSteppePalette.GOLD_TAMGA, _on_apply_doctrine_pressed)
	doc_box.add_child(_btn_apply_doctrine)

	_doctrine_active_lbl = Label.new()
	_doctrine_active_lbl.name = "DoctrineActiveLabel"
	_doctrine_active_lbl.theme_type_variation = &"MutedLabel"
	_doctrine_active_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	doc_box.add_child(_doctrine_active_lbl)

	_sync_builder_labels()


func _make_cycle_btn(node_name: String, label_text: String, accent: Color, cb: Callable) -> Button:
	var btn: Button = Button.new()
	btn.name = node_name
	btn.theme_type_variation = &"GhostIconButton"
	btn.text = label_text
	OtukenThemeFactory.apply_button_semantic_styles(btn, accent, false, 7, 3)
	btn.pressed.connect(cb)
	_btn_callbacks[btn] = cb
	return btn


func _make_action_btn(node_name: String, label_text: String, accent: Color, cb: Callable) -> Button:
	var btn: Button = Button.new()
	btn.name = node_name
	btn.theme_type_variation = &"ActionButton"
	btn.text = label_text
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	OtukenThemeFactory.apply_button_semantic_styles(btn, accent, false, 8, 4)
	btn.pressed.connect(cb)
	_btn_callbacks[btn] = cb
	return btn


func _sync_preview_to_viewmodel() -> void:
	var vm: TacticalCommandViewModel = get_view_model()
	vm.set_preview_courier_route(_current_distance_m(), _current_terrain_type(), _courier_storm)
	if _btn_terrain != null:
		var t_names: PackedStringArray = PackedStringArray(["Bozkır 1.0x", "Orman 1.65x", "Dağ 1.65x"])
		_btn_terrain.text = "Arazi: %s" % t_names[_terrain_idx]
	if _btn_storm != null:
		_btn_storm.text = "Hava: Fırtına 1.45x" if _courier_storm else "Hava: Açık 1.0x"
		OtukenThemeFactory.apply_button_semantic_styles(_btn_storm, NeoSteppePalette.EMBER_RED if _courier_storm else NeoSteppePalette.ICE_BLUE, _courier_storm, 7, 3)
	if _btn_distance != null:
		_btn_distance.text = "Menzil: %.0fm" % _current_distance_m()
	if _btn_tactic != null:
		_btn_tactic.text = "Emir: %s" % TacticalCommandViewModel.format_turan_phase_short(_current_tactic_phase())


func _sync_builder_labels() -> void:
	var trig: GameEnums.OfflineDoctrineTrigger = _current_trigger_enum()
	var ratio: float = 2.0 if _trigger_idx == 1 else 1.5
	var if_txt: String = OfflineDoctrineConfig.format_trigger_label(trig, ratio, 0.20)
	var do_txt: String = OfflineDoctrineConfig.format_action_label(_current_action_tactic(), _current_action_pack_cart(), _current_action_evade())
	var tgt_txt: String = OfflineDoctrineConfig.format_target_label(_current_target_terrain(), _current_target_geo())

	if _btn_if_block != null:
		_btn_if_block.text = "EĞER [%s]" % if_txt
	if _btn_do_block != null:
		_btn_do_block.text = "YAP [%s]" % do_txt
	if _btn_target_block != null:
		_btn_target_block.text = "HEDEF [%s]" % tgt_txt
	if _doctrine_preview_lbl != null:
		_doctrine_preview_lbl.text = "EĞER [%s] -> YAP [%s] -> HEDEF [%s]" % [if_txt, do_txt, tgt_txt]


func _current_distance_m() -> float:
	if _distance_idx == 1:
		return 360.0
	if _distance_idx == 2:
		return 540.0
	return 180.0


func _current_terrain_type() -> GameEnums.TerrainType:
	if _terrain_idx == 1:
		return GameEnums.TerrainType.FOREST
	if _terrain_idx == 2:
		return GameEnums.TerrainType.MOUNTAIN
	return GameEnums.TerrainType.STEPPE


func _current_tactic_phase() -> GameEnums.TuranTacticPhase:
	match clampi(_tactic_idx, 0, 4):
		0:
			return GameEnums.TuranTacticPhase.RECON_DUST_SCREEN
		1:
			return GameEnums.TuranTacticPhase.WHISTLING_ARROW_HARASSMENT
		3:
			return GameEnums.TuranTacticPhase.CRESCENT_ENCIRCLEMENT_TRAP
		4:
			return GameEnums.TuranTacticPhase.BORU_SHOCK_ANNIHILATION
		_:
			return GameEnums.TuranTacticPhase.FEIGNED_RETREAT_LURE


func _current_trigger_enum() -> GameEnums.OfflineDoctrineTrigger:
	match posmod(_trigger_idx, 6):
		2:
			return GameEnums.OfflineDoctrineTrigger.LOW_SUPPLY_OR_AMMO
		3:
			return GameEnums.OfflineDoctrineTrigger.SHELTER_IN_KISLAK
		4:
			return GameEnums.OfflineDoctrineTrigger.ORDER_TIMED_OUT_OFFLINE
		5:
			return GameEnums.OfflineDoctrineTrigger.NONE
		_:
			return GameEnums.OfflineDoctrineTrigger.ENEMY_POWER_RATIO_EXCEEDED


func _current_action_tactic() -> GameEnums.TuranTacticPhase:
	match posmod(_action_idx, 4):
		1:
			return GameEnums.TuranTacticPhase.CRESCENT_ENCIRCLEMENT_TRAP
		2:
			return GameEnums.TuranTacticPhase.WHISTLING_ARROW_HARASSMENT
		3:
			return GameEnums.TuranTacticPhase.BORU_SHOCK_ANNIHILATION
		_:
			return GameEnums.TuranTacticPhase.FEIGNED_RETREAT_LURE


func _current_action_pack_cart() -> bool:
	var idx: int = posmod(_action_idx, 4)
	return idx == 0 or idx == 2


func _current_action_evade() -> bool:
	var idx: int = posmod(_action_idx, 4)
	return idx == 0 or idx == 2


func _current_target_terrain() -> GameEnums.TerrainClass:
	match posmod(_target_idx, 4):
		2:
			return GameEnums.TerrainClass.DAMARLI_YAMAC
		3:
			return GameEnums.TerrainClass.HAKIMIYET_PLATOSU
		_:
			return GameEnums.TerrainClass.SIK_ORMAN


func _current_target_geo() -> GameEnums.RegionGeographyClass:
	match posmod(_target_idx, 4):
		1:
			return GameEnums.RegionGeographyClass.SHELTERED_VALLEY_KISLAK
		3:
			return GameEnums.RegionGeographyClass.SACRED_CORE
		_:
			return GameEnums.RegionGeographyClass.FOREST_EDGE


func _connect_bus() -> void:
	if _signals_connected:
		return
	_signals_connected = true
	_sub(EventBus.courier_dispatched, _on_bus_courier_dispatched)
	_sub(EventBus.courier_order_delivered, _on_bus_courier_delivered)
	_sub(EventBus.courier_ambushed_plan_exposed, _on_bus_courier_ambushed)
	_sub(EventBus.dust_decoy_toggled, _on_bus_dust_toggled)
	_sub(EventBus.offline_doctrine_configured, _on_bus_doctrine_configured)
	_sub(EventBus.wind_weather_changed, _on_bus_weather_changed)


func _sub(sig: Signal, cb: Callable) -> void:
	if not sig.is_connected(cb):
		sig.connect(cb)
	_bus_subs.append(BusSub.new(sig, cb))


func _disconnect_bus() -> void:
	for s: BusSub in _bus_subs:
		if s.bus_signal.is_connected(s.callback):
			s.bus_signal.disconnect(s.callback)
	_bus_subs.clear()
	_signals_connected = false


func _disconnect_buttons() -> void:
	for btn: Button in _btn_callbacks:
		if btn != null and is_instance_valid(btn):
			var cb: Callable = _btn_callbacks[btn]
			if not cb.is_null() and btn.pressed.is_connected(cb):
				btn.pressed.disconnect(cb)
	_btn_callbacks.clear()


func _on_terrain_cycle_pressed() -> void:
	_terrain_idx = (_terrain_idx + 1) % 3
	_sync_preview_to_viewmodel()
	refresh_from_viewmodel()


func _on_storm_toggle_pressed() -> void:
	_courier_storm = not _courier_storm
	_sync_preview_to_viewmodel()
	refresh_from_viewmodel()


func _on_distance_cycle_pressed() -> void:
	_distance_idx = (_distance_idx + 1) % 3
	_sync_preview_to_viewmodel()
	refresh_from_viewmodel()


func _on_tactic_cycle_pressed() -> void:
	_tactic_idx = (_tactic_idx + 1) % 5
	_sync_preview_to_viewmodel()


func _on_dispatch_courier_pressed() -> void:
	trigger_dispatch_courier()


func _on_toggle_dust_pressed() -> void:
	trigger_toggle_dust(-1)


func _on_if_cycle_pressed() -> void:
	_trigger_idx = (_trigger_idx + 1) % 6
	_sync_builder_labels()


func _on_do_cycle_pressed() -> void:
	_action_idx = (_action_idx + 1) % 4
	_sync_builder_labels()


func _on_target_cycle_pressed() -> void:
	_target_idx = (_target_idx + 1) % 4
	_sync_builder_labels()


func _on_apply_doctrine_pressed() -> void:
	trigger_apply_doctrine()


func _on_bus_courier_dispatched(_order_id: StringName, _player_id: int, target_army_id: int, _eta_sec: float) -> void:
	if target_army_id == get_view_model().get_army_id():
		refresh_from_viewmodel()


func _on_bus_courier_delivered(_order_id: StringName, _player_id: int, target_army_id: int, _cmd_type: StringName) -> void:
	if target_army_id == get_view_model().get_army_id():
		refresh_from_viewmodel()


func _on_bus_courier_ambushed(_order_id: StringName, victim_player_id: int, _ambusher_id: int, _leaked: GameEnums.TuranTacticPhase) -> void:
	if victim_player_id == get_view_model().get_player_id():
		refresh_from_viewmodel()


func _on_bus_dust_toggled(army_id: int, _player_id: int, _is_active: bool) -> void:
	if army_id == get_view_model().get_army_id():
		refresh_from_viewmodel()


func _on_bus_doctrine_configured(army_id: int, _trig: GameEnums.OfflineDoctrineTrigger, _ratio: float, _act: GameEnums.TuranTacticPhase, _terr: GameEnums.TerrainClass, _geo: GameEnums.RegionGeographyClass, _pack: bool, _evade: bool) -> void:
	if army_id == get_view_model().get_army_id():
		refresh_from_viewmodel()


func _on_bus_weather_changed(_wind: Vector3, _temp: float, _state: GameEnums.WindWeatherState) -> void:
	refresh_from_viewmodel()
