class_name TacticalCommandViewModel
extends RefCounted
## UI ViewModel (rank 4). Strictly read-only telemetry & geometry math layer for
## Phase 26 (**Turan 360 Vector Compass, Courier Latency Gauge, Dust Deception &
## Bozkır Nöbeti Doctrine Builder**).
##
## Architectural Guarantee:
##   - NEVER mutates any core autoload, simulation resource, or unit component.
##   - Holds bound `ArmyController` via `WeakRef` only.
##   - Player commands go exclusively through `CommandBus`.

const COMBAT_RULES_PATH: String = "res://data/combat/combat_rules.tres"
const COURIER_RULES_PATH: String = "res://data/logistics/courier_and_caravan_rules.tres"
const SUCCESSION_RULES_PATH: String = "res://data/governance/succession_rules.tres"


class TacticalUnitSnapshot:
	var army_id: int = 1
	var player_id: int = 1
	var army_display_name: String = "Öncü Tümeni"
	var has_bound_army: bool = false

	# Vectorial Directional Exposure & Sector Geometry
	var flank_dot_threshold: float = 0.35
	var front_damage_mult: float = 1.0
	var flank_damage_mult: float = 1.45
	var rear_damage_mult: float = 2.10
	var threat_active: bool = false
	var threat_bearing_rad: float = 0.0
	var threat_sector: GameEnums.CombatEngagementAngle = GameEnums.CombatEngagementAngle.FRONT
	var threat_damage_mult: float = 1.0
	var escape_vector_sealed: bool = false

	# 5-Stage Turan Tactic FSM & Overextension Telemetry
	var turan_phase: GameEnums.TuranTacticPhase = GameEnums.TuranTacticPhase.RECON_DUST_SCREEN
	var turan_progress_ratio: float = 0.0
	var turan_fallback_reason: StringName = &""
	var target_formation_entropy: float = 0.0
	var critical_entropy_threshold: float = 0.60
	var target_armor_collapse_ratio: float = 0.0
	var last_flank_angle_rad: float = 0.0
	var min_crescent_flank_angle_rad: float = 2.042035
	var maneuver_efficiency: float = 1.0

	# Outer Gauge Arcs: Sadak (Quiver), Yılkı (Remounts), Yorgunluk (Fatigue)
	var quiver_ammo: float = 100.0
	var remount_horse_ratio: float = 1.0
	var battle_fatigue: float = 0.0
	var current_morale: float = 100.0
	var current_cohesion: float = 100.0
	var supply_ratio: float = 1.0
	var supply_isolated: bool = false
	var cascade_routing: bool = false
	var staggered_hold: bool = false
	var elite_vanguard_alive: bool = true

	# Heavy Armor vs Light Horse-Archer Terrain/Storm Physics Preview
	var is_heavy_armor: bool = false
	var is_mud: bool = false
	var is_steep_slope: bool = false
	var is_storm: bool = false
	var heavy_armor_fatigue_mult: float = 0.65

	# Commander Legacy (Gazi Mirası)
	var commander_name: String = "Kül Tegin"
	var commander_alive: bool = true
	var commander_veteran_score: float = 0.0
	var commander_scars: int = 0
	var commander_turan_speed_mult: float = 1.0
	var commander_rout_resistance: float = 0.0

	# Courier Order Latency Breakdown & Ambush Exposure
	var courier_has_order: bool = false
	var courier_order_id: StringName = &""
	var courier_status: GameEnums.CourierStatus = GameEnums.CourierStatus.DELIVERED
	var courier_base_delay_sec: float = 0.0
	var courier_terrain_delay_sec: float = 0.0
	var courier_storm_delay_sec: float = 0.0
	var courier_total_delay_sec: float = 0.0
	var courier_remaining_delay_sec: float = 0.0
	var courier_ambush_risk_pct: float = 0.0
	var courier_plan_leaked: bool = false
	var courier_leaked_tactic: GameEnums.TuranTacticPhase = GameEnums.TuranTacticPhase.RECON_DUST_SCREEN

	# Yılkı Dust Screen Deception (Toz Perdesi)
	var dust_decoy_active: bool = false
	var dust_apparent_mult: float = 2.10
	var true_power_estimate: float = 100.0
	var perceived_power_estimate: float = 100.0
	var min_remount_for_dust: float = 0.25

	# Standing Doctrine (Bozkır Nöbeti)
	var doctrine_trigger: GameEnums.OfflineDoctrineTrigger = GameEnums.OfflineDoctrineTrigger.ENEMY_POWER_RATIO_EXCEEDED
	var doctrine_power_ratio: float = 1.5
	var doctrine_low_supply: float = 0.20
	var doctrine_action_tactic: GameEnums.TuranTacticPhase = GameEnums.TuranTacticPhase.FEIGNED_RETREAT_LURE
	var doctrine_pack_cart: bool = true
	var doctrine_evade_combat: bool = true
	var doctrine_target_terrain: GameEnums.TerrainClass = GameEnums.TerrainClass.SIK_ORMAN
	var doctrine_target_geo: GameEnums.RegionGeographyClass = GameEnums.RegionGeographyClass.FOREST_EDGE
	var doctrine_summary: String = ""
	var last_decision_triggered: bool = false


