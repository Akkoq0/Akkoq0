extends Node
## Autoload `SuccessionManager` (rank 2). Implements Phase 24 **Generational
## Ruler/Commander Aging, Battle Scars & Legacy Progression, Amanat Hostage
## Succession Vulnerability, Ak Sakallılar Regency, and Kurultay Succession Crises**.

const RULES_PATH: String = "res://data/governance/succession_rules.tres"
const BULLION_ORE_PATH: String = "res://data/ores/silver_gold.tres"

var _rules: SuccessionRules = null
var _bullion_ore: OreData = null
var _dynasties: Dictionary[int, DynastyRulerProfile] = {}
var _commanders: Dictionary[int, CommanderProfile] = {}
var _crisis_counter: int = 0


func _ready() -> void:
	_rules = ResourceLoader.load(RULES_PATH) as SuccessionRules
	if _rules == null:
		push_error("SuccessionManager: failed to load SuccessionRules at %s." % RULES_PATH)
	else:
		for err: String in _rules.get_validation_errors():
			push_error("SuccessionManager: %s" % err)
	_bullion_ore = ResourceLoader.load(BULLION_ORE_PATH) as OreData

	CommandBus.register_handler(DesignateAndTrainHeirCommand.ID, _handle_designate_and_train_heir)
	CommandBus.register_handler(StepSuccessionSeasonCommand.ID, _handle_step_succession_season)
	CommandBus.register_handler(ResolveSuccessionCrisisCommand.ID, _handle_resolve_succession_crisis)
	EventBus.amanat_pact_sealed.connect(_on_amanat_pact_sealed)
	EventBus.amanat_pact_broken.connect(_on_amanat_pact_broken)


func _exit_tree() -> void:
	CommandBus.unregister_handler(DesignateAndTrainHeirCommand.ID, _handle_designate_and_train_heir)
	CommandBus.unregister_handler(StepSuccessionSeasonCommand.ID, _handle_step_succession_season)
	CommandBus.unregister_handler(ResolveSuccessionCrisisCommand.ID, _handle_resolve_succession_crisis)
	if EventBus.amanat_pact_sealed.is_connected(_on_amanat_pact_sealed):
		EventBus.amanat_pact_sealed.disconnect(_on_amanat_pact_sealed)
	if EventBus.amanat_pact_broken.is_connected(_on_amanat_pact_broken):
		EventBus.amanat_pact_broken.disconnect(_on_amanat_pact_broken)


func reset_succession_state() -> void:
	_dynasties.clear()
	_commanders.clear()
	_crisis_counter = 0


func get_rules() -> SuccessionRules:
	return _rules


func get_dynasty_count() -> int:
	return _dynasties.size()


func get_commander_count() -> int:
	return _commanders.size()


func get_registered_player_ids() -> PackedInt32Array:
	var ids: PackedInt32Array = PackedInt32Array()
	for pid: int in _dynasties:
		ids.append(pid)
	ids.sort()
	return ids


func get_registered_commander_ids() -> PackedInt32Array:
	var ids: PackedInt32Array = PackedInt32Array()
	for cid: int in _commanders:
		ids.append(cid)
	ids.sort()
	return ids


func register_dynasty(
		player_id: int,
		ruler_name: StringName = &"Bilge Khagan",
		age_seasons: int = 128,
		competence: float = 75.0,
		heir_name: StringName = &"Tigin",
		heir_age_seasons: int = 40,
		heir_competence: float = 45.0) -> DynastyRulerProfile:
	var profile: DynastyRulerProfile = DynastyRulerProfile.new(
		player_id, ruler_name, age_seasons, competence)
	profile.designated_heir_name = heir_name
	profile.heir_age_seasons = maxi(heir_age_seasons, 0)
	profile.heir_competence = clampf(heir_competence, 0.0, 100.0)
	_dynasties[player_id] = profile
	return profile


func get_dynasty(player_id: int) -> DynastyRulerProfile:
	if _dynasties.has(player_id):
		return _dynasties[player_id]
	return null


