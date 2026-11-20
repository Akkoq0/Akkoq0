class_name MobileRtsHud
extends Control
## Clean Mobile RTS HUD (rank 4).
## - Single-row Top Resource Bar (Erzak, Gümüş, Çelik, Taş, Ordu + live delta)
## - Top-Right Interactive Minimap (terrain, buildings, armies, camera box; tap to jump)
## - Top utility buttons (Ayarlar, Menü, Detay) + optional Live FPS counter
## - Bottom thumb-friendly (>=56px) contextual Build & Command Bar
## - Victory / Defeat summary overlay

signal build_requested(building_id: StringName)
signal build_cancelled()
signal train_unit_requested(unit_id: StringName)
signal army_order_requested(order_id: StringName)
signal minimap_jump_requested(world_pos: Vector3)
signal settings_requested()
signal menu_requested()
signal details_toggled()
signal return_to_main_menu_requested()
signal replay_requested()


class MinimapDot:
	extends RefCounted
	var pos: Vector3 = Vector3.ZERO
	var owner_id: int = 1
	var is_hq: bool = false

	func _init(p_pos: Vector3, p_owner: int, p_hq: bool = false) -> void:
		pos = p_pos
		owner_id = p_owner
		is_hq = p_hq


class MinimapCanvas:
	extends Control

	signal world_clicked(world_pos: Vector3)

	var map_half_extent: float = 64.0
	var terrain_grid: PackedColorArray = PackedColorArray()
	var terrain_cols: int = 0
	var terrain_rows: int = 0
	var building_dots: Array[MinimapDot] = []
	var army_dots: Array[MinimapDot] = []
	var camera_pos: Vector3 = Vector3.ZERO
	var _dragging: bool = false

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _gui_input(event: InputEvent) -> void:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb != null and mb.button_index == MOUSE_BUTTON_LEFT:
			_dragging = mb.pressed
			if mb.pressed:
				_emit_world_from_local(mb.position)
				accept_event()
		elif event is InputEventMouseMotion and _dragging:
			var mm: InputEventMouseMotion = event as InputEventMouseMotion
			_emit_world_from_local(mm.position)
			accept_event()

	func _emit_world_from_local(local_pos: Vector2) -> void:
		if size.x <= 1.0 or size.y <= 1.0:
			return
		var nx: float = clampf(local_pos.x / size.x, 0.0, 1.0)
		var nz: float = clampf(local_pos.y / size.y, 0.0, 1.0)
		var wx: float = (nx * 2.0 - 1.0) * map_half_extent
		var wz: float = (nz * 2.0 - 1.0) * map_half_extent
		world_clicked.emit(Vector3(wx, 0.0, wz))

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.10, 0.09, 1.0))
		if terrain_cols > 0 and terrain_rows > 0 and terrain_grid.size() == terrain_cols * terrain_rows:
			var cw: float = size.x / float(terrain_cols)
			var ch: float = size.y / float(terrain_rows)
			for rz: int in range(terrain_rows):
				for rx: int in range(terrain_cols):
					var c: Color = terrain_grid[rz * terrain_cols + rx]
					draw_rect(Rect2(float(rx) * cw, float(rz) * ch, cw + 0.5, ch + 0.5), c)

		for b: MinimapDot in building_dots:
			var sp: Vector2 = _world_to_minimap(b.pos)
			var col: Color = Color(0.28, 0.65, 0.98, 1.0) if b.owner_id == 1 else Color(0.92, 0.25, 0.22, 1.0)
			var half_sz: float = 4.5 if b.is_hq else 3.0
			draw_rect(Rect2(sp - Vector2(half_sz, half_sz), Vector2(half_sz * 2.0, half_sz * 2.0)), col)
			draw_rect(Rect2(sp - Vector2(half_sz, half_sz), Vector2(half_sz * 2.0, half_sz * 2.0)), Color(0.96, 0.85, 0.45, 0.9), false, 1.0)

		for a: MinimapDot in army_dots:
			var asp: Vector2 = _world_to_minimap(a.pos)
			var acol: Color = Color(0.96, 0.84, 0.35, 1.0) if a.owner_id == 1 else Color(1.0, 0.32, 0.28, 1.0)
			draw_circle(asp, 3.2, acol)

		var cam_sp: Vector2 = _world_to_minimap(camera_pos)
		var box_sz: Vector2 = Vector2(26.0, 18.0)
		draw_rect(Rect2(cam_sp - box_sz * 0.5, box_sz), Color(1.0, 0.94, 0.72, 0.95), false, 1.5)
		draw_rect(Rect2(Vector2.ZERO, size), NeoSteppePalette.GOLD_TAMGA, false, 1.5)

	func _world_to_minimap(wp: Vector3) -> Vector2:
		var ext: float = maxf(map_half_extent, 1.0)
		var nx: float = clampf((wp.x / ext + 1.0) * 0.5, 0.0, 1.0)
		var nz: float = clampf((wp.z / ext + 1.0) * 0.5, 0.0, 1.0)
		return Vector2(nx * size.x, nz * size.y)


