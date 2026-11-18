extends Node
## Autoload `CouncilEventEngine` (rank 2). Executes the Phase 5 **Ak Sakallılar
## Konseyi & Crisis Decision Matrix** when Kut drops below `< 30`, processing
## the 3 strategic dilemmas (`TRADITION`, `EXPANSION`, `SACRIFICE`) via
## `CommandBus` and broadcasting `EventBus.council_decree_enacted`.

const CRISIS_EVENT_PATH: String = "res://data/governance/council_crisis_event.tres"
const STEEL_ORE_PATH: String = "res://data/ores/steel.tres"
const SILVER_GOLD_ORE_PATH: String = "res://data/ores/silver_gold.tres"

const REASON_COUNCIL_TRADITION: StringName = &"council_decree_tradition"
const REASON_COUNCIL_SACRIFICE: StringName = &"council_decree_sacrifice"

var _crisis_event: CouncilCrisisEvent = null
var _steel_ore: OreData = null
var _silver_gold_ore: OreData = null

var _crisis_dilemma_pending: bool = false
var _last_choice: GameEnums.CouncilDilemmaChoice = GameEnums.CouncilDilemmaChoice.TRADITION
var _active_income_multiplier: float = 1.0
var _active_speed_multiplier: float = 1.0
var _active_morale_bonus: float = 0.0
var _active_loot_multiplier: float = 1.0
var _popular_loyalty_bonus: float = 0.0


func _ready() -> void:
	_crisis_event = ResourceLoader.load(CRISIS_EVENT_PATH) as CouncilCrisisEvent
	if _crisis_event == null:
		push_error("CouncilEventEngine: failed to load CouncilCrisisEvent at %s." % CRISIS_EVENT_PATH)
	else:
		for err: String in _crisis_event.get_validation_errors():
			push_error("CouncilEventEngine: %s" % err)
	_steel_ore = ResourceLoader.load(STEEL_ORE_PATH) as OreData
	_silver_gold_ore = ResourceLoader.load(SILVER_GOLD_ORE_PATH) as OreData
	EventBus.ak_sakallilar_council_convened.connect(_on_council_convened)
	CommandBus.register_handler(EnactCouncilDecreeCommand.ID, _handle_enact_decree)


func _exit_tree() -> void:
	CommandBus.unregister_handler(EnactCouncilDecreeCommand.ID, _handle_enact_decree)


func get_crisis_event() -> CouncilCrisisEvent:
	return _crisis_event


func is_crisis_dilemma_pending() -> bool:
	return _crisis_dilemma_pending


func get_active_income_multiplier() -> float:
	return _active_income_multiplier


func get_active_speed_multiplier() -> float:
	return _active_speed_multiplier


func get_active_morale_bonus() -> float:
	return _active_morale_bonus


func get_active_loot_multiplier() -> float:
	return _active_loot_multiplier


func get_popular_loyalty_bonus() -> float:
	return _popular_loyalty_bonus


func _handle_enact_decree(command: GameCommand) -> bool:
	var decree: EnactCouncilDecreeCommand = command as EnactCouncilDecreeCommand
	if decree == null:
		return command.reject("Expected EnactCouncilDecreeCommand.")
	if _crisis_event == null:
		return command.reject("CouncilCrisisEvent data is not loaded.")

	if decree.choice == GameEnums.CouncilDilemmaChoice.TRADITION:
		# 1. Töreye Bağlılık: +Kut, -Economic Income, -Army Speed
		var kut_cmd: ModifyKutCommand = ModifyKutCommand.new(_crisis_event.tradition_kut_gain, REASON_COUNCIL_TRADITION)
		CommandBus.dispatch(kut_cmd)
		_active_income_multiplier = _crisis_event.tradition_income_multiplier
		_active_speed_multiplier = _crisis_event.tradition_speed_multiplier
		decree.kut_delta_applied = _crisis_event.tradition_kut_gain
	elif decree.choice == GameEnums.CouncilDilemmaChoice.EXPANSION:
		# 2. Yağma ve Sefer Serbestisi: +Military Morale, +Loot, -Dynasty Diplomacy Trust
		_active_morale_bonus = _crisis_event.expansion_morale_bonus
		_active_loot_multiplier = _crisis_event.expansion_loot_multiplier
		decree.morale_bonus = _active_morale_bonus
		decree.loot_multiplier = _active_loot_multiplier
		decree.diplomacy_trust_delta = _crisis_event.expansion_diplomacy_trust_penalty
		DiplomacyManager.modify_all_dynasty_trust(_crisis_event.expansion_diplomacy_trust_penalty)
	elif decree.choice == GameEnums.CouncilDilemmaChoice.SACRIFICE:
		# 3. Hazine Fedakarlığı: Spend Steel + Silver/Gold treasury to buy popular loyalty & Kut
		if _steel_ore == null or _silver_gold_ore == null:
			return command.reject("Treasury ores (Steel / Silver-Gold) not loaded.")
		var steel_cost: ResourceAmount = ResourceAmount.new()
		steel_cost.ore = _steel_ore
		steel_cost.amount = _crisis_event.sacrifice_steel_cost
		var bullion_cost: ResourceAmount = ResourceAmount.new()
		bullion_cost.ore = _silver_gold_ore
		bullion_cost.amount = _crisis_event.sacrifice_silver_gold_cost
		var costs: Array[ResourceAmount] = [steel_cost, bullion_cost]
		var spend_cmd: SpendResourcesCommand = SpendResourcesCommand.new(decree.player_id, costs)
		if not CommandBus.dispatch(spend_cmd):
			return command.reject("Insufficient Steel or Silver/Gold for Hazine Fedakarlığı: %s" % spend_cmd.rejection_reason)
		var kut_sac_cmd: ModifyKutCommand = ModifyKutCommand.new(_crisis_event.sacrifice_kut_gain, REASON_COUNCIL_SACRIFICE)
		CommandBus.dispatch(kut_sac_cmd)
		_popular_loyalty_bonus += _crisis_event.sacrifice_popular_loyalty_bonus
		decree.kut_delta_applied = _crisis_event.sacrifice_kut_gain
		decree.popular_loyalty_bonus = _popular_loyalty_bonus

	_last_choice = decree.choice
	_crisis_dilemma_pending = GameManager.is_ak_sakallilar_council_active()
	decree.resulting_kut = GameManager.get_kut_score()
	decree.income_multiplier = _active_income_multiplier
	decree.speed_multiplier = _active_speed_multiplier
	decree.morale_bonus = _active_morale_bonus
	decree.loot_multiplier = _active_loot_multiplier

	EventBus.council_decree_enacted.emit(
		decree.player_id,
		decree.choice,
		decree.resulting_kut,
		_active_income_multiplier,
		_active_speed_multiplier,
		_active_loot_multiplier)
	return true


func _on_council_convened(_current_kut: float, _legitimacy_penalty: float, _trigger_skirmish: bool) -> void:
	_crisis_dilemma_pending = true
