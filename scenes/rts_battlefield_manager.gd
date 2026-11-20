class_name RtsBattlefieldManager
extends Node3D
## Live RTS Battlefield Manager (rank 4).
## Drives real-time economy, touch/mouse building placement, unit training,
## army selection/movement/pursuit, CombatCalculator damage + floating numbers/VFX,
## active Enemy AI opponent, Minimap syncing, and ENet LAN RPC synchronization.

const MAP_HALF_EXTENT: float = 58.0
const ECON_TICK_SEC: float = 5.0
const AI_THINK_SEC: float = 1.5
const AGGRO_RADIUS: float = 19.0
const ARCHER_RANGE: float = 16.0
const MELEE_RANGE: float = 4.6
const DEFAULT_CAMERA_ORIGIN_Y: float = 0.0

class FactionEconomy:
	extends RefCounted
	var player_id: int = 1
	var food: int = 320
	var silver: int = 260
	var steel: int = 150
	var stone: int = 360
	var pop_used: int = 0
	var pop_cap: int = 10
	var food_rate: int = 0
	var silver_rate: int = 0
	var steel_rate: int = 0
	var stone_rate: int = 0

	func _init(p_id: int) -> void:
		player_id = p_id


class RtsBuildingEntity:
	extends RefCounted
	var entity_id: int = 0
	var owner_id: int = 1
	var building_id: StringName = &"ger_camp"
	var display_name: String = "Otağ"
	var is_hq: bool = false
	var can_train: bool = false
	var hp: float = 600.0
	var max_hp: float = 600.0
	var world_pos: Vector3 = Vector3.ZERO
	var radius: float = 3.2
	var build_progress: float = 1.0
	var node_root: Node3D = null
	var hp_bar: Node3D = null
	var sel_ring: MeshInstance3D = null


class RtsUnitEntity:
	extends RefCounted
	var entity_id: int = 0
	var owner_id: int = 1
	var unit_id: StringName = &"horse_archer"
	var display_name: String = "Atlı Okçu"
	var hp: float = 110.0
	var max_hp: float = 110.0
	var attack: float = 18.0
	var defense: float = 10.0
	var speed: float = 12.0
	var attack_range: float = 16.0
	var attack_cooldown: float = 1.3
	var cooldown_timer: float = 0.0
	var is_ranged: bool = true
	var is_support: bool = false
	var world_pos: Vector3 = Vector3.ZERO
	var move_target: Vector3 = Vector3.ZERO
	var has_move_order: bool = false
	var target_entity_id: int = 0
	var hold_position: bool = false
	var dust_timer: float = 0.0
	var node_root: Node3D = null
	var hp_bar: Node3D = null
	var sel_ring: MeshInstance3D = null


class RtsProjectileFx:
	extends RefCounted
	var mesh: MeshInstance3D = null
	var start_pos: Vector3 = Vector3.ZERO
	var end_pos: Vector3 = Vector3.ZERO
	var elapsed: float = 0.0
	var duration: float = 0.35


class RtsTempFx:
	extends RefCounted
	var node: Node3D = null
	var velocity: Vector3 = Vector3.ZERO
	var elapsed: float = 0.0
	var duration: float = 0.8
	var is_ring: bool = false


var _building_data: Dictionary[StringName, BuildingData] = {}
var _unit_data: Dictionary[StringName, UnitData] = {}
var _economies: Dictionary[int, FactionEconomy] = {}
var _buildings: Dictionary[int, RtsBuildingEntity] = {}
var _units: Dictionary[int, RtsUnitEntity] = {}
var _projectiles: Array[RtsProjectileFx] = []
var _temp_fx: Array[RtsTempFx] = []

var _next_entity_id: int = 100
var _local_player_id: int = 1
var _match_over: bool = false
var _sim_time: float = 0.0
var _econ_accum: float = 0.0
var _ai_accum: float = 0.0
var _hud_accum: float = 0.0
var _ai_raids_sent: int = 0
var _battles_fought: int = 0
var _buildings_built_count: Dictionary[int, int] = {1: 0, 2: 0}
var _units_trained_count: Dictionary[int, int] = {1: 0, 2: 0}

var _selected_building_id: int = 0
var _selected_unit_id: int = 0
var _placing_building_id: StringName = &""
var _preview_node: Node3D = null
var _preview_mat: StandardMaterial3D = null
var _path_line_mesh: MeshInstance3D = null

var _hud_ref: WeakRef = null
var _cam_ref: WeakRef = null
var _height_sampler: Callable = Callable()
var _passability_sampler: Callable = Callable()
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _entities_root: Node3D = null
var _fx_root: Node3D = null
var _headless_mode: bool = false


func _ready() -> void:
	name = "RtsBattlefieldManager"
	_headless_mode = DisplayServer.get_name().to_lower().contains("headless")
	_rng.seed = MatchSessionConfig.world_seed
	_entities_root = Node3D.new()
	_entities_root.name = "EntitiesRoot"
	add_child(_entities_root)
	_fx_root = Node3D.new()
	_fx_root.name = "FxRoot"
	add_child(_fx_root)
	_load_templates()
	_build_preview_and_path_nodes()


func setup_match(
		hud: MobileRtsHud,
		cam: DualLayerCamera,
		p_height_sampler: Callable = Callable(),
		p_passability_sampler: Callable = Callable()) -> void:
	_hud_ref = weakref(hud) if hud != null else null
	_cam_ref = weakref(cam) if cam != null else null
	_height_sampler = p_height_sampler
	_passability_sampler = p_passability_sampler
	_local_player_id = MatchSessionConfig.local_player_id if MatchSessionConfig.is_multiplayer_session() else 1

	if hud != null:
		if not hud.build_requested.is_connected(_on_hud_build_requested):
			hud.build_requested.connect(_on_hud_build_requested)
		if not hud.build_cancelled.is_connected(_on_hud_build_cancelled):
			hud.build_cancelled.connect(_on_hud_build_cancelled)
		if not hud.train_unit_requested.is_connected(_on_hud_train_requested):
			hud.train_unit_requested.connect(_on_hud_train_requested)
		if not hud.army_order_requested.is_connected(_on_hud_army_order):
			hud.army_order_requested.connect(_on_hud_army_order)
		if not hud.replay_requested.is_connected(_on_replay_requested):
			hud.replay_requested.connect(_on_replay_requested)

	_reset_match_entities()


func _process(delta: float) -> void:
	if _match_over:
		return
	step_simulation(delta)


