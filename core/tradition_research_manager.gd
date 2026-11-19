class_name TraditionResearchManager
extends RefCounted
## Core static manager (rank 2). Owns authoritative per-player Tradition &
## Military Research DAG state, silver spending via `SpendResourcesCommand`,
## seasonal progression synced with `SeasonManager`, deterministic matchup
## bonuses, and canonical save/load serialization for `WorldSnapshotSerializer`.


class ResearchBonusesSnapshot:
	extends RefCounted
	var melee_attack_bonus: float = 0.0
	var defense_bonus: float = 0.0
	var speed_bonus: float = 0.0
	var water_resilience_bonus: float = 0.0
	var courier_speed_bonus: float = 0.0
	var tax_efficiency_bonus: float = 0.0
	var kut_stability_bonus: float = 0.0
	var steel_craft_bonus: float = 0.0
	var completed_count: int = 0


class PlayerResearchState:
	extends RefCounted
	var player_id: int = 1
	var active_node_id: StringName = &""
	var active_elapsed_seasons: int = 0
	var active_total_seasons: int = 0
	var completed_nodes: Array[StringName] = []

	func _init(p_id: int = 1) -> void:
		player_id = p_id


static var _states: Dictionary[int, PlayerResearchState] = {}


static func reset_research_state() -> void:
	_states.clear()


static func is_node_completed(player_id: int, node_id: StringName) -> bool:
	var st: PlayerResearchState = _get_state(player_id)
	if st == null or node_id == &"":
		return false
	return st.completed_nodes.has(node_id)


static func are_prerequisites_met(player_id: int, node_id: StringName) -> bool:
	var node: TraditionResearchNode = TraditionResearchCatalog.get_node_by_id(node_id)
	if node == null:
		return false
	for req_str: String in node.prerequisites:
		var req_id: StringName = StringName(req_str)
		if req_id == &"":
			continue
		if not is_node_completed(player_id, req_id):
			return false
	return true


static func get_node_status(player_id: int, node_id: StringName) -> GameEnums.ResearchNodeStatus:
	if is_node_completed(player_id, node_id):
		return GameEnums.ResearchNodeStatus.COMPLETED
	var st: PlayerResearchState = _get_state(player_id)
	if st != null and st.active_node_id == node_id and node_id != &"":
		return GameEnums.ResearchNodeStatus.IN_PROGRESS
	if are_prerequisites_met(player_id, node_id):
		return GameEnums.ResearchNodeStatus.RESEARCHABLE
	return GameEnums.ResearchNodeStatus.LOCKED


static func get_active_node_id(player_id: int) -> StringName:
	var st: PlayerResearchState = _get_state(player_id)
	return st.active_node_id if st != null else &""


static func get_active_elapsed_seasons(player_id: int) -> int:
	var st: PlayerResearchState = _get_state(player_id)
	return st.active_elapsed_seasons if st != null else 0


static func get_active_total_seasons(player_id: int) -> int:
	var st: PlayerResearchState = _get_state(player_id)
	return st.active_total_seasons if st != null else 0


static func get_active_progress_ratio(player_id: int) -> float:
	var st: PlayerResearchState = _get_state(player_id)
	if st == null or st.active_node_id == &"" or st.active_total_seasons <= 0:
		return 0.0
	return clampf(float(st.active_elapsed_seasons) / float(st.active_total_seasons), 0.0, 1.0)


static func get_completed_node_ids(player_id: int) -> Array[StringName]:
	var out: Array[StringName] = []
	var st: PlayerResearchState = _get_state(player_id)
	if st == null:
		return out
	for nid: StringName in st.completed_nodes:
		out.append(nid)
	return out


static func get_player_bonuses(player_id: int) -> ResearchBonusesSnapshot:
	var snap: ResearchBonusesSnapshot = ResearchBonusesSnapshot.new()
	var st: PlayerResearchState = _get_state(player_id)
	if st == null:
		return snap
	for nid: StringName in st.completed_nodes:
		var node: TraditionResearchNode = TraditionResearchCatalog.get_node_by_id(nid)
		if node == null:
			continue
		snap.completed_count += 1
		snap.melee_attack_bonus += node.melee_attack_bonus
		snap.defense_bonus += node.defense_bonus
		snap.speed_bonus += node.speed_bonus
		snap.water_resilience_bonus += node.water_resilience_bonus
		snap.courier_speed_bonus += node.courier_speed_bonus
		snap.tax_efficiency_bonus += node.tax_efficiency_bonus
		snap.kut_stability_bonus += node.kut_stability_bonus
		snap.steel_craft_bonus += node.steel_craft_bonus
	return snap


