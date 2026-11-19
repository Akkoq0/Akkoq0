class_name DoctrineMatchupPreviewWidget
extends TamgaCardPanel
## Compact Tactical Drawer sub-widget (rank 4). Evaluates real-time doctrine
## matchups strictly through `DoctrineMatchupResolver.evaluate(...)` (via
## `ResearchTreeViewModel`) across enemy doctrine presets, engagement angle,
## and steppe terrain/weather conditions without modifying simulation state.


class MatchupComparisonCanvas:
	extends Control

	class MetricBarRow:
		extends RefCounted
		var label: String = ""
		var val: float = 1.0
		var max_val: float = 2.0
		var col: Color = NeoSteppePalette.GOLD_TAMGA

		func _init(p_label: String, p_val: float, p_max: float, p_col: Color) -> void:
			label = p_label
			val = p_val
			max_val = p_max
			col = p_col

	var _atk_mult: float = 1.0
	var _def_mult: float = 1.0
	var _mob_mult: float = 1.0
	var _fat_mult: float = 1.0
	var _verdict_color: Color = NeoSteppePalette.GOLD_TAMGA

	func _init() -> void:
		name = "MatchupComparisonCanvas"
		custom_minimum_size = Vector2(216.0, 56.0)
		size_flags_horizontal = Control.SIZE_EXPAND_FILL

	func apply_metrics(
			atk_m: float,
			def_m: float,
			mob_m: float,
			fat_m: float,
			verdict_col: Color) -> void:
		_atk_mult = atk_m
		_def_mult = def_m
		_mob_mult = mob_m
		_fat_mult = fat_m
		_verdict_color = verdict_col
		queue_redraw()

	func _draw() -> void:
		var w: float = maxf(size.x, custom_minimum_size.x)
		var h: float = maxf(size.y, custom_minimum_size.y)
		if w <= 12.0 or h <= 12.0:
			return
		var font: Font = get_theme_default_font()
		var rows: Array[MetricBarRow] = [
			MetricBarRow.new("Taarruz", _atk_mult, 2.0, _verdict_color),
			MetricBarRow.new("D.Savun", _def_mult, 2.0, NeoSteppePalette.ICE_BLUE),
			MetricBarRow.new("Manevra", _mob_mult / maxf(sqrt(_fat_mult), 0.75), 2.0, NeoSteppePalette.GOLD_TAMGA),
		]
		var row_h: float = h / 3.0
		var label_w: float = 54.0
		var val_w: float = 38.0
		var bar_w: float = maxf(w - label_w - val_w - 8.0, 40.0)
		for i: int in range(rows.size()):
			var row: MetricBarRow = rows[i]
			var y: float = float(i) * row_h + 2.0
			if font != null:
				draw_string(font, Vector2(2.0, y + row_h * 0.72), row.label, HORIZONTAL_ALIGNMENT_LEFT, label_w, 9, NeoSteppePalette.TEXT_SECONDARY)
				draw_string(font, Vector2(w - val_w, y + row_h * 0.72), "x%.2f" % row.val, HORIZONTAL_ALIGNMENT_RIGHT, val_w, 9, NeoSteppePalette.TEXT_PRIMARY)

			var track_rect: Rect2 = Rect2(label_w + 4.0, y + 4.0, bar_w, maxf(row_h - 8.0, 6.0))
			draw_rect(track_rect, NeoSteppePalette.CHARCOAL_SURFACE, true)
			var fill_ratio: float = clampf(row.val / row.max_val, 0.05, 1.0)
			draw_rect(Rect2(track_rect.position, Vector2(track_rect.size.x * fill_ratio, track_rect.size.y)), row.col, true)
			var ref_x: float = track_rect.position.x + track_rect.size.x * 0.5
			draw_line(Vector2(ref_x, track_rect.position.y - 1.0), Vector2(ref_x, track_rect.position.y + track_rect.size.y + 1.0), NeoSteppePalette.TEXT_MUTED, 1.0)


const PRESET_ORDER: Array[GameEnums.BattleDoctrinePresetId] = [
	GameEnums.BattleDoctrinePresetId.TOLGAMA_KISKACI,
	GameEnums.BattleDoctrinePresetId.BORU_KAMASI,
	GameEnums.BattleDoctrinePresetId.KURT_KAPANI,
	GameEnums.BattleDoctrinePresetId.ARABA_KALESI,
	GameEnums.BattleDoctrinePresetId.TONYUKUK_YIPRATMASI,
]

