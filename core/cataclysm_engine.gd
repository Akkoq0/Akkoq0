extends Node
## Autoload `CataclysmEngine` (rank 2). Implements Phase 9 **Major Steppe
## Cataclysms & Natural Destruction Engine** (`res://core/cataclysm_engine.gd`).
##
## Models:
##  1. `KARA_ZUD_ICE_TRAP`: freezes pastures (`0.15x`), cripples Yılkı grazing &
##     movement (`0.45x`), and slows/derails supply caravans (`0.35x`).
##  2. `STEPPE_WILDFIRE_SCORCH`: burns pastures (`0.10x`) and `SIK_ORMAN` ambush
##     cover (`-65%` concealment), forcing migration.
##  3. `GREAT_FLOOD_QUAKE_EXODUS`: inflicts `structural_wear` (`0.45`) on
##     buildings and drives a `refugee_influx` (`+180`) into the region.

const KARA_ZUD_PATH: String = "res://data/cataclysms/kara_zud_ice_trap.tres"
const WILDFIRE_PATH: String = "res://data/cataclysms/steppe_wildfire_scorch.tres"
const FLOOD_QUAKE_PATH: String = "res://data/cataclysms/great_flood_quake_exodus.tres"

var _catalog: Dictionary[GameEnums.CataclysmType, CataclysmEventData] = {}
var _active_region_cataclysms: Dictionary[Vector2i, CataclysmEventData] = {}


func _ready() -> void:
	_register_cataclysm(KARA_ZUD_PATH)
	_register_cataclysm(WILDFIRE_PATH)
	_register_cataclysm(FLOOD_QUAKE_PATH)
	CommandBus.register_handler(EvaluateCataclysmCommand.ID, _handle_evaluate_cataclysm)


func _exit_tree() -> void:
	CommandBus.unregister_handler(EvaluateCataclysmCommand.ID, _handle_evaluate_cataclysm)


func get_cataclysm_data(c_type: GameEnums.CataclysmType) -> CataclysmEventData:
	if _catalog.has(c_type):
		return _catalog[c_type]
	return null


func get_active_region_cataclysm(region_coord: Vector2i) -> CataclysmEventData:
	if _active_region_cataclysms.has(region_coord):
		return _active_region_cataclysms[region_coord]
	return null


func clear_region_cataclysm(region_coord: Vector2i) -> void:
	if _active_region_cataclysms.has(region_coord):
		var prev: CataclysmEventData = _active_region_cataclysms[region_coord]
		_active_region_cataclysms.erase(region_coord)
		EventBus.cataclysm_subsided.emit(prev.cataclysm_id, region_coord)


func _handle_evaluate_cataclysm(command: GameCommand) -> bool:
	var cmd: EvaluateCataclysmCommand = command as EvaluateCataclysmCommand
	if cmd == null:
		return command.reject("Expected EvaluateCataclysmCommand.")

	var chosen_type: GameEnums.CataclysmType = GameEnums.CataclysmType.NONE
	if cmd.is_zud_winter and cmd.temperature_celsius <= -15.0 and cmd.pasture_depleted:
		chosen_type = GameEnums.CataclysmType.KARA_ZUD_ICE_TRAP
	elif cmd.drought_severity >= 0.75 and cmd.wind_speed_m_per_sec >= 10.0:
		chosen_type = GameEnums.CataclysmType.STEPPE_WILDFIRE_SCORCH
	elif cmd.river_slope_quake_hazard >= 0.75:
		chosen_type = GameEnums.CataclysmType.GREAT_FLOOD_QUAKE_EXODUS

	cmd.triggered_type = chosen_type
	if chosen_type == GameEnums.CataclysmType.NONE or not _catalog.has(chosen_type):
		return true

	var data: CataclysmEventData = _catalog[chosen_type]
	var existing: CataclysmEventData = get_active_region_cataclysm(cmd.region_coord)
	var already_active_same: bool = existing != null and existing.cataclysm_type == chosen_type
	_active_region_cataclysms[cmd.region_coord] = data
	cmd.event_data = data
	cmd.pasture_yield_multiplier = data.pasture_yield_multiplier
	cmd.caravan_speed_multiplier = data.caravan_speed_multiplier
	cmd.forest_concealment_loss_ratio = data.forest_concealment_loss_ratio
	cmd.structural_wear_ratio = data.structural_wear_ratio
	cmd.refugee_influx_count = data.refugee_influx_count
	cmd.open_response_options = data.open_response_options

	if not already_active_same:
		if data.kut_shock_drain > 0.0:
			CommandBus.dispatch(ModifyKutCommand.new(-data.kut_shock_drain, data.cataclysm_id))

		EventBus.cataclysm_erupted.emit(
			data.cataclysm_id,
			data.cataclysm_type,
			cmd.region_coord,
			data.pasture_yield_multiplier,
			data.caravan_speed_multiplier,
			data.structural_wear_ratio,
			data.refugee_influx_count)
	return true


func _register_cataclysm(path: String) -> void:
	var data: CataclysmEventData = ResourceLoader.load(path) as CataclysmEventData
	if data == null:
		push_error("CataclysmEngine: failed to load CataclysmEventData at %s." % path)
		return
	for err: String in data.get_validation_errors():
		push_error("CataclysmEngine: %s" % err)
	_catalog[data.cataclysm_type] = data
