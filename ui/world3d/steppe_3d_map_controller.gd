class_name Steppe3DMapController
extends Node3D
## UI 3D World Bridge (rank 4). Connects live simulation state via strictly
## read-only `Steppe3DMapViewModel`, `WeakRef` scene references, and `EventBus`
## to procedural 3D region/climate tiles, Border Tuğ rings, Water nodes,
## moving Caravan/Courier beacons, and Doctrine/Dust-aware army markers.

signal region_selected(coord: Vector2i)
signal army_selected(army_id: int)
signal map_synced(lens: GameEnums.TacticalMapLens, region_count: int, route_count: int)

const ARMY_PICK_RADIUS_M: float = 4.5
const RAY_EPSILON: float = 0.0001


class BusSub:
	var bus_signal: Signal
	var callback: Callable

	func _init(p_sig: Signal, p_cb: Callable) -> void:
		bus_signal = p_sig
		callback = p_cb


class ArmyMarkerRig:
	var root: Node3D
	var core_banner: MeshInstance3D
	var formation_wings_root: Node3D
	var wing_meshes: Array[MeshInstance3D]
	var dust_veil: MeshInstance3D
	var selection_ring: MeshInstance3D
	var alert_ring: MeshInstance3D
	var shape_id: StringName = &"hilal"

	func _init(
			p_root: Node3D,
			p_banner: MeshInstance3D,
			p_wings_root: Node3D,
			p_wings: Array[MeshInstance3D],
			p_dust: MeshInstance3D,
			p_sel: MeshInstance3D,
			p_alert: MeshInstance3D) -> void:
		root = p_root
		core_banner = p_banner
		formation_wings_root = p_wings_root
		wing_meshes = p_wings
		dust_veil = p_dust
		selection_ring = p_sel
		alert_ring = p_alert


var _view_model: Steppe3DMapViewModel = null
var _last_snapshot: Steppe3DMapViewModel.MapSnapshot = null
var _camera_ref: WeakRef = null
var _army_registry_ref: WeakRef = null
var _sun_light_ref: WeakRef = null

var _meshes_built: bool = false
var _is_refreshing: bool = false
var _signals_connected: bool = false
var _visual_time: float = 0.0

var _overlay_tiles_mm: MultiMeshInstance3D = null
var _kurgans_mm: MultiMeshInstance3D = null
var _water_nodes_mm: MultiMeshInstance3D = null
var _tug_rings_mm: MultiMeshInstance3D = null
var _routes_mm: MultiMeshInstance3D = null
var _armies_root: Node3D = null

var _region_colors: Dictionary[Vector2i, Color] = {}
var _army_rigs: Dictionary[int, ArmyMarkerRig] = {}
var _bus_subs: Array[BusSub] = []


func _ready() -> void:
	if _view_model == null:
		_view_model = Steppe3DMapViewModel.new(1, 1)
	_ensure_visual_layers()
	_connect_bus()
	sync_from_viewmodel()


func _exit_tree() -> void:
	_disconnect_bus()
	_clear_army_rigs()


func _process(delta: float) -> void:
	if _last_snapshot == null or not _meshes_built:
		return
	if not SessionClockAuthority.is_paused():
		_visual_time += delta * SessionClockAuthority.get_speed_scale()
	var reg_obj: Object = _army_registry_ref.get_ref() if _army_registry_ref != null else null
	var reg: ArmyRegistry = reg_obj as ArmyRegistry
	if reg != null:
		for army_id: int in _army_rigs:
			var army: ArmyController = reg.get_army(army_id)
			var rig: ArmyMarkerRig = _army_rigs[army_id]
			if army != null and rig != null and is_instance_valid(rig.root):
				var army_pos: Vector3 = army.global_position if army.is_inside_tree() else army.position
				if rig.root.is_inside_tree():
					rig.root.global_position = army_pos
				else:
					rig.root.position = army_pos
				rig.root.rotation.y = army.rotation.y
				if rig.dust_veil.visible:
					var pulse: float = 1.0 + 0.08 * sin(_visual_time * 3.5)
					rig.dust_veil.scale = Vector3(pulse, 1.0, pulse)


func _unhandled_input(event: InputEvent) -> void:
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	var hit: Vector3 = _project_screen_to_ground(mb.position)
	if not is_inf(hit.x):
		if handle_ground_click_world(hit) and get_viewport() != null:
			get_viewport().set_input_as_handled()


