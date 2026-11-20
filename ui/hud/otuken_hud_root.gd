class_name OtukenHudRoot
extends Control
## UI Root Shell (rank 4). Three-layer Neo-Steppe HUD skeleton:
##   Layer 1: Pure Pulse Top Bar (strictly 4 unified cards, >=82% open map)
##            + Right-edge emergency CrisisChipRail (visible only in crises)
##   Layer 2: Single-key Tactical Map Lens Selector (1..5 hotkeys & EventBus)
##   Layer 3: Non-blocking Tween-animated Modular Analysis Drawer for Phase 26-28

signal drawer_state_changed(is_open: bool, active_slot_id: StringName)

const DRAWER_WIDTH_PX: float = 332.0
const DRAWER_CLOSED_OFFSET_X: float = -352.0
const DRAWER_OPEN_OFFSET_X: float = 14.0
const DEFAULT_TWEEN_DURATION_SEC: float = 0.22
const MAX_VISIBLE_CRISIS_CHIPS: int = 5
const SLOT_TACTICAL_COMMAND: StringName = &"tactical_command"


class BusSignalSubscription:
	var bus_signal: Signal
	var callback: Callable

	func _init(p_signal: Signal, p_callback: Callable) -> void:
		bus_signal = p_signal
		callback = p_callback


class PulseCardWidgets:
	var card: TamgaCardPanel
	var slot_id: StringName
	var header_label: Label
	var primary_label: Label
	var secondary_label: Label
	var glossary_badge: Button

	func _init(
			p_card: TamgaCardPanel,
			p_slot_id: StringName,
			p_header: Label,
			p_primary: Label,
			p_secondary: Label,
			p_badge: Button) -> void:
		card = p_card
		slot_id = p_slot_id
		header_label = p_header
		primary_label = p_primary
		secondary_label = p_secondary
		glossary_badge = p_badge


class LensOptionWidgets:
	var lens: GameEnums.TacticalMapLens
	var key_number: int
	var title: String
	var tone_id: StringName
	var button: Button
	var pressed_cb: Callable

	func _init(
			p_lens: GameEnums.TacticalMapLens,
			p_key: int,
			p_title: String,
			p_tone: StringName,
			p_button: Button,
			p_cb: Callable) -> void:
		lens = p_lens
		key_number = p_key
		title = p_title
		tone_id = p_tone
		button = p_button
		pressed_cb = p_cb


class DrawerSlotRecord:
	var slot_id: StringName
	var title: String
	var accent_tone: StringName
	var tab_button: Button
	var tab_cb: Callable
	var container: VBoxContainer
	var summary_label: Label
	var custom_panel_mount: VBoxContainer

	func _init(
			p_id: StringName,
			p_title: String,
			p_tone: StringName,
			p_tab_btn: Button,
			p_tab_cb: Callable,
			p_container: VBoxContainer,
			p_summary: Label,
			p_mount: VBoxContainer) -> void:
		slot_id = p_id
		title = p_title
		accent_tone = p_tone
		tab_button = p_tab_btn
		tab_cb = p_tab_cb
		container = p_container
		summary_label = p_summary
		custom_panel_mount = p_mount


var _research_vm: ResearchTreeViewModel = null
var _research_tree_panel: TraditionResearchTreePanel = null
var _research_toggle_btn: Button = null
var _research_toggle_cb: Callable = Callable()

var _toast_stack: AlertToastStack = null
var _rich_tooltip: RichTermTooltipController = null
var _game_shell: GameShellCoordinator = null
var _toast_activated_cb: Callable = Callable()
var _shell_settings_cb: Callable = Callable()

@export var drawer_tween_duration_sec: float = DEFAULT_TWEEN_DURATION_SEC
@export var player_id: int = 1
@export var tracked_army_id: int = 1

var _view_model: OtukenHudViewModel = null
var _analytics_vm: MetricAnalyticsViewModel = null
var _ui_built: bool = false
var _active_lens: GameEnums.TacticalMapLens = GameEnums.TacticalMapLens.NORMAL
var _drawer_open: bool = false
var _active_drawer_slot: StringName = OtukenHudViewModel.SLOT_ECONOMY_WATER
var _drawer_tween: Tween = null
var _last_crisis_signature: String = "__init__"

var _top_pulse_margin: Control = null
var _top_pulse_hbox: HBoxContainer = null
var _crisis_chip_rail: VBoxContainer = null
var _tactical_lens_dock: Control = null
var _tactical_lens_card: TamgaCardPanel = null
var _tactical_lens_hbox: HBoxContainer = null
var _analytics_dock: Control = null
var _analytics_card: TamgaCardPanel = null
var _chronicle_toggle_btn: Button = null
var _ledger_toggle_btn: Button = null
var _chronicle_toggle_cb: Callable = Callable()
var _ledger_toggle_cb: Callable = Callable()
var _metric_popover: MetricBreakdownPopover = null
var _chronicle_feed: SteppeChronicleFeed = null
var _empire_ledger: EmpireLedgerPanel = null
var _popover_action_cb: Callable = Callable()
var _chronicle_focus_cb: Callable = Callable()
var _ledger_focus_cb: Callable = Callable()
var _camera_ref: WeakRef = null
var _session_clock_dock: Control = null
var _session_clock_card: TamgaCardPanel = null
var _clock_mode_label: Label = null
var _clock_pause_btn: Button = null
var _clock_pause_cb: Callable = Callable()
var _clock_speed_buttons: Dictionary[int, Button] = {}
var _clock_speed_callbacks: Dictionary[Button, Callable] = {}
var _clock_envelope_seq: int = 0
var _analysis_drawer_card: TamgaCardPanel = null
var _drawer_title_label: Label = null
var _drawer_close_btn: Button = null
var _drawer_tabs_hbox: HFlowContainer = null
var _drawer_slot_host: MarginContainer = null
var _glossary_tooltip: SteppeGlossaryTooltip = null

var _pulse_cards: Array[PulseCardWidgets] = []
var _lens_options: Array[LensOptionWidgets] = []
var _drawer_slots: Dictionary[StringName, DrawerSlotRecord] = {}
var _drawer_slot_order: Array[StringName] = []
var _crisis_chips: Array[CrisisChipButton] = []
var _chip_activated_callbacks: Dictionary[CrisisChipButton, Callable] = {}
var _glossary_badges: Array[Button] = []
var _glossary_click_callbacks: Dictionary[Button, Callable] = {}
var _metric_chip_buttons: Dictionary[StringName, Button] = {}
var _metric_chip_callbacks: Dictionary[Button, Callable] = {}
var _card_click_callbacks: Dictionary[TamgaCardPanel, Callable] = {}
var _bus_subscriptions: Array[BusSignalSubscription] = []
var _signals_connected: bool = false
var _touch_bar: TouchActionBar = null
var _mobile_rts_mode: bool = false


func _init() -> void:
	name = "OtukenHudRoot"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = OtukenThemeFactory.create_theme()


func _ready() -> void:
	if _view_model == null:
		_view_model = OtukenHudViewModel.new(player_id, tracked_army_id)
	else:
		_view_model.set_player_context(player_id, tracked_army_id)
	if _analytics_vm == null:
		_analytics_vm = MetricAnalyticsViewModel.new(player_id, tracked_army_id)
	else:
		_analytics_vm.set_context(player_id, tracked_army_id)
	_build_hud_structure()
	_connect_event_bus()
	refresh_from_viewmodel()
	GraphicsQualityApplier.apply_safe_area_margins(self)
	_touch_bar = TouchActionBar.new()
	_touch_bar.offset_top = -118.0
	_touch_bar.offset_bottom = -64.0
	add_child(_touch_bar)
	var sh: GameShellCoordinator = get_game_shell()
	if sh != null:
		_touch_bar.pause_requested.connect(sh.open_pause_menu)
		var st: GameShellViewModel.UserSettingsSnapshot = sh.get_view_model().load_user_settings()
		_touch_bar.refresh_visibility(st.touch_friendly_layout)


func set_mobile_rts_mode(enabled: bool) -> void:
	_build_hud_structure()
	_mobile_rts_mode = enabled
	if _top_pulse_margin != null:
		_top_pulse_margin.visible = not enabled
	if _tactical_lens_dock != null:
		_tactical_lens_dock.visible = not enabled
	if _analytics_dock != null:
		_analytics_dock.visible = not enabled
	if _session_clock_dock != null:
		_session_clock_dock.visible = not enabled
	if _crisis_chip_rail != null and enabled:
		_crisis_chip_rail.visible = false
	if _touch_bar != null:
		_touch_bar.visible = false if enabled else _touch_bar.visible


func _exit_tree() -> void:
	_kill_drawer_tween()
	_disconnect_event_bus()
	_disconnect_ui_signals()


func _unhandled_input(event: InputEvent) -> void:
	var focus_owner: Control = get_viewport().gui_get_focus_owner() if get_viewport() != null else null
	if focus_owner is LineEdit or focus_owner is TextEdit:
		return
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_1, KEY_KP_1:
			select_lens(GameEnums.TacticalMapLens.NORMAL)
			_mark_input_handled()
		KEY_2, KEY_KP_2:
			select_lens(GameEnums.TacticalMapLens.LOGISTICS_WATER_COURIER)
			_mark_input_handled()
		KEY_3, KEY_KP_3:
			select_lens(GameEnums.TacticalMapLens.YAYLAK_KISLAK)
			_mark_input_handled()
		KEY_4, KEY_KP_4:
			select_lens(GameEnums.TacticalMapLens.TUG_CONTROL)
			_mark_input_handled()
		KEY_5, KEY_KP_5:
			select_lens(GameEnums.TacticalMapLens.INTELLIGENCE_DUST)
			_mark_input_handled()
		KEY_F10:
			_build_hud_structure()
			if _game_shell != null:
				if _game_shell.is_any_screen_visible():
					_game_shell.close_all_menus()
				else:
					_game_shell.open_pause_menu()
				_mark_input_handled()
		KEY_ESCAPE:
			if _game_shell != null and _game_shell.is_any_screen_visible() and _game_shell.get_active_screen_id() != &"main_menu":
				_game_shell.close_all_menus()
				_mark_input_handled()
			elif _rich_tooltip != null and _rich_tooltip.visible:
				_rich_tooltip.hide_tooltip()
				_mark_input_handled()
			elif _metric_popover != null and _metric_popover.visible:
				close_metric_breakdown()
				_mark_input_handled()
			elif _empire_ledger != null and _empire_ledger.visible:
				close_ledger()
				_mark_input_handled()
			elif _research_tree_panel != null and _research_tree_panel.visible:
				close_research_tree()
				_mark_input_handled()
			elif _chronicle_feed != null and _chronicle_feed.visible:
				close_chronicle()
				_mark_input_handled()
			elif _drawer_open:
				close_drawer(false)
				_mark_input_handled()
			elif _game_shell != null:
				_game_shell.open_pause_menu()
				_mark_input_handled()


func set_player_context(p_player_id: int, p_tracked_army_id: int = -1) -> void:
	player_id = maxi(p_player_id, 1)
	if p_tracked_army_id > 0:
		tracked_army_id = p_tracked_army_id
	if _view_model == null:
		_view_model = OtukenHudViewModel.new(player_id, tracked_army_id)
	else:
		_view_model.set_player_context(player_id, tracked_army_id)
	if _analytics_vm == null:
		_analytics_vm = MetricAnalyticsViewModel.new(player_id, tracked_army_id)
	else:
		_analytics_vm.set_context(player_id, tracked_army_id)
	if _research_vm == null:
		_research_vm = ResearchTreeViewModel.new(player_id, tracked_army_id)
	else:
		_research_vm.set_context(player_id, tracked_army_id)
	if _research_tree_panel != null and _research_tree_panel.visible:
		_research_tree_panel.refresh_tree()
	if _ui_built:
		refresh_from_viewmodel()


func get_view_model() -> OtukenHudViewModel:
	if _view_model == null:
		_view_model = OtukenHudViewModel.new(player_id, tracked_army_id)
	return _view_model


func get_analytics_view_model() -> MetricAnalyticsViewModel:
	if _analytics_vm == null:
		_analytics_vm = MetricAnalyticsViewModel.new(player_id, tracked_army_id)
	return _analytics_vm


func get_research_view_model() -> ResearchTreeViewModel:
	if _research_vm == null:
		_research_vm = ResearchTreeViewModel.new(player_id, tracked_army_id)
	return _research_vm


func get_glossary_tooltip() -> SteppeGlossaryTooltip:
	_build_hud_structure()
	return _glossary_tooltip


func get_top_pulse_card_count() -> int:
	_build_hud_structure()
	return _pulse_cards.size()


func get_lens_button_count() -> int:
	_build_hud_structure()
	return _lens_options.size()


func get_active_crisis_chip_count() -> int:
	_build_hud_structure()
	return _crisis_chips.size()


func get_active_lens() -> GameEnums.TacticalMapLens:
	return _active_lens


func select_lens(target_lens: GameEnums.TacticalMapLens, emit_bus: bool = true) -> bool:
	_build_hud_structure()
	var prev_lens: GameEnums.TacticalMapLens = _active_lens
	_active_lens = target_lens
	_sync_lens_buttons()
	if emit_bus and prev_lens != target_lens:
		EventBus.tactical_lens_changed.emit(prev_lens, target_lens)
	return prev_lens != target_lens


