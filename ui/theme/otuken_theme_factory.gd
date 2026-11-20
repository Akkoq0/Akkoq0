class_name OtukenThemeFactory
extends RefCounted
## UI Presentation (rank 4). Builds the unified "Bozkır Modernizmi" Godot Theme,
## StyleBoxFlat button/panel styles, typography hierarchy variations, and
## CanvasItem ShaderMaterials so zero bare default Godot controls appear.

const CARD_SHADER_PATH: String = "res://ui/theme/neo_steppe_card.gdshader"
const PILL_SHADER_PATH: String = "res://ui/theme/neo_steppe_status_pill.gdshader"

static var _cached_card_shader: Shader = null
static var _cached_pill_shader: Shader = null


static func load_card_shader() -> Shader:
	if _cached_card_shader == null:
		_cached_card_shader = ResourceLoader.load(CARD_SHADER_PATH) as Shader
	return _cached_card_shader


static func load_pill_shader() -> Shader:
	if _cached_pill_shader == null:
		_cached_pill_shader = ResourceLoader.load(PILL_SHADER_PATH) as Shader
	return _cached_pill_shader


static func create_card_shader_material(
		accent_color: Color = NeoSteppePalette.JADE_PRIMARY,
		panel_size: Vector2 = Vector2(240.0, 56.0),
		alert_pulse: float = 0.0) -> ShaderMaterial:
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = load_card_shader()
	mat.set_shader_parameter(&"base_obsidian_color", NeoSteppePalette.OBSIDIAN_DEEP)
	mat.set_shader_parameter(&"charcoal_top_color", NeoSteppePalette.CHARCOAL_SURFACE)
	mat.set_shader_parameter(&"bronze_border_color", NeoSteppePalette.BRONZE_WEATHERED)
	mat.set_shader_parameter(&"semantic_accent_color", accent_color)
	mat.set_shader_parameter(&"border_px", 1.5)
	mat.set_shader_parameter(&"tamga_corner_len", NeoSteppePalette.TAMGA_CORNER_LENGTH)
	mat.set_shader_parameter(&"glass_sheen", 0.22)
	mat.set_shader_parameter(&"accent_glow", 0.28)
	mat.set_shader_parameter(&"alert_pulse", clampf(alert_pulse, 0.0, 1.0))
	mat.set_shader_parameter(&"panel_size", panel_size)
	return mat


static func create_pill_shader_material(
		accent_color: Color = NeoSteppePalette.GOLD_TAMGA,
		pill_size: Vector2 = Vector2(140.0, 34.0),
		active_weight: float = 0.0,
		urgent_pulse: float = 0.0) -> ShaderMaterial:
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = load_pill_shader()
	mat.set_shader_parameter(&"base_fill_color", NeoSteppePalette.OBSIDIAN_GLASS)
	mat.set_shader_parameter(&"accent_rim_color", accent_color)
	mat.set_shader_parameter(&"active_weight", clampf(active_weight, 0.0, 1.0))
	mat.set_shader_parameter(&"urgent_pulse", clampf(urgent_pulse, 0.0, 1.0))
	mat.set_shader_parameter(&"pill_size", pill_size)
	return mat


static func build_card_style(
		border_color: Color = NeoSteppePalette.BRONZE_WEATHERED,
		border_px: int = NeoSteppePalette.BORDER_WIDTH_THIN,
		bg_color: Color = NeoSteppePalette.OBSIDIAN_DEEP,
		pad_x: int = 10,
		pad_y: int = 7) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = bg_color
	box.border_color = border_color
	box.set_border_width_all(clampi(border_px, 1, 3))
	box.set_corner_radius_all(NeoSteppePalette.CORNER_RADIUS_CRISP)
	box.set_content_margin_all(pad_y)
	box.content_margin_left = float(pad_x)
	box.content_margin_right = float(pad_x)
	box.shadow_color = NeoSteppePalette.OBSIDIAN_SHADOW
	box.shadow_size = 4
	box.shadow_offset = Vector2(0.0, 2.0)
	return box


