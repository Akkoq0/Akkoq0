extends Node
## Headless integration & architectural test suite (rank 4).
##
## Run with: `godot --headless --path . res://tests/test_suite.tscn`

var _failures: PackedStringArray = PackedStringArray()
var _assertions: int = 0
var _council_signal_received: bool = false
var _rogue_warband_signal_received: bool = false
var _quiver_depleted_signal_received: bool = false
var _lured_signal_received: bool = false
var _entropy_critical_signal_received: bool = false
var _crescent_trap_signal_received: bool = false
var _supply_severed_signal_received: bool = false
var _yilki_sacrificed_signal_received: bool = false
var _espionage_signal_received: bool = false
var _envoy_assassinated_signal_received: bool = false
var _total_war_signal_received: bool = false
var _cascade_rout_signal_received: bool = false
var _enslaved_to_toy_signal_received: bool = false
var _epidemic_outbreak_signal_received: bool = false
var _epidemic_attrition_signal_received: bool = false
var _epidemic_purified_signal_received: bool = false
var _dynasty_stance_signal_received: bool = false
var _coalition_war_signal_received: bool = false
var _council_decree_signal_received: bool = false
var _glory_changed_signal_received: bool = false
var _warband_joined_by_glory_signal_received: bool = false
var _building_placed_signal_received: bool = false
var _worker_started_signal_received: bool = false
var _worker_delivered_signal_received: bool = false
var _ai_phase_changed_signal_received: bool = false
var _ai_raid_launched_signal_received: bool = false
var _pasture_depleted_signal_received: bool = false
var _camp_migrated_signal_received: bool = false
var _overgrazing_rebellion_signal_received: bool = false
var _wind_changed_signal_received: bool = false
var _volley_resolved_signal_received: bool = false
var _noble_captives_signal_received: bool = false
var _captive_labor_signal_received: bool = false
var _slave_revolt_signal_received: bool = false
var _sovereignty_evolved_signal_received: bool = false
var _emergent_chain_signal_received: bool = false
var _inter_faction_conflict_signal_received: bool = false
var _player_intervened_signal_received: bool = false
var _outpost_relocated_signal_received: bool = false
var _force_detached_signal_received: bool = false
var _forces_merged_signal_received: bool = false
var _cataclysm_erupted_signal_received: bool = false
var _cataclysm_subsided_signal_received: bool = false
var _kinship_plot_signal_received: bool = false
var _internal_betrayal_signal_received: bool = false
var _kinship_resolved_signal_received: bool = false
var _battle_wounded_signal_received: bool = false
var _wounded_recovered_signal_received: bool = false
var _veteran_shock_signal_received: bool = false
var _causal_step_propagated_signal_received: bool = false
var _causal_counterplay_signal_received: bool = false
var _causal_transition_records: Array[CausalTransitionRecord] = []
var _p12_overgrazing_rebellion_count: int = 0
var _p12_supply_restored_count: int = 0
var _p12_council_convened_count: int = 0
var _p12_coalition_declared_count: int = 0
var _p12_cataclysm_erupted_count: int = 0
var _p12_internal_betrayal_count: int = 0


func _ready() -> void:
	_run_suite.call_deferred()


func _run_suite() -> void:
	_test_architecture_governance()
	_test_ore_registry_and_economy()
	_test_phase2_seven_ore_pipeline()
	_test_buildings_nomadic_and_roi()
	_test_totems_100_point_asymmetry()
	_test_world_macro_and_micro_generation()
	_test_army_weight_mobility_and_supply()
	_test_combat_calculator()
	_test_camera_profile_and_layer_switch()
	_test_phase2_kut_and_ak_sakallilar_council()
	_test_phase2_toy_and_meat_distribution()
	_test_phase3_turan_tactics_fsm()
	_test_phase3_vectorial_combat_and_seven_ores()
	_test_phase3_yilki_logistics_and_zud_sacrifice()
	_test_phase4_espionage_and_envoy_provocation()
	_test_phase4_psychological_warfare_and_cascade_rout()
	_test_phase4_zud_epidemic_and_kurgan_purification()
	_test_phase5_dynasty_threat_matrix_and_coalition_war()
	_test_phase5_ak_sakallilar_council_dilemmas()
	_test_phase5_kagan_glory_and_warband_recruitment()
	_test_phase6_micro_building_placement_and_collision()
	_test_phase6_worker_gathering_caravan_pipeline()
	_test_phase6_ai_commander_and_raider_loop()
	_test_phase7_pasture_ecology_and_sefer_arabasi_migration()
	_test_phase7_vectorial_wind_and_atmospheric_ballistics()
	_test_phase7_tore_captive_labor_and_revolt_risk()
	_test_phase8_dynamic_sovereignty_path_evolution()
	_test_phase8_emergent_causality_and_inter_faction_wars()
	_test_phase8_free_outpost_migration_and_modular_forces()
	_test_phase9_steppe_cataclysms_and_natural_destruction()
	_test_phase9_kinship_intrigue_and_internal_betrayal()
	_test_phase9_wounded_pool_and_veteran_attrition()
	_test_causal_friction_calibration_and_threshold_matrix()
	_test_causal_chains_and_counterplay_recovery()
	_test_phase11_continuous_accumulation_decay_and_telemetry()
	_test_phase11_turan_maneuver_readiness_and_layered_morale()
	_test_phase11_economy_logistics_contagion_and_political_synergy()
	_test_phase12_long_horizon_ecology_seasons_and_supply_recovery()
	_test_phase12_long_horizon_combat_turan_reset_and_bounds()
	_test_phase12_long_horizon_politics_intrigue_envoy_and_telemetry()
	_test_phase14_deterministic_long_horizon_harness()
	_test_phase15_economy_ecology_profile_calibration()
	_test_phase16_combat_turan_fsm_and_casualty_hardening()
	_test_phase17_politics_intrigue_dynasty_long_horizon()
	_test_phase18_persistent_world_peace_and_anti_snowball()
	_test_main_scene_integration()

	if _failures.is_empty():
		print("[PASS] Ötüken Full Architecture & Causal Chains validation succeeded (%d assertions, 0 failures)." % _assertions)
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error("[FAIL] %s" % failure)
		get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	_assertions += 1
	if not condition:
		_failures.append(message)


func _test_architecture_governance() -> void:
	var errors: PackedStringArray = ArchitectureVerifier.run_all_checks()
	for err: String in errors:
		_failures.append("Governance: %s" % err)
	_expect(errors.is_empty(), "ArchitectureVerifier found zero violations.")


func _test_ore_registry_and_economy() -> void:
	var registry: OreRegistry = ResourceManager.get_registry()
	_expect(registry != null, "OreRegistry loads via ResourceManager.")
	_expect(registry.ores.size() == 7, "Exactly 7 core ores registered.")
	var expected_ids: Array[StringName] = [
		&"stone", &"iron", &"coal", &"silver_gold", &"jade", &"sulfur", &"meteoric_iron"
	]
	for ore_id: StringName in expected_ids:
		_expect(registry.has_ore(ore_id), "Ore '%s' exists in registry." % ore_id)

	var deposit: DepositResourcesCommand = DepositResourcesCommand.new(1, &"stone", 100)
	_expect(CommandBus.dispatch(deposit), "DepositResourcesCommand succeeds.")
	_expect(deposit.resulting_amount == 600, "Stone stockpile updated from 500 to 600.")

	var invalid_deposit: DepositResourcesCommand = DepositResourcesCommand.new(1, &"unknown_ore", 10)
	_expect(not CommandBus.dispatch(invalid_deposit), "Unknown ore deposit is rejected.")


func _test_phase2_seven_ore_pipeline() -> void:
	var iron_before: int = ResourceManager.get_amount(2, &"iron")
	var coal_before: int = ResourceManager.get_amount(2, &"coal")
	var steel_before: int = ResourceManager.get_amount(2, &"steel")
	_expect(ResourceManager.smelt_steel_in_nomadic_forge(2, 4), "Smelting 4 Steel in NomadicForge succeeds.")
	_expect(ResourceManager.get_amount(2, &"iron") == iron_before - 8, "Smelting 4 Steel consumes 8 Iron (2 per Steel).")
	_expect(ResourceManager.get_amount(2, &"coal") == coal_before - 4, "Smelting 4 Steel consumes 4 Coal (1 per Steel).")
	_expect(ResourceManager.get_amount(2, &"steel") == steel_before + 4, "Smelting 4 Steel produces 4 Steel.")

	var wrong_building_cmd: RefineOreCommand = RefineOreCommand.new(2, &"quarry", &"smelt_steel", 1)
	_expect(not CommandBus.dispatch(wrong_building_cmd), "Steel smelting outside NomadicForge is rejected.")

	var base_auth: float = ResourceManager.calculate_jade_authority_multiplier(2)
	_expect(base_auth > 1.0, "Starting Jade grants > 1.0 Tamga/Authority multiplier.")
	CommandBus.dispatch(DepositResourcesCommand.new(2, &"jade", 40))
	var boosted_auth: float = ResourceManager.calculate_jade_authority_multiplier(2)
	_expect(boosted_auth > base_auth, "Depositing Jade increases Tamga/Authority multiplier.")

	var treasury_before: int = ResourceManager.get_amount(2, &"silver_gold")
	var tax_collected: int = ResourceManager.collect_regional_tax(2, 5, 2)
	_expect(tax_collected > 0, "Regional Silver/Gold tax is positive.")
	_expect(ResourceManager.get_amount(2, &"silver_gold") == treasury_before + tax_collected,
		"Regional Silver/Gold tax is routed directly to the player's treasury.")

	_expect(ResourceManager.can_bind_meteoric_iron(2, false), "Player can bind Meteoric Iron to commander weapon.")
	var bind_weapon: BindMeteoricIronCommand = BindMeteoricIronCommand.new(2, &"khagan_kilic", false)
	_expect(CommandBus.dispatch(bind_weapon), "Commander weapon Meteoric Iron binding succeeds.")
	_expect(bind_weapon.consumed_amount == 5, "Commander weapon binding consumes 5 Meteoric Iron.")
	_expect(ResourceManager.is_meteoric_iron_bound(2, &"khagan_kilic"), "Commander weapon recorded as bound.")
	_expect(not CommandBus.dispatch(BindMeteoricIronCommand.new(2, &"khagan_kilic", false)),
		"Duplicate Meteoric Iron binding on same target is rejected.")

	var bind_totem: BindMeteoricIronCommand = BindMeteoricIronCommand.new(2, &"bozkurt_ascension", true)
	_expect(CommandBus.dispatch(bind_totem), "Totem ascension Meteoric Iron binding succeeds.")
	_expect(bind_totem.consumed_amount == 12, "Totem ascension consumes 12 Meteoric Iron.")


func _test_buildings_nomadic_and_roi() -> void:
	var ger: BuildingData = ResourceLoader.load("res://data/buildings/ger_camp.tres") as BuildingData
	var forge: BuildingData = ResourceLoader.load("res://data/buildings/nomadic_forge.tres") as BuildingData
	var quarry: BuildingData = ResourceLoader.load("res://data/buildings/quarry.tres") as BuildingData
	var kurgan: BuildingData = ResourceLoader.load("res://data/buildings/kurgan_shrine.tres") as BuildingData
	var cart: BuildingData = ResourceLoader.load("res://data/buildings/sefer_arabasi.tres") as BuildingData

	_expect(ger.is_nomadic_movable and ger.is_supply_depot(), "Ger camp is nomadic movable and a supply depot.")
	_expect(cart != null and cart.id == &"sefer_arabasi" and cart.is_nomadic_movable, "Sefer Arabası migration cart resource loads.")
	_expect(forge.is_nomadic_movable and forge.get_net_income_per_minute() > 0.0, "Nomadic forge has positive net income.")
	_expect(not quarry.is_nomadic_movable and is_inf(quarry.get_relocation_time_sec()), "Static quarry has INF relocation time.")
	_expect(kurgan.is_supply_depot() and kurgan.get_payback_minutes() < INF, "Kurgan shrine has finite ROI payback.")
	_expect(forge.get_roi_ratio(20.0) > 0.0, "Nomadic forge 20-minute ROI is positive.")
	_expect(forge.get_roi_ratio(20.0, 2, 1.0) < forge.get_roi_ratio(20.0, 0, 1.0),
		"Relocations reduce net ROI over a fixed horizon.")
	_expect(ger.get_payback_minutes(1.5, 1.0) < ger.get_payback_minutes(1.0, 1.0),
		"Higher Jade Tamga/Authority multiplier shortens payback time.")

	var base_reloc_cost: float = ger.get_relocation_cost_value()
	var dynamic_reloc_cost: float = ger.calculate_dynamic_relocation_cost_value(120.0, 0.8, 1.5)
	var base_reloc_time: float = ger.get_relocation_time_sec()
	var dynamic_reloc_time: float = ger.calculate_dynamic_relocation_time_sec(120.0, 0.8, 0.7)
	_expect(dynamic_reloc_cost > base_reloc_cost, "Sefer Arabası migration distance and harsh terrain/season increase relocation cost.")
	_expect(dynamic_reloc_time > base_reloc_time, "Sefer Arabası migration distance increases total relocation time.")


func _test_totems_100_point_asymmetry() -> void:
	_expect(TotemManager.is_roster_valid(), "TotemManager validated all 8 totems on 100-point budget.")
	var roster: TotemRoster = TotemManager.get_roster()
	_expect(roster != null and roster.totems.size() == 8, "TotemRoster contains 8 totems.")
	for totem: TotemData in roster.totems:
		_expect(totem.get_allocated_points() == 100, "Totem '%s' allocates 100 points." % totem.id)
	var summon: SummonTotemCommand = SummonTotemCommand.new(1, &"bozkurt", Vector3.ZERO)
	_expect(CommandBus.dispatch(summon), "SummonTotemCommand succeeds when resources suffice.")
	_expect(not CommandBus.dispatch(SummonTotemCommand.new(1, &"bozkurt", Vector3.ZERO)), "Totem cooldown blocks immediate re-summon.")


func _test_world_macro_and_micro_generation() -> void:
	var macro_cfg: MacroWorldConfig = ResourceLoader.load("res://data/world/macro_world_config.tres") as MacroWorldConfig
	var micro_cfg: MicroZoneConfig = ResourceLoader.load("res://data/world/micro_zone_config.tres") as MicroZoneConfig
	var macro_gen: MacroWorldGenerator = MacroWorldGenerator.new()
	macro_gen.config = macro_cfg
	macro_gen.generate_on_ready = false
	var world_state: MacroWorldState = macro_gen.generate()
	_expect(world_state != null, "MacroWorldGenerator produces MacroWorldState.")
	_expect(world_state.get_regions().size() == 64, "Macro world has 8x8 = 64 regions.")
	for region: MacroRegion in world_state.get_regions():
		_expect(region.terrain.is_allowed_in_layer(GameEnums.WorldLayer.MACRO),
			"Macro region %s terrain allowed on MACRO." % region.coord)

	var micro_gen: MicroZoneGenerator = MicroZoneGenerator.new()
	micro_gen.config = micro_cfg
	add_child(micro_gen)
	EventBus.macro_world_generated.emit(world_state)
	var zone: MicroZoneState = micro_gen.get_or_generate_zone(Vector2i(3, 3))
	_expect(zone != null and zone.get_tiles().size() == 256, "MicroZoneGenerator produces 16x16 = 256 tiles.")
	for tile: MicroTile in zone.get_tiles():
		_expect(tile.terrain.is_allowed_in_layer(GameEnums.WorldLayer.MICRO),
			"Micro tile %s terrain allowed on MICRO." % tile.coord)
	micro_gen.free()
	macro_gen.free()


func _test_army_weight_mobility_and_supply() -> void:
	var template: ArmyTemplate = ResourceLoader.load("res://data/units/vanguard_army.tres") as ArmyTemplate
	var profile: MobilityProfile = template.mobility_profile
	var base_speed: float = template.get_slowest_base_speed()
	var capacity: float = template.get_total_carry_capacity()
	var base_weight: float = template.get_total_unit_weight()

	var unloaded_speed: float = ArmyMobilityComponent.calculate_weighted_speed(base_speed, 0.0, capacity, profile)
	var normal_speed: float = ArmyMobilityComponent.calculate_weighted_speed(base_speed, base_weight, capacity, profile)
	var full_speed: float = ArmyMobilityComponent.calculate_weighted_speed(base_speed, capacity, capacity, profile)
	var overloaded_speed: float = ArmyMobilityComponent.calculate_weighted_speed(base_speed, capacity * 1.5, capacity, profile)

	_expect(is_equal_approx(unloaded_speed, base_speed), "Zero weight retains 100% base speed.")
	_expect(normal_speed < unloaded_speed and normal_speed > full_speed, "Weight reduces speed monotonically within capacity.")
	_expect(is_equal_approx(full_speed, base_speed * profile.min_speed_factor), "Full capacity reaches min_speed_factor.")
	_expect(overloaded_speed < full_speed, "Overloading beyond capacity applies overload penalty.")


func _test_combat_calculator() -> void:
	var steppe: TerrainData = ResourceLoader.load("res://data/terrain/steppe.tres") as TerrainData
	var mountain: TerrainData = ResourceLoader.load("res://data/terrain/mountain.tres") as TerrainData
	var attacker: CombatantStats = CombatantStats.new(1, 200.0, 120.0, 1000.0, 1.0)
	var defender: CombatantStats = CombatantStats.new(2, 160.0, 140.0, 1000.0, 1.0)
	var defender2: CombatantStats = CombatantStats.new(3, 160.0, 140.0, 1000.0, 1.0)

	var cmd_steppe: ResolveCombatCommand = ResolveCombatCommand.new(attacker, defender, steppe, 42)
	var cmd_mountain: ResolveCombatCommand = ResolveCombatCommand.new(attacker, defender2, mountain, 42)
	_expect(CommandBus.dispatch(cmd_steppe) and CommandBus.dispatch(cmd_mountain), "ResolveCombatCommand dispatches.")
	_expect(cmd_mountain.result.damage_to_defender < cmd_steppe.result.damage_to_defender,
		"Mountain defense multiplier reduces damage taken by defender.")


func _test_camera_profile_and_layer_switch() -> void:
	var cam_profile: CameraProfile = ResourceLoader.load("res://data/camera/camera_profile.tres") as CameraProfile
	_expect(cam_profile != null and is_equal_approx(cam_profile.transition_duration_sec, 0.4),
		"CameraProfile specifies 0.4s cloud transition.")


func _test_phase2_kut_and_ak_sakallilar_council() -> void:
	_council_signal_received = false
	EventBus.ak_sakallilar_council_convened.connect(_on_ak_sakallilar_council_convened)

	var initial_kut: float = GameManager.get_kut_score()
	_expect(is_equal_approx(initial_kut, 75.0), "Initial Kut score starts at 75 on the 0-100 scale.")

	var winter: SeasonData = ResourceLoader.load("res://data/seasons/winter.tres") as SeasonData
	SeasonManager.set_food_reserve(0)
	_expect(SeasonManager.evaluate_zud_starvation(winter), "Zud starvation triggers when Food <= 0 during Winter.")
	var after_zud_kut: float = GameManager.get_kut_score()
	_expect(after_zud_kut < initial_kut, "Zud starvation drains Kut.")

	GameManager.record_battle_outcome(false)
	GameManager.record_battle_outcome(false)
	GameManager.record_battle_outcome(false)
	_expect(GameManager.get_consecutive_battle_losses() == 3, "Consecutive battle losses tracked accurately.")
	_expect(GameManager.get_kut_score() < 30.0, "Sustained Zud starvation and consecutive defeats drop Kut below 30.")
	_expect(_council_signal_received and GameManager.is_ak_sakallilar_council_active(),
		"Kut < 30 convenes Ak Sakallılar Konseyi via EventBus.")
	_expect(GameManager.get_legitimacy_multiplier() < 1.0,
		"Ak Sakallılar Konseyi applies internal legitimacy penalty.")

	EventBus.ak_sakallilar_council_convened.disconnect(_on_ak_sakallilar_council_convened)


func _test_phase2_toy_and_meat_distribution() -> void:
	_rogue_warband_signal_received = false
	EventBus.bey_rebelled_as_rogue_warband.connect(_on_bey_rebelled)

	var fair_cmd: DistributeToyLootCommand = DistributeToyLootCommand.new(&"bumin_bey", 1000.0, 450.0, true)
	_expect(CommandBus.dispatch(fair_cmd), "Fair Toy & Meat distribution command succeeds.")
	_expect(fair_cmd.resulting_satisfaction > 65.0 and not fair_cmd.turned_rogue_warband,
		"Fair loot share and Söğüş meat portion increase Bey satisfaction.")

	var unfair_cmd1: DistributeToyLootCommand = DistributeToyLootCommand.new(&"kulan_bey", 1000.0, 50.0, false)
	_expect(CommandBus.dispatch(unfair_cmd1), "Unfair Toy distribution command executes.")
	_expect(unfair_cmd1.resulting_satisfaction < 30.0, "Severe loot shortfall and unfair meat portion drop satisfaction < 30.")
	_expect(unfair_cmd1.turned_rogue_warband and _rogue_warband_signal_received,
		"Dissatisfied Bey converts into independent rogue warband.")
	_expect(unfair_cmd1.spawned_warband_title == "Yersiz Yurtsuz Çeriler" and CommandBus.is_bey_rogue_warband(&"kulan_bey"),
		"Rogue warband is titled 'Yersiz Yurtsuz Çeriler'.")

	EventBus.bey_rebelled_as_rogue_warband.disconnect(_on_bey_rebelled)


func _test_phase3_turan_tactics_fsm() -> void:
	_quiver_depleted_signal_received = false
	_lured_signal_received = false
	_entropy_critical_signal_received = false
	_crescent_trap_signal_received = false
	EventBus.quiver_ammo_depleted.connect(_on_quiver_depleted)
	EventBus.feigned_retreat_lured.connect(_on_feigned_retreat_lured)
	EventBus.formation_entropy_critical.connect(_on_entropy_critical)
	EventBus.crescent_trap_sprung.connect(_on_crescent_trap_sprung)

	var doc_charge: TacticalDoctrineData = ResourceLoader.load("res://data/tactics/standard_charge.tres") as TacticalDoctrineData
	var doc_retreat: TacticalDoctrineData = ResourceLoader.load("res://data/tactics/feigned_retreat.tres") as TacticalDoctrineData
	var doc_crescent: TacticalDoctrineData = ResourceLoader.load("res://data/tactics/crescent_encirclement.tres") as TacticalDoctrineData
	var doc_ambush: TacticalDoctrineData = ResourceLoader.load("res://data/tactics/steppe_ambush.tres") as TacticalDoctrineData
	_expect(doc_charge != null and doc_retreat != null and doc_crescent != null and doc_ambush != null,
		"All 4 TacticalDoctrineData .tres files load cleanly.")

	var tactics: TuranTacticsComponent = TuranTacticsComponent.new()
	add_child(tactics)
	_expect(tactics.configure(7, doc_retreat, 16.0), "TuranTacticsComponent configures with feigned_retreat.tres.")

	# Stage 1: RECON_DUST_SCREEN
	_expect(tactics.get_current_phase() == GameEnums.TuranTacticPhase.RECON_DUST_SCREEN,
		"Starts in RECON_DUST_SCREEN phase.")
	_expect(tactics.get_enemy_vision_multiplier() < 1.0 and tactics.get_deceptive_army_size_multiplier() > 1.0,
		"Dust screen narrows enemy vision and projects deceptive army size.")

	# Stage 2: WHISTLING_ARROW_HARASSMENT (2 volleys exhaust 16 quiver ammo -> forces exit to FEIGNED_RETREAT_LURE)
	var enemy: CombatantStats = CombatantStats.new(99, 180.0, 140.0, 1000.0, 1.0)
	tactics.execute_whistling_arrow_volley(enemy)
	_expect(enemy.cohesion < 100.0 and enemy.morale < 100.0, "Whistling arrows erode enemy cohesion and morale.")
	tactics.execute_whistling_arrow_volley(enemy)
	_expect(_quiver_depleted_signal_received and is_zero_approx(tactics.get_quiver_ammo()),
		"Depleting quiver ammo emits quiver_ammo_depleted.")
	_expect(tactics.get_current_phase() == GameEnums.TuranTacticPhase.FEIGNED_RETREAT_LURE,
		"Empty quiver forces transition out of WHISTLING_ARROW_HARASSMENT into FEIGNED_RETREAT_LURE.")

	# Stage 3: FEIGNED_RETREAT_LURE (overextension collapses armor up to 45%)
	var lure_metrics: Dictionary[StringName, float] = tactics.calculate_lure_overextension(0.95, 0.35, 65.0, enemy)
	_expect(_lured_signal_received and _entropy_critical_signal_received,
		"Feigned retreat lure emits feigned_retreat_lured and formation_entropy_critical.")
	_expect(is_equal_approx(lure_metrics[TuranTacticsComponent.KEY_ARMOR_COLLAPSE_RATIO], 0.45),
		"Full formation entropy collapses pursuing enemy armor multiplier by 45%.")
	_expect(tactics.get_current_phase() == GameEnums.TuranTacticPhase.CRESCENT_ENCIRCLEMENT_TRAP,
		"Critical formation entropy advances FSM to CRESCENT_ENCIRCLEMENT_TRAP.")

	# Stage 4: CRESCENT_ENCIRCLEMENT_TRAP (Vector3.dot flank angle >= PI * 0.65 on Sık Orman seals escape vector)
	var forest: TerrainData = ResourceLoader.load("res://data/terrain/forest.tres") as TerrainData
	var left_wing: Vector3 = Vector3(-0.35, 0.0, 0.936).normalized()
	var right_wing: Vector3 = Vector3(0.35, 0.0, -0.936).normalized()
	_expect(tactics.evaluate_crescent_trap(left_wing, right_wing, forest, enemy),
		"Wing pincer angle >= PI * 0.65 springs Crescent Encirclement Trap.")
	_expect(_crescent_trap_signal_received and enemy.is_escape_vector_sealed,
		"Ambush units in Sık Orman seal the enemy escape vector.")
	_expect(tactics.get_current_phase() == GameEnums.TuranTacticPhase.BORU_SHOCK_ANNIHILATION,
		"Springing Crescent Trap transitions FSM to BORU_SHOCK_ANNIHILATION.")

	# Stage 5: BORU_SHOCK_ANNIHILATION
	var shock_momentum: float = tactics.compute_boru_shock_momentum(850.0, 14.0, true, true)
	_expect(shock_momentum > 10.0, "Börü heavy-lance charge computes Steel + Meteoric Iron shock momentum.")

	EventBus.quiver_ammo_depleted.disconnect(_on_quiver_depleted)
	EventBus.feigned_retreat_lured.disconnect(_on_feigned_retreat_lured)
	EventBus.formation_entropy_critical.disconnect(_on_entropy_critical)
	EventBus.crescent_trap_sprung.disconnect(_on_crescent_trap_sprung)
	tactics.free()


