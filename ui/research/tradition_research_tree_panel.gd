class_name TraditionResearchTreePanel
extends TamgaCardPanel
## Interactive Neo-Steppe Tradition & Military Research Tree overlay (rank 4).
## Renders the 4-branch acyclic prerequisite diagram via custom `_draw()`
## connectors, active progress rings, clickable node buttons, inspector pane,
## and `CommandBus`/`CommandEnvelope` research dispatch.

signal research_started_from_ui(node_id: StringName, ok: bool, message: String)
signal research_tree_closed()


class TraditionGraphCanvas:
	extends Control

	signal node_button_activated(node_id: StringName)

	const BRANCH_ROWS: Array[GameEnums.ResearchBranch] = [
		GameEnums.ResearchBranch.STEPPE_WARFARE,
		GameEnums.ResearchBranch.LOGISTICS_AND_WATER,
		GameEnums.ResearchBranch.TORE_AND_KURULTAY,
		GameEnums.ResearchBranch.CRAFTS_AND_IRON,
	]

	var _snapshot: ResearchTreeViewModel.ResearchTreeSnapshot = null
	var _selected_node_id: StringName = &"yelme_gozculeri"
	var _node_rects: Dictionary[StringName, Rect2] = {}
	var _node_buttons: Dictionary[StringName, Button] = {}
	var _node_callbacks: Dictionary[Button, Callable] = {}
	var _resized_cb: Callable = Callable()

	func _init() -> void:
		name = "TraditionGraphCanvas"
		custom_minimum_size = Vector2(560.0, 344.0)
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		size_flags_vertical = Control.SIZE_EXPAND_FILL

	func _ready() -> void:
		_resized_cb = _layout_buttons
		if not resized.is_connected(_resized_cb):
			resized.connect(_resized_cb)

	func _exit_tree() -> void:
		disconnect_canvas_signals()

	func disconnect_canvas_signals() -> void:
		if _resized_cb.is_valid() and resized.is_connected(_resized_cb):
			resized.disconnect(_resized_cb)
		for btn: Button in _node_callbacks.keys():
			if btn != null and is_instance_valid(btn):
				var cb: Callable = _node_callbacks[btn]
				if cb.is_valid() and btn.pressed.is_connected(cb):
					btn.pressed.disconnect(cb)
		_node_callbacks.clear()
		_node_buttons.clear()

	func apply_snapshot(
			snap: ResearchTreeViewModel.ResearchTreeSnapshot,
			selected_id: StringName) -> void:
		_snapshot = snap
		_selected_node_id = selected_id
		_sync_buttons()
		_layout_buttons()
		queue_redraw()

	func get_node_button(node_id: StringName) -> Button:
		if _node_buttons.has(node_id):
			return _node_buttons[node_id]
		return null

	func get_node_rect(node_id: StringName) -> Rect2:
		if _node_rects.has(node_id):
			return _node_rects[node_id]
		return Rect2()

	func _on_node_btn_pressed(node_id: StringName) -> void:
		node_button_activated.emit(node_id)

	func _sync_buttons() -> void:
		if _snapshot == null:
			return
		for nv: ResearchTreeViewModel.ResearchNodeView in _snapshot.nodes:
			if nv == null:
				continue
			var btn: Button = null
			if _node_buttons.has(nv.node_id):
				btn = _node_buttons[nv.node_id]
			else:
				btn = Button.new()
				btn.name = "ResearchNodeBtn_%s" % String(nv.node_id)
				btn.theme_type_variation = &"GhostIconButton"
				btn.clip_text = true
				btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				btn.add_theme_font_size_override(&"font_size", NeoSteppePalette.FONT_SIZE_MICRO)
				var cb: Callable = _on_node_btn_pressed.bind(nv.node_id)
				btn.pressed.connect(cb)
				add_child(btn)
				_node_buttons[nv.node_id] = btn
				_node_callbacks[btn] = cb

			var badge: String = _format_status_badge(nv)
			btn.text = "%s\n%s · %dG" % [nv.title, badge, nv.silver_cost]
			var tone_col: Color = _status_color(nv.status)
			var is_sel: bool = nv.node_id == _selected_node_id
			OtukenThemeFactory.apply_button_semantic_styles(btn, tone_col, is_sel, 6, 4)

	func _layout_buttons() -> void:
		_node_rects.clear()
		if _snapshot == null:
			return
		var canvas_w: float = maxf(size.x, custom_minimum_size.x)
		var canvas_h: float = maxf(size.y, custom_minimum_size.y)
		var left_gutter: float = 104.0
		var usable_w: float = maxf(canvas_w - left_gutter - 14.0, 320.0)
		var col_step: float = usable_w / 3.0
		var row_h: float = canvas_h / 4.0
		var node_w: float = clampf(col_step - 28.0, 114.0, 152.0)
		var node_h: float = clampf(row_h - 18.0, 48.0, 62.0)

		for nv: ResearchTreeViewModel.ResearchNodeView in _snapshot.nodes:
			if nv == null:
				continue
			var row_idx: int = clampi(BRANCH_ROWS.find(nv.branch), 0, 3)
			var col_idx: int = clampi(nv.tier - 1, 0, 2)
			var cx: float = left_gutter + (float(col_idx) + 0.5) * col_step
			var cy: float = (float(row_idx) + 0.5) * row_h + 6.0
			var r: Rect2 = Rect2(cx - node_w * 0.5, cy - node_h * 0.5, node_w, node_h)
			_node_rects[nv.node_id] = r
			if _node_buttons.has(nv.node_id):
				var btn: Button = _node_buttons[nv.node_id]
				if btn != null:
					btn.position = r.position
					btn.size = r.size

	func _draw() -> void:
		var canvas_w: float = maxf(size.x, custom_minimum_size.x)
		var canvas_h: float = maxf(size.y, custom_minimum_size.y)
		if canvas_w <= 10.0 or canvas_h <= 10.0:
			return

		var font: Font = get_theme_default_font()
		var left_gutter: float = 104.0
		var usable_w: float = maxf(canvas_w - left_gutter - 14.0, 320.0)
		var col_step: float = usable_w / 3.0
		var row_h: float = canvas_h / 4.0

		# 1. Swimlanes for the 4 Steppe Research Branches
		for row_idx: int in range(4):
			var br: GameEnums.ResearchBranch = BRANCH_ROWS[row_idx]
			var y0: float = float(row_idx) * row_h + 4.0
			var lane_rect: Rect2 = Rect2(4.0, y0, canvas_w - 8.0, row_h - 6.0)
			var lane_bg: Color = Color(0.08, 0.095, 0.12, 0.65) if row_idx % 2 == 0 else Color(0.06, 0.072, 0.092, 0.55)
			draw_rect(lane_rect, lane_bg, true)
			draw_rect(lane_rect, NeoSteppePalette.BRONZE_DARK, false, 1.0)
			if font != null:
				draw_string(
					font,
					Vector2(10.0, y0 + row_h * 0.52),
					TraditionResearchCatalog.format_branch_name(br),
					HORIZONTAL_ALIGNMENT_LEFT,
					92.0,
					10,
					NeoSteppePalette.GOLD_PALE
				)

		# Tier Column Headers
		if font != null:
			var tier_labels: PackedStringArray = PackedStringArray(["KADEME I", "KADEME II", "KADEME III"])
			for c_idx: int in range(3):
				var hx: float = left_gutter + float(c_idx) * col_step
				draw_string(
					font,
					Vector2(hx + 8.0, 12.0),
					tier_labels[c_idx],
					HORIZONTAL_ALIGNMENT_CENTER,
					col_step - 16.0,
					9,
					NeoSteppePalette.TEXT_MUTED
				)

		if _snapshot == null:
			return

		# 2. Directed Prerequisite Arrows
		for edge: ResearchTreeViewModel.ResearchEdgeView in _snapshot.edges:
			if edge == null:
				continue
			if not _node_rects.has(edge.from_id) or not _node_rects.has(edge.to_id):
				continue
			var r_from: Rect2 = _node_rects[edge.from_id]
			var r_to: Rect2 = _node_rects[edge.to_id]
			var p_start: Vector2 = Vector2(r_from.position.x + r_from.size.x, r_from.position.y + r_from.size.y * 0.5)
			var p_end: Vector2 = Vector2(r_to.position.x, r_to.position.y + r_to.size.y * 0.5)
			if r_from.position.y < r_to.position.y and is_equal_approx(r_from.position.x, r_to.position.x):
				p_start = Vector2(r_from.position.x + r_from.size.x * 0.5, r_from.position.y + r_from.size.y)
				p_end = Vector2(r_to.position.x + r_to.size.x * 0.5, r_to.position.y)

			var line_col: Color = NeoSteppePalette.BRONZE_DARK
			var width_px: float = 1.6
			if edge.from_completed and edge.to_unlocked:
				line_col = NeoSteppePalette.JADE_PRIMARY
				width_px = 2.4
			elif edge.from_completed:
				line_col = NeoSteppePalette.GOLD_TAMGA
				width_px = 2.0

			draw_line(p_start, p_end, line_col, width_px, true)
			var dir: Vector2 = (p_end - p_start).normalized()
			if dir.length_squared() > 0.01:
				var perp: Vector2 = Vector2(-dir.y, dir.x)
				var tip: Vector2 = p_end - dir * 2.0
				var wing_a: Vector2 = tip - dir * 7.0 + perp * 4.0
				var wing_b: Vector2 = tip - dir * 7.0 - perp * 4.0
				draw_colored_polygon(PackedVector2Array([tip, wing_a, wing_b]), line_col)

		# 3. Selection Halo & Active Progress Ring
		for nv: ResearchTreeViewModel.ResearchNodeView in _snapshot.nodes:
			if nv == null or not _node_rects.has(nv.node_id):
				continue
			var nr: Rect2 = _node_rects[nv.node_id]
			if nv.node_id == _selected_node_id:
				var sel_rect: Rect2 = Rect2(nr.position - Vector2(2.5, 2.5), nr.size + Vector2(5.0, 5.0))
				draw_rect(sel_rect, NeoSteppePalette.GOLD_TAMGA, false, 1.8)
			if nv.status == GameEnums.ResearchNodeStatus.IN_PROGRESS:
				var ring_c: Vector2 = Vector2(nr.position.x + nr.size.x - 11.0, nr.position.y + 11.0)
				draw_arc(ring_c, 6.5, 0.0, TAU, 20, NeoSteppePalette.CHARCOAL_SURFACE, 2.2)
				var sweep: float = maxf(TAU * clampf(nv.progress_ratio, 0.08, 1.0), 0.35)
				draw_arc(ring_c, 6.5, -PI * 0.5, -PI * 0.5 + sweep, 20, NeoSteppePalette.ICE_BLUE, 2.4)

	static func _status_color(status: GameEnums.ResearchNodeStatus) -> Color:
		match status:
			GameEnums.ResearchNodeStatus.COMPLETED:
				return NeoSteppePalette.JADE_PRIMARY
			GameEnums.ResearchNodeStatus.IN_PROGRESS:
				return NeoSteppePalette.ICE_BLUE
			GameEnums.ResearchNodeStatus.RESEARCHABLE:
				return NeoSteppePalette.GOLD_TAMGA
		return NeoSteppePalette.BRONZE_DARK

	static func _format_status_badge(nv: ResearchTreeViewModel.ResearchNodeView) -> String:
		match nv.status:
			GameEnums.ResearchNodeStatus.COMPLETED:
				return "TAMAM"
			GameEnums.ResearchNodeStatus.IN_PROGRESS:
				return "%d/%d M" % [nv.elapsed_seasons, nv.duration_seasons]
			GameEnums.ResearchNodeStatus.RESEARCHABLE:
				return "%d Mevsim" % nv.duration_seasons
		return "KİLİTLİ"