func bind_scene_context(
		camera: DualLayerCamera,
		army_registry: ArmyRegistry,
		macro_generator: MacroWorldGenerator,
		directional_light: DirectionalLight3D,
		p_player_id: int = 1,
		p_army_id: int = 1) -> void:
	_camera_ref = weakref(camera) if camera != null else null
	_army_registry_ref = weakref(army_registry) if army_registry != null else null
	_sun_light_ref = weakref(directional_light) if directional_light != null else null

	var vm: Steppe3DMapViewModel = get_view_model()
	vm.set_player_context(p_player_id, p_army_id)
	vm.bind_army_registry(army_registry)
	if macro_generator != null and macro_generator.get_state() != null:
		vm.set_macro_world_state(macro_generator.get_state())
	_ensure_visual_layers()
	sync_from_viewmodel()


func get_view_model() -> Steppe3DMapViewModel:
	if _view_model == null:
		_view_model = Steppe3DMapViewModel.new(1, 1)
	return _view_model


func get_last_snapshot() -> Steppe3DMapViewModel.MapSnapshot:
	return _last_snapshot


func get_active_lens() -> GameEnums.TacticalMapLens:
	return _last_snapshot.active_lens if _last_snapshot != null else GameEnums.TacticalMapLens.NORMAL


func get_lens_summary_text() -> String:
	return _last_snapshot.lens_summary_text if _last_snapshot != null else ""


func get_selected_region_coord() -> Vector2i:
	return _last_snapshot.selected_region_coord if _last_snapshot != null else Vector2i.ZERO


func get_selected_army_id() -> int:
	return _last_snapshot.selected_army_id if _last_snapshot != null else 1


func get_region_visual_color(coord: Vector2i) -> Color:
	return _region_colors.get(coord, Color.BLACK)


func get_region_tile_count() -> int:
	if _overlay_tiles_mm == null or _overlay_tiles_mm.multimesh == null:
		return 0
	return _overlay_tiles_mm.multimesh.instance_count


func get_tug_ring_count() -> int:
	if _tug_rings_mm == null or _tug_rings_mm.multimesh == null:
		return 0
	return _tug_rings_mm.multimesh.instance_count


func get_water_marker_count() -> int:
	if _water_nodes_mm == null or _water_nodes_mm.multimesh == null:
		return 0
	return _water_nodes_mm.multimesh.instance_count


func get_route_marker_count() -> int:
	if _routes_mm == null or _routes_mm.multimesh == null:
		return 0
	return _routes_mm.multimesh.instance_count


func get_army_formation_shape(army_id: int) -> StringName:
	if _army_rigs.has(army_id):
		return _army_rigs[army_id].shape_id
	return &""


func is_army_dust_veil_visible(army_id: int) -> bool:
	if _army_rigs.has(army_id):
		var rig: ArmyMarkerRig = _army_rigs[army_id]
		return rig.dust_veil != null and rig.dust_veil.visible
	return false


func select_region(coord: Vector2i, focus_camera: bool = false) -> bool:
	var vm: Steppe3DMapViewModel = get_view_model()
	vm.set_selected_region(coord, true)
	sync_from_viewmodel()
	if focus_camera:
		_focus_camera_on(vm.coord_to_world_pos(coord))
	region_selected.emit(coord)
	return true


func select_army(army_id: int, focus_camera: bool = false) -> bool:
	if army_id <= 0:
		return false
	var vm: Steppe3DMapViewModel = get_view_model()
	vm.set_selected_army(army_id)
	sync_from_viewmodel()
	if focus_camera:
		var reg_obj: Object = _army_registry_ref.get_ref() if _army_registry_ref != null else null
		var reg: ArmyRegistry = reg_obj as ArmyRegistry
		if reg != null:
			var army: ArmyController = reg.get_army(army_id)
			if army != null:
				_focus_camera_on(army.global_position if army.is_inside_tree() else army.position)
	army_selected.emit(army_id)
	return true