func register_commander(
		commander_id: int,
		player_id: int,
		army_id: int,
		commander_name: StringName = &"Kul Tigin",
		age_seasons: int = 104,
		p_commander_trait: GameEnums.CommanderTrait = GameEnums.CommanderTrait.NONE) -> CommanderProfile:
	var cmdr: CommanderProfile = CommanderProfile.new(
		commander_id, player_id, army_id, commander_name, age_seasons, p_commander_trait)
	_commanders[commander_id] = cmdr
	return cmdr


func get_commander(commander_id: int) -> CommanderProfile:
	if _commanders.has(commander_id):
		return _commanders[commander_id]
	return null


func get_commander_for_army(army_id: int) -> CommanderProfile:
	for cid: int in _commanders:
		var cmdr: CommanderProfile = _commanders[cid]
		if cmdr.assigned_army_id == army_id:
			return cmdr
	return null


func get_regency_status(player_id: int) -> GameEnums.RegencyStatus:
	if not _dynasties.has(player_id):
		return GameEnums.RegencyStatus.STABLE_RULE
	return _dynasties[player_id].regency_status


func get_regency_tax_multiplier(player_id: int) -> float:
	if not _dynasties.has(player_id):
		return 1.0
	var st: GameEnums.RegencyStatus = _dynasties[player_id].regency_status
	if st == GameEnums.RegencyStatus.STABLE_RULE:
		return 1.0
	var base_mult: float = _rules.regency_tax_efficiency_mult if _rules != null else 0.80
	if st == GameEnums.RegencyStatus.KURULTAY_SUCCESSION_CRISIS:
		return clampf(base_mult - 0.15, 0.45, 1.0)
	return base_mult


func is_crisis_or_regency_active(player_id: int) -> bool:
	return get_regency_status(player_id) != GameEnums.RegencyStatus.STABLE_RULE


func record_commander_battle_experience(
		commander_id: int,
		veteran_gain: float = 12.0,
		unlock_trait: GameEnums.CommanderTrait = GameEnums.CommanderTrait.NONE) -> CommanderProfile:
	if not _commanders.has(commander_id):
		return null
	var cmdr: CommanderProfile = _commanders[commander_id]
	if not cmdr.is_alive:
		return cmdr
	cmdr.veteran_score = clampf(cmdr.veteran_score + maxf(veteran_gain, 0.0), 0.0, 200.0)
	cmdr.leadership = clampf(cmdr.leadership + maxf(veteran_gain * 0.25, 0.0), 0.0, 100.0)
	if unlock_trait != GameEnums.CommanderTrait.NONE and cmdr.commander_trait == GameEnums.CommanderTrait.NONE:
		cmdr.commander_trait = unlock_trait
	EventBus.commander_legacy_updated.emit(
		cmdr.commander_id, cmdr.assigned_army_id, cmdr.veteran_score, cmdr.scars, cmdr.commander_trait)
	return cmdr


## Inflicts permanent battle wound scar (`SAGIR_YARA` specialization on scar accrual)
## or fatal battlefield death upon `commander_id`, emitting instant morale/cohesion shock.
func inflict_commander_battle_trauma(commander_id: int, lethal: bool = false) -> bool:
	if not _commanders.has(commander_id):
		return false
	var cmdr: CommanderProfile = _commanders[commander_id]
	if not cmdr.is_alive:
		return false
	if lethal:
		cmdr.is_alive = false
		var m_shock: float = _rules.commander_death_morale_shock if _rules != null else 28.0
		var c_shock: float = _rules.commander_death_cohesion_shock if _rules != null else 24.0
		EventBus.commander_fallen_in_battle.emit(
			cmdr.commander_id, cmdr.assigned_army_id, cmdr.player_id, m_shock, c_shock)
		EventBus.commander_legacy_updated.emit(
			cmdr.commander_id, cmdr.assigned_army_id, cmdr.veteran_score, cmdr.scars, cmdr.commander_trait)
		return true

	var max_scars: int = _rules.max_battle_scars if _rules != null else 3
	if cmdr.scars < max_scars:
		cmdr.scars += 1
	cmdr.veteran_score = clampf(cmdr.veteran_score + 8.0, 0.0, 200.0)
	if cmdr.commander_trait == GameEnums.CommanderTrait.NONE and cmdr.scars >= 1:
		cmdr.commander_trait = GameEnums.CommanderTrait.SAGIR_YARA
	EventBus.commander_legacy_updated.emit(
		cmdr.commander_id, cmdr.assigned_army_id, cmdr.veteran_score, cmdr.scars, cmdr.commander_trait)
	return true


