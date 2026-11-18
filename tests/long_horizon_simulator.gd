class_name LongHorizonSimulator
extends RefCounted
## Verification harness (rank 4). Runs deterministic multi-year (24+ season)
## headless simulations under a fixed PRNG seed, recording per-season snapshots
## across Food, Kut, 7-Ores, pasture ecology, Yılkı remounts, combat/wounded,
## Khagan glory, epidemics/cataclysms, Turan FSM, and dynasty relations.

enum SimulationProfile {
	BALANCED_NOMAD = 0,
	SETTLED_MINER = 1,
	CONTINUOUS_NOMAD = 2,
	CRISIS_CLAN = 3,
}

const ORE_IDS: Array[StringName] = [
	&"stone",
	&"iron",
	&"coal",
	&"steel",
	&"silver_gold",
	&"jade",
	&"meteoric_iron",
	&"sulfur",
]
const DYNASTY_IDS: Array[StringName] = [&"karluk", &"kipchak", &"oghuz"]


class SimulationRunResult:
	extends RefCounted
	var profile: SimulationProfile = SimulationProfile.BALANCED_NOMAD
	var rng_seed: int = 14001
	var seasons_simulated: int = 0
	var history: Array[SimulationInvariantChecker.SeasonSnapshot] = []
	var violations: PackedStringArray = PackedStringArray()
	var signal_counts: Dictionary[StringName, int] = {}
	var battles_fought: int = 0
	var steel_batches_smelted: int = 0
	var migrations_performed: int = 0
	var migration_food_spent: int = 0
	var min_food_observed: int = 999999
	var min_kut_observed: float = 100.0
	var min_remount_observed: float = 1.0
	var min_pasture_multiplier_observed: float = 1.0
	var had_grazed_friction: bool = false
	var had_starving_pasture: bool = false
	var had_council_crisis: bool = false

	func passed() -> bool:
		return violations.is_empty()

	func latest() -> SimulationInvariantChecker.SeasonSnapshot:
		if history.is_empty():
			return null
		return history[history.size() - 1]


