class_name TamgaCardPanel
extends PanelContainer
## UI Component (rank 4). Frosted Obsidian & Weathered Bronze card container
## backed by `neo_steppe_card.gdshader` plus crisp 1-2px geometric Tamga
## corner brackets and semantic Yeşim / Buz Mavisi / Köz Kızılı accents.

signal card_clicked(card_id: StringName)

@export var card_id: StringName = &""
@export var semantic_tone: StringName = &"jade"
@export var clickable: bool = false
@export var show_tamga_corners: bool = true

var _accent_color: Color = NeoSteppePalette.JADE_PRIMARY
var _alert_pulse: float = 0.0
var _is_hovered: bool = false
var _is_selected: bool = false
var _shader_backdrop: ColorRect = null
var _shader_material: ShaderMaterial = null
var _content_margin: MarginContainer = null


func _init() -> void:
	theme_type_variation = &"ObsidianCard"
	add_theme_stylebox_override(&"panel", _build_transparent_frame())


func _ready() -> void:
	_ensure_visual_layers()
	_sync_styles()
	if not resized.is_connected(_on_resized):
		resized.connect(_on_resized)
	if not mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)
	if not mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.connect(_on_mouse_exited)


func _exit_tree() -> void:
	if resized.is_connected(_on_resized):
		resized.disconnect(_on_resized)
	if mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.disconnect(_on_mouse_entered)
	if mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.disconnect(_on_mouse_exited)


func _gui_input(event: InputEvent) -> void:
	if not clickable:
		return
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if mb != null and mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
		card_clicked.emit(card_id)
		accept_event()


func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	if w <= 4.0 or h <= 4.0:
		return
	var outer_color: Color = _accent_color if (_is_hovered or _is_selected) else NeoSteppePalette.BRONZE_DARK
	draw_rect(Rect2(Vector2.ZERO, size), outer_color, false, 1.0)
	if not show_tamga_corners:
		return

	var bracket_color: Color = NeoSteppePalette.GOLD_TAMGA if (_is_hovered or _is_selected) else NeoSteppePalette.BRONZE_WEATHERED
	var corner_len: float = minf(NeoSteppePalette.TAMGA_CORNER_LENGTH, minf(w, h) * 0.28)
	var pad: float = 1.0
	# Top-left L-Tamga
	draw_line(Vector2(pad, pad), Vector2(pad + corner_len, pad), bracket_color, 2.0)
	draw_line(Vector2(pad, pad), Vector2(pad, pad + corner_len), bracket_color, 2.0)
	# Top-right L-Tamga
	draw_line(Vector2(w - pad - corner_len, pad), Vector2(w - pad, pad), bracket_color, 2.0)
	draw_line(Vector2(w - pad, pad), Vector2(w - pad, pad + corner_len), bracket_color, 2.0)
	# Bottom-left L-Tamga
	draw_line(Vector2(pad, h - pad), Vector2(pad + corner_len, h - pad), bracket_color, 2.0)
	draw_line(Vector2(pad, h - pad - corner_len), Vector2(pad, h - pad), bracket_color, 2.0)
	# Bottom-right L-Tamga
	draw_line(Vector2(w - pad - corner_len, h - pad), Vector2(w - pad, h - pad), bracket_color, 2.0)
	draw_line(Vector2(w - pad, h - pad - corner_len), Vector2(w - pad, h - pad), bracket_color, 2.0)

	# Top center geometric Tamga diamond accent
	var mid_x: float = w * 0.5
	var notch_half: float = 10.0
	draw_line(Vector2(mid_x - notch_half, 1.5), Vector2(mid_x + notch_half, 1.5), _accent_color, 2.0)


func set_semantic_tone(tone_id: StringName, alert_pulse: float = 0.0) -> void:
	semantic_tone = tone_id
	_accent_color = NeoSteppePalette.get_semantic_color(tone_id)
	_alert_pulse = clampf(alert_pulse, 0.0, 1.0)
	_sync_styles()


func set_selected(selected: bool) -> void:
	_is_selected = selected
	_sync_styles()


func is_selected() -> bool:
	return _is_selected


func get_semantic_color() -> Color:
	return _accent_color


func get_shader_material() -> ShaderMaterial:
	_ensure_visual_layers()
	return _shader_material


func get_content_container() -> MarginContainer:
	_ensure_visual_layers()
	return _content_margin


func _ensure_visual_layers() -> void:
	if _shader_backdrop == null:
		_shader_backdrop = ColorRect.new()
		_shader_backdrop.name = "ShaderBackdrop"
		_shader_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_shader_backdrop.show_behind_parent = true
		_shader_backdrop.color = Color.WHITE
		_shader_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_shader_material = OtukenThemeFactory.create_card_shader_material(_accent_color, Vector2(240.0, 56.0), _alert_pulse)
		_shader_backdrop.material = _shader_material
		add_child(_shader_backdrop)
		move_child(_shader_backdrop, 0)
	if _content_margin == null:
		_content_margin = MarginContainer.new()
		_content_margin.name = "CardMargin"
		_content_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_content_margin.add_theme_constant_override(&"margin_left", 10)
		_content_margin.add_theme_constant_override(&"margin_right", 10)
		_content_margin.add_theme_constant_override(&"margin_top", 6)
		_content_margin.add_theme_constant_override(&"margin_bottom", 6)
		add_child(_content_margin)


func _sync_styles() -> void:
	_accent_color = NeoSteppePalette.get_semantic_color(semantic_tone)
	if _shader_material != null:
		_shader_material.set_shader_parameter(&"semantic_accent_color", _accent_color)
		_shader_material.set_shader_parameter(&"alert_pulse", _alert_pulse)
		_shader_material.set_shader_parameter(&"accent_glow", 0.48 if (_is_hovered or _is_selected) else 0.24)
		_shader_material.set_shader_parameter(&"panel_size", size.max(Vector2(24.0, 24.0)))
	queue_redraw()


func _build_transparent_frame() -> StyleBoxEmpty:
	return StyleBoxEmpty.new()


func _on_resized() -> void:
	if _shader_material != null:
		_shader_material.set_shader_parameter(&"panel_size", size.max(Vector2(24.0, 24.0)))
	queue_redraw()


func _on_mouse_entered() -> void:
	_is_hovered = true
	_sync_styles()


func _on_mouse_exited() -> void:
	_is_hovered = false
	_sync_styles()