func handle_ground_click_world(world_pos: Vector3) -> bool:
	var reg_obj: Object = _army_registry_ref.get_ref() if _army_registry_ref != null else null
	var reg: ArmyRegistry = reg_obj as ArmyRegistry
	if reg != null:
		var best_army_id: int = -1
		var best_dist: float = ARMY_PICK_RADIUS_M
		for army: ArmyController in reg.get_all_armies():
			if army == null or not is_instance_valid(army):
				continue
			var a_pos: Vector3 = army.global_position if army.is_inside_tree() else army.position
			var d: float = Vector2(a_pos.x - world_pos.x, a_pos.z - world_pos.z).length()
			if d <= best_dist:
				best_dist = d
				best_army_id = army.army_id
		if best_army_id > 0:
			return select_army(best_army_id, false)

	var coord: Vector2i = get_view_model().world_pos_to_coord(world_pos)
	return select_region(coord, false)


func pan_camera(delta_xz: Vector2) -> Vector3:
	var cam_obj: Object = _camera_ref.get_ref() if _camera_ref != null else null
	var cam: DualLayerCamera = cam_obj as DualLayerCamera
	if cam != null:
		return cam.pan_by(delta_xz)
	return Vector3.ZERO


func zoom_camera(delta_factor: float) -> float:
	var cam_obj: Object = _camera_ref.get_ref() if _camera_ref != null else null
	var cam: DualLayerCamera = cam_obj as DualLayerCamera
	if cam != null:
		return cam.zoom_by(delta_factor)
	return 1.0


func sync_from_viewmodel() -> void:
	if _is_refreshing:
		return
	_is_refreshing = true
	_ensure_visual_layers()
	var snap: Steppe3DMapViewModel.MapSnapshot = get_view_model().capture_snapshot()
	_last_snapshot = snap

	_apply_sun_climate(snap)
	_rebuild_region_tiles(snap)
	_rebuild_kurgans(snap)
	_rebuild_water_nodes(snap)
	_rebuild_tug_rings(snap)
	_rebuild_routes(snap)
	_sync_army_markers(snap)

	_is_refreshing = false
	map_synced.emit(snap.active_lens, snap.regions.size(), snap.routes.size())


func _focus_camera_on(world_pos: Vector3) -> void:
	var cam_obj: Object = _camera_ref.get_ref() if _camera_ref != null else null
	var cam: DualLayerCamera = cam_obj as DualLayerCamera
	if cam != null:
		cam.focus_world_position(world_pos)


func _project_screen_to_ground(screen_pos: Vector2) -> Vector3:
	if get_viewport() == null:
		return Vector3.INF
	var active_cam: Camera3D = get_viewport().get_camera_3d()
	if active_cam == null:
		return Vector3.INF
	var origin: Vector3 = active_cam.project_ray_origin(screen_pos)
	var dir: Vector3 = active_cam.project_ray_normal(screen_pos)
	if absf(dir.y) <= RAY_EPSILON:
		return Vector3.INF
	var t: float = -origin.y / dir.y
	if t < 0.0:
		return Vector3.INF
	return origin + dir * t


func _apply_sun_climate(snap: Steppe3DMapViewModel.MapSnapshot) -> void:
	var light_obj: Object = _sun_light_ref.get_ref() if _sun_light_ref != null else null
	var light: DirectionalLight3D = light_obj as DirectionalLight3D
	if light != null:
		light.light_color = snap.sun_light_color
		light.light_energy = snap.sun_light_energy


func _rebuild_region_tiles(snap: Steppe3DMapViewModel.MapSnapshot) -> void:
	_region_colors.clear()
	if _overlay_tiles_mm == null or _overlay_tiles_mm.multimesh == null:
		return
	var mm: MultiMesh = _overlay_tiles_mm.multimesh
	mm.instance_count = snap.regions.size()
	for i: int in range(snap.regions.size()):
		var r: Steppe3DMapViewModel.RegionVisualEntry = snap.regions[i]
		_region_colors[r.coord] = r.lens_color
		var tile_w: float = maxf(r.tile_size_m * 0.92, 1.0)
		var h: float = 0.16 + r.highlight_height_m
		var y_base: float = 0.45 + r.elevation * 1.2 + h * 0.5
		var xf: Transform3D = Transform3D(Basis.from_scale(Vector3(tile_w, h, tile_w)), Vector3(r.world_center.x, y_base, r.world_center.z))
		mm.set_instance_transform(i, xf)
		mm.set_instance_color(i, r.lens_color)


