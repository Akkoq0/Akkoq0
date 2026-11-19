extends Node
## Autoload `CourierDispatchSystem` (rank 2). Implements Phase 21 **Courier
## Order Latency, Tactical Ambush & Plan Leakage, and Yılkı Dust Screen
## Reconnaissance Deception**.

const RULES_PATH: String = "res://data/logistics/courier_and_caravan_rules.tres"

var _rules: CourierAndCaravanRules = null
var _orders: Dictionary[StringName, CourierDispatchOrder] = {}
var _latest_order_by_army: Dictionary[int, StringName] = {}
var _delivered_orders_by_army: Dictionary[int, Array] = {}
var _active_dust_decoys: Dictionary[int, bool] = {}


func _ready() -> void:
	_rules = ResourceLoader.load(RULES_PATH) as CourierAndCaravanRules
	if _rules == null:
		push_error("CourierDispatchSystem: failed to load CourierAndCaravanRules at %s." % RULES_PATH)
	else:
		for err: String in _rules.get_validation_errors():
			push_error("CourierDispatchSystem: %s" % err)
	CommandBus.register_handler(DispatchCourierOrderCommand.ID, _handle_dispatch_courier)
	CommandBus.register_handler(AmbushCourierCommand.ID, _handle_ambush_courier)
	CommandBus.register_handler(ToggleDustScreenCommand.ID, _handle_toggle_dust_screen)


func _exit_tree() -> void:
	CommandBus.unregister_handler(DispatchCourierOrderCommand.ID, _handle_dispatch_courier)
	CommandBus.unregister_handler(AmbushCourierCommand.ID, _handle_ambush_courier)
	CommandBus.unregister_handler(ToggleDustScreenCommand.ID, _handle_toggle_dust_screen)


func reset_courier_state() -> void:
	_orders.clear()
	_latest_order_by_army.clear()
	_delivered_orders_by_army.clear()
	_active_dust_decoys.clear()


func get_rules() -> CourierAndCaravanRules:
	return _rules


func get_order(order_id: StringName) -> CourierDispatchOrder:
	if _orders.has(order_id):
		return _orders[order_id]
	return null


func get_active_order_for_army(army_id: int) -> CourierDispatchOrder:
	var latest_id: StringName = _latest_order_by_army.get(army_id, &"")
	if latest_id != &"" and _orders.has(latest_id):
		var latest_ord: CourierDispatchOrder = _orders[latest_id]
		if latest_ord.status == GameEnums.CourierStatus.IN_TRANSIT:
			return latest_ord
	for ord_id: StringName in _orders:
		var order: CourierDispatchOrder = _orders[ord_id]
		if order.target_army_id == army_id and order.status == GameEnums.CourierStatus.IN_TRANSIT:
			return order
	return null


func get_latest_order_for_army(army_id: int) -> CourierDispatchOrder:
	var latest_id: StringName = _latest_order_by_army.get(army_id, &"")
	if latest_id != &"" and _orders.has(latest_id):
		return _orders[latest_id]
	var found: CourierDispatchOrder = null
	for ord_id: StringName in _orders:
		var order: CourierDispatchOrder = _orders[ord_id]
		if order.target_army_id == army_id:
			found = order
	return found


func is_order_delivered(order_id: StringName) -> bool:
	if not _orders.has(order_id):
		return false
	return _orders[order_id].status == GameEnums.CourierStatus.DELIVERED


func is_army_awaiting_courier(army_id: int) -> bool:
	for ord_id: StringName in _orders:
		var order: CourierDispatchOrder = _orders[ord_id]
		if order.target_army_id == army_id and order.status == GameEnums.CourierStatus.IN_TRANSIT:
			return true
	return false


func get_delivered_order_count(army_id: int) -> int:
	if not _delivered_orders_by_army.has(army_id):
		return 0
	return _delivered_orders_by_army[army_id].size()


