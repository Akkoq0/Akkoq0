class_name AIBeliefModel
extends RefCounted
## Core AI Belief & Memory Model (rank 2). Tracks only legitimate public facts,
## observable steppe reputation, dust-screen perception, and directly observed
## or espionage-exposed opponent battle doctrines (zero secret-state peeking).

const MAX_DOCTRINE_HISTORY: int = 8
const MAX_ACTION_HISTORY: int = 6

var _ai_player_id: int = 2
var _target_player_id: int = 1
var _target_army_id: int = 1

var _observed_doctrine_history: Array[int] = []
var _doctrine_frequencies: Dictionary[int, float] = {}
var _last_observed_enemy_doctrine: int = -1
var _enemy_doctrine_known: bool = false
var _enemy_plan_exposed: bool = false

var _perceived_enemy_power: float = 1000.0
var _suspected_dust_mirage: bool = false
var _observed_enemy_dread: float = 0.0
var _observed_enemy_honor: float = 50.0
var _observed_enemy_regency: GameEnums.RegencyStatus = GameEnums.RegencyStatus.STABLE_RULE
var _observed_enemy_ulus_strained: bool = false
var _observed_enemy_overextended: bool = false
var _observed_target_region_coord: Vector2i = Vector2i.ZERO
var _observed_enemy_caravan_ids: PackedStringArray = PackedStringArray()
var _observed_enemy_courier_ids: PackedStringArray = PackedStringArray()

var _own_recent_actions: Array[int] = []
var _own_last_doctrine: int = -1
var _action_cooldowns: Dictionary[int, int] = {}
var _hazard_count: int = 0
var _consumed_intel_signature: String = ""


func _init(p_ai_pid: int = 2, p_target_pid: int = 1, p_target_army: int = 1) -> void:
	_ai_player_id = maxi(p_ai_pid, 1)
	_target_player_id = maxi(p_target_pid, 1)
	_target_army_id = maxi(p_target_army, 1)


func set_target(p_target_pid: int, p_target_army: int, p_target_coord: Vector2i = Vector2i.ZERO) -> void:
	_target_player_id = maxi(p_target_pid, 1)
	_target_army_id = maxi(p_target_army, 1)
	if p_target_coord != Vector2i.ZERO:
		_observed_target_region_coord = p_target_coord


func observe_enemy_doctrine(preset_id: int, learning_rate: float = 0.60) -> void:
	if preset_id < 0 or preset_id > 4:
		return
	var lr: float = clampf(learning_rate, 0.15, 1.50)
	var decay: float = clampf(1.0 - lr * 0.25, 0.55, 0.92)
	var keys: Array[int] = _doctrine_frequencies.keys()
	for k: int in keys:
		_doctrine_frequencies[k] = _doctrine_frequencies[k] * decay
	_doctrine_frequencies[preset_id] = _doctrine_frequencies.get(preset_id, 0.0) + lr
	_last_observed_enemy_doctrine = preset_id
	_enemy_doctrine_known = true
	_observed_doctrine_history.append(preset_id)
	while _observed_doctrine_history.size() > MAX_DOCTRINE_HISTORY:
		_observed_doctrine_history.remove_at(0)


func observe_doctrine_id_string(doctrine_id: StringName, learning_rate: float = 0.60) -> void:
	if doctrine_id == &"":
		return
	var doc: BattleDoctrineResource = DoctrinePresetCatalog.create_by_id(doctrine_id)
	if doc != null:
		observe_enemy_doctrine(int(doc.preset_id), learning_rate)


