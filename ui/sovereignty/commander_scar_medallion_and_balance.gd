class_name CommanderScarMedallionAndBalance
extends Control
## UI Widget (rank 3). Custom `_draw()` Commander Scar Medallion (career, age,
## scars, veteran status, heir readiness warning) and Dread vs Honor/Töre Scale.

var _commander_name: String = "Kül Tigin"
var _age_years: int = 26
var _scars: int = 0
var _veteran_score: float = 0.0
var _commander_alive: bool = true
var _heir_ready: bool = true
var _heir_amanat: bool = false
var _dread: float = 0.0
var _honor: float = 50.0
var _reliability: float = 100.0


func _ready() -> void:
	custom_minimum_size = Vector2(280.0, 114.0)


func apply_snapshot(snap: SovereigntyViewModel.SovereigntySnapshot) -> void:
	if snap == null:
		return
	_commander_name = snap.commander_name
	_age_years = snap.commander_age_years
	_scars = snap.commander_scars
	_veteran_score = snap.commander_veteran_score
	_commander_alive = snap.commander_alive
	_heir_ready = snap.heir_ready
	_heir_amanat = snap.heir_amanat
	_dread = snap.dread_score
	_honor = snap.honor_score
	_reliability = snap.word_reliability
	queue_redraw()


func _draw() -> void:
	var w: float = maxf(size.x, 220.0)
	var h: float = maxf(size.y, 100.0)
	draw_rect(Rect2(Vector2.ZERO, Vector2(w, h)), Color(0.06, 0.06, 0.08, 0.90), true)
	draw_rect(Rect2(Vector2(1.0, 1.0), Vector2(w - 2.0, h - 2.0)), NeoSteppePalette.BRONZE_WEATHERED, false, 1.0)

	# Left: Commander Scar Medallion
	var med_c: Vector2 = Vector2(38.0, 48.0)
	var med_col: Color = NeoSteppePalette.EMBER_RED if not _commander_alive else (NeoSteppePalette.GOLD_TAMGA if _veteran_score >= 25.0 else NeoSteppePalette.JADE_BRIGHT)
	draw_circle(med_c, 22.0, Color(0.10, 0.11, 0.13, 0.95))
	draw_arc(med_c, 22.0, 0.0, TAU, 28, med_col, 2.0, true)
	# Draw scar slashes across medallion
	var shown_scars: int = mini(_scars, 5)
	for s_i: int in range(shown_scars):
		var offset_x: float = -10.0 + float(s_i) * 5.0
		draw_line(med_c + Vector2(offset_x - 4.0, -10.0), med_c + Vector2(offset_x + 4.0, 10.0), NeoSteppePalette.EMBER_RED, 1.8, true)

	# Bottom: Dread vs Honor/Töre Sword Balance Beam
	var beam_x: float = 14.0
	var beam_w: float = w - 28.0
	var beam_y: float = h - 18.0
	var tilt: float = clampf((_honor - _dread) / 100.0, -1.0, 1.0)
	var left_y: float = beam_y + tilt * 6.0
	var right_y: float = beam_y - tilt * 6.0
	draw_line(Vector2(beam_x, left_y), Vector2(beam_x + beam_w, right_y), NeoSteppePalette.GOLD_TAMGA, 2.2, true)
	draw_circle(Vector2(beam_x + beam_w * 0.5, beam_y), 3.5, NeoSteppePalette.BRONZE_WEATHERED)
	draw_circle(Vector2(beam_x, left_y), 4.0, NeoSteppePalette.EMBER_RED)
	draw_circle(Vector2(beam_x + beam_w, right_y), 4.0, NeoSteppePalette.JADE_BRIGHT)

	var font: Font = ThemeDB.fallback_font
	if font != null:
		draw_string(font, Vector2(68.0, 18.0), "%s (%d yaş) · Gazi %.0f · Yara %d" % [_commander_name, _age_years, _veteran_score, _scars], HORIZONTAL_ALIGNMENT_LEFT, w - 76.0, 10, NeoSteppePalette.TEXT_PRIMARY)
		var heir_msg: String = "Veliaht Amanat!" if _heir_amanat else ("Veliaht Hazır" if _heir_ready else "Veliaht Yetersiz (Naip Riski)")
		var heir_col: Color = NeoSteppePalette.JADE_BRIGHT if (_heir_ready and not _heir_amanat) else NeoSteppePalette.EMBER_RED
		draw_string(font, Vector2(68.0, 36.0), heir_msg, HORIZONTAL_ALIGNMENT_LEFT, w - 76.0, 10, heir_col)
		draw_string(font, Vector2(68.0, 54.0), "Dehşet %.0f  |  Töre/Onur %.0f  |  Söz %.0f%%" % [_dread, _honor, _reliability], HORIZONTAL_ALIGNMENT_LEFT, w - 76.0, 10, NeoSteppePalette.GOLD_TAMGA)
