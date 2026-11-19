class_name MetricBreakdownPopover
extends TamgaCardPanel
## Floating Neo-Steppe analytical popover (rank 4) displaying a time-series
## curve with peaks & 3-season projection (`SteppeTrendChartWidget`),
## semantic +/- factor attribution (`FactorBreakdownList`), and a quick-action
## jump button to the authoritative domain drawer slot.

signal quick_action_requested(primary_slot: StringName, fallback_slot: StringName)
signal popover_closed()

const SWITCH_LABELS: Dictionary[StringName, String] = {
	&"nufus": "Nüfus",
	&"kut": "Kut",
	&"ulus": "Ülüş",
	&"yilki": "Yılkı",
	&"su": "Su",
	&"hazine": "Hazine",
	&"ordu": "Ordu",
}

var _vm_ref: WeakRef = null
var _active_metric_id: StringName = MetricAnalyticsViewModel.METRIC_KUT
var _last_snapshot: MetricAnalyticsViewModel.MetricBreakdownSnapshot = null

var _built: bool = false
var _title_lbl: Label = null
var _value_lbl: Label = null
var _subtitle_lbl: Label = null
var _peaks_lbl: Label = null
var _close_btn: Button = null
var _quick_action_btn: Button = null
var _chart_widget: SteppeTrendChartWidget = null
var _factor_list: FactorBreakdownList = null

var _switch_buttons: Dictionary[StringName, Button] = {}
var _switch_callbacks: Dictionary[Button, Callable] = {}
var _close_cb: Callable = Callable()
var _quick_action_cb: Callable = Callable()
var _chart_point_cb: Callable = Callable()


func _init() -> void:
	name = "MetricBreakdownPopover"
	card_id = &"metric_breakdown_popover"
	clickable = false
	semantic_tone = &"gold"
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP


func _ready() -> void:
	_ensure_built()


func _exit_tree() -> void:
	_disconnect_all_signals()


func bind_view_model(vm: MetricAnalyticsViewModel) -> void:
	_vm_ref = weakref(vm) if vm != null else null


func open_metric(metric_id: StringName, vm: MetricAnalyticsViewModel = null) -> void:
	_ensure_built()
	if vm != null:
		bind_view_model(vm)
	_active_metric_id = metric_id if MetricAnalyticsViewModel.METRIC_ORDER.has(metric_id) else MetricAnalyticsViewModel.METRIC_KUT
	visible = true
	refresh_active_metric()


func refresh_active_metric() -> void:
	_ensure_built()
	var vm_obj: Object = _vm_ref.get_ref() if _vm_ref != null else null
	var vm: MetricAnalyticsViewModel = vm_obj as MetricAnalyticsViewModel if vm_obj != null else null
	if vm == null:
		return
	var snap: MetricAnalyticsViewModel.MetricBreakdownSnapshot = vm.capture_metric_breakdown(_active_metric_id)
	_last_snapshot = snap
	set_semantic_tone(snap.tone_id, 0.0)

	_title_lbl.text = snap.title
	_value_lbl.text = snap.formatted_value
	_value_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.get_semantic_color(snap.tone_id))
	_subtitle_lbl.text = snap.subtitle
	_peaks_lbl.text = "Zirve: %.1f (%s) · Dip: %.1f (%s) · Son Değişim: %s%.1f" % [
		snap.max_value, snap.max_label,
		snap.min_value, snap.min_label,
		"+" if snap.trend_delta >= 0.0 else "", snap.trend_delta]

	_chart_widget.set_series_data(snap)
	_factor_list.set_factors(snap.factors)
	_quick_action_btn.text = "%s ->" % snap.quick_action_label
	_sync_switch_buttons()


func close_popover() -> void:
	if not visible:
		return
	visible = false
	popover_closed.emit()


func get_active_metric_id() -> StringName:
	return _active_metric_id


func get_chart_widget() -> SteppeTrendChartWidget:
	_ensure_built()
	return _chart_widget


func get_factor_count() -> int:
	if _last_snapshot == null:
		return 0
	return _last_snapshot.factors.size()


func get_quick_action_button() -> Button:
	_ensure_built()
	return _quick_action_btn


