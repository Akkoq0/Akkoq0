extends Node
## Autoload `TerritoryManager` (rank 2). Implements Phase 19 **Hybrid Steppe
## Territory, Seasonal Yaylak/Kışlak Shift, Bozkır Tuğu Overlapping Zones,
## Yurt Claim Contestation FSM, Post-Conquest Aftermath, and Sacred Kurgan
## Majority Hegemony**.

const RULES_PATH: String = "res://data/conquest/conquest_rules.tres"
const STEEL_ORE_PATH: String = "res://data/ores/steel.tres"
const METEORIC_ORE_PATH: String = "res://data/ores/meteoric_iron.tres"
const REASON_YURT_CLAIM: StringName = &"yurt_claim_declaration"
const REASON_SACRED_KURGAN: StringName = &"sacred_kurgan_devotion"

var _rules: ConquestRules = null
var _steel_ore: OreData = null
var _meteoric_ore: OreData = null
var _regions: Dictionary[Vector2i, RegionData] = {}
var _nodes_by_id: Dictionary[StringName, BorderNode] = {}
var _claims: Dictionary[StringName, ClaimContestationFSM] = {}
var _active_claim_by_coord: Dictionary[Vector2i, StringName] = {}
var _region_claim_freeze_until: Dictionary[Vector2i, float] = {}
var _khagan_candidates: Dictionary[int, bool] = {}


func _ready() -> void:
	_rules = ResourceLoader.load(RULES_PATH) as ConquestRules
	if _rules == null:
		push_error("TerritoryManager: failed to load ConquestRules at %s." % RULES_PATH)
	else:
		for err: String in _rules.get_validation_errors():
			push_error("TerritoryManager: %s" % err)
	_steel_ore = ResourceLoader.load(STEEL_ORE_PATH) as OreData
	_meteoric_ore = ResourceLoader.load(METEORIC_ORE_PATH) as OreData

	CommandBus.register_handler(CaptureBorderNodeCommand.ID, _handle_capture_border_node)
	CommandBus.register_handler(OpenYurtClaimCommand.ID, _handle_open_yurt_claim)
	CommandBus.register_handler(RespondToYurtClaimCommand.ID, _handle_respond_to_yurt_claim)
	CommandBus.register_handler(ResolveConquestAftermathCommand.ID, _handle_resolve_conquest_aftermath)


func _exit_tree() -> void:
	CommandBus.unregister_handler(CaptureBorderNodeCommand.ID, _handle_capture_border_node)
	CommandBus.unregister_handler(OpenYurtClaimCommand.ID, _handle_open_yurt_claim)
	CommandBus.unregister_handler(RespondToYurtClaimCommand.ID, _handle_respond_to_yurt_claim)
	CommandBus.unregister_handler(ResolveConquestAftermathCommand.ID, _handle_resolve_conquest_aftermath)


func reset_territory_state() -> void:
	_regions.clear()
	_nodes_by_id.clear()
	_claims.clear()
	_active_claim_by_coord.clear()
	_region_claim_freeze_until.clear()
	_khagan_candidates.clear()


func get_rules() -> ConquestRules:
	return _rules


func register_region(
		coord: Vector2i,
		geography: GameEnums.RegionGeographyClass,
		owner_id: int = 0,
		is_core_oba: bool = false,
		has_sacred_kurgan: bool = false,
		initial_control: float = 100.0) -> RegionData:
	var reg: RegionData = RegionData.new(coord, geography, owner_id, is_core_oba, has_sacred_kurgan, initial_control)
	_regions[coord] = reg
	return reg


func get_region(coord: Vector2i) -> RegionData:
	if _regions.has(coord):
		return _regions[coord]
	return null