func _handle_designate_and_train_heir(command: GameCommand) -> bool:
	var cmd: DesignateAndTrainHeirCommand = command as DesignateAndTrainHeirCommand
	if cmd == null:
		return command.reject("Expected DesignateAndTrainHeirCommand.")
	if cmd.player_id <= 0:
		return command.reject("DesignateAndTrainHeirCommand requires positive player_id.")
	var profile: DynastyRulerProfile = _dynasties.get(cmd.player_id, null)
	if profile == null:
		profile = register_dynasty(cmd.player_id)

	if cmd.heir_name != &"":
		profile.designated_heir_name = cmd.heir_name
		if profile.heir_held_as_amanat:
			profile.heir_held_as_amanat = false
			profile.amanat_pact_id = &""
	if cmd.heir_age_seasons >= 0:
		profile.heir_age_seasons = cmd.heir_age_seasons

	var bullion_spent: int = 0
	if cmd.invest_training:
		if profile.designated_heir_name == &"":
			return command.reject("Cannot train nonexistent designated heir for player %d." % cmd.player_id)
		var cost_amt: int = _rules.heir_training_bullion_cost if _rules != null else 20
		if _bullion_ore != null and cost_amt > 0:
			var ra: ResourceAmount = ResourceAmount.new()
			ra.ore = _bullion_ore
			ra.amount = cost_amt
			var spend: SpendResourcesCommand = SpendResourcesCommand.new(cmd.player_id, [ra])
			if not CommandBus.dispatch(spend):
				return command.reject("Player %d lacks %d silver_gold to train heir." % [cmd.player_id, cost_amt])
			bullion_spent = cost_amt
		var gain: float = _rules.heir_training_competence_gain if _rules != null else 12.0
		profile.heir_competence = clampf(profile.heir_competence + gain, 0.0, 100.0)

	cmd.updated = true
	cmd.resulting_competence = profile.heir_competence
	cmd.bullion_spent = bullion_spent
	return true