func has_ambushed_courier_intercepted_by(ambusher_id: int) -> bool:
	if ambusher_id <= 0:
		return false
	for ord_id: StringName in _orders:
		var order: CourierDispatchOrder = _orders[ord_id]
		if order != null and order.status == GameEnums.CourierStatus.AMBUSHED_LOST and order.exposed_to_faction_id == ambusher_id:
			return true
	return false


func is_player_plan_exposed_by_courier(player_id: int, army_id: int = -1) -> bool:
	if player_id <= 0:
		return false
	for ord_id: StringName in _orders:
		var order: CourierDispatchOrder = _orders[ord_id]
		if order != null and order.status == GameEnums.CourierStatus.AMBUSHED_LOST and order.player_id == player_id:
			if army_id <= 0 or order.target_army_id == army_id:
				return true
	return false


## Advances physical transit of all active mounted couriers by `dt_sec` seconds.
func step_courier_transit(dt_sec: float) -> int:
	var dt: float = maxf(dt_sec, 0.0)
	if dt <= 0.0:
		return 0
	var completed: int = 0
	for ord_id: StringName in _orders:
		var order: CourierDispatchOrder = _orders[ord_id]
		if order.status != GameEnums.CourierStatus.IN_TRANSIT:
			continue
		order.remaining_delay_sec = maxf(order.remaining_delay_sec - dt, 0.0)
		if order.remaining_delay_sec <= 0.0:
			order.status = GameEnums.CourierStatus.DELIVERED
			if not _delivered_orders_by_army.has(order.target_army_id):
				var arr: Array = []
				_delivered_orders_by_army[order.target_army_id] = arr
			_delivered_orders_by_army[order.target_army_id].append(order.order_id)
			completed += 1
			EventBus.courier_order_delivered.emit(
				order.order_id, order.player_id, order.target_army_id, order.command_type)
	return completed


## Activates Dust Screen Deception (`Toz Perdesi`) for `army_id`, raising fake
## apparent cavalry dust clouds using spare mounts.
func activate_dust_decoy(army_id: int, remount_horse_ratio: float = 1.0) -> bool:
	if army_id <= 0:
		return false
	if remount_horse_ratio < 0.25:
		return false
	_active_dust_decoys[army_id] = true
	return true


func clear_dust_decoy(army_id: int) -> void:
	_active_dust_decoys.erase(army_id)


func has_dust_decoy(army_id: int) -> bool:
	return _active_dust_decoys.get(army_id, false)


## Evaluates perceived power against an army raising a Yılkı Dust Screen.
## Weak distant scouts overestimate enemy numbers (~2.1x); strong scouting
## (`scout_strength >= 70.0`) or close-contact reconnaissance (`<= 35m`) pierces the veil.
func evaluate_dust_perception(
		observer_id: int,
		target_army_id: int,
		true_power: float,
		scout_strength: float,
		distance_m: float) -> Dictionary[StringName, float]:
	var safe_true: float = maxf(true_power, 0.0)
	var sees_through: bool = true
	var perceived: float = safe_true

	if has_dust_decoy(target_army_id):
		var threshold: float = _rules.scout_reveal_threshold if _rules != null else 70.0
		var close_dist: float = _rules.close_contact_reveal_distance_m if _rules != null else 35.0
		var mult: float = _rules.decoy_apparent_power_mult if _rules != null else 2.10
		if scout_strength < threshold and distance_m > close_dist:
			sees_through = false
			perceived = safe_true * mult

	EventBus.dust_deception_evaluated.emit(observer_id, target_army_id, safe_true, perceived, sees_through)
	return {
		&"true_power": safe_true,
		&"perceived_power": perceived,
		&"sees_through": 1.0 if sees_through else 0.0,
	}


