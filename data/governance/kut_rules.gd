class_name KutRules
extends Resource
## Data layer (rank 1). Balancing parameters for the Kut (Divine Mandate)
## 0-100 scoring system and the Ak Sakallılar Konseyi crisis threshold.

@export_range(1.0, 1000.0, 1.0) var max_kut: float = 100.0
@export_range(0.0, 1000.0, 1.0) var initial_kut: float = 75.0
## Dropping strictly below this threshold (< 30) triggers Ak Sakallılar Konseyi.
@export_range(0.0, 1000.0, 1.0) var critical_kut_threshold: float = 30.0

@export_group("Drain & Recovery")
## Kut drained when Food <= 0 during Zud / Winter.
@export_range(0.0, 100.0, 0.1) var zud_starvation_kut_drain: float = 18.0
## Base Kut drained on a battle defeat.
@export_range(0.0, 100.0, 0.1) var battle_loss_base_kut_drain: float = 8.0
## Extra Kut drained per consecutive defeat beyond the first.
@export_range(0.0, 100.0, 0.1) var consecutive_loss_escalation: float = 4.0
## Kut restored on a victorious battle.
@export_range(0.0, 100.0, 0.1) var victory_kut_gain: float = 6.0

@export_group("Ak Sakallılar Council Effects")
## Fractional legitimacy loss applied while Kut is below the critical threshold.
@export_range(0.0, 1.0, 0.01) var legitimacy_loss_penalty: float = 0.25
## True when convening the council also initiates potential civil skirmishes.
@export var trigger_civil_skirmish_on_critical: bool = true

@export_group("Seasonal Food")
@export_range(0, 100000) var starting_food_reserve: int = 120
@export_range(0, 100000) var winter_food_consumption_per_cycle: int = 60
## Mild-season Kut normalization toward baseline (75) when pastures are healthy and food buffer suffices.
@export_range(0.0, 20.0, 0.5) var benign_pasture_prosperity_kut_recovery: float = 2.0
@export_range(0, 500) var prosperity_food_surplus_threshold: int = 80

@export_group("Phase 4 Zud Epidemic & Kurgan Purification")
## Base probability of Bozkır Vebası (`outbreak_epidemic`) when Food <= 0 during Winter/Zud.
@export_range(0.0, 1.0, 0.01) var epidemic_outbreak_base_chance: float = 0.65
## Additional outbreak probability inside a closed/isolated camp during Zud starvation.
@export_range(0.0, 1.0, 0.01) var closed_camp_epidemic_bonus_chance: float = 0.25
## Movement speed multiplier applied to plague-stricken armies (0.50 = speed halved).
@export_range(0.1, 1.0, 0.01) var epidemic_speed_multiplier: float = 0.50
## Daily fractional troop attrition suffered while infected by the steppe plague.
@export_range(0.005, 0.50, 0.005) var epidemic_daily_troop_attrition_ratio: float = 0.08
## Kut cost required to perform a purification ritual at a Kurgan Shrine (`kurgan_shrine.tres`) or infirmary.
@export_range(1.0, 100.0, 0.5) var kurgan_purification_kut_cost: float = 12.0
@export var kurgan_shrine_building_id: StringName = &"kurgan_shrine"


## Computes Kut drain for the Nth consecutive battle defeat (N >= 1).
func compute_battle_loss_drain(consecutive_losses: int) -> float:
	var streak: int = maxi(consecutive_losses, 1)
	return battle_loss_base_kut_drain + float(streak - 1) * consecutive_loss_escalation


## Computes total probability (`0..1`) of a Zud steppe plague outbreak when Food <= 0.
func compute_epidemic_outbreak_chance(is_closed_camp: bool) -> float:
	var bonus: float = closed_camp_epidemic_bonus_chance if is_closed_camp else 0.0
	return clampf(epidemic_outbreak_base_chance + bonus, 0.0, 1.0)


## Returns schema violations (empty when valid).
func get_validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if max_kut <= 0.0:
		errors.append("KutRules: max_kut must be > 0.")
	if critical_kut_threshold <= 0.0 or critical_kut_threshold >= max_kut:
		errors.append("KutRules: critical_kut_threshold must lie in (0, max_kut).")
	if epidemic_speed_multiplier <= 0.0 or epidemic_speed_multiplier > 1.0:
		errors.append("KutRules: epidemic_speed_multiplier must lie in (0, 1].")
	if kurgan_purification_kut_cost <= 0.0:
		errors.append("KutRules: kurgan_purification_kut_cost must be > 0.")
	return errors