func _handle_step_succession_season(command: GameCommand) -> bool:
	var cmd: StepSuccessionSeasonCommand = command as StepSuccessionSeasonCommand
	if cmd == null:
		return command.reject("Expected StepSuccessionSeasonCommand.")
	if cmd.player_id <= 0:
		return command.reject("StepSuccessionSeasonCommand requires positive player_id.")

	var profile: DynastyRulerProfile = _dynasties.get(cmd.player_id, null)
	if profile == null:
		profile = register_dynasty(cmd.player_id)

	var steps: int = maxi(cmd.seasons_to_advance, 1)
	profile.age_seasons += steps
	if profile.designated_heir_name != &"":
		profile.heir_age_seasons += steps

	for cid: int in _commanders:
		var cmdr: CommanderProfile = _commanders[cid]
		if cmdr.player_id == cmd.player_id and cmdr.is_alive:
			cmdr.age_seasons += steps
			cmdr.veteran_score = clampf(cmdr.veteran_score + float(steps) * 0.5, 0.0, 200.0)

	var s_per_y: int = _rules.seasons_per_year if _rules != null else 4
	var max_age_y: int = _rules.max_natural_lifespan_years if _rules != null else 76
	var should_die: bool = cmd.force_ruler_death or profile.get_age_years(s_per_y) >= max_age_y

	if should_die:
		var deceased: StringName = profile.ruler_name
		var smooth_ready: bool = profile.is_heir_ready(_rules)
		var next_name: StringName = profile.designated_heir_name if profile.designated_heir_name != &"" else StringName("Kurultay_Heir_%d" % (profile.generation + 1))

		profile.generation += 1
		profile.ruler_name = next_name
		if profile.designated_heir_name != &"" and not profile.heir_held_as_amanat:
			profile.age_seasons = maxi(profile.heir_age_seasons, 28)
			profile.competence = clampf(profile.heir_competence, 20.0, 100.0)
		else:
			profile.age_seasons = 44 ## 11-year emergency placeholder under regency/claimants
			profile.competence = 30.0

		## Seed next generation junior heir candidate
		profile.designated_heir_name = StringName("Tigin_Gen_%d" % (profile.generation + 1))
		profile.heir_age_seasons = 24
		profile.heir_competence = 40.0
		profile.heir_held_as_amanat = false
		profile.amanat_pact_id = &""

		cmd.succession_occurred = true
		cmd.new_ruler_name = profile.ruler_name
		cmd.generation_after = profile.generation

		if smooth_ready:
			profile.regency_status = GameEnums.RegencyStatus.STABLE_RULE
			profile.crisis_id = &""
			profile.claimant_bey_id = &""
			profile.contested_territory_coord = Vector2i.ZERO
			profile.last_succession_reason = &"smooth_prepared_heir"
			cmd.crisis_triggered = false
			cmd.resulting_regency_status = GameEnums.RegencyStatus.STABLE_RULE
		else:
			var vassals: Array[VassalBeyAssignment] = GovernanceManager.get_vassals_for_suzerain(cmd.player_id)
			var chosen_claimant: VassalBeyAssignment = null
			var loyalty_drop: float = _rules.crisis_ambitious_vassal_loyalty_drop if _rules != null else 22.0
			for v: VassalBeyAssignment in vassals:
				if v.personality_trait == GameEnums.VassalPersonalityTrait.AMBITIOUS:
					v.loyalty = clampf(v.loyalty - loyalty_drop, 0.0, 100.0)
					v.silent_sabotage_active = true
					v.reinforcement_delay_hours = maxf(v.reinforcement_delay_hours, 16.0)
					v.reinforcement_troop_mult = minf(v.reinforcement_troop_mult, 0.55)
					if chosen_claimant == null:
						chosen_claimant = v
				elif chosen_claimant == null and v.personality_trait != GameEnums.VassalPersonalityTrait.LOYAL:
					v.loyalty = clampf(v.loyalty - (loyalty_drop * 0.5), 0.0, 100.0)

			var owned_regions: Array[Vector2i] = TerritoryManager.get_owned_region_coords(cmd.player_id)
			var triggers_kurultay_crisis: bool = chosen_claimant != null or (owned_regions.size() >= 2 and profile.competence < 45.0)
			_crisis_counter += 1
			profile.crisis_id = StringName("crisis_%d_%d" % [cmd.player_id, _crisis_counter])

			if triggers_kurultay_crisis:
				profile.regency_status = GameEnums.RegencyStatus.KURULTAY_SUCCESSION_CRISIS
				profile.claimant_bey_id = chosen_claimant.bey_id if chosen_claimant != null else &"kurultay_pretender"
				if chosen_claimant != null:
					profile.contested_territory_coord = chosen_claimant.region_coord
				elif not owned_regions.is_empty():
					profile.contested_territory_coord = owned_regions[0]
				profile.last_succession_reason = cmd.death_cause
				cmd.crisis_triggered = true
				cmd.claimant_bey_id = profile.claimant_bey_id
				cmd.contested_coord = profile.contested_territory_coord
				if cmd.player_id == 1:
					CommandBus.dispatch(ModifyKutCommand.new(-10.0, &"kurultay_succession_crisis"))
				EventBus.kurultay_succession_crisis_triggered.emit(
					cmd.player_id, profile.crisis_id, profile.claimant_bey_id,
					profile.contested_territory_coord, cmd.death_cause)
			else:
				profile.regency_status = GameEnums.RegencyStatus.AK_SAKALLILAR_REGENCY
				profile.claimant_bey_id = &""
				profile.contested_territory_coord = Vector2i.ZERO
				profile.last_succession_reason = &"weak_or_minor_heir_regency"
				cmd.crisis_triggered = true
				if cmd.player_id == 1:
					CommandBus.dispatch(ModifyKutCommand.new(-4.0, &"ak_sakallilar_regency"))

			cmd.resulting_regency_status = profile.regency_status

		EventBus.ruler_died_succession_started.emit(
			cmd.player_id, deceased, profile.ruler_name, profile.generation,
			cmd.crisis_triggered, profile.regency_status)
	else:
		cmd.succession_occurred = false
		cmd.crisis_triggered = is_crisis_or_regency_active(cmd.player_id)
		cmd.resulting_regency_status = profile.regency_status
		cmd.new_ruler_name = profile.ruler_name
		cmd.generation_after = profile.generation

	return true