func _test_phase3_vectorial_combat_and_seven_ores() -> void:
	var steppe: TerrainData = ResourceLoader.load("res://data/terrain/steppe.tres") as TerrainData
	var mountain: TerrainData = ResourceLoader.load("res://data/terrain/mountain.tres") as TerrainData

	# 1. Vectorial dot-product Front (1.0x) vs Flank (1.45x) vs Rear (2.1x)
	var atk_front: CombatantStats = CombatantStats.new(10, 220.0, 120.0, 1000.0, 1.0)
	atk_front.attack_vector = Vector3.BACK
	var def_front: CombatantStats = CombatantStats.new(11, 140.0, 120.0, 1000.0, 1.0)
	def_front.facing_vector = Vector3.FORWARD

	var atk_flank: CombatantStats = CombatantStats.new(10, 220.0, 120.0, 1000.0, 1.0)
	atk_flank.attack_vector = Vector3.RIGHT
	var def_flank: CombatantStats = CombatantStats.new(12, 140.0, 120.0, 1000.0, 1.0)
	def_flank.facing_vector = Vector3.FORWARD

	var atk_rear: CombatantStats = CombatantStats.new(10, 220.0, 120.0, 1000.0, 1.0)
	atk_rear.attack_vector = Vector3.FORWARD
	var def_rear: CombatantStats = CombatantStats.new(13, 140.0, 120.0, 1000.0, 1.0)
	def_rear.facing_vector = Vector3.FORWARD

	var cmd_front: ResolveCombatCommand = ResolveCombatCommand.new(atk_front, def_front, steppe, 77)
	var cmd_flank: ResolveCombatCommand = ResolveCombatCommand.new(atk_flank, def_flank, steppe, 77)
	var cmd_rear: ResolveCombatCommand = ResolveCombatCommand.new(atk_rear, def_rear, steppe, 77)
	CommandBus.dispatch(cmd_front)
	CommandBus.dispatch(cmd_flank)
	CommandBus.dispatch(cmd_rear)

	_expect(is_equal_approx(cmd_front.result.directional_damage_multiplier, 1.0), "Frontal dot-product yields 1.0x multiplier.")
	_expect(is_equal_approx(cmd_flank.result.directional_damage_multiplier, 1.45), "Flank dot-product yields 1.45x multiplier.")
	_expect(is_equal_approx(cmd_rear.result.directional_damage_multiplier, 2.1), "Rear dot-product yields 2.1x multiplier.")
	_expect(cmd_flank.result.cohesion_damage_to_defender > cmd_front.result.cohesion_damage_to_defender * 2.5,
		"Flank strike inflicts 1.45x physical * 2.0x cohesion destruction.")
	_expect(cmd_rear.result.morale_damage_to_defender > cmd_flank.result.morale_damage_to_defender + 20.0,
		"Rear strike inflicts instant panic morale drop.")

	# 2. Sulfur Fire & Smoke Trap in Damarlı Yamaç choke point
	var enemy_cavalry: CombatantStats = CombatantStats.new(20, 180.0, 140.0, 900.0, 1.0)
	var trap_cmd: SulfurFireTrapCommand = SulfurFireTrapCommand.new(1, enemy_cavalry, mountain)
	_expect(CommandBus.dispatch(trap_cmd), "SulfurFireTrapCommand consumes Sulfur and detonates.")
	_expect(trap_cmd.area_damage_dealt > 140.0 and trap_cmd.cohesion_drop_dealt > 30.0,
		"Sulfur trap deals amplified chokepoint area damage and spooks enemy cavalry.")

	# 3. Steel + Meteoric Iron + Sealed Crescent Encirclement -> Rout & Annihilation into Toy loot pool
	var boru_attacker: CombatantStats = CombatantStats.new(30, 320.0, 160.0, 1200.0, 1.0)
	boru_attacker.attack_vector = Vector3.FORWARD
	boru_attacker.has_steel_weapons = true
	boru_attacker.has_meteoric_iron_weapon = true
	boru_attacker.charge_mass_momentum = 2.0

	var encircled_defender: CombatantStats = CombatantStats.new(31, 140.0, 120.0, 600.0, 0.5)
	encircled_defender.facing_vector = Vector3.FORWARD
	encircled_defender.cohesion = 35.0
	encircled_defender.morale = 40.0
	encircled_defender.armor_collapse_ratio = 0.45
	encircled_defender.is_escape_vector_sealed = true

	var loot_before: float = CombatCalculator.get_pending_toy_loot_pool()
	var annihilate_cmd: ResolveCombatCommand = ResolveCombatCommand.new(boru_attacker, encircled_defender, steppe, 99)
	_expect(CommandBus.dispatch(annihilate_cmd), "Börü shock combat resolution succeeds.")
	_expect(annihilate_cmd.result.defender_routed and annihilate_cmd.result.defender_annihilated_in_crescent,
		"Encircled defender with broken cohesion routs and is annihilated inside Crescent Trap.")
	_expect(annihilate_cmd.result.captured_toy_loot_value > 0.0 and CombatCalculator.get_pending_toy_loot_pool() > loot_before,
		"Annihilated enemy's weapons and horses are transferred to the Toy loot pool.")


func _test_phase3_yilki_logistics_and_zud_sacrifice() -> void:
	_supply_severed_signal_received = false
	_yilki_sacrificed_signal_received = false
	EventBus.supply_line_severed.connect(_on_supply_line_severed)
	EventBus.yilki_horses_sacrificed_for_ration.connect(_on_yilki_sacrificed)

	var army_packed: PackedScene = ResourceLoader.load("res://units/army.tscn") as PackedScene
	var army: ArmyController = army_packed.instantiate() as ArmyController
	army.army_id = 77
	add_child(army)

	var speed_with_full_yilki: float = army.mobility.get_target_speed()
	_expect(army.supply.get_remount_horse_ratio() >= 1.0, "Army starts with full Yılkı spare horse ratio.")

	# Rogue warband ('Yersiz Yurtsuz Çeriler') interdicts the supply convoy
	var interdict_cmd: InterdictSupplyLineCommand = InterdictSupplyLineCommand.new(77, 1, &"kulan_bey")
	_expect(CommandBus.dispatch(interdict_cmd), "InterdictSupplyLineCommand succeeds.")
	_expect(_supply_severed_signal_received and army.supply.is_isolated(),
		"Severing supply line emits supply_line_severed and sets army status to ISOLATED.")
	_expect(CommandBus.get_raider_seized_loot(&"kulan_bey") >= 240.0,
		"Convoy rations and horses are seized by the rogue warband raider.")

	# Winter/Zud starvation (Food <= 0) forces isolated army to slaughter its Yılkı spare horses
	CommandBus.dispatch(ModifyKutCommand.new(60.0, &"restore_for_phase3_test"))
	var kut_before_sacrifice: float = GameManager.get_kut_score()
	var winter: SeasonData = ResourceLoader.load("res://data/seasons/winter.tres") as SeasonData
	SeasonManager.set_food_reserve(0)
	SeasonManager.evaluate_zud_starvation(winter)

	_expect(_yilki_sacrificed_signal_received, "Isolated army slaughters Yılkı horses during Zud starvation.")
	_expect(army.supply.get_remount_horse_ratio() < 1.0, "Yılkı spare horse ratio permanently reduced.")
	_expect(army.mobility.get_target_speed() < speed_with_full_yilki,
		"Slaughtering Yılkı spare horses permanently degrades army cavalry speed.")
	_expect(army.supply.get_battle_morale() < 100.0, "Eating own mounts collapses army battle morale.")
	_expect(GameManager.get_kut_score() < kut_before_sacrifice,
		"Yılkı horse sacrifice heavily drains the Khagan's Kut score.")

	# Exhausting remaining Yılkı horses drops army to dismounted infantry speed
	army.supply.consume_yilki_horses_for_ration()
	_expect(is_zero_approx(army.supply.get_remount_horse_ratio()), "Second Zud sacrifice exhausts all Yılkı spare horses.")
	var dismounted_mult: float = ArmyMobilityComponent.calculate_remount_speed_multiplier(0.0, army.template.mobility_profile)
	_expect(is_equal_approx(dismounted_mult, army.template.mobility_profile.dismounted_penalty),
		"Zero Yılkı horses applies dismounted_penalty (0.42x infantry speed).")

	EventBus.supply_line_severed.disconnect(_on_supply_line_severed)
	EventBus.yilki_horses_sacrificed_for_ration.disconnect(_on_yilki_sacrificed)
	army.free()


func _test_phase4_espionage_and_envoy_provocation() -> void:
	_espionage_signal_received = false
	_envoy_assassinated_signal_received = false
	_total_war_signal_received = false
	EventBus.espionage_mission_completed.connect(_on_espionage_completed)
	EventBus.envoy_assassinated.connect(_on_envoy_assassinated)
	EventBus.total_war_declared.connect(_on_total_war_declared)

	var rules: DiplomacyRules = ResourceLoader.load("res://data/diplomacy/diplomacy_rules.tres") as DiplomacyRules
	_expect(rules != null and rules.get_validation_errors().is_empty(), "DiplomacyRules loaded and valid.")

	var steppe: TerrainData = ResourceLoader.load("res://data/terrain/steppe.tres") as TerrainData
	var forest: TerrainData = ResourceLoader.load("res://data/terrain/forest.tres") as TerrainData
	var chance_open: float = IntelligenceManager.evaluate_espionage_chance(75.0, steppe, 0.05)
	var chance_forest: float = IntelligenceManager.evaluate_espionage_chance(75.0, forest, 0.05)
	var chance_novice: float = IntelligenceManager.evaluate_espionage_chance(20.0, steppe, 0.05)
	_expect(chance_open > chance_novice, "Commander leadership directly increases espionage success probability.")
	_expect(chance_forest > chance_open, "SIK_ORMAN (Dense Forest) stealth multiplier amplifies spy infiltration chance.")

	var espionage_comp: EspionageComponent = EspionageComponent.new()
	espionage_comp.rules = rules
	espionage_comp.commander_leadership = 95.0
	add_child(espionage_comp)

	var report: EspionageReport = espionage_comp.infiltrate_target_army(
		1,
		2,
		501,
		forest,
		84.0,
		GameEnums.TuranTacticPhase.CRESCENT_ENCIRCLEMENT_TRAP,
		GameEnums.TacticalDoctrineType.CRESCENT_ENCIRCLEMENT,
		0.0,
		1)
	_expect(_espionage_signal_received and report != null and report.succeeded,
		"Infiltration through SIK_ORMAN with high leadership succeeds and emits espionage_mission_completed.")
	_expect(is_equal_approx(report.revealed_quiver_ammo, 84.0),
		"Successful espionage reveals enemy's hidden quiver ammunition reserve (quiver_ammo).")
	_expect(report.revealed_tactic_intent == GameEnums.TuranTacticPhase.CRESCENT_ENCIRCLEMENT_TRAP,
		"Successful espionage reveals enemy's planned Turan tactic phase intent.")
	_expect(IntelligenceManager.get_latest_report_for_army(501) == report,
		"IntelligenceManager caches latest intelligence report for target army.")

	# Envoy Assassination & Provocation -> Instant Kut Gain + Total War (Büyük Yağma)
	CommandBus.dispatch(ModifyKutCommand.new(60.0 - GameManager.get_kut_score(), &"set_baseline_for_envoy_test"))
	var kut_before_envoy: float = GameManager.get_kut_score()
	_expect(not IntelligenceManager.is_total_war_active(1, 2), "Factions 1 and 2 start in TRUCE stance.")
	_expect(espionage_comp.assassinate_enemy_envoy(1, 2, &"juan_juan_elcisi"),
		"Assassinating rival dynasty's envoy succeeds.")
	_expect(_envoy_assassinated_signal_received and _total_war_signal_received,
		"Envoy execution emits EventBus.envoy_assassinated and EventBus.total_war_declared.")
	_expect(is_equal_approx(GameManager.get_kut_score(), kut_before_envoy + rules.envoy_assassination_kut_gain),
		"Executing enemy envoy grants an instant Kut surge (+15.0) to the Khagan.")
	_expect(IntelligenceManager.is_total_war_active(1, 2),
		"Envoy assassination triggers inevitable Total War (TOTAL_WAR_GREAT_RAID / Büyük Yağma).")

	EventBus.espionage_mission_completed.disconnect(_on_espionage_completed)
	EventBus.envoy_assassinated.disconnect(_on_envoy_assassinated)
	EventBus.total_war_declared.disconnect(_on_total_war_declared)
	espionage_comp.free()


func _test_phase4_psychological_warfare_and_cascade_rout() -> void:
	_cascade_rout_signal_received = false
	_enslaved_to_toy_signal_received = false
	EventBus.cascade_rout_triggered.connect(_on_cascade_rout_triggered)
	EventBus.routed_troops_enslaved_to_toy.connect(_on_routed_troops_enslaved)

	var rules: CombatRules = ResourceLoader.load("res://data/combat/combat_rules.tres") as CombatRules
	var steppe: TerrainData = ResourceLoader.load("res://data/terrain/steppe.tres") as TerrainData

	# 1. Battle Fatigue: progressive charge speed & lance impact momentum degradation
	var morale_comp: MoraleComponent = MoraleComponent.new()
	morale_comp.configure(401, rules)
	add_child(morale_comp)

	_expect(is_equal_approx(morale_comp.get_fatigue_speed_multiplier(), 1.0) \
		and is_equal_approx(morale_comp.get_fatigue_momentum_multiplier(), 1.0),
		"Fresh army has 1.0x charge speed and 1.0x lance impact momentum.")
	morale_comp.accumulate_battle_fatigue(20.0) # 20s * 2.5/s = 50.0 fatigue
	_expect(is_equal_approx(morale_comp.get_battle_fatigue(), 50.0),
		"20 seconds of combat accumulates 50.0 battle fatigue.")
	_expect(morale_comp.get_fatigue_speed_multiplier() < 1.0 \
		and is_equal_approx(morale_comp.get_fatigue_momentum_multiplier(), 0.75),
		"50 battle fatigue degrades charge speed and reduces lance impact momentum by 25%.")
	_expect(morale_comp.get_effective_charge_speed(16.0) < 16.0 \
		and morale_comp.get_effective_charge_momentum(2.0) < 2.0,
		"Effective charge speed and lance momentum scale down with accumulated fatigue.")

	var fresh_lancer: CombatantStats = CombatantStats.new(61, 200.0, 100.0, 800.0, 1.0)
	var tired_lancer: CombatantStats = CombatantStats.new(62, 200.0, 100.0, 800.0, 1.0)
	tired_lancer.combat_duration_sec = 30.0 # accumulates 75 fatigue in CombatCalculator
	var dummy_a: CombatantStats = CombatantStats.new(63, 100.0, 100.0, 800.0, 1.0)
	var dummy_b: CombatantStats = CombatantStats.new(64, 100.0, 100.0, 800.0, 1.0)

	var rng_a: RandomNumberGenerator = RandomNumberGenerator.new()
	rng_a.seed = 123
	var rng_b: RandomNumberGenerator = RandomNumberGenerator.new()
	rng_b.seed = 123
	var res_fresh: CombatResult = CombatCalculator.calculate(fresh_lancer, dummy_a, steppe, null, rng_a)
	var res_tired: CombatResult = CombatCalculator.calculate(tired_lancer, dummy_b, steppe, null, rng_b)
	_expect(res_tired.attacker_fatigue_momentum_multiplier < 1.0 \
		and res_tired.damage_to_defender < res_fresh.damage_to_defender,
		"Sustained battle fatigue reduces attacker's lance impact momentum and physical damage output.")

	# 2. Psychological Pressure & Cascade Rout (Bozkurt elite vanguard wiped out -> rear rookie panic -> 2.1x Rear strike & Toy enslavement)
	_expect(morale_comp.notify_elite_vanguard_destroyed(&"bozkurt_cavalry"),
		"Destroying front-line Bozkurt elite cavalry triggers cascade_rout in MoraleComponent.")
	_expect(morale_comp.is_cascade_routing() and morale_comp.get_current_morale() < 100.0,
		"Cascade rout collapses rear rookie morale and cohesion.")

	var pursuer: CombatantStats = CombatantStats.new(70, 220.0, 120.0, 900.0, 1.0)
	var panicking_defender: CombatantStats = CombatantStats.new(71, 130.0, 100.0, 500.0, 1.0)
	panicking_defender.elite_vanguard_destroyed = true
	panicking_defender.elite_vanguard_id = &"bozkurt_cavalry"
	panicking_defender.rookie_troop_ratio = 0.85

	var slaves_before: int = CombatCalculator.get_captured_slave_worker_pool()
	var toy_loot_before: float = CombatCalculator.get_pending_toy_loot_pool()
	var rout_cmd: ResolveCombatCommand = ResolveCombatCommand.new(pursuer, panicking_defender, steppe, 777)
	_expect(CommandBus.dispatch(rout_cmd), "ResolveCombatCommand on cascade-routing army succeeds.")
	_expect(_cascade_rout_signal_received and rout_cmd.result.cascade_rout_triggered,
		"Destruction of elite Bozkurt vanguard triggers cascade_rout during combat resolution.")
	_expect(rout_cmd.result.engagement_angle == GameEnums.CombatEngagementAngle.REAR \
		and is_equal_approx(rout_cmd.result.directional_damage_multiplier, 2.1),
		"Fleeing cascade_rout units turn their backs and suffer the 2.1x Rear strike multiplier.")
	_expect(_enslaved_to_toy_signal_received and rout_cmd.result.captured_slave_workers > 0,
		"Fleeing troops are captured as slave workers and transferred to the Toy economy.")
	_expect(CombatCalculator.get_captured_slave_worker_pool() > slaves_before \
		and CombatCalculator.get_pending_toy_loot_pool() > toy_loot_before,
		"Captured slave workers expand both the slave worker pool and the Toy loot pool.")

	EventBus.cascade_rout_triggered.disconnect(_on_cascade_rout_triggered)
	EventBus.routed_troops_enslaved_to_toy.disconnect(_on_routed_troops_enslaved)
	morale_comp.free()


func _test_phase4_zud_epidemic_and_kurgan_purification() -> void:
	_epidemic_outbreak_signal_received = false
	_epidemic_attrition_signal_received = false
	_epidemic_purified_signal_received = false
	EventBus.outbreak_epidemic_started.connect(_on_epidemic_outbreak_started)
	EventBus.epidemic_daily_attrition_ticked.connect(_on_epidemic_attrition_ticked)
	EventBus.epidemic_purified_at_kurgan.connect(_on_epidemic_purified)

	var army_packed: PackedScene = ResourceLoader.load("res://units/army.tscn") as PackedScene
	var army: ArmyController = army_packed.instantiate() as ArmyController
	army.army_id = 88
	add_child(army)

	var healthy_speed: float = army.mobility.get_target_speed()
	var winter: SeasonData = ResourceLoader.load("res://data/seasons/winter.tres") as SeasonData
	SeasonManager.set_food_reserve(0)

	var closed_camp_chance: float = SeasonManager.get_epidemic_outbreak_chance(true)
	var open_camp_chance: float = SeasonManager.get_epidemic_outbreak_chance(false)
	_expect(closed_camp_chance > open_camp_chance and is_equal_approx(closed_camp_chance, 0.90),
		"Closed camp during Zud starvation (Food <= 0) has a 90% Bozkır Vebası outbreak probability.")

	var outbreak: bool = SeasonManager.evaluate_zud_epidemic_outbreak(88, true, 1, winter)
	_expect(outbreak and _epidemic_outbreak_signal_received and SeasonManager.is_army_infected(88),
		"Zud starvation triggers outbreak_epidemic on army 88 and emits outbreak_epidemic_started.")
	_expect(is_equal_approx(army.mobility.get_epidemic_speed_multiplier(), 0.50) \
		and is_equal_approx(army.mobility.get_target_speed(), healthy_speed * 0.50),
		"Steppe plague halves the infected army's movement speed (0.50x).")

	var day1_remaining: int = SeasonManager.simulate_epidemic_day(88, 1000)
	var day2_remaining: int = SeasonManager.simulate_epidemic_day(88, day1_remaining)
	_expect(_epidemic_attrition_signal_received and day1_remaining == 920 and day2_remaining < day1_remaining,
		"Infected army loses 8% of its troops each day to the steppe plague.")

	# Shamanic purification ritual around Kurgan Shrine ('kurgan_shrine.tres') spends Kut to halt the epidemic
	CommandBus.dispatch(ModifyKutCommand.new(75.0 - GameManager.get_kut_score(), &"set_kut_for_kurgan_ritual"))
	var kut_before_ritual: float = GameManager.get_kut_score()
	var purify_cmd: PurifyEpidemicCommand = PurifyEpidemicCommand.new(88, &"kurgan_shrine")
	_expect(CommandBus.dispatch(purify_cmd) and purify_cmd.purified,
		"Kurgan Shrine purification ritual succeeds when Kut suffices.")
	_expect(_epidemic_purified_signal_received and not SeasonManager.is_army_infected(88) \
		and SeasonManager.get_army_epidemic_state(88) == GameEnums.EpidemicState.PURIFIED,
		"Purification ritual halts the epidemic and transitions army state to PURIFIED.")
	_expect(is_equal_approx(GameManager.get_kut_score(), kut_before_ritual - purify_cmd.kut_spent),
		"Kurgan purification ritual deducts the required Kut cost (12.0) from the Khagan.")
	_expect(is_equal_approx(army.mobility.get_target_speed(), healthy_speed),
		"Purifying the plague restores the army's full movement speed (1.0x).")

	EventBus.outbreak_epidemic_started.disconnect(_on_epidemic_outbreak_started)
	EventBus.epidemic_daily_attrition_ticked.disconnect(_on_epidemic_attrition_ticked)
	EventBus.epidemic_purified_at_kurgan.disconnect(_on_epidemic_purified)
	army.free()


func _test_phase5_dynasty_threat_matrix_and_coalition_war() -> void:
	_dynasty_stance_signal_received = false
	_coalition_war_signal_received = false
	EventBus.dynasty_stance_changed.connect(_on_dynasty_stance_changed)
	EventBus.coalition_war_declared.connect(_on_coalition_war_declared)

	var karluk: DynastyProfile = DiplomacyManager.get_dynasty_profile(&"karluk")
	var kipchak: DynastyProfile = DiplomacyManager.get_dynasty_profile(&"kipchak")
	var oghuz: DynastyProfile = DiplomacyManager.get_dynasty_profile(&"oghuz")
	_expect(karluk != null and kipchak != null and oghuz != null,
		"Karluk, Kıpçak, and Oğuz DynastyProfile resources loaded in DiplomacyManager.")

	# 1. Strong Khaganate (High Kut = 92, Strong Army = 1600, Zero Raids) -> Karluk becomes ALLY
	DiplomacyManager.set_dynasty_trust(&"karluk", 82.0)
	var karluk_stance_strong: GameEnums.DynastyAttitude = DiplomacyManager.calculate_dynasty_stance(&"karluk", 92.0, 1600.0, 0.0)
	_expect(karluk_stance_strong == GameEnums.DynastyAttitude.ALLY,
		"High Kut, strong army, and high trust yield ALLY (Müttefik) attitude from Karluk Beyliği.")

	# 2. High raid frequency and high ambition -> Kıpçak becomes THREATENING or HOSTILE
	var kipchak_stance_raids: GameEnums.DynastyAttitude = DiplomacyManager.calculate_dynasty_stance(&"kipchak", 55.0, 750.0, 5.0)
	_expect(_dynasty_stance_signal_received and (kipchak_stance_raids == GameEnums.DynastyAttitude.THREATENING \
		or kipchak_stance_raids == GameEnums.DynastyAttitude.HOSTILE),
		"High border raid frequency and Kıpçak ambition escalate stance to THREATENING/HOSTILE.")

	# 3. Kut drops below critical threshold (< 30) -> Coalition War triggered
	var eval_cmd: EvaluateDiplomacyCommand = EvaluateDiplomacyCommand.new(22.0, 600.0, 4.0)
	_expect(CommandBus.dispatch(eval_cmd) and eval_cmd.coalition_triggered,
		"EvaluateDiplomacyCommand triggers Coalition War when Kut < 30 and army is weakened.")
	_expect(_coalition_war_signal_received and DiplomacyManager.is_coalition_war_active() \
		and eval_cmd.coalition_members.size() >= 2,
		"Multiple rival dynasties unite in a Coalition War (coalition_war_declared) against a low-Kut Khaganate.")

	EventBus.dynasty_stance_changed.disconnect(_on_dynasty_stance_changed)
	EventBus.coalition_war_declared.disconnect(_on_coalition_war_declared)


func _test_phase5_ak_sakallilar_council_dilemmas() -> void:
	_council_decree_signal_received = false
	EventBus.council_decree_enacted.connect(_on_council_decree_enacted)

	var crisis: CouncilCrisisEvent = CouncilEventEngine.get_crisis_event()
	_expect(crisis != null and crisis.get_validation_errors().is_empty(),
		"CouncilCrisisEvent resource loaded and valid.")

	# Drop Kut below 30 to convene Ak Sakallılar Konseyi
	CommandBus.dispatch(ModifyKutCommand.new(20.0 - GameManager.get_kut_score(), &"trigger_phase5_council"))
	_expect(GameManager.is_ak_sakallilar_council_active() and CouncilEventEngine.is_crisis_dilemma_pending(),
		"Dropping Kut below 30 activates Ak Sakallılar Konseyi crisis dilemma.")

	# Dilemma 1: Töreye Bağlılık (TRADITION) -> +Kut, -Income (0.75x), -Army Speed (0.85x)
	var army_packed: PackedScene = ResourceLoader.load("res://units/army.tscn") as PackedScene
	var army: ArmyController = army_packed.instantiate() as ArmyController
	army.army_id = 91
	add_child(army)
	var base_speed: float = army.mobility.get_target_speed()
	var kut_before_tradition: float = GameManager.get_kut_score()

	var trad_cmd: EnactCouncilDecreeCommand = EnactCouncilDecreeCommand.new(1, GameEnums.CouncilDilemmaChoice.TRADITION)
	_expect(CommandBus.dispatch(trad_cmd) and _council_decree_signal_received,
		"Enacting Töreye Bağlılık (TRADITION) succeeds and emits council_decree_enacted.")
	_expect(GameManager.get_kut_score() > kut_before_tradition \
		and is_equal_approx(CouncilEventEngine.get_active_income_multiplier(), crisis.tradition_income_multiplier) \
		and is_equal_approx(army.mobility.get_target_speed(), base_speed * crisis.tradition_speed_multiplier),
		"Töreye Bağlılık boosts Kut while restricting economic income (0.75x) and army movement speed (0.85x).")

	# Dilemma 2: Yağma ve Sefer Serbestisi (EXPANSION) -> +Morale, +Loot (1.45x), -Dynasty Trust
	var oghuz_trust_before: float = DiplomacyManager.get_dynasty_trust(&"oghuz")
	var exp_cmd: EnactCouncilDecreeCommand = EnactCouncilDecreeCommand.new(1, GameEnums.CouncilDilemmaChoice.EXPANSION)
	_expect(CommandBus.dispatch(exp_cmd), "Enacting Yağma ve Sefer Serbestisi (EXPANSION) succeeds.")
	_expect(CouncilEventEngine.get_active_morale_bonus() >= 20.0 \
		and is_equal_approx(CouncilEventEngine.get_active_loot_multiplier(), crisis.expansion_loot_multiplier) \
		and DiplomacyManager.get_dynasty_trust(&"oghuz") < oghuz_trust_before,
		"Yağma ve Sefer Serbestisi boosts military morale and raid loot while collapsing neighboring dynasty trust.")

	# Dilemma 3: Hazine Fedakarlığı (SACRIFICE) -> Spend Steel + Silver/Gold treasury to buy popular loyalty & Kut
	CommandBus.dispatch(DepositResourcesCommand.new(1, &"steel", 10))
	CommandBus.dispatch(DepositResourcesCommand.new(1, &"silver_gold", 40))

	var steel_before: int = ResourceManager.get_amount(1, &"steel")
	var bullion_before: int = ResourceManager.get_amount(1, &"silver_gold")
	var kut_before_sac: float = GameManager.get_kut_score()

	var sac_cmd: EnactCouncilDecreeCommand = EnactCouncilDecreeCommand.new(1, GameEnums.CouncilDilemmaChoice.SACRIFICE)
	_expect(CommandBus.dispatch(sac_cmd), "Enacting Hazine Fedakarlığı (SACRIFICE) succeeds when treasury suffices.")
	_expect(ResourceManager.get_amount(1, &"steel") == steel_before - crisis.sacrifice_steel_cost \
		and ResourceManager.get_amount(1, &"silver_gold") == bullion_before - crisis.sacrifice_silver_gold_cost,
		"Hazine Fedakarlığı spends Steel and Silver/Gold from the player's treasury.")
	_expect(GameManager.get_kut_score() > kut_before_sac and CouncilEventEngine.get_popular_loyalty_bonus() >= 30.0,
		"Hazine Fedakarlığı purchases popular loyalty and restores Kut.")

	EventBus.council_decree_enacted.disconnect(_on_council_decree_enacted)
	army.free()


func _test_phase5_kagan_glory_and_warband_recruitment() -> void:
	_glory_changed_signal_received = false
	_warband_joined_by_glory_signal_received = false
	EventBus.kagan_glory_changed.connect(_on_kagan_glory_changed)
	EventBus.rogue_warband_joined_by_glory.connect(_on_warband_joined_by_glory)

	var rules: DiplomacyRules = ResourceLoader.load("res://data/diplomacy/diplomacy_rules.tres") as DiplomacyRules
	var glory_comp: GloryComponent = GloryComponent.new()
	glory_comp.configure(95, rules)
	add_child(glory_comp)

	# Create a rogue warband ('Yersiz Yurtsuz Çeriler') via unfair Toy distribution
	CommandBus.dispatch(DistributeToyLootCommand.new(&"bars_bey", 1000.0, 0.0, false))
	CommandBus.dispatch(DistributeToyLootCommand.new(&"bars_bey", 1000.0, 0.0, false))
	_expect(CommandBus.is_bey_rogue_warband(&"bars_bey"),
		"Bars Bey rebels into an independent Yersiz Yurtsuz Çeriler rogue warband.")
	_expect(not glory_comp.can_recruit_rogue_warband_freely() and glory_comp.recruit_rogue_warband(&"bars_bey") == 0,
		"Low-glory Khagan cannot recruit independent rogue warbands without hostages.")

	# Accumulate Glory via Turan Tactic, Feigned Retreat lure, and Envoy Assassination
	glory_comp.record_successful_turan_tactic()
	glory_comp.record_successful_feigned_retreat()
	glory_comp.record_envoy_assassination()
	_expect(_glory_changed_signal_received and glory_comp.get_glory_score() >= rules.free_warband_recruitment_glory_threshold,
		"Successful Turan tactics, Feigned Retreat lures, and Envoy Assassinations raise Khagan's glory_score above recruitment threshold (>= 40).")
	_expect(glory_comp.can_recruit_rogue_warband_freely(),
		"High glory unlocks hostage-free recruitment of roaming Yersiz Yurtsuz Çeriler warbands.")

	var joined_troops: int = glory_comp.recruit_rogue_warband(&"bars_bey")
	_expect(_warband_joined_by_glory_signal_received and joined_troops == rules.rogue_warband_troop_size,
		"High-glory Khagan recruits rogue warband directly into the army (+250 veteran riders) without hostages.")
	_expect(not CommandBus.is_bey_rogue_warband(&"bars_bey") and glory_comp.get_recruited_troops() == 250,
		"Recruited warband is reintegrated into the Khaganate's command structure.")

	EventBus.kagan_glory_changed.disconnect(_on_kagan_glory_changed)
	EventBus.rogue_warband_joined_by_glory.disconnect(_on_warband_joined_by_glory)
	glory_comp.free()


