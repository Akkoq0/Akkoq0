class_name GameShellCoordinator
extends Control
## Orchestrates complete Game Flow & Shell Screens (rank 4):
## MainMenuScreen -> NewGameSetupPanel -> Active Campaign <-> PauseMenuPanel ->
## SaveLoadMenuPanel / SettingsPanel -> MatchSummaryScreen, plus Online Lobby
## entry hook for Faz D transport layer.

signal campaign_launch_requested(config: GameShellViewModel.NewGameLaunchConfig)
signal multiplayer_lobby_opened()
signal game_quit_requested()
signal shell_screen_changed(active_screen: StringName)

var _vm: GameShellViewModel = null
var _analytics_vm_ref: WeakRef = null
var _built: bool = false
var _active_screen: StringName = &"none"
var _last_config: GameShellViewModel.NewGameLaunchConfig = GameShellViewModel.NewGameLaunchConfig.new()

var _main_menu: MainMenuScreen = null
var _new_game_panel: NewGameSetupPanel = null
var _save_load_panel: SaveLoadMenuPanel = null
var _settings_panel: SettingsPanel = null
var _pause_panel: PauseMenuPanel = null
var _summary_screen: MatchSummaryScreen = null
var _lobby_panel: TamgaCardPanel = null
var _lobby_status_lbl: Label = null
var _lobby_close_btn: Button = null
var _lobby_close_cb: Callable = Callable()


func _init() -> void:
	name = "GameShellCoordinator"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	_ensure_built()


func _exit_tree() -> void:
	_disconnect_shell_signals()


func get_view_model() -> GameShellViewModel:
	if _vm == null:
		_vm = GameShellViewModel.new()
	return _vm


func bind_analytics_view_model(avm: MetricAnalyticsViewModel) -> void:
	_analytics_vm_ref = weakref(avm) if avm != null else null


func open_main_menu() -> void:
	_ensure_built()
	_hide_all_screens()
	_main_menu.bind_view_model(get_view_model())
	_main_menu.visible = true
	_main_menu.refresh_menu()
	_set_active_screen(&"main_menu")


func open_new_game_setup() -> void:
	_ensure_built()
	_hide_all_screens()
	_new_game_panel.bind_view_model(get_view_model())
	_new_game_panel.open_setup()
	_set_active_screen(&"new_game_setup")


func open_save_load_menu(allow_saving: bool = true) -> void:
	_ensure_built()
	_hide_all_screens()
	_save_load_panel.bind_view_model(get_view_model())
	_save_load_panel.open_menu(allow_saving)
	_set_active_screen(&"save_load")


func open_settings() -> void:
	_ensure_built()
	_hide_all_screens()
	_settings_panel.bind_view_model(get_view_model())
	_settings_panel.open_settings()
	_set_active_screen(&"settings")


func open_pause_menu() -> void:
	_ensure_built()
	_hide_all_screens()
	if SessionClockAuthority.can_pause():
		SessionClockAuthority.request_pause(true, "1")
	_pause_panel.open_pause_menu()
	_set_active_screen(&"pause_menu")


func open_match_summary(forced_outcome: int = -1) -> void:
	_ensure_built()
	_hide_all_screens()
	var avm: MetricAnalyticsViewModel = null
	if _analytics_vm_ref != null:
		var obj: Object = _analytics_vm_ref.get_ref()
		if obj != null and is_instance_valid(obj):
			avm = obj as MetricAnalyticsViewModel
	var snap: GameShellViewModel.MatchSummarySnapshot = get_view_model().capture_match_summary(avm, forced_outcome)
	_summary_screen.open_summary(snap)
	_set_active_screen(&"match_summary")


func open_online_lobby() -> void:
	_ensure_built()
	_hide_all_screens()
	_lobby_panel.visible = true
	_set_active_screen(&"online_lobby")
	multiplayer_lobby_opened.emit()


func close_all_menus() -> void:
	_hide_all_screens()
	if SessionClockAuthority.can_pause() and SessionClockAuthority.is_paused():
		SessionClockAuthority.request_pause(false, "1")
	_set_active_screen(&"none")


