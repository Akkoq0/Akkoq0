extends Node
## Autoload `EmergentWorldEngine` (rank 2). Implements Phase 8 **Emergent
## Steppe Causality Engine & Autonomous Inter-Faction Conflicts**
## (`res://core/emergent_world_engine.gd`).
##
## Responsibilities:
##  * Evaluates live world variables (`pasture_depleted`, `is_zud_winter`,
##    `supply_line_severed`, `kut_score`, `quiver_ammo`, `captured_slave_workers`)
##    to trigger causal chains (`EmergentChain`) without pre-scripted quest locks.
##  * Simulates autonomous wars between neighboring dynasties and roaming
##    warbands (`karluk`, `kipchak`, `oghuz`, `rogue_warbands`), allowing the
##    player to profit via neutral trade, back either side, or strike both
##    exhausted armies opportunistically.

const RULES_PATH: String = "res://data/world/emergent_world_rules.tres"
const CHAIN_ZUD_PASTURE_SUPPLY: StringName = &"zud_pasture_supply_collapse"
const CHAIN_QUIVER_BORDER: StringName = &"quiver_famine_border_opportunism"
const CHAIN_CAPTIVE_KUT_FRACTURE: StringName = &"captive_unrest_kut_fracture"
const DEFAULT_ROGUE_SPLIT_ID: StringName = &"bozkir_kopuk_cerileri"

var _rules: EmergentWorldRules = null
var _active_chains: PackedStringArray = PackedStringArray()
var _inter_faction_conflict_count: int = 0


func _ready() -> void:
	_rules = ResourceLoader.load(RULES_PATH) as EmergentWorldRules
	if _rules == null:
		push_error("EmergentWorldEngine: failed to load EmergentWorldRules at %s." % RULES_PATH)
	else:
		for err: String in _rules.get_validation_errors():
			push_error("EmergentWorldEngine: %s" % err)
	CommandBus.register_handler(EvaluateEmergentWorldCommand.ID, _handle_evaluate_emergent_world)
	CommandBus.register_handler(InterveneFactionConflictCommand.ID, _handle_intervene_conflict)


func _exit_tree() -> void:
	CommandBus.unregister_handler(EvaluateEmergentWorldCommand.ID, _handle_evaluate_emergent_world)
	CommandBus.unregister_handler(InterveneFactionConflictCommand.ID, _handle_intervene_conflict)


func get_rules() -> EmergentWorldRules:
	return _rules


func get_active_chains() -> PackedStringArray:
	return _active_chains


func get_inter_faction_conflict_count() -> int:
	return _inter_faction_conflict_count


func _handle_evaluate_emergent_world(command: GameCommand) -> bool:
	var cmd: EvaluateEmergentWorldCommand = command as EvaluateEmergentWorldCommand
	if cmd == null:
		return command.reject("Expected EvaluateEmergentWorldCommand.")
	if _rules == null:
		return command.reject("EmergentWorldRules not loaded.")

	var chains: PackedStringArray = PackedStringArray()
	var responses: PackedStringArray = PackedStringArray()

	# Causal Chain 1: Overgrazed Pasture + Zud Winter + Severed Supply Line
	# -> Yılkı herd attrition + Yersiz Yurtsuz Çeriler split-off + 3 open sandbox options
	if cmd.pasture_depleted and cmd.is_zud_winter and cmd.supply_line_severed:
		chains.append(CHAIN_ZUD_PASTURE_SUPPLY)
		var opts1: PackedStringArray = _rules.get_open_responses_for_chain(CHAIN_ZUD_PASTURE_SUPPLY)
		responses.append_array(opts1)
		cmd.yilki_herd_attrition_ratio = _rules.zud_pasture_supply_yilki_attrition
		cmd.rogue_warband_split_triggered = true
		cmd.spawned_rogue_warband_id = DEFAULT_ROGUE_SPLIT_ID
		EventBus.emergent_causal_chain_triggered.emit(CHAIN_ZUD_PASTURE_SUPPLY, cmd.region_coord, 0.90, opts1)

	# Causal Chain 2: Low Quiver Ammo + Hostile Neighbor
	if cmd.quiver_ammo <= _rules.low_quiver_ammo_threshold and cmd.hostile_neighbor_present:
		chains.append(CHAIN_QUIVER_BORDER)
		var opts2: PackedStringArray = _rules.get_open_responses_for_chain(CHAIN_QUIVER_BORDER)
		responses.append_array(opts2)
		EventBus.emergent_causal_chain_triggered.emit(CHAIN_QUIVER_BORDER, cmd.region_coord, 0.65, opts2)

	# Causal Chain 3: Captive Workers Outnumber Clan Population + Low Kut
	if cmd.captured_slave_workers > cmd.clan_population and cmd.kut_score < _rules.fracture_kut_threshold:
		chains.append(CHAIN_CAPTIVE_KUT_FRACTURE)
		var opts3: PackedStringArray = _rules.get_open_responses_for_chain(CHAIN_CAPTIVE_KUT_FRACTURE)
		responses.append_array(opts3)
		EventBus.emergent_causal_chain_triggered.emit(CHAIN_CAPTIVE_KUT_FRACTURE, cmd.region_coord, 0.80, opts3)

	_active_chains = chains
	cmd.triggered_chain_ids = chains
	cmd.available_responses = responses
	return true


func _handle_intervene_conflict(command: GameCommand) -> bool:
	var cmd: InterveneFactionConflictCommand = command as InterveneFactionConflictCommand
	if cmd == null:
		return command.reject("Expected InterveneFactionConflictCommand.")
	if _rules == null:
		return command.reject("EmergentWorldRules not loaded.")
	if cmd.attacker_faction_id == &"" or cmd.defender_faction_id == &"" or cmd.attacker_faction_id == cmd.defender_faction_id:
		return command.reject("InterveneFactionConflictCommand requires two distinct faction IDs.")

	_inter_faction_conflict_count += 1
	EventBus.inter_faction_conflict_erupted.emit(
		cmd.attacker_faction_id, cmd.defender_faction_id, cmd.region_coord, cmd.contested_driver)

	cmd.mutual_exhaustion_ratio = _rules.inter_faction_mutual_exhaustion_ratio

	if cmd.stance == GameEnums.EmergentInterventionStance.NEUTRAL_TRADE_PROFITEER:
		var bullion: int = _rules.neutral_trade_profiteer_bullion
		CommandBus.dispatch(DepositResourcesCommand.new(cmd.player_id, &"silver_gold", bullion))
		cmd.bullion_profited = bullion
		cmd.reward_value_gained = float(bullion)
	elif cmd.stance == GameEnums.EmergentInterventionStance.OPPORTUNISTIC_STRIKE_BOTH:
		cmd.bullion_profited = 0
		cmd.reward_value_gained = _rules.opportunistic_double_strike_loot
	else:
		cmd.bullion_profited = 0
		cmd.reward_value_gained = _rules.coalition_intervention_reward

	EventBus.player_intervened_in_faction_conflict.emit(
		cmd.player_id,
		cmd.attacker_faction_id,
		cmd.defender_faction_id,
		cmd.stance,
		cmd.reward_value_gained)
	return true
