extends Node
## Autoload `ReputationAndPactSystem` (rank 2). Implements Phase 22 **Amanat
## Pacts (`Seal`/`Break`), Word Reliability Memory, Silver-Funded Covert Proxy
## Wars (`Yersiz Yurtsuz`), and Strategic Symmetry Between Dread (`Dehşet`)
## and Honor/Töre (`Töre Saygınlığı`)**.

const RULES_PATH: String = "res://data/governance/politics_and_pacts_rules.tres"
const DEFAULT_WORD_RELIABILITY: float = 80.0
const DEFAULT_DREAD_SCORE: float = 0.0
const DEFAULT_HONOR_SCORE: float = 50.0

var _rules: PoliticsAndPactsRules = null
var _word_reliability: Dictionary[int, float] = {}
var _dread_score: Dictionary[int, float] = {}
var _honor_score: Dictionary[int, float] = {}
var _pacts: Dictionary[StringName, AmanatPactRecord] = {}
var _proxy_wars: Dictionary[StringName, ProxyWarContract] = {}
var _casus_belli: Dictionary[StringName, bool] = {}


func _ready() -> void:
	_rules = ResourceLoader.load(RULES_PATH) as PoliticsAndPactsRules
	if _rules == null:
		push_error("ReputationAndPactSystem: failed to load PoliticsAndPactsRules at %s." % RULES_PATH)
	else:
		for err: String in _rules.get_validation_errors():
			push_error("ReputationAndPactSystem: %s" % err)
	CommandBus.register_handler(SealAmanatPactCommand.ID, _handle_seal_amanat)
	CommandBus.register_handler(BreakAmanatPactCommand.ID, _handle_break_amanat)
	CommandBus.register_handler(SponsorProxyWarCommand.ID, _handle_sponsor_proxy_war)
	CommandBus.register_handler(InvestigateProxyWarCommand.ID, _handle_investigate_proxy_war)


func _exit_tree() -> void:
	CommandBus.unregister_handler(SealAmanatPactCommand.ID, _handle_seal_amanat)
	CommandBus.unregister_handler(BreakAmanatPactCommand.ID, _handle_break_amanat)
	CommandBus.unregister_handler(SponsorProxyWarCommand.ID, _handle_sponsor_proxy_war)
	CommandBus.unregister_handler(InvestigateProxyWarCommand.ID, _handle_investigate_proxy_war)


func reset_reputation_state() -> void:
	_word_reliability.clear()
	_dread_score.clear()
	_honor_score.clear()
	_pacts.clear()
	_proxy_wars.clear()
	_casus_belli.clear()


func get_rules() -> PoliticsAndPactsRules:
	return _rules


func get_word_reliability(player_id: int) -> float:
	if _word_reliability.has(player_id):
		return _word_reliability[player_id]
	_word_reliability[player_id] = DEFAULT_WORD_RELIABILITY
	return DEFAULT_WORD_RELIABILITY


func get_dread_score(player_id: int) -> float:
	if _dread_score.has(player_id):
		return _dread_score[player_id]
	_dread_score[player_id] = DEFAULT_DREAD_SCORE
	return DEFAULT_DREAD_SCORE


func get_honor_score(player_id: int) -> float:
	if _honor_score.has(player_id):
		return _honor_score[player_id]
	_honor_score[player_id] = DEFAULT_HONOR_SCORE
	return DEFAULT_HONOR_SCORE


func get_pact(pact_id: StringName) -> AmanatPactRecord:
	if _pacts.has(pact_id):
		return _pacts[pact_id]
	return null


func get_proxy_war(warband_id: StringName) -> ProxyWarContract:
	if _proxy_wars.has(warband_id):
		return _proxy_wars[warband_id]
	return null


func get_proxy_war_count_by(sponsor_id: int) -> int:
	if sponsor_id <= 0:
		return 0
	var count: int = 0
	for wb_id: StringName in _proxy_wars:
		var contract: ProxyWarContract = _proxy_wars[wb_id]
		if contract != null and contract.sponsor_id == sponsor_id:
			count += 1
	return count


