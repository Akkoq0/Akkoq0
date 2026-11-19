class_name ResearchTreeViewModel
extends RefCounted
## UI ViewModel (rank 4). Strictly read-only aggregator for the 4-branch Steppe
## Tradition & Military Research DAG and live `DoctrineMatchupResolver` tactical
## matchup previews. Never mutates core managers directly; dispatches research
## commands exclusively through `CommandBus` / `CommandEnvelope`.


class ResearchNodeView:
	extends RefCounted
	var node_id: StringName = &""
	var title: String = ""
	var description: String = ""
	var effect_summary: String = ""
	var branch: GameEnums.ResearchBranch = GameEnums.ResearchBranch.STEPPE_WARFARE
	var branch_label: String = ""
	var tier: int = 1
	var prerequisites: PackedStringArray = PackedStringArray()
	var silver_cost: int = 0
	var duration_seasons: int = 1
	var status: GameEnums.ResearchNodeStatus = GameEnums.ResearchNodeStatus.LOCKED
	var can_afford: bool = false
	var can_start: bool = false
	var is_active: bool = false
	var progress_ratio: float = 0.0
	var elapsed_seasons: int = 0
	var missing_prereq_titles: PackedStringArray = PackedStringArray()


class ResearchEdgeView:
	extends RefCounted
	var from_id: StringName = &""
	var to_id: StringName = &""
	var from_completed: bool = false
	var to_unlocked: bool = false


class ResearchTreeSnapshot:
	extends RefCounted
	var player_id: int = 1
	var silver_stock: int = 0
	var active_node_id: StringName = &""
	var active_title: String = ""
	var active_elapsed_seasons: int = 0
	var active_total_seasons: int = 0
	var active_progress_ratio: float = 0.0
	var completed_count: int = 0
	var total_count: int = 0
	var nodes: Array[ResearchNodeView] = []
	var edges: Array[ResearchEdgeView] = []
	var bonuses: TraditionResearchManager.ResearchBonusesSnapshot = null


class StartResearchDispatchResult:
	extends RefCounted
	var ok: bool = false
	var message: String = ""
	var silver_spent: int = 0


class DoctrineMatchupPreviewSnapshot:
	extends RefCounted
	var attacker_preset_id: GameEnums.BattleDoctrinePresetId = GameEnums.BattleDoctrinePresetId.TOLGAMA_KISKACI
	var attacker_doctrine_name: String = ""
	var defender_preset_id: GameEnums.BattleDoctrinePresetId = GameEnums.BattleDoctrinePresetId.BORU_KAMASI
	var defender_doctrine_name: String = ""
	var engagement_angle: GameEnums.CombatEngagementAngle = GameEnums.CombatEngagementAngle.FRONT
	var is_mud: bool = false
	var is_steep_slope: bool = false
	var is_storm: bool = false
	var attacker_attack_mult: float = 1.0
	var defender_defense_mult: float = 1.0
	var attacker_mobility_mult: float = 1.0
	var defender_mobility_mult: float = 1.0
	var attacker_fatigue_mult: float = 1.0
	var advantage_score: float = 1.0
	var verdict_label: String = ""
	var verdict_tone_id: StringName = &"gold"
	var highlights: PackedStringArray = PackedStringArray()
	var raw_result: DoctrineMatchupResult = null


var _player_id: int = 1
var _army_id: int = 1
var _region_coord: Vector2i = Vector2i(3, 3)
var _army_ref: WeakRef = null
var _envelope_seq: int = 0


func _init(
		p_player_id: int = 1,
		p_army_id: int = 1,
		p_region_coord: Vector2i = Vector2i(3, 3)) -> void:
	_player_id = maxi(p_player_id, 1)
	_army_id = maxi(p_army_id, 1)
	_region_coord = p_region_coord


func set_context(
		p_player_id: int,
		p_army_id: int = -1,
		p_region_coord: Vector2i = Vector2i(-1, -1)) -> void:
	_player_id = maxi(p_player_id, 1)
	if p_army_id > 0:
		_army_id = p_army_id
	if p_region_coord.x >= 0 and p_region_coord.y >= 0:
		_region_coord = p_region_coord


func bind_army(army: ArmyController) -> void:
	_army_ref = weakref(army) if army != null else null
	if army != null:
		_army_id = maxi(army.army_id, 1)
		_player_id = maxi(army.owner_id, 1)


func get_player_id() -> int:
	return _player_id