func add_border_node(
		coord: Vector2i,
		node_id: StringName,
		node_type: GameEnums.BorderNodeType,
		position: Vector3,
		ore_id: StringName = &"",
		initial_owner_id: int = 0) -> BorderNode:
	if node_id == &"":
		return null
	if not _regions.has(coord):
		register_region(coord, GameEnums.RegionGeographyClass.HIGH_PLATEAU_YAYLAK, 0, false, false, 100.0)
	var region: RegionData = _regions[coord]
	var node: BorderNode = BorderNode.new(node_id, coord, node_type, position, ore_id, initial_owner_id)
	if initial_owner_id > 0:
		node.has_tug_planted = true
		node.tug_radius_m = compute_effective_tug_radius(initial_owner_id)
	region.border_nodes.append(node)
	_nodes_by_id[node_id] = node
	return node


func get_border_node(node_id: StringName) -> BorderNode:
	if _nodes_by_id.has(node_id):
		return _nodes_by_id[node_id]
	return null


## Computes player's Bozkır Tuğu sphere radius scaled by Jade Tamga/Authority.
func compute_effective_tug_radius(player_id: int) -> float:
	var base_r: float = _rules.base_tug_radius_m if _rules != null else 120.0
	if player_id <= 0:
		return base_r
	return base_r * ResourceManager.calculate_jade_authority_multiplier(player_id)


func get_overlapping_enemy_tugs(node_id: StringName) -> int:
	if not _nodes_by_id.has(node_id):
		return 0
	var node: BorderNode = _nodes_by_id[node_id]
	var count: int = 0
	for other_id: StringName in _nodes_by_id:
		var other: BorderNode = _nodes_by_id[other_id]
		if node.overlaps_enemy_tug(other):
			count += 1
	return count


## Computes active caravan logistics disruption ratio [0, 0.85] caused by overlapping hostile Tuğ spheres.
func get_caravan_disruption_in_region(coord: Vector2i, defender_id: int) -> float:
	if not _regions.has(coord):
		return 0.0
	var region: RegionData = _regions[coord]
	var overlaps: int = 0
	for n: BorderNode in region.border_nodes:
		if n.owner_id == defender_id and n.has_tug_planted:
			for other_id: StringName in _nodes_by_id:
				var other: BorderNode = _nodes_by_id[other_id]
				if n.overlaps_enemy_tug(other):
					overlaps += 1
	var step_ratio: float = _rules.overlap_caravan_disruption_ratio if _rules != null else 0.35
	return clampf(float(overlaps) * step_ratio, 0.0, 0.85)


func get_claim(claim_id: StringName) -> ClaimContestationFSM:
	if _claims.has(claim_id):
		return _claims[claim_id]
	return null


func raise_region_control(coord: Vector2i, actor_id: int, use_toy_festival: bool = false) -> float:
	if not _regions.has(coord):
		return 0.0
	var region: RegionData = _regions[coord]
	if region.owner_id != actor_id:
		return region.control_percent
	var gain: float = 15.0
	if _rules != null:
		gain = _rules.toy_festival_control_gain if use_toy_festival else _rules.garrison_control_gain_per_step
	region.control_percent = clampf(region.control_percent + gain, 0.0, 100.0)
	return region.control_percent


func count_owned_regions(player_id: int) -> int:
	var count: int = 0
	for coord: Vector2i in _regions:
		if _regions[coord].owner_id == player_id:
			count += 1
	return count


func get_owned_region_coords(player_id: int) -> Array[Vector2i]:
	var coords: Array[Vector2i] = []
	for coord: Vector2i in _regions:
		if _regions[coord].owner_id == player_id:
			coords.append(coord)
	return coords


func count_sacred_kurgans() -> int:
	var total: int = 0
	for coord: Vector2i in _regions:
		if _regions[coord].has_sacred_kurgan:
			total += 1
	return total


func count_player_kurgans(player_id: int) -> int:
	var owned: int = 0
	for coord: Vector2i in _regions:
		var reg: RegionData = _regions[coord]
		if reg.has_sacred_kurgan and (reg.kurgan_owner_id == player_id or reg.owner_id == player_id):
			owned += 1
	return owned


func is_great_khagan_candidate(player_id: int) -> bool:
	return _khagan_candidates.get(player_id, false)