func step_simulation(delta: float) -> void:
	if _match_over or delta <= 0.0:
		return
	var dt: float = minf(delta, 0.25)
	_sim_time += dt

	# 1. Construction rise animation
	for bid: int in _buildings.keys():
		var b: RtsBuildingEntity = _buildings[bid]
		if b.build_progress < 1.0:
			b.build_progress = minf(b.build_progress + dt * 1.4, 1.0)
			if b.node_root != null:
				b.node_root.scale = Vector3(1.0, lerpf(0.25, 1.0, b.build_progress), 1.0)

	# 2. Economy cycle
	_econ_accum += dt
	if _econ_accum >= ECON_TICK_SEC:
		_econ_accum -= ECON_TICK_SEC
		_tick_economy()

	# 3. Active AI Opponent (in Singleplayer)
	if not MatchSessionConfig.is_multiplayer_session():
		_ai_accum += dt
		if _ai_accum >= AI_THINK_SEC:
			_ai_accum -= AI_THINK_SEC
			_tick_enemy_ai()

	# 4. Unit movement, targeting, & combat
	_tick_units(dt)

	# 5. Visual projectiles & temporary FX
	_tick_fx(dt)

	# 6. HUD + Minimap sync
	_hud_accum += dt
	if _hud_accum >= 0.25:
		_hud_accum = 0.0
		_sync_hud_and_minimap()
		_update_path_trail()


func _unhandled_input(event: InputEvent) -> void:
	if _match_over:
		return
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if mb != null and mb.pressed:
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			if _placing_building_id != &"":
				_cancel_placement()
				_mark_handled()
				return
			var hit_r: Vector3 = _raycast_terrain(mb.position)
			if not is_inf(hit_r.x) and _selected_unit_id > 0:
				_handle_world_action_on_unit(hit_r)
				_mark_handled()
				return
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			var hit_l: Vector3 = _raycast_terrain(mb.position)
			if is_inf(hit_l.x):
				return
			if _placing_building_id != &"":
				_try_confirm_placement(hit_l)
				_mark_handled()
				return
			if _handle_world_left_click(hit_l):
				_mark_handled()
				return

	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion != null and _placing_building_id != &"":
		var hover_pos: Vector3 = _raycast_terrain(motion.position)
		if not is_inf(hover_pos.x):
			_update_preview_transform(hover_pos)


func _get_hud() -> MobileRtsHud:
	if _hud_ref == null:
		return null
	var obj: Object = _hud_ref.get_ref()
	if obj != null and is_instance_valid(obj):
		return obj as MobileRtsHud
	return null


func _get_cam() -> DualLayerCamera:
	if _cam_ref == null:
		return null
	var obj: Object = _cam_ref.get_ref()
	if obj != null and is_instance_valid(obj):
		return obj as DualLayerCamera
	return null


func get_height_at(wx: float, wz: float) -> float:
	if _height_sampler.is_valid():
		var val: Variant = _height_sampler.call(wx, wz)
		return DeterministicStateHasher.v_float(val, DEFAULT_CAMERA_ORIGIN_Y)
	return DEFAULT_CAMERA_ORIGIN_Y


func is_passable_at(wx: float, wz: float) -> bool:
	if absf(wx) > MAP_HALF_EXTENT or absf(wz) > MAP_HALF_EXTENT:
		return false
	if _passability_sampler.is_valid():
		var val: Variant = _passability_sampler.call(wx, wz)
		return DeterministicStateHasher.v_bool(val, true)
	return true


func can_place_building_at(player_id: int, building_id: StringName, pos: Vector3) -> bool:
	if not is_passable_at(pos.x, pos.z):
		return false
	var bd: BuildingData = _building_data.get(building_id, null)
	if bd == null:
		return false
	if not _can_afford_building(player_id, building_id):
		return false
	# Slope check
	var h0: float = get_height_at(pos.x, pos.z)
	var hx: float = get_height_at(pos.x + 2.5, pos.z)
	var hz: float = get_height_at(pos.x, pos.z + 2.5)
	if absf(hx - h0) > 1.65 or absf(hz - h0) > 1.65:
		return false
	# Spacing check against buildings
	for bid: int in _buildings:
		var other: RtsBuildingEntity = _buildings[bid]
		if other.world_pos.distance_to(pos) < 7.5:
			return false
	return true


func issue_build_command(player_id: int, building_id: StringName, world_pos: Vector3) -> bool:
	if not can_place_building_at(player_id, building_id, world_pos):
		return false
	if MatchSessionConfig.is_multiplayer_session() and get_tree() != null and get_tree().get_multiplayer().multiplayer_peer != null:
		_rpc_place_building.rpc(player_id, String(building_id), world_pos)
		return true
	return _execute_place_building(player_id, building_id, world_pos)


func issue_train_command(player_id: int, unit_id: StringName, from_building_id: int) -> bool:
	if not _can_afford_unit(player_id, unit_id):
		return false
	var econ: FactionEconomy = _economies.get(player_id, null)
	if econ == null or econ.pop_used >= econ.pop_cap:
		return false
	var b: RtsBuildingEntity = _buildings.get(from_building_id, null)
	if b == null or b.owner_id != player_id:
		return false
	var spawn_pos: Vector3 = _find_free_rally_point(b.world_pos, player_id)
	if MatchSessionConfig.is_multiplayer_session() and get_tree() != null and get_tree().get_multiplayer().multiplayer_peer != null:
		_rpc_train_unit.rpc(player_id, String(unit_id), spawn_pos)
		return true
	return _execute_train_unit(player_id, unit_id, spawn_pos)


func issue_move_command(unit_entity_id: int, dest: Vector3) -> bool:
	var u: RtsUnitEntity = _units.get(unit_entity_id, null)
	if u == null:
		return false
	if MatchSessionConfig.is_multiplayer_session() and get_tree() != null and get_tree().get_multiplayer().multiplayer_peer != null:
		_rpc_order_move.rpc(unit_entity_id, dest)
		return true
	_execute_order_move(unit_entity_id, dest)
	return true


func issue_attack_command(unit_entity_id: int, target_entity_id: int) -> bool:
	var u: RtsUnitEntity = _units.get(unit_entity_id, null)
	if u == null:
		return false
	if MatchSessionConfig.is_multiplayer_session() and get_tree() != null and get_tree().get_multiplayer().multiplayer_peer != null:
		_rpc_order_attack.rpc(unit_entity_id, target_entity_id)
		return true
	_execute_order_attack(unit_entity_id, target_entity_id)
	return true


func get_economy(player_id: int) -> FactionEconomy:
	return _economies.get(player_id, null)


func get_building_count(player_id: int = -1) -> int:
	if player_id < 0:
		return _buildings.size()
	var cnt: int = 0
	for bid: int in _buildings:
		if _buildings[bid].owner_id == player_id:
			cnt += 1
	return cnt


func get_unit_count(player_id: int = -1) -> int:
	if player_id < 0:
		return _units.size()
	var cnt: int = 0
	for uid: int in _units:
		if _units[uid].owner_id == player_id:
			cnt += 1
	return cnt


func get_buildings_built_count(player_id: int) -> int:
	return _buildings_built_count[player_id] if _buildings_built_count.has(player_id) else 0


func get_units_trained_count(player_id: int) -> int:
	return _units_trained_count[player_id] if _units_trained_count.has(player_id) else 0


func get_battles_fought() -> int:
	return _battles_fought