var _player_id: int = 1
var _army_id: int = 1
var _bound_army_ref: WeakRef = null

# Strictly UI-local interactive preview parameters (never alter core sim state)
var _preview_threat_active: bool = false
var _preview_threat_bearing_rad: float = 0.0
var _preview_heavy_armor: bool = false
var _preview_is_mud: bool = false
var _preview_is_slope: bool = false
var _preview_is_storm: bool = false
var _preview_courier_distance_m: float = 180.0
var _preview_courier_terrain: GameEnums.TerrainType = GameEnums.TerrainType.STEPPE
var _preview_courier_storm: bool = false

var _cached_combat_rules: CombatRules = null
var _cached_courier_rules: CourierAndCaravanRules = null
var _cached_succession_rules: SuccessionRules = null


func _init(p_player_id: int = 1, p_army_id: int = 1) -> void:
	_player_id = maxi(p_player_id, 1)
	_army_id = maxi(p_army_id, 1)


func set_context(p_player_id: int, p_army_id: int = -1) -> void:
	_player_id = maxi(p_player_id, 1)
	if p_army_id > 0:
		_army_id = p_army_id


func bind_army(army: ArmyController) -> void:
	if army != null and is_instance_valid(army):
		_bound_army_ref = weakref(army)
		if army.army_id > 0:
			_army_id = army.army_id
		if army.owner_id > 0:
			_player_id = army.owner_id
	else:
		_bound_army_ref = null


func get_player_id() -> int:
	return _player_id


func get_army_id() -> int:
	return _army_id


func set_preview_threat(bearing_rad: float, active: bool = true) -> void:
	_preview_threat_active = active
	_preview_threat_bearing_rad = _safe_float(bearing_rad, 0.0)


func set_preview_armor_and_weather(heavy_armor: bool, is_mud: bool, is_steep_slope: bool, is_storm: bool) -> void:
	_preview_heavy_armor = heavy_armor
	_preview_is_mud = is_mud
	_preview_is_slope = is_steep_slope
	_preview_is_storm = is_storm


func set_preview_courier_route(distance_m: float, terrain_type: GameEnums.TerrainType, is_storm: bool) -> void:
	_preview_courier_distance_m = clampf(_safe_float(distance_m, 180.0), 10.0, 2000.0)
	_preview_courier_terrain = terrain_type
	_preview_courier_storm = is_storm


