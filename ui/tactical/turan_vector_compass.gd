class_name TuranVectorCompass
extends Control
## UI Tactical Visualization (rank 4). Custom `_draw()` Neo-Steppe **Turan 360°
## Vector Compass** integrating 3 concentric rings:
##   1. Inner Ring: Vectorial facing sector exposure (`1.0x ÖN`, `1.45x YAN`, `2.1x ARKA`) + threat vector.
##   2. Middle Ring: 5-stage Turan Tactic FSM nodes & clockwise tactical progress (`0..4`).
##   3. Outer Ring: `Sadak` Quiver arc, `Yılkı` Remount arc, and `Yorgunluk` Fatigue arc with 65% & 85% rout notches.


class SectorArcSpec:
	var sector_id: StringName = &"front"
	var angle_type: GameEnums.CombatEngagementAngle = GameEnums.CombatEngagementAngle.FRONT
	var start_angle_rad: float = 0.0
	var end_angle_rad: float = 0.0
	var damage_multiplier: float = 1.0
	var label: String = "1.0x"

	func _init(p_id: StringName, p_type: GameEnums.CombatEngagementAngle, p_start: float, p_end: float, p_mult: float, p_label: String) -> void:
		sector_id = p_id
		angle_type = p_type
		start_angle_rad = p_start
		end_angle_rad = p_end
		damage_multiplier = p_mult
		label = p_label


var _snapshot: TacticalCommandViewModel.TacticalUnitSnapshot = TacticalCommandViewModel.TacticalUnitSnapshot.new()


func _init() -> void:
	name = "TuranVectorCompass"
	custom_minimum_size = Vector2(248.0, 260.0)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_PASS


func apply_snapshot(snap: TacticalCommandViewModel.TacticalUnitSnapshot) -> void:
	if snap != null:
		_snapshot = snap
	queue_redraw()


func get_snapshot() -> TacticalCommandViewModel.TacticalUnitSnapshot:
	return _snapshot


