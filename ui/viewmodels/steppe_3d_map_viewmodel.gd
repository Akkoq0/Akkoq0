class_name Steppe3DMapViewModel
extends RefCounted
## UI ViewModel (rank 4). Strictly read-only 3D world projection combining
## MacroWorldState, TerritoryManager, WaterRouteManager, PastureEcologyManager,
## RegionalMarketEngine, SeasonManager, CombatCalculator, CourierDispatchSystem,
## CaravanLogisticsManager, SystemicSynergyMatrix, SessionClockAuthority, and
## WeakRef-tracked ArmyRegistry divisions. Never mutates simulation state.

const DEFAULT_REGION_SIZE_M: float = 16.0
const DEFAULT_GRID_SIZE: Vector2i = Vector2i(8, 8)


class RegionVisualEntry:
	var coord: Vector2i = Vector2i.ZERO
	var world_center: Vector3 = Vector3.ZERO
	var tile_size_m: float = 16.0
	var elevation: float = 0.2
	var base_terrain_color: Color = Color(0.45, 0.50, 0.32, 1.0)
	var geography_class: GameEnums.RegionGeographyClass = GameEnums.RegionGeographyClass.HIGH_PLATEAU_YAYLAK
	var owner_id: int = 0
	var vassal_bey_id: StringName = &""
	var control_percent: float = 100.0
	var has_sacred_kurgan: bool = false
	var scorched_seasons_remaining: int = 0
	var active_cataclysm_id: StringName = &""
	var water_usable_count: int = 0
	var water_sabotaged_count: int = 0
	var market_scarcity_mult: float = 1.0
	var black_market_mult: float = 1.0
	var pasture_capacity: float = 100.0
	var tug_radius_m: float = 0.0
	var caravan_disruption: float = 0.0
	var lens_color: Color = Color.WHITE
	var highlight_height_m: float = 0.0
	var is_selected: bool = false


class ArmyVisualEntry:
	var army_id: int = 0
	var owner_id: int = 0
	var world_position: Vector3 = Vector3.ZERO
	var facing_rad: float = 0.0
	var doctrine_id: StringName = &""
	var doctrine_preset: GameEnums.BattleDoctrinePresetId = GameEnums.BattleDoctrinePresetId.KURT_KAPANI
	var decisive_maneuver: GameEnums.DecisiveManeuver = GameEnums.DecisiveManeuver.KURT_KAPANI_FEIGNED_RETREAT
	var is_heavy_armor: bool = false
	var center_ratio: float = 0.25
	var flank_ratio: float = 0.50
	var reserve_ratio: float = 0.25
	var formation_shape: StringName = &"hilal"
	var dust_screen_active: bool = false
	var plan_exposed: bool = false
	var supply_isolated: bool = false
	var supply_ratio: float = 1.0
	var rider_count: int = 0
	var is_selected: bool = false


class RouteMarkerEntry:
	var entity_id: StringName = &""
	var kind: StringName = &"caravan"
	var owner_id: int = 0
	var origin_pos: Vector3 = Vector3.ZERO
	var dest_pos: Vector3 = Vector3.ZERO
	var current_pos: Vector3 = Vector3.ZERO
	var progress_ratio: float = 0.0
	var status_tag: StringName = &"en_route"


class WaterVisualEntry:
	var source_id: StringName = &""
	var coord: Vector2i = Vector2i.ZERO
	var world_pos: Vector3 = Vector3.ZERO
	var usable: bool = true
	var sabotaged: bool = false
	var frozen_in_winter: bool = false


class TugRingEntry:
	var node_id: StringName = &""
	var owner_id: int = 0
	var world_pos: Vector3 = Vector3.ZERO
	var radius_m: float = 20.0
	var overlapping_enemy: bool = false


