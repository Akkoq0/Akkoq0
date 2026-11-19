class_name AlertToastStack
extends VBoxContainer
## Edge-anchored clickable toast notification stack (rank 4).
## Stacks transient Neo-Steppe alert cards without obstructing the center map;
## once dismissed, collapses to zero area so >=82% open map ratio is preserved.

signal toast_activated(toast_id: StringName, focus_coord: Vector2i, target_drawer_slot: StringName)
signal toast_dismissed(toast_id: StringName)

const MAX_VISIBLE_TOASTS: int = 4


class ToastRecord:
	extends RefCounted
	var toast_id: StringName = &""
	var title: String = ""
	var detail: String = ""
	var tone_id: StringName = &"gold"
	var focus_coord: Vector2i = Vector2i.ZERO
	var target_drawer_slot: StringName = &""
	var remaining_sec: float = 6.5
	var card: TamgaCardPanel = null
	var close_btn: Button = null
	var card_cb: Callable = Callable()
	var close_cb: Callable = Callable()


var _records: Array[ToastRecord] = []
var _seq: int = 0


func _init() -> void:
	name = "AlertToastStack"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(264.0, 0.0)
	add_theme_constant_override(&"separation", 5)
	visible = false


func _ready() -> void:
	set_process(true)


func _exit_tree() -> void:
	clear_all_toasts()


func _process(delta: float) -> void:
	step_lifetimes(delta)


func step_lifetimes(delta: float) -> void:
	if _records.is_empty():
		return
	var dt: float = maxf(delta, 0.0)
	var expired: Array[StringName] = []
	for rec: ToastRecord in _records:
		if rec == null:
			continue
		if rec.remaining_sec > 0.0:
			rec.remaining_sec -= dt
			if rec.remaining_sec <= 0.0:
				expired.append(rec.toast_id)
	for tid: StringName in expired:
		dismiss_toast(tid)


func push_toast(
		title: String,
		detail: String,
		tone_id: StringName = &"gold",
		focus_coord: Vector2i = Vector2i.ZERO,
		target_drawer_slot: StringName = &"",
		auto_dismiss_sec: float = 6.5) -> StringName:
	_seq += 1
	var tid: StringName = StringName("toast_%d" % _seq)

	while _records.size() >= MAX_VISIBLE_TOASTS:
		var oldest: ToastRecord = _records[0]
		if oldest != null:
			dismiss_toast(oldest.toast_id)
		else:
			_records.remove_at(0)

	var rec: ToastRecord = ToastRecord.new()
	rec.toast_id = tid
	rec.title = title
	rec.detail = detail
	rec.tone_id = tone_id
	rec.focus_coord = focus_coord
	rec.target_drawer_slot = target_drawer_slot
	rec.remaining_sec = auto_dismiss_sec

	var card: TamgaCardPanel = TamgaCardPanel.new()
	card.name = "AlertToastCard_%d" % _seq
	card.card_id = tid
	card.semantic_tone = tone_id
	card.clickable = true
	card.custom_minimum_size = Vector2(260.0, 0.0)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	rec.card_cb = _on_toast_card_clicked.bind(tid)
	card.card_clicked.connect(rec.card_cb)
	add_child(card)
	rec.card = card

	var m: MarginContainer = card.get_content_container()
	m.add_theme_constant_override(&"margin_left", 8)
	m.add_theme_constant_override(&"margin_right", 8)
	m.add_theme_constant_override(&"margin_top", 5)
	m.add_theme_constant_override(&"margin_bottom", 5)

	var v: VBoxContainer = VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override(&"separation", 2)
	m.add_child(v)

	var top_h: HBoxContainer = HBoxContainer.new()
	top_h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_h.add_theme_constant_override(&"separation", 4)
	v.add_child(top_h)

	var title_lbl: Label = Label.new()
	title_lbl.theme_type_variation = &"CaptionLabel"
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.clip_text = true
	title_lbl.text = title
	title_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.get_semantic_color(tone_id))
	top_h.add_child(title_lbl)

	var close_btn: Button = Button.new()
	close_btn.name = "CloseToast_%d" % _seq
	close_btn.theme_type_variation = &"GhostIconButton"
	close_btn.text = "✕"
	close_btn.add_theme_font_size_override(&"font_size", 9)
	OtukenThemeFactory.apply_button_semantic_styles(close_btn, NeoSteppePalette.BRONZE_WEATHERED, false, 4, 0)
	rec.close_cb = dismiss_toast.bind(tid)
	close_btn.pressed.connect(rec.close_cb)
	top_h.add_child(close_btn)
	rec.close_btn = close_btn

	var detail_lbl: Label = Label.new()
	detail_lbl.theme_type_variation = &"MutedLabel"
	detail_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_lbl.add_theme_font_size_override(&"font_size", 10)
	detail_lbl.text = detail
	v.add_child(detail_lbl)

	_records.append(rec)
	visible = true
	return tid


func dismiss_toast(toast_id: StringName) -> bool:
	for i: int in range(_records.size()):
		var rec: ToastRecord = _records[i]
		if rec != null and rec.toast_id == toast_id:
			_free_record(rec)
			_records.remove_at(i)
			visible = not _records.is_empty()
			toast_dismissed.emit(toast_id)
			return true
	return false


func clear_all_toasts() -> void:
	for rec: ToastRecord in _records:
		_free_record(rec)
	_records.clear()
	visible = false


func activate_toast(toast_id: StringName) -> bool:
	for rec: ToastRecord in _records:
		if rec != null and rec.toast_id == toast_id:
			toast_activated.emit(rec.toast_id, rec.focus_coord, rec.target_drawer_slot)
			return true
	return false


func get_active_toast_count() -> int:
	return _records.size()


func get_latest_toast_id() -> StringName:
	if _records.is_empty():
		return &""
	var last_rec: ToastRecord = _records[_records.size() - 1]
	return last_rec.toast_id if last_rec != null else &""


func _on_toast_card_clicked(_card_id: StringName, tid: StringName) -> void:
	activate_toast(tid)


func _free_record(rec: ToastRecord) -> void:
	if rec == null:
		return
	if rec.close_btn != null and is_instance_valid(rec.close_btn) and rec.close_cb.is_valid():
		if rec.close_btn.pressed.is_connected(rec.close_cb):
			rec.close_btn.pressed.disconnect(rec.close_cb)
	if rec.card != null and is_instance_valid(rec.card) and rec.card_cb.is_valid():
		if rec.card.card_clicked.is_connected(rec.card_cb):
			rec.card.card_clicked.disconnect(rec.card_cb)
		if rec.card.get_parent() != null:
			rec.card.get_parent().remove_child(rec.card)
		rec.card.queue_free()