func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	if w < 24.0 or h < 24.0:
		return

	var center: Vector2 = Vector2(w * 0.5, h * 0.45)
	var r_max: float = minf(w * 0.45, h * 0.40)
	var r_inner: float = r_max * 0.46
	var r_mid: float = r_max * 0.68
	var r_outer: float = r_max * 0.90
	var draw_font: Font = _resolve_draw_font()

	# Backdrop Obsidian Disc & Subtle Tamga Frame
	draw_circle(center, r_max + 4.0, NeoSteppePalette.OBSIDIAN_DEEP)
	draw_arc(center, r_max + 4.0, 0.0, TAU, 64, NeoSteppePalette.BRONZE_DARK, 1.0, true)

	# --- Ring 1: Vectorial Sector Exposure (Front / Flanks / Rear) ------------
	var sectors: Array[SectorArcSpec] = compute_directional_sectors(_snapshot.flank_dot_threshold, null)
	for sec: SectorArcSpec in sectors:
		var sec_color: Color = _color_for_sector(sec.angle_type)
		var is_hit_sector: bool = _snapshot.threat_active and _snapshot.threat_sector == sec.angle_type
		var fill_alpha: float = 0.24 if is_hit_sector else 0.11
		_draw_annular_sector(center, r_inner * 0.28, r_inner, sec.start_angle_rad, sec.end_angle_rad, Color(sec_color.r, sec_color.g, sec_color.b, fill_alpha), 20)
		var rim_width: float = 2.5 if is_hit_sector else 1.5
		draw_arc(center, r_inner, sec.start_angle_rad, sec.end_angle_rad, 20, sec_color, rim_width, true)
		var divider_end: Vector2 = center + Vector2(cos(sec.start_angle_rad), sin(sec.start_angle_rad)) * r_inner
		draw_line(center, divider_end, NeoSteppePalette.BRONZE_WEATHERED, 1.0, true)

	# Center Forward Facing Arrowhead (Points UP = -PI/2)
	var tip: Vector2 = center + Vector2(0.0, -r_inner * 0.36)
	var wing_l: Vector2 = center + Vector2(-r_inner * 0.20, r_inner * 0.20)
	var wing_r: Vector2 = center + Vector2(r_inner * 0.20, r_inner * 0.20)
	var tail_c: Vector2 = center + Vector2(0.0, r_inner * 0.08)
	draw_colored_polygon(PackedVector2Array([tip, wing_r, tail_c, wing_l]), NeoSteppePalette.GOLD_PALE)

	# Threat Vector Indicator
	if _snapshot.threat_active:
		var t_ang: float = -PI * 0.5 + normalize_bearing_rad(_snapshot.threat_bearing_rad)
		var t_dir: Vector2 = Vector2(cos(t_ang), sin(t_ang))
		var p_outer: Vector2 = center + t_dir * (r_inner + 10.0)
		var p_inner: Vector2 = center + t_dir * (r_inner * 0.42)
		var hit_col: Color = _color_for_sector(_snapshot.threat_sector)
		draw_line(p_outer, p_inner, hit_col, 2.5, true)
		draw_circle(p_outer, 4.0, hit_col)

	# Escaped Sealed Indicator
	if _snapshot.escape_vector_sealed:
		draw_arc(center, r_inner + 5.0, PI * 0.5 - 0.75, PI * 0.5 + 0.75, 18, NeoSteppePalette.EMBER_BRIGHT, 2.5, true)

	# --- Ring 2: 5-Stage Turan FSM Track & Nodes ------------------------------
	draw_arc(center, r_mid, 0.0, TAU, 56, NeoSteppePalette.BRONZE_DARK, 2.0, true)
	var active_phase_idx: int = clampi(int(_snapshot.turan_phase), 0, 4)
	var has_fallback: bool = _snapshot.turan_fallback_reason != &"" or _snapshot.cascade_routing
	var fsm_color: Color = NeoSteppePalette.EMBER_RED if has_fallback else NeoSteppePalette.JADE_BRIGHT
	var node0_ang: float = compute_turan_phase_node_angle(0)
	var active_node_ang: float = compute_turan_phase_node_angle(active_phase_idx)
	if active_phase_idx > 0:
		draw_arc(center, r_mid, node0_ang, active_node_ang, 32, fsm_color, 3.0, true)

	for idx: int in range(5):
		var n_ang: float = compute_turan_phase_node_angle(idx)
		var n_pos: Vector2 = center + Vector2(cos(n_ang), sin(n_ang)) * r_mid
		var is_current: bool = idx == active_phase_idx
		var is_done: bool = idx < active_phase_idx
		var fill_col: Color = NeoSteppePalette.OBSIDIAN_DEEP
		var rim_col: Color = NeoSteppePalette.BRONZE_WEATHERED
		if is_current:
			fill_col = fsm_color
			rim_col = NeoSteppePalette.GOLD_PALE
			draw_circle(n_pos, 9.0, Color(fsm_color.r, fsm_color.g, fsm_color.b, 0.30))
		elif is_done:
			fill_col = NeoSteppePalette.JADE_DARK
			rim_col = NeoSteppePalette.JADE_PRIMARY
		draw_circle(n_pos, 6.0 if is_current else 4.5, fill_col)
		draw_arc(n_pos, 6.0 if is_current else 4.5, 0.0, TAU, 16, rim_col, 1.5, true)

	# --- Ring 3: Outer Sadak / Yılkı / Yorgunluk Arcs -------------------------
	# Left-Upper: Sadak (Quiver Ammo 0..100)
	var sadak_start: float = -PI * 0.5 - 0.14
	var sadak_span: float = -1.78
	var sadak_end: float = compute_gauge_arc_end(sadak_start, sadak_span, _snapshot.quiver_ammo, 100.0)
	var sadak_col: Color = NeoSteppePalette.EMBER_RED if _snapshot.quiver_ammo <= 15.0 else NeoSteppePalette.ICE_BLUE
	draw_arc(center, r_outer, sadak_start, sadak_start + sadak_span, 24, NeoSteppePalette.CHARCOAL_ELEVATED, 5.0, true)
	if absf(sadak_end - sadak_start) > 0.02:
		draw_arc(center, r_outer, sadak_start, sadak_end, 24, sadak_col, 5.0, true)

	# Right-Upper: Yılkı (Remounts 0..1)
	var yilki_start: float = -PI * 0.5 + 0.14
	var yilki_span: float = 1.78
	var yilki_end: float = compute_gauge_arc_end(yilki_start, yilki_span, _snapshot.remount_horse_ratio, 1.0)
	var yilki_col: Color = NeoSteppePalette.EMBER_RED if _snapshot.remount_horse_ratio < 0.25 else (NeoSteppePalette.GOLD_TAMGA if _snapshot.remount_horse_ratio < 0.55 else NeoSteppePalette.JADE_BRIGHT)
	draw_arc(center, r_outer, yilki_start, yilki_start + yilki_span, 24, NeoSteppePalette.CHARCOAL_ELEVATED, 5.0, true)
	if absf(yilki_end - yilki_start) > 0.02:
		draw_arc(center, r_outer, yilki_start, yilki_end, 24, yilki_col, 5.0, true)

	# Bottom: Yorgunluk (Battle Fatigue 0..100 with 65% Shock & 85% Extreme notches)
	var fat_start: float = PI * 0.5 + 0.92
	var fat_span: float = -1.84
	var fat_end: float = compute_gauge_arc_end(fat_start, fat_span, _snapshot.battle_fatigue, 100.0)
	var fat_col: Color = NeoSteppePalette.EMBER_RED if _snapshot.battle_fatigue >= 85.0 else (NeoSteppePalette.EMBER_BRIGHT if _snapshot.battle_fatigue >= 65.0 else NeoSteppePalette.GOLD_TAMGA)
	draw_arc(center, r_outer, fat_start, fat_start + fat_span, 24, NeoSteppePalette.CHARCOAL_ELEVATED, 5.5, true)
	if absf(fat_end - fat_start) > 0.02:
		draw_arc(center, r_outer, fat_start, fat_end, 24, fat_col, 5.5, true)

	for notch_pct: float in [65.0, 85.0]:
		var n_theta: float = compute_fatigue_notch_angle(fat_start, fat_span, notch_pct)
		var dir_vec: Vector2 = Vector2(cos(n_theta), sin(n_theta))
		var notch_col: Color = NeoSteppePalette.EMBER_BRIGHT if notch_pct >= 80.0 else NeoSteppePalette.GOLD_PALE
		draw_line(center + dir_vec * (r_outer - 5.0), center + dir_vec * (r_outer + 5.0), notch_col, 2.0, true)

	# --- Crisp Readout Labels -------------------------------------------------
	if draw_font != null:
		var phase_txt: String = TacticalCommandViewModel.format_turan_phase_short(_snapshot.turan_phase)
		if _snapshot.turan_fallback_reason != &"":
			phase_txt += " (!)"
		draw_string(draw_font, Vector2(8.0, h - 22.0), phase_txt, HORIZONTAL_ALIGNMENT_CENTER, w - 16.0, NeoSteppePalette.FONT_SIZE_CAPTION, NeoSteppePalette.GOLD_PALE)
		var stats_txt: String = "Sadak %%%.0f · Yılkı %%%.0f · Yorg. %%%.0f" % [
			_snapshot.quiver_ammo, _snapshot.remount_horse_ratio * 100.0, _snapshot.battle_fatigue]
		draw_string(draw_font, Vector2(8.0, h - 6.0), stats_txt, HORIZONTAL_ALIGNMENT_CENTER, w - 16.0, NeoSteppePalette.FONT_SIZE_MICRO, NeoSteppePalette.TEXT_SECONDARY)
		if _snapshot.threat_active:
			var threat_txt: String = TacticalCommandViewModel.format_sector_short(_snapshot.threat_sector)
			draw_string(draw_font, Vector2(8.0, 14.0), "TEHDİT: %s" % threat_txt, HORIZONTAL_ALIGNMENT_LEFT, w - 16.0, NeoSteppePalette.FONT_SIZE_MICRO, _color_for_sector(_snapshot.threat_sector))
		if _snapshot.is_heavy_armor:
			draw_string(draw_font, Vector2(8.0, 14.0), "Ağır Zırh x%.2f" % _snapshot.heavy_armor_fatigue_mult, HORIZONTAL_ALIGNMENT_RIGHT, w - 16.0, NeoSteppePalette.FONT_SIZE_MICRO, NeoSteppePalette.EMBER_BRIGHT)


