class_name CouncilCrisisEvent
extends Resource
## Data layer (rank 1). Defines the 3 strategic dilemmas presented by the
## **Ak Sakallılar Konseyi** when the Khagan's Kut drops below 30:
##  1. `TRADITION` (Töreye Bağlılık): +Kut, -Economic Income, -Army Speed
##  2. `EXPANSION` (Yağma ve Sefer Serbestisi): +Military Morale, +Raid Loot, -Dynasty Diplomacy Trust
##  3. `SACRIFICE` (Hazine Fedakarlığı): -Steel, -Silver/Gold Treasury, +Popular Loyalty & Kut

@export var crisis_id: StringName = &"ak_sakallilar_mandate_crisis"
@export var title: String = "Ak Sakallılar Kurultayı: Kut ve Töre İkilemi"

@export_group("1. Töreye Bağlılık (Tradition)")
@export_range(1.0, 100.0, 0.5) var tradition_kut_gain: float = 22.0
@export_range(0.1, 1.0, 0.01) var tradition_income_multiplier: float = 0.75
@export_range(0.1, 1.0, 0.01) var tradition_speed_multiplier: float = 0.85

@export_group("2. Yağma ve Sefer Serbestisi (Expansion)")
@export_range(1.0, 100.0, 0.5) var expansion_morale_bonus: float = 20.0
@export_range(1.0, 3.0, 0.05) var expansion_loot_multiplier: float = 1.45
@export_range(-100.0, -1.0, 0.5) var expansion_diplomacy_trust_penalty: float = -35.0

@export_group("3. Hazine Fedakarlığı (Sacrifice)")
@export_range(1, 500) var sacrifice_steel_cost: int = 2
@export_range(1, 5000) var sacrifice_silver_gold_cost: int = 15
@export_range(1.0, 100.0, 0.5) var sacrifice_kut_gain: float = 28.0
@export_range(1.0, 100.0, 0.5) var sacrifice_popular_loyalty_bonus: float = 30.0


## Returns schema violations (empty when valid).
func get_validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if crisis_id == &"":
		errors.append("CouncilCrisisEvent: crisis_id cannot be empty.")
	if tradition_kut_gain <= 0.0 or tradition_income_multiplier >= 1.0 or tradition_speed_multiplier >= 1.0:
		errors.append("CouncilCrisisEvent: TRADITION must increase Kut while restricting income (< 1.0) and speed (< 1.0).")
	if expansion_morale_bonus <= 0.0 or expansion_loot_multiplier <= 1.0 or expansion_diplomacy_trust_penalty >= 0.0:
		errors.append("CouncilCrisisEvent: EXPANSION must boost morale/loot while penalizing dynasty trust (< 0).")
	if sacrifice_steel_cost <= 0 or sacrifice_silver_gold_cost <= 0 or sacrifice_kut_gain <= 0.0:
		errors.append("CouncilCrisisEvent: SACRIFICE requires positive Steel and Silver/Gold costs and positive Kut gain.")
	return errors
