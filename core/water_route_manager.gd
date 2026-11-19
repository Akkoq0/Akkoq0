extends Node
## Autoload `WaterRouteManager` (rank 2). Implements Phase 23 **Steppe Water
## Route Logistics, Well Sabotage/Kavruk Bozkır Contamination, Zud Freezing,
## and Cavalry Remount/Morale Dehydration Penalties**.

const RULES_PATH: String = "res://data/economy/water_and_market_rules.tres"
const BULLION_ORE_PATH: String = "res://data/ores/silver_gold.tres"
const STONE_ORE_PATH: String = "res://data/ores/stone.tres"

var _rules: WaterAndMarketRules = null
var _bullion_ore: OreData = null
var _stone_ore: OreData = null
var _sources_by_region: Dictionary[Vector2i, PackedStringArray] = {}
var _sources_by_id: Dictionary[StringName, WaterSourceNode] = {}


func _ready() -> void:
	_rules = ResourceLoader.load(RULES_PATH) as WaterAndMarketRules
	if _rules == null:
		push_error("WaterRouteManager: failed to load WaterAndMarketRules at %s." % RULES_PATH)
	else:
		for err: String in _rules.get_validation_errors():
			push_error("WaterRouteManager: %s" % err)
	_bullion_ore = ResourceLoader.load(BULLION_ORE_PATH) as OreData
	_stone_ore = ResourceLoader.load(STONE_ORE_PATH) as OreData

	CommandBus.register_handler(SabotageWellCommand.ID, _handle_sabotage_well)
	CommandBus.register_handler(RestoreWaterSourceCommand.ID, _handle_restore_water_source)
	EventBus.region_control_changed.connect(_on_region_control_changed)
	EventBus.season_changed.connect(_on_season_changed)


func _exit_tree() -> void:
	CommandBus.unregister_handler(SabotageWellCommand.ID, _handle_sabotage_well)
	CommandBus.unregister_handler(RestoreWaterSourceCommand.ID, _handle_restore_water_source)
	if EventBus.region_control_changed.is_connected(_on_region_control_changed):
		EventBus.region_control_changed.disconnect(_on_region_control_changed)
	if EventBus.season_changed.is_connected(_on_season_changed):
		EventBus.season_changed.disconnect(_on_season_changed)


func reset_water_state() -> void:
	_sources_by_region.clear()
	_sources_by_id.clear()


func get_rules() -> WaterAndMarketRules:
	return _rules


func register_water_source(
		coord: Vector2i,
		source_id: StringName,
		source_type: GameEnums.WaterSourceType = GameEnums.WaterSourceType.WELL,
		owner_id: int = 0) -> WaterSourceNode:
	if source_id == &"":
		return null
	var node: WaterSourceNode = WaterSourceNode.new(source_id, coord, source_type, owner_id)
	_sources_by_id[source_id] = node
	if not _sources_by_region.has(coord):
		_sources_by_region[coord] = PackedStringArray()
	var ids: PackedStringArray = _sources_by_region[coord]
	var sid_str: String = String(source_id)
	if not ids.has(sid_str):
		ids.append(sid_str)
		_sources_by_region[coord] = ids
	return node


func get_water_source(source_id: StringName) -> WaterSourceNode:
	if _sources_by_id.has(source_id):
		return _sources_by_id[source_id]
	return null


func count_usable_water_sources(coord: Vector2i, season_type: GameEnums.SeasonType, is_zud: bool = false) -> int:
	if not _sources_by_region.has(coord):
		return 0
	var winter_freeze: bool = is_zud or season_type == GameEnums.SeasonType.WINTER
	var ids: PackedStringArray = _sources_by_region[coord]
	var count: int = 0
	for sid_str: String in ids:
		var sid: StringName = StringName(sid_str)
		if _sources_by_id.has(sid):
			var node: WaterSourceNode = _sources_by_id[sid]
			if node != null and node.is_usable(winter_freeze):
				count += 1
	return count


func count_registered_water_sources(coord: Vector2i) -> int:
	if not _sources_by_region.has(coord):
		return 0
	return _sources_by_region[coord].size()


