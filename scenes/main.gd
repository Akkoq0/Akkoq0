extends Node3D
## Main scene coordinator (rank 4). Bridges `Steppe3DMapController` (live 3D
## steppe world), `OtukenHudRoot` + Phase 29/30/31 drawer panels, and
## transitions game state from LOADING to PLAYING on macro generation.


var _tactical_panel: TacticalCommandDrawerPanel = null
var _world_ecology_panel: WorldEcologyDrawerPanel = null
var _sovereignty_panel: SovereigntyDrawerPanel = null
var _map_3d_controller: Steppe3DMapController = null

var _player_id: int = 1
var _army_id: int = 1
var _selected_region: Vector2i = Vector2i.ZERO


func _ready() -> void:
	EventBus.macro_world_generated.connect(_on_macro_world_generated, CONNECT_ONE_SHOT)
	var vanguard: ArmyController = get_node_or_null("ArmyRegistry/VanguardArmy") as ArmyController
	_player_id = vanguard.owner_id if (vanguard != null and vanguard.owner_id > 0) else 1
	_army_id = vanguard.army_id if (vanguard != null and vanguard.army_id > 0) else 1
	_mount_hud_panels(vanguard)
	_bind_3d_map_bridge()


func _exit_tree() -> void:
	if EventBus.macro_world_generated.is_connected(_on_macro_world_generated):
		EventBus.macro_world_generated.disconnect(_on_macro_world_generated)
	if _map_3d_controller != null and is_instance_valid(_map_3d_controller):
		if _map_3d_controller.region_selected.is_connected(_on_map_region_selected):
			_map_3d_controller.region_selected.disconnect(_on_map_region_selected)
		if _map_3d_controller.army_selected.is_connected(_on_map_army_selected):
			_map_3d_controller.army_selected.disconnect(_on_map_army_selected)


func get_tactical_panel() -> TacticalCommandDrawerPanel:
	return _tactical_panel


func get_world_ecology_panel() -> WorldEcologyDrawerPanel:
	return _world_ecology_panel


func get_sovereignty_panel() -> SovereigntyDrawerPanel:
	return _sovereignty_panel


func get_map_3d_controller() -> Steppe3DMapController:
	return _map_3d_controller


func _mount_hud_panels(vanguard: ArmyController) -> void:
	var hud: OtukenHudRoot = get_node_or_null("HudLayer/OtukenHudRoot") as OtukenHudRoot
	if hud == null:
		return
	hud.set_player_context(_player_id, _army_id)

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