static func apply_bonuses_to_matchup(
		res: DoctrineMatchupResult,
		attacker_player_id: int,
		defender_player_id: int) -> void:
	if res == null:
		return
	var atk_b: ResearchBonusesSnapshot = get_player_bonuses(attacker_player_id)
	if atk_b.completed_count > 0:
		if atk_b.melee_attack_bonus > 0.0:
			res.attacker_attack_multiplier = clampf(
				res.attacker_attack_multiplier * (1.0 + atk_b.melee_attack_bonus), 0.25, 4.0)
		if atk_b.speed_bonus > 0.0:
			res.attacker_mobility_multiplier = clampf(
				res.attacker_mobility_multiplier * (1.0 + atk_b.speed_bonus), 0.25, 3.0)
		if not res.tactical_tags.has("tradition_research_atk"):
			var new_tags: PackedStringArray = res.tactical_tags
			new_tags.append("tradition_research_atk")
			res.tactical_tags = new_tags
		var new_reasons: PackedStringArray = res.summary_reasons
		new_reasons.append("Töre Geleneği Saldırı Bonusu (+%%%d Saldırı, +%%%d Hız)" % [
			roundi(atk_b.melee_attack_bonus * 100.0),
			roundi(atk_b.speed_bonus * 100.0)])
		res.summary_reasons = new_reasons

	var def_b: ResearchBonusesSnapshot = get_player_bonuses(defender_player_id)
	if def_b.completed_count > 0:
		if def_b.defense_bonus > 0.0:
			res.defender_defense_multiplier = clampf(
				res.defender_defense_multiplier * (1.0 + def_b.defense_bonus), 0.25, 4.0)
		if def_b.speed_bonus > 0.0:
			res.defender_mobility_multiplier = clampf(
				res.defender_mobility_multiplier * (1.0 + def_b.speed_bonus), 0.25, 3.0)
		if not res.tactical_tags.has("tradition_research_def"):
			var d_tags: PackedStringArray = res.tactical_tags
			d_tags.append("tradition_research_def")
			res.tactical_tags = d_tags
		var d_reasons: PackedStringArray = res.summary_reasons
		d_reasons.append("Savunan Töre Geleneği (+%%%d Savunma)" % [
			roundi(def_b.defense_bonus * 100.0)])
		res.summary_reasons = d_reasons


static func handle_start_research(command: GameCommand) -> bool:
	var cmd: StartResearchCommand = command as StartResearchCommand
	if cmd == null:
		return command.reject("Expected StartResearchCommand.")
	if cmd.player_id <= 0:
		return command.reject("StartResearchCommand: player_id must be > 0.")
	var node: TraditionResearchNode = TraditionResearchCatalog.get_node_by_id(cmd.node_id)
	if node == null:
		return command.reject("Bilinmeyen gelenek araştırma düğümü: %s." % String(cmd.node_id))

	var st: PlayerResearchState = _get_or_create_state(cmd.player_id)
	if st.completed_nodes.has(cmd.node_id):
		return command.reject("Araştırma zaten tamamlandı: %s." % node.title)
	if st.active_node_id != &"":
		return command.reject("Aktif araştırma sürerken (%s) yeni araştırma başlatılamaz." % String(st.active_node_id))
	if not are_prerequisites_met(cmd.player_id, cmd.node_id):
		return command.reject("Ön koşul gelenek araştırmaları tamamlanmadı: %s." % node.title)

	if node.silver_cost > 0:
		var reg: OreRegistry = ResourceManager.get_registry()
		var ore: OreData = reg.find_ore(&"silver_gold") if reg != null else null
		if ore == null:
			return command.reject("Silver ore registry entry missing.")
		var cost_entry: ResourceAmount = ResourceAmount.new()
		cost_entry.ore = ore
		cost_entry.amount = node.silver_cost
		var costs: Array[ResourceAmount] = [cost_entry]
		var spend_cmd: SpendResourcesCommand = SpendResourcesCommand.new(cmd.player_id, costs)
		if not CommandBus.dispatch(spend_cmd):
			var fail_msg: String = spend_cmd.rejection_reason
			if fail_msg.is_empty():
				fail_msg = "Yetersiz gümüş (%d gerekiyor)." % node.silver_cost
			return command.reject(fail_msg)

	st.active_node_id = node.node_id
	st.active_elapsed_seasons = 0
	st.active_total_seasons = maxi(node.duration_seasons, 1)

	cmd.started = true
	cmd.silver_spent = node.silver_cost
	cmd.duration_seasons = st.active_total_seasons

	EventBus.tradition_research_started.emit(
		cmd.player_id, node.node_id, st.active_total_seasons, node.silver_cost)
	return true