func is_any_screen_visible() -> bool:
	return _active_screen != &"none"


func get_active_screen_id() -> StringName:
	return _active_screen


func get_main_menu() -> MainMenuScreen:
	_ensure_built()
	return _main_menu


func get_new_game_setup_panel() -> NewGameSetupPanel:
	_ensure_built()
	return _new_game_panel


func get_save_load_panel() -> SaveLoadMenuPanel:
	_ensure_built()
	return _save_load_panel


func get_settings_panel() -> SettingsPanel:
	_ensure_built()
	return _settings_panel


func get_pause_panel() -> PauseMenuPanel:
	_ensure_built()
	return _pause_panel


func get_match_summary_screen() -> MatchSummaryScreen:
	_ensure_built()
	return _summary_screen


func apply_launch_config_to_simulation(cfg: GameShellViewModel.NewGameLaunchConfig) -> void:
	if cfg == null:
		return
	_last_config = cfg
	SessionClockAuthority.configure_session_mode(cfg.session_mode, 1.0, 10.0)
	if cfg.session_mode == GameEnums.SessionMode.ONLINE_PERSISTENT_WORLD:
		GracePeriodManager.configure_persistent_world(true, 0.0)
		GracePeriodManager.register_player(1, false, Vector2i(8, 8), cfg.world_seed)
	else:
		GracePeriodManager.reset_persistent_world()
	SteppeStrategicAIController.reset_strategic_ai_state()
	var ai_ctrl: SteppeStrategicAIController = SteppeStrategicAIController.new(
		&"rival_bozkir_bey",
		2,
		201,
		Vector2i(5, 5),
		cfg.ai_difficulty,
		cfg.ai_personality,
		cfg.world_seed,
		1,
		1,
		Vector2i(2, 2)
	)
	SteppeStrategicAIController.register_ai_agent(ai_ctrl)


func _ensure_built() -> void:
	if _built:
		return
	_built = true

	var vm: GameShellViewModel = get_view_model()

	_main_menu = MainMenuScreen.new()
	_main_menu.bind_view_model(vm)
	add_child(_main_menu)

	_new_game_panel = _center_card(NewGameSetupPanel.new(), Vector2(560.0, 440.0)) as NewGameSetupPanel
	_new_game_panel.bind_view_model(vm)
	add_child(_new_game_panel)

	_save_load_panel = _center_card(SaveLoadMenuPanel.new(), Vector2(500.0, 360.0)) as SaveLoadMenuPanel
	_save_load_panel.bind_view_model(vm)
	add_child(_save_load_panel)

	_settings_panel = _center_card(SettingsPanel.new(), Vector2(460.0, 360.0)) as SettingsPanel
	_settings_panel.bind_view_model(vm)
	add_child(_settings_panel)

	_pause_panel = _center_card(PauseMenuPanel.new(), Vector2(340.0, 310.0)) as PauseMenuPanel
	add_child(_pause_panel)

	_summary_screen = _center_card(MatchSummaryScreen.new(), Vector2(580.0, 440.0)) as MatchSummaryScreen
	add_child(_summary_screen)

	_build_lobby_stub()
	_connect_shell_signals()


