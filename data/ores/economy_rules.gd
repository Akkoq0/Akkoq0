class_name EconomyRules
extends Resource
## Data layer (rank 1). Parameters for regional tax, Jade Tamga/Authority
## scaling, and Meteoric Iron binding requirements.

@export_group("Regional Silver/Gold Tax")
@export var tax_ore_id: StringName = &"silver_gold"
@export_range(0.0, 10000.0, 0.1) var base_tax_per_region: float = 12.0
@export_range(0.0, 10000.0, 0.1) var rich_region_tax_bonus: float = 6.0

@export_group("Jade Tamga / Authority")
@export var authority_ore_id: StringName = &"jade"
## Fractional authority bonus per unit of Jade held in stockpile.
@export_range(0.0, 1.0, 0.0001) var jade_authority_bonus_per_unit: float = 0.005
@export_range(1.0, 10.0, 0.01) var max_authority_multiplier: float = 2.0

@export_group("Meteoric Iron Binding")
@export var meteoric_ore_id: StringName = &"meteoric_iron"
@export_range(1, 10000) var commander_weapon_binding_cost: int = 5
@export_range(1, 10000) var totem_ascension_binding_cost: int = 12

@export_group("Warehouse Cap")
@export_range(1000, 500000) var max_ore_stockpile_capacity: int = 50000


## Computes the Jade-driven Tamga/Authority multiplier from `jade_amount`.
func compute_authority_multiplier(jade_amount: int) -> float:
	var bonus: float = float(maxi(jade_amount, 0)) * jade_authority_bonus_per_unit
	return clampf(1.0 + bonus, 1.0, max_authority_multiplier)


## Computes the regional silver/gold tax routed to the treasury.
func compute_regional_tax(region_count: int, rich_region_count: int, authority_multiplier: float) -> int:
	var raw_tax: float = float(maxi(region_count, 0)) * base_tax_per_region \
		+ float(maxi(rich_region_count, 0)) * rich_region_tax_bonus
	return maxi(roundi(raw_tax * maxf(authority_multiplier, 0.0)), 0)


## Required Meteoric Iron units for commander weapon or totem ascension binding.
func get_binding_cost(for_totem_ascension: bool) -> int:
	return totem_ascension_binding_cost if for_totem_ascension else commander_weapon_binding_cost


## Returns schema violations (empty when valid).
func get_validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if tax_ore_id == &"":
		errors.append("EconomyRules: tax_ore_id is empty.")
	if authority_ore_id == &"":
		errors.append("EconomyRules: authority_ore_id is empty.")
	if meteoric_ore_id == &"":
		errors.append("EconomyRules: meteoric_ore_id is empty.")
	if max_authority_multiplier < 1.0:
		errors.append("EconomyRules: max_authority_multiplier must be >= 1.0.")
	if max_ore_stockpile_capacity < 1000:
		errors.append("EconomyRules: max_ore_stockpile_capacity must be >= 1000.")
	return errors
