class_name EmpireLedgerPanel
extends TamgaCardPanel
## Sortable multi-tab Empire Ledger (Devlet Defteri, rank 4) covering
## Bölgeler, Tümenler, Komutanlar, Su & Kervanlar, and Fog-of-War compliant
## Bilinen Boylar.

signal ledger_focus_requested(coord: Vector2i, world_pos: Vector3)
signal ledger_closed()

const TAB_ORDER: Array[StringName] = [
	MetricAnalyticsViewModel.LEDGER_TAB_REGIONS,
	MetricAnalyticsViewModel.LEDGER_TAB_ARMIES,
	MetricAnalyticsViewModel.LEDGER_TAB_COMMANDERS,
	MetricAnalyticsViewModel.LEDGER_TAB_ROUTES,
	MetricAnalyticsViewModel.LEDGER_TAB_RIVALS,
]

const TAB_LABELS: Dictionary[StringName, String] = {
	&"regions": "Bölgeler",
	&"armies": "Tümenler",
	&"commanders": "Komutanlar",
	&"routes": "Su & Kervan",
	&"rivals": "Bilinen Boylar",
}

var _vm_ref: WeakRef = null
var _camera_ref: WeakRef = null
var _active_tab_id: StringName = MetricAnalyticsViewModel.LEDGER_TAB_REGIONS
var _sort_column: String = ""
var _sort_ascending: bool = true
var _last_table: MetricAnalyticsViewModel.LedgerTableSnapshot = null
var _built: bool = false

var _title_lbl: Label = null
var _close_btn: Button = null
var _close_cb: Callable = Callable()
var _headers_hbox: HBoxContainer = null
var _rows_vbox: VBoxContainer = null

var _tab_buttons: Dictionary[StringName, Button] = {}
var _tab_callbacks: Dictionary[Button, Callable] = {}
var _header_buttons: Array[Button] = []
var _header_callbacks: Dictionary[Button, Callable] = {}
var _focus_buttons: Array[Button] = []
var _focus_callbacks: Dictionary[Button, Callable] = {}


func _init() -> void:
	name = "EmpireLedgerPanel"
	card_id = &"empire_ledger_panel"
	clickable = false
	semantic_tone = &"gold"
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP


func _ready() -> void:
	_ensure_built()


func _exit_tree() -> void:
	_disconnect_all_signals()


func bind_view_model(vm: MetricAnalyticsViewModel) -> void:
	_vm_ref = weakref(vm) if vm != null else null
	refresh_ledger()


func bind_camera(camera: DualLayerCamera) -> void:
	_camera_ref = weakref(camera) if camera != null else null


func open_ledger(tab_id: StringName = &"") -> void:
	_ensure_built()
	if tab_id != &"":
		_active_tab_id = tab_id
		_sort_column = ""
		_sort_ascending = true
	visible = true
	refresh_ledger()


func close_ledger() -> void:
	if not visible:
		return
	visible = false
	ledger_closed.emit()


func select_tab(tab_id: StringName) -> void:
	_ensure_built()
	if TAB_ORDER.has(tab_id):
		_active_tab_id = tab_id
	_sort_column = ""
	_sort_ascending = true
	refresh_ledger()


func sort_by(column_key: String, force_ascending_override: int = -1) -> void:
	_ensure_built()
	if force_ascending_override == 1:
		_sort_ascending = true
	elif force_ascending_override == 0:
		_sort_ascending = false
	elif _sort_column == column_key:
		_sort_ascending = not _sort_ascending
	else:
		_sort_ascending = true
	_sort_column = column_key
	refresh_ledger()


func get_active_tab_id() -> StringName:
	return _active_tab_id


func get_sort_column() -> String:
	return _sort_column


func is_sort_ascending() -> bool:
	return _sort_ascending


func get_visible_row_count() -> int:
	if _last_table == null:
		return 0
	return _last_table.rows.size()


func get_row_cell_text(row_index: int, column_key: String) -> String:
	if _last_table == null or row_index < 0 or row_index >= _last_table.rows.size():
		return ""
	var row: MetricAnalyticsViewModel.LedgerRow = _last_table.rows[row_index]
	if row != null and row.values.has(column_key):
		return row.values[column_key]
	return ""


func get_last_table() -> MetricAnalyticsViewModel.LedgerTableSnapshot:
	return _last_table