## Evaluates whether `player_id` holds a qualifying majority of Sacred Kurgans,
## proclaiming `"Büyük Kağan Adayı"` and surging rival Coalition war pressure.
func evaluate_sacred_kurgan_hegemony(player_id: int) -> bool:
	if player_id <= 0:
		return false
	var total_kurgans: int = count_sacred_kurgans()
	if total_kurgans <= 0:
		return false
	var owned_kurgans: int = count_player_kurgans(player_id)
	var ratio_needed: float = _rules.kurgan_majority_threshold_ratio if _rules != null else 0.51
	var majority: bool = (float(owned_kurgans) / float(total_kurgans)) >= ratio_needed
	if not majority:
		return false
	if not _khagan_candidates.get(player_id, false):
		_khagan_candidates[player_id] = true
		var spike: float = _rules.kurgan_hegemon_threat_spike if _rules != null else 40.0
		var coalition_triggered: bool = DiplomacyManager.add_diplomatic_infamy_spike(spike, true)
		EventBus.great_khagan_candidate_proclaimed.emit(player_id, owned_kurgans, total_kurgans, coalition_triggered)
	return true


## Advances registered territories by one season (cooling Scorched Earth timers,
## computing seasonal Yaylak/Kışlak modifiers, and granting Sacred Kurgan Kut bonus
## for `player_id` when holding sacred cores).
func step_seasonal_territory_cycle(season_type: GameEnums.SeasonType, player_id: int = 0) -> Dictionary[Vector2i, float]:
	var kut_bonuses: Dictionary[Vector2i, float] = {}
	for coord: Vector2i in _regions:
		var reg: RegionData = _regions[coord]
		if reg.scorched_seasons_remaining > 0:
			reg.scorched_seasons_remaining -= 1
		var mods: Dictionary[StringName, float] = reg.compute_seasonal_modifiers(season_type, _rules)
		if player_id > 0 and reg.has_sacred_kurgan and (reg.kurgan_owner_id == player_id or reg.owner_id == player_id):
			var kut_gain: float = mods[&"kurgan_kut_bonus"]
			if kut_gain > 0.0:
				CommandBus.dispatch(ModifyKutCommand.new(kut_gain, REASON_SACRED_KURGAN))
				kut_bonuses[coord] = kut_gain
	return kut_bonuses


func _handle_capture_border_node(command: GameCommand) -> bool:
	var cmd: CaptureBorderNodeCommand = command as CaptureBorderNodeCommand
	if cmd == null:
		return command.reject("Expected CaptureBorderNodeCommand.")
	if cmd.actor_id <= 0 or cmd.node_id == &"":
		return command.reject("CaptureBorderNodeCommand requires actor_id > 0 and non-empty node_id.")
	if not _nodes_by_id.has(cmd.node_id):
		return command.reject("Unknown BorderNode '%s'." % cmd.node_id)

	var node: BorderNode = _nodes_by_id[cmd.node_id]
	var prev_owner: int = node.owner_id
	var action: GameEnums.ToreActionType = GameEnums.ToreActionType.UNCLAIMED_NODE_TUG if prev_owner == 0 else GameEnums.ToreActionType.BORDER_NODE_RAID
	if not GracePeriodManager.validate_and_commit_action(cmd.actor_id, action, prev_owner):
		return command.reject("Action blocked by active Töre Peace.")

	cmd.previous_owner_id = prev_owner
	node.owner_id = cmd.actor_id
	node.has_tug_planted = cmd.plant_tug
	node.tug_radius_m = compute_effective_tug_radius(cmd.actor_id) if cmd.plant_tug else 0.0

	var overlaps: int = get_overlapping_enemy_tugs(node.node_id)
	var step_ratio: float = _rules.overlap_caravan_disruption_ratio if _rules != null else 0.35
	cmd.tug_radius_m = node.tug_radius_m
	cmd.overlapping_enemy_tug_count = overlaps
	cmd.caravan_disruption_ratio = clampf(float(overlaps) * step_ratio, 0.0, 0.85)

	EventBus.border_node_captured.emit(
		node.region_coord, node.node_id, prev_owner, cmd.actor_id, node.tug_radius_m, overlaps)
	return true


