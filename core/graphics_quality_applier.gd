class_name GraphicsQualityApplier
extends RefCounted
## Applies and persists mobile-friendly graphics quality (`user://graphics_settings.cfg`),
## resolution scale, shadow quality, foliage density, atmospheric fog, FPS cap,
## live FPS counter toggle, and safe-area margins (rank 2).
## Strictly prohibits SSR, SDFGI, and Volumetric Fog for mobile GPU efficiency.

const GRAPHICS_CFG_PATH: String = "user://graphics_settings.cfg"

const PROFILE_NAMES: Array[String] = [
	"Düşük (Pil & Hız)",
	"Orta (Dengeli - Android Varsayılan)",
	"Yüksek (Manor Lords)",
	"Gerçekçi (Maksimum)",
]

const RES_SCALE_STEPS: Array[float] = [0.60, 0.75, 0.90, 1.00]
const FOLIAGE_STEPS: Array[float] = [0.25, 0.50, 0.80, 1.00]


class GraphicsConfigData:
	extends RefCounted
	var profile_index: int = 1
	var resolution_scale: float = 0.75
	var shadow_quality: int = 1
	var foliage_density: float = 0.50
	var fog_enabled: bool = true
	var fps_limit: int = 60
	var show_fps_counter: bool = false


static func get_preset(profile_index: int) -> GraphicsConfigData:
	var p: int = clampi(profile_index, 0, 3)
	var d: GraphicsConfigData = GraphicsConfigData.new()
	d.profile_index = p
	match p:
		0:
			d.resolution_scale = 0.60
			d.shadow_quality = 0
			d.foliage_density = 0.25
			d.fog_enabled = false
			d.fps_limit = 30
		1:
			d.resolution_scale = 0.75
			d.shadow_quality = 1
			d.foliage_density = 0.50
			d.fog_enabled = true
			d.fps_limit = 60
		2:
			d.resolution_scale = 0.90
			d.shadow_quality = 2
			d.foliage_density = 0.80
			d.fog_enabled = true
			d.fps_limit = 60
		_:
			d.resolution_scale = 1.00
			d.shadow_quality = 3
			d.foliage_density = 1.00
			d.fog_enabled = true
			d.fps_limit = 60
	return d


static func load_graphics_settings() -> GraphicsConfigData:
	var defaults: GraphicsConfigData = get_preset(1)
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(GRAPHICS_CFG_PATH) != OK:
		return defaults
	var out: GraphicsConfigData = GraphicsConfigData.new()
	out.profile_index = clampi(DeterministicStateHasher.v_int(cfg.get_value("graphics", "profile_index", 1), 1), -1, 3)
	out.resolution_scale = clampf(DeterministicStateHasher.v_float(cfg.get_value("graphics", "resolution_scale", 0.75), 0.75), 0.50, 1.00)
	out.shadow_quality = clampi(DeterministicStateHasher.v_int(cfg.get_value("graphics", "shadow_quality", 1), 1), 0, 3)
	out.foliage_density = clampf(DeterministicStateHasher.v_float(cfg.get_value("graphics", "foliage_density", 0.50), 0.50), 0.10, 1.00)
	out.fog_enabled = DeterministicStateHasher.v_bool(cfg.get_value("graphics", "fog_enabled", true), true)
	var fps_raw: int = DeterministicStateHasher.v_int(cfg.get_value("graphics", "fps_limit", 60), 60)
	out.fps_limit = 30 if fps_raw <= 35 else 60
	out.show_fps_counter = DeterministicStateHasher.v_bool(cfg.get_value("graphics", "show_fps_counter", false), false)
	return out


static func save_graphics_settings(settings: GraphicsConfigData) -> bool:
	if settings == null:
		return false
	var cfg: ConfigFile = ConfigFile.new()
	cfg.set_value("graphics", "profile_index", settings.profile_index)
	cfg.set_value("graphics", "resolution_scale", settings.resolution_scale)
	cfg.set_value("graphics", "shadow_quality", settings.shadow_quality)
	cfg.set_value("graphics", "foliage_density", settings.foliage_density)
	cfg.set_value("graphics", "fog_enabled", settings.fog_enabled)
	cfg.set_value("graphics", "fps_limit", settings.fps_limit)
	cfg.set_value("graphics", "show_fps_counter", settings.show_fps_counter)
	return cfg.save(GRAPHICS_CFG_PATH) == OK


