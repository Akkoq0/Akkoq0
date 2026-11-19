class_name StoryAgendaResource
extends Resource
## Data layer (rank 1). Optional future Campaign/Scenario Narrative Agenda Hook
## resource allowing story missions to inject deterministic weights, seasonal
## raid windows, region protections, or Dread/Töre betrayal triggers into AI.

@export var agenda_id: StringName = &"steppe_story_agenda"
@export var title: String = "Bozkır Sefer Hedefi"
@export var description: String = ""

@export_group("Regional & Seasonal Focus")
@export var protected_region_coord: Vector2i = Vector2i(-1, -1)
@export var target_region_coord: Vector2i = Vector2i(-1, -1)
@export_range(-1, 3, 1) var preferred_season: int = -1

@export_group("Dread / Töre / Betrayal Thresholds")
@export_range(-1.0, 100.0, 1.0) var trigger_on_target_dread_min: float = -1.0
@export_range(-1.0, 100.0, 1.0) var min_honor_floor_to_keep_pact: float = -1.0
@export var break_pacts_when_triggered: bool = false

@export_group("Utility & Scheme Weight Injection")
@export var preferred_action: GameEnums.AIActionCategory = GameEnums.AIActionCategory.HOLD_AND_GATHER
@export var forced_scheme: GameEnums.AISchemeType = GameEnums.AISchemeType.NONE
@export_range(0.0, 200.0, 1.0) var action_weight_bonus: float = 0.0
@export_range(0.0, 200.0, 1.0) var scheme_weight_bonus: float = 0.0
@export_range(-1, 4, 1) var priority_doctrine: int = -1


func duplicate_agenda() -> StoryAgendaResource:
	var copy: StoryAgendaResource = StoryAgendaResource.new()
	copy.agenda_id = agenda_id
	copy.title = title
	copy.description = description
	copy.protected_region_coord = protected_region_coord
	copy.target_region_coord = target_region_coord
	copy.preferred_season = preferred_season
	copy.trigger_on_target_dread_min = trigger_on_target_dread_min
	copy.min_honor_floor_to_keep_pact = min_honor_floor_to_keep_pact
	copy.break_pacts_when_triggered = break_pacts_when_triggered
	copy.preferred_action = preferred_action
	copy.forced_scheme = forced_scheme
	copy.action_weight_bonus = action_weight_bonus
	copy.scheme_weight_bonus = scheme_weight_bonus
	copy.priority_doctrine = priority_doctrine
	return copy


func get_validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if agenda_id == &"":
		errors.append("StoryAgendaResource: agenda_id cannot be empty.")
	if preferred_season < -1 or preferred_season > 3:
		errors.append("StoryAgendaResource: preferred_season must be -1..3.")
	if action_weight_bonus < 0.0 or scheme_weight_bonus < 0.0:
		errors.append("StoryAgendaResource: weight bonuses cannot be negative.")
	return errors


func export_dict() -> Dictionary:
	return {
		"action_weight_bonus": action_weight_bonus,
		"agenda_id": String(agenda_id),
		"break_pacts_when_triggered": break_pacts_when_triggered,
		"description": description,
		"forced_scheme": int(forced_scheme),
		"min_honor_floor_to_keep_pact": min_honor_floor_to_keep_pact,
		"preferred_action": int(preferred_action),
		"preferred_season": preferred_season,
		"priority_doctrine": priority_doctrine,
		"protected_region_x": protected_region_coord.x,
		"protected_region_y": protected_region_coord.y,
		"scheme_weight_bonus": scheme_weight_bonus,
		"target_region_x": target_region_coord.x,
		"target_region_y": target_region_coord.y,
		"title": title,
		"trigger_on_target_dread_min": trigger_on_target_dread_min,
	}


static func from_dict(data: Dictionary) -> StoryAgendaResource:
	var agenda: StoryAgendaResource = StoryAgendaResource.new()
	agenda.agenda_id = StringName(str(data.get("agenda_id", "steppe_story_agenda")))
	agenda.title = str(data.get("title", "Bozkır Sefer Hedefi"))
	agenda.description = str(data.get("description", ""))
	agenda.protected_region_coord = Vector2i(
		str(data.get("protected_region_x", -1)).to_int(),
		str(data.get("protected_region_y", -1)).to_int())
	agenda.target_region_coord = Vector2i(
		str(data.get("target_region_x", -1)).to_int(),
		str(data.get("target_region_y", -1)).to_int())
	agenda.preferred_season = clampi(str(data.get("preferred_season", -1)).to_int(), -1, 3)
	agenda.trigger_on_target_dread_min = str(data.get("trigger_on_target_dread_min", -1.0)).to_float()
	agenda.min_honor_floor_to_keep_pact = str(data.get("min_honor_floor_to_keep_pact", -1.0)).to_float()
	var break_var: Variant = data.get("break_pacts_when_triggered", false)
	if typeof(break_var) == TYPE_BOOL:
		var break_flag: bool = break_var
		agenda.break_pacts_when_triggered = break_flag
	else:
		agenda.break_pacts_when_triggered = str(break_var) == "true" or str(break_var).to_int() != 0
	var pref_action_int: int = clampi(str(data.get("preferred_action", 0)).to_int(), 0, 9)
	agenda.preferred_action = pref_action_int as GameEnums.AIActionCategory
	var scheme_int: int = clampi(str(data.get("forced_scheme", 0)).to_int(), 0, 3)
	agenda.forced_scheme = scheme_int as GameEnums.AISchemeType
	agenda.action_weight_bonus = clampf(str(data.get("action_weight_bonus", 0.0)).to_float(), 0.0, 200.0)
	agenda.scheme_weight_bonus = clampf(str(data.get("scheme_weight_bonus", 0.0)).to_float(), 0.0, 200.0)
	agenda.priority_doctrine = clampi(str(data.get("priority_doctrine", -1)).to_int(), -1, 4)
	return agenda
