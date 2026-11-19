class_name CourierLatencyGauge
extends Control
## UI Tactical Visualization (rank 4). Custom `_draw()` segmented **Courier
## Order Latency & Ambush Exposure Gauge**:
##   - Segment 1 (`ICE_BLUE`): Base courier distance delay (`18 m/s`)
##   - Segment 2 (`GOLD_TAMGA`): Mountain / Forest terrain multiplier (`1.65x`)
##   - Segment 3 (`EMBER_RED`): Pre-Zud / Winter storm delay multiplier (`1.45x`)
##   - Secondary Track: Route ambush probability (`%`) & leaked tactic alert.

var _base_sec: float = 10.0
var _terrain_sec: float = 0.0
var _storm_sec: float = 0.0
var _total_sec: float = 10.0
var _remaining_sec: float = 10.0
var _ambush_risk_pct: float = 10.0
var _status: GameEnums.CourierStatus = GameEnums.CourierStatus.DELIVERED
var _plan_leaked: bool = false


func _init() -> void:
	name = "CourierLatencyGauge"
	custom_minimum_size = Vector2(248.0, 76.0)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_PASS


func apply_metrics(base_sec: float, terrain_sec: float, storm_sec: float, total_sec: float, remaining_sec: float, ambush_risk_pct: float, status: GameEnums.CourierStatus, leaked: bool) -> void:
	_base_sec = maxf(_safe_f(base_sec, 0.0), 0.0)
	_terrain_sec = maxf(_safe_f(terrain_sec, 0.0), 0.0)
	_storm_sec = maxf(_safe_f(storm_sec, 0.0), 0.0)
	var sum_bd: float = _base_sec + _terrain_sec + _storm_sec
	var safe_total: float = maxf(_safe_f(total_sec, sum_bd), 0.0)
	_total_sec = safe_total if safe_total > 0.0 else sum_bd
	_remaining_sec = clampf(_safe_f(remaining_sec, 0.0), 0.0, maxf(_total_sec, 0.0))
	_ambush_risk_pct = clampf(_safe_f(ambush_risk_pct, 0.0), 0.0, 100.0)
	_status = status
	_plan_leaked = leaked
	queue_redraw()


func get_ambush_risk_pct() -> float:
	return _ambush_risk_pct


func get_total_delay_sec() -> float:
	return _total_sec


func is_plan_leaked() -> bool:
	return _plan_leaked


static func compute_segment_widths(total_width: float, base_sec: float, terrain_sec: float, storm_sec: float) -> Dictionary[StringName, float]:
	var safe_w: float = maxf(_safe_f(total_width, 0.0), 0.0)
	var b: float = maxf(_safe_f(base_sec, 0.0), 0.0)
	var t: float = maxf(_safe_f(terrain_sec, 0.0), 0.0)
	var s: float = maxf(_safe_f(storm_sec, 0.0), 0.0)
	var total: float = b + t + s
	if total <= 0.0001 or safe_w <= 0.0:
		return {&"base_w": 0.0, &"terrain_w": 0.0, &"storm_w": 0.0}
	var base_w: float = safe_w * (b / total)
	var terrain_w: float = safe_w * (t / total)
	var storm_w: float = maxf(safe_w - base_w - terrain_w, 0.0)
	return {
		&"base_w": base_w,
		&"terrain_w": terrain_w,
		&"storm_w": storm_w,
	}


static func _safe_f(val: float, fallback: float) -> float:
	if is_nan(val) or is_inf(val):
		return fallback
	return val


