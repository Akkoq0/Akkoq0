class_name SteppePbrTerrain
extends Node3D
## Manor Lords-style Single-Piece PBR Steppe Terrain, River Water,
## Distant Mountain Rim, Golden-Hour Environment, and MultiMesh Foliage (rank 3).
## Strictly mobile-optimized: no SSR, no SDFGI, no Volumetric Fog.

const WORLD_SPAN_M: float = 160.0
const PLAYABLE_HALF_M: float = 58.0
const TERRAIN_RES: int = 112
const WATER_LEVEL_Y: float = -0.55

var _world_seed: int = 1071
var _elev_noise: FastNoiseLite = null
var _moisture_noise: FastNoiseLite = null
var _detail_noise: FastNoiseLite = null

var _terrain_mesh_inst: MeshInstance3D = null
var _water_mesh_inst: MeshInstance3D = null
var _world_env: WorldEnvironment = null
var _trees_mm: MultiMeshInstance3D = null
var _rocks_mm: MultiMeshInstance3D = null
var _grass_mm: MultiMeshInstance3D = null
var _ores_root: Node3D = null

var _cached_normal_tex: ImageTexture = null
var _cached_rough_tex: ImageTexture = null


func build_world(seed_val: int = 1071) -> void:
	_world_seed = maxi(seed_val, 1)
	_init_noise()
	_clear_children()
	_build_cached_pbr_maps()
	_build_environment()
	_build_terrain_mesh()
	_build_water_mesh()
	_build_foliage_multimeshes()
	_build_ore_vein_clusters()


func get_height_at(wx: float, wz: float) -> float:
	if _elev_noise == null:
		_init_noise()
	var n1: float = (_elev_noise.get_noise_2d(wx, wz) + 1.0) * 0.5
	var n2: float = (_detail_noise.get_noise_2d(wx, wz) + 1.0) * 0.5
	var base_h: float = (n1 * 3.8 + n2 * 1.1) - 0.35

	# Winding river channel across center with two passable fords
	var river_center_z: float = sin(wx * 0.045) * 14.0 - wx * 0.22
	var river_dist: float = absf(wz - river_center_z)
	var ford_a: float = Vector2(wx + 14.0, wz - (-14.0 * 0.22 + sin(-14.0 * 0.045) * 14.0)).length()
	var ford_b: float = Vector2(wx - 16.0, wz - (16.0 * 0.22 * -1.0 + sin(16.0 * 0.045) * 14.0)).length()
	var ford_blend: float = minf(clampf(ford_a / 8.5, 0.0, 1.0), clampf(ford_b / 8.5, 0.0, 1.0))

	if river_dist < 8.5:
		var t_riv: float = 1.0 - smoothstep_01(river_dist / 8.5)
		var channel_depth: float = lerpf(-0.22, -1.65, ford_blend)
		base_h = lerpf(base_h, channel_depth, t_riv)

	# Flatten SW (-34, 34) and NE (34, -34) base plateaus
	var d_sw: float = Vector2(wx + 34.0, wz - 34.0).length()
	var d_ne: float = Vector2(wx - 34.0, wz + 34.0).length()
	if d_sw < 16.0:
		base_h = lerpf(0.85, base_h, smoothstep_01(d_sw / 16.0))
	if d_ne < 16.0:
		base_h = lerpf(0.85, base_h, smoothstep_01(d_ne / 16.0))

	# Distant mountain rim outside playable boundary (eliminates void edge)
	var max_axis: float = maxf(absf(wx), absf(wz))
	if max_axis > PLAYABLE_HALF_M:
		var rim_t: float = clampf((max_axis - PLAYABLE_HALF_M) / 22.0, 0.0, 1.0)
		var ridge_noise: float = 0.55 + n1 * 0.85 + n2 * 0.35
		base_h += rim_t * rim_t * 22.0 * ridge_noise

	return base_h


func is_passable_at(wx: float, wz: float) -> bool:
	if absf(wx) > PLAYABLE_HALF_M or absf(wz) > PLAYABLE_HALF_M:
		return false
	return get_height_at(wx, wz) > -0.78


