extends Node
## Autoload `IntelligenceManager` (rank 2). Manages steppe espionage networks,
## intelligence infiltration reports, and inter-dynasty diplomatic stances
## including **Envoy Assassination (`EventBus.envoy_assassinated`)** and the
## resulting **Total War / Great Raid (`TOTAL_WAR_GREAT_RAID`)** escalation.

const DIPLOMACY_RULES_PATH: String = "res://data/diplomacy/diplomacy_rules.tres"
const REASON_ENVOY_ASSASSINATED: StringName = &"envoy_assassinated"
const MAX_CACHED_ARMY_REPORTS: int = 128
const REPORT_STALENESS_SEASONS: int = 8
const TOTAL_WAR_MAX_DURATION_SEASONS: int = 8

var _rules: DiplomacyRules = null
var _army_reports: Dictionary[int, EspionageReport] = {}
var _report_seasons: Dictionary[int, int] = {}
var _stances: Dictionary[StringName, GameEnums.DiplomaticStance] = {}
var _total_war_seasons: Dictionary[StringName, int] = {}
var _assassinated_envoys: Dictionary[StringName, bool] = {}
var _season_tick: int = 0


static func _safe_float(val: float, fallback: float, min_val: float = -INF, max_val: float = INF) -> float:
	if is_nan(val) or is_inf(val):
		return fallback
	return clampf(val, min_val, max_val)


func _ready() -> void:
	_rules = ResourceLoader.load(DIPLOMACY_RULES_PATH) as DiplomacyRules
	if _rules == null:
		push_error("IntelligenceManager: failed to load DiplomacyRules at %s." % DIPLOMACY_RULES_PATH)
	else:
		for error: String in _rules.get_validation_errors():
			push_error("IntelligenceManager: %s" % error)
	EventBus.season_changed.connect(_on_season_changed)
	CommandBus.register_handler(DispatchSpyCommand.ID, _handle_dispatch_spy)
	CommandBus.register_handler(AssassinateEnvoyCommand.ID, _handle_assassinate_envoy)


func _exit_tree() -> void:
	CommandBus.unregister_handler(DispatchSpyCommand.ID, _handle_dispatch_spy)
	CommandBus.unregister_handler(AssassinateEnvoyCommand.ID, _handle_assassinate_envoy)


## Computes the infiltration probability for a commander and terrain.
func evaluate_espionage_chance(commander_leadership: float, terrain: TerrainData, counter_espionage: float = 0.0) -> float:
	if _rules == null:
		return 0.0
	var safe_lead: float = _safe_float(commander_leadership, 0.0, 0.0, 100.0)
	var safe_counter: float = _safe_float(counter_espionage, 0.0, 0.0, 1.0)
	return _rules.calculate_espionage_success_chance(safe_lead, terrain, safe_counter)


## Latest successful intelligence report collected on `target_army_id` (or null).
func get_latest_report_for_army(target_army_id: int) -> EspionageReport:
	return _army_reports.get(target_army_id, null)


## Number of non-expired army espionage reports currently cached.
func get_cached_report_count() -> int:
	return _army_reports.size()


## Diplomatic stance between `faction_a` and `faction_b`.
func get_diplomatic_stance(faction_a: int, faction_b: int) -> GameEnums.DiplomaticStance:
	var key: StringName = _pair_key(faction_a, faction_b)
	return _stances.get(key, GameEnums.DiplomaticStance.TRUCE)


## True when `faction_a` and `faction_b` are locked in Total War (Büyük Yağma).
func is_total_war_active(faction_a: int, faction_b: int) -> bool:
	return get_diplomatic_stance(faction_a, faction_b) == GameEnums.DiplomaticStance.TOTAL_WAR_GREAT_RAID


## Restores a diplomatic truce between `faction_a` and `faction_b` after a war concludes.
func establish_truce(faction_a: int, faction_b: int) -> void:
	if faction_a == faction_b:
		return
	var key: StringName = _pair_key(faction_a, faction_b)
	_stances[key] = GameEnums.DiplomaticStance.TRUCE
	_total_war_seasons.erase(key)


## Advances seasonal war exhaustion and prunes expired spy reports so long campaigns
## do not stay locked in permanent Total War or bloat report caches.
func step_seasonal_intelligence_decay(cycles: int = 1) -> void:
	var step_count: int = maxi(cycles, 1)
	_season_tick += step_count

	var ended_wars: Array[StringName] = []
	for key: StringName in _total_war_seasons:
		var next_dur: int = _total_war_seasons[key] + step_count
		if next_dur >= TOTAL_WAR_MAX_DURATION_SEASONS:
			ended_wars.append(key)
		else:
			_total_war_seasons[key] = next_dur
	for war_key: StringName in ended_wars:
		_total_war_seasons.erase(war_key)
		_stances[war_key] = GameEnums.DiplomaticStance.TRUCE

	var stale_armies: Array[int] = []
	for army_id: int in _report_seasons:
		if _season_tick - _report_seasons[army_id] >= REPORT_STALENESS_SEASONS:
			stale_armies.append(army_id)
	for army_id: int in stale_armies:
		_report_seasons.erase(army_id)
		_army_reports.erase(army_id)


