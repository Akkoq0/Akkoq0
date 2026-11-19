class_name WaterAndMarketRules
extends Resource
## Data layer (rank 1). Schema and mathematical safeguards for Phase 23
## **Steppe Water Logistics, Well Sabotage/Winter Freezing, and Anti-Arbitrage
## Regional Scarcity Barter Market** (`res://data/economy/water_and_market_rules.tres`).

@export var rules_id: StringName = &"steppe_water_and_market_rules"

@export_group("Steppe Water & Hydration")
@export_range(0.05, 0.80, 0.01) var dehydration_remount_drain_per_season: float = 0.28
@export_range(2.0, 40.0, 0.5) var dehydration_morale_penalty: float = 18.0
@export_range(1, 10) var well_sabotage_duration_seasons: int = 3
@export_range(5, 200) var well_restore_bullion_cost: int = 25
@export_range(5, 200) var well_restore_stone_cost: int = 20

@export_group("Regional Scarcity & Anti-Arbitrage Market")
@export var base_commodity_prices: Dictionary[StringName, float] = {
	&"stone": 4.0,
	&"iron": 6.0,
	&"coal": 7.0,
	&"sulfur": 9.0,
	&"steel": 18.0,
	&"jade": 32.0,
	&"meteoric_iron": 48.0,
	&"food": 5.0,
	&"yilki_horse": 22.0,
}
@export_range(0.30, 1.0, 0.05) var min_scarcity_multiplier: float = 0.60
@export_range(1.2, 5.0, 0.1) var max_scarcity_multiplier: float = 3.20
@export_range(0.05, 1.0, 0.05) var caravan_cut_scarcity_boost: float = 0.45
@export_range(0.05, 1.0, 0.05) var quarry_loss_scarcity_boost: float = 0.35
@export_range(0.05, 0.45, 0.01) var bid_ask_spread_ratio: float = 0.16
@export_range(0.02, 0.35, 0.01) var caravan_freight_fee_ratio: float = 0.08
@export_range(0.05, 0.80, 0.01) var black_market_scarcity_bonus: float = 0.25
@export_range(0.0, 0.20, 0.01) var exile_smuggler_sell_bonus: float = 0.08


func get_base_price(commodity_id: StringName) -> float:
	if base_commodity_prices.has(commodity_id):
		return maxf(base_commodity_prices[commodity_id], 1.0)
	return 0.0


## Computes unit purchase price strictly above mid-price via spread + freight + depth impact.
func compute_buy_unit_price(commodity_id: StringName, scarcity_mult: float, quantity: int, is_black_market: bool) -> float:
	var base_p: float = get_base_price(commodity_id)
	if base_p <= 0.0:
		return 0.0
	var clamped_scarcity: float = clampf(scarcity_mult, min_scarcity_multiplier, max_scarcity_multiplier)
	var bm_add: float = black_market_scarcity_bonus if is_black_market else 0.0
	var mid: float = base_p * clampf(clamped_scarcity + bm_add, min_scarcity_multiplier, max_scarcity_multiplier + black_market_scarcity_bonus)
	var volume_slippage: float = clampf(float(maxi(quantity, 1)) * 0.004, 0.0, 0.25)
	return mid * (1.0 + bid_ask_spread_ratio + caravan_freight_fee_ratio + volume_slippage)


## Computes unit sale price strictly below buy price (`sell <= 0.85 * buy`) so
## buy -> sell or sell -> buy round trips mathematically guarantee negative net profit.
func compute_sell_unit_price(commodity_id: StringName, scarcity_mult: float, quantity: int, is_black_market: bool, is_exile_smuggler: bool) -> float:
	var base_p: float = get_base_price(commodity_id)
	if base_p <= 0.0:
		return 0.0
	var clamped_scarcity: float = clampf(scarcity_mult, min_scarcity_multiplier, max_scarcity_multiplier)
	var bm_add: float = black_market_scarcity_bonus * 0.50 if is_black_market else 0.0
	var mid: float = base_p * clampf(clamped_scarcity + bm_add, min_scarcity_multiplier, max_scarcity_multiplier + black_market_scarcity_bonus)
	var exile_relief: float = exile_smuggler_sell_bonus if (is_black_market and is_exile_smuggler) else 0.0
	var volume_impact: float = clampf(float(maxi(quantity, 1)) * 0.004, 0.0, 0.25)
	var ask_ref: float = compute_buy_unit_price(commodity_id, scarcity_mult, 1, is_black_market)
	var raw_bid_mult: float = clampf(1.0 - bid_ask_spread_ratio - caravan_freight_fee_ratio * 0.5 + exile_relief - volume_impact, 0.35, 0.90)
	return minf(mid * raw_bid_mult, ask_ref * 0.80)


func get_validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if rules_id == &"":
		errors.append("WaterAndMarketRules: rules_id cannot be empty.")
	if dehydration_remount_drain_per_season <= 0.0 or well_sabotage_duration_seasons < 1:
		errors.append("WaterAndMarketRules: water crisis parameters must be positive.")
	if min_scarcity_multiplier <= 0.0 or max_scarcity_multiplier <= min_scarcity_multiplier:
		errors.append("WaterAndMarketRules: scarcity bounds invalid.")
	if bid_ask_spread_ratio + caravan_freight_fee_ratio <= exile_smuggler_sell_bonus:
		errors.append("WaterAndMarketRules: friction must exceed smuggler bonus to guarantee anti-arbitrage.")
	return errors
