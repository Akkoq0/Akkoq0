class_name ExecuteBarterTradeCommand
extends GameCommand
## Executes a dynamic scarcity barter or black-market smuggling trade with strict
## bid-ask spread and caravan freight fees that forbid round-trip arbitrage.

const ID: StringName = &"execute_barter_trade"

var player_id: int = 1
var region_coord: Vector2i = Vector2i.ZERO
var commodity_id: StringName = &"iron"
var direction: GameEnums.BarterDirection = GameEnums.BarterDirection.BUY_FROM_MARKET
var quantity: int = 1
var is_black_market: bool = false

var executed: bool = false
var unit_price: float = 0.0
var total_silver_delta: int = 0
var freight_fee_paid: int = 0


func _init(
		p_player_id: int = 1,
		p_region_coord: Vector2i = Vector2i.ZERO,
		p_commodity_id: StringName = &"iron",
		p_direction: GameEnums.BarterDirection = GameEnums.BarterDirection.BUY_FROM_MARKET,
		p_quantity: int = 1,
		p_is_black_market: bool = false) -> void:
	player_id = p_player_id
	region_coord = p_region_coord
	commodity_id = p_commodity_id
	direction = p_direction
	quantity = p_quantity
	is_black_market = p_is_black_market


func get_command_id() -> StringName:
	return ID