func count_sabotaged_water_sources(coord: Vector2i) -> int:
	if not _sources_by_region.has(coord):
		return 0
	var ids: PackedStringArray = _sources_by_region[coord]
	var count: int = 0
	for sid_str: String in ids:
		var sid: StringName = StringName(sid_str)
		if _sources_by_id.has(sid):
			var node: WaterSourceNode = _sources_by_id[sid]
			if node != null and node.contaminated_seasons_remaining > 0:
				count += 1
	return count


func contaminate_region_wells(coord: Vector2i, duration_seasons: int = 3, saboteur_id: int = 0, specific_source_id: StringName = &"") -> int:
	if not _sources_by_region.has(coord):
		return 0
	var ids: PackedStringArray = _sources_by_region[coord]
	var dur: int = maxi(duration_seasons, 1)
	var affected: int = 0
	for sid_str: String in ids:
		var sid: StringName = StringName(sid_str)
		if not _sources_by_id.has(sid):
			continue
		var node: WaterSourceNode = _sources_by_id[sid]
		if node == null:
			continue
		if specific_source_id != &"" and node.source_id != specific_source_id:
			continue
		node.contaminated_seasons_remaining = maxi(node.contaminated_seasons_remaining, dur)
		affected += 1
		EventBus.water_source_sabotaged.emit(coord, node.source_id, saboteur_id, node.contaminated_seasons_remaining)
	return affected


func step_seasonal_water_recovery(_season: SeasonData = null) -> void:
	for sid: StringName in _sources_by_id:
		var node: WaterSourceNode = _sources_by_id[sid]
		if node.contaminated_seasons_remaining > 0:
			node.contaminated_seasons_remaining -= 1


## Evaluates army cavalry/camp hydration at `coord` during `season_type` (`is_zud`).
## Returns dehydration status, remount_drain, and morale_penalty; when water route
## fails (sources registered cleanly yet 0 usable remain), emits `water_crisis_inflicted`.
func evaluate_army_hydration(army_id: int, coord: Vector2i, season_type: GameEnums.SeasonType, is_zud: bool = false) -> Dictionary[StringName, float]:
	var has_registered: bool = _sources_by_region.has(coord) and not _sources_by_region[coord].is_empty()
	if not has_registered:
		return {
			&"dehydrated": 0.0,
			&"usable_sources": 1.0,
			&"remount_drain": 0.0,
			&"morale_penalty": 0.0,
		}
	var usable: int = count_usable_water_sources(coord, season_type, is_zud)
	if usable > 0:
		return {
			&"dehydrated": 0.0,
			&"usable_sources": float(usable),
			&"remount_drain": 0.0,
			&"morale_penalty": 0.0,
		}
	var remount_drain: float = _rules.dehydration_remount_drain_per_season if _rules != null else 0.28
	var morale_pen: float = _rules.dehydration_morale_penalty if _rules != null else 18.0
	var winter_freeze: bool = is_zud or season_type == GameEnums.SeasonType.WINTER
	EventBus.water_crisis_inflicted.emit(army_id, coord, remount_drain, morale_pen, winter_freeze)
	return {
		&"dehydrated": 1.0,
		&"usable_sources": 0.0,
		&"remount_drain": remount_drain,
		&"morale_penalty": morale_pen,
	}


func _handle_sabotage_well(command: GameCommand) -> bool:
	var cmd: SabotageWellCommand = command as SabotageWellCommand
	if cmd == null:
		return command.reject("Expected SabotageWellCommand.")
	if cmd.saboteur_id <= 0:
		return command.reject("SabotageWellCommand requires positive saboteur_id.")
	if not _sources_by_region.has(cmd.region_coord):
		return command.reject("No water sources registered in region %s." % cmd.region_coord)

	var reg: RegionData = TerritoryManager.get_region(cmd.region_coord)
	var owner_id: int = reg.owner_id if reg != null else 0
	if owner_id > 0 and owner_id != cmd.saboteur_id:
		if not GracePeriodManager.validate_and_commit_action(cmd.saboteur_id, GameEnums.ToreActionType.BORDER_NODE_RAID, owner_id):
			return command.reject("Well sabotage blocked by active Töre Peace or Collapse truce.")

	var default_dur: int = _rules.well_sabotage_duration_seasons if _rules != null else 3
	var dur: int = maxi(cmd.duration_seasons, 1) if cmd.duration_seasons > 0 else default_dur
	var affected: int = contaminate_region_wells(cmd.region_coord, dur, cmd.saboteur_id, cmd.source_id)
	if affected <= 0:
		return command.reject("No matching water source '%s' found in region %s." % [cmd.source_id, cmd.region_coord])

	var cur_season: SeasonData = SeasonManager.get_current_season()
	var s_type: GameEnums.SeasonType = cur_season.season_type if cur_season != null else GameEnums.SeasonType.SPRING
	cmd.sabotaged = true
	cmd.sources_affected = affected
	cmd.remaining_usable_sources = count_usable_water_sources(cmd.region_coord, s_type, s_type == GameEnums.SeasonType.WINTER)
	return true