func get_all_entity_y_errors() -> PackedStringArray:
	var errs: PackedStringArray = PackedStringArray()
	for bid: int in _buildings:
		var b: RtsBuildingEntity = _buildings[bid]
		var expected_y: float = get_height_at(b.world_pos.x, b.world_pos.z)
		if b.node_root != null and absf(b.node_root.position.y - expected_y) > 0.05:
			errs.append("Building %d Y mismatch: %.2f vs %.2f" % [bid, b.node_root.position.y, expected_y])
	for uid: int in _units:
		var u: RtsUnitEntity = _units[uid]
		var expected_y: float = get_height_at(u.world_pos.x, u.world_pos.z)
		if u.node_root != null and absf(u.node_root.position.y - expected_y) > 0.05:
			errs.append("Unit %d Y mismatch: %.2f vs %.2f" % [uid, u.node_root.position.y, expected_y])
	return errs


@rpc("any_peer", "call_local", "reliable")
func _rpc_place_building(player_id: int, b_id_str: String, world_pos: Vector3) -> void:
	_execute_place_building(player_id, StringName(b_id_str), world_pos)


@rpc("any_peer", "call_local", "reliable")
func _rpc_train_unit(player_id: int, u_id_str: String, spawn_pos: Vector3) -> void:
	_execute_train_unit(player_id, StringName(u_id_str), spawn_pos)


@rpc("any_peer", "call_local", "reliable")
func _rpc_order_move(unit_entity_id: int, dest: Vector3) -> void:
	_execute_order_move(unit_entity_id, dest)


@rpc("any_peer", "call_local", "reliable")
func _rpc_order_attack(unit_entity_id: int, target_entity_id: int) -> void:
	_execute_order_attack(unit_entity_id, target_entity_id)


func _reset_match_entities() -> void:
	for ch: Node in _entities_root.get_children():
		_entities_root.remove_child(ch)
		ch.queue_free()
	for ch: Node in _fx_root.get_children():
		_fx_root.remove_child(ch)
		ch.queue_free()
	_buildings.clear()
	_units.clear()
	_projectiles.clear()
	_temp_fx.clear()
	_economies.clear()
	_economies[1] = FactionEconomy.new(1)
	_economies[2] = FactionEconomy.new(2)
	_next_entity_id = 100
	_match_over = false
	_sim_time = 0.0
	_econ_accum = 0.0
	_ai_accum = 0.0
	_ai_raids_sent = 0
	_battles_fought = 0
	_buildings_built_count = {1: 0, 2: 0}
	_units_trained_count = {1: 0, 2: 0}
	_selected_building_id = 0
	_selected_unit_id = 0
	_placing_building_id = &""

	# Player 1 (Southwest) starting HQ + Starting Squadron
	var p1_hq_pos: Vector3 = Vector3(-34.0, 0.0, 34.0)
	_spawn_building(1, &"ger_camp", p1_hq_pos, true, true)
	_spawn_unit(1, &"horse_archer", p1_hq_pos + Vector3(5.5, 0.0, -4.0), true)

	# Player 2 / Enemy AI (Northeast) starting HQ + Nomadic Forge + Starting Squadron
	var p2_hq_pos: Vector3 = Vector3(34.0, 0.0, -34.0)
	_spawn_building(2, &"ger_camp", p2_hq_pos, true, true)
	_spawn_building(2, &"nomadic_forge", p2_hq_pos + Vector3(-8.5, 0.0, 6.5), false, true)
	_spawn_unit(2, &"horse_archer", p2_hq_pos + Vector3(-5.5, 0.0, 4.5), true)

	_recompute_rates()
	_sync_hud_and_minimap()

	var cam: DualLayerCamera = _get_cam()
	if cam != null:
		var focus: Vector3 = p1_hq_pos if _local_player_id == 1 else p2_hq_pos
		cam.focus_world_position(focus)

	var hud: MobileRtsHud = _get_hud()
	if hud != null:
		hud.set_context_build()


func _execute_place_building(player_id: int, building_id: StringName, world_pos: Vector3) -> bool:
	if not _spend_for_building(player_id, building_id):
		return false
	_spawn_building(player_id, building_id, world_pos, false, false)
	var cur_b: int = _buildings_built_count[player_id] if _buildings_built_count.has(player_id) else 0
	_buildings_built_count[player_id] = cur_b + 1
	_recompute_rates()
	if not _headless_mode and AudioDirector != null:
		AudioDirector.play_sfx(&"ui_click", &"SFX", 0.06)
	_sync_hud_and_minimap()
	return true


func _execute_train_unit(player_id: int, unit_id: StringName, spawn_pos: Vector3) -> bool:
	if not _spend_for_unit(player_id, unit_id):
		return false
	_spawn_unit(player_id, unit_id, spawn_pos, false)
	var cur_u: int = _units_trained_count[player_id] if _units_trained_count.has(player_id) else 0
	_units_trained_count[player_id] = cur_u + 1
	_recompute_rates()
	if not _headless_mode and AudioDirector != null:
		AudioDirector.play_sfx(&"march_hooves", &"SFX", 0.05)
	_sync_hud_and_minimap()
	return true


func _execute_order_move(unit_entity_id: int, dest: Vector3) -> void:
	var u: RtsUnitEntity = _units.get(unit_entity_id, null)
	if u == null:
		return
	var clamped: Vector3 = Vector3(
		clampf(dest.x, -MAP_HALF_EXTENT + 2.0, MAP_HALF_EXTENT - 2.0),
		get_height_at(dest.x, dest.z),
		clampf(dest.z, -MAP_HALF_EXTENT + 2.0, MAP_HALF_EXTENT - 2.0)
	)
	u.move_target = clamped
	u.has_move_order = true
	u.target_entity_id = 0
	u.hold_position = false
	if u.owner_id == _local_player_id and not _headless_mode:
		_spawn_move_ring(clamped)
		if AudioDirector != null:
			AudioDirector.play_sfx(&"march_hooves", &"SFX", 0.05)


func _execute_order_attack(unit_entity_id: int, target_entity_id: int) -> void:
	var u: RtsUnitEntity = _units.get(unit_entity_id, null)
	if u == null:
		return
	u.target_entity_id = target_entity_id
	u.has_move_order = false
	u.hold_position = false
	if u.owner_id == _local_player_id and not _headless_mode and AudioDirector != null:
		AudioDirector.play_sfx(&"horn_war", &"SFX", 0.04)


