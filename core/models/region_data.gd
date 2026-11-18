class_name RegionData
extends RefCounted
## Core model (rank 2). Authoritative Phase 19 strategic macro region holding
## geography class (`Yaylak`, `Kışlak`, `Forest Edge`, `Sacred Core`),
## ownership/control %, Sacred Kurgan hegemony, Scorched Earth state, and
## attached frontier `BorderNode` sites.

var coord: Vector2i = Vector2i.ZERO
var geography_class: GameEnums.RegionGeographyClass = GameEnums.RegionGeographyClass.HIGH_PLATEAU_YAYLAK
var owner_id: int = 0
var vassal_bey_id: StringName = &""
var control_percent: float = 100.0
var is_core_oba: bool = false
var has_sacred_kurgan: bool = false
var kurgan_owner_id: int = 0
var scorched_seasons_remaining: int = 0
var border_nodes: Array[BorderNode] = []


func _init(
		p_coord: Vector2i = Vector2i.ZERO,
		p_geography: GameEnums.RegionGeographyClass = GameEnums.RegionGeographyClass.HIGH_PLATEAU_YAYLAK,
		p_owner_id: int = 0,
		p_is_core_oba: bool = false,
		p_has_sacred_kurgan: bool = false,
		p_control_percent: float = 100.0) -> void:
	coord = p_coord
	geography_class = p_geography
	owner_id = p_owner_id
	is_core_oba = p_is_core_oba
	has_sacred_kurgan = p_has_sacred_kurgan
	kurgan_owner_id = p_owner_id if p_has_sacred_kurgan else 0
	control_percent = clampf(p_control_percent, 0.0, 100.0)


## True when newly conquered / unstable Denetim sits below the rebellion threshold.
func is_rebellion_prone(rules: ConquestRules) -> bool:
	if owner_id <= 0:
		return false
	var threshold: float = rules.low_control_rebellion_threshold if rules != null else 40.0
	return control_percent < threshold


## Effective economic/tax yield multiplier driven by Denetim (%) and Scorched Earth.
func get_effective_yield_multiplier() -> float:
	var ctrl_mult: float = clampf(0.20 + 0.80 * (control_percent / 100.0), 0.20, 1.0)
	if scorched_seasons_remaining > 0:
		ctrl_mult *= 0.35
	return ctrl_mult


## Computes seasonal ecological, supply, attrition, mobility & Kurgan bonuses
## reflecting the authentic Yaylak (Summer highland) vs Kışlak (Winter shelter) shift.
func compute_seasonal_modifiers(season_type: GameEnums.SeasonType, rules: ConquestRules) -> Dictionary[StringName, float]:
	var pasture_regen_mult: float = 1.0
	var yilki_breed_mult: float = 1.0
	var attrition_mult: float = 1.0
	var supply_drain_mult: float = 1.0
	var supply_efficiency_mult: float = 1.0
	var movement_speed_mult: float = 1.0
	var kurgan_kut_bonus: float = 0.0
	var epidemic_resistance: float = 0.0

	var r_yaylak_regen: float = rules.yaylak_warm_regen_mult if rules != null else 1.65
	var r_yaylak_breed: float = rules.yaylak_warm_yilki_breed_mult if rules != null else 1.40
	var r_yaylak_freeze: float = rules.yaylak_winter_freeze_attrition_mult if rules != null else 2.40
	var r_yaylak_winter_sup: float = rules.yaylak_winter_supply_drain_mult if rules != null else 1.80
	var r_kislak_shelter: float = rules.kislak_winter_shelter_attrition_mult if rules != null else 0.55
	var r_kislak_sup: float = rules.kislak_winter_supply_drain_mult if rules != null else 0.65
	var r_kislak_regen: float = rules.kislak_winter_regen_mult if rules != null else 0.50
	var r_kurgan_kut: float = rules.sacred_core_kurgan_kut_per_season if rules != null else 2.0
	var r_kurgan_res: float = rules.sacred_core_epidemic_resistance if rules != null else 0.45
	var r_scorch_spd: float = rules.scorched_earth_speed_penalty_mult if rules != null else 0.60
	var r_scorch_sup: float = rules.scorched_earth_supply_penalty_mult if rules != null else 0.50

	if geography_class == GameEnums.RegionGeographyClass.HIGH_PLATEAU_YAYLAK:
		if season_type == GameEnums.SeasonType.SPRING or season_type == GameEnums.SeasonType.SUMMER:
			pasture_regen_mult = r_yaylak_regen
			yilki_breed_mult = r_yaylak_breed
			attrition_mult = 0.85
			supply_drain_mult = 0.90
		elif season_type == GameEnums.SeasonType.AUTUMN:
			pasture_regen_mult = 1.0
			yilki_breed_mult = 1.0
			attrition_mult = 1.05
			supply_drain_mult = 1.0
		else:
			pasture_regen_mult = 0.15
			yilki_breed_mult = 0.40
			attrition_mult = r_yaylak_freeze
			supply_drain_mult = r_yaylak_winter_sup
			movement_speed_mult = 0.78
	elif geography_class == GameEnums.RegionGeographyClass.SHELTERED_VALLEY_KISLAK:
		if season_type == GameEnums.SeasonType.WINTER:
			pasture_regen_mult = r_kislak_regen
			yilki_breed_mult = 0.85
			attrition_mult = r_kislak_shelter
			supply_drain_mult = r_kislak_sup
			movement_speed_mult = 0.95
		else:
			pasture_regen_mult = 0.90
			yilki_breed_mult = 0.95
			attrition_mult = 0.95
			supply_drain_mult = 0.95
	elif geography_class == GameEnums.RegionGeographyClass.FOREST_EDGE:
		if season_type == GameEnums.SeasonType.WINTER:
			pasture_regen_mult = 0.35
			yilki_breed_mult = 0.75
			attrition_mult = 0.80
			supply_drain_mult = 0.95
			movement_speed_mult = 0.88
		else:
			pasture_regen_mult = 0.95
			yilki_breed_mult = 0.90
			movement_speed_mult = 0.92
	elif geography_class == GameEnums.RegionGeographyClass.SACRED_CORE:
		if season_type == GameEnums.SeasonType.WINTER:
			pasture_regen_mult = 0.40
			attrition_mult = 0.85
			supply_drain_mult = 0.90

	if has_sacred_kurgan:
		kurgan_kut_bonus = r_kurgan_kut
		epidemic_resistance = r_kurgan_res

	if scorched_seasons_remaining > 0:
		movement_speed_mult *= r_scorch_spd
		supply_efficiency_mult *= r_scorch_sup
		supply_drain_mult *= (1.0 / maxf(r_scorch_sup, 0.10))
		pasture_regen_mult *= 0.25

	return {
		&"pasture_regen_mult": pasture_regen_mult,
		&"yilki_breed_mult": yilki_breed_mult,
		&"attrition_mult": attrition_mult,
		&"supply_drain_mult": supply_drain_mult,
		&"supply_efficiency_mult": supply_efficiency_mult,
		&"movement_speed_mult": movement_speed_mult,
		&"kurgan_kut_bonus": kurgan_kut_bonus,
		&"epidemic_resistance": epidemic_resistance,
	}