func _handle_resolve_succession_crisis(command: GameCommand) -> bool:
	var cmd: ResolveSuccessionCrisisCommand = command as ResolveSuccessionCrisisCommand
	if cmd == null:
		return command.reject("Expected ResolveSuccessionCrisisCommand.")
	if cmd.player_id <= 0 or not _dynasties.has(cmd.player_id):
		return command.reject("Unknown dynasty for player %d." % cmd.player_id)

	var profile: DynastyRulerProfile = _dynasties[cmd.player_id]
	if profile.regency_status == GameEnums.RegencyStatus.STABLE_RULE:
		return command.reject("Player %d has no active regency or succession crisis." % cmd.player_id)

	var active_crisis_id: StringName = profile.crisis_id
	var silver_spent: int = 0
	var dread_gained: float = 0.0
	var kut_delta: float = 0.0

	if cmd.response == GameEnums.SuccessionCrisisResponse.COUNCIL_REGENCY_TRANSITION:
		profile.regency_status = GameEnums.RegencyStatus.AK_SAKALLILAR_REGENCY
		profile.claimant_bey_id = &""
		profile.contested_territory_coord = Vector2i.ZERO
		ReputationAndPactSystem.record_honor_act(cmd.player_id, 6.0, 2.0)
	elif cmd.response == GameEnums.SuccessionCrisisResponse.PURGE_AMBITIOUS_CLAIMANTS:
		var cost_amt: int = _rules.crisis_purge_silver_cost if _rules != null else 50
		if _bullion_ore != null and cost_amt > 0:
			var ra: ResourceAmount = ResourceAmount.new()
			ra.ore = _bullion_ore
			ra.amount = cost_amt
			var purge_costs: Array[ResourceAmount] = [ra]
			if not CommandBus.dispatch(SpendResourcesCommand.new(cmd.player_id, purge_costs)):
				return command.reject("Player %d lacks %d silver_gold to purge claimants." % [cmd.player_id, cost_amt])
			silver_spent = cost_amt
		dread_gained = _rules.crisis_purge_dread_gain if _rules != null else 18.0
		ReputationAndPactSystem.record_dread_act(cmd.player_id, dread_gained, 8.0)
		var vassals: Array[VassalBeyAssignment] = GovernanceManager.get_vassals_for_suzerain(cmd.player_id)
		for v: VassalBeyAssignment in vassals:
			if v.bey_id == profile.claimant_bey_id or v.personality_trait == GameEnums.VassalPersonalityTrait.AMBITIOUS:
				v.loyalty = clampf(v.loyalty + 20.0, 0.0, 100.0)
				v.silent_sabotage_active = false
				v.reinforcement_delay_hours = 0.0
				v.reinforcement_troop_mult = 1.0
		profile.regency_status = GameEnums.RegencyStatus.STABLE_RULE
		profile.claimant_bey_id = &""
		profile.contested_territory_coord = Vector2i.ZERO
		profile.crisis_id = &""
	elif cmd.response == GameEnums.SuccessionCrisisResponse.CEDE_AUTONOMY_AND_ULUS:
		var appease_cost: int = _rules.crisis_appease_silver_cost if _rules != null else 65
		var appease_kut: float = _rules.crisis_appease_kut_cost if _rules != null else 10.0
		if _bullion_ore != null and appease_cost > 0:
			var ra2: ResourceAmount = ResourceAmount.new()
			ra2.ore = _bullion_ore
			ra2.amount = appease_cost
			var appease_costs: Array[ResourceAmount] = [ra2]
			if not CommandBus.dispatch(SpendResourcesCommand.new(cmd.player_id, appease_costs)):
				return command.reject("Player %d lacks %d silver_gold to appease claimants." % [cmd.player_id, appease_cost])
			silver_spent = appease_cost
		if appease_kut > 0.0 and cmd.player_id == 1:
			CommandBus.dispatch(ModifyKutCommand.new(-appease_kut, &"succession_autonomy_concession"))
			kut_delta = -appease_kut
		var vassals2: Array[VassalBeyAssignment] = GovernanceManager.get_vassals_for_suzerain(cmd.player_id)
		for v2: VassalBeyAssignment in vassals2:
			v2.loyalty = clampf(v2.loyalty + 28.0, 0.0, 100.0)
			v2.silent_sabotage_active = false
			v2.reinforcement_delay_hours = 0.0
			v2.reinforcement_troop_mult = 1.0
		profile.regency_status = GameEnums.RegencyStatus.STABLE_RULE
		profile.claimant_bey_id = &""
		profile.contested_territory_coord = Vector2i.ZERO
		profile.crisis_id = &""

	cmd.resolved = true
	cmd.resulting_status = profile.regency_status
	cmd.silver_spent = silver_spent
	cmd.dread_gained = dread_gained
	cmd.kut_delta = kut_delta

	EventBus.succession_crisis_resolved.emit(
		cmd.player_id, active_crisis_id, cmd.response, profile.regency_status)
	return true


