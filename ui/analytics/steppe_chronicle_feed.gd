class_name SteppeChronicleFeed
extends TamgaCardPanel
## Filterable Neo-Steppe chronicle event feed (Bozkır Vakanüvisi, rank 4).
## Displays live combat, ambush, water sabotage, Zud, and Kurultay/diplomacy
## events where clicking an entry jumps the 3D camera smoothly to its region.

signal chronicle_focus_requested(region_coord: Vector2i, world_pos: Vector3)
signal feed_closed()

const FILTER_TABS: Array[StringName] = [
	MetricAnalyticsViewModel.CHRONICLE_ALL,
	MetricAnalyticsViewModel.CHRONICLE_BATTLE,
	MetricAnalyticsViewModel.CHRONICLE_AMBUSH_SABOTAGE,
	MetricAnalyticsViewModel.CHRONICLE_ZUD_ECOLOGY,
	MetricAnalyticsViewModel.CHRONICLE_KURULTAY_DIPLOMACY,
]

const FILTER_LABELS: Dictionary[StringName, String] = {
	&"all": "Tümü",
	&"battle": "Savaş",
	&"ambush_sabotage": "Pusu/Sabotaj",
	&"zud_ecology": "Zud/Ekoloji",
	&"kurultay_diplomacy": "Kurultay/Dip.",
}

var _vm_ref: WeakRef = null
var _camera_ref: WeakRef = null
var _active_filter: StringName = MetricAnalyticsViewModel.CHRONICLE_ALL
var _built: bool = false

var _close_btn: Button = null
var _close_cb: Callable = Callable()
var _count_lbl: Label = null
var _entries_vbox: VBoxContainer = null

var _filter_buttons: Dictionary[StringName, Button] = {}
var _filter_callbacks: Dictionary[Button, Callable] = {}
var _entry_buttons: Array[Button] = []
var _entry_callbacks: Dictionary[Button, Callable] = {}


func _init() -> void:
	name = "SteppeChronicleFeed"
	card_id = &"steppe_chronicle_feed"
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
	refresh_chronicle()


func bind_camera(camera: DualLayerCamera) -> void:
	_camera_ref = weakref(camera) if camera != null else null


func open_feed(filter_category: StringName = &"") -> void:
	_ensure_built()
	if filter_category != &"":
		_active_filter = filter_category
	visible = true
	refresh_chronicle()


func close_feed() -> void:
	if not visible:
		return
	visible = false
	feed_closed.emit()


func set_filter(filter_category: StringName) -> void:
	_ensure_built()
	_active_filter = filter_category if FILTER_TABS.has(filter_category) else MetricAnalyticsViewModel.CHRONICLE_ALL
	refresh_chronicle()


func get_active_filter() -> StringName:
	return _active_filter


func get_visible_entry_count() -> int:
	return _entry_buttons.size()


func activate_entry_at(index: int) -> bool:
	if index < 0 or index >= _entry_buttons.size():
		return false
	var btn: Button = _entry_buttons[index]
	if btn != null and is_instance_valid(btn):
		btn.pressed.emit()
		return true
	return false


func refresh_chronicle() -> void:
	_ensure_built()
	_sync_filter_buttons()
	_clear_entry_rows()

	var vm_obj: Object = _vm_ref.get_ref() if _vm_ref != null else null
	var vm: MetricAnalyticsViewModel = vm_obj as MetricAnalyticsViewModel if vm_obj != null else null
	if vm == null:
		_count_lbl.text = "0 kayıt"
		return

	var entries: Array[MetricAnalyticsViewModel.ChronicleEntry] = vm.get_chronicle_entries(_active_filter)
	_count_lbl.text = "%d kayıt" % entries.size()
	if entries.is_empty():
		var empty_lbl: Label = Label.new()
		empty_lbl.theme_type_variation = &"MutedLabel"
		empty_lbl.text = "Seçilen kategoride henüz vaka kaydı yok."
		_entries_vbox.add_child(empty_lbl)
		return

	for entry: MetricAnalyticsViewModel.ChronicleEntry in entries:
		if entry == null:
			continue
		var sem_col: Color = NeoSteppePalette.get_semantic_color(entry.tone_id)
		var btn: Button = Button.new()
		btn.name = "ChronicleEntryBtn_%d" % entry.entry_id
		btn.theme_type_variation = &"GhostIconButton"
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.text = "[%s · %s] %s\n%s · Odak: [%d, %d] ->" % [
			entry.category_label,
			entry.season_label,
			entry.title,
			entry.detail,
			entry.region_coord.x,
			entry.region_coord.y]
		OtukenThemeFactory.apply_button_semantic_styles(btn, Color(sem_col.r, sem_col.g, sem_col.b, 0.70), false, 8, 5)
		var cb: Callable = _on_entry_clicked.bind(entry.region_coord, entry.world_pos)
		btn.pressed.connect(cb)
		_entries_vbox.add_child(btn)
		_entry_buttons.append(btn)
		_entry_callbacks[btn] = cb


