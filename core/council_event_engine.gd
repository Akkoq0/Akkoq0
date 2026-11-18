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
var _espionage_advantage_count: int = 0
var _assassination_count: int = 0
var _tracked_glory_score: float = 0.0
var _active_coalition_pressure: bool = false


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
	EventBus.espionage_mission_completed.connect(_on_espionage_mission_completed)
	EventBus.envoy_assassinated.connect(_on_envoy_assassinated)
	EventBus.kagan_glory_changed.connect(_on_kagan_glory_changed)
	EventBus.coalition_war_declared.connect(_on_coalition_war_declared)
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


## Evaluates the weight & political concessions of the Ak Sakallılar Konseyi crisis
## given active Coalition Wars, envoy assassination backlash, successful espionage
## forewarning, and the Khagan's battlefield `glory_score`.
func evaluate_council_crisis_severity_with_context(current_kut: float = -1.0, active_coalition_override: bool = false, recent_espionage_override: bool = false, glory_override: float = -1.0) -> Dictionary[StringName, float]:
	var active_kut: float = current_kut if current_kut >= 0.0 else GameManager.get_kut_score()
	var active_glory: float = glory_override if glory_override >= 0.0 else _tracked_glory_score
	var has_coalition: bool = active_coalition_override or _active_coalition_pressure or DiplomacyManager.is_coalition_war_active()
	var has_espionage: bool = recent_espionage_override or _espionage_advantage_count > 0

	var base_kut_deficit: float = clampf((30.0 - active_kut) * 2.2, 0.0, 66.0)
	var coalition_weight: float = 25.0 if has_coalition else 0.0
	var assassination_weight: float = clampf(float(_assassination_count) * 10.0, 0.0, 30.0)
	var espionage_mitigation: float = 15.0 if has_espionage else 0.0
	var glory_mitigation: float = clampf((active_glory - 30.0) * 0.40, 0.0, 22.0)

	var severity_score: float = clampf(
		base_kut_deficit + coalition_weight + assassination_weight - espionage_mitigation - glory_mitigation,
		0.0, 100.0)
	var sacrifice_discount: float = clampf((glory_mitigation + espionage_mitigation) / 100.0, 0.0, 0.35)
	var base_trad_kut: float = _crisis_event.tradition_kut_gain if _crisis_event != null else 15.0
	var effective_trad_kut: float = base_trad_kut * (1.0 + (0.20 if has_espionage else 0.0) + (0.15 if active_glory >= 40.0 else 0.0))

	return {
		&"severity_score": severity_score,
		&"coalition_weight": coalition_weight,
		&"espionage_mitigation": espionage_mitigation,
		&"glory_mitigation": glory_mitigation,
		&"sacrifice_bullion_discount_ratio": sacrifice_discount,
		&"effective_tradition_kut_gain": effective_trad_kut,
	}


func get_espionage_advantage_count() -> int:
	return _espionage_advantage_count


func get_assassination_count() -> int:
	return _assassination_count


func _on_council_convened(_current_kut: float, _legitimacy_penalty: float, _trigger_skirmish: bool) -> void:
	_crisis_dilemma_pending = true


func _on_espionage_mission_completed(report: EspionageReport) -> void:
	if report != null and report.succeeded:
		_espionage_advantage_count += 1


func _on_envoy_assassinated(_instigator_id: int, _target_id: int, _envoy_id: StringName, _kut_gained: float) -> void:
	_assassination_count += 1


func _on_kagan_glory_changed(_army_id: int, _previous_glory: float, new_glory: float, _reason: StringName) -> void:
	_tracked_glory_score = clampf(new_glory, 0.0, 100.0)


func _on_coalition_war_declared(_members: PackedStringArray, _player_kut: float) -> void:
	_active_coalition_pressure = true