func _build_lobby_stub() -> void:
	_lobby_panel = _center_card(TamgaCardPanel.new(), Vector2(420.0, 220.0)) as TamgaCardPanel
	_lobby_panel.name = "OnlineLobbyPanel"
	_lobby_panel.semantic_tone = &"ice"
	_lobby_panel.visible = false
	add_child(_lobby_panel)

	var m: MarginContainer = _lobby_panel.get_content_container()
	m.add_theme_constant_override(&"margin_left", 16)
	m.add_theme_constant_override(&"margin_right", 16)
	m.add_theme_constant_override(&"margin_top", 14)
	m.add_theme_constant_override(&"margin_bottom", 14)

	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override(&"separation", 8)
	m.add_child(v)

	var t: Label = Label.new()
	t.theme_type_variation = &"TitleLabel"
	t.text = "ONLINE LOBİ & SUNUCU BAĞLANTISI"
	v.add_child(t)

	_lobby_status_lbl = Label.new()
	_lobby_status_lbl.theme_type_variation = &"BodyLabel"
	_lobby_status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lobby_status_lbl.text = "Otoriter sunucu odasına katılmaya hazır (ENet / Loopback Taşıma Katmanı)."
	v.add_child(_lobby_status_lbl)

	_lobby_close_btn = Button.new()
	_lobby_close_btn.name = "CloseLobbyBtn"
	_lobby_close_btn.theme_type_variation = &"GhostIconButton"
	_lobby_close_btn.text = "Ana Menüye Dön"
	OtukenThemeFactory.apply_button_semantic_styles(_lobby_close_btn, NeoSteppePalette.BRONZE_WEATHERED, false, 10, 5)
	_lobby_close_cb = open_main_menu
	_lobby_close_btn.pressed.connect(_lobby_close_cb)
	v.add_child(_lobby_close_btn)


func _center_card(card: TamgaCardPanel, box_size: Vector2) -> TamgaCardPanel:
	card.anchor_left = 0.5
	card.anchor_top = 0.5
	card.anchor_right = 0.5
	card.anchor_bottom = 0.5
	card.offset_left = -box_size.x * 0.5
	card.offset_top = -box_size.y * 0.5
	card.offset_right = box_size.x * 0.5
	card.offset_bottom = box_size.y * 0.5
	return card


func _hide_all_screens() -> void:
	if _main_menu != null:
		_main_menu.visible = false
	if _new_game_panel != null:
		_new_game_panel.visible = false
	if _save_load_panel != null:
		_save_load_panel.visible = false
	if _settings_panel != null:
		_settings_panel.visible = false
	if _pause_panel != null:
		_pause_panel.visible = false
	if _summary_screen != null:
		_summary_screen.visible = false
	if _lobby_panel != null:
		_lobby_panel.visible = false


func _set_active_screen(scr: StringName) -> void:
	_active_screen = scr
	shell_screen_changed.emit(_active_screen)


func _connect_shell_signals() -> void:
	_main_menu.new_game_requested.connect(open_new_game_setup)
	_main_menu.continue_game_requested.connect(_on_continue_slot_requested)
	_main_menu.load_menu_requested.connect(_on_main_load_requested)
	_main_menu.multiplayer_lobby_requested.connect(open_online_lobby)
	_main_menu.settings_requested.connect(open_settings)
	_main_menu.quit_requested.connect(_on_quit_requested)

	_new_game_panel.start_game_confirmed.connect(_on_new_game_confirmed)
	_new_game_panel.cancelled.connect(open_main_menu)

	_save_load_panel.load_completed.connect(_on_save_loaded_into_game)
	_save_load_panel.panel_closed.connect(open_main_menu)

	_settings_panel.panel_closed.connect(open_main_menu)

	_pause_panel.resume_requested.connect(close_all_menus)
	_pause_panel.save_load_requested.connect(_on_pause_save_load_requested)
	_pause_panel.settings_requested.connect(open_settings)
	_pause_panel.match_summary_requested.connect(_on_pause_summary_requested)
	_pause_panel.main_menu_requested.connect(open_main_menu)

	_summary_screen.replay_requested.connect(_on_replay_requested)
	_summary_screen.main_menu_requested.connect(open_main_menu)