func observe_tactic_intent(tactic: GameEnums.TuranTacticPhase, learning_rate: float = 0.60) -> void:
	var mapped_preset: int = int(GameEnums.BattleDoctrinePresetId.KURT_KAPANI)
	match tactic:
		GameEnums.TuranTacticPhase.BORU_SHOCK_ANNIHILATION:
			mapped_preset = int(GameEnums.BattleDoctrinePresetId.BORU_KAMASI)
		GameEnums.TuranTacticPhase.CRESCENT_ENCIRCLEMENT_TRAP:
			mapped_preset = int(GameEnums.BattleDoctrinePresetId.TOLGAMA_KISKACI)
		GameEnums.TuranTacticPhase.WHISTLING_ARROW_HARASSMENT:
			mapped_preset = int(GameEnums.BattleDoctrinePresetId.TONYUKUK_YIPRATMASI)
		GameEnums.TuranTacticPhase.RECON_DUST_SCREEN:
			mapped_preset = int(GameEnums.BattleDoctrinePresetId.ARABA_KALESI)
		_:
			mapped_preset = int(GameEnums.BattleDoctrinePresetId.KURT_KAPANI)
	observe_enemy_doctrine(mapped_preset, learning_rate)


func record_own_action(category: GameEnums.AIActionCategory, doctrine_preset: int = -1, cooldown_ticks: int = 0) -> void:
	var cat_i: int = int(category)
	_own_recent_actions.append(cat_i)
	while _own_recent_actions.size() > MAX_ACTION_HISTORY:
		_own_recent_actions.remove_at(0)
	if doctrine_preset >= 0:
		_own_last_doctrine = doctrine_preset
	if cooldown_ticks > 0:
		var prev_cd: int = _action_cooldowns[cat_i] if _action_cooldowns.has(cat_i) else 0
		_action_cooldowns[cat_i] = maxi(prev_cd, cooldown_ticks)


func step_cooldowns() -> void:
	var erase_keys: Array[int] = []
	for k: int in _action_cooldowns:
		var rem: int = _action_cooldowns[k] - 1
		if rem <= 0:
			erase_keys.append(k)
		else:
			_action_cooldowns[k] = rem
	for ek: int in erase_keys:
		_action_cooldowns.erase(ek)


func get_action_cooldown(category: GameEnums.AIActionCategory) -> int:
	return _action_cooldowns.get(int(category), 0)


func get_action_recent_repeats(category: GameEnums.AIActionCategory) -> int:
	var cat_i: int = int(category)
	var cnt: int = 0
	for a: int in _own_recent_actions:
		if a == cat_i:
			cnt += 1
	return cnt