static func build_button_style(
		border_color: Color = NeoSteppePalette.BRONZE_WEATHERED,
		bg_color: Color = NeoSteppePalette.CHARCOAL_SURFACE,
		border_px: int = NeoSteppePalette.BORDER_WIDTH_THIN,
		pad_x: int = 10,
		pad_y: int = 5) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = bg_color
	box.border_color = border_color
	box.set_border_width_all(clampi(border_px, 1, 3))
	box.set_corner_radius_all(NeoSteppePalette.CORNER_RADIUS_PILL)
	box.content_margin_left = float(pad_x)
	box.content_margin_right = float(pad_x)
	box.content_margin_top = float(pad_y)
	box.content_margin_bottom = float(pad_y)
	return box


static func apply_button_semantic_styles(
		button: Button,
		accent_color: Color = NeoSteppePalette.BRONZE_WEATHERED,
		is_active: bool = false,
		pad_x: int = 10,
		pad_y: int = 5) -> void:
	if button == null:
		return
	var normal_border: Color = accent_color if is_active else accent_color.lerp(NeoSteppePalette.BRONZE_DARK, 0.45)
	var normal_bg: Color = accent_color.lerp(NeoSteppePalette.OBSIDIAN_DEEP, 0.78) if is_active else NeoSteppePalette.CHARCOAL_SURFACE
	var hover_bg: Color = accent_color.lerp(NeoSteppePalette.CHARCOAL_ELEVATED, 0.72)
	var pressed_bg: Color = accent_color.lerp(NeoSteppePalette.CHARCOAL_PRESSED, 0.80)
	var border_px: int = NeoSteppePalette.BORDER_WIDTH_EMPHASIS if is_active else NeoSteppePalette.BORDER_WIDTH_THIN

	button.add_theme_stylebox_override(&"normal", build_button_style(normal_border, normal_bg, border_px, pad_x, pad_y))
	button.add_theme_stylebox_override(&"hover", build_button_style(accent_color, hover_bg, NeoSteppePalette.BORDER_WIDTH_EMPHASIS, pad_x, pad_y))
	button.add_theme_stylebox_override(&"pressed", build_button_style(NeoSteppePalette.GOLD_TAMGA, pressed_bg, NeoSteppePalette.BORDER_WIDTH_EMPHASIS, pad_x, pad_y))
	button.add_theme_stylebox_override(&"focus", build_button_style(NeoSteppePalette.GOLD_TAMGA, hover_bg, NeoSteppePalette.BORDER_WIDTH_EMPHASIS, pad_x, pad_y))
	button.add_theme_stylebox_override(&"disabled", build_button_style(NeoSteppePalette.BRONZE_DARK, NeoSteppePalette.CHARCOAL_PRESSED, 1, pad_x, pad_y))
	button.add_theme_color_override(&"font_color", NeoSteppePalette.GOLD_PALE if is_active else NeoSteppePalette.TEXT_PRIMARY)
	button.add_theme_color_override(&"font_hover_color", NeoSteppePalette.GOLD_PALE)
	button.add_theme_color_override(&"font_pressed_color", NeoSteppePalette.TEXT_PRIMARY)
	button.add_theme_color_override(&"font_focus_color", NeoSteppePalette.GOLD_PALE)
	button.add_theme_color_override(&"font_disabled_color", NeoSteppePalette.TEXT_MUTED)


