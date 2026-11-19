class_name KurultaiCouncilRing
extends Control
## UI Widget (rank 3). Custom `_draw()` Kurultai Council Ring with central Otağ,
## vassal Ülüş loyalty nodes, and +12–36h silent sabotage risk indicators.

var _vassals: Array[SovereigntyViewModel.VassalCouncilEntry] = []
var _direct_regions: int = 0
var _direct_cap: int = 4
var _sabotage_count: int = 0
var _max_delay_hours: float = 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(280.0, 124.0)


func apply_snapshot(snap: SovereigntyViewModel.SovereigntySnapshot) -> void:
	if snap == null:
		return
	_vassals = snap.vassals.duplicate()
	_direct_regions = snap.direct_regions
	_direct_cap = snap.direct_cap
	_sabotage_count = snap.silent_sabotage_count
	_max_delay_hours = snap.max_delay_hours
	queue_redraw()


func _draw() -> void:
	var w: float = maxf(size.x, 220.0)
	var h: float = maxf(size.y, 110.0)
	var center: Vector2 = Vector2(w * 0.5, h * 0.56)
	var ring_r: float = minf(w, h) * 0.32

	draw_rect(Rect2(Vector2.ZERO, Vector2(w, h)), Color(0.05, 0.06, 0.08, 0.92), true)
	draw_rect(Rect2(Vector2(1.0, 1.0), Vector2(w - 2.0, h - 2.0)), NeoSteppePalette.BRONZE_WEATHERED, false, 1.0)

	# Outer council ring
	draw_arc(center, ring_r, 0.0, TAU, 36, NeoSteppePalette.BRONZE_DARK, 1.5, true)
	# Central Otağ (Khagan's tent)
	var otag_col: Color = NeoSteppePalette.EMBER_RED if _direct_regions > _direct_cap else NeoSteppePalette.GOLD_TAMGA
	draw_circle(center, 11.0, Color(0.09, 0.10, 0.12, 0.95))
	draw_arc(center, 11.0, 0.0, TAU, 20, otag_col, 2.0, true)

	var font: Font = ThemeDB.fallback_font
	var count: int = _vassals.size()
	for i: int in range(count):
		var v: SovereigntyViewModel.VassalCouncilEntry = _vassals[i]
		var angle: float = -PI * 0.5 + float(i) * (TAU / float(maxi(count, 1)))
		var pos: Vector2 = center + Vector2(cos(angle), sin(angle)) * ring_r
		var node_col: Color = NeoSteppePalette.EMBER_RED if v.silent_sabotage_active else (NeoSteppePalette.JADE_BRIGHT if v.loyalty >= 65.0 else NeoSteppePalette.GOLD_TAMGA)
		draw_line(center, pos, Color(node_col.r, node_col.g, node_col.b, 0.45), 1.5, true)
		draw_circle(pos, 6.5, node_col)
		if v.silent_sabotage_active:
			draw_arc(pos, 10.0, 0.0, TAU, 16, NeoSteppePalette.EMBER_RED, 1.5, true)

	if font != null:
		var header: String = "KURULTAY HALKASI · Doğrudan %d/%d · Boy %d" % [_direct_regions, _direct_cap, count]
		draw_string(font, Vector2(8.0, 14.0), header, HORIZONTAL_ALIGNMENT_LEFT, w - 16.0, 11, otag_col)
		var sub: String = "Sessiz Sabotaj: %d (+%.0fh gecikme)" % [_sabotage_count, _max_delay_hours] if _sabotage_count > 0 else "Boylar Sadık (0 sabotaj)"
		draw_string(font, Vector2(8.0, h - 7.0), sub, HORIZONTAL_ALIGNMENT_LEFT, w - 16.0, 10, NeoSteppePalette.EMBER_RED if _sabotage_count > 0 else NeoSteppePalette.JADE_BRIGHT)