func has_active_proxy_war_by(sponsor_id: int) -> bool:
	return get_proxy_war_count_by(sponsor_id) > 0


func is_amanat_truce_active(party_a: int, party_b: int) -> bool:
	for pid: StringName in _pacts:
		var rec: AmanatPactRecord = _pacts[pid]
		if not rec.active:
			continue
		var match_ab: bool = (rec.party_a == party_a and rec.party_b == party_b) or (rec.party_a == party_b and rec.party_b == party_a)
		if match_ab:
			return true
	return false


func get_active_pacts_for_player(player_id: int) -> Array[AmanatPactRecord]:
	var out: Array[AmanatPactRecord] = []
	if player_id <= 0:
		return out
	for pid: StringName in _pacts:
		var rec: AmanatPactRecord = _pacts[pid]
		if rec != null and rec.active and (rec.party_a == player_id or rec.party_b == player_id):
			out.append(rec)
	return out


func has_penalty_free_casus_belli(attacker_id: int, sponsor_id: int) -> bool:
	var key: StringName = StringName("%d:%d" % [attacker_id, sponsor_id])
	if _casus_belli.has(key):
		return _casus_belli[key]
	return false


## Records an act of terror/atrocity (`Kan Davası`, Scorched Earth, Amanat betrayal).
## Builds Dread (`Dehşet`), inflicting combat morale shock while alienating diplomatic partners.
func record_dread_act(player_id: int, dread_gain: float, honor_loss: float = 0.0) -> void:
	if player_id <= 0:
		return
	var safe_gain: float = maxf(dread_gain, 0.0)
	var safe_honor_loss: float = maxf(honor_loss, 0.0)
	var new_dread: float = clampf(get_dread_score(player_id) + safe_gain, 0.0, 100.0)
	var new_honor: float = clampf(get_honor_score(player_id) - safe_honor_loss, 0.0, 100.0)
	_dread_score[player_id] = new_dread
	_honor_score[player_id] = new_honor
	EventBus.reputation_memory_changed.emit(player_id, get_word_reliability(player_id), new_dread, new_honor)


## Records honorable steppe Töre conduct (fulfilled Amanats, fair Ülüş, mercy).
func record_honor_act(player_id: int, honor_gain: float, dread_relief: float = 2.0) -> void:
	if player_id <= 0:
		return
	var new_honor: float = clampf(get_honor_score(player_id) + maxf(honor_gain, 0.0), 0.0, 100.0)
	var new_dread: float = clampf(get_dread_score(player_id) - maxf(dread_relief, 0.0), 0.0, 100.0)
	_honor_score[player_id] = new_honor
	_dread_score[player_id] = new_dread
	EventBus.reputation_memory_changed.emit(player_id, get_word_reliability(player_id), new_dread, new_honor)


## Combat morale shock bonus inflicted on enemies (`0.0 .. 0.25`) from attacker Dread.
func get_combat_dread_morale_shock(player_id: int) -> float:
	var max_shock: float = _rules.dread_morale_shock_max if _rules != null else 0.25
	var dread: float = get_dread_score(player_id)
	return clampf((dread / 100.0) * max_shock, 0.0, max_shock)


## True when ruler has low enough Dread (< 60) and enough Word Reliability (>= 35) to negotiate easy truces.
func can_negotiate_easy_truce(player_id: int) -> bool:
	var threshold: float = _rules.dread_truce_block_threshold if _rules != null else 60.0
	return get_dread_score(player_id) < threshold and get_word_reliability(player_id) >= 35.0


