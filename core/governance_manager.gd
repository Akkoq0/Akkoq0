extends Node
## Autoload `GovernanceManager` (rank 2). Implements Phase 22 **Direct Governance
## Cap (`Yönetişim Sınırı`), Named Vassal Bey Traits (`AMBITIOUS`, `LOYAL`,
## `CAUTIOUS`, `GREEDY`), and Ülüş-Contract Silent Sabotage (delayed / reduced
## army reinforcements when promised loot or shares fall short)**.

const RULES_PATH: String = "res://data/governance/politics_and_pacts_rules.tres"
const REASON_OVEREXTENSION: StringName = &"governance_overextension"

var _rules: PoliticsAndPactsRules = null
var _delegated_by_coord: Dictionary[Vector2i, StringName] = {}
var _vassals: Dictionary[StringName, VassalBeyAssignment] = {}
var _direct_tax_efficiency: Dictionary[int, float] = {}


func _ready() -> void:
	_rules = ResourceLoader.load(RULES_PATH) as PoliticsAndPactsRules
	if _rules == null:
		push_error("GovernanceManager: failed to load PoliticsAndPactsRules at %s." % RULES_PATH)
	else:
		for err: String in _rules.get_validation_errors():
			push_error("GovernanceManager: %s" % err)
	CommandBus.register_handler(DelegateRegionToVassalCommand.ID, _handle_delegate_region)
	CommandBus.register_handler(SignUlusContractCommand.ID, _handle_sign_ulus_contract)


func _exit_tree() -> void:
	CommandBus.unregister_handler(DelegateRegionToVassalCommand.ID, _handle_delegate_region)
	CommandBus.unregister_handler(SignUlusContractCommand.ID, _handle_sign_ulus_contract)


func reset_governance_state() -> void:
	_delegated_by_coord.clear()
	_vassals.clear()
	_direct_tax_efficiency.clear()


func get_rules() -> PoliticsAndPactsRules:
	return _rules


func get_direct_cap(_player_id: int = 1) -> int:
	return _rules.direct_governance_cap if _rules != null else 3


func get_delegated_region_count(player_id: int) -> int:
	var count: int = 0
	for bey_id: StringName in _vassals:
		var assignment: VassalBeyAssignment = _vassals[bey_id]
		if assignment.suzerain_id == player_id:
			count += 1
	return count


func get_direct_region_count(player_id: int) -> int:
	if player_id <= 0:
		return 0
	var owned_coords: Array[Vector2i] = TerritoryManager.get_owned_region_coords(player_id)
	var direct: int = 0
	for coord: Vector2i in owned_coords:
		if not _delegated_by_coord.has(coord):
			direct += 1
			continue
		var mapped_bey: StringName = _delegated_by_coord[coord]
		if not _vassals.has(mapped_bey) or _vassals[mapped_bey].suzerain_id != player_id:
			direct += 1
	return direct


func is_region_delegated(coord: Vector2i) -> bool:
	return _delegated_by_coord.has(coord)


func get_vassal(bey_id: StringName) -> VassalBeyAssignment:
	if _vassals.has(bey_id):
		return _vassals[bey_id]
	return null


func get_vassals_for_suzerain(player_id: int) -> Array[VassalBeyAssignment]:
	var list: Array[VassalBeyAssignment] = []
	for bey_id: StringName in _vassals:
		var assignment: VassalBeyAssignment = _vassals[bey_id]
		if assignment.suzerain_id == player_id:
			list.append(assignment)
	return list


func get_direct_tax_efficiency(player_id: int) -> float:
	if _direct_tax_efficiency.has(player_id):
		return _direct_tax_efficiency[player_id]
	return 1.0


func get_vassal_reinforcement_delay_hours(bey_id: StringName) -> float:
	if _vassals.has(bey_id):
		return _vassals[bey_id].reinforcement_delay_hours
	return 0.0


func get_vassal_reinforcement_troop_multiplier(bey_id: StringName) -> float:
	if _vassals.has(bey_id):
		return _vassals[bey_id].reinforcement_troop_mult
	return 1.0