func _handle_open_yurt_claim(command: GameCommand) -> bool:
	var cmd: OpenYurtClaimCommand = command as OpenYurtClaimCommand
	if cmd == null:
		return command.reject("Expected OpenYurtClaimCommand.")
	if cmd.claim_id == &"" or cmd.challenger_id <= 0:
		return command.reject("OpenYurtClaimCommand requires non-empty claim_id and positive challenger_id.")
	if _claims.has(cmd.claim_id):
		return command.reject("Yurt Claim '%s' already exists." % cmd.claim_id)
	if not _regions.has(cmd.target_coord):
		return command.reject("Unknown target region %s." % cmd.target_coord)

	var region: RegionData = _regions[cmd.target_coord]
	if region.owner_id == cmd.challenger_id:
		return command.reject("Challenger already owns region %s." % cmd.target_coord)

	var action: GameEnums.ToreActionType = GameEnums.ToreActionType.KURGAN_CONTEST if region.has_sacred_kurgan else GameEnums.ToreActionType.CORE_YURT_CLAIM
	if not GracePeriodManager.validate_and_commit_action(cmd.challenger_id, action, region.owner_id):
		return command.reject("Yurt Claim blocked by active Töre Peace.")

	var cur_hours: float = GracePeriodManager.get_server_elapsed_hours()
	if _region_claim_freeze_until.has(cmd.target_coord):
		var frozen_until: float = _region_claim_freeze_until[cmd.target_coord]
		if cur_hours < frozen_until:
			return command.reject("Region %s is protected by active Ülüş Tribute freeze." % cmd.target_coord)

	var kut_cost: float = _rules.claim_kut_cost if _rules != null else 8.0
	var glory_cost: float = _rules.claim_glory_cost if _rules != null else 10.0
	if cmd.challenger_glory < glory_cost:
		return command.reject("Insufficient Khagan Glory (%.1f < %.1f) for Yurt Claim." % [cmd.challenger_glory, glory_cost])
	if GameManager.get_kut_score() < kut_cost:
		return command.reject("Insufficient Kut (%.1f < %.1f) for Yurt Claim." % [GameManager.get_kut_score(), kut_cost])

	CommandBus.dispatch(ModifyKutCommand.new(-kut_cost, REASON_YURT_CLAIM))

	var base_hours: float = _rules.claim_contestation_hours if _rules != null else 18.0
	var window_hours: float = cmd.contestation_hours_override if cmd.contestation_hours_override > 0.0 else base_hours
	window_hours = clampf(window_hours, 12.0, 24.0)

	var fsm: ClaimContestationFSM = ClaimContestationFSM.new()
	fsm.open_window(cmd.claim_id, cmd.challenger_id, region.owner_id, cmd.target_coord, window_hours)
	_claims[cmd.claim_id] = fsm
	_active_claim_by_coord[cmd.target_coord] = cmd.claim_id

	cmd.defender_id = region.owner_id
	cmd.contestation_hours = fsm.remaining_window_hours
	cmd.kut_spent = kut_cost
	cmd.glory_spent = glory_cost
	cmd.stage = fsm.stage

	EventBus.yurt_claim_opened.emit(
		cmd.claim_id, cmd.challenger_id, region.owner_id, cmd.target_coord, fsm.remaining_window_hours)
	return true