func open_drawer(slot_id: StringName = &"", instant: bool = false) -> bool:
	_build_hud_structure()
	var resolved_slot: StringName = slot_id if (slot_id != &"" and _drawer_slots.has(slot_id)) else _active_drawer_slot
	if not _drawer_slots.has(resolved_slot):
		return false
	_active_drawer_slot = resolved_slot
	_sync_drawer_slot_visibility()

	_drawer_open = true
	_analysis_drawer_card.visible = true
	_analysis_drawer_card.mouse_filter = Control.MOUSE_FILTER_STOP
	_kill_drawer_tween()

	if instant or not is_inside_tree():
		_set_drawer_x(DRAWER_OPEN_OFFSET_X)
	else:
		_drawer_tween = create_tween()
		_drawer_tween.set_trans(Tween.TRANS_CUBIC)
		_drawer_tween.set_ease(Tween.EASE_OUT)
		_drawer_tween.tween_method(_set_drawer_x, _analysis_drawer_card.offset_left, DRAWER_OPEN_OFFSET_X, drawer_tween_duration_sec)
		_drawer_tween.finished.connect(_on_drawer_open_tween_finished)

	drawer_state_changed.emit(true, _active_drawer_slot)
	return true


func close_drawer(instant: bool = false) -> void:
	_build_hud_structure()
	_drawer_open = false
	_kill_drawer_tween()
	if instant or not is_inside_tree():
		_set_drawer_x(DRAWER_CLOSED_OFFSET_X)
		_analysis_drawer_card.visible = false
		_analysis_drawer_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		_drawer_tween = create_tween()
		_drawer_tween.set_trans(Tween.TRANS_CUBIC)
		_drawer_tween.set_ease(Tween.EASE_IN)
		_drawer_tween.tween_method(_set_drawer_x, _analysis_drawer_card.offset_left, DRAWER_CLOSED_OFFSET_X, drawer_tween_duration_sec)
		_drawer_tween.finished.connect(_on_drawer_close_tween_finished)
	drawer_state_changed.emit(false, _active_drawer_slot)


func toggle_drawer(slot_id: StringName = &"", instant: bool = false) -> bool:
	var requested_slot: StringName = slot_id if slot_id != &"" else _active_drawer_slot
	if _drawer_open and requested_slot == _active_drawer_slot:
		close_drawer(instant)
		return false
	return open_drawer(requested_slot, instant)


func is_drawer_open() -> bool:
	return _drawer_open


func is_drawer_tween_running() -> bool:
	return _drawer_tween != null and _drawer_tween.is_valid() and _drawer_tween.is_running()


func get_active_drawer_slot() -> StringName:
	return _active_drawer_slot


func has_drawer_slot(slot_id: StringName) -> bool:
	_build_hud_structure()
	return _drawer_slots.has(slot_id)


func get_registered_slot_ids() -> PackedStringArray:
	_build_hud_structure()
	var ids: PackedStringArray = PackedStringArray()
	for sid: StringName in _drawer_slot_order:
		ids.append(String(sid))
	return ids


func get_drawer_slot_container(slot_id: StringName) -> Control:
	_build_hud_structure()
	var rec: DrawerSlotRecord = _drawer_slots.get(slot_id, null)
	return rec.custom_panel_mount if rec != null else null


func register_drawer_slot(slot_id: StringName, title: String, accent_tone: StringName = &"bronze") -> Control:
	_build_hud_structure()
	if _drawer_slots.has(slot_id):
		var existing: DrawerSlotRecord = _drawer_slots[slot_id]
		return existing.custom_panel_mount

	var tab_btn: Button = Button.new()
	tab_btn.name = "DrawerTab_%s" % String(slot_id)
	tab_btn.theme_type_variation = &"GhostIconButton"
	tab_btn.text = title
	OtukenThemeFactory.apply_button_semantic_styles(tab_btn, NeoSteppePalette.get_semantic_color(accent_tone), false, 6, 3)
	var tab_cb: Callable = _on_drawer_tab_pressed.bind(slot_id)
	tab_btn.pressed.connect(tab_cb)
	_drawer_tabs_hbox.add_child(tab_btn)

	var slot_box: VBoxContainer = VBoxContainer.new()
	slot_box.name = "Slot_%s" % String(slot_id)
	slot_box.visible = false
	slot_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	slot_box.add_theme_constant_override(&"separation", 8)
	_drawer_slot_host.add_child(slot_box)

	var domain_header: Label = Label.new()
	domain_header.name = "DomainHeader"
	domain_header.theme_type_variation = &"TitleLabel"
	domain_header.text = title.to_upper()
	slot_box.add_child(domain_header)

	var summary_panel: PanelContainer = PanelContainer.new()
	summary_panel.name = "SlotTelemetryBox"
	summary_panel.add_theme_stylebox_override(&"panel", OtukenThemeFactory.build_card_style(
		NeoSteppePalette.get_semantic_color(accent_tone), 1, NeoSteppePalette.CHARCOAL_SURFACE, 8, 6))
	slot_box.add_child(summary_panel)

	var summary_lbl: Label = Label.new()
	summary_lbl.name = "SlotSummaryLabel"
	summary_lbl.theme_type_variation = &"Label"
	summary_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_panel.add_child(summary_lbl)

	var mount_host: VBoxContainer = VBoxContainer.new()
	mount_host.name = "CustomPanelMount_%s" % String(slot_id)
	mount_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mount_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mount_host.add_theme_constant_override(&"separation", 6)
	slot_box.add_child(mount_host)

	var rec: DrawerSlotRecord = DrawerSlotRecord.new(
		slot_id, title, accent_tone, tab_btn, tab_cb, slot_box, summary_lbl, mount_host)
	_drawer_slots[slot_id] = rec
	_drawer_slot_order.append(slot_id)
	_attach_domain_glossary_strip(slot_id, slot_box)
	_sync_drawer_slot_visibility()
	return mount_host


func mount_panel_to_slot(slot_id: StringName, panel: Control) -> bool:
	if panel == null:
		return false
	var mount_target: Control = get_drawer_slot_container(slot_id)
	if mount_target == null:
		return false
	if panel.get_parent() != null:
		panel.get_parent().remove_child(panel)
	mount_target.add_child(panel)
	return true


func get_session_clock_dock() -> Control:
	_build_hud_structure()
	return _session_clock_dock


func get_session_clock_mode_text() -> String:
	_build_hud_structure()
	return _clock_mode_label.text if _clock_mode_label != null else ""


func get_session_pause_button() -> Button:
	_build_hud_structure()
	return _clock_pause_btn


func get_session_speed_button(speed_scale_int: int) -> Button:
	_build_hud_structure()
	return _clock_speed_buttons.get(speed_scale_int, null)


func request_session_pause(paused: bool) -> bool:
	var sender_str: String = str(player_id)
	var base_seq: int = maxi(CommandBus.get_last_sequence_for_sender(sender_str), _clock_envelope_seq)
	_clock_envelope_seq = base_seq + CommandBus.get_pending_envelope_count() + 1
	var cur_tick: int = SessionClockAuthority.get_current_tick()
	var env: CommandEnvelope = CommandEnvelope.new(
		_clock_envelope_seq,
		sender_str,
		cur_tick,
		"pause_session" if paused else "resume_session",
		{"paused": paused})
	var accepted: bool = CommandBus.enqueue_envelope(env, cur_tick)
	if accepted:
		CommandBus.flush_envelopes_for_tick(cur_tick)
	refresh_from_viewmodel()
	return accepted


func request_session_speed(speed_scale: float) -> bool:
	var sender_str: String = str(player_id)
	var base_seq: int = maxi(CommandBus.get_last_sequence_for_sender(sender_str), _clock_envelope_seq)
	_clock_envelope_seq = base_seq + CommandBus.get_pending_envelope_count() + 1
	var cur_tick: int = SessionClockAuthority.get_current_tick()
	var env: CommandEnvelope = CommandEnvelope.new(
		_clock_envelope_seq,
		sender_str,
		cur_tick,
		"set_tempo_speed",
		{"speed_scale": speed_scale})
	var accepted: bool = CommandBus.enqueue_envelope(env, cur_tick)
	if accepted:
		CommandBus.flush_envelopes_for_tick(cur_tick)
	refresh_from_viewmodel()
	return accepted


func bind_analytics_scene_context(
		camera: DualLayerCamera,
		world_state: MacroWorldState = null,
		army_registry: ArmyRegistry = null,
		tracked_army: ArmyController = null) -> void:
	_camera_ref = weakref(camera) if camera != null else null
	var vm: MetricAnalyticsViewModel = get_analytics_view_model()
	if world_state != null:
		vm.bind_world_state(world_state)
	if army_registry != null:
		vm.bind_army_registry(army_registry)
	if tracked_army != null:
		vm.bind_tracked_army(tracked_army)
	if _chronicle_feed != null:
		_chronicle_feed.bind_camera(camera)
		_chronicle_feed.refresh_chronicle()
	if _empire_ledger != null:
		_empire_ledger.bind_camera(camera)
		_empire_ledger.refresh_ledger()
	var rvm: ResearchTreeViewModel = get_research_view_model()
	if tracked_army != null:
		rvm.bind_army(tracked_army)
	if _research_tree_panel != null and _research_tree_panel.visible:
		_research_tree_panel.refresh_tree()


func open_metric_breakdown(metric_id: StringName) -> void:
	_build_hud_structure()
	if _metric_popover != null:
		_metric_popover.open_metric(metric_id, get_analytics_view_model())


func close_metric_breakdown() -> void:
	if _metric_popover != null:
		_metric_popover.close_popover()


func get_metric_breakdown_popover() -> MetricBreakdownPopover:
	_build_hud_structure()
	return _metric_popover


func get_metric_button(metric_id: StringName) -> Button:
	_build_hud_structure()
	if _metric_chip_buttons.has(metric_id):
		return _metric_chip_buttons[metric_id]
	return null


func open_chronicle(filter_category: StringName = &"") -> void:
	_build_hud_structure()
	if _chronicle_feed != null:
		_chronicle_feed.open_feed(filter_category)
		_sync_analytics_dock_buttons()


func close_chronicle() -> void:
	if _chronicle_feed != null:
		_chronicle_feed.close_feed()
		_sync_analytics_dock_buttons()


func toggle_chronicle() -> bool:
	_build_hud_structure()
	if _chronicle_feed != null and _chronicle_feed.visible:
		close_chronicle()
		return false
	open_chronicle()
	return true


func get_chronicle_feed() -> SteppeChronicleFeed:
	_build_hud_structure()
	return _chronicle_feed


func open_ledger(tab_id: StringName = &"") -> void:
	_build_hud_structure()
	if _empire_ledger != null:
		_empire_ledger.open_ledger(tab_id)
		_sync_analytics_dock_buttons()


func close_ledger() -> void:
	if _empire_ledger != null:
		_empire_ledger.close_ledger()
		_sync_analytics_dock_buttons()


func toggle_ledger() -> bool:
	_build_hud_structure()
	if _empire_ledger != null and _empire_ledger.visible:
		close_ledger()
		return false
	open_ledger()
	return true


func get_empire_ledger_panel() -> EmpireLedgerPanel:
	_build_hud_structure()
	return _empire_ledger


func open_research_tree(node_id: StringName = &"") -> void:
	_build_hud_structure()
	if _research_tree_panel != null:
		_research_tree_panel.open_tree(node_id)
		_sync_analytics_dock_buttons()


func close_research_tree() -> void:
	if _research_tree_panel != null:
		_research_tree_panel.close_tree()
		_sync_analytics_dock_buttons()


func toggle_research_tree() -> bool:
	_build_hud_structure()
	if _research_tree_panel != null and _research_tree_panel.visible:
		close_research_tree()
		return false
	open_research_tree()
	return true


func get_research_tree_panel() -> TraditionResearchTreePanel:
	_build_hud_structure()
	return _research_tree_panel


func get_research_toggle_button() -> Button:
	_build_hud_structure()
	return _research_toggle_btn


func get_alert_toast_stack() -> AlertToastStack:
	_build_hud_structure()
	return _toast_stack


func get_rich_tooltip_controller() -> RichTermTooltipController:
	_build_hud_structure()
	return _rich_tooltip


func get_game_shell() -> GameShellCoordinator:
	_build_hud_structure()
	return _game_shell


func push_alert_toast(
		title: String,
		detail: String,
		tone_id: StringName = &"gold",
		focus_coord: Vector2i = Vector2i.ZERO,
		target_drawer_slot: StringName = &"",
		auto_dismiss_sec: float = 6.5) -> StringName:
	_build_hud_structure()
	if _toast_stack == null:
		return &""
	return _toast_stack.push_toast(title, detail, tone_id, focus_coord, target_drawer_slot, auto_dismiss_sec)