func _test_phase6_micro_building_placement_and_collision() -> void:
	_building_placed_signal_received = false
	EventBus.building_placed_on_micro_grid.connect(_on_building_placed_on_micro_grid)

	var steppe: TerrainData = ResourceLoader.load("res://data/terrain/steppe.tres") as TerrainData
	var zone: MicroZoneState = MicroZoneState.new(Vector2i(2, 2), Vector2i(16, 16), 1.0, Vector3.ZERO)
	for y: int in range(16):
		for x: int in range(16):
			var tile: MicroTile = MicroTile.new(Vector2i(x, y), 0.35, steppe)
			tile.is_settlement_clearing = true
			zone.set_tile(tile)
	BuildingPlacementManager.set_active_zone(zone)

	var ger: BuildingData = BuildingPlacementManager.get_building_data(&"ger_camp")
	var forge: BuildingData = BuildingPlacementManager.get_building_data(&"nomadic_forge")
	var quarry: BuildingData = BuildingPlacementManager.get_building_data(&"quarry")
	var kurgan: BuildingData = BuildingPlacementManager.get_building_data(&"kurgan_shrine")
	_expect(ger != null and forge != null and quarry != null and kurgan != null,
		"BuildingPlacementManager registers ger_camp, nomadic_forge, quarry, and kurgan_shrine.")

	CommandBus.dispatch(DepositResourcesCommand.new(1, &"stone", 500))
	CommandBus.dispatch(DepositResourcesCommand.new(1, &"iron", 120))
	CommandBus.dispatch(DepositResourcesCommand.new(1, &"jade", 40))
	var stone_before: int = ResourceManager.get_amount(1, &"stone")
	var iron_before: int = ResourceManager.get_amount(1, &"iron")
	var jade_before: int = ResourceManager.get_amount(1, &"jade")

	# 1. Place GerCamp (2x2 footprint) at (1, 1)
	var place_ger: PlaceBuildingCommand = PlaceBuildingCommand.new(1, ger, Vector2i(1, 1), zone)
	_expect(CommandBus.dispatch(place_ger) and _building_placed_signal_received,
		"PlaceBuildingCommand places ger_camp at grid (1, 1) and emits building_placed_on_micro_grid.")
	_expect(ResourceManager.get_amount(1, &"stone") == stone_before - 60,
		"GerCamp placement deducts 60 Stone construction cost from treasury.")

	# 2. Collision check: overlapping placement at (1, 1) or (2, 2) must be rejected
	_expect(not BuildingPlacementManager.can_place_at_grid(zone, forge, Vector2i(1, 1)),
		"can_place_at_grid blocks overlapping building placement at occupied origin (1, 1).")
	_expect(not BuildingPlacementManager.can_place_at_grid(zone, forge, Vector2i(2, 2)),
		"can_place_at_grid blocks partial footprint overlap at (2, 2).")
	var overlap_cmd: PlaceBuildingCommand = PlaceBuildingCommand.new(1, forge, Vector2i(2, 2), zone)
	_expect(not CommandBus.dispatch(overlap_cmd),
		"PlaceBuildingCommand rejects overlapping building placement without deducting resources.")

	# 3. Mouse world-click grid snapping for NomadicForge (2x3) near tile (4, 1)
	var place_forge: PlaceBuildingCommand = PlaceBuildingCommand.new(1, forge, Vector2i.ZERO, zone)
	place_forge.use_world_click = true
	place_forge.world_click_position = zone.tile_to_world(Vector2i(4, 1)) + Vector3(0.24, 0.0, -0.19)
	_expect(CommandBus.dispatch(place_forge) and place_forge.snapped_grid_coord == Vector2i(4, 1),
		"Mouse world-click position snaps accurately to micro grid (4, 1) for nomadic_forge.")

	# 4. Place Quarry (3x3) at (7, 1) and KurganShrine (3x3) at (11, 1)
	var place_quarry: PlaceBuildingCommand = PlaceBuildingCommand.new(1, quarry, Vector2i(7, 1), zone)
	var place_kurgan: PlaceBuildingCommand = PlaceBuildingCommand.new(1, kurgan, Vector2i(11, 1), zone)
	_expect(CommandBus.dispatch(place_quarry) and CommandBus.dispatch(place_kurgan),
		"Quarry and KurganShrine place cleanly on non-overlapping micro grid coordinates.")
	_expect(BuildingPlacementManager.get_placed_building_count() == 4,
		"All 4 buildings (ger_camp, nomadic_forge, quarry, kurgan_shrine) are active on the micro grid.")
	_expect(ResourceManager.get_amount(1, &"stone") == stone_before - 410 and ResourceManager.get_amount(1, &"iron") == iron_before - 70 and ResourceManager.get_amount(1, &"jade") == jade_before - 15,
		"Total construction costs (410 Stone, 70 Iron, 15 Jade) deducted accurately from treasury.")

	EventBus.building_placed_on_micro_grid.disconnect(_on_building_placed_on_micro_grid)


func _test_phase6_worker_gathering_caravan_pipeline() -> void:
	_worker_started_signal_received = false
	_worker_delivered_signal_received = false
	EventBus.worker_gathering_started.connect(_on_worker_gathering_started)
	EventBus.worker_caravan_delivered.connect(_on_worker_caravan_delivered)

	var steppe: TerrainData = ResourceLoader.load("res://data/terrain/steppe.tres") as TerrainData
	var forest: TerrainData = ResourceLoader.load("res://data/terrain/forest.tres") as TerrainData
	var stone_ore: OreData = ResourceLoader.load("res://data/ores/stone.tres") as OreData
	var iron_ore: OreData = ResourceLoader.load("res://data/ores/iron.tres") as OreData
	var coal_ore: OreData = ResourceLoader.load("res://data/ores/coal.tres") as OreData

	var zone: MicroZoneState = MicroZoneState.new(Vector2i(4, 4), Vector2i(16, 16), 1.0, Vector3.ZERO)
	for y: int in range(16):
		for x: int in range(16):
			zone.set_tile(MicroTile.new(Vector2i(x, y), 0.35, steppe))

	var stone_tile: MicroTile = zone.get_tile(Vector2i(3, 1))
	stone_tile.ore = stone_ore
	stone_tile.ore_amount = 50

	var iron_tile: MicroTile = zone.get_tile(Vector2i(1, 4))
	iron_tile.ore = iron_ore
	iron_tile.ore_amount = 45

	var coal_tile: MicroTile = zone.get_tile(Vector2i(4, 4))
	coal_tile.ore = coal_ore
	coal_tile.ore_amount = 40

	var forest_tile: MicroTile = MicroTile.new(Vector2i(2, 3), 0.40, forest)
	zone.set_tile(forest_tile)

	var ger_world_pos: Vector3 = zone.tile_to_world(Vector2i(1, 1))
	var worker: WorkerGatheringComponent = WorkerGatheringComponent.new()
	add_child(worker)
	worker.configure(101, 1, ger_world_pos)

	var iron_before: int = ResourceManager.get_amount(1, &"iron")
	_expect(worker.assign_nearest_gather_job(zone, &"iron") and _worker_started_signal_received,
		"Oymak İşçileri worker detachment locates nearest Iron vein at (1, 4) and begins marching.")
	_expect(worker.get_state() == GameEnums.WorkerGatherState.WALKING_TO_RESOURCE,
		"Worker enters WALKING_TO_RESOURCE state.")

	# March 3.0m at 4.0m/s -> 1.0s reaches the Iron vein and enters HARVESTING
	worker.tick_gathering(1.0)
	_expect(worker.get_state() == GameEnums.WorkerGatherState.HARVESTING,
		"Worker reaches Iron vein and enters HARVESTING state.")

	# Harvest for 2.0s -> extracts 20 Iron and transitions to HAULING_TO_GER_CAMP
	worker.tick_gathering(2.1)
	_expect(worker.get_state() == GameEnums.WorkerGatherState.HAULING_TO_GER_CAMP and worker.get_carried_amount() == 20 and iron_tile.ore_amount == 25,
		"Worker extracts 20 Iron from vein and transitions to physical caravan hauling.")

	# Haul 3.0m back to GerCamp at 3.0m/s -> deposits into GerCamp stockpile
	worker.tick_gathering(1.2)
	_expect(_worker_delivered_signal_received and worker.get_state() == GameEnums.WorkerGatherState.IDLE,
		"Caravan arrives at GerCamp, emits worker_caravan_delivered, and returns to IDLE.")
	_expect(ResourceManager.get_amount(1, &"iron") == iron_before + 20 and worker.get_total_delivered(&"iron") == 20,
		"Delivered Iron cargo (+20) is deposited into the player's GerCamp treasury.")

	# Gather Wood timber from Forest tile at (2, 3)
	_expect(worker.assign_nearest_gather_job(zone, &"wood"),
		"Oymak İşçileri locates nearest Forest timber zone for Wood gathering.")
	worker.tick_gathering(1.0)
	worker.tick_gathering(2.1)
	worker.tick_gathering(1.2)
	_expect(worker.get_total_delivered(&"wood") == 20,
		"Oymak İşçileri harvests and hauls 20 Wood from Forest tile to GerCamp.")

	EventBus.worker_gathering_started.disconnect(_on_worker_gathering_started)
	EventBus.worker_caravan_delivered.disconnect(_on_worker_caravan_delivered)
	worker.free()


func _test_phase6_ai_commander_and_raider_loop() -> void:
	_ai_phase_changed_signal_received = false
	_ai_raid_launched_signal_received = false
	EventBus.ai_commander_phase_changed.connect(_on_ai_commander_phase_changed)
	EventBus.ai_raid_launched.connect(_on_ai_raid_launched)

	var ai_profile: AIBehaviorProfile = AICommander.get_behavior_profile()
	_expect(ai_profile != null and ai_profile.get_validation_errors().is_empty(),
		"AICommander loaded AIBehaviorProfile (res://data/ai/ai_behavior_profile.tres) cleanly.")

	# 1. Rival dynasty Kıpçak (ambition = 0.85, discipline = 0.68):
	#    GATHER_RESOURCES -> UPGRADE_FORGE -> LAUNCH_RAID
	_expect(AICommander.get_agent_phase(&"kipchak") == GameEnums.AICommanderPhase.GATHER_RESOURCES,
		"Rival dynasty Kıpçak starts in GATHER_RESOURCES phase.")

	var step1: StepAICommanderCommand = StepAICommanderCommand.new(&"kipchak", false, 1, 1)
	_expect(CommandBus.dispatch(step1),
		"StepAICommanderCommand advances Kıpçak resource gathering.")
	_expect(_ai_phase_changed_signal_received and AICommander.get_agent_phase(&"kipchak") == GameEnums.AICommanderPhase.UPGRADE_FORGE,
		"Kıpçak transitions from GATHER_RESOURCES to UPGRADE_FORGE once forge threshold is met.")

	var step2: StepAICommanderCommand = StepAICommanderCommand.new(&"kipchak", false, 1, 1)
	_expect(CommandBus.dispatch(step2),
		"Kıpçak upgrades nomadic forge and reaches raid readiness threshold.")
	_expect(AICommander.is_agent_forge_upgraded(&"kipchak") and AICommander.get_agent_phase(&"kipchak") == GameEnums.AICommanderPhase.LAUNCH_RAID,
		"Kıpçak completes UPGRADE_FORGE and enters LAUNCH_RAID phase.")
	_expect(_ai_raid_launched_signal_received and step2.raid_launched,
		"Entering LAUNCH_RAID dispatches a Turan formation raid and emits ai_raid_launched.")
	_expect(step2.chosen_turan_phase == GameEnums.TuranTacticPhase.FEIGNED_RETREAT_LURE and step2.raid_target_type == &"ger_camp",
		"High-ambition Kıpçak (0.85, discipline 0.68) deterministically selects FEIGNED_RETREAT_LURE against player GerCamp.")

	# 2. High-discipline Karluk dynasty (ambition = 0.55, discipline = 0.78) selects CRESCENT_ENCIRCLEMENT_TRAP
	var karluk_cmd: StepAICommanderCommand = null
	for _i: int in range(5):
		karluk_cmd = StepAICommanderCommand.new(&"karluk", false, 1, 1)
		CommandBus.dispatch(karluk_cmd)
	_expect(karluk_cmd != null and karluk_cmd.raid_launched and karluk_cmd.chosen_turan_phase == GameEnums.TuranTacticPhase.CRESCENT_ENCIRCLEMENT_TRAP,
		"High-discipline Karluk (0.78) deterministically selects CRESCENT_ENCIRCLEMENT_TRAP formation.")

	# 3. Roaming rogue warband (Yersiz Yurtsuz Çeriler) raids player supply lines
	var rogue_cmd: StepAICommanderCommand = null
	for _i: int in range(4):
		rogue_cmd = StepAICommanderCommand.new(&"kulan_bey", true, 1, 1)
		CommandBus.dispatch(rogue_cmd)
	_expect(rogue_cmd != null and rogue_cmd.raid_launched and rogue_cmd.raid_target_type == &"supply_line",
		"Rogue warband progresses through AI loop and launches raid targeting player supply lines.")

	EventBus.ai_commander_phase_changed.disconnect(_on_ai_commander_phase_changed)
	EventBus.ai_raid_launched.disconnect(_on_ai_raid_launched)


func _test_phase7_pasture_ecology_and_sefer_arabasi_migration() -> void:
	_pasture_depleted_signal_received = false
	_camp_migrated_signal_received = false
	_overgrazing_rebellion_signal_received = false
	EventBus.pasture_depleted_starving_livestock.connect(_on_pasture_depleted)
	EventBus.camp_migrated_by_sefer_arabasi.connect(_on_camp_migrated)
	EventBus.overgrazing_rebellion_triggered.connect(_on_overgrazing_rebellion)

	var p_data: PastureData = PastureEcologyManager.get_pasture_data()
	_expect(p_data != null and p_data.get_validation_errors().is_empty(),
		"PastureEcologyManager loaded PastureData (res://data/world/pasture_data.tres) cleanly.")

	var region_a: Vector2i = Vector2i(2, 5)
	var region_b: Vector2i = Vector2i(3, 6)
	_expect(is_equal_approx(PastureEcologyManager.get_region_pasture_capacity(region_a), 100.0),
		"Fresh macro region starts at 100.0 pasture capacity.")

	# 1. Graze 700 Yılkı & sheep (700 * 0.08 = 56.0 depletion -> 44.0 remaining, still LUSH)
	var graze1: GrazePastureCommand = GrazePastureCommand.new(1, region_a, 700, 1.0)
	_expect(CommandBus.dispatch(graze1) and is_equal_approx(graze1.remaining_capacity, 44.0),
		"Grazing 700 livestock depletes pasture capacity by 56.0 according to pasture_depletion_rate (0.08).")
	_expect(not graze1.starving_livestock and is_equal_approx(graze1.meat_milk_production_multiplier, 1.0),
		"Meat and milk production remain at 100% while pasture is not depleted.")

	# 2. Overgraze to 0.0 -> starving_livestock, meat/milk stops (0.0), mandatory Sefer Arabası migration
	var graze2: GrazePastureCommand = GrazePastureCommand.new(1, region_a, 700, 1.0)
	_expect(CommandBus.dispatch(graze2) and is_zero_approx(graze2.remaining_capacity),
		"Sustained grazing exhausts regional pasture capacity to 0.0.")
	_expect(_pasture_depleted_signal_received and graze2.starving_livestock and graze2.migration_required,
		"Overgrazing triggers starving_livestock, halts meat/milk production (0.0), and requires Sefer Arabası migration.")
	_expect(is_zero_approx(PastureEcologyManager.get_meat_milk_production_multiplier(1)),
		"PastureEcologyManager reports 0.0 meat/milk production multiplier during livestock starvation.")

	# 3. Refusing to migrate triggers clan and army rebellion
	var kut_before: float = GameManager.get_kut_score()
	var graze3: GrazePastureCommand = GrazePastureCommand.new(1, region_a, 700, 1.0)
	_expect(CommandBus.dispatch(graze3) and graze3.rebellion_triggered and _overgrazing_rebellion_signal_received,
		"Remaining in a depleted pasture without migrating triggers clan and army rebellion.")
	_expect(GameManager.get_kut_score() < kut_before and PastureEcologyManager.is_overgrazing_rebellion_active(1),
		"Overgrazing rebellion drains Khagan's Kut score.")

	# 4. Relocating camp via Sefer Arabası to fresh waterside pasture restores production and ends rebellion
	var migrate_cmd: MigrateCampToPastureCommand = MigrateCampToPastureCommand.new(1, region_b)
	_expect(CommandBus.dispatch(migrate_cmd) and _camp_migrated_signal_received,
		"MigrateCampToPastureCommand relocates camp via Sefer Arabası to fresh waterside region (3, 6).")
	_expect(not PastureEcologyManager.is_livestock_starving(1) and not PastureEcologyManager.is_overgrazing_rebellion_active(1) and is_equal_approx(PastureEcologyManager.get_meat_milk_production_multiplier(1), 1.0),
		"Sefer Arabası migration clears starving_livestock, ends rebellion, and restores 100% meat/milk production.")

	EventBus.pasture_depleted_starving_livestock.disconnect(_on_pasture_depleted)
	EventBus.camp_migrated_by_sefer_arabasi.disconnect(_on_camp_migrated)
	EventBus.overgrazing_rebellion_triggered.disconnect(_on_overgrazing_rebellion)


func _test_phase7_vectorial_wind_and_atmospheric_ballistics() -> void:
	_wind_changed_signal_received = false
	_volley_resolved_signal_received = false
	EventBus.wind_weather_changed.connect(_on_wind_weather_changed)
	EventBus.atmospheric_volley_resolved.connect(_on_atmospheric_volley_resolved)

	var b_rules: BallisticsRules = BallisticsEngine.get_rules()
	_expect(b_rules != null and b_rules.get_validation_errors().is_empty(),
		"BallisticsEngine loaded BallisticsRules (res://data/combat/ballistics_rules.tres) cleanly.")

	# 1. Tailwind (Arkadan Esen Rüzgar): wind blowing North (0, 0, -8), archers shooting North (0, 0, -1)
	BallisticsEngine.set_steppe_wind_weather(Vector3(0.0, 0.0, -8.0), 16.0, false)
	_expect(_wind_changed_signal_received, "set_steppe_wind_weather emits wind_weather_changed.")

	var tailwind_cmd: EvaluateAtmosphericVolleyCommand = EvaluateAtmosphericVolleyCommand.new(1, Vector3(0.0, 0.0, -1.0), 12.0, 8.0)
	_expect(CommandBus.dispatch(tailwind_cmd) and _volley_resolved_signal_received,
		"EvaluateAtmosphericVolleyCommand resolves tailwind volley.")
	_expect(tailwind_cmd.result.weather_state == GameEnums.WindWeatherState.TAILWIND_BREEZE,
		"Aligned wind vector (dot = 1.0) classifies as TAILWIND_BREEZE.")
	_expect(is_equal_approx(tailwind_cmd.result.range_multiplier, 1.25) and is_equal_approx(tailwind_cmd.result.effective_range_m, 150.0),
		"Tailwind increases arrow range by +25% (120m -> 150m).")
	_expect(tailwind_cmd.result.accuracy_multiplier > 1.0,
		"Tailwind increases formation hit accuracy (1.20x).")

	# 2. Pre-Zud Headwind / Crosswind Gale Storm (Önden/Yandan Esen Şiddetli Fırtına):
	#    wind blowing South-East (12, 0, 12), temperature -12 C, archers shooting North (0, 0, -1)
	BallisticsEngine.set_steppe_wind_weather(Vector3(12.0, 0.0, 12.0), -12.0, true)
	var storm_cmd: EvaluateAtmosphericVolleyCommand = EvaluateAtmosphericVolleyCommand.new(1, Vector3(0.0, 0.0, -1.0), 12.0, 8.0)
	_expect(CommandBus.dispatch(storm_cmd) and storm_cmd.result.weather_state == GameEnums.WindWeatherState.PRE_ZUD_GALE_STORM,
		"Severe headwind/crosswind before Zud classifies as PRE_ZUD_GALE_STORM.")
	_expect(storm_cmd.result.range_multiplier < 1.0 and storm_cmd.result.accuracy_multiplier < 1.0,
		"Pre-Zud gale storm reduces bow range (0.70x) and accuracy (0.65x).")
	_expect(storm_cmd.effective_morale_shock < tailwind_cmd.effective_morale_shock and storm_cmd.effective_quiver_ammo_cost > tailwind_cmd.effective_quiver_ammo_cost,
		"Pre-Zud gale storm weakens whistling arrow morale shock (0.60x) and increases quiver ammo consumption (1.35x).")

	BallisticsEngine.set_steppe_wind_weather(Vector3(0.0, 0.0, -6.0), 14.0, false)
	EventBus.wind_weather_changed.disconnect(_on_wind_weather_changed)
	EventBus.atmospheric_volley_resolved.disconnect(_on_atmospheric_volley_resolved)


func _test_phase7_tore_captive_labor_and_revolt_risk() -> void:
	_noble_captives_signal_received = false
	_captive_labor_signal_received = false
	_slave_revolt_signal_received = false
	EventBus.noble_captives_ransomed_or_exchanged.connect(_on_noble_captives_processed)
	EventBus.captive_labor_assigned.connect(_on_captive_labor_assigned)
	EventBus.slave_revolt_triggered.connect(_on_slave_revolt_triggered)

	var c_rules: CaptiveLaborRules = CaptiveLaborManager.get_rules()
	_expect(c_rules != null and c_rules.get_validation_errors().is_empty(),
		"CaptiveLaborManager loaded CaptiveLaborRules (res://data/governance/captive_labor_rules.tres) cleanly.")

	# 1. Soylular ve Beyler: Ransom into Silver/Gold treasury & Envoy Exchange
	var bullion_before: int = ResourceManager.get_amount(2, &"silver_gold")
	var ransom_cmd: ProcessNobleCaptivesCommand = ProcessNobleCaptivesCommand.new(2, 3, ProcessNobleCaptivesCommand.MODE_RANSOM)
	_expect(CommandBus.dispatch(ransom_cmd) and _noble_captives_signal_received,
		"ProcessNobleCaptivesCommand ransoms 3 captured enemy nobles.")
	_expect(ransom_cmd.bullion_gained == 105 and ResourceManager.get_amount(2, &"silver_gold") == bullion_before + 105,
		"Ransoming 3 enemy nobles deposits +105 Silver/Gold bullion into treasury.")

	var exchange_cmd: ProcessNobleCaptivesCommand = ProcessNobleCaptivesCommand.new(2, 2, ProcessNobleCaptivesCommand.MODE_ENVOY_EXCHANGE)
	_expect(CommandBus.dispatch(exchange_cmd) and is_equal_approx(exchange_cmd.diplomatic_trust_gained, 24.0),
		"Exchanging 2 captured nobles for diplomatic envoys yields +24.0 trust credit.")

	# 2. Sıradan Askerler ve Esirler: 30% discount on Quarry & NomadicForge construction time & production costs
	var labor_safe_cmd: AssignCaptiveLaborCommand = AssignCaptiveLaborCommand.new(2, 30, 120)
	_expect(CommandBus.dispatch(labor_safe_cmd) and _captive_labor_signal_received,
		"AssignCaptiveLaborCommand assigns 30 captive workers to Quarry and NomadicForge.")
	_expect(is_equal_approx(labor_safe_cmd.discount_ratio, 0.30) and is_equal_approx(labor_safe_cmd.construction_time_multiplier, 0.70) and is_equal_approx(labor_safe_cmd.production_cost_multiplier, 0.70),
		"Full captive labor pool reduces construction_time and raw material production costs by 30% (0.70x multiplier).")
	_expect(is_zero_approx(labor_safe_cmd.slave_revolt_risk) and not labor_safe_cmd.revolt_triggered,
		"No slave revolt risk when captive workers (30) do not exceed core clan population (120).")

	# 3. Slave Revolt Risk when captive workers exceed core clan population (150 > 120)
	var labor_revolt_cmd: AssignCaptiveLaborCommand = AssignCaptiveLaborCommand.new(2, 120, 120)
	_expect(CommandBus.dispatch(labor_revolt_cmd) and labor_revolt_cmd.revolt_triggered and _slave_revolt_signal_received,
		"Exceeding core clan population (150 captives > 120 clan pop) triggers slave_revolt_risk and emits slave_revolt_triggered.")
	_expect(labor_revolt_cmd.slave_revolt_risk > 0.0 and CaptiveLaborManager.get_slave_revolt_risk(2) > 0.0,
		"CaptiveLaborManager computes positive slave_revolt_risk when captives outnumber clan population.")

	EventBus.noble_captives_ransomed_or_exchanged.disconnect(_on_noble_captives_processed)
	EventBus.captive_labor_assigned.disconnect(_on_captive_labor_assigned)
	EventBus.slave_revolt_triggered.disconnect(_on_slave_revolt_triggered)


func _test_phase8_dynamic_sovereignty_path_evolution() -> void:
	_sovereignty_evolved_signal_received = false
	EventBus.sovereignty_alignment_evolved.connect(_on_sovereignty_alignment_evolved)

	var s_profile: SovereigntyProfileData = SovereigntyPathEngine.get_profile()
	_expect(s_profile != null and s_profile.get_validation_errors().is_empty(),
		"SovereigntyPathEngine loaded SovereigntyProfileData (res://data/sovereignty/sovereignty_profile_data.tres) cleanly.")
	_expect(not SovereigntyPathEngine.is_any_path_locked(3),
		"Zero quest lock-in: no sovereignty path ever locks out alternative playstyles.")

	# 1. Start as Ulu Kağan & Töre Koruyucusu (high Kut = 90, Töre decrees)
	var ulu_cmd: EvaluateSovereigntyPathCommand = EvaluateSovereigntyPathCommand.new(3, 90.0, 20.0)
	ulu_cmd.reset_counters_before_apply = true
	ulu_cmd.add_tore_actions = 4
	_expect(CommandBus.dispatch(ulu_cmd) and ulu_cmd.active_alignment == GameEnums.SovereigntyAlignment.ULU_KAGAN_TORE_GUARDIAN,
		"High Kut and Töre council harmony align player with ULU_KAGAN_TORE_GUARDIAN.")

	# 2. Pivot freely to Bozkır Akıncısı & Yağma Beyi via raids, Toy distributions, and high glory
	var raider_cmd: EvaluateSovereigntyPathCommand = EvaluateSovereigntyPathCommand.new(3, 60.0, 88.0)
	raider_cmd.reset_counters_before_apply = true
	raider_cmd.add_raid_actions = 5
	raider_cmd.add_toy_actions = 3
	_expect(CommandBus.dispatch(raider_cmd) and _sovereignty_evolved_signal_received and raider_cmd.active_alignment == GameEnums.SovereigntyAlignment.STEPPE_RAIDER_WARLORD,
		"Frequent raids, Toy loot distribution, and high glory evolve alignment to STEPPE_RAIDER_WARLORD.")

	# 3. Pivot freely to Göçebe Tüccar & Demirci Hanedanı via 7-ore refining, tax/trade, and Sefer Arabası migrations
	var merchant_cmd: EvaluateSovereigntyPathCommand = EvaluateSovereigntyPathCommand.new(3, 65.0, 30.0)
	merchant_cmd.reset_counters_before_apply = true
	merchant_cmd.add_refining_actions = 6
	merchant_cmd.add_trade_actions = 4
	merchant_cmd.add_migration_actions = 3
	_expect(CommandBus.dispatch(merchant_cmd) and merchant_cmd.active_alignment == GameEnums.SovereigntyAlignment.NOMADIC_MERCHANT_FORGEMASTER,
		"7-ore refining, regional trade, and Sefer Arabası migrations evolve alignment to NOMADIC_MERCHANT_FORGEMASTER.")

	# 4. Pivot freely to Asi / Bağımsız Oymak via council defiance and low-Kut autonomy
	var rebel_cmd: EvaluateSovereigntyPathCommand = EvaluateSovereigntyPathCommand.new(3, 18.0, 20.0)
	rebel_cmd.reset_counters_before_apply = true
	rebel_cmd.add_defiance_actions = 6
	_expect(CommandBus.dispatch(rebel_cmd) and rebel_cmd.active_alignment == GameEnums.SovereigntyAlignment.REBEL_INDEPENDENT_CLAN,
		"Defying council authority and low-Kut autonomy evolve alignment to REBEL_INDEPENDENT_CLAN without locking future paths.")

	EventBus.sovereignty_alignment_evolved.disconnect(_on_sovereignty_alignment_evolved)


