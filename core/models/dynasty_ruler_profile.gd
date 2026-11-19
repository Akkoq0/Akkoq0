class_name DynastyRulerProfile
extends RefCounted
## Core model (rank 2). Tracks Phase 24 ruling Khagan age, competence,
## designated heir readiness, Amanat hostage lock, regency state, and active
## Kurultay succession crisis claims.

var player_id: int = 1
var ruler_name: StringName = &"Bilge Khagan"
var age_seasons: int = 128 ## 32 years old
var competence: float = 75.0
var is_alive: bool = true
var generation: int = 1

var designated_heir_name: StringName = &"Tigin"
var heir_age_seasons: int = 40 ## 10 years old
var heir_competence: float = 45.0
var heir_held_as_amanat: bool = false
var amanat_pact_id: StringName = &""

var regency_status: GameEnums.RegencyStatus = GameEnums.RegencyStatus.STABLE_RULE
var crisis_id: StringName = &""
var claimant_bey_id: StringName = &""
var contested_territory_coord: Vector2i = Vector2i.ZERO
var last_succession_reason: StringName = &""


func _init(
		p_player_id: int = 1,
		p_ruler_name: StringName = &"Bilge Khagan",
		p_age_seasons: int = 128,
		p_competence: float = 75.0) -> void:
	player_id = p_player_id
	ruler_name = p_ruler_name
	age_seasons = maxi(p_age_seasons, 0)
	competence = clampf(p_competence, 0.0, 100.0)


func get_age_years(seasons_per_year: int = 4) -> int:
	return age_seasons / maxi(seasons_per_year, 1)


func get_heir_age_years(seasons_per_year: int = 4) -> int:
	return heir_age_seasons / maxi(seasons_per_year, 1)


func is_heir_ready(rules: SuccessionRules = null) -> bool:
	if designated_heir_name == &"" or heir_held_as_amanat:
		return false
	var s_per_y: int = rules.seasons_per_year if rules != null else 4
	var majority: int = rules.heir_majority_age_years if rules != null else 18
	var min_comp: float = rules.strong_heir_competence_threshold if rules != null else 55.0
	return get_heir_age_years(s_per_y) >= majority and heir_competence >= min_comp
