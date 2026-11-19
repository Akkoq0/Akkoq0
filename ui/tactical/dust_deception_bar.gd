class_name DustDeceptionBar
extends Control
## UI Tactical Visualization (rank 4). Custom `_draw()` comparative power meter
## showing true military strength vs the ~2.1x illusory army silhouette
## projected by **Yılkı Toz Perdesi (`Toz Perdesi`)**.

var _true_power: float = 100.0
var _perceived_power: float = 100.0
var _decoy_active: bool = false
var _apparent_mult: float = 2.10


func _init() -> void:
	name = "DustDeceptionBar"
	custom_minimum_size = Vector2(248.0, 56.0)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_PASS


func apply_metrics(true_power: float, perceived_power: float, is_active: bool, multiplier: float = 2.10) -> void:
	_true_power = maxf(_safe_f(true_power, 100.0), 1.0)
	_perceived_power = maxf(_safe_f(perceived_power, _true_power), 0.0)
	_decoy_active = is_active
	_apparent_mult = maxf(_safe_f(multiplier, 2.10), 1.0)
	queue_redraw()


func get_true_power() -> float:
	return _true_power


func get_perceived_power() -> float:
	return _perceived_power


func is_decoy_active() -> bool:
	return _decoy_active


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
	var scale_max: float = maxf(maxf(_true_power * _apparent_mult, _perceived_power), 1.0)

	# Row 1: True Power
	if font != null:
		draw_string(font, Vector2(pad_x, 11.0), "Gerçek Güç: %.0f" % _true_power, HORIZONTAL_ALIGNMENT_LEFT, bar_w, NeoSteppePalette.FONT_SIZE_MICRO, NeoSteppePalette.JADE_BRIGHT)
	var true_ratio: float = clampf(_true_power / scale_max, 0.0, 1.0)
	draw_rect(Rect2(pad_x, 14.0, bar_w, 10.0), NeoSteppePalette.CHARCOAL_PRESSED, true)
	draw_rect(Rect2(pad_x, 14.0, bar_w * true_ratio, 10.0), NeoSteppePalette.JADE_PRIMARY, true)
	draw_rect(Rect2(pad_x, 14.0, bar_w, 10.0), NeoSteppePalette.BRONZE_DARK, false, 1.0)

	# Row 2: Perceived Dust Illusion Power
	var ratio_shown: float = _perceived_power / _true_power
	var perc_ratio: float = clampf(_perceived_power / scale_max, 0.0, 1.0)
	var perc_col: Color = NeoSteppePalette.EMBER_BRIGHT if _decoy_active else NeoSteppePalette.BRONZE_WEATHERED
	if font != null:
		var perc_txt: String = "Düşman Algısı: %.0f (%.2fx %s)" % [
			_perceived_power, ratio_shown, "TOZ AKTİF" if _decoy_active else "Normal"]
		draw_string(font, Vector2(pad_x, 38.0), perc_txt, HORIZONTAL_ALIGNMENT_LEFT, bar_w, NeoSteppePalette.FONT_SIZE_MICRO, NeoSteppePalette.GOLD_PALE if _decoy_active else NeoSteppePalette.TEXT_SECONDARY)
	draw_rect(Rect2(pad_x, 42.0, bar_w, 10.0), NeoSteppePalette.CHARCOAL_PRESSED, true)
	draw_rect(Rect2(pad_x, 42.0, bar_w * perc_ratio, 10.0), perc_col, true)
	draw_rect(Rect2(pad_x, 42.0, bar_w, 10.0), NeoSteppePalette.BRONZE_WEATHERED if _decoy_active else NeoSteppePalette.BRONZE_DARK, false, 1.0)


func _resolve_font() -> Font:
	var f: Font = get_theme_font(&"font", &"Label")
	if f != null:
		return f
	return ThemeDB.fallback_font
