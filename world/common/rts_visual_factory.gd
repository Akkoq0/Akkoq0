class_name RtsVisualFactory
extends RefCounted
## World Visual Factory (rank 3).
## Single unified entry point for all 3D buildings, unit formations, ore veins,
## trees, world-space HP bars, and combat VFX.
## Automatically loads drop-in `.glb` models from `res://assets/models/` if present,
## otherwise constructs rich multi-part procedural PBR Steppe architecture/units.

const MODEL_SLOTS: Dictionary[StringName, String] = {
	&"ger_camp": "res://assets/models/otag.glb",
	&"nomadic_forge": "res://assets/models/kisla_ocak.glb",
	&"quarry": "res://assets/models/tas_ocagi.glb",
	&"kurgan_shrine": "res://assets/models/kurgan.glb",
	&"horse_archer": "res://assets/models/atli_okcu.glb",
	&"heavy_lancer": "res://assets/models/agir_suvari.glb",
	&"supply_ox": "res://assets/models/ikmal_okuzu.glb",
	&"pine_tree": "res://assets/models/cam_agaci.glb",
}

static var _cached_mats: Dictionary[StringName, StandardMaterial3D] = {}


static func create_building_visual(building_id: StringName, owner_id: int, is_hq: bool = false) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "Visual_%s" % String(building_id)
	var faction_col: Color = get_faction_color(owner_id)

	var glb_node: Node3D = _try_load_glb(building_id, 4.2 if is_hq else 3.4)
	if glb_node != null:
		root.add_child(glb_node)
		_add_banner_pole(root, Vector3(2.2, 0.0, 1.8), 4.2 if is_hq else 3.2, faction_col)
		return root

	match building_id:
		&"ger_camp":
			_build_otag_mesh(root, faction_col, is_hq)
		&"nomadic_forge":
			_build_forge_mesh(root, faction_col)
		&"quarry":
			_build_quarry_mesh(root, faction_col)
		&"kurgan_shrine":
			_build_kurgan_mesh(root, faction_col)
		_:
			_build_otag_mesh(root, faction_col, is_hq)
	return root


static func create_unit_visual(unit_id: StringName, owner_id: int) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "Squad_%s" % String(unit_id)
	var faction_col: Color = get_faction_color(owner_id)

	var glb_node: Node3D = _try_load_glb(unit_id, 2.0)
	if glb_node != null:
		root.add_child(glb_node)
		_add_banner_pole(root, Vector3(0.0, 0.0, 0.0), 2.8, faction_col)
		return root

	match unit_id:
		&"heavy_lancer":
			_build_heavy_lancer_squad(root, faction_col)
		&"supply_ox":
			_build_supply_ox_convoy(root, faction_col)
		_:
			_build_horse_archer_squad(root, faction_col)
	return root


static func create_ore_deposit_visual(ore_id: StringName, ore_color: Color) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "OreVein_%s" % String(ore_id)

	var rock_mat: StandardMaterial3D = _get_mat(&"rock_dark", Color(0.28, 0.27, 0.26, 1.0), 0.92, 0.05)
	var vein_mat: StandardMaterial3D = _get_mat(StringName("ore_" + String(ore_id)), ore_color.darkened(0.15), 0.45, 0.65)

	var offsets: Array[Vector3] = [
		Vector3(0.0, 0.45, 0.0),
		Vector3(0.75, 0.30, 0.40),
		Vector3(-0.65, 0.28, 0.55),
		Vector3(-0.35, 0.32, -0.60),
	]
	var scales: Array[Vector3] = [
		Vector3(1.4, 1.1, 1.2),
		Vector3(0.95, 0.75, 0.85),
		Vector3(0.85, 0.65, 0.90),
		Vector3(1.0, 0.72, 0.80),
	]
	for i: int in range(offsets.size()):
		var boulder: MeshInstance3D = MeshInstance3D.new()
		var pm: PrismMesh = PrismMesh.new()
		pm.size = scales[i]
		boulder.mesh = pm
		boulder.position = offsets[i]
		boulder.rotation_degrees = Vector3(float(i * 11 - 8), float(i * 47), float(i * 7 - 5))
		boulder.material_override = rock_mat
		boulder.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		root.add_child(boulder)

		if i < 2:
			var seam: MeshInstance3D = MeshInstance3D.new()
			var bm: BoxMesh = BoxMesh.new()
			bm.size = scales[i] * Vector3(0.45, 0.40, 0.45)
			seam.mesh = bm
			seam.position = offsets[i] + Vector3(0.15, 0.12, 0.12)
			seam.rotation_degrees = Vector3(12.0, float(i * 55), 18.0)
			seam.material_override = vein_mat
			root.add_child(seam)

	return root


