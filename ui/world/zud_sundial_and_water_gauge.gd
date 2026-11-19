class_name ZudSundialAndWaterGauge
extends Control
## UI Widget (rank 3). Custom `_draw()` Yaylak/Kışlak Zud Sundial & Poisoned Water
## Ring showing seasonal hemisphere, Zud famine threshold, and well contamination.

var _season_type: GameEnums.SeasonType = GameEnums.SeasonType.SPRING
var _season_name: String = "İlkbahar"
var _is_yaylak: bool = true
var _food_reserve: int = 120
var _zud_threshold: int = 40
var _is_zud_active: bool = false
var _water_purity_ratio: float = 1.0
var _usable_sources: int = 0
var _sabotaged_sources: int = 0
var _registered_sources: int = 0


func _ready() -> void:
	custom_minimum_size = Vector2(280.0, 116.0)


func apply_snapshot(snap: WorldEcologyViewModel.WorldEcologySnapshot) -> void:
	if snap == null:
		return
	_season_type = snap.season_type
	_season_name = snap.season_name
	_is_yaylak = snap.is_yaylak_highland
	_food_reserve = snap.food_reserve
	_zud_threshold = maxi(snap.zud_famine_threshold, 1)
	_is_zud_active = snap.is_zud_active
	_water_purity_ratio = clampf(snap.water_purity_ratio, 0.0, 1.0)
	_usable_sources = snap.usable_water_sources
	_sabotaged_sources = snap.sabotaged_water_sources
	_registered_sources = snap.registered_water_sources
	queue_redraw()


func _draw() -> void:
	var w: float = maxf(size.x, 220.0)
	var h: float = maxf(size.y, 100.0)
	draw_rect(Rect2(Vector2.ZERO, Vector2(w, h)), Color(0.06, 0.07, 0.09, 0.90), true)
	draw_rect(Rect2(Vector2(1.0, 1.0), Vector2(w - 2.0, h - 2.0)), NeoSteppePalette.BRONZE_WEATHERED, false, 1.0)

	# Left: Yaylak / Kışlak Zud Sundial
	var dial_c: Vector2 = Vector2(56.0, h * 0.56)
	var dial_r: float = 34.0
	# Top hemisphere = Yaylak (warm jade/gold), Bottom = Kışlak/Zud (ice/slate)
	draw_arc(dial_c, dial_r, PI, TAU, 24, NeoSteppePalette.JADE_BRIGHT if _is_yaylak else NeoSteppePalette.BRONZE_DARK, 5.0, true)
	draw_arc(dial_c, dial_r, 0.0, PI, 24, NeoSteppePalette.EMBER_RED if _is_zud_active else NeoSteppePalette.ICE_BLUE, 5.0, true)

	# Season hand angle
	var s_angle: float = -PI * 0.75 + float(int(_season_type)) * (PI * 0.5)
	draw_line(dial_c, dial_c + Vector2(cos(s_angle), sin(s_angle)) * (dial_r - 6.0), NeoSteppePalette.GOLD_TAMGA, 2.5, true)
	draw_circle(dial_c, 4.0, NeoSteppePalette.GOLD_TAMGA)

	# Right: Poisoned Water Ring
	var water_c: Vector2 = Vector2(w - 58.0, h * 0.56)
	var water_r: float = 32.0
	draw_arc(water_c, water_r, 0.0, TAU, 32, Color(0.18, 0.16, 0.18, 0.8), 6.0, true)
	var pure_arc: float = TAU * _water_purity_ratio
	if pure_arc > 0.01:
		draw_arc(water_c, water_r, -PI * 0.5, -PI * 0.5 + pure_arc, 32, NeoSteppePalette.ICE_BLUE, 6.0, true)
	if _sabotaged_sources > 0:
		draw_arc(water_c, water_r, -PI * 0.5 + pure_arc, -PI * 0.5 + TAU, 24, NeoSteppePalette.EMBER_RED, 6.0, true)

	var font: Font = ThemeDB.fallback_font
	if font != null:
		var hemi: String = "YAYLAK" if _is_yaylak else "KIŞLAK"
		var zud_tag: String = " [ZUD!]" if _is_zud_active else ""
		draw_string(font, Vector2(8.0, 15.0), "%s · %s%s" % [hemi, _season_name, zud_tag], HORIZONTAL_ALIGNMENT_LEFT, w - 16.0, 11, NeoSteppePalette.EMBER_RED if _is_zud_active else NeoSteppePalette.TEXT_PRIMARY)
		draw_string(font, Vector2(102.0, h * 0.44), "Erzak: %d / %d" % [_food_reserve, _zud_threshold], HORIZONTAL_ALIGNMENT_LEFT, w - 170.0, 11, NeoSteppePalette.TEXT_PRIMARY)
		draw_string(font, Vector2(102.0, h * 0.64), "Su: %d/%d (Zehir:%d)" % [_usable_sources, _registered_sources, _sabotaged_sources], HORIZONTAL_ALIGNMENT_LEFT, w - 170.0, 10, NeoSteppePalette.ICE_BLUE if _sabotaged_sources == 0 else NeoSteppePalette.EMBER_RED)
		draw_string(font, water_c + Vector2(-16.0, 4.0), "%d%%" % roundi(_water_purity_ratio * 100.0), HORIZONTAL_ALIGNMENT_LEFT, 36.0, 11, NeoSteppePalette.TEXT_PRIMARY)
