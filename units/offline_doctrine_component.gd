class_name OfflineDoctrineComponent
extends Node
## Units (rank 3). Phase 18 **Offline Steppe Watch & Standby Doctrine**
## component (`res://units/offline_doctrine_component.gd`).
##
## Evaluates conditional rules when an army awaits orders / player is offline:
## e.g. when incoming enemy power ratio >= threshold (`1.5x`), aborts open clash,
## packs Sefer Arabası supply train, and activates `FEIGNED_RETREAT_LURE`
## toward dense forest (`SIK_ORMAN`) ambush cover.

@export var avoid_clash_power_ratio_threshold: float = 1.5
@export var preferred_retreat_terrain: GameEnums.TerrainClass = GameEnums.TerrainClass.SIK_ORMAN
@export var pack_sefer_arabasi_on_evasion: bool = true
@export var use_feigned_retreat_on_evasion: bool = true
@export var low_supply_retreat_threshold: float = 0.20
@export var configured_trigger_mode: GameEnums.OfflineDoctrineTrigger = GameEnums.OfflineDoctrineTrigger.ENEMY_POWER_RATIO_EXCEEDED
@export var configured_tactic_phase: GameEnums.TuranTacticPhase = GameEnums.TuranTacticPhase.FEIGNED_RETREAT_LURE
@export var preferred_shelter_geography: GameEnums.RegionGeographyClass = GameEnums.RegionGeographyClass.FOREST_EDGE
@export var evade_combat_on_trigger: bool = true

var _army_id: int = 1
var _last_decision: OfflineDoctrineDecision = null


func _ready() -> void:
	if not EventBus.offline_doctrine_configured.is_connected(_on_offline_doctrine_configured):
		EventBus.offline_doctrine_configured.connect(_on_offline_doctrine_configured)


func _exit_tree() -> void:
	if EventBus.offline_doctrine_configured.is_connected(_on_offline_doctrine_configured):
		EventBus.offline_doctrine_configured.disconnect(_on_offline_doctrine_configured)


static func _safe_float(val: float, fallback: float) -> float:
	if is_nan(val) or is_inf(val):
		return fallback
	return val


func configure(p_army_id: int, p_power_ratio_threshold: float = 1.5, p_retreat_terrain: GameEnums.TerrainClass = GameEnums.TerrainClass.SIK_ORMAN) -> void:
	_army_id = maxi(p_army_id, 1)
	avoid_clash_power_ratio_threshold = clampf(_safe_float(p_power_ratio_threshold, 1.5), 1.05, 10.0)
	preferred_retreat_terrain = p_retreat_terrain
	_last_decision = null
	var stored: OfflineDoctrineConfig = GracePeriodManager.get_offline_doctrine_config(_army_id)
	if stored != null:
		_apply_config(stored)


func get_last_decision() -> OfflineDoctrineDecision:
	return _last_decision


func get_configured_trigger_mode() -> GameEnums.OfflineDoctrineTrigger:
	return configured_trigger_mode


func get_configured_tactic_phase() -> GameEnums.TuranTacticPhase:
	return configured_tactic_phase


func get_preferred_shelter_geography() -> GameEnums.RegionGeographyClass:
	return preferred_shelter_geography


