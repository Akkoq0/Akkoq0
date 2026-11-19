class_name PauseMenuPanel
extends TamgaCardPanel
## In-Game Pause Menu overlay (rank 4). Supports returning to active campaign,
## Save/Load Menu, Settings, Match Summary History, and Main Menu return while
## clearly indicating non-pausable flow in `ONLINE_PERSISTENT_WORLD`.

signal resume_requested()
signal save_load_requested()
signal settings_requested()
signal match_summary_requested()
signal main_menu_requested()

var _built: bool = false
var _status_lbl: Label = null
var _btn_resume: Button = null
var _btn_save_load: Button = null
var _btn_settings: Button = null
var _btn_summary: Button = null
var _btn_main_menu: Button = null
var _btn_callbacks: Dictionary[Button, Callable] = {}


func _init() -> void:
	name = "PauseMenuPanel"
	card_id = &"pause_menu_panel"
	semantic_tone = &"gold"
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


func open_pause_menu() -> void:
	_ensure_built()
	visible = true
	refresh_mode_status()


func close_pause_menu() -> void:
	if not visible:
		return
	visible = false
	resume_requested.emit()


func refresh_mode_status() -> void:
	_ensure_built()
	if SessionClockAuthority.can_pause():
		_status_lbl.text = "Tekil Sefer — Simülasyon Duraklatıldı"
		_status_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.GOLD_PALE)
	else:
		_status_lbl.text = "Kalıcı Online Dünya — Zaman Durdurulamaz (1x Aktif)"
		_status_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.ICE_FROST)


func get_button(action_name: StringName) -> Button:
	_ensure_built()
	match action_name:
		&"resume":
			return _btn_resume
		&"save_load":
			return _btn_save_load
		&"settings":
			return _btn_settings
		&"summary":
			return _btn_summary
		&"main_menu":
			return _btn_main_menu
	return null


func _ensure_built() -> void:
	if _built:
		return
	_built = true

	var margin: MarginContainer = get_content_container()
	margin.add_theme_constant_override(&"margin_left", 16)
	margin.add_theme_constant_override(&"margin_right", 16)
	margin.add_theme_constant_override(&"margin_top", 14)
	margin.add_theme_constant_override(&"margin_bottom", 14)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override(&"separation", 7)
	margin.add_child(vbox)

	var title_lbl: Label = Label.new()
	title_lbl.theme_type_variation = &"TitleLabel"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.text = "SEFER MENÜSÜ"
	vbox.add_child(title_lbl)

	_status_lbl = Label.new()
	_status_lbl.theme_type_variation = &"CaptionLabel"
	_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_status_lbl)

	_btn_resume = _make_btn("BtnPauseResume", "Seferi Sürdür", NeoSteppePalette.JADE_PRIMARY, close_pause_menu)
	vbox.add_child(_btn_resume)
	_btn_save_load = _make_btn("BtnPauseSaveLoad", "Kaydet / Yükle", NeoSteppePalette.GOLD_TAMGA, _on_save_load_pressed)
	vbox.add_child(_btn_save_load)
	_btn_settings = _make_btn("BtnPauseSettings", "Ayarlar", NeoSteppePalette.BRONZE_WEATHERED, _on_settings_pressed)
	vbox.add_child(_btn_settings)
	_btn_summary = _make_btn("BtnPauseSummary", "Sefer Sonu & Tarihçe Özeti", NeoSteppePalette.ICE_BLUE, _on_summary_pressed)
	vbox.add_child(_btn_summary)
	_btn_main_menu = _make_btn("BtnPauseMainMenu", "Ana Menüye Dön", NeoSteppePalette.EMBER_RED, _on_main_menu_pressed)
	vbox.add_child(_btn_main_menu)


func _make_btn(p_name: String, p_text: String, p_col: Color, p_cb: Callable) -> Button:
	var btn: Button = Button.new()
	btn.name = p_name
	btn.theme_type_variation = &"PrimaryCommandButton"
	btn.text = p_text
	OtukenThemeFactory.apply_button_semantic_styles(btn, p_col, false, 10, 5)
	btn.pressed.connect(p_cb)
	_btn_callbacks[btn] = p_cb
	return btn


func _on_save_load_pressed() -> void:
	save_load_requested.emit()


func _on_settings_pressed() -> void:
	settings_requested.emit()


func _on_summary_pressed() -> void:
	match_summary_requested.emit()


func _on_main_menu_pressed() -> void:
	visible = false
	main_menu_requested.emit()
