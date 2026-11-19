extends Node
## Autoload `AICommander` (rank 2). Executes the Phase 6 deterministic
## **AI Commander & Steppe Raider AI** behavior loop for rival dynasties and
## roaming `rogue_warbands` (`Yersiz Yurtsuz Çeriler`):
##   `1. GATHER_RESOURCES -> 2. UPGRADE_FORGE -> 3. LAUNCH_RAID`
##
## Decisions are computed deterministically from each dynasty's `ambition` and
## `discipline` ratios (`DynastyProfile`) and `AIBehaviorProfile`.

const AI_PROFILE_PATH: String = "res://data/ai/ai_behavior_profile.tres"
const RAID_SUPPLY_COST: float = 60.0
const MAX_AGENT_STOCKPILE: float = 5000.0

var _profile: AIBehaviorProfile = null
var _agent_phases: Dictionary[StringName, GameEnums.AICommanderPhase] = {}
var _agent_stockpiles: Dictionary[StringName, float] = {}
var _agent_forge_upgraded: Dictionary[StringName, bool] = {}
var _agent_raids_launched: Dictionary[StringName, int] = {}


static func _safe_float(val: float, fallback: float, min_val: float = 0.0, max_val: float = MAX_AGENT_STOCKPILE) -> float:
	if is_nan(val) or is_inf(val):
		return fallback
	return clampf(val, min_val, max_val)


func _ready() -> void:
	_profile = ResourceLoader.load(AI_PROFILE_PATH) as AIBehaviorProfile
	if _profile == null:
		push_error("AICommander: failed to load AIBehaviorProfile at %s." % AI_PROFILE_PATH)
	else:
		for err: String in _profile.get_validation_errors():
			push_error("AICommander: %s" % err)
	CommandBus.register_handler(StepAICommanderCommand.ID, _handle_step_ai)
	EventBus.doctrine_matchup_evaluated.connect(_on_doctrine_matchup_evaluated)
	EventBus.espionage_mission_completed.connect(_on_espionage_mission_completed)
	EventBus.courier_ambushed_plan_exposed.connect(_on_courier_ambushed_plan_exposed)
	EventBus.water_source_sabotaged.connect(_on_water_source_sabotaged)
	EventBus.zud_starvation_ticked.connect(_on_zud_starvation_ticked)
	EventBus.amanat_pact_broken.connect(_on_amanat_pact_broken)
	EventBus.commander_fallen_in_battle.connect(_on_commander_fallen_in_battle)


func _exit_tree() -> void:
	CommandBus.unregister_handler(StepAICommanderCommand.ID, _handle_step_ai)
	if EventBus.doctrine_matchup_evaluated.is_connected(_on_doctrine_matchup_evaluated):
		EventBus.doctrine_matchup_evaluated.disconnect(_on_doctrine_matchup_evaluated)
	if EventBus.espionage_mission_completed.is_connected(_on_espionage_mission_completed):
		EventBus.espionage_mission_completed.disconnect(_on_espionage_mission_completed)
	if EventBus.courier_ambushed_plan_exposed.is_connected(_on_courier_ambushed_plan_exposed):
		EventBus.courier_ambushed_plan_exposed.disconnect(_on_courier_ambushed_plan_exposed)
	if EventBus.water_source_sabotaged.is_connected(_on_water_source_sabotaged):
		EventBus.water_source_sabotaged.disconnect(_on_water_source_sabotaged)
	if EventBus.zud_starvation_ticked.is_connected(_on_zud_starvation_ticked):
		EventBus.zud_starvation_ticked.disconnect(_on_zud_starvation_ticked)
	if EventBus.amanat_pact_broken.is_connected(_on_amanat_pact_broken):
		EventBus.amanat_pact_broken.disconnect(_on_amanat_pact_broken)
	if EventBus.commander_fallen_in_battle.is_connected(_on_commander_fallen_in_battle):
		EventBus.commander_fallen_in_battle.disconnect(_on_commander_fallen_in_battle)