## Evaluates conditional standing doctrine under `own_power` vs `enemy_power` and
## active `supply_ratio`. Picks matching retreat terrain (default `SIK_ORMAN`) from
## `candidate_terrains` and transitions `turan_tactics` to `configured_tactic_phase`
## (`FEIGNED_RETREAT_LURE` by default).
func evaluate_doctrine(
		own_power: float,
		enemy_power: float,
		supply_ratio: float = 1.0,
		turan_tactics: TuranTacticsComponent = null,
		candidate_terrains: Array[TerrainData] = [],
		order_timed_out_offline: bool = false,
		is_winter_zud: bool = false) -> OfflineDoctrineDecision:
	var decision: OfflineDoctrineDecision = OfflineDoctrineDecision.new()
	decision.army_id = _army_id

	var safe_own: float = maxf(_safe_float(own_power, 100.0), 1.0)
	var safe_enemy: float = maxf(_safe_float(enemy_power, 0.0), 0.0)
	var safe_sup: float = clampf(_safe_float(supply_ratio, 1.0), 0.0, 1.0)
	var ratio: float = safe_enemy / safe_own
	decision.power_ratio = ratio

	if configured_trigger_mode == GameEnums.OfflineDoctrineTrigger.NONE:
		_last_decision = decision
		return decision

	if ratio >= avoid_clash_power_ratio_threshold:
		decision.triggered = true
		decision.trigger_reason = GameEnums.OfflineDoctrineTrigger.ENEMY_POWER_RATIO_EXCEEDED
	elif safe_sup <= low_supply_retreat_threshold:
		decision.triggered = true
		decision.trigger_reason = GameEnums.OfflineDoctrineTrigger.LOW_SUPPLY_OR_AMMO
	elif is_winter_zud:
		decision.triggered = true
		decision.trigger_reason = GameEnums.OfflineDoctrineTrigger.SHELTER_IN_KISLAK
		decision.sheltered_in_kislak = true
	elif order_timed_out_offline and safe_enemy > 0.0:
		decision.triggered = true
		decision.trigger_reason = GameEnums.OfflineDoctrineTrigger.ORDER_TIMED_OUT_OFFLINE

	if decision.triggered:
		decision.evade_combat = evade_combat_on_trigger
		decision.packed_sefer_arabasi = pack_sefer_arabasi_on_evasion
		decision.retreat_target_terrain_class = preferred_retreat_terrain
		if preferred_shelter_geography == GameEnums.RegionGeographyClass.SHELTERED_VALLEY_KISLAK:
			decision.sheltered_in_kislak = true
		for terr: TerrainData in candidate_terrains:
			if terr != null and terr.terrain_class == preferred_retreat_terrain:
				decision.target_terrain = terr
				break
		if use_feigned_retreat_on_evasion and turan_tactics != null:
			if turan_tactics.get_current_phase() != configured_tactic_phase:
				turan_tactics.advance_to_phase(configured_tactic_phase)
			decision.activated_feigned_retreat = configured_tactic_phase == GameEnums.TuranTacticPhase.FEIGNED_RETREAT_LURE
		EventBus.offline_doctrine_executed.emit(
			_army_id,
			decision.trigger_reason,
			decision.evade_combat,
			decision.packed_sefer_arabasi,
			decision.retreat_target_terrain_class)

	_last_decision = decision
	return decision


func _apply_config(cfg: OfflineDoctrineConfig) -> void:
	configured_trigger_mode = cfg.trigger_condition
	avoid_clash_power_ratio_threshold = clampf(_safe_float(cfg.power_ratio_threshold, 1.5), 1.05, 10.0)
	low_supply_retreat_threshold = clampf(_safe_float(cfg.low_supply_threshold, 0.20), 0.05, 0.85)
	configured_tactic_phase = cfg.action_tactic
	pack_sefer_arabasi_on_evasion = cfg.pack_sefer_arabasi
	evade_combat_on_trigger = cfg.evade_combat
	preferred_retreat_terrain = cfg.target_terrain_class
	preferred_shelter_geography = cfg.target_geography_class


func _on_offline_doctrine_configured(
		p_army_id: int,
		p_trigger: GameEnums.OfflineDoctrineTrigger,
		p_power_ratio: float,
		p_action_tactic: GameEnums.TuranTacticPhase,
		p_target_terrain: GameEnums.TerrainClass,
		p_target_geo: GameEnums.RegionGeographyClass,
		p_pack_cart: bool,
		p_evade_combat: bool) -> void:
	if p_army_id != _army_id:
		return
	configured_trigger_mode = p_trigger
	avoid_clash_power_ratio_threshold = clampf(_safe_float(p_power_ratio, 1.5), 1.05, 10.0)
	configured_tactic_phase = p_action_tactic
	preferred_retreat_terrain = p_target_terrain
	preferred_shelter_geography = p_target_geo
	pack_sefer_arabasi_on_evasion = p_pack_cart
	evade_combat_on_trigger = p_evade_combat
	var stored: OfflineDoctrineConfig = GracePeriodManager.get_offline_doctrine_config(_army_id)
	if stored != null:
		low_supply_retreat_threshold = clampf(_safe_float(stored.low_supply_threshold, low_supply_retreat_threshold), 0.05, 0.85)