const ANGLE_ORDER: Array[GameEnums.CombatEngagementAngle] = [
	GameEnums.CombatEngagementAngle.FRONT,
	GameEnums.CombatEngagementAngle.FLANK,
	GameEnums.CombatEngagementAngle.REAR,
]

var _vm_ref: WeakRef = null
var _own_idx: int = 0
var _enemy_idx: int = 1
var _angle_idx: int = 0
var _is_mud: bool = false
var _is_slope: bool = false
var _is_storm: bool = false
var _built: bool = false

var _last_preview: ResearchTreeViewModel.DoctrineMatchupPreviewSnapshot = null

var _own_btn: Button = null
var _enemy_btn: Button = null
var _angle_btn: Button = null
var _mud_btn: Button = null
var _slope_btn: Button = null
var _storm_btn: Button = null

var _verdict_lbl: Label = null
var _metrics_lbl: Label = null
var _reasons_lbl: Label = null
var _canvas: MatchupComparisonCanvas = null
var _btn_callbacks: Dictionary[Button, Callable] = {}


func _init() -> void:
	name = "DoctrineMatchupPreviewWidget"
	card_id = &"doctrine_matchup_preview"
	clickable = false
	semantic_tone = &"gold"
	custom_minimum_size = Vector2(256.0, 0.0)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL


func _ready() -> void:
	_ensure_built()
	refresh_preview()


func _exit_tree() -> void:
	_disconnect_all_buttons()


func bind_view_model(vm: ResearchTreeViewModel) -> void:
	_vm_ref = weakref(vm) if vm != null else null
	sync_with_army_preset()
	refresh_preview()


func sync_with_army_preset() -> void:
	var vm: ResearchTreeViewModel = _get_vm()
	if vm == null:
		return
	var active_p: GameEnums.BattleDoctrinePresetId = vm.get_active_army_preset_id()
	var idx: int = PRESET_ORDER.find(active_p)
	if idx >= 0:
		_own_idx = idx


func set_preview_parameters(
		own_preset: GameEnums.BattleDoctrinePresetId,
		enemy_preset: GameEnums.BattleDoctrinePresetId,
		engagement_angle: GameEnums.CombatEngagementAngle = GameEnums.CombatEngagementAngle.FRONT,
		p_is_mud: bool = false,
		p_is_slope: bool = false,
		p_is_storm: bool = false) -> void:
	var o_i: int = PRESET_ORDER.find(own_preset)
	if o_i >= 0:
		_own_idx = o_i
	var e_i: int = PRESET_ORDER.find(enemy_preset)
	if e_i >= 0:
		_enemy_idx = e_i
	var a_i: int = ANGLE_ORDER.find(engagement_angle)
	if a_i >= 0:
		_angle_idx = a_i
	_is_mud = p_is_mud
	_is_slope = p_is_slope
	_is_storm = p_is_storm
	refresh_preview()


func get_last_preview() -> ResearchTreeViewModel.DoctrineMatchupPreviewSnapshot:
	return _last_preview


func get_own_button() -> Button:
	_ensure_built()
	return _own_btn


func get_enemy_button() -> Button:
	_ensure_built()
	return _enemy_btn


func get_angle_button() -> Button:
	_ensure_built()
	return _angle_btn


func get_mud_button() -> Button:
	_ensure_built()
	return _mud_btn


func get_slope_button() -> Button:
	_ensure_built()
	return _slope_btn


func get_storm_button() -> Button:
	_ensure_built()
	return _storm_btn