static func create_pine_tree_mesh() -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Trunk (brown timber)
	var trunk_col: Color = Color(0.26, 0.17, 0.11, 1.0)
	_append_cone_to_st(st, Vector3(0.0, 0.0, 0.0), 0.24, 0.15, 2.2, 6, trunk_col)

	# 3-tier pine foliage (natural dark forest green, zero cartoon neon)
	_append_cone_to_st(st, Vector3(0.0, 1.7, 0.0), 1.55, 0.22, 2.3, 7, Color(0.14, 0.23, 0.14, 1.0))
	_append_cone_to_st(st, Vector3(0.0, 3.1, 0.0), 1.20, 0.16, 2.0, 7, Color(0.16, 0.26, 0.15, 1.0))
	_append_cone_to_st(st, Vector3(0.0, 4.4, 0.0), 0.80, 0.04, 1.7, 7, Color(0.19, 0.29, 0.17, 1.0))

	st.generate_normals()
	return st.commit()


static func create_health_bar_3d(width_m: float, height_m: float, y_offset: float) -> Node3D:
	var container: Node3D = Node3D.new()
	container.name = "HpBar3D"
	container.position = Vector3(0.0, y_offset, 0.0)

	var bg: MeshInstance3D = MeshInstance3D.new()
	bg.name = "Bg"
	var bg_quad: QuadMesh = QuadMesh.new()
	bg_quad.size = Vector2(width_m + 0.12, height_m + 0.08)
	bg.mesh = bg_quad
	var bg_mat: StandardMaterial3D = StandardMaterial3D.new()
	bg_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bg_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	bg_mat.albedo_color = Color(0.06, 0.06, 0.07, 0.88)
	bg_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bg.material_override = bg_mat
	bg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	container.add_child(bg)

	var fill: MeshInstance3D = MeshInstance3D.new()
	fill.name = "Fill"
	var fill_quad: QuadMesh = QuadMesh.new()
	fill_quad.size = Vector2(width_m, height_m)
	fill.mesh = fill_quad
	fill.position = Vector3(0.0, 0.0, 0.02)
	var fill_mat: StandardMaterial3D = StandardMaterial3D.new()
	fill_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fill_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	fill_mat.albedo_color = Color(0.24, 0.78, 0.36, 1.0)
	fill.material_override = fill_mat
	fill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	container.add_child(fill)

	return container


static func update_health_bar_3d(bar_root: Node3D, hp: float, max_hp: float, owner_id: int) -> void:
	if bar_root == null or not is_instance_valid(bar_root):
		return
	var fill: MeshInstance3D = bar_root.get_node_or_null("Fill") as MeshInstance3D
	if fill == null:
		return
	var ratio: float = clampf(hp / maxf(max_hp, 1.0), 0.0, 1.0)
	fill.scale.x = maxf(ratio, 0.02)
	var fmat: StandardMaterial3D = fill.material_override as StandardMaterial3D
	if fmat != null:
		if owner_id == 1:
			fmat.albedo_color = Color(0.22, 0.76, 0.42, 1.0) if ratio > 0.35 else Color(0.95, 0.65, 0.18, 1.0)
		else:
			fmat.albedo_color = Color(0.88, 0.24, 0.22, 1.0)


static func create_selection_ring(radius_m: float, color: Color) -> MeshInstance3D:
	var ring: MeshInstance3D = MeshInstance3D.new()
	ring.name = "SelectionRing"
	var torus: TorusMesh = TorusMesh.new()
	torus.inner_radius = maxf(radius_m - 0.16, 0.2)
	torus.outer_radius = radius_m
	torus.rings = 24
	torus.ring_segments = 8
	ring.mesh = torus
	ring.scale = Vector3(1.0, 0.18, 1.0)
	ring.position = Vector3(0.0, 0.12, 0.0)
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.material_override = mat
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return ring


static func get_faction_color(owner_id: int) -> Color:
	return Color(0.20, 0.56, 0.88, 1.0) if owner_id == 1 else Color(0.82, 0.22, 0.20, 1.0)


