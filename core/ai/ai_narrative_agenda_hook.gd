class_name AINarrativeAgendaHook
extends RefCounted
## Core AI Narrative Hook (rank 2). Injects optional singleplayer story or
## campaign agenda weights into AI utility scoring and scheme priorities without
## granting any simulation cheat.

class NarrativeWeightDirective:
	extends RefCounted
	var has_active_agenda: bool = false
	var agenda_id: StringName = &""
	var triggered_now: bool = false
	var trigger_reason: StringName = &""
	var action_bonuses: Dictionary[int, float] = {}
	var preferred_scheme: GameEnums.AISchemeType = GameEnums.AISchemeType.NONE
	var scheme_bonus: float = 0.0
	var priority_doctrine: int = -1
	var protected_coord: Vector2i = Vector2i(-1, -1)
	var target_coord: Vector2i = Vector2i(-1, -1)
	var wants_break_pact: bool = false


var _agenda: StoryAgendaResource = null
var _triggered_once: bool = false
var _last_reason: StringName = &""


func bind_agenda(agenda: StoryAgendaResource) -> void:
	_agenda = agenda.duplicate_agenda() if agenda != null else null
	_triggered_once = false
	_last_reason = &""


func clear_agenda() -> void:
	_agenda = null
	_triggered_once = false
	_last_reason = &""


func get_agenda() -> StoryAgendaResource:
	return _agenda


func get_agenda_id() -> StringName:
	return _agenda.agenda_id if _agenda != null else &""


func has_triggered() -> bool:
	return _triggered_once


func get_last_reason() -> StringName:
	return _last_reason


func evaluate_directive(ai_player_id: int, target_player_id: int) -> NarrativeWeightDirective:
	var dir: NarrativeWeightDirective = NarrativeWeightDirective.new()
	if _agenda == null or _agenda.agenda_id == &"":
		return dir

	dir.agenda_id = _agenda.agenda_id
	dir.protected_coord = _agenda.protected_region_coord
	dir.target_coord = _agenda.target_region_coord

	var cur_season: SeasonData = SeasonManager.get_current_season()
	var s_type: int = int(cur_season.season_type) if cur_season != null else int(GameEnums.SeasonType.SPRING)
	var target_dread: float = ReputationAndPactSystem.get_dread_score(target_player_id)
	var target_honor: float = ReputationAndPactSystem.get_honor_score(target_player_id)

	var has_conditional_gate: bool = false
	var conditions_met: bool = false
	var reason: StringName = &"story_standing_mandate"

	if _agenda.preferred_season >= 0:
		has_conditional_gate = true
		if s_type == _agenda.preferred_season:
			conditions_met = true
			reason = &"story_seasonal_window"

	if _agenda.trigger_on_target_dread_min >= 0.0:
		has_conditional_gate = true
		if target_dread >= _agenda.trigger_on_target_dread_min:
			conditions_met = true
			reason = &"story_dread_threshold_breached"

	if _agenda.min_honor_floor_to_keep_pact >= 0.0:
		has_conditional_gate = true
		if target_honor < _agenda.min_honor_floor_to_keep_pact:
			conditions_met = true
			reason = &"story_tore_honor_forfeited"

	if _agenda.protected_region_coord.x >= 0 and _agenda.protected_region_coord.y >= 0:
		var prot_reg: RegionData = TerritoryManager.get_region(_agenda.protected_region_coord)
		if prot_reg != null and (prot_reg.owner_id != ai_player_id or prot_reg.control_percent < 85.0):
			conditions_met = true
			reason = &"story_protect_homeland_region"

	var is_active: bool = conditions_met if has_conditional_gate else true
	if not is_active:
		return dir

	dir.has_active_agenda = true
	dir.trigger_reason = reason
	if not _triggered_once:
		_triggered_once = true
		dir.triggered_now = true
	_last_reason = reason

	if _agenda.action_weight_bonus > 0.0:
		var cat_key: int = int(_agenda.preferred_action)
		dir.action_bonuses[cat_key] = dir.action_bonuses.get(cat_key, 0.0) + _agenda.action_weight_bonus

	if _agenda.protected_region_coord.x >= 0 and _agenda.protected_region_coord.y >= 0:
		var fort_key: int = int(GameEnums.AIActionCategory.FORTIFY_AND_SUSTAIN)
		dir.action_bonuses[fort_key] = dir.action_bonuses.get(fort_key, 0.0) + maxf(_agenda.action_weight_bonus * 0.65, 25.0)

	if _agenda.target_region_coord.x >= 0 and _agenda.target_region_coord.y >= 0:
		var sab_key: int = int(GameEnums.AIActionCategory.SABOTAGE_ENEMY_WATER)
		dir.action_bonuses[sab_key] = dir.action_bonuses.get(sab_key, 0.0) + maxf(_agenda.action_weight_bonus * 0.45, 18.0)

	dir.preferred_scheme = _agenda.forced_scheme
	dir.scheme_bonus = _agenda.scheme_weight_bonus
	dir.priority_doctrine = _agenda.priority_doctrine
	dir.wants_break_pact = _agenda.break_pacts_when_triggered and (conditions_met or not has_conditional_gate)
	return dir


func export_state_dict() -> Dictionary:
	return {
		"agenda": _agenda.export_dict() if _agenda != null else {},
		"has_agenda": _agenda != null,
		"last_reason": String(_last_reason),
		"triggered_once": _triggered_once,
	}


func import_state_dict(data: Dictionary) -> bool:
	var has_ag: bool = DeterministicStateHasher.v_bool(data.get("has_agenda", false), false)
	if has_ag:
		var ag_dict: Dictionary = DeterministicStateHasher.v_dict(data.get("agenda", {}))
		if not ag_dict.is_empty():
			_agenda = StoryAgendaResource.from_dict(ag_dict)
		else:
			_agenda = null
	else:
		_agenda = null
	_triggered_once = DeterministicStateHasher.v_bool(data.get("triggered_once", false), false)
	_last_reason = StringName(DeterministicStateHasher.v_str(data.get("last_reason", "")))
	return true
