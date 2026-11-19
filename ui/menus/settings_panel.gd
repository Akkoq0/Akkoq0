class_name SettingsPanel
extends TamgaCardPanel
## Audio, Graphics Quality, UI Scale, and Touch-Friendly Layout Settings
## Panel (rank 4). Persists through `GameShellViewModel`.

signal settings_applied(settings: GameShellViewModel.UserSettingsSnapshot)
signal panel_closed()

var _vm_ref: WeakRef = null
var _working: GameShellViewModel.UserSettingsSnapshot = GameShellViewModel.UserSettingsSnapshot.new()
var _built: bool = false

var _master_slider: HSlider = null
var _music_slider: HSlider = null
var _sfx_slider: HSlider = null
var _audio_val_lbl: Label = null
var _gfx_btn: Button = null
var _scale_slider: HSlider = null
var _scale_val_lbl: Label = null
var _touch_btn: Button = null
var _status_lbl: Label = null
var _apply_btn: Button = null
var _reset_btn: Button = null
var _close_btn: Button = null

var _btn_callbacks: Dictionary[Button, Callable] = {}
var _slider_callbacks: Dictionary[HSlider, Callable] = {}


func _init() -> void:
	name = "SettingsPanel"
	card_id = &"settings_panel"
	semantic_tone = &"bronze"
	clickable = false
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP


func _ready() -> void:
	_ensure_built()


func _exit_tree() -> void:
	for btn: Button in _btn_callbacks.keys():
		if btn != null and is_instance_valid(btn):
			var cb: Callable = _btn_callbacks[btn]
			if cb.is_valid() and btn.pressed.is_connected(cb):
				btn.pressed.disconnect(cb)
	_btn_callbacks.clear()
	for sl: HSlider in _slider_callbacks.keys():
		if sl != null and is_instance_valid(sl):
			var scb: Callable = _slider_callbacks[sl]
			if scb.is_valid() and sl.value_changed.is_connected(scb):
				sl.value_changed.disconnect(scb)
	_slider_callbacks.clear()


func bind_view_model(vm: GameShellViewModel) -> void:
	_vm_ref = weakref(vm) if vm != null else null
	if vm != null:
		_working = vm.load_user_settings()
	_sync_controls()


func open_settings() -> void:
	_ensure_built()
	var vm: GameShellViewModel = _get_vm()
	if vm != null:
		_working = vm.load_user_settings()
	visible = true
	_sync_controls()


func close_settings() -> void:
	if not visible:
		return
	visible = false
	panel_closed.emit()


func set_working_values(
		master_v: float,
		music_v: float,
		sfx_v: float,
		gfx_q: int,
		ui_s: float,
		touch_on: bool) -> void:
	_ensure_built()
	_working.master_volume = clampf(master_v, 0.0, 1.0)
	_working.music_volume = clampf(music_v, 0.0, 1.0)
	_working.sfx_volume = clampf(sfx_v, 0.0, 1.0)
	_working.graphics_quality = clampi(gfx_q, 0, 2)
	_working.ui_scale = clampf(ui_s, 0.85, 1.25)
	_working.touch_friendly_layout = touch_on
	_sync_controls()


func apply_and_save() -> GameShellViewModel.UserSettingsSnapshot:
	_ensure_built()
	var vm: GameShellViewModel = _get_vm()
	var saved_ok: bool = vm.save_user_settings(_working) if vm != null else false
	_status_lbl.text = "Ayarlar kaydedildi ve uygulandı." if saved_ok else "Ayarlar belleğe uygulandı."
	_status_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.JADE_BRIGHT)
	var out: GameShellViewModel.UserSettingsSnapshot = _working.duplicate_settings()
	settings_applied.emit(out)
	return out


func get_working_settings() -> GameShellViewModel.UserSettingsSnapshot:
	return _working.duplicate_settings()


func get_apply_button() -> Button:
	_ensure_built()
	return _apply_btn