func _rebuild_kurgans(snap: Steppe3DMapViewModel.MapSnapshot) -> void:
	if _kurgans_mm == null or _kurgans_mm.multimesh == null:
		return
	var kurgans: Array[Steppe3DMapViewModel.RegionVisualEntry] = []
	for r: Steppe3DMapViewModel.RegionVisualEntry in snap.regions:
		if r.has_sacred_kurgan:
			kurgans.append(r)
	var mm: MultiMesh = _kurgans_mm.multimesh
	mm.instance_count = kurgans.size()
	for i: int in range(kurgans.size()):
		var kr: Steppe3DMapViewModel.RegionVisualEntry = kurgans[i]
		var xf: Transform3D = Transform3D(Basis.from_scale(Vector3(1.8, 3.6, 1.8)), Vector3(kr.world_center.x, 2.2, kr.world_center.z))
		mm.set_instance_transform(i, xf)
		var k_col: Color = NeoSteppePalette.JADE_BRIGHT if kr.owner_id == snap.player_id else NeoSteppePalette.GOLD_TAMGA
		mm.set_instance_color(i, k_col)


func _rebuild_water_nodes(snap: Steppe3DMapViewModel.MapSnapshot) -> void:
	if _water_nodes_mm == null or _water_nodes_mm.multimesh == null:
		return
	var mm: MultiMesh = _water_nodes_mm.multimesh
	mm.instance_count = snap.water_nodes.size()
	for i: int in range(snap.water_nodes.size()):
		var w: Steppe3DMapViewModel.WaterVisualEntry = snap.water_nodes[i]
		var scale_m: float = 2.4 if snap.active_lens == GameEnums.TacticalMapLens.LOGISTICS_WATER_COURIER else 1.5
		var xf: Transform3D = Transform3D(Basis.from_scale(Vector3(scale_m, 0.45, scale_m)), w.world_pos)
		mm.set_instance_transform(i, xf)
		var col: Color = NeoSteppePalette.EMBER_RED if (w.sabotaged or not w.usable) else NeoSteppePalette.ICE_BLUE
		mm.set_instance_color(i, col)


func _rebuild_tug_rings(snap: Steppe3DMapViewModel.MapSnapshot) -> void:
	if _tug_rings_mm == null or _tug_rings_mm.multimesh == null:
		return
	var mm: MultiMesh = _tug_rings_mm.multimesh
	mm.instance_count = snap.tug_rings.size()
	for i: int in range(snap.tug_rings.size()):
		var tr: Steppe3DMapViewModel.TugRingEntry = snap.tug_rings[i]
		var diam: float = clampf(tr.radius_m * 0.14, 3.0, 26.0)
		var xf: Transform3D = Transform3D(Basis.from_scale(Vector3(diam, 0.20, diam)), Vector3(tr.world_pos.x, 0.85, tr.world_pos.z))
		mm.set_instance_transform(i, xf)
		var col: Color = NeoSteppePalette.EMBER_RED if tr.overlapping_enemy else (NeoSteppePalette.JADE_BRIGHT if tr.owner_id == snap.player_id else NeoSteppePalette.GOLD_TAMGA)
		mm.set_instance_color(i, Color(col.r, col.g, col.b, 0.55 if snap.active_lens == GameEnums.TacticalMapLens.TUG_CONTROL else 0.28))


func _rebuild_routes(snap: Steppe3DMapViewModel.MapSnapshot) -> void:
	if _routes_mm == null or _routes_mm.multimesh == null:
		return
	var mm: MultiMesh = _routes_mm.multimesh
	mm.instance_count = snap.routes.size()
	for i: int in range(snap.routes.size()):
		var rm: Steppe3DMapViewModel.RouteMarkerEntry = snap.routes[i]
		var marker_scale: Vector3 = Vector3(1.6, 1.0, 2.2) if rm.kind == &"caravan" else Vector3(1.1, 1.8, 1.1)
		var pos: Vector3 = Vector3(rm.current_pos.x, 1.4, rm.current_pos.z)
		mm.set_instance_transform(i, Transform3D(Basis.from_scale(marker_scale), pos))
		var col: Color = NeoSteppePalette.EMBER_RED
		if rm.status_tag == &"en_route":
			col = NeoSteppePalette.GOLD_TAMGA if rm.kind == &"caravan" else NeoSteppePalette.ICE_FROST
		mm.set_instance_color(i, col)