func refresh_ledger() -> void:
	_ensure_built()
	_sync_tab_buttons()
	_clear_dynamic_table()

	var vm_obj: Object = _vm_ref.get_ref() if _vm_ref != null else null
	var vm: MetricAnalyticsViewModel = vm_obj as MetricAnalyticsViewModel if vm_obj != null else null
	if vm == null:
		return

	var table: MetricAnalyticsViewModel.LedgerTableSnapshot = vm.capture_ledger_tab(_active_tab_id, _sort_column, _sort_ascending)
	_last_table = table
	_title_lbl.text = "DEVLET DEFTERİ · %s" % table.tab_title.to_upper()

	# Build sortable headers
	for col: MetricAnalyticsViewModel.LedgerColumn in table.columns:
		var hbtn: Button = Button.new()
		hbtn.name = "LedgerColBtn_%s" % col.key
		hbtn.theme_type_variation = &"GhostIconButton"
		hbtn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var dir_mark: String = ""
		if _sort_column == col.key:
			dir_mark = " ▲" if _sort_ascending else " ▼"
		hbtn.text = "%s%s" % [col.title, dir_mark]
		hbtn.add_theme_font_size_override(&"font_size", NeoSteppePalette.FONT_SIZE_MICRO)
		var col_col: Color = NeoSteppePalette.GOLD_TAMGA if _sort_column == col.key else NeoSteppePalette.BRONZE_WEATHERED
		OtukenThemeFactory.apply_button_semantic_styles(hbtn, col_col, _sort_column == col.key, 6, 2)
		var hcb: Callable = sort_by.bind(col.key)
		hbtn.pressed.connect(hcb)
		_headers_hbox.add_child(hbtn)
		_header_buttons.append(hbtn)
		_header_callbacks[hbtn] = hcb

	# Optional Focus spacer header
	var spacer_hdr: Label = Label.new()
	spacer_hdr.theme_type_variation = &"CaptionLabel"
	spacer_hdr.custom_minimum_size = Vector2(54.0, 0.0)
	spacer_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	spacer_hdr.text = "Konum"
	_headers_hbox.add_child(spacer_hdr)

	if table.rows.is_empty():
		var empty_lbl: Label = Label.new()
		empty_lbl.theme_type_variation = &"MutedLabel"
		empty_lbl.text = "Bu sekmede kayıtlı öğe bulunmuyor."
		_rows_vbox.add_child(empty_lbl)
		return

	for row: MetricAnalyticsViewModel.LedgerRow in table.rows:
		if row == null:
			continue
		var sem_col: Color = NeoSteppePalette.get_semantic_color(row.tone_id)
		var panel: PanelContainer = PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.add_theme_stylebox_override(&"panel", OtukenThemeFactory.build_card_style(
			Color(sem_col.r, sem_col.g, sem_col.b, 0.45), 1, NeoSteppePalette.CHARCOAL_SURFACE, 6, 4))

		var rh: HBoxContainer = HBoxContainer.new()
		rh.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rh.add_theme_constant_override(&"separation", 4)
		panel.add_child(rh)

		for col: MetricAnalyticsViewModel.LedgerColumn in table.columns:
			var cell: Label = Label.new()
			cell.theme_type_variation = &"CaptionLabel"
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cell.clip_text = true
			cell.text = row.values[col.key] if row.values.has(col.key) else "-"
			cell.add_theme_color_override(&"font_color", NeoSteppePalette.TEXT_PRIMARY)
			rh.add_child(cell)

		var focus_btn: Button = Button.new()
		focus_btn.custom_minimum_size = Vector2(54.0, 0.0)
		focus_btn.theme_type_variation = &"GhostIconButton"
		focus_btn.add_theme_font_size_override(&"font_size", NeoSteppePalette.FONT_SIZE_MICRO)
		if row.has_focus_coord:
			focus_btn.text = "Odak"
			OtukenThemeFactory.apply_button_semantic_styles(focus_btn, NeoSteppePalette.ICE_BLUE, false, 4, 2)
			var fcb: Callable = _on_row_focus_clicked.bind(row.focus_coord)
			focus_btn.pressed.connect(fcb)
			_focus_buttons.append(focus_btn)
			_focus_callbacks[focus_btn] = fcb
		else:
			focus_btn.text = "-"
			focus_btn.disabled = true
			OtukenThemeFactory.apply_button_semantic_styles(focus_btn, NeoSteppePalette.BRONZE_DARK, false, 4, 2)
		rh.add_child(focus_btn)
		_rows_vbox.add_child(panel)


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
	root_v.name = "LedgerRootVBox"
	root_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_v.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_v.add_theme_constant_override(&"separation", 6)
	margin.add_child(root_v)

	var hdr: HBoxContainer = HBoxContainer.new()
	hdr.add_theme_constant_override(&"separation", 6)
	root_v.add_child(hdr)

	_title_lbl = Label.new()
	_title_lbl.theme_type_variation = &"TitleLabel"
	_title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_lbl.text = "DEVLET DEFTERİ"
	hdr.add_child(_title_lbl)

	_close_btn = Button.new()
	_close_btn.name = "CloseLedgerBtn"
	_close_btn.theme_type_variation = &"GhostIconButton"
	_close_btn.text = "✕"
	OtukenThemeFactory.apply_button_semantic_styles(_close_btn, NeoSteppePalette.BRONZE_WEATHERED, false, 6, 2)
	_close_cb = close_ledger
	_close_btn.pressed.connect(_close_cb)
	hdr.add_child(_close_btn)

	var tab_hbox: HBoxContainer = HBoxContainer.new()
	tab_hbox.add_theme_constant_override(&"separation", 4)
	root_v.add_child(tab_hbox)

	for tid: StringName in TAB_ORDER:
		var tbtn: Button = Button.new()
		tbtn.name = "LedgerTabBtn_%s" % String(tid)
		tbtn.theme_type_variation = &"GhostIconButton"
		tbtn.text = TAB_LABELS[tid] if TAB_LABELS.has(tid) else String(tid)
		tbtn.add_theme_font_size_override(&"font_size", NeoSteppePalette.FONT_SIZE_MICRO)
		var tcb: Callable = select_tab.bind(tid)
		tbtn.pressed.connect(tcb)
		tab_hbox.add_child(tbtn)
		_tab_buttons[tid] = tbtn
		_tab_callbacks[tbtn] = tcb

	_headers_hbox = HBoxContainer.new()
	_headers_hbox.name = "LedgerHeadersHBox"
	_headers_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_headers_hbox.add_theme_constant_override(&"separation", 4)
	root_v.add_child(_headers_hbox)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_v.add_child(scroll)

	_rows_vbox = VBoxContainer.new()
	_rows_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows_vbox.add_theme_constant_override(&"separation", 4)
	scroll.add_child(_rows_vbox)


