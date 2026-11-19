class_name WorldEcologyViewModel
extends RefCounted
## UI ViewModel (rank 3). Strictly read-only projection for Phase 29 World,
## Ecology, Sky Constellation (5 Faz 27A resonances), Zud Sundial, Water Ring,
## and Molten Ore / Black-Market Crucible widgets.

var player_id: int = 1
var tracked_army_id: int = 1
var tracked_region: Vector2i = Vector2i.ZERO


class WorldEcologySnapshot:
	var player_id: int = 1
	var army_id: int = 1
	var region_coord: Vector2i = Vector2i.ZERO

	# Sky Constellation (5 Faz 27A Resonances + Causal Links)
	var active_resonances: Array[GameEnums.SynergyResonanceId] = []
	var resonance_active_map: Dictionary[int, bool] = {}
	var effective_combat_power_mult: float = 1.0
	var kut_entropy_net_drift: float = 0.0
	var courier_tempo_mult: float = 1.0
	var coalition_pressure_score: float = 0.0

	# Yaylak / Kışlak Zud Sundial & Poisoned Water Ring
	var season_type: GameEnums.SeasonType = GameEnums.SeasonType.SPRING
	var season_name: String = "İlkbahar"
	var season_index: int = 0
	var is_yaylak_highland: bool = true
	var is_kislak_valley: bool = false
	var food_reserve: int = 120
	var zud_famine_threshold: int = 40
	var is_zud_active: bool = false
	var winter_horizon_seasons: float = 3.0
	var usable_water_sources: int = 0
	var registered_water_sources: int = 0
	var sabotaged_water_sources: int = 0
	var water_purity_ratio: float = 1.0
	var water_logistics_ratio: float = 1.0

	# Molten Ore & Black-Market Crucible
	var iron_stock: int = 0
	var coal_stock: int = 0
	var steel_stock: int = 0
	var silver_stock: int = 0
	var jade_stock: int = 0
	var meteoric_iron_stock: int = 0
	var artisan_quality_factor: float = 1.0
	var black_market_scarcity_mult: float = 1.0
	var market_volume_traded: int = 0
	var camp_migrating: bool = false
	var camp_supply_cut: bool = false
	var yilki_herd_count: int = 0


func _init(
		p_player_id: int = 1,
		p_army_id: int = 1,
		p_region: Vector2i = Vector2i.ZERO) -> void:
	player_id = p_player_id
	tracked_army_id = p_army_id
	tracked_region = p_region


func set_context(p_player_id: int, p_army_id: int, p_region: Vector2i) -> void:
	player_id = p_player_id
	tracked_army_id = p_army_id
	tracked_region = p_region


func capture_snapshot() -> WorldEcologySnapshot:
	var snap: WorldEcologySnapshot = WorldEcologySnapshot.new()
	snap.player_id = player_id
	snap.army_id = tracked_army_id
	snap.region_coord = tracked_region

	var syn: SynergyEvaluationSnapshot = SystemicSynergyMatrix.evaluate_player(
		player_id, tracked_army_id, tracked_region)
	if syn != null:
		snap.active_resonances = syn.active_resonances.duplicate()
		snap.effective_combat_power_mult = syn.effective_combat_power_mult
		snap.kut_entropy_net_drift = syn.kut_entropy_net_drift
		snap.courier_tempo_mult = syn.courier_tempo_mult
		snap.coalition_pressure_score = syn.coalition_pressure_score
		snap.water_logistics_ratio = syn.water_logistics_ratio
		snap.artisan_quality_factor = syn.artisan_quality_factor
		snap.black_market_scarcity_mult = clampf(syn.black_market_scarcity_mult, 1.0, 3.40)

	for rid: int in range(5):
		var enum_id: GameEnums.SynergyResonanceId = rid as GameEnums.SynergyResonanceId
		snap.resonance_active_map[rid] = snap.active_resonances.has(enum_id)

	var season: SeasonData = SeasonManager.get_current_season()
	snap.season_index = syn.season_index if syn != null else 0
	if season != null:
		snap.season_type = season.season_type
		snap.season_name = _format_season_name(season.season_type)
	snap.food_reserve = SeasonManager.get_food_reserve()
	snap.zud_famine_threshold = 40
	snap.is_zud_active = snap.season_type == GameEnums.SeasonType.WINTER and snap.food_reserve <= snap.zud_famine_threshold
	snap.winter_horizon_seasons = clampf(float(snap.food_reserve) / 40.0, 0.0, 12.0)

	var reg: RegionData = TerritoryManager.get_region(tracked_region)
	if reg != null:
		snap.is_yaylak_highland = reg.geography_class == GameEnums.RegionGeographyClass.HIGH_PLATEAU_YAYLAK
		snap.is_kislak_valley = reg.geography_class == GameEnums.RegionGeographyClass.SHELTERED_VALLEY_KISLAK
	else:
		snap.is_yaylak_highland = snap.season_type != GameEnums.SeasonType.WINTER
		snap.is_kislak_valley = snap.season_type == GameEnums.SeasonType.WINTER

	var is_winter_zud: bool = snap.season_type == GameEnums.SeasonType.WINTER
	snap.registered_water_sources = WaterRouteManager.count_registered_water_sources(tracked_region)
	snap.usable_water_sources = WaterRouteManager.count_usable_water_sources(tracked_region, snap.season_type, is_winter_zud)
	snap.sabotaged_water_sources = WaterRouteManager.count_sabotaged_water_sources(tracked_region)
	if snap.registered_water_sources > 0:
		snap.water_purity_ratio = clampf(
			float(maxi(snap.registered_water_sources - snap.sabotaged_water_sources, 0)) / float(snap.registered_water_sources),
			0.0, 1.0)
	else:
		snap.water_purity_ratio = 1.0 if not snap.is_zud_active else 0.5

	snap.iron_stock = ResourceManager.get_amount(player_id, &"iron")
	snap.coal_stock = ResourceManager.get_amount(player_id, &"coal")
	snap.steel_stock = ResourceManager.get_amount(player_id, &"steel")
	snap.silver_stock = ResourceManager.get_amount(player_id, &"silver_gold")
	snap.jade_stock = ResourceManager.get_amount(player_id, &"jade")
	snap.meteoric_iron_stock = ResourceManager.get_amount(player_id, &"meteoric_iron")
	snap.camp_migrating = ResourceManager.is_camp_migrating(player_id)
	snap.camp_supply_cut = ResourceManager.is_camp_supply_cut(player_id)
	snap.yilki_herd_count = RegionalMarketEngine.get_player_yilki_herd(player_id)

	var scarcity: float = RegionalMarketEngine.get_regional_scarcity(tracked_region, &"iron")
	snap.market_volume_traded = maxi(roundi((scarcity - 1.0) * 100.0), 0)

	return snap


static func _format_season_name(s_type: GameEnums.SeasonType) -> String:
	match s_type:
		GameEnums.SeasonType.SPRING:
			return "İlkbahar"
		GameEnums.SeasonType.SUMMER:
			return "Yaz"
		GameEnums.SeasonType.AUTUMN:
			return "Güz"
		GameEnums.SeasonType.WINTER:
			return "Kış (Zud)"
		_:
			return "Mevsim"
