class_name SkyConstellationWidget
extends Control
## UI Widget (rank 3). Custom `_draw()` Gök Kubbe Sinerji Takımyıldızı rendering
## the 5 Faz 27A cross-domain resonances and their causal links.

const NODE_LABELS: Array[String] = [
	"Gölge",
	"Serap",
	"Börü",
	"Kurultay",
	"KralNet",
]

var _resonance_active: Array[bool] = [false, false, false, false, false]
var _combat_mult: float = 1.0
var _kut_drift: float = 0.0
var _courier_mult: float = 1.0
var _coalition_pressure: float = 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(280.0, 128.0)


func apply_snapshot(snap: WorldEcologyViewModel.WorldEcologySnapshot) -> void:
	if snap == null:
		return
	for i: int in range(5):
		var flag: bool = snap.resonance_active_map[i] if snap.resonance_active_map.has(i) else false
		_resonance_active[i] = flag
	_combat_mult = snap.effective_combat_power_mult
	_kut_drift = snap.kut_entropy_net_drift
	_courier_mult = snap.courier_tempo_mult
	_coalition_pressure = snap.coalition_pressure_score
	queue_redraw()


func _draw() -> void:
	var w: float = maxf(size.x, 220.0)
	var h: float = maxf(size.y, 110.0)
	var center: Vector2 = Vector2(w * 0.5, h * 0.52)

	draw_rect(Rect2(Vector2.ZERO, Vector2(w, h)), Color(0.05, 0.06, 0.08, 0.92), true)
	draw_rect(Rect2(Vector2(1.0, 1.0), Vector2(w - 2.0, h - 2.0)), NeoSteppePalette.BRONZE_WEATHERED, false, 1.0)

	var radius_x: float = w * 0.34
	var radius_y: float = h * 0.33
	var pts: Array[Vector2] = []
	for i: int in range(5):
		var angle: float = -PI * 0.5 + float(i) * (TAU / 5.0)
		pts.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))

	# Causal pentagon & inner star links
	for i: int in range(5):
		var next_i: int = (i + 1) % 5
		var star_i: int = (i + 2) % 5
		var both_ring: bool = _resonance_active[i] and _resonance_active[next_i]
		var link_col: Color = NeoSteppePalette.JADE_BRIGHT if both_ring else Color(0.32, 0.30, 0.25, 0.45)
		draw_line(pts[i], pts[next_i], link_col, 2.0 if both_ring else 1.0, true)
		var star_col: Color = NeoSteppePalette.GOLD_TAMGA if (_resonance_active[i] or _resonance_active[star_i]) else Color(0.24, 0.23, 0.20, 0.35)
		draw_line(pts[i], pts[star_i], star_col, 1.2, true)

	# Central Kut & Power nexus
	var active_count: int = 0
	for flag: bool in _resonance_active:
		if flag:
			active_count += 1
	var nexus_col: Color = NeoSteppePalette.JADE_BRIGHT if active_count >= 2 else (NeoSteppePalette.GOLD_TAMGA if active_count == 1 else NeoSteppePalette.BRONZE_DARK)
	draw_circle(center, 10.0, Color(0.08, 0.10, 0.12, 0.95))
	draw_arc(center, 10.0, 0.0, TAU, 24, nexus_col, 1.8, true)

	# 5 Resonance Star Nodes
	var font: Font = ThemeDB.fallback_font
	for i: int in range(5):
		var is_on: bool = _resonance_active[i]
		var node_col: Color = NeoSteppePalette.EMBER_RED if (i == 0 or i == 1) else NeoSteppePalette.JADE_BRIGHT
		if not is_on:
			node_col = Color(0.35, 0.36, 0.38, 0.70)
		if is_on:
			draw_circle(pts[i], 9.0, Color(node_col.r, node_col.g, node_col.b, 0.24))
		draw_circle(pts[i], 5.5, node_col)
		if font != null:
			var lbl_pos: Vector2 = pts[i] + Vector2(-18.0, -9.0 if pts[i].y <= center.y else 16.0)
			draw_string(font, lbl_pos, NODE_LABELS[i], HORIZONTAL_ALIGNMENT_LEFT, 48.0, 10, NeoSteppePalette.TEXT_PRIMARY if is_on else NeoSteppePalette.TEXT_MUTED)

	if font != null:
		var header: String = "GÖK KUBBE (%d/5) · Güç %.2fx · Drift %+.2f" % [active_count, _combat_mult, _kut_drift]
		draw_string(font, Vector2(8.0, 14.0), header, HORIZONTAL_ALIGNMENT_LEFT, w - 16.0, 11, NeoSteppePalette.GOLD_TAMGA)
