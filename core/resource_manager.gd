extends Node
## Autoload `ResourceManager` (rank 2). Owns every player's ore stockpile and
## executes the 7-ore transformation pipeline:
##  * `2 Iron + 1 Coal = 1 Steel` inside `NomadicForge`
##  * Regional Silver/Gold tax generation routed directly to the treasury
##  * Jade-driven Tamga/Authority multiplier calculation
##  * Meteoric Iron binding checks for commander weapons and totem ascension

const ORE_REGISTRY_PATH: String = "res://data/ores/ore_registry.tres"
const ECONOMY_RULES_PATH: String = "res://data/ores/economy_rules.tres"
const STEEL_RECIPE_ID: StringName = &"smelt_steel"
const NOMADIC_FORGE_ID: StringName = &"nomadic_forge"

var _registry: OreRegistry = null
var _economy_rules: EconomyRules = null
var _stockpiles: Dictionary[int, Stockpile] = {}
## "<player_id>:<target_id>" -> true when Meteoric Iron has been bound.
var _meteoric_bindings: Dictionary[StringName, bool] = {}
## Phase 11 operational logistics state for Sefer Arabası migration & supply isolation.
var _camp_migrating_state: Dictionary[int, bool] = {}
var _camp_supply_cut_state: Dictionary[int, bool] = {}


func _ready() -> void:
	_registry = ResourceLoader.load(ORE_REGISTRY_PATH) as OreRegistry
	if _registry == null:
		push_error("ResourceManager: failed to load OreRegistry at %s." % ORE_REGISTRY_PATH)
		return
	for error: String in _registry.get_validation_errors():
		push_error("ResourceManager: %s" % error)

	_economy_rules = ResourceLoader.load(ECONOMY_RULES_PATH) as EconomyRules
	if _economy_rules == null:
		push_error("ResourceManager: failed to load EconomyRules at %s." % ECONOMY_RULES_PATH)
		return
	for error: String in _economy_rules.get_validation_errors():
		push_error("ResourceManager: %s" % error)

	CommandBus.register_handler(SpendResourcesCommand.ID, _handle_spend)
	CommandBus.register_handler(DepositResourcesCommand.ID, _handle_deposit)
	CommandBus.register_handler(RefineOreCommand.ID, _handle_refine_ore)
	CommandBus.register_handler(CollectRegionalTaxCommand.ID, _handle_collect_regional_tax)
	CommandBus.register_handler(BindMeteoricIronCommand.ID, _handle_bind_meteoric_iron)


func _exit_tree() -> void:
	CommandBus.unregister_handler(SpendResourcesCommand.ID, _handle_spend)
	CommandBus.unregister_handler(DepositResourcesCommand.ID, _handle_deposit)
	CommandBus.unregister_handler(RefineOreCommand.ID, _handle_refine_ore)
	CommandBus.unregister_handler(CollectRegionalTaxCommand.ID, _handle_collect_regional_tax)
	CommandBus.unregister_handler(BindMeteoricIronCommand.ID, _handle_bind_meteoric_iron)


## The loaded ore registry (null if loading failed).
func get_registry() -> OreRegistry:
	return _registry


## The loaded economy rules (null if loading failed).
func get_economy_rules() -> EconomyRules:
	return _economy_rules


## Read-only query: amount of `ore_id` owned by `player_id`.
func get_amount(player_id: int, ore_id: StringName) -> int:
	return _get_or_create_stockpile(player_id).get_amount(ore_id)


## Read-only query: true when `player_id` can pay `costs`.
func can_afford(player_id: int, costs: Array[ResourceAmount]) -> bool:
	return _get_or_create_stockpile(player_id).can_afford(costs)


## Jade-driven Tamga/Authority multiplier for `player_id`.
func calculate_jade_authority_multiplier(player_id: int) -> float:
	if _economy_rules == null:
		return 1.0
	var jade_amount: int = get_amount(player_id, _economy_rules.authority_ore_id)
	return _economy_rules.compute_authority_multiplier(jade_amount)


## Convenience helper: converts `2 Iron + 1 Coal = 1 Steel` inside `NomadicForge`.
func smelt_steel_in_nomadic_forge(player_id: int, batches: int = 1) -> bool:
	var cmd: RefineOreCommand = RefineOreCommand.new(player_id, NOMADIC_FORGE_ID, STEEL_RECIPE_ID, batches)
	return CommandBus.dispatch(cmd)