func compute_open_map_ratio(include_drawer: bool = false) -> float:
	_build_hud_structure()
	var vp_size: Vector2 = _resolve_viewport_size()
	var total_area: float = maxf(vp_size.x * vp_size.y, 1.0)
	var occupied: float = 0.0

	if _top_pulse_margin != null and _top_pulse_margin.visible:
		occupied += _measure_control_area(_top_pulse_margin, vp_size)
	if _tactical_lens_dock != null and _tactical_lens_dock.visible:
		occupied += _measure_control_area(_tactical_lens_dock, vp_size)
	if _analytics_dock != null and _analytics_dock.visible:
		occupied += _measure_control_area(_analytics_dock, vp_size)
	if _session_clock_dock != null and _session_clock_dock.visible:
		occupied += _measure_control_area(_session_clock_dock, vp_size)
	if _metric_popover != null and _metric_popover.visible:
		occupied += _measure_control_area(_metric_popover, vp_size)
	if _chronicle_feed != null and _chronicle_feed.visible:
		occupied += _measure_control_area(_chronicle_feed, vp_size)
	if _empire_ledger != null and _empire_ledger.visible:
		occupied += _measure_control_area(_empire_ledger, vp_size)
	if _research_tree_panel != null and _research_tree_panel.visible:
		occupied += _measure_control_area(_research_tree_panel, vp_size)
	if _toast_stack != null and _toast_stack.visible and _toast_stack.get_active_toast_count() > 0:
		occupied += _measure_control_area(_toast_stack, vp_size)
	if _crisis_chip_rail != null and _crisis_chip_rail.visible and not _crisis_chips.is_empty():
		var chip_h: float = 0.0
		var chip_w: float = 204.0
		for chip: CrisisChipButton in _crisis_chips:
			var cs: Vector2 = chip.size.max(chip.custom_minimum_size)
			chip_w = maxf(chip_w, cs.x)
			chip_h += cs.y + 4.0
		occupied += chip_w * maxf(chip_h - 4.0, 0.0)
	if include_drawer and _drawer_open and _analysis_drawer_card != null and _analysis_drawer_card.visible:
		occupied += _measure_control_area(_analysis_drawer_card, vp_size)

	return clampf(1.0 - (occupied / total_area), 0.0, 1.0)


func refresh_from_viewmodel() -> void:
	_build_hud_structure()
	if _view_model == null:
		_view_model = OtukenHudViewModel.new(player_id, tracked_army_id)
	var snap: OtukenHudViewModel.PulseSummarySnapshot = _view_model.capture_snapshot()
	_apply_pulse_cards(snap)
	_apply_drawer_slot_summaries(snap)
	_apply_session_clock_controls(snap)
	_rebuild_crisis_chips(_view_model.collect_active_crises(snap))
	if _metric_popover != null and _metric_popover.visible:
		_metric_popover.refresh_active_metric()
	if _chronicle_feed != null and _chronicle_feed.visible:
		_chronicle_feed.refresh_chronicle()
	if _empire_ledger != null and _empire_ledger.visible:
		_empire_ledger.refresh_ledger()
	if _glossary_tooltip != null and _glossary_tooltip.visible and _glossary_tooltip.get_active_term_id() != &"":
		_glossary_tooltip.show_for_term(_glossary_tooltip.get_active_term_id(), Rect2(Vector2(24.0, 74.0), Vector2(180.0, 48.0)), _view_model)