func get_minimap_grid(cols: int, rows: int, half_extent: float) -> PackedColorArray:
	var out: PackedColorArray = PackedColorArray()
	out.resize(cols * rows)
	for rz: int in range(rows):
		for rx: int in range(cols):
			var wx: float = ((float(rx) + 0.5) / float(cols) * 2.0 - 1.0) * half_extent
			var wz: float = ((float(rz) + 0.5) / float(rows) * 2.0 - 1.0) * half_extent
			var h: float = get_height_at(wx, wz)
			var col: Color = Color(0.28, 0.32, 0.19, 1.0)
			if h < WATER_LEVEL_Y:
				col = Color(0.14, 0.28, 0.34, 1.0)
			elif h < -0.1:
				col = Color(0.32, 0.29, 0.22, 1.0)
			elif h > 3.6:
				col = Color(0.38, 0.36, 0.33, 1.0)
			elif h > 2.2:
				col = Color(0.36, 0.35, 0.22, 1.0)
			out[rz * cols + rx] = col
	return out


func _init_noise() -> void:
	_elev_noise = FastNoiseLite.new()
	_elev_noise.seed = _world_seed
	_elev_noise.frequency = 0.022
	_elev_noise.fractal_octaves = 3

	_moisture_noise = FastNoiseLite.new()
	_moisture_noise.seed = _world_seed + 4099
	_moisture_noise.frequency = 0.030
	_moisture_noise.fractal_octaves = 2

	_detail_noise = FastNoiseLite.new()
	_detail_noise.seed = _world_seed + 9173
	_detail_noise.frequency = 0.075
	_detail_noise.fractal_octaves = 2


func _clear_children() -> void:
	for ch: Node in get_children():
		remove_child(ch)
		ch.queue_free()


func _build_cached_pbr_maps() -> void:
	if _cached_normal_tex != null and _cached_rough_tex != null:
		return
	var tex_noise: FastNoiseLite = FastNoiseLite.new()
	tex_noise.seed = _world_seed + 131
	tex_noise.frequency = 0.08
	tex_noise.fractal_octaves = 4

	var sz: int = 128
	var bump_img: Image = Image.create(sz, sz, false, Image.FORMAT_L8)
	var rough_img: Image = Image.create(sz, sz, false, Image.FORMAT_L8)
	for y: int in range(sz):
		for x: int in range(sz):
			var v: float = (tex_noise.get_noise_2d(float(x), float(y)) + 1.0) * 0.5
			bump_img.set_pixel(x, y, Color(v, v, v, 1.0))
			var rv: float = clampf(0.72 + (v - 0.5) * 0.35, 0.45, 0.96)
			rough_img.set_pixel(x, y, Color(rv, rv, rv, 1.0))

	var norm_img: Image = bump_img.duplicate()
	norm_img.bump_map_to_normal_map(2.2)
	_cached_normal_tex = ImageTexture.create_from_image(norm_img)
	_cached_rough_tex = ImageTexture.create_from_image(rough_img)


func _build_environment() -> void:
	var env: Environment = Environment.new()
	var sky: Sky = Sky.new()
	var sky_mat: ProceduralSkyMaterial = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.22, 0.31, 0.44, 1.0)
	sky_mat.sky_horizon_color = Color(0.76, 0.63, 0.46, 1.0)
	sky_mat.ground_bottom_color = Color(0.16, 0.15, 0.12, 1.0)
	sky_mat.ground_horizon_color = Color(0.58, 0.49, 0.38, 1.0)
	sky_mat.sun_angle_max = 16.0
	sky.sky_material = sky_mat

	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.42
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.fog_enabled = true
	env.fog_light_color = Color(0.54, 0.50, 0.43, 1.0)
	env.fog_density = 0.0020
	env.fog_aerial_perspective = 0.35
	env.fog_sky_affect = 0.20
	env.ssr_enabled = false
	env.sdfgi_enabled = false
	env.volumetric_fog_enabled = false

	_world_env = WorldEnvironment.new()
	_world_env.name = "SteppeWorldEnvironment"
	_world_env.environment = env
	add_child(_world_env)