# --- Pure Static Vector Geometry Helpers (Unit-Test Audited) ----------------

static func compute_flank_half_cone_rad(flank_dot_threshold: float = 0.35) -> float:
	var threshold: float = clampf(TacticalCommandViewModel._safe_float(flank_dot_threshold, 0.35), 0.05, 0.95)
	return acos(threshold)


static func normalize_bearing_rad(bearing_rad: float) -> float:
	var safe_b: float = TacticalCommandViewModel._safe_float(bearing_rad, 0.0)
	return wrapf(safe_b, -PI, PI)


static func compute_directional_sectors(flank_dot_threshold: float = 0.35, rules: CombatRules = null) -> Array[SectorArcSpec]:
	var half_cone: float = compute_flank_half_cone_rad(flank_dot_threshold)
	var flank_span: float = maxf(PI - 2.0 * half_cone, 0.01)
	var front_m: float = rules.front_damage_multiplier if rules != null else 1.0
	var flank_m: float = rules.flank_damage_multiplier if rules != null else 1.45
	var rear_m: float = rules.rear_damage_multiplier if rules != null else 2.10

	var s0_start: float = -PI * 0.5 - half_cone
	var s0_end: float = s0_start + 2.0 * half_cone
	var s1_end: float = s0_end + flank_span
	var s2_end: float = s1_end + 2.0 * half_cone
	var s3_end: float = s2_end + flank_span

	return [
		SectorArcSpec.new(&"front", GameEnums.CombatEngagementAngle.FRONT, s0_start, s0_end, front_m, "1.0x ÖN"),
		SectorArcSpec.new(&"right_flank", GameEnums.CombatEngagementAngle.FLANK, s0_end, s1_end, flank_m, "1.45x YAN"),
		SectorArcSpec.new(&"rear", GameEnums.CombatEngagementAngle.REAR, s1_end, s2_end, rear_m, "2.1x ARKA"),
		SectorArcSpec.new(&"left_flank", GameEnums.CombatEngagementAngle.FLANK, s2_end, s3_end, flank_m, "1.45x YAN"),
	]