var _built: bool = false
var _top_bar: TamgaCardPanel = null
var _res_labels: Dictionary[StringName, Label] = {}
var _fps_label: Label = null
var _settings_btn: Button = null
var _menu_btn: Button = null
var _details_btn: Button = null

var _minimap_card: TamgaCardPanel = null
var _minimap: MinimapCanvas = null

var _bottom_card: TamgaCardPanel = null
var _bottom_hbox: HBoxContainer = null
var _context_title_lbl: Label = null
var _action_buttons_box: HBoxContainer = null

var _end_screen: TamgaCardPanel = null
var _end_title_lbl: Label = null
var _end_stats_lbl: Label = null

var _show_fps: bool = false
var _fps_accum: float = 0.0
var _context_mode: StringName = &"build"
var _selected_label: String = ""
var _selected_building_is_prod: bool = false
var _placing_building_name: String = ""


func _init() -> void:
	name = "MobileRtsHud"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	_ensure_built()
	var cfg: GraphicsQualityApplier.GraphicsConfigData = GraphicsQualityApplier.load_graphics_settings()
	_show_fps = cfg.show_fps_counter
	_fps_label.visible = _show_fps
	if EventBus != null and not EventBus.graphics_settings_updated.is_connected(_on_graphics_updated):
		EventBus.graphics_settings_updated.connect(_on_graphics_updated)


func _exit_tree() -> void:
	if EventBus != null and EventBus.graphics_settings_updated.is_connected(_on_graphics_updated):
		EventBus.graphics_settings_updated.disconnect(_on_graphics_updated)


func _process(delta: float) -> void:
	if _show_fps and _fps_label != null:
		_fps_accum += delta
		if _fps_accum >= 0.35:
			_fps_accum = 0.0
			_fps_label.text = "FPS: %d" % Engine.get_frames_per_second()


func update_resources(
		food_val: int, food_rate: int,
		silver_val: int, silver_rate: int,
		steel_val: int, steel_rate: int,
		stone_val: int, stone_rate: int,
		army_cnt: int, pop_cap: int) -> void:
	_ensure_built()
	_set_res_text(&"food", "Erzak: %d (%s)" % [food_val, _fmt_rate(food_rate)])
	_set_res_text(&"silver", "Gümüş: %d (%s)" % [silver_val, _fmt_rate(silver_rate)])
	_set_res_text(&"steel", "Çelik: %d (%s)" % [steel_val, _fmt_rate(steel_rate)])
	_set_res_text(&"stone", "Taş: %d (%s)" % [stone_val, _fmt_rate(stone_rate)])
	_set_res_text(&"pop", "Ordu: %d/%d" % [army_cnt, pop_cap])


func set_minimap_terrain(cols: int, rows: int, colors: PackedColorArray, half_extent: float) -> void:
	_ensure_built()
	_minimap.terrain_cols = cols
	_minimap.terrain_rows = rows
	_minimap.terrain_grid = colors
	_minimap.map_half_extent = half_extent
	_minimap.queue_redraw()


func update_minimap_entities(buildings: Array[MinimapDot], armies: Array[MinimapDot], cam_world_pos: Vector3) -> void:
	_ensure_built()
	_minimap.building_dots = buildings
	_minimap.army_dots = armies
	_minimap.camera_pos = cam_world_pos
	_minimap.queue_redraw()


func set_context_build() -> void:
	_ensure_built()
	_context_mode = &"build"
	_rebuild_bottom_actions()


func set_context_placing(building_title: String) -> void:
	_ensure_built()
	_context_mode = &"placing"
	_placing_building_name = building_title
	_rebuild_bottom_actions()


func set_context_building(title_txt: String, can_train: bool) -> void:
	_ensure_built()
	_context_mode = &"building"
	_selected_label = title_txt
	_selected_building_is_prod = can_train
	_rebuild_bottom_actions()


func set_context_army(title_txt: String) -> void:
	_ensure_built()
	_context_mode = &"army"
	_selected_label = title_txt
	_rebuild_bottom_actions()