func capture_tree_snapshot() -> ResearchTreeSnapshot:
	var snap: ResearchTreeSnapshot = ResearchTreeSnapshot.new()
	snap.player_id = _player_id
	snap.silver_stock = ResourceManager.get_amount(_player_id, &"silver_gold")
	snap.active_node_id = TraditionResearchManager.get_active_node_id(_player_id)
	snap.active_elapsed_seasons = TraditionResearchManager.get_active_elapsed_seasons(_player_id)
	snap.active_total_seasons = TraditionResearchManager.get_active_total_seasons(_player_id)
	snap.active_progress_ratio = TraditionResearchManager.get_active_progress_ratio(_player_id)
	snap.bonuses = TraditionResearchManager.get_player_bonuses(_player_id)

	var all_nodes: Array[TraditionResearchNode] = TraditionResearchCatalog.get_all_nodes()
	snap.total_count = all_nodes.size()
	var busy_with_other: bool = snap.active_node_id != &""

	for n: TraditionResearchNode in all_nodes:
		if n == null:
			continue
		var view: ResearchNodeView = ResearchNodeView.new()
		view.node_id = n.node_id
		view.title = n.title
		view.description = n.description
		view.effect_summary = n.effect_summary
		view.branch = n.branch
		view.branch_label = TraditionResearchCatalog.format_branch_name(n.branch)
		view.tier = n.tier
		view.prerequisites = n.prerequisites
		view.silver_cost = n.silver_cost
		view.duration_seasons = n.duration_seasons
		view.status = TraditionResearchManager.get_node_status(_player_id, n.node_id)
		view.can_afford = snap.silver_stock >= n.silver_cost
		view.is_active = view.status == GameEnums.ResearchNodeStatus.IN_PROGRESS
		if view.is_active:
			snap.active_title = n.title
			view.elapsed_seasons = snap.active_elapsed_seasons
			view.progress_ratio = snap.active_progress_ratio
		elif view.status == GameEnums.ResearchNodeStatus.COMPLETED:
			snap.completed_count += 1
			view.elapsed_seasons = n.duration_seasons
			view.progress_ratio = 1.0

		for req_str: String in n.prerequisites:
			var req_id: StringName = StringName(req_str)
			if req_id == &"":
				continue
			var req_done: bool = TraditionResearchManager.is_node_completed(_player_id, req_id)
			if not req_done:
				var req_node: TraditionResearchNode = TraditionResearchCatalog.get_node_by_id(req_id)
				var req_title: String = req_node.title if req_node != null else req_str
				view.missing_prereq_titles.append(req_title)

			var edge: ResearchEdgeView = ResearchEdgeView.new()
			edge.from_id = req_id
			edge.to_id = n.node_id
			edge.from_completed = req_done
			edge.to_unlocked = view.status != GameEnums.ResearchNodeStatus.LOCKED
			snap.edges.append(edge)

		view.can_start = (
			view.status == GameEnums.ResearchNodeStatus.RESEARCHABLE
			and not busy_with_other
			and view.can_afford
		)
		snap.nodes.append(view)

	return snap


func build_start_research_envelope(node_id: StringName) -> CommandEnvelope:
	var sender_str: String = "player_%d" % _player_id
	var min_seq: int = CommandBus.get_last_sequence_for_sender(sender_str) + 1
	_envelope_seq = maxi(_envelope_seq + 1, min_seq)
	var tick: int = SessionClockAuthority.get_current_tick()
	var payload: Dictionary = {
		"player_id": _player_id,
		"node_id": String(node_id),
	}
	return CommandEnvelope.new(_envelope_seq, sender_str, tick, "start_research", payload)


func dispatch_start_research(node_id: StringName) -> StartResearchDispatchResult:
	var res: StartResearchDispatchResult = StartResearchDispatchResult.new()
	var node: TraditionResearchNode = TraditionResearchCatalog.get_node_by_id(node_id)
	var tick: int = SessionClockAuthority.get_current_tick()
	var env: CommandEnvelope = build_start_research_envelope(node_id)
	var enqueued: bool = CommandBus.enqueue_envelope(env, tick)
	if not enqueued:
		res.ok = false
		res.message = env.rejection_reason if not env.rejection_reason.is_empty() else "Araştırma emri reddedildi."
		return res
	var flushed: int = CommandBus.flush_envelopes_for_tick(tick)
	if flushed > 0 and TraditionResearchManager.get_active_node_id(_player_id) == node_id and node != null:
		res.ok = true
		res.silver_spent = node.silver_cost
		res.message = "%s başlatıldı (%d mevsim · %d Gümüş)." % [node.title, maxi(node.duration_seasons, 1), node.silver_cost]
		return res

	res.ok = false
	if node == null:
		res.message = "Bilinmeyen araştırma düğümü."
	elif TraditionResearchManager.get_active_node_id(_player_id) != &"":
		res.message = "Aktif araştırma sürerken yeni araştırma başlatılamaz."
	elif not TraditionResearchManager.are_prerequisites_met(_player_id, node_id):
		res.message = "Ön koşul araştırmalar tamamlanmadı."
	elif ResourceManager.get_amount(_player_id, &"silver_gold") < node.silver_cost:
		res.message = "Yetersiz gümüş (%d gerekiyor)." % node.silver_cost
	else:
		res.message = "Araştırma başlatılamadı."
	return res


func get_available_doctrine_presets() -> Array[BattleDoctrineResource]:
	return DoctrinePresetCatalog.create_all_presets()


func get_active_army_preset_id() -> GameEnums.BattleDoctrinePresetId:
	var army_doc: BattleDoctrineResource = CombatCalculator.get_assigned_doctrine(_army_id)
	if army_doc != null:
		return army_doc.preset_id
	var player_doc: BattleDoctrineResource = CombatCalculator.get_assigned_doctrine(_player_id)
	if player_doc != null:
		return player_doc.preset_id
	return GameEnums.BattleDoctrinePresetId.TOLGAMA_KISKACI