## Computes average effective reinforcement readiness multiplier across all
## delegated vassals belonging to `suzerain_id`.
func get_player_vassal_reinforcement_multiplier(suzerain_id: int) -> float:
	var list: Array[VassalBeyAssignment] = get_vassals_for_suzerain(suzerain_id)
	if list.is_empty():
		return 1.0
	var total: float = 0.0
	for assignment: VassalBeyAssignment in list:
		total += assignment.reinforcement_troop_mult
	return clampf(total / float(list.size()), 0.25, 1.0)


## Audits direct region ownership vs Direct Governance Cap for `player_id`.
## Exceeding the cap inflicts tax inefficiency and optional seasonal Kut drain.
func evaluate_governance_strain(player_id: int, apply_seasonal_kut_drain: bool = false) -> Dictionary[StringName, float]:
	var direct_count: int = get_direct_region_count(player_id)
	var cap: int = get_direct_cap(player_id)
	var extra: int = maxi(direct_count - cap, 0)

	var per_extra_kut: float = _rules.over_cap_kut_drain_per_extra if _rules != null else 4.0
	var per_extra_tax: float = _rules.over_cap_tax_penalty_per_extra if _rules != null else 0.15
	var floor_tax: float = _rules.over_cap_tax_floor if _rules != null else 0.25

	var kut_drain: float = float(extra) * per_extra_kut
	var tax_eff: float = clampf(1.0 - float(extra) * per_extra_tax, floor_tax, 1.0)
	_direct_tax_efficiency[player_id] = tax_eff

	if apply_seasonal_kut_drain and extra > 0:
		CommandBus.dispatch(ModifyKutCommand.new(-kut_drain, REASON_OVEREXTENSION))
		EventBus.governance_cap_exceeded.emit(
			player_id, direct_count, cap, kut_drain, clampf(1.0 - tax_eff, 0.0, 1.0))

	return {
		&"direct_count": float(direct_count),
		&"direct_cap": float(cap),
		&"extra_regions": float(extra),
		&"kut_drain": kut_drain,
		&"tax_efficiency": tax_eff,
	}


func _handle_delegate_region(command: GameCommand) -> bool:
	var cmd: DelegateRegionToVassalCommand = command as DelegateRegionToVassalCommand
	if cmd == null:
		return command.reject("Expected DelegateRegionToVassalCommand.")
	if cmd.player_id <= 0 or cmd.bey_id == &"":
		return command.reject("DelegateRegionToVassalCommand requires positive player_id and non-empty bey_id.")
	var reg: RegionData = TerritoryManager.get_region(cmd.coord)
	if reg == null or reg.owner_id != cmd.player_id:
		return command.reject("Player %d does not own region (%d, %d) to delegate." % [cmd.player_id, cmd.coord.x, cmd.coord.y])
	if _delegated_by_coord.has(cmd.coord) and _vassals.has(_delegated_by_coord[cmd.coord]):
		return command.reject("Region (%d, %d) is already delegated to a Vassal Bey." % [cmd.coord.x, cmd.coord.y])

	var assignment: VassalBeyAssignment = VassalBeyAssignment.new(
		cmd.bey_id, cmd.player_id, cmd.coord, cmd.personality_trait)
	if cmd.personality_trait == GameEnums.VassalPersonalityTrait.LOYAL:
		assignment.loyalty = 85.0
	elif cmd.personality_trait == GameEnums.VassalPersonalityTrait.AMBITIOUS:
		assignment.loyalty = 62.0

	_delegated_by_coord[cmd.coord] = cmd.bey_id
	_vassals[cmd.bey_id] = assignment

	var strain: Dictionary[StringName, float] = evaluate_governance_strain(cmd.player_id, false)
	cmd.delegated = true
	cmd.direct_regions_after = int(strain[&"direct_count"])
	EventBus.region_delegated_to_vassal.emit(cmd.player_id, cmd.coord, cmd.bey_id, cmd.personality_trait)
	return true