func show_match_outcome(is_victory: bool, stats_text: String) -> void:
	_ensure_built()
	_end_title_lbl.text = "ZAFER — ÖTÜKEN SENİNDİR!" if is_victory else "YENİLGİ — OTAĞ DÜŞTÜ"
	_end_title_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.GOLD_TAMGA if is_victory else NeoSteppePalette.EMBER_RED)
	_end_stats_lbl.text = stats_text
	_end_screen.visible = true


func collect_visible_buttons() -> Array[Button]:
	var out: Array[Button] = []
	_gather_visible_buttons(self, out)
	return out


func _gather_visible_buttons(node: Node, out: Array[Button]) -> void:
	if node.is_queued_for_deletion():
		return
	if node is Control and not (node as Control).visible:
		return
	if node is Button:
		out.append(node as Button)
	for ch: Node in node.get_children():
		_gather_visible_buttons(ch, out)


func _ensure_built() -> void:
	if _built:
		return
	_built = true

	_top_bar = TamgaCardPanel.new()
	_top_bar.name = "TopResourceBar"
	_top_bar.semantic_tone = &"gold"
	_top_bar.clickable = false
	_top_bar.anchor_left = 0.0
	_top_bar.anchor_top = 0.0
	_top_bar.anchor_right = 1.0
	_top_bar.anchor_bottom = 0.0
	_top_bar.offset_left = 10.0
	_top_bar.offset_top = 8.0
	_top_bar.offset_right = -172.0
	_top_bar.offset_bottom = 56.0
	add_child(_top_bar)

	var top_m: MarginContainer = _top_bar.get_content_container()
	top_m.add_theme_constant_override(&"margin_left", 10)
	top_m.add_theme_constant_override(&"margin_right", 8)
	top_m.add_theme_constant_override(&"margin_top", 4)
	top_m.add_theme_constant_override(&"margin_bottom", 4)

	var top_h: HBoxContainer = HBoxContainer.new()
	top_h.add_theme_constant_override(&"separation", 10)
	top_m.add_child(top_h)

	_add_res_label(top_h, &"food", "Erzak: 300 (+0)", NeoSteppePalette.JADE_BRIGHT)
	_add_res_label(top_h, &"silver", "Gümüş: 250 (+0)", NeoSteppePalette.GOLD_TAMGA)
	_add_res_label(top_h, &"steel", "Çelik: 140 (+0)", NeoSteppePalette.ICE_FROST)
	_add_res_label(top_h, &"stone", "Taş: 350 (+0)", NeoSteppePalette.TEXT_PRIMARY)
	_add_res_label(top_h, &"pop", "Ordu: 1/12", NeoSteppePalette.GOLD_PALE)

	_fps_label = Label.new()
	_fps_label.name = "LiveFpsLabel"
	_fps_label.text = "FPS: 60"
	_fps_label.visible = false
	_fps_label.add_theme_font_size_override(&"font_size", 12)
	_fps_label.add_theme_color_override(&"font_color", NeoSteppePalette.JADE_BRIGHT)
	top_h.add_child(_fps_label)

	_settings_btn = _make_top_btn("Ayarlar", NeoSteppePalette.ICE_BLUE, func() -> void: settings_requested.emit())
	top_h.add_child(_settings_btn)
	_details_btn = _make_top_btn("Detay", NeoSteppePalette.BRONZE_WEATHERED, func() -> void: details_toggled.emit())
	top_h.add_child(_details_btn)
	_menu_btn = _make_top_btn("Menü", NeoSteppePalette.GOLD_TAMGA, func() -> void: menu_requested.emit())
	top_h.add_child(_menu_btn)

	_minimap_card = TamgaCardPanel.new()
	_minimap_card.name = "MinimapCard"
	_minimap_card.semantic_tone = &"gold"
	_minimap_card.clickable = false
	_minimap_card.anchor_left = 1.0
	_minimap_card.anchor_top = 0.0
	_minimap_card.anchor_right = 1.0
	_minimap_card.anchor_bottom = 0.0
	_minimap_card.offset_left = -162.0
	_minimap_card.offset_top = 8.0
	_minimap_card.offset_right = -10.0
	_minimap_card.offset_bottom = 160.0
	add_child(_minimap_card)

	var mm_m: MarginContainer = _minimap_card.get_content_container()
	mm_m.add_theme_constant_override(&"margin_left", 4)
	mm_m.add_theme_constant_override(&"margin_right", 4)
	mm_m.add_theme_constant_override(&"margin_top", 4)
	mm_m.add_theme_constant_override(&"margin_bottom", 4)

	_minimap = MinimapCanvas.new()
	_minimap.name = "InteractiveMinimap"
	_minimap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_minimap.world_clicked.connect(func(wp: Vector3) -> void: minimap_jump_requested.emit(wp))
	mm_m.add_child(_minimap)

	_bottom_card = TamgaCardPanel.new()
	_bottom_card.name = "BottomCommandBar"
	_bottom_card.semantic_tone = &"gold"
	_bottom_card.clickable = false
	_bottom_card.anchor_left = 0.5
	_bottom_card.anchor_top = 1.0
	_bottom_card.anchor_right = 0.5
	_bottom_card.anchor_bottom = 1.0
	_bottom_card.offset_left = -480.0
	_bottom_card.offset_top = -80.0
	_bottom_card.offset_right = 480.0
	_bottom_card.offset_bottom = -8.0
	add_child(_bottom_card)

	var bot_m: MarginContainer = _bottom_card.get_content_container()
	bot_m.add_theme_constant_override(&"margin_left", 10)
	bot_m.add_theme_constant_override(&"margin_right", 10)
	bot_m.add_theme_constant_override(&"margin_top", 6)
	bot_m.add_theme_constant_override(&"margin_bottom", 6)

	_bottom_hbox = HBoxContainer.new()
	_bottom_hbox.add_theme_constant_override(&"separation", 10)
	bot_m.add_child(_bottom_hbox)

	_context_title_lbl = Label.new()
	_context_title_lbl.custom_minimum_size = Vector2(150.0, 0.0)
	_context_title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_context_title_lbl.add_theme_font_size_override(&"font_size", 13)
	_context_title_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.GOLD_PALE)
	_bottom_hbox.add_child(_context_title_lbl)

	_action_buttons_box = HBoxContainer.new()
	_action_buttons_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_action_buttons_box.add_theme_constant_override(&"separation", 8)
	_bottom_hbox.add_child(_action_buttons_box)

	_end_screen = TamgaCardPanel.new()
	_end_screen.name = "MatchOutcomeCard"
	_end_screen.semantic_tone = &"gold"
	_end_screen.clickable = false
	_end_screen.visible = false
	_end_screen.anchor_left = 0.5
	_end_screen.anchor_top = 0.5
	_end_screen.anchor_right = 0.5
	_end_screen.anchor_bottom = 0.5
	_end_screen.offset_left = -260.0
	_end_screen.offset_top = -170.0
	_end_screen.offset_right = 260.0
	_end_screen.offset_bottom = 170.0
	add_child(_end_screen)

	var end_m: MarginContainer = _end_screen.get_content_container()
	end_m.add_theme_constant_override(&"margin_left", 22)
	end_m.add_theme_constant_override(&"margin_right", 22)
	end_m.add_theme_constant_override(&"margin_top", 20)
	end_m.add_theme_constant_override(&"margin_bottom", 20)

	var end_v: VBoxContainer = VBoxContainer.new()
	end_v.add_theme_constant_override(&"separation", 12)
	end_m.add_child(end_v)

	_end_title_lbl = Label.new()
	_end_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end_title_lbl.add_theme_font_size_override(&"font_size", 24)
	end_v.add_child(_end_title_lbl)

	_end_stats_lbl = Label.new()
	_end_stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end_stats_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_end_stats_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	end_v.add_child(_end_stats_lbl)

	var end_btns: HBoxContainer = HBoxContainer.new()
	end_btns.add_theme_constant_override(&"separation", 10)
	end_v.add_child(end_btns)

	var btn_replay: Button = _make_action_btn("Yeniden Oyna", NeoSteppePalette.JADE_PRIMARY, func() -> void:
		_end_screen.visible = false
		replay_requested.emit())
	end_btns.add_child(btn_replay)

	var btn_mm: Button = _make_action_btn("Ana Menü", NeoSteppePalette.GOLD_TAMGA, func() -> void:
		return_to_main_menu_requested.emit())
	end_btns.add_child(btn_mm)

	_rebuild_bottom_actions()