func capture_snapshot() -> TacticalUnitSnapshot:
	var snap: TacticalUnitSnapshot = TacticalUnitSnapshot.new()
	snap.player_id = _player_id
	snap.army_id = _army_id

	var c_rules: CombatRules = _get_combat_rules()
	var l_rules: CourierAndCaravanRules = _get_courier_rules()
	var s_rules: SuccessionRules = _get_succession_rules()

	if c_rules != null:
		snap.flank_dot_threshold = clampf(_safe_float(c_rules.flank_dot_threshold, 0.35), 0.05, 0.95)
		snap.front_damage_mult = maxf(_safe_float(c_rules.front_damage_multiplier, 1.0), 1.0)
		snap.flank_damage_mult = maxf(_safe_float(c_rules.flank_damage_multiplier, 1.45), 1.0)
		snap.rear_damage_mult = maxf(_safe_float(c_rules.rear_damage_multiplier, 2.10), 1.0)

	snap.threat_active = _preview_threat_active
	snap.threat_bearing_rad = _safe_float(_preview_threat_bearing_rad, 0.0)
	snap.threat_sector = classify_sector_from_bearing(snap.threat_bearing_rad, snap.flank_dot_threshold)
	snap.threat_damage_mult = get_sector_damage_multiplier(snap.threat_sector, c_rules)

	var army: ArmyController = _get_bound_army()
	if army != null:
		snap.has_bound_army = true
		if army.template != null:
			if not army.template.display_name.is_empty():
				snap.army_display_name = army.template.display_name
			snap.true_power_estimate = maxf(army.template.get_total_attack() + army.template.get_total_defense(), 1.0)
		if army.turan_tactics != null:
			var tt: TuranTacticsComponent = army.turan_tactics
			snap.turan_phase = tt.get_current_phase()
			snap.quiver_ammo = clampf(_safe_float(tt.get_quiver_ammo(), 100.0), 0.0, 100.0)
			snap.target_formation_entropy = clampf(_safe_float(tt.get_target_formation_entropy(), 0.0), 0.0, 1.0)
			snap.target_armor_collapse_ratio = clampf(_safe_float(tt.get_target_armor_collapse_ratio(), 0.0), 0.0, 1.0)
			snap.last_flank_angle_rad = maxf(_safe_float(tt.get_last_flank_angle_rad(), 0.0), 0.0)
			snap.escape_vector_sealed = tt.is_escape_vector_sealed()
			snap.turan_fallback_reason = tt.get_last_fallback_reason()
			if tt.doctrine != null:
				snap.critical_entropy_threshold = clampf(_safe_float(tt.doctrine.critical_entropy_threshold, 0.60), 0.05, 1.0)
				snap.min_crescent_flank_angle_rad = clampf(_safe_float(tt.doctrine.min_crescent_flank_angle_rad, 2.042035), 0.1, PI)
			snap.maneuver_efficiency = _safe_float(tt.compute_maneuver_execution_efficiency(), 1.0)
			snap.battle_fatigue = clampf(_safe_float(tt.get_own_fatigue(), 0.0), 0.0, 100.0)
			snap.remount_horse_ratio = clampf(_safe_float(tt.get_remount_horse_ratio(), 1.0), 0.0, 1.0)
			snap.commander_alive = tt.is_commander_alive()
		if army.supply != null:
			var sup: SupplyLineComponent = army.supply
			snap.supply_ratio = clampf(_safe_float(sup.get_supply_ratio(), 1.0), 0.0, 1.0)
			snap.supply_isolated = sup.is_isolated() or CommandBus.is_army_supply_isolated(_army_id)
			snap.remount_horse_ratio = clampf(_safe_float(sup.get_remount_horse_ratio(), snap.remount_horse_ratio), 0.0, 1.0)
			if army.turan_tactics == null:
				snap.quiver_ammo = clampf(_safe_float(sup.get_quiver_ammo_reserve(), 100.0), 0.0, 100.0)
			snap.current_morale = clampf(_safe_float(sup.get_battle_morale(), 100.0), 0.0, 100.0)
		else:
			snap.supply_isolated = CommandBus.is_army_supply_isolated(_army_id)
		if army.morale_component != null:
			var mc: MoraleComponent = army.morale_component
			snap.battle_fatigue = clampf(_safe_float(mc.get_battle_fatigue(), snap.battle_fatigue), 0.0, 100.0)
			snap.current_morale = clampf(_safe_float(mc.get_current_morale(), snap.current_morale), 0.0, 100.0)
			snap.current_cohesion = clampf(_safe_float(mc.get_current_cohesion(), 100.0), 0.0, 100.0)
			snap.cascade_routing = mc.is_cascade_routing()
			snap.staggered_hold = mc.is_in_staggered_hold()
			snap.elite_vanguard_alive = mc.is_elite_vanguard_alive()
		if army.commander_legacy != null:
			var cl: CommanderLegacyComponent = army.commander_legacy
			snap.commander_alive = cl.is_commander_alive()
			snap.commander_veteran_score = maxf(_safe_float(cl.get_veteran_score(), 0.0), 0.0)
			snap.commander_scars = cl.get_scar_count()
			snap.commander_turan_speed_mult = _safe_float(cl.get_turan_speed_multiplier(), 1.0)
			snap.commander_rout_resistance = clampf(_safe_float(cl.get_cascade_rout_resistance(), 0.0), 0.0, 0.55)
	else:
		snap.supply_isolated = CommandBus.is_army_supply_isolated(_army_id)

	# Override / enrich commander profile directly from SuccessionManager when registered
	var cmdr_prof: CommanderProfile = SuccessionManager.get_commander_for_army(_army_id)
	if cmdr_prof != null:
		snap.commander_name = String(cmdr_prof.commander_name)
		snap.commander_alive = cmdr_prof.is_alive
		snap.commander_veteran_score = maxf(_safe_float(cmdr_prof.veteran_score, snap.commander_veteran_score), 0.0)
		snap.commander_scars = cmdr_prof.scars
		snap.commander_turan_speed_mult = _safe_float(cmdr_prof.get_turan_speed_multiplier(s_rules), snap.commander_turan_speed_mult)
		snap.commander_rout_resistance = clampf(_safe_float(cmdr_prof.get_cascade_rout_resistance(s_rules), snap.commander_rout_resistance), 0.0, 0.55)

	snap.turan_progress_ratio = compute_turan_fsm_progress(
		snap.turan_phase,
		snap.target_formation_entropy,
		snap.critical_entropy_threshold,
		snap.last_flank_angle_rad,
		snap.min_crescent_flank_angle_rad)

	# Heavy armor & atmospheric fatigue preview
	var core_storm: bool = BallisticsEngine.is_pre_zud_storm_active()
	snap.is_heavy_armor = _preview_heavy_armor
	snap.is_mud = _preview_is_mud
	snap.is_steep_slope = _preview_is_slope
	snap.is_storm = core_storm or _preview_is_storm
	snap.heavy_armor_fatigue_mult = compute_heavy_armor_fatigue_multiplier(
		snap.is_heavy_armor, snap.is_mud, snap.is_steep_slope, snap.is_storm, l_rules)

	# Courier Latency Breakdown & Ambush Exposure
	var latest_order: CourierDispatchOrder = CourierDispatchSystem.get_latest_order_for_army(_army_id)
	if latest_order != null:
		snap.courier_has_order = true
		snap.courier_order_id = latest_order.order_id
		snap.courier_status = latest_order.status
		snap.courier_total_delay_sec = maxf(_safe_float(latest_order.total_delay_sec, 0.0), 0.0)
		snap.courier_remaining_delay_sec = maxf(_safe_float(latest_order.remaining_delay_sec, 0.0), 0.0)
		var order_dist: float = maxf(latest_order.origin_pos.distance_to(latest_order.target_pos), 10.0)
		var order_breakdown: Dictionary[StringName, float] = _decompose_dispatched_order_latency(
			order_dist, snap.courier_total_delay_sec, l_rules)
		snap.courier_base_delay_sec = order_breakdown[&"base_sec"]
		snap.courier_terrain_delay_sec = order_breakdown[&"terrain_sec"]
		snap.courier_storm_delay_sec = order_breakdown[&"storm_sec"]
		snap.courier_ambush_risk_pct = compute_courier_ambush_risk_pct(
			order_dist,
			GameEnums.TerrainType.MOUNTAIN if snap.courier_terrain_delay_sec > 0.01 else GameEnums.TerrainType.STEPPE,
			snap.courier_storm_delay_sec > 0.01 or core_storm,
			snap.supply_isolated)
		if latest_order.status == GameEnums.CourierStatus.AMBUSHED_LOST:
			snap.courier_plan_leaked = true
			snap.courier_leaked_tactic = latest_order.intended_tactic
	else:
		var preview_storm: bool = _preview_courier_storm or core_storm
		var preview_bd: Dictionary[StringName, float] = compute_courier_latency_breakdown(
			_preview_courier_distance_m, _preview_courier_terrain, preview_storm, l_rules)
		snap.courier_has_order = false
		snap.courier_base_delay_sec = preview_bd[&"base_sec"]
		snap.courier_terrain_delay_sec = preview_bd[&"terrain_sec"]
		snap.courier_storm_delay_sec = preview_bd[&"storm_sec"]
		snap.courier_total_delay_sec = preview_bd[&"total_sec"]
		snap.courier_remaining_delay_sec = preview_bd[&"total_sec"]
		snap.courier_ambush_risk_pct = compute_courier_ambush_risk_pct(
			_preview_courier_distance_m, _preview_courier_terrain, preview_storm, snap.supply_isolated)

	var intel_report: EspionageReport = IntelligenceManager.get_latest_report_for_army(_army_id)
	if intel_report != null and intel_report.succeeded and snap.courier_status == GameEnums.CourierStatus.AMBUSHED_LOST:
		snap.courier_plan_leaked = true
		snap.courier_leaked_tactic = intel_report.revealed_tactic_intent

	# Yılkı Dust Screen Deception (Toz Perdesi)
	snap.dust_decoy_active = CourierDispatchSystem.has_dust_decoy(_army_id)
	snap.dust_apparent_mult = l_rules.decoy_apparent_power_mult if l_rules != null else 2.10
	if snap.dust_decoy_active:
		snap.perceived_power_estimate = snap.true_power_estimate * snap.dust_apparent_mult
	else:
		snap.perceived_power_estimate = snap.true_power_estimate

	# Bozkır Nöbeti (Offline / Standby Doctrine)
	var stored_doc: OfflineDoctrineConfig = GracePeriodManager.get_offline_doctrine_config(_army_id)
	if stored_doc != null:
		snap.doctrine_trigger = stored_doc.trigger_condition
		snap.doctrine_power_ratio = stored_doc.power_ratio_threshold
		snap.doctrine_low_supply = stored_doc.low_supply_threshold
		snap.doctrine_action_tactic = stored_doc.action_tactic
		snap.doctrine_pack_cart = stored_doc.pack_sefer_arabasi
		snap.doctrine_evade_combat = stored_doc.evade_combat
		snap.doctrine_target_terrain = stored_doc.target_terrain_class
		snap.doctrine_target_geo = stored_doc.target_geography_class
		snap.doctrine_summary = stored_doc.format_summary()
	elif army != null and army.offline_doctrine != null:
		var od: OfflineDoctrineComponent = army.offline_doctrine
		snap.doctrine_trigger = od.get_configured_trigger_mode()
		snap.doctrine_power_ratio = od.avoid_clash_power_ratio_threshold
		snap.doctrine_low_supply = od.low_supply_retreat_threshold
		snap.doctrine_action_tactic = od.get_configured_tactic_phase()
		snap.doctrine_pack_cart = od.pack_sefer_arabasi_on_evasion
		snap.doctrine_evade_combat = od.evade_combat_on_trigger
		snap.doctrine_target_terrain = od.preferred_retreat_terrain
		snap.doctrine_target_geo = od.get_preferred_shelter_geography()
		snap.doctrine_summary = "EĞER [%s] -> YAP [%s] -> HEDEF [%s]" % [
			OfflineDoctrineConfig.format_trigger_label(snap.doctrine_trigger, snap.doctrine_power_ratio, snap.doctrine_low_supply),
			OfflineDoctrineConfig.format_action_label(snap.doctrine_action_tactic, snap.doctrine_pack_cart, snap.doctrine_evade_combat),
			OfflineDoctrineConfig.format_target_label(snap.doctrine_target_terrain, snap.doctrine_target_geo),
		]
	else:
		snap.doctrine_summary = OfflineDoctrineConfig.new().format_summary()

	if army != null and army.offline_doctrine != null:
		var last_dec: OfflineDoctrineDecision = army.offline_doctrine.get_last_decision()
		snap.last_decision_triggered = last_dec != null and last_dec.triggered

	return snap