func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	if w < 24.0 or h < 24.0:
		return

	var pad_x: float = 4.0
	var bar_w: float = maxf(w - pad_x * 2.0, 10.0)
	var font: Font = _resolve_font()

	# Header Label Row
	if font != null:
		var status_str: String = "Hazır %.1fs" % _total_sec
		var status_col: Color = NeoSteppePalette.ICE_FROST
		if _plan_leaked or _status == GameEnums.CourierStatus.AMBUSHED_LOST:
			status_str = "PUSUDA SIZDI! (%.1fs)" % _total_sec
			status_col = NeoSteppePalette.EMBER_BRIGHT
		elif _status == GameEnums.CourierStatus.IN_TRANSIT:
			status_str = "Yolda: %.1f / %.1fs" % [_remaining_sec, _total_sec]
			status_col = NeoSteppePalette.GOLD_PALE
		elif _total_sec > 0.0:
			status_str = "Süre: %.1fs (T%.1f + A%.1f + F%.1f)" % [_total_sec, _base_sec, _terrain_sec, _storm_sec]
		draw_string(font, Vector2(pad_x, 12.0), status_str, HORIZONTAL_ALIGNMENT_LEFT, bar_w, NeoSteppePalette.FONT_SIZE_MICRO, status_col)

	# Segmented Latency Bar
	var bar_y: float = 17.0
	var bar_h: float = 16.0
	draw_rect(Rect2(pad_x, bar_y, bar_w, bar_h), NeoSteppePalette.CHARCOAL_PRESSED, true)
	var widths: Dictionary[StringName, float] = compute_segment_widths(bar_w, _base_sec, _terrain_sec, _storm_sec)
	var cur_x: float = pad_x
	if widths[&"base_w"] > 0.5:
		draw_rect(Rect2(cur_x, bar_y, widths[&"base_w"], bar_h), NeoSteppePalette.ICE_BLUE, true)
		cur_x += widths[&"base_w"]
	if widths[&"terrain_w"] > 0.5:
		draw_rect(Rect2(cur_x, bar_y, widths[&"terrain_w"], bar_h), NeoSteppePalette.GOLD_TAMGA, true)
		cur_x += widths[&"terrain_w"]
	if widths[&"storm_w"] > 0.5:
		draw_rect(Rect2(cur_x, bar_y, widths[&"storm_w"], bar_h), NeoSteppePalette.EMBER_RED, true)
	draw_rect(Rect2(pad_x, bar_y, bar_w, bar_h), NeoSteppePalette.BRONZE_WEATHERED, false, 1.0)

	# Transit progress cursor
	if _status == GameEnums.CourierStatus.IN_TRANSIT and _total_sec > 0.01:
		var prog: float = clampf(1.0 - (_remaining_sec / _total_sec), 0.0, 1.0)
		var cursor_x: float = pad_x + bar_w * prog
		draw_line(Vector2(cursor_x, bar_y - 2.0), Vector2(cursor_x, bar_y + bar_h + 2.0), NeoSteppePalette.GOLD_PALE, 2.0)

	# Legend row
	if font != null:
		var leg: String = "Taban · Arazi %.1fs · Fırtına %.1fs" % [_terrain_sec, _storm_sec]
		draw_string(font, Vector2(pad_x, 45.0), leg, HORIZONTAL_ALIGNMENT_LEFT, bar_w, NeoSteppePalette.FONT_SIZE_MICRO, NeoSteppePalette.TEXT_SECONDARY)

	# Ambush Exposure Risk Bar
	var risk_y: float = 52.0
	var risk_h: float = 12.0
	var risk_ratio: float = clampf(_ambush_risk_pct / 100.0, 0.0, 1.0)
	var risk_col: Color = NeoSteppePalette.EMBER_RED if (_plan_leaked or _ambush_risk_pct >= 55.0) else (NeoSteppePalette.GOLD_TAMGA if _ambush_risk_pct >= 30.0 else NeoSteppePalette.JADE_PRIMARY)
	draw_rect(Rect2(pad_x, risk_y, bar_w, risk_h), NeoSteppePalette.CHARCOAL_PRESSED, true)
	if risk_ratio > 0.0:
		draw_rect(Rect2(pad_x, risk_y, bar_w * risk_ratio, risk_h), risk_col, true)
	draw_rect(Rect2(pad_x, risk_y, bar_w, risk_h), NeoSteppePalette.BRONZE_DARK, false, 1.0)
	if font != null:
		var risk_txt: String = "Pusu & Plan Sızması Riski: %%%.0f" % _ambush_risk_pct
		draw_string(font, Vector2(pad_x, 75.0), risk_txt, HORIZONTAL_ALIGNMENT_LEFT, bar_w, NeoSteppePalette.FONT_SIZE_MICRO, NeoSteppePalette.GOLD_PALE if _plan_leaked else NeoSteppePalette.TEXT_SECONDARY)


func _resolve_font() -> Font:
	var f: Font = get_theme_font(&"font", &"Label")
	if f != null:
		return f
	return ThemeDB.fallback_font