func _on_amanat_pact_sealed(pact_id: StringName, party_a: int, _party_b: int, hostage_type: GameEnums.AmanatHostageType) -> void:
	if hostage_type == GameEnums.AmanatHostageType.HEIR_HOSTAGE and _dynasties.has(party_a):
		var profile: DynastyRulerProfile = _dynasties[party_a]
		profile.heir_held_as_amanat = true
		profile.amanat_pact_id = pact_id
	elif hostage_type == GameEnums.AmanatHostageType.COMMANDER_HOSTAGE:
		for cid: int in _commanders:
			var cmdr: CommanderProfile = _commanders[cid]
			if cmdr.player_id == party_a and cmdr.is_alive and not cmdr.held_as_amanat:
				cmdr.held_as_amanat = true
				break


func _on_amanat_pact_broken(pact_id: StringName, betrayer_id: int, hostage_forfeited: bool, _reliability_after: float) -> void:
	if _dynasties.has(betrayer_id):
		var profile: DynastyRulerProfile = _dynasties[betrayer_id]
		if profile.amanat_pact_id == pact_id or (hostage_forfeited and profile.heir_held_as_amanat):
			profile.heir_held_as_amanat = false
			profile.amanat_pact_id = &""
			if hostage_forfeited:
				profile.designated_heir_name = &""
				profile.heir_competence = 0.0
				profile.heir_age_seasons = 0
	if hostage_forfeited:
		for cid: int in _commanders:
			var cmdr: CommanderProfile = _commanders[cid]
			if cmdr.player_id == betrayer_id and cmdr.held_as_amanat:
				cmdr.held_as_amanat = false
				inflict_commander_battle_trauma(cid, true)
				break


