extends Node
## Autoload `CaravanLogisticsManager` (rank 2). Implements Phase 21 **Physical
## Non-Teleporting Steppe Caravans, Interception Front-Line Shock, and Captured
## Master Artisan Pools (`ArtisanPool`)**.

const RULES_PATH: String = "res://data/logistics/courier_and_caravan_rules.tres"

var _rules: CourierAndCaravanRules = null
var _caravans: Dictionary[StringName, PhysicalCaravan] = {}
var _artisans_by_player: Dictionary[int, int] = {}
var _army_front_ammo_deficit: Dictionary[int, float] = {}
var _army_front_supply_deficit: Dictionary[int, float] = {}


func _ready() -> void:
	_rules = ResourceLoader.load(RULES_PATH) as CourierAndCaravanRules
	if _rules == null:
		push_error("CaravanLogisticsManager: failed to load CourierAndCaravanRules at %s." % RULES_PATH)
	else:
		for err: String in _rules.get_validation_errors():
			push_error("CaravanLogisticsManager: %s" % err)
	CommandBus.register_handler(DispatchPhysicalCaravanCommand.ID, _handle_dispatch_caravan)
	CommandBus.register_handler(InterceptCaravanCommand.ID, _handle_intercept_caravan)
	CommandBus.register_handler(CaptureArtisansCommand.ID, _handle_capture_artisans)


func _exit_tree() -> void:
	CommandBus.unregister_handler(DispatchPhysicalCaravanCommand.ID, _handle_dispatch_caravan)
	CommandBus.unregister_handler(InterceptCaravanCommand.ID, _handle_intercept_caravan)
	CommandBus.unregister_handler(CaptureArtisansCommand.ID, _handle_capture_artisans)


func reset_logistics_state() -> void:
	_caravans.clear()
	_artisans_by_player.clear()
	_army_front_ammo_deficit.clear()
	_army_front_supply_deficit.clear()


func get_rules() -> CourierAndCaravanRules:
	return _rules


func get_caravan(caravan_id: StringName) -> PhysicalCaravan:
	if _caravans.has(caravan_id):
		return _caravans[caravan_id]
	return null


func get_all_caravans() -> Array[PhysicalCaravan]:
	var out: Array[PhysicalCaravan] = []
	for cid: StringName in _caravans:
		var c: PhysicalCaravan = _caravans[cid]
		if c != null:
			out.append(c)
	return out


func get_artisan_count(player_id: int) -> int:
	if _artisans_by_player.has(player_id):
		return _artisans_by_player[player_id]
	var initial: int = _rules.initial_artisans_per_player if _rules != null else 8
	_artisans_by_player[player_id] = initial
	return initial


func set_artisan_count(player_id: int, count: int) -> void:
	if player_id > 0:
		_artisans_by_player[player_id] = maxi(count, 0)


## Scales Steel crafting efficiency / armor quality by active Master Artisans.
func get_steel_quality_multiplier(player_id: int) -> float:
	var count: int = get_artisan_count(player_id)
	var per_master: float = _rules.steel_quality_per_artisan if _rules != null else 0.05
	return clampf(0.60 + float(count) * per_master, 0.60, 1.50)


## Meteoric Iron (`Gök Demiri`) master weapon/totem forging requires at least 6 Artisans.
func can_forge_meteoric_iron(player_id: int) -> bool:
	var min_masters: int = _rules.meteoric_forging_min_artisans if _rules != null else 6
	return get_artisan_count(player_id) >= min_masters


func get_army_front_ammo_deficit(army_id: int) -> float:
	if _army_front_ammo_deficit.has(army_id):
		return _army_front_ammo_deficit[army_id]
	return 0.0


func get_army_front_supply_deficit(army_id: int) -> float:
	if _army_front_supply_deficit.has(army_id):
		return _army_front_supply_deficit[army_id]
	return 0.0