func _test_phase8_emergent_causality_and_inter_faction_wars() -> void:
	_emergent_chain_signal_received = false
	_inter_faction_conflict_signal_received = false
	_player_intervened_signal_received = false
	EventBus.emergent_causal_chain_triggered.connect(_on_emergent_chain_triggered)
	EventBus.inter_faction_conflict_erupted.connect(_on_inter_faction_conflict_erupted)
	EventBus.player_intervened_in_faction_conflict.connect(_on_player_intervened)

	var e_rules: EmergentWorldRules = EmergentWorldEngine.get_rules()
	_expect(e_rules != null and e_rules.get_validation_errors().is_empty(),
		"EmergentWorldEngine loaded EmergentWorldRules (res://data/world/emergent_world_rules.tres) cleanly.")

	# 1. Multi-variable causal chain: Overgrazed Pasture + Zud Winter + Severed Supply Line
	var chain_cmd: EvaluateEmergentWorldCommand = EvaluateEmergentWorldCommand.new(Vector2i(4, 2), true, true, true)
	chain_cmd.quiver_ammo = 4.0
	chain_cmd.hostile_neighbor_present = true
	chain_cmd.captured_slave_workers = 160
	chain_cmd.clan_population = 120
	chain_cmd.kut_score = 24.0
	_expect(CommandBus.dispatch(chain_cmd) and _emergent_chain_signal_received,
		"EvaluateEmergentWorldCommand triggers emergent causal chains from combined world variables.")
	_expect(chain_cmd.triggered_chain_ids.size() == 3 and chain_cmd.rogue_warband_split_triggered and chain_cmd.yilki_herd_attrition_ratio > 0.0,
		"Overgrazed pasture + Zud winter + severed supply line triggers Yılkı herd attrition and Yersiz Yurtsuz Çeriler split.")
	_expect(chain_cmd.available_responses.has("kurgan_purification_ritual") and chain_cmd.available_responses.has("migrate_to_fertile_basin") and chain_cmd.available_responses.has("raid_rival_supply_convoy"),
		"Emergent chain offers open-ended sandbox responses (Kurgan ritual, migration, or rival convoy raid) without forced quests.")

	# 2. Autonomous Inter-Faction Conflict between Kıpçak and Karluk:
	#    Option A: Neutral trade profiteering (+80 Silver/Gold)
	var bullion_before: int = ResourceManager.get_amount(1, &"silver_gold")
	var trade_intervene: InterveneFactionConflictCommand = InterveneFactionConflictCommand.new(
		1, &"kipchak", &"karluk", Vector2i(5, 3), &"fertile_pasture", GameEnums.EmergentInterventionStance.NEUTRAL_TRADE_PROFITEER)
	_expect(CommandBus.dispatch(trade_intervene) and _inter_faction_conflict_signal_received and _player_intervened_signal_received,
		"Neighboring dynasties (Kıpçak vs Karluk) wage autonomous pasture war; player can stay neutral and trade weapons/ores.")
	_expect(ResourceManager.get_amount(1, &"silver_gold") == bullion_before + 80,
		"Neutral war trade profiteering deposits +80 Silver/Gold into treasury.")

	#    Option B: Wait for mutual exhaustion (0.45) and strike both sides opportunistically
	var strike_both: InterveneFactionConflictCommand = InterveneFactionConflictCommand.new(
		1, &"oghuz", &"kipchak", Vector2i(6, 4), &"seven_ore_vein", GameEnums.EmergentInterventionStance.OPPORTUNISTIC_STRIKE_BOTH)
	_expect(CommandBus.dispatch(strike_both) and strike_both.mutual_exhaustion_ratio >= 0.45 and strike_both.reward_value_gained > 400.0,
		"Opportunistic double-strike after mutual faction exhaustion yields maximum Toy loot reward (420.0).")

	EventBus.emergent_causal_chain_triggered.disconnect(_on_emergent_chain_triggered)
	EventBus.inter_faction_conflict_erupted.disconnect(_on_inter_faction_conflict_erupted)
	EventBus.player_intervened_in_faction_conflict.disconnect(_on_player_intervened)


func _test_phase8_free_outpost_migration_and_modular_forces() -> void:
	_outpost_relocated_signal_received = false
	_force_detached_signal_received = false
	_forces_merged_signal_received = false
	EventBus.nomadic_outpost_relocated.connect(_on_nomadic_outpost_relocated)
	EventBus.force_detached_from_army.connect(_on_force_detached)
	EventBus.forces_merged_into_army.connect(_on_forces_merged)

	# 1. Free multi-region nomadic camp & forward forge relocation via Sefer Arabası
	var reloc_main: RelocateNomadicOutpostCommand = RelocateNomadicOutpostCommand.new(1, &"main_otag", Vector2i(3, 7))
	var reloc_forge: RelocateNomadicOutpostCommand = RelocateNomadicOutpostCommand.new(1, &"forward_steel_forge", Vector2i(6, 2))
	_expect(CommandBus.dispatch(reloc_main) and CommandBus.dispatch(reloc_forge) and _outpost_relocated_signal_received,
		"Player freely relocates main Otağ and deploys a forward steel forge across different macro regions.")
	_expect(CommandBus.get_nomadic_outpost_coord(&"main_otag") == Vector2i(3, 7) and CommandBus.get_nomadic_outpost_coord(&"forward_steel_forge") == Vector2i(6, 2) and CommandBus.get_nomadic_outpost_count() >= 2,
		"CommandBus tracks multiple simultaneous nomadic outposts across the steppe.")

	# 2. Modular Force Splitting & Merging via ModularForceComponent
	var mod_force: ModularForceComponent = ModularForceComponent.new()
	add_child(mod_force)
	mod_force.configure(50, 1000)

	var split_recon: SplitDetachForceCommand = mod_force.split_detachment(51, 250, GameEnums.DetachmentRole.FAST_CAVALRY_RECON_RAIDER)
	var split_escort: SplitDetachForceCommand = mod_force.split_detachment(52, 150, GameEnums.DetachmentRole.SUPPLY_ESCORT_GUARD)
	_expect(_force_detached_signal_received and split_recon.remaining_parent_riders == 750 and split_escort.remaining_parent_riders == 600,
		"Splitting 250 fast cavalry raiders and 150 supply escorts leaves 600 riders in the main vanguard army.")
	_expect(is_equal_approx(split_recon.speed_bonus_multiplier, 1.35) and mod_force.get_active_detachment_count() == 2,
		"Fast cavalry recon/raider detachment gains 1.35x speed multiplier.")

	var merge_recon: MergeForcesCommand = mod_force.merge_detachment(51)
	var merge_escort: MergeForcesCommand = mod_force.merge_detachment(52)
	_expect(_forces_merged_signal_received and merge_recon.merged_total_riders == 850 and merge_escort.merged_total_riders == 1000,
		"Merging detached forces back on the field restores the full 1000-rider army with exact conservation.")
	_expect(mod_force.get_active_detachment_count() == 0 and CommandBus.get_army_rider_count(50) == 1000,
		"All detachments re-merged cleanly into parent army 50.")

	EventBus.nomadic_outpost_relocated.disconnect(_on_nomadic_outpost_relocated)
	EventBus.force_detached_from_army.disconnect(_on_force_detached)
	EventBus.forces_merged_into_army.disconnect(_on_forces_merged)
	mod_force.free()


func _test_phase9_steppe_cataclysms_and_natural_destruction() -> void:
	_cataclysm_erupted_signal_received = false
	_cataclysm_subsided_signal_received = false
	EventBus.cataclysm_erupted.connect(_on_cataclysm_erupted)
	EventBus.cataclysm_subsided.connect(_on_cataclysm_subsided)

	# 1. Kara Zud ve Buz Kapanı (is_zud_winter = true, temp <= -15C, pasture_depleted = true)
	var zud_data: CataclysmEventData = CataclysmEngine.get_cataclysm_data(GameEnums.CataclysmType.KARA_ZUD_ICE_TRAP)
	_expect(zud_data != null and zud_data.get_validation_errors().is_empty(),
		"CataclysmEngine loaded Kara Zud ve Buz Kapanı (res://data/cataclysms/kara_zud_ice_trap.tres) cleanly.")
	var zud_cmd: EvaluateCataclysmCommand = EvaluateCataclysmCommand.new(Vector2i(2, 2), true, -24.0, true, 0.1, 6.0, 0.0)
	_expect(CommandBus.dispatch(zud_cmd) and _cataclysm_erupted_signal_received and zud_cmd.triggered_type == GameEnums.CataclysmType.KARA_ZUD_ICE_TRAP,
		"Harsh Zud winter (-24C) and depleted pasture trigger KARA_ZUD_ICE_TRAP cataclysm.")
	_expect(is_equal_approx(zud_cmd.pasture_yield_multiplier, 0.15) and is_equal_approx(zud_cmd.caravan_speed_multiplier, 0.35),
		"Kara Zud freezes pastures (0.15x yield) and slows/derails supply caravans (0.35x speed).")
	_expect(zud_cmd.open_response_options.size() >= 3 and CataclysmEngine.get_active_region_cataclysm(Vector2i(2, 2)) == zud_data,
		"Kara Zud offers multiple open-ended survival choices without linear quest lock-in.")

	# 2. Bozkır Yangını ve Kurak Rüzgar (drought >= 0.75, wind >= 10 m/s)
	var fire_cmd: EvaluateCataclysmCommand = EvaluateCataclysmCommand.new(Vector2i(4, 5), false, 34.0, false, 0.85, 14.5, 0.0)
	_expect(CommandBus.dispatch(fire_cmd) and fire_cmd.triggered_type == GameEnums.CataclysmType.STEPPE_WILDFIRE_SCORCH,
		"Severe drought (0.85) and gale steppe wind (14.5 m/s) trigger STEPPE_WILDFIRE_SCORCH.")
	_expect(is_equal_approx(fire_cmd.pasture_yield_multiplier, 0.10) and is_equal_approx(fire_cmd.forest_concealment_loss_ratio, 0.65),
		"Steppe wildfire scorches pastures (0.10x) and burns 65% of Sık Orman ambush concealment.")

	# 3. Büyük Göç Dalgası ve Yıkım Depremi / Sel Taşkını (river_slope_quake_hazard >= 0.75)
	var quake_cmd: EvaluateCataclysmCommand = EvaluateCataclysmCommand.new(Vector2i(7, 3), false, 16.0, false, 0.2, 5.0, 0.88)
	_expect(CommandBus.dispatch(quake_cmd) and quake_cmd.triggered_type == GameEnums.CataclysmType.GREAT_FLOOD_QUAKE_EXODUS,
		"High river/fault hazard (0.88) triggers GREAT_FLOOD_QUAKE_EXODUS.")
	_expect(is_equal_approx(quake_cmd.structural_wear_ratio, 0.45) and quake_cmd.refugee_influx_count == 180,
		"Great flood/quake inflicts 45% structural_wear on regional buildings and generates +180 refugee_influx.")

	CataclysmEngine.clear_region_cataclysm(Vector2i(2, 2))
	_expect(_cataclysm_subsided_signal_received and CataclysmEngine.get_active_region_cataclysm(Vector2i(2, 2)) == null,
		"clear_region_cataclysm removes active cataclysm and emits cataclysm_subsided.")

	EventBus.cataclysm_erupted.disconnect(_on_cataclysm_erupted)
	EventBus.cataclysm_subsided.disconnect(_on_cataclysm_subsided)


func _test_phase9_kinship_intrigue_and_internal_betrayal() -> void:
	_kinship_plot_signal_received = false
	_internal_betrayal_signal_received = false
	_kinship_resolved_signal_received = false
	EventBus.kinship_plot_escalated.connect(_on_kinship_plot_escalated)
	EventBus.internal_betrayal_triggered.connect(_on_internal_betrayal_triggered)
	EventBus.kinship_crisis_resolved.connect(_on_kinship_crisis_resolved)

	var k_rules: KinshipIntrigueRules = KinshipIntrigueManager.get_rules()
	_expect(k_rules != null and k_rules.get_validation_errors().is_empty(),
		"KinshipIntrigueManager loaded KinshipIntrigueRules (res://data/governance/kinship_intrigue_rules.tres) cleanly.")

	# 1. Unfair Toy/Ülüş share + low Kut escalates Bey into FACTION_PLOT_BREWING
	var plot_cmd: StepKinshipIntrigueCommand = StepKinshipIntrigueCommand.new(&"inel_tigin_bey", true, true, 65.0, 1)
	_expect(CommandBus.dispatch(plot_cmd) and _kinship_plot_signal_received and plot_cmd.resulting_stage == GameEnums.IntriguePlotStage.FACTION_PLOT_BREWING,
		"Unfair Toy/Ülüş distribution pushes Bey into secret FACTION_PLOT_BREWING (faction_plot).")

	# 2. Continued neglect escalates moderate-ambition Bey (65.0) to DEFECTION_OR_SABOTAGE (pulling 180 troops & sabotaging supply line)
	var defect_cmd: StepKinshipIntrigueCommand = StepKinshipIntrigueCommand.new(&"inel_tigin_bey", true, false, 65.0, 1)
	_expect(CommandBus.dispatch(defect_cmd) and _internal_betrayal_signal_received and defect_cmd.resulting_stage == GameEnums.IntriguePlotStage.DEFECTION_OR_SABOTAGE,
		"Repeated Toy neglect escalates faction plot to DEFECTION_OR_SABOTAGE.")
	_expect(defect_cmd.defected_troops == 180 and defect_cmd.supply_sabotaged,
		"Defecting Bey pulls 180 troops from the army and sabotages the supply line.")

	# 3. High-ambition surge (82.0 >= 75.0) + low-Kut crisis escalates Bey to full INTERNAL_UPRISING (360 troops)
	var uprising_cmd: StepKinshipIntrigueCommand = StepKinshipIntrigueCommand.new(&"inel_tigin_bey", true, true, 82.0, 1)
	_expect(CommandBus.dispatch(uprising_cmd) and uprising_cmd.resulting_stage == GameEnums.IntriguePlotStage.INTERNAL_UPRISING and uprising_cmd.defected_troops == 360,
		"High ambition and low-Kut crisis trigger INTERNAL_UPRISING with 360 rebel troops.")

	# 4. Player resolves intrigue via open-ended choices (Bestow Title & Ülüş vs Loyal Guard Suppression vs Kinship Negotiation)
	CommandBus.dispatch(DepositResourcesCommand.new(1, &"silver_gold", 200))
	var resolve_bestow: ResolveKinshipIntrigueCommand = ResolveKinshipIntrigueCommand.new(1, &"inel_tigin_bey", GameEnums.IntrigueResolutionAction.BESTOW_TITLE_AND_TOY_SHARE)
	_expect(CommandBus.dispatch(resolve_bestow) and _kinship_resolved_signal_received and resolve_bestow.resulting_stage == GameEnums.IntriguePlotStage.LOYAL_CALM,
		"Bestowing title and Toy share spends treasury bullion and restores Bey to LOYAL_CALM.")
	_expect(resolve_bestow.restored_loyalty >= 55.0 and KinshipIntrigueManager.get_lord_plot_stage(&"inel_tigin_bey") == GameEnums.IntriguePlotStage.LOYAL_CALM,
		"KinshipLordRecord loyalty is restored and active plot stage cleared.")

	EventBus.kinship_plot_escalated.disconnect(_on_kinship_plot_escalated)
	EventBus.internal_betrayal_triggered.disconnect(_on_internal_betrayal_triggered)
	EventBus.kinship_crisis_resolved.disconnect(_on_kinship_crisis_resolved)


func _test_phase9_wounded_pool_and_veteran_attrition() -> void:
	_battle_wounded_signal_received = false
	_wounded_recovered_signal_received = false
	_veteran_shock_signal_received = false
	EventBus.battle_wounded_recorded.connect(_on_battle_wounded_recorded)
	EventBus.wounded_troops_recovered.connect(_on_wounded_troops_recovered)
	EventBus.veteran_casualty_shock_applied.connect(_on_veteran_casualty_shock_applied)

	var casualty_comp: AttritionCasualtyComponent = AttritionCasualtyComponent.new()
	add_child(casualty_comp)
	casualty_comp.configure(77, 200, 0.80)
	_expect(casualty_comp.profile != null and casualty_comp.profile.get_validation_errors().is_empty(),
		"AttritionCasualtyComponent loaded default_attrition_casualty_profile.tres cleanly.")

	# 1. Battle casualties split into wounded_pool (45%) and immediate dead (55%), slowing army movement and eroding veteran core
	var report: Dictionary = casualty_comp.record_battle_casualties(60, 1.35, 0.22)
	_expect(_battle_wounded_signal_received and _veteran_shock_signal_received,
		"record_battle_casualties emits battle_wounded_recorded and veteran_casualty_shock_applied.")
	_expect(casualty_comp.get_wounded_pool() == 27 and casualty_comp.get_permanent_dead() == 33 and casualty_comp.get_active_troops() == 140,
		"60 fallen soldiers split into 27 wounded_pool survivors and 33 immediate dead, leaving 140 active troops.")
	_expect(casualty_comp.get_wounded_speed_multiplier() < 1.0 and casualty_comp.get_veteran_ratio() < 0.80 and casualty_comp.get_tactical_efficiency_multiplier() < 1.0,
		"Carrying wounded slows army movement, and losing veteran core + commander fatigue reduces tactical efficiency.")
	_expect(report.has("wounded_added"), "record_battle_casualties returns detailed casualty breakdown dictionary.")

	# 2. Field healer & camp supply treatment recovers wounded soldiers back to the ranks
	var heal_report: Dictionary = casualty_comp.tick_wounded_treatment(true)
	_expect(_wounded_recovered_signal_received and casualty_comp.get_active_troops() == 151 and casualty_comp.get_wounded_pool() == 16,
		"Healer/supply support recovers 11 wounded soldiers back into active troops (140 -> 151).")
	_expect(heal_report.has("recovered"), "tick_wounded_treatment returns treatment report.")

	# 3. Neglecting wounded without supply/healer turns wounded into permanent losses
	casualty_comp.tick_wounded_treatment(false)
	_expect(casualty_comp.get_wounded_pool() == 10 and casualty_comp.get_permanent_dead() == 39,
		"Without healer/supply support, 6 neglected wounded soldiers perish into permanent losses (33 -> 39).")

	# 4. Reinforcing with raw recruits dilutes veteran ratio and lowers cohesion cap until acclimated
	var vet_before_recruits: float = casualty_comp.get_veteran_ratio()
	casualty_comp.reinforce_with_raw_recruits(90)
	_expect(casualty_comp.get_active_troops() == 241 and casualty_comp.get_veteran_ratio() < vet_before_recruits and casualty_comp.get_effective_cohesion_cap() < 100.0,
		"Reinforcing with 90 raw recruits dilutes veteran ratio and lowers immediate cohesion cap (< 100.0).")
	var cap_before_drill: float = casualty_comp.get_effective_cohesion_cap()
	casualty_comp.tick_cohesion_acclimation(4.0)
	_expect(casualty_comp.get_effective_cohesion_cap() > cap_before_drill,
		"Field acclimation gradually restores cohesion cap and relieves commander fatigue.")

	EventBus.battle_wounded_recorded.disconnect(_on_battle_wounded_recorded)
	EventBus.wounded_troops_recovered.disconnect(_on_wounded_troops_recovered)
	EventBus.veteran_casualty_shock_applied.disconnect(_on_veteran_casualty_shock_applied)
	casualty_comp.free()


func _test_causal_friction_calibration_and_threshold_matrix() -> void:
	var calib: CausalFrictionCalibration = CausalChainEngine.get_calibration()
	_expect(calib != null and calib.get_validation_errors().is_empty(),
		"CausalChainEngine loaded CausalFrictionCalibration (res://data/world/causal_friction_calibration.tres) cleanly.")
	var parity_errors: PackedStringArray = CausalChainEngine.verify_calibration_parity()
	_expect(parity_errors.is_empty(),
		"CausalFrictionCalibration matches KutRules (Kut<30, epidemic 0.50x/8%/12 Kut), CombatRules (fatigue 2.5/s, 1.0x/1.45x/2.1x), and DiplomacyRules (glory>=40).")
	_expect(is_equal_approx(calib.critical_kut_council_threshold, 30.0) and is_equal_approx(calib.free_warband_glory_threshold, 40.0),
		"Calibrated governance/glory thresholds enforce Kut < 30.0 council crisis and glory_score >= 40.0 free warband recruitment.")
	_expect(is_equal_approx(calib.directional_front_multiplier, 1.0) and is_equal_approx(calib.directional_flank_multiplier, 1.45) and is_equal_approx(calib.directional_rear_multiplier, 2.1),
		"Calibrated directional encirclement matrix enforces 1.0x Front, 1.45x Flank, and 2.1x Rear strike multipliers.")

	# Verify direct Yılkı remount ratio -> Stage 4 Crescent Encirclement Trap wing damping on TuranTacticsComponent
	var doctrine: TacticalDoctrineData = ResourceLoader.load("res://data/tactics/crescent_encirclement.tres") as TacticalDoctrineData
	var forest: TerrainData = ResourceLoader.load("res://data/terrain/forest.tres") as TerrainData
	var tactics: TuranTacticsComponent = TuranTacticsComponent.new()
	add_child(tactics)
	tactics.configure(88, doctrine, 100.0)

	var left_wing: Vector3 = Vector3(-0.35, 0.0, 0.936).normalized()
	var right_wing: Vector3 = Vector3(0.35, 0.0, -0.936).normalized()
	_expect(not tactics.evaluate_crescent_trap_with_remount_ratio(left_wing, right_wing, 0.20, calib, forest),
		"Depleted Yılkı spare-horse ratio (0.20 < 0.55) damps wing encirclement speed/angle and causes Crescent Trap to fail.")
	_expect(tactics.evaluate_crescent_trap_with_remount_ratio(left_wing, right_wing, 1.0, calib, forest),
		"Healthy Yılkı spare-horse ratio (1.0 >= 0.55) reaches full pincer angle (>= PI*0.65) and seals the Crescent Trap.")
	tactics.free()


func _test_causal_chains_and_counterplay_recovery() -> void:
	_causal_step_propagated_signal_received = false
	_causal_counterplay_signal_received = false
	EventBus.causal_chain_step_propagated.connect(_on_causal_chain_step_propagated)
	EventBus.causal_chain_counterplay_applied.connect(_on_causal_chain_counterplay_applied)

	# 1. Chain 1: Ecological & Logistics Collapse (Pasture depletion -> Zud food zero -> Yılkı slaughter -> Crescent Trap failure -> Rogue warband split)
	var eco_collapse: ExecuteCausalChainCommand = ExecuteCausalChainCommand.new(
		GameEnums.CausalChainArchetype.ECOLOGICAL_LOGISTICS_COLLAPSE, GameEnums.CausalCounterplayAction.NONE, 1, 81)
	eco_collapse.bey_id = &"chain_eco_bey"
	_expect(CommandBus.dispatch(eco_collapse) and _causal_step_propagated_signal_received,
		"Ecological & Logistics Collapse causal chain propagates across PastureEcology, Yılkı logistics, TuranTactics, and Toy rebellion.")
	_expect(is_equal_approx(eco_collapse.resulting_remount_ratio, 0.20) and not eco_collapse.crescent_trap_succeeded and eco_collapse.rogue_warband_split,
		"Without counterplay, Yılkı sacrifice drops remount ratio to 0.20, failing Crescent Trap and splitting Yersiz Yurtsuz Çeriler.")

	#    Chain 1 Counterplay: Timely Sefer Arabası migration preserves Yılkı mobility and succeeds in Crescent Trap
	var eco_counter: ExecuteCausalChainCommand = ExecuteCausalChainCommand.new(
		GameEnums.CausalChainArchetype.ECOLOGICAL_LOGISTICS_COLLAPSE, GameEnums.CausalCounterplayAction.MIGRATE_SEFER_ARABASI_OR_RESUPPLY, 1, 81)
	_expect(CommandBus.dispatch(eco_counter) and _causal_counterplay_signal_received and eco_counter.counterplay_broke_chain and eco_counter.crescent_trap_succeeded,
		"Sefer Arabası migration counterplay preserves Yılkı remount ratio (1.0) and allows Crescent Trap to succeed.")

	# 2. Chain 2: Combat Fatigue & Psychological Cascade Rout (Prolonged battle -> fatigue momentum decay -> elite vanguard loss -> cascade_rout -> 2.1x rear strike & Toy prisoner capture -> Kut erosion)
	var combat_collapse: ExecuteCausalChainCommand = ExecuteCausalChainCommand.new(
		GameEnums.CausalChainArchetype.COMBAT_FATIGUE_PSYCHOLOGICAL_ROUT, GameEnums.CausalCounterplayAction.NONE, 1, 82)
	combat_collapse.combat_duration_sec = 28.0
	_expect(CommandBus.dispatch(combat_collapse) and combat_collapse.accumulated_battle_fatigue >= 70.0 and combat_collapse.fatigue_momentum_multiplier < 1.0,
		"28s of prolonged combat accumulates 70.0 battle_fatigue and decays lance momentum.")
	_expect(combat_collapse.cascade_rout_triggered and is_equal_approx(combat_collapse.rear_strike_damage_multiplier, 2.1) and combat_collapse.captured_toy_loot_value > 0.0,
		"Elite vanguard loss triggers cascade_rout, 2.1x vectorial rear strike, and Toy prisoner/loot capture.")

	#    Chain 2 Counterplay: Reserve rotation / tactical withdrawal resets fatigue and prevents cascade_rout
	var combat_counter: ExecuteCausalChainCommand = ExecuteCausalChainCommand.new(
		GameEnums.CausalChainArchetype.COMBAT_FATIGUE_PSYCHOLOGICAL_ROUT, GameEnums.CausalCounterplayAction.ROTATE_RESERVE_OR_TACTICAL_WITHDRAW, 1, 82)
	_expect(CommandBus.dispatch(combat_counter) and combat_counter.counterplay_broke_chain and not combat_counter.cascade_rout_triggered,
		"Reserve rotation counterplay resets battle fatigue and prevents cascade_rout.")

	# 3. Chain 3: Political, Espionage & Coalition Chain (Low Kut/unfair Toy -> rogue warband & coalition war -> reversed by Glory >= 40 & Sık Orman espionage)
	var pol_collapse: ExecuteCausalChainCommand = ExecuteCausalChainCommand.new(
		GameEnums.CausalChainArchetype.POLITICAL_ESPIONAGE_COALITION, GameEnums.CausalCounterplayAction.NONE, 1, 83)
	pol_collapse.bey_id = &"chain_pol_bey"
	_expect(CommandBus.dispatch(pol_collapse) and pol_collapse.rogue_warband_split and pol_collapse.coalition_formed,
		"Low Kut (< 30.0) and unfair Toy share spawn rogue warband and trigger neighboring dynasty coalition war.")

	var pol_counter: ExecuteCausalChainCommand = ExecuteCausalChainCommand.new(
		GameEnums.CausalChainArchetype.POLITICAL_ESPIONAGE_COALITION, GameEnums.CausalCounterplayAction.ESPIONAGE_OR_GLORY_WARBAND_RECRUIT, 1, 83)
	pol_counter.bey_id = &"chain_pol_bey"
	pol_counter.glory_score = 52.0
	pol_counter.commander_leadership = 95.0
	_expect(CommandBus.dispatch(pol_counter) and pol_counter.counterplay_broke_chain and pol_counter.warband_reintegrated_by_glory and pol_counter.coalition_broken_by_espionage_or_glory,
		"High Khagan Glory (52.0 >= 40.0) freely reintegrates rogue warband and Sık Orman espionage breaks the coalition threat.")

	# 4. Chain 4: Epidemic & Kurgan Purification Chain (Zud + Food <= 0 -> outbreak_epidemic & 8% daily attrition -> halted by Kurgan purification at 12.0 Kut cost)
	var epi_collapse: ExecuteCausalChainCommand = ExecuteCausalChainCommand.new(
		GameEnums.CausalChainArchetype.EPIDEMIC_KURGAN_PURIFICATION, GameEnums.CausalCounterplayAction.NONE, 1, 84)
	epi_collapse.initial_troops = 200
	_expect(CommandBus.dispatch(epi_collapse) and epi_collapse.epidemic_active and epi_collapse.remaining_troops_after_epidemic == 184,
		"Zud starvation (Food <= 0) triggers outbreak_epidemic and inflicts 8% daily troop attrition (200 -> 184).")

	var epi_counter: ExecuteCausalChainCommand = ExecuteCausalChainCommand.new(
		GameEnums.CausalChainArchetype.EPIDEMIC_KURGAN_PURIFICATION, GameEnums.CausalCounterplayAction.KURGAN_PURIFICATION_RITUAL, 1, 84)
	epi_counter.initial_troops = 184
	_expect(CommandBus.dispatch(epi_counter) and epi_counter.counterplay_broke_chain and epi_counter.epidemic_purified and not epi_counter.epidemic_active,
		"Kurgan Shrine purification ritual spends 12.0 Kut and halts the Zud epidemic.")

	EventBus.causal_chain_step_propagated.disconnect(_on_causal_chain_step_propagated)
	EventBus.causal_chain_counterplay_applied.disconnect(_on_causal_chain_counterplay_applied)