class MapSnapshot:
	var player_id: int = 1
	var selected_army_id: int = 1
	var selected_region_coord: Vector2i = Vector2i.ZERO
	var has_selected_region: bool = false
	var active_lens: GameEnums.TacticalMapLens = GameEnums.TacticalMapLens.NORMAL
	var season_type: GameEnums.SeasonType = GameEnums.SeasonType.SPRING
	var food_reserve: int = 120
	var is_zud_active: bool = false
	var sun_light_color: Color = Color(1.0, 0.96, 0.88, 1.0)
	var sun_light_energy: float = 1.15
	var session_mode: GameEnums.SessionMode = GameEnums.SessionMode.SINGLEPLAYER_SESSION
	var is_paused: bool = false
	var speed_scale: float = 1.0
	var current_tick: int = 0
	var online_pause_rejected: bool = false
	var kut_score: float = 75.0
	var synergy_resonances_count: int = 0
	var synergy_primary_resonance: String = "Yok"
	var black_market_synergy_mult: float = 1.0
	var coalition_pressure: float = 0.0
	var effective_combat_power_mult: float = 1.0
	var lens_summary_text: String = ""
	var regions: Array[RegionVisualEntry] = []
	var armies: Array[ArmyVisualEntry] = []
	var routes: Array[RouteMarkerEntry] = []
	var water_nodes: Array[WaterVisualEntry] = []
	var tug_rings: Array[TugRingEntry] = []


var _player_id: int = 1
var _selected_army_id: int = 1
var _selected_region_coord: Vector2i = Vector2i.ZERO
var _has_selected_region: bool = false
var _active_lens: GameEnums.TacticalMapLens = GameEnums.TacticalMapLens.NORMAL
var _world_state: MacroWorldState = null
var _army_registry_ref: WeakRef = null


func _init(p_player_id: int = 1, p_army_id: int = 1) -> void:
	_player_id = maxi(p_player_id, 1)
	_selected_army_id = maxi(p_army_id, 1)


func set_player_context(p_player_id: int, p_army_id: int = -1) -> void:
	_player_id = maxi(p_player_id, 1)
	if p_army_id > 0:
		_selected_army_id = p_army_id


func set_selected_region(coord: Vector2i, has_selection: bool = true) -> void:
	_selected_region_coord = coord
	_has_selected_region = has_selection


func set_selected_army(army_id: int) -> void:
	if army_id > 0:
		_selected_army_id = army_id


func set_active_lens(lens: GameEnums.TacticalMapLens) -> void:
	_active_lens = lens


func set_macro_world_state(world_state: MacroWorldState) -> void:
	_world_state = world_state


func bind_army_registry(registry: ArmyRegistry) -> void:
	_army_registry_ref = weakref(registry) if registry != null else null


func get_region_size_m() -> float:
	if _world_state != null and _world_state.region_size_m > 0.0:
		return _world_state.region_size_m
	return DEFAULT_REGION_SIZE_M


func coord_to_world_pos(coord: Vector2i) -> Vector3:
	if _world_state != null:
		return _world_state.coord_to_world(coord)
	var size_m: float = DEFAULT_REGION_SIZE_M
	return Vector3(
		(float(coord.x) + 0.5 - float(DEFAULT_GRID_SIZE.x) * 0.5) * size_m,
		0.0,
		(float(coord.y) + 0.5 - float(DEFAULT_GRID_SIZE.y) * 0.5) * size_m)


func world_pos_to_coord(world_pos: Vector3) -> Vector2i:
	if _world_state != null:
		return _world_state.world_to_coord(world_pos)
	var size_m: float = DEFAULT_REGION_SIZE_M
	var gx: int = floori(world_pos.x / size_m + float(DEFAULT_GRID_SIZE.x) * 0.5)
	var gz: int = floori(world_pos.z / size_m + float(DEFAULT_GRID_SIZE.y) * 0.5)
	return Vector2i(gx, gz)


