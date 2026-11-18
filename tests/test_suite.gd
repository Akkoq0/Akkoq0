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
	_test_main_scene_integration()

	if _failures.is_empty():
		print("[PASS] Ötüken Phase 1 + Phase 2 + Phase 3 Ultra + Phase 4 Deep + Phase 5 Dynasty validation succeeded (%d assertions, 0 failures)." % _assertions)
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