func _test_main_scene_integration() -> void:
	var main_packed: PackedScene = ResourceLoader.load("res://scenes/main.tscn") as PackedScene
	var main_instance: Node = main_packed.instantiate()
	add_child(main_instance)
	var move_cmd: MoveArmyCommand = MoveArmyCommand.new(1, Vector3(4.0, 0.0, 4.0))
	_expect(CommandBus.dispatch(move_cmd), "MoveArmyCommand routed to VanguardArmy via ArmyRegistry.")
	main_instance.free()


func _on_ak_sakallilar_council_convened(_current_kut: float, _penalty: float, _skirmish: bool) -> void:
	_council_signal_received = true


func _on_bey_rebelled(_bey_id: StringName, _title: String, _satisfaction: float) -> void:
	_rogue_warband_signal_received = true


func _on_quiver_depleted(_army_id: int) -> void:
	_quiver_depleted_signal_received = true


func _on_feigned_retreat_lured(_army_id: int, _pursuer_id: int, _dist: float, _entropy: float, _collapse: float) -> void:
	_lured_signal_received = true


func _on_entropy_critical(_army_id: int, _entropy: float, _collapse: float) -> void:
	_entropy_critical_signal_received = true


func _on_crescent_trap_sprung(_army_id: int, _target_id: int, _angle: float, _sealed: bool) -> void:
	_crescent_trap_signal_received = true


func _on_supply_line_severed(_army_id: int, _depot_id: int, _raider_id: StringName, _loot: float) -> void:
	_supply_severed_signal_received = true


func _on_yilki_sacrificed(_army_id: int, _remount: float, _morale_drop: float, _kut_drop: float) -> void:
	_yilki_sacrificed_signal_received = true


func _on_espionage_completed(_report: EspionageReport) -> void:
	_espionage_signal_received = true


func _on_envoy_assassinated(_instigator: int, _target: int, _envoy: StringName, _kut: float) -> void:
	_envoy_assassinated_signal_received = true


func _on_total_war_declared(_instigator: int, _target: int, _stance: GameEnums.DiplomaticStance) -> void:
	_total_war_signal_received = true


func _on_cascade_rout_triggered(_army_id: int, _elite_id: StringName, _morale: float) -> void:
	_cascade_rout_signal_received = true


func _on_routed_troops_enslaved(_army_id: int, _slaves: int, _loot_val: float) -> void:
	_enslaved_to_toy_signal_received = true


func _on_epidemic_outbreak_started(_army_id: int, _speed_mult: float, _attrition: float) -> void:
	_epidemic_outbreak_signal_received = true


func _on_epidemic_attrition_ticked(_army_id: int, _remaining: int, _casualties: int) -> void:
	_epidemic_attrition_signal_received = true


func _on_epidemic_purified(_army_id: int, _shrine_id: StringName, _kut_spent: float) -> void:
	_epidemic_purified_signal_received = true


func _on_dynasty_stance_changed(_dynasty_id: StringName, _prev: GameEnums.DynastyAttitude, _next: GameEnums.DynastyAttitude, _trust: float) -> void:
	_dynasty_stance_signal_received = true


func _on_coalition_war_declared(_members: PackedStringArray, _kut: float) -> void:
	_coalition_war_signal_received = true


func _on_council_decree_enacted(_player_id: int, _choice: GameEnums.CouncilDilemmaChoice, _kut: float, _inc: float, _spd: float, _loot: float) -> void:
	_council_decree_signal_received = true


func _on_kagan_glory_changed(_army_id: int, _prev: float, _next: float, _reason: StringName) -> void:
	_glory_changed_signal_received = true


func _on_warband_joined_by_glory(_army_id: int, _bey_id: StringName, _troops: int, _glory: float) -> void:
	_warband_joined_by_glory_signal_received = true


func _on_building_placed_on_micro_grid(_inst_id: int, _player_id: int, _b_id: StringName, _z_id: StringName, _coord: Vector2i, _pos: Vector3) -> void:
	_building_placed_signal_received = true


func _on_worker_gathering_started(_w_id: int, _p_id: int, _res_id: StringName, _coord: Vector2i, _pos: Vector3) -> void:
	_worker_started_signal_received = true


func _on_worker_caravan_delivered(_w_id: int, _p_id: int, _res_id: StringName, _amt: int, _pos: Vector3) -> void:
	_worker_delivered_signal_received = true


func _on_ai_commander_phase_changed(_agent_id: StringName, _prev: GameEnums.AICommanderPhase, _next: GameEnums.AICommanderPhase) -> void:
	_ai_phase_changed_signal_received = true


func _on_ai_raid_launched(_agent_id: StringName, _rogue: bool, _target: StringName, _army_id: int, _phase: GameEnums.TuranTacticPhase, _amb: float, _disc: float) -> void:
	_ai_raid_launched_signal_received = true


func _on_pasture_depleted(_coord: Vector2i, _herd: int, _mig: bool) -> void:
	_pasture_depleted_signal_received = true


func _on_camp_migrated(_p_id: int, _from: Vector2i, _to: Vector2i, _cap: float) -> void:
	_camp_migrated_signal_received = true


func _on_overgrazing_rebellion(_p_id: int, _coord: Vector2i, _kut: float) -> void:
	_overgrazing_rebellion_signal_received = true


func _on_wind_weather_changed(_wind: Vector3, _temp: float, _state: GameEnums.WindWeatherState) -> void:
	_wind_changed_signal_received = true


func _on_atmospheric_volley_resolved(_s_id: int, _rng: float, _acc: float, _mor: float, _ammo: float) -> void:
	_volley_resolved_signal_received = true


func _on_noble_captives_processed(_p_id: int, _cnt: int, _mode: StringName, _bul: int, _tr: float) -> void:
	_noble_captives_signal_received = true


func _on_captive_labor_assigned(_p_id: int, _slaves: int, _pop: int, _t_disc: float, _c_disc: float) -> void:
	_captive_labor_signal_received = true


func _on_slave_revolt_triggered(_p_id: int, _slaves: int, _pop: int, _risk: float) -> void:
	_slave_revolt_signal_received = true


func _on_sovereignty_alignment_evolved(_p_id: int, _prev: GameEnums.SovereigntyAlignment, _next: GameEnums.SovereigntyAlignment, _score: float) -> void:
	_sovereignty_evolved_signal_received = true


func _on_emergent_chain_triggered(_c_id: StringName, _coord: Vector2i, _sev: float, _opts: PackedStringArray) -> void:
	_emergent_chain_signal_received = true


func _on_inter_faction_conflict_erupted(_att: StringName, _def: StringName, _coord: Vector2i, _drv: StringName) -> void:
	_inter_faction_conflict_signal_received = true


func _on_player_intervened(_p_id: int, _att: StringName, _def: StringName, _st: GameEnums.EmergentInterventionStance, _rew: float) -> void:
	_player_intervened_signal_received = true


func _on_nomadic_outpost_relocated(_p_id: int, _o_id: StringName, _from: Vector2i, _to: Vector2i) -> void:
	_outpost_relocated_signal_received = true


func _on_force_detached(_p_id: int, _d_id: int, _role: GameEnums.DetachmentRole, _riders: int, _spd: float) -> void:
	_force_detached_signal_received = true


func _on_forces_merged(_t_id: int, _d_id: int, _tot: int) -> void:
	_forces_merged_signal_received = true


func _on_cataclysm_erupted(_c_id: StringName, _c_type: GameEnums.CataclysmType, _coord: Vector2i, _p_mult: float, _c_mult: float, _wear: float, _ref: int) -> void:
	_cataclysm_erupted_signal_received = true


func _on_cataclysm_subsided(_c_id: StringName, _coord: Vector2i) -> void:
	_cataclysm_subsided_signal_received = true


func _on_kinship_plot_escalated(_b_id: StringName, _st: GameEnums.IntriguePlotStage, _loy: float, _amb: float, _grv: float) -> void:
	_kinship_plot_signal_received = true


func _on_internal_betrayal_triggered(_b_id: StringName, _st: GameEnums.IntriguePlotStage, _trp: int, _sab: bool, _kut: float) -> void:
	_internal_betrayal_signal_received = true


func _on_kinship_crisis_resolved(_b_id: StringName, _act: GameEnums.IntrigueResolutionAction, _loy: float) -> void:
	_kinship_resolved_signal_received = true


func _on_battle_wounded_recorded(_a_id: int, _new_w: int, _tot_w: int, _spd: float) -> void:
	_battle_wounded_signal_received = true


func _on_wounded_troops_recovered(_a_id: int, _rec: int, _rem_w: int) -> void:
	_wounded_recovered_signal_received = true


func _on_veteran_casualty_shock_applied(_a_id: int, _v_ratio: float, _tac: float, _coh: float) -> void:
	_veteran_shock_signal_received = true


func _on_causal_chain_step_propagated(_arch: GameEnums.CausalChainArchetype, _cnt: int, _steps: PackedStringArray, _brk: bool) -> void:
	_causal_step_propagated_signal_received = true


func _on_causal_chain_counterplay_applied(_arch: GameEnums.CausalChainArchetype, _cp: GameEnums.CausalCounterplayAction, _sum: StringName) -> void:
	_causal_counterplay_signal_received = true


func _on_causal_transition_recorded(record: CausalTransitionRecord) -> void:
	if record != null:
		_causal_transition_records.append(record)


func _test_phase11_continuous_accumulation_decay_and_telemetry() -> void:
	_causal_transition_records.clear()
	EventBus.causal_transition_recorded.connect(_on_causal_transition_recorded)
	CausalChainEngine.reset_continuous_state()

	# 1. Sustained steppe crisis ticks (depleted pasture, no migration, no supply, Zud winter, unfair Toy share)
	var tick_a: StepContinuousSimulationCommand = StepContinuousSimulationCommand.new(
		1, 110, 4.0, true, false, false, true, 0.20, false)
	_expect(CommandBus.dispatch(tick_a) and tick_a.ecological_pressure > 0.0 and tick_a.logistics_strain > 0.0,
		"Continuous simulation accumulates ecological pressure and logistics strain under pasture depletion & supply cutoff.")

	var tick_b: StepContinuousSimulationCommand = StepContinuousSimulationCommand.new(
		1, 110, 6.0, true, false, false, true, 0.20, false)
	_expect(CommandBus.dispatch(tick_b) \
		and tick_b.ecological_pressure > tick_a.ecological_pressure \
		and tick_b.logistics_strain > tick_a.logistics_strain \
		and tick_b.morale_panic_pressure > tick_a.morale_panic_pressure \
		and tick_b.political_fracture_pressure > tick_a.political_fracture_pressure,
		"Continuous ticks compound pressure monotonically across ecology -> logistics -> morale -> political fracture.")
	_expect(tick_b.effective_remount_ratio < 1.0 and tick_b.effective_maneuver_speed_mult < 1.0,
		"Continuous Yılkı spare-horse depletion reduces maneuver speed multiplier progressively.")
	_expect(_causal_transition_records.size() >= 6,
		"Type-safe CausalTransitionRecord telemetry payloads emitted via EventBus for continuous causal steps.")

	# 2. Active counterplay ticks: Sefer Arabası migration + intact supply + fair Toy + rest out of combat
	var recovery_cmd: StepContinuousSimulationCommand = StepContinuousSimulationCommand.new(
		1, 110, 8.0, false, true, true, false, 0.75, true)
	_expect(CommandBus.dispatch(recovery_cmd) \
		and recovery_cmd.ecological_pressure < tick_b.ecological_pressure \
		and recovery_cmd.logistics_strain < tick_b.logistics_strain \
		and recovery_cmd.morale_panic_pressure < tick_b.morale_panic_pressure \
		and recovery_cmd.effective_remount_ratio > tick_b.effective_remount_ratio,
		"Counterplay recovery ticks decay accumulated crisis pressures and restore Yılkı remount ratio.")

	var found_recovery_record: bool = false
	for rec: CausalTransitionRecord in _causal_transition_records:
		if rec.is_recovery and rec.cause_source != &"" and rec.effect_target != &"":
			found_recovery_record = true
			break
	_expect(found_recovery_record,
		"CausalTransitionRecord stream explicitly logs recovery transitions with non-empty source and target tags.")

	EventBus.causal_transition_recorded.disconnect(_on_causal_transition_recorded)


func _test_phase11_turan_maneuver_readiness_and_layered_morale() -> void:
	var steppe: TerrainData = ResourceLoader.load("res://data/terrain/steppe.tres") as TerrainData
	var forest: TerrainData = ResourceLoader.load("res://data/terrain/forest.tres") as TerrainData
	var doctrine: TacticalDoctrineData = ResourceLoader.load("res://data/tactics/feigned_retreat.tres") as TacticalDoctrineData
	var combat_rules: CombatRules = ResourceLoader.load("res://data/combat/combat_rules.tres") as CombatRules

	# 1. TuranTacticsComponent maneuver readiness tied to fatigue, quiver_ammo, remount_horse_ratio & terrain
	var tactics: TuranTacticsComponent = TuranTacticsComponent.new()
	add_child(tactics)
	tactics.configure(112, doctrine)

	tactics.set_readiness_state(0.0, 90.0, 1.0)
	var fresh_eff: float = tactics.compute_maneuver_execution_efficiency(steppe)
	tactics.set_readiness_state(85.0, 0.0, 0.20)
	var exhausted_eff: float = tactics.compute_maneuver_execution_efficiency(forest)
	_expect(fresh_eff >= 1.0 and exhausted_eff < 0.50 and exhausted_eff < fresh_eff,
		"Turan maneuver efficiency rises on fertile steppe and drops severely under fatigue, empty quiver, and low Yılkı remounts.")

	var tactics_tired: TuranTacticsComponent = TuranTacticsComponent.new()
	add_child(tactics_tired)
	tactics_tired.configure(115, doctrine)

	var enemy_fresh: CombatantStats = CombatantStats.new(301, 140.0, 100.0, 500.0, 1.0)
	var enemy_tired: CombatantStats = CombatantStats.new(302, 140.0, 100.0, 500.0, 1.0)
	tactics.set_readiness_state(0.0, 90.0, 1.0)
	var lure_fresh: Dictionary[StringName, float] = tactics.execute_feigned_retreat_with_readiness(0.90, 0.35, 80.0, steppe, enemy_fresh)
	tactics_tired.set_readiness_state(85.0, 0.0, 0.15)
	var lure_tired: Dictionary[StringName, float] = tactics_tired.execute_feigned_retreat_with_readiness(0.90, 0.35, 80.0, null, enemy_tired)
	_expect(lure_fresh[TuranTacticsComponent.KEY_ARMOR_COLLAPSE_RATIO] > lure_tired[TuranTacticsComponent.KEY_ARMOR_COLLAPSE_RATIO],
		"Exhausted, unmounted, ammo-starved troops induce less Feigned Retreat armor collapse than rested riders.")
	tactics_tired.free()

	tactics.set_readiness_state(85.0, 0.0, 0.20)
	var recovered_eff: float = tactics.rest_and_resupply_tactical_readiness(25.0, 80.0, 0.85, steppe)
	_expect(recovered_eff > exhausted_eff and recovered_eff >= 1.0,
		"Out-of-combat rest and resupply restore full Turan maneuver execution readiness.")

	# 2. CombatCalculator readiness scaling (quiver_ammo & remount_horse_ratio)
	var atk_ready: CombatantStats = CombatantStats.new(310, 200.0, 100.0, 800.0, 1.0)
	atk_ready.active_tactic_phase = GameEnums.TuranTacticPhase.WHISTLING_ARROW_HARASSMENT
	atk_ready.quiver_ammo_ratio = 1.0
	atk_ready.remount_horse_ratio = 1.0

	var atk_depleted: CombatantStats = CombatantStats.new(311, 200.0, 100.0, 800.0, 1.0)
	atk_depleted.active_tactic_phase = GameEnums.TuranTacticPhase.WHISTLING_ARROW_HARASSMENT
	atk_depleted.quiver_ammo_ratio = 0.0
	atk_depleted.remount_horse_ratio = 0.20

	_expect(CombatCalculator.compute_maneuver_readiness_multiplier(atk_depleted) < 0.60,
		"CombatCalculator reduces tactical readiness multiplier when quiver ammo and remount horses are depleted.")
	var def_a: CombatantStats = CombatantStats.new(312, 100.0, 100.0, 800.0, 1.0)
	var def_b: CombatantStats = CombatantStats.new(313, 100.0, 100.0, 800.0, 1.0)
	var rng1: RandomNumberGenerator = RandomNumberGenerator.new()
	rng1.seed = 42
	var rng2: RandomNumberGenerator = RandomNumberGenerator.new()
	rng2.seed = 42
	var r_ready: CombatResult = CombatCalculator.calculate(atk_ready, def_a, null, null, rng1)
	var r_depleted: CombatResult = CombatCalculator.calculate(atk_depleted, def_b, null, null, rng2)
	_expect(r_depleted.damage_to_defender < r_ready.damage_to_defender,
		"Depleted quiver ammo and Yılkı spare horses lower CombatCalculator damage output during whistling arrow phase.")

	# 3. Layered MoraleComponent vanguard shock damping & recovery
	var vet_morale: MoraleComponent = MoraleComponent.new()
	vet_morale.configure(113, combat_rules)
	add_child(vet_morale)
	vet_morale.configure_veteran_and_commander_profile(0.90, 95.0, 85.0, 80.0)
	var vet_shock: Dictionary[StringName, float] = vet_morale.evaluate_layered_vanguard_loss_shock(&"bozkurt_cavalry", 200.0)
	_expect(vet_morale.is_in_staggered_hold() and not vet_morale.is_cascade_routing() \
		and is_equal_approx(vet_shock[&"rear_strike_multiplier"], combat_rules.front_damage_multiplier) \
		and is_zero_approx(vet_shock[&"captured_slave_workers"]),
		"Veteran troops led by high-leadership commander hold in staggered_hold without cascade_rout or prisoner loss.")

	var rookie_morale: MoraleComponent = MoraleComponent.new()
	rookie_morale.configure(114, combat_rules)
	add_child(rookie_morale)
	rookie_morale.configure_veteran_and_commander_profile(0.10, 20.0, 50.0, 45.0)
	rookie_morale.accumulate_battle_fatigue(28.0)
	var rookie_shock: Dictionary[StringName, float] = rookie_morale.evaluate_layered_vanguard_loss_shock(&"bozkurt_cavalry", 200.0)
	_expect(rookie_morale.is_cascade_routing() and not rookie_morale.is_in_staggered_hold() \
		and is_equal_approx(rookie_shock[&"rear_strike_multiplier"], 2.1) \
		and rookie_shock[&"captured_slave_workers"] > 0.0,
		"Fatigued rookie formation breaks into cascade_rout (2.1x rear strike and Toy captive capture).")

	var fatigued_before: float = rookie_morale.get_battle_fatigue()
	rookie_morale.recover_fatigue_and_rally(10.0, 1.0)
	_expect(rookie_morale.get_battle_fatigue() < fatigued_before,
		"Supplied rest lowers battle fatigue and rallies unit morale/cohesion.")

	tactics.free()
	vet_morale.free()
	rookie_morale.free()


func _test_phase11_economy_logistics_contagion_and_political_synergy() -> void:
	# 1. 7-Ore Refining & Tax under Sefer Arabası migration & supply isolation
	CommandBus.dispatch(DepositResourcesCommand.new(3, &"iron", 20))
	CommandBus.dispatch(DepositResourcesCommand.new(3, &"coal", 20))
	CommandBus.dispatch(DepositResourcesCommand.new(3, &"jade", 10))
	CommandBus.dispatch(DepositResourcesCommand.new(3, &"meteoric_iron", 10))

	ResourceManager.set_camp_migration_and_supply_state(3, false, false)
	var settled_tax: int = ResourceManager.calculate_effective_regional_tax_with_logistics(3, 5, 2)
	var settled_smelt: int = ResourceManager.smelt_steel_with_logistics_constraints(3, 4)

	ResourceManager.set_camp_migration_and_supply_state(3, true, false)
	var migrating_tax: int = ResourceManager.calculate_effective_regional_tax_with_logistics(3, 5, 2)
	var migrating_smelt: int = ResourceManager.smelt_steel_with_logistics_constraints(3, 4)
	_expect(is_equal_approx(ResourceManager.get_effective_forge_throughput_multiplier(3), 0.35),
		"Migrating Sefer Arabası limits Nomadic Forge smelting throughput to 0.35x.")
	_expect(migrating_smelt == 1 and settled_smelt == 4 and migrating_tax < settled_tax,
		"Migrating camp yields fewer Steel batches (1 vs 4) and reduced regional Silver/Gold tax collection.")
	_expect(not ResourceManager.bind_meteoric_iron_with_logistics(3, &"totem_sky_altar", true),
		"Meteoric Iron Totem Ascension binding requires a settled hearth and is blocked during Sefer Arabası migration.")
	ResourceManager.set_camp_migration_and_supply_state(3, false, false)
	_expect(ResourceManager.bind_meteoric_iron_with_logistics(3, &"totem_sky_altar", true),
		"Once Sefer Arabası settles, Meteoric Iron Totem Ascension binding succeeds.")

	# 2. Zud Contagion, Emergency Food Rations & Escalating Kurgan Kut Cost
	var winter: SeasonData = ResourceLoader.load("res://data/seasons/winter.tres") as SeasonData
	SeasonManager.set_food_reserve(0)
	_expect(SeasonManager.evaluate_zud_epidemic_outbreak(121, true, 1, winter),
		"Winter Zud starvation triggers outbreak_epidemic on army 121.")
	SeasonManager.set_food_reserve(60)
	var ration_metrics: Dictionary[StringName, float] = SeasonManager.evaluate_epidemic_contagion_and_ration_strain(121, 122, 25, 200)
	_expect(is_equal_approx(ration_metrics[&"food_consumed"], 25.0) \
		and ration_metrics[&"effective_attrition_ratio"] <= 0.045 \
		and not SeasonManager.is_army_infected(122),
		"Allocating >= 20 emergency food rations halves epidemic attrition and blocks contagion spread to nearby army 122.")

	var neglect_metrics: Dictionary[StringName, float] = SeasonManager.evaluate_epidemic_contagion_and_ration_strain(121, 122, 0, 192)
	_expect(SeasonManager.is_army_infected(122) \
		and is_equal_approx(neglect_metrics[&"nearby_infected"], 1.0) \
		and SeasonManager.get_effective_purification_kut_cost(121) > 12.0,
		"Withholding rations spreads Zud epidemic to nearby army 122 and escalates Kurgan purification Kut cost above 12.0.")

	CommandBus.dispatch(ModifyKutCommand.new(80.0 - GameManager.get_kut_score(), &"set_kut_for_escalated_kurgan"))
	var escalated_cost: float = SeasonManager.get_effective_purification_kut_cost(121)
	var purify_cmd: PurifyEpidemicCommand = PurifyEpidemicCommand.new(121, &"kurgan_shrine")
	_expect(CommandBus.dispatch(purify_cmd) and is_equal_approx(purify_cmd.kut_spent, escalated_cost),
		"PurifyEpidemicCommand charges the escalated Kurgan Kut cost (%.1f) and purifies army 121." % escalated_cost)

	# 3. Intelligence -> Diplomacy -> Council -> Glory Synergy
	DiplomacyManager.set_political_intelligence_context(0.0, 6.0, 18.0, 10.0)
	var crisis_ctx: Dictionary[StringName, float] = DiplomacyManager.evaluate_coalition_with_political_context(22.0, 650.0, 3.0)
	DiplomacyManager.set_political_intelligence_context(20.0, 0.0, 0.0, 78.0)
	var deterred_ctx: Dictionary[StringName, float] = DiplomacyManager.evaluate_coalition_with_political_context(22.0, 1000.0, 0.5)
	_expect(is_equal_approx(crisis_ctx[&"coalition_active"], 1.0) \
		and deterred_ctx[&"max_effective_threat"] < crisis_ctx[&"max_effective_threat"],
		"Combined Sık Orman espionage deterrence and high Khagan Glory sharply lower neighbor coalition threat even below Kut 30.")

	var raw_council: Dictionary[StringName, float] = CouncilEventEngine.evaluate_council_crisis_severity_with_context(20.0, true, false, 15.0)
	var mitigated_council: Dictionary[StringName, float] = CouncilEventEngine.evaluate_council_crisis_severity_with_context(20.0, false, true, 78.0)
	_expect(mitigated_council[&"severity_score"] < raw_council[&"severity_score"] \
		and mitigated_council[&"sacrifice_bullion_discount_ratio"] > 0.25,
		"Espionage forewarning and Khagan Glory mitigate Ak Sakallılar crisis severity and expand political concessions.")

	var rules: DiplomacyRules = ResourceLoader.load("res://data/diplomacy/diplomacy_rules.tres") as DiplomacyRules
	var glory_comp: GloryComponent = GloryComponent.new()
	add_child(glory_comp)
	glory_comp.configure(125, rules)

	var forest_p11: TerrainData = ResourceLoader.load("res://data/terrain/forest.tres") as TerrainData
	var det_before: float = DiplomacyManager.get_espionage_deterrence_bonus()
	var esp_adv_before: int = CouncilEventEngine.get_espionage_advantage_count()
	var live_spy: DispatchSpyCommand = DispatchSpyCommand.new(
		1, 2, 333, 95.0, forest_p11, 80.0, GameEnums.TuranTacticPhase.FEIGNED_RETREAT_LURE)
	_expect(CommandBus.dispatch(live_spy) and live_spy.report != null and live_spy.report.succeeded \
		and DiplomacyManager.get_espionage_deterrence_bonus() > det_before \
		and CouncilEventEngine.get_espionage_advantage_count() > esp_adv_before \
		and glory_comp.get_glory_score() >= 4.0,
		"Live espionage mission in Sık Orman synchronously boosts DiplomacyManager deterrence, CouncilEventEngine advantage, and Khagan Glory via EventBus.")

	var glory_before_decree: float = glory_comp.get_glory_score()
	var decree_exp: EnactCouncilDecreeCommand = EnactCouncilDecreeCommand.new(1, GameEnums.CouncilDilemmaChoice.EXPANSION)
	_expect(CommandBus.dispatch(decree_exp) and glory_comp.get_glory_score() > glory_before_decree,
		"EXPANSION council decree boosts Khagan Glory via EventBus alongside raids & loot.")

	glory_comp.record_successful_turan_tactic()
	glory_comp.record_successful_feigned_retreat()
	glory_comp.record_envoy_assassination()
	glory_comp.record_successful_turan_tactic()
	CommandBus.dispatch(DistributeToyLootCommand.new(&"phase11_scaled_bey", 500.0, 0.0, false))
	CommandBus.dispatch(DistributeToyLootCommand.new(&"phase11_scaled_bey", 500.0, 0.0, false))
	var scaled_recruited: int = glory_comp.recruit_rogue_warband_scaled_by_glory(&"phase11_scaled_bey")
	_expect(scaled_recruited > rules.rogue_warband_troop_size,
		"Surplus Khagan Glory (> 40) scales recruited Yersiz Yurtsuz Çeriler rider detachment above base 250 (%d riders)." % scaled_recruited)
	glory_comp.free()


