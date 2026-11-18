extends Node
## Autoload `CaptiveLaborManager` (rank 2). Implements Phase 7 **Töre Law &
## Captive Labor Integration** (`res://core/captive_labor_manager.gd`).
##
## Responsibilities:
##  * **Nobles & Beys (`ProcessNobleCaptivesCommand`):** Ransomed into
##    `silver_gold` bullion (`DepositResourcesCommand`) or exchanged for
##    diplomatic envoys (`envoy_exchange`).
##  * **Common Soldiers & Captives (`AssignCaptiveLaborCommand`):** Added to
##    the settlement's Quarry and `NomadicForge` slave labor pool
##    (`captured_slave_workers`), reducing `construction_time` and raw material
##    production costs by up to **30%** (`0.70x` multiplier).
##  * **Slave Revolt Risk (`slave_revolt_risk`):** When `captured_slave_workers`
##    exceeds the settlement's `core_clan_population`, triggers a revolt risk
##    and emits `EventBus.slave_revolt_triggered`.

const CAPTIVE_RULES_PATH: String = "res://data/governance/captive_labor_rules.tres"
const BULLION_ORE_ID: StringName = &"silver_gold"

var _rules: CaptiveLaborRules = null
var _slave_workers_by_player: Dictionary[int, int] = {}
var _clan_population_by_player: Dictionary[int, int] = {}
var _envoy_exchange_credits: Dictionary[int, float] = {}
var _revolt_active_by_player: Dictionary[int, bool] = {}


func _ready() -> void:
	_rules = ResourceLoader.load(CAPTIVE_RULES_PATH) as CaptiveLaborRules
	if _rules == null:
		push_error("CaptiveLaborManager: failed to load CaptiveLaborRules at %s." % CAPTIVE_RULES_PATH)
	else:
		for err: String in _rules.get_validation_errors():
			push_error("CaptiveLaborManager: %s" % err)
	EventBus.routed_troops_enslaved_to_toy.connect(_on_routed_troops_enslaved)
	CommandBus.register_handler(ProcessNobleCaptivesCommand.ID, _handle_process_nobles)
	CommandBus.register_handler(AssignCaptiveLaborCommand.ID, _handle_assign_labor)


func _exit_tree() -> void:
	CommandBus.unregister_handler(ProcessNobleCaptivesCommand.ID, _handle_process_nobles)
	CommandBus.unregister_handler(AssignCaptiveLaborCommand.ID, _handle_assign_labor)


func get_rules() -> CaptiveLaborRules:
	return _rules


func get_captured_slave_workers(player_id: int) -> int:
	return _slave_workers_by_player.get(player_id, 0)


func get_core_clan_population(player_id: int) -> int:
	var default_pop: int = _rules.default_core_clan_population if _rules != null else 120
	return _clan_population_by_player.get(player_id, default_pop)


func get_envoy_exchange_credits(player_id: int) -> float:
	return _envoy_exchange_credits.get(player_id, 0.0)


func is_slave_revolt_active(player_id: int) -> bool:
	return _revolt_active_by_player.get(player_id, false)


## Returns the construction time multiplier (`1.0` down to `0.70` = 30% reduction).
func get_construction_time_multiplier(player_id: int) -> float:
	if _rules == null:
		return 1.0
	return 1.0 - _rules.compute_labor_discount_ratio(get_captured_slave_workers(player_id))


## Returns the raw material production cost multiplier (`1.0` down to `0.70` = 30% reduction).
func get_production_cost_multiplier(player_id: int) -> float:
	if _rules == null:
		return 1.0
	return 1.0 - _rules.compute_labor_discount_ratio(get_captured_slave_workers(player_id))


## Returns the current `slave_revolt_risk` (`0.0 .. 1.0`). Positive when captives exceed clan population.
func get_slave_revolt_risk(player_id: int) -> float:
	if _rules == null:
		return 0.0
	return _rules.compute_slave_revolt_risk(get_captured_slave_workers(player_id), get_core_clan_population(player_id))


## Voluntarily emancipates or releases `count` captive workers to restore Töre balance
## and defuse active slave revolt risk. Returns remaining captive workers.
func release_or_emancipate_captives(player_id: int, count: int) -> int:
	var current: int = get_captured_slave_workers(player_id)
	var updated: int = maxi(current - maxi(count, 0), 0)
	_slave_workers_by_player[player_id] = updated
	var clan_pop: int = get_core_clan_population(player_id)
	if updated <= clan_pop:
		_revolt_active_by_player[player_id] = false
	return updated


## Applies seasonal captive manumission / attrition so captive labor pools do not accumulate unboundedly.
func step_captive_labor_season(player_id: int) -> int:
	var current: int = get_captured_slave_workers(player_id)
	if current <= 0:
		_revolt_active_by_player[player_id] = false
		return 0
	var clan_pop: int = get_core_clan_population(player_id)
	var attrition: int = maxi(current / 12, 1) if current > clan_pop else maxi(current / 20, 0)
	return release_or_emancipate_captives(player_id, attrition)