## Sets the player's current camp migration (`Sefer Arabası`) and supply-line status.
func set_camp_migration_and_supply_state(player_id: int, is_migrating_sefer_arabasi: bool, is_supply_cut_or_besieged: bool) -> void:
	_camp_migrating_state[player_id] = is_migrating_sefer_arabasi
	_camp_supply_cut_state[player_id] = is_supply_cut_or_besieged


func is_camp_migrating(player_id: int) -> bool:
	return _camp_migrating_state.get(player_id, false)


func is_camp_supply_cut(player_id: int) -> bool:
	return _camp_supply_cut_state.get(player_id, false)


## Returns Nomadic Forge steel smelting throughput multiplier under migration & supply constraints.
func get_effective_forge_throughput_multiplier(player_id: int) -> float:
	var mult: float = 1.0
	if is_camp_migrating(player_id):
		mult *= 0.35
	if is_camp_supply_cut(player_id):
		mult *= 0.70
	return mult


## Returns regional tax collection efficiency under Sefer Arabası migration & supply isolation.
func get_regional_tax_logistics_multiplier(player_id: int) -> float:
	var mult: float = 1.0
	if is_camp_migrating(player_id):
		mult *= 0.50
	if is_camp_supply_cut(player_id):
		mult *= 0.60
	return mult


## Returns combined political legitimacy (Kut < 30 penalty), Ak Sakallılar Council,
## and Direct Governance Cap tax efficiency multiplier.
func get_governance_tax_multiplier(player_id: int = 1) -> float:
	var gov_eff: float = GovernanceManager.get_direct_tax_efficiency(player_id)
	var mult: float = GameManager.get_legitimacy_multiplier() * CouncilEventEngine.get_active_income_multiplier() * gov_eff
	return clampf(mult, 0.20, 1.5)


## Attempts `2 Iron + 1 Coal = 1 Steel` smelting constrained by mobile Sefer Arabası / siege capacity.
## Clamps against available input stockpiles so large requests don't fail atomically, and avoids stalling
## on multi-batch requests during overlapping migration + siege constraints. Returns actual Steel smelted.
func smelt_steel_with_logistics_constraints(player_id: int, requested_batches: int) -> int:
	var clamped_req: int = maxi(requested_batches, 0)
	if clamped_req <= 0:
		return 0
	var throughput: float = get_effective_forge_throughput_multiplier(player_id)
	var allowed_batches: int = int(floorf(float(clamped_req) * throughput))
	if allowed_batches <= 0 and clamped_req >= 2 and throughput > 0.0:
		allowed_batches = 1
	if _registry != null:
		var recipe: RefiningRecipe = _registry.find_recipe(STEEL_RECIPE_ID)
		if recipe != null:
			var stockpile: Stockpile = _get_or_create_stockpile(player_id)
			var max_affordable: int = allowed_batches
			for inp: ResourceAmount in recipe.inputs:
				if inp != null and inp.amount > 0:
					max_affordable = mini(max_affordable, stockpile.get_amount(inp.get_ore_id()) / inp.amount)
			allowed_batches = maxi(max_affordable, 0)
	if allowed_batches <= 0:
		return 0
	var cmd: RefineOreCommand = RefineOreCommand.new(player_id, NOMADIC_FORGE_ID, STEEL_RECIPE_ID, allowed_batches)
	if not CommandBus.dispatch(cmd):
		return 0
	return cmd.produced_amount


## Convenience helper: calculates and routes regional Silver/Gold tax to the treasury.
func collect_regional_tax(player_id: int, region_count: int, rich_region_count: int = 0) -> int:
	var cmd: CollectRegionalTaxCommand = CollectRegionalTaxCommand.new(player_id, region_count, rich_region_count)
	if not CommandBus.dispatch(cmd):
		return 0
	return cmd.collected_tax


## Pure preview/evaluation combining Jade Tamga Authority, Sefer Arabası logistics, and Kut/Council governance limits.
func calculate_effective_regional_tax_with_logistics(player_id: int, region_count: int, rich_region_count: int = 0) -> int:
	if _economy_rules == null or region_count <= 0:
		return 0
	var effective_mult: float = calculate_jade_authority_multiplier(player_id) * get_regional_tax_logistics_multiplier(player_id) * get_governance_tax_multiplier(player_id)
	return _economy_rules.compute_regional_tax(region_count, rich_region_count, effective_mult)


## True when `player_id` has enough Meteoric Iron for commander weapon or totem ascension binding.
func can_bind_meteoric_iron(player_id: int, for_totem_ascension: bool) -> bool:
	if _economy_rules == null:
		return false
	var required: int = _economy_rules.get_binding_cost(for_totem_ascension)
	return get_amount(player_id, _economy_rules.meteoric_ore_id) >= required


