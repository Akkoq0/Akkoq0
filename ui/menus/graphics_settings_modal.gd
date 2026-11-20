class_name GraphicsSettingsModal
extends Control
## Unified Mobile Graphics & Audio Settings Modal (rank 4).
## Persists to `user://graphics_settings.cfg` and applies instantly to the
## active scene without restarting.

signal closed()

var _built: bool = false
var _cfg: GraphicsQualityApplier.GraphicsConfigData = null

var _profile_btns: Array[Button] = []
var _res_btn: Button = null
var _shadow_btn: Button = null
var _foliage_btn: Button = null
var _fog_btn: Button = null
var _fps_cap_btn: Button = null
var _fps_counter_btn: Button = null
var _master_slider: HSlider = null
var _music_slider: HSlider = null
var _sfx_slider: HSlider = null
var _status_lbl: Label = null


func _init() -> void:
	name = "GraphicsSettingsModal"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false


func _ready() -> void:
	_ensure_built()


func open_modal() -> void:
	_ensure_built()
	_cfg = GraphicsQualityApplier.load_graphics_settings()
	_sync_ui()
	visible = true


func close_modal() -> void:
	visible = false
	closed.emit()


func _ensure_built() -> void:
	if _built:
		return
	_built = true

	var dim: ColorRect = ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.025, 0.032, 0.78)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var card: TamgaCardPanel = TamgaCardPanel.new()
	card.semantic_tone = &"gold"
	card.clickable = false
	card.custom_minimum_size = Vector2(620.0, 520.0)
	center.add_child(card)

	var margin: MarginContainer = card.get_content_container()
	margin.add_theme_constant_override(&"margin_left", 20)
	margin.add_theme_constant_override(&"margin_right", 20)
	margin.add_theme_constant_override(&"margin_top", 16)
	margin.add_theme_constant_override(&"margin_bottom", 16)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override(&"separation", 8)
	scroll.add_child(vbox)

	var hdr: HBoxContainer = HBoxContainer.new()
	vbox.add_child(hdr)

	var title_lbl: Label = Label.new()
	title_lbl.text = "GRAFİK & SES AYARLARI"
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.add_theme_font_size_override(&"font_size", 20)
	title_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.GOLD_TAMGA)
	hdr.add_child(title_lbl)

	var close_btn: Button = Button.new()
	close_btn.text = "Kapat"
	close_btn.custom_minimum_size = Vector2(90.0, 40.0)
	OtukenThemeFactory.apply_button_semantic_styles(close_btn, NeoSteppePalette.BRONZE_WEATHERED, false, 10, 4)
	close_btn.pressed.connect(close_modal)
	hdr.add_child(close_btn)

	var prof_lbl: Label = Label.new()
	prof_lbl.text = "Hazır Mobil Profiller:"
	prof_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.TEXT_MUTED)
	vbox.add_child(prof_lbl)

	var prof_grid: GridContainer = GridContainer.new()
	prof_grid.columns = 2
	prof_grid.add_theme_constant_override(&"h_separation", 8)
	prof_grid.add_theme_constant_override(&"v_separation", 8)
	vbox.add_child(prof_grid)

	_profile_btns.clear()
	for i: int in range(GraphicsQualityApplier.PROFILE_NAMES.size()):
		var pb: Button = Button.new()
		pb.text = GraphicsQualityApplier.PROFILE_NAMES[i]
		pb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pb.custom_minimum_size = Vector2(240.0, 44.0)
		pb.pressed.connect(_on_preset_selected.bind(i))
		prof_grid.add_child(pb)
		_profile_btns.append(pb)

	var fine_lbl: Label = Label.new()
	fine_lbl.text = "İnce Ayarlar (Anında Uygulanır):"
	fine_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.TEXT_MUTED)
	vbox.add_child(fine_lbl)

	var fine_grid: GridContainer = GridContainer.new()
	fine_grid.columns = 2
	fine_grid.add_theme_constant_override(&"h_separation", 8)
	fine_grid.add_theme_constant_override(&"v_separation", 8)
	vbox.add_child(fine_grid)

	_res_btn = _make_cycle_btn(_on_cycle_resolution)
	fine_grid.add_child(_res_btn)
	_shadow_btn = _make_cycle_btn(_on_cycle_shadow)
	fine_grid.add_child(_shadow_btn)
	_foliage_btn = _make_cycle_btn(_on_cycle_foliage)
	fine_grid.add_child(_foliage_btn)
	_fog_btn = _make_cycle_btn(_on_toggle_fog)
	fine_grid.add_child(_fog_btn)
	_fps_cap_btn = _make_cycle_btn(_on_toggle_fps_cap)
	fine_grid.add_child(_fps_cap_btn)
	_fps_counter_btn = _make_cycle_btn(_on_toggle_fps_counter)
	fine_grid.add_child(_fps_counter_btn)

	var audio_lbl: Label = Label.new()
	audio_lbl.text = "Ses Düzeyleri (Oyun İçi Müzik ve Efektler):"
	audio_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.TEXT_MUTED)
	vbox.add_child(audio_lbl)

	_master_slider = _add_audio_row(vbox, "Ana Ses", 0.85)
	_music_slider = _add_audio_row(vbox, "Müzik", 0.70)
	_sfx_slider = _add_audio_row(vbox, "Efektler", 0.90)

	_status_lbl = Label.new()
	_status_lbl.text = ""
	_status_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.JADE_BRIGHT)
	vbox.add_child(_status_lbl)

	_cfg = GraphicsQualityApplier.load_graphics_settings()
	_sync_ui()