func _build_terrain_mesh() -> void:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var half: float = WORLD_SPAN_M * 0.5
	var step: float = WORLD_SPAN_M / float(TERRAIN_RES)

	var heights: PackedFloat32Array = PackedFloat32Array()
	heights.resize((TERRAIN_RES + 1) * (TERRAIN_RES + 1))
	for z: int in range(TERRAIN_RES + 1):
		for x: int in range(TERRAIN_RES + 1):
			var wx: float = -half + float(x) * step
			var wz: float = -half + float(z) * step
			heights[z * (TERRAIN_RES + 1) + x] = get_height_at(wx, wz)

	for z: int in range(TERRAIN_RES):
		for x: int in range(TERRAIN_RES):
			var i00: int = z * (TERRAIN_RES + 1) + x
			var i10: int = i00 + 1
			var i01: int = i00 + (TERRAIN_RES + 1)
			var i11: int = i01 + 1

			var wx0: float = -half + float(x) * step
			var wx1: float = wx0 + step
			var wz0: float = -half + float(z) * step
			var wz1: float = wz0 + step

			var p00: Vector3 = Vector3(wx0, heights[i00], wz0)
			var p10: Vector3 = Vector3(wx1, heights[i10], wz0)
			var p01: Vector3 = Vector3(wx0, heights[i01], wz1)
			var p11: Vector3 = Vector3(wx1, heights[i11], wz1)

			var uv00: Vector2 = Vector2(float(x) / float(TERRAIN_RES), float(z) / float(TERRAIN_RES))
			var uv10: Vector2 = Vector2(float(x + 1) / float(TERRAIN_RES), float(z) / float(TERRAIN_RES))
			var uv01: Vector2 = Vector2(float(x) / float(TERRAIN_RES), float(z + 1) / float(TERRAIN_RES))
			var uv11: Vector2 = Vector2(float(x + 1) / float(TERRAIN_RES), float(z + 1) / float(TERRAIN_RES))

			_add_terrain_vert(st, p00, uv00)
			_add_terrain_vert(st, p10, uv10)
			_add_terrain_vert(st, p11, uv11)

			_add_terrain_vert(st, p00, uv00)
			_add_terrain_vert(st, p11, uv11)
			_add_terrain_vert(st, p01, uv01)

	st.generate_normals()
	_terrain_mesh_inst = MeshInstance3D.new()
	_terrain_mesh_inst.name = "SteppePbrTerrainMesh"
	_terrain_mesh_inst.mesh = st.commit()
	_terrain_mesh_inst.material_override = _create_terrain_shader_material()
	_terrain_mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_terrain_mesh_inst)


func _add_terrain_vert(st: SurfaceTool, pos: Vector3, uv: Vector2) -> void:
	var moist: float = (_moisture_noise.get_noise_2d(pos.x, pos.z) + 1.0) * 0.5
	st.set_uv(uv)
	st.set_color(Color(moist, clampf((pos.y + 2.0) / 22.0, 0.0, 1.0), 0.0, 1.0))
	st.add_vertex(pos)


func _create_terrain_shader_material() -> ShaderMaterial:
	var shader: Shader = Shader.new()
	shader.code = """
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D tex_grass : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D tex_ground : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D tex_snow : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D tex_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D tex_rough : filter_linear_mipmap, repeat_enable;

varying vec3 v_world_pos;
varying vec3 v_world_norm;
varying float v_moisture;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_norm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_moisture = COLOR.r;
}

void fragment() {
	vec2 w_uv = v_world_pos.xz * 0.085;
	vec3 g_tex = texture(tex_grass, w_uv).rgb;
	vec3 d_tex = texture(tex_ground, w_uv * 1.15).rgb;
	vec3 s_tex = texture(tex_snow, w_uv * 0.9).rgb;

	// Muted Manor Lords steppe palette (deep olive/sage grass + golden dry turf + dark slate rock)
	vec3 olive_grass = mix(vec3(0.17, 0.21, 0.11), vec3(0.31, 0.27, 0.15), clamp(1.0 - v_moisture, 0.0, 1.0));
	vec3 grass_col = mix(olive_grass, g_tex * vec3(0.45, 0.48, 0.34), 0.45);
	vec3 dirt_col = mix(vec3(0.16, 0.14, 0.10), d_tex * vec3(0.44, 0.39, 0.31), 0.45);
	vec3 rock_col = mix(vec3(0.22, 0.21, 0.20), d_tex * vec3(0.38, 0.37, 0.36), 0.38);

	float slope = clamp(v_world_norm.y, 0.0, 1.0);
	float rock_mask = 1.0 - smoothstep(0.76, 0.89, slope);
	float shore_mask = 1.0 - smoothstep(-0.65, 0.35, v_world_pos.y);
	float snow_mask = smoothstep(13.5, 19.5, v_world_pos.y);

	vec3 base_col = mix(grass_col, dirt_col, shore_mask * 0.92);
	base_col = mix(base_col, rock_col, clamp(rock_mask + smoothstep(6.0, 11.0, v_world_pos.y) * 0.55, 0.0, 1.0));
	base_col = mix(base_col, s_tex * vec3(0.76, 0.78, 0.82), snow_mask * 0.78);

	ALBEDO = base_col;
	NORMAL_MAP = texture(tex_normal, w_uv * 1.8).rgb;
	NORMAL_MAP_DEPTH = 0.65;
	ROUGHNESS = mix(texture(tex_rough, w_uv * 1.4).r, 0.38, shore_mask * 0.7);
	METALLIC = 0.02;
}
"""
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = shader
	var g_res: Texture2D = ResourceLoader.load("res://assets/textures/Grass001_1K-JPG_Color.jpg") as Texture2D
	var d_res: Texture2D = ResourceLoader.load("res://assets/textures/Ground037_1K-JPG_Color.jpg") as Texture2D
	var s_res: Texture2D = ResourceLoader.load("res://assets/textures/Snow006_1K-JPG_Color.jpg") as Texture2D
	if g_res != null:
		mat.set_shader_parameter("tex_grass", g_res)
	if d_res != null:
		mat.set_shader_parameter("tex_ground", d_res)
	if s_res != null:
		mat.set_shader_parameter("tex_snow", s_res)
	mat.set_shader_parameter("tex_normal", _cached_normal_tex)
	mat.set_shader_parameter("tex_rough", _cached_rough_tex)
	return mat


