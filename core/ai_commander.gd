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

var _profile: AIBehaviorProfile = null
var _agent_phases: Dictionary[StringName, GameEnums.AICommanderPhase] = {}
var _agent_stockpiles: Dictionary[StringName, float] = {}
var _agent_forge_upgraded: Dictionary[StringName, bool] = {}
var _agent_raids_launched: Dictionary[StringName, int] = {}


func _ready() -> void:
	_profile = ResourceLoader.load(AI_PROFILE_PATH) as AIBehaviorProfile
	if _profile == null:
		push_error("AICommander: failed to load AIBehaviorProfile at %s." % AI_PROFILE_PATH)
	else:
		for err: String in _profile.get_validation_errors():
			push_error("AICommander: %s" % err)
	CommandBus.register_handler(StepAICommanderCommand.ID, _handle_step_ai)


func _exit_tree() -> void:
	CommandBus.unregister_handler(StepAICommanderCommand.ID, _handle_step_ai)


func get_behavior_profile() -> AIBehaviorProfile:
	return _profile


func get_agent_phase(agent_id: StringName) -> GameEnums.AICommanderPhase:
	return _agent_phases.get(agent_id, GameEnums.AICommanderPhase.GATHER_RESOURCES)


func get_agent_stockpile(agent_id: StringName) -> float:
	return _agent_stockpiles.get(agent_id, 0.0)


func is_agent_forge_upgraded(agent_id: StringName) -> bool:
	return _agent_forge_upgraded.get(agent_id, false)


func get_agent_raids_launched(agent_id: StringName) -> int:
	return _agent_raids_launched.get(agent_id, 0)


## Resolves `(ambition, discipline)` deterministically for a dynasty or rogue warband.
func get_agent_traits(agent_id: StringName, is_rogue_warband: bool) -> Vector2:
	var dyn: DynastyProfile = DiplomacyManager.get_dynasty_profile(agent_id)
	if dyn != null and not is_rogue_warband:
		return Vector2(dyn.ambition, dyn.discipline)
	if _profile != null:
		return Vector2(_profile.rogue_warband_default_ambition, _profile.rogue_warband_default_discipline)
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
		stockpile += _profile.base_gather_rate_per_tick * (1.0 + ambition * 0.50 + discipline * 0.30)
		_agent_stockpiles[step_cmd.agent_id] = stockpile
		if is_agent_forge_upgraded(step_cmd.agent_id):
			if stockpile >= _profile.compute_effective_raid_threshold(ambition, discipline):
				_set_phase(step_cmd.agent_id, GameEnums.AICommanderPhase.LAUNCH_RAID)
		elif stockpile >= _profile.compute_effective_forge_threshold(ambition):
			_set_phase(step_cmd.agent_id, GameEnums.AICommanderPhase.UPGRADE_FORGE)
	elif current_phase == GameEnums.AICommanderPhase.UPGRADE_FORGE:
		_agent_forge_upgraded[step_cmd.agent_id] = true
		stockpile += _profile.base_gather_rate_per_tick * (1.0 + ambition * 0.45 + discipline * 0.55)
		_agent_stockpiles[step_cmd.agent_id] = stockpile
		if stockpile >= _profile.compute_effective_raid_threshold(ambition, discipline):
			_set_phase(step_cmd.agent_id, GameEnums.AICommanderPhase.LAUNCH_RAID)

	var updated_phase: GameEnums.AICommanderPhase = get_agent_phase(step_cmd.agent_id)
	if updated_phase == GameEnums.AICommanderPhase.LAUNCH_RAID:
		if stockpile < RAID_SUPPLY_COST:
			_set_phase(step_cmd.agent_id, GameEnums.AICommanderPhase.GATHER_RESOURCES)
		else:
			stockpile -= RAID_SUPPLY_COST
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
