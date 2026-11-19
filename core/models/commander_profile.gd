class_name CommanderProfile
extends RefCounted
## Core model (rank 2). Tracks Phase 24 military commander aging, campaign
## veteran score, battle scars, trait specialization, and Turan tactical/rout
## multipliers.

var commander_id: int = 1
var player_id: int = 1
var assigned_army_id: int = 1
var commander_name: StringName = &"Kul Tigin"
var age_seasons: int = 104 ## 26 years old
var veteran_score: float = 0.0
var leadership: float = 65.0
var scars: int = 0
var commander_trait: GameEnums.CommanderTrait = GameEnums.CommanderTrait.NONE
var is_alive: bool = true
var held_as_amanat: bool = false


func _init(
		p_commander_id: int = 1,
		p_player_id: int = 1,
		p_army_id: int = 1,
		p_name: StringName = &"Kul Tigin",
		p_age_seasons: int = 104,
		p_trait: GameEnums.CommanderTrait = GameEnums.CommanderTrait.NONE) -> void:
	commander_id = p_commander_id
	player_id = p_player_id
	assigned_army_id = p_army_id
	commander_name = p_name
	age_seasons = maxi(p_age_seasons, 0)
	commander_trait = p_trait


func get_age_years(seasons_per_year: int = 4) -> int:
	return age_seasons / maxi(seasons_per_year, 1)


func get_turan_speed_multiplier(rules: SuccessionRules = null) -> float:
	if not is_alive:
		return 0.72
	var per_vet: float = rules.commander_turan_bonus_per_vet if rules != null else 0.015
	var max_b: float = rules.commander_turan_bonus_max if rules != null else 0.25
	var scar_pen: float = rules.veteran_scar_speed_penalty if rules != null else 0.06
	var vet_bonus: float = clampf(veteran_score * per_vet * 0.25, 0.0, max_b)
	if commander_trait == GameEnums.CommanderTrait.BOZKIR_KURDU:
		vet_bonus += 0.12
	elif commander_trait == GameEnums.CommanderTrait.SAGIR_YARA:
		vet_bonus -= 0.04
	var age_years: int = get_age_years(rules.seasons_per_year if rules != null else 4)
	var old_decline: float = maxf(float(age_years - 58) * 0.01, 0.0)
	var total_scar_pen: float = float(maxi(scars, 0)) * scar_pen
	return clampf(1.0 + vet_bonus - total_scar_pen - old_decline, 0.70, 1.45)


func get_cascade_rout_resistance(rules: SuccessionRules = null) -> float:
	if not is_alive:
		return 0.0
	var per_vet: float = rules.commander_rout_resistance_per_vet if rules != null else 0.008
	var max_r: float = rules.commander_rout_resistance_max if rules != null else 0.40
	var base_r: float = clampf(veteran_score * per_vet * 0.20, 0.0, max_r)
	if commander_trait == GameEnums.CommanderTrait.BORU_YUREK:
		base_r += 0.15
	elif commander_trait == GameEnums.CommanderTrait.SAGIR_YARA:
		base_r += 0.10
	base_r += clampf(float(scars) * 0.04, 0.0, 0.15)
	return clampf(base_r, 0.0, 0.55)


func get_scar_combat_bonus(rules: SuccessionRules = null) -> float:
	if not is_alive:
		return -0.15
	var bonus_per_scar: float = rules.veteran_scar_combat_bonus if rules != null else 0.10
	return clampf(float(maxi(scars, 0)) * bonus_per_scar, 0.0, 0.35)