func _test_phase12_long_horizon_ecology_seasons_and_supply_recovery() -> void:
	_p12_overgrazing_rebellion_count = 0
	_p12_supply_restored_count = 0
	EventBus.overgrazing_rebellion_triggered.connect(_on_p12_overgrazing_rebellion)
	EventBus.supply_line_restored.connect(_on_p12_supply_line_restored)

	# 1. Overgrazing rebellion idempotency & anti ping-pong pasture exploit
	if PastureEcologyManager.get_player_camp_region(1) != Vector2i(10, 10):
		CommandBus.dispatch(MigrateCampToPastureCommand.new(1, Vector2i(10, 10)))
	CommandBus.dispatch(ModifyKutCommand.new(75.0 - GameManager.get_kut_score(), &"p12_setup_kut_ecology"))
	var kut_before_overgraze: float = GameManager.get_kut_score()

	# First graze depletes (10, 10) completely to 0.0; next 5 ticks remain without migrating
	CommandBus.dispatch(GrazePastureCommand.new(1, Vector2i(10, 10), 1300, 1.0))
	for _tick: int in range(5):
		CommandBus.dispatch(GrazePastureCommand.new(1, Vector2i(10, 10), 1300, 1.0))
	var p_data: PastureData = PastureEcologyManager.get_pasture_data()
	_expect(_p12_overgrazing_rebellion_count == 1 \
		and is_equal_approx(GameManager.get_kut_score(), kut_before_overgraze - p_data.rebellion_kut_penalty),
		"Repeated overgrazing ticks without migration inflict rebellion Kut penalty (-14.0) only ONCE.")

	# Ping-pong migrate immediately back into exhausted (10, 10) must NOT conjure free grass
	_expect(CommandBus.dispatch(MigrateCampToPastureCommand.new(1, Vector2i(10, 11))),
		"Sefer Arabası migrates to fresh waterside region (10, 11) and lifts overgrazing starvation.")
	_expect(not PastureEcologyManager.is_livestock_starving(1) and is_equal_approx(PastureEcologyManager.get_meat_milk_production_multiplier(1), 1.0),
		"Fresh region (10, 11) immediately restores 100% meat/milk output.")
	CommandBus.dispatch(MigrateCampToPastureCommand.new(1, Vector2i(10, 10)))
	_expect(PastureEcologyManager.is_livestock_starving(1) and is_zero_approx(PastureEcologyManager.get_meat_milk_production_multiplier(1)),
		"Immediately migrating back into exhausted (10, 10) without seasonal rest preserves starvation (zero free ping-pong grass).")

	# 2. 12-Season (3-Year) Rotational Nomadism & Sustainable Food Balance
	CommandBus.dispatch(MigrateCampToPastureCommand.new(1, Vector2i(10, 11)))
	SeasonManager.set_food_reserve(100)
	var rotation_coords: Array[Vector2i] = [Vector2i(10, 11), Vector2i(10, 12), Vector2i(10, 13), Vector2i(10, 14)]
	for step_idx: int in range(12):
		var active_region: Vector2i = rotation_coords[step_idx % rotation_coords.size()]
		if PastureEcologyManager.get_player_camp_region(1) != active_region:
			CommandBus.dispatch(MigrateCampToPastureCommand.new(1, active_region))
		CommandBus.dispatch(GrazePastureCommand.new(1, active_region, 350, 1.0))
		SeasonManager.advance_season_cycle()

	var regen_cap_10_10: float = PastureEcologyManager.get_region_pasture_capacity(Vector2i(10, 10))
	_expect(regen_cap_10_10 >= 90.0,
		"Exhausted region (10, 10) rested for 3 years regenerates back to fertile capacity (%.1f >= 90.0)." % regen_cap_10_10)
	_expect(SeasonManager.get_food_reserve() > 100 and not PastureEcologyManager.is_livestock_starving(1),
		"3-year (12-season) rotational grazing sustains healthy pastures and achieves a net multi-year food surplus (%d > 100)." % SeasonManager.get_food_reserve())

	# 3. Supply Line Interdiction Anti-Loot-Farming & Auto Depot Recovery
	var army_packed: PackedScene = ResourceLoader.load("res://units/army.tscn") as PackedScene
	var army: ArmyController = army_packed.instantiate() as ArmyController
	army.army_id = 131
	army.owner_id = 1
	army.position = Vector3(20.0, 0.0, 20.0)
	add_child(army)

	var ger_data: BuildingData = ResourceLoader.load("res://data/buildings/ger_camp.tres") as BuildingData
	var depot: SupplyDepotNode = SupplyDepotNode.new()
	depot.depot_id = 55
	depot.owner_id = 1
	depot.building_data = ger_data
	depot.position = Vector3(20.0, 0.0, 20.0)
	add_child(depot)

	var raider_tag: StringName = &"p12_convoy_farmer"
	var interdict_first: InterdictSupplyLineCommand = InterdictSupplyLineCommand.new(131, 55, raider_tag)
	var interdict_dup: InterdictSupplyLineCommand = InterdictSupplyLineCommand.new(131, 55, raider_tag)
	_expect(CommandBus.dispatch(interdict_first) and CommandBus.dispatch(interdict_dup),
		"InterdictSupplyLineCommand executes on initial and duplicate attacks cleanly.")
	_expect(interdict_first.captured_loot_value > 200.0 \
		and is_zero_approx(interdict_dup.captured_loot_value) \
		and is_equal_approx(CommandBus.get_raider_seized_loot(raider_tag), interdict_first.captured_loot_value),
		"Attacking an already-ISOLATED army grants 0.0 extra convoy loot (prevents infinite convoy loot farming).")

	army.supply._physics_process(2.2)
	army.supply._physics_process(2.2)
	_expect(_p12_supply_restored_count >= 1 \
		and not CommandBus.is_army_supply_isolated(131) \
		and not army.supply.is_isolated() \
		and army.supply.is_connected_to_supply(),
		"Holding within friendly GerCamp depot perimeter automatically dispatches RestoreSupplyLineCommand and clears ISOLATED state.")

	army.supply.consume_yilki_horses_for_ration()
	var depleted_remount: float = army.supply.get_remount_horse_ratio()
	var replenished_remount: float = army.supply.replenish_yilki_herd(0.40)
	_expect(replenished_remount > depleted_remount,
		"Friendly depot replenishment restores Yılkı spare-horse ratio (%.2f -> %.2f)." % [depleted_remount, replenished_remount])

	CommandBus.dispatch(InterdictSupplyLineCommand.new(132, 55, raider_tag))
	var manual_restore: RestoreSupplyLineCommand = RestoreSupplyLineCommand.new(132, 55, 0.45)
	_expect(CommandBus.dispatch(manual_restore) and manual_restore.was_isolated and manual_restore.restored and not CommandBus.is_army_supply_isolated(132),
		"Direct RestoreSupplyLineCommand cleanly clears ISOLATED logistics status on isolated armies.")

	# 4. Captive Labor Cap, Single Revolt Kut Penalty & Seasonal Emancipation
	CommandBus.dispatch(ModifyKutCommand.new(80.0 - GameManager.get_kut_score(), &"p12_captive_kut_baseline"))
	var kut_before_captives: float = GameManager.get_kut_score()
	for _c: int in range(5):
		CommandBus.dispatch(AssignCaptiveLaborCommand.new(6, 150, 100))
	var expected_revolt_kut: float = CaptiveLaborManager.get_rules().slave_revolt_kut_penalty
	_expect(CaptiveLaborManager.get_captured_slave_workers(6) <= 480 \
		and is_equal_approx(GameManager.get_kut_score(), kut_before_captives - expected_revolt_kut),
		"Flooding captive workers enforces population cap (<= 480) and triggers single revolt Kut penalty (-%.1f)." % expected_revolt_kut)
	CaptiveLaborManager.step_captive_labor_season(6)
	CaptiveLaborManager.release_or_emancipate_captives(6, 480)
	_expect(not CaptiveLaborManager.is_slave_revolt_active(6) and is_zero_approx(CaptiveLaborManager.get_slave_revolt_risk(6)),
		"Voluntary emancipation and seasonal attrition resolve active slave revolt risk cleanly.")

	# 5. AI Commander 12-Tick Multi-Cycle Stamina Loop
	var ai_id: StringName = &"p12_stamina_warlord"
	var raid_steps: int = 0
	var returned_to_gather: bool = false
	var saw_first_raid: bool = false
	for _ai_tick: int in range(12):
		var ai_cmd: StepAICommanderCommand = StepAICommanderCommand.new(ai_id, true, 0, 1)
		CommandBus.dispatch(ai_cmd)
		if ai_cmd.raid_launched:
			raid_steps += 1
			saw_first_raid = true
			if ai_cmd.new_phase == GameEnums.AICommanderPhase.GATHER_RESOURCES:
				returned_to_gather = true
		elif saw_first_raid and ai_cmd.new_phase == GameEnums.AICommanderPhase.GATHER_RESOURCES:
			returned_to_gather = true
	_expect(raid_steps >= 4 and returned_to_gather,
		"AICommander executes multiple raid cycles (%d raids) and falls back to GATHER_RESOURCES upon spending raid stockpile." % raid_steps)

	EventBus.overgrazing_rebellion_triggered.disconnect(_on_p12_overgrazing_rebellion)
	EventBus.supply_line_restored.disconnect(_on_p12_supply_line_restored)
	depot.free()
	army.free()


func _test_phase12_long_horizon_combat_turan_reset_and_bounds() -> void:
	var steppe: TerrainData = ResourceLoader.load("res://data/terrain/steppe.tres") as TerrainData
	var forest: TerrainData = ResourceLoader.load("res://data/terrain/forest.tres") as TerrainData
	var doctrine: TacticalDoctrineData = ResourceLoader.load("res://data/tactics/crescent_encirclement.tres") as TacticalDoctrineData
	var combat_rules: CombatRules = ResourceLoader.load("res://data/combat/combat_rules.tres") as CombatRules
	var winter: SeasonData = ResourceLoader.load("res://data/seasons/winter.tres") as SeasonData

	# 1. 0-HP Corpse Farming Immunity & Dead Target Fire Trap Rejection
	CommandBus.dispatch(ModifyKutCommand.new(60.0 - GameManager.get_kut_score(), &"p12_corpse_kut_baseline"))
	var kut_before_corpse: float = GameManager.get_kut_score()
	var loot_before_corpse: float = CombatCalculator.get_pending_toy_loot_pool()
	var slaves_before_corpse: int = CombatCalculator.get_captured_slave_worker_pool()

	var corpse_attacker: CombatantStats = CombatantStats.new(801, 200.0, 100.0, 600.0, 1.0)
	var dead_target: CombatantStats = CombatantStats.new(802, 120.0, 80.0, 400.0, 1.0)
	dead_target.health = 0.0
	dead_target.cohesion = 0.0
	dead_target.elite_vanguard_destroyed = true

	var corpse_attack_clean: bool = true
	for _strike: int in range(5):
		var c_cmd: ResolveCombatCommand = ResolveCombatCommand.new(corpse_attacker, dead_target, steppe, 901)
		CommandBus.dispatch(c_cmd)
		if c_cmd.result == null or not is_zero_approx(c_cmd.result.damage_to_defender) \
				or c_cmd.result.defender_routed or c_cmd.result.captured_slave_workers > 0:
			corpse_attack_clean = false
	_expect(corpse_attack_clean \
		and is_equal_approx(CombatCalculator.get_pending_toy_loot_pool(), loot_before_corpse) \
		and CombatCalculator.get_captured_slave_worker_pool() == slaves_before_corpse \
		and is_equal_approx(GameManager.get_kut_score(), kut_before_corpse),
		"Striking 0-HP corpses deals 0 damage, yields 0 Toy loot/prisoners, and prevents infinite victory Kut farming.")

	var dead_trap: SulfurFireTrapCommand = SulfurFireTrapCommand.new(1, dead_target, steppe)
	_expect(not CommandBus.dispatch(dead_trap),
		"SulfurFireTrapCommand rejects 0-HP already-destroyed targets cleanly.")

	# 2. Multi-Battle Turan Tactic 5-Stage Reset & Morale Cascade Rout Rally
	var tactics: TuranTacticsComponent = TuranTacticsComponent.new()
	add_child(tactics)
	tactics.configure(133, doctrine, 100.0)

	var left_wing: Vector3 = Vector3(-0.35, 0.0, 0.936).normalized()
	var right_wing: Vector3 = Vector3(0.35, 0.0, -0.936).normalized()
	var all_three_cycles_complete: bool = true
	for _battle_idx: int in range(3):
		if tactics.get_current_phase() != GameEnums.TuranTacticPhase.RECON_DUST_SCREEN:
			all_three_cycles_complete = false
		var target_foe: CombatantStats = CombatantStats.new(820, 120.0, 90.0, 500.0, 1.0)
		tactics.execute_whistling_arrow_volley(target_foe)
		if tactics.get_current_phase() != GameEnums.TuranTacticPhase.WHISTLING_ARROW_HARASSMENT:
			all_three_cycles_complete = false
		tactics.calculate_lure_overextension(0.90, 0.40, 120.0, target_foe)
		if not tactics.evaluate_crescent_trap(left_wing, right_wing, forest, target_foe):
			all_three_cycles_complete = false
		if tactics.get_current_phase() != GameEnums.TuranTacticPhase.BORU_SHOCK_ANNIHILATION:
			all_three_cycles_complete = false
		tactics.rest_and_resupply_tactical_readiness(25.0, 90.0, 0.90, steppe)
		if tactics.get_current_phase() != GameEnums.TuranTacticPhase.RECON_DUST_SCREEN \
				or not is_zero_approx(tactics.get_target_formation_entropy()):
			all_three_cycles_complete = false
	_expect(all_three_cycles_complete,
		"TuranTacticsComponent completes 3 full 5-stage battles back-to-back with automatic post-battle reset & quiver resupply.")

	var morale_comp: MoraleComponent = MoraleComponent.new()
	morale_comp.configure(134, combat_rules)
	add_child(morale_comp)
	morale_comp.configure_veteran_and_commander_profile(0.15, 25.0, 45.0, 45.0)
	morale_comp.accumulate_battle_fatigue(20.0)
	morale_comp.evaluate_layered_vanguard_loss_shock(&"bozkurt_cavalry", 200.0)
	_expect(morale_comp.is_cascade_routing(),
		"Broken rookie formation initially enters cascade_rout.")
	for _rally_step: int in range(12):
		morale_comp.recover_fatigue_and_rally(4.0, 1.0)
	morale_comp.restore_elite_vanguard()
	_expect(not morale_comp.is_cascade_routing() and morale_comp.get_current_morale() >= 50.0 and is_zero_approx(morale_comp.get_battle_fatigue()),
		"Supplied field rest and vanguard replacement clear cascade_rout and rally morale/cohesion.")

	# 3. Stacked Speed Debuff Navigable Mobility Floor (>= 12%)
	var army_packed: PackedScene = ResourceLoader.load("res://units/army.tscn") as PackedScene
	var slow_army: ArmyController = army_packed.instantiate() as ArmyController
	slow_army.army_id = 135
	slow_army.owner_id = 1
	add_child(slow_army)
	var clean_speed: float = slow_army.mobility.get_target_speed()

	CommandBus.dispatch(ModifyKutCommand.new(20.0 - GameManager.get_kut_score(), &"p12_stack_council_debuff"))
	CommandBus.dispatch(EnactCouncilDecreeCommand.new(1, GameEnums.CouncilDilemmaChoice.TRADITION))
	SeasonManager.set_food_reserve(0)
	SeasonManager.evaluate_zud_epidemic_outbreak(135, true, 1, winter)
	slow_army.mobility.set_season(winter)
	slow_army.supply.consume_yilki_horses_for_ration()
	slow_army.supply.consume_yilki_horses_for_ration()

	var base_speed: float = slow_army.template.get_slowest_base_speed()
	var stacked_speed: float = slow_army.mobility.get_target_speed()
	_expect(stacked_speed >= base_speed * 0.12 - 0.001 and stacked_speed > 0.0 and stacked_speed < clean_speed,
		"Simultaneous winter + plague + dismounted Yılkı + council austerity preserves navigable >= 12%% base speed floor (%.2f >= %.2f)." % [stacked_speed, base_speed * 0.12])

	tactics.free()
	morale_comp.free()
	slow_army.free()


func _test_phase12_long_horizon_politics_intrigue_envoy_and_telemetry() -> void:
	_p12_council_convened_count = 0
	_p12_coalition_declared_count = 0
	_p12_cataclysm_erupted_count = 0
	_p12_internal_betrayal_count = 0
	EventBus.ak_sakallilar_council_convened.connect(_on_p12_council_convened)
	EventBus.coalition_war_declared.connect(_on_p12_coalition_declared)
	EventBus.cataclysm_erupted.connect(_on_p12_cataclysm_erupted)
	EventBus.internal_betrayal_triggered.connect(_on_p12_internal_betrayal)

	# 1. Kinship Intrigue Idempotent Uprising & Fair Healing
	CommandBus.dispatch(ModifyKutCommand.new(75.0 - GameManager.get_kut_score(), &"p12_kinship_kut"))
	CommandBus.dispatch(StepKinshipIntrigueCommand.new(&"p12_ambitious_bey", true, true, 90.0, 0))
	CommandBus.dispatch(StepKinshipIntrigueCommand.new(&"p12_ambitious_bey", true, true, 90.0, 0))
	var uprising_stage: GameEnums.IntriguePlotStage = KinshipIntrigueManager.get_lord_plot_stage(&"p12_ambitious_bey")
	var kut_at_uprising: float = GameManager.get_kut_score()
	var betrayal_before_repeat: int = _p12_internal_betrayal_count
	for _rep: int in range(4):
		CommandBus.dispatch(StepKinshipIntrigueCommand.new(&"p12_ambitious_bey", true, true, 90.0, 0))
	_expect(uprising_stage == GameEnums.IntriguePlotStage.INTERNAL_UPRISING \
		and is_equal_approx(GameManager.get_kut_score(), kut_at_uprising) \
		and _p12_internal_betrayal_count == betrayal_before_repeat,
		"Repeated steps while already at INTERNAL_UPRISING do not drain infinite -12.0 Kut or spam betrayal signals.")

	var lord_rec: KinshipLordRecord = KinshipIntrigueManager.get_or_create_lord(&"p12_ambitious_bey")
	var grv_before: float = lord_rec.grievance
	var loy_before: float = lord_rec.loyalty
	CommandBus.dispatch(StepKinshipIntrigueCommand.new(&"p12_ambitious_bey", false, false, -1.0, 0))
	_expect(lord_rec.grievance < grv_before and lord_rec.loyalty > loy_before,
		"Fair Toy/Kut turns actively heal kinsman Bey grievances and gradually rebuild loyalty.")

	# 2. Ak Sakallılar Council & Coalition Auto-Closure + Seasonal Policy Sunset
	CommandBus.dispatch(ModifyKutCommand.new(60.0 - GameManager.get_kut_score(), &"p12_reset_high_kut"))
	DiplomacyManager.evaluate_all_dynasties(GameManager.get_kut_score(), 1000.0, 0.2)
	_p12_council_convened_count = 0
	_p12_coalition_declared_count = 0

	CommandBus.dispatch(ModifyKutCommand.new(22.0 - GameManager.get_kut_score(), &"p12_trigger_crisis"))
	CommandBus.dispatch(ModifyKutCommand.new(-3.0, &"p12_fluctuate_1"))
	CommandBus.dispatch(ModifyKutCommand.new(4.0, &"p12_fluctuate_2"))
	CommandBus.dispatch(ModifyKutCommand.new(-5.0, &"p12_fluctuate_3"))
	_expect(_p12_council_convened_count == 1 and _p12_coalition_declared_count == 1,
		"Fluctuating below Kut 30 triggers Ak Sakallılar council and Coalition War ONCE without oscillation spam.")

	CommandBus.dispatch(EnactCouncilDecreeCommand.new(1, GameEnums.CouncilDilemmaChoice.TRADITION))
	CommandBus.dispatch(ModifyKutCommand.new(72.0 - GameManager.get_kut_score(), &"p12_recover_above_30"))
	_expect(not GameManager.is_ak_sakallilar_council_active() \
		and not CouncilEventEngine.is_crisis_dilemma_pending() \
		and not DiplomacyManager.is_coalition_war_active(),
		"Restoring Kut above 30 synchronously closes Ak Sakallılar crisis, pending dilemma, and hostile coalition war.")

	SeasonManager.set_food_reserve(120)
	SeasonManager.advance_season_cycle()
	_expect(is_equal_approx(CouncilEventEngine.get_active_income_multiplier(), 1.0) \
		and is_equal_approx(CouncilEventEngine.get_active_speed_multiplier(), 1.0),
		"Passing a season after Kut crisis resolution cleanly sunsets temporary TRADITION austerity multipliers.")

	# 3. Envoy Assassination Total War Lock Guard, Truce & Seasonal Infamy Decay
	var envoy_cmd_1: AssassinateEnvoyCommand = AssassinateEnvoyCommand.new(10, 11, &"p12_envoy_alpha")
	var envoy_cmd_while_war: AssassinateEnvoyCommand = AssassinateEnvoyCommand.new(10, 11, &"p12_envoy_beta")
	_expect(CommandBus.dispatch(envoy_cmd_1) and IntelligenceManager.is_total_war_active(10, 11),
		"Initial envoy assassination succeeds and escalates factions (10, 11) into TOTAL_WAR_GREAT_RAID.")
	_expect(not CommandBus.dispatch(envoy_cmd_while_war),
		"Envoy assassination is rejected while Total War is already active between factions.")

	IntelligenceManager.establish_truce(10, 11)
	_expect(not IntelligenceManager.is_total_war_active(10, 11) \
		and not CommandBus.dispatch(AssassinateEnvoyCommand.new(10, 11, &"p12_envoy_alpha")) \
		and CommandBus.dispatch(AssassinateEnvoyCommand.new(10, 11, &"p12_envoy_beta")),
		"Restoring truce clears Total War lock for future diplomacy while keeping executed envoy permanently dead.")

	DiplomacyManager.step_seasonal_diplomatic_decay(10)
	_expect(is_zero_approx(DiplomacyManager.get_recent_assassination_infamy()) \
		and is_zero_approx(DiplomacyManager.get_spy_exposure_penalty()),
		"Seasonal diplomatic decay cools old assassination infamy and spy exposure penalties over time.")

	# 4. Dead Army Epidemic Clearance, Duplicate Cataclysm Guard & Bounded Telemetry History
	var winter: SeasonData = ResourceLoader.load("res://data/seasons/winter.tres") as SeasonData
	SeasonManager.set_food_reserve(0)
	SeasonManager.evaluate_zud_epidemic_outbreak(201, true, 1, winter)
	SeasonManager.simulate_epidemic_day(201, 0)
	_expect(not SeasonManager.is_army_infected(201),
		"Exterminated army (0 troops) automatically clears OUTBREAK_EPIDEMIC status.")
	SeasonManager.evaluate_epidemic_contagion_and_ration_strain(201, 202, 0, 0)
	_expect(not SeasonManager.is_army_infected(202),
		"Dead army (0 troops) cannot spread steppe plague contagion to living army 202.")

	var kut_before_cataclysm: float = GameManager.get_kut_score()
	for _fire_tick: int in range(5):
		CommandBus.dispatch(EvaluateCataclysmCommand.new(Vector2i(19, 19), false, 34.0, false, 0.85, 14.5, 0.0))
	var fire_data: CataclysmEventData = CataclysmEngine.get_cataclysm_data(GameEnums.CataclysmType.STEPPE_WILDFIRE_SCORCH)
	_expect(_p12_cataclysm_erupted_count == 1 \
		and is_equal_approx(GameManager.get_kut_score(), kut_before_cataclysm - fire_data.kut_shock_drain),
		"Re-evaluating an already-active STEPPE_WILDFIRE_SCORCH on (19, 19) does not double-drain Kut or spam eruptions.")
	CataclysmEngine.clear_region_cataclysm(Vector2i(19, 19))

	CausalChainEngine.reset_continuous_state()
	for _acc: int in range(260):
		CommandBus.dispatch(StepContinuousSimulationCommand.new(1, 210, 1.0, true, false, false, true, 0.25, false))
	for _rec_step: int in range(60):
		CommandBus.dispatch(StepContinuousSimulationCommand.new(1, 210, 2.0, false, true, true, false, 0.80, true))
	var settled_tick: StepContinuousSimulationCommand = StepContinuousSimulationCommand.new(
		1, 210, 1.0, false, true, true, false, 0.80, true)
	CommandBus.dispatch(settled_tick)
	_expect(CausalChainEngine.get_transition_history().size() <= CausalChainEngine.MAX_TRANSITION_HISTORY \
		and settled_tick.transition_records_emitted == 0,
		"CausalChainEngine history stays capped (<= 256) across 320+ ticks and stops emitting no-op steady-state recovery records.")

	EventBus.ak_sakallilar_council_convened.disconnect(_on_p12_council_convened)
	EventBus.coalition_war_declared.disconnect(_on_p12_coalition_declared)
	EventBus.cataclysm_erupted.disconnect(_on_p12_cataclysm_erupted)
	EventBus.internal_betrayal_triggered.disconnect(_on_p12_internal_betrayal)


func _on_p12_overgrazing_rebellion(_p_id: int, _coord: Vector2i, _penalty: float) -> void:
	_p12_overgrazing_rebellion_count += 1


func _on_p12_supply_line_restored(_army_id: int, _depot_id: int) -> void:
	_p12_supply_restored_count += 1


func _on_p12_council_convened(_current_kut: float, _penalty: float, _skirmish: bool) -> void:
	_p12_council_convened_count += 1


func _on_p12_coalition_declared(_members: PackedStringArray, _kut: float) -> void:
	_p12_coalition_declared_count += 1


func _on_p12_cataclysm_erupted(_c_id: StringName, _c_type: GameEnums.CataclysmType, _coord: Vector2i, _p_mult: float, _c_mult: float, _wear: float, _ref: int) -> void:
	_p12_cataclysm_erupted_count += 1


func _on_p12_internal_betrayal(_b_id: StringName, _stage: GameEnums.IntriguePlotStage, _trp: int, _sab: bool, _kut: float) -> void:
	_p12_internal_betrayal_count += 1


func _test_phase14_deterministic_long_horizon_harness() -> void:
	# 1. Negative invariant verification: ensure SimulationInvariantChecker detects NaN, overflows, and deadlocks
	var bad_snap: SimulationInvariantChecker.SeasonSnapshot = SimulationInvariantChecker.SeasonSnapshot.new()
	bad_snap.kut = NAN
	bad_snap.food = -15
	bad_snap.ores = {&"iron": -3, &"steel": 999999}
	bad_snap.jade_authority_multiplier = 2.75
	bad_snap.turan_phase = GameEnums.TuranTacticPhase.WHISTLING_ARROW_HARASSMENT
	bad_snap.turan_quiver_ammo = 0.0
	bad_snap.army_speed = 0.10
	bad_snap.base_speed = 8.0
	var bad_errors: PackedStringArray = SimulationInvariantChecker.validate_snapshot(bad_snap)
	_expect(bad_errors.size() >= 7,
		"SimulationInvariantChecker flags NaN, negative food/ore, runaway inflation, clamp bypass, speed collapse, and FSM deadlock (%d errors detected)." % bad_errors.size())

	# 2. Run 24-season (6-year) deterministic simulation under fixed seed 14001
	var sim_a: LongHorizonSimulator.SimulationRunResult = LongHorizonSimulator.run(
		self, LongHorizonSimulator.SimulationProfile.BALANCED_NOMAD, 24, 14001, 0)
	_expect(sim_a.seasons_simulated == 24 and sim_a.history.size() == 24,
		"LongHorizonSimulator records all 24 seasonal snapshots (6 game years).")
	_expect(sim_a.passed(),
		"24-season balanced steppe simulation satisfies all invariants (violations: %s)." % ", ".join(sim_a.violations))

	var final_a: SimulationInvariantChecker.SeasonSnapshot = sim_a.latest()
	_expect(final_a != null \
		and final_a.ores.size() == 8 \
		and sim_a.steel_batches_smelted > 0 \
		and sim_a.battles_fought >= 4 \
		and final_a.dynasty_trust.size() == 3,
		"Seasonal snapshots capture Food, Kut, 7-Ores+Steel, battles (%d), steel batches (%d), and dynasty relations." % [sim_a.battles_fought, sim_a.steel_batches_smelted])

	# 3. Repeatability verification: identical seed on clean slot yields byte-for-byte identical trajectory
	var sim_b: LongHorizonSimulator.SimulationRunResult = LongHorizonSimulator.run(
		self, LongHorizonSimulator.SimulationProfile.BALANCED_NOMAD, 24, 14001, 1)
	var final_b: SimulationInvariantChecker.SeasonSnapshot = sim_b.latest()
	var exact_replay_match: bool = sim_b.passed() \
		and final_b != null \
		and final_a.food == final_b.food \
		and is_equal_approx(final_a.kut, final_b.kut) \
		and final_a.ores[&"steel"] == final_b.ores[&"steel"] \
		and final_a.active_troops == final_b.active_troops \
		and is_equal_approx(final_a.glory_score, final_b.glory_score)
	_expect(exact_replay_match,
		"Fixed-seed replay reproduces identical Food (%d), Kut (%.2f), Steel (%d), Troops (%d), and Glory (%.2f)." % [
			final_a.food, final_a.kut, final_a.ores.get(&"steel", 0), final_a.active_troops, final_a.glory_score])


