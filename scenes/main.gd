extends Node3D
## Main scene coordinator (rank 4). Transitions the game from LOADING to
## PLAYING once the macro map has been generated.


var _tactical_panel: TacticalCommandDrawerPanel = null


func _ready() -> void:
	EventBus.macro_world_generated.connect(_on_macro_world_generated, CONNECT_ONE_SHOT)
	_mount_tactical_hud_panel()


func _exit_tree() -> void:
	if EventBus.macro_world_generated.is_connected(_on_macro_world_generated):
		EventBus.macro_world_generated.disconnect(_on_macro_world_generated)


func get_tactical_panel() -> TacticalCommandDrawerPanel:
	return _tactical_panel


func _mount_tactical_hud_panel() -> void:
	var hud: OtukenHudRoot = get_node_or_null("HudLayer/OtukenHudRoot") as OtukenHudRoot
	if hud == null:
		return
	var vanguard: ArmyController = get_node_or_null("ArmyRegistry/VanguardArmy") as ArmyController
	var target_player_id: int = vanguard.owner_id if (vanguard != null and vanguard.owner_id > 0) else 1
	var target_army_id: int = vanguard.army_id if (vanguard != null and vanguard.army_id > 0) else 1
	hud.register_drawer_slot(OtukenHudRoot.SLOT_TACTICAL_COMMAND, "Taktik & Komuta", &"jade")
	_tactical_panel = TacticalCommandDrawerPanel.new()
	_tactical_panel.bind_context(target_player_id, target_army_id, vanguard)
	hud.mount_panel_to_slot(OtukenHudRoot.SLOT_TACTICAL_COMMAND, _tactical_panel)


func _on_macro_world_generated(_world_state: MacroWorldState) -> void:
	CommandBus.dispatch(ChangeGameStateCommand.new(GameEnums.GameState.PLAYING))
