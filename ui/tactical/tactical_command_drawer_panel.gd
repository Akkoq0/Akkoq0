class_name TacticalCommandDrawerPanel
extends VBoxContainer
## UI Domain Drawer Panel (rank 4). Composes Phase 26's **Turan 360° Vector
## Compass**, **Gazi Mirası** veteran telemetry, **Heavy-Armor Terrain/Storm
## Exponential Fatigue Predictor**, and **Courier & Bozkır Nöbeti** controls
## inside `OtukenHudRoot` Layer 3 drawer slot `tactical_command`.

signal tactical_panel_refreshed(army_id: int)


class BusSub:
	var bus_signal: Signal
	var callback: Callable

	func _init(p_sig: Signal, p_cb: Callable) -> void:
		bus_signal = p_sig
		callback = p_cb


var _view_model: TacticalCommandViewModel = null
var _ui_built: bool = false
var _signals_connected: bool = false
var _bus_subs: Array[BusSub] = []
var _btn_callbacks: Dictionary[Button, Callable] = {}

# UI-local preview toggles
var _preview_heavy_armor: bool = false
var _preview_mud: bool = false
var _preview_slope: bool = false
var _preview_storm: bool = false
var _threat_preset_idx: int = 0

# Child UI nodes
var _telemetry_card: TamgaCardPanel = null
var _army_title_lbl: Label = null
var _legacy_lbl: Label = null
var _fatigue_lbl: Label = null
var _doctrine_synergy_lbl: Label = null
var _btn_armor: Button = null
var _btn_mud: Button = null
var _btn_slope: Button = null
var _btn_storm: Button = null
var _btn_threat: Button = null

var _compass_card: TamgaCardPanel = null
var _compass: TuranVectorCompass = null
var _turan_detail_lbl: Label = null

var _courier_doctrine_panel: CourierAndDoctrinePanel = null
var _matchup_preview: DoctrineMatchupPreviewWidget = null
var _research_vm: ResearchTreeViewModel = null


func _init() -> void:
	name = "TacticalCommandDrawerPanel"
	custom_minimum_size = Vector2(260.0, 0.0)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override(&"separation", 8)


func _ready() -> void:
	_ensure_ui()
	_connect_bus()
	refresh_panel()


func _exit_tree() -> void:
	_disconnect_bus()
	_disconnect_buttons()


func bind_context(p_player_id: int, p_army_id: int, army: ArmyController = null) -> void:
	var vm: TacticalCommandViewModel = get_view_model()
	vm.set_context(p_player_id, p_army_id)
	if army != null:
		vm.bind_army(army)
	var rvm: ResearchTreeViewModel = get_research_view_model()
	rvm.set_context(p_player_id, p_army_id)
	if army != null:
		rvm.bind_army(army)
	_ensure_ui()
	_courier_doctrine_panel.set_view_model(vm)
	if _matchup_preview != null:
		_matchup_preview.bind_view_model(rvm)
	refresh_panel()


func get_view_model() -> TacticalCommandViewModel:
	if _view_model == null:
		_view_model = TacticalCommandViewModel.new(1, 1)
	return _view_model


func get_research_view_model() -> ResearchTreeViewModel:
	if _research_vm == null:
		_research_vm = ResearchTreeViewModel.new(1, 1)
	return _research_vm


func get_compass() -> TuranVectorCompass:
	_ensure_ui()
	return _compass


func get_courier_and_doctrine_panel() -> CourierAndDoctrinePanel:
	_ensure_ui()
	return _courier_doctrine_panel


func get_doctrine_matchup_preview() -> DoctrineMatchupPreviewWidget:
	_ensure_ui()
	return _matchup_preview


func set_threat_preview(bearing_rad: float, active: bool = true) -> void:
	get_view_model().set_preview_threat(bearing_rad, active)
	refresh_panel()


func set_armor_weather_preview(heavy_armor: bool, is_mud: bool, is_slope: bool, is_storm: bool) -> void:
	_preview_heavy_armor = heavy_armor
	_preview_mud = is_mud
	_preview_slope = is_slope
	_preview_storm = is_storm
	get_view_model().set_preview_armor_and_weather(heavy_armor, is_mud, is_slope, is_storm)
	_sync_preview_buttons()
	refresh_panel()


func get_legacy_summary_text() -> String:
	_ensure_ui()
	return _legacy_lbl.text if _legacy_lbl != null else ""


func get_fatigue_warning_text() -> String:
	_ensure_ui()
	return _fatigue_lbl.text if _fatigue_lbl != null else ""


func get_doctrine_synergy_text() -> String:
	_ensure_ui()
	return _doctrine_synergy_lbl.text if _doctrine_synergy_lbl != null else ""