## Binds Meteoric Iron under realistic hearth constraints: Totem Ascension requires a
## settled camp (blocked during Sefer Arabası migration), while emergency weapon binding
## succeeds unless supply-cut with insufficient reserves.
func bind_meteoric_iron_with_logistics(player_id: int, target_id: StringName, for_totem_ascension: bool) -> bool:
	if for_totem_ascension and is_camp_migrating(player_id):
		return false
	if not CaravanLogisticsManager.can_forge_meteoric_iron(player_id):
		return false
	var cmd: BindMeteoricIronCommand = BindMeteoricIronCommand.new(player_id, target_id, for_totem_ascension)
	return CommandBus.dispatch(cmd)


## True when `target_id` (commander weapon or totem id) has already been bound with Meteoric Iron.
func is_meteoric_iron_bound(player_id: int, target_id: StringName) -> bool:
	return _meteoric_bindings.get(_binding_key(player_id, target_id), false)


func _handle_spend(command: GameCommand) -> bool:
	var spend: SpendResourcesCommand = command as SpendResourcesCommand
	if spend == null:
		return command.reject("Expected SpendResourcesCommand.")
	var stockpile: Stockpile = _get_or_create_stockpile(spend.player_id)
	if not stockpile.can_afford(spend.costs):
		return command.reject("Player %d cannot afford the cost." % spend.player_id)
	for cost: ResourceAmount in spend.costs:
		var ore_id: StringName = cost.get_ore_id()
		var new_amount: int = stockpile.add(ore_id, -cost.amount)
		EventBus.resource_amount_changed.emit(spend.player_id, ore_id, new_amount, -cost.amount)
		_notify_if_authority_ore(spend.player_id, ore_id)
	return true


func _handle_deposit(command: GameCommand) -> bool:
	var deposit: DepositResourcesCommand = command as DepositResourcesCommand
	if deposit == null:
		return command.reject("Expected DepositResourcesCommand.")
	if _registry == null or not _registry.has_ore(deposit.ore_id):
		return command.reject("Unknown ore '%s'." % deposit.ore_id)
	if deposit.amount <= 0:
		return command.reject("Deposit amount must be positive.")
	var stockpile: Stockpile = _get_or_create_stockpile(deposit.player_id)
	deposit.resulting_amount = stockpile.add(deposit.ore_id, deposit.amount)
	EventBus.resource_amount_changed.emit(deposit.player_id, deposit.ore_id, deposit.resulting_amount, deposit.amount)
	_notify_if_authority_ore(deposit.player_id, deposit.ore_id)
	return true


func _handle_refine_ore(command: GameCommand) -> bool:
	var refine: RefineOreCommand = command as RefineOreCommand
	if refine == null:
		return command.reject("Expected RefineOreCommand.")
	if _registry == null:
		return command.reject("OreRegistry is not loaded.")
	if refine.batches <= 0:
		return command.reject("Refining batches must be positive.")
	var recipe: RefiningRecipe = _registry.find_recipe(refine.recipe_id)
	if recipe == null:
		return command.reject("Unknown refining recipe '%s'." % refine.recipe_id)
	if recipe.required_building_id != refine.building_id:
		return command.reject("Recipe '%s' requires building '%s', got '%s'." % [
			refine.recipe_id, recipe.required_building_id, refine.building_id])
	var scaled_inputs: Array[ResourceAmount] = recipe.build_scaled_inputs(refine.batches)
	var stockpile: Stockpile = _get_or_create_stockpile(refine.player_id)
	if not stockpile.can_afford(scaled_inputs):
		return command.reject("Player %d lacks input ores for '%s'." % [refine.player_id, refine.recipe_id])
	for input_cost: ResourceAmount in scaled_inputs:
		var in_id: StringName = input_cost.get_ore_id()
		var remaining: int = stockpile.add(in_id, -input_cost.amount)
		EventBus.resource_amount_changed.emit(refine.player_id, in_id, remaining, -input_cost.amount)
		_notify_if_authority_ore(refine.player_id, in_id)
	var scaled_outputs: Array[ResourceAmount] = recipe.build_scaled_outputs(refine.batches)
	var total_produced: int = 0
	for output_gain: ResourceAmount in scaled_outputs:
		var out_id: StringName = output_gain.get_ore_id()
		var updated: int = stockpile.add(out_id, output_gain.amount)
		total_produced += output_gain.amount
		EventBus.resource_amount_changed.emit(refine.player_id, out_id, updated, output_gain.amount)
		_notify_if_authority_ore(refine.player_id, out_id)
	refine.produced_amount = total_produced
	EventBus.ore_refined.emit(refine.player_id, refine.recipe_id, refine.building_id, refine.batches)
	return true