static func _try_load_glb(slot_id: StringName, target_width: float) -> Node3D:
	var path: String = MODEL_SLOTS.get(slot_id, "")
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var res: Resource = ResourceLoader.load(path)
	if not (res is PackedScene):
		return null
	var packed: PackedScene = res as PackedScene
	var inst: Node = packed.instantiate()
	if not (inst is Node3D):
		if inst != null:
			inst.queue_free()
		return null
	var n3d: Node3D = inst as Node3D
	var bounds: AABB = _compute_combined_aabb(n3d)
	if bounds.size.length() > 0.001:
		var max_xz: float = maxf(bounds.size.x, bounds.size.z)
		if max_xz > 0.01:
			var sc: float = target_width / max_xz
			n3d.scale = Vector3.ONE * sc
			n3d.position.y = -bounds.position.y * sc
	return n3d


static func _compute_combined_aabb(node: Node3D) -> AABB:
	var combined: AABB = AABB()
	var has_box: bool = false
	if node is VisualInstance3D:
		combined = (node as VisualInstance3D).get_aabb()
		has_box = true
	for ch: Node in node.get_children():
		if ch is Node3D:
			var sub: AABB = _compute_combined_aabb(ch as Node3D)
			if sub.size.length() > 0.001:
				combined = combined.merge(sub) if has_box else sub
				has_box = true
	return combined


static func _build_otag_mesh(root: Node3D, faction_col: Color, is_hq: bool) -> void:
	var sc: float = 1.25 if is_hq else 0.95
	var felt_mat: StandardMaterial3D = _get_mat(&"felt", Color(0.75, 0.70, 0.60, 1.0), 0.92, 0.0)
	var wood_mat: StandardMaterial3D = _get_mat(&"wood", Color(0.34, 0.22, 0.13, 1.0), 0.88, 0.0)
	var trim_mat: StandardMaterial3D = _get_mat(&"gold_trim", Color(0.72, 0.56, 0.24, 1.0), 0.45, 0.55)
	var stone_mat: StandardMaterial3D = _get_mat(&"stone_base", Color(0.36, 0.35, 0.32, 1.0), 0.92, 0.05)

	# Stone foundation ring
	_add_cyl(root, Vector3(0.0, 0.15 * sc, 0.0), 2.35 * sc, 2.45 * sc, 0.30 * sc, stone_mat)
	# Felt yurt cylinder wall
	_add_cyl(root, Vector3(0.0, 0.95 * sc, 0.0), 2.05 * sc, 2.15 * sc, 1.35 * sc, felt_mat)
	# Decorative woven band
	_add_cyl(root, Vector3(0.0, 1.48 * sc, 0.0), 2.08 * sc, 2.08 * sc, 0.22 * sc, trim_mat)
	# Conical dome roof
	_add_cyl(root, Vector3(0.0, 2.20 * sc, 0.0), 0.32 * sc, 2.18 * sc, 1.25 * sc, _get_mat(&"roof_felt", Color(0.62, 0.54, 0.42, 1.0), 0.90, 0.0))
	# Tündük wooden smoke ring at apex
	_add_cyl(root, Vector3(0.0, 2.86 * sc, 0.0), 0.38 * sc, 0.38 * sc, 0.18 * sc, wood_mat)
	# Timber door frame facing +Z
	_add_box(root, Vector3(0.0, 0.72 * sc, 2.05 * sc), Vector3(0.95 * sc, 1.25 * sc, 0.35 * sc), wood_mat)

	if is_hq:
		# Two smaller guard yurts beside the Khan Otağ
		for sx: float in [-3.1, 3.1]:
			_add_cyl(root, Vector3(sx, 0.52, -1.3), 0.95, 1.05, 0.85, felt_mat)
			_add_cyl(root, Vector3(sx, 1.22, -1.3), 0.15, 1.05, 0.65, wood_mat)

	_add_banner_pole(root, Vector3(1.9 * sc, 0.0, 1.8 * sc), 4.2 * sc, faction_col)


