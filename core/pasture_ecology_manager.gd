extends Node
## Autoload `PastureEcologyManager` (rank 2). Simulates Phase 7 **Seasonal Steppe
## Pasture Ecology & Overgrazing (`Aşırı Otlatma`)** (`res://core/pasture_ecology_manager.gd`).
##
## Responsibilities:
##  * Tracks macro-region pasture capacity (`0..100`) consumed by `Yılkı` horse
##    and sheep herds (`pasture_depletion_rate`).
##  * When a region is overgrazed to `0.0`:
##      - Sets `starving_livestock = true` and halts meat/milk output (`0.0`).
##      - Flags mandatory `Sefer Arabası` camp relocation (`migration_required = true`).
##      - Triggers clan and army rebellion (`overgrazing_rebellion_triggered`) if
##        the camp refuses to migrate within the grace period.

const PASTURE_DATA_PATH: String = "res://data/world/pasture_data.tres"

var _pasture_data: PastureData = null
var _region_capacities: Dictionary[Vector2i, float] = {}
var _player_camp_regions: Dictionary[int, Vector2i] = {}
var _depleted_ticks_without_migration: Dictionary[int, int] = {}
var _starving_livestock: Dictionary[int, bool] = {}
var _migration_required: Dictionary[int, bool] = {}
var _rebellion_active: Dictionary[int, bool] = {}


func _ready() -> void:
	_pasture_data = ResourceLoader.load(PASTURE_DATA_PATH) as PastureData
	if _pasture_data == null:
		push_error("PastureEcologyManager: failed to load PastureData at %s." % PASTURE_DATA_PATH)
	else:
		for err: String in _pasture_data.get_validation_errors():
			push_error("PastureEcologyManager: %s" % err)
	CommandBus.register_handler(GrazePastureCommand.ID, _handle_graze_pasture)
	CommandBus.register_handler(MigrateCampToPastureCommand.ID, _handle_migrate_camp)


func _exit_tree() -> void:
	CommandBus.unregister_handler(GrazePastureCommand.ID, _handle_graze_pasture)
	CommandBus.unregister_handler(MigrateCampToPastureCommand.ID, _handle_migrate_camp)


func get_pasture_data() -> PastureData:
	return _pasture_data


func get_region_pasture_capacity(region_coord: Vector2i) -> float:
	var default_cap: float = _pasture_data.max_pasture_capacity if _pasture_data != null else 100.0
	return _region_capacities.get(region_coord, default_cap)


func is_livestock_starving(player_id: int) -> bool:
	return _starving_livestock.get(player_id, false)


func is_migration_required(player_id: int) -> bool:
	return _migration_required.get(player_id, false)


func is_overgrazing_rebellion_active(player_id: int) -> bool:
	return _rebellion_active.get(player_id, false)


func get_meat_milk_production_multiplier(player_id: int) -> float:
	if is_livestock_starving(player_id):
		return 0.0
	return 1.0


func _handle_graze_pasture(command: GameCommand) -> bool:
	var graze: GrazePastureCommand = command as GrazePastureCommand
	if graze == null:
		return command.reject("Expected GrazePastureCommand.")
	if _pasture_data == null:
		return command.reject("PastureData not loaded.")

	_player_camp_regions[graze.player_id] = graze.region_coord
	var current_cap: float = get_region_pasture_capacity(graze.region_coord)
	var delta: float = _pasture_data.compute_depletion_delta(graze.herd_size, graze.season_depletion_multiplier)
	var next_cap: float = clampf(current_cap - delta, 0.0, _pasture_data.max_pasture_capacity)
	_region_capacities[graze.region_coord] = next_cap

	var condition: GameEnums.PastureCondition = _pasture_data.classify_condition(next_cap)
	graze.remaining_capacity = next_cap
	graze.condition = condition

	if condition == GameEnums.PastureCondition.DEPLETED_STARVING:
		var was_starving: bool = is_livestock_starving(graze.player_id)
		_starving_livestock[graze.player_id] = true
		_migration_required[graze.player_id] = true
		graze.starving_livestock = true
		graze.meat_milk_production_multiplier = 0.0
		graze.migration_required = true

		if not was_starving:
			_depleted_ticks_without_migration[graze.player_id] = 1
			EventBus.pasture_depleted_starving_livestock.emit(graze.region_coord, graze.herd_size, true)
		else:
			var ticks: int = _depleted_ticks_without_migration.get(graze.player_id, 1) + 1
			_depleted_ticks_without_migration[graze.player_id] = ticks
			if ticks >= _pasture_data.rebellion_grace_ticks_after_depletion:
				_rebellion_active[graze.player_id] = true
				graze.rebellion_triggered = true
				CommandBus.dispatch(ModifyKutCommand.new(-_pasture_data.rebellion_kut_penalty, &"overgrazing_rebellion"))
				EventBus.overgrazing_rebellion_triggered.emit(
					graze.player_id, graze.region_coord, _pasture_data.rebellion_kut_penalty)
	else:
		_starving_livestock[graze.player_id] = false
		_migration_required[graze.player_id] = false
		_rebellion_active[graze.player_id] = false
		_depleted_ticks_without_migration[graze.player_id] = 0
		graze.starving_livestock = false
		graze.meat_milk_production_multiplier = 1.0
		graze.migration_required = false

	return true


func _handle_migrate_camp(command: GameCommand) -> bool:
	var migrate: MigrateCampToPastureCommand = command as MigrateCampToPastureCommand
	if migrate == null:
		return command.reject("Expected MigrateCampToPastureCommand.")
	if _pasture_data == null:
		return command.reject("PastureData not loaded.")

	var prev_coord: Vector2i = _player_camp_regions.get(migrate.player_id, Vector2i.ZERO)
	migrate.previous_region_coord = prev_coord
	if prev_coord == migrate.target_region_coord:
		return command.reject("Camp is already located at region %s." % migrate.target_region_coord)

	# Rested waterside target region has full or regenerated pasture capacity
	var target_cap: float = get_region_pasture_capacity(migrate.target_region_coord)
	if target_cap < _pasture_data.max_pasture_capacity:
		target_cap = clampf(target_cap + _pasture_data.waterside_regeneration_per_tick, 0.0, _pasture_data.max_pasture_capacity)
	_region_capacities[migrate.target_region_coord] = target_cap

	_player_camp_regions[migrate.player_id] = migrate.target_region_coord
	_starving_livestock[migrate.player_id] = false
	_migration_required[migrate.player_id] = false
	_rebellion_active[migrate.player_id] = false
	_depleted_ticks_without_migration[migrate.player_id] = 0

	migrate.new_pasture_capacity = target_cap
	migrate.starving_livestock_cleared = true
	migrate.meat_milk_production_multiplier = 1.0

	EventBus.camp_migrated_by_sefer_arabasi.emit(
		migrate.player_id, prev_coord, migrate.target_region_coord, target_cap)
	return true