func _handle_collect_regional_tax(command: GameCommand) -> bool:
	var tax_cmd: CollectRegionalTaxCommand = command as CollectRegionalTaxCommand
	if tax_cmd == null:
		return command.reject("Expected CollectRegionalTaxCommand.")
	if _economy_rules == null:
		return command.reject("EconomyRules not loaded.")
	if tax_cmd.controlled_region_count <= 0:
		return command.reject("controlled_region_count must be positive.")
	var authority_mult: float = calculate_jade_authority_multiplier(tax_cmd.player_id)
	var logistics_mult: float = get_regional_tax_logistics_multiplier(tax_cmd.player_id)
	var governance_mult: float = get_governance_tax_multiplier(tax_cmd.player_id)
	var effective_mult: float = authority_mult * logistics_mult * governance_mult
	var tax_amount: int = _economy_rules.compute_regional_tax(
		tax_cmd.controlled_region_count, tax_cmd.rich_region_count, effective_mult)
	if tax_amount <= 0:
		return command.reject("Computed regional tax is zero.")
	var stockpile: Stockpile = _get_or_create_stockpile(tax_cmd.player_id)
	var new_treasury: int = stockpile.add(_economy_rules.tax_ore_id, tax_amount)
	tax_cmd.collected_tax = tax_amount
	tax_cmd.applied_authority_multiplier = authority_mult
	EventBus.resource_amount_changed.emit(tax_cmd.player_id, _economy_rules.tax_ore_id, new_treasury, tax_amount)
	EventBus.regional_tax_collected.emit(tax_cmd.player_id, tax_amount, authority_mult)
	return true


func _handle_bind_meteoric_iron(command: GameCommand) -> bool:
	var bind_cmd: BindMeteoricIronCommand = command as BindMeteoricIronCommand
	if bind_cmd == null:
		return command.reject("Expected BindMeteoricIronCommand.")
	if _economy_rules == null:
		return command.reject("EconomyRules not loaded.")
	if bind_cmd.target_id == &"":
		return command.reject("BindMeteoricIronCommand requires a non-empty target_id.")
	var key: StringName = _binding_key(bind_cmd.player_id, bind_cmd.target_id)
	if _meteoric_bindings.get(key, false):
		return command.reject("Target '%s' is already bound with Meteoric Iron." % bind_cmd.target_id)
	var required: int = _economy_rules.get_binding_cost(bind_cmd.for_totem_ascension)
	var stockpile: Stockpile = _get_or_create_stockpile(bind_cmd.player_id)
	var available: int = stockpile.get_amount(_economy_rules.meteoric_ore_id)
	if available < required:
		return command.reject("Insufficient Meteoric Iron: need %d, have %d." % [required, available])
	var remaining: int = stockpile.add(_economy_rules.meteoric_ore_id, -required)
	_meteoric_bindings[key] = true
	bind_cmd.consumed_amount = required
	EventBus.resource_amount_changed.emit(bind_cmd.player_id, _economy_rules.meteoric_ore_id, remaining, -required)
	EventBus.meteoric_iron_bound.emit(bind_cmd.player_id, bind_cmd.target_id, bind_cmd.for_totem_ascension, required)
	return true


func _notify_if_authority_ore(player_id: int, ore_id: StringName) -> void:
	if _economy_rules != null and ore_id == _economy_rules.authority_ore_id:
		EventBus.tamga_authority_updated.emit(player_id, calculate_jade_authority_multiplier(player_id))


func _binding_key(player_id: int, target_id: StringName) -> StringName:
	return StringName("%d:%s" % [player_id, target_id])


func _get_or_create_stockpile(player_id: int) -> Stockpile:
	var max_cap: int = _economy_rules.max_ore_stockpile_capacity if _economy_rules != null else 0
	if _stockpiles.has(player_id):
		var existing: Stockpile = _stockpiles[player_id]
		if existing.get_max_capacity() == 0 and max_cap > 0:
			existing.set_max_capacity(max_cap)
		return existing
	var stockpile: Stockpile = Stockpile.new(player_id, max_cap)
	if _registry != null:
		for ore: OreData in _registry.ores:
			if ore != null and ore.starting_amount > 0:
				stockpile.add(ore.id, ore.starting_amount)
		for refined: OreData in _registry.refined_ores:
			if refined != null and refined.starting_amount > 0:
				stockpile.add(refined.id, refined.starting_amount)
	_stockpiles[player_id] = stockpile
	return stockpile