## Advances all physical `EN_ROUTE` caravans over `dt_sec` seconds. Cargo never
## teleports: stockpiles & army ammo only update when physical transit completes.
func step_caravan_transit(dt_sec: float) -> int:
	var dt: float = maxf(dt_sec, 0.0)
	if dt <= 0.0:
		return 0
	var delivered_count: int = 0
	for cid: StringName in _caravans:
		var conv: PhysicalCaravan = _caravans[cid]
		if conv.state != GameEnums.CaravanCargoState.EN_ROUTE:
			continue
		conv.remaining_travel_sec = maxf(conv.remaining_travel_sec - dt, 0.0)
		if conv.remaining_travel_sec <= 0.0:
			conv.state = GameEnums.CaravanCargoState.DELIVERED
			var steel_delivered: int = 0
			for ore_id: StringName in conv.ore_cargo:
				var amt: int = conv.ore_cargo[ore_id]
				if amt > 0:
					CommandBus.dispatch(DepositResourcesCommand.new(conv.owner_id, ore_id, amt))
					if ore_id == &"steel":
						steel_delivered += amt
			if conv.food_cargo > 0:
				SeasonManager.set_food_reserve(SeasonManager.get_food_reserve() + conv.food_cargo)
			if conv.quiver_ammo_cargo > 0.0 and conv.dest_army_id > 0:
				var cur_def: float = get_army_front_ammo_deficit(conv.dest_army_id)
				_army_front_ammo_deficit[conv.dest_army_id] = maxf(cur_def - conv.quiver_ammo_cargo, 0.0)
				EventBus.army_caravan_resupply_delivered.emit(conv.dest_army_id, conv.quiver_ammo_cargo, conv.food_cargo)
			delivered_count += 1
			EventBus.caravan_delivered.emit(
				conv.caravan_id, conv.owner_id, steel_delivered, conv.food_cargo, conv.quiver_ammo_cargo)
	return delivered_count


func _handle_dispatch_caravan(command: GameCommand) -> bool:
	var cmd: DispatchPhysicalCaravanCommand = command as DispatchPhysicalCaravanCommand
	if cmd == null:
		return command.reject("Expected DispatchPhysicalCaravanCommand.")
	if cmd.caravan_id == &"" or cmd.owner_id <= 0:
		return command.reject("DispatchPhysicalCaravanCommand requires caravan_id and positive owner_id.")
	if _caravans.has(cmd.caravan_id):
		return command.reject("Caravan '%s' already exists." % cmd.caravan_id)

	var registry: OreRegistry = ResourceManager.get_registry()
	var costs: Array[ResourceAmount] = []
	for ore_id: StringName in cmd.ore_cargo:
		var amt: int = cmd.ore_cargo[ore_id]
		if amt > 0 and registry != null:
			var ore_res: OreData = registry.find_ore(ore_id)
			if ore_res != null:
				var ra: ResourceAmount = ResourceAmount.new()
				ra.ore = ore_res
				ra.amount = amt
				costs.append(ra)
	if not costs.is_empty():
		var spend: SpendResourcesCommand = SpendResourcesCommand.new(cmd.owner_id, costs)
		if not CommandBus.dispatch(spend):
			return command.reject("Player %d lacks caravan cargo ores to dispatch." % cmd.owner_id)

	if cmd.food_cargo > 0:
		var spent_food: int = SeasonManager.consume_food_for_migration(cmd.food_cargo)
		if spent_food < cmd.food_cargo:
			# Refund spent food & fail cleanly if insufficient
			SeasonManager.set_food_reserve(SeasonManager.get_food_reserve() + spent_food)
			for c: ResourceAmount in costs:
				CommandBus.dispatch(DepositResourcesCommand.new(cmd.owner_id, c.get_ore_id(), c.amount))
			return command.reject("Insufficient Food reserve to load caravan cargo.")

	var base_spd: float = _rules.caravan_speed_m_per_sec if _rules != null else 11.0
	var spd_mult: float = 1.0
	var active_cat: CataclysmEventData = CataclysmEngine.get_active_region_cataclysm(cmd.dest_coord)
	if active_cat != null:
		spd_mult *= clampf(active_cat.caravan_speed_multiplier, 0.25, 1.0)
	var dest_reg: RegionData = TerritoryManager.get_region(cmd.dest_coord)
	if dest_reg != null and dest_reg.scorched_seasons_remaining > 0:
		spd_mult *= 0.60
	var disruption: float = TerritoryManager.get_caravan_disruption_in_region(cmd.dest_coord, cmd.owner_id)
	spd_mult *= clampf(1.0 - disruption * 0.50, 0.35, 1.0)

	var eta: float = maxf(cmd.distance_m, 10.0) / maxf(base_spd * spd_mult, 1.0)
	var conv: PhysicalCaravan = PhysicalCaravan.new(
		cmd.caravan_id, cmd.owner_id, cmd.dest_army_id, cmd.origin_coord, cmd.dest_coord)
	conv.distance_m = cmd.distance_m
	conv.total_travel_sec = eta
	conv.remaining_travel_sec = eta
	conv.ore_cargo = cmd.ore_cargo.duplicate()
	conv.food_cargo = cmd.food_cargo
	conv.quiver_ammo_cargo = cmd.quiver_ammo_cargo
	conv.state = GameEnums.CaravanCargoState.EN_ROUTE
	_caravans[cmd.caravan_id] = conv

	cmd.computed_eta_sec = eta
	cmd.arrived_immediately = false
	cmd.state = conv.state

	EventBus.caravan_dispatched.emit(cmd.caravan_id, cmd.owner_id, cmd.origin_coord, cmd.dest_coord, eta)
	return true