func _build_hud_structure() -> void:
	if _ui_built:
		return
	_ui_built = true
	theme = OtukenThemeFactory.create_theme()

	# --- Layer 1A: Top Pulse Bar (strictly 4 unified cards) -------------------
	_top_pulse_margin = get_node_or_null("TopPulseMargin") as Control
	if _top_pulse_margin == null:
		_top_pulse_margin = Control.new()
		_top_pulse_margin.name = "TopPulseMargin"
		_top_pulse_margin.anchor_left = 0.0
		_top_pulse_margin.anchor_top = 0.0
		_top_pulse_margin.anchor_right = 1.0
		_top_pulse_margin.anchor_bottom = 0.0
		_top_pulse_margin.offset_left = 14.0
		_top_pulse_margin.offset_top = 8.0
		_top_pulse_margin.offset_right = -14.0
		_top_pulse_margin.offset_bottom = 64.0
		_top_pulse_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_top_pulse_margin)

	_top_pulse_hbox = _top_pulse_margin.get_node_or_null("TopPulseHBox") as HBoxContainer
	if _top_pulse_hbox == null:
		_top_pulse_hbox = HBoxContainer.new()
		_top_pulse_hbox.name = "TopPulseHBox"
		_top_pulse_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_top_pulse_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_top_pulse_hbox.add_theme_constant_override(&"separation", 10)
		_top_pulse_margin.add_child(_top_pulse_hbox)

	_ensure_pulse_card("PulseCardEconomy", OtukenHudViewModel.SLOT_ECONOMY_WATER, "ERZAK / SU & KIŞ UFKU", &"zud", "Zud", [MetricAnalyticsViewModel.METRIC_SU, MetricAnalyticsViewModel.METRIC_HAZINE])
	_ensure_pulse_card("PulseCardKut", OtukenHudViewModel.SLOT_GOVERNANCE_DYNASTY, "KUT & VERASET DENGESİ", &"kut", "Kut", [MetricAnalyticsViewModel.METRIC_NUFUS, MetricAnalyticsViewModel.METRIC_KUT, MetricAnalyticsViewModel.METRIC_ULUS])
	_ensure_pulse_card("PulseCardYilki", OtukenHudViewModel.SLOT_MILITARY_HERD, "YILKI & MANEVRA GÜCÜ", &"yilki", "Yılkı", [MetricAnalyticsViewModel.METRIC_YILKI, MetricAnalyticsViewModel.METRIC_ORDU])
	_ensure_pulse_card("PulseCardSeason", OtukenHudViewModel.SLOT_TERRITORY_ECOLOGY, "MEVSİM / TÖRE BARIŞI", &"tore_barisi", "Töre", [])

	# --- Layer 1B: Right-edge Crisis Chip Rail (active emergencies only) -----
	_crisis_chip_rail = get_node_or_null("CrisisChipRail") as VBoxContainer
	if _crisis_chip_rail == null:
		_crisis_chip_rail = VBoxContainer.new()
		_crisis_chip_rail.name = "CrisisChipRail"
		_crisis_chip_rail.anchor_left = 1.0
		_crisis_chip_rail.anchor_top = 0.0
		_crisis_chip_rail.anchor_right = 1.0
		_crisis_chip_rail.anchor_bottom = 0.0
		_crisis_chip_rail.offset_left = -220.0
		_crisis_chip_rail.offset_top = 72.0
		_crisis_chip_rail.offset_right = -14.0
		_crisis_chip_rail.offset_bottom = 320.0
		_crisis_chip_rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_crisis_chip_rail.visible = false
		_crisis_chip_rail.add_theme_constant_override(&"separation", 4)
		add_child(_crisis_chip_rail)

	# --- Layer 2: Single-key Tactical Map Lens Bar ---------------------------
	_tactical_lens_dock = get_node_or_null("TacticalLensDock") as Control
	if _tactical_lens_dock == null:
		_tactical_lens_dock = Control.new()
		_tactical_lens_dock.name = "TacticalLensDock"
		_tactical_lens_dock.anchor_left = 0.0
		_tactical_lens_dock.anchor_top = 1.0
		_tactical_lens_dock.anchor_right = 0.0
		_tactical_lens_dock.anchor_bottom = 1.0
		_tactical_lens_dock.offset_left = 14.0
		_tactical_lens_dock.offset_top = -44.0
		_tactical_lens_dock.offset_right = 540.0
		_tactical_lens_dock.offset_bottom = -8.0
		_tactical_lens_dock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_tactical_lens_dock)

	_tactical_lens_card = _tactical_lens_dock.get_node_or_null("TacticalLensCard") as TamgaCardPanel
	if _tactical_lens_card == null:
		_tactical_lens_card = TamgaCardPanel.new()
		_tactical_lens_card.name = "TacticalLensCard"
		_tactical_lens_card.card_id = &"tactical_lens_bar"
		_tactical_lens_card.semantic_tone = &"gold"
		_tactical_lens_card.clickable = false
		_tactical_lens_card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_tactical_lens_dock.add_child(_tactical_lens_card)

	var lens_margin: MarginContainer = _tactical_lens_card.get_content_container()
	lens_margin.add_theme_constant_override(&"margin_left", 6)
	lens_margin.add_theme_constant_override(&"margin_right", 6)
	lens_margin.add_theme_constant_override(&"margin_top", 2)
	lens_margin.add_theme_constant_override(&"margin_bottom", 2)

	_tactical_lens_hbox = HBoxContainer.new()
	_tactical_lens_hbox.name = "TacticalLensButtons"
	_tactical_lens_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_tactical_lens_hbox.add_theme_constant_override(&"separation", 4)
	lens_margin.add_child(_tactical_lens_hbox)

	_add_lens_option(GameEnums.TacticalMapLens.NORMAL, 1, "1 Normal", &"gold")
	_add_lens_option(GameEnums.TacticalMapLens.LOGISTICS_WATER_COURIER, 2, "2 Su", &"ice")
	_add_lens_option(GameEnums.TacticalMapLens.YAYLAK_KISLAK, 3, "3 Yaylak", &"jade")
	_add_lens_option(GameEnums.TacticalMapLens.TUG_CONTROL, 4, "4 Tuğ", &"jade")
	_add_lens_option(GameEnums.TacticalMapLens.INTELLIGENCE_DUST, 5, "5 Toz", &"ember")
	_sync_lens_buttons()

	# --- Layer 2A: Compact Chronicle & Empire Ledger Toggle Strip ------------
	_analytics_dock = get_node_or_null("AnalyticsOverlayDock") as Control
	if _analytics_dock == null:
		_analytics_dock = Control.new()
		_analytics_dock.name = "AnalyticsOverlayDock"
		_analytics_dock.anchor_left = 0.0
		_analytics_dock.anchor_top = 1.0
		_analytics_dock.anchor_right = 0.0
		_analytics_dock.anchor_bottom = 1.0
		_analytics_dock.offset_left = 544.0
		_analytics_dock.offset_top = -36.0
		_analytics_dock.offset_right = 732.0
		_analytics_dock.offset_bottom = -8.0
		_analytics_dock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_analytics_dock)

	_analytics_card = _analytics_dock.get_node_or_null("AnalyticsOverlayCard") as TamgaCardPanel
	if _analytics_card == null:
		_analytics_card = TamgaCardPanel.new()
		_analytics_card.name = "AnalyticsOverlayCard"
		_analytics_card.card_id = &"analytics_toggle_dock"
		_analytics_card.semantic_tone = &"gold"
		_analytics_card.clickable = false
		_analytics_card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_analytics_dock.add_child(_analytics_card)

	var ad_margin: MarginContainer = _analytics_card.get_content_container()
	ad_margin.add_theme_constant_override(&"margin_left", 4)
	ad_margin.add_theme_constant_override(&"margin_right", 4)
	ad_margin.add_theme_constant_override(&"margin_top", 1)
	ad_margin.add_theme_constant_override(&"margin_bottom", 1)

	var ad_hbox: HBoxContainer = HBoxContainer.new()
	ad_hbox.name = "AnalyticsToggleHBox"
	ad_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	ad_hbox.add_theme_constant_override(&"separation", 3)
	ad_margin.add_child(ad_hbox)

	_chronicle_toggle_btn = Button.new()
	_chronicle_toggle_btn.name = "ChronicleToggleButton"
	_chronicle_toggle_btn.theme_type_variation = &"LensButton"
	_chronicle_toggle_btn.text = "Vakanüvis"
	_chronicle_toggle_btn.add_theme_font_size_override(&"font_size", 9)
	_chronicle_toggle_cb = _on_chronicle_toggle_pressed
	_chronicle_toggle_btn.pressed.connect(_chronicle_toggle_cb)
	ad_hbox.add_child(_chronicle_toggle_btn)

	_ledger_toggle_btn = Button.new()
	_ledger_toggle_btn.name = "LedgerToggleButton"
	_ledger_toggle_btn.theme_type_variation = &"LensButton"
	_ledger_toggle_btn.text = "Defter"
	_ledger_toggle_btn.add_theme_font_size_override(&"font_size", 9)
	_ledger_toggle_cb = _on_ledger_toggle_pressed
	_ledger_toggle_btn.pressed.connect(_ledger_toggle_cb)
	ad_hbox.add_child(_ledger_toggle_btn)

	_research_toggle_btn = Button.new()
	_research_toggle_btn.name = "ResearchToggleButton"
	_research_toggle_btn.theme_type_variation = &"LensButton"
	_research_toggle_btn.text = "Araştır"
	_research_toggle_btn.add_theme_font_size_override(&"font_size", 9)
	_research_toggle_cb = _on_research_toggle_pressed
	_research_toggle_btn.pressed.connect(_research_toggle_cb)
	ad_hbox.add_child(_research_toggle_btn)
	_sync_analytics_dock_buttons()

	# --- Layer 2B: Unified Session Clock & Tempo Strip (Faz 31) --------------
	_session_clock_dock = get_node_or_null("SessionClockDock") as Control
	if _session_clock_dock == null:
		_session_clock_dock = Control.new()
		_session_clock_dock.name = "SessionClockDock"
		_session_clock_dock.anchor_left = 1.0
		_session_clock_dock.anchor_top = 1.0
		_session_clock_dock.anchor_right = 1.0
		_session_clock_dock.anchor_bottom = 1.0
		_session_clock_dock.offset_left = -290.0
		_session_clock_dock.offset_top = -50.0
		_session_clock_dock.offset_right = -14.0
		_session_clock_dock.offset_bottom = -8.0
		_session_clock_dock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_session_clock_dock)

	_session_clock_card = _session_clock_dock.get_node_or_null("SessionClockCard") as TamgaCardPanel
	if _session_clock_card == null:
		_session_clock_card = TamgaCardPanel.new()
		_session_clock_card.name = "SessionClockCard"
		_session_clock_card.card_id = &"session_clock_bar"
		_session_clock_card.semantic_tone = &"gold"
		_session_clock_card.clickable = false
		_session_clock_card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_session_clock_dock.add_child(_session_clock_card)

	var clock_margin: MarginContainer = _session_clock_card.get_content_container()
	clock_margin.add_theme_constant_override(&"margin_left", 8)
	clock_margin.add_theme_constant_override(&"margin_right", 8)
	clock_margin.add_theme_constant_override(&"margin_top", 4)
	clock_margin.add_theme_constant_override(&"margin_bottom", 4)

	var clock_hbox: HBoxContainer = HBoxContainer.new()
	clock_hbox.name = "SessionClockHBox"
	clock_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	clock_hbox.add_theme_constant_override(&"separation", 4)
	clock_margin.add_child(clock_hbox)

	_clock_mode_label = Label.new()
	_clock_mode_label.name = "SessionClockModeLabel"
	_clock_mode_label.theme_type_variation = &"CaptionLabel"
	_clock_mode_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_clock_mode_label.clip_text = true
	_clock_mode_label.add_theme_font_size_override(&"font_size", NeoSteppePalette.FONT_SIZE_MICRO)
	_clock_mode_label.text = "TEKİL · T0"
	clock_hbox.add_child(_clock_mode_label)

	_clock_pause_btn = Button.new()
	_clock_pause_btn.name = "SessionPauseButton"
	_clock_pause_btn.theme_type_variation = &"LensButton"
	_clock_pause_btn.text = "Duraklat"
	_clock_pause_btn.add_theme_font_size_override(&"font_size", NeoSteppePalette.FONT_SIZE_MICRO)
	_clock_pause_cb = _on_clock_pause_pressed
	_clock_pause_btn.pressed.connect(_clock_pause_cb)
	clock_hbox.add_child(_clock_pause_btn)

	for speed_val: int in [1, 2, 4]:
		var sbtn: Button = Button.new()
		sbtn.name = "ClockSpeedBtn_%d" % speed_val
		sbtn.theme_type_variation = &"LensButton"
		sbtn.text = "%dx" % speed_val
		sbtn.add_theme_font_size_override(&"font_size", NeoSteppePalette.FONT_SIZE_MICRO)
		var scb: Callable = _on_clock_speed_pressed.bind(float(speed_val))
		sbtn.pressed.connect(scb)
		clock_hbox.add_child(sbtn)
		_clock_speed_buttons[speed_val] = sbtn
		_clock_speed_callbacks[sbtn] = scb

	# --- Layer 3: Modular Sliding Analysis Drawer ----------------------------
	_analysis_drawer_card = get_node_or_null("AnalysisDrawerPanel") as TamgaCardPanel
	if _analysis_drawer_card == null:
		_analysis_drawer_card = TamgaCardPanel.new()
		_analysis_drawer_card.name = "AnalysisDrawerPanel"
		_analysis_drawer_card.card_id = &"analysis_drawer"
		_analysis_drawer_card.theme_type_variation = &"DrawerPanel"
		_analysis_drawer_card.semantic_tone = &"gold"
		_analysis_drawer_card.clickable = false
		_analysis_drawer_card.anchor_left = 0.0
		_analysis_drawer_card.anchor_top = 0.0
		_analysis_drawer_card.anchor_right = 0.0
		_analysis_drawer_card.anchor_bottom = 1.0
		_analysis_drawer_card.offset_left = DRAWER_CLOSED_OFFSET_X
		_analysis_drawer_card.offset_top = 72.0
		_analysis_drawer_card.offset_right = DRAWER_CLOSED_OFFSET_X + DRAWER_WIDTH_PX
		_analysis_drawer_card.offset_bottom = -60.0
		_analysis_drawer_card.visible = false
		_analysis_drawer_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_analysis_drawer_card)

	var drawer_vbox: VBoxContainer = VBoxContainer.new()
	drawer_vbox.name = "DrawerRootLayout"
	drawer_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	drawer_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	drawer_vbox.add_theme_constant_override(&"separation", 8)
	_analysis_drawer_card.get_content_container().add_child(drawer_vbox)

	var drawer_header: HBoxContainer = HBoxContainer.new()
	drawer_header.name = "DrawerHeaderRow"
	drawer_header.add_theme_constant_override(&"separation", 6)
	drawer_vbox.add_child(drawer_header)

	_drawer_title_label = Label.new()
	_drawer_title_label.name = "DrawerTitleLabel"
	_drawer_title_label.theme_type_variation = &"TitleLabel"
	_drawer_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_drawer_title_label.text = "OTAĞ ANALİZ ÇEKMECESİ"
	drawer_header.add_child(_drawer_title_label)

	_drawer_close_btn = Button.new()
	_drawer_close_btn.name = "DrawerCloseButton"
	_drawer_close_btn.theme_type_variation = &"GhostIconButton"
	_drawer_close_btn.text = "✕"
	OtukenThemeFactory.apply_button_semantic_styles(_drawer_close_btn, NeoSteppePalette.BRONZE_WEATHERED, false, 7, 3)
	_drawer_close_btn.pressed.connect(_on_drawer_close_pressed)
	drawer_header.add_child(_drawer_close_btn)

	_drawer_tabs_hbox = HFlowContainer.new()
	_drawer_tabs_hbox.name = "DrawerSlotTabs"
	_drawer_tabs_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_drawer_tabs_hbox.add_theme_constant_override(&"h_separation", 4)
	_drawer_tabs_hbox.add_theme_constant_override(&"v_separation", 4)
	drawer_vbox.add_child(_drawer_tabs_hbox)

	drawer_vbox.add_child(HSeparator.new())

	var drawer_scroll: ScrollContainer = ScrollContainer.new()
	drawer_scroll.name = "DrawerScrollContainer"
	drawer_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	drawer_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	drawer_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	drawer_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	drawer_scroll.custom_minimum_size = Vector2(0.0, 220.0)
	drawer_vbox.add_child(drawer_scroll)

	_drawer_slot_host = MarginContainer.new()
	_drawer_slot_host.name = "DrawerSlotHost"
	_drawer_slot_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_drawer_slot_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	drawer_scroll.add_child(_drawer_slot_host)

	# --- Floating Faz A Analytical Popover, Chronicle Feed & Empire Ledger ---
	var vm_analytics: MetricAnalyticsViewModel = get_analytics_view_model()

	_metric_popover = get_node_or_null("MetricBreakdownPopover") as MetricBreakdownPopover
	if _metric_popover == null:
		_metric_popover = MetricBreakdownPopover.new()
		_metric_popover.anchor_left = 0.5
		_metric_popover.anchor_top = 0.0
		_metric_popover.anchor_right = 0.5
		_metric_popover.anchor_bottom = 0.0
		_metric_popover.offset_left = -230.0
		_metric_popover.offset_top = 74.0
		_metric_popover.offset_right = 230.0
		_metric_popover.offset_bottom = 456.0
		add_child(_metric_popover)
	_metric_popover.bind_view_model(vm_analytics)
	_popover_action_cb = _on_popover_quick_action_requested
	if not _metric_popover.quick_action_requested.is_connected(_popover_action_cb):
		_metric_popover.quick_action_requested.connect(_popover_action_cb)

	_chronicle_feed = get_node_or_null("SteppeChronicleFeed") as SteppeChronicleFeed
	if _chronicle_feed == null:
		_chronicle_feed = SteppeChronicleFeed.new()
		_chronicle_feed.anchor_left = 0.0
		_chronicle_feed.anchor_top = 1.0
		_chronicle_feed.anchor_right = 0.0
		_chronicle_feed.anchor_bottom = 1.0
		_chronicle_feed.offset_left = 14.0
		_chronicle_feed.offset_top = -410.0
		_chronicle_feed.offset_right = 414.0
		_chronicle_feed.offset_bottom = -58.0
		add_child(_chronicle_feed)
	_chronicle_feed.bind_view_model(vm_analytics)
	_chronicle_focus_cb = _on_analytics_focus_requested
	if not _chronicle_feed.chronicle_focus_requested.is_connected(_chronicle_focus_cb):
		_chronicle_feed.chronicle_focus_requested.connect(_chronicle_focus_cb)

	_empire_ledger = get_node_or_null("EmpireLedgerPanel") as EmpireLedgerPanel
	if _empire_ledger == null:
		_empire_ledger = EmpireLedgerPanel.new()
		_empire_ledger.anchor_left = 0.5
		_empire_ledger.anchor_top = 0.5
		_empire_ledger.anchor_right = 0.5
		_empire_ledger.anchor_bottom = 0.5
		_empire_ledger.offset_left = -330.0
		_empire_ledger.offset_top = -200.0
		_empire_ledger.offset_right = 330.0
		_empire_ledger.offset_bottom = 200.0
		add_child(_empire_ledger)
	_empire_ledger.bind_view_model(vm_analytics)
	_ledger_focus_cb = _on_analytics_focus_requested
	if not _empire_ledger.ledger_focus_requested.is_connected(_ledger_focus_cb):
		_empire_ledger.ledger_focus_requested.connect(_ledger_focus_cb)

	_research_tree_panel = get_node_or_null("TraditionResearchTreePanel") as TraditionResearchTreePanel
	if _research_tree_panel == null:
		_research_tree_panel = TraditionResearchTreePanel.new()
		_research_tree_panel.anchor_left = 0.5
		_research_tree_panel.anchor_top = 0.5
		_research_tree_panel.anchor_right = 0.5
		_research_tree_panel.anchor_bottom = 0.5
		_research_tree_panel.offset_left = -395.0
		_research_tree_panel.offset_top = -215.0
		_research_tree_panel.offset_right = 395.0
		_research_tree_panel.offset_bottom = 215.0
		add_child(_research_tree_panel)
	_research_tree_panel.bind_view_model(get_research_view_model())

	_toast_stack = get_node_or_null("AlertToastStack") as AlertToastStack
	if _toast_stack == null:
		_toast_stack = AlertToastStack.new()
		_toast_stack.anchor_left = 1.0
		_toast_stack.anchor_top = 1.0
		_toast_stack.anchor_right = 1.0
		_toast_stack.anchor_bottom = 1.0
		_toast_stack.offset_left = -280.0
		_toast_stack.offset_top = -310.0
		_toast_stack.offset_right = -14.0
		_toast_stack.offset_bottom = -58.0
		add_child(_toast_stack)
	_toast_activated_cb = _on_toast_activated
	if not _toast_stack.toast_activated.is_connected(_toast_activated_cb):
		_toast_stack.toast_activated.connect(_toast_activated_cb)

	# --- Dual-Layer Hover-Lock Steppe Glossary Tooltip -----------------------
	_glossary_tooltip = get_node_or_null("SteppeGlossaryTooltip") as SteppeGlossaryTooltip
	if _glossary_tooltip == null:
		_glossary_tooltip = SteppeGlossaryTooltip.new()
		_glossary_tooltip.name = "SteppeGlossaryTooltip"
		add_child(_glossary_tooltip)
	_glossary_tooltip.set_view_model(get_view_model())
	move_child(_glossary_tooltip, get_child_count() - 1)

	_rich_tooltip = get_node_or_null("RichTermTooltipController") as RichTermTooltipController
	if _rich_tooltip == null:
		_rich_tooltip = RichTermTooltipController.new()
		add_child(_rich_tooltip)
	_rich_tooltip.set_hud_view_model(get_view_model())
	move_child(_rich_tooltip, get_child_count() - 1)

	_game_shell = get_node_or_null("GameShellCoordinator") as GameShellCoordinator
	if _game_shell == null:
		_game_shell = GameShellCoordinator.new()
		add_child(_game_shell)
	_game_shell.bind_analytics_view_model(get_analytics_view_model())
	_shell_settings_cb = _on_shell_settings_applied
	var sp_panel: SettingsPanel = _game_shell.get_settings_panel()
	if sp_panel != null and not sp_panel.settings_applied.is_connected(_shell_settings_cb):
		sp_panel.settings_applied.connect(_shell_settings_cb)
	move_child(_game_shell, get_child_count() - 1)

	# Register the 5 standard Phase 26-28 modular drawer slots cleanly
	register_drawer_slot(OtukenHudViewModel.SLOT_ECONOMY_WATER, "Erzak/Su", &"ice")
	register_drawer_slot(OtukenHudViewModel.SLOT_GOVERNANCE_DYNASTY, "Kut/Veraset", &"jade")
	register_drawer_slot(OtukenHudViewModel.SLOT_MILITARY_HERD, "Yılkı/Ordu", &"jade")
	register_drawer_slot(OtukenHudViewModel.SLOT_TERRITORY_ECOLOGY, "Otlak/Töre", &"gold")
	register_drawer_slot(OtukenHudViewModel.SLOT_WORLD_DIPLOMACY, "Dünya/Siyaset", &"ember")

	# Bind the 4 top bar card glossary badges after tooltip exists
	for i: int in range(_pulse_cards.size()):
		var pw: PulseCardWidgets = _pulse_cards[i]
		var term_ids: Array[StringName] = [&"kut", &"zud", &"yilki", &"tore_barisi"]
		if pw.slot_id == OtukenHudViewModel.SLOT_ECONOMY_WATER:
			term_ids = [&"zud"]
		elif pw.slot_id == OtukenHudViewModel.SLOT_GOVERNANCE_DYNASTY:
			term_ids = [&"kut"]
		elif pw.slot_id == OtukenHudViewModel.SLOT_MILITARY_HERD:
			term_ids = [&"yilki"]
		else:
			term_ids = [&"tore_barisi"]
		_bind_glossary_badge(pw.glossary_badge, term_ids[0])


