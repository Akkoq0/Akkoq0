class_name TutorialOverlay
extends TamgaCardPanel
## Non-blocking Compact Tutorial Banner (rank 4).
## Docks at top-center below the pulse bar so the 3D map stays >=80% open.

signal tutorial_completed()

var _director: TutorialDirector = null
var _title_lbl: Label = null
var _body_lbl: Label = null
var _next_btn: Button = null
var _skip_btn: Button = null
var _built: bool = false


func _init() -> void:
	name = "TutorialOverlay"
	card_id = &"tutorial_overlay"
	semantic_tone = &"gold"
	clickable = false
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_CENTER_TOP)
	offset_left = -240.0
	offset_top = 86.0
	offset_right = 240.0
	offset_bottom = 204.0


func _ready() -> void:
	_ensure_built()


func _exit_tree() -> void:
	if EventBus.world_layer_changed.is_connected(_on_layer_changed):
		EventBus.world_layer_changed.disconnect(_on_layer_changed)
	if EventBus.army_move_ordered.is_connected(_on_army_move_ordered):
		EventBus.army_move_ordered.disconnect(_on_army_move_ordered)


func bind_director(director: TutorialDirector) -> void:
	_director = director
	_ensure_built()
	if _director == null:
		return
	if not _director.step_changed.is_connected(_on_step_changed):
		_director.step_changed.connect(_on_step_changed)
	if not _director.tutorial_finished.is_connected(_on_tutorial_finished):
		_director.tutorial_finished.connect(_on_tutorial_finished)
	if not EventBus.world_layer_changed.is_connected(_on_layer_changed):
		EventBus.world_layer_changed.connect(_on_layer_changed)
	if not EventBus.army_move_ordered.is_connected(_on_army_move_ordered):
		EventBus.army_move_ordered.connect(_on_army_move_ordered)


func start_guided_tour() -> void:
	if _director == null:
		bind_director(TutorialDirector.new())
	visible = true
	_director.start_tutorial()


func _ensure_built() -> void:
	if _built:
		return
	_built = true

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 14.0
	vbox.offset_top = 10.0
	vbox.offset_right = -14.0
	vbox.offset_bottom = -10.0
	vbox.add_theme_constant_override(&"separation", 6)
	add_child(vbox)

	_title_lbl = Label.new()
	_title_lbl.add_theme_font_size_override(&"font_size", 15)
	_title_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.GOLD_PALE)
	vbox.add_child(_title_lbl)

	_body_lbl = Label.new()
	_body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_lbl.add_theme_font_size_override(&"font_size", 13)
	_body_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_body_lbl)

	var btn_row: HBoxContainer = HBoxContainer.new()
	btn_row.add_theme_constant_override(&"separation", 8)
	vbox.add_child(btn_row)

	_skip_btn = Button.new()
	_skip_btn.text = "Atla"
	_skip_btn.custom_minimum_size = Vector2(88.0, 34.0)
	OtukenThemeFactory.apply_button_semantic_styles(_skip_btn, NeoSteppePalette.BRONZE_WEATHERED, false, 8, 4)
	_skip_btn.pressed.connect(_on_skip_pressed)
	btn_row.add_child(_skip_btn)

	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_row.add_child(spacer)

	_next_btn = Button.new()
	_next_btn.text = "Devam →"
	_next_btn.custom_minimum_size = Vector2(110.0, 34.0)
	OtukenThemeFactory.apply_button_semantic_styles(_next_btn, NeoSteppePalette.JADE_PRIMARY, true, 8, 4)
	_next_btn.pressed.connect(_on_next_pressed)
	btn_row.add_child(_next_btn)


func _on_step_changed(_idx: int, step_data: TutorialDirector.TutorialStep) -> void:
	if step_data == null:
		return
	var is_touch: bool = DisplayServer.is_touchscreen_available()
	_title_lbl.text = step_data.title
	_body_lbl.text = step_data.get_body(is_touch)
	_next_btn.text = "Bitir" if _director != null and _director.get_current_index() == _director.get_step_count() - 1 else "Devam →"
	visible = true


func _on_tutorial_finished(_was_skipped: bool) -> void:
	visible = false
	tutorial_completed.emit()


func _on_next_pressed() -> void:
	if _director != null:
		_director.advance_step()


func _on_skip_pressed() -> void:
	if _director != null:
		_director.skip_tutorial()


func _on_layer_changed(_prev: GameEnums.WorldLayer, _target: GameEnums.WorldLayer) -> void:
	if _director != null:
		_director.notify_action(&"layer_switch")


func _on_army_move_ordered(_army_id: int, _dest: Vector3) -> void:
	if _director != null:
		_director.notify_action(&"move_order")
