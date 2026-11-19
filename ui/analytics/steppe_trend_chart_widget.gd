class_name SteppeTrendChartWidget
extends Control
## Custom `_draw()` time-series line & projection chart (rank 4).
## Displays historical seasons, horizontal gridlines, min/max peak callouts,
## dashed 3-season projection curve, and interactive hover/click point readout.

signal point_selected(point_index: int, is_projection: bool, label: String, value: float)

const TOP_PAD: float = 18.0
const BOTTOM_PAD: float = 34.0
const LEFT_PAD: float = 42.0
const RIGHT_PAD: float = 14.0

var _history_points: Array[MetricAnalyticsViewModel.TimeSeriesPoint] = []
var _projection_points: Array[MetricAnalyticsViewModel.TimeSeriesPoint] = []
var _combined_points: Array[MetricAnalyticsViewModel.TimeSeriesPoint] = []
var _point_screen_positions: Array[Vector2] = []

var _accent_color: Color = NeoSteppePalette.JADE_PRIMARY
var _unit_suffix: String = ""
var _selected_index: int = -1
var _min_val: float = 0.0
var _max_val: float = 100.0
var _min_hist_idx: int = -1
var _max_hist_idx: int = -1


func _init() -> void:
	custom_minimum_size = Vector2(360.0, 152.0)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_STOP


func set_series_data(snap: MetricAnalyticsViewModel.MetricBreakdownSnapshot) -> void:
	_history_points.clear()
	_projection_points.clear()
	_combined_points.clear()
	_point_screen_positions.clear()
	_min_hist_idx = -1
	_max_hist_idx = -1
	_selected_index = -1

	if snap == null:
		queue_redraw()
		return

	_accent_color = NeoSteppePalette.get_semantic_color(snap.tone_id)
	_unit_suffix = snap.unit_suffix

	for pt: MetricAnalyticsViewModel.TimeSeriesPoint in snap.history_points:
		if pt != null:
			_history_points.append(pt)
			_combined_points.append(pt)
	for pt_p: MetricAnalyticsViewModel.TimeSeriesPoint in snap.projection_points:
		if pt_p != null:
			_projection_points.append(pt_p)
			_combined_points.append(pt_p)

	if _combined_points.is_empty():
		queue_redraw()
		return

	var lo: float = _combined_points[0].value
	var hi: float = _combined_points[0].value
	for pt_all: MetricAnalyticsViewModel.TimeSeriesPoint in _combined_points:
		lo = minf(lo, pt_all.value)
		hi = maxf(hi, pt_all.value)

	if not _history_points.is_empty():
		var h_lo: float = _history_points[0].value
		var h_hi: float = _history_points[0].value
		_min_hist_idx = 0
		_max_hist_idx = 0
		for i: int in range(_history_points.size()):
			var v: float = _history_points[i].value
			if v < h_lo:
				h_lo = v
				_min_hist_idx = i
			if v > h_hi:
				h_hi = v
				_max_hist_idx = i

	var span: float = maxf(hi - lo, 4.0)
	_min_val = maxf(lo - span * 0.15, 0.0)
	_max_val = hi + span * 0.18
	if _max_val <= _min_val:
		_max_val = _min_val + 10.0

	_selected_index = maxi(_history_points.size() - 1, 0)
	queue_redraw()


func select_point(index: int) -> void:
	if _combined_points.is_empty():
		_selected_index = -1
		return
	var clamped: int = clampi(index, 0, _combined_points.size() - 1)
	_selected_index = clamped
	var pt: MetricAnalyticsViewModel.TimeSeriesPoint = _combined_points[clamped]
	point_selected.emit(clamped, pt.is_projection, pt.season_label, pt.value)
	queue_redraw()


func get_selected_index() -> int:
	return _selected_index


func get_total_point_count() -> int:
	return _combined_points.size()


func get_projection_point_count() -> int:
	return _projection_points.size()


func get_peak_bounds() -> Vector2:
	if _history_points.is_empty():
		return Vector2.ZERO
	var lo: float = _history_points[_min_hist_idx].value if _min_hist_idx >= 0 else _min_val
	var hi: float = _history_points[_max_hist_idx].value if _max_hist_idx >= 0 else _max_val
	return Vector2(lo, hi)


