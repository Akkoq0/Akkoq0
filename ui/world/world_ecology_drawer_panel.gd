class_name WorldEcologyDrawerPanel
extends VBoxContainer
## UI Drawer Panel (rank 3). Houses Phase 29 SkyConstellationWidget,
## ZudSundialAndWaterGauge, and MoltenOreAndMarketCrucible inside <= 332px width.
## Strictly read-only via WorldEcologyViewModel; all actions go via CommandBus.

var _player_id: int = 1
var _tracked_army_id: int = 1
var _tracked_region: Vector2i = Vector2i.ZERO
var _view_model: WorldEcologyViewModel = null

var _constellation: SkyConstellationWidget = null
var _sundial_water: ZudSundialAndWaterGauge = null
var _crucible: MoltenOreAndMarketCrucible = null
var _status_label: Label = null
var _ui_built: bool = false
var _is_refreshing: bool = false
var _subscriptions: Array[Dictionary] = []


func _ready() -> void:
	name = "WorldEcologyDrawerPanel"
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


func set_context(p_player_id: int, p_army_id: int, p_region: Vector2i) -> void:
	_player_id = p_player_id
	_tracked_army_id = p_army_id
	_tracked_region = p_region
	if _view_model != null:
		_view_model.set_context(_player_id, _tracked_army_id, _tracked_region)
	refresh_from_viewmodel()


func get_constellation_widget() -> SkyConstellationWidget:
	return _constellation


func get_sundial_water_widget() -> ZudSundialAndWaterGauge:
	return _sundial_water


func get_crucible_widget() -> MoltenOreAndMarketCrucible:
	return _crucible


func refresh_from_viewmodel() -> void:
	if _is_refreshing:
		return
	_is_refreshing = true
	_build_ui()
	if _view_model == null:
		_view_model = WorldEcologyViewModel.new(_player_id, _tracked_army_id, _tracked_region)
	var snap: WorldEcologyViewModel.WorldEcologySnapshot = _view_model.capture_snapshot()
	if _constellation != null:
		_constellation.apply_snapshot(snap)
	if _sundial_water != null:
		_sundial_water.apply_snapshot(snap)
	if _crucible != null:
		_crucible.apply_snapshot(snap)
	if _status_label != null:
		_status_label.text = "Bölge (%d,%d) · Yılkı: %d · Kış Ufku: %.1f Mevsim" % [
			snap.region_coord.x, snap.region_coord.y, snap.yilki_herd_count, snap.winter_horizon_seasons]
	_is_refreshing = false


func trigger_restore_water(source_id: StringName) -> bool:
	var cmd: RestoreWaterSourceCommand = RestoreWaterSourceCommand.new(_player_id, _tracked_region, source_id)
	var ok: bool = CommandBus.dispatch(cmd)
	refresh_from_viewmodel()
	return ok


func trigger_barter_iron(quantity: int = 1, use_black_market: bool = false) -> bool:
	var cmd: ExecuteBarterTradeCommand = ExecuteBarterTradeCommand.new(
		_player_id, _tracked_region, &"iron", GameEnums.BarterDirection.BUY_FROM_MARKET, quantity, use_black_market)
	var ok: bool = CommandBus.dispatch(cmd)
	refresh_from_viewmodel()
	return ok


func _build_ui() -> void:
	if _ui_built:
		return
	_ui_built = true

	var card: TamgaCardPanel = TamgaCardPanel.new()
	card.name = "WorldEcologyCard"
	card.custom_minimum_size = Vector2(280.0, 0.0)
	card.set_semantic_tone(&"bronze")
	add_child(card)

	var inner: VBoxContainer = VBoxContainer.new()
	inner.add_theme_constant_override("separation", 6)
	card.get_content_container().add_child(inner)

	_constellation = SkyConstellationWidget.new()
	_constellation.name = "SkyConstellationWidget"
	inner.add_child(_constellation)

	_sundial_water = ZudSundialAndWaterGauge.new()
	_sundial_water.name = "ZudSundialAndWaterGauge"
	inner.add_child(_sundial_water)

	_crucible = MoltenOreAndMarketCrucible.new()
	_crucible.name = "MoltenOreAndMarketCrucible"
	inner.add_child(_crucible)

	_status_label = Label.new()
	_status_label.name = "WorldEcologyStatusLabel"
	_status_label.add_theme_font_size_override("font_size", 11)
	_status_label.add_theme_color_override("font_color", NeoSteppePalette.TEXT_MUTED)
	inner.add_child(_status_label)


func _connect_bus() -> void:
	_subscribe_bus(EventBus.season_changed, _on_world_dirty.unbind(2))
	_subscribe_bus(EventBus.systemic_synergy_evaluated, _on_world_dirty.unbind(1))
	_subscribe_bus(EventBus.water_source_sabotaged, _on_world_dirty.unbind(4))
	_subscribe_bus(EventBus.water_source_restored, _on_world_dirty.unbind(3))
	_subscribe_bus(EventBus.barter_trade_executed, _on_world_dirty.unbind(7))
	_subscribe_bus(EventBus.resource_amount_changed, _on_world_dirty.unbind(4))


func _subscribe_bus(bus_signal: Signal, callback: Callable) -> void:
	if not bus_signal.is_connected(callback):
		bus_signal.connect(callback)
		_subscriptions.append({"signal": bus_signal, "callable": callback})


func _on_world_dirty() -> void:
	if is_inside_tree():
		refresh_from_viewmodel()
