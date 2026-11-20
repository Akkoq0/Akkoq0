extends Node3D
## Main scene coordinator (rank 4). Bridges `Steppe3DMapController` (live 3D
## steppe world), `OtukenHudRoot` + Phase 29/30/31 drawer panels, and
## transitions game state from LOADING to PLAYING on macro generation.


var _tactical_panel: TacticalCommandDrawerPanel = null
var _world_ecology_panel: WorldEcologyDrawerPanel = null
var _sovereignty_panel: SovereigntyDrawerPanel = null
var _map_3d_controller: Steppe3DMapController = null
var _mobile_hud: MobileRtsHud = null
var _gfx_modal: GraphicsSettingsModal = null
var _battlefield_mgr: RtsBattlefieldManager = null
var _pbr_terrain: SteppePbrTerrain = null
var _shell_launch_cb: Callable = Callable()

var _player_id: int = 1
var _army_id: int = 1
var _selected_region: Vector2i = Vector2i.ZERO


func _ready() -> void:
	EventBus.macro_world_generated.connect(_on_macro_world_generated, CONNECT_ONE_SHOT)
	var vanguard: ArmyController = get_node_or_null("ArmyRegistry/VanguardArmy") as ArmyController
	_player_id = MatchSessionConfig.local_player_id if MatchSessionConfig.is_multiplayer_session() else (vanguard.owner_id if (vanguard != null and vanguard.owner_id > 0) else 1)
	_army_id = vanguard.army_id if (vanguard != null and vanguard.army_id > 0) else 1
	_hide_legacy_debug_visuals()
	_mount_pbr_terrain()
	_mount_hud_panels(vanguard)
	_bind_3d_map_bridge()
	_mount_battlefield_manager()
	var saved_gfx: GraphicsQualityApplier.GraphicsConfigData = GraphicsQualityApplier.load_graphics_settings()
	GraphicsQualityApplier.apply_detailed_settings(get_tree(), saved_gfx, false)
	if AudioDirector != null:
		AudioDirector.set_music_mood(AudioDirector.MusicMood.EXPLORE)


func _exit_tree() -> void:
	if EventBus.macro_world_generated.is_connected(_on_macro_world_generated):
		EventBus.macro_world_generated.disconnect(_on_macro_world_generated)
	if _map_3d_controller != null and is_instance_valid(_map_3d_controller):
		if _map_3d_controller.region_selected.is_connected(_on_map_region_selected):
			_map_3d_controller.region_selected.disconnect(_on_map_region_selected)
		if _map_3d_controller.army_selected.is_connected(_on_map_army_selected):
			_map_3d_controller.army_selected.disconnect(_on_map_army_selected)
	var hud: OtukenHudRoot = get_node_or_null("HudLayer/OtukenHudRoot") as OtukenHudRoot
	if hud != null and is_instance_valid(hud) and _shell_launch_cb.is_valid():
		var sh: GameShellCoordinator = hud.get_game_shell()
		if sh != null and is_instance_valid(sh) and sh.campaign_launch_requested.is_connected(_shell_launch_cb):
			sh.campaign_launch_requested.disconnect(_shell_launch_cb)
	_shell_launch_cb = Callable()


func get_tactical_panel() -> TacticalCommandDrawerPanel:
	return _tactical_panel


func get_world_ecology_panel() -> WorldEcologyDrawerPanel:
	return _world_ecology_panel


func get_sovereignty_panel() -> SovereigntyDrawerPanel:
	return _sovereignty_panel


func get_map_3d_controller() -> Steppe3DMapController:
	return _map_3d_controller


func get_mobile_hud() -> MobileRtsHud:
	return _mobile_hud


func get_battlefield_manager() -> RtsBattlefieldManager:
	return _battlefield_mgr


func get_pbr_terrain() -> SteppePbrTerrain:
	return _pbr_terrain


func _hide_legacy_debug_visuals() -> void:
	for path: String in ["MacroWorldRenderer", "MicroZoneRenderer", "SupplyDepotNode", "ArmyRegistry"]:
		var n3d: Node3D = get_node_or_null(path) as Node3D
		if n3d != null:
			n3d.visible = false
	var cmd_in: Node = get_node_or_null("PlayerCommandInput")
	if cmd_in != null:
		cmd_in.set_process_unhandled_input(false)


func _mount_pbr_terrain() -> void:
	_pbr_terrain = SteppePbrTerrain.new()
	_pbr_terrain.name = "SteppePbrTerrain"
	add_child(_pbr_terrain)
	_pbr_terrain.build_world(MatchSessionConfig.world_seed)
	var sun: DirectionalLight3D = get_node_or_null("DirectionalLight3D") as DirectionalLight3D
	if sun != null:
		sun.light_color = Color(1.0, 0.87, 0.66, 1.0)
		sun.light_energy = 1.25
		sun.rotation_degrees = Vector3(-34.0, 42.0, 0.0)