func _spawn_building(
		owner_id: int,
		building_id: StringName,
		pos: Vector3,
		is_hq: bool,
		instant: bool) -> RtsBuildingEntity:
	var id: int = _next_entity_id
	_next_entity_id += 1
	var b: RtsBuildingEntity = RtsBuildingEntity.new()
	b.entity_id = id
	b.owner_id = owner_id
	b.building_id = building_id
	b.is_hq = is_hq
	b.can_train = (building_id == &"ger_camp" or building_id == &"nomadic_forge")
	b.max_hp = 900.0 if is_hq else 520.0
	b.hp = b.max_hp
	b.build_progress = 1.0 if instant else 0.15

	var bd: BuildingData = _building_data.get(building_id, null)
	if bd != null:
		b.display_name = "Baş Otağ" if is_hq else bd.display_name.split(" (")[0]

	var h: float = get_height_at(pos.x, pos.z)
	b.world_pos = Vector3(pos.x, h, pos.z)

	var root: Node3D = RtsVisualFactory.create_building_visual(building_id, owner_id, is_hq)
	root.position = b.world_pos
	if not instant:
		root.scale = Vector3(1.0, 0.25, 1.0)
	_entities_root.add_child(root)
	b.node_root = root

	var bar: Node3D = RtsVisualFactory.create_health_bar_3d(3.4 if is_hq else 2.6, 0.26, 4.6 if is_hq else 3.8)
	root.add_child(bar)
	b.hp_bar = bar
	RtsVisualFactory.update_health_bar_3d(bar, b.hp, b.max_hp, owner_id)

	var ring: MeshInstance3D = RtsVisualFactory.create_selection_ring(3.6 if is_hq else 2.8, NeoSteppePalette.GOLD_TAMGA)
	ring.visible = false
	root.add_child(ring)
	b.sel_ring = ring

	_buildings[id] = b
	if EventBus != null:
		EventBus.rts_building_constructed.emit(id, owner_id, building_id, b.world_pos)
	return b


func _spawn_unit(owner_id: int, unit_id: StringName, pos: Vector3, _is_starter: bool) -> RtsUnitEntity:
	var id: int = _next_entity_id
	_next_entity_id += 1
	var u: RtsUnitEntity = RtsUnitEntity.new()
	u.entity_id = id
	u.owner_id = owner_id
	u.unit_id = unit_id

	var ud: UnitData = _unit_data.get(unit_id, null)
	if ud != null:
		u.display_name = ud.display_name.split(" (")[0]
		u.max_hp = ud.max_health
		u.hp = ud.max_health
		u.attack = ud.attack
		u.defense = ud.defense
		u.speed = ud.base_speed
	u.is_ranged = (unit_id == &"horse_archer")
	u.is_support = (unit_id == &"supply_ox")
	u.attack_range = ARCHER_RANGE if u.is_ranged else MELEE_RANGE
	u.attack_cooldown = 1.25 if u.is_ranged else 1.45

	var h: float = get_height_at(pos.x, pos.z)
	u.world_pos = Vector3(pos.x, h, pos.z)

	var root: Node3D = RtsVisualFactory.create_unit_visual(unit_id, owner_id)
	root.position = u.world_pos
	_entities_root.add_child(root)
	u.node_root = root

	var bar: Node3D = RtsVisualFactory.create_health_bar_3d(2.2, 0.22, 2.85)
	root.add_child(bar)
	u.hp_bar = bar
	RtsVisualFactory.update_health_bar_3d(bar, u.hp, u.max_hp, owner_id)

	var ring: MeshInstance3D = RtsVisualFactory.create_selection_ring(2.3, NeoSteppePalette.GOLD_TAMGA)
	ring.visible = false
	root.add_child(ring)
	u.sel_ring = ring

	_units[id] = u
	if EventBus != null:
		EventBus.rts_unit_trained.emit(id, owner_id, unit_id, u.world_pos)
	return u


func _tick_economy() -> void:
	_recompute_rates()
	for pid: int in _economies:
		var econ: FactionEconomy = _economies[pid]
		econ.food += econ.food_rate
		econ.silver += econ.silver_rate
		econ.steel += econ.steel_rate
		econ.stone += econ.stone_rate
	if ResourceManager != null:
		var p1: FactionEconomy = _economies[1]
		CommandBus.dispatch(DepositResourcesCommand.new(1, &"stone", maxi(p1.stone_rate, 0)))


func _recompute_rates() -> void:
	for pid: int in _economies:
		var econ: FactionEconomy = _economies[pid]
		econ.food_rate = 0
		econ.silver_rate = 0
		econ.steel_rate = 0
		econ.stone_rate = 0
		econ.pop_cap = 4
		econ.pop_used = 0
	for bid: int in _buildings:
		var b: RtsBuildingEntity = _buildings[bid]
		if b.build_progress < 0.99:
			continue
		var econ: FactionEconomy = _economies.get(b.owner_id, null)
		if econ == null:
			continue
		match b.building_id:
			&"ger_camp":
				econ.food_rate += 14 if b.is_hq else 10
				econ.silver_rate += 8 if b.is_hq else 5
				econ.stone_rate += 8 if b.is_hq else 4
				econ.pop_cap += 8
			&"nomadic_forge":
				econ.steel_rate += 12
				econ.pop_cap += 4
			&"quarry":
				econ.stone_rate += 18
				econ.steel_rate += 6
			&"kurgan_shrine":
				econ.silver_rate += 12
				econ.food_rate += 8
	for uid: int in _units:
		var u: RtsUnitEntity = _units[uid]
		var econ: FactionEconomy = _economies.get(u.owner_id, null)
		if econ != null:
			econ.pop_used += 1


func _tick_enemy_ai() -> void:
	var ai_econ: FactionEconomy = _economies.get(2, null)
	if ai_econ == null:
		return
	var ai_hq: RtsBuildingEntity = _find_hq(2)
	if ai_hq == null:
		return

	# 1. Build additional economic/military buildings near AI base
	var ai_b_count: int = get_building_count(2)
	if ai_b_count < 4:
		var build_choice: StringName = &"quarry" if ai_b_count == 2 else &"ger_camp"
		if can_place_building_at(2, build_choice, ai_hq.world_pos + Vector3(-11.0, 0.0, -5.0)):
			_execute_place_building(2, build_choice, ai_hq.world_pos + Vector3(-11.0, 0.0, -5.0))
		else:
			for attempt: int in range(6):
				var ang: float = float(attempt) * 1.05 + 1.8
				var cand: Vector3 = ai_hq.world_pos + Vector3(cos(ang) * 11.0, 0.0, sin(ang) * 11.0)
				if can_place_building_at(2, build_choice, cand):
					_execute_place_building(2, build_choice, cand)
					break

	# 2. Train combat units
	if ai_econ.pop_used < ai_econ.pop_cap and get_unit_count(2) < 6:
		var train_choice: StringName = &"heavy_lancer" if (get_unit_count(2) % 2 == 1) else &"horse_archer"
		if _can_afford_unit(2, train_choice):
			var rally: Vector3 = _find_free_rally_point(ai_hq.world_pos, 2)
			_execute_train_unit(2, train_choice, rally)

	# 3. Defend base if player unit is close to AI HQ
	var threat_id: int = _find_nearest_enemy_entity(ai_hq.world_pos, 2, 26.0)
	if threat_id > 0:
		for uid: int in _units:
			var u: RtsUnitEntity = _units[uid]
			if u.owner_id == 2 and u.target_entity_id == 0:
				u.target_entity_id = threat_id
		return

	# 4. Launch coordinated raid once AI has >= 2 units or after 30s
	var ai_units: Array[RtsUnitEntity] = []
	for uid: int in _units:
		var u: RtsUnitEntity = _units[uid]
		if u.owner_id == 2 and not u.is_support:
			ai_units.append(u)
	if ai_units.size() >= 2 or (_sim_time >= 30.0 and ai_units.size() >= 1):
		var p1_hq: RtsBuildingEntity = _find_hq(1)
		var raid_target_id: int = 0
		if p1_hq != null:
			raid_target_id = _find_nearest_enemy_entity(ai_hq.world_pos, 2, 160.0)
			if raid_target_id == 0:
				raid_target_id = p1_hq.entity_id
		for au: RtsUnitEntity in ai_units:
			if au.target_entity_id == 0 and not au.has_move_order and raid_target_id > 0:
				au.target_entity_id = raid_target_id
				_ai_raids_sent += 1