## Coalition threat accrual multiplier (`1.0 .. 2.0`) driven by ruler Dread.
func get_coalition_threat_multiplier(player_id: int) -> float:
	var max_mult: float = _rules.dread_coalition_threat_multiplier if _rules != null else 2.0
	var threshold: float = _rules.dread_truce_block_threshold if _rules != null else 60.0
	var dread: float = get_dread_score(player_id)
	return lerpf(1.0, max_mult, clampf(dread / maxf(threshold, 1.0), 0.0, 1.0))


## Passive seasonal Glory accrual unlocked above baseline Honor/Töre (`> 50`).
func get_seasonal_honor_glory_bonus(player_id: int) -> float:
	var max_glory: float = _rules.honor_glory_per_season_max if _rules != null else 4.0
	var honor: float = get_honor_score(player_id)
	if honor <= 50.0:
		return 0.0
	return clampf(((honor - 50.0) / 50.0) * max_glory, 0.0, max_glory)


## True when Honor/Töre and Word Reliability invite peaceful voluntary vassal alignment.
func accepts_voluntary_vassalization(player_id: int) -> bool:
	var honor_thresh: float = _rules.honor_voluntary_vassal_threshold if _rules != null else 65.0
	var dread_block: float = _rules.dread_truce_block_threshold if _rules != null else 60.0
	return get_honor_score(player_id) >= honor_thresh \
		and get_word_reliability(player_id) >= 60.0 \
		and get_dread_score(player_id) < dread_block


## Advances active Amanat pacts & reputation memory for `player_id` by one season.
## Returns earned Glory bonus from Honor while enforcing Coalition pressure on high Dread.
func step_seasonal_reputation_and_pacts(player_id: int) -> float:
	var completed_honor: float = _rules.amanat_fulfilled_honor_bonus if _rules != null else 8.0
	var dread_threshold: float = _rules.dread_truce_block_threshold if _rules != null else 60.0

	for pid: StringName in _pacts:
		var rec: AmanatPactRecord = _pacts[pid]
		if not rec.active:
			continue
		if rec.party_a != player_id and rec.party_b != player_id:
			continue
		rec.remaining_seasons -= 1
		if rec.remaining_seasons <= 0:
			rec.active = false
			_word_reliability[player_id] = clampf(get_word_reliability(player_id) + 5.0, 0.0, 100.0)
			record_honor_act(player_id, completed_honor, 3.0)

	var dread: float = get_dread_score(player_id)
	if dread >= dread_threshold:
		var mult: float = get_coalition_threat_multiplier(player_id)
		DiplomacyManager.add_diplomatic_infamy_spike(8.0 * mult, true)

	return get_seasonal_honor_glory_bonus(player_id)


func _handle_seal_amanat(command: GameCommand) -> bool:
	var cmd: SealAmanatPactCommand = command as SealAmanatPactCommand
	if cmd == null:
		return command.reject("Expected SealAmanatPactCommand.")
	if cmd.pact_id == &"" or cmd.party_a <= 0 or cmd.party_b <= 0 or cmd.party_a == cmd.party_b:
		return command.reject("SealAmanatPactCommand requires pact_id and two distinct positive parties.")
	if _pacts.has(cmd.pact_id):
		return command.reject("Amanat pact '%s' already exists." % cmd.pact_id)

	var rec: AmanatPactRecord = AmanatPactRecord.new(
		cmd.pact_id, cmd.party_a, cmd.party_b, cmd.hostage_type, cmd.duration_seasons)
	_pacts[cmd.pact_id] = rec
	cmd.sealed = true
	EventBus.amanat_pact_sealed.emit(cmd.pact_id, cmd.party_a, cmd.party_b, cmd.hostage_type)
	return true