func refresh_public_and_legitimate_observations(
		difficulty: AIDifficultyProfile,
		target_coord_hint: Vector2i = Vector2i.ZERO) -> void:
	step_cooldowns()
	var learn_rate: float = difficulty.adaptation_learning_rate if difficulty != null else 0.60
	var scout_strength: float = difficulty.get_effective_scout_strength() if difficulty != null else 60.0

	# Public steppe reputation, regency & governance metrics
	_observed_enemy_dread = ReputationAndPactSystem.get_dread_score(_target_player_id)
	_observed_enemy_honor = ReputationAndPactSystem.get_honor_score(_target_player_id)
	_observed_enemy_regency = SuccessionManager.get_regency_status(_target_player_id)

	var direct_cnt: int = GovernanceManager.get_direct_region_count(_target_player_id)
	var direct_cap: int = GovernanceManager.get_direct_cap(_target_player_id)
	_observed_enemy_overextended = direct_cnt > direct_cap

	var vassals: Array[VassalBeyAssignment] = GovernanceManager.get_vassals_for_suzerain(_target_player_id)
	var ulus_strained: bool = false
	for v: VassalBeyAssignment in vassals:
		if v != null and (v.silent_sabotage_active or v.loyalty < 45.0):
			ulus_strained = true
			break
	_observed_enemy_ulus_strained = ulus_strained

	# Public target geography
	if target_coord_hint != Vector2i.ZERO:
		_observed_target_region_coord = target_coord_hint
	else:
		var owned: Array[Vector2i] = TerritoryManager.get_owned_region_coords(_target_player_id)
		if not owned.is_empty():
			_observed_target_region_coord = owned[0]
		else:
			var camp_c: Vector2i = PastureEcologyManager.get_player_camp_region(_target_player_id)
			if camp_c != Vector2i.ZERO:
				_observed_target_region_coord = camp_c

	# Environment hazard awareness (storm / cataclysm)
	var storm_haz: int = 1 if BallisticsEngine.is_pre_zud_storm_active() else 0
	var active_cat: CataclysmEventData = CataclysmEngine.get_active_region_cataclysm(_observed_target_region_coord)
	var cat_haz: int = 1 if active_cat != null else 0
	_hazard_count = storm_haz + cat_haz

	# Dust perception strictly via scouting physics (may fool easy/medium AIs)
	var base_army_power: float = 1000.0
	var perc: Dictionary[StringName, float] = CourierDispatchSystem.evaluate_dust_perception(
		_ai_player_id, _target_army_id, base_army_power, scout_strength, 90.0)
	_perceived_enemy_power = perc.get(&"perceived_power", base_army_power)
	_suspected_dust_mirage = perc.get(&"sees_through", 1.0) < 0.5

	# Legitimate intelligence revelation ONLY (no peeking!)
	_enemy_plan_exposed = CourierDispatchSystem.is_player_plan_exposed_by_courier(_target_player_id, _target_army_id)
	var intel_rep: EspionageReport = IntelligenceManager.get_latest_report_for_army(_target_army_id)
	if intel_rep != null and intel_rep.succeeded and intel_rep.spy_owner_id == _ai_player_id:
		_enemy_plan_exposed = true
		var rep_sig: String = "%d:%d:%d" % [intel_rep.target_army_id, int(intel_rep.revealed_tactic_intent), int(intel_rep.revealed_doctrine_type)]
		if _consumed_intel_signature != rep_sig:
			_consumed_intel_signature = rep_sig
			observe_tactic_intent(intel_rep.revealed_tactic_intent, learn_rate)

	# Visible steppe road caravans & active couriers
	_observed_enemy_caravan_ids = PackedStringArray()
	for conv: PhysicalCaravan in CaravanLogisticsManager.get_all_caravans():
		if conv != null and conv.owner_id == _target_player_id and conv.state == GameEnums.CaravanCargoState.EN_ROUTE:
			_observed_enemy_caravan_ids.append(String(conv.caravan_id))

	_observed_enemy_courier_ids = PackedStringArray()
	for ord: CourierDispatchOrder in CourierDispatchSystem.get_all_orders():
		if ord != null and ord.player_id == _target_player_id and ord.status == GameEnums.CourierStatus.IN_TRANSIT:
			_observed_enemy_courier_ids.append(String(ord.order_id))


func get_target_player_id() -> int:
	return _target_player_id


func get_target_army_id() -> int:
	return _target_army_id


func is_enemy_doctrine_known() -> bool:
	return _enemy_doctrine_known


func is_enemy_plan_exposed() -> bool:
	return _enemy_plan_exposed


func get_predicted_enemy_doctrine() -> int:
	if _doctrine_frequencies.is_empty():
		return _last_observed_enemy_doctrine
	var best_preset: int = _last_observed_enemy_doctrine
	var best_score: float = -1.0
	for preset_i: int in _doctrine_frequencies:
		var w: float = _doctrine_frequencies[preset_i]
		if w > best_score:
			best_score = w
			best_preset = preset_i
	return best_preset


func get_doctrine_confidence() -> float:
	if _doctrine_frequencies.is_empty():
		return 0.0
	var total: float = 0.0
	var top_w: float = 0.0
	for preset_i: int in _doctrine_frequencies:
		var w: float = _doctrine_frequencies[preset_i]
		total += w
		if w > top_w:
			top_w = w
	if total <= 0.001:
		return 0.0
	return clampf(top_w / maxf(total, 1.0), 0.0, 1.0)