func get_behavior_profile() -> AIBehaviorProfile:
	return _profile


func get_agent_phase(agent_id: StringName) -> GameEnums.AICommanderPhase:
	return _agent_phases.get(agent_id, GameEnums.AICommanderPhase.GATHER_RESOURCES)


func get_agent_stockpile(agent_id: StringName) -> float:
	var raw: float = _agent_stockpiles[agent_id] if _agent_stockpiles.has(agent_id) else 0.0
	return clampf(_safe_float(raw, 0.0), 0.0, MAX_AGENT_STOCKPILE)


func is_agent_forge_upgraded(agent_id: StringName) -> bool:
	return _agent_forge_upgraded.get(agent_id, false)


func get_agent_raids_launched(agent_id: StringName) -> int:
	return _agent_raids_launched.get(agent_id, 0)


## Resolves `(ambition, discipline)` deterministically for a dynasty or rogue warband.
func get_agent_traits(agent_id: StringName, is_rogue_warband: bool) -> Vector2:
	var dyn: DynastyProfile = DiplomacyManager.get_dynasty_profile(agent_id)
	if dyn != null and not is_rogue_warband:
		return Vector2(_safe_float(dyn.ambition, 0.65, 0.0, 1.0), _safe_float(dyn.discipline, 0.70, 0.0, 1.0))
	if _profile != null:
		return Vector2(
			_safe_float(_profile.rogue_warband_default_ambition, 0.85, 0.0, 1.0),
			_safe_float(_profile.rogue_warband_default_discipline, 0.60, 0.0, 1.0))
	return Vector2(0.85, 0.60)


func _handle_step_ai(command: GameCommand) -> bool:
	var step_cmd: StepAICommanderCommand = command as StepAICommanderCommand
	if step_cmd == null:
		return command.reject("Expected StepAICommanderCommand.")
	if _profile == null:
		return command.reject("AIBehaviorProfile not loaded.")
	if step_cmd.agent_id == &"":
		return command.reject("StepAICommanderCommand requires non-empty agent_id.")

	var traits: Vector2 = get_agent_traits(step_cmd.agent_id, step_cmd.is_rogue_warband)
	var ambition: float = traits.x
	var discipline: float = traits.y

	var current_phase: GameEnums.AICommanderPhase = get_agent_phase(step_cmd.agent_id)
	step_cmd.previous_phase = current_phase
	var stockpile: float = get_agent_stockpile(step_cmd.agent_id)

	if current_phase == GameEnums.AICommanderPhase.GATHER_RESOURCES:
		stockpile = clampf(stockpile + _profile.base_gather_rate_per_tick * (1.0 + ambition * 0.50 + discipline * 0.30), 0.0, MAX_AGENT_STOCKPILE)
		_agent_stockpiles[step_cmd.agent_id] = stockpile
		if is_agent_forge_upgraded(step_cmd.agent_id):
			if stockpile >= _profile.compute_effective_raid_threshold(ambition, discipline):
				_set_phase(step_cmd.agent_id, GameEnums.AICommanderPhase.LAUNCH_RAID)
		elif stockpile >= _profile.compute_effective_forge_threshold(ambition):
			_set_phase(step_cmd.agent_id, GameEnums.AICommanderPhase.UPGRADE_FORGE)
	elif current_phase == GameEnums.AICommanderPhase.UPGRADE_FORGE:
		_agent_forge_upgraded[step_cmd.agent_id] = true
		stockpile = clampf(stockpile + _profile.base_gather_rate_per_tick * (1.0 + ambition * 0.45 + discipline * 0.55), 0.0, MAX_AGENT_STOCKPILE)
		_agent_stockpiles[step_cmd.agent_id] = stockpile
		if stockpile >= _profile.compute_effective_raid_threshold(ambition, discipline):
			_set_phase(step_cmd.agent_id, GameEnums.AICommanderPhase.LAUNCH_RAID)

	var updated_phase: GameEnums.AICommanderPhase = get_agent_phase(step_cmd.agent_id)
	if updated_phase == GameEnums.AICommanderPhase.LAUNCH_RAID:
		if stockpile < RAID_SUPPLY_COST:
			_set_phase(step_cmd.agent_id, GameEnums.AICommanderPhase.GATHER_RESOURCES)
		else:
			stockpile = clampf(stockpile - RAID_SUPPLY_COST, 0.0, MAX_AGENT_STOCKPILE)
			_agent_stockpiles[step_cmd.agent_id] = stockpile
			var turan_phase: GameEnums.TuranTacticPhase = _profile.select_deterministic_turan_phase(ambition, discipline)
			var target_type: StringName = _profile.select_deterministic_raid_target(ambition, discipline)
			if step_cmd.is_rogue_warband:
				target_type = &"supply_line"
			if target_type == &"supply_line" and step_cmd.target_player_army_id > 0:
				CommandBus.dispatch(InterdictSupplyLineCommand.new(
					step_cmd.target_player_army_id, step_cmd.target_depot_id, step_cmd.agent_id))
			_agent_raids_launched[step_cmd.agent_id] = get_agent_raids_launched(step_cmd.agent_id) + 1
			step_cmd.raid_launched = true
			step_cmd.chosen_turan_phase = turan_phase
			step_cmd.raid_target_type = target_type
			EventBus.ai_raid_launched.emit(
				step_cmd.agent_id,
				step_cmd.is_rogue_warband,
				target_type,
				step_cmd.target_player_army_id,
				turan_phase,
				ambition,
				discipline)
			if stockpile < RAID_SUPPLY_COST:
				_set_phase(step_cmd.agent_id, GameEnums.AICommanderPhase.GATHER_RESOURCES)

	step_cmd.new_phase = get_agent_phase(step_cmd.agent_id)
	return true


