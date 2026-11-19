class_name TraditionResearchNode
extends Resource
## Data layer (rank 1). Definition of one node inside the 4-branch Steppe
## Tradition & Military Research DAG (`TraditionResearchCatalog`).

@export var node_id: StringName = &""
@export var title: String = ""
@export_multiline var description: String = ""
@export var branch: GameEnums.ResearchBranch = GameEnums.ResearchBranch.STEPPE_WARFARE
@export_range(1, 4, 1) var tier: int = 1
@export var prerequisites: PackedStringArray = PackedStringArray()
@export var silver_cost: int = 25
@export var duration_seasons: int = 1

@export_group("Deterministic Numeric Bonuses")
@export var melee_attack_bonus: float = 0.0
@export var defense_bonus: float = 0.0
@export var speed_bonus: float = 0.0
@export var water_resilience_bonus: float = 0.0
@export var courier_speed_bonus: float = 0.0
@export var tax_efficiency_bonus: float = 0.0
@export var kut_stability_bonus: float = 0.0
@export var steel_craft_bonus: float = 0.0
@export var effect_summary: String = ""


func get_validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if node_id == &"":
		errors.append("TraditionResearchNode: node_id cannot be empty.")
	if title.is_empty():
		errors.append("TraditionResearchNode '%s': title cannot be empty." % String(node_id))
	if tier < 1 or tier > 4:
		errors.append("TraditionResearchNode '%s': tier must be in [1, 4]." % String(node_id))
	if silver_cost < 0:
		errors.append("TraditionResearchNode '%s': silver_cost cannot be negative." % String(node_id))
	if duration_seasons < 1:
		errors.append("TraditionResearchNode '%s': duration_seasons must be >= 1." % String(node_id))
	var values: Array[float] = [
		melee_attack_bonus, defense_bonus, speed_bonus, water_resilience_bonus,
		courier_speed_bonus, tax_efficiency_bonus, kut_stability_bonus, steel_craft_bonus,
	]
	for v: float in values:
		if is_nan(v) or is_inf(v) or v < 0.0:
			errors.append("TraditionResearchNode '%s': bonus values must be finite and non-negative." % String(node_id))
	return errors
