extends Node
## Autoload `GracePeriodManager` (rank 2). Implements Phase 18 **Persistent
## World Physics, Graduated Töre Peace (Kurultay Barışı) & Anti-Snowball
## Equations** (`res://core/grace_period_manager.gd`).

const RULES_PATH: String = "res://data/world/persistent_world_rules.tres"
const STEEL_ORE_PATH: String = "res://data/ores/steel.tres"
const IRON_ORE_PATH: String = "res://data/ores/iron.tres"

var _rules: PersistentWorldRules = null
var _steel_ore: OreData = null
var _iron_ore: OreData = null

var _persistent_mode_active: bool = false
var _server_elapsed_hours: float = 0.0
var _global_stage: GameEnums.TorePeaceStage = GameEnums.TorePeaceStage.STAGE_1_FULL_TORE_PEACE
var _player_join_hours: Dictionary[int, float] = {}
var _personal_peace_until_hours: Dictionary[int, float] = {}
var _personal_peace_forfeited: Dictionary[int, bool] = {}
var _player_spawn_coords: Dictionary[int, Vector2i] = {}
var _player_idle_hours: Dictionary[int, float] = {}


static func _safe_float(val: float, fallback: float) -> float:
	if is_nan(val) or is_inf(val):
		return fallback
	return val


func _ready() -> void:
	_rules = ResourceLoader.load(RULES_PATH) as PersistentWorldRules
	if _rules == null:
		push_error("GracePeriodManager: failed to load PersistentWorldRules at %s." % RULES_PATH)
	else:
		for err: String in _rules.get_validation_errors():
			push_error("GracePeriodManager: %s" % err)
	_steel_ore = ResourceLoader.load(STEEL_ORE_PATH) as OreData
	_iron_ore = ResourceLoader.load(IRON_ORE_PATH) as OreData
	CommandBus.register_handler(StepAntiSnowballTickCommand.ID, _handle_step_anti_snowball)


func _exit_tree() -> void:
	CommandBus.unregister_handler(StepAntiSnowballTickCommand.ID, _handle_step_anti_snowball)


func get_rules() -> PersistentWorldRules:
	return _rules


func configure_persistent_world(enabled: bool, elapsed_hours: float = 0.0) -> void:
	_persistent_mode_active = enabled
	_server_elapsed_hours = maxf(_safe_float(elapsed_hours, 0.0), 0.0)
	_global_stage = _rules.get_stage_for_hours(_server_elapsed_hours) if _rules != null else GameEnums.TorePeaceStage.STAGE_1_FULL_TORE_PEACE
	if not enabled:
		_player_join_hours.clear()
		_personal_peace_until_hours.clear()
		_personal_peace_forfeited.clear()
		_player_spawn_coords.clear()
		_player_idle_hours.clear()


func reset_persistent_world() -> void:
	configure_persistent_world(false, 0.0)


func is_persistent_mode_active() -> bool:
	return _persistent_mode_active


func get_server_elapsed_hours() -> float:
	return _server_elapsed_hours


func get_global_stage() -> GameEnums.TorePeaceStage:
	return _global_stage


## Advances persistent server clock by `hours` and transitions Töre Peace stage.
func advance_world_hours(hours: float) -> GameEnums.TorePeaceStage:
	var dt: float = maxf(_safe_float(hours, 0.0), 0.0)
	var prev_stage: GameEnums.TorePeaceStage = _global_stage
	_server_elapsed_hours += dt
	if _rules != null:
		_global_stage = _rules.get_stage_for_hours(_server_elapsed_hours)
	if _global_stage != prev_stage:
		EventBus.tore_peace_stage_changed.emit(prev_stage, _global_stage, _server_elapsed_hours)
	return _global_stage


## Registers a persistent player. Late joiners spawn on the outer rim (`Uç Beyi`)
## and receive a 48h personal Töre Peace protection window.
func register_player(player_id: int, is_late_joiner: bool = false, grid_size: Vector2i = Vector2i(10, 10), slot_seed: int = 0) -> Vector2i:
	if player_id <= 0:
		return Vector2i.ZERO
	_player_join_hours[player_id] = _server_elapsed_hours
	_personal_peace_forfeited[player_id] = false
	_player_idle_hours[player_id] = 0.0

	var spawn_coord: Vector2i = _compute_spawn_coord(is_late_joiner or _server_elapsed_hours > 0.0, grid_size, slot_seed, player_id)
	_player_spawn_coords[player_id] = spawn_coord

	if is_late_joiner or _server_elapsed_hours > 0.0:
		var dur: float = _rules.late_join_personal_peace_hours if _rules != null else 48.0
		_personal_peace_until_hours[player_id] = _server_elapsed_hours + dur
		EventBus.personal_tore_peace_granted.emit(player_id, dur, spawn_coord)
	else:
		_personal_peace_until_hours[player_id] = 0.0
	return spawn_coord