func _set_phase(agent_id: StringName, next_phase: GameEnums.AICommanderPhase) -> void:
	var prev: GameEnums.AICommanderPhase = get_agent_phase(agent_id)
	_agent_phases[agent_id] = next_phase
	if prev != next_phase:
		EventBus.ai_commander_phase_changed.emit(agent_id, prev, next_phase)


func _on_doctrine_matchup_evaluated(attacker_id: int, defender_id: int, result: DoctrineMatchupResult) -> void:
	SteppeStrategicAIController.notify_doctrine_matchup(attacker_id, attacker_id, defender_id, defender_id, result)


func _on_espionage_mission_completed(report: EspionageReport) -> void:
	SteppeStrategicAIController.notify_espionage_report(report)


func _on_courier_ambushed_plan_exposed(_order_id: StringName, victim_player_id: int, ambusher_id: int, leaked_plan: GameEnums.TuranTacticPhase) -> void:
	SteppeStrategicAIController.notify_courier_ambushed(victim_player_id, ambusher_id, leaked_plan)


func _on_water_source_sabotaged(region_coord: Vector2i, _source_id: StringName, saboteur_id: int, _duration_seasons: int) -> void:
	SteppeStrategicAIController.notify_water_sabotaged(region_coord, saboteur_id)


func _on_zud_starvation_ticked(food_remaining: int, _season: SeasonData) -> void:
	SteppeStrategicAIController.notify_zud_starvation(food_remaining)


func _on_amanat_pact_broken(pact_id: StringName, betrayer_id: int, _hostage_forfeited: bool, _reliability_after: float) -> void:
	var pact: AmanatPactRecord = ReputationAndPactSystem.get_pact(pact_id)
	var pa: int = pact.party_a if pact != null else 0
	var pb: int = pact.party_b if pact != null else 0
	SteppeStrategicAIController.notify_amanat_pact_broken(pact_id, betrayer_id, pa, pb)


func _on_commander_fallen_in_battle(_commander_id: int, _army_id: int, player_id: int, _morale_shock: float, _cohesion_shock: float) -> void:
	SteppeStrategicAIController.notify_commander_fallen(player_id, 0)