func get_selected_readout_text() -> String:
	if _selected_index < 0 or _selected_index >= _combined_points.size():
		return "Veri yok"
	var pt: MetricAnalyticsViewModel.TimeSeriesPoint = _combined_points[_selected_index]
	var tag: String = "Tahmin" if pt.is_projection else "Gerçek"
	var suffix_str: String = (" " + _unit_suffix) if (not _unit_suffix.is_empty() and _unit_suffix != "%") else _unit_suffix
	return "%s (%s): %.1f%s" % [pt.season_label, tag, pt.value, suffix_str]


func _gui_input(event: InputEvent) -> void:
	if _point_screen_positions.is_empty():
		return
	var target_x: float = -1.0
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			target_x = mb.position.x
	elif event is InputEventMouseMotion:
		var mm: InputEventMouseMotion = event as InputEventMouseMotion
		if mm != null and (mm.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			target_x = mm.position.x
	if target_x < 0.0:
		return

	var best_idx: int = 0
	var best_dist: float = absf(_point_screen_positions[0].x - target_x)
	for i: int in range(1, _point_screen_positions.size()):
		var d: float = absf(_point_screen_positions[i].x - target_x)
		if d < best_dist:
			best_dist = d
			best_idx = i
	select_point(best_idx)
	if get_viewport() != null:
		get_viewport().set_input_as_handled()


func _draw() -> void:
	var w: float = maxf(size.x, custom_minimum_size.x)
	var h: float = maxf(size.y, custom_minimum_size.y)
	var full_rect: Rect2 = Rect2(Vector2.ZERO, Vector2(w, h))

	draw_rect(full_rect, NeoSteppePalette.OBSIDIAN_DEEP, true)
	draw_rect(full_rect, NeoSteppePalette.BRONZE_DARK, false, 1.0)

	var plot_w: float = maxf(w - LEFT_PAD - RIGHT_PAD, 40.0)
	var plot_h: float = maxf(h - TOP_PAD - BOTTOM_PAD, 36.0)
	var plot_rect: Rect2 = Rect2(Vector2(LEFT_PAD, TOP_PAD), Vector2(plot_w, plot_h))

	var font: Font = ThemeDB.fallback_font
	var val_span: float = maxf(_max_val - _min_val, 1.0)

	# 3 Horizontal grid lines (min, mid, max)
	var grid_col: Color = Color(NeoSteppePalette.BRONZE_DARK.r, NeoSteppePalette.BRONZE_DARK.g, NeoSteppePalette.BRONZE_DARK.b, 0.35)
	for step: int in range(3):
		var t: float = float(step) * 0.5
		var y_line: float = plot_rect.position.y + plot_rect.size.y * (1.0 - t)
		draw_line(Vector2(plot_rect.position.x, y_line), Vector2(plot_rect.end.x, y_line), grid_col, 1.0)
		var tick_v: float = _min_val + val_span * t
		if font != null:
			draw_string(font, Vector2(4.0, y_line + 3.0), "%.0f" % tick_v, HORIZONTAL_ALIGNMENT_RIGHT, LEFT_PAD - 8.0, 10, NeoSteppePalette.TEXT_MUTED)

	if _combined_points.is_empty():
		if font != null:
			draw_string(font, plot_rect.position + Vector2(12.0, plot_h * 0.5), "Zaman serisi verisi bekleniyor", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, NeoSteppePalette.TEXT_MUTED)
		return

	_point_screen_positions.clear()
	var n_total: int = _combined_points.size()
	for i: int in range(n_total):
		var pt: MetricAnalyticsViewModel.TimeSeriesPoint = _combined_points[i]
		var x_ratio: float = float(i) / float(maxi(n_total - 1, 1))
		var y_ratio: float = clampf((pt.value - _min_val) / val_span, 0.0, 1.0)
		var px: float = plot_rect.position.x + x_ratio * plot_rect.size.x
		var py: float = plot_rect.end.y - y_ratio * plot_rect.size.y
		_point_screen_positions.append(Vector2(px, py))

	# History area fill & line
	var hist_cnt: int = _history_points.size()
	if hist_cnt >= 2:
		var poly: PackedVector2Array = PackedVector2Array()
		var line_pts: PackedVector2Array = PackedVector2Array()
		for i: int in range(hist_cnt):
			poly.append(_point_screen_positions[i])
			line_pts.append(_point_screen_positions[i])
		poly.append(Vector2(_point_screen_positions[hist_cnt - 1].x, plot_rect.end.y))
		poly.append(Vector2(_point_screen_positions[0].x, plot_rect.end.y))
		var fill_col: Color = Color(_accent_color.r, _accent_color.g, _accent_color.b, 0.16)
		draw_colored_polygon(poly, fill_col)
		draw_polyline(line_pts, _accent_color, 2.3, true)

	# 3-Season projection dashed curve
	if not _projection_points.is_empty() and hist_cnt >= 1:
		var start_idx: int = hist_cnt - 1
		var proj_col: Color = NeoSteppePalette.ICE_FROST
		for j: int in range(start_idx, n_total - 1):
			draw_dashed_line(_point_screen_positions[j], _point_screen_positions[j + 1], proj_col, 2.0, 5.0, false, true)
		var border_x: float = _point_screen_positions[start_idx].x
		draw_dashed_line(Vector2(border_x, plot_rect.position.y), Vector2(border_x, plot_rect.end.y), Color(NeoSteppePalette.GOLD_PALE.r, NeoSteppePalette.GOLD_PALE.g, NeoSteppePalette.GOLD_PALE.b, 0.45), 1.0, 4.0, false, true)

	# Plot points + Min/Max peaks
	for i: int in range(n_total):
		var pos: Vector2 = _point_screen_positions[i]
		var is_proj: bool = _combined_points[i].is_projection
		var node_col: Color = NeoSteppePalette.ICE_FROST if is_proj else _accent_color
		if i == _max_hist_idx:
			node_col = NeoSteppePalette.GOLD_TAMGA
		elif i == _min_hist_idx:
			node_col = NeoSteppePalette.EMBER_BRIGHT
		draw_circle(pos, 4.2 if (i == _max_hist_idx or i == _min_hist_idx) else 3.2, NeoSteppePalette.OBSIDIAN_DEEP)
		draw_arc(pos, 4.2 if (i == _max_hist_idx or i == _min_hist_idx) else 3.2, 0.0, TAU, 16, node_col, 2.0, true)

	if font != null:
		if _max_hist_idx >= 0 and _max_hist_idx < _point_screen_positions.size():
			var mp: Vector2 = _point_screen_positions[_max_hist_idx]
			draw_string(font, Vector2(clampf(mp.x - 16.0, plot_rect.position.x, plot_rect.end.x - 42.0), maxf(mp.y - 6.0, 11.0)), "Zirve", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, NeoSteppePalette.GOLD_TAMGA)
		if _min_hist_idx >= 0 and _min_hist_idx != _max_hist_idx and _min_hist_idx < _point_screen_positions.size():
			var mnp: Vector2 = _point_screen_positions[_min_hist_idx]
			draw_string(font, Vector2(clampf(mnp.x - 18.0, plot_rect.position.x, plot_rect.end.x - 46.0), minf(mnp.y + 13.0, plot_rect.end.y - 2.0)), "Dip", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, NeoSteppePalette.EMBER_BRIGHT)

	# Selected point highlight + bottom readout footer
	if _selected_index >= 0 and _selected_index < _point_screen_positions.size():
		var sp: Vector2 = _point_screen_positions[_selected_index]
		draw_line(Vector2(sp.x, plot_rect.position.y), Vector2(sp.x, plot_rect.end.y), Color(NeoSteppePalette.GOLD_TAMGA.r, NeoSteppePalette.GOLD_TAMGA.g, NeoSteppePalette.GOLD_TAMGA.b, 0.55), 1.2)
		draw_circle(sp, 6.0, Color(NeoSteppePalette.GOLD_TAMGA.r, NeoSteppePalette.GOLD_TAMGA.g, NeoSteppePalette.GOLD_TAMGA.b, 0.30))
		draw_arc(sp, 5.5, 0.0, TAU, 20, NeoSteppePalette.GOLD_TAMGA, 2.0, true)

	if font != null:
		var readout: String = get_selected_readout_text()
		draw_string(font, Vector2(8.0, h - 10.0), readout, HORIZONTAL_ALIGNMENT_LEFT, w - 16.0, 11, NeoSteppePalette.GOLD_PALE)
		if _projection_points.size() > 0:
			draw_string(font, Vector2(w - 132.0, 12.0), "--- 3M Tahmin", HORIZONTAL_ALIGNMENT_RIGHT, 124.0, 9, NeoSteppePalette.ICE_FROST)