func capture_snapshot() -> MapSnapshot:
	var snap: MapSnapshot = MapSnapshot.new()
	snap.player_id = _player_id
	snap.selected_army_id = _selected_army_id
	snap.selected_region_coord = _selected_region_coord
	snap.has_selected_region = _has_selected_region
	snap.active_lens = _active_lens

	var cur_season: SeasonData = SeasonManager.get_current_season()
	snap.season_type = cur_season.season_type if cur_season != null else GameEnums.SeasonType.SPRING
	snap.food_reserve = SeasonManager.get_food_reserve()
	var is_winter: bool = snap.season_type == GameEnums.SeasonType.WINTER
	snap.is_zud_active = is_winter and snap.food_reserve <= 40
	snap.sun_light_color = _resolve_sun_color(snap.season_type, snap.is_zud_active)
	snap.sun_light_energy = _resolve_sun_energy(snap.season_type, snap.is_zud_active)

	snap.session_mode = SessionClockAuthority.get_session_mode()
	snap.is_paused = SessionClockAuthority.is_paused()
	snap.speed_scale = SessionClockAuthority.get_speed_scale()
	snap.current_tick = SessionClockAuthority.get_current_tick()
	snap.online_pause_rejected = SessionClockAuthority.get_last_pause_rejection_code() == &"REJECTED_PAUSE_IN_ONLINE"
	snap.kut_score = GameManager.get_kut_score()

	var focus_coord: Vector2i = _selected_region_coord if _has_selected_region else PastureEcologyManager.get_player_camp_region(_player_id)
	var syn: SynergyEvaluationSnapshot = SystemicSynergyMatrix.evaluate_player(
		_player_id, _selected_army_id, focus_coord, false)
	if syn != null:
		snap.synergy_resonances_count = syn.get_resonance_count()
		snap.synergy_primary_resonance = syn.get_primary_resonance_label()
		snap.black_market_synergy_mult = clampf(syn.black_market_scarcity_mult, 1.0, 3.40)
		snap.coalition_pressure = syn.coalition_pressure_score
		snap.effective_combat_power_mult = syn.effective_combat_power_mult

	var coord_seen: Dictionary[Vector2i, bool] = {}
	var sim_by_coord: Dictionary[Vector2i, RegionData] = {}
	for r_data: RegionData in TerritoryManager.get_all_regions():
		if r_data != null:
			sim_by_coord[r_data.coord] = r_data

	var tile_size: float = get_region_size_m()
	if _world_state != null:
		for m_reg: MacroRegion in _world_state.get_regions():
			if m_reg == null:
				continue
			coord_seen[m_reg.coord] = true
			var sim_reg: RegionData = sim_by_coord.get(m_reg.coord, null)
			var base_col: Color = m_reg.terrain.debug_color if m_reg.terrain != null else Color(0.45, 0.50, 0.32, 1.0)
			snap.regions.append(_build_region_entry(
				m_reg.coord, m_reg.world_center, tile_size, m_reg.elevation, base_col, sim_reg, snap))

	for sim_coord: Vector2i in sim_by_coord:
		if coord_seen.has(sim_coord):
			continue
		var sim_reg: RegionData = sim_by_coord[sim_coord]
		var fallback_col: Color = Color(0.32, 0.52, 0.36, 1.0) if sim_reg.geography_class == GameEnums.RegionGeographyClass.HIGH_PLATEAU_YAYLAK else Color(0.28, 0.42, 0.50, 1.0)
		snap.regions.append(_build_region_entry(
			sim_coord, coord_to_world_pos(sim_coord), tile_size, 0.25, fallback_col, sim_reg, snap))

	# BorderNode Tug spheres
	for b_node: BorderNode in TerritoryManager.get_all_border_nodes():
		if b_node == null or not b_node.has_tug_planted:
			continue
		var ring: TugRingEntry = TugRingEntry.new()
		ring.node_id = b_node.node_id
		ring.owner_id = b_node.owner_id
		ring.world_pos = b_node.position
		ring.radius_m = maxf(b_node.tug_radius_m, 8.0)
		ring.overlapping_enemy = TerritoryManager.get_overlapping_enemy_tugs(b_node.node_id) > 0
		snap.tug_rings.append(ring)

	# Water Route nodes
	for w_node: WaterSourceNode in WaterRouteManager.get_all_water_sources():
		if w_node == null:
			continue
		var w_entry: WaterVisualEntry = WaterVisualEntry.new()
		w_entry.source_id = w_node.source_id
		w_entry.coord = w_node.region_coord
		w_entry.world_pos = coord_to_world_pos(w_node.region_coord) + Vector3(2.4, 0.6, -2.4)
		w_entry.sabotaged = w_node.contaminated_seasons_remaining > 0
		w_entry.frozen_in_winter = is_winter and w_node.source_type == GameEnums.WaterSourceType.STEPPE_STREAM
		w_entry.usable = w_node.is_usable(is_winter)
		snap.water_nodes.append(w_entry)

	# Armies tracked from ArmyRegistry via WeakRef
	var reg_obj: Object = _army_registry_ref.get_ref() if _army_registry_ref != null else null
	var reg: ArmyRegistry = reg_obj as ArmyRegistry
	if reg != null:
		for army: ArmyController in reg.get_all_armies():
			if army == null or not is_instance_valid(army):
				continue
			snap.armies.append(_build_army_entry(army, snap))

	# Active Physical Caravans
	for conv: PhysicalCaravan in CaravanLogisticsManager.get_all_caravans():
		if conv == null:
			continue
		if conv.state == GameEnums.CaravanCargoState.EN_ROUTE or conv.state == GameEnums.CaravanCargoState.INTERCEPTED:
			var r_entry: RouteMarkerEntry = RouteMarkerEntry.new()
			r_entry.entity_id = conv.caravan_id
			r_entry.kind = &"caravan"
			r_entry.owner_id = conv.owner_id
			r_entry.origin_pos = coord_to_world_pos(conv.origin_coord)
			r_entry.dest_pos = coord_to_world_pos(conv.dest_coord)
			var tot_c: float = maxf(conv.total_travel_sec, 0.001)
			r_entry.progress_ratio = clampf(1.0 - (conv.remaining_travel_sec / tot_c), 0.0, 1.0)
			r_entry.current_pos = r_entry.origin_pos.lerp(r_entry.dest_pos, r_entry.progress_ratio)
			r_entry.status_tag = &"intercepted" if conv.state == GameEnums.CaravanCargoState.INTERCEPTED else &"en_route"
			snap.routes.append(r_entry)

	# Active Couriers
	for ord: CourierDispatchOrder in CourierDispatchSystem.get_all_orders():
		if ord == null:
			continue
		if ord.status == GameEnums.CourierStatus.IN_TRANSIT or ord.status == GameEnums.CourierStatus.AMBUSHED_LOST:
			var c_entry: RouteMarkerEntry = RouteMarkerEntry.new()
			c_entry.entity_id = ord.order_id
			c_entry.kind = &"courier"
			c_entry.owner_id = ord.player_id
			c_entry.origin_pos = ord.origin_pos
			c_entry.dest_pos = ord.target_pos
			var tot_d: float = maxf(ord.total_delay_sec, 0.001)
			c_entry.progress_ratio = clampf(1.0 - (ord.remaining_delay_sec / tot_d), 0.0, 1.0)
			c_entry.current_pos = ord.origin_pos.lerp(ord.target_pos, c_entry.progress_ratio)
			c_entry.status_tag = &"ambushed" if ord.status == GameEnums.CourierStatus.AMBUSHED_LOST else &"en_route"
			snap.routes.append(c_entry)

	snap.lens_summary_text = format_lens_summary(snap)
	return snap