func _disconnect_shell_signals() -> void:
	if _main_menu != null and is_instance_valid(_main_menu):
		if _main_menu.new_game_requested.is_connected(open_new_game_setup):
			_main_menu.new_game_requested.disconnect(open_new_game_setup)
		if _main_menu.continue_game_requested.is_connected(_on_continue_slot_requested):
			_main_menu.continue_game_requested.disconnect(_on_continue_slot_requested)
		if _main_menu.load_menu_requested.is_connected(_on_main_load_requested):
			_main_menu.load_menu_requested.disconnect(_on_main_load_requested)
		if _main_menu.multiplayer_lobby_requested.is_connected(open_online_lobby):
			_main_menu.multiplayer_lobby_requested.disconnect(open_online_lobby)
		if _main_menu.settings_requested.is_connected(open_settings):
			_main_menu.settings_requested.disconnect(open_settings)
		if _main_menu.quit_requested.is_connected(_on_quit_requested):
			_main_menu.quit_requested.disconnect(_on_quit_requested)
	if _new_game_panel != null and is_instance_valid(_new_game_panel):
		if _new_game_panel.start_game_confirmed.is_connected(_on_new_game_confirmed):
			_new_game_panel.start_game_confirmed.disconnect(_on_new_game_confirmed)
		if _new_game_panel.cancelled.is_connected(open_main_menu):
			_new_game_panel.cancelled.disconnect(open_main_menu)
	if _save_load_panel != null and is_instance_valid(_save_load_panel):
		if _save_load_panel.load_completed.is_connected(_on_save_loaded_into_game):
			_save_load_panel.load_completed.disconnect(_on_save_loaded_into_game)
		if _save_load_panel.panel_closed.is_connected(open_main_menu):
			_save_load_panel.panel_closed.disconnect(open_main_menu)
	if _settings_panel != null and is_instance_valid(_settings_panel):
		if _settings_panel.panel_closed.is_connected(open_main_menu):
			_settings_panel.panel_closed.disconnect(open_main_menu)
	if _pause_panel != null and is_instance_valid(_pause_panel):
		if _pause_panel.resume_requested.is_connected(close_all_menus):
			_pause_panel.resume_requested.disconnect(close_all_menus)
		if _pause_panel.save_load_requested.is_connected(_on_pause_save_load_requested):
			_pause_panel.save_load_requested.disconnect(_on_pause_save_load_requested)
		if _pause_panel.settings_requested.is_connected(open_settings):
			_pause_panel.settings_requested.disconnect(open_settings)
		if _pause_panel.match_summary_requested.is_connected(_on_pause_summary_requested):
			_pause_panel.match_summary_requested.disconnect(_on_pause_summary_requested)
		if _pause_panel.main_menu_requested.is_connected(open_main_menu):
			_pause_panel.main_menu_requested.disconnect(open_main_menu)
	if _summary_screen != null and is_instance_valid(_summary_screen):
		if _summary_screen.replay_requested.is_connected(_on_replay_requested):
			_summary_screen.replay_requested.disconnect(_on_replay_requested)
		if _summary_screen.main_menu_requested.is_connected(open_main_menu):
			_summary_screen.main_menu_requested.disconnect(open_main_menu)
	if _lobby_close_btn != null and is_instance_valid(_lobby_close_btn) and _lobby_close_cb.is_valid():
		if _lobby_close_btn.pressed.is_connected(_lobby_close_cb):
			_lobby_close_btn.pressed.disconnect(_lobby_close_cb)
	_lobby_close_cb = Callable()


func _on_continue_slot_requested(slot_id: String) -> void:
	var res: GameShellViewModel.SaveActionResult = get_view_model().load_from_slot(slot_id)
	if res.ok:
		close_all_menus()


func _on_main_load_requested() -> void:
	open_save_load_menu(false)


func _on_pause_save_load_requested() -> void:
	open_save_load_menu(true)


func _on_pause_summary_requested() -> void:
	open_match_summary(-1)


func _on_new_game_confirmed(cfg: GameShellViewModel.NewGameLaunchConfig) -> void:
	apply_launch_config_to_simulation(cfg)
	close_all_menus()
	campaign_launch_requested.emit(cfg)


func _on_save_loaded_into_game(_slot_id: String, _world_hash: String) -> void:
	close_all_menus()


func _on_replay_requested() -> void:
	apply_launch_config_to_simulation(_last_config)
	close_all_menus()
	campaign_launch_requested.emit(_last_config)


func _on_quit_requested() -> void:
	game_quit_requested.emit()
