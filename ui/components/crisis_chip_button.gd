class_name CrisisChipButton
extends Button
## UI Component (rank 4). Interactive right-edge emergency crisis chip rendered
## with the Bozkır Modernizmi status pill shader and crisp bronze/ember framing.

signal crisis_chip_activated(crisis_id: StringName, target_drawer_slot: StringName, glossary_term: StringName)

var crisis_id: StringName = &""
var target_drawer_slot: StringName = OtukenHudViewModel.SLOT_ECONOMY_WATER
var glossary_term: StringName = &"kut"
var tone_id: StringName = &"ember"

var _shader_fill: ColorRect = null
var _shader_mat: ShaderMaterial = null


func _init() -> void:
	theme_type_variation = &"SteppeCrisisChip"
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	custom_minimum_size = Vector2(204.0, 34.0)
	clip_text = true


func _ready() -> void:
	_ensure_shader_layer()
	_sync_visuals()
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)
	if not resized.is_connected(_on_resized):
		resized.connect(_on_resized)


func _exit_tree() -> void:
	if pressed.is_connected(_on_pressed):
		pressed.disconnect(_on_pressed)
	if resized.is_connected(_on_resized):
		resized.disconnect(_on_resized)


func configure_crisis(descriptor: OtukenHudViewModel.CrisisChipDescriptor) -> void:
	if descriptor == null:
		return
	crisis_id = descriptor.crisis_id
	target_drawer_slot = descriptor.target_drawer_slot
	glossary_term = descriptor.glossary_term
	tone_id = descriptor.tone_id
	text = "%s\n%s" % [descriptor.title, descriptor.detail]
	_ensure_shader_layer()
	_sync_visuals()


func get_shader_material() -> ShaderMaterial:
	_ensure_shader_layer()
	return _shader_mat


func _ensure_shader_layer() -> void:
	if _shader_fill != null:
		return
	_shader_fill = ColorRect.new()
	_shader_fill.name = "CrisisPillShader"
	_shader_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shader_fill.show_behind_parent = true
	_shader_fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var accent: Color = NeoSteppePalette.get_semantic_color(tone_id)
	_shader_mat = OtukenThemeFactory.create_pill_shader_material(accent, Vector2(204.0, 34.0), 0.7, 1.0)
	_shader_fill.material = _shader_mat
	add_child(_shader_fill)


func _sync_visuals() -> void:
	var accent: Color = NeoSteppePalette.get_semantic_color(tone_id)
	OtukenThemeFactory.apply_button_semantic_styles(self, accent, true, 10, 4)
	add_theme_font_size_override(&"font_size", NeoSteppePalette.FONT_SIZE_CAPTION)
	if _shader_mat != null:
		_shader_mat.set_shader_parameter(&"accent_rim_color", accent)
		_shader_mat.set_shader_parameter(&"pill_size", size.max(Vector2(60.0, 28.0)))


func _on_pressed() -> void:
	crisis_chip_activated.emit(crisis_id, target_drawer_slot, glossary_term)


func _on_resized() -> void:
	if _shader_mat != null:
		_shader_mat.set_shader_parameter(&"pill_size", size.max(Vector2(60.0, 28.0)))