static func _build_forge_mesh(root: Node3D, faction_col: Color) -> void:
	var wood_mat: StandardMaterial3D = _get_mat(&"wood", Color(0.32, 0.20, 0.12, 1.0), 0.88, 0.0)
	var stone_mat: StandardMaterial3D = _get_mat(&"stone_base", Color(0.35, 0.34, 0.33, 1.0), 0.90, 0.05)
	var iron_mat: StandardMaterial3D = _get_mat(&"forged_iron", Color(0.20, 0.21, 0.24, 1.0), 0.42, 0.78)
	var ember_mat: StandardMaterial3D = _get_mat(&"forge_ember", Color(0.95, 0.42, 0.10, 1.0), 0.3, 0.0, Color(1.0, 0.45, 0.08, 1.0), 2.2)

	# Stone hearth & chimney
	_add_box(root, Vector3(-0.7, 0.9, -0.5), Vector3(1.5, 1.8, 1.4), stone_mat)
	_add_box(root, Vector3(-0.7, 2.2, -0.5), Vector3(0.85, 1.1, 0.85), stone_mat)
	# Glowing coal furnace mouth
	_add_box(root, Vector3(-0.7, 0.55, 0.25), Vector3(0.65, 0.55, 0.20), ember_mat)
	# Timber shed canopy posts & roof
	for px: float in [-1.8, 1.6]:
		for pz: float in [-1.6, 1.5]:
			_add_box(root, Vector3(px, 1.1, pz), Vector3(0.22, 2.2, 0.22), wood_mat)
	_add_box(root, Vector3(0.0, 2.25, 0.0), Vector3(3.8, 0.20, 3.4), wood_mat, Vector3(8.0, 0.0, 0.0))
	# Anvil & Palisade fence segments
	_add_box(root, Vector3(0.85, 0.45, 0.45), Vector3(0.65, 0.55, 0.40), iron_mat)
	_add_box(root, Vector3(1.9, 0.65, 0.0), Vector3(0.22, 1.3, 3.2), wood_mat)
	_add_banner_pole(root, Vector3(1.9, 0.0, 1.7), 3.6, faction_col)


static func _build_quarry_mesh(root: Node3D, faction_col: Color) -> void:
	var stone_mat: StandardMaterial3D = _get_mat(&"quarry_stone", Color(0.46, 0.45, 0.42, 1.0), 0.92, 0.05)
	var wood_mat: StandardMaterial3D = _get_mat(&"wood", Color(0.35, 0.23, 0.14, 1.0), 0.88, 0.0)

	# Stepped rock benches
	_add_box(root, Vector3(-0.6, 0.45, -0.6), Vector3(2.8, 0.9, 2.4), stone_mat)
	_add_box(root, Vector3(-0.9, 1.15, -0.9), Vector3(1.9, 0.7, 1.6), stone_mat)
	# Stacked cut stone blocks
	_add_box(root, Vector3(1.2, 0.32, 0.8), Vector3(0.7, 0.55, 0.6), stone_mat)
	_add_box(root, Vector3(1.4, 0.32, 0.0), Vector3(0.6, 0.55, 0.6), stone_mat)
	# Timber crane A-frame
	_add_box(root, Vector3(0.3, 1.4, 1.1), Vector3(0.18, 2.8, 0.18), wood_mat, Vector3(0.0, 0.0, -18.0))
	_add_box(root, Vector3(1.1, 1.4, 1.1), Vector3(0.18, 2.8, 0.18), wood_mat, Vector3(0.0, 0.0, 18.0))
	_add_box(root, Vector3(0.7, 2.55, 0.65), Vector3(0.18, 0.18, 2.1), wood_mat, Vector3(-12.0, 0.0, 0.0))
	_add_banner_pole(root, Vector3(-1.8, 0.0, 1.4), 3.2, faction_col)


static func _build_kurgan_mesh(root: Node3D, faction_col: Color) -> void:
	var stone_mat: StandardMaterial3D = _get_mat(&"kurgan_stone", Color(0.42, 0.40, 0.37, 1.0), 0.92, 0.05)
	var mound_mat: StandardMaterial3D = _get_mat(&"kurgan_earth", Color(0.34, 0.36, 0.24, 1.0), 0.94, 0.0)
	var flame_mat: StandardMaterial3D = _get_mat(&"kurgan_flame", Color(1.0, 0.62, 0.18, 1.0), 0.25, 0.0, Color(1.0, 0.58, 0.15, 1.0), 2.4)

	# Burial mound
	_add_cyl(root, Vector3(0.0, 0.55, 0.0), 1.4, 2.5, 1.1, mound_mat)
	_add_cyl(root, Vector3(0.0, 1.25, 0.0), 0.4, 1.45, 0.5, stone_mat)
	# Balbal standing stones around base
	for i: int in range(5):
		var ang: float = float(i) * TAU / 5.0
		var bx: float = cos(ang) * 2.25
		var bz: float = sin(ang) * 2.25
		_add_box(root, Vector3(bx, 0.65, bz), Vector3(0.34, 1.25, 0.24), stone_mat, Vector3(0.0, rad_to_deg(-ang), 0.0))
	# Sacred brazier at top
	_add_cyl(root, Vector3(0.0, 1.62, 0.0), 0.32, 0.22, 0.26, flame_mat)
	_add_banner_pole(root, Vector3(1.5, 0.0, 1.8), 3.6, faction_col)


