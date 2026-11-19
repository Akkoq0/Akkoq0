class_name MatchSummaryScreen
extends TamgaCardPanel
## Victory / Defeat Chronicle Screen (rank 4). Renders a multi-series match
## history line chart (`Kut`, `Ordu Gücü`, `Gümüş Hazine`), key historical
## turning points, and Replay / Main Menu navigation.

signal replay_requested()
signal main_menu_requested()


class MultiSeriesSummaryChart:
	extends Control

	var _tracks: Array[GameShellViewModel.MatchSeriesTrack] = []

	func _init() -> void:
		name = "MultiSeriesSummaryChart"
		custom_minimum_size = Vector2(460.0, 150.0)
		size_flags_horizontal = Control.SIZE_EXPAND_FILL

	func set_tracks(tracks: Array[GameShellViewModel.MatchSeriesTrack]) -> void:
		_tracks.clear()
		for t: GameShellViewModel.MatchSeriesTrack in tracks:
			if t != null and not t.values.is_empty():
				_tracks.append(t)
		queue_redraw()

	func _draw() -> void:
		var w: float = maxf(size.x, custom_minimum_size.x)
		var h: float = maxf(size.y, custom_minimum_size.y)
		if w <= 24.0 or h <= 24.0:
			return
		var bg_rect: Rect2 = Rect2(0.0, 0.0, w, h)
		draw_rect(bg_rect, Color(0.05, 0.06, 0.08, 0.90), true)
		draw_rect(bg_rect, NeoSteppePalette.BRONZE_DARK, false, 1.0)

		var font: Font = get_theme_default_font()
		var pad_l: float = 28.0
		var pad_r: float = 16.0
		var pad_t: float = 22.0
		var pad_b: float = 24.0
		var plot_w: float = maxf(w - pad_l - pad_r, 40.0)
		var plot_h: float = maxf(h - pad_t - pad_b, 30.0)

		for g: int in range(4):
			var gy: float = pad_t + plot_h * (float(g) / 3.0)
			draw_line(Vector2(pad_l, gy), Vector2(pad_l + plot_w, gy), Color(0.35, 0.32, 0.25, 0.35), 1.0)

		# Legend
		var lx: float = pad_l
		for tr: GameShellViewModel.MatchSeriesTrack in _tracks:
			var col: Color = NeoSteppePalette.get_semantic_color(tr.tone_id)
			draw_rect(Rect2(lx, 7.0, 9.0, 9.0), col, true)
			if font != null:
				draw_string(font, Vector2(lx + 13.0, 15.0), tr.title, HORIZONTAL_ALIGNMENT_LEFT, 110.0, 9, NeoSteppePalette.TEXT_PRIMARY)
			lx += 118.0

		# Normalized Multi-Series Curves
		for tr2: GameShellViewModel.MatchSeriesTrack in _tracks:
			var col2: Color = NeoSteppePalette.get_semantic_color(tr2.tone_id)
			var cnt: int = tr2.values.size()
			var lo: float = tr2.values[0]
			var hi: float = tr2.values[0]
			for v: float in tr2.values:
				lo = minf(lo, v)
				hi = maxf(hi, v)
			var span: float = maxf(hi - lo, 1.0)
			var pts: PackedVector2Array = PackedVector2Array()
			for idx: int in range(cnt):
				var tx: float = pad_l + (plot_w * (float(idx) / float(maxi(cnt - 1, 1))) if cnt > 1 else plot_w * 0.5)
				var norm_y: float = (tr2.values[idx] - lo) / span
				var ty: float = pad_t + plot_h * (1.0 - clampf(norm_y * 0.8 + 0.1, 0.05, 0.95))
				pts.append(Vector2(tx, ty))
			if pts.size() >= 2:
				draw_polyline(pts, col2, 2.2, true)
			for p_pt: Vector2 in pts:
				draw_circle(p_pt, 3.2, col2)


var _built: bool = false
var _last_summary: GameShellViewModel.MatchSummarySnapshot = null
var _title_lbl: Label = null
var _subtitle_lbl: Label = null
var _stats_lbl: Label = null
var _chart: MultiSeriesSummaryChart = null
var _turning_points_vbox: VBoxContainer = null
var _btn_replay: Button = null
var _btn_main_menu: Button = null
var _btn_callbacks: Dictionary[Button, Callable] = {}


func _init() -> void:
	name = "MatchSummaryScreen"
	card_id = &"match_summary_screen"
	semantic_tone = &"gold"
	clickable = false
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP


func _ready() -> void:
	_ensure_built()


func _exit_tree() -> void:
	for btn: Button in _btn_callbacks.keys():
		if btn != null and is_instance_valid(btn):
			var cb: Callable = _btn_callbacks[btn]
			if cb.is_valid() and btn.pressed.is_connected(cb):
				btn.pressed.disconnect(cb)
	_btn_callbacks.clear()


