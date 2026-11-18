extends Node
## Headless integration & architectural test suite (rank 4).
##
## Run with: `godot --headless --path . res://tests/test_suite.tscn`

var _failures: PackedStringArray = PackedStringArray()
var _assertions: int = 0


func _ready() -> void:
	_run_suite.call_deferred()


func _run_suite() -> void:
	_test_architecture_governance()
	_test_ore_registry_and_economy()
	_test_buildings_nomadic_and_roi()
	_test_totems_100_point_asymmetry()
	_test_world_macro_and_micro_generation()
	_test_army_weight_mobility_and_supply()
	_test_combat_calculator()
	_test_camera_profile_and_layer_switch()
	_test_main_scene_integration()

	if _failures.is_empty():
		print("[PASS] Ötüken Phase 1 validation succeeded (%d assertions, 0 failures)." % _assertions)
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


func _test_buildings_nomadic_and_roi() -> void:
	var ger: BuildingData = ResourceLoader.load("res://data/buildings/ger_camp.tres") as BuildingData
	var forge: BuildingData = ResourceLoader.load("res://data/buildings/nomadic_forge.tres") as BuildingData
	var quarry: BuildingData = ResourceLoader.load("res://data/buildings/quarry.tres") as BuildingData
	var kurgan: BuildingData = ResourceLoader.load("res://data/buildings/kurgan_shrine.tres") as BuildingData

	_expect(ger.is_nomadic_movable and ger.is_supply_depot(), "Ger camp is nomadic movable and a supply depot.")
	_expect(forge.is_nomadic_movable and forge.get_net_income_per_minute() > 0.0, "Nomadic forge has positive net income.")
	_expect(not quarry.is_nomadic_movable and is_inf(quarry.get_relocation_time_sec()), "Static quarry has INF relocation time.")
	_expect(kurgan.is_supply_depot() and kurgan.get_payback_minutes() < INF, "Kurgan shrine has finite ROI payback.")
	_expect(forge.get_roi_ratio(20.0) > 0.0, "Nomadic forge 20-minute ROI is positive.")


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

	var cmd_steppe: ResolveCombatCommand = ResolveCombatCommand.new(attacker, defender, steppe, 42)
	var cmd_mountain: ResolveCombatCommand = ResolveCombatCommand.new(attacker, defender, mountain, 42)
	_expect(CommandBus.dispatch(cmd_steppe) and CommandBus.dispatch(cmd_mountain), "ResolveCombatCommand dispatches.")
	_expect(cmd_mountain.result.damage_to_defender < cmd_steppe.result.damage_to_defender,
		"Mountain defense multiplier reduces damage taken by defender.")


func _test_camera_profile_and_layer_switch() -> void:
	var cam_profile: CameraProfile = ResourceLoader.load("res://data/camera/camera_profile.tres") as CameraProfile
	_expect(cam_profile != null and is_equal_approx(cam_profile.transition_duration_sec, 0.4),
		"CameraProfile specifies 0.4s cloud transition.")


func _test_main_scene_integration() -> void:
	var main_packed: PackedScene = ResourceLoader.load("res://scenes/main.tscn") as PackedScene
	var main_instance: Node = main_packed.instantiate()
	add_child(main_instance)
	var move_cmd: MoveArmyCommand = MoveArmyCommand.new(1, Vector3(4.0, 0.0, 4.0))
	_expect(CommandBus.dispatch(move_cmd), "MoveArmyCommand routed to VanguardArmy via ArmyRegistry.")
	main_instance.free()
