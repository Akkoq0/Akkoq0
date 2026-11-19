class_name NewGameSetupPanel
extends TamgaCardPanel
## New Game Setup Panel (rank 4). Configures SessionMode (`SINGLEPLAYER_SESSION`
## or `ONLINE_PERSISTENT_WORLD`), Clan/Personality archetype, 4 AI Difficulty
## profiles (`OYMAK_BEYI` -> `KAGAN_ZEKASI`) with descriptions, and Map Seed.

signal start_game_confirmed(config: GameShellViewModel.NewGameLaunchConfig)
signal cancelled()

var _vm_ref: WeakRef = null
var _built: bool = false

var _selected_mode: GameEnums.SessionMode = GameEnums.SessionMode.SINGLEPLAYER_SESSION
var _selected_personality: GameEnums.SteppeAIPersonality = GameEnums.SteppeAIPersonality.AKINCI_BASKINCI
var _selected_difficulty: GameEnums.AIDifficultyTier = GameEnums.AIDifficultyTier.SANCAK_BEYI
var _world_seed: int = 1071

var _mode_sp_btn: Button = null
var _mode_online_btn: Button = null
var _clan_edit: LineEdit = null
var _seed_spin: SpinBox = null
var _rand_seed_btn: Button = null

var _personality_btns: Dictionary[GameEnums.SteppeAIPersonality, Button] = {}
var _personality_desc_lbl: Label = null

var _difficulty_btns: Dictionary[GameEnums.AIDifficultyTier, Button] = {}
var _difficulty_desc_lbl: Label = null

var _start_btn: Button = null
var _cancel_btn: Button = null
var _btn_callbacks: Dictionary[Button, Callable] = {}


func _init() -> void:
	name = "NewGameSetupPanel"
	card_id = &"new_game_setup_panel"
	semantic_tone = &"gold"
	clickable = false
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP


func _ready() -> void:
	_ensure_built()
	refresh_options()


func _exit_tree() -> void:
	_disconnect_all_buttons()


func bind_view_model(vm: GameShellViewModel) -> void:
	_vm_ref = weakref(vm) if vm != null else null
	refresh_options()


func open_setup() -> void:
	_ensure_built()
	visible = true
	refresh_options()


func close_setup() -> void:
	if not visible:
		return
	visible = false
	cancelled.emit()


func select_session_mode(mode: GameEnums.SessionMode) -> void:
	_selected_mode = mode
	_sync_selection_styles()


func select_personality(p: GameEnums.SteppeAIPersonality) -> void:
	_selected_personality = p
	_sync_selection_styles()


func select_difficulty(d: GameEnums.AIDifficultyTier) -> void:
	_selected_difficulty = d
	_sync_selection_styles()


func set_world_seed(p_seed: int) -> void:
	_ensure_built()
	_world_seed = maxi(p_seed, 1)
	if _seed_spin != null:
		_seed_spin.value = float(_world_seed)


func build_launch_config() -> GameShellViewModel.NewGameLaunchConfig:
	_ensure_built()
	var cfg: GameShellViewModel.NewGameLaunchConfig = GameShellViewModel.NewGameLaunchConfig.new()
	cfg.session_mode = _selected_mode
	cfg.player_personality = _selected_personality
	cfg.ai_difficulty = _selected_difficulty
	cfg.ai_personality = GameEnums.SteppeAIPersonality.GOLGE_SABOTOR if _selected_personality != GameEnums.SteppeAIPersonality.GOLGE_SABOTOR else GameEnums.SteppeAIPersonality.DEMIR_SAVUNMACI
	cfg.world_seed = int(roundf(_seed_spin.value)) if _seed_spin != null else _world_seed
	var raw_clan: String = _clan_edit.text.strip_edges() if _clan_edit != null else ""
	cfg.clan_name = raw_clan if not raw_clan.is_empty() else "Ötüken Kök Boyu"
	return cfg


func get_difficulty_description_text() -> String:
	_ensure_built()
	return _difficulty_desc_lbl.text


func get_personality_description_text() -> String:
	_ensure_built()
	return _personality_desc_lbl.text


func get_difficulty_button(tier: GameEnums.AIDifficultyTier) -> Button:
	_ensure_built()
	if _difficulty_btns.has(tier):
		return _difficulty_btns[tier]
	return null


func get_personality_button(p: GameEnums.SteppeAIPersonality) -> Button:
	_ensure_built()
	if _personality_btns.has(p):
		return _personality_btns[p]
	return null


func get_start_button() -> Button:
	_ensure_built()
	return _start_btn