func _ensure_built() -> void:
	if _built:
		return
	_built = true

	var margin: MarginContainer = get_content_container()
	margin.add_theme_constant_override(&"margin_left", 10)
	margin.add_theme_constant_override(&"margin_right", 10)
	margin.add_theme_constant_override(&"margin_top", 8)
	margin.add_theme_constant_override(&"margin_bottom", 8)

	var root_v: VBoxContainer = VBoxContainer.new()
	root_v.name = "ChronicleRootVBox"
	root_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_v.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_v.add_theme_constant_override(&"separation", 6)
	margin.add_child(root_v)

	var hdr: HBoxContainer = HBoxContainer.new()
	hdr.add_theme_constant_override(&"separation", 6)
	root_v.add_child(hdr)

	var title_lbl: Label = Label.new()
	title_lbl.theme_type_variation = &"TitleLabel"
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.text = "BOZKIR VAKANÜVİSİ"
	hdr.add_child(title_lbl)

	_count_lbl = Label.new()
	_count_lbl.theme_type_variation = &"MutedLabel"
	_count_lbl.text = "0 kayıt"
	hdr.add_child(_count_lbl)

	_close_btn = Button.new()
	_close_btn.name = "CloseChronicleBtn"
	_close_btn.theme_type_variation = &"GhostIconButton"
	_close_btn.text = "✕"
	OtukenThemeFactory.apply_button_semantic_styles(_close_btn, NeoSteppePalette.BRONZE_WEATHERED, false, 6, 2)
	_close_cb = close_feed
	_close_btn.pressed.connect(_close_cb)
	hdr.add_child(_close_btn)

	var filter_flow: HFlowContainer = HFlowContainer.new()
	filter_flow.add_theme_constant_override(&"h_separation", 4)
	filter_flow.add_theme_constant_override(&"v_separation", 4)
	root_v.add_child(filter_flow)

	for fid: StringName in FILTER_TABS:
		var fbtn: Button = Button.new()
		fbtn.name = "ChronicleFilterBtn_%s" % String(fid)
		fbtn.theme_type_variation = &"GhostIconButton"
		fbtn.text = FILTER_LABELS[fid] if FILTER_LABELS.has(fid) else String(fid)
		fbtn.add_theme_font_size_override(&"font_size", NeoSteppePalette.FONT_SIZE_MICRO)
		var cb: Callable = set_filter.bind(fid)
		fbtn.pressed.connect(cb)
		filter_flow.add_child(fbtn)
		_filter_buttons[fid] = fbtn
		_filter_callbacks[fbtn] = cb

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_v.add_child(scroll)

	_entries_vbox = VBoxContainer.new()
	_entries_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_entries_vbox.add_theme_constant_override(&"separation", 5)
	scroll.add_child(_entries_vbox)


func _sync_filter_buttons() -> void:
	for fid: StringName in _filter_buttons:
		var btn: Button = _filter_buttons[fid]
		if btn == null:
			continue
		var selected: bool = (fid == _active_filter)
		var col: Color = NeoSteppePalette.GOLD_TAMGA if selected else NeoSteppePalette.BRONZE_WEATHERED
		OtukenThemeFactory.apply_button_semantic_styles(btn, col, selected, 6, 2)


func _clear_entry_rows() -> void:
	for btn: Button in _entry_buttons:
		if btn != null and is_instance_valid(btn):
			if _entry_callbacks.has(btn):
				var cb: Callable = _entry_callbacks[btn]
				if not cb.is_null() and btn.pressed.is_connected(cb):
					btn.pressed.disconnect(cb)
	_entry_buttons.clear()
	_entry_callbacks.clear()
	if _entries_vbox != null:
		for child: Node in _entries_vbox.get_children():
			_entries_vbox.remove_child(child)
			child.free()


func _on_entry_clicked(coord: Vector2i, world_pos: Vector3) -> void:
	if _camera_ref != null:
		var cam_obj: Object = _camera_ref.get_ref()
		if cam_obj != null and is_instance_valid(cam_obj):
			var cam: DualLayerCamera = cam_obj as DualLayerCamera
			if cam != null:
				cam.focus_world_position(world_pos)
	chronicle_focus_requested.emit(coord, world_pos)


func _disconnect_all_signals() -> void:
	if _close_btn != null and is_instance_valid(_close_btn) and not _close_cb.is_null():
		if _close_btn.pressed.is_connected(_close_cb):
			_close_btn.pressed.disconnect(_close_cb)
	_close_cb = Callable()

	for fbtn: Button in _filter_callbacks:
		if fbtn != null and is_instance_valid(fbtn):
			var cb: Callable = _filter_callbacks[fbtn]
			if not cb.is_null() and fbtn.pressed.is_connected(cb):
				fbtn.pressed.disconnect(cb)
	_filter_callbacks.clear()
	_filter_buttons.clear()
	_clear_entry_rows()