func _mount_hud_panels(vanguard: ArmyController) -> void:
	var hud: OtukenHudRoot = get_node_or_null("HudLayer/OtukenHudRoot") as OtukenHudRoot
	if hud == null:
		return
	hud.set_player_context(_player_id, _army_id)
	hud.set_mobile_rts_mode(true)
	var sh: GameShellCoordinator = hud.get_game_shell()
	if sh != null:
		_shell_launch_cb = _on_campaign_launch_requested
		if not sh.campaign_launch_requested.is_connected(_shell_launch_cb):
			sh.campaign_launch_requested.connect(_shell_launch_cb)

	_world_ecology_panel = WorldEcologyDrawerPanel.new()
	_world_ecology_panel.set_context(_player_id, _army_id, _selected_region)
	hud.mount_panel_to_slot(OtukenHudViewModel.SLOT_ECONOMY_WATER, _world_ecology_panel)

	_sovereignty_panel = SovereigntyDrawerPanel.new()
	_sovereignty_panel.set_context(_player_id, _army_id, _selected_region)
	hud.mount_panel_to_slot(OtukenHudViewModel.SLOT_GOVERNANCE_DYNASTY, _sovereignty_panel)

	hud.register_drawer_slot(OtukenHudRoot.SLOT_TACTICAL_COMMAND, "Taktik & Komuta", &"jade")
	_tactical_panel = TacticalCommandDrawerPanel.new()
	_tactical_panel.bind_context(_player_id, _army_id, vanguard)
	hud.mount_panel_to_slot(OtukenHudRoot.SLOT_TACTICAL_COMMAND, _tactical_panel)

	var hud_layer: CanvasLayer = get_node_or_null("HudLayer") as CanvasLayer
	if hud_layer != null:
		_mobile_hud = MobileRtsHud.new()
		hud_layer.add_child(_mobile_hud)
		_gfx_modal = GraphicsSettingsModal.new()
		hud_layer.add_child(_gfx_modal)
		_mobile_hud.settings_requested.connect(func() -> void: _gfx_modal.open_modal())
		_mobile_hud.details_toggled.connect(func() -> void: hud.toggle_drawer(OtukenHudRoot.SLOT_TACTICAL_COMMAND, false))
		_mobile_hud.menu_requested.connect(_on_return_to_main_menu)
		_mobile_hud.return_to_main_menu_requested.connect(_on_return_to_main_menu)
		_mobile_hud.minimap_jump_requested.connect(_on_minimap_jump)


func _on_minimap_jump(world_pos: Vector3) -> void:
	var cam: DualLayerCamera = get_node_or_null("DualLayerCamera") as DualLayerCamera
	if cam != null:
		cam.focus_world_position(world_pos)


func _on_return_to_main_menu() -> void:
	var mp: MultiplayerAPI = get_tree().get_multiplayer()
	if mp != null and mp.multiplayer_peer != null:
		mp.multiplayer_peer.close()
		mp.multiplayer_peer = null
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _mount_battlefield_manager() -> void:
	_battlefield_mgr = RtsBattlefieldManager.new()
	add_child(_battlefield_mgr)
	var cam: DualLayerCamera = get_node_or_null("DualLayerCamera") as DualLayerCamera
	if cam != null:
		cam.zoom_by(-0.38)
	var h_cb: Callable = _pbr_terrain.get_height_at if _pbr_terrain != null else Callable()
	var p_cb: Callable = _pbr_terrain.is_passable_at if _pbr_terrain != null else Callable()
	_battlefield_mgr.setup_match(_mobile_hud, cam, h_cb, p_cb)
	if _mobile_hud != null and _pbr_terrain != null:
		_mobile_hud.set_minimap_terrain(48, 48, _pbr_terrain.get_minimap_grid(48, 48, RtsBattlefieldManager.MAP_HALF_EXTENT), RtsBattlefieldManager.MAP_HALF_EXTENT)
	if _map_3d_controller != null:
		_map_3d_controller.visible = false
		_map_3d_controller.set_process_unhandled_input(false)


func _bind_3d_map_bridge() -> void:
	_map_3d_controller = get_node_or_null("Steppe3DMapController") as Steppe3DMapController
	var cam: DualLayerCamera = get_node_or_null("DualLayerCamera") as DualLayerCamera
	var army_reg: ArmyRegistry = get_node_or_null("ArmyRegistry") as ArmyRegistry
	var vanguard: ArmyController = army_reg.get_army(_army_id) if army_reg != null else null
	var hud: OtukenHudRoot = get_node_or_null("HudLayer/OtukenHudRoot") as OtukenHudRoot
	if hud != null:
		hud.bind_analytics_scene_context(cam, null, army_reg, vanguard)
	if _map_3d_controller == null:
		return
	var macro_gen: MacroWorldGenerator = get_node_or_null("MacroWorldGenerator") as MacroWorldGenerator
	var sun_light: DirectionalLight3D = get_node_or_null("DirectionalLight3D") as DirectionalLight3D
	_map_3d_controller.bind_scene_context(cam, army_reg, macro_gen, sun_light, _player_id, _army_id)
	if not _map_3d_controller.region_selected.is_connected(_on_map_region_selected):
		_map_3d_controller.region_selected.connect(_on_map_region_selected)
	if not _map_3d_controller.army_selected.is_connected(_on_map_army_selected):
		_map_3d_controller.army_selected.connect(_on_map_army_selected)