func refresh_panel() -> void:
	_ensure_ui()
	var vm: TacticalCommandViewModel = get_view_model()
	var snap: TacticalCommandViewModel.TacticalUnitSnapshot = vm.capture_snapshot()

	if _army_title_lbl != null:
		var status_tag: String = "BOZGUN!" if snap.cascade_routing else ("SARSIK HAT" if snap.staggered_hold else ("DÜŞTÜ" if not snap.commander_alive else "Hazır"))
		_army_title_lbl.text = "%s (#%d) · %s" % [snap.army_display_name, snap.army_id, status_tag]

	if _legacy_lbl != null:
		var cmdr_state: String = "Sağ" if snap.commander_alive else "ŞEHİT/DÜŞTÜ"
		_legacy_lbl.text = "Gazi Mirası: %s (%s) · Gazi %.0f · Yara %d\nTuran Hız %.2fx · Panik Direnci %%%.0f" % [
			snap.commander_name,
			cmdr_state,
			snap.commander_veteran_score,
			snap.commander_scars,
			snap.commander_turan_speed_mult,
			snap.commander_rout_resistance * 100.0]

	if _fatigue_lbl != null:
		var armor_label: String = "AĞIR ZIRH" if snap.is_heavy_armor else "Hafif Süvari"
		_fatigue_lbl.text = "Yorgunluk Fiziği (%s): x%.2f çarpan · Moral %%%.0f · Düzen %%%.0f" % [
			armor_label, snap.heavy_armor_fatigue_mult, snap.current_morale, snap.current_cohesion]
		var warn_col: Color = NeoSteppePalette.EMBER_BRIGHT if (snap.is_heavy_armor and snap.heavy_armor_fatigue_mult >= 2.5) else NeoSteppePalette.TEXT_SECONDARY
		_fatigue_lbl.add_theme_color_override(&"font_color", warn_col)

	if _doctrine_synergy_lbl != null:
		var expo_txt: String = " · PLAN İFŞA!" if snap.courier_plan_exposed_global else ""
		var doc_head: String = snap.active_doctrine_summary if snap.active_doctrine_id != &"" else snap.active_doctrine_name
		_doctrine_synergy_lbl.text = "Nizam: %s\nSinerji %.2fx · Tempo %.2fx · Rezonans %d (%s)%s" % [
			doc_head,
			snap.synergy_combat_power_mult,
			snap.synergy_courier_tempo_mult,
			snap.synergy_active_resonance_count,
			snap.synergy_primary_resonance_name,
			expo_txt]
		var doc_col: Color = NeoSteppePalette.EMBER_BRIGHT if snap.courier_plan_exposed_global else (NeoSteppePalette.JADE_PRIMARY if snap.active_doctrine_id != &"" else NeoSteppePalette.TEXT_MUTED)
		_doctrine_synergy_lbl.add_theme_color_override(&"font_color", doc_col)

	if _telemetry_card != null:
		var tone: StringName = &"ember" if (not snap.commander_alive or snap.cascade_routing or snap.supply_isolated) else (&"gold" if snap.battle_fatigue >= 65.0 else &"jade")
		_telemetry_card.set_semantic_tone(tone, 0.85 if tone == &"ember" else 0.0)

	if _compass != null:
		_compass.apply_snapshot(snap)
	if _compass_card != null:
		var comp_tone: StringName = &"ember" if (snap.escape_vector_sealed or snap.threat_sector == GameEnums.CombatEngagementAngle.REAR) else (&"gold" if snap.turan_fallback_reason != &"" else &"jade")
		_compass_card.set_semantic_tone(comp_tone, 0.7 if comp_tone == &"ember" else 0.0)

	if _turan_detail_lbl != null:
		var seal_txt: String = "KİLİT!" if snap.escape_vector_sealed else "Açık"
		_turan_detail_lbl.text = "%s · Entropi %%%.0f/%%%.0f · Çökme %%%.0f · Kaçış %s" % [
			TacticalCommandViewModel.format_turan_phase_short(snap.turan_phase),
			snap.target_formation_entropy * 100.0,
			snap.critical_entropy_threshold * 100.0,
			snap.target_armor_collapse_ratio * 100.0,
			seal_txt]

	if _courier_doctrine_panel != null:
		_courier_doctrine_panel.refresh_from_viewmodel(snap)
	if _matchup_preview != null:
		_matchup_preview.sync_with_army_preset()
		_matchup_preview.refresh_preview()

	_sync_preview_buttons()
	tactical_panel_refreshed.emit(snap.army_id)


