class_name SaveLoadMenuPanel
extends TamgaCardPanel
## Save / Load Manager Panel (rank 4). Operates directly on `SaveLoadRepository`
## snapshots through `GameShellViewModel`, showing season/Kut/hash telemetry,
## corrupted save warnings, save, load, and delete actions.

signal save_completed(slot_id: String, world_hash: String)
signal load_completed(slot_id: String, world_hash: String)
signal panel_closed()

var _vm_ref: WeakRef = null
var _selected_slot_id: String = ""
var _allow_saving: bool = true
var _built: bool = false

var _slot_name_edit: LineEdit = null
var _save_btn: Button = null
var _load_btn: Button = null
var _delete_btn: Button = null
var _close_btn: Button = null
var _status_lbl: Label = null
var _slots_vbox: VBoxContainer = null

var _slot_buttons: Array[Button] = []
var _static_callbacks: Dictionary[Button, Callable] = {}
var _dynamic_callbacks: Dictionary[Button, Callable] = {}


func _init() -> void:
	name = "SaveLoadMenuPanel"
	card_id = &"save_load_menu_panel"
	semantic_tone = &"gold"
	clickable = false
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP


func _ready() -> void:
	_ensure_built()


func _exit_tree() -> void:
	_clear_dynamic_slot_rows()
	for btn: Button in _static_callbacks.keys():
		if btn != null and is_instance_valid(btn):
			var cb: Callable = _static_callbacks[btn]
			if cb.is_valid() and btn.pressed.is_connected(cb):
				btn.pressed.disconnect(cb)
	_static_callbacks.clear()


func bind_view_model(vm: GameShellViewModel) -> void:
	_vm_ref = weakref(vm) if vm != null else null
	refresh_slots()


func open_menu(allow_saving: bool = true) -> void:
	_ensure_built()
	_allow_saving = allow_saving
	_save_btn.visible = _allow_saving
	_slot_name_edit.visible = _allow_saving
	visible = true
	refresh_slots()


func close_menu() -> void:
	if not visible:
		return
	visible = false
	panel_closed.emit()


func refresh_slots() -> void:
	_ensure_built()
	_clear_dynamic_slot_rows()
	var vm: GameShellViewModel = _get_vm()
	if vm == null:
		return

	var slots: Array[GameShellViewModel.SaveSlotSummary] = vm.list_save_slots()
	if slots.is_empty():
		var empty_lbl: Label = Label.new()
		empty_lbl.theme_type_variation = &"MutedLabel"
		empty_lbl.text = "Henüz kayıtlı sefer dosyası bulunamadı."
		_slots_vbox.add_child(empty_lbl)
		_selected_slot_id = ""
		_sync_action_buttons(null)
		return

	var selected_summary: GameShellViewModel.SaveSlotSummary = null
	for s: GameShellViewModel.SaveSlotSummary in slots:
		if s == null:
			continue
		if _selected_slot_id.is_empty():
			_selected_slot_id = s.slot_id
		var is_sel: bool = s.slot_id == _selected_slot_id
		if is_sel:
			selected_summary = s

		var btn: Button = Button.new()
		btn.name = "SaveSlotBtn_%s" % s.slot_id
		btn.theme_type_variation = &"GhostIconButton"
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if s.is_valid:
			btn.text = "%s · %s · Kut %.0f · #%s" % [
				s.slot_id, s.season_label, s.kut_score, s.world_hash.substr(0, 8)]
			OtukenThemeFactory.apply_button_semantic_styles(btn, NeoSteppePalette.JADE_PRIMARY, is_sel, 8, 4)
		else:
			btn.text = "[BOZUK KAYIT] %s — %s" % [s.slot_id, s.error_reason]
			OtukenThemeFactory.apply_button_semantic_styles(btn, NeoSteppePalette.EMBER_RED, is_sel, 8, 4)

		var cb: Callable = _on_slot_row_pressed.bind(s.slot_id)
		btn.pressed.connect(cb)
		_slots_vbox.add_child(btn)
		_slot_buttons.append(btn)
		_dynamic_callbacks[btn] = cb

	_sync_action_buttons(selected_summary)


func select_slot(slot_id: String) -> void:
	_selected_slot_id = slot_id
	refresh_slots()


func save_current_slot(slot_id: String = "") -> GameShellViewModel.SaveActionResult:
	_ensure_built()
	var target: String = slot_id if not slot_id.strip_edges().is_empty() else _slot_name_edit.text
	var vm: GameShellViewModel = _get_vm()
	if vm == null:
		var fail: GameShellViewModel.SaveActionResult = GameShellViewModel.SaveActionResult.new()
		fail.ok = false
		fail.message = "ViewModel bağlı değil."
		return fail
	var res: GameShellViewModel.SaveActionResult = vm.save_to_slot(target)
	_status_lbl.text = res.message
	_status_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.JADE_BRIGHT if res.ok else NeoSteppePalette.EMBER_BRIGHT)
	if res.ok:
		_selected_slot_id = res.slot_id
		save_completed.emit(res.slot_id, res.world_hash)
	refresh_slots()
	return res


func load_selected_slot() -> GameShellViewModel.SaveActionResult:
	_ensure_built()
	var vm: GameShellViewModel = _get_vm()
	if vm == null or _selected_slot_id.is_empty():
		var fail: GameShellViewModel.SaveActionResult = GameShellViewModel.SaveActionResult.new()
		fail.ok = false
		fail.message = "Yüklenecek geçerli bir kayıt seçin."
		return fail
	var res: GameShellViewModel.SaveActionResult = vm.load_from_slot(_selected_slot_id)
	_status_lbl.text = res.message
	_status_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.JADE_BRIGHT if res.ok else NeoSteppePalette.EMBER_BRIGHT)
	if res.ok:
		load_completed.emit(res.slot_id, res.world_hash)
	return res


