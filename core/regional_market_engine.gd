extends Node
## Autoload `RegionalMarketEngine` (rank 2). Implements Phase 23 **Regional
## Dynamic Scarcity & Anti-Arbitrage Barter Economy** for 7-Ores, Food, and
## Yılkı Horses, including covert black-market trade for Exiles (`HOMELESS_EXILE`).

const RULES_PATH: String = "res://data/economy/water_and_market_rules.tres"
const BULLION_ORE_ID: StringName = &"silver_gold"
const DEFAULT_YILKI_RESERVE: int = 60

var _rules: WaterAndMarketRules = null
var _markets: Dictionary[Vector2i, RegionalMarketState] = {}
var _player_yilki_herds: Dictionary[int, int] = {}


func _ready() -> void:
	_rules = ResourceLoader.load(RULES_PATH) as WaterAndMarketRules
	if _rules == null:
		push_error("RegionalMarketEngine: failed to load WaterAndMarketRules at %s." % RULES_PATH)
	else:
		for err: String in _rules.get_validation_errors():
			push_error("RegionalMarketEngine: %s" % err)
	CommandBus.register_handler(ExecuteBarterTradeCommand.ID, _handle_execute_barter_trade)
	EventBus.caravan_intercepted_crisis.connect(_on_caravan_intercepted_crisis)
	EventBus.border_node_captured.connect(_on_border_node_captured)


func _exit_tree() -> void:
	CommandBus.unregister_handler(ExecuteBarterTradeCommand.ID, _handle_execute_barter_trade)
	if EventBus.caravan_intercepted_crisis.is_connected(_on_caravan_intercepted_crisis):
		EventBus.caravan_intercepted_crisis.disconnect(_on_caravan_intercepted_crisis)
	if EventBus.border_node_captured.is_connected(_on_border_node_captured):
		EventBus.border_node_captured.disconnect(_on_border_node_captured)


func reset_market_state() -> void:
	_markets.clear()
	_player_yilki_herds.clear()


func get_rules() -> WaterAndMarketRules:
	return _rules


func get_or_create_market(region_coord: Vector2i) -> RegionalMarketState:
	if _markets.has(region_coord):
		return _markets[region_coord]
	var state: RegionalMarketState = RegionalMarketState.new(region_coord)
	_markets[region_coord] = state
	return state


func get_player_yilki_herd(player_id: int) -> int:
	if _player_yilki_herds.has(player_id):
		return _player_yilki_herds[player_id]
	_player_yilki_herds[player_id] = DEFAULT_YILKI_RESERVE
	return DEFAULT_YILKI_RESERVE


func set_player_yilki_herd(player_id: int, count: int) -> void:
	if player_id > 0:
		_player_yilki_herds[player_id] = maxi(count, 0)


func get_regional_scarcity(region_coord: Vector2i, commodity_id: StringName) -> float:
	if not _markets.has(region_coord):
		return 1.0
	return _markets[region_coord].get_scarcity(commodity_id)


func boost_scarcity(region_coord: Vector2i, commodity_id: StringName, boost: float, reason: StringName = &"supply_disruption") -> float:
	var min_s: float = _rules.min_scarcity_multiplier if _rules != null else 0.60
	var max_s: float = _rules.max_scarcity_multiplier if _rules != null else 3.20
	var market: RegionalMarketState = get_or_create_market(region_coord)
	var next_s: float = clampf(market.get_scarcity(commodity_id) + maxf(boost, 0.0), min_s, max_s)
	market.set_scarcity(commodity_id, next_s)
	market.trade_routes_disrupted += 1
	if next_s >= 1.25:
		market.black_market_open = true
	EventBus.regional_market_scarcity_shifted.emit(region_coord, commodity_id, next_s, reason)
	return next_s


func compute_buy_quote(region_coord: Vector2i, commodity_id: StringName, quantity: int, is_black_market: bool = false) -> Dictionary[StringName, float]:
	if _rules == null:
		return {&"unit_price": 0.0, &"total_silver": 0.0, &"freight_fee": 0.0}
	var scarcity: float = get_regional_scarcity(region_coord, commodity_id)
	var unit_p: float = _rules.compute_buy_unit_price(commodity_id, scarcity, quantity, is_black_market)
	var total: int = maxi(int(ceilf(unit_p * float(maxi(quantity, 1)))), 1)
	var freight: int = maxi(int(ceilf(float(total) * _rules.caravan_freight_fee_ratio)), 1)
	return {
		&"unit_price": unit_p,
		&"total_silver": float(total),
		&"freight_fee": float(freight),
	}