func _ensure_ui() -> void:
	if _ui_built:
		return
	_ui_built = true

	# === 1. Unit & Commander Legacy + Heavy Armor Predictor Card =============
	_telemetry_card = TamgaCardPanel.new()
	_telemetry_card.name = "TacticalUnitTelemetryCard"
	_telemetry_card.semantic_tone = &"jade"
	add_child(_telemetry_card)
	var t_box: VBoxContainer = VBoxContainer.new()
	t_box.add_theme_constant_override(&"separation", 4)
	_telemetry_card.get_content_container().add_child(t_box)

	_army_title_lbl = Label.new()
	_army_title_lbl.name = "ArmyHeaderLabel"
	_army_title_lbl.theme_type_variation = &"MetricLabel"
	_army_title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t_box.add_child(_army_title_lbl)

	_legacy_lbl = Label.new()
	_legacy_lbl.name = "CommanderLegacyLabel"
	_legacy_lbl.theme_type_variation = &"MutedLabel"
	_legacy_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t_box.add_child(_legacy_lbl)

	_fatigue_lbl = Label.new()
	_fatigue_lbl.name = "ArmorFatigueLabel"
	_fatigue_lbl.theme_type_variation = &"CaptionLabel"
	_fatigue_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t_box.add_child(_fatigue_lbl)

	_doctrine_synergy_lbl = Label.new()
	_doctrine_synergy_lbl.name = "DoctrineSynergyLabel"
	_doctrine_synergy_lbl.theme_type_variation = &"CaptionLabel"
	_doctrine_synergy_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t_box.add_child(_doctrine_synergy_lbl)

	var preview_flow: HFlowContainer = HFlowContainer.new()
	preview_flow.add_theme_constant_override(&"h_separation", 4)
	preview_flow.add_theme_constant_override(&"v_separation", 4)
	t_box.add_child(preview_flow)

	_btn_armor = _make_toggle_btn("BtnPreviewArmor", "Zırh: Hafif", _on_armor_pressed)
	preview_flow.add_child(_btn_armor)
	_btn_mud = _make_toggle_btn("BtnPreviewMud", "Çamur", _on_mud_pressed)
	preview_flow.add_child(_btn_mud)
	_btn_slope = _make_toggle_btn("BtnPreviewSlope", "Yamaç", _on_slope_pressed)
	preview_flow.add_child(_btn_slope)
	_btn_storm = _make_toggle_btn("BtnPreviewStorm", "Fırtına", _on_storm_pressed)
	preview_flow.add_child(_btn_storm)
	_btn_threat = _make_toggle_btn("BtnPreviewThreat", "Tehdit: Yok", _on_threat_cycle_pressed)
	preview_flow.add_child(_btn_threat)

	# === 2. Turan 360 Vector Compass Card ====================================
	_compass_card = TamgaCardPanel.new()
	_compass_card.name = "TuranVectorCompassCard"
	_compass_card.semantic_tone = &"jade"
	add_child(_compass_card)
	var c_box: VBoxContainer = VBoxContainer.new()
	c_box.add_theme_constant_override(&"separation", 4)
	_compass_card.get_content_container().add_child(c_box)

	var c_hdr: Label = Label.new()
	c_hdr.theme_type_variation = &"CaptionLabel"
	c_hdr.text = "TURAN 360° VEKTÖR PUSULASI (1.0x / 1.45x / 2.1x)"
	c_hdr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	c_box.add_child(c_hdr)

	_compass = TuranVectorCompass.new()
	c_box.add_child(_compass)

	_turan_detail_lbl = Label.new()
	_turan_detail_lbl.name = "TuranDetailLabel"
	_turan_detail_lbl.theme_type_variation = &"MutedLabel"
	_turan_detail_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	c_box.add_child(_turan_detail_lbl)

	# === 3. Courier Latency, Dust Deception & Bozkır Nöbeti Builder ==========
	_courier_doctrine_panel = CourierAndDoctrinePanel.new()
	_courier_doctrine_panel.set_view_model(get_view_model())
	add_child(_courier_doctrine_panel)

	# === 4. Live Doctrine Matchup Preview Widget =============================
	_matchup_preview = DoctrineMatchupPreviewWidget.new()
	_matchup_preview.bind_view_model(get_research_view_model())
	add_child(_matchup_preview)


func _make_toggle_btn(node_name: String, label_txt: String, cb: Callable) -> Button:
	var btn: Button = Button.new()
	btn.name = node_name
	btn.theme_type_variation = &"GhostIconButton"
	btn.text = label_txt
	OtukenThemeFactory.apply_button_semantic_styles(btn, NeoSteppePalette.BRONZE_WEATHERED, false, 6, 2)
	btn.pressed.connect(cb)
	_btn_callbacks[btn] = cb
	return btn