static func apply_detailed_settings(tree: SceneTree, settings: GraphicsConfigData, save_to_disk: bool = true) -> void:
	if settings == null:
		return
	if save_to_disk:
		save_graphics_settings(settings)
	if tree == null:
		return
	var win: Window = tree.root
	if win == null:
		return

	var fps_cap: int = 30 if settings.fps_limit <= 35 else 60
	Engine.max_fps = fps_cap

	var res_scale: float = clampf(settings.resolution_scale, 0.50, 1.00)
	win.scaling_3d_scale = res_scale

	var shadow_q: int = clampi(settings.shadow_quality, 0, 3)
	win.msaa_3d = Viewport.MSAA_2X if shadow_q >= 3 else Viewport.MSAA_DISABLED
	_apply_shadow_quality(win, shadow_q)

	var foliage_density: float = clampf(settings.foliage_density, 0.10, 1.00)
	_apply_foliage_density(tree, foliage_density)

	_apply_environment_settings(win, settings.fog_enabled)

	if EventBus != null:
		EventBus.graphics_settings_updated.emit(settings.profile_index, settings.show_fps_counter)


static func apply_to_scene(tree: SceneTree, quality: int, ui_scale: float, touch_layout: bool = false) -> void:
	if tree == null:
		return
	var q: int = clampi(quality, 0, 3)
	var win: Window = tree.root
	if win == null:
		return

	var preset: GraphicsConfigData = get_preset(q)
	if q == 0:
		preset.fps_limit = 30
		preset.resolution_scale = 0.75
	elif q == 1:
		preset.fps_limit = 60
		preset.resolution_scale = 0.90
	elif q == 2:
		preset.fps_limit = 60
		preset.resolution_scale = 1.00
	apply_detailed_settings(tree, preset, false)

	var clamped_scale: float = clampf(ui_scale, 0.85, 1.25)
	if touch_layout and clamped_scale < 1.05:
		clamped_scale = 1.08
	if not DisplayServer.get_name().to_lower().contains("headless"):
		win.content_scale_factor = clamped_scale


static func _apply_shadow_quality(root: Node, shadow_q: int) -> void:
	if root == null:
		return
	var is_headless: bool = DisplayServer.get_name().to_lower().contains("headless")
	if not is_headless:
		var atlas_size: int = 1024
		if shadow_q == 0:
			atlas_size = 512
		elif shadow_q == 1:
			atlas_size = 1024
		elif shadow_q == 2:
			atlas_size = 2048
		else:
			atlas_size = 4096
		RenderingServer.directional_shadow_atlas_set_size(atlas_size, true)
	_apply_light_nodes(root, shadow_q)


static func _apply_light_nodes(node: Node, shadow_q: int) -> void:
	for child: Node in node.get_children():
		if child is DirectionalLight3D:
			var dl: DirectionalLight3D = child as DirectionalLight3D
			dl.shadow_enabled = shadow_q > 0
			if shadow_q == 1:
				dl.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
				dl.directional_shadow_max_distance = 130.0
			elif shadow_q == 2:
				dl.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
				dl.directional_shadow_max_distance = 180.0
			elif shadow_q >= 3:
				dl.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
				dl.directional_shadow_max_distance = 240.0
		if child.get_child_count() > 0:
			_apply_light_nodes(child, shadow_q)


static func _apply_environment_settings(node: Node, fog_on: bool) -> void:
	for child: Node in node.get_children():
		if child is WorldEnvironment:
			var we: WorldEnvironment = child as WorldEnvironment
			if we.environment != null:
				we.environment.fog_enabled = fog_on
				we.environment.ssr_enabled = false
				we.environment.sdfgi_enabled = false
				we.environment.volumetric_fog_enabled = false
		if child.get_child_count() > 0:
			_apply_environment_settings(child, fog_on)


static func _apply_foliage_density(tree: SceneTree, density: float) -> void:
	var nodes: Array[Node] = tree.get_nodes_in_group(&"foliage_multimesh")
	for n: Node in nodes:
		if n is MultiMeshInstance3D:
			var mmi: MultiMeshInstance3D = n as MultiMeshInstance3D
			if mmi.multimesh != null:
				var total: int = mmi.multimesh.instance_count
				mmi.multimesh.visible_instance_count = clampi(int(roundf(float(total) * density)), 0, total)


static func apply_safe_area_margins(hud_root: Control) -> void:
	if hud_root == null:
		return
	if DisplayServer.get_name().to_lower().contains("headless"):
		return
	var safe: Rect2i = DisplayServer.get_display_safe_area()
	var win_size: Vector2i = DisplayServer.window_get_size()
	if win_size.x <= 0 or win_size.y <= 0 or safe.size.x <= 0 or safe.size.y <= 0:
		return
	var scale_x: float = hud_root.get_viewport_rect().size.x / float(win_size.x)
	var scale_y: float = hud_root.get_viewport_rect().size.y / float(win_size.y)
	var left_pad: float = maxf(0.0, float(safe.position.x) * scale_x)
	var top_pad: float = maxf(0.0, float(safe.position.y) * scale_y)
	var right_pad: float = maxf(0.0, float(win_size.x - safe.end.x) * scale_x)
	var bottom_pad: float = maxf(0.0, float(win_size.y - safe.end.y) * scale_y)
	hud_root.offset_left = left_pad
	hud_root.offset_top = top_pad
	hud_root.offset_right = -right_pad
	hud_root.offset_bottom = -bottom_pad
