extends Node
## Autoload `KinshipIntrigueManager` (rank 2). Implements Phase 9 **Kinship
## Blood-Ties, Bey Rivalry & Internal Betrayal / Coup Dynamics**
## (`res://core/kinship_intrigue_manager.gd`).
##
## Responsibilities:
##  * Maintains a blood-tie network of clan Beys and kinsmen (`loyalty`,
##    `ambition`, `grievance`).
##  * Escalates neglected or slighted Beys from `LOYAL_CALM` ->
##    `FACTION_PLOT_BREWING` (`faction_plot`) -> `DEFECTION_OR_SABOTAGE`
##    (`defection` + supply line sabotage) or `INTERNAL_UPRISING` (`internal_uprising`).
##  * Allows open-ended resolution via title/Toy bestowal, loyal guard
##    suppression, or kinship negotiation (`ResolveKinshipIntrigueCommand`).

const RULES_PATH: String = "res://data/governance/kinship_intrigue_rules.tres"
const BULLION_ORE_PATH: String = "res://data/ores/silver_gold.tres"

var _rules: KinshipIntrigueRules = null
var _bullion_ore: OreData = null
var _lords: Dictionary[StringName, KinshipLordRecord] = {}


func _ready() -> void:
	_rules = ResourceLoader.load(RULES_PATH) as KinshipIntrigueRules
	if _rules == null:
		push_error("KinshipIntrigueManager: failed to load KinshipIntrigueRules at %s." % RULES_PATH)
	else:
		for err: String in _rules.get_validation_errors():
			push_error("KinshipIntrigueManager: %s" % err)
	_bullion_ore = ResourceLoader.load(BULLION_ORE_PATH) as OreData
	CommandBus.register_handler(StepKinshipIntrigueCommand.ID, _handle_step_intrigue)
	CommandBus.register_handler(ResolveKinshipIntrigueCommand.ID, _handle_resolve_intrigue)


func _exit_tree() -> void:
	CommandBus.unregister_handler(StepKinshipIntrigueCommand.ID, _handle_step_intrigue)
	CommandBus.unregister_handler(ResolveKinshipIntrigueCommand.ID, _handle_resolve_intrigue)


func get_rules() -> KinshipIntrigueRules:
	return _rules


func get_or_create_lord(bey_id: StringName) -> KinshipLordRecord:
	if _lords.has(bey_id):
		return _lords[bey_id]
	var rec: KinshipLordRecord = KinshipLordRecord.new()
	rec.bey_id = bey_id
	if _rules != null:
		rec.loyalty = _rules.default_initial_loyalty
		rec.ambition = _rules.default_initial_ambition
		rec.grievance = _rules.default_initial_grievance
	_lords[bey_id] = rec
	return rec


func get_lord_plot_stage(bey_id: StringName) -> GameEnums.IntriguePlotStage:
	return get_or_create_lord(bey_id).plot_stage