func _build_region_entry(
		coord: Vector2i,
		center: Vector3,
		tile_size: float,
		elevation: float,
		base_col: Color,
		sim_reg: RegionData,
		snap: MapSnapshot) -> RegionVisualEntry:
	var entry: RegionVisualEntry = RegionVisualEntry.new()
	entry.coord = coord
	entry.world_center = center
	entry.tile_size_m = tile_size
	entry.elevation = elevation
	entry.base_terrain_color = base_col
	entry.is_selected = snap.has_selected_region and coord == snap.selected_region_coord

	var is_winter: bool = snap.season_type == GameEnums.SeasonType.WINTER
	if sim_reg != null:
		entry.geography_class = sim_reg.geography_class
		entry.owner_id = sim_reg.owner_id
		entry.vassal_bey_id = sim_reg.vassal_bey_id
		entry.control_percent = sim_reg.control_percent
		entry.has_sacred_kurgan = sim_reg.has_sacred_kurgan
		entry.scorched_seasons_remaining = sim_reg.scorched_seasons_remaining
		entry.tug_radius_m = TerritoryManager.compute_effective_tug_radius(sim_reg.owner_id) if sim_reg.owner_id > 0 else 0.0
		entry.caravan_disruption = TerritoryManager.get_caravan_disruption_in_region(coord, sim_reg.owner_id) if sim_reg.owner_id > 0 else 0.0
	else:
		entry.geography_class = GameEnums.RegionGeographyClass.HIGH_PLATEAU_YAYLAK if elevation >= 0.45 else GameEnums.RegionGeographyClass.SHELTERED_VALLEY_KISLAK

	var cat: CataclysmEventData = CataclysmEngine.get_active_region_cataclysm(coord)
	entry.active_cataclysm_id = cat.cataclysm_id if cat != null else &""
	entry.water_usable_count = WaterRouteManager.count_usable_water_sources(coord, snap.season_type, is_winter)
	entry.water_sabotaged_count = WaterRouteManager.count_sabotaged_water_sources(coord)
	entry.market_scarcity_mult = RegionalMarketEngine.get_regional_scarcity(coord, &"iron")
	entry.black_market_mult = snap.black_market_synergy_mult
	entry.pasture_capacity = PastureEcologyManager.get_region_pasture_capacity(coord)
	entry.lens_color = _compute_lens_tile_color(entry, snap)
	entry.highlight_height_m = _compute_lens_highlight_height(entry, snap)
	return entry