func refresh_options() -> void:
	_ensure_built()
	_sync_selection_styles()


func _ensure_built() -> void:
	if _built:
		return
	_built = true

	var margin: MarginContainer = get_content_container()
	margin.add_theme_constant_override(&"margin_left", 16)
	margin.add_theme_constant_override(&"margin_right", 16)
	margin.add_theme_constant_override(&"margin_top", 12)
	margin.add_theme_constant_override(&"margin_bottom", 12)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override(&"separation", 8)
	scroll.add_child(vbox)

	var title_lbl: Label = Label.new()
	title_lbl.theme_type_variation = &"TitleLabel"
	title_lbl.text = "YENİ SEFER KURULUMU"
	vbox.add_child(title_lbl)

	# 1. Session Mode
	var mode_lbl: Label = Label.new()
	mode_lbl.theme_type_variation = &"CaptionLabel"
	mode_lbl.text = "Oyun Modu:"
	vbox.add_child(mode_lbl)

	var mode_h: HBoxContainer = HBoxContainer.new()
	mode_h.add_theme_constant_override(&"separation", 6)
	vbox.add_child(mode_h)

	_mode_sp_btn = _make_btn("BtnModeSingle", "Tekil Sefer (Duraklatılabilir)", NeoSteppePalette.JADE_PRIMARY, _on_sp_mode_pressed)
	_mode_sp_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mode_h.add_child(_mode_sp_btn)

	_mode_online_btn = _make_btn("BtnModeOnline", "Kalıcı Bozkır Dünyası (Online 1x)", NeoSteppePalette.ICE_BLUE, _on_online_mode_pressed)
	_mode_online_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mode_h.add_child(_mode_online_btn)

	# 2. Clan Name & World Seed
	var seed_h: HBoxContainer = HBoxContainer.new()
	seed_h.add_theme_constant_override(&"separation", 6)
	vbox.add_child(seed_h)

	var clan_lbl: Label = Label.new()
	clan_lbl.theme_type_variation = &"CaptionLabel"
	clan_lbl.text = "Boy Adı:"
	seed_h.add_child(clan_lbl)

	_clan_edit = LineEdit.new()
	_clan_edit.text = "Ötüken Kök Boyu"
	_clan_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	seed_h.add_child(_clan_edit)

	var seed_lbl: Label = Label.new()
	seed_lbl.theme_type_variation = &"CaptionLabel"
	seed_lbl.text = "Tohum:"
	seed_h.add_child(seed_lbl)

	_seed_spin = SpinBox.new()
	_seed_spin.min_value = 1.0
	_seed_spin.max_value = 9999999.0
	_seed_spin.step = 1.0
	_seed_spin.value = float(_world_seed)
	seed_h.add_child(_seed_spin)

	_rand_seed_btn = _make_btn("BtnRandomSeed", "Rastgele", NeoSteppePalette.BRONZE_WEATHERED, _on_random_seed_pressed)
	seed_h.add_child(_rand_seed_btn)

	# 3. Boy / Personality Cards
	var pers_hdr: Label = Label.new()
	pers_hdr.theme_type_variation = &"CaptionLabel"
	pers_hdr.text = "Boy Karakteri & Stratejik Kimlik:"
	vbox.add_child(pers_hdr)

	var pers_flow: HFlowContainer = HFlowContainer.new()
	pers_flow.add_theme_constant_override(&"h_separation", 6)
	pers_flow.add_theme_constant_override(&"v_separation", 4)
	vbox.add_child(pers_flow)

	var vm: GameShellViewModel = _get_or_temp_vm()
	for po: GameShellViewModel.PersonalityOptionView in vm.get_personality_options():
		var pbtn: Button = _make_btn(
			"BtnPers_%d" % int(po.personality),
			po.title,
			NeoSteppePalette.GOLD_TAMGA,
			select_personality.bind(po.personality)
		)
		pers_flow.add_child(pbtn)
		_personality_btns[po.personality] = pbtn

	_personality_desc_lbl = Label.new()
	_personality_desc_lbl.theme_type_variation = &"MutedLabel"
	_personality_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_personality_desc_lbl)

	# 4. 4 AI Difficulty Tiers
	var diff_hdr: Label = Label.new()
	diff_hdr.theme_type_variation = &"CaptionLabel"
	diff_hdr.text = "Yapay Zekâ Zorluk Profili (Sıfır Hile):"
	vbox.add_child(diff_hdr)

	var diff_flow: HFlowContainer = HFlowContainer.new()
	diff_flow.add_theme_constant_override(&"h_separation", 6)
	diff_flow.add_theme_constant_override(&"v_separation", 4)
	vbox.add_child(diff_flow)

	for do_item: GameShellViewModel.DifficultyOptionView in vm.get_difficulty_options():
		var dbtn: Button = _make_btn(
			"BtnDiff_%d" % int(do_item.tier),
			do_item.title,
			NeoSteppePalette.JADE_PRIMARY,
			select_difficulty.bind(do_item.tier)
		)
		diff_flow.add_child(dbtn)
		_difficulty_btns[do_item.tier] = dbtn

	_difficulty_desc_lbl = Label.new()
	_difficulty_desc_lbl.theme_type_variation = &"MutedLabel"
	_difficulty_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_difficulty_desc_lbl)

	# 5. Confirm / Cancel
	var footer_h: HBoxContainer = HBoxContainer.new()
	footer_h.add_theme_constant_override(&"separation", 8)
	vbox.add_child(footer_h)

	_cancel_btn = _make_btn("BtnSetupCancel", "Geri Dön", NeoSteppePalette.BRONZE_WEATHERED, close_setup)
	footer_h.add_child(_cancel_btn)

	_start_btn = _make_btn("BtnSetupLaunch", "Seferi Başlat ->", NeoSteppePalette.JADE_PRIMARY, _on_launch_pressed)
	_start_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer_h.add_child(_start_btn)


