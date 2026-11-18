extends Node
## Autoload `ResourceManager` (rank 2). Owns every player's ore stockpile.
##
## Mutations only happen through `SpendResourcesCommand` /
## `DepositResourcesCommand`; every change is broadcast on the EventBus.

const ORE_REGISTRY_PATH: String = "res://data/ores/ore_registry.tres"

var _registry: OreRegistry = null
var _stockpiles: Dictionary[int, Stockpile] = {}


func _ready() -> void:
	_registry = ResourceLoader.load(ORE_REGISTRY_PATH) as OreRegistry
	if _registry == null:
		push_error("ResourceManager: failed to load OreRegistry at %s." % ORE_REGISTRY_PATH)
		return
	for error: String in _registry.get_validation_errors():
		push_error("ResourceManager: %s" % error)
	CommandBus.register_handler(SpendResourcesCommand.ID, _handle_spend)
	CommandBus.register_handler(DepositResourcesCommand.ID, _handle_deposit)


func _exit_tree() -> void:
	CommandBus.unregister_handler(SpendResourcesCommand.ID, _handle_spend)
	CommandBus.unregister_handler(DepositResourcesCommand.ID, _handle_deposit)


## The loaded ore registry (null if loading failed).
func get_registry() -> OreRegistry:
	return _registry


## Read-only query: amount of `ore_id` owned by `player_id`.
func get_amount(player_id: int, ore_id: StringName) -> int:
	return _get_or_create_stockpile(player_id).get_amount(ore_id)


## Read-only query: true when `player_id` can pay `costs`.
func can_afford(player_id: int, costs: Array[ResourceAmount]) -> bool:
	return _get_or_create_stockpile(player_id).can_afford(costs)


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
	return true


func _get_or_create_stockpile(player_id: int) -> Stockpile:
	if _stockpiles.has(player_id):
		return _stockpiles[player_id]
	var stockpile: Stockpile = Stockpile.new(player_id)
	if _registry != null:
		for ore: OreData in _registry.ores:
			if ore != null and ore.starting_amount > 0:
				stockpile.add(ore.id, ore.starting_amount)
	_stockpiles[player_id] = stockpile
	return stockpile