func _build_army_entry(army: ArmyController, snap: MapSnapshot) -> ArmyVisualEntry:
	var entry: ArmyVisualEntry = ArmyVisualEntry.new()
	entry.army_id = army.army_id
	entry.owner_id = army.owner_id
	entry.world_position = army.global_position if army.is_inside_tree() else army.position
	entry.facing_rad = army.rotation.y
	entry.is_selected = army.army_id == snap.selected_army_id
	entry.dust_screen_active = CourierDispatchSystem.has_dust_decoy(army.army_id)
	entry.plan_exposed = CourierDispatchSystem.is_player_plan_exposed_by_courier(army.owner_id, army.army_id)
	entry.supply_isolated = CommandBus.is_army_supply_isolated(army.army_id)
	if army.supply != null:
		entry.supply_ratio = army.supply.get_supply_ratio()
	entry.rider_count = CommandBus.get_army_rider_count(army.army_id)

	var doc: BattleDoctrineResource = CombatCalculator.get_assigned_doctrine(army.army_id)
	if doc != null:
		entry.doctrine_id = doc.doctrine_id
		entry.doctrine_preset = doc.preset_id
		entry.decisive_maneuver = doc.decisive_maneuver
		entry.is_heavy_armor = doc.is_heavy_armor_doctrine
		entry.center_ratio = doc.center_ratio
		entry.flank_ratio = doc.flank_ratio
		entry.reserve_ratio = doc.reserve_ratio
	entry.formation_shape = map_maneuver_to_shape(entry.decisive_maneuver, entry.doctrine_preset)
	return entry