func _tick_units(dt: float) -> void:
	var dead_units: Array[int] = []
	for uid: int in _units.keys():
		var u: RtsUnitEntity = _units[uid]
		if u.hp <= 0.0:
			dead_units.append(uid)
			continue
		u.cooldown_timer = maxf(u.cooldown_timer - dt, 0.0)

		# Support unit heals nearby friendly units
		if u.is_support:
			for f_id: int in _units:
				var fu: RtsUnitEntity = _units[f_id]
				if fu.owner_id == u.owner_id and fu.hp < fu.max_hp and fu.world_pos.distance_to(u.world_pos) <= 10.0:
					fu.hp = minf(fu.hp + 6.0 * dt, fu.max_hp)
					RtsVisualFactory.update_health_bar_3d(fu.hp_bar, fu.hp, fu.max_hp, fu.owner_id)

		# Acquire nearby target if idle and not holding
		if u.target_entity_id == 0 and not u.has_move_order and not u.hold_position and not u.is_support:
			u.target_entity_id = _find_nearest_enemy_entity(u.world_pos, u.owner_id, AGGRO_RADIUS)

		# Validate current target
		if u.target_entity_id > 0:
			var tpos: Vector3 = _get_entity_position(u.target_entity_id)
			if is_inf(tpos.x):
				u.target_entity_id = 0
			else:
				var dist: float = Vector2(tpos.x - u.world_pos.x, tpos.z - u.world_pos.z).length()
				if dist <= u.attack_range:
					u.has_move_order = false
					_face_unit_toward(u, tpos)
					if u.cooldown_timer <= 0.0 and not u.is_support:
						u.cooldown_timer = u.attack_cooldown
						_perform_attack(u, u.target_entity_id, tpos)
				else:
					_move_unit_step(u, tpos, dt)
				continue

		if u.has_move_order:
			var dist_m: float = Vector2(u.move_target.x - u.world_pos.x, u.move_target.z - u.world_pos.z).length()
			if dist_m <= 1.2:
				u.has_move_order = false
			else:
				_move_unit_step(u, u.move_target, dt)

	for dead_id: int in dead_units:
		_destroy_unit(dead_id)


func _move_unit_step(u: RtsUnitEntity, target: Vector3, dt: float) -> void:
	var dir_xz: Vector2 = Vector2(target.x - u.world_pos.x, target.z - u.world_pos.z)
	var dist: float = dir_xz.length()
	if dist < 0.01:
		return
	var step_dist: float = minf(u.speed * dt, dist)
	var norm: Vector2 = dir_xz / dist
	var nx: float = clampf(u.world_pos.x + norm.x * step_dist, -MAP_HALF_EXTENT + 1.5, MAP_HALF_EXTENT - 1.5)
	var nz: float = clampf(u.world_pos.z + norm.y * step_dist, -MAP_HALF_EXTENT + 1.5, MAP_HALF_EXTENT - 1.5)
	var ny: float = get_height_at(nx, nz)
	u.world_pos = Vector3(nx, ny, nz)
	if u.node_root != null:
		u.node_root.position = u.world_pos
		u.node_root.rotation.y = atan2(-norm.x, -norm.y)

	u.dust_timer += dt
	if u.dust_timer >= 0.45 and not _headless_mode:
		u.dust_timer = 0.0
		_spawn_dust_puff(u.world_pos)


func _face_unit_toward(u: RtsUnitEntity, target: Vector3) -> void:
	if u.node_root == null:
		return
	var dx: float = target.x - u.world_pos.x
	var dz: float = target.z - u.world_pos.z
	if absf(dx) + absf(dz) > 0.01:
		u.node_root.rotation.y = atan2(-dx, -dz)


func _perform_attack(attacker: RtsUnitEntity, target_id: int, target_pos: Vector3) -> void:
	var atk_stats: CombatantStats = CombatantStats.new(attacker.entity_id, attacker.attack, attacker.defense, attacker.hp, 1.0)
	var def_stats: CombatantStats = null
	var is_building_target: bool = _buildings.has(target_id)
	if is_building_target:
		var tb: RtsBuildingEntity = _buildings[target_id]
		def_stats = CombatantStats.new(tb.entity_id, 6.0, 12.0, tb.hp, 1.0)
	elif _units.has(target_id):
		var tu: RtsUnitEntity = _units[target_id]
		def_stats = CombatantStats.new(tu.entity_id, tu.attack, tu.defense, tu.hp, 1.0)
	else:
		return

	var res: CombatResult = CombatCalculator.calculate(atk_stats, def_stats, null, null, _rng)
	var dmg: float = maxf(res.damage_to_defender, 6.0)
	_battles_fought += 1

	if is_building_target:
		var tb: RtsBuildingEntity = _buildings[target_id]
		tb.hp = maxf(tb.hp - dmg, 0.0)
		RtsVisualFactory.update_health_bar_3d(tb.hp_bar, tb.hp, tb.max_hp, tb.owner_id)
		if tb.hp <= 0.0:
			_destroy_building(target_id)
	else:
		var tu: RtsUnitEntity = _units[target_id]
		tu.hp = maxf(tu.hp - dmg, 0.0)
		RtsVisualFactory.update_health_bar_3d(tu.hp_bar, tu.hp, tu.max_hp, tu.owner_id)
		if tu.hp <= 0.0:
			_destroy_unit(target_id)

	if EventBus != null:
		EventBus.rts_combat_hit.emit(attacker.entity_id, target_id, dmg, target_pos, attacker.is_ranged)

	if not _headless_mode:
		_spawn_damage_number(target_pos + Vector3(0.0, 2.8, 0.0), int(roundf(dmg)))
		if attacker.is_ranged:
			_spawn_arrow_fx(attacker.world_pos + Vector3(0.0, 1.6, 0.0), target_pos + Vector3(0.0, 1.2, 0.0))
		else:
			_spawn_spark_fx(target_pos + Vector3(0.0, 1.2, 0.0))
		if AudioDirector != null:
			AudioDirector.play_sfx(&"sword_clash", &"SFX", 0.08)


func _destroy_unit(unit_id: int) -> void:
	if not _units.has(unit_id):
		return
	var u: RtsUnitEntity = _units[unit_id]
	var owner_id: int = u.owner_id
	var pos: Vector3 = u.world_pos
	if u.node_root != null and is_instance_valid(u.node_root):
		u.node_root.queue_free()
	_units.erase(unit_id)
	if _selected_unit_id == unit_id:
		_selected_unit_id = 0
		var hud: MobileRtsHud = _get_hud()
		if hud != null:
			hud.set_context_build()
	_recompute_rates()
	if EventBus != null:
		EventBus.rts_entity_destroyed.emit(unit_id, owner_id, false, false, pos)