func delete_selected_slot() -> bool:
	_ensure_built()
	var vm: GameShellViewModel = _get_vm()
	if vm == null or _selected_slot_id.is_empty():
		return false
	var ok: bool = vm.delete_save_slot(_selected_slot_id)
	_status_lbl.text = ("Kayıt silindi: %s" % _selected_slot_id) if ok else "Kayıt silinemedi."
	_status_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.GOLD_PALE if ok else NeoSteppePalette.EMBER_BRIGHT)
	_selected_slot_id = ""
	refresh_slots()
	return ok


func get_slot_count() -> int:
	return _slot_buttons.size()


func get_status_text() -> String:
	_ensure_built()
	return _status_lbl.text


func get_selected_slot_id() -> String:
	return _selected_slot_id


func _sync_action_buttons(selected: GameShellViewModel.SaveSlotSummary) -> void:
	_load_btn.disabled = selected == null
	_delete_btn.disabled = selected == null
	if selected != null and not selected.is_valid:
		_status_lbl.text = "UYARI: %s bozuk (%s). Yükleme engellenecek." % [selected.slot_id, selected.error_reason]
		_status_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.EMBER_BRIGHT)


func _ensure_built() -> void:
	if _built:
		return
	_built = true

	var margin: MarginContainer = get_content_container()
	margin.add_theme_constant_override(&"margin_left", 14)
	margin.add_theme_constant_override(&"margin_right", 14)
	margin.add_theme_constant_override(&"margin_top", 10)
	margin.add_theme_constant_override(&"margin_bottom", 10)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override(&"separation", 7)
	margin.add_child(vbox)

	var hdr: HBoxContainer = HBoxContainer.new()
	vbox.add_child(hdr)

	var title_lbl: Label = Label.new()
	title_lbl.theme_type_variation = &"TitleLabel"
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.text = "SEFER KAYIT & YÜKLEME"
	hdr.add_child(title_lbl)

	_close_btn = _make_static_btn("CloseSaveLoadBtn", "✕", NeoSteppePalette.BRONZE_WEATHERED, close_menu)
	hdr.add_child(_close_btn)

	var save_row: HBoxContainer = HBoxContainer.new()
	save_row.add_theme_constant_override(&"separation", 6)
	vbox.add_child(save_row)

	_slot_name_edit = LineEdit.new()
	_slot_name_edit.name = "SaveSlotNameEdit"
	_slot_name_edit.placeholder_text = "Kayıt adı..."
	_slot_name_edit.text = "otuken_sefer_1"
	_slot_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_row.add_child(_slot_name_edit)

	_save_btn = _make_static_btn("BtnDoSaveSlot", "Kaydet", NeoSteppePalette.JADE_PRIMARY, _on_save_pressed)
	save_row.add_child(_save_btn)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0.0, 180.0)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_slots_vbox = VBoxContainer.new()
	_slots_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_slots_vbox.add_theme_constant_override(&"separation", 4)
	scroll.add_child(_slots_vbox)

	var action_row: HBoxContainer = HBoxContainer.new()
	action_row.add_theme_constant_override(&"separation", 8)
	vbox.add_child(action_row)

	_load_btn = _make_static_btn("BtnDoLoadSlot", "Seçileni Yükle", NeoSteppePalette.GOLD_TAMGA, _on_load_pressed)
	_load_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_row.add_child(_load_btn)

	_delete_btn = _make_static_btn("BtnDeleteSlot", "Sil", NeoSteppePalette.EMBER_RED, _on_delete_pressed)
	action_row.add_child(_delete_btn)

	_status_lbl = Label.new()
	_status_lbl.theme_type_variation = &"CaptionLabel"
	_status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_lbl.text = ""
	vbox.add_child(_status_lbl)


func _make_static_btn(p_name: String, p_text: String, p_col: Color, p_cb: Callable) -> Button:
	var btn: Button = Button.new()
	btn.name = p_name
	btn.theme_type_variation = &"GhostIconButton"
	btn.text = p_text
	OtukenThemeFactory.apply_button_semantic_styles(btn, p_col, false, 8, 4)
	btn.pressed.connect(p_cb)
	_static_callbacks[btn] = p_cb
	return btn


func _on_slot_row_pressed(slot_id: String) -> void:
	select_slot(slot_id)


func _on_save_pressed() -> void:
	save_current_slot("")


func _on_load_pressed() -> void:
	load_selected_slot()


func _on_delete_pressed() -> void:
	delete_selected_slot()


func _clear_dynamic_slot_rows() -> void:
	for btn: Button in _dynamic_callbacks.keys():
		if btn != null and is_instance_valid(btn):
			var cb: Callable = _dynamic_callbacks[btn]
			if cb.is_valid() and btn.pressed.is_connected(cb):
				btn.pressed.disconnect(cb)
	_dynamic_callbacks.clear()
	_slot_buttons.clear()
	if _slots_vbox != null and is_instance_valid(_slots_vbox):
		for child: Node in _slots_vbox.get_children():
			_slots_vbox.remove_child(child)
			child.queue_free()


func _get_vm() -> GameShellViewModel:
	if _vm_ref == null:
		return null
	var obj: Object = _vm_ref.get_ref()
	if obj != null and is_instance_valid(obj):
		return obj as GameShellViewModel
	return null