func _ensure_pulse_card(
		node_name: String,
		slot_id: StringName,
		header_text: String,
		glossary_term: StringName,
		badge_text: String,
		metric_chips: Array[StringName] = []) -> void:
	var card: TamgaCardPanel = _top_pulse_hbox.get_node_or_null(node_name) as TamgaCardPanel
	if card == null:
		card = TamgaCardPanel.new()
		card.name = node_name
		_top_pulse_hbox.add_child(card)
	card.card_id = slot_id
	card.clickable = true
	card.semantic_tone = &"jade"
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var card_margin: MarginContainer = card.get_content_container()
	card_margin.add_theme_constant_override(&"margin_left", 7)
	card_margin.add_theme_constant_override(&"margin_right", 7)
	card_margin.add_theme_constant_override(&"margin_top", 2)
	card_margin.add_theme_constant_override(&"margin_bottom", 2)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.name = "PulseCardVBox"
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override(&"separation", 0)
	card_margin.add_child(vbox)

	var top_row: HBoxContainer = HBoxContainer.new()
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.add_theme_constant_override(&"separation", 4)
	vbox.add_child(top_row)

	var header_lbl: Label = Label.new()
	header_lbl.name = "HeaderLabel"
	header_lbl.theme_type_variation = &"CaptionLabel"
	header_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_lbl.clip_text = true
	header_lbl.add_theme_font_size_override(&"font_size", NeoSteppePalette.FONT_SIZE_MICRO)
	header_lbl.text = header_text
	top_row.add_child(header_lbl)

	var badge_btn: Button = Button.new()
	badge_btn.name = "GlossaryBadge_%s" % String(glossary_term)
	badge_btn.theme_type_variation = &"GhostIconButton"
	badge_btn.text = "%s ?" % badge_text
	badge_btn.add_theme_font_size_override(&"font_size", NeoSteppePalette.FONT_SIZE_MICRO)
	OtukenThemeFactory.apply_button_semantic_styles(badge_btn, NeoSteppePalette.BRONZE_WEATHERED, false, 4, 0)
	top_row.add_child(badge_btn)

	var primary_lbl: Label = Label.new()
	primary_lbl.name = "PrimaryMetricLabel"
	primary_lbl.theme_type_variation = &"MetricLabel"
	primary_lbl.clip_text = true
	primary_lbl.add_theme_font_size_override(&"font_size", NeoSteppePalette.FONT_SIZE_CAPTION)
	vbox.add_child(primary_lbl)

	var bottom_row: HBoxContainer = HBoxContainer.new()
	bottom_row.name = "CardBottomRow"
	bottom_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_row.add_theme_constant_override(&"separation", 3)
	vbox.add_child(bottom_row)

	var secondary_lbl: Label = Label.new()
	secondary_lbl.name = "SecondaryDetailLabel"
	secondary_lbl.theme_type_variation = &"MutedLabel"
	secondary_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	secondary_lbl.clip_text = true
	secondary_lbl.add_theme_font_size_override(&"font_size", 9)
	bottom_row.add_child(secondary_lbl)

	for mid: StringName in metric_chips:
		var mbtn: Button = Button.new()
		mbtn.name = "MetricChipBtn_%s" % String(mid)
		mbtn.theme_type_variation = &"GhostIconButton"
		mbtn.text = MetricBreakdownPopover.SWITCH_LABELS[mid] if MetricBreakdownPopover.SWITCH_LABELS.has(mid) else String(mid)
		mbtn.add_theme_font_size_override(&"font_size", 9)
		OtukenThemeFactory.apply_button_semantic_styles(mbtn, NeoSteppePalette.GOLD_TAMGA, false, 4, 0)
		var mcb: Callable = _on_metric_chip_pressed.bind(mid)
		mbtn.pressed.connect(mcb)
		bottom_row.add_child(mbtn)
		_metric_chip_buttons[mid] = mbtn
		_metric_chip_callbacks[mbtn] = mcb

	var card_cb: Callable = _on_pulse_card_clicked
	if not card.card_clicked.is_connected(card_cb):
		card.card_clicked.connect(card_cb)
	_card_click_callbacks[card] = card_cb

	_pulse_cards.append(PulseCardWidgets.new(card, slot_id, header_lbl, primary_lbl, secondary_lbl, badge_btn))


func _add_lens_option(
		lens: GameEnums.TacticalMapLens,
		key_number: int,
		title: String,
		tone_id: StringName) -> void:
	var btn: Button = Button.new()
	btn.name = "LensBtn_%d" % key_number
	btn.theme_type_variation = &"LensButton"
	btn.text = title
	var cb: Callable = _on_lens_button_pressed.bind(lens)
	btn.pressed.connect(cb)
	_tactical_lens_hbox.add_child(btn)
	_lens_options.append(LensOptionWidgets.new(lens, key_number, title, tone_id, btn, cb))


func _attach_domain_glossary_strip(slot_id: StringName, slot_box: VBoxContainer) -> void:
	var strip_title: Label = Label.new()
	strip_title.theme_type_variation = &"MutedLabel"
	strip_title.text = "İlgili Bozkır Kavramları (Üzerine gelerek Sabitle):"
	slot_box.add_child(strip_title)

	var chip_row: HFlowContainer = HFlowContainer.new()
	chip_row.add_theme_constant_override(&"h_separation", 6)
	chip_row.add_theme_constant_override(&"v_separation", 4)
	slot_box.add_child(chip_row)

	var terms: Array[StringName] = []
	if slot_id == OtukenHudViewModel.SLOT_ECONOMY_WATER:
		terms = [&"zud", &"kuyu_sabotaji", &"kara_borsa"]
	elif slot_id == OtukenHudViewModel.SLOT_GOVERNANCE_DYNASTY:
		terms = [&"kut", &"ulus", &"veraset", &"amanat"]
	elif slot_id == OtukenHudViewModel.SLOT_MILITARY_HERD:
		terms = [&"yilki", &"tug", &"gazi_mirasi", &"savas_nizami", &"toy"]
	elif slot_id == OtukenHudViewModel.SLOT_TERRITORY_ECOLOGY:
		terms = [&"kurgan", &"tore_barisi"]
	elif slot_id == SLOT_TACTICAL_COMMAND:
		terms = [&"yilki", &"tug", &"kuyu_sabotaji", &"gazi_mirasi", &"savas_nizami"]
	else:
		terms = [&"amanat", &"ulus", &"kara_borsa", &"sistemik_sinerji"]

	for tid: StringName in terms:
		var badge: Button = Button.new()
		badge.name = "SlotGlossary_%s_%s" % [String(slot_id), String(tid)]
		badge.theme_type_variation = &"GhostIconButton"
		var entry: SteppeGlossaryTooltip.GlossaryEntry = SteppeGlossaryTooltip.resolve_entry(tid, get_view_model())
		badge.text = entry.native_name
		OtukenThemeFactory.apply_button_semantic_styles(
			badge, NeoSteppePalette.get_semantic_color(entry.tone_id), false, 8, 2)
		chip_row.add_child(badge)
		_bind_glossary_badge(badge, tid)


func _bind_glossary_badge(badge: Button, term_id: StringName) -> void:
	if badge == null or _glossary_tooltip == null:
		return
	_glossary_tooltip.bind_control(badge, term_id)
	var click_cb: Callable = _on_glossary_badge_pressed.bind(badge, term_id)
	badge.pressed.connect(click_cb)
	_glossary_badges.append(badge)
	_glossary_click_callbacks[badge] = click_cb


func _apply_pulse_cards(snap: OtukenHudViewModel.PulseSummarySnapshot) -> void:
	if _pulse_cards.size() < 4:
		return

	# Card 1: Erzak / Su & Kış Ufku
	var c1: PulseCardWidgets = _pulse_cards[0]
	c1.primary_label.text = "Erzak %d · Kış %.1fM" % [snap.food_reserve, snap.winter_horizon_seasons]
	c1.secondary_label.text = "Su: %d · Gümüş %d · Çelik %d" % [
		snap.usable_water_sources, snap.silver_bullion, snap.steel_stockpile]
	c1.card.set_semantic_tone(snap.economy_tone, 0.85 if snap.economy_tone == &"ember" else 0.0)

	# Card 2: Kut & Veraset Dengesi
	var c2: PulseCardWidgets = _pulse_cards[1]
	c2.primary_label.text = "Kut %.0f · Meşr. %%%.0f" % [snap.kut_score, snap.legitimacy_multiplier * 100.0]
	var heir_str: String = "Rehin" if snap.heir_amanat_locked else ("Hazır" if snap.heir_ready else "Ergin Değil")
	c2.secondary_label.text = "%s (N%d) · Bölge %d/%d · %s" % [
		snap.ruler_name, snap.generation, snap.direct_regions, snap.direct_cap, heir_str]
	c2.card.set_semantic_tone(snap.kut_tone, 0.85 if snap.kut_tone == &"ember" else 0.0)

	# Card 3: Yılkı & Manevra Gücü
	var c3: PulseCardWidgets = _pulse_cards[2]
	c3.primary_label.text = "Yılkı %d · At %%%.0f" % [snap.yilki_herd_count, snap.remount_horse_ratio * 100.0]
	var supply_txt: String = "KESİK" if snap.supply_isolated else "Bağlı"
	var courier_txt: String = "Ulak Yolda" if snap.courier_in_transit else ("Toz" if snap.dust_decoy_active else "Hazır")
	c3.secondary_label.text = "İkmal %s · Hız %.2fx · %s" % [
		supply_txt, snap.expedition_speed_mult, courier_txt]
	c3.card.set_semantic_tone(snap.yilki_tone, 0.85 if snap.yilki_tone == &"ember" else 0.0)

	# Card 4: Mevsim / Töre Barışı
	var c4: PulseCardWidgets = _pulse_cards[3]
	var season_short: String = snap.season_display_name.split(" ")[0]
	c4.primary_label.text = "%s %%%.0f · %s" % [
		season_short, clampf(snap.season_progress * 100.0, 0.0, 100.0), OtukenHudViewModel.format_tore_stage_short(snap.tore_stage)]
	c4.secondary_label.text = "Yurt %d · Kurgan %d/%d · Tuğ %.0fm" % [
		snap.owned_regions, snap.player_kurgans, snap.total_kurgans, snap.tug_radius_m]
	c4.card.set_semantic_tone(snap.season_tone, 0.85 if snap.season_tone == &"ember" else 0.0)


func _apply_drawer_slot_summaries(snap: OtukenHudViewModel.PulseSummarySnapshot) -> void:
	var texts: Dictionary[StringName, String] = {
		OtukenHudViewModel.SLOT_ECONOMY_WATER: "Erzak: %d (Kış Ufku %.1f Mevsim)\nSu Kaynağı: %d · Çelik Kıtlık: %.2fx (Sinerji: %.2fx)\nGümüş: %d · Çelik: %d · Zanaatkar: %d" % [
			snap.food_reserve, snap.winter_horizon_seasons, snap.usable_water_sources,
			snap.market_scarcity_steel, snap.synergy_black_market_mult,
			snap.silver_bullion, snap.steel_stockpile, snap.artisan_count],
		OtukenHudViewModel.SLOT_GOVERNANCE_DYNASTY: "Kut: %.1f/100 (Drift %s%.2f) · Meşruiyet: %%%.0f\nHükümdar: %s (Nesil %d) · %s\nDoğrudan Bölge: %d/%d · Tâbi: %d (Sabotaj: %d)" % [
			snap.kut_score, "+" if snap.synergy_kut_drift >= 0.0 else "", snap.synergy_kut_drift,
			snap.legitimacy_multiplier * 100.0, snap.ruler_name, snap.generation,
			OtukenHudViewModel.format_regency_short(snap.regency_status), snap.direct_regions, snap.direct_cap,
			snap.delegated_regions, snap.silent_sabotage_beys],
		OtukenHudViewModel.SLOT_MILITARY_HERD: "Yılkı Sürüsü: %d · Yedek At: %%%.0f · Savaş Gücü: %.2fx\nNizam: %s · İkmal: %s · Kervan Açığı: %.1f · Tempo: %.2fx\nHız Çarpanı: %.2fx · Ulak: %s" % [
			snap.yilki_herd_count, snap.remount_horse_ratio * 100.0, snap.synergy_combat_power_mult,
			snap.active_battle_doctrine_name,
			"KESİLDİ" if snap.supply_isolated else "Bağlı", snap.caravan_ammo_deficit, snap.synergy_courier_tempo_mult,
			snap.expedition_speed_mult, "İFŞA" if snap.doctrine_plan_exposed else ("Yolda" if snap.courier_in_transit else "Hazır")],
		OtukenHudViewModel.SLOT_TERRITORY_ECOLOGY: "Mevsim: %s · %s\nBölge: %d · Kurgan: %d/%d · Tuğ Yarıçapı: %.0fm\nYeşim Otoritesi: %.2fx · Afet: %s" % [
			snap.season_display_name, OtukenHudViewModel.format_tore_stage_short(snap.tore_stage),
			snap.owned_regions, snap.player_kurgans, snap.total_kurgans, snap.tug_radius_m,
			snap.jade_authority_mult, String(snap.active_cataclysm_id) if snap.active_cataclysm_id != &"" else "Yok"],
		OtukenHudViewModel.SLOT_WORLD_DIPLOMACY: "Söz Güveni: %.0f/100 · Onur: %.0f · Dehşet: %.0f\nKoalisyon: %s (Baskı %.1f) · İç Hizip: %d\nÇöküş: %s · Rezonans: %d (%s)" % [
			snap.word_reliability, snap.honor_score, snap.dread_score,
			"AKTİF" if snap.coalition_active else "Yok", snap.synergy_coalition_pressure, snap.active_intrigue_plots,
			OtukenHudViewModel.format_collapse_state_short(snap.collapse_state),
			snap.synergy_active_resonance_count, snap.synergy_primary_resonance_name],
		SLOT_TACTICAL_COMMAND: "Ordu #%d (%s) · İkmal %s · Yedek At %%%.0f · Nizam %.2fx\nUlak: %s (Tempo %.2fx) · Toz Perdesi: %s" % [
			snap.tracked_army_id, snap.active_battle_doctrine_name, "KESİLDİ" if snap.supply_isolated else "Bağlı",
			snap.remount_horse_ratio * 100.0, snap.synergy_combat_power_mult,
			"İFŞA" if snap.doctrine_plan_exposed else ("Yolda" if snap.courier_in_transit else "Hazır"), snap.synergy_courier_tempo_mult,
			"AÇIK (~2.1x)" if snap.dust_decoy_active else "Kapalı"],
	}
	for sid: StringName in texts:
		var rec: DrawerSlotRecord = _drawer_slots.get(sid, null)
		if rec != null:
			rec.summary_label.text = texts[sid]