func open_summary(snap: GameShellViewModel.MatchSummarySnapshot) -> void:
	_ensure_built()
	_last_summary = snap
	visible = true
	if snap == null:
		return

	set_semantic_tone(&"jade" if snap.is_victory else &"ember", 0.0)
	_title_lbl.text = snap.outcome_title
	_title_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.JADE_BRIGHT if snap.is_victory else NeoSteppePalette.EMBER_BRIGHT)
	_subtitle_lbl.text = snap.outcome_subtitle
	_stats_lbl.text = "Toplam Mevsim: %d · Final Kut: %.1f · Hazine: %d Gümüş · Bölge: %d · Gelenek: %d" % [
		snap.total_seasons, snap.final_kut, snap.final_silver, snap.regions_owned, snap.research_completed]
	_chart.set_tracks(snap.series_tracks)

	for ch: Node in _turning_points_vbox.get_children():
		_turning_points_vbox.remove_child(ch)
		ch.queue_free()

	for tp: GameShellViewModel.TurningPointItem in snap.turning_points:
		if tp == null:
			continue
		var lbl: Label = Label.new()
		lbl.theme_type_variation = &"BodyLabel"
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_font_size_override(&"font_size", 11)
		lbl.add_theme_color_override(&"font_color", NeoSteppePalette.get_semantic_color(tp.tone_id))
		lbl.text = "• [%s] %s — %s" % [tp.season_label, tp.title, tp.detail]
		_turning_points_vbox.add_child(lbl)


func close_summary() -> void:
	visible = false


func get_series_count() -> int:
	return _last_summary.series_tracks.size() if _last_summary != null else 0


func get_turning_point_count() -> int:
	return _last_summary.turning_points.size() if _last_summary != null else 0


func get_chart() -> MultiSeriesSummaryChart:
	_ensure_built()
	return _chart


func get_replay_button() -> Button:
	_ensure_built()
	return _btn_replay


func get_main_menu_button() -> Button:
	_ensure_built()
	return _btn_main_menu


func _ensure_built() -> void:
	if _built:
		return
	_built = true

	var margin: MarginContainer = get_content_container()
	margin.add_theme_constant_override(&"margin_left", 16)
	margin.add_theme_constant_override(&"margin_right", 16)
	margin.add_theme_constant_override(&"margin_top", 12)
	margin.add_theme_constant_override(&"margin_bottom", 12)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override(&"separation", 7)
	margin.add_child(vbox)

	_title_lbl = Label.new()
	_title_lbl.theme_type_variation = &"TitleLabel"
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_lbl.add_theme_font_size_override(&"font_size", NeoSteppePalette.FONT_SIZE_DISPLAY)
	vbox.add_child(_title_lbl)

	_subtitle_lbl = Label.new()
	_subtitle_lbl.theme_type_variation = &"CaptionLabel"
	_subtitle_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_subtitle_lbl)

	_stats_lbl = Label.new()
	_stats_lbl.theme_type_variation = &"BodyLabel"
	_stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_stats_lbl)

	_chart = MultiSeriesSummaryChart.new()
	vbox.add_child(_chart)

	var tp_hdr: Label = Label.new()
	tp_hdr.theme_type_variation = &"CaptionLabel"
	tp_hdr.text = "KRİTİK DÖNÜM NOKTALARI"
	vbox.add_child(tp_hdr)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0.0, 90.0)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_turning_points_vbox = VBoxContainer.new()
	_turning_points_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_turning_points_vbox.add_theme_constant_override(&"separation", 3)
	scroll.add_child(_turning_points_vbox)

	var footer: HBoxContainer = HBoxContainer.new()
	footer.add_theme_constant_override(&"separation", 8)
	vbox.add_child(footer)

	_btn_replay = _make_btn("BtnSummaryReplay", "Yeni Sefer (Tekrar Oyna)", NeoSteppePalette.JADE_PRIMARY, _on_replay_pressed)
	_btn_replay.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(_btn_replay)

	_btn_main_menu = _make_btn("BtnSummaryMainMenu", "Ana Menü", NeoSteppePalette.GOLD_TAMGA, _on_main_menu_pressed)
	_btn_main_menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(_btn_main_menu)


func _make_btn(p_name: String, p_text: String, p_col: Color, p_cb: Callable) -> Button:
	var btn: Button = Button.new()
	btn.name = p_name
	btn.theme_type_variation = &"PrimaryCommandButton"
	btn.text = p_text
	OtukenThemeFactory.apply_button_semantic_styles(btn, p_col, false, 10, 5)
	btn.pressed.connect(p_cb)
	_btn_callbacks[btn] = p_cb
	return btn


func _on_replay_pressed() -> void:
	visible = false
	replay_requested.emit()


func _on_main_menu_pressed() -> void:
	visible = false
	main_menu_requested.emit()