# --- Pure Mathematical Transform Functions ----------------------------------

static func _safe_float(val: float, fallback: float) -> float:
	if is_nan(val) or is_inf(val):
		return fallback
	return val


static func classify_sector_from_bearing(bearing_rad: float, flank_dot_threshold: float = 0.35) -> GameEnums.CombatEngagementAngle:
	var safe_bearing: float = _safe_float(bearing_rad, 0.0)
	var threshold: float = clampf(_safe_float(flank_dot_threshold, 0.35), 0.05, 0.95)
	# Threat bearing is relative to defender forward direction (0 = front, PI = rear).
	# Attack blow travels opposite to threat vector, so atk.dot(def_facing) == -cos(bearing).
	var dot_val: float = clampf(-cos(safe_bearing), -1.0, 1.0)
	if dot_val <= -threshold:
		return GameEnums.CombatEngagementAngle.FRONT
	if dot_val >= threshold:
		return GameEnums.CombatEngagementAngle.REAR
	return GameEnums.CombatEngagementAngle.FLANK


static func get_sector_damage_multiplier(angle: GameEnums.CombatEngagementAngle, rules: CombatRules = null) -> float:
	if rules != null:
		return rules.get_directional_damage_multiplier(angle)
	if angle == GameEnums.CombatEngagementAngle.REAR:
		return 2.10
	if angle == GameEnums.CombatEngagementAngle.FLANK:
		return 1.45
	return 1.0