static func map_maneuver_to_shape(
		maneuver: GameEnums.DecisiveManeuver,
		preset: GameEnums.BattleDoctrinePresetId) -> StringName:
	if maneuver == GameEnums.DecisiveManeuver.BORU_HEAVY_WEDGE or preset == GameEnums.BattleDoctrinePresetId.BORU_KAMASI:
		return &"kama"
	if maneuver == GameEnums.DecisiveManeuver.WAGON_CIRCLE_LAAGER or preset == GameEnums.BattleDoctrinePresetId.ARABA_KALESI:
		return &"cember"
	if maneuver == GameEnums.DecisiveManeuver.TONYUKUK_WATER_CARAVAN_ATTRITION or preset == GameEnums.BattleDoctrinePresetId.TONYUKUK_YIPRATMASI:
		return &"yipratma"
	return &"hilal"


func _compute_lens_tile_color(reg: RegionVisualEntry, snap: MapSnapshot) -> Color:
	var col: Color = reg.base_terrain_color
	var is_winter: bool = snap.season_type == GameEnums.SeasonType.WINTER

	match snap.active_lens:
		GameEnums.TacticalMapLens.NORMAL:
			# Territory/Sovereignty + climate blend
			if is_winter:
				col = col.lerp(NeoSteppePalette.ICE_FROST, 0.36 if snap.is_zud_active else 0.22)
			elif snap.season_type == GameEnums.SeasonType.AUTUMN:
				col = col.lerp(NeoSteppePalette.GOLD_TAMGA, 0.16)
			if reg.owner_id == snap.player_id:
				var own_tint: Color = NeoSteppePalette.GOLD_TAMGA if reg.vassal_bey_id != &"" else NeoSteppePalette.JADE_PRIMARY
				col = col.lerp(own_tint, 0.48)
			elif reg.owner_id > 0:
				col = col.lerp(NeoSteppePalette.EMBER_RED, 0.45)
		GameEnums.TacticalMapLens.LOGISTICS_WATER_COURIER:
			# Water / Supply lens
			col = col.lerp(NeoSteppePalette.CHARCOAL_SURFACE, 0.55)
			if reg.water_sabotaged_count > 0:
				col = NeoSteppePalette.EMBER_RED
			elif reg.water_usable_count > 0:
				col = NeoSteppePalette.ICE_BLUE
			elif reg.caravan_disruption > 0.1:
				col = NeoSteppePalette.EMBER_BRIGHT
		GameEnums.TacticalMapLens.YAYLAK_KISLAK:
			# Seasonal Ecology & Market/Black-Market scarcity lens
			if reg.geography_class == GameEnums.RegionGeographyClass.HIGH_PLATEAU_YAYLAK:
				col = NeoSteppePalette.ICE_FROST if is_winter else NeoSteppePalette.JADE_BRIGHT
			elif reg.geography_class == GameEnums.RegionGeographyClass.SHELTERED_VALLEY_KISLAK:
				col = NeoSteppePalette.ICE_BLUE if is_winter else NeoSteppePalette.JADE_DARK
			elif reg.geography_class == GameEnums.RegionGeographyClass.SACRED_CORE:
				col = NeoSteppePalette.GOLD_TAMGA
			else:
				col = Color(0.24, 0.44, 0.30, 1.0)
			if reg.market_scarcity_mult > 1.25:
				var heat: float = clampf((reg.market_scarcity_mult - 1.0) / 1.5, 0.0, 1.0)
				col = col.lerp(NeoSteppePalette.EMBER_BRIGHT, heat * 0.65)
		GameEnums.TacticalMapLens.TUG_CONTROL:
			# Doctrine / Threat / Sovereignty Control lens
			col = col.lerp(NeoSteppePalette.OBSIDIAN_DEEP, 0.45)
			if reg.owner_id == snap.player_id:
				if reg.control_percent < 40.0:
					col = NeoSteppePalette.EMBER_RED
				elif reg.vassal_bey_id != &"":
					col = NeoSteppePalette.GOLD_TAMGA
				else:
					col = NeoSteppePalette.JADE_PRIMARY.lerp(NeoSteppePalette.JADE_BRIGHT, reg.control_percent / 100.0)
			elif reg.owner_id > 0:
				col = NeoSteppePalette.EMBER_RED
		GameEnums.TacticalMapLens.INTELLIGENCE_DUST:
			# Intelligence, Toz Perdesi & Synergy/Resonance lens
			col = col.lerp(NeoSteppePalette.OBSIDIAN_DEEP, 0.72)
			if snap.synergy_resonances_count > 0 and reg.owner_id == snap.player_id:
				col = NeoSteppePalette.JADE_BRIGHT.lerp(NeoSteppePalette.GOLD_TAMGA, clampf(float(snap.synergy_resonances_count) / 5.0, 0.2, 1.0))
			elif reg.active_cataclysm_id != &"":
				col = NeoSteppePalette.EMBER_RED

	if reg.scorched_seasons_remaining > 0:
		col = col.lerp(Color(0.12, 0.08, 0.08, 1.0), 0.70)
	if reg.is_selected:
		col = col.lerp(NeoSteppePalette.GOLD_PALE, 0.55)
	return col