static func run(host_node: Node, profile: SimulationProfile = SimulationProfile.BALANCED_NOMAD, num_seasons: int = 24, rng_seed: int = 14001, run_slot: int = 0) -> SimulationRunResult:
	var result: SimulationRunResult = SimulationRunResult.new()
	result.profile = profile
	result.rng_seed = rng_seed
	if host_node == null:
		result.violations.append("LongHorizonSimulator requires a non-null host Node.")
		return result

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = rng_seed

	var slot_id: int = int(profile) * 20 + run_slot
	var pid: int = 400 + slot_id
	var army_id: int = 4100 + slot_id
	var depot_id: int = 4200 + slot_id
	var region_y: int = 50 + slot_id * 4
	var region_band: Array[Vector2i] = [
		Vector2i(50, region_y),
		Vector2i(51, region_y),
		Vector2i(52, region_y),
		Vector2i(53, region_y),
		Vector2i(54, region_y),
		Vector2i(55, region_y),
	]
	var bey_id: StringName = StringName("sim_bey_%d_%d" % [slot_id, rng_seed])
	var agent_id: StringName = StringName("sim_ai_%d_%d" % [slot_id, rng_seed])

	var sig_counts: Dictionary[StringName, int] = {
		&"council_convened": 0,
		&"coalition_declared": 0,
		&"overgrazing_rebellion": 0,
		&"internal_betrayal": 0,
	}

	var on_council: Callable = func(_k: float, _p: float, _s: bool) -> void:
		sig_counts[&"council_convened"] = sig_counts[&"council_convened"] + 1
	var on_coalition: Callable = func(_m: PackedStringArray, _k: float) -> void:
		sig_counts[&"coalition_declared"] = sig_counts[&"coalition_declared"] + 1
	var on_overgraze: Callable = func(_pl: int, _c: Vector2i, _k: float) -> void:
		sig_counts[&"overgrazing_rebellion"] = sig_counts[&"overgrazing_rebellion"] + 1
	var on_betrayal: Callable = func(_b: StringName, _st: GameEnums.IntriguePlotStage, _t: int, _sb: bool, _k: float) -> void:
		sig_counts[&"internal_betrayal"] = sig_counts[&"internal_betrayal"] + 1
	var tracking_started: Array[bool] = [false]
	var on_kut_changed: Callable = func(_prev: float, new_kut: float, _reason: StringName) -> void:
		if tracking_started[0]:
			result.min_kut_observed = minf(result.min_kut_observed, new_kut)

	EventBus.ak_sakallilar_council_convened.connect(on_council)
	EventBus.coalition_war_declared.connect(on_coalition)
	EventBus.overgrazing_rebellion_triggered.connect(on_overgraze)
	EventBus.internal_betrayal_triggered.connect(on_betrayal)
	EventBus.kut_changed.connect(on_kut_changed)

	# Load required data resources
	var steppe: TerrainData = ResourceLoader.load("res://data/terrain/steppe.tres") as TerrainData
	var forest: TerrainData = ResourceLoader.load("res://data/terrain/forest.tres") as TerrainData
	var doctrine: TacticalDoctrineData = ResourceLoader.load("res://data/tactics/crescent_encirclement.tres") as TacticalDoctrineData
	var combat_rules: CombatRules = ResourceLoader.load("res://data/combat/combat_rules.tres") as CombatRules
	var winter: SeasonData = ResourceLoader.load("res://data/seasons/winter.tres") as SeasonData
	var army_packed: PackedScene = ResourceLoader.load("res://units/army.tscn") as PackedScene
	var ger_data: BuildingData = ResourceLoader.load("res://data/buildings/ger_camp.tres") as BuildingData

	# Instantiate decoupled unit components & depot
	var army: ArmyController = army_packed.instantiate() as ArmyController
	army.army_id = army_id
	army.owner_id = pid
	army.position = Vector3(80.0, 0.0, 80.0)
	host_node.add_child(army)

	var depot: SupplyDepotNode = SupplyDepotNode.new()
	depot.depot_id = depot_id
	depot.owner_id = pid
	depot.building_data = ger_data
	depot.position = Vector3(80.0, 0.0, 80.0)
	host_node.add_child(depot)

	var tactics: TuranTacticsComponent = TuranTacticsComponent.new()
	host_node.add_child(tactics)
	tactics.configure(army_id, doctrine, 100.0)

	var morale_comp: MoraleComponent = MoraleComponent.new()
	morale_comp.configure(army_id, combat_rules)
	morale_comp.configure_veteran_and_commander_profile(0.75, 72.0, 92.0, 90.0)
	host_node.add_child(morale_comp)

	var casualty_comp: AttritionCasualtyComponent = AttritionCasualtyComponent.new()
	host_node.add_child(casualty_comp)
	casualty_comp.configure(army_id, 240, 0.75)

	var glory_comp: GloryComponent = GloryComponent.new()
	host_node.add_child(glory_comp)
	glory_comp.configure(army_id, null, pid)

	# Establish clean deterministic starting baselines
	CausalChainEngine.reset_continuous_state()
	ResourceManager.set_camp_migration_and_supply_state(pid, false, false)
	CommandBus.dispatch(ModifyKutCommand.new(75.0 - GameManager.get_kut_score(), &"sim_init_baseline"))
	SeasonManager.set_food_reserve(35 if profile == SimulationProfile.CRISIS_CLAN else 140)
	SeasonManager.set_pasture_yield_multiplier(pid, 1.0)
	for d_id: StringName in DYNASTY_IDS:
		var prof: DynastyProfile = DiplomacyManager.get_dynasty_profile(d_id)
		if prof != null:
			DiplomacyManager.set_dynasty_trust(d_id, prof.trust_index)
	DiplomacyManager.set_political_intelligence_context(0.0, 0.0, 0.0, 0.0)
	DiplomacyManager.evaluate_all_dynasties(75.0, 1000.0, 0.25)
	var current_region_idx: int = 0
	CommandBus.dispatch(MigrateCampToPastureCommand.new(pid, region_band[0]))
	if SeasonManager.is_army_infected(army_id):
		CommandBus.dispatch(PurifyEpidemicCommand.new(army_id, &"kurgan_shrine"))
	CataclysmEngine.clear_region_cataclysm(region_band[0])
	BallisticsEngine.set_steppe_wind_weather(Vector3(0.0, 0.0, -6.0), 14.0, false)
	DiplomacyManager.step_seasonal_diplomatic_decay(10)
	CouncilEventEngine.step_seasonal_council_decay(10)

	var left_wing: Vector3 = Vector3(-0.35, 0.0, 0.936).normalized()
	var right_wing: Vector3 = Vector3(0.35, 0.0, -0.936).normalized()
	var econ_rules: EconomyRules = ResourceManager.get_economy_rules()
	var max_ore_cap: int = econ_rules.max_ore_stockpile_capacity if econ_rules != null else 50000
	tracking_started[0] = true

	for step_idx: int in range(num_seasons):
		var cur_coord: Vector2i = region_band[current_region_idx]

		# --- A. Mining, Taxation, Jade Scaling & 2 Iron + 1 Coal = 1 Steel ---
		var iron_gain: int = 12
		var coal_gain: int = 8
		var jade_gain: int = 4
		var herd_size: int = 340
		var migrate_every_n: int = 2
		var combat_cadence: int = 3
		var is_migrating_step: bool = false

		if profile == SimulationProfile.SETTLED_MINER:
			iron_gain = 32
			coal_gain = 20
			jade_gain = 10
			herd_size = 370
			migrate_every_n = 3
			combat_cadence = 4
		elif profile == SimulationProfile.CONTINUOUS_NOMAD:
			iron_gain = 8
			coal_gain = 6
			jade_gain = 2
			herd_size = 380
			migrate_every_n = 1
			combat_cadence = 2
		elif profile == SimulationProfile.CRISIS_CLAN:
			iron_gain = 10
			coal_gain = 6
			jade_gain = 2
			herd_size = 950 if step_idx < 7 else 320
			migrate_every_n = 99 if step_idx < 7 else 1
			combat_cadence = 2

		CommandBus.dispatch(DepositResourcesCommand.new(pid, &"iron", iron_gain + rng.randi_range(0, 6)))
		CommandBus.dispatch(DepositResourcesCommand.new(pid, &"coal", coal_gain + rng.randi_range(0, 4)))
		if jade_gain > 0:
			CommandBus.dispatch(DepositResourcesCommand.new(pid, &"jade", jade_gain))

		if step_idx % migrate_every_n == 0 and step_idx > 0:
			current_region_idx = (current_region_idx + 1) % region_band.size()
			cur_coord = region_band[current_region_idx]
			var mig_cmd: MigrateCampToPastureCommand = MigrateCampToPastureCommand.new(pid, cur_coord)
			if CommandBus.dispatch(mig_cmd):
				is_migrating_step = true
				result.migrations_performed += 1
				result.migration_food_spent += mig_cmd.migration_food_spent

		var supply_cut_step: bool = (profile == SimulationProfile.CRISIS_CLAN and step_idx >= 0 and step_idx <= 6)
		ResourceManager.set_camp_migration_and_supply_state(pid, is_migrating_step, supply_cut_step)
		if supply_cut_step and not CommandBus.is_army_supply_isolated(army_id):
			CommandBus.dispatch(InterdictSupplyLineCommand.new(army_id, depot_id, agent_id))
		elif not supply_cut_step and CommandBus.is_army_supply_isolated(army_id):
			CommandBus.dispatch(RestoreSupplyLineCommand.new(army_id, depot_id, 0.45))

		var target_batches: int = 10 if profile == SimulationProfile.SETTLED_MINER else 4
		var smelted: int = ResourceManager.smelt_steel_with_logistics_constraints(pid, target_batches)
		result.steel_batches_smelted += smelted

		var reg_count: int = 3 if profile == SimulationProfile.SETTLED_MINER else 2
		var rich_count: int = 2 if profile == SimulationProfile.SETTLED_MINER else 1
		ResourceManager.collect_regional_tax(pid, reg_count, rich_count)

		# --- B. Ecology Grazing & Cataclysm Exposure ---
		var active_season: SeasonData = SeasonManager.get_current_season()
		var sea_dep_mult: float = 1.2 if (active_season != null and active_season.season_type == GameEnums.SeasonType.WINTER) else 1.0
		var graze_cmd: GrazePastureCommand = GrazePastureCommand.new(pid, cur_coord, herd_size, sea_dep_mult)
		CommandBus.dispatch(graze_cmd)
		if graze_cmd.condition == GameEnums.PastureCondition.GRAZED:
			result.had_grazed_friction = true
		var eff_pasture_mult: float = PastureEcologyManager.get_meat_milk_production_multiplier(pid)
		SeasonManager.set_pasture_yield_multiplier(pid, eff_pasture_mult)

		if profile == SimulationProfile.CRISIS_CLAN and step_idx == 5:
			CommandBus.dispatch(EvaluateCataclysmCommand.new(cur_coord, true, -18.0, true, 0.0, 2.0, 0.0))
		elif step_idx >= 9:
			CataclysmEngine.clear_region_cataclysm(cur_coord)

		# --- C. Seasonal Advancement & Food / Winter Zud Resolution ---
		var next_season: SeasonData = SeasonManager.advance_season_cycle(PastureEcologyManager.get_meat_milk_production_multiplier(pid))
		if next_season != null:
			army.mobility.set_season(next_season)
		if next_season != null and next_season.season_type == GameEnums.SeasonType.WINTER:
			if SeasonManager.get_food_reserve() <= 0:
				SeasonManager.evaluate_zud_epidemic_outbreak(army_id, true, rng_seed + step_idx, next_season)

		if SeasonManager.is_army_infected(army_id):
			var rem_troops: int = SeasonManager.simulate_epidemic_day(army_id, casualty_comp.get_active_troops())
			var pur_cost: float = SeasonManager.get_effective_purification_kut_cost(army_id)
			if GameManager.get_kut_score() >= pur_cost + 15.0 and rem_troops > 0:
				CommandBus.dispatch(PurifyEpidemicCommand.new(army_id, &"kurgan_shrine"))

		# --- D. Tactical Combat Cycle, Casualties & Wounded Pool Recovery ---
		if step_idx % combat_cadence == 1:
			result.battles_fought += 1
			var attacker_st: CombatantStats = CombatantStats.new(army_id, 210.0 + float(smelted) * 8.0, 125.0, 750.0, army.supply.get_supply_ratio())
			attacker_st.has_steel_weapons = ResourceManager.get_amount(pid, &"steel") > 0
			attacker_st.combat_duration_sec = 8.0
			var is_crisis_siege_foe: bool = (profile == SimulationProfile.CRISIS_CLAN and step_idx <= 6)
			var def_atk: float = 240.0 if is_crisis_siege_foe else 130.0
			var def_def: float = 140.0 if is_crisis_siege_foe else 95.0
			var def_hp: float = 950.0 if is_crisis_siege_foe else 480.0
			var defender_st: CombatantStats = CombatantStats.new(9500 + step_idx, def_atk, def_def, def_hp, 0.90)

			tactics.execute_whistling_arrow_volley(defender_st)
			if tactics.get_current_phase() == GameEnums.TuranTacticPhase.FEIGNED_RETREAT_LURE or tactics.get_quiver_ammo() <= 0.0:
				tactics.calculate_lure_overextension(0.82, 0.45, 95.0, defender_st)
			if tactics.get_current_phase() == GameEnums.TuranTacticPhase.CRESCENT_ENCIRCLEMENT_TRAP:
				tactics.evaluate_crescent_trap(left_wing, right_wing, forest, defender_st)
			if tactics.get_current_phase() == GameEnums.TuranTacticPhase.BORU_SHOCK_ANNIHILATION:
				tactics.compute_boru_shock_momentum(820.0, 13.0, attacker_st.has_steel_weapons, false)
			attacker_st.active_tactic_phase = tactics.get_current_phase()
			attacker_st.quiver_ammo_ratio = clampf(tactics.get_quiver_ammo() / 100.0, 0.0, 1.0)
			attacker_st.remount_horse_ratio = army.supply.get_remount_horse_ratio()

			var combat_cmd: ResolveCombatCommand = ResolveCombatCommand.new(attacker_st, defender_st, steppe, rng_seed + step_idx * 17)
			CommandBus.dispatch(combat_cmd)
			var fallen: int = 14 if profile != SimulationProfile.CRISIS_CLAN else 24
			casualty_comp.record_battle_casualties(fallen, 1.15, 0.12)
			morale_comp.accumulate_battle_fatigue(8.0)

		casualty_comp.tick_wounded_treatment(not supply_cut_step)
		casualty_comp.tick_cohesion_acclimation(5.0)
		if casualty_comp.get_active_troops() < 160 and ResourceManager.get_amount(pid, &"silver_gold") >= 40:
			casualty_comp.reinforce_with_raw_recruits(40)
		morale_comp.recover_fatigue_and_rally(4.5, maxf(army.supply.get_supply_ratio(), 0.25))
		tactics.rest_and_resupply_tactical_readiness(15.0, 45.0, 0.25, steppe)
		army.supply._physics_process(2.5)

		# --- E. AI Commander, Diplomacy, Council & Kinship Intrigue ---
		var unfair_toy: bool = (profile == SimulationProfile.CRISIS_CLAN and step_idx >= 3 and step_idx <= 6)
		var low_kut: bool = GameManager.get_kut_score() < 30.0
		CommandBus.dispatch(StepAICommanderCommand.new(agent_id, true, depot_id, army_id))
		CommandBus.dispatch(StepKinshipIntrigueCommand.new(bey_id, unfair_toy, low_kut, 75.0, army_id if unfair_toy else 0))

		if CouncilEventEngine.is_crisis_dilemma_pending() and GameManager.is_ak_sakallilar_council_active():
			var choice: GameEnums.CouncilDilemmaChoice = GameEnums.CouncilDilemmaChoice.SACRIFICE
			if ResourceManager.get_amount(pid, &"steel") < 5 or ResourceManager.get_amount(pid, &"silver_gold") < 30:
				choice = GameEnums.CouncilDilemmaChoice.TRADITION
			CommandBus.dispatch(EnactCouncilDecreeCommand.new(pid, choice))

		DiplomacyManager.evaluate_all_dynasties(GameManager.get_kut_score(), float(casualty_comp.get_active_troops()) * 4.5, 0.25)

		CommandBus.dispatch(StepContinuousSimulationCommand.new(
			pid,
			army_id,
			2.0,
			PastureEcologyManager.is_livestock_starving(pid),
			is_migrating_step,
			not CommandBus.is_army_supply_isolated(army_id),
			active_season != null and active_season.season_type == GameEnums.SeasonType.WINTER,
			0.25 if unfair_toy else 0.70,
			step_idx % combat_cadence != 1))

		# --- F. Record SeasonSnapshot & Validate Invariants ---
		var snap: SimulationInvariantChecker.SeasonSnapshot = _capture_snapshot(
			step_idx,
			pid,
			army_id,
			cur_coord,
			bey_id,
			army,
			tactics,
			morale_comp,
			casualty_comp,
			glory_comp)
		result.history.append(snap)
		result.seasons_simulated += 1
		result.min_food_observed = mini(result.min_food_observed, snap.food)
		result.min_kut_observed = minf(result.min_kut_observed, snap.kut)
		result.min_remount_observed = minf(result.min_remount_observed, snap.remount_horse_ratio)
		result.min_pasture_multiplier_observed = minf(result.min_pasture_multiplier_observed, snap.meat_milk_multiplier)
		if snap.pasture_starving:
			result.had_starving_pasture = true
		if snap.council_active:
			result.had_council_crisis = true

		var step_errors: PackedStringArray = SimulationInvariantChecker.validate_snapshot(snap, max_ore_cap)
		for err: String in step_errors:
			result.violations.append(err)

	var hist_errors: PackedStringArray = SimulationInvariantChecker.validate_history(result.history, sig_counts)
	for err: String in hist_errors:
		result.violations.append(err)
	result.signal_counts = sig_counts
	if sig_counts.get(&"council_convened", 0) > 0:
		result.had_council_crisis = true

	# Restore clean shared singleton baselines & detach temporary test objects
	EventBus.ak_sakallilar_council_convened.disconnect(on_council)
	EventBus.coalition_war_declared.disconnect(on_coalition)
	EventBus.overgrazing_rebellion_triggered.disconnect(on_overgraze)
	EventBus.internal_betrayal_triggered.disconnect(on_betrayal)
	EventBus.kut_changed.disconnect(on_kut_changed)

	depot.free()
	army.free()
	tactics.free()
	morale_comp.free()
	casualty_comp.free()
	glory_comp.free()

	if winter != null:
		pass
	ResourceManager.set_camp_migration_and_supply_state(pid, false, false)
	CommandBus.dispatch(ModifyKutCommand.new(75.0 - GameManager.get_kut_score(), &"sim_cleanup_restore"))
	SeasonManager.set_food_reserve(120)
	DiplomacyManager.evaluate_all_dynasties(75.0, 1000.0, 0.2)
	CouncilEventEngine.step_seasonal_council_decay(5)
	BallisticsEngine.set_steppe_wind_weather(Vector3(0.0, 0.0, -6.0), 14.0, false)
	CausalChainEngine.reset_continuous_state()

	return result