var _vm_ref: WeakRef = null
var _selected_node_id: StringName = &"yelme_gozculeri"
var _last_snapshot: ResearchTreeViewModel.ResearchTreeSnapshot = null
var _built: bool = false

var _title_lbl: Label = null
var _summary_lbl: Label = null
var _close_btn: Button = null
var _graph_canvas: TraditionGraphCanvas = null

var _insp_title_lbl: Label = null
var _insp_meta_lbl: Label = null
var _insp_desc_lbl: Label = null
var _insp_effect_lbl: Label = null
var _insp_prereq_lbl: Label = null
var _insp_progress_lbl: Label = null
var _start_btn: Button = null
var _action_status_lbl: Label = null
var _bonuses_footer_lbl: Label = null

var _close_cb: Callable = Callable()
var _start_cb: Callable = Callable()
var _node_select_cb: Callable = Callable()


func _init() -> void:
	name = "TraditionResearchTreePanel"
	card_id = &"tradition_research_tree_panel"
	clickable = false
	semantic_tone = &"jade"
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP


func _ready() -> void:
	_ensure_built()


func _exit_tree() -> void:
	_disconnect_all_signals()


func bind_view_model(vm: ResearchTreeViewModel) -> void:
	_vm_ref = weakref(vm) if vm != null else null
	refresh_tree()