static func compute_heavy_armor_fatigue_multiplier(is_heavy_armor: bool, is_mud: bool, is_steep_slope: bool, is_storm: bool, rules: CourierAndCaravanRules = null) -> float:
	var mud_m: float = rules.heavy_armor_mud_fatigue_mult if rules != null else 2.10
	var slope_m: float = rules.heavy_armor_slope_fatigue_mult if rules != null else 1.90
	var storm_m: float = rules.heavy_armor_storm_fatigue_mult if rules != null else 1.75
	var exp_pow: float = rules.heavy_armor_exponential_power if rules != null else 1.35
	var light_res: float = rules.light_cavalry_terrain_resilience if rules != null else 0.65

	var compound: float = 1.0
	if is_mud:
		compound *= (mud_m if is_heavy_armor else 1.15)
	if is_steep_slope:
		compound *= (slope_m if is_heavy_armor else 1.12)
	if is_storm:
		compound *= (storm_m if is_heavy_armor else 1.10)
	return pow(compound, exp_pow) if is_heavy_armor else compound * light_res


static func compute_courier_latency_breakdown(distance_m: float, terrain_type: GameEnums.TerrainType, is_winter_storm: bool, rules: CourierAndCaravanRules = null) -> Dictionary[StringName, float]:
	var safe_dist: float = maxf(_safe_float(distance_m, 10.0), 10.0)
	var base_speed: float = rules.courier_base_speed_m_per_sec if rules != null else 18.0
	var base_sec: float = safe_dist / maxf(base_speed, 1.0)
	var terrain_mult: float = 1.0
	if terrain_type == GameEnums.TerrainType.MOUNTAIN or terrain_type == GameEnums.TerrainType.FOREST:
		terrain_mult = rules.mountain_forest_delay_mult if rules != null else 1.65
	var storm_mult: float = (rules.winter_storm_delay_mult if rules != null else 1.45) if is_winter_storm else 1.0

	var terrain_sec: float = base_sec * (terrain_mult - 1.0)
	var storm_sec: float = base_sec * terrain_mult * (storm_mult - 1.0)
	var total_sec: float = base_sec * terrain_mult * storm_mult
	return {
		&"base_sec": base_sec,
		&"terrain_sec": terrain_sec,
		&"storm_sec": storm_sec,
		&"total_sec": total_sec,
	}