func _apply_session_clock_controls(snap: OtukenHudViewModel.PulseSummarySnapshot) -> void:
	if _session_clock_dock == null:
		return
	var is_online: bool = snap.session_mode == GameEnums.SessionMode.ONLINE_PERSISTENT_WORLD
	if _session_clock_card != null:
		var card_tone: StringName = &"jade"
		if snap.online_pause_rejected or snap.session_paused:
			card_tone = &"ember"
		elif is_online:
			card_tone = &"ice"
		_session_clock_card.set_semantic_tone(card_tone, 0.0)

	if _clock_mode_label != null:
		if snap.online_pause_rejected:
			_clock_mode_label.text = "DURAKLATMA REDDİ!"
			_clock_mode_label.add_theme_color_override(&"font_color", NeoSteppePalette.EMBER_RED)
		elif is_online:
			var online_prefix: String = "CANLI NÖBET" if snap.offline_protection_active else "CANLI 1x"
			_clock_mode_label.text = "%s · T%d" % [online_prefix, snap.session_tick]
			_clock_mode_label.add_theme_color_override(&"font_color", NeoSteppePalette.ICE_FROST)
		elif snap.session_paused:
			_clock_mode_label.text = "DURAKLADI · T%d" % snap.session_tick
			_clock_mode_label.add_theme_color_override(&"font_color", NeoSteppePalette.EMBER_BRIGHT)
		else:
			_clock_mode_label.text = "TEKİL %dx · T%d" % [clampi(roundi(snap.session_speed_scale), 1, 4), snap.session_tick]
			_clock_mode_label.add_theme_color_override(&"font_color", NeoSteppePalette.JADE_BRIGHT)

	if _clock_pause_btn != null:
		_clock_pause_btn.disabled = false
		if is_online:
			_clock_pause_btn.text = "Duraklat"
		elif snap.session_paused:
			_clock_pause_btn.text = "Devam"
		else:
			_clock_pause_btn.text = "Duraklat"
		var pause_col: Color = NeoSteppePalette.JADE_PRIMARY
		if snap.online_pause_rejected or snap.session_paused:
			pause_col = NeoSteppePalette.EMBER_BRIGHT
		elif is_online:
			pause_col = NeoSteppePalette.ICE_BLUE
		OtukenThemeFactory.apply_button_semantic_styles(_clock_pause_btn, pause_col, snap.session_paused or snap.online_pause_rejected, 5, 2)

	var active_spd_int: int = 1 if is_online else clampi(roundi(snap.session_speed_scale), 1, 4)
	for spd_key: int in _clock_speed_buttons:
		var sbtn: Button = _clock_speed_buttons[spd_key]
		if sbtn == null:
			continue
		var locked: bool = is_online and spd_key > 1
		sbtn.disabled = locked
		var is_selected: bool = (spd_key == active_spd_int)
		var scol: Color = NeoSteppePalette.ICE_BLUE if is_online else (NeoSteppePalette.JADE_PRIMARY if is_selected else NeoSteppePalette.BRONZE_WEATHERED)
		OtukenThemeFactory.apply_button_semantic_styles(sbtn, scol, is_selected, 5, 2)


func _rebuild_crisis_chips(crises: Array[OtukenHudViewModel.CrisisChipDescriptor]) -> void:
	var capped_count: int = mini(crises.size(), MAX_VISIBLE_CRISIS_CHIPS)
	var sig_parts: PackedStringArray = PackedStringArray()
	for i: int in range(capped_count):
		var d: OtukenHudViewModel.CrisisChipDescriptor = crises[i]
		sig_parts.append("%s|%s|%s" % [String(d.crisis_id), d.title, d.detail])
	var next_sig: String = ";".join(sig_parts)

	if next_sig == _last_crisis_signature:
		_crisis_chip_rail.visible = (not _crisis_chips.is_empty()) and (not _mobile_rts_mode)
		return
	_last_crisis_signature = next_sig

	_clear_crisis_chips()
	for i: int in range(capped_count):
		var desc: OtukenHudViewModel.CrisisChipDescriptor = crises[i]
		var chip: CrisisChipButton = CrisisChipButton.new()
		chip.name = "CrisisChip_%s" % String(desc.crisis_id)
		chip.custom_minimum_size = Vector2(204.0, 32.0)
		var cb: Callable = _on_crisis_chip_activated
		chip.crisis_chip_activated.connect(cb)
		_chip_activated_callbacks[chip] = cb
		_crisis_chip_rail.add_child(chip)
		chip.configure_crisis(desc)
		if _glossary_tooltip != null:
			_glossary_tooltip.bind_control(chip, desc.glossary_term)
		_crisis_chips.append(chip)

	_crisis_chip_rail.visible = (not _crisis_chips.is_empty()) and (not _mobile_rts_mode)


func _clear_crisis_chips() -> void:
	for chip: CrisisChipButton in _crisis_chips:
		if _glossary_tooltip != null and is_instance_valid(_glossary_tooltip):
			_glossary_tooltip.unbind_control(chip)
		if chip != null and is_instance_valid(chip):
			var cb: Callable = _chip_activated_callbacks.get(chip, Callable())
			if not cb.is_null() and chip.crisis_chip_activated.is_connected(cb):
				chip.crisis_chip_activated.disconnect(cb)
			if chip.get_parent() != null:
				chip.get_parent().remove_child(chip)
			chip.queue_free()
	_crisis_chips.clear()
	_chip_activated_callbacks.clear()


func _sync_lens_buttons() -> void:
	var active_color: Color = NeoSteppePalette.get_lens_accent_color(_active_lens)
	if _tactical_lens_card != null:
		var bar_tone: StringName = &"gold"
		match _active_lens:
			GameEnums.TacticalMapLens.LOGISTICS_WATER_COURIER:
				bar_tone = &"ice"
			GameEnums.TacticalMapLens.YAYLAK_KISLAK, GameEnums.TacticalMapLens.TUG_CONTROL:
				bar_tone = &"jade"
			GameEnums.TacticalMapLens.INTELLIGENCE_DUST:
				bar_tone = &"ember"
			_:
				bar_tone = &"gold"
		_tactical_lens_card.set_semantic_tone(bar_tone, 0.0)
	for opt: LensOptionWidgets in _lens_options:
		var is_sel: bool = opt.lens == _active_lens
		var opt_color: Color = active_color if is_sel else NeoSteppePalette.get_semantic_color(opt.tone_id)
		OtukenThemeFactory.apply_button_semantic_styles(opt.button, opt_color, is_sel, 5, 1)


func _sync_analytics_dock_buttons() -> void:
	if _chronicle_toggle_btn != null:
		var ch_open: bool = _chronicle_feed != null and _chronicle_feed.visible
		var ch_col: Color = NeoSteppePalette.GOLD_TAMGA if ch_open else NeoSteppePalette.BRONZE_WEATHERED
		OtukenThemeFactory.apply_button_semantic_styles(_chronicle_toggle_btn, ch_col, ch_open, 4, 0)
	if _ledger_toggle_btn != null:
		var le_open: bool = _empire_ledger != null and _empire_ledger.visible
		var le_col: Color = NeoSteppePalette.GOLD_TAMGA if le_open else NeoSteppePalette.BRONZE_WEATHERED
		OtukenThemeFactory.apply_button_semantic_styles(_ledger_toggle_btn, le_col, le_open, 4, 0)
	if _research_toggle_btn != null:
		var res_open: bool = _research_tree_panel != null and _research_tree_panel.visible
		var res_col: Color = NeoSteppePalette.JADE_PRIMARY if res_open else NeoSteppePalette.BRONZE_WEATHERED
		OtukenThemeFactory.apply_button_semantic_styles(_research_toggle_btn, res_col, res_open, 4, 0)


func _sync_drawer_slot_visibility() -> void:
	for sid: StringName in _drawer_slot_order:
		var rec: DrawerSlotRecord = _drawer_slots.get(sid, null)
		if rec == null:
			continue
		var is_active: bool = sid == _active_drawer_slot
		rec.container.visible = is_active
		OtukenThemeFactory.apply_button_semantic_styles(
			rec.tab_button, NeoSteppePalette.get_semantic_color(rec.accent_tone), is_active, 6, 3)
		if is_active and _analysis_drawer_card != null:
			_analysis_drawer_card.set_semantic_tone(rec.accent_tone, 0.0)


func _set_drawer_x(x_pos: float) -> void:
	if _analysis_drawer_card == null:
		return
	_analysis_drawer_card.offset_left = x_pos
	_analysis_drawer_card.offset_right = x_pos + DRAWER_WIDTH_PX


func _kill_drawer_tween() -> void:
	if _drawer_tween != null and _drawer_tween.is_valid():
		_drawer_tween.kill()
	_drawer_tween = null