func get_perceived_enemy_power() -> float:
	return _perceived_enemy_power


func is_suspected_dust_mirage() -> bool:
	return _suspected_dust_mirage


func get_observed_enemy_dread() -> float:
	return _observed_enemy_dread


func get_observed_enemy_honor() -> float:
	return _observed_enemy_honor


func get_observed_enemy_regency() -> GameEnums.RegencyStatus:
	return _observed_enemy_regency


func is_observed_enemy_ulus_strained() -> bool:
	return _observed_enemy_ulus_strained


func is_observed_enemy_overextended() -> bool:
	return _observed_enemy_overextended


func get_observed_target_region_coord() -> Vector2i:
	return _observed_target_region_coord


func get_observed_enemy_caravan_ids() -> PackedStringArray:
	return _observed_enemy_caravan_ids


func get_observed_enemy_courier_ids() -> PackedStringArray:
	return _observed_enemy_courier_ids


func get_own_last_doctrine() -> int:
	return _own_last_doctrine


func get_hazard_count() -> int:
	return _hazard_count


func recommend_counter_doctrine(avoid_heavy_in_hazards: bool = true) -> GameEnums.BattleDoctrinePresetId:
	var pred: int = get_predicted_enemy_doctrine()
	if pred == int(GameEnums.BattleDoctrinePresetId.TOLGAMA_KISKACI):
		if avoid_heavy_in_hazards and _hazard_count >= 2:
			return GameEnums.BattleDoctrinePresetId.ARABA_KALESI
		return GameEnums.BattleDoctrinePresetId.BORU_KAMASI
	if pred == int(GameEnums.BattleDoctrinePresetId.BORU_KAMASI):
		if _enemy_plan_exposed:
			return GameEnums.BattleDoctrinePresetId.ARABA_KALESI
		return GameEnums.BattleDoctrinePresetId.KURT_KAPANI
	if pred == int(GameEnums.BattleDoctrinePresetId.KURT_KAPANI):
		return GameEnums.BattleDoctrinePresetId.ARABA_KALESI
	if pred == int(GameEnums.BattleDoctrinePresetId.ARABA_KALESI):
		return GameEnums.BattleDoctrinePresetId.TONYUKUK_YIPRATMASI
	if pred == int(GameEnums.BattleDoctrinePresetId.TONYUKUK_YIPRATMASI):
		return GameEnums.BattleDoctrinePresetId.TOLGAMA_KISKACI
	return GameEnums.BattleDoctrinePresetId.TOLGAMA_KISKACI


func export_state_dict() -> Dictionary:
	var freq_dict: Dictionary = {}
	for k: int in _doctrine_frequencies:
		freq_dict[str(k)] = _doctrine_frequencies[k]
	var cd_dict: Dictionary = {}
	for k: int in _action_cooldowns:
		cd_dict[str(k)] = _action_cooldowns[k]
	return {
		"action_cooldowns": cd_dict,
		"ai_player_id": _ai_player_id,
		"doctrine_frequencies": freq_dict,
		"enemy_doctrine_known": _enemy_doctrine_known,
		"enemy_plan_exposed": _enemy_plan_exposed,
		"hazard_count": _hazard_count,
		"consumed_intel_signature": _consumed_intel_signature,
		"last_observed_enemy_doctrine": _last_observed_enemy_doctrine,
		"observed_doctrine_history": _observed_doctrine_history.duplicate(),
		"observed_enemy_dread": _observed_enemy_dread,
		"observed_enemy_honor": _observed_enemy_honor,
		"observed_enemy_overextended": _observed_enemy_overextended,
		"observed_enemy_regency": int(_observed_enemy_regency),
		"observed_enemy_ulus_strained": _observed_enemy_ulus_strained,
		"observed_target_region_x": _observed_target_region_coord.x,
		"observed_target_region_y": _observed_target_region_coord.y,
		"own_last_doctrine": _own_last_doctrine,
		"own_recent_actions": _own_recent_actions.duplicate(),
		"perceived_enemy_power": _perceived_enemy_power,
		"suspected_dust_mirage": _suspected_dust_mirage,
		"target_army_id": _target_army_id,
		"target_player_id": _target_player_id,
	}