static func compute_courier_ambush_risk_pct(distance_m: float, terrain_type: GameEnums.TerrainType, is_winter_storm: bool, supply_isolated: bool) -> float:
	var safe_dist: float = maxf(_safe_float(distance_m, 10.0), 10.0)
	var risk: float = clampf(safe_dist / 600.0, 0.0, 1.0) * 32.0
	if terrain_type == GameEnums.TerrainType.FOREST or terrain_type == GameEnums.TerrainType.MOUNTAIN:
		risk += 24.0
	if is_winter_storm:
		risk += 16.0
	if supply_isolated:
		risk += 22.0
	return clampf(risk, 0.0, 96.0)


static func compute_turan_fsm_progress(phase: GameEnums.TuranTacticPhase, formation_entropy: float, critical_entropy: float, flank_angle_rad: float, min_flank_angle: float) -> float:
	var phase_idx: int = clampi(int(phase), 0, 4)
	var base_prog: float = float(phase_idx) / 4.0
	var safe_ent: float = clampf(_safe_float(formation_entropy, 0.0), 0.0, 1.0)
	var safe_crit: float = clampf(_safe_float(critical_entropy, 0.60), 0.05, 1.0)
	var safe_flank: float = maxf(_safe_float(flank_angle_rad, 0.0), 0.0)
	var safe_min_flank: float = maxf(_safe_float(min_flank_angle, 2.042035), 0.1)

	if phase == GameEnums.TuranTacticPhase.FEIGNED_RETREAT_LURE:
		return clampf(base_prog + clampf(safe_ent / safe_crit, 0.0, 1.0) * 0.20, 0.0, 1.0)
	if phase == GameEnums.TuranTacticPhase.CRESCENT_ENCIRCLEMENT_TRAP:
		return clampf(base_prog + clampf(safe_flank / safe_min_flank, 0.0, 1.0) * 0.20, 0.0, 1.0)
	return clampf(base_prog, 0.0, 1.0)