static func create_theme() -> Theme:
	var theme: Theme = Theme.new()
	theme.default_font_size = NeoSteppePalette.FONT_SIZE_BODY
	const FONT_PATH: String = "res://assets/fonts/NotoSans-Regular.ttf"
	if ResourceLoader.exists(FONT_PATH):
		var loaded_font: Font = ResourceLoader.load(FONT_PATH) as Font
		if loaded_font != null:
			theme.default_font = loaded_font

	# --- Base Panel / PanelContainer -----------------------------------------
	var base_panel: StyleBoxFlat = build_card_style(NeoSteppePalette.BRONZE_DARK, 1, NeoSteppePalette.OBSIDIAN_DEEP, 10, 8)
	theme.set_stylebox(&"panel", &"Panel", base_panel)
	theme.set_stylebox(&"panel", &"PanelContainer", base_panel)

	var obsidian_card: StyleBoxFlat = build_card_style(NeoSteppePalette.BRONZE_WEATHERED, 1, NeoSteppePalette.OBSIDIAN_GLASS, 10, 6)
	theme.set_type_variation(&"ObsidianCard", &"PanelContainer")
	theme.set_stylebox(&"panel", &"ObsidianCard", obsidian_card)

	var tooltip_card: StyleBoxFlat = build_card_style(NeoSteppePalette.GOLD_TAMGA, 2, NeoSteppePalette.OBSIDIAN_DEEP, 12, 10)
	theme.set_type_variation(&"TooltipCard", &"PanelContainer")
	theme.set_stylebox(&"panel", &"TooltipCard", tooltip_card)

	var drawer_panel: StyleBoxFlat = build_card_style(NeoSteppePalette.BRONZE_WEATHERED, 2, NeoSteppePalette.OBSIDIAN_DEEP, 12, 10)
	theme.set_type_variation(&"DrawerPanel", &"PanelContainer")
	theme.set_stylebox(&"panel", &"DrawerPanel", drawer_panel)

	# --- Buttons (Zero bare Godot buttons!) ----------------------------------
	var btn_normal: StyleBoxFlat = build_button_style(NeoSteppePalette.BRONZE_WEATHERED, NeoSteppePalette.CHARCOAL_SURFACE, 1, 10, 5)
	var btn_hover: StyleBoxFlat = build_button_style(NeoSteppePalette.GOLD_TAMGA, NeoSteppePalette.CHARCOAL_ELEVATED, 2, 10, 5)
	var btn_pressed: StyleBoxFlat = build_button_style(NeoSteppePalette.JADE_PRIMARY, NeoSteppePalette.CHARCOAL_PRESSED, 2, 10, 5)
	var btn_focus: StyleBoxFlat = build_button_style(NeoSteppePalette.GOLD_PALE, NeoSteppePalette.CHARCOAL_ELEVATED, 2, 10, 5)
	var btn_disabled: StyleBoxFlat = build_button_style(NeoSteppePalette.BRONZE_DARK, NeoSteppePalette.CHARCOAL_PRESSED, 1, 10, 5)

	theme.set_stylebox(&"normal", &"Button", btn_normal)
	theme.set_stylebox(&"hover", &"Button", btn_hover)
	theme.set_stylebox(&"pressed", &"Button", btn_pressed)
	theme.set_stylebox(&"focus", &"Button", btn_focus)
	theme.set_stylebox(&"disabled", &"Button", btn_disabled)
	theme.set_color(&"font_color", &"Button", NeoSteppePalette.TEXT_PRIMARY)
	theme.set_color(&"font_hover_color", &"Button", NeoSteppePalette.GOLD_PALE)
	theme.set_color(&"font_pressed_color", &"Button", NeoSteppePalette.TEXT_PRIMARY)
	theme.set_color(&"font_focus_color", &"Button", NeoSteppePalette.GOLD_PALE)
	theme.set_color(&"font_disabled_color", &"Button", NeoSteppePalette.TEXT_MUTED)
	theme.set_font_size(&"font_size", &"Button", NeoSteppePalette.FONT_SIZE_BODY)

	theme.set_type_variation(&"LensButton", &"Button")
	theme.set_stylebox(&"normal", &"LensButton", build_button_style(NeoSteppePalette.BRONZE_DARK, NeoSteppePalette.OBSIDIAN_GLASS, 1, 9, 4))
	theme.set_stylebox(&"hover", &"LensButton", build_button_style(NeoSteppePalette.GOLD_TAMGA, NeoSteppePalette.CHARCOAL_ELEVATED, 2, 9, 4))
	theme.set_stylebox(&"pressed", &"LensButton", build_button_style(NeoSteppePalette.JADE_PRIMARY, NeoSteppePalette.JADE_DARK, 2, 9, 4))
	theme.set_font_size(&"font_size", &"LensButton", NeoSteppePalette.FONT_SIZE_CAPTION)

	theme.set_type_variation(&"SteppeCrisisChip", &"Button")
	theme.set_stylebox(&"normal", &"SteppeCrisisChip", build_button_style(NeoSteppePalette.EMBER_RED, NeoSteppePalette.EMBER_DARK, 2, 10, 5))
	theme.set_stylebox(&"hover", &"SteppeCrisisChip", build_button_style(NeoSteppePalette.EMBER_BRIGHT, NeoSteppePalette.EMBER_DARK, 2, 10, 5))
	theme.set_stylebox(&"pressed", &"SteppeCrisisChip", build_button_style(NeoSteppePalette.GOLD_TAMGA, NeoSteppePalette.CHARCOAL_PRESSED, 2, 10, 5))
	theme.set_font_size(&"font_size", &"SteppeCrisisChip", NeoSteppePalette.FONT_SIZE_CAPTION)

	theme.set_type_variation(&"ActionButton", &"Button")
	theme.set_stylebox(&"normal", &"ActionButton", build_button_style(NeoSteppePalette.BRONZE_WEATHERED, NeoSteppePalette.CHARCOAL_SURFACE, 1, 10, 5))
	theme.set_stylebox(&"hover", &"ActionButton", build_button_style(NeoSteppePalette.JADE_BRIGHT, NeoSteppePalette.JADE_DARK, 2, 10, 5))
	theme.set_font_size(&"font_size", &"ActionButton", NeoSteppePalette.FONT_SIZE_BODY)

	theme.set_type_variation(&"GhostIconButton", &"Button")
	theme.set_stylebox(&"normal", &"GhostIconButton", build_button_style(NeoSteppePalette.BRONZE_DARK, NeoSteppePalette.OBSIDIAN_GLASS, 1, 7, 3))
	theme.set_stylebox(&"hover", &"GhostIconButton", build_button_style(NeoSteppePalette.GOLD_TAMGA, NeoSteppePalette.CHARCOAL_ELEVATED, 1, 7, 3))
	theme.set_font_size(&"font_size", &"GhostIconButton", NeoSteppePalette.FONT_SIZE_CAPTION)

	# --- Typography Hierarchy (Label + Variations) -------------------------
	theme.set_color(&"font_color", &"Label", NeoSteppePalette.TEXT_PRIMARY)
	theme.set_font_size(&"font_size", &"Label", NeoSteppePalette.FONT_SIZE_BODY)

	theme.set_type_variation(&"DisplayLabel", &"Label")
	theme.set_color(&"font_color", &"DisplayLabel", NeoSteppePalette.GOLD_PALE)
	theme.set_font_size(&"font_size", &"DisplayLabel", NeoSteppePalette.FONT_SIZE_DISPLAY)

	theme.set_type_variation(&"TitleLabel", &"Label")
	theme.set_color(&"font_color", &"TitleLabel", NeoSteppePalette.GOLD_TAMGA)
	theme.set_font_size(&"font_size", &"TitleLabel", NeoSteppePalette.FONT_SIZE_TITLE)

	theme.set_type_variation(&"MetricLabel", &"Label")
	theme.set_color(&"font_color", &"MetricLabel", NeoSteppePalette.TEXT_PRIMARY)
	theme.set_font_size(&"font_size", &"MetricLabel", NeoSteppePalette.FONT_SIZE_METRIC)

	theme.set_type_variation(&"CaptionLabel", &"Label")
	theme.set_color(&"font_color", &"CaptionLabel", NeoSteppePalette.BRONZE_WEATHERED)
	theme.set_font_size(&"font_size", &"CaptionLabel", NeoSteppePalette.FONT_SIZE_CAPTION)

	theme.set_type_variation(&"MutedLabel", &"Label")
	theme.set_color(&"font_color", &"MutedLabel", NeoSteppePalette.TEXT_SECONDARY)
	theme.set_font_size(&"font_size", &"MutedLabel", NeoSteppePalette.FONT_SIZE_CAPTION)

	# --- Separators & Progress -----------------------------------------------
	var sep_line: StyleBoxLine = StyleBoxLine.new()
	sep_line.color = NeoSteppePalette.BRONZE_DARK
	sep_line.thickness = 1
	theme.set_stylebox(&"separator", &"HSeparator", sep_line)

	var vsep_line: StyleBoxLine = StyleBoxLine.new()
	vsep_line.color = NeoSteppePalette.BRONZE_DARK
	vsep_line.thickness = 1
	vsep_line.vertical = true
	theme.set_stylebox(&"separator", &"VSeparator", vsep_line)

	var prog_bg: StyleBoxFlat = build_button_style(NeoSteppePalette.BRONZE_DARK, NeoSteppePalette.CHARCOAL_PRESSED, 1, 0, 0)
	var prog_fill: StyleBoxFlat = build_button_style(NeoSteppePalette.JADE_BRIGHT, NeoSteppePalette.JADE_PRIMARY, 0, 0, 0)
	theme.set_stylebox(&"background", &"ProgressBar", prog_bg)
	theme.set_stylebox(&"fill", &"ProgressBar", prog_fill)

	return theme