func _sync_army_markers(snap: Steppe3DMapViewModel.MapSnapshot) -> void:
	if _armies_root == null:
		return
	var active_ids: Dictionary[int, bool] = {}
	for a: Steppe3DMapViewModel.ArmyVisualEntry in snap.armies:
		active_ids[a.army_id] = true
		var rig: ArmyMarkerRig = _army_rigs.get(a.army_id, null)
		if rig == null:
			rig = _create_army_rig(a.army_id)
			_army_rigs[a.army_id] = rig
			_armies_root.add_child(rig.root)

		if rig.root.is_inside_tree():
			rig.root.global_position = a.world_position
		else:
			rig.root.position = a.world_position
		rig.root.rotation.y = a.facing_rad
		rig.shape_id = a.formation_shape
		rig.dust_veil.visible = a.dust_screen_active
		rig.selection_ring.visible = a.is_selected
		rig.alert_ring.visible = a.supply_isolated or a.plan_exposed

		_update_banner_color(rig.core_banner, NeoSteppePalette.JADE_BRIGHT if a.owner_id == snap.player_id else NeoSteppePalette.EMBER_RED)
		_apply_formation_silhouette(rig, a)

	var stale_ids: Array[int] = []
	for existing_id: int in _army_rigs:
		if not active_ids.has(existing_id):
			stale_ids.append(existing_id)
	for sid: int in stale_ids:
		var stale: ArmyMarkerRig = _army_rigs[sid]
		if stale.root != null and is_instance_valid(stale.root):
			if stale.root.get_parent() != null:
				stale.root.get_parent().remove_child(stale.root)
			stale.root.free()
		_army_rigs.erase(sid)


func _apply_formation_silhouette(rig: ArmyMarkerRig, entry: Steppe3DMapViewModel.ArmyVisualEntry) -> void:
	var offsets: Array[Vector3] = []
	var wing_scale: Vector3 = Vector3(0.75, 0.55, 0.75)
	var wing_color: Color = NeoSteppePalette.GOLD_TAMGA if entry.is_heavy_armor else NeoSteppePalette.JADE_PRIMARY

	if entry.formation_shape == &"kama":
		# Pointed Wedge Spearhead
		offsets = [
			Vector3(0.0, 0.4, -1.8),
			Vector3(-0.9, 0.4, -0.6),
			Vector3(0.9, 0.4, -0.6),
			Vector3(0.0, 0.4, 0.8),
		]
	elif entry.formation_shape == &"cember":
		# Araba Kalesi / Wagon Circle Laager
		offsets = [
			Vector3(1.6, 0.4, 0.0),
			Vector3(-1.6, 0.4, 0.0),
			Vector3(0.0, 0.4, 1.6),
			Vector3(0.0, 0.4, -1.6),
		]
		wing_color = NeoSteppePalette.BRONZE_WEATHERED
	elif entry.formation_shape == &"yipratma":
		# Staggered raiding echelon
		offsets = [
			Vector3(-1.5, 0.4, -1.2),
			Vector3(1.5, 0.4, -0.4),
			Vector3(-1.2, 0.4, 0.8),
			Vector3(1.4, 0.4, 1.4),
		]
		wing_color = NeoSteppePalette.ICE_BLUE
	else:
		# Hilal / Crescent Envelopment Wings
		var span: float = lerpf(1.4, 2.4, clampf(entry.flank_ratio, 0.0, 1.0))
		offsets = [
			Vector3(-span, 0.4, -1.2),
			Vector3(-span * 0.55, 0.4, 0.2),
			Vector3(span * 0.55, 0.4, 0.2),
			Vector3(span, 0.4, -1.2),
		]

	for idx: int in range(mini(rig.wing_meshes.size(), offsets.size())):
		var wm: MeshInstance3D = rig.wing_meshes[idx]
		wm.position = offsets[idx]
		wm.scale = wing_scale
		_update_banner_color(wm, wing_color)