func _make_cycle_btn(cb: Callable) -> Button:
	var btn: Button = Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(240.0, 44.0)
	OtukenThemeFactory.apply_button_semantic_styles(btn, NeoSteppePalette.ICE_BLUE, false, 10, 4)
	btn.pressed.connect(cb)
	return btn


func _add_audio_row(parent_box: VBoxContainer, label_txt: String, initial_val: float) -> HSlider:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 10)
	parent_box.add_child(row)
	var lbl: Label = Label.new()
	lbl.text = label_txt
	lbl.custom_minimum_size = Vector2(96.0, 0.0)
	row.add_child(lbl)
	var sl: HSlider = HSlider.new()
	sl.min_value = 0.0
	sl.max_value = 1.0
	sl.step = 0.05
	sl.value = initial_val
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sl.custom_minimum_size = Vector2(180.0, 28.0)
	sl.value_changed.connect(_on_audio_changed)
	row.add_child(sl)
	return sl


func _sync_ui() -> void:
	if _cfg == null:
		_cfg = GraphicsQualityApplier.load_graphics_settings()
	var prof_idx: int = _cfg.profile_index
	for i: int in range(_profile_btns.size()):
		var active: bool = i == prof_idx
		var tone: Color = NeoSteppePalette.GOLD_TAMGA if active else NeoSteppePalette.BRONZE_WEATHERED
		OtukenThemeFactory.apply_button_semantic_styles(_profile_btns[i], tone, active, 10, 4)

	var res_pct: int = int(roundf(_cfg.resolution_scale * 100.0))
	_res_btn.text = "Çözünürlük Ölçeği: %%%d" % res_pct

	var shadow_names: Array[String] = ["Kapalı", "Düşük", "Orta", "Yüksek"]
	var sq: int = clampi(_cfg.shadow_quality, 0, 3)
	_shadow_btn.text = "Gölge Kalitesi: %s" % shadow_names[sq]

	var fol_pct: int = int(roundf(_cfg.foliage_density * 100.0))
	_foliage_btn.text = "Bitki & Ağaç Yoğunluğu: %%%d" % fol_pct

	_fog_btn.text = "Atmosferik Sis: %s" % ("Açık" if _cfg.fog_enabled else "Kapalı")
	_fps_cap_btn.text = "FPS Limiti: %d" % _cfg.fps_limit
	_fps_counter_btn.text = "Canlı FPS Sayacı: %s" % ("Açık" if _cfg.show_fps_counter else "Kapalı")


func _apply_and_save(note: String) -> void:
	GraphicsQualityApplier.apply_detailed_settings(get_tree(), _cfg, true)
	_sync_ui()
	_status_lbl.text = note


func _on_preset_selected(idx: int) -> void:
	var keep_fps_counter: bool = _cfg.show_fps_counter if _cfg != null else false
	_cfg = GraphicsQualityApplier.get_preset(idx)
	_cfg.show_fps_counter = keep_fps_counter
	_apply_and_save("Profil uygulandı: %s" % GraphicsQualityApplier.PROFILE_NAMES[idx])


func _on_cycle_resolution() -> void:
	var cur: float = _cfg.resolution_scale
	var next_val: float = 0.60
	for i: int in range(GraphicsQualityApplier.RES_SCALE_STEPS.size()):
		if is_equal_approx(cur, GraphicsQualityApplier.RES_SCALE_STEPS[i]):
			next_val = GraphicsQualityApplier.RES_SCALE_STEPS[(i + 1) % GraphicsQualityApplier.RES_SCALE_STEPS.size()]
			break
	_cfg.profile_index = -1
	_cfg.resolution_scale = next_val
	_apply_and_save("Çözünürlük ölçeği güncellendi.")


func _on_cycle_shadow() -> void:
	_cfg.profile_index = -1
	_cfg.shadow_quality = (_cfg.shadow_quality + 1) % 4
	_apply_and_save("Gölge kalitesi güncellendi.")


func _on_cycle_foliage() -> void:
	var cur: float = _cfg.foliage_density
	var next_val: float = 0.25
	for i: int in range(GraphicsQualityApplier.FOLIAGE_STEPS.size()):
		if is_equal_approx(cur, GraphicsQualityApplier.FOLIAGE_STEPS[i]):
			next_val = GraphicsQualityApplier.FOLIAGE_STEPS[(i + 1) % GraphicsQualityApplier.FOLIAGE_STEPS.size()]
			break
	_cfg.profile_index = -1
	_cfg.foliage_density = next_val
	_apply_and_save("Bitki & ağaç yoğunluğu güncellendi.")


func _on_toggle_fog() -> void:
	_cfg.profile_index = -1
	_cfg.fog_enabled = not _cfg.fog_enabled
	_apply_and_save("Atmosferik sis güncellendi.")


func _on_toggle_fps_cap() -> void:
	_cfg.profile_index = -1
	_cfg.fps_limit = 30 if _cfg.fps_limit >= 60 else 60
	_apply_and_save("FPS limiti güncellendi.")


func _on_toggle_fps_counter() -> void:
	_cfg.show_fps_counter = not _cfg.show_fps_counter
	_apply_and_save("Canlı FPS sayacı güncellendi.")


func _on_audio_changed(_val: float) -> void:
	if AudioDirector != null:
		AudioDirector.apply_volumes(float(_master_slider.value), float(_music_slider.value), float(_sfx_slider.value))
	_status_lbl.text = "Ses ayarları uygulandı."