func _test_phase15_economy_ecology_profile_calibration() -> void:
	# 1. Warehouse Stockpile Cap, Non-Stalling Crisis Smelting & Governance Tax Multiplier
	var econ_rules: EconomyRules = ResourceManager.get_economy_rules()
	var cap: int = econ_rules.max_ore_stockpile_capacity
	CommandBus.dispatch(DepositResourcesCommand.new(1501, &"iron", cap + 25000))
	_expect(ResourceManager.get_amount(1501, &"iron") == cap,
		"Stockpile warehouse ceiling enforces max_ore_stockpile_capacity (%d)." % cap)

	CommandBus.dispatch(DepositResourcesCommand.new(1502, &"iron", 20))
	CommandBus.dispatch(DepositResourcesCommand.new(1502, &"coal", 10))
	ResourceManager.set_camp_migration_and_supply_state(1502, true, true)
	var crisis_smelt: int = ResourceManager.smelt_steel_with_logistics_constraints(1502, 4)
	var capped_smelt: int = ResourceManager.smelt_steel_with_logistics_constraints(1502, 500)
	_expect(crisis_smelt >= 1 and capped_smelt >= 1,
		"Multi-batch Steel smelting does not stall to 0 under overlapping Sefer Arabası + Siege (min 1 batch) and clamps cleanly to affordable inputs.")

	CommandBus.dispatch(ModifyKutCommand.new(75.0 - GameManager.get_kut_score(), &"p15_tax_baseline"))
	CouncilEventEngine.step_seasonal_council_decay(5)
	var high_kut_tax: int = ResourceManager.calculate_effective_regional_tax_with_logistics(1502, 4, 2)
	CommandBus.dispatch(ModifyKutCommand.new(22.0 - GameManager.get_kut_score(), &"p15_tax_low_kut"))
	var low_kut_tax: int = ResourceManager.calculate_effective_regional_tax_with_logistics(1502, 4, 2)
	_expect(low_kut_tax < high_kut_tax and is_equal_approx(ResourceManager.get_governance_tax_multiplier(), 0.75),
		"Kut < 30 legitimacy penalty authentically reduces collected regional Silver/Gold tax (0.75x: %d < %d)." % [low_kut_tax, high_kut_tax])

	CommandBus.dispatch(ModifyKutCommand.new(75.0 - GameManager.get_kut_score(), &"p15_tax_restore"))
	CouncilEventEngine.step_seasonal_council_decay(5)

	# 2. Sefer Arabası Migration Rations vs Famine-Bypass & Zud Double-Emit Prevention
	CommandBus.dispatch(MigrateCampToPastureCommand.new(1503, Vector2i(71, 71)))
	SeasonManager.set_food_reserve(50)
	var fed_mig: MigrateCampToPastureCommand = MigrateCampToPastureCommand.new(1503, Vector2i(71, 72))
	_expect(CommandBus.dispatch(fed_mig) and fed_mig.migration_food_spent == 4 and SeasonManager.get_food_reserve() == 46,
		"Healthy Sefer Arabası migration deducts calibrated migration_food_cost (4 Food: 50 -> 46).")
	SeasonManager.set_food_reserve(5)
	var famine_mig: MigrateCampToPastureCommand = MigrateCampToPastureCommand.new(1503, Vector2i(71, 73))
	_expect(CommandBus.dispatch(famine_mig) and famine_mig.migration_food_spent == 0 and SeasonManager.get_food_reserve() == 5,
		"Emergency famine-bypass (Food <= 12) allows critical pasture evacuation at 0 Food ration cost.")

	# Verify GRAZED intermediate pasture multiplier (0.75x when capacity in (0, 40])
	CommandBus.dispatch(GrazePastureCommand.new(1503, Vector2i(71, 73), 800, 1.0))
	_expect(is_equal_approx(PastureEcologyManager.get_meat_milk_production_multiplier(1503), 0.75),
		"Partially depleted pasture (<= 40.0) applies 0.75x GRAZED ecological friction before full collapse.")

	# Verify SeasonManager.set_food_reserve(0) does not falsely fire Winter Zud drain without evaluate_zud_starvation
	var winter_res: SeasonData = ResourceLoader.load("res://data/seasons/winter.tres") as SeasonData
	while SeasonManager.get_current_season().season_type != GameEnums.SeasonType.WINTER:
		SeasonManager.advance_season_cycle()
	var kut_before_zero: float = GameManager.get_kut_score()
	SeasonManager.set_food_reserve(0)
	_expect(is_equal_approx(GameManager.get_kut_score(), kut_before_zero),
		"Setting Food reserve to 0 during Winter does not double-emit spurious zud_starvation_ticked Kut drain.")
	SeasonManager.evaluate_zud_starvation(winter_res)
	_expect(GameManager.get_kut_score() < kut_before_zero,
		"Explicit Winter Zud evaluation drains calibrated Zud Kut penalty (-14.0).")

	# 3. Three Distinct 24-Season (6-Year) Long-Horizon Profiles
	var miner: LongHorizonSimulator.SimulationRunResult = LongHorizonSimulator.run(
		self, LongHorizonSimulator.SimulationProfile.SETTLED_MINER, 24, 15011, 2)
	var miner_end: SimulationInvariantChecker.SeasonSnapshot = miner.latest()
	_expect(miner.passed() and miner_end != null \
		and miner.had_grazed_friction \
		and not miner.had_starving_pasture \
		and miner.steel_batches_smelted >= 60 \
		and miner_end.ores.has(&"steel") and miner_end.ores[&"steel"] <= cap \
		and miner_end.food >= 100,
		"SETTLED_MINER (24s): passed=%s, grazed_friction=%s, steel_batches=%d, final_food=%d (violations: %s)." % [
			miner.passed(), miner.had_grazed_friction, miner.steel_batches_smelted,
			miner_end.food if miner_end != null else -1, ", ".join(miner.violations)])

	var nomad: LongHorizonSimulator.SimulationRunResult = LongHorizonSimulator.run(
		self, LongHorizonSimulator.SimulationProfile.CONTINUOUS_NOMAD, 24, 15022, 3)
	var nomad_end: SimulationInvariantChecker.SeasonSnapshot = nomad.latest()
	_expect(nomad.passed() and nomad_end != null \
		and nomad.migrations_performed >= 20 \
		and nomad.migration_food_spent >= 40 \
		and not nomad.had_starving_pasture \
		and is_equal_approx(nomad.min_pasture_multiplier_observed, 1.0) \
		and nomad_end.remount_horse_ratio >= 0.99 \
		and nomad_end.food >= 100,
		"CONTINUOUS_NOMAD (24s): passed=%s, migrations=%d, food_spent=%d, min_yield=%.2f, final_food=%d (violations: %s)." % [
			nomad.passed(), nomad.migrations_performed, nomad.migration_food_spent,
			nomad.min_pasture_multiplier_observed, nomad_end.food if nomad_end != null else -1,
			", ".join(nomad.violations)])

	var crisis: LongHorizonSimulator.SimulationRunResult = LongHorizonSimulator.run(
		self, LongHorizonSimulator.SimulationProfile.CRISIS_CLAN, 24, 15033, 4)
	var crisis_end: SimulationInvariantChecker.SeasonSnapshot = crisis.latest()
	var crisis_recovered: bool = crisis.passed() and crisis_end != null \
		and crisis.min_food_observed == 0 \
		and crisis.min_kut_observed < 30.0 \
		and crisis.had_council_crisis \
		and crisis.had_starving_pasture \
		and crisis.min_remount_observed < 1.0 \
		and crisis_end.food >= 40 \
		and crisis_end.kut >= 40.0 \
		and not crisis_end.council_active \
		and crisis_end.remount_horse_ratio > crisis.min_remount_observed \
		and crisis_end.remount_horse_ratio >= 0.90 \
		and crisis_end.active_troops >= 100
	_expect(crisis_recovered,
		"CRISIS_CLAN (24s): genuine shock & organic recovery (min_food=%d -> %d, min_kut=%.1f -> %.1f, min_remount=%.2f -> %.2f, troops=%d, violations=%s)." % [
			crisis.min_food_observed,
			crisis_end.food if crisis_end != null else -1,
			crisis.min_kut_observed,
			crisis_end.kut if crisis_end != null else -1.0,
			crisis.min_remount_observed,
			crisis_end.remount_horse_ratio if crisis_end != null else -1.0,
			crisis_end.active_troops if crisis_end != null else -1,
			", ".join(crisis.violations)])


func _test_phase16_combat_turan_fsm_and_casualty_hardening() -> void:
	var steppe: TerrainData = ResourceLoader.load("res://data/terrain/steppe.tres") as TerrainData
	var forest: TerrainData = ResourceLoader.load("res://data/terrain/forest.tres") as TerrainData
	var doctrine: TacticalDoctrineData = ResourceLoader.load("res://data/tactics/crescent_encirclement.tres") as TacticalDoctrineData
	var combat_rules: CombatRules = ResourceLoader.load("res://data/combat/combat_rules.tres") as CombatRules
	var calib: CausalFrictionCalibration = CausalChainEngine.get_calibration()

	# 1. Zero-Ammo Setter Exit & Interrupted Mid-Battle Rest Cleanup
	BallisticsEngine.set_steppe_wind_weather(Vector3(0.0, 0.0, -6.0), 14.0, false)
	var tactics: TuranTacticsComponent = TuranTacticsComponent.new()
	add_child(tactics)
	tactics.configure(1601, doctrine, 100.0)

	var dummy_foe: CombatantStats = CombatantStats.new(1690, 120.0, 90.0, 600.0, 1.0)
	tactics.execute_whistling_arrow_volley(dummy_foe)
	_expect(tactics.get_current_phase() == GameEnums.TuranTacticPhase.WHISTLING_ARROW_HARASSMENT,
		"Phase 16 setup: whistling volley enters Stage 2 WHISTLING_ARROW_HARASSMENT.")
	tactics.set_quiver_ammo(0.0)
	_expect(tactics.get_current_phase() == GameEnums.TuranTacticPhase.FEIGNED_RETREAT_LURE,
		"Setting quiver ammo to 0.0 while in WHISTLING_ARROW_HARASSMENT immediately exits Stage 2 (prevents 0-ammo deadlock).")

	tactics.configure(1601, doctrine, 50.0)
	tactics.execute_whistling_arrow_volley(dummy_foe)
	tactics.set_readiness_state(10.0, 0.0, 1.0)
	_expect(tactics.get_current_phase() != GameEnums.TuranTacticPhase.WHISTLING_ARROW_HARASSMENT,
		"set_readiness_state(..., 0.0, ...) immediately exits WHISTLING_ARROW_HARASSMENT.")

	tactics.rest_and_resupply_tactical_readiness(10.0, 90.0, 0.5, steppe)
	_expect(tactics.get_current_phase() == GameEnums.TuranTacticPhase.RECON_DUST_SCREEN \
		and is_zero_approx(tactics.get_target_formation_entropy()),
		"Interrupted mid-battle rest cleanly resets active Stage 3 commitment back to RECON_DUST_SCREEN.")

	# 2. Pre-Zud Gale Storm Atmospheric Coupling in TuranTacticsComponent
	var tactics_calm: TuranTacticsComponent = TuranTacticsComponent.new()
	var tactics_storm: TuranTacticsComponent = TuranTacticsComponent.new()
	add_child(tactics_calm)
	add_child(tactics_storm)
	tactics_calm.configure(1602, doctrine, 100.0)
	tactics_storm.configure(1603, doctrine, 100.0)

	var calm_foe: CombatantStats = CombatantStats.new(1691, 120.0, 90.0, 600.0, 1.0)
	var storm_foe: CombatantStats = CombatantStats.new(1692, 120.0, 90.0, 600.0, 1.0)
	var calm_volley: Dictionary[StringName, float] = tactics_calm.execute_whistling_arrow_volley(calm_foe)
	var calm_ammo_spent: float = 100.0 - tactics_calm.get_quiver_ammo()

	BallisticsEngine.set_steppe_wind_weather(Vector3(12.0, 0.0, 12.0), -12.0, true)
	var storm_volley: Dictionary[StringName, float] = tactics_storm.execute_whistling_arrow_volley(storm_foe)
	var storm_ammo_spent: float = 100.0 - tactics_storm.get_quiver_ammo()
	_expect(storm_ammo_spent > calm_ammo_spent * 1.25 \
		and storm_volley[TuranTacticsComponent.KEY_MORALE_DAMAGE] < calm_volley[TuranTacticsComponent.KEY_MORALE_DAMAGE] * 0.70,
		"Pre-Zud gale storm increases whistling volley quiver drain (1.35x) and damps morale shock (0.60x).")

	# Wing angle ~135 deg (2.356 rad >= PI*0.65 calm, *0.78 = 1.838 < PI*0.65 storm -> storm aborts to melee)
	var wing_a: Vector3 = Vector3(1.0, 0.0, 0.0)
	var wing_b: Vector3 = Vector3(-0.7071, 0.0, 0.7071).normalized()
	tactics_storm.advance_to_phase(GameEnums.TuranTacticPhase.CRESCENT_ENCIRCLEMENT_TRAP)
	var storm_trap_ok: bool = tactics_storm.evaluate_crescent_trap(wing_a, wing_b, forest, storm_foe)
	_expect(not storm_trap_ok \
		and tactics_storm.get_current_phase() == GameEnums.TuranTacticPhase.BORU_SHOCK_ANNIHILATION \
		and tactics_storm.get_last_fallback_reason() == &"pre_zud_storm_crescent_melee",
		"PRE_ZUD_GALE_STORM damps marginal Crescent wings and breaks stalemate into BORU_SHOCK_ANNIHILATION melee.")

	BallisticsEngine.set_steppe_wind_weather(Vector3(0.0, 0.0, -6.0), 14.0, false)
	tactics_calm.advance_to_phase(GameEnums.TuranTacticPhase.CRESCENT_ENCIRCLEMENT_TRAP)
	_expect(tactics_calm.evaluate_crescent_trap(wing_a, wing_b, forest, calm_foe),
		"Same marginal Crescent wings succeed cleanly once calm steppe weather returns.")

	# 3. Stalled Lure / Blocked Crescent / Extreme Fatigue / Commander Loss Escape Guarantees
	var fallback_reasons: Array[StringName] = []
	var on_fallback: Callable = func(_prev: GameEnums.TuranTacticPhase, _fb: GameEnums.TuranTacticPhase, reason: StringName) -> void:
		fallback_reasons.append(reason)
	tactics.tactical_fallback_triggered.connect(on_fallback)

	tactics.configure(1601, doctrine, 100.0)
	for _lure_i: int in range(3):
		tactics.calculate_lure_overextension(0.10, 0.90, 5.0, dummy_foe)
	_expect(tactics.get_current_phase() == GameEnums.TuranTacticPhase.BORU_SHOCK_ANNIHILATION \
		and tactics.get_last_fallback_reason() == &"feigned_retreat_stalled_fallback",
		"3 consecutive stalled low-ambition lure steps break out of FEIGNED_RETREAT_LURE into BORU_SHOCK_ANNIHILATION.")

	tactics.configure(1601, doctrine, 100.0)
	tactics.advance_to_phase(GameEnums.TuranTacticPhase.CRESCENT_ENCIRCLEMENT_TRAP)
	var first_narrow: bool = tactics.evaluate_crescent_trap_with_remount_ratio(Vector3.FORWARD, Vector3.FORWARD, 1.0, calib, forest)
	var phase_after_first_narrow: GameEnums.TuranTacticPhase = tactics.get_current_phase()
	var second_narrow: bool = tactics.evaluate_crescent_trap_with_remount_ratio(Vector3.FORWARD, Vector3.FORWARD, 1.0, calib, forest)
	_expect(not first_narrow and phase_after_first_narrow == GameEnums.TuranTacticPhase.CRESCENT_ENCIRCLEMENT_TRAP \
		and not second_narrow and tactics.get_current_phase() == GameEnums.TuranTacticPhase.BORU_SHOCK_ANNIHILATION \
		and tactics.get_last_fallback_reason() == &"crescent_encirclement_blocked",
		"Blocked Crescent permits 1 retry, then triggers deterministic melee fallback on second stalled attempt.")

	tactics.set_readiness_state(88.0, 50.0, 1.0)
	tactics.advance_to_phase(GameEnums.TuranTacticPhase.CRESCENT_ENCIRCLEMENT_TRAP)
	tactics.evaluate_crescent_trap(wing_a, wing_b, forest)
	_expect(tactics.get_current_phase() == GameEnums.TuranTacticPhase.RECON_DUST_SCREEN \
		and tactics.get_last_fallback_reason() == &"extreme_fatigue_crescent_abort",
		"Extreme battle fatigue (>= 85.0) aborts blocked or contested Crescent Trap cleanly into RECON_DUST_SCREEN.")

	tactics.configure(1601, doctrine, 100.0)
	var fresh_momentum: float = tactics.compute_boru_shock_momentum(1200.0, 14.0, true, false)
	tactics.set_readiness_state(90.0, 10.0, 0.20)
	var tired_momentum: float = tactics.compute_boru_shock_momentum(1200.0, 14.0, true, false)
	_expect(fresh_momentum > tired_momentum and tired_momentum >= 1.0 and not is_nan(tired_momentum),
		"Börü heavy shock scales safely down under fatigue/low-remounts (%.2f -> %.2f >= 1.0)." % [fresh_momentum, tired_momentum])

	tactics.execute_whistling_arrow_volley(dummy_foe)
	tactics.notify_commander_lost(false)
	_expect(tactics.get_current_phase() == GameEnums.TuranTacticPhase.RECON_DUST_SCREEN \
		and not tactics.is_commander_alive() \
		and fallback_reasons.has(&"commander_lost_withdrawal"),
		"Losing commander mid-battle cleanly withdraws active Turan FSM stage back to RECON_DUST_SCREEN.")
	tactics.tactical_fallback_triggered.disconnect(on_fallback)
	tactics_calm.free()
	tactics_storm.free()
	tactics.free()

	# 4. CombatCalculator NaN/Zero Vectors, Overkill Loot Cap, Extreme Penalty Finite Floor
	CombatCalculator.claim_pending_toy_loot_pool()
	var nan_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	nan_rng.seed = 1604
	var atk_nan: CombatantStats = CombatantStats.new(1610, 180.0, 100.0, 600.0, 1.0)
	atk_nan.attack_vector = Vector3.ZERO
	var def_nan: CombatantStats = CombatantStats.new(1611, 100.0, 80.0, 500.0, 1.0)
	def_nan.facing_vector = Vector3(NAN, 0.0, 0.0)
	var res_nan: CombatResult = CombatCalculator.calculate(atk_nan, def_nan, steppe, null, nan_rng)
	_expect(res_nan.engagement_angle == GameEnums.CombatEngagementAngle.FRONT \
		and is_equal_approx(res_nan.directional_damage_multiplier, 1.0) \
		and not is_nan(res_nan.damage_to_defender) and res_nan.damage_to_defender > 0.0,
		"CombatCalculator safely falls back to FRONT (1.0x) on Vector3.ZERO / NAN vectors with zero NaN.")

	var overkill_atk: CombatantStats = CombatantStats.new(1612, 10000.0, 100.0, 2000.0, 1.0)
	overkill_atk.has_steel_weapons = true
	overkill_atk.charge_mass_momentum = 3.0
	var tiny_def: CombatantStats = CombatantStats.new(1613, 50.0, 20.0, 10.0, 1.0)
	tiny_def.is_escape_vector_sealed = true
	tiny_def.elite_vanguard_destroyed = true
	var ok_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	ok_rng.seed = 1605
	var res_ok: CombatResult = CombatCalculator.calculate(overkill_atk, tiny_def, steppe, null, ok_rng)
	var max_legit_slaves: int = maxi(int(roundf(10.0 * combat_rules.slave_capture_per_routed_health)), 1)
	var max_legit_loot: float = float(max_legit_slaves) * combat_rules.slave_worker_toy_value + 10.0 * combat_rules.annihilation_loot_per_health
	_expect(res_ok.defender_routed \
		and res_ok.captured_slave_workers <= max_legit_slaves \
		and res_ok.captured_toy_loot_value <= max_legit_loot + 0.01,
		"Massive overkill strike on 10-HP target caps slave capture (%d <= %d) and Toy loot (%.2f <= %.2f) to actual pre-hit HP." % [
			res_ok.captured_slave_workers, max_legit_slaves, res_ok.captured_toy_loot_value, max_legit_loot])

	var ext_atk: CombatantStats = CombatantStats.new(1614, 150.0, 90.0, 400.0, 0.0)
	ext_atk.fatigue = 100.0
	ext_atk.quiver_ammo_ratio = 0.0
	ext_atk.remount_horse_ratio = 0.0
	ext_atk.totem_offense_bonus = -0.95
	ext_atk.active_tactic_phase = GameEnums.TuranTacticPhase.WHISTLING_ARROW_HARASSMENT
	var ext_def: CombatantStats = CombatantStats.new(1615, 120.0, 90.0, 400.0, 1.0)
	var res_ext: CombatResult = CombatCalculator.calculate(ext_atk, ext_def, steppe, null, nan_rng)
	_expect(not is_nan(res_ext.damage_to_defender) and not is_inf(res_ext.damage_to_defender) and res_ext.damage_to_defender >= 0.0,
		"Extreme stacked penalties (0 supply, 100 fatigue, 0 ammo, 0 remounts) yield finite non-negative combat damage.")

	var claim_cmd: ResolveCombatCommand = ResolveCombatCommand.new(
		CombatantStats.new(1616, 400.0, 100.0, 800.0, 1.0),
		CombatantStats.new(1617, 50.0, 20.0, 50.0, 1.0),
		steppe, 1606)
	claim_cmd.defender.elite_vanguard_destroyed = true
	CommandBus.dispatch(claim_cmd)
	var pooled_before_claim: float = CombatCalculator.get_pending_toy_loot_pool()
	var claimed_pool: float = CombatCalculator.claim_pending_toy_loot_pool()
	_expect(pooled_before_claim > 0.0 and is_equal_approx(claimed_pool, pooled_before_claim) \
		and is_zero_approx(CombatCalculator.get_pending_toy_loot_pool()),
		"claim_pending_toy_loot_pool() returns full accumulated pool and resets pending pool cleanly to 0.0.")

	# 5. MoraleComponent Idempotent Vanguard Loss, 0-Supply Rally Block, Staggered Hold Collapse
	var morale_comp: MoraleComponent = MoraleComponent.new()
	morale_comp.configure(1620, combat_rules)
	add_child(morale_comp)
	morale_comp.configure_veteran_and_commander_profile(0.15, 25.0, 55.0, 50.0)
	var rout_signal_count: Array[int] = [0]
	var on_rout: Callable = func(_id: int, _el: StringName, _mor: float) -> void:
		rout_signal_count[0] += 1
	morale_comp.cascade_rout_started.connect(on_rout)

	var first_shock: Dictionary[StringName, float] = morale_comp.evaluate_layered_vanguard_loss_shock(&"bozkurt_cavalry", 200.0)
	var second_shock: Dictionary[StringName, float] = morale_comp.evaluate_layered_vanguard_loss_shock(&"bozkurt_cavalry", 200.0)
	_expect(rout_signal_count[0] == 1 \
		and first_shock[&"morale_shock"] > 0.0 \
		and is_zero_approx(second_shock[&"morale_shock"]) \
		and is_zero_approx(second_shock[&"captured_slave_workers"]),
		"Duplicate vanguard destruction call while already destroyed is strictly idempotent (1 rout signal, 0 duplicate shock/slaves).")

	var morale_at_rout: float = morale_comp.get_current_morale()
	morale_comp.recover_fatigue_and_rally(10.0, 0.0)
	_expect(morale_comp.is_cascade_routing() and is_equal_approx(morale_comp.get_current_morale(), morale_at_rout),
		"Starving formation (supply_ratio == 0.0) cannot rally morale or clear active cascade_rout.")
	for _r: int in range(12):
		morale_comp.recover_fatigue_and_rally(4.0, 1.0)
	morale_comp.restore_elite_vanguard()
	_expect(not morale_comp.is_cascade_routing() and morale_comp.get_current_morale() > morale_at_rout,
		"Supplied rest and vanguard restoration lift cascade_rout and rally morale.")

	morale_comp.configure_veteran_and_commander_profile(0.90, 95.0, 85.0, 80.0)
	morale_comp.evaluate_layered_vanguard_loss_shock(&"bozkurt_cavalry", 200.0)
	var held_initially: bool = morale_comp.is_in_staggered_hold() and not morale_comp.is_cascade_routing()
	morale_comp.accumulate_battle_fatigue(40.0)
	_expect(held_initially and not morale_comp.is_in_staggered_hold() and morale_comp.is_cascade_routing(),
		"Formation holding in staggered_hold collapses into cascade_rout once fatigue reaches >= 85.0.")
	morale_comp.cascade_rout_started.disconnect(on_rout)
	morale_comp.free()

	# 6. 25-Battle Soldier Conservation, 0-Veteran Fix, 0-Troop Edge & Captive Bound Gauntlet
	var zero_vet_comp: AttritionCasualtyComponent = AttritionCasualtyComponent.new()
	add_child(zero_vet_comp)
	zero_vet_comp.configure(1621, 100, 0.0)
	zero_vet_comp.reinforce_with_raw_recruits(50)
	_expect(is_zero_approx(zero_vet_comp.get_veteran_ratio()),
		"Reinforcing a 0.0-veteran raw army with more raw recruits preserves 0.0 veteran_ratio (no artificial 0.05 inflation).")
	var wipe_res: Dictionary = zero_vet_comp.record_battle_casualties(9999)
	var wounded_after_wipe: int = zero_vet_comp.get_wounded_pool()
	var dead_after_wipe: int = zero_vet_comp.get_permanent_dead()
	var post_wipe_res: Dictionary = zero_vet_comp.record_battle_casualties(50)
	_expect(zero_vet_comp.get_active_troops() == 0 \
		and wounded_after_wipe + dead_after_wipe == 150 \
		and zero_vet_comp.get_wounded_pool() == wounded_after_wipe \
		and zero_vet_comp.get_permanent_dead() == dead_after_wipe \
		and wipe_res.has("active_troops") and post_wipe_res.has("wounded_added"),
		"Total wipeout clamps cleanly to 0 active troops, preserves 150-soldier count, and rejects further casualties at 0 troops.")
	zero_vet_comp.free()

	var battle_comp: AttritionCasualtyComponent = AttritionCasualtyComponent.new()
	var battle_tactics: TuranTacticsComponent = TuranTacticsComponent.new()
	add_child(battle_comp)
	add_child(battle_tactics)
	battle_comp.configure(1622, 200, 0.80)
	battle_tactics.configure(1622, doctrine, 100.0)
	var total_recruited: int = 0
	var gauntlet_ok: bool = true
	var w_a: Vector3 = Vector3(-0.35, 0.0, 0.936).normalized()
	var w_b: Vector3 = Vector3(0.35, 0.0, -0.936).normalized()

	for b_idx: int in range(25):
		var atk_b: CombatantStats = CombatantStats.new(1622, 220.0, 120.0, 700.0, 1.0)
		var def_b: CombatantStats = CombatantStats.new(2600 + b_idx, 120.0, 80.0, 320.0, 0.9)
		battle_tactics.execute_whistling_arrow_volley(def_b)
		battle_tactics.calculate_lure_overextension(0.90, 0.40, 100.0, def_b)
		battle_tactics.evaluate_crescent_trap(w_a, w_b, forest, def_b)
		battle_tactics.compute_boru_shock_momentum(800.0, 13.0, true, false)
		CommandBus.dispatch(ResolveCombatCommand.new(atk_b, def_b, steppe, 1650 + b_idx))
		battle_comp.record_battle_casualties(20, 1.15, 0.10)
		battle_comp.tick_wounded_treatment(b_idx % 4 != 0)
		if battle_comp.get_active_troops() < 150:
			battle_comp.reinforce_with_raw_recruits(35)
			total_recruited += 35
		battle_comp.tick_cohesion_acclimation(3.0)
		battle_tactics.rest_and_resupply_tactical_readiness(20.0, 85.0, 0.5, steppe)
		var conserved: int = battle_comp.get_active_troops() + battle_comp.get_wounded_pool() + battle_comp.get_permanent_dead()
		var vr: float = battle_comp.get_veteran_ratio()
		var sm: float = battle_comp.get_wounded_speed_multiplier()
		var cc: float = battle_comp.get_effective_cohesion_cap()
		if conserved != 200 + total_recruited or vr < 0.0 or vr > 1.0 or sm < 0.65 or sm > 1.0 or cc < 45.0 or cc > 100.0 \
				or battle_tactics.get_current_phase() != GameEnums.TuranTacticPhase.RECON_DUST_SCREEN:
			gauntlet_ok = false

	var captive_cap: int = maxi(CaptiveLaborManager.get_core_clan_population(1) * 4, 480)
	_expect(gauntlet_ok and CaptiveLaborManager.get_captured_slave_workers(1) <= captive_cap,
		"25-battle combat gauntlet strictly conserves soldier count (%d), bounds veteran/speed/cohesion, resets Turan FSM, and caps captives (%d <= %d)." % [
			200 + total_recruited, CaptiveLaborManager.get_captured_slave_workers(1), captive_cap])

	CombatCalculator.claim_pending_toy_loot_pool()
	battle_tactics.free()
	battle_comp.free()


