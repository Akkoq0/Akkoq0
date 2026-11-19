class_name AITheoryOfMindModel
extends RefCounted
## Core 2nd-Order Theory of Mind module (rank 2, leaf 2A).
## Tracks AI's own last visible move and reasons:
## "Opponent saw me do X -> opponent expects me to do X next -> opponent prepares
## counter C(X) -> my 2nd-order optimal play is C(C(X)) or a trap."
## Strictly decoupled from other AI leaf modules to preserve acyclic DAG.

var last_visible_ai_doctrine: int = -1
var last_visible_ai_action: StringName = &""
var projected_posture: StringName = &"neutral"
var predicted_opponent_assumption_about_me: int = -1
var predicted_opponent_counter_doctrine: int = -1
var second_order_optimal_doctrine: int = -1
var second_order_confidence: float = 0.0
var total_predictions: int = 0
var matched_predictions: int = 0
var _doctrine_counter_hits: Dictionary[int, int] = {}


func reset() -> void:
	last_visible_ai_doctrine = -1
	last_visible_ai_action = &""
	projected_posture = &"neutral"
	predicted_opponent_assumption_about_me = -1
	predicted_opponent_counter_doctrine = -1
	second_order_optimal_doctrine = -1
	second_order_confidence = 0.0
	total_predictions = 0
	matched_predictions = 0
	_doctrine_counter_hits.clear()


static func compute_direct_counter_doctrine(
		target_doctrine: int,
		prefer_safe_heavy: bool = false) -> int:
	if target_doctrine < 0:
		return -1
	match target_doctrine:
		int(GameEnums.BattleDoctrinePresetId.TOLGAMA_KISKACI):
			if prefer_safe_heavy:
				return int(GameEnums.BattleDoctrinePresetId.ARABA_KALESI)
			return int(GameEnums.BattleDoctrinePresetId.BORU_KAMASI)
		int(GameEnums.BattleDoctrinePresetId.BORU_KAMASI):
			return int(GameEnums.BattleDoctrinePresetId.KURT_KAPANI)
		int(GameEnums.BattleDoctrinePresetId.KURT_KAPANI):
			return int(GameEnums.BattleDoctrinePresetId.ARABA_KALESI)
		int(GameEnums.BattleDoctrinePresetId.ARABA_KALESI):
			return int(GameEnums.BattleDoctrinePresetId.TONYUKUK_YIPRATMASI)
		int(GameEnums.BattleDoctrinePresetId.TONYUKUK_YIPRATMASI):
			return int(GameEnums.BattleDoctrinePresetId.TOLGAMA_KISKACI)
	return int(GameEnums.BattleDoctrinePresetId.TOLGAMA_KISKACI)


func record_ai_visible_action(
		action_category: GameEnums.AIActionCategory,
		doctrine_preset: int,
		posture_tag: StringName = &"neutral",
		diff: AIDifficultyProfile = null) -> void:
	last_visible_ai_action = StringName("cat_%d" % int(action_category))
	if posture_tag != &"":
		projected_posture = posture_tag
	if doctrine_preset >= 0 and doctrine_preset <= 4:
		last_visible_ai_doctrine = doctrine_preset
	_recompute_second_order_prediction(diff)


func observe_opponent_matchup_doctrine(
		opponent_doctrine_id: StringName,
		diff: AIDifficultyProfile = null) -> void:
	var opp_int: int = _doctrine_id_to_preset_int(opponent_doctrine_id)
	if opp_int < 0:
		return
	if predicted_opponent_counter_doctrine >= 0:
		total_predictions += 1
		if opp_int == predicted_opponent_counter_doctrine:
			matched_predictions += 1
			second_order_confidence = clampf(second_order_confidence + 0.28, 0.20, 0.96)
			_doctrine_counter_hits[opp_int] = _doctrine_counter_hits.get(opp_int, 0) + 1
		else:
			second_order_confidence = clampf(second_order_confidence * 0.80 + 0.08, 0.10, 0.90)
	_recompute_second_order_prediction(diff)


func _recompute_second_order_prediction(diff: AIDifficultyProfile) -> void:
	if last_visible_ai_doctrine < 0:
		predicted_opponent_assumption_about_me = -1
		predicted_opponent_counter_doctrine = -1
		second_order_optimal_doctrine = -1
		return
	predicted_opponent_assumption_about_me = last_visible_ai_doctrine
	predicted_opponent_counter_doctrine = compute_direct_counter_doctrine(predicted_opponent_assumption_about_me, false)
	second_order_optimal_doctrine = compute_direct_counter_doctrine(predicted_opponent_counter_doctrine, false)
	var lr: float = diff.adaptation_learning_rate if diff != null else 0.60
	var base_conf: float = clampf(lr * 0.55, 0.05, 0.88)
	second_order_confidence = clampf(maxf(second_order_confidence, base_conf), 0.05, 0.96)