static func _capture_snapshot(
		step_idx: int,
		pid: int,
		army_id: int,
		cur_coord: Vector2i,
		bey_id: StringName,
		army: ArmyController,
		tactics: TuranTacticsComponent,
		morale_comp: MoraleComponent,
		casualty_comp: AttritionCasualtyComponent,
		glory_comp: GloryComponent) -> SimulationInvariantChecker.SeasonSnapshot:
	var snap: SimulationInvariantChecker.SeasonSnapshot = SimulationInvariantChecker.SeasonSnapshot.new()
	snap.season_index = step_idx
	var cur_season: SeasonData = SeasonManager.get_current_season()
	snap.season_type = cur_season.season_type if cur_season != null else GameEnums.SeasonType.SPRING
	snap.food = SeasonManager.get_food_reserve()
	snap.kut = GameManager.get_kut_score()

	var ore_map: Dictionary[StringName, int] = {}
	for ore_id: StringName in ORE_IDS:
		ore_map[ore_id] = ResourceManager.get_amount(pid, ore_id)
	snap.ores = ore_map

	snap.jade_authority_multiplier = ResourceManager.calculate_jade_authority_multiplier(pid)
	snap.pasture_coord = cur_coord
	snap.pasture_capacity = PastureEcologyManager.get_region_pasture_capacity(cur_coord)
	snap.pasture_starving = PastureEcologyManager.is_livestock_starving(pid)
	snap.meat_milk_multiplier = PastureEcologyManager.get_meat_milk_production_multiplier(pid)
	snap.remount_horse_ratio = army.supply.get_remount_horse_ratio()
	snap.active_troops = casualty_comp.get_active_troops()
	snap.wounded_pool = casualty_comp.get_wounded_pool()
	snap.permanent_dead = casualty_comp.get_permanent_dead()
	snap.veteran_ratio = casualty_comp.get_veteran_ratio()
	snap.glory_score = glory_comp.get_glory_score()
	snap.epidemic_active = SeasonManager.is_army_infected(army_id)

	var active_cat: CataclysmEventData = CataclysmEngine.get_active_region_cataclysm(cur_coord)
	snap.cataclysm_type = active_cat.cataclysm_type if active_cat != null else GameEnums.CataclysmType.NONE

	var trust_map: Dictionary[StringName, float] = {}
	var stance_map: Dictionary[StringName, GameEnums.DynastyAttitude] = {}
	for d_id: StringName in DYNASTY_IDS:
		trust_map[d_id] = DiplomacyManager.get_dynasty_trust(d_id)
		stance_map[d_id] = DiplomacyManager.get_dynasty_stance(d_id)
	snap.dynasty_trust = trust_map
	snap.dynasty_stances = stance_map
	snap.coalition_war_active = DiplomacyManager.is_coalition_war_active()

	snap.council_active = GameManager.is_ak_sakallilar_council_active()
	snap.council_dilemma_pending = CouncilEventEngine.is_crisis_dilemma_pending()
	snap.council_income_multiplier = CouncilEventEngine.get_active_income_multiplier()
	snap.council_speed_multiplier = CouncilEventEngine.get_active_speed_multiplier()

	var lord: KinshipLordRecord = KinshipIntrigueManager.get_or_create_lord(bey_id)
	snap.kinship_stage = lord.plot_stage
	snap.kinship_loyalty = lord.loyalty
	snap.kinship_grievance = lord.grievance

	snap.turan_phase = tactics.get_current_phase()
	snap.turan_quiver_ammo = tactics.get_quiver_ammo()
	snap.turan_fatigue = tactics.get_own_fatigue()

	snap.army_morale = morale_comp.get_current_morale()
	snap.army_cohesion = morale_comp.get_current_cohesion()
	snap.army_fatigue = morale_comp.get_battle_fatigue()
	snap.cascade_routing = morale_comp.is_cascade_routing()
	snap.army_speed = army.mobility.get_target_speed()
	snap.base_speed = army.template.get_slowest_base_speed()
	snap.transition_history_size = CausalChainEngine.get_transition_history().size()
	return snap