func _destroy_building(building_id: int) -> void:
	if not _buildings.has(building_id):
		return
	var b: RtsBuildingEntity = _buildings[building_id]
	var owner_id: int = b.owner_id
	var was_hq: bool = b.is_hq
	var pos: Vector3 = b.world_pos
	if b.node_root != null and is_instance_valid(b.node_root):
		b.node_root.queue_free()
	_buildings.erase(building_id)
	if _selected_building_id == building_id:
		_selected_building_id = 0
	_recompute_rates()
	if EventBus != null:
		EventBus.rts_entity_destroyed.emit(building_id, owner_id, true, was_hq, pos)
	if was_hq and not _match_over:
		_conclude_match(1 if owner_id == 2 else 2)


func _conclude_match(winner_id: int) -> void:
	_match_over = true
	var is_local_win: bool = (winner_id == _local_player_id)
	var hud: MobileRtsHud = _get_hud()
	if hud != null:
		var stats: String = "Süre: %d sn\nDikilen Yapı: %d\nEğitilen Bölük: %d\nÇatışma Vuruşu: %d" % [
			int(roundf(_sim_time)),
			get_buildings_built_count(_local_player_id),
			get_units_trained_count(_local_player_id),
			_battles_fought,
		]
		hud.show_match_outcome(is_local_win, stats)
	if EventBus != null:
		EventBus.match_concluded.emit(winner_id, &"hq_destroyed")


func _tick_fx(dt: float) -> void:
	var keep_proj: Array[RtsProjectileFx] = []
	for p: RtsProjectileFx in _projectiles:
		p.elapsed += dt
		var t: float = clampf(p.elapsed / p.duration, 0.0, 1.0)
		if t >= 1.0:
			if p.mesh != null and is_instance_valid(p.mesh):
				p.mesh.queue_free()
		else:
			var pos: Vector3 = p.start_pos.lerp(p.end_pos, t)
			pos.y += sin(t * PI) * 3.4
			if p.mesh != null and is_instance_valid(p.mesh):
				p.mesh.position = pos
			keep_proj.append(p)
	_projectiles = keep_proj

	var keep_fx: Array[RtsTempFx] = []
	for f: RtsTempFx in _temp_fx:
		f.elapsed += dt
		if f.elapsed >= f.duration:
			if f.node != null and is_instance_valid(f.node):
				f.node.queue_free()
		else:
			if f.node != null and is_instance_valid(f.node):
				f.node.position += f.velocity * dt
				if f.is_ring:
					var s: float = 1.0 + f.elapsed * 1.4
					f.node.scale = Vector3(s, 0.2, s)
			keep_fx.append(f)
	_temp_fx = keep_fx


func _sync_hud_and_minimap() -> void:
	var hud: MobileRtsHud = _get_hud()
	if hud == null:
		return
	var econ: FactionEconomy = _economies.get(_local_player_id, null)
	if econ != null:
		hud.update_resources(
			econ.food, econ.food_rate * 12,
			econ.silver, econ.silver_rate * 12,
			econ.steel, econ.steel_rate * 12,
			econ.stone, econ.stone_rate * 12,
			econ.pop_used, econ.pop_cap
		)
	var b_dots: Array[MobileRtsHud.MinimapDot] = []
	for bid: int in _buildings:
		var b: RtsBuildingEntity = _buildings[bid]
		b_dots.append(MobileRtsHud.MinimapDot.new(b.world_pos, b.owner_id, b.is_hq))
	var a_dots: Array[MobileRtsHud.MinimapDot] = []
	for uid: int in _units:
		var u: RtsUnitEntity = _units[uid]
		a_dots.append(MobileRtsHud.MinimapDot.new(u.world_pos, u.owner_id, false))
	var cam: DualLayerCamera = _get_cam()
	var cam_pos: Vector3 = cam.global_position if cam != null else Vector3.ZERO
	hud.update_minimap_entities(b_dots, a_dots, cam_pos)


func _handle_world_left_click(hit: Vector3) -> bool:
	# 1. Check friendly unit selection
	var best_u: RtsUnitEntity = null
	var best_u_dist: float = 4.2
	for uid: int in _units:
		var u: RtsUnitEntity = _units[uid]
		if u.owner_id == _local_player_id:
			var d: float = Vector2(u.world_pos.x - hit.x, u.world_pos.z - hit.z).length()
			if d < best_u_dist:
				best_u_dist = d
				best_u = u
	if best_u != null:
		_select_unit(best_u.entity_id)
		return true

	# 2. If a friendly unit is already selected, check enemy click (attack) or ground click (move)
	if _selected_unit_id > 0 and _units.has(_selected_unit_id):
		var enemy_id: int = _find_nearest_enemy_entity(hit, _local_player_id, 5.2)
		if enemy_id > 0:
			issue_attack_command(_selected_unit_id, enemy_id)
			return true
		issue_move_command(_selected_unit_id, hit)
		return true

	# 3. Check friendly building selection
	var best_b: RtsBuildingEntity = null
	var best_b_dist: float = 5.0
	for bid: int in _buildings:
		var b: RtsBuildingEntity = _buildings[bid]
		if b.owner_id == _local_player_id:
			var d: float = Vector2(b.world_pos.x - hit.x, b.world_pos.z - hit.z).length()
			if d < best_b_dist:
				best_b_dist = d
				best_b = b
	if best_b != null:
		_select_building(best_b.entity_id)
		return true

	_clear_selection()
	return false


func _handle_world_action_on_unit(hit: Vector3) -> void:
	if _selected_unit_id <= 0 or not _units.has(_selected_unit_id):
		return
	var enemy_id: int = _find_nearest_enemy_entity(hit, _local_player_id, 5.2)
	if enemy_id > 0:
		issue_attack_command(_selected_unit_id, enemy_id)
	else:
		issue_move_command(_selected_unit_id, hit)


func _select_unit(unit_id: int) -> void:
	_clear_selection()
	_selected_unit_id = unit_id
	var u: RtsUnitEntity = _units.get(unit_id, null)
	if u != null and u.sel_ring != null:
		u.sel_ring.visible = true
		var hud: MobileRtsHud = _get_hud()
		if hud != null:
			hud.set_context_army("%s\nHP %d/%d · Hsr %d" % [u.display_name, int(u.hp), int(u.max_hp), int(u.attack)])


func _select_building(building_id: int) -> void:
	_clear_selection()
	_selected_building_id = building_id
	var b: RtsBuildingEntity = _buildings.get(building_id, null)
	if b != null and b.sel_ring != null:
		b.sel_ring.visible = true
		var hud: MobileRtsHud = _get_hud()
		if hud != null:
			hud.set_context_building("%s\nHP %d/%d" % [b.display_name, int(b.hp), int(b.max_hp)], b.can_train)


