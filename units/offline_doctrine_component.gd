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

var _army_id: int = 1
var _last_decision: OfflineDoctrineDecision = null


static func _safe_float(val: float, fallback: float) -> float:
	if is_nan(val) or is_inf(val):
		return fallback
	return val


func configure(p_army_id: int, p_power_ratio_threshold: float = 1.5, p_retreat_terrain: GameEnums.TerrainClass = GameEnums.TerrainClass.SIK_ORMAN) -> void:
	_army_id = maxi(p_army_id, 1)
	avoid_clash_power_ratio_threshold = clampf(_safe_float(p_power_ratio_threshold, 1.5), 1.05, 10.0)
	preferred_retreat_terrain = p_retreat_terrain
	_last_decision = null


func get_last_decision() -> OfflineDoctrineDecision:
	return _last_decision


## Evaluates conditional standing doctrine under `own_power` vs `enemy_power` and
## active `supply_ratio`. Picks matching retreat terrain (default `SIK_ORMAN`) from
## `candidate_terrains` and transitions `turan_tactics` to `FEIGNED_RETREAT_LURE`.
func evaluate_doctrine(
		own_power: float,
		enemy_power: float,
		supply_ratio: float = 1.0,
		turan_tactics: TuranTacticsComponent = null,
		candidate_terrains: Array[TerrainData] = [],
		order_timed_out_offline: bool = false) -> OfflineDoctrineDecision:
	var decision: OfflineDoctrineDecision = OfflineDoctrineDecision.new()
	decision.army_id = _army_id

	var safe_own: float = maxf(_safe_float(own_power, 100.0), 1.0)
	var safe_enemy: float = maxf(_safe_float(enemy_power, 0.0), 0.0)
	var safe_sup: float = clampf(_safe_float(supply_ratio, 1.0), 0.0, 1.0)
	var ratio: float = safe_enemy / safe_own
	decision.power_ratio = ratio

	if ratio >= avoid_clash_power_ratio_threshold:
		decision.triggered = true
		decision.trigger_reason = GameEnums.OfflineDoctrineTrigger.ENEMY_POWER_RATIO_EXCEEDED
	elif safe_sup <= low_supply_retreat_threshold:
		decision.triggered = true
		decision.trigger_reason = GameEnums.OfflineDoctrineTrigger.LOW_SUPPLY_OR_AMMO
	elif order_timed_out_offline and safe_enemy > 0.0:
		decision.triggered = true
		decision.trigger_reason = GameEnums.OfflineDoctrineTrigger.ORDER_TIMED_OUT_OFFLINE

	if decision.triggered:
		decision.evade_combat = true
		decision.packed_sefer_arabasi = pack_sefer_arabasi_on_evasion
		decision.retreat_target_terrain_class = preferred_retreat_terrain
		for terr: TerrainData in candidate_terrains:
			if terr != null and terr.terrain_class == preferred_retreat_terrain:
				decision.target_terrain = terr
				break
		if use_feigned_retreat_on_evasion and turan_tactics != null:
			if turan_tactics.get_current_phase() != GameEnums.TuranTacticPhase.FEIGNED_RETREAT_LURE:
				turan_tactics.advance_to_phase(GameEnums.TuranTacticPhase.FEIGNED_RETREAT_LURE)
			decision.activated_feigned_retreat = true
		EventBus.offline_doctrine_executed.emit(
			_army_id,
			decision.trigger_reason,
			decision.evade_combat,
			decision.packed_sefer_arabasi,
			decision.retreat_target_terrain_class)

	_last_decision = decision
	return decision