func _sync_preview_buttons() -> void:
	if _btn_armor != null:
		_btn_armor.text = "Zırh: AĞIR" if _preview_heavy_armor else "Zırh: Hafif"
		OtukenThemeFactory.apply_button_semantic_styles(_btn_armor, NeoSteppePalette.EMBER_RED if _preview_heavy_armor else NeoSteppePalette.JADE_PRIMARY, _preview_heavy_armor, 6, 2)
	if _btn_mud != null:
		OtukenThemeFactory.apply_button_semantic_styles(_btn_mud, NeoSteppePalette.GOLD_TAMGA, _preview_mud, 6, 2)
	if _btn_slope != null:
		OtukenThemeFactory.apply_button_semantic_styles(_btn_slope, NeoSteppePalette.GOLD_TAMGA, _preview_slope, 6, 2)
	if _btn_storm != null:
		OtukenThemeFactory.apply_button_semantic_styles(_btn_storm, NeoSteppePalette.ICE_BLUE, _preview_storm, 6, 2)
	if _btn_threat != null:
		var labels: PackedStringArray = PackedStringArray(["Tehdit: Yok", "Tehdit: Ön 1.0x", "Tehdit: Yan 1.45x", "Tehdit: Arka 2.1x"])
		_btn_threat.text = labels[_threat_preset_idx]
		var col: Color = NeoSteppePalette.EMBER_RED if _threat_preset_idx == 3 else (NeoSteppePalette.GOLD_TAMGA if _threat_preset_idx == 2 else NeoSteppePalette.JADE_PRIMARY)
		OtukenThemeFactory.apply_button_semantic_styles(_btn_threat, col, _threat_preset_idx > 0, 6, 2)


func _connect_bus() -> void:
	if _signals_connected:
		return
	_signals_connected = true
	_sub(EventBus.turan_phase_changed, _on_bus_refresh.unbind(3))
	_sub(EventBus.commander_legacy_updated, _on_bus_refresh.unbind(5))
	_sub(EventBus.commander_fallen_in_battle, _on_bus_refresh.unbind(5))
	_sub(EventBus.offline_doctrine_configured, _on_bus_refresh.unbind(8))
	_sub(EventBus.dust_decoy_toggled, _on_bus_refresh.unbind(3))
	_sub(EventBus.courier_dispatched, _on_bus_refresh.unbind(4))
	_sub(EventBus.courier_order_delivered, _on_bus_refresh.unbind(4))
	_sub(EventBus.courier_ambushed_plan_exposed, _on_bus_refresh.unbind(4))
	_sub(EventBus.wind_weather_changed, _on_bus_refresh.unbind(3))
	_sub(EventBus.army_supply_changed, _on_bus_refresh.unbind(3))
	_sub(EventBus.supply_line_severed, _on_bus_refresh.unbind(4))
	_sub(EventBus.supply_line_restored, _on_bus_refresh.unbind(2))
	_sub(EventBus.cascade_rout_triggered, _on_bus_refresh.unbind(3))
	_sub(EventBus.feigned_retreat_lured, _on_bus_refresh.unbind(5))
	_sub(EventBus.crescent_trap_sprung, _on_bus_refresh.unbind(4))
	_sub(EventBus.battle_doctrine_assigned, _on_bus_refresh.unbind(4))
	_sub(EventBus.systemic_synergy_evaluated, _on_bus_refresh.unbind(1))


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


func _on_bus_refresh() -> void:
	refresh_panel()


func _on_armor_pressed() -> void:
	set_armor_weather_preview(not _preview_heavy_armor, _preview_mud, _preview_slope, _preview_storm)


func _on_mud_pressed() -> void:
	set_armor_weather_preview(_preview_heavy_armor, not _preview_mud, _preview_slope, _preview_storm)


func _on_slope_pressed() -> void:
	set_armor_weather_preview(_preview_heavy_armor, _preview_mud, not _preview_slope, _preview_storm)


func _on_storm_pressed() -> void:
	set_armor_weather_preview(_preview_heavy_armor, _preview_mud, _preview_slope, not _preview_storm)


func _on_threat_cycle_pressed() -> void:
	_threat_preset_idx = (_threat_preset_idx + 1) % 4
	if _threat_preset_idx == 0:
		set_threat_preview(0.0, false)
	elif _threat_preset_idx == 1:
		set_threat_preview(0.0, true)
	elif _threat_preset_idx == 2:
		set_threat_preview(PI * 0.5, true)
	else:
		set_threat_preview(PI, true)