static func format_turan_phase_short(phase: GameEnums.TuranTacticPhase) -> String:
	match phase:
		GameEnums.TuranTacticPhase.RECON_DUST_SCREEN:
			return "0. Keşif & Toz"
		GameEnums.TuranTacticPhase.WHISTLING_ARROW_HARASSMENT:
			return "1. Islıklı Ok"
		GameEnums.TuranTacticPhase.FEIGNED_RETREAT_LURE:
			return "2. Sahte Ricat"
		GameEnums.TuranTacticPhase.CRESCENT_ENCIRCLEMENT_TRAP:
			return "3. Hilal Kapanı"
		_:
			return "4. Börü Hücumu"


static func format_sector_short(angle: GameEnums.CombatEngagementAngle) -> String:
	match angle:
		GameEnums.CombatEngagementAngle.REAR:
			return "ARKA (2.1x)"
		GameEnums.CombatEngagementAngle.FLANK:
			return "YAN (1.45x)"
		_:
			return "ÖN (1.0x)"


static func _decompose_dispatched_order_latency(distance_m: float, total_delay_sec: float, rules: CourierAndCaravanRules = null) -> Dictionary[StringName, float]:
	var base_speed: float = rules.courier_base_speed_m_per_sec if rules != null else 18.0
	var t_mult: float = rules.mountain_forest_delay_mult if rules != null else 1.65
	var s_mult: float = rules.winter_storm_delay_mult if rules != null else 1.45

	var base_sec: float = maxf(distance_m, 10.0) / maxf(base_speed, 1.0)
	var total_sec: float = maxf(_safe_float(total_delay_sec, base_sec), 0.0)
	if total_sec <= base_sec + 0.005:
		return {
			&"base_sec": total_sec,
			&"terrain_sec": 0.0,
			&"storm_sec": 0.0,
		}

	var ratio: float = total_sec / maxf(base_sec, 0.001)
	if absf(ratio - t_mult) < 0.04:
		return {
			&"base_sec": base_sec,
			&"terrain_sec": maxf(total_sec - base_sec, 0.0),
			&"storm_sec": 0.0,
		}
	if absf(ratio - s_mult) < 0.04:
		return {
			&"base_sec": base_sec,
			&"terrain_sec": 0.0,
			&"storm_sec": maxf(total_sec - base_sec, 0.0),
		}
	if absf(ratio - t_mult * s_mult) < 0.06:
		var terrain_only: float = base_sec * (t_mult - 1.0)
		return {
			&"base_sec": base_sec,
			&"terrain_sec": terrain_only,
			&"storm_sec": maxf(total_sec - base_sec - terrain_only, 0.0),
		}
	var extra: float = maxf(total_sec - base_sec, 0.0)
	return {
		&"base_sec": base_sec,
		&"terrain_sec": extra,
		&"storm_sec": 0.0,
	}


func _get_bound_army() -> ArmyController:
	if _bound_army_ref == null:
		return null
	var obj: Object = _bound_army_ref.get_ref()
	if obj == null or not is_instance_valid(obj):
		_bound_army_ref = null
		return null
	return obj as ArmyController


func _get_combat_rules() -> CombatRules:
	if _cached_combat_rules == null:
		_cached_combat_rules = ResourceLoader.load(COMBAT_RULES_PATH) as CombatRules
	return _cached_combat_rules


func _get_courier_rules() -> CourierAndCaravanRules:
	if _cached_courier_rules == null:
		_cached_courier_rules = ResourceLoader.load(COURIER_RULES_PATH) as CourierAndCaravanRules
	return _cached_courier_rules


func _get_succession_rules() -> SuccessionRules:
	if _cached_succession_rules == null:
		_cached_succession_rules = ResourceLoader.load(SUCCESSION_RULES_PATH) as SuccessionRules
	return _cached_succession_rules