static func _compute_lens_highlight_height(reg: RegionVisualEntry, snap: MapSnapshot) -> float:
	if reg.is_selected:
		return 0.45
	if snap.active_lens == GameEnums.TacticalMapLens.TUG_CONTROL and reg.owner_id > 0:
		return 0.25
	if snap.active_lens == GameEnums.TacticalMapLens.YAYLAK_KISLAK and reg.market_scarcity_mult > 1.25:
		return clampf((reg.market_scarcity_mult - 1.0) * 0.6, 0.1, 1.2)
	return 0.0


static func format_lens_summary(snap: MapSnapshot) -> String:
	match snap.active_lens:
		GameEnums.TacticalMapLens.NORMAL:
			return "Mercek 1 [Egemenlik/Toprak] · Bölge %d · Zud %s" % [
				snap.regions.size(), "AKTİF" if snap.is_zud_active else "Yok"]
		GameEnums.TacticalMapLens.LOGISTICS_WATER_COURIER:
			return "Mercek 2 [Su/İkmal & Kervan] · Su %d · Hat %d" % [
				snap.water_nodes.size(), snap.routes.size()]
		GameEnums.TacticalMapLens.YAYLAK_KISLAK:
			return "Mercek 3 [Yaylak/Kışlak & Kara Borsa] · Sinerji %.2fx" % snap.black_market_synergy_mult
		GameEnums.TacticalMapLens.TUG_CONTROL:
			return "Mercek 4 [Tuğ/Savaş Nizamı & Tehdit] · Tuğ %d · Ordu %d" % [
				snap.tug_rings.size(), snap.armies.size()]
		GameEnums.TacticalMapLens.INTELLIGENCE_DUST:
			return "Mercek 5 [İstihbarat/Toz & Rezonans] · %d/5 (%s)" % [
				snap.synergy_resonances_count, snap.synergy_primary_resonance]
		_:
			return "Mercek"


static func _resolve_sun_color(season: GameEnums.SeasonType, is_zud: bool) -> Color:
	if is_zud:
		return Color(0.66, 0.78, 0.94, 1.0)
	match season:
		GameEnums.SeasonType.SPRING:
			return Color(1.0, 0.97, 0.89, 1.0)
		GameEnums.SeasonType.SUMMER:
			return Color(1.0, 0.93, 0.78, 1.0)
		GameEnums.SeasonType.AUTUMN:
			return Color(0.98, 0.84, 0.64, 1.0)
		GameEnums.SeasonType.WINTER:
			return Color(0.78, 0.88, 0.98, 1.0)
		_:
			return Color.WHITE


static func _resolve_sun_energy(season: GameEnums.SeasonType, is_zud: bool) -> float:
	if is_zud:
		return 0.72
	match season:
		GameEnums.SeasonType.SUMMER:
			return 1.25
		GameEnums.SeasonType.WINTER:
			return 0.86
		GameEnums.SeasonType.AUTUMN:
			return 1.00
		_:
			return 1.12