func _handle_restore_water_source(command: GameCommand) -> bool:
	var cmd: RestoreWaterSourceCommand = command as RestoreWaterSourceCommand
	if cmd == null:
		return command.reject("Expected RestoreWaterSourceCommand.")
	if cmd.actor_id <= 0:
		return command.reject("RestoreWaterSourceCommand requires positive actor_id.")

	var silver_cost: int = _rules.well_restore_bullion_cost if _rules != null else 25
	var stone_cost: int = _rules.well_restore_stone_cost if _rules != null else 20
	var costs: Array[ResourceAmount] = []
	if _bullion_ore != null and silver_cost > 0:
		var b_ra: ResourceAmount = ResourceAmount.new()
		b_ra.ore = _bullion_ore
		b_ra.amount = silver_cost
		costs.append(b_ra)
	if _stone_ore != null and stone_cost > 0:
		var s_ra: ResourceAmount = ResourceAmount.new()
		s_ra.ore = _stone_ore
		s_ra.amount = stone_cost
		costs.append(s_ra)
	if not costs.is_empty():
		var spend: SpendResourcesCommand = SpendResourcesCommand.new(cmd.actor_id, costs)
		if not CommandBus.dispatch(spend):
			return command.reject("Player %d lacks Silver (%d) or Stone (%d) to restore well." % [cmd.actor_id, silver_cost, stone_cost])

	var restored_id: StringName = cmd.source_id
	if _sources_by_region.has(cmd.region_coord):
		var ids: PackedStringArray = _sources_by_region[cmd.region_coord]
		for sid_str: String in ids:
			var sid: StringName = StringName(sid_str)
			if not _sources_by_id.has(sid):
				continue
			var node: WaterSourceNode = _sources_by_id[sid]
			if node == null:
				continue
			if restored_id == &"" or node.source_id == restored_id:
				node.contaminated_seasons_remaining = 0
				restored_id = node.source_id
	if not _sources_by_region.has(cmd.region_coord):
		var fallback_id: StringName = restored_id if restored_id != &"" else StringName("well_%d_%d" % [cmd.region_coord.x, cmd.region_coord.y])
		register_water_source(cmd.region_coord, fallback_id, GameEnums.WaterSourceType.WELL, cmd.actor_id)
		restored_id = fallback_id

	var cur_season: SeasonData = SeasonManager.get_current_season()
	var s_type: GameEnums.SeasonType = cur_season.season_type if cur_season != null else GameEnums.SeasonType.SPRING
	cmd.restored = true
	cmd.remaining_usable_sources = count_usable_water_sources(cmd.region_coord, s_type, false)
	EventBus.water_source_restored.emit(cmd.region_coord, restored_id, cmd.actor_id)
	return true


func _on_region_control_changed(
		region_coord: Vector2i,
		_owner_id: int,
		_control_percent: float,
		aftermath_choice: GameEnums.ConquestAftermathChoice,
		scorched_seasons: int) -> void:
	if aftermath_choice == GameEnums.ConquestAftermathChoice.SCORCHED_EARTH_PILLAGE and scorched_seasons > 0:
		contaminate_region_wells(region_coord, scorched_seasons, 0, &"")


func _on_season_changed(season: SeasonData, _cycle_index: int) -> void:
	step_seasonal_water_recovery(season)