func get_player_spawn_coord(player_id: int) -> Vector2i:
	return _player_spawn_coords.get(player_id, Vector2i.ZERO)


func is_outer_rim_coord(coord: Vector2i, grid_size: Vector2i = Vector2i(10, 10)) -> bool:
	var margin: int = _rules.late_join_border_margin_cells if _rules != null else 1
	return coord.x < margin or coord.y < margin or coord.x >= grid_size.x - margin or coord.y >= grid_size.y - margin


func has_active_personal_peace(player_id: int) -> bool:
	if _personal_peace_forfeited.get(player_id, false):
		return false
	var until_h: float = _personal_peace_until_hours.get(player_id, 0.0)
	return _server_elapsed_hours < until_h


func get_remaining_personal_peace_hours(player_id: int) -> float:
	if not has_active_personal_peace(player_id):
		return 0.0
	var until_h: float = _personal_peace_until_hours.get(player_id, 0.0)
	return maxf(until_h - _server_elapsed_hours, 0.0)


func forfeit_personal_peace(player_id: int, reason: StringName = &"hostile_aggression") -> bool:
	if not has_active_personal_peace(player_id):
		return false
	_personal_peace_forfeited[player_id] = true
	_personal_peace_until_hours[player_id] = _server_elapsed_hours
	EventBus.personal_tore_peace_forfeited.emit(player_id, reason)
	return true


## Drops `actor_id`'s personal 48h Töre Peace if `actor_id` commits a hostile act
## (attack or offensive espionage) against another real player (`target_player_id > 0`).
func notify_hostile_intent(actor_id: int, target_player_id: int, is_espionage: bool = false) -> void:
	if not _persistent_mode_active:
		return
	if actor_id <= 0 or target_player_id <= 0 or actor_id == target_player_id:
		return
	if has_active_personal_peace(actor_id):
		var reason: StringName = &"hostile_espionage_break" if is_espionage else &"hostile_attack_break"
		forfeit_personal_peace(actor_id, reason)


## Evaluates whether `actor_id` may execute `action` against `target_owner_id`
## (`0` indicates NPC / Yersiz Yurtsuz Çeri or unclaimed steppe node).
func can_perform_action(actor_id: int, action: GameEnums.ToreActionType, target_owner_id: int = 0) -> bool:
	if not _persistent_mode_active:
		return true

	# Day 1+ allowed universally across all stages: scouting, NPC cleanup,
	# unclaimed border node Tuğ planting, refining, and intelligence espionage.
	if action == GameEnums.ToreActionType.SCOUTING \
			or action == GameEnums.ToreActionType.NPC_CLEANUP \
			or action == GameEnums.ToreActionType.UNCLAIMED_NODE_TUG \
			or action == GameEnums.ToreActionType.REFINING:
		return true

	if action == GameEnums.ToreActionType.ESPIONAGE:
		return true

	# Personal 48h protection shields defender from another player's claims & attacks
	if target_owner_id > 0 and target_owner_id != actor_id and has_active_personal_peace(target_owner_id):
		return false

	if _global_stage == GameEnums.TorePeaceStage.STAGE_1_FULL_TORE_PEACE:
		return false

	if _global_stage == GameEnums.TorePeaceStage.STAGE_2_BORDER_SKIRMISH:
		return action == GameEnums.ToreActionType.BORDER_NODE_RAID

	return true


## Executes an allowed action; if `actor_id` holds active personal Töre Peace and
## strikes/raids/claims against another player, forfeits actor's personal peace first.
func validate_and_commit_action(actor_id: int, action: GameEnums.ToreActionType, target_owner_id: int = 0) -> bool:
	if not can_perform_action(actor_id, action, target_owner_id):
		return false
	if target_owner_id > 0 and target_owner_id != actor_id:
		var is_spy: bool = action == GameEnums.ToreActionType.ESPIONAGE
		if is_spy or action == GameEnums.ToreActionType.BORDER_NODE_RAID \
				or action == GameEnums.ToreActionType.CORE_YURT_CLAIM \
				or action == GameEnums.ToreActionType.KURGAN_CONTEST \
				or action == GameEnums.ToreActionType.PLAYER_ATTACK:
			notify_hostile_intent(actor_id, target_owner_id, is_spy)
	return true


## Computes exponential upkeep consumption via `PersistentWorldRules`.
func compute_exponential_consumption(base_amount: float, unit_count: int) -> float:
	if _rules == null:
		return base_amount * (1.0 + 0.002 * pow(float(maxi(unit_count, 0)), 1.25))
	return _rules.compute_exponential_consumption(base_amount, unit_count)