func _handle_process_nobles(command: GameCommand) -> bool:
	var cmd: ProcessNobleCaptivesCommand = command as ProcessNobleCaptivesCommand
	if cmd == null:
		return command.reject("Expected ProcessNobleCaptivesCommand.")
	if _rules == null or cmd.noble_count <= 0:
		return command.reject("ProcessNobleCaptivesCommand requires noble_count > 0 and loaded rules.")

	if cmd.mode == ProcessNobleCaptivesCommand.MODE_RANSOM:
		var bullion: int = cmd.noble_count * _rules.bullion_ransom_per_noble
		CommandBus.dispatch(DepositResourcesCommand.new(cmd.player_id, BULLION_ORE_ID, bullion))
		cmd.bullion_gained = bullion
		cmd.diplomatic_trust_gained = 0.0
	elif cmd.mode == ProcessNobleCaptivesCommand.MODE_ENVOY_EXCHANGE:
		var trust: float = float(cmd.noble_count) * _rules.trust_gain_per_exchanged_noble
		_envoy_exchange_credits[cmd.player_id] = get_envoy_exchange_credits(cmd.player_id) + trust
		cmd.bullion_gained = 0
		cmd.diplomatic_trust_gained = trust
	else:
		return command.reject("Unknown noble captive processing mode '%s'." % cmd.mode)

	EventBus.noble_captives_ransomed_or_exchanged.emit(
		cmd.player_id, cmd.noble_count, cmd.mode, cmd.bullion_gained, cmd.diplomatic_trust_gained)
	return true


func _handle_assign_labor(command: GameCommand) -> bool:
	var cmd: AssignCaptiveLaborCommand = command as AssignCaptiveLaborCommand
	if cmd == null:
		return command.reject("Expected AssignCaptiveLaborCommand.")
	if _rules == null:
		return command.reject("CaptiveLaborRules not loaded.")

	if cmd.core_clan_population > 0:
		_clan_population_by_player[cmd.player_id] = cmd.core_clan_population

	var clan_pop: int = get_core_clan_population(cmd.player_id)
	var max_camp_captives: int = maxi(clan_pop * 4, 480)
	var updated_workers: int = clampi(get_captured_slave_workers(cmd.player_id) + cmd.added_slave_workers, 0, max_camp_captives)
	_slave_workers_by_player[cmd.player_id] = updated_workers

	var discount: float = _rules.compute_labor_discount_ratio(updated_workers)
	var risk: float = _rules.compute_slave_revolt_risk(updated_workers, clan_pop)

	if risk > 0.0:
		var was_revolt_active: bool = is_slave_revolt_active(cmd.player_id)
		var excess: int = updated_workers - clan_pop
		if not was_revolt_active:
			_revolt_active_by_player[cmd.player_id] = true
			cmd.revolt_triggered = true
			CommandBus.dispatch(ModifyKutCommand.new(-_rules.slave_revolt_kut_penalty, &"slave_revolt"))
			EventBus.slave_revolt_triggered.emit(cmd.player_id, updated_workers, clan_pop, risk)
			if excess > 1:
				var escaped: int = mini(excess - 1, maxi(excess / 3, 1))
				updated_workers -= escaped
				_slave_workers_by_player[cmd.player_id] = updated_workers
				discount = _rules.compute_labor_discount_ratio(updated_workers)
				risk = _rules.compute_slave_revolt_risk(updated_workers, clan_pop)
		elif cmd.added_slave_workers > 0 and excess > 1:
			var overflow_escaped: int = mini(excess - 1, maxi(cmd.added_slave_workers / 2, 1))
			updated_workers -= overflow_escaped
			_slave_workers_by_player[cmd.player_id] = updated_workers
			discount = _rules.compute_labor_discount_ratio(updated_workers)
			risk = _rules.compute_slave_revolt_risk(updated_workers, clan_pop)
	else:
		_revolt_active_by_player[cmd.player_id] = false

	cmd.total_slave_workers = updated_workers
	cmd.discount_ratio = discount
	cmd.construction_time_multiplier = 1.0 - discount
	cmd.production_cost_multiplier = 1.0 - discount
	cmd.slave_revolt_risk = risk

	EventBus.captive_labor_assigned.emit(cmd.player_id, updated_workers, clan_pop, discount, discount)
	return true


func _on_routed_troops_enslaved(_routed_army_id: int, captured_slave_workers: int, _added_toy_loot_value: float) -> void:
	if captured_slave_workers <= 0:
		return
	var clan_pop: int = get_core_clan_population(1)
	var max_camp_captives: int = maxi(clan_pop * 4, 480)
	var current: int = get_captured_slave_workers(1)
	_slave_workers_by_player[1] = clampi(current + captured_slave_workers, 0, max_camp_captives)