func _handle_respond_to_yurt_claim(command: GameCommand) -> bool:
	var cmd: RespondToYurtClaimCommand = command as RespondToYurtClaimCommand
	if cmd == null:
		return command.reject("Expected RespondToYurtClaimCommand.")
	if not _claims.has(cmd.claim_id):
		return command.reject("Unknown Yurt Claim '%s'." % cmd.claim_id)
	var fsm: ClaimContestationFSM = _claims[cmd.claim_id]
	if fsm.stage != GameEnums.ClaimContestationStage.WINDOW_OPEN:
		return command.reject("Yurt Claim '%s' is not in WINDOW_OPEN state." % cmd.claim_id)
	if fsm.defender_id > 0 and cmd.responder_id != fsm.defender_id:
		return command.reject("Only defender %d may respond to Yurt Claim '%s'." % [fsm.defender_id, cmd.claim_id])

	var cur_hours: float = GracePeriodManager.get_server_elapsed_hours()
	var freeze_hours: float = _rules.tribute_freeze_hours if _rules != null else 24.0
	var won_battle: bool = cmd.challenger_won_battle

	if cmd.response == GameEnums.ClaimDefenseResponse.ACCEPT_PITCHED_BATTLE:
		if cmd.attacker_stats != null and cmd.defender_stats != null:
			var combat_cmd: ResolveCombatCommand = ResolveCombatCommand.new(
				cmd.attacker_stats, cmd.defender_stats, null, cmd.rng_seed)
			CommandBus.dispatch(combat_cmd)
			won_battle = cmd.defender_stats.health <= 0.0 or cmd.attacker_stats.health >= cmd.defender_stats.health
	elif cmd.response == GameEnums.ClaimDefenseResponse.PAY_ULUS_TRIBUTE:
		var steel_cost: int = _rules.tribute_steel_cost if _rules != null else 8
		var meteor_cost: int = _rules.tribute_meteoric_cost if _rules != null else 2
		var costs: Array[ResourceAmount] = []
		if steel_cost > 0 and _steel_ore != null:
			var ra_s: ResourceAmount = ResourceAmount.new()
			ra_s.ore = _steel_ore
			ra_s.amount = steel_cost
			costs.append(ra_s)
		if meteor_cost > 0 and _meteoric_ore != null:
			var ra_m: ResourceAmount = ResourceAmount.new()
			ra_m.ore = _meteoric_ore
			ra_m.amount = meteor_cost
			costs.append(ra_m)
		if not costs.is_empty():
			var spend: SpendResourcesCommand = SpendResourcesCommand.new(cmd.responder_id, costs)
			if not CommandBus.dispatch(spend):
				return command.reject("Defender %d cannot afford Ülüş Tribute (%d Steel, %d Meteoric Iron)." % [
					cmd.responder_id, steel_cost, meteor_cost])
			if steel_cost > 0:
				CommandBus.dispatch(DepositResourcesCommand.new(fsm.challenger_id, &"steel", steel_cost))
			if meteor_cost > 0:
				CommandBus.dispatch(DepositResourcesCommand.new(fsm.challenger_id, &"meteoric_iron", meteor_cost))
		cmd.tribute_paid = true
		_region_claim_freeze_until[fsm.target_coord] = cur_hours + freeze_hours
		cmd.freeze_until_hours = cur_hours + freeze_hours
	elif cmd.response == GameEnums.ClaimDefenseResponse.KILL_ENVOY_KAN_DAVASI:
		var trust_pen: float = _rules.kan_davasi_trust_penalty if _rules != null else -35.0
		var threat_spike: float = _rules.kan_davasi_coalition_threat_boost if _rules != null else 35.0
		DiplomacyManager.modify_all_dynasty_trust(trust_pen)
		DiplomacyManager.add_diplomatic_infamy_spike(threat_spike, true)
		IntelligenceManager.declare_blood_feud_total_war(cmd.responder_id, fsm.challenger_id)
		cmd.kan_davasi_triggered = true
		cmd.trust_penalty_applied = trust_pen

	var resulting: GameEnums.ClaimContestationStage = fsm.apply_defense_response(
		cmd.response, cur_hours, freeze_hours, won_battle)
	cmd.resulting_stage = resulting
	cmd.winner_id = fsm.winner_id

	EventBus.yurt_claim_responded.emit(cmd.claim_id, cmd.response, resulting, fsm.winner_id)
	return true