func get_tier_tom_depth_weight(diff: AIDifficultyProfile) -> float:
	if diff == null:
		return 0.35
	match diff.difficulty_tier:
		GameEnums.AIDifficultyTier.OYMAK_BEYI:
			return 0.05
		GameEnums.AIDifficultyTier.SANCAK_BEYI:
			return 0.30
		GameEnums.AIDifficultyTier.BOZKIR_KURDU:
			return 0.72
		GameEnums.AIDifficultyTier.KAGAN_ZEKASI:
			return 1.00
	return 0.35


func get_second_order_doctrine_bonus(
		candidate_preset: int,
		diff: AIDifficultyProfile) -> float:
	if second_order_optimal_doctrine < 0 or candidate_preset != second_order_optimal_doctrine:
		return 0.0
	var depth_w: float = get_tier_tom_depth_weight(diff)
	if depth_w <= 0.06:
		return 0.0
	var hit_boost: float = 0.0
	if predicted_opponent_counter_doctrine >= 0 and _doctrine_counter_hits.has(predicted_opponent_counter_doctrine):
		hit_boost = minf(float(_doctrine_counter_hits[predicted_opponent_counter_doctrine]) * 4.5, 12.0)
	return (22.0 + hit_boost) * depth_w * maxf(second_order_confidence, 0.35)


static func _doctrine_id_to_preset_int(doc_id: StringName) -> int:
	if doc_id == &"kurt_kapani":
		return int(GameEnums.BattleDoctrinePresetId.KURT_KAPANI)
	if doc_id == &"araba_kalesi":
		return int(GameEnums.BattleDoctrinePresetId.ARABA_KALESI)
	if doc_id == &"tonyukuk_yipratmasi":
		return int(GameEnums.BattleDoctrinePresetId.TONYUKUK_YIPRATMASI)
	if doc_id == &"boru_kamasi":
		return int(GameEnums.BattleDoctrinePresetId.BORU_KAMASI)
	if doc_id == &"tolgama_kiskaci":
		return int(GameEnums.BattleDoctrinePresetId.TOLGAMA_KISKACI)
	return -1


func export_state_dict() -> Dictionary:
	var hits_dict: Dictionary = {}
	var keys: Array[int] = _doctrine_counter_hits.keys()
	keys.sort()
	for k: int in keys:
		hits_dict[str(k)] = _doctrine_counter_hits[k]
	return {
		"doctrine_counter_hits": hits_dict,
		"last_visible_ai_action": String(last_visible_ai_action),
		"last_visible_ai_doctrine": last_visible_ai_doctrine,
		"matched_predictions": matched_predictions,
		"predicted_opponent_assumption_about_me": predicted_opponent_assumption_about_me,
		"predicted_opponent_counter_doctrine": predicted_opponent_counter_doctrine,
		"projected_posture": String(projected_posture),
		"second_order_confidence": second_order_confidence,
		"second_order_optimal_doctrine": second_order_optimal_doctrine,
		"total_predictions": total_predictions,
	}


func import_state_dict(data: Dictionary) -> bool:
	last_visible_ai_doctrine = DeterministicStateHasher.v_int(data.get("last_visible_ai_doctrine", -1), -1)
	last_visible_ai_action = StringName(DeterministicStateHasher.v_str(data.get("last_visible_ai_action", "")))
	projected_posture = StringName(DeterministicStateHasher.v_str(data.get("projected_posture", "neutral"), "neutral"))
	predicted_opponent_assumption_about_me = DeterministicStateHasher.v_int(data.get("predicted_opponent_assumption_about_me", -1), -1)
	predicted_opponent_counter_doctrine = DeterministicStateHasher.v_int(data.get("predicted_opponent_counter_doctrine", -1), -1)
	second_order_optimal_doctrine = DeterministicStateHasher.v_int(data.get("second_order_optimal_doctrine", -1), -1)
	second_order_confidence = clampf(DeterministicStateHasher.v_float(data.get("second_order_confidence", 0.0), 0.0), 0.0, 1.0)
	total_predictions = maxi(DeterministicStateHasher.v_int(data.get("total_predictions", 0), 0), 0)
	matched_predictions = maxi(DeterministicStateHasher.v_int(data.get("matched_predictions", 0), 0), 0)
	_doctrine_counter_hits.clear()
	var hd: Dictionary = DeterministicStateHasher.v_dict(data.get("doctrine_counter_hits", {}))
	for k: Variant in hd:
		var ki: int = DeterministicStateHasher.v_str(k).to_int()
		_doctrine_counter_hits[ki] = maxi(DeterministicStateHasher.v_int(hd[k], 0), 0)
	return true