func _make_btn(p_name: String, p_text: String, p_col: Color, p_cb: Callable) -> Button:
	var btn: Button = Button.new()
	btn.name = p_name
	btn.theme_type_variation = &"GhostIconButton"
	btn.text = p_text
	OtukenThemeFactory.apply_button_semantic_styles(btn, p_col, false, 8, 4)
	btn.pressed.connect(p_cb)
	_btn_callbacks[btn] = p_cb
	return btn


func _sync_selection_styles() -> void:
	if not _built:
		return
	var is_sp: bool = _selected_mode == GameEnums.SessionMode.SINGLEPLAYER_SESSION
	OtukenThemeFactory.apply_button_semantic_styles(_mode_sp_btn, NeoSteppePalette.JADE_PRIMARY, is_sp, 8, 4)
	OtukenThemeFactory.apply_button_semantic_styles(_mode_online_btn, NeoSteppePalette.ICE_BLUE, not is_sp, 8, 4)

	var vm: GameShellViewModel = _get_or_temp_vm()
	for po: GameShellViewModel.PersonalityOptionView in vm.get_personality_options():
		if _personality_btns.has(po.personality):
			var active_p: bool = po.personality == _selected_personality
			OtukenThemeFactory.apply_button_semantic_styles(_personality_btns[po.personality], NeoSteppePalette.GOLD_TAMGA, active_p, 8, 4)
			if active_p:
				_personality_desc_lbl.text = "%s — %s" % [po.description, po.doctrine_line]

	for do_item: GameShellViewModel.DifficultyOptionView in vm.get_difficulty_options():
		if _difficulty_btns.has(do_item.tier):
			var active_d: bool = do_item.tier == _selected_difficulty
			OtukenThemeFactory.apply_button_semantic_styles(_difficulty_btns[do_item.tier], NeoSteppePalette.JADE_PRIMARY, active_d, 8, 4)
			if active_d:
				_difficulty_desc_lbl.text = "%s (%s)" % [do_item.description, do_item.stats_line]


func _on_sp_mode_pressed() -> void:
	select_session_mode(GameEnums.SessionMode.SINGLEPLAYER_SESSION)


func _on_online_mode_pressed() -> void:
	select_session_mode(GameEnums.SessionMode.ONLINE_PERSISTENT_WORLD)


func _on_random_seed_pressed() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	set_world_seed(rng.randi_range(100, 999999))


func _on_launch_pressed() -> void:
	var cfg: GameShellViewModel.NewGameLaunchConfig = build_launch_config()
	visible = false
	start_game_confirmed.emit(cfg)


func _get_or_temp_vm() -> GameShellViewModel:
	if _vm_ref != null:
		var obj: Object = _vm_ref.get_ref()
		if obj != null and is_instance_valid(obj):
			var vm: GameShellViewModel = obj as GameShellViewModel
			if vm != null:
				return vm
	return GameShellViewModel.new()


func _disconnect_all_buttons() -> void:
	for btn: Button in _btn_callbacks.keys():
		if btn != null and is_instance_valid(btn):
			var cb: Callable = _btn_callbacks[btn]
			if cb.is_valid() and btn.pressed.is_connected(cb):
				btn.pressed.disconnect(cb)
	_btn_callbacks.clear()
