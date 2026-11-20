class_name PlayerCommandInput
extends Node
## Input (rank 3). Translates InputMap actions and mobile multi-touch gestures
## into `CommandBus` dispatches and camera controls.

const RAY_PARALLEL_EPSILON: float = 0.0001

@export var controlled_army_id: int = 1

var _gesture: TouchGestureRecognizer = null
var _camera_ref: WeakRef = null


func _ready() -> void:
	var dpi: int = 160
	if not DisplayServer.get_name().to_lower().contains("headless"):
		dpi = maxi(DisplayServer.screen_get_dpi(), 160)
	_gesture = TouchGestureRecognizer.new(dpi)
	_gesture.tap_detected.connect(_on_touch_tap)
	_gesture.long_press_detected.connect(_on_touch_long_press)
	_gesture.pan_delta.connect(_on_touch_pan)
	_gesture.pinch_zoom_delta.connect(_on_touch_pinch)
	_gesture.twist_delta.connect(_on_touch_twist)


func _exit_tree() -> void:
	if _gesture != null:
		if _gesture.tap_detected.is_connected(_on_touch_tap):
			_gesture.tap_detected.disconnect(_on_touch_tap)
		if _gesture.long_press_detected.is_connected(_on_touch_long_press):
			_gesture.long_press_detected.disconnect(_on_touch_long_press)
		if _gesture.pan_delta.is_connected(_on_touch_pan):
			_gesture.pan_delta.disconnect(_on_touch_pan)
		if _gesture.pinch_zoom_delta.is_connected(_on_touch_pinch):
			_gesture.pinch_zoom_delta.disconnect(_on_touch_pinch)
		if _gesture.twist_delta.is_connected(_on_touch_twist):
			_gesture.twist_delta.disconnect(_on_touch_twist)


func _process(delta: float) -> void:
	if _gesture != null:
		_gesture.tick(delta)


func _unhandled_input(event: InputEvent) -> void:
	if _gesture != null and (event is InputEventScreenTouch or event is InputEventScreenDrag):
		if _gesture.process_event(event):
			if get_viewport() != null:
				get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed(&"toggle_world_layer"):
		var current: GameEnums.WorldLayer = GameManager.get_world_layer()
		var target: GameEnums.WorldLayer = GameEnums.WorldLayer.MICRO \
			if current == GameEnums.WorldLayer.MACRO else GameEnums.WorldLayer.MACRO
		CommandBus.dispatch(SwitchLayerCommand.new(target))
		if get_viewport() != null:
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"issue_move_order"):
		var mouse: Vector2 = get_viewport().get_mouse_position() if get_viewport() != null else Vector2.ZERO
		var hit: Vector3 = _project_screen_to_ground(mouse)
		if not is_inf(hit.x):
			CommandBus.dispatch(MoveArmyCommand.new(controlled_army_id, hit))
			if get_viewport() != null:
				get_viewport().set_input_as_handled()


func _on_touch_tap(screen_pos: Vector2) -> void:
	var hit: Vector3 = _project_screen_to_ground(screen_pos)
	if not is_inf(hit.x):
		CommandBus.dispatch(MoveArmyCommand.new(controlled_army_id, hit))


func _on_touch_long_press(screen_pos: Vector2) -> void:
	var hit: Vector3 = _project_screen_to_ground(screen_pos)
	if is_inf(hit.x):
		return
	var cam: DualLayerCamera = _get_dual_camera()
	if cam != null:
		cam.focus_world_position(hit)


func _on_touch_pan(screen_delta: Vector2) -> void:
	var cam: DualLayerCamera = _get_dual_camera()
	if cam != null:
		cam.apply_touch_pan(screen_delta)


func _on_touch_pinch(zoom_ratio_delta: float, _focus_pos: Vector2) -> void:
	var cam: DualLayerCamera = _get_dual_camera()
	if cam != null:
		cam.apply_pinch_zoom(zoom_ratio_delta)


func _on_touch_twist(angle_rad: float) -> void:
	var cam: DualLayerCamera = _get_dual_camera()
	if cam != null:
		cam.apply_twist(angle_rad)


func _get_dual_camera() -> DualLayerCamera:
	if _camera_ref != null:
		var obj: Object = _camera_ref.get_ref()
		if obj is DualLayerCamera and is_instance_valid(obj):
			return obj as DualLayerCamera
	var parent_node: Node = get_parent()
	if parent_node != null:
		var found: DualLayerCamera = parent_node.get_node_or_null("DualLayerCamera") as DualLayerCamera
		if found != null:
			_camera_ref = weakref(found)
			return found
	return null


func _project_screen_to_ground(screen_pos: Vector2) -> Vector3:
	if get_viewport() == null:
		return Vector3.INF
	var active_camera: Camera3D = get_viewport().get_camera_3d()
	if active_camera == null:
		return Vector3.INF
	var origin: Vector3 = active_camera.project_ray_origin(screen_pos)
	var direction: Vector3 = active_camera.project_ray_normal(screen_pos)
	if absf(direction.y) <= RAY_PARALLEL_EPSILON:
		return Vector3.INF
	var distance: float = -origin.y / direction.y
	if distance < 0.0:
		return Vector3.INF
	return origin + direction * distance