func _handle_break_amanat(command: GameCommand) -> bool:
	var cmd: BreakAmanatPactCommand = command as BreakAmanatPactCommand
	if cmd == null:
		return command.reject("Expected BreakAmanatPactCommand.")
	if not _pacts.has(cmd.pact_id):
		return command.reject("Unknown Amanat pact '%s'." % cmd.pact_id)
	var rec: AmanatPactRecord = _pacts[cmd.pact_id]
	if not rec.active:
		return command.reject("Amanat pact '%s' is already inactive." % cmd.pact_id)
	if cmd.betrayer_id != rec.party_a and cmd.betrayer_id != rec.party_b:
		return command.reject("Betrayer %d is not a party to pact '%s'." % [cmd.betrayer_id, cmd.pact_id])

	rec.active = false
	rec.broken_by_id = cmd.betrayer_id
	rec.hostage_forfeited = true

	var rel_pen: float = _rules.amanat_break_reliability_penalty if _rules != null else 35.0
	var trust_pen: float = _rules.amanat_break_trust_penalty if _rules != null else -30.0
	var new_rel: float = clampf(get_word_reliability(cmd.betrayer_id) - rel_pen, 0.0, 100.0)
	_word_reliability[cmd.betrayer_id] = new_rel
	record_dread_act(cmd.betrayer_id, 22.0, 20.0)
	DiplomacyManager.modify_all_dynasty_trust(trust_pen)
	DiplomacyManager.add_diplomatic_infamy_spike(25.0, true)

	cmd.broken = true
	cmd.hostage_forfeited = true
	cmd.reliability_after = new_rel
	cmd.dread_after = get_dread_score(cmd.betrayer_id)

	EventBus.amanat_pact_broken.emit(cmd.pact_id, cmd.betrayer_id, true, new_rel)
	return true


func _handle_sponsor_proxy_war(command: GameCommand) -> bool:
	var cmd: SponsorProxyWarCommand = command as SponsorProxyWarCommand
	if cmd == null:
		return command.reject("Expected SponsorProxyWarCommand.")
	if cmd.warband_id == &"" or cmd.sponsor_id <= 0 or cmd.target_id <= 0 or cmd.sponsor_id == cmd.target_id:
		return command.reject("SponsorProxyWarCommand requires warband_id and distinct positive sponsor/target IDs.")
	if _proxy_wars.has(cmd.warband_id):
		return command.reject("Proxy warband '%s' is already contracted." % cmd.warband_id)

	var registry: OreRegistry = ResourceManager.get_registry()
	if registry == null:
		return command.reject("OreRegistry unavailable for proxy funding.")
	var silver_ore: OreData = registry.find_ore(&"silver_gold")
	if silver_ore == null:
		return command.reject("Silver/Gold ore definition missing.")
	var ra: ResourceAmount = ResourceAmount.new()
	ra.ore = silver_ore
	ra.amount = cmd.silver_cost
	if not CommandBus.dispatch(SpendResourcesCommand.new(cmd.sponsor_id, [ra])):
		return command.reject("Sponsor %d lacks %d silver_gold to fund proxy war." % [cmd.sponsor_id, cmd.silver_cost])

	var contract: ProxyWarContract = ProxyWarContract.new(
		cmd.warband_id, cmd.sponsor_id, cmd.target_id, cmd.silver_cost, cmd.raid_intensity)
	_proxy_wars[cmd.warband_id] = contract
	cmd.sponsored = true
	cmd.concealed = true

	EventBus.proxy_war_sponsored.emit(cmd.sponsor_id, cmd.warband_id, cmd.target_id, cmd.silver_cost)
	return true


