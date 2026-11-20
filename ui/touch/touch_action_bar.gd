class_name TouchActionBar
extends HBoxContainer
## Thumb-reachable bottom-right touch action bar (rank 4) for mobile play.
## Provides >=48px touch targets for Layer Toggle, Lens Cycle, and Pause/Menu.

signal pause_requested()
signal layer_toggled(target_layer: GameEnums.WorldLayer)
signal lens_cycled(next_lens: GameEnums.TacticalMapLens)

var _layer_btn: Button = null
var _lens_btn: Button = null
var _pause_btn: Button = null
var _current_lens_idx: int = 0
var _forced_visible: bool = false


func _init() -> void:
	name = "TouchActionBar"
	set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	offset_left = -330.0
	offset_top = -68.0
	offset_right = -16.0
	offset_bottom = -14.0
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_theme_constant_override(&"separation", 10)
	mouse_filter = Control.MOUSE_FILTER_PASS


func _ready() -> void:
	_build_buttons()
	refresh_visibility(false)


func _exit_tree() -> void:
	if _layer_btn != null and is_instance_valid(_layer_btn) and _layer_btn.pressed.is_connected(_on_layer_pressed):
		_layer_btn.pressed.disconnect(_on_layer_pressed)
	if _lens_btn != null and is_instance_valid(_lens_btn) and _lens_btn.pressed.is_connected(_on_lens_pressed):
		_lens_btn.pressed.disconnect(_on_lens_pressed)
	if _pause_btn != null and is_instance_valid(_pause_btn) and _pause_btn.pressed.is_connected(_on_pause_pressed):
		_pause_btn.pressed.disconnect(_on_pause_pressed)


func refresh_visibility(touch_setting_enabled: bool) -> void:
	_forced_visible = touch_setting_enabled
	visible = _forced_visible or DisplayServer.is_touchscreen_available()


func _build_buttons() -> void:
	if _layer_btn != null:
		return
	_layer_btn = _make_touch_btn("Katman", NeoSteppePalette.ICE_BLUE, _on_layer_pressed)
	_lens_btn = _make_touch_btn("Mercek", NeoSteppePalette.GOLD_TAMGA, _on_lens_pressed)
	_pause_btn = _make_touch_btn("Menü", NeoSteppePalette.BRONZE_WEATHERED, _on_pause_pressed)
	add_child(_layer_btn)
	add_child(_lens_btn)
	add_child(_pause_btn)


func _make_touch_btn(label_text: String, tone: Color, cb: Callable) -> Button:
	var btn: Button = Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(96.0, 48.0)
	btn.theme_type_variation = &"GhostIconButton"
	OtukenThemeFactory.apply_button_semantic_styles(btn, tone, false, 12, 8)
	btn.pressed.connect(cb)
	return btn


func _on_layer_pressed() -> void:
	var current: GameEnums.WorldLayer = GameManager.get_world_layer()
	var target: GameEnums.WorldLayer = GameEnums.WorldLayer.MICRO \
		if current == GameEnums.WorldLayer.MACRO else GameEnums.WorldLayer.MACRO
	CommandBus.dispatch(SwitchLayerCommand.new(target))
	layer_toggled.emit(target)


func _on_lens_pressed() -> void:
	var lenses: Array[GameEnums.TacticalMapLens] = [
		GameEnums.TacticalMapLens.NORMAL,
		GameEnums.TacticalMapLens.LOGISTICS_WATER_COURIER,
		GameEnums.TacticalMapLens.YAYLAK_KISLAK,
		GameEnums.TacticalMapLens.TUG_CONTROL,
		GameEnums.TacticalMapLens.INTELLIGENCE_DUST,
	]
	var prev_lens: GameEnums.TacticalMapLens = lenses[_current_lens_idx]
	_current_lens_idx = (_current_lens_idx + 1) % lenses.size()
	var next_lens: GameEnums.TacticalMapLens = lenses[_current_lens_idx]
	EventBus.tactical_lens_changed.emit(prev_lens, next_lens)
	lens_cycled.emit(next_lens)


func _on_pause_pressed() -> void:
	pause_requested.emit()