func _on_season_changed(_season: SeasonData, _cycle_index: int) -> void:
	step_seasonal_intelligence_decay(1)


func _handle_dispatch_spy(command: GameCommand) -> bool:
	var spy_cmd: DispatchSpyCommand = command as DispatchSpyCommand
	if spy_cmd == null:
		return command.reject("Expected DispatchSpyCommand.")
	if _rules == null:
		return command.reject("DiplomacyRules not loaded.")
	if spy_cmd.target_army_id <= 0:
		return command.reject("DispatchSpyCommand requires target_army_id > 0.")
	if spy_cmd.spy_owner_id == spy_cmd.target_faction_id:
		return command.reject("Cannot dispatch spy against own faction.")

	var safe_lead: float = _safe_float(spy_cmd.commander_leadership, 0.0, 0.0, 100.0)
	var safe_counter: float = _safe_float(spy_cmd.counter_espionage, 0.0, 0.0, 1.0)
	var safe_ammo: float = _safe_float(spy_cmd.target_quiver_ammo, 0.0, 0.0, 100.0)
	var chance: float = _rules.calculate_espionage_success_chance(safe_lead, spy_cmd.terrain, safe_counter)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = spy_cmd.rng_seed
	var roll: float = rng.randf()

	var report: EspionageReport = EspionageReport.new()
	report.spy_owner_id = spy_cmd.spy_owner_id
	report.target_faction_id = spy_cmd.target_faction_id
	report.target_army_id = spy_cmd.target_army_id
	report.computed_success_chance = chance
	report.succeeded = roll <= chance
	if report.succeeded:
		report.revealed_quiver_ammo = safe_ammo
		report.revealed_tactic_intent = spy_cmd.target_tactic_intent
		report.revealed_doctrine_type = spy_cmd.target_doctrine_type
		if not _army_reports.has(spy_cmd.target_army_id) and _army_reports.size() >= MAX_CACHED_ARMY_REPORTS:
			var oldest_id: int = -1
			var oldest_tick: int = _season_tick + 1
			for cached_id: int in _army_reports:
				var tick: int = _report_seasons.get(cached_id, 0)
				if tick < oldest_tick:
					oldest_tick = tick
					oldest_id = cached_id
			if oldest_id != -1:
				_army_reports.erase(oldest_id)
				_report_seasons.erase(oldest_id)
		_army_reports[spy_cmd.target_army_id] = report
		_report_seasons[spy_cmd.target_army_id] = _season_tick
	else:
		report.spy_captured = true

	if spy_cmd.target_faction_id > 0 and spy_cmd.spy_owner_id > 0 and spy_cmd.spy_owner_id != spy_cmd.target_faction_id:
		GracePeriodManager.notify_hostile_intent(spy_cmd.spy_owner_id, spy_cmd.target_faction_id, true)

	spy_cmd.report = report
	EventBus.espionage_mission_completed.emit(report)
	return true


func _handle_assassinate_envoy(command: GameCommand) -> bool:
	var assassinate: AssassinateEnvoyCommand = command as AssassinateEnvoyCommand
	if assassinate == null:
		return command.reject("Expected AssassinateEnvoyCommand.")
	if _rules == null:
		return command.reject("DiplomacyRules not loaded.")
	if assassinate.envoy_id == &"":
		return command.reject("AssassinateEnvoyCommand requires a non-empty envoy_id.")
	if assassinate.instigator_faction_id == assassinate.target_faction_id:
		return command.reject("Cannot assassinate own faction's envoy.")
	if is_total_war_active(assassinate.instigator_faction_id, assassinate.target_faction_id):
		return command.reject("Factions are already in Total War (Büyük Yağma); no active envoy to assassinate.")
	if _assassinated_envoys.has(assassinate.envoy_id):
		return command.reject("Envoy '%s' has already been assassinated." % assassinate.envoy_id)

	var key: StringName = _pair_key(assassinate.instigator_faction_id, assassinate.target_faction_id)
	_stances[key] = GameEnums.DiplomaticStance.TOTAL_WAR_GREAT_RAID
	_total_war_seasons[key] = 0
	_assassinated_envoys[assassinate.envoy_id] = true

	var kut_cmd: ModifyKutCommand = ModifyKutCommand.new(_rules.envoy_assassination_kut_gain, REASON_ENVOY_ASSASSINATED)
	CommandBus.dispatch(kut_cmd)

	assassinate.kut_gained = _rules.envoy_assassination_kut_gain
	assassinate.resulting_kut = kut_cmd.resulting_kut
	assassinate.new_stance = GameEnums.DiplomaticStance.TOTAL_WAR_GREAT_RAID
	assassinate.total_war_triggered = true

	EventBus.envoy_assassinated.emit(
		assassinate.instigator_faction_id,
		assassinate.target_faction_id,
		assassinate.envoy_id,
		assassinate.kut_gained)
	EventBus.total_war_declared.emit(
		assassinate.instigator_faction_id,
		assassinate.target_faction_id,
		GameEnums.DiplomaticStance.TOTAL_WAR_GREAT_RAID)
	return true


func _pair_key(faction_a: int, faction_b: int) -> StringName:
	var low: int = mini(faction_a, faction_b)
	var high: int = maxi(faction_a, faction_b)
	return StringName("%d_%d" % [low, high])