static func compute_turan_phase_node_angle(phase_index: int) -> float:
	var clamped_idx: int = clampi(phase_index, 0, 4)
	return -PI * 0.5 + float(clamped_idx) * (TAU / 5.0)


static func compute_gauge_arc_end(start_rad: float, full_span_rad: float, value: float, max_value: float) -> float:
	var safe_start: float = TacticalCommandViewModel._safe_float(start_rad, 0.0)
	var safe_span: float = TacticalCommandViewModel._safe_float(full_span_rad, 0.0)
	var safe_max: float = TacticalCommandViewModel._safe_float(max_value, 1.0)
	if safe_max <= 0.0:
		return safe_start
	var safe_val: float = TacticalCommandViewModel._safe_float(value, 0.0)
	var ratio: float = clampf(safe_val / safe_max, 0.0, 1.0)
	return safe_start + safe_span * ratio


static func compute_fatigue_notch_angle(start_rad: float, span_rad: float, threshold_pct: float) -> float:
	return compute_gauge_arc_end(start_rad, span_rad, threshold_pct, 100.0)


func _draw_annular_sector(center: Vector2, r_inner: float, r_outer: float, start_ang: float, end_ang: float, color: Color, steps: int = 16) -> void:
	var n: int = maxi(steps, 4)
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in range(n + 1):
		var t: float = float(i) / float(n)
		var ang: float = lerpf(start_ang, end_ang, t)
		pts.append(center + Vector2(cos(ang), sin(ang)) * r_outer)
	for i: int in range(n, -1, -1):
		var t: float = float(i) / float(n)
		var ang: float = lerpf(start_ang, end_ang, t)
		pts.append(center + Vector2(cos(ang), sin(ang)) * r_inner)
	draw_colored_polygon(pts, color)


func _color_for_sector(angle_type: GameEnums.CombatEngagementAngle) -> Color:
	if angle_type == GameEnums.CombatEngagementAngle.REAR:
		return NeoSteppePalette.EMBER_RED
	if angle_type == GameEnums.CombatEngagementAngle.FLANK:
		return NeoSteppePalette.GOLD_TAMGA
	return NeoSteppePalette.JADE_PRIMARY


func _resolve_draw_font() -> Font:
	var f: Font = get_theme_font(&"font", &"Label")
	if f != null:
		return f
	return ThemeDB.fallback_font