func _ensure_built() -> void:
	if _built:
		return
	_built = true

	var margin: MarginContainer = get_content_container()
	margin.add_theme_constant_override(&"margin_left", 12)
	margin.add_theme_constant_override(&"margin_right", 12)
	margin.add_theme_constant_override(&"margin_top", 10)
	margin.add_theme_constant_override(&"margin_bottom", 10)

	var root_v: VBoxContainer = VBoxContainer.new()
	root_v.name = "PopoverRootVBox"
	root_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_v.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_v.add_theme_constant_override(&"separation", 6)
	margin.add_child(root_v)

	# Header
	var header_h: HBoxContainer = HBoxContainer.new()
	header_h.add_theme_constant_override(&"separation", 6)
	root_v.add_child(header_h)

	_title_lbl = Label.new()
	_title_lbl.theme_type_variation = &"TitleLabel"
	_title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_lbl.clip_text = true
	header_h.add_child(_title_lbl)

	_value_lbl = Label.new()
	_value_lbl.theme_type_variation = &"MetricLabel"
	header_h.add_child(_value_lbl)

	_close_btn = Button.new()
	_close_btn.name = "CloseMetricPopoverBtn"
	_close_btn.theme_type_variation = &"GhostIconButton"
	_close_btn.text = "✕"
	OtukenThemeFactory.apply_button_semantic_styles(_close_btn, NeoSteppePalette.BRONZE_WEATHERED, false, 6, 2)
	_close_cb = close_popover
	_close_btn.pressed.connect(_close_cb)
	header_h.add_child(_close_btn)

	_subtitle_lbl = Label.new()
	_subtitle_lbl.theme_type_variation = &"MutedLabel"
	_subtitle_lbl.clip_text = true
	root_v.add_child(_subtitle_lbl)

	# 7 Metric Quick Switch Strip
	var switch_h: HFlowContainer = HFlowContainer.new()
	switch_h.add_theme_constant_override(&"h_separation", 4)
	switch_h.add_theme_constant_override(&"v_separation", 3)
	root_v.add_child(switch_h)

	for mid: StringName in MetricAnalyticsViewModel.METRIC_ORDER:
		var btn: Button = Button.new()
		btn.name = "MetricSwitchBtn_%s" % String(mid)
		btn.theme_type_variation = &"GhostIconButton"
		btn.text = SWITCH_LABELS[mid] if SWITCH_LABELS.has(mid) else String(mid)
		btn.add_theme_font_size_override(&"font_size", NeoSteppePalette.FONT_SIZE_MICRO)
		var cb: Callable = _on_switch_metric_pressed.bind(mid)
		btn.pressed.connect(cb)
		switch_h.add_child(btn)
		_switch_buttons[mid] = btn
		_switch_callbacks[btn] = cb

	_peaks_lbl = Label.new()
	_peaks_lbl.theme_type_variation = &"CaptionLabel"
	_peaks_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.GOLD_PALE)
	root_v.add_child(_peaks_lbl)

	_chart_widget = SteppeTrendChartWidget.new()
	_chart_point_cb = _on_chart_point_selected
	_chart_widget.point_selected.connect(_chart_point_cb)
	root_v.add_child(_chart_widget)

	var factor_hdr: Label = Label.new()
	factor_hdr.theme_type_variation = &"CaptionLabel"
	factor_hdr.text = "ETKEN DAĞILIMI (+/-)"
	factor_hdr.add_theme_color_override(&"font_color", NeoSteppePalette.GOLD_TAMGA)
	root_v.add_child(factor_hdr)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0.0, 96.0)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_v.add_child(scroll)

	_factor_list = FactorBreakdownList.new()
	scroll.add_child(_factor_list)

	_quick_action_btn = Button.new()
	_quick_action_btn.name = "QuickActionDrawerButton"
	_quick_action_btn.theme_type_variation = &"ActionButton"
	_quick_action_btn.text = "İlgili Çekmeceye Git ->"
	OtukenThemeFactory.apply_button_semantic_styles(_quick_action_btn, NeoSteppePalette.JADE_PRIMARY, true, 10, 5)
	_quick_action_cb = _on_quick_action_pressed
	_quick_action_btn.pressed.connect(_quick_action_cb)
	root_v.add_child(_quick_action_btn)


func _sync_switch_buttons() -> void:
	for mid: StringName in _switch_buttons:
		var b: Button = _switch_buttons[mid]
		if b == null:
			continue
		var selected: bool = (mid == _active_metric_id)
		var col: Color = NeoSteppePalette.JADE_PRIMARY if selected else NeoSteppePalette.BRONZE_WEATHERED
		OtukenThemeFactory.apply_button_semantic_styles(b, col, selected, 6, 2)


func _on_switch_metric_pressed(metric_id: StringName) -> void:
	open_metric(metric_id)


func _on_quick_action_pressed() -> void:
	if _last_snapshot == null:
		return
	quick_action_requested.emit(_last_snapshot.primary_drawer_slot, _last_snapshot.fallback_drawer_slot)


func _on_chart_point_selected(_idx: int, is_proj: bool, lbl: String, val: float) -> void:
	if _peaks_lbl == null or _last_snapshot == null:
		return
	var kind_s: String = "3M Tahmin" if is_proj else "Tarihsel"
	_peaks_lbl.text = "%s [%s]: %.1f · Zirve: %.1f · Dip: %.1f" % [
		lbl, kind_s, val, _last_snapshot.max_value, _last_snapshot.min_value]


func _disconnect_all_signals() -> void:
	if _close_btn != null and is_instance_valid(_close_btn) and not _close_cb.is_null():
		if _close_btn.pressed.is_connected(_close_cb):
			_close_btn.pressed.disconnect(_close_cb)
	_close_cb = Callable()

	if _quick_action_btn != null and is_instance_valid(_quick_action_btn) and not _quick_action_cb.is_null():
		if _quick_action_btn.pressed.is_connected(_quick_action_cb):
			_quick_action_btn.pressed.disconnect(_quick_action_cb)
	_quick_action_cb = Callable()

	if _chart_widget != null and is_instance_valid(_chart_widget) and not _chart_point_cb.is_null():
		if _chart_widget.point_selected.is_connected(_chart_point_cb):
			_chart_widget.point_selected.disconnect(_chart_point_cb)
	_chart_point_cb = Callable()

	for b: Button in _switch_callbacks:
		if b != null and is_instance_valid(b):
			var cb: Callable = _switch_callbacks[b]
			if not cb.is_null() and b.pressed.is_connected(cb):
				b.pressed.disconnect(cb)
	_switch_callbacks.clear()
	_switch_buttons.clear()