func refresh_preview() -> void:
	_ensure_built()
	_sync_control_labels()

	var vm: ResearchTreeViewModel = _get_vm()
	if vm == null:
		return
	var own_p: GameEnums.BattleDoctrinePresetId = PRESET_ORDER[_own_idx]
	var enemy_p: GameEnums.BattleDoctrinePresetId = PRESET_ORDER[_enemy_idx]
	var ang: GameEnums.CombatEngagementAngle = ANGLE_ORDER[_angle_idx]

	var snap: ResearchTreeViewModel.DoctrineMatchupPreviewSnapshot = vm.evaluate_doctrine_preview(
		own_p, enemy_p, ang, _is_mud, _is_slope, _is_storm)
	_last_preview = snap

	var tone_col: Color = NeoSteppePalette.get_semantic_color(snap.verdict_tone_id)
	set_semantic_tone(snap.verdict_tone_id, 0.0)
	_canvas.apply_metrics(
		snap.attacker_attack_mult,
		snap.defender_defense_mult,
		snap.attacker_mobility_mult,
		snap.attacker_fatigue_mult,
		tone_col
	)
	_verdict_lbl.text = "%s · Skor x%.2f" % [snap.verdict_label, snap.advantage_score]
	_verdict_lbl.add_theme_color_override(&"font_color", tone_col)
	_metrics_lbl.text = "Taarruz x%.2f · R.Savunma x%.2f · Hız x%.2f · Yorg. x%.2f" % [
		snap.attacker_attack_mult,
		snap.defender_defense_mult,
		snap.attacker_mobility_mult,
		snap.attacker_fatigue_mult,
	]
	var reason_lines: PackedStringArray = PackedStringArray()
	var max_reasons: int = mini(snap.highlights.size(), 3)
	for i: int in range(max_reasons):
		reason_lines.append("• %s" % snap.highlights[i])
	_reasons_lbl.text = "\n".join(reason_lines)


func _ensure_built() -> void:
	if _built:
		return
	_built = true

	var margin: MarginContainer = get_content_container()
	margin.add_theme_constant_override(&"margin_left", 8)
	margin.add_theme_constant_override(&"margin_right", 8)
	margin.add_theme_constant_override(&"margin_top", 7)
	margin.add_theme_constant_override(&"margin_bottom", 7)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.name = "MatchupPreviewVBox"
	vbox.add_theme_constant_override(&"separation", 5)
	margin.add_child(vbox)

	var hdr: Label = Label.new()
	hdr.theme_type_variation = &"CaptionLabel"
	hdr.text = "NİZAM EŞLEŞME ÖNİZLEMESİ"
	vbox.add_child(hdr)

	var select_flow: HFlowContainer = HFlowContainer.new()
	select_flow.add_theme_constant_override(&"h_separation", 4)
	select_flow.add_theme_constant_override(&"v_separation", 4)
	vbox.add_child(select_flow)

	_own_btn = _make_btn("BtnMatchupOwn", "Biz: Tolgama", NeoSteppePalette.JADE_PRIMARY, _on_own_cycle_pressed)
	select_flow.add_child(_own_btn)
	_enemy_btn = _make_btn("BtnMatchupEnemy", "Rakip: Börü", NeoSteppePalette.EMBER_RED, _on_enemy_cycle_pressed)
	select_flow.add_child(_enemy_btn)
	_angle_btn = _make_btn("BtnMatchupAngle", "Temas: Ön", NeoSteppePalette.GOLD_TAMGA, _on_angle_cycle_pressed)
	select_flow.add_child(_angle_btn)

	var env_flow: HFlowContainer = HFlowContainer.new()
	env_flow.add_theme_constant_override(&"h_separation", 4)
	env_flow.add_theme_constant_override(&"v_separation", 3)
	vbox.add_child(env_flow)

	_mud_btn = _make_btn("BtnMatchupMud", "Çamur", NeoSteppePalette.ICE_BLUE, _on_mud_toggled)
	env_flow.add_child(_mud_btn)
	_slope_btn = _make_btn("BtnMatchupSlope", "Yamaç", NeoSteppePalette.ICE_BLUE, _on_slope_toggled)
	env_flow.add_child(_slope_btn)
	_storm_btn = _make_btn("BtnMatchupStorm", "Fırtına", NeoSteppePalette.ICE_BLUE, _on_storm_toggled)
	env_flow.add_child(_storm_btn)

	_canvas = MatchupComparisonCanvas.new()
	vbox.add_child(_canvas)

	_verdict_lbl = Label.new()
	_verdict_lbl.theme_type_variation = &"CaptionLabel"
	_verdict_lbl.text = "Dengeli Çarpışma"
	vbox.add_child(_verdict_lbl)

	_metrics_lbl = Label.new()
	_metrics_lbl.theme_type_variation = &"MutedLabel"
	_metrics_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_metrics_lbl)

	_reasons_lbl = Label.new()
	_reasons_lbl.theme_type_variation = &"MutedLabel"
	_reasons_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_reasons_lbl)