func import_state_dict(data: Dictionary) -> bool:
	_ai_player_id = maxi(DeterministicStateHasher.v_int(data.get("ai_player_id", 2), 2), 1)
	_target_player_id = maxi(DeterministicStateHasher.v_int(data.get("target_player_id", 1), 1), 1)
	_target_army_id = maxi(DeterministicStateHasher.v_int(data.get("target_army_id", 1), 1), 1)
	_consumed_intel_signature = DeterministicStateHasher.v_str(data.get("consumed_intel_signature", ""))
	_enemy_doctrine_known = DeterministicStateHasher.v_bool(data.get("enemy_doctrine_known", false), false)
	_enemy_plan_exposed = DeterministicStateHasher.v_bool(data.get("enemy_plan_exposed", false), false)
	_hazard_count = maxi(DeterministicStateHasher.v_int(data.get("hazard_count", 0), 0), 0)
	_last_observed_enemy_doctrine = DeterministicStateHasher.v_int(data.get("last_observed_enemy_doctrine", -1), -1)
	_observed_enemy_dread = DeterministicStateHasher.v_float(data.get("observed_enemy_dread", 0.0), 0.0)
	_observed_enemy_honor = DeterministicStateHasher.v_float(data.get("observed_enemy_honor", 50.0), 50.0)
	var reg_int: int = clampi(DeterministicStateHasher.v_int(data.get("observed_enemy_regency", 0), 0), 0, 2)
	_observed_enemy_regency = reg_int as GameEnums.RegencyStatus
	_observed_enemy_overextended = DeterministicStateHasher.v_bool(data.get("observed_enemy_overextended", false), false)
	_observed_enemy_ulus_strained = DeterministicStateHasher.v_bool(data.get("observed_enemy_ulus_strained", false), false)
	_observed_target_region_coord = Vector2i(
		DeterministicStateHasher.v_int(data.get("observed_target_region_x", 0), 0),
		DeterministicStateHasher.v_int(data.get("observed_target_region_y", 0), 0))
	_own_last_doctrine = DeterministicStateHasher.v_int(data.get("own_last_doctrine", -1), -1)
	_perceived_enemy_power = DeterministicStateHasher.v_float(data.get("perceived_enemy_power", 1000.0), 1000.0)
	_suspected_dust_mirage = DeterministicStateHasher.v_bool(data.get("suspected_dust_mirage", false), false)

	_doctrine_frequencies.clear()
	var freq_dict: Dictionary = DeterministicStateHasher.v_dict(data.get("doctrine_frequencies", {}))
	for k: Variant in freq_dict:
		var ki: int = DeterministicStateHasher.v_str(k).to_int()
		_doctrine_frequencies[ki] = DeterministicStateHasher.v_float(freq_dict[k], 0.0)

	_action_cooldowns.clear()
	var cd_dict: Dictionary = DeterministicStateHasher.v_dict(data.get("action_cooldowns", {}))
	for k: Variant in cd_dict:
		var ki: int = DeterministicStateHasher.v_str(k).to_int()
		_action_cooldowns[ki] = DeterministicStateHasher.v_int(cd_dict[k], 0)

	_observed_doctrine_history.clear()
	for h_v: Variant in DeterministicStateHasher.v_arr(data.get("observed_doctrine_history", [])):
		_observed_doctrine_history.append(DeterministicStateHasher.v_int(h_v, -1))

	_own_recent_actions.clear()
	for a_v: Variant in DeterministicStateHasher.v_arr(data.get("own_recent_actions", [])):
		_own_recent_actions.append(DeterministicStateHasher.v_int(a_v, 0))
	return true