func _add_res_label(parent_box: HBoxContainer, key_n: StringName, init_txt: String, col: Color) -> void:
	var rl: Label = Label.new()
	rl.text = init_txt
	rl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rl.clip_text = true
	rl.add_theme_font_size_override(&"font_size", 13)
	rl.add_theme_color_override(&"font_color", col)
	parent_box.add_child(rl)
	_res_labels[key_n] = rl


func _make_top_btn(txt: String, col: Color, cb: Callable) -> Button:
	var btn: Button = Button.new()
	btn.text = txt
	btn.custom_minimum_size = Vector2(68.0, 36.0)
	btn.add_theme_font_size_override(&"font_size", 12)
	OtukenThemeFactory.apply_button_semantic_styles(btn, col, false, 8, 4)
	btn.pressed.connect(cb)
	return btn


func _make_action_btn(txt: String, col: Color, cb: Callable) -> Button:
	var btn: Button = Button.new()
	btn.text = txt
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(120.0, 56.0)
	btn.add_theme_font_size_override(&"font_size", 12)
	OtukenThemeFactory.apply_button_semantic_styles(btn, col, false, 10, 6)
	btn.pressed.connect(cb)
	return btn


func _rebuild_bottom_actions() -> void:
	for ch: Node in _action_buttons_box.get_children():
		_action_buttons_box.remove_child(ch)
		ch.queue_free()

	if _context_mode == &"build":
		_context_title_lbl.text = "İNŞA ET\n(Seç & Dokun)"
		_action_buttons_box.add_child(_make_action_btn("Otağ (Yurt)\n60 Taş", NeoSteppePalette.GOLD_TAMGA, func() -> void: build_requested.emit(&"ger_camp")))
		_action_buttons_box.add_child(_make_action_btn("Demirci Ocağı\n80 Taş · 40 Çelik", NeoSteppePalette.EMBER_RED, func() -> void: build_requested.emit(&"nomadic_forge")))
		_action_buttons_box.add_child(_make_action_btn("Taş Ocağı\n120 Taş · 30 Çelik", NeoSteppePalette.BRONZE_WEATHERED, func() -> void: build_requested.emit(&"quarry")))
		_action_buttons_box.add_child(_make_action_btn("Kurgan\n150 Taş · 15 Gümüş", NeoSteppePalette.ICE_BLUE, func() -> void: build_requested.emit(&"kurgan_shrine")))
	elif _context_mode == &"placing":
		_context_title_lbl.text = "YERLEŞTİR:\n%s" % _placing_building_name
		var hint: Label = Label.new()
		hint.text = "Haritada yeşil önizleme alanına dokunarak binayı dikin."
		hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_action_buttons_box.add_child(hint)
		_action_buttons_box.add_child(_make_action_btn("İptal Et", NeoSteppePalette.EMBER_RED, func() -> void: build_cancelled.emit()))
	elif _context_mode == &"building":
		_context_title_lbl.text = _selected_label
		if _selected_building_is_prod:
			_action_buttons_box.add_child(_make_action_btn("Atlı Okçu\n110 HP · 18 Hsr\n60 Erzak · 20 Gümüş", NeoSteppePalette.JADE_PRIMARY, func() -> void: train_unit_requested.emit(&"horse_archer")))
			_action_buttons_box.add_child(_make_action_btn("Ağır Süvari\n180 HP · 28 Hsr\n80 Erzak · 35 Çelik", NeoSteppePalette.GOLD_TAMGA, func() -> void: train_unit_requested.emit(&"heavy_lancer")))
			_action_buttons_box.add_child(_make_action_btn("İkmal Öküzü\n220 HP · Yük\n50 Erzak · 15 Taş", NeoSteppePalette.ICE_BLUE, func() -> void: train_unit_requested.emit(&"supply_ox")))
		_action_buttons_box.add_child(_make_action_btn("İnşa Menüsü", NeoSteppePalette.BRONZE_WEATHERED, func() -> void: set_context_build()))
	elif _context_mode == &"army":
		_context_title_lbl.text = _selected_label
		_action_buttons_box.add_child(_make_action_btn("En Yakına Saldır", NeoSteppePalette.EMBER_RED, func() -> void: army_order_requested.emit(&"attack_nearest")))
		_action_buttons_box.add_child(_make_action_btn("Dur / Savun", NeoSteppePalette.ICE_BLUE, func() -> void: army_order_requested.emit(&"hold")))
		_action_buttons_box.add_child(_make_action_btn("Otağa Dön", NeoSteppePalette.JADE_PRIMARY, func() -> void: army_order_requested.emit(&"retreat")))
		_action_buttons_box.add_child(_make_action_btn("İnşa Menüsü", NeoSteppePalette.BRONZE_WEATHERED, func() -> void: set_context_build()))


func _set_res_text(key_n: StringName, txt: String) -> void:
	if _res_labels.has(key_n):
		_res_labels[key_n].text = txt


func _fmt_rate(r: int) -> String:
	return "+%d" % r if r >= 0 else "%d" % r


func _on_graphics_updated(_prof_idx: int, show_fps_flag: bool) -> void:
	_show_fps = show_fps_flag
	if _fps_label != null:
		_fps_label.visible = _show_fps