func _on_map_region_selected(coord: Vector2i) -> void:
	_selected_region = coord
	if _world_ecology_panel != null:
		_world_ecology_panel.set_context(_player_id, _army_id, _selected_region)
	if _sovereignty_panel != null:
		_sovereignty_panel.set_context(_player_id, _army_id, _selected_region)
	var hud: OtukenHudRoot = get_node_or_null("HudLayer/OtukenHudRoot") as OtukenHudRoot
	if hud != null:
		hud.get_analytics_view_model().set_context(_player_id, _army_id, _selected_region)
		hud.refresh_from_viewmodel()


func _on_map_army_selected(selected_army_id: int) -> void:
	_army_id = maxi(selected_army_id, 1)
	var cmd_input: PlayerCommandInput = get_node_or_null("PlayerCommandInput") as PlayerCommandInput
	if cmd_input != null:
		cmd_input.controlled_army_id = _army_id
	var army_reg: ArmyRegistry = get_node_or_null("ArmyRegistry") as ArmyRegistry
	var selected_army: ArmyController = army_reg.get_army(_army_id) if army_reg != null else null
	if _tactical_panel != null:
		_tactical_panel.bind_context(_player_id, _army_id, selected_army)
	if _world_ecology_panel != null:
		_world_ecology_panel.set_context(_player_id, _army_id, _selected_region)
	if _sovereignty_panel != null:
		_sovereignty_panel.set_context(_player_id, _army_id, _selected_region)
	var hud: OtukenHudRoot = get_node_or_null("HudLayer/OtukenHudRoot") as OtukenHudRoot
	if hud != null:
		var cam: DualLayerCamera = get_node_or_null("DualLayerCamera") as DualLayerCamera
		hud.bind_analytics_scene_context(cam, null, army_reg, selected_army)
		hud.set_player_context(_player_id, _army_id)


func _on_macro_world_generated(world_state: MacroWorldState) -> void:
	if _map_3d_controller != null and world_state != null:
		_map_3d_controller.get_view_model().set_macro_world_state(world_state)
		_map_3d_controller.sync_from_viewmodel()
	var hud: OtukenHudRoot = get_node_or_null("HudLayer/OtukenHudRoot") as OtukenHudRoot
	if hud != null and world_state != null:
		var cam: DualLayerCamera = get_node_or_null("DualLayerCamera") as DualLayerCamera
		var army_reg: ArmyRegistry = get_node_or_null("ArmyRegistry") as ArmyRegistry
		hud.bind_analytics_scene_context(cam, world_state, army_reg, null)
	CommandBus.dispatch(ChangeGameStateCommand.new(GameEnums.GameState.PLAYING))


func _on_campaign_launch_requested(cfg: GameShellViewModel.NewGameLaunchConfig) -> void:
	if cfg == null:
		return
	set_meta(&"quick_match", cfg.quick_match)
	set_meta(&"seasons_elapsed", 0)
	if not EventBus.season_changed.is_connected(_on_season_changed_victory_check):
		EventBus.season_changed.connect(_on_season_changed_victory_check)
	var macro_gen: MacroWorldGenerator = get_node_or_null("MacroWorldGenerator") as MacroWorldGenerator
	if macro_gen != null and macro_gen.config != null:
		macro_gen.config.world_seed = maxi(cfg.world_seed, 1)
		var state: MacroWorldState = macro_gen.generate()
		_on_macro_world_generated(state)
	var hud: OtukenHudRoot = get_node_or_null("HudLayer/OtukenHudRoot") as OtukenHudRoot
	if hud != null:
		hud.refresh_from_viewmodel()


func _on_season_changed_victory_check(_season: SeasonData, _cycle_index: int) -> void:
	var seasons_done: int = DeterministicStateHasher.v_int(get_meta(&"seasons_elapsed", 0), 0) + 1
	set_meta(&"seasons_elapsed", seasons_done)
	var is_quick: bool = DeterministicStateHasher.v_bool(get_meta(&"quick_match", false), false)
	var kut_val: float = GameManager.get_kut_score() if GameManager != null else 50.0
	var s1: MatchVictoryEvaluator.PlayerStandingInput = MatchVictoryEvaluator.PlayerStandingInput.new(
		_player_id, kut_val, 1, 10, 0, kut_val <= 0.0, 1)
	var res: MatchVictoryEvaluator.MatchOutcomeResult = MatchVictoryEvaluator.evaluate(
		[s1], seasons_done, is_quick, _player_id)
	if res.concluded:
		EventBus.match_concluded.emit(res.winner_id, res.reason)