static func _build_horse_archer_squad(root: Node3D, faction_col: Color) -> void:
	var horse_mat: StandardMaterial3D = _get_mat(&"horse_bay", Color(0.36, 0.24, 0.15, 1.0), 0.78, 0.05)
	var rider_mat: StandardMaterial3D = _get_mat(StringName("rider_" + faction_col.to_html()), faction_col.darkened(0.15), 0.72, 0.15)
	var skin_mat: StandardMaterial3D = _get_mat(&"helm_steel", Color(0.55, 0.56, 0.58, 1.0), 0.45, 0.70)

	var offsets: Array[Vector3] = [
		Vector3(0.0, 0.0, -0.75),
		Vector3(-0.95, 0.0, 0.15),
		Vector3(0.95, 0.0, 0.15),
		Vector3(-1.55, 0.0, 1.05),
		Vector3(1.55, 0.0, 1.05),
	]
	for i: int in range(offsets.size()):
		_add_cavalry_figure(root, offsets[i], horse_mat, rider_mat, skin_mat, false)
	_add_banner_pole(root, Vector3(0.0, 0.0, -0.5), 2.7, faction_col)


static func _build_heavy_lancer_squad(root: Node3D, faction_col: Color) -> void:
	var horse_mat: StandardMaterial3D = _get_mat(&"horse_iron", Color(0.24, 0.22, 0.22, 1.0), 0.65, 0.25)
	var rider_mat: StandardMaterial3D = _get_mat(StringName("lancer_" + faction_col.to_html()), faction_col.darkened(0.10), 0.50, 0.45)
	var armor_mat: StandardMaterial3D = _get_mat(&"steel_armor", Color(0.58, 0.60, 0.64, 1.0), 0.35, 0.85)

	var offsets: Array[Vector3] = [
		Vector3(0.0, 0.0, -0.8),
		Vector3(-0.85, 0.0, -0.1),
		Vector3(0.85, 0.0, -0.1),
		Vector3(-1.1, 0.0, 0.85),
		Vector3(1.1, 0.0, 0.85),
	]
	for i: int in range(offsets.size()):
		_add_cavalry_figure(root, offsets[i], horse_mat, rider_mat, armor_mat, true)
	_add_banner_pole(root, Vector3(0.0, 0.0, 0.1), 3.0, faction_col)


static func _build_supply_ox_convoy(root: Node3D, faction_col: Color) -> void:
	var ox_mat: StandardMaterial3D = _get_mat(&"ox_fur", Color(0.30, 0.24, 0.18, 1.0), 0.88, 0.0)
	var wood_mat: StandardMaterial3D = _get_mat(&"wood", Color(0.38, 0.25, 0.14, 1.0), 0.88, 0.0)
	var cargo_mat: StandardMaterial3D = _get_mat(&"felt", Color(0.72, 0.65, 0.52, 1.0), 0.90, 0.0)

	# Two oxen in front
	for sx: float in [-0.45, 0.45]:
		_add_box(root, Vector3(sx, 0.52, -0.95), Vector3(0.45, 0.58, 1.05), ox_mat)
		_add_box(root, Vector3(sx, 0.72, -1.55), Vector3(0.32, 0.32, 0.34), ox_mat)
	# Heavy wagon bed & canvas cargo
	_add_box(root, Vector3(0.0, 0.58, 0.55), Vector3(1.35, 0.45, 1.75), wood_mat)
	_add_cyl(root, Vector3(0.0, 0.95, 0.55), 0.58, 0.62, 1.45, cargo_mat, Vector3(90.0, 0.0, 0.0))
	for wx: float in [-0.72, 0.72]:
		for wz: float in [-0.05, 1.15]:
			_add_cyl(root, Vector3(wx, 0.34, wz), 0.34, 0.34, 0.12, wood_mat, Vector3(0.0, 0.0, 90.0))
	_add_banner_pole(root, Vector3(0.65, 0.0, 1.25), 2.4, faction_col)