func _handle_investigate_proxy_war(command: GameCommand) -> bool:
	var cmd: InvestigateProxyWarCommand = command as InvestigateProxyWarCommand
	if cmd == null:
		return command.reject("Expected InvestigateProxyWarCommand.")
	if not _proxy_wars.has(cmd.warband_id):
		return command.reject("Unknown proxy warband '%s'." % cmd.warband_id)
	var contract: ProxyWarContract = _proxy_wars[cmd.warband_id]
	var threshold: float = _rules.proxy_discovery_scout_threshold if _rules != null else 65.0
	if cmd.scout_strength < threshold:
		cmd.discovered = false
		cmd.revealed_sponsor_id = 0
		cmd.penalty_free_casus_belli = false
		return true

	contract.exposed = true
	contract.exposed_to_id = cmd.investigator_id
	contract.casus_belli_granted = true
	var key: StringName = StringName("%d:%d" % [cmd.investigator_id, contract.sponsor_id])
	_casus_belli[key] = true

	_word_reliability[contract.sponsor_id] = clampf(get_word_reliability(contract.sponsor_id) - 12.0, 0.0, 100.0)
	var infamy: float = _rules.proxy_exposed_infamy_spike if _rules != null else 22.0
	DiplomacyManager.add_diplomatic_infamy_spike(infamy, false)
	EventBus.reputation_memory_changed.emit(
		contract.sponsor_id,
		get_word_reliability(contract.sponsor_id),
		get_dread_score(contract.sponsor_id),
		get_honor_score(contract.sponsor_id))

	cmd.discovered = true
	cmd.revealed_sponsor_id = contract.sponsor_id
	cmd.penalty_free_casus_belli = true

	EventBus.proxy_war_exposed_casus_belli.emit(
		contract.sponsor_id, cmd.investigator_id, cmd.warband_id, true)
	return true


func export_state_dict() -> Dictionary:
	var rel: Dictionary = {}
	for pid: int in _word_reliability:
		rel[str(pid)] = _word_reliability[pid]
	var dread: Dictionary = {}
	for pid: int in _dread_score:
		dread[str(pid)] = _dread_score[pid]
	var honor: Dictionary = {}
	for pid: int in _honor_score:
		honor[str(pid)] = _honor_score[pid]
	var pacts_dict: Dictionary = {}
	var pact_keys: Array[StringName] = _pacts.keys()
	pact_keys.sort_custom(func(a: StringName, b: StringName) -> bool:
		return String(a) < String(b)
	)
	for pk: StringName in pact_keys:
		var rec: AmanatPactRecord = _pacts[pk]
		if rec == null:
			continue
		pacts_dict[String(pk)] = {
			"active": rec.active,
			"broken_by_id": rec.broken_by_id,
			"duration_seasons": rec.duration_seasons,
			"hostage_forfeited": rec.hostage_forfeited,
			"hostage_type": int(rec.hostage_type),
			"pact_id": String(rec.pact_id),
			"party_a": rec.party_a,
			"party_b": rec.party_b,
			"remaining_seasons": rec.remaining_seasons,
		}
	var proxies_dict: Dictionary = {}
	var proxy_keys: Array[StringName] = _proxy_wars.keys()
	proxy_keys.sort_custom(func(a: StringName, b: StringName) -> bool:
		return String(a) < String(b)
	)
	for wk: StringName in proxy_keys:
		var con: ProxyWarContract = _proxy_wars[wk]
		if con == null:
			continue
		proxies_dict[String(wk)] = {
			"casus_belli_granted": con.casus_belli_granted,
			"exposed": con.exposed,
			"exposed_to_id": con.exposed_to_id,
			"raid_intensity": con.raid_intensity,
			"silver_cost": con.silver_cost,
			"sponsor_id": con.sponsor_id,
			"target_id": con.target_id,
			"warband_id": String(con.warband_id),
		}
	var cb_dict: Dictionary = {}
	var cb_keys: Array[StringName] = _casus_belli.keys()
	cb_keys.sort_custom(func(a: StringName, b: StringName) -> bool:
		return String(a) < String(b)
	)
	for ck: StringName in cb_keys:
		cb_dict[String(ck)] = _casus_belli[ck]
	return {
		"casus_belli": cb_dict,
		"dread_score": dread,
		"honor_score": honor,
		"pacts": pacts_dict,
		"proxy_wars": proxies_dict,
		"word_reliability": rel,
	}


