class_name MainMenuScreen
extends Control
## Neo-Steppe Main Menu screen (rank 4). Provides entry actions for New Game,
## Continue Latest Save, Save/Load Manager, Online Lobby, Settings, and Quit.

signal new_game_requested()
signal continue_game_requested(slot_id: String)
signal load_menu_requested()
signal multiplayer_lobby_requested()
signal settings_requested()
signal quit_requested()

var _vm_ref: WeakRef = null
var _latest_slot_id: String = ""
var _built: bool = false

var _card: TamgaCardPanel = null
var _subtitle_lbl: Label = null
var _continue_info_lbl: Label = null
var _btn_new_game: Button = null
var _btn_continue: Button = null
var _btn_load: Button = null
var _btn_online: Button = null
var _btn_settings: Button = null
var _btn_quit: Button = null
var _btn_callbacks: Dictionary[Button, Callable] = {}


func _init() -> void:
	name = "MainMenuScreen"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false


func _ready() -> void:
	_ensure_built()
	refresh_menu()


func _exit_tree() -> void:
	_disconnect_all_buttons()


func bind_view_model(vm: GameShellViewModel) -> void:
	_vm_ref = weakref(vm) if vm != null else null
	refresh_menu()


func refresh_menu() -> void:
	_ensure_built()
	var vm: GameShellViewModel = _get_vm()
	if vm == null:
		_latest_slot_id = ""
		_btn_continue.disabled = true
		_continue_info_lbl.text = "Devam edilecek kayıt bulunamadı."
		return
	_latest_slot_id = vm.get_latest_valid_slot_id()
	var has_save: bool = not _latest_slot_id.is_empty()
	_btn_continue.disabled = not has_save
	OtukenThemeFactory.apply_button_semantic_styles(
		_btn_continue,
		NeoSteppePalette.JADE_PRIMARY if has_save else NeoSteppePalette.BRONZE_DARK,
		has_save,
		12,
		6
	)
	_continue_info_lbl.text = ("Son Kayıt Hazır: %s" % _latest_slot_id) if has_save else "Kayıtlı sefer henüz yok"


func get_button(action_name: StringName) -> Button:
	_ensure_built()
	match action_name:
		&"new_game":
			return _btn_new_game
		&"continue":
			return _btn_continue
		&"load":
			return _btn_load
		&"online":
			return _btn_online
		&"settings":
			return _btn_settings
		&"quit":
			return _btn_quit
	return null


func _ensure_built() -> void:
	if _built:
		return
	_built = true

	var backdrop: ColorRect = ColorRect.new()
	backdrop.name = "MainMenuBackdrop"
	backdrop.color = Color(0.03, 0.035, 0.045, 0.88)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	_card = TamgaCardPanel.new()
	_card.name = "MainMenuCard"
	_card.semantic_tone = &"gold"
	_card.clickable = false
	_card.anchor_left = 0.5
	_card.anchor_top = 0.5
	_card.anchor_right = 0.5
	_card.anchor_bottom = 0.5
	_card.offset_left = -210.0
	_card.offset_top = -220.0
	_card.offset_right = 210.0
	_card.offset_bottom = 220.0
	add_child(_card)

	var margin: MarginContainer = _card.get_content_container()
	margin.add_theme_constant_override(&"margin_left", 20)
	margin.add_theme_constant_override(&"margin_right", 20)
	margin.add_theme_constant_override(&"margin_top", 18)
	margin.add_theme_constant_override(&"margin_bottom", 18)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override(&"separation", 8)
	margin.add_child(vbox)

	var title_lbl: Label = Label.new()
	title_lbl.theme_type_variation = &"TitleLabel"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override(&"font_size", NeoSteppePalette.FONT_SIZE_DISPLAY)
	title_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.GOLD_TAMGA)
	title_lbl.text = "ÖTÜKEN — BOZKIR KAĞANLIĞI"
	vbox.add_child(title_lbl)

	_subtitle_lbl = Label.new()
	_subtitle_lbl.theme_type_variation = &"MutedLabel"
	_subtitle_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_lbl.text = "3D Taktik & Büyük Strateji Kabuğu"
	vbox.add_child(_subtitle_lbl)

	_continue_info_lbl = Label.new()
	_continue_info_lbl.theme_type_variation = &"CaptionLabel"
	_continue_info_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_continue_info_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.JADE_BRIGHT)
	_continue_info_lbl.text = "Kayıtlı sefer henüz yok"
	vbox.add_child(_continue_info_lbl)

	_btn_continue = _make_menu_btn("BtnMainContinue", "Devam Et", NeoSteppePalette.JADE_PRIMARY, _on_continue_pressed)
	vbox.add_child(_btn_continue)
	_btn_new_game = _make_menu_btn("BtnMainNewGame", "Yeni Oyun Kur", NeoSteppePalette.GOLD_TAMGA, _on_new_game_pressed)
	vbox.add_child(_btn_new_game)
	_btn_load = _make_menu_btn("BtnMainLoad", "Kayıt Yükle", NeoSteppePalette.BRONZE_WEATHERED, _on_load_pressed)
	vbox.add_child(_btn_load)
	_btn_online = _make_menu_btn("BtnMainOnline", "Çok Oyunculu / Online Lobi", NeoSteppePalette.ICE_BLUE, _on_online_pressed)
	vbox.add_child(_btn_online)
	_btn_settings = _make_menu_btn("BtnMainSettings", "Ayarlar", NeoSteppePalette.BRONZE_WEATHERED, _on_settings_pressed)
	vbox.add_child(_btn_settings)
	_btn_quit = _make_menu_btn("BtnMainQuit", "Çıkış", NeoSteppePalette.EMBER_RED, _on_quit_pressed)
	vbox.add_child(_btn_quit)


func _make_menu_btn(
		p_name: String,
		p_text: String,
		p_col: Color,
		p_cb: Callable) -> Button:
	var btn: Button = Button.new()
	btn.name = p_name
	btn.theme_type_variation = &"PrimaryCommandButton"
	btn.text = p_text
	btn.custom_minimum_size = Vector2(0.0, 34.0)
	OtukenThemeFactory.apply_button_semantic_styles(btn, p_col, false, 12, 6)
	btn.pressed.connect(p_cb)
	_btn_callbacks[btn] = p_cb
	return btn


func _on_continue_pressed() -> void:
	if not _latest_slot_id.is_empty():
		continue_game_requested.emit(_latest_slot_id)


func _on_new_game_pressed() -> void:
	new_game_requested.emit()


func _on_load_pressed() -> void:
	load_menu_requested.emit()


func _on_online_pressed() -> void:
	multiplayer_lobby_requested.emit()


func _on_settings_pressed() -> void:
	settings_requested.emit()


func _on_quit_pressed() -> void:
	quit_requested.emit()


func _get_vm() -> GameShellViewModel:
	if _vm_ref == null:
		return null
	var obj: Object = _vm_ref.get_ref()
	if obj != null and is_instance_valid(obj):
		return obj as GameShellViewModel
	return null


func _disconnect_all_buttons() -> void:
	for btn: Button in _btn_callbacks.keys():
		if btn != null and is_instance_valid(btn):
			var cb: Callable = _btn_callbacks[btn]
			if cb.is_valid() and btn.pressed.is_connected(cb):
				btn.pressed.disconnect(cb)
	_btn_callbacks.clear()