func _handle_step_anti_snowball(command: GameCommand) -> bool:
	var cmd: StepAntiSnowballTickCommand = command as StepAntiSnowballTickCommand
	if cmd == null:
		return command.reject("Expected StepAntiSnowballTickCommand.")
	if _rules == null:
		return command.reject("PersistentWorldRules not loaded.")
	if cmd.player_id <= 0:
		return command.reject("StepAntiSnowballTickCommand requires positive player_id.")

	var days: float = maxf(_safe_float(cmd.days_elapsed, 0.0), 0.0)
	var units: int = maxi(cmd.unit_count, 0)
	var steel_troops: int = maxi(cmd.steel_equipped_troops, 0)

	# 1. Exponential pasture exhaustion multiplier (active even on Day 1)
	var exp_mult: float = _rules.compute_exponential_consumption(1.0, units)
	cmd.exponential_pasture_multiplier = exp_mult
	if cmd.herd_size > 0:
		var graze: GrazePastureCommand = GrazePastureCommand.new(
			cmd.player_id, cmd.pasture_coord, cmd.herd_size, clampf(exp_mult, 1.0, 20.0))
		CommandBus.dispatch(graze)

	# 2. Food spoilage (active from Day 1, anti-hoarding)
	var cur_food: int = SeasonManager.get_food_reserve()
	var spoiled: int = _rules.compute_food_spoilage(cur_food, days)
	if spoiled > 0:
		SeasonManager.apply_food_spoilage(spoiled)
	cmd.food_spoiled = spoiled

	# 3. Steel & Iron military maintenance (`jade` & `meteoric_iron` are preserved!)
	var av_steel: int = ResourceManager.get_amount(cmd.player_id, &"steel")
	var av_iron: int = ResourceManager.get_amount(cmd.player_id, &"iron")
	var steel_cost: int = _rules.compute_steel_maintenance(av_steel, steel_troops, days)
	var iron_cost: int = _rules.compute_iron_maintenance(av_iron, units, days)
	var costs: Array[ResourceAmount] = []
	if steel_cost > 0 and _steel_ore != null:
		var st_amt: ResourceAmount = ResourceAmount.new()
		st_amt.ore = _steel_ore
		st_amt.amount = steel_cost
		costs.append(st_amt)
	if iron_cost > 0 and _iron_ore != null:
		var ir_amt: ResourceAmount = ResourceAmount.new()
		ir_amt.ore = _iron_ore
		ir_amt.amount = iron_cost
		costs.append(ir_amt)
	if not costs.is_empty():
		var spend_cmd: SpendResourcesCommand = SpendResourcesCommand.new(cmd.player_id, costs)
		if CommandBus.dispatch(spend_cmd):
			cmd.steel_upkeep_consumed = steel_cost
			cmd.iron_upkeep_consumed = iron_cost
	else:
		cmd.steel_upkeep_consumed = 0
		cmd.iron_upkeep_consumed = 0

	# 4. Passive Kut stagnation drain when a large Khaganate remains idle past threshold
	if cmd.is_actively_campaigning:
		_player_idle_hours[cmd.player_id] = 0.0
	else:
		_player_idle_hours[cmd.player_id] = _player_idle_hours.get(cmd.player_id, 0.0) + days * 24.0
	var idle_days: float = _player_idle_hours.get(cmd.player_id, 0.0) / 24.0
	cmd.idle_days_accumulated = idle_days
	var kut_drain: float = _rules.compute_idle_kut_stagnation_drain(units, idle_days, days)
	cmd.kut_stagnation_drain = kut_drain
	if kut_drain > 0.0:
		CommandBus.dispatch(ModifyKutCommand.new(-kut_drain, &"idle_empire_stagnation_ulus_unmet"))

	EventBus.anti_snowball_upkeep_applied.emit(
		cmd.player_id,
		cmd.food_spoiled,
		cmd.steel_upkeep_consumed,
		cmd.iron_upkeep_consumed,
		cmd.kut_stagnation_drain,
		cmd.exponential_pasture_multiplier)
	return true


func _compute_spawn_coord(outer_rim: bool, grid_size: Vector2i, slot_seed: int, player_id: int) -> Vector2i:
	var w: int = maxi(grid_size.x, 4)
	var h: int = maxi(grid_size.y, 4)
	var hash_idx: int = absi(player_id * 7 + slot_seed * 13)
	if outer_rim:
		var side: int = hash_idx % 4
		if side == 0:
			return Vector2i(0, hash_idx % h)
		elif side == 1:
			return Vector2i(w - 1, hash_idx % h)
		elif side == 2:
			return Vector2i(hash_idx % w, 0)
		return Vector2i(hash_idx % w, h - 1)
	return Vector2i(clampi(w / 2 + (hash_idx % 3) - 1, 1, w - 2), clampi(h / 2 + ((hash_idx / 3) % 3) - 1, 1, h - 2))