func _connect_event_bus() -> void:
	if _signals_connected:
		return
	_signals_connected = true

	_subscribe_bus(EventBus.resource_amount_changed, _on_telemetry_dirty.unbind(4))
	_subscribe_bus(EventBus.season_changed, _on_season_changed_hud)
	_subscribe_bus(EventBus.zud_starvation_ticked, _on_zud_starvation_hud)
	_subscribe_bus(EventBus.regional_tax_collected, _on_telemetry_dirty.unbind(3))
	_subscribe_bus(EventBus.tamga_authority_updated, _on_telemetry_dirty.unbind(2))
	_subscribe_bus(EventBus.kut_changed, _on_telemetry_dirty.unbind(3))
	_subscribe_bus(EventBus.ak_sakallilar_council_convened, _on_ak_sakallilar_hud)
	_subscribe_bus(EventBus.council_decree_enacted, _on_telemetry_dirty.unbind(6))
	_subscribe_bus(EventBus.army_supply_changed, _on_telemetry_dirty.unbind(3))
	_subscribe_bus(EventBus.supply_line_severed, _on_telemetry_dirty.unbind(4))
	_subscribe_bus(EventBus.supply_line_restored, _on_telemetry_dirty.unbind(2))
	_subscribe_bus(EventBus.yilki_horses_sacrificed_for_ration, _on_yilki_sacrificed)
	_subscribe_bus(EventBus.outbreak_epidemic_started, _on_telemetry_dirty.unbind(3))
	_subscribe_bus(EventBus.epidemic_purified_at_kurgan, _on_telemetry_dirty.unbind(3))
	_subscribe_bus(EventBus.coalition_war_declared, _on_coalition_war_declared)
	_subscribe_bus(EventBus.great_khagan_candidate_proclaimed, _on_great_khagan_proclaimed)
	_subscribe_bus(EventBus.pasture_depleted_starving_livestock, _on_pasture_depleted_hud)
	_subscribe_bus(EventBus.camp_migrated_by_sefer_arabasi, _on_telemetry_dirty.unbind(4))
	_subscribe_bus(EventBus.overgrazing_rebellion_triggered, _on_telemetry_dirty.unbind(3))
	_subscribe_bus(EventBus.cataclysm_erupted, _on_cataclysm_erupted_hud)
	_subscribe_bus(EventBus.cataclysm_subsided, _on_telemetry_dirty.unbind(2))
	_subscribe_bus(EventBus.kinship_plot_escalated, _on_telemetry_dirty.unbind(5))
	_subscribe_bus(EventBus.internal_betrayal_triggered, _on_telemetry_dirty.unbind(5))
	_subscribe_bus(EventBus.kinship_crisis_resolved, _on_telemetry_dirty.unbind(3))
	_subscribe_bus(EventBus.tore_peace_stage_changed, _on_telemetry_dirty.unbind(3))
	_subscribe_bus(EventBus.personal_tore_peace_granted, _on_telemetry_dirty.unbind(3))
	_subscribe_bus(EventBus.personal_tore_peace_forfeited, _on_telemetry_dirty.unbind(2))
	_subscribe_bus(EventBus.region_control_changed, _on_telemetry_dirty.unbind(5))
	_subscribe_bus(EventBus.collapse_triggered, _on_telemetry_dirty.unbind(3))
	_subscribe_bus(EventBus.collapse_path_selected, _on_telemetry_dirty.unbind(4))
	_subscribe_bus(EventBus.dynasty_reborn_at_frontier, _on_telemetry_dirty.unbind(3))
	_subscribe_bus(EventBus.courier_dispatched, _on_telemetry_dirty.unbind(4))
	_subscribe_bus(EventBus.courier_order_delivered, _on_telemetry_dirty.unbind(4))
	_subscribe_bus(EventBus.caravan_intercepted_crisis, _on_caravan_intercepted_hud)
	_subscribe_bus(EventBus.governance_cap_exceeded, _on_telemetry_dirty.unbind(5))
	_subscribe_bus(EventBus.region_delegated_to_vassal, _on_telemetry_dirty.unbind(4))
	_subscribe_bus(EventBus.vassal_silent_sabotage_delayed, _on_telemetry_dirty.unbind(3))
	_subscribe_bus(EventBus.amanat_pact_sealed, _on_amanat_sealed_hud)
	_subscribe_bus(EventBus.amanat_pact_broken, _on_amanat_broken_hud)
	_subscribe_bus(EventBus.reputation_memory_changed, _on_telemetry_dirty.unbind(4))
	_subscribe_bus(EventBus.water_source_sabotaged, _on_water_sabotaged_hud)
	_subscribe_bus(EventBus.water_source_restored, _on_water_source_restored)
	_subscribe_bus(EventBus.water_crisis_inflicted, _on_water_crisis_inflicted)
	_subscribe_bus(EventBus.regional_market_scarcity_shifted, _on_telemetry_dirty.unbind(4))
	_subscribe_bus(EventBus.ruler_died_succession_started, _on_telemetry_dirty.unbind(6))
	_subscribe_bus(EventBus.kurultay_succession_crisis_triggered, _on_kurultay_crisis_hud)
	_subscribe_bus(EventBus.succession_crisis_resolved, _on_telemetry_dirty.unbind(4))
	_subscribe_bus(EventBus.tactical_lens_changed, _on_tactical_lens_changed)
	_subscribe_bus(EventBus.dust_decoy_toggled, _on_telemetry_dirty.unbind(3))
	_subscribe_bus(EventBus.offline_doctrine_configured, _on_telemetry_dirty.unbind(8))
	_subscribe_bus(EventBus.battle_doctrine_assigned, _on_telemetry_dirty.unbind(4))
	_subscribe_bus(EventBus.courier_ambushed_plan_exposed, _on_courier_ambushed_hud)
	_subscribe_bus(EventBus.systemic_synergy_evaluated, _on_systemic_synergy_evaluated)
	_subscribe_bus(EventBus.session_pause_rejected, _on_telemetry_dirty.unbind(2))
	_subscribe_bus(EventBus.session_tempo_changed, _on_telemetry_dirty.unbind(4))
	_subscribe_bus(EventBus.combat_resolved, _on_combat_resolved_hud)
	_subscribe_bus(EventBus.dynasty_stance_changed, _on_dynasty_stance_changed_hud)
	_subscribe_bus(EventBus.envoy_assassinated, _on_envoy_assassinated_hud)
	_subscribe_bus(EventBus.ai_story_agenda_activated, _on_ai_story_agenda_hud)
	_subscribe_bus(EventBus.tradition_research_started, _on_tradition_research_dirty.unbind(4))
	_subscribe_bus(EventBus.tradition_research_progressed, _on_tradition_research_dirty.unbind(4))
	_subscribe_bus(EventBus.tradition_research_completed, _on_tradition_research_completed_hud)


func _subscribe_bus(bus_signal: Signal, callback: Callable) -> void:
	if not bus_signal.is_connected(callback):
		bus_signal.connect(callback)
	_bus_subscriptions.append(BusSignalSubscription.new(bus_signal, callback))


func _disconnect_event_bus() -> void:
	for sub: BusSignalSubscription in _bus_subscriptions:
		if sub.bus_signal.is_connected(sub.callback):
			sub.bus_signal.disconnect(sub.callback)
	_bus_subscriptions.clear()
	_signals_connected = false


func _disconnect_ui_signals() -> void:
	for pw: PulseCardWidgets in _pulse_cards:
		if pw.card != null and is_instance_valid(pw.card):
			var cb: Callable = _card_click_callbacks.get(pw.card, Callable())
			if not cb.is_null() and pw.card.card_clicked.is_connected(cb):
				pw.card.card_clicked.disconnect(cb)
	_card_click_callbacks.clear()

	for mbtn: Button in _metric_chip_callbacks:
		if mbtn != null and is_instance_valid(mbtn):
			var mcb: Callable = _metric_chip_callbacks[mbtn]
			if not mcb.is_null() and mbtn.pressed.is_connected(mcb):
				mbtn.pressed.disconnect(mcb)
	_metric_chip_callbacks.clear()
	_metric_chip_buttons.clear()

	if _chronicle_toggle_btn != null and is_instance_valid(_chronicle_toggle_btn) and not _chronicle_toggle_cb.is_null():
		if _chronicle_toggle_btn.pressed.is_connected(_chronicle_toggle_cb):
			_chronicle_toggle_btn.pressed.disconnect(_chronicle_toggle_cb)
	_chronicle_toggle_cb = Callable()

	if _ledger_toggle_btn != null and is_instance_valid(_ledger_toggle_btn) and not _ledger_toggle_cb.is_null():
		if _ledger_toggle_btn.pressed.is_connected(_ledger_toggle_cb):
			_ledger_toggle_btn.pressed.disconnect(_ledger_toggle_cb)
	_ledger_toggle_cb = Callable()

	if _research_toggle_btn != null and is_instance_valid(_research_toggle_btn) and not _research_toggle_cb.is_null():
		if _research_toggle_btn.pressed.is_connected(_research_toggle_cb):
			_research_toggle_btn.pressed.disconnect(_research_toggle_cb)
	_research_toggle_cb = Callable()

	if _metric_popover != null and is_instance_valid(_metric_popover) and not _popover_action_cb.is_null():
		if _metric_popover.quick_action_requested.is_connected(_popover_action_cb):
			_metric_popover.quick_action_requested.disconnect(_popover_action_cb)
	_popover_action_cb = Callable()

	if _chronicle_feed != null and is_instance_valid(_chronicle_feed) and not _chronicle_focus_cb.is_null():
		if _chronicle_feed.chronicle_focus_requested.is_connected(_chronicle_focus_cb):
			_chronicle_feed.chronicle_focus_requested.disconnect(_chronicle_focus_cb)
	_chronicle_focus_cb = Callable()

	if _empire_ledger != null and is_instance_valid(_empire_ledger) and not _ledger_focus_cb.is_null():
		if _empire_ledger.ledger_focus_requested.is_connected(_ledger_focus_cb):
			_empire_ledger.ledger_focus_requested.disconnect(_ledger_focus_cb)
	_ledger_focus_cb = Callable()

	if _toast_stack != null and is_instance_valid(_toast_stack) and not _toast_activated_cb.is_null():
		if _toast_stack.toast_activated.is_connected(_toast_activated_cb):
			_toast_stack.toast_activated.disconnect(_toast_activated_cb)
	_toast_activated_cb = Callable()

	if _game_shell != null and is_instance_valid(_game_shell) and not _shell_settings_cb.is_null():
		var sp: SettingsPanel = _game_shell.get_settings_panel()
		if sp != null and is_instance_valid(sp) and sp.settings_applied.is_connected(_shell_settings_cb):
			sp.settings_applied.disconnect(_shell_settings_cb)
	_shell_settings_cb = Callable()

	for opt: LensOptionWidgets in _lens_options:
		if opt.button != null and is_instance_valid(opt.button) and opt.button.pressed.is_connected(opt.pressed_cb):
			opt.button.pressed.disconnect(opt.pressed_cb)

	for sid: StringName in _drawer_slot_order:
		var rec: DrawerSlotRecord = _drawer_slots.get(sid, null)
		if rec != null and rec.tab_button != null and is_instance_valid(rec.tab_button):
			if rec.tab_button.pressed.is_connected(rec.tab_cb):
				rec.tab_button.pressed.disconnect(rec.tab_cb)

	if _drawer_close_btn != null and is_instance_valid(_drawer_close_btn) and _drawer_close_btn.pressed.is_connected(_on_drawer_close_pressed):
		_drawer_close_btn.pressed.disconnect(_on_drawer_close_pressed)

	if _clock_pause_btn != null and is_instance_valid(_clock_pause_btn):
		if not _clock_pause_cb.is_null() and _clock_pause_btn.pressed.is_connected(_clock_pause_cb):
			_clock_pause_btn.pressed.disconnect(_clock_pause_cb)
	_clock_pause_cb = Callable()

	for sbtn: Button in _clock_speed_callbacks:
		if sbtn != null and is_instance_valid(sbtn):
			var scb: Callable = _clock_speed_callbacks.get(sbtn, Callable())
			if not scb.is_null() and sbtn.pressed.is_connected(scb):
				sbtn.pressed.disconnect(scb)
	_clock_speed_callbacks.clear()
	_clock_speed_buttons.clear()

	for badge: Button in _glossary_badges:
		if badge != null and is_instance_valid(badge):
			var gcb: Callable = _glossary_click_callbacks.get(badge, Callable())
			if not gcb.is_null() and badge.pressed.is_connected(gcb):
				badge.pressed.disconnect(gcb)
	_glossary_badges.clear()
	_glossary_click_callbacks.clear()

	for chip: CrisisChipButton in _crisis_chips:
		if chip != null and is_instance_valid(chip):
			var ccb: Callable = _chip_activated_callbacks.get(chip, Callable())
			if not ccb.is_null() and chip.crisis_chip_activated.is_connected(ccb):
				chip.crisis_chip_activated.disconnect(ccb)
	_chip_activated_callbacks.clear()

	if _glossary_tooltip != null and is_instance_valid(_glossary_tooltip):
		_glossary_tooltip.unbind_all_controls()


func _is_dummy_headless_viewport() -> bool:
	var vp: Viewport = get_viewport()
	if vp == null:
		return true
	var visible_rect: Rect2 = vp.get_visible_rect()
	return visible_rect.size.x < 320.0 or visible_rect.size.y < 240.0


func _resolve_viewport_size() -> Vector2:
	var vp: Viewport = get_viewport()
	if vp != null:
		var visible_rect: Rect2 = vp.get_visible_rect()
		if visible_rect.size.x >= 320.0 and visible_rect.size.y >= 240.0:
			return visible_rect.size
	var width_var: Variant = ProjectSettings.get_setting("display/window/size/viewport_width", 1152)
	var height_var: Variant = ProjectSettings.get_setting("display/window/size/viewport_height", 648)
	var vw: float = str(width_var).to_float()
	var vh: float = str(height_var).to_float()
	if vw < 320.0:
		vw = 1152.0
	if vh < 240.0:
		vh = 648.0
	return Vector2(vw, vh)


func _measure_control_area(ctrl: Control, vp_size: Vector2) -> float:
	if ctrl == null:
		return 0.0
	var measured: Vector2 = ctrl.size
	if _is_dummy_headless_viewport() or measured.x <= 1.0 or measured.y <= 1.0:
		var anchored_w: float = (ctrl.anchor_right - ctrl.anchor_left) * vp_size.x + (ctrl.offset_right - ctrl.offset_left)
		var anchored_h: float = (ctrl.anchor_bottom - ctrl.anchor_top) * vp_size.y + (ctrl.offset_bottom - ctrl.offset_top)
		measured = Vector2(maxf(anchored_w, 0.0), maxf(anchored_h, 0.0)).max(ctrl.get_combined_minimum_size())
	return maxf(measured.x, 0.0) * maxf(measured.y, 0.0)


func _mark_input_handled() -> void:
	if get_viewport() != null:
		get_viewport().set_input_as_handled()


func _on_telemetry_dirty() -> void:
	if _view_model != null:
		_view_model.invalidate_synergy_cache()
	refresh_from_viewmodel()


func _on_season_changed_hud(_season: SeasonData, _cycle_index: int) -> void:
	if _analytics_vm != null:
		_analytics_vm.record_season_point()
	_on_telemetry_dirty()


func _on_zud_starvation_hud(food_remaining: int, season: SeasonData) -> void:
	if _analytics_vm != null:
		_analytics_vm.ingest_zud_starvation(food_remaining, season)
	_on_telemetry_dirty()


func _on_ak_sakallilar_hud(current_kut: float, legitimacy_penalty: float, _trigger_skirmish: bool) -> void:
	if _analytics_vm != null:
		_analytics_vm.ingest_council_convened(current_kut, legitimacy_penalty)
	_on_telemetry_dirty()