func export_state_dict() -> Dictionary:
	var dyn_dict: Dictionary = {}
	for pid: int in _dynasties:
		var d: DynastyRulerProfile = _dynasties[pid]
		dyn_dict[str(pid)] = {
			"age_seasons": d.age_seasons,
			"competence": d.competence,
			"crisis_id": String(d.crisis_id),
			"designated_heir_name": String(d.designated_heir_name),
			"generation": d.generation,
			"heir_age_seasons": d.heir_age_seasons,
			"heir_competence": d.heir_competence,
			"heir_held_as_amanat": d.heir_held_as_amanat,
			"is_alive": d.is_alive,
			"regency_status": int(d.regency_status),
			"ruler_name": String(d.ruler_name),
		}
	var cmd_dict: Dictionary = {}
	for cid: int in _commanders:
		var c: CommanderProfile = _commanders[cid]
		cmd_dict[str(cid)] = {
			"age_seasons": c.age_seasons,
			"assigned_army_id": c.assigned_army_id,
			"commander_id": c.commander_id,
			"commander_name": String(c.commander_name),
			"commander_trait": int(c.commander_trait),
			"is_alive": c.is_alive,
			"leadership": c.leadership,
			"player_id": c.player_id,
			"scars": c.scars,
			"veteran_score": c.veteran_score,
		}
	return {
		"commanders": cmd_dict,
		"crisis_counter": _crisis_counter,
		"dynasties": dyn_dict,
	}


func import_state_dict(data: Dictionary) -> bool:
	if not (data.get("dynasties") is Dictionary) or not (data.get("commanders") is Dictionary):
		return false
	reset_succession_state()
	_crisis_counter = maxi(DeterministicStateHasher.v_int(data.get("crisis_counter", 0)), 0)
	var dyn_dict: Dictionary = DeterministicStateHasher.v_dict(data.get("dynasties"))
	for k: Variant in dyn_dict:
		var pid: int = DeterministicStateHasher.v_str(k).to_int()
		var dd: Dictionary = DeterministicStateHasher.v_dict(dyn_dict[k])
		var d: DynastyRulerProfile = DynastyRulerProfile.new(
			pid,
			StringName(DeterministicStateHasher.v_str(dd.get("ruler_name", "Bilge Khagan"), "Bilge Khagan")),
			DeterministicStateHasher.v_int(dd.get("age_seasons", 128), 128),
			DeterministicStateHasher.v_float(dd.get("competence", 75.0), 75.0))
		d.generation = DeterministicStateHasher.v_int(dd.get("generation", 1), 1)
		d.is_alive = DeterministicStateHasher.v_bool(dd.get("is_alive", true), true)
		d.crisis_id = StringName(DeterministicStateHasher.v_str(dd.get("crisis_id", "")))
		d.designated_heir_name = StringName(DeterministicStateHasher.v_str(dd.get("designated_heir_name", "")))
		d.heir_age_seasons = DeterministicStateHasher.v_int(dd.get("heir_age_seasons", 0))
		d.heir_competence = DeterministicStateHasher.v_float(dd.get("heir_competence", 0.0))
		d.heir_held_as_amanat = DeterministicStateHasher.v_bool(dd.get("heir_held_as_amanat", false))
		d.regency_status = DeterministicStateHasher.v_int(dd.get("regency_status", 0)) as GameEnums.RegencyStatus
		_dynasties[pid] = d
	var cmd_dict: Dictionary = DeterministicStateHasher.v_dict(data.get("commanders"))
	for k: Variant in cmd_dict:
		var cid: int = DeterministicStateHasher.v_str(k).to_int()
		var cd: Dictionary = DeterministicStateHasher.v_dict(cmd_dict[k])
		var c: CommanderProfile = CommanderProfile.new(
			cid,
			DeterministicStateHasher.v_int(cd.get("player_id", 1), 1),
			DeterministicStateHasher.v_int(cd.get("assigned_army_id", cid), cid),
			StringName(DeterministicStateHasher.v_str(cd.get("commander_name", "Komutan"), "Komutan")),
			DeterministicStateHasher.v_int(cd.get("age_seasons", 96), 96),
			DeterministicStateHasher.v_int(cd.get("commander_trait", 0)) as GameEnums.CommanderTrait)
		c.is_alive = DeterministicStateHasher.v_bool(cd.get("is_alive", true), true)
		c.leadership = DeterministicStateHasher.v_float(cd.get("leadership", 65.0), 65.0)
		c.scars = DeterministicStateHasher.v_int(cd.get("scars", 0))
		c.veteran_score = DeterministicStateHasher.v_float(cd.get("veteran_score", 0.0))
		_commanders[cid] = c
	return true