func _handle_sign_ulus_contract(command: GameCommand) -> bool:
	var cmd: SignUlusContractCommand = command as SignUlusContractCommand
	if cmd == null:
		return command.reject("Expected SignUlusContractCommand.")
	if cmd.bey_id == &"" or not _vassals.has(cmd.bey_id):
		return command.reject("Unknown delegated Vassal Bey '%s'." % cmd.bey_id)

	var assignment: VassalBeyAssignment = _vassals[cmd.bey_id]
	assignment.promised_ulus_share = cmd.promised_share
	assignment.delivered_ulus_share = cmd.delivered_share

	var shortfall_ratio: float = 0.0
	if cmd.promised_share > 0.0 and cmd.delivered_share < cmd.promised_share:
		shortfall_ratio = clampf((cmd.promised_share - cmd.delivered_share) / cmd.promised_share, 0.0, 1.0)

	var tolerance: float = 0.05
	var delay_trait_mult: float = 1.0
	var troop_trait_mult: float = 1.0
	match assignment.personality_trait:
		GameEnums.VassalPersonalityTrait.LOYAL:
			tolerance = 0.12
			delay_trait_mult = 0.75
			troop_trait_mult = 0.85
		GameEnums.VassalPersonalityTrait.GREEDY:
			tolerance = 0.0
			delay_trait_mult = 1.35
			troop_trait_mult = 1.25
		GameEnums.VassalPersonalityTrait.AMBITIOUS:
			tolerance = 0.02
			delay_trait_mult = 1.15
			troop_trait_mult = 1.15
		GameEnums.VassalPersonalityTrait.CAUTIOUS:
			tolerance = 0.05
			delay_trait_mult = 1.20
			troop_trait_mult = 1.25

	var base_delay: float = _rules.ulus_unmet_silent_delay_hours if _rules != null else 12.0
	var base_troop: float = _rules.ulus_unmet_troop_mult if _rules != null else 0.55
	var loyal_gain: float = _rules.ulus_fulfillment_loyalty_gain if _rules != null else 8.0
	var loyalty_drop: float = _rules.ulus_shortfall_loyalty_drop if _rules != null else 18.0

	var prev_loyalty: float = assignment.loyalty
	if shortfall_ratio <= tolerance:
		assignment.silent_sabotage_active = false
		assignment.reinforcement_delay_hours = 0.0
		assignment.reinforcement_troop_mult = 1.0
		assignment.loyalty = clampf(assignment.loyalty + loyal_gain, 0.0, 100.0)
		cmd.fulfilled = true
		cmd.silent_sabotage_triggered = false
	else:
		assignment.silent_sabotage_active = true
		assignment.reinforcement_delay_hours = clampf(
			base_delay * delay_trait_mult * (0.65 + shortfall_ratio * 0.70), 4.0, 36.0)
		assignment.reinforcement_troop_mult = clampf(
			1.0 - (1.0 - base_troop) * troop_trait_mult * (0.55 + shortfall_ratio * 0.85), 0.25, 0.90)
		assignment.loyalty = clampf(
			assignment.loyalty - loyalty_drop * (0.5 + shortfall_ratio * delay_trait_mult), 0.0, 100.0)
		cmd.fulfilled = false
		cmd.silent_sabotage_triggered = true

	var loyalty_delta: float = assignment.loyalty - prev_loyalty
	cmd.reinforcement_delay_hours = assignment.reinforcement_delay_hours
	cmd.reinforcement_troop_mult = assignment.reinforcement_troop_mult
	cmd.resulting_loyalty = assignment.loyalty

	EventBus.ulus_contract_settled.emit(cmd.bey_id, cmd.fulfilled, shortfall_ratio, loyalty_delta)
	if assignment.silent_sabotage_active:
		EventBus.vassal_silent_sabotage_delayed.emit(
			cmd.bey_id, assignment.reinforcement_delay_hours, assignment.reinforcement_troop_mult)
	return true