func _clear_selection() -> void:
	if _selected_unit_id > 0 and _units.has(_selected_unit_id):
		var u: RtsUnitEntity = _units[_selected_unit_id]
		if u.sel_ring != null:
			u.sel_ring.visible = false
	if _selected_building_id > 0 and _buildings.has(_selected_building_id):
		var b: RtsBuildingEntity = _buildings[_selected_building_id]
		if b.sel_ring != null:
			b.sel_ring.visible = false
	_selected_unit_id = 0
	_selected_building_id = 0
	var hud: MobileRtsHud = _get_hud()
	if hud != null:
		hud.set_context_build()


func _on_hud_build_requested(building_id: StringName) -> void:
	_clear_selection()
	_placing_building_id = building_id
	if _preview_node != null:
		_preview_node.visible = true
	var bd: BuildingData = _building_data.get(building_id, null)
	var title: String = bd.display_name.split(" (")[0] if bd != null else String(building_id)
	var hud: MobileRtsHud = _get_hud()
	if hud != null:
		hud.set_context_placing(title)


func _on_hud_build_cancelled() -> void:
	_cancel_placement()


func _cancel_placement() -> void:
	_placing_building_id = &""
	if _preview_node != null:
		_preview_node.visible = false
	var hud: MobileRtsHud = _get_hud()
	if hud != null:
		hud.set_context_build()


func _try_confirm_placement(hit: Vector3) -> void:
	var bid: StringName = _placing_building_id
	if issue_build_command(_local_player_id, bid, hit):
		_cancel_placement()


func _on_hud_train_requested(unit_id: StringName) -> void:
	var source_b: int = _selected_building_id
	if source_b == 0:
		var hq: RtsBuildingEntity = _find_hq(_local_player_id)
		if hq != null:
			source_b = hq.entity_id
	if source_b > 0:
		issue_train_command(_local_player_id, unit_id, source_b)


func _on_hud_army_order(order_id: StringName) -> void:
	if _selected_unit_id <= 0 or not _units.has(_selected_unit_id):
		return
	var u: RtsUnitEntity = _units[_selected_unit_id]
	if order_id == &"attack_nearest":
		var tid: int = _find_nearest_enemy_entity(u.world_pos, _local_player_id, 180.0)
		if tid > 0:
			issue_attack_command(u.entity_id, tid)
	elif order_id == &"hold":
		u.has_move_order = false
		u.target_entity_id = 0
		u.hold_position = true
	elif order_id == &"retreat":
		var hq: RtsBuildingEntity = _find_hq(_local_player_id)
		if hq != null:
			issue_move_command(u.entity_id, hq.world_pos + Vector3(4.5, 0.0, -4.5))


func _on_replay_requested() -> void:
	_reset_match_entities()


func _find_hq(owner_id: int) -> RtsBuildingEntity:
	for bid: int in _buildings:
		var b: RtsBuildingEntity = _buildings[bid]
		if b.owner_id == owner_id and b.is_hq:
			return b
	return null


func _find_nearest_enemy_entity(origin: Vector3, my_owner: int, max_range: float) -> int:
	var best_id: int = 0
	var best_d: float = max_range
	for uid: int in _units:
		var u: RtsUnitEntity = _units[uid]
		if u.owner_id != my_owner and u.hp > 0.0:
			var d: float = Vector2(u.world_pos.x - origin.x, u.world_pos.z - origin.z).length()
			if d < best_d:
				best_d = d
				best_id = u.entity_id
	if best_id > 0:
		return best_id
	for bid: int in _buildings:
		var b: RtsBuildingEntity = _buildings[bid]
		if b.owner_id != my_owner and b.hp > 0.0:
			var d: float = Vector2(b.world_pos.x - origin.x, b.world_pos.z - origin.z).length()
			if d < best_d:
				best_d = d
				best_id = b.entity_id
	return best_id


func _get_entity_position(entity_id: int) -> Vector3:
	if _units.has(entity_id):
		return _units[entity_id].world_pos
	if _buildings.has(entity_id):
		return _buildings[entity_id].world_pos
	return Vector3.INF


func _find_free_rally_point(center: Vector3, owner_id: int) -> Vector3:
	var dir_sign: float = 1.0 if owner_id == 1 else -1.0
	var offset: Vector3 = Vector3(5.5 * dir_sign, 0.0, -5.0 * dir_sign)
	var jitter: float = float((_units.size() % 5) - 2) * 1.4
	var p: Vector3 = center + offset + Vector3(jitter, 0.0, jitter * 0.5)
	return Vector3(
		clampf(p.x, -MAP_HALF_EXTENT + 3.0, MAP_HALF_EXTENT - 3.0),
		get_height_at(p.x, p.z),
		clampf(p.z, -MAP_HALF_EXTENT + 3.0, MAP_HALF_EXTENT - 3.0)
	)


func _can_afford_building(player_id: int, building_id: StringName) -> bool:
	var e: FactionEconomy = _economies.get(player_id, null)
	if e == null:
		return false
	match building_id:
		&"ger_camp":
			return e.stone >= 60
		&"nomadic_forge":
			return e.stone >= 80 and e.steel >= 40
		&"quarry":
			return e.stone >= 120 and e.steel >= 30
		&"kurgan_shrine":
			return e.stone >= 150 and e.silver >= 15
	return false


func _spend_for_building(player_id: int, building_id: StringName) -> bool:
	if not _can_afford_building(player_id, building_id):
		return false
	var e: FactionEconomy = _economies[player_id]
	match building_id:
		&"ger_camp":
			e.stone -= 60
		&"nomadic_forge":
			e.stone -= 80
			e.steel -= 40
		&"quarry":
			e.stone -= 120
			e.steel -= 30
		&"kurgan_shrine":
			e.stone -= 150
			e.silver -= 15
	return true


func _can_afford_unit(player_id: int, unit_id: StringName) -> bool:
	var e: FactionEconomy = _economies.get(player_id, null)
	if e == null:
		return false
	match unit_id:
		&"horse_archer":
			return e.food >= 60 and e.silver >= 20
		&"heavy_lancer":
			return e.food >= 80 and e.steel >= 35
		&"supply_ox":
			return e.food >= 50 and e.stone >= 15
	return false


func _spend_for_unit(player_id: int, unit_id: StringName) -> bool:
	if not _can_afford_unit(player_id, unit_id):
		return false
	var e: FactionEconomy = _economies[player_id]
	match unit_id:
		&"horse_archer":
			e.food -= 60
			e.silver -= 20
		&"heavy_lancer":
			e.food -= 80
			e.steel -= 35
		&"supply_ox":
			e.food -= 50
			e.stone -= 15
	return true


func _load_templates() -> void:
	for path: String in [
		"res://data/buildings/ger_camp.tres",
		"res://data/buildings/nomadic_forge.tres",
		"res://data/buildings/quarry.tres",
		"res://data/buildings/kurgan_shrine.tres",
	]:
		var bd: BuildingData = ResourceLoader.load(path) as BuildingData
		if bd != null:
			_building_data[bd.id] = bd
	for upath: String in [
		"res://data/units/horse_archer.tres",
		"res://data/units/heavy_lancer.tres",
		"res://data/units/supply_ox.tres",
	]:
		var ud: UnitData = ResourceLoader.load(upath) as UnitData
		if ud != null:
			_unit_data[ud.id] = ud