func import_state_dict(data: Dictionary) -> bool:
	if not (data.get("word_reliability") is Dictionary):
		return false
	reset_reputation_state()
	var rel: Dictionary = DeterministicStateHasher.v_dict(data.get("word_reliability"))
	for k: Variant in rel:
		_word_reliability[DeterministicStateHasher.v_str(k).to_int()] = DeterministicStateHasher.v_float(rel[k], 1.0)
	var dread: Dictionary = DeterministicStateHasher.v_dict(data.get("dread_score", {}))
	for k: Variant in dread:
		_dread_score[DeterministicStateHasher.v_str(k).to_int()] = DeterministicStateHasher.v_float(dread[k])
	var honor: Dictionary = DeterministicStateHasher.v_dict(data.get("honor_score", {}))
	for k: Variant in honor:
		_honor_score[DeterministicStateHasher.v_str(k).to_int()] = DeterministicStateHasher.v_float(honor[k])
	var pacts_dict: Dictionary = DeterministicStateHasher.v_dict(data.get("pacts", {}))
	for k: Variant in pacts_dict:
		var pd: Dictionary = DeterministicStateHasher.v_dict(pacts_dict[k])
		var pid_sn: StringName = StringName(DeterministicStateHasher.v_str(pd.get("pact_id", DeterministicStateHasher.v_str(k))))
		if pid_sn == &"":
			continue
		var h_type_int: int = clampi(DeterministicStateHasher.v_int(pd.get("hostage_type", 0), 0), 0, 3)
		var rec: AmanatPactRecord = AmanatPactRecord.new(
			pid_sn,
			DeterministicStateHasher.v_int(pd.get("party_a", 0), 0),
			DeterministicStateHasher.v_int(pd.get("party_b", 0), 0),
			h_type_int as GameEnums.AmanatHostageType,
			maxi(DeterministicStateHasher.v_int(pd.get("duration_seasons", 8), 8), 1))
		rec.remaining_seasons = DeterministicStateHasher.v_int(pd.get("remaining_seasons", rec.duration_seasons), rec.duration_seasons)
		rec.active = DeterministicStateHasher.v_bool(pd.get("active", true), true)
		rec.broken_by_id = DeterministicStateHasher.v_int(pd.get("broken_by_id", 0), 0)
		rec.hostage_forfeited = DeterministicStateHasher.v_bool(pd.get("hostage_forfeited", false), false)
		_pacts[pid_sn] = rec
	var proxies_dict: Dictionary = DeterministicStateHasher.v_dict(data.get("proxy_wars", {}))
	for k: Variant in proxies_dict:
		var wd: Dictionary = DeterministicStateHasher.v_dict(proxies_dict[k])
		var wb_sn: StringName = StringName(DeterministicStateHasher.v_str(wd.get("warband_id", DeterministicStateHasher.v_str(k))))
		if wb_sn == &"":
			continue
		var con: ProxyWarContract = ProxyWarContract.new(
			wb_sn,
			DeterministicStateHasher.v_int(wd.get("sponsor_id", 0), 0),
			DeterministicStateHasher.v_int(wd.get("target_id", 0), 0),
			maxi(DeterministicStateHasher.v_int(wd.get("silver_cost", 45), 45), 0),
			DeterministicStateHasher.v_float(wd.get("raid_intensity", 0.75), 0.75))
		con.exposed = DeterministicStateHasher.v_bool(wd.get("exposed", false), false)
		con.exposed_to_id = DeterministicStateHasher.v_int(wd.get("exposed_to_id", 0), 0)
		con.casus_belli_granted = DeterministicStateHasher.v_bool(wd.get("casus_belli_granted", false), false)
		_proxy_wars[wb_sn] = con
	var cb_dict: Dictionary = DeterministicStateHasher.v_dict(data.get("casus_belli", {}))
	for k: Variant in cb_dict:
		var cb_sn: StringName = StringName(DeterministicStateHasher.v_str(k))
		_casus_belli[cb_sn] = DeterministicStateHasher.v_bool(cb_dict[k], false)
	return true