func open_tree(node_id: StringName = &"") -> void:
	_ensure_built()
	if node_id != &"" and TraditionResearchCatalog.get_node_by_id(node_id) != null:
		_selected_node_id = node_id
	visible = true
	refresh_tree()


func close_tree() -> void:
	if not visible:
		return
	visible = false
	research_tree_closed.emit()


func select_node(node_id: StringName) -> void:
	if node_id != &"" and TraditionResearchCatalog.get_node_by_id(node_id) != null:
		_selected_node_id = node_id
	refresh_tree()


func get_selected_node_id() -> StringName:
	return _selected_node_id


func get_node_count() -> int:
	if _last_snapshot == null:
		return 0
	return _last_snapshot.nodes.size()


func get_edge_count() -> int:
	if _last_snapshot == null:
		return 0
	return _last_snapshot.edges.size()


func get_node_button(node_id: StringName) -> Button:
	_ensure_built()
	return _graph_canvas.get_node_button(node_id)


func get_start_button() -> Button:
	_ensure_built()
	return _start_btn


func get_graph_canvas() -> Control:
	_ensure_built()
	return _graph_canvas


func trigger_start_selected() -> ResearchTreeViewModel.StartResearchDispatchResult:
	_ensure_built()
	var vm: ResearchTreeViewModel = _get_vm()
	if vm == null:
		var fail: ResearchTreeViewModel.StartResearchDispatchResult = ResearchTreeViewModel.StartResearchDispatchResult.new()
		fail.ok = false
		fail.message = "ViewModel bağlı değil."
		return fail
	var res: ResearchTreeViewModel.StartResearchDispatchResult = vm.dispatch_start_research(_selected_node_id)
	_action_status_lbl.text = res.message
	_action_status_lbl.add_theme_color_override(
		&"font_color",
		NeoSteppePalette.JADE_BRIGHT if res.ok else NeoSteppePalette.EMBER_BRIGHT
	)
	research_started_from_ui.emit(_selected_node_id, res.ok, res.message)
	refresh_tree()
	return res