func _handle_step_intrigue(command: GameCommand) -> bool:
	var cmd: StepKinshipIntrigueCommand = command as StepKinshipIntrigueCommand
	if cmd == null:
		return command.reject("Expected StepKinshipIntrigueCommand.")
	if _rules == null or cmd.bey_id == &"":
		return command.reject("StepKinshipIntrigueCommand requires valid rules and non-empty bey_id.")

	var lord: KinshipLordRecord = get_or_create_lord(cmd.bey_id)
	if cmd.ambition_override >= 0.0:
		lord.ambition = clampf(cmd.ambition_override, 0.0, 100.0)

	if cmd.unfair_toy_share:
		lord.grievance = clampf(lord.grievance + _rules.unfair_toy_grievance_gain, 0.0, 100.0)
		lord.loyalty = clampf(lord.loyalty - _rules.unfair_toy_loyalty_drop, 0.0, 100.0)
	if cmd.low_kut_crisis:
		lord.grievance = clampf(lord.grievance + _rules.low_kut_grievance_gain, 0.0, 100.0)
		lord.loyalty = clampf(lord.loyalty - _rules.low_kut_grievance_gain * 0.6, 0.0, 100.0)

	var next_stage: GameEnums.IntriguePlotStage = _rules.classify_plot_stage(lord.loyalty, lord.ambition, lord.grievance)
	lord.plot_stage = next_stage

	if next_stage == GameEnums.IntriguePlotStage.FACTION_PLOT_BREWING:
		EventBus.kinship_plot_escalated.emit(lord.bey_id, next_stage, lord.loyalty, lord.ambition, lord.grievance)
	elif next_stage == GameEnums.IntriguePlotStage.DEFECTION_OR_SABOTAGE:
		lord.defected_troops = _rules.base_defected_troops
		lord.supply_sabotaged = true
		cmd.defected_troops = lord.defected_troops
		cmd.supply_sabotaged = true
		if cmd.target_army_id_for_sabotage > 0:
			CommandBus.dispatch(InterdictSupplyLineCommand.new(cmd.target_army_id_for_sabotage, 1, lord.bey_id))
		EventBus.kinship_plot_escalated.emit(lord.bey_id, next_stage, lord.loyalty, lord.ambition, lord.grievance)
		EventBus.internal_betrayal_triggered.emit(lord.bey_id, next_stage, lord.defected_troops, true, 0.0)
	elif next_stage == GameEnums.IntriguePlotStage.INTERNAL_UPRISING:
		lord.defected_troops = _rules.base_defected_troops * 2
		cmd.defected_troops = lord.defected_troops
		CommandBus.dispatch(ModifyKutCommand.new(-_rules.uprising_kut_drain, &"kinship_internal_uprising"))
		EventBus.kinship_plot_escalated.emit(lord.bey_id, next_stage, lord.loyalty, lord.ambition, lord.grievance)
		EventBus.internal_betrayal_triggered.emit(lord.bey_id, next_stage, lord.defected_troops, false, _rules.uprising_kut_drain)

	cmd.resulting_loyalty = lord.loyalty
	cmd.resulting_grievance = lord.grievance
	cmd.resulting_stage = lord.plot_stage
	return true


func _handle_resolve_intrigue(command: GameCommand) -> bool:
	var cmd: ResolveKinshipIntrigueCommand = command as ResolveKinshipIntrigueCommand
	if cmd == null:
		return command.reject("Expected ResolveKinshipIntrigueCommand.")
	if _rules == null or cmd.bey_id == &"":
		return command.reject("ResolveKinshipIntrigueCommand requires valid rules and non-empty bey_id.")

	var lord: KinshipLordRecord = get_or_create_lord(cmd.bey_id)

	if cmd.action == GameEnums.IntrigueResolutionAction.BESTOW_TITLE_AND_TOY_SHARE:
		if _bullion_ore != null:
			var cost: ResourceAmount = ResourceAmount.new()
			cost.ore = _bullion_ore
			cost.amount = _rules.title_bestowal_bullion_cost
			var spend_list: Array[ResourceAmount] = [cost]
			var spend_cmd: SpendResourcesCommand = SpendResourcesCommand.new(cmd.player_id, spend_list)
			if not CommandBus.dispatch(spend_cmd):
				return command.reject("Insufficient Silver/Gold to bestow title and Ülüş: %s" % spend_cmd.rejection_reason)
		lord.loyalty = clampf(lord.loyalty + _rules.title_bestowal_loyalty_gain, 55.0, 100.0)
		lord.grievance = 10.0
	elif cmd.action == GameEnums.IntrigueResolutionAction.SUPPRESS_WITH_LOYAL_GUARD:
		lord.loyalty = _rules.suppression_loyalty_enforce
		lord.grievance = 15.0
	else:
		lord.loyalty = clampf(lord.loyalty + _rules.negotiation_loyalty_gain, 50.0, 100.0)
		lord.grievance = 20.0

	lord.plot_stage = GameEnums.IntriguePlotStage.LOYAL_CALM
	lord.defected_troops = 0
	lord.supply_sabotaged = false

	cmd.restored_loyalty = lord.loyalty
	cmd.remaining_grievance = lord.grievance
	cmd.resulting_stage = lord.plot_stage

	EventBus.kinship_crisis_resolved.emit(lord.bey_id, cmd.action, lord.loyalty)
	return true