func compute_sell_quote(region_coord: Vector2i, commodity_id: StringName, quantity: int, is_black_market: bool = false, player_id: int = 1) -> Dictionary[StringName, float]:
	if _rules == null:
		return {&"unit_price": 0.0, &"total_silver": 0.0, &"freight_fee": 0.0}
	var scarcity: float = get_regional_scarcity(region_coord, commodity_id)
	var is_exile: bool = CollapseRecoveryFSM.get_player_state(player_id) == GameEnums.CollapseState.HOMELESS_EXILE
	var unit_p: float = _rules.compute_sell_unit_price(commodity_id, scarcity, quantity, is_black_market, is_exile)
	var gross: int = maxi(int(floorf(unit_p * float(maxi(quantity, 1)))), 1)
	var freight: int = maxi(int(ceilf(float(gross) * (_rules.caravan_freight_fee_ratio * 0.5))), 1)
	var net: int = maxi(gross - freight, 0)
	return {
		&"unit_price": unit_p,
		&"total_silver": float(net),
		&"freight_fee": float(freight),
	}


func step_seasonal_market_normalization(cycles: int = 1) -> void:
	var decay_step: float = 0.12 * float(maxi(cycles, 1))
	for coord: Vector2i in _markets:
		var market: RegionalMarketState = _markets[coord]
		var keys: Array[StringName] = market.scarcity_multipliers.keys()
		for k: StringName in keys:
			var cur: float = market.scarcity_multipliers[k]
			if cur > 1.0:
				market.scarcity_multipliers[k] = maxf(cur - decay_step, 1.0)
			elif cur < 1.0:
				market.scarcity_multipliers[k] = minf(cur + decay_step, 1.0)


func _get_player_commodity_stock(player_id: int, commodity_id: StringName) -> int:
	if commodity_id == &"food":
		return SeasonManager.get_food_reserve()
	if commodity_id == &"yilki_horse":
		return get_player_yilki_herd(player_id)
	return ResourceManager.get_amount(player_id, commodity_id)


func _is_supported_commodity(commodity_id: StringName) -> bool:
	if commodity_id == BULLION_ORE_ID:
		return false
	if _rules == null:
		return false
	return _rules.get_base_price(commodity_id) > 0.0