func get_touch_toggle_button() -> Button:
	_ensure_built()
	return _touch_btn


func get_graphics_button() -> Button:
	_ensure_built()
	return _gfx_btn


func _ensure_built() -> void:
	if _built:
		return
	_built = true

	var margin: MarginContainer = get_content_container()
	margin.add_theme_constant_override(&"margin_left", 16)
	margin.add_theme_constant_override(&"margin_right", 16)
	margin.add_theme_constant_override(&"margin_top", 12)
	margin.add_theme_constant_override(&"margin_bottom", 12)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override(&"separation", 7)
	margin.add_child(vbox)

	var hdr: HBoxContainer = HBoxContainer.new()
	vbox.add_child(hdr)

	var title_lbl: Label = Label.new()
	title_lbl.theme_type_variation = &"TitleLabel"
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.text = "AYARLAR (SES, GRAFİK, ÖLÇEK & DOKUNMATİK)"
	hdr.add_child(title_lbl)

	_close_btn = _make_btn("CloseSettingsBtn", "✕", NeoSteppePalette.BRONZE_WEATHERED, close_settings)
	hdr.add_child(_close_btn)

	_audio_val_lbl = Label.new()
	_audio_val_lbl.theme_type_variation = &"CaptionLabel"
	vbox.add_child(_audio_val_lbl)

	_master_slider = _make_slider("MasterSlider", 0.0, 1.0, 0.05, _on_audio_slider_changed)
	vbox.add_child(_make_labeled_row("Ana Ses", _master_slider))
	_music_slider = _make_slider("MusicSlider", 0.0, 1.0, 0.05, _on_audio_slider_changed)
	vbox.add_child(_make_labeled_row("Müzik", _music_slider))
	_sfx_slider = _make_slider("SfxSlider", 0.0, 1.0, 0.05, _on_audio_slider_changed)
	vbox.add_child(_make_labeled_row("Efektler", _sfx_slider))

	var gfx_row: HBoxContainer = HBoxContainer.new()
	gfx_row.add_theme_constant_override(&"separation", 8)
	vbox.add_child(gfx_row)

	_gfx_btn = _make_btn("BtnGfxQuality", "Grafik: Yüksek", NeoSteppePalette.GOLD_TAMGA, _on_cycle_gfx_pressed)
	_gfx_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gfx_row.add_child(_gfx_btn)

	_touch_btn = _make_btn("BtnTouchLayout", "Dokunmatik Düzen: Kapalı", NeoSteppePalette.ICE_BLUE, _on_toggle_touch_pressed)
	_touch_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gfx_row.add_child(_touch_btn)

	_scale_val_lbl = Label.new()
	_scale_val_lbl.theme_type_variation = &"CaptionLabel"
	vbox.add_child(_scale_val_lbl)

	_scale_slider = _make_slider("UiScaleSlider", 0.85, 1.25, 0.05, _on_scale_slider_changed)
	vbox.add_child(_make_labeled_row("UI Ölçeği", _scale_slider))

	var footer: HBoxContainer = HBoxContainer.new()
	footer.add_theme_constant_override(&"separation", 8)
	vbox.add_child(footer)

	_reset_btn = _make_btn("BtnResetSettings", "Varsayılan", NeoSteppePalette.BRONZE_WEATHERED, _on_reset_pressed)
	footer.add_child(_reset_btn)

	_apply_btn = _make_btn("BtnApplySettings", "Uygula & Kaydet", NeoSteppePalette.JADE_PRIMARY, _on_apply_pressed)
	_apply_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(_apply_btn)

	_status_lbl = Label.new()
	_status_lbl.theme_type_variation = &"MutedLabel"
	_status_lbl.text = ""
	vbox.add_child(_status_lbl)

	_sync_controls()