func evaluate_doctrine_preview(
		own_preset: GameEnums.BattleDoctrinePresetId,
		enemy_preset: GameEnums.BattleDoctrinePresetId,
		engagement_angle: GameEnums.CombatEngagementAngle = GameEnums.CombatEngagementAngle.FRONT,
		is_mud: bool = false,
		is_steep_slope: bool = false,
		is_storm: bool = false) -> DoctrineMatchupPreviewSnapshot:
	var atk_stats: CombatantStats = null
	if _army_ref != null:
		var obj: Object = _army_ref.get_ref()
		if obj != null and is_instance_valid(obj):
			var army: ArmyController = obj as ArmyController
			if army != null:
				atk_stats = army.get_combatant_stats()
	if atk_stats == null:
		atk_stats = CombatantStats.new(_army_id, 210.0, 140.0, 1200.0, 1.0)
		atk_stats.player_id = _player_id
		atk_stats.army_id = _army_id
		atk_stats.troop_count = 120
		atk_stats.region_coord = _region_coord

	var rival_pid: int = 999
	var def_stats: CombatantStats = CombatantStats.new(rival_pid, 200.0, 140.0, 1200.0, 1.0)
	def_stats.player_id = rival_pid
	def_stats.army_id = rival_pid
	def_stats.troop_count = 120
	def_stats.region_coord = _region_coord

	var own_doc: BattleDoctrineResource = DoctrinePresetCatalog.create_preset(own_preset)
	var enemy_doc: BattleDoctrineResource = DoctrinePresetCatalog.create_preset(enemy_preset)
	var cur_season: SeasonData = SeasonManager.get_current_season()

	var raw: DoctrineMatchupResult = DoctrineMatchupResolver.evaluate(
		atk_stats,
		def_stats,
		own_doc,
		enemy_doc,
		null,
		cur_season,
		engagement_angle,
		is_mud,
		is_steep_slope,
		is_storm,
		_region_coord)
	TraditionResearchManager.apply_bonuses_to_matchup(raw, _player_id, rival_pid)

	var preview: DoctrineMatchupPreviewSnapshot = DoctrineMatchupPreviewSnapshot.new()
	preview.attacker_preset_id = own_preset
	preview.attacker_doctrine_name = own_doc.display_name if own_doc != null else "Özel Düzen"
	preview.defender_preset_id = enemy_preset
	preview.defender_doctrine_name = enemy_doc.display_name if enemy_doc != null else "Rakip Düzen"
	preview.engagement_angle = engagement_angle
	preview.is_mud = is_mud
	preview.is_steep_slope = is_steep_slope
	preview.is_storm = is_storm
	preview.raw_result = raw

	if raw != null:
		preview.attacker_attack_mult = raw.attacker_attack_multiplier
		preview.defender_defense_mult = raw.defender_defense_multiplier
		preview.attacker_mobility_mult = raw.attacker_mobility_multiplier
		preview.defender_mobility_mult = raw.defender_mobility_multiplier
		preview.attacker_fatigue_mult = raw.attacker_fatigue_multiplier
		preview.advantage_score = raw.attacker_attack_multiplier / maxf(raw.defender_defense_multiplier, 0.35)

		if raw.heavy_armor_terrain_collapse:
			preview.verdict_label = "Çöküş Riski"
			preview.verdict_tone_id = &"ember"
		elif preview.advantage_score >= 1.18:
			preview.verdict_label = "Üstün Eşleşme"
			preview.verdict_tone_id = &"jade"
		elif preview.advantage_score >= 0.94:
			preview.verdict_label = "Dengeli Çarpışma"
			preview.verdict_tone_id = &"gold"
		else:
			preview.verdict_label = "Zayıf Eşleşme"
			preview.verdict_tone_id = &"ember"

		var hl: PackedStringArray = PackedStringArray()
		if raw.wedge_pierced_thin_center:
			hl.append("Börü Kaması rakibin ince merkezini yardı!")
		if raw.feigned_retreat_lure_succeeded:
			hl.append("Kurt Kapanı sahte ricat pususu tuttu (Arka Vuruş).")
		if raw.heavy_armor_terrain_collapse:
			hl.append("Ağır zırh çamur/yamaçta tıkandı (Yorgunluk x%.1f)!" % raw.attacker_fatigue_multiplier)
		if raw.laager_encirclement_damped:
			hl.append("Rakip Araba Kalesi kuşatma darbesini sönümlüyor.")
		if raw.tonyukuk_attrition_triggered:
			hl.append("Tonyukuk yıpratması düşman düzenini zayıflatıyor.")
		if raw.plan_exposed_by_courier:
			hl.append("Sızan ulak nedeniyle taarruz sürprizi kayboldu (-%25).")
		for r_line: String in raw.summary_reasons:
			if not r_line.is_empty() and not hl.has(r_line):
				hl.append(r_line)
		if hl.is_empty():
			hl.append("Standart Bozkır düzeni teması bekleniyor.")
		preview.highlights = hl

	return preview