func _on_pasture_depleted_hud(region_coord: Vector2i, herd_size: int, migration_required: bool) -> void:
	if _analytics_vm != null:
		_analytics_vm.ingest_pasture_depleted(region_coord, herd_size, migration_required)
	_on_telemetry_dirty()


func _on_cataclysm_erupted_hud(
		cataclysm_id: StringName,
		_cat_type: GameEnums.CataclysmType,
		region_coord: Vector2i,
		_p_mult: float,
		_c_mult: float,
		_s_wear: float,
		_refugees: int) -> void:
	if _analytics_vm != null:
		_analytics_vm.ingest_cataclysm_erupted(cataclysm_id, region_coord)
	_on_telemetry_dirty()


func _on_caravan_intercepted_hud(caravan_id: StringName, owner_id: int, raider_id: int, dest_army_id: int, _ammo_lost: float, _sup_drop: float) -> void:
	if _analytics_vm != null:
		_analytics_vm.record_chronicle_entry(
			MetricAnalyticsViewModel.CHRONICLE_AMBUSH_SABOTAGE,
			"Kervan Baskını (%s)" % String(caravan_id),
			"Boy %d kervanı Boy %d tarafından vuruldu (Ordu #%d)." % [owner_id, raider_id, dest_army_id],
			PastureEcologyManager.get_player_camp_region(player_id),
			&"ember")
	_on_telemetry_dirty()


func _on_water_sabotaged_hud(region_coord: Vector2i, source_id: StringName, saboteur_id: int, duration_seasons: int) -> void:
	if _analytics_vm != null:
		_analytics_vm.ingest_water_sabotaged(region_coord, source_id, saboteur_id, duration_seasons)
	_on_telemetry_dirty()


func _on_kurultay_crisis_hud(_pid: int, crisis_id: StringName, claimant_bey_id: StringName, contested_coord: Vector2i, _reason: StringName) -> void:
	if _analytics_vm != null:
		_analytics_vm.ingest_succession_crisis(crisis_id, claimant_bey_id, contested_coord)
	_on_telemetry_dirty()


func _on_courier_ambushed_hud(order_id: StringName, victim_pid: int, ambusher_id: int, leaked_plan: GameEnums.TuranTacticPhase) -> void:
	if _analytics_vm != null:
		_analytics_vm.ingest_courier_ambush(order_id, victim_pid, ambusher_id, leaked_plan)
	if _toast_stack != null and victim_pid == player_id:
		_toast_stack.push_toast(
			"Ulak Pusuya Düştü!",
			"Emir #%s sızdırıldı (Pusu: Boy %d)." % [String(order_id), ambusher_id],
			&"ember",
			PastureEcologyManager.get_player_camp_region(player_id),
			SLOT_TACTICAL_COMMAND,
			6.0
		)
	_on_telemetry_dirty()


func _on_combat_resolved_hud(result: CombatResult) -> void:
	if _analytics_vm != null:
		_analytics_vm.ingest_combat_resolved(result)
	_on_telemetry_dirty()


func _on_dynasty_stance_changed_hud(dynasty_id: StringName, _prev_s: GameEnums.DynastyAttitude, new_s: GameEnums.DynastyAttitude, trust_index: float) -> void:
	if _analytics_vm != null:
		_analytics_vm.ingest_diplomacy_event(
			"Boy Tutumu Değişti (%s)" % String(dynasty_id),
			"Yeni tutum: %s · Güven: %.0f" % [MetricAnalyticsViewModel._format_dynasty_attitude(new_s), trust_index],
			&"ember" if new_s == GameEnums.DynastyAttitude.HOSTILE else &"gold")
	refresh_from_viewmodel()


func _on_amanat_sealed_hud(pact_id: StringName, party_a: int, party_b: int, _hostage_type: GameEnums.AmanatHostageType) -> void:
	if _analytics_vm != null:
		_analytics_vm.ingest_diplomacy_event(
			"Amanat Antlaşması (%s)" % String(pact_id),
			"Boy %d ve Boy %d arasında rehine teminatı kuruldu." % [party_a, party_b],
			&"jade")
	_on_telemetry_dirty()


func _on_amanat_broken_hud(pact_id: StringName, betrayer_id: int, _forfeited: bool, reliability_after: float) -> void:
	if _analytics_vm != null:
		_analytics_vm.ingest_diplomacy_event(
			"Amanat İhlali (%s)" % String(pact_id),
			"Boy %d antlaşmayı bozdu; söz güveni %.0f seviyesine düştü." % [betrayer_id, reliability_after],
			&"ember")
	_on_telemetry_dirty()


func _on_envoy_assassinated_hud(instigator_id: int, target_id: int, envoy_id: StringName, _kut_gained: float) -> void:
	if _analytics_vm != null:
		_analytics_vm.record_chronicle_entry(
			MetricAnalyticsViewModel.CHRONICLE_AMBUSH_SABOTAGE,
			"Elçi Suikastı (%s)" % String(envoy_id),
			"Boy %d elçisi Boy %d tarafından infaz edildi; topyekûn baskın riski." % [target_id, instigator_id],
			PastureEcologyManager.get_player_camp_region(player_id),
			&"ember")
	refresh_from_viewmodel()


func _on_ai_story_agenda_hud(agent_id: StringName, agenda_id: StringName, triggered_reason: StringName) -> void:
	if _analytics_vm != null:
		_analytics_vm.ingest_diplomacy_event(
			"Bozkır Güç Gündemi: %s" % String(agent_id),
			"Niyet: %s (%s)" % [String(agenda_id), String(triggered_reason)],
			&"gold")
	refresh_from_viewmodel()


func _on_systemic_synergy_evaluated(snapshot: SynergyEvaluationSnapshot) -> void:
	if _view_model != null:
		_view_model.notify_synergy_snapshot_observed(snapshot)
	refresh_from_viewmodel()


func _on_yilki_sacrificed(army_id: int, remaining_remount_ratio: float, _morale_drop: float, _kut_penalty: float) -> void:
	if _view_model != null:
		_view_model.invalidate_synergy_cache()
		if army_id == tracked_army_id:
			_view_model.notify_remount_ratio_observed(remaining_remount_ratio)
	if _analytics_vm != null and army_id == tracked_army_id:
		_analytics_vm.notify_remount_ratio_observed(remaining_remount_ratio)
	refresh_from_viewmodel()


func _on_water_crisis_inflicted(army_id: int, _coord: Vector2i, _remount_drain: float, _morale_pen: float, _is_frozen: bool) -> void:
	if _view_model != null:
		_view_model.invalidate_synergy_cache()
		if army_id == tracked_army_id or army_id == player_id:
			_view_model.notify_water_crisis_observed(true)
	if _analytics_vm != null and (army_id == tracked_army_id or army_id == player_id):
		_analytics_vm.notify_water_crisis_observed(true)
	refresh_from_viewmodel()


func _on_water_source_restored(coord: Vector2i, source_id: StringName, restorer_id: int) -> void:
	if _view_model != null:
		_view_model.invalidate_synergy_cache()
		if restorer_id == player_id:
			_view_model.notify_water_crisis_observed(false)
	if _analytics_vm != null:
		if restorer_id == player_id:
			_analytics_vm.notify_water_crisis_observed(false)
		_analytics_vm.ingest_water_restored(coord, source_id, restorer_id)
	refresh_from_viewmodel()


func _on_coalition_war_declared(dynasties: PackedStringArray, kut: float) -> void:
	if _view_model != null:
		_view_model.invalidate_synergy_cache()
		_view_model.notify_coalition_observed(true)
	if _analytics_vm != null:
		_analytics_vm.ingest_diplomacy_event(
			"Koalisyon Savaşı İlanı",
			"%d boy koalisyon kurdu (Kut %.1f)." % [dynasties.size(), kut],
			&"ember")
	refresh_from_viewmodel()


func _on_great_khagan_proclaimed(_p_id: int, _owned: int, _total: int, coalition_triggered: bool) -> void:
	if _view_model != null:
		_view_model.invalidate_synergy_cache()
		if coalition_triggered:
			_view_model.notify_coalition_observed(true)
	refresh_from_viewmodel()


func _on_tactical_lens_changed(_previous_lens: GameEnums.TacticalMapLens, new_lens: GameEnums.TacticalMapLens) -> void:
	if _active_lens != new_lens:
		_active_lens = new_lens
		_sync_lens_buttons()


func _on_pulse_card_clicked(card_id: StringName) -> void:
	toggle_drawer(card_id, false)


func _on_metric_chip_pressed(metric_id: StringName) -> void:
	open_metric_breakdown(metric_id)


func _on_chronicle_toggle_pressed() -> void:
	toggle_chronicle()


func _on_ledger_toggle_pressed() -> void:
	toggle_ledger()


func _on_research_toggle_pressed() -> void:
	toggle_research_tree()


func _on_tradition_research_dirty() -> void:
	if _research_tree_panel != null and is_instance_valid(_research_tree_panel) and _research_tree_panel.visible:
		_research_tree_panel.refresh_tree()
	_on_telemetry_dirty()


func _on_tradition_research_completed_hud(
		pid: int,
		node_id: StringName,
		_branch: GameEnums.ResearchBranch,
		effect_summary: String) -> void:
	if pid == player_id and _toast_stack != null:
		var n: TraditionResearchNode = TraditionResearchCatalog.get_node_by_id(node_id)
		var label: String = n.title if n != null else String(node_id)
		_toast_stack.push_toast(
			"Gelenek Tamamlandı: %s" % label,
			effect_summary,
			&"jade",
			PastureEcologyManager.get_player_camp_region(player_id),
			OtukenHudViewModel.SLOT_MILITARY_HERD,
			6.5
		)
	_on_tradition_research_dirty()


func _on_toast_activated(_toast_id: StringName, focus_coord: Vector2i, target_drawer_slot: StringName) -> void:
	var wp: Vector3 = Vector3(float(focus_coord.x) * 16.0 + 8.0, 0.0, float(focus_coord.y) * 16.0 + 8.0)
	_on_analytics_focus_requested(focus_coord, wp)
	if target_drawer_slot != &"" and has_drawer_slot(target_drawer_slot):
		open_drawer(target_drawer_slot, false)


func _on_shell_settings_applied(settings: GameShellViewModel.UserSettingsSnapshot) -> void:
	if settings == null:
		return
	scale = Vector2(settings.ui_scale, settings.ui_scale)
	if _rich_tooltip != null and is_instance_valid(_rich_tooltip):
		_rich_tooltip.set_touch_friendly(settings.touch_friendly_layout)


func _on_popover_quick_action_requested(primary_slot: StringName, fallback_slot: StringName) -> void:
	var target: StringName = primary_slot if has_drawer_slot(primary_slot) else fallback_slot
	open_drawer(target, false)


func _on_analytics_focus_requested(_coord: Vector2i, world_pos: Vector3) -> void:
	if _camera_ref != null:
		var obj: Object = _camera_ref.get_ref()
		if obj != null and is_instance_valid(obj):
			var cam: DualLayerCamera = obj as DualLayerCamera
			if cam != null:
				cam.focus_world_position(world_pos)


func _on_lens_button_pressed(lens: GameEnums.TacticalMapLens) -> void:
	select_lens(lens, true)


func _on_drawer_tab_pressed(slot_id: StringName) -> void:
	open_drawer(slot_id, true)


func _on_drawer_close_pressed() -> void:
	close_drawer(false)


func _on_crisis_chip_activated(_crisis_id: StringName, target_drawer_slot: StringName, glossary_term: StringName) -> void:
	open_drawer(target_drawer_slot, false)
	if _glossary_tooltip != null and glossary_term != &"":
		_glossary_tooltip.show_for_term(glossary_term, Rect2(Vector2(DRAWER_OPEN_OFFSET_X + DRAWER_WIDTH_PX + 12.0, 84.0), Vector2(180.0, 40.0)), get_view_model())


func _on_glossary_badge_pressed(badge: Button, term_id: StringName) -> void:
	if _glossary_tooltip == null or badge == null:
		return
	var same_locked: bool = _glossary_tooltip.visible and _glossary_tooltip.is_hover_locked() and _glossary_tooltip.get_active_term_id() == SteppeGlossaryTooltip.normalize_term_id(term_id)
	if same_locked:
		_glossary_tooltip.unlock_tooltip(true)
		return
	_glossary_tooltip.show_for_term(term_id, badge.get_global_rect(), get_view_model())
	_glossary_tooltip.lock_tooltip()


func _on_drawer_open_tween_finished() -> void:
	_set_drawer_x(DRAWER_OPEN_OFFSET_X)
	_drawer_tween = null


func _on_drawer_close_tween_finished() -> void:
	_set_drawer_x(DRAWER_CLOSED_OFFSET_X)
	if not _drawer_open and _analysis_drawer_card != null:
		_analysis_drawer_card.visible = false
		_analysis_drawer_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_drawer_tween = null


func _on_clock_pause_pressed() -> void:
	if SessionClockAuthority.get_session_mode() == GameEnums.SessionMode.ONLINE_PERSISTENT_WORLD:
		request_session_pause(true)
	else:
		request_session_pause(not SessionClockAuthority.is_paused())


func _on_clock_speed_pressed(scale_val: float) -> void:
	request_session_speed(scale_val)
