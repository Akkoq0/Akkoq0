class_name GraphicsQualityApplier
extends RefCounted
## Applies mobile-friendly graphics quality, FPS cap, 3D render scale, MSAA,
## shadow toggle, and UI content scale from `UserSettingsSnapshot` (rank 4).


static func apply_to_scene(tree: SceneTree, quality: int, ui_scale: float, touch_layout: bool = false) -> void:
	if tree == null:
		return
	var q: int = clampi(quality, 0, 2)
	var win: Window = tree.root
	if win == null:
		return

	# Mobile-friendly defaults:
	# 0 = Düşük (Battery Saver: 30 FPS, 0.75x 3D scale, no MSAA, no shadows)
	# 1 = Orta  (Balanced Mobile: 60 FPS, 0.90x 3D scale, no MSAA, shadows on)
	# 2 = Yüksek (High Fidelity: 60 FPS, 1.00x 3D scale, 2x MSAA, shadows on)
	match q:
		0:
			Engine.max_fps = 30
			win.scaling_3d_scale = 0.75
			win.msaa_3d = Viewport.MSAA_DISABLED
			_set_shadows_enabled(win, false)
		1:
			Engine.max_fps = 60
			win.scaling_3d_scale = 0.90
			win.msaa_3d = Viewport.MSAA_DISABLED
			_set_shadows_enabled(win, true)
		2:
			Engine.max_fps = 60
			win.scaling_3d_scale = 1.0
			win.msaa_3d = Viewport.MSAA_2X
			_set_shadows_enabled(win, true)

	var clamped_scale: float = clampf(ui_scale, 0.85, 1.25)
	if touch_layout and clamped_scale < 1.05:
		clamped_scale = 1.08
	if not DisplayServer.get_name().to_lower().contains("headless"):
		win.content_scale_factor = clamped_scale


static func _set_shadows_enabled(root: Node, enabled: bool) -> void:
	if root == null:
		return
	for child: Node in root.get_children():
		if child is DirectionalLight3D:
			(child as DirectionalLight3D).shadow_enabled = enabled
		elif child.get_child_count() > 0:
			_set_shadows_enabled(child, enabled)


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