func refresh_tree() -> void:
	_ensure_built()
	var vm: ResearchTreeViewModel = _get_vm()
	if vm == null:
		return
	var snap: ResearchTreeViewModel.ResearchTreeSnapshot = vm.capture_tree_snapshot()
	_last_snapshot = snap

	if snap.active_node_id != &"":
		_summary_lbl.text = "Tamamlanan: %d/%d · Hazine: %d Gümüş · Aktif: %s (%d/%d Mevsim)" % [
			snap.completed_count,
			snap.total_count,
			snap.silver_stock,
			snap.active_title,
			snap.active_elapsed_seasons,
			snap.active_total_seasons,
		]
	else:
		_summary_lbl.text = "Tamamlanan: %d/%d · Hazine: %d Gümüş · Aktif araştırma yok" % [
			snap.completed_count,
			snap.total_count,
			snap.silver_stock,
		]

	_graph_canvas.apply_snapshot(snap, _selected_node_id)
	_sync_inspector(snap)
	_sync_bonuses_footer(snap.bonuses)


func _sync_inspector(snap: ResearchTreeViewModel.ResearchTreeSnapshot) -> void:
	var sel: ResearchTreeViewModel.ResearchNodeView = null
	for nv: ResearchTreeViewModel.ResearchNodeView in snap.nodes:
		if nv != null and nv.node_id == _selected_node_id:
			sel = nv
			break
	if sel == null and not snap.nodes.is_empty():
		sel = snap.nodes[0]
		_selected_node_id = sel.node_id
	if sel == null:
		return

	_insp_title_lbl.text = sel.title
	_insp_meta_lbl.text = "%s · Kademe %d · Maliyet: %d Gümüş · Süre: %d Mevsim" % [
		sel.branch_label,
		sel.tier,
		sel.silver_cost,
		sel.duration_seasons,
	]
	_insp_desc_lbl.text = sel.description
	_insp_effect_lbl.text = "Kazanç: %s" % sel.effect_summary

	if sel.prerequisites.is_empty():
		_insp_prereq_lbl.text = "Ön Koşul: Yok (Kök Gelenek)"
		_insp_prereq_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.JADE_BRIGHT)
	elif sel.missing_prereq_titles.is_empty():
		_insp_prereq_lbl.text = "Ön Koşul: Tamamlandı (%s)" % ", ".join(sel.prerequisites)
		_insp_prereq_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.JADE_BRIGHT)
	else:
		_insp_prereq_lbl.text = "Eksik Ön Koşul: %s" % ", ".join(sel.missing_prereq_titles)
		_insp_prereq_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.EMBER_BRIGHT)

	match sel.status:
		GameEnums.ResearchNodeStatus.COMPLETED:
			_insp_progress_lbl.text = "Durum: TAMAMLANDI (%d/%d Mevsim)" % [sel.duration_seasons, sel.duration_seasons]
			_insp_progress_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.JADE_PRIMARY)
			_start_btn.text = "Tamamlandı"
			_start_btn.disabled = true
			OtukenThemeFactory.apply_button_semantic_styles(_start_btn, NeoSteppePalette.JADE_PRIMARY, true, 10, 6)
		GameEnums.ResearchNodeStatus.IN_PROGRESS:
			_insp_progress_lbl.text = "Durum: ARAŞTIRILIYOR (%d/%d Mevsim · %%%.0f)" % [
				sel.elapsed_seasons,
				sel.duration_seasons,
				sel.progress_ratio * 100.0,
			]
			_insp_progress_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.ICE_FROST)
			_start_btn.text = "Devam Ediyor (%d/%d)" % [sel.elapsed_seasons, sel.duration_seasons]
			_start_btn.disabled = true
			OtukenThemeFactory.apply_button_semantic_styles(_start_btn, NeoSteppePalette.ICE_BLUE, true, 10, 6)
		GameEnums.ResearchNodeStatus.RESEARCHABLE:
			if snap.active_node_id != &"":
				_insp_progress_lbl.text = "Durum: Başka araştırma (%s) sürerken kilitli" % snap.active_title
				_insp_progress_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.GOLD_PALE)
				_start_btn.text = "Sırada Bekliyor"
				_start_btn.disabled = true
				OtukenThemeFactory.apply_button_semantic_styles(_start_btn, NeoSteppePalette.BRONZE_DARK, false, 10, 6)
			elif not sel.can_afford:
				_insp_progress_lbl.text = "Durum: Yetersiz Gümüş (%d / %d)" % [snap.silver_stock, sel.silver_cost]
				_insp_progress_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.EMBER_BRIGHT)
				_start_btn.text = "Gümüş Yetersiz (%dG)" % sel.silver_cost
				_start_btn.disabled = true
				OtukenThemeFactory.apply_button_semantic_styles(_start_btn, NeoSteppePalette.EMBER_RED, false, 10, 6)
			else:
				_insp_progress_lbl.text = "Durum: Araştırmaya Hazır (%d Gümüş)" % sel.silver_cost
				_insp_progress_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.GOLD_PALE)
				_start_btn.text = "Araştırmayı Başlat (%dG)" % sel.silver_cost
				_start_btn.disabled = false
				OtukenThemeFactory.apply_button_semantic_styles(_start_btn, NeoSteppePalette.JADE_PRIMARY, true, 10, 6)
		GameEnums.ResearchNodeStatus.LOCKED:
			_insp_progress_lbl.text = "Durum: KİLİTLİ (Önce önceki kademeyi tamamla)"
			_insp_progress_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.TEXT_MUTED)
			_start_btn.text = "Ön Koşul Gerekli"
			_start_btn.disabled = true
			OtukenThemeFactory.apply_button_semantic_styles(_start_btn, NeoSteppePalette.BRONZE_DARK, false, 10, 6)