func _handle_intercept_caravan(command: GameCommand) -> bool:
	var cmd: InterceptCaravanCommand = command as InterceptCaravanCommand
	if cmd == null:
		return command.reject("Expected InterceptCaravanCommand.")
	if not _caravans.has(cmd.caravan_id):
		return command.reject("Unknown caravan '%s'." % cmd.caravan_id)
	var conv: PhysicalCaravan = _caravans[cmd.caravan_id]
	if conv.state != GameEnums.CaravanCargoState.EN_ROUTE:
		return command.reject("Caravan '%s' is not EN_ROUTE." % cmd.caravan_id)
	if cmd.raider_id <= 0 or cmd.raider_id == conv.owner_id:
		return command.reject("InterceptCaravanCommand requires rival positive raider_id.")

	conv.state = GameEnums.CaravanCargoState.INTERCEPTED
	var steel_seized: int = 0
	for ore_id: StringName in conv.ore_cargo:
		var amt: int = conv.ore_cargo[ore_id]
		if amt > 0:
			CommandBus.dispatch(DepositResourcesCommand.new(cmd.raider_id, ore_id, amt))
			if ore_id == &"steel":
				steel_seized += amt

	var ammo_shock: float = _rules.interception_ammo_shock if _rules != null else 28.0
	var sup_shock: float = _rules.interception_supply_shock if _rules != null else 0.35
	if conv.dest_army_id > 0:
		_army_front_ammo_deficit[conv.dest_army_id] = get_army_front_ammo_deficit(conv.dest_army_id) + ammo_shock + conv.quiver_ammo_cargo
		_army_front_supply_deficit[conv.dest_army_id] = clampf(get_army_front_supply_deficit(conv.dest_army_id) + sup_shock, 0.0, 1.0)

	cmd.intercepted = true
	cmd.dest_army_id = conv.dest_army_id
	cmd.seized_steel = steel_seized
	cmd.seized_food = conv.food_cargo
	cmd.front_ammo_lost = ammo_shock + conv.quiver_ammo_cargo
	cmd.front_supply_shock = sup_shock

	EventBus.caravan_intercepted_crisis.emit(
		conv.caravan_id, conv.owner_id, cmd.raider_id, conv.dest_army_id, cmd.front_ammo_lost, sup_shock)
	return true


func _handle_capture_artisans(command: GameCommand) -> bool:
	var cmd: CaptureArtisansCommand = command as CaptureArtisansCommand
	if cmd == null:
		return command.reject("Expected CaptureArtisansCommand.")
	if cmd.victim_id <= 0 or cmd.captor_id <= 0 or cmd.victim_id == cmd.captor_id:
		return command.reject("CaptureArtisansCommand requires distinct positive victim_id and captor_id.")
	var cur_victim: int = get_artisan_count(cmd.victim_id)
	var taken: int = clampi(cmd.requested_masters, 0, cur_victim)
	if taken <= 0:
		return command.reject("Victim %d has no remaining artisans to capture." % cmd.victim_id)

	_artisans_by_player[cmd.victim_id] = cur_victim - taken
	_artisans_by_player[cmd.captor_id] = get_artisan_count(cmd.captor_id) + taken

	cmd.captured_masters = taken
	cmd.victim_remaining_artisans = _artisans_by_player[cmd.victim_id]
	cmd.captor_artisans = _artisans_by_player[cmd.captor_id]
	cmd.victim_can_forge_meteoric = can_forge_meteoric_iron(cmd.victim_id)

	EventBus.artisans_captured.emit(
		cmd.victim_id, cmd.captor_id, taken, get_steel_quality_multiplier(cmd.victim_id))
	return true