func _make_labeled_row(lbl_text: String, ctrl: Control) -> HBoxContainer:
	var h: HBoxContainer = HBoxContainer.new()
	h.add_theme_constant_override(&"separation", 8)
	var lbl: Label = Label.new()
	lbl.theme_type_variation = &"BodyLabel"
	lbl.custom_minimum_size = Vector2(96.0, 0.0)
	lbl.text = lbl_text
	h.add_child(lbl)
	ctrl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(ctrl)
	return h


func _make_slider(
		p_name: String,
		min_v: float,
		max_v: float,
		step_v: float,
		cb: Callable) -> HSlider:
	var sl: HSlider = HSlider.new()
	sl.name = p_name
	sl.min_value = min_v
	sl.max_value = max_v
	sl.step = step_v
	sl.value_changed.connect(cb)
	_slider_callbacks[sl] = cb
	return sl


func _make_btn(p_name: String, p_text: String, p_col: Color, p_cb: Callable) -> Button:
	var btn: Button = Button.new()
	btn.name = p_name
	btn.theme_type_variation = &"GhostIconButton"
	btn.text = p_text
	OtukenThemeFactory.apply_button_semantic_styles(btn, p_col, false, 8, 4)
	btn.pressed.connect(p_cb)
	_btn_callbacks[btn] = p_cb
	return btn


func _sync_controls() -> void:
	if not _built:
		return
	_master_slider.set_value_no_signal(_working.master_volume)
	_music_slider.set_value_no_signal(_working.music_volume)
	_sfx_slider.set_value_no_signal(_working.sfx_volume)
	_scale_slider.set_value_no_signal(_working.ui_scale)

	_audio_val_lbl.text = "Ses Düzeyi · Ana %%%d · Müzik %%%d · Efekt %%%d" % [
		roundi(_working.master_volume * 100.0),
		roundi(_working.music_volume * 100.0),
		roundi(_working.sfx_volume * 100.0),
	]
	_scale_val_lbl.text = "Arayüz Ölçeği: %.2fx" % _working.ui_scale
	var gfx_names: PackedStringArray = PackedStringArray(["Düşük", "Orta", "Yüksek"])
	_gfx_btn.text = "Grafik: %s" % gfx_names[clampi(_working.graphics_quality, 0, 2)]
	_touch_btn.text = "Dokunmatik Düzen: %s" % ("Açık" if _working.touch_friendly_layout else "Kapalı")
	OtukenThemeFactory.apply_button_semantic_styles(_touch_btn, NeoSteppePalette.JADE_PRIMARY if _working.touch_friendly_layout else NeoSteppePalette.ICE_BLUE, _working.touch_friendly_layout, 8, 4)


func _on_audio_slider_changed(_v: float) -> void:
	_working.master_volume = float(_master_slider.value)
	_working.music_volume = float(_music_slider.value)
	_working.sfx_volume = float(_sfx_slider.value)
	_sync_controls()


func _on_scale_slider_changed(v: float) -> void:
	_working.ui_scale = clampf(v, 0.85, 1.25)
	_sync_controls()


func _on_cycle_gfx_pressed() -> void:
	_working.graphics_quality = (_working.graphics_quality + 1) % 3
	_sync_controls()


func _on_toggle_touch_pressed() -> void:
	_working.touch_friendly_layout = not _working.touch_friendly_layout
	_sync_controls()


func _on_reset_pressed() -> void:
	var vm: GameShellViewModel = _get_vm()
	_working = vm.reset_default_settings() if vm != null else GameShellViewModel.UserSettingsSnapshot.new()
	_sync_controls()
	_status_lbl.text = "Varsayılan ayarlar geri yüklendi."


func _on_apply_pressed() -> void:
	apply_and_save()


func _get_vm() -> GameShellViewModel:
	if _vm_ref == null:
		return null
	var obj: Object = _vm_ref.get_ref()
	if obj != null and is_instance_valid(obj):
		return obj as GameShellViewModel
	return null