static func _add_cavalry_figure(
		root: Node3D,
		offset: Vector3,
		horse_mat: StandardMaterial3D,
		rider_mat: StandardMaterial3D,
		metal_mat: StandardMaterial3D,
		with_lance: bool) -> void:
	# Horse body + legs + neck/head
	_add_box(root, offset + Vector3(0.0, 0.62, 0.0), Vector3(0.38, 0.42, 0.95), horse_mat)
	_add_box(root, offset + Vector3(0.0, 0.92, -0.45), Vector3(0.22, 0.42, 0.32), horse_mat, Vector3(25.0, 0.0, 0.0))
	for lx: float in [-0.12, 0.12]:
		for lz: float in [-0.32, 0.32]:
			_add_box(root, offset + Vector3(lx, 0.24, lz), Vector3(0.09, 0.48, 0.09), horse_mat)
	# Rider torso + helmet
	_add_box(root, offset + Vector3(0.0, 1.08, 0.02), Vector3(0.32, 0.46, 0.24), rider_mat)
	_add_cyl(root, offset + Vector3(0.0, 1.44, 0.02), 0.06, 0.13, 0.22, metal_mat)
	if with_lance:
		_add_cyl(root, offset + Vector3(0.22, 1.35, -0.45), 0.025, 0.03, 1.85, metal_mat, Vector3(72.0, 0.0, 0.0))
	else:
		# Bow arc
		_add_box(root, offset + Vector3(-0.20, 1.16, -0.18), Vector3(0.05, 0.52, 0.14), metal_mat)


static func _add_banner_pole(root: Node3D, pos: Vector3, height: float, faction_col: Color) -> void:
	var wood_mat: StandardMaterial3D = _get_mat(&"wood", Color(0.30, 0.19, 0.11, 1.0), 0.85, 0.0)
	var flag_mat: StandardMaterial3D = _get_mat(StringName("flag_" + faction_col.to_html()), faction_col, 0.72, 0.05)
	_add_cyl(root, pos + Vector3(0.0, height * 0.5, 0.0), 0.05, 0.06, height, wood_mat)
	_add_box(root, pos + Vector3(0.45, height - 0.32, 0.0), Vector3(0.85, 0.48, 0.04), flag_mat)


static func _add_box(
		parent: Node3D,
		pos: Vector3,
		sz: Vector3,
		mat: StandardMaterial3D,
		rot_deg: Vector3 = Vector3.ZERO) -> void:
	var mi: MeshInstance3D = MeshInstance3D.new()
	var bm: BoxMesh = BoxMesh.new()
	bm.size = sz
	mi.mesh = bm
	mi.position = pos
	mi.rotation_degrees = rot_deg
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(mi)


static func _add_cyl(
		parent: Node3D,
		pos: Vector3,
		top_r: float,
		bot_r: float,
		h: float,
		mat: StandardMaterial3D,
		rot_deg: Vector3 = Vector3.ZERO) -> void:
	var mi: MeshInstance3D = MeshInstance3D.new()
	var cm: CylinderMesh = CylinderMesh.new()
	cm.top_radius = top_r
	cm.bottom_radius = bot_r
	cm.height = h
	cm.radial_segments = 10
	mi.mesh = cm
	mi.position = pos
	mi.rotation_degrees = rot_deg
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(mi)


static func _append_cone_to_st(
		st: SurfaceTool,
		base_pos: Vector3,
		bot_r: float,
		top_r: float,
		height: float,
		segs: int,
		col: Color) -> void:
	for i: int in range(segs):
		var a0: float = float(i) / float(segs) * TAU
		var a1: float = float(i + 1) / float(segs) * TAU
		var b0: Vector3 = base_pos + Vector3(cos(a0) * bot_r, 0.0, sin(a0) * bot_r)
		var b1: Vector3 = base_pos + Vector3(cos(a1) * bot_r, 0.0, sin(a1) * bot_r)
		var t0: Vector3 = base_pos + Vector3(cos(a0) * top_r, height, sin(a0) * top_r)
		var t1: Vector3 = base_pos + Vector3(cos(a1) * top_r, height, sin(a1) * top_r)
		st.set_color(col)
		st.add_vertex(b0)
		st.add_vertex(t0)
		st.add_vertex(t1)
		st.set_color(col.darkened(0.08))
		st.add_vertex(b0)
		st.add_vertex(t1)
		st.add_vertex(b1)


static func _get_mat(
		key: StringName,
		albedo: Color,
		rough: float,
		metal: float,
		emissive: Color = Color.BLACK,
		emit_energy: float = 0.0) -> StandardMaterial3D:
	if _cached_mats.has(key):
		return _cached_mats[key]
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = albedo
	m.roughness = rough
	m.metallic = metal
	if emit_energy > 0.0:
		m.emission_enabled = true
		m.emission = emissive
		m.emission_energy_multiplier = emit_energy
	_cached_mats[key] = m
	return m