func _handle_execute_barter_trade(command: GameCommand) -> bool:
	var cmd: ExecuteBarterTradeCommand = command as ExecuteBarterTradeCommand
	if cmd == null:
		return command.reject("Expected ExecuteBarterTradeCommand.")
	if _rules == null:
		return command.reject("WaterAndMarketRules not loaded.")
	if cmd.player_id <= 0 or cmd.quantity <= 0:
		return command.reject("ExecuteBarterTradeCommand requires positive player_id and quantity.")
	if not _is_supported_commodity(cmd.commodity_id):
		return command.reject("Unsupported or non-barterable commodity '%s'." % cmd.commodity_id)

	var is_exile: bool = CollapseRecoveryFSM.get_player_state(cmd.player_id) == GameEnums.CollapseState.HOMELESS_EXILE
	if is_exile and not cmd.is_black_market:
		return command.reject("Homeless Exile factions can only trade via black-market smuggling routes.")

	var registry: OreRegistry = ResourceManager.get_registry()
	var bullion_ore: OreData = registry.find_ore(BULLION_ORE_ID) if registry != null else null
	if bullion_ore == null:
		return command.reject("Bullion currency '%s' unavailable." % BULLION_ORE_ID)

	var market: RegionalMarketState = get_or_create_market(cmd.region_coord)
	if cmd.direction == GameEnums.BarterDirection.BUY_FROM_MARKET:
		var quote: Dictionary[StringName, float] = compute_buy_quote(
			cmd.region_coord, cmd.commodity_id, cmd.quantity, cmd.is_black_market)
		var total_cost: int = int(quote[&"total_silver"])
		var freight_paid: int = int(quote[&"freight_fee"])
		var bullion_ra: ResourceAmount = ResourceAmount.new()
		bullion_ra.ore = bullion_ore
		bullion_ra.amount = total_cost
		var spend_arr: Array[ResourceAmount] = [bullion_ra]
		if not CommandBus.dispatch(SpendResourcesCommand.new(cmd.player_id, spend_arr)):
			return command.reject("Player %d lacks %d silver_gold to buy %d '%s'." % [cmd.player_id, total_cost, cmd.quantity, cmd.commodity_id])

		if cmd.commodity_id == &"food":
			SeasonManager.set_food_reserve(SeasonManager.get_food_reserve() + cmd.quantity)
		elif cmd.commodity_id == &"yilki_horse":
			set_player_yilki_herd(cmd.player_id, get_player_yilki_herd(cmd.player_id) + cmd.quantity)
		else:
			CommandBus.dispatch(DepositResourcesCommand.new(cmd.player_id, cmd.commodity_id, cmd.quantity))

		cmd.executed = true
		cmd.unit_price = quote[&"unit_price"]
		cmd.total_silver_delta = -total_cost
		cmd.freight_fee_paid = freight_paid
	else:
		var avail: int = _get_player_commodity_stock(cmd.player_id, cmd.commodity_id)
		if avail < cmd.quantity:
			return command.reject("Player %d holds %d '%s', cannot sell %d." % [cmd.player_id, avail, cmd.commodity_id, cmd.quantity])

		var quote: Dictionary[StringName, float] = compute_sell_quote(
			cmd.region_coord, cmd.commodity_id, cmd.quantity, cmd.is_black_market, cmd.player_id)
		var net_silver: int = int(quote[&"total_silver"])
		var freight_paid: int = int(quote[&"freight_fee"])

		if cmd.commodity_id == &"food":
			SeasonManager.consume_food_for_migration(cmd.quantity)
		elif cmd.commodity_id == &"yilki_horse":
			set_player_yilki_herd(cmd.player_id, avail - cmd.quantity)
		else:
			var sell_ore: OreData = registry.find_ore(cmd.commodity_id)
			if sell_ore == null:
				return command.reject("Missing OreData for '%s'." % cmd.commodity_id)
			var sell_ra: ResourceAmount = ResourceAmount.new()
			sell_ra.ore = sell_ore
			sell_ra.amount = cmd.quantity
			var s_arr: Array[ResourceAmount] = [sell_ra]
			if not CommandBus.dispatch(SpendResourcesCommand.new(cmd.player_id, s_arr)):
				return command.reject("Failed deducting sold '%s' from player %d." % [cmd.commodity_id, cmd.player_id])

		if net_silver > 0:
			CommandBus.dispatch(DepositResourcesCommand.new(cmd.player_id, BULLION_ORE_ID, net_silver))

		# Abundant sales relieve acute regional scarcity slightly (anti-inflation pressure)
		var min_s: float = _rules.min_scarcity_multiplier if _rules != null else 0.60
		var cur_s: float = market.get_scarcity(cmd.commodity_id)
		if cur_s > min_s:
			market.set_scarcity(cmd.commodity_id, maxf(cur_s - minf(0.05, float(cmd.quantity) * 0.002), min_s))

		cmd.executed = true
		cmd.unit_price = quote[&"unit_price"]
		cmd.total_silver_delta = net_silver
		cmd.freight_fee_paid = freight_paid

	market.total_volume_traded += cmd.quantity
	EventBus.barter_trade_executed.emit(
		cmd.player_id, cmd.region_coord, cmd.commodity_id, cmd.direction,
		cmd.quantity, cmd.total_silver_delta, cmd.is_black_market)
	return true


func _on_caravan_intercepted_crisis(_caravan_id: StringName, owner_id: int, _raider_id: int, _dest_army_id: int, _ammo_lost: float, _supply_drop: float) -> void:
	var boost: float = _rules.caravan_cut_scarcity_boost if _rules != null else 0.45
	var owned_coords: Array[Vector2i] = TerritoryManager.get_owned_region_coords(owner_id)
	var target_coord: Vector2i = owned_coords[0] if not owned_coords.is_empty() else Vector2i.ZERO
	boost_scarcity(target_coord, &"steel", boost, &"caravan_corridor_severed")
	boost_scarcity(target_coord, &"food", boost * 0.85, &"caravan_corridor_severed")


func _on_border_node_captured(region_coord: Vector2i, _node_id: StringName, _prev_owner_id: int, _new_owner_id: int, _tug_radius_m: float, overlapping_enemies: int) -> void:
	if overlapping_enemies > 0:
		var boost: float = _rules.quarry_loss_scarcity_boost if _rules != null else 0.35
		boost_scarcity(region_coord, &"iron", boost, &"quarry_node_contested")
		boost_scarcity(region_coord, &"coal", boost, &"quarry_node_contested")