func _build_water_mesh() -> void:
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(WORLD_SPAN_M, WORLD_SPAN_M)
	plane.subdivide_width = 16
	plane.subdivide_depth = 16

	var shader: Shader = Shader.new()
	shader.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, specular_schlick_ggx;

void fragment() {
	float t = TIME * 0.9;
	float w1 = sin(UV.x * 72.0 + t * 1.4) * cos(UV.y * 64.0 - t * 1.1);
	float w2 = sin(UV.x * 48.0 - t * 0.8 + UV.y * 52.0);
	float ripple = (w1 + w2) * 0.5;
	ALBEDO = mix(vec3(0.11, 0.24, 0.28), vec3(0.18, 0.34, 0.37), ripple * 0.25 + 0.5);
	ROUGHNESS = 0.14;
	METALLIC = 0.18;
	SPECULAR = 0.65;
	ALPHA = 0.86;
	NORMAL = normalize(vec3(ripple * 0.08, 1.0, w2 * 0.08));
}
"""
	var wmat: ShaderMaterial = ShaderMaterial.new()
	wmat.shader = shader

	_water_mesh_inst = MeshInstance3D.new()
	_water_mesh_inst.name = "SteppeRiverWater"
	_water_mesh_inst.mesh = plane
	_water_mesh_inst.position = Vector3(0.0, WATER_LEVEL_Y, 0.0)
	_water_mesh_inst.material_override = wmat
	_water_mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_water_mesh_inst)


func _build_foliage_multimeshes() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = _world_seed + 555

	# 1. Pine Forest MultiMesh (380 trees)
	var tree_transforms: Array[Transform3D] = []
	for _i: int in range(900):
		if tree_transforms.size() >= 380:
			break
		var px: float = rng.randf_range(-62.0, 62.0)
		var pz: float = rng.randf_range(-62.0, 62.0)
		if Vector2(px + 34.0, pz - 34.0).length() < 15.0:
			continue
		if Vector2(px - 34.0, pz + 34.0).length() < 15.0:
			continue
		var h: float = get_height_at(px, pz)
		if h < 0.25 or h > 7.5:
			continue
		var sc: float = rng.randf_range(0.75, 1.35)
		var basis: Basis = Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(Vector3.ONE * sc)
		tree_transforms.append(Transform3D(basis, Vector3(px, h, pz)))

	var tree_mesh: ArrayMesh = RtsVisualFactory.create_pine_tree_mesh()
	var t_mat: StandardMaterial3D = StandardMaterial3D.new()
	t_mat.vertex_color_use_as_albedo = true
	t_mat.roughness = 0.88
	tree_mesh.surface_set_material(0, t_mat)
	_trees_mm = _make_foliage_mmi("PineForests", tree_mesh, tree_transforms)

	# 2. Rock Outcrops MultiMesh (120 rocks)
	var rock_transforms: Array[Transform3D] = []
	for _i: int in range(300):
		if rock_transforms.size() >= 120:
			break
		var rx: float = rng.randf_range(-60.0, 60.0)
		var rz: float = rng.randf_range(-60.0, 60.0)
		if Vector2(rx + 34.0, rz - 34.0).length() < 12.0 or Vector2(rx - 34.0, rz + 34.0).length() < 12.0:
			continue
		var rh: float = get_height_at(rx, rz)
		if rh < -0.1:
			continue
		var rsc: Vector3 = Vector3(rng.randf_range(0.7, 1.8), rng.randf_range(0.5, 1.2), rng.randf_range(0.7, 1.6))
		var rbasis: Basis = Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(rsc)
		rock_transforms.append(Transform3D(rbasis, Vector3(rx, rh + 0.15, rz)))

	var rock_mesh: PrismMesh = PrismMesh.new()
	rock_mesh.size = Vector3(1.0, 1.0, 1.0)
	var rmat: StandardMaterial3D = StandardMaterial3D.new()
	rmat.albedo_color = Color(0.32, 0.31, 0.29, 1.0)
	rmat.roughness = 0.92
	rock_mesh.material = rmat
	_rocks_mm = _make_foliage_mmi("RockOutcrops", rock_mesh, rock_transforms)

	# 3. Wind-swaying Grass Tufts MultiMesh (640 tufts)
	var grass_transforms: Array[Transform3D] = []
	for _i: int in range(1200):
		if grass_transforms.size() >= 640:
			break
		var gx: float = rng.randf_range(-56.0, 56.0)
		var gz: float = rng.randf_range(-56.0, 56.0)
		var gh: float = get_height_at(gx, gz)
		if gh < 0.05 or gh > 4.2:
			continue
		var gsc: float = rng.randf_range(0.75, 1.35)
		var gbasis: Basis = Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(Vector3.ONE * gsc)
		grass_transforms.append(Transform3D(gbasis, Vector3(gx, gh, gz)))

	var grass_mesh: ArrayMesh = _create_grass_tuft_mesh()
	_grass_mm = _make_foliage_mmi("WindGrassTufts", grass_mesh, grass_transforms)
	_grass_mm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _make_foliage_mmi(mmi_name: String, mesh_res: Mesh, transforms: Array[Transform3D]) -> MultiMeshInstance3D:
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh_res
	mm.instance_count = transforms.size()
	for i: int in range(transforms.size()):
		mm.set_instance_transform(i, transforms[i])
	var mmi: MultiMeshInstance3D = MultiMeshInstance3D.new()
	mmi.name = mmi_name
	mmi.multimesh = mm
	mmi.add_to_group(&"foliage_multimesh")
	add_child(mmi)
	return mmi


func _create_grass_tuft_mesh() -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for blade: int in range(3):
		var ang: float = float(blade) * PI / 3.0
		var dx: float = cos(ang) * 0.28
		var dz: float = sin(ang) * 0.28
		st.set_color(Color(0.32, 0.36, 0.19, 1.0))
		st.add_vertex(Vector3(-dx, 0.0, -dz))
		st.add_vertex(Vector3(dx, 0.0, dz))
		st.set_color(Color(0.45, 0.44, 0.24, 1.0))
		st.add_vertex(Vector3(0.0, 0.58, 0.0))
	st.generate_normals()

	var shader: Shader = Shader.new()
	shader.code = """
