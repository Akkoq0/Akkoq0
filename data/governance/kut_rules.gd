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


## Computes Kut drain for the Nth consecutive battle defeat (N >= 1).
func compute_battle_loss_drain(consecutive_losses: int) -> float:
	var streak: int = maxi(consecutive_losses, 1)
	return battle_loss_base_kut_drain + float(streak - 1) * consecutive_loss_escalation


## Returns schema violations (empty when valid).
func get_validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if max_kut <= 0.0:
		errors.append("KutRules: max_kut must be > 0.")
	if critical_kut_threshold <= 0.0 or critical_kut_threshold >= max_kut:
		errors.append("KutRules: critical_kut_threshold must lie in (0, max_kut).")
	return errors
