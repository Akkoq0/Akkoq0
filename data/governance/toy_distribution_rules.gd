class_name ToyDistributionRules
extends Resource
## Data layer (rank 1). Parameters for post-raid Toy & Meat (Ülüş / Söğüş)
## distribution politics and Bey conversion into rogue warbands.

## Minimum fraction of total raid loot expected by regional Beys.
@export_range(0.0, 1.0, 0.01) var expected_bey_share_ratio: float = 0.40
@export_range(0.0, 100.0, 0.1) var max_bey_satisfaction: float = 100.0
@export_range(0.0, 100.0, 0.1) var initial_bey_satisfaction: float = 65.0
## Satisfaction gained when both loot share and Toy meat distribution are fair.
@export_range(0.0, 100.0, 0.1) var satisfaction_gain_on_fair_share: float = 12.0
## Satisfaction lost per unit of share shortfall (expected_ratio - actual_ratio).
@export_range(0.0, 500.0, 0.1) var satisfaction_loss_per_shortfall_ratio: float = 85.0
## Additional satisfaction penalty when Toy meat (Söğüş / Ülüş) protocol is dishonored.
@export_range(0.0, 100.0, 0.1) var unfair_meat_portion_penalty: float = 18.0
## Satisfaction threshold (< threshold) below which a Bey rebels as a rogue warband.
@export_range(0.0, 100.0, 0.1) var rebellion_satisfaction_threshold: float = 30.0
## Title assigned to independent rogue warbands formed by dissatisfied Beys.
@export var rogue_warband_title: String = "Yersiz Yurtsuz Çeriler"


## Computes the satisfaction delta for a single Toy distribution event.
func compute_satisfaction_delta(total_loot_value: float, allocated_bey_value: float, sogus_meat_fair: bool) -> float:
	if total_loot_value <= 0.0:
		return -unfair_meat_portion_penalty if not sogus_meat_fair else 0.0
	var actual_ratio: float = clampf(allocated_bey_value / total_loot_value, 0.0, 1.0)
	var delta: float = 0.0
	if actual_ratio < expected_bey_share_ratio:
		var shortfall: float = expected_bey_share_ratio - actual_ratio
		delta -= shortfall * satisfaction_loss_per_shortfall_ratio
	else:
		delta += satisfaction_gain_on_fair_share
	if not sogus_meat_fair:
		delta -= unfair_meat_portion_penalty
	return delta


## Returns schema violations (empty when valid).
func get_validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if rogue_warband_title.is_empty():
		errors.append("ToyDistributionRules: rogue_warband_title is empty.")
	if rebellion_satisfaction_threshold <= 0.0 or rebellion_satisfaction_threshold >= max_bey_satisfaction:
		errors.append("ToyDistributionRules: rebellion_satisfaction_threshold out of range.")
	return errors