func _handle_resolve_conquest_aftermath(command: GameCommand) -> bool:
	var cmd: ResolveConquestAftermathCommand = command as ResolveConquestAftermathCommand
	if cmd == null:
		return command.reject("Expected ResolveConquestAftermathCommand.")
	if cmd.actor_id <= 0 or not _regions.has(cmd.target_coord):
		return command.reject("ResolveConquestAftermathCommand requires actor_id > 0 and valid region.")

	if _active_claim_by_coord.has(cmd.target_coord):
		var c_id: StringName = _active_claim_by_coord[cmd.target_coord]
		if _claims.has(c_id):
			var fsm: ClaimContestationFSM = _claims[c_id]
			if fsm.stage == GameEnums.ClaimContestationStage.TRIBUTE_FROZEN:
				return command.reject("Cannot conquer region frozen by Ülüş Tribute.")
			if (fsm.stage == GameEnums.ClaimContestationStage.PITCHED_BATTLE_ACCEPTED or fsm.stage == GameEnums.ClaimContestationStage.RESOLVED) \
					and fsm.winner_id > 0 and fsm.winner_id != cmd.actor_id:
				return command.reject("Claim '%s' was won by faction %d, not %d." % [c_id, fsm.winner_id, cmd.actor_id])

	var region: RegionData = _regions[cmd.target_coord]
	var init_ctrl: float = _rules.initial_conquest_control if _rules != null else 20.0
	var vassal_bonus: float = _rules.vassal_appointment_control_bonus if _rules != null else 25.0
	var scorch_seasons: int = _rules.scorched_earth_duration_seasons if _rules != null else 4
	var pillage_bullion: int = _rules.scorched_earth_pillage_bullion if _rules != null else 55
	var pillage_slaves: int = _rules.scorched_earth_captive_workers if _rules != null else 35

	region.owner_id = cmd.actor_id
	region.is_core_oba = false
	if region.has_sacred_kurgan:
		region.kurgan_owner_id = cmd.actor_id

	if cmd.choice == GameEnums.ConquestAftermathChoice.SCORCHED_EARTH_PILLAGE:
		region.scorched_seasons_remaining = scorch_seasons
		region.control_percent = 10.0
		region.vassal_bey_id = &""
		CommandBus.dispatch(DepositResourcesCommand.new(cmd.actor_id, &"silver_gold", pillage_bullion))
		CommandBus.dispatch(AssignCaptiveLaborCommand.new(cmd.actor_id, pillage_slaves, 100))
		cmd.bullion_gained = pillage_bullion
		cmd.captives_gained = pillage_slaves
		cmd.scorched_seasons = scorch_seasons
	elif cmd.choice == GameEnums.ConquestAftermathChoice.HOLD_GARRISON_CONTROL:
		region.scorched_seasons_remaining = 0
		region.control_percent = init_ctrl
		region.vassal_bey_id = &""
		cmd.scorched_seasons = 0
	elif cmd.choice == GameEnums.ConquestAftermathChoice.APPOINT_VASSAL_BEY:
		region.scorched_seasons_remaining = 0
		region.control_percent = clampf(init_ctrl + vassal_bonus, 0.0, 100.0)
		region.vassal_bey_id = cmd.vassal_bey_id
		cmd.scorched_seasons = 0

	cmd.new_owner_id = region.owner_id
	cmd.resulting_control_percent = region.control_percent

	if _active_claim_by_coord.has(cmd.target_coord):
		var claim_key: StringName = _active_claim_by_coord[cmd.target_coord]
		if _claims.has(claim_key):
			_claims[claim_key].mark_resolved(cmd.actor_id)

	cmd.became_khagan_candidate = evaluate_sacred_kurgan_hegemony(cmd.actor_id)
	cmd.coalition_triggered = DiplomacyManager.is_coalition_war_active()

	EventBus.region_control_changed.emit(
		region.coord, region.owner_id, region.control_percent, cmd.choice, region.scorched_seasons_remaining)
	return true