func _sync_bonuses_footer(b: TraditionResearchManager.ResearchBonusesSnapshot) -> void:
	if b == null or b.completed_count <= 0:
		_bonuses_footer_lbl.text = "Toplam Gelenek Kazanımı: Henüz tamamlanan araştırma yok."
		return
	_bonuses_footer_lbl.text = "Kazanımlar (+%d): Saldırı +%%%d · Savunma +%%%d · Hız +%%%d · Su +%%%d · Ulak +%%%d · Vergi +%%%d · Kut +%d · Çelik +%%%d" % [
		b.completed_count,
		roundi(b.melee_attack_bonus * 100.0),
		roundi(b.defense_bonus * 100.0),
		roundi(b.speed_bonus * 100.0),
		roundi(b.water_resilience_bonus * 100.0),
		roundi(b.courier_speed_bonus * 100.0),
		roundi(b.tax_efficiency_bonus * 100.0),
		roundi(b.kut_stability_bonus),
		roundi(b.steel_craft_bonus * 100.0),
	]


func _ensure_built() -> void:
	if _built:
		return
	_built = true

	var margin: MarginContainer = get_content_container()
	margin.add_theme_constant_override(&"margin_left", 12)
	margin.add_theme_constant_override(&"margin_right", 12)
	margin.add_theme_constant_override(&"margin_top", 10)
	margin.add_theme_constant_override(&"margin_bottom", 10)

	var root_v: VBoxContainer = VBoxContainer.new()
	root_v.name = "ResearchTreeRootVBox"
	root_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_v.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_v.add_theme_constant_override(&"separation", 8)
	margin.add_child(root_v)

	# Header
	var hdr: HBoxContainer = HBoxContainer.new()
	hdr.add_theme_constant_override(&"separation", 8)
	root_v.add_child(hdr)

	_title_lbl = Label.new()
	_title_lbl.theme_type_variation = &"TitleLabel"
	_title_lbl.text = "TÖRE & GELENEK ARAŞTIRMA AĞACI"
	_title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr.add_child(_title_lbl)

	_summary_lbl = Label.new()
	_summary_lbl.theme_type_variation = &"CaptionLabel"
	_summary_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.GOLD_PALE)
	hdr.add_child(_summary_lbl)

	_close_btn = Button.new()
	_close_btn.name = "CloseResearchTreeBtn"
	_close_btn.theme_type_variation = &"GhostIconButton"
	_close_btn.text = "✕"
	OtukenThemeFactory.apply_button_semantic_styles(_close_btn, NeoSteppePalette.BRONZE_WEATHERED, false, 7, 2)
	_close_cb = close_tree
	_close_btn.pressed.connect(_close_cb)
	hdr.add_child(_close_btn)

	# Body Split: Graph Canvas (left) + Node Inspector (right)
	var split_h: HBoxContainer = HBoxContainer.new()
	split_h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split_h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split_h.add_theme_constant_override(&"separation", 10)
	root_v.add_child(split_h)

	_graph_canvas = TraditionGraphCanvas.new()
	_node_select_cb = select_node
	_graph_canvas.node_button_activated.connect(_node_select_cb)
	split_h.add_child(_graph_canvas)

	var insp_box: PanelContainer = PanelContainer.new()
	insp_box.custom_minimum_size = Vector2(236.0, 0.0)
	insp_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	insp_box.add_theme_stylebox_override(
		&"panel",
		OtukenThemeFactory.build_card_style(NeoSteppePalette.BRONZE_DARK, 1, NeoSteppePalette.CHARCOAL_SURFACE, 10, 10)
	)
	split_h.add_child(insp_box)

	var insp_v: VBoxContainer = VBoxContainer.new()
	insp_v.add_theme_constant_override(&"separation", 6)
	insp_v.size_flags_vertical = Control.SIZE_EXPAND_FILL
	insp_box.add_child(insp_v)

	_insp_title_lbl = Label.new()
	_insp_title_lbl.theme_type_variation = &"TitleLabel"
	_insp_title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	insp_v.add_child(_insp_title_lbl)

	_insp_meta_lbl = Label.new()
	_insp_meta_lbl.theme_type_variation = &"CaptionLabel"
	_insp_meta_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_insp_meta_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.GOLD_PALE)
	insp_v.add_child(_insp_meta_lbl)

	_insp_desc_lbl = Label.new()
	_insp_desc_lbl.theme_type_variation = &"BodyLabel"
	_insp_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_insp_desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	insp_v.add_child(_insp_desc_lbl)

	_insp_effect_lbl = Label.new()
	_insp_effect_lbl.theme_type_variation = &"CaptionLabel"
	_insp_effect_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_insp_effect_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.JADE_BRIGHT)
	insp_v.add_child(_insp_effect_lbl)

	_insp_prereq_lbl = Label.new()
	_insp_prereq_lbl.theme_type_variation = &"CaptionLabel"
	_insp_prereq_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	insp_v.add_child(_insp_prereq_lbl)

	_insp_progress_lbl = Label.new()
	_insp_progress_lbl.theme_type_variation = &"CaptionLabel"
	_insp_progress_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	insp_v.add_child(_insp_progress_lbl)

	_start_btn = Button.new()
	_start_btn.name = "StartResearchBtn"
	_start_btn.theme_type_variation = &"PrimaryCommandButton"
	_start_btn.text = "Araştırmayı Başlat"
	_start_cb = _on_start_btn_pressed
	_start_btn.pressed.connect(_start_cb)
	insp_v.add_child(_start_btn)

	_action_status_lbl = Label.new()
	_action_status_lbl.theme_type_variation = &"MutedLabel"
	_action_status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_action_status_lbl.text = ""
	insp_v.add_child(_action_status_lbl)

	# Footer
	_bonuses_footer_lbl = Label.new()
	_bonuses_footer_lbl.theme_type_variation = &"MutedLabel"
	_bonuses_footer_lbl.clip_text = true
	root_v.add_child(_bonuses_footer_lbl)


func _on_start_btn_pressed() -> void:
	trigger_start_selected()


func _get_vm() -> ResearchTreeViewModel:
	if _vm_ref == null:
		return null
	var obj: Object = _vm_ref.get_ref()
	if obj != null and is_instance_valid(obj):
		return obj as ResearchTreeViewModel
	return null


func _disconnect_all_signals() -> void:
	if _close_btn != null and is_instance_valid(_close_btn) and _close_cb.is_valid() and _close_btn.pressed.is_connected(_close_cb):
		_close_btn.pressed.disconnect(_close_cb)
	if _start_btn != null and is_instance_valid(_start_btn) and _start_cb.is_valid() and _start_btn.pressed.is_connected(_start_cb):
		_start_btn.pressed.disconnect(_start_cb)
	if _graph_canvas != null and is_instance_valid(_graph_canvas):
		if _node_select_cb.is_valid() and _graph_canvas.node_button_activated.is_connected(_node_select_cb):
			_graph_canvas.node_button_activated.disconnect(_node_select_cb)
		_graph_canvas.disconnect_canvas_signals()