shader_type spatial;
render_mode cull_disabled;

void vertex() {
	float sway = sin(TIME * 2.1 + NODE_POSITION_WORLD.x * 0.4 + NODE_POSITION_WORLD.z * 0.3) * 0.14;
	VERTEX.x += sway * VERTEX.y;
}

void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 0.88;
}
"""
	var smat: ShaderMaterial = ShaderMaterial.new()
	smat.shader = shader
	var mesh_out: ArrayMesh = st.commit()
	mesh_out.surface_set_material(0, smat)
	return mesh_out


func _build_ore_vein_clusters() -> void:
	_ores_root = Node3D.new()
	_ores_root.name = "OreVeinsRoot"
	add_child(_ores_root)
	var ore_ids: Array[StringName] = [
		&"iron", &"stone", &"silver_gold", &"meteoric_iron", &"iron", &"stone", &"silver_gold"
	]
	var ore_cols: Array[Color] = [
		Color(0.42, 0.46, 0.52, 1.0),
		Color(0.56, 0.54, 0.50, 1.0),
		Color(0.84, 0.70, 0.26, 1.0),
		Color(0.48, 0.34, 0.72, 1.0),
		Color(0.42, 0.46, 0.52, 1.0),
		Color(0.56, 0.54, 0.50, 1.0),
		Color(0.84, 0.70, 0.26, 1.0),
	]
	var ore_pos: Array[Vector2] = [
		Vector2(-22.0, 22.0),
		Vector2(-42.0, 18.0),
		Vector2(-18.0, 40.0),
		Vector2(0.0, 0.0),
		Vector2(22.0, -20.0),
		Vector2(40.0, -16.0),
		Vector2(18.0, -40.0),
	]
	for i: int in range(ore_ids.size()):
		var pos2: Vector2 = ore_pos[i]
		var node: Node3D = RtsVisualFactory.create_ore_deposit_visual(ore_ids[i], ore_cols[i])
		var hy: float = get_height_at(pos2.x, pos2.y)
		node.position = Vector3(pos2.x, hy, pos2.y)
		_ores_root.add_child(node)


static func smoothstep_01(x: float) -> float:
	var t: float = clampf(x, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)