func _make_btn(
		p_name: String,
		p_text: String,
		p_col: Color,
		p_cb: Callable) -> Button:
	var btn: Button = Button.new()
	btn.name = p_name
	btn.theme_type_variation = &"GhostIconButton"
	btn.text = p_text
	btn.add_theme_font_size_override(&"font_size", NeoSteppePalette.FONT_SIZE_MICRO)
	OtukenThemeFactory.apply_button_semantic_styles(btn, p_col, false, 7, 3)
	btn.pressed.connect(p_cb)
	_btn_callbacks[btn] = p_cb
	return btn


func _sync_control_labels() -> void:
	_own_btn.text = "Biz: %s" % _format_preset_short(PRESET_ORDER[_own_idx])
	_enemy_btn.text = "Rakip: %s" % _format_preset_short(PRESET_ORDER[_enemy_idx])
	_angle_btn.text = "Temas: %s" % _format_angle_short(ANGLE_ORDER[_angle_idx])
	OtukenThemeFactory.apply_button_semantic_styles(_mud_btn, NeoSteppePalette.ICE_BLUE, _is_mud, 7, 3)
	OtukenThemeFactory.apply_button_semantic_styles(_slope_btn, NeoSteppePalette.ICE_BLUE, _is_slope, 7, 3)
	OtukenThemeFactory.apply_button_semantic_styles(_storm_btn, NeoSteppePalette.EMBER_BRIGHT if _is_storm else NeoSteppePalette.ICE_BLUE, _is_storm, 7, 3)


func _on_own_cycle_pressed() -> void:
	_own_idx = (_own_idx + 1) % PRESET_ORDER.size()
	refresh_preview()


func _on_enemy_cycle_pressed() -> void:
	_enemy_idx = (_enemy_idx + 1) % PRESET_ORDER.size()
	refresh_preview()


func _on_angle_cycle_pressed() -> void:
	_angle_idx = (_angle_idx + 1) % ANGLE_ORDER.size()
	refresh_preview()


func _on_mud_toggled() -> void:
	_is_mud = not _is_mud
	refresh_preview()


func _on_slope_toggled() -> void:
	_is_slope = not _is_slope
	refresh_preview()


func _on_storm_toggled() -> void:
	_is_storm = not _is_storm
	refresh_preview()


func _get_vm() -> ResearchTreeViewModel:
	if _vm_ref == null:
		return null
	var obj: Object = _vm_ref.get_ref()
	if obj != null and is_instance_valid(obj):
		return obj as ResearchTreeViewModel
	return null


func _disconnect_all_buttons() -> void:
	for btn: Button in _btn_callbacks.keys():
		if btn != null and is_instance_valid(btn):
			var cb: Callable = _btn_callbacks[btn]
			if cb.is_valid() and btn.pressed.is_connected(cb):
				btn.pressed.disconnect(cb)
	_btn_callbacks.clear()


static func _format_preset_short(p_id: GameEnums.BattleDoctrinePresetId) -> String:
	match p_id:
		GameEnums.BattleDoctrinePresetId.TOLGAMA_KISKACI:
			return "Tolgama"
		GameEnums.BattleDoctrinePresetId.BORU_KAMASI:
			return "Börü"
		GameEnums.BattleDoctrinePresetId.KURT_KAPANI:
			return "Kurt Kapanı"
		GameEnums.BattleDoctrinePresetId.ARABA_KALESI:
			return "Araba Kalesi"
		GameEnums.BattleDoctrinePresetId.TONYUKUK_YIPRATMASI:
			return "Tonyukuk"
	return "Düzen"


static func _format_angle_short(ang: GameEnums.CombatEngagementAngle) -> String:
	match ang:
		GameEnums.CombatEngagementAngle.FRONT:
			return "Ön"
		GameEnums.CombatEngagementAngle.FLANK:
			return "Yan"
		GameEnums.CombatEngagementAngle.REAR:
			return "Arka"
	return "Ön"