static func step_seasonal_research(seasons_elapsed: int = 1) -> void:
	if _states.is_empty():
		return
	var step: int = maxi(seasons_elapsed, 1)
	var pids: Array[int] = []
	for k: int in _states.keys():
		pids.append(k)
	pids.sort()

	for pid: int in pids:
		var st: PlayerResearchState = _states[pid]
		if st == null or st.active_node_id == &"":
			continue
		var node: TraditionResearchNode = TraditionResearchCatalog.get_node_by_id(st.active_node_id)
		if node == null:
			st.active_node_id = &""
			st.active_elapsed_seasons = 0
			st.active_total_seasons = 0
			continue
		st.active_elapsed_seasons += step
		var clamped_elapsed: int = mini(st.active_elapsed_seasons, st.active_total_seasons)
		var progressing_id: StringName = st.active_node_id
		EventBus.tradition_research_progressed.emit(
			pid, progressing_id, clamped_elapsed, st.active_total_seasons)
		if st.active_elapsed_seasons >= st.active_total_seasons:
			if not st.completed_nodes.has(progressing_id):
				st.completed_nodes.append(progressing_id)
				_sort_completed_nodes(st.completed_nodes)
			st.active_node_id = &""
			st.active_elapsed_seasons = 0
			st.active_total_seasons = 0
			EventBus.tradition_research_completed.emit(
				pid, progressing_id, node.branch, node.effect_summary)


static func export_state_dict() -> Dictionary:
	var players_out: Dictionary = {}
	var pids: Array[int] = []
	for k: int in _states.keys():
		pids.append(k)
	pids.sort()
	for pid: int in pids:
		var st: PlayerResearchState = _states[pid]
		if st == null:
			continue
		var sorted_done: Array[StringName] = []
		for nid: StringName in st.completed_nodes:
			sorted_done.append(nid)
		_sort_completed_nodes(sorted_done)
		var comp_strs: Array[String] = []
		for nid2: StringName in sorted_done:
			comp_strs.append(String(nid2))
		players_out[String.num_int64(pid)] = {
			"active_node_id": String(st.active_node_id),
			"active_elapsed_seasons": st.active_elapsed_seasons,
			"active_total_seasons": st.active_total_seasons,
			"completed_nodes": comp_strs,
		}
	return {
		"players": players_out,
	}


static func import_state_dict(data: Dictionary) -> bool:
	if typeof(data) != TYPE_DICTIONARY or not data.has("players"):
		return false
	var raw_players: Variant = data.get("players")
	if typeof(raw_players) != TYPE_DICTIONARY:
		return false
	var p_dict: Dictionary = DeterministicStateHasher.v_dict(raw_players)
	var new_states: Dictionary[int, PlayerResearchState] = {}

	for k: Variant in p_dict.keys():
		var k_str: String = DeterministicStateHasher.v_str(k, "").strip_edges()
		if not k_str.is_valid_int():
			return false
		var pid: int = k_str.to_int()
		if pid <= 0:
			return false
		var entry_var: Variant = p_dict[k]
		if typeof(entry_var) != TYPE_DICTIONARY:
			return false
		var entry: Dictionary = DeterministicStateHasher.v_dict(entry_var)
		var st: PlayerResearchState = PlayerResearchState.new(pid)
		var raw_active: String = DeterministicStateHasher.v_str(entry.get("active_node_id", ""), "")
		if not raw_active.is_empty():
			var active_id: StringName = StringName(raw_active)
			if TraditionResearchCatalog.get_node_by_id(active_id) == null:
				return false
			st.active_node_id = active_id
		st.active_elapsed_seasons = maxi(DeterministicStateHasher.v_int(entry.get("active_elapsed_seasons", 0), 0), 0)
		st.active_total_seasons = maxi(DeterministicStateHasher.v_int(entry.get("active_total_seasons", 0), 0), 0)

		var raw_comp: Variant = entry.get("completed_nodes", [])
		if typeof(raw_comp) != TYPE_ARRAY:
			return false
		var comp_arr: Array = DeterministicStateHasher.v_arr(raw_comp)
		for item: Variant in comp_arr:
			var nid_str: String = DeterministicStateHasher.v_str(item, "")
			if nid_str.is_empty():
				return false
			var nid: StringName = StringName(nid_str)
			if TraditionResearchCatalog.get_node_by_id(nid) == null:
				return false
			if not st.completed_nodes.has(nid):
				st.completed_nodes.append(nid)
		_sort_completed_nodes(st.completed_nodes)
		new_states[pid] = st

	_states = new_states
	return true


static func _get_state(player_id: int) -> PlayerResearchState:
	if _states.has(player_id):
		return _states[player_id]
	return null


static func _get_or_create_state(player_id: int) -> PlayerResearchState:
	if _states.has(player_id):
		return _states[player_id]
	var created: PlayerResearchState = PlayerResearchState.new(player_id)
	_states[player_id] = created
	return created


static func _sort_completed_nodes(arr: Array[StringName]) -> void:
	arr.sort_custom(func(a: StringName, b: StringName) -> bool:
		return String(a) < String(b)
	)