func _handle_dispatch_courier(command: GameCommand) -> bool:
	var cmd: DispatchCourierOrderCommand = command as DispatchCourierOrderCommand
	if cmd == null:
		return command.reject("Expected DispatchCourierOrderCommand.")
	if cmd.order_id == &"" or cmd.player_id <= 0 or cmd.target_army_id <= 0:
		return command.reject("DispatchCourierOrderCommand requires order_id, player_id > 0, and target_army_id > 0.")
	if _orders.has(cmd.order_id):
		return command.reject("Courier order '%s' already exists." % cmd.order_id)

	var base_speed: float = _rules.courier_base_speed_m_per_sec if _rules != null else 18.0
	var terrain_mult: float = 1.0
	if cmd.terrain_type == GameEnums.TerrainType.MOUNTAIN or cmd.terrain_type == GameEnums.TerrainType.FOREST:
		terrain_mult = _rules.mountain_forest_delay_mult if _rules != null else 1.65
	var storm_mult: float = (_rules.winter_storm_delay_mult if _rules != null else 1.45) if cmd.is_winter_storm else 1.0
	var dist: float = maxf(cmd.origin_pos.distance_to(cmd.target_pos), 10.0)
	var delay_sec: float = (dist / maxf(base_speed, 1.0)) * terrain_mult * storm_mult

	var order: CourierDispatchOrder = CourierDispatchOrder.new(
		cmd.order_id, cmd.player_id, cmd.target_army_id, cmd.command_type, cmd.intended_tactic)
	order.origin_pos = cmd.origin_pos
	order.target_pos = cmd.target_pos
	order.total_delay_sec = delay_sec
	order.remaining_delay_sec = delay_sec
	order.status = GameEnums.CourierStatus.IN_TRANSIT
	_orders[cmd.order_id] = order
	_latest_order_by_army[cmd.target_army_id] = cmd.order_id

	cmd.computed_delay_sec = delay_sec
	cmd.status = order.status
	EventBus.courier_dispatched.emit(cmd.order_id, cmd.player_id, cmd.target_army_id, delay_sec)
	return true


func _handle_ambush_courier(command: GameCommand) -> bool:
	var cmd: AmbushCourierCommand = command as AmbushCourierCommand
	if cmd == null:
		return command.reject("Expected AmbushCourierCommand.")
	if not _orders.has(cmd.order_id):
		return command.reject("Unknown courier order '%s'." % cmd.order_id)
	var order: CourierDispatchOrder = _orders[cmd.order_id]
	if order.status != GameEnums.CourierStatus.IN_TRANSIT:
		return command.reject("Courier order '%s' is no longer IN_TRANSIT." % cmd.order_id)

	order.status = GameEnums.CourierStatus.AMBUSHED_LOST
	order.exposed_to_faction_id = cmd.ambusher_faction_id
	IntelligenceManager.record_intercepted_courier_report(
		cmd.ambusher_faction_id, order.player_id, order.target_army_id, order.intended_tactic)

	cmd.intercepted = true
	cmd.victim_player_id = order.player_id
	cmd.target_army_id = order.target_army_id
	cmd.leaked_tactic = order.intended_tactic

	EventBus.courier_ambushed_plan_exposed.emit(
		order.order_id, order.player_id, cmd.ambusher_faction_id, order.intended_tactic)
	return true


func _handle_toggle_dust_screen(command: GameCommand) -> bool:
	var cmd: ToggleDustScreenCommand = command as ToggleDustScreenCommand
	if cmd == null:
		return command.reject("Expected ToggleDustScreenCommand.")
	if cmd.army_id <= 0 or cmd.player_id <= 0:
		return command.reject("ToggleDustScreenCommand requires positive army_id and player_id.")
	if cmd.enable:
		var ratio: float = 0.0 if (is_nan(cmd.remount_horse_ratio) or is_inf(cmd.remount_horse_ratio)) else cmd.remount_horse_ratio
		if not activate_dust_decoy(cmd.army_id, ratio):
			return command.reject("Insufficient Yılkı remount ratio (min 0.25) to raise Toz Perdesi.")
	else:
		clear_dust_decoy(cmd.army_id)
	var now_active: bool = has_dust_decoy(cmd.army_id)
	cmd.active_after = now_active
	EventBus.dust_decoy_toggled.emit(cmd.army_id, cmd.player_id, now_active)
	return true