func _create_army_rig(army_id: int) -> ArmyMarkerRig:
	var root: Node3D = Node3D.new()
	root.name = "ArmyMarker_%d" % army_id

	var banner_mesh: BoxMesh = BoxMesh.new()
	banner_mesh.size = Vector3(0.9, 2.6, 0.9)
	var banner: MeshInstance3D = MeshInstance3D.new()
	banner.name = "CoreBanner"
	banner.mesh = banner_mesh
	banner.position = Vector3(0.0, 1.3, 0.0)
	banner.material_override = _make_unlit_mat(NeoSteppePalette.JADE_BRIGHT)
	root.add_child(banner)

	var wings_root: Node3D = Node3D.new()
	wings_root.name = "FormationWings"
	root.add_child(wings_root)

	var wings: Array[MeshInstance3D] = []
	for i: int in range(4):
		var w_box: BoxMesh = BoxMesh.new()
		w_box.size = Vector3(0.7, 0.6, 0.7)
		var wm: MeshInstance3D = MeshInstance3D.new()
		wm.name = "Wing_%d" % i
		wm.mesh = w_box
		wm.material_override = _make_unlit_mat(NeoSteppePalette.GOLD_TAMGA)
		wings_root.add_child(wm)
		wings.append(wm)

	var dust_cyl: CylinderMesh = CylinderMesh.new()
	dust_cyl.top_radius = 4.2
	dust_cyl.bottom_radius = 4.6
	dust_cyl.height = 0.35
	var dust: MeshInstance3D = MeshInstance3D.new()
	dust.name = "DustVeilMesh"
	dust.mesh = dust_cyl
	dust.position = Vector3(0.0, 0.55, 0.0)
	dust.visible = false
	var dust_mat: StandardMaterial3D = _make_unlit_mat(Color(0.84, 0.68, 0.38, 0.38))
	dust_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dust.material_override = dust_mat
	root.add_child(dust)

	var sel_cyl: CylinderMesh = CylinderMesh.new()
	sel_cyl.top_radius = 2.3
	sel_cyl.bottom_radius = 2.5
	sel_cyl.height = 0.12
	var sel: MeshInstance3D = MeshInstance3D.new()
	sel.name = "SelectionRing"
	sel.mesh = sel_cyl
	sel.position = Vector3(0.0, 0.35, 0.0)
	sel.visible = false
	sel.material_override = _make_unlit_mat(NeoSteppePalette.GOLD_PALE)
	root.add_child(sel)

	var al_cyl: CylinderMesh = CylinderMesh.new()
	al_cyl.top_radius = 2.8
	al_cyl.bottom_radius = 3.0
	al_cyl.height = 0.10
	var alert: MeshInstance3D = MeshInstance3D.new()
	alert.name = "AlertRing"
	alert.mesh = al_cyl
	alert.position = Vector3(0.0, 0.25, 0.0)
	alert.visible = false
	alert.material_override = _make_unlit_mat(NeoSteppePalette.EMBER_RED)
	root.add_child(alert)

	return ArmyMarkerRig.new(root, banner, wings_root, wings, dust, sel, alert)


func _ensure_visual_layers() -> void:
	if _meshes_built:
		return
	_meshes_built = true

	var tile_box: BoxMesh = BoxMesh.new()
	tile_box.size = Vector3.ONE
	_overlay_tiles_mm = _create_multimesh("RegionOverlayTiles", tile_box, false)

	var kurgan_cyl: CylinderMesh = CylinderMesh.new()
	kurgan_cyl.top_radius = 0.25
	kurgan_cyl.bottom_radius = 0.8
	kurgan_cyl.height = 1.0
	_kurgans_mm = _create_multimesh("SacredKurganObelisks", kurgan_cyl, false)

	var water_cyl: CylinderMesh = CylinderMesh.new()
	water_cyl.top_radius = 0.5
	water_cyl.bottom_radius = 0.6
	water_cyl.height = 1.0
	_water_nodes_mm = _create_multimesh("WaterSourceMarkers", water_cyl, false)

	var tug_cyl: CylinderMesh = CylinderMesh.new()
	tug_cyl.top_radius = 0.5
	tug_cyl.bottom_radius = 0.5
	tug_cyl.height = 1.0
	_tug_rings_mm = _create_multimesh("TugSphereRings", tug_cyl, true)

	var route_box: BoxMesh = BoxMesh.new()
	route_box.size = Vector3.ONE
	_routes_mm = _create_multimesh("CaravanCourierMarkers", route_box, false)

	_armies_root = Node3D.new()
	_armies_root.name = "ArmyMarkersRoot"
	add_child(_armies_root)


