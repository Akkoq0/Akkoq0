class_name SovereigntyDrawerPanel
extends VBoxContainer
## UI Drawer Panel (rank 3). Houses Phase 30 KurultaiCouncilRing,
## CommanderScarMedallionAndBalance, and HybridConquestAndCollapsePanel inside
## <= 332px width. Strictly read-only via SovereigntyViewModel; actions go via CommandBus.

var _player_id: int = 1
var _tracked_army_id: int = 1
var _target_coord: Vector2i = Vector2i.ZERO
var _view_model: SovereigntyViewModel = null

var _kurultai_ring: KurultaiCouncilRing = null
var _medallion_balance: CommanderScarMedallionAndBalance = null
var _conquest_collapse: HybridConquestAndCollapsePanel = null
var _ui_built: bool = false
var _is_refreshing: bool = false
var _subscriptions: Array[Dictionary] = []


func _ready() -> void:
	name = "SovereigntyDrawerPanel"
	custom_minimum_size = Vector2(280.0, 0.0)
	add_theme_constant_override("separation", 6)
	_build_ui()
	_connect_bus()
	refresh_from_viewmodel()


func _exit_tree() -> void:
	for entry: Dictionary in _subscriptions:
		var sig: Variant = entry.get("signal")
		var cb: Variant = entry.get("callable")
		if sig is Signal and cb is Callable:
			var s: Signal = sig
			var c: Callable = cb
			if s.is_connected(c):
				s.disconnect(c)
	_subscriptions.clear()


func set_context(p_player_id: int, p_army_id: int, p_coord: Vector2i) -> void:
	_player_id = p_player_id
	_tracked_army_id = p_army_id
	_target_coord = p_coord
	if _view_model != null:
		_view_model.set_context(_player_id, _tracked_army_id, _target_coord)
	if _conquest_collapse != null:
		_conquest_collapse.set_context(_player_id, _target_coord)
	refresh_from_viewmodel()


func get_kurultai_ring() -> KurultaiCouncilRing:
	return _kurultai_ring


func get_medallion_balance() -> CommanderScarMedallionAndBalance:
	return _medallion_balance


func get_conquest_collapse_panel() -> HybridConquestAndCollapsePanel:
	return _conquest_collapse


func refresh_from_viewmodel() -> void:
	if _is_refreshing:
		return
	_is_refreshing = true
	_build_ui()
	if _view_model == null:
		_view_model = SovereigntyViewModel.new(_player_id, _tracked_army_id, _target_coord)
	var snap: SovereigntyViewModel.SovereigntySnapshot = _view_model.capture_snapshot()
	if _kurultai_ring != null:
		_kurultai_ring.apply_snapshot(snap)
	if _medallion_balance != null:
		_medallion_balance.apply_snapshot(snap)
	if _conquest_collapse != null:
		_conquest_collapse.apply_snapshot(snap)
	_is_refreshing = false


func _build_ui() -> void:
	if _ui_built:
		return
	_ui_built = true

	var card: TamgaCardPanel = TamgaCardPanel.new()
	card.name = "SovereigntyCard"
	card.custom_minimum_size = Vector2(280.0, 0.0)
	card.set_semantic_tone(&"jade")
	add_child(card)

	var inner: VBoxContainer = VBoxContainer.new()
	inner.add_theme_constant_override("separation", 6)
	card.get_content_container().add_child(inner)

	_kurultai_ring = KurultaiCouncilRing.new()
	_kurultai_ring.name = "KurultaiCouncilRing"
	inner.add_child(_kurultai_ring)

	_medallion_balance = CommanderScarMedallionAndBalance.new()
	_medallion_balance.name = "CommanderScarMedallionAndBalance"
	inner.add_child(_medallion_balance)

	_conquest_collapse = HybridConquestAndCollapsePanel.new()
	_conquest_collapse.name = "HybridConquestAndCollapsePanel"
	_conquest_collapse.set_context(_player_id, _target_coord)
	inner.add_child(_conquest_collapse)


func _connect_bus() -> void:
	_subscribe_bus(EventBus.region_delegated_to_vassal, _on_sovereignty_dirty.unbind(4))
	_subscribe_bus(EventBus.vassal_silent_sabotage_delayed, _on_sovereignty_dirty.unbind(3))
	_subscribe_bus(EventBus.reputation_memory_changed, _on_sovereignty_dirty.unbind(4))
	_subscribe_bus(EventBus.commander_legacy_updated, _on_sovereignty_dirty.unbind(5))
	_subscribe_bus(EventBus.collapse_triggered, _on_sovereignty_dirty.unbind(3))
	_subscribe_bus(EventBus.collapse_path_selected, _on_sovereignty_dirty.unbind(4))
	_subscribe_bus(EventBus.succession_crisis_resolved, _on_sovereignty_dirty.unbind(4))


func _subscribe_bus(bus_signal: Signal, callback: Callable) -> void:
	if not bus_signal.is_connected(callback):
		bus_signal.connect(callback)
		_subscriptions.append({"signal": bus_signal, "callable": callback})


func _on_sovereignty_dirty() -> void:
	if is_inside_tree():
		refresh_from_viewmodel()