func _test_phase17_politics_intrigue_dynasty_long_horizon() -> void:
	var forest: TerrainData = ResourceLoader.load("res://data/terrain/forest.tres") as TerrainData
	var rules: DiplomacyRules = ResourceLoader.load("res://data/diplomacy/diplomacy_rules.tres") as DiplomacyRules

	# 1. GameManager Kut/Council Synchronicity inside kut_changed & NaN/INF Immunity
	CommandBus.dispatch(ModifyKutCommand.new(75.0 - GameManager.get_kut_score(), &"p17_init_baseline"))
	var observed_council: Array[bool] = [false]
	var observed_dilemma: Array[bool] = [false]
	var on_kut_sync: Callable = func(_prev: float, new_kut: float, _reason: StringName) -> void:
		if new_kut < 30.0:
			observed_council[0] = GameManager.is_ak_sakallilar_council_active()
			observed_dilemma[0] = CouncilEventEngine.is_crisis_dilemma_pending()
	EventBus.kut_changed.connect(on_kut_sync)

	CommandBus.dispatch(ModifyKutCommand.new(22.0 - GameManager.get_kut_score(), &"p17_drop_below_30"))
	_expect(observed_council[0] and observed_dilemma[0],
		"Subscribers inside EventBus.kut_changed observe synchronized _council_active and _crisis_dilemma_pending states.")
	EventBus.kut_changed.disconnect(on_kut_sync)

	CommandBus.dispatch(ModifyKutCommand.new(NAN, &"p17_nan_delta"))
	CommandBus.dispatch(ModifyKutCommand.new(INF, &"p17_inf_delta"))
	_expect(is_equal_approx(GameManager.get_kut_score(), 22.0) and not is_nan(GameManager.get_kut_score()),
		"GameManager ignores NaN/INF Kut deltas without corrupting state.")

	CommandBus.dispatch(ModifyKutCommand.new(75.0 - GameManager.get_kut_score(), &"p17_restore_kut"))
	_expect(not GameManager.is_ak_sakallilar_council_active() \
		and not CouncilEventEngine.is_crisis_dilemma_pending() \
		and not DiplomacyManager.is_coalition_war_active(),
		"Restoring Kut above 30 synchronously clears council, pending dilemma, and coalition state.")

	# 2. DiplomacyManager NaN Guards & Multi-Season Peaceful Trust Thaw
	DiplomacyManager.evaluate_all_dynasties(75.0, 1000.0, 0.2)
	var karluk_profile: DynastyProfile = DiplomacyManager.get_dynasty_profile(&"karluk")
	DiplomacyManager.set_dynasty_trust(&"karluk", 20.0)
	DiplomacyManager.set_dynasty_trust(&"karluk", NAN)
	DiplomacyManager.modify_all_dynasty_trust(NAN)
	var guarded_stance: GameEnums.DynastyAttitude = DiplomacyManager.evaluate_dynasty_with_intelligence_and_glory(&"karluk", NAN, INF, -NAN)
	_expect(is_equal_approx(DiplomacyManager.get_dynasty_trust(&"karluk"), 20.0) \
		and guarded_stance >= GameEnums.DynastyAttitude.ALLY,
		"DiplomacyManager rejects NaN/INF trust and evaluation inputs while keeping trust finite (20.0).")

	DiplomacyManager.step_seasonal_diplomatic_decay(10)
	var thawed_trust: float = DiplomacyManager.get_dynasty_trust(&"karluk")
	DiplomacyManager.step_seasonal_diplomatic_decay(30)
	var capped_trust: float = DiplomacyManager.get_dynasty_trust(&"karluk")
	_expect(thawed_trust > 30.0 and thawed_trust <= karluk_profile.trust_index \
		and is_equal_approx(capped_trust, karluk_profile.trust_index),
		"Peaceful high-Kut seasons gradually thaw depressed dynasty trust (20.0 -> %.1f) and cap at baseline (%.1f)." % [
			thawed_trust, karluk_profile.trust_index])

	# 3. CouncilEventEngine Stack Cap, Loyalty Decay & Coalition Sync
	CouncilEventEngine.step_seasonal_council_decay(20)
	CommandBus.dispatch(DepositResourcesCommand.new(1701, &"steel", 20))
	CommandBus.dispatch(DepositResourcesCommand.new(1701, &"silver_gold", 100))
	CommandBus.dispatch(ModifyKutCommand.new(20.0 - GameManager.get_kut_score(), &"p17_council_sac_setup"))
	CommandBus.dispatch(EnactCouncilDecreeCommand.new(1701, GameEnums.CouncilDilemmaChoice.SACRIFICE))
	CommandBus.dispatch(ModifyKutCommand.new(75.0 - GameManager.get_kut_score(), &"p17_council_sac_restore"))
	var loy_after_sac: float = CouncilEventEngine.get_popular_loyalty_bonus()
	CouncilEventEngine.step_seasonal_council_decay(4)
	var loy_decayed: float = CouncilEventEngine.get_popular_loyalty_bonus()
	CouncilEventEngine.step_seasonal_council_decay(10)
	_expect(loy_after_sac >= 30.0 and loy_decayed < loy_after_sac and is_zero_approx(CouncilEventEngine.get_popular_loyalty_bonus()),
		"Council popular loyalty bonus decays across peaceful post-crisis seasons (%.1f -> %.1f -> 0.0)." % [
			loy_after_sac, loy_decayed])

	for _spy_i: int in range(15):
		CommandBus.dispatch(DispatchSpyCommand.new(1, 2, 1710 + _spy_i, 95.0, forest, 70.0, GameEnums.TuranTacticPhase.CRESCENT_ENCIRCLEMENT_TRAP, GameEnums.TacticalDoctrineType.CRESCENT_ENCIRCLEMENT, 0.0, 1))
	var capped_adv: int = CouncilEventEngine.get_espionage_advantage_count()
	CouncilEventEngine.step_seasonal_council_decay(12)
	DiplomacyManager.evaluate_all_dynasties(75.0, 1000.0, 0.2)
	var synced_sev: Dictionary[StringName, float] = CouncilEventEngine.evaluate_council_crisis_severity_with_context(25.0, false, false, 0.0)
	_expect(capped_adv <= 12 and CouncilEventEngine.get_espionage_advantage_count() == 0 \
		and is_zero_approx(synced_sev[&"coalition_weight"]),
		"CouncilEventEngine caps espionage stacks (%d <= 12), cools to 0, and syncs cleared coalition weight." % capped_adv)

	# 4. IntelligenceManager Total War Auto-Truce & Bounded Spy Cache
	var envoy_war: AssassinateEnvoyCommand = AssassinateEnvoyCommand.new(1710, 1711, &"p17_envoy_war_a")
	_expect(CommandBus.dispatch(envoy_war) and IntelligenceManager.is_total_war_active(1710, 1711),
		"Envoy execution escalates factions (1710, 1711) into Total War.")
	IntelligenceManager.step_seasonal_intelligence_decay(7)
	var still_at_war_7: bool = IntelligenceManager.is_total_war_active(1710, 1711)
	IntelligenceManager.step_seasonal_intelligence_decay(1)
	var settled_at_war_8: bool = IntelligenceManager.is_total_war_active(1710, 1711)
	_expect(still_at_war_7 and not settled_at_war_8 \
		and CommandBus.dispatch(AssassinateEnvoyCommand.new(1710, 1711, &"p17_envoy_war_b")),
		"Prolonged Total War auto-resolves to TRUCE after 8 seasons, unlocking later diplomacy.")
	IntelligenceManager.establish_truce(1710, 1711)

	for _cache_i: int in range(135):
		CommandBus.dispatch(DispatchSpyCommand.new(1, 2, 17200 + _cache_i, 99.0, forest, 60.0, GameEnums.TuranTacticPhase.FEIGNED_RETREAT_LURE, GameEnums.TacticalDoctrineType.FEIGNED_RETREAT, 0.0, 1))
	var cached_during_flood: int = IntelligenceManager.get_cached_report_count()
	IntelligenceManager.step_seasonal_intelligence_decay(IntelligenceManager.REPORT_STALENESS_SEASONS)
	_expect(cached_during_flood <= IntelligenceManager.MAX_CACHED_ARMY_REPORTS \
		and IntelligenceManager.get_cached_report_count() == 0 \
		and IntelligenceManager.get_latest_report_for_army(17334) == null,
		"IntelligenceManager caps report cache (%d <= %d) and expires stale reports after 8 seasons." % [
			cached_during_flood, IntelligenceManager.MAX_CACHED_ARMY_REPORTS])

	# 5. KinshipIntrigueManager Anti-Oscillation & Organic Healing Cleanup + CommandBus & Glory
	var nan_intrigue: StepKinshipIntrigueCommand = StepKinshipIntrigueCommand.new(&"p17_osc_bey", false, false, NAN, 0)
	CommandBus.dispatch(nan_intrigue)
	var osc_lord: KinshipLordRecord = KinshipIntrigueManager.get_or_create_lord(&"p17_osc_bey")
	_expect(not is_nan(osc_lord.ambition) and not is_nan(osc_lord.loyalty),
		"KinshipIntrigueManager ignores NaN ambition_override cleanly.")

	CommandBus.dispatch(ModifyKutCommand.new(75.0 - GameManager.get_kut_score(), &"p17_kinship_base"))
	CommandBus.dispatch(StepKinshipIntrigueCommand.new(&"p17_osc_bey", true, true, 82.0, 0))
	CommandBus.dispatch(StepKinshipIntrigueCommand.new(&"p17_osc_bey", true, true, 82.0, 0))
	var kut_after_first_uprising: float = GameManager.get_kut_score()
	CommandBus.dispatch(StepKinshipIntrigueCommand.new(&"p17_osc_bey", true, true, 70.0, 0))
	var dipped_to_stage2: bool = KinshipIntrigueManager.get_lord_plot_stage(&"p17_osc_bey") == GameEnums.IntriguePlotStage.DEFECTION_OR_SABOTAGE
	CommandBus.dispatch(StepKinshipIntrigueCommand.new(&"p17_osc_bey", true, true, 85.0, 0))
	var reentered_stage3: bool = KinshipIntrigueManager.get_lord_plot_stage(&"p17_osc_bey") == GameEnums.IntriguePlotStage.INTERNAL_UPRISING
	var kut_after_reentry: float = GameManager.get_kut_score()
	_expect(dipped_to_stage2 and reentered_stage3 and is_equal_approx(kut_after_reentry, kut_after_first_uprising),
		"Stage 2 <-> 3 ambition oscillation does not double-drain uprising Kut penalty.")

	for _heal_i: int in range(18):
		CommandBus.dispatch(StepKinshipIntrigueCommand.new(&"p17_osc_bey", false, false, -1.0, 0))
	_expect(osc_lord.plot_stage == GameEnums.IntriguePlotStage.LOYAL_CALM \
		and osc_lord.defected_troops == 0 \
		and not osc_lord.supply_sabotaged \
		and not osc_lord.uprising_kut_applied,
		"Organic healing back to LOYAL_CALM clears defected_troops, supply_sabotaged, and uprising_kut_applied.")

	var nan_toy: DistributeToyLootCommand = DistributeToyLootCommand.new(&"p17_rebel_bey", NAN, 0.0, false)
	_expect(not CommandBus.dispatch(nan_toy),
		"CommandBus rejects NaN Toy loot distribution cleanly.")

	CommandBus.dispatch(SplitDetachForceCommand.new(1740, 1741, GameEnums.DetachmentRole.FAST_CAVALRY_RECON_RAIDER, 80))
	CommandBus.dispatch(InterdictSupplyLineCommand.new(1741, 1, &"p17_raider"))
	var iso_before_merge: bool = CommandBus.is_army_supply_isolated(1741)
	CommandBus.dispatch(MergeForcesCommand.new(1740, 1741))
	_expect(iso_before_merge and not CommandBus.is_army_supply_isolated(1741),
		"Merging detached army erases stale _isolated_armies status for the dissolved detachment.")

	var glory_comp: GloryComponent = GloryComponent.new()
	add_child(glory_comp)
	glory_comp.configure(1750, rules, 1)
	CommandBus.dispatch(AssassinateEnvoyCommand.new(20, 21, &"p17_third_party_envoy"))
	CommandBus.dispatch(DispatchSpyCommand.new(20, 21, 1755, 99.0, forest, 75.0, GameEnums.TuranTacticPhase.FEIGNED_RETREAT_LURE, GameEnums.TacticalDoctrineType.FEIGNED_RETREAT, 0.0, 1))
	_expect(is_zero_approx(glory_comp.get_glory_score()),
		"GloryComponent ignores third-party faction (20 != 1) envoy assassinations and spy reports.")
	IntelligenceManager.establish_truce(20, 21)

	glory_comp.record_successful_turan_tactic()
	glory_comp.record_successful_turan_tactic()
	glory_comp.record_successful_turan_tactic()
	CommandBus.dispatch(DistributeToyLootCommand.new(&"p17_rebel_bey", 1000.0, 0.0, false))
	CommandBus.dispatch(DistributeToyLootCommand.new(&"p17_rebel_bey", 1000.0, 0.0, false))
	var first_rec: int = glory_comp.recruit_rogue_warband(&"p17_rebel_bey")
	CommandBus.dispatch(DistributeToyLootCommand.new(&"p17_rebel_bey", 1000.0, 0.0, false))
	CommandBus.dispatch(DistributeToyLootCommand.new(&"p17_rebel_bey", 1000.0, 0.0, false))
	var second_rec: int = glory_comp.recruit_rogue_warband(&"p17_rebel_bey")
	_expect(first_rec == rules.rogue_warband_troop_size \
		and second_rec == rules.rogue_warband_troop_size \
		and glory_comp.get_recruited_warbands().size() == 1 \
		and glory_comp.get_recruited_troops() == rules.rogue_warband_troop_size * 2,
		"Re-rebelling and re-recruiting rogue warband deduplicates warband names cleanly without blocking repeat integration.")
	glory_comp.free()

	for _ai_i: int in range(35):
		CommandBus.dispatch(StepAICommanderCommand.new(&"p17_cap_agent", false, 0, 0))
	_expect(AICommander.get_agent_stockpile(&"p17_cap_agent") <= AICommander.MAX_AGENT_STOCKPILE,
		"AICommander agent stockpile respects bounded ceiling (<= 5000.0).")

	var sov_nan: EvaluateSovereigntyPathCommand = EvaluateSovereigntyPathCommand.new(1790, NAN, INF)
	_expect(CommandBus.dispatch(sov_nan) and not is_nan(sov_nan.dominant_score) and sov_nan.dominant_score >= 0.0,
		"SovereigntyPathEngine sanitizes NaN/INF Kut and Glory telemetry inputs.")

	# 6. 36-Season (9-Year) Multi-Profile Long-Horizon Stress Test
	var bal36: LongHorizonSimulator.SimulationRunResult = LongHorizonSimulator.run(
		self, LongHorizonSimulator.SimulationProfile.BALANCED_NOMAD, 36, 17001, 5)
	var bal36_end: SimulationInvariantChecker.SeasonSnapshot = bal36.latest()
	_expect(bal36.seasons_simulated == 36 and bal36.passed() and bal36_end != null,
		"BALANCED_NOMAD 36-season (9-year) marathon passes all invariants (violations: %s)." % ", ".join(bal36.violations))

	var crisis36: LongHorizonSimulator.SimulationRunResult = LongHorizonSimulator.run(
		self, LongHorizonSimulator.SimulationProfile.CRISIS_CLAN, 36, 17002, 6)
	var crisis36_end: SimulationInvariantChecker.SeasonSnapshot = crisis36.latest()
	var crisis36_ok: bool = crisis36.seasons_simulated == 36 and crisis36.passed() and crisis36_end != null \
		and crisis36.min_kut_observed < 30.0 \
		and crisis36_end.kut >= 45.0 \
		and not crisis36_end.council_active \
		and not crisis36_end.coalition_war_active \
		and crisis36_end.kinship_stage == GameEnums.IntriguePlotStage.LOYAL_CALM
	_expect(crisis36_ok,
		"CRISIS_CLAN 36-season (9-year) marathon recovers from early crisis to stable Kut (%.1f -> %.1f), ended council/coalition, and LOYAL_CALM kinship (violations: %s)." % [
			crisis36.min_kut_observed,
			crisis36_end.kut if crisis36_end != null else -1.0,
			", ".join(crisis36.violations)])

	# Restore clean singleton state before remaining tests
	CommandBus.dispatch(ModifyKutCommand.new(75.0 - GameManager.get_kut_score(), &"p17_cleanup_restore"))
	DiplomacyManager.step_seasonal_diplomatic_decay(15)
	CouncilEventEngine.step_seasonal_council_decay(15)
	IntelligenceManager.step_seasonal_intelligence_decay(10)
	CausalChainEngine.reset_continuous_state()


func _test_phase18_persistent_world_peace_and_anti_snowball() -> void:
	var forest: TerrainData = ResourceLoader.load("res://data/terrain/forest.tres") as TerrainData
	var steppe: TerrainData = ResourceLoader.load("res://data/terrain/steppe.tres") as TerrainData
	var doctrine: TacticalDoctrineData = ResourceLoader.load("res://data/tactics/feigned_retreat.tres") as TacticalDoctrineData
	var rules: PersistentWorldRules = GracePeriodManager.get_rules()

	# 1. Graduated 3-Stage Töre Barışı (Kurultay Barışı)
	GracePeriodManager.configure_persistent_world(true, 0.0)
	var p1_spawn: Vector2i = GracePeriodManager.register_player(1801, false, Vector2i(12, 12), 1)
	var p2_spawn: Vector2i = GracePeriodManager.register_player(1802, false, Vector2i(12, 12), 2)
	_expect(p1_spawn != Vector2i.ZERO and p2_spawn != Vector2i.ZERO \
		and GracePeriodManager.get_global_stage() == GameEnums.TorePeaceStage.STAGE_1_FULL_TORE_PEACE,
		"Server Day 1 opens in STAGE_1_FULL_TORE_PEACE.")
	_expect(GracePeriodManager.can_perform_action(1801, GameEnums.ToreActionType.SCOUTING) \
		and GracePeriodManager.can_perform_action(1801, GameEnums.ToreActionType.NPC_CLEANUP, 0) \
		and GracePeriodManager.can_perform_action(1801, GameEnums.ToreActionType.UNCLAIMED_NODE_TUG, 0) \
		and GracePeriodManager.can_perform_action(1801, GameEnums.ToreActionType.REFINING) \
		and GracePeriodManager.can_perform_action(1801, GameEnums.ToreActionType.ESPIONAGE, 1802),
		"Day 1-2 Töre Peace permits scouting, NPC cleanup, unclaimed node Tuğ, refining, and espionage.")
	_expect(not GracePeriodManager.can_perform_action(1801, GameEnums.ToreActionType.BORDER_NODE_RAID, 1802) \
		and not GracePeriodManager.can_perform_action(1801, GameEnums.ToreActionType.CORE_YURT_CLAIM, 1802) \
		and not GracePeriodManager.can_perform_action(1801, GameEnums.ToreActionType.KURGAN_CONTEST, 1802) \
		and not GracePeriodManager.can_perform_action(1801, GameEnums.ToreActionType.PLAYER_ATTACK, 1802),
		"Day 1-2 Töre Peace strictly locks inter-player attacks, border raids, core Yurt claims, and Kurgan contests.")

	# Advance to Day 3 (48h..72h): Border skirmishes open, core Oba/Yurt and Kurgan stay locked
	var stage_day3: GameEnums.TorePeaceStage = GracePeriodManager.advance_world_hours(50.0)
	_expect(stage_day3 == GameEnums.TorePeaceStage.STAGE_2_BORDER_SKIRMISH \
		and GracePeriodManager.can_perform_action(1801, GameEnums.ToreActionType.BORDER_NODE_RAID, 1802) \
		and not GracePeriodManager.can_perform_action(1801, GameEnums.ToreActionType.CORE_YURT_CLAIM, 1802) \
		and not GracePeriodManager.can_perform_action(1801, GameEnums.ToreActionType.KURGAN_CONTEST, 1802) \
		and not GracePeriodManager.can_perform_action(1801, GameEnums.ToreActionType.PLAYER_ATTACK, 1802),
		"Day 3 Stage 2 opens Border Node cavalry skirmishes while keeping core Yurts & Sacred Kurgans protected.")

	# Advance to Day 4+ (72h+): Full steppe conquest unlocks
	var stage_day4: GameEnums.TorePeaceStage = GracePeriodManager.advance_world_hours(25.0)
	_expect(stage_day4 == GameEnums.TorePeaceStage.STAGE_3_TOTAL_STEPPE \
		and GracePeriodManager.can_perform_action(1801, GameEnums.ToreActionType.CORE_YURT_CLAIM, 1802) \
		and GracePeriodManager.can_perform_action(1801, GameEnums.ToreActionType.KURGAN_CONTEST, 1802) \
		and GracePeriodManager.can_perform_action(1801, GameEnums.ToreActionType.PLAYER_ATTACK, 1802),
		"Day 4+ Stage 3 opens all Yurt claims, Kurgan conquests, and total steppe war.")

	# 2. Late-Joiner Uç Beyi Outer Rim Spawn & Anti-Exploit Personal Peace Forfeit
	var late_coord: Vector2i = GracePeriodManager.register_player(1803, true, Vector2i(12, 12), 9)
	_expect(GracePeriodManager.is_outer_rim_coord(late_coord, Vector2i(12, 12)) \
		and GracePeriodManager.has_active_personal_peace(1803) \
		and GracePeriodManager.get_remaining_personal_peace_hours(1803) >= 47.9 \
		and not GracePeriodManager.can_perform_action(1801, GameEnums.ToreActionType.PLAYER_ATTACK, 1803),
		"Late-joiner spawns on outer rim Uç Beyi border (%s) and receives 48h personal peace shielding against attacks." % late_coord)

	# Late-joiner initiating hostile espionage immediately forfeits personal 48h Töre Peace
	var forfeit_events: Array[StringName] = []
	var on_forfeit: Callable = func(pid: int, reason: StringName) -> void:
		if pid == 1803:
			forfeit_events.append(reason)
	EventBus.personal_tore_peace_forfeited.connect(on_forfeit)
	CommandBus.dispatch(DispatchSpyCommand.new(1803, 1801, 1899, 80.0, forest, 60.0, GameEnums.TuranTacticPhase.RECON_DUST_SCREEN, GameEnums.TacticalDoctrineType.FEIGNED_RETREAT, 0.0, 1))
	EventBus.personal_tore_peace_forfeited.disconnect(on_forfeit)
	_expect(not GracePeriodManager.has_active_personal_peace(1803) \
		and forfeit_events.has(&"hostile_espionage_break") \
		and GracePeriodManager.can_perform_action(1801, GameEnums.ToreActionType.PLAYER_ATTACK, 1803),
		"Personal 48h Töre Peace is immediately forfeited when late-joiner dispatches hostile espionage against another player.")

	# 3. Non-Linear Exponential Upkeep, Day-1 Spoilage & Passive Stagnation Kut Erosion
	var exp_100: float = rules.compute_exponential_consumption(10.0, 100)
	var exp_1000: float = rules.compute_exponential_consumption(10.0, 1000)
	var expected_1000: float = 10.0 * (1.0 + 0.002 * pow(1000.0, 1.25))
	_expect(is_equal_approx(exp_1000, expected_1000) and exp_1000 > exp_100 * 5.0,
		"Exponential upkeep follows exact non-linear power law (100u=%.2f vs 1000u=%.2f)." % [exp_100, exp_1000])

	# Day 1 active spoilage, upkeep & pasture depletion (even while in Stage 1 Töre Peace!)
	GracePeriodManager.configure_persistent_world(true, 10.0)
	SeasonManager.set_food_reserve(200)
	CommandBus.dispatch(ModifyKutCommand.new(80.0 - GameManager.get_kut_score(), &"p18_kut_baseline"))
	CommandBus.dispatch(DepositResourcesCommand.new(1804, &"steel", 80))
	CommandBus.dispatch(DepositResourcesCommand.new(1804, &"iron", 120))
	CommandBus.dispatch(DepositResourcesCommand.new(1804, &"jade", 40))
	CommandBus.dispatch(DepositResourcesCommand.new(1804, &"meteoric_iron", 15))
	var jade_before: int = ResourceManager.get_amount(1804, &"jade")
	var meteor_before: int = ResourceManager.get_amount(1804, &"meteoric_iron")
	var steel_before: int = ResourceManager.get_amount(1804, &"steel")

	var upkeep_cmd: StepAntiSnowballTickCommand = StepAntiSnowballTickCommand.new(1804, 2.0, 1000, 600, 350, Vector2i(88, 1), false)
	var upkeep_cmd_2: StepAntiSnowballTickCommand = StepAntiSnowballTickCommand.new(1804, 2.5, 1000, 600, 350, Vector2i(88, 1), false)
	_expect(CommandBus.dispatch(upkeep_cmd) and CommandBus.dispatch(upkeep_cmd_2),
		"StepAntiSnowballTickCommand executes cleanly during Day 1 Töre Peace.")
	_expect(SeasonManager.get_food_reserve() < 200 \
		and upkeep_cmd.food_spoiled > 0 \
		and ResourceManager.get_amount(1804, &"steel") < steel_before \
		and ResourceManager.get_amount(1804, &"jade") == jade_before \
		and ResourceManager.get_amount(1804, &"meteoric_iron") == meteor_before \
		and PastureEcologyManager.get_region_pasture_capacity(Vector2i(88, 1)) < 100.0 \
		and upkeep_cmd_2.kut_stagnation_drain > 0.0 \
		and GameManager.get_kut_score() < 80.0,
		"Day-1 anti-snowball physics spoils Food, drains Steel/Iron maintenance & exponential pasture, erodes stagnant Kut, and leaves Jade/Meteoric Iron 100%% immune.")

	# 4. OfflineDoctrineComponent (Enemy Power Ratio >= 1.5 -> Pack Sefer Arabası + Feigned Retreat to Sık Orman)
	var offline_comp: OfflineDoctrineComponent = OfflineDoctrineComponent.new()
	var offline_tactics: TuranTacticsComponent = TuranTacticsComponent.new()
	add_child(offline_comp)
	add_child(offline_tactics)
	offline_comp.configure(1805, 1.5, GameEnums.TerrainClass.SIK_ORMAN)
	offline_tactics.configure(1805, doctrine, 100.0)
	var candidates: Array[TerrainData] = [steppe, forest]

	var calm_watch: OfflineDoctrineDecision = offline_comp.evaluate_doctrine(200.0, 220.0, 1.0, offline_tactics, candidates, false)
	var outnumbered_watch: OfflineDoctrineDecision = offline_comp.evaluate_doctrine(200.0, 340.0, 1.0, offline_tactics, candidates, false)
	_expect(not calm_watch.triggered \
		and outnumbered_watch.triggered \
		and outnumbered_watch.trigger_reason == GameEnums.OfflineDoctrineTrigger.ENEMY_POWER_RATIO_EXCEEDED \
		and outnumbered_watch.evade_combat \
		and outnumbered_watch.packed_sefer_arabasi \
		and outnumbered_watch.activated_feigned_retreat \
		and outnumbered_watch.retreat_target_terrain_class == GameEnums.TerrainClass.SIK_ORMAN \
		and outnumbered_watch.target_terrain == forest \
		and offline_tactics.get_current_phase() == GameEnums.TuranTacticPhase.FEIGNED_RETREAT_LURE,
		"OfflineDoctrineComponent stays standby at 1.1x ratio and executes Sefer Arabası + Feigned Retreat into Sık Orman when enemy ratio >= 1.5x.")

	offline_tactics.free()
	offline_comp.free()
	GracePeriodManager.reset_persistent_world()
	SeasonManager.set_food_reserve(120)
	CommandBus.dispatch(ModifyKutCommand.new(75.0 - GameManager.get_kut_score(), &"p18_cleanup_restore"))



