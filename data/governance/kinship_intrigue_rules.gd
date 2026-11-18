class_name KinshipIntrigueRules
extends Resource
## Data layer (rank 1). Schema for Phase 9 **Kinship Blood-Ties, Bey Rivalry &
## Internal Betrayal / Coup Dynamics** (`res://data/governance/kinship_intrigue_rules.tres`).

@export var rules_id: StringName = &"steppe_kinship_intrigue_rules"
@export_range(10.0, 100.0, 1.0) var default_initial_loyalty: float = 70.0
@export_range(10.0, 100.0, 1.0) var default_initial_ambition: float = 55.0
@export_range(0.0, 100.0, 1.0) var default_initial_grievance: float = 10.0

@export_group("Grievance & Loyalty Escalation")
@export_range(5.0, 60.0, 1.0) var unfair_toy_grievance_gain: float = 28.0
@export_range(5.0, 60.0, 1.0) var unfair_toy_loyalty_drop: float = 22.0
@export_range(5.0, 50.0, 1.0) var low_kut_grievance_gain: float = 18.0
@export_range(20.0, 80.0, 1.0) var plot_grievance_threshold: float = 45.0
@export_range(10.0, 70.0, 1.0) var plot_loyalty_threshold: float = 45.0
## Combined `grievance + ambition * 0.5` above which `faction_plot` erupts into `defection` or `internal_uprising`.
@export_range(50.0, 160.0, 1.0) var betrayal_critical_score_threshold: float = 95.0
## Ambition threshold (`>= 75.0`) that turns a betrayal into a full `INTERNAL_UPRISING` coup rather than `DEFECTION_OR_SABOTAGE`.
@export_range(40.0, 99.0, 1.0) var uprising_ambition_threshold: float = 75.0
@export_range(50, 1000, 10) var base_defected_troops: int = 180
@export_range(2.0, 30.0, 1.0) var uprising_kut_drain: float = 12.0

@export_group("Resolution Costs & Restorations")
@export_range(5, 200, 5) var title_bestowal_bullion_cost: int = 25
@export_range(10.0, 60.0, 1.0) var title_bestowal_loyalty_gain: float = 35.0
@export_range(10.0, 60.0, 1.0) var negotiation_loyalty_gain: float = 22.0
@export_range(10.0, 60.0, 1.0) var suppression_loyalty_enforce: float = 60.0


## Evaluates the plot stage from `loyalty`, `ambition`, and `grievance`.
func classify_plot_stage(loyalty: float, ambition: float, grievance: float) -> GameEnums.IntriguePlotStage:
	var critical_score: float = grievance + ambition * 0.5
	if critical_score >= betrayal_critical_score_threshold and loyalty <= plot_loyalty_threshold:
		if ambition >= uprising_ambition_threshold:
			return GameEnums.IntriguePlotStage.INTERNAL_UPRISING
		return GameEnums.IntriguePlotStage.DEFECTION_OR_SABOTAGE
	if grievance >= plot_grievance_threshold or loyalty <= plot_loyalty_threshold:
		return GameEnums.IntriguePlotStage.FACTION_PLOT_BREWING
	return GameEnums.IntriguePlotStage.LOYAL_CALM


## Returns schema violations (empty when valid).
func get_validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if rules_id == &"":
		errors.append("KinshipIntrigueRules: rules_id cannot be empty.")
	if plot_grievance_threshold <= 0.0 or betrayal_critical_score_threshold <= plot_grievance_threshold:
		errors.append("KinshipIntrigueRules: betrayal_critical_score_threshold must exceed plot_grievance_threshold.")
	return errors