func _sync_tab_buttons() -> void:
	for tid: StringName in _tab_buttons:
		var btn: Button = _tab_buttons[tid]
		if btn == null:
			continue
		var sel: bool = (tid == _active_tab_id)
		var col: Color = NeoSteppePalette.JADE_PRIMARY if sel else NeoSteppePalette.BRONZE_WEATHERED
		OtukenThemeFactory.apply_button_semantic_styles(btn, col, sel, 7, 3)


func _clear_dynamic_table() -> void:
	for hb: Button in _header_buttons:
		if hb != null and is_instance_valid(hb) and _header_callbacks.has(hb):
			var hcb: Callable = _header_callbacks[hb]
			if not hcb.is_null() and hb.pressed.is_connected(hcb):
				hb.pressed.disconnect(hcb)
	_header_buttons.clear()
	_header_callbacks.clear()
	if _headers_hbox != null:
		for c: Node in _headers_hbox.get_children():
			_headers_hbox.remove_child(c)
			c.free()

	for fb: Button in _focus_buttons:
		if fb != null and is_instance_valid(fb) and _focus_callbacks.has(fb):
			var fcb: Callable = _focus_callbacks[fb]
			if not fcb.is_null() and fb.pressed.is_connected(fcb):
				fb.pressed.disconnect(fcb)
	_focus_buttons.clear()
	_focus_callbacks.clear()
	if _rows_vbox != null:
		for c2: Node in _rows_vbox.get_children():
			_rows_vbox.remove_child(c2)
			c2.free()


func _on_row_focus_clicked(coord: Vector2i) -> void:
	var vm_obj: Object = _vm_ref.get_ref() if _vm_ref != null else null
	var vm: MetricAnalyticsViewModel = vm_obj as MetricAnalyticsViewModel if vm_obj != null else null
	var world_pos: Vector3 = vm.coord_to_world_pos(coord) if vm != null else Vector3.ZERO
	if _camera_ref != null:
		var cam_obj: Object = _camera_ref.get_ref()
		if cam_obj != null and is_instance_valid(cam_obj):
			var cam: DualLayerCamera = cam_obj as DualLayerCamera
			if cam != null:
				cam.focus_world_position(world_pos)
	ledger_focus_requested.emit(coord, world_pos)


func _disconnect_all_signals() -> void:
	if _close_btn != null and is_instance_valid(_close_btn) and not _close_cb.is_null():
		if _close_btn.pressed.is_connected(_close_cb):
			_close_btn.pressed.disconnect(_close_cb)
	_close_cb = Callable()

	for tb: Button in _tab_callbacks:
		if tb != null and is_instance_valid(tb):
			var tcb: Callable = _tab_callbacks[tb]
			if not tcb.is_null() and tb.pressed.is_connected(tcb):
				tb.pressed.disconnect(tcb)
	_tab_callbacks.clear()
	_tab_buttons.clear()
	_clear_dynamic_table()