func _create_multimesh(node_name: String, mesh: PrimitiveMesh, alpha_blend: bool) -> MultiMeshInstance3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	if alpha_blend:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material = mat
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	var inst: MultiMeshInstance3D = MultiMeshInstance3D.new()
	inst.name = node_name
	inst.multimesh = mm
	add_child(inst)
	return inst


func _make_unlit_mat(col: Color) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = col
	return mat


func _update_banner_color(mesh_inst: MeshInstance3D, col: Color) -> void:
	if mesh_inst == null:
		return
	var mat: StandardMaterial3D = mesh_inst.material_override as StandardMaterial3D
	if mat != null:
		mat.albedo_color = col


func _clear_army_rigs() -> void:
	for aid: int in _army_rigs:
		var rig: ArmyMarkerRig = _army_rigs[aid]
		if rig != null and rig.root != null and is_instance_valid(rig.root):
			if rig.root.get_parent() != null:
				rig.root.get_parent().remove_child(rig.root)
			rig.root.free()
	_army_rigs.clear()


func _connect_bus() -> void:
	if _signals_connected:
		return
	_signals_connected = true
	_subscribe_bus(EventBus.macro_world_generated, _on_macro_world_generated)
	_subscribe_bus(EventBus.tactical_lens_changed, _on_tactical_lens_changed)
	_subscribe_bus(EventBus.season_changed, _on_world_dirty.unbind(2))
	_subscribe_bus(EventBus.zud_starvation_ticked, _on_world_dirty.unbind(2))
	_subscribe_bus(EventBus.region_control_changed, _on_world_dirty.unbind(5))
	_subscribe_bus(EventBus.border_node_captured, _on_world_dirty.unbind(6))
	_subscribe_bus(EventBus.water_source_sabotaged, _on_world_dirty.unbind(4))
	_subscribe_bus(EventBus.water_source_restored, _on_world_dirty.unbind(3))
	_subscribe_bus(EventBus.caravan_dispatched, _on_world_dirty.unbind(5))
	_subscribe_bus(EventBus.caravan_delivered, _on_world_dirty.unbind(5))
	_subscribe_bus(EventBus.caravan_intercepted_crisis, _on_world_dirty.unbind(6))
	_subscribe_bus(EventBus.courier_dispatched, _on_world_dirty.unbind(4))
	_subscribe_bus(EventBus.courier_order_delivered, _on_world_dirty.unbind(4))
	_subscribe_bus(EventBus.courier_ambushed_plan_exposed, _on_world_dirty.unbind(4))
	_subscribe_bus(EventBus.battle_doctrine_assigned, _on_world_dirty.unbind(4))
	_subscribe_bus(EventBus.dust_decoy_toggled, _on_world_dirty.unbind(3))
	_subscribe_bus(EventBus.systemic_synergy_evaluated, _on_world_dirty.unbind(1))
	_subscribe_bus(EventBus.supply_line_severed, _on_world_dirty.unbind(4))
	_subscribe_bus(EventBus.supply_line_restored, _on_world_dirty.unbind(2))
	_subscribe_bus(EventBus.army_move_ordered, _on_world_dirty.unbind(2))
	_subscribe_bus(EventBus.army_destination_reached, _on_world_dirty.unbind(2))
	_subscribe_bus(EventBus.session_tempo_changed, _on_world_dirty.unbind(4))


func _subscribe_bus(bus_signal: Signal, callback: Callable) -> void:
	if not bus_signal.is_connected(callback):
		bus_signal.connect(callback)
	_bus_subs.append(BusSub.new(bus_signal, callback))


func _disconnect_bus() -> void:
	for sub: BusSub in _bus_subs:
		if sub.bus_signal.is_connected(sub.callback):
			sub.bus_signal.disconnect(sub.callback)
	_bus_subs.clear()
	_signals_connected = false


func _on_macro_world_generated(world_state: MacroWorldState) -> void:
	get_view_model().set_macro_world_state(world_state)
	sync_from_viewmodel()


func _on_tactical_lens_changed(_prev: GameEnums.TacticalMapLens, next_lens: GameEnums.TacticalMapLens) -> void:
	get_view_model().set_active_lens(next_lens)
	sync_from_viewmodel()


func _on_world_dirty() -> void:
	sync_from_viewmodel()