func _build_preview_and_path_nodes() -> void:
	_preview_node = Node3D.new()
	_preview_node.visible = false
	var mi: MeshInstance3D = MeshInstance3D.new()
	var bm: BoxMesh = BoxMesh.new()
	bm.size = Vector3(5.0, 0.35, 5.0)
	mi.mesh = bm
	_preview_mat = StandardMaterial3D.new()
	_preview_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_preview_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_preview_mat.albedo_color = Color(0.20, 0.85, 0.35, 0.55)
	mi.material_override = _preview_mat
	_preview_node.add_child(mi)
	_fx_root.add_child(_preview_node)

	_path_line_mesh = MeshInstance3D.new()
	_path_line_mesh.visible = false
	var pmat: StandardMaterial3D = StandardMaterial3D.new()
	pmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pmat.albedo_color = Color(0.95, 0.82, 0.32, 0.85)
	_path_line_mesh.material_override = pmat
	_fx_root.add_child(_path_line_mesh)


func _update_preview_transform(pos: Vector3) -> void:
	if _preview_node == null:
		return
	var h: float = get_height_at(pos.x, pos.z)
	_preview_node.position = Vector3(pos.x, h + 0.25, pos.z)
	var valid: bool = can_place_building_at(_local_player_id, _placing_building_id, pos)
	if _preview_mat != null:
		_preview_mat.albedo_color = Color(0.20, 0.85, 0.35, 0.55) if valid else Color(0.90, 0.22, 0.20, 0.55)


func _update_path_trail() -> void:
	if _path_line_mesh == null or _headless_mode:
		return
	if _selected_unit_id <= 0 or not _units.has(_selected_unit_id):
		_path_line_mesh.visible = false
		return
	var u: RtsUnitEntity = _units[_selected_unit_id]
	var dest: Vector3 = Vector3.INF
	if u.has_move_order:
		dest = u.move_target
	elif u.target_entity_id > 0:
		dest = _get_entity_position(u.target_entity_id)
	if is_inf(dest.x):
		_path_line_mesh.visible = false
		return
	var im: ImmediateMesh = ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	im.surface_add_vertex(u.world_pos + Vector3(0.0, 0.45, 0.0))
	im.surface_add_vertex(dest + Vector3(0.0, 0.45, 0.0))
	im.surface_end()
	_path_line_mesh.mesh = im
	_path_line_mesh.visible = true


func _spawn_damage_number(pos: Vector3, dmg_val: int) -> void:
	var lbl: Label3D = Label3D.new()
	lbl.text = "-%d" % dmg_val
	lbl.font_size = 44
	lbl.pixel_size = 0.045
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.modulate = Color(1.0, 0.36, 0.24, 1.0)
	lbl.outline_modulate = Color(0.05, 0.04, 0.03, 1.0)
	lbl.outline_size = 8
	lbl.position = pos
	_fx_root.add_child(lbl)
	var fx: RtsTempFx = RtsTempFx.new()
	fx.node = lbl
	fx.velocity = Vector3(0.0, 2.2, 0.0)
	fx.duration = 0.85
	_temp_fx.append(fx)


func _spawn_arrow_fx(start_p: Vector3, end_p: Vector3) -> void:
	var arrow: MeshInstance3D = MeshInstance3D.new()
	var bm: BoxMesh = BoxMesh.new()
	bm.size = Vector3(0.10, 0.10, 0.85)
	arrow.mesh = bm
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.98, 0.88, 0.55, 1.0)
	arrow.material_override = mat
	arrow.position = start_p
	_fx_root.add_child(arrow)
	var p: RtsProjectileFx = RtsProjectileFx.new()
	p.mesh = arrow
	p.start_pos = start_p
	p.end_pos = end_p
	p.duration = 0.34
	_projectiles.append(p)


func _spawn_spark_fx(pos: Vector3) -> void:
	var spark: MeshInstance3D = MeshInstance3D.new()
	var sm: SphereMesh = SphereMesh.new()
	sm.radius = 0.32
	sm.height = 0.64
	spark.mesh = sm
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.72, 0.22, 1.0)
	spark.material_override = mat
	spark.position = pos
	_fx_root.add_child(spark)
	var fx: RtsTempFx = RtsTempFx.new()
	fx.node = spark
	fx.velocity = Vector3(0.0, 0.8, 0.0)
	fx.duration = 0.22
	_temp_fx.append(fx)


func _spawn_dust_puff(pos: Vector3) -> void:
	var puff: MeshInstance3D = MeshInstance3D.new()
	var sm: SphereMesh = SphereMesh.new()
	sm.radius = 0.28
	sm.height = 0.25
	puff.mesh = sm
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.66, 0.58, 0.46, 0.45)
	puff.material_override = mat
	puff.position = pos + Vector3(0.0, 0.2, 0.0)
	_fx_root.add_child(puff)
	var fx: RtsTempFx = RtsTempFx.new()
	fx.node = puff
	fx.velocity = Vector3(0.0, 0.5, 0.0)
	fx.duration = 0.45
	_temp_fx.append(fx)


func _spawn_move_ring(pos: Vector3) -> void:
	var ring: MeshInstance3D = RtsVisualFactory.create_selection_ring(1.2, Color(0.32, 0.92, 0.55, 0.85))
	ring.position = pos + Vector3(0.0, 0.18, 0.0)
	_fx_root.add_child(ring)
	var fx: RtsTempFx = RtsTempFx.new()
	fx.node = ring
	fx.duration = 0.55
	fx.is_ring = true
	_temp_fx.append(fx)


func _raycast_terrain(screen_pos: Vector2) -> Vector3:
	if get_viewport() == null:
		return Vector3.INF
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam == null:
		return Vector3.INF
	var orig: Vector3 = cam.project_ray_origin(screen_pos)
	var dir: Vector3 = cam.project_ray_normal(screen_pos)
	# March along ray against heightmap for exact sloped-terrain picking
	var prev_p: Vector3 = orig
	var step_m: float = 2.0
	for i: int in range(1, 140):
		var cur_p: Vector3 = orig + dir * (float(i) * step_m)
		var th: float = get_height_at(cur_p.x, cur_p.z)
		if cur_p.y <= th:
			# Binary refine
			var lo: float = float(i - 1) * step_m
			var hi: float = float(i) * step_m
			for _r: int in range(6):
				var mid: float = (lo + hi) * 0.5
				var mp: Vector3 = orig + dir * mid
				if mp.y <= get_height_at(mp.x, mp.z):
					hi = mid
				else:
					lo = mid
			var final_p: Vector3 = orig + dir * ((lo + hi) * 0.5)
			return Vector3(final_p.x, get_height_at(final_p.x, final_p.z), final_p.z)
		prev_p = cur_p
	if absf(dir.y) > 0.0001:
		var t: float = -orig.y / dir.y
		if t > 0.0:
			var gp: Vector3 = orig + dir * t
			return Vector3(gp.x, get_height_at(gp.x, gp.z), gp.z)
	return Vector3.INF


func _mark_handled() -> void:
	if get_viewport() != null:
		get_viewport().set_input_as_handled()
