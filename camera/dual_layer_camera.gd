class_name DualLayerCamera
extends Node3D
## Camera (rank 3). Framing, XZ panning and smooth cloud-veiled transitions
## between the Macro and Micro layers.
##
## All timing and framing values come from `CameraProfile` (`camera_profile.tres`
## sets `transition_duration_sec = 0.4`). The visible world swaps at the cloud
## peak via `EventBus.layer_transition_midpoint` so the cut is hidden.

@export var profile: CameraProfile
@export var camera: Camera3D
@export var cloud_veil: ColorRect
@export_range(0.45, 1.0, 0.05) var min_zoom_factor: float = 0.55
@export_range(1.0, 2.5, 0.05) var max_zoom_factor: float = 1.65
@export_range(0.05, 0.4, 0.01) var zoom_step: float = 0.12

var _layer: GameEnums.WorldLayer = GameEnums.WorldLayer.MACRO
var _progress: float = 0.0
var _start_progress: float = 0.0
var _target_progress: float = 0.0
var _midpoint_emitted: bool = false
var _tween: Tween = null
var _macro_focus: Vector3 = Vector3.ZERO
var _pan_bounds: Vector2 = Vector2(80.0, 80.0)
var _zoom_factor: float = 1.0


func _ready() -> void:
	if not _validate():
		set_process(false)
		return
	cloud_veil.color = Color(profile.cloud_color.r, profile.cloud_color.g, profile.cloud_color.b, 0.0)
	_apply_progress(0.0)
	EventBus.world_layer_changed.connect(_on_world_layer_changed)
	EventBus.macro_world_generated.connect(_on_macro_world_generated)
	EventBus.micro_zone_generated.connect(_on_micro_zone_generated)


func _exit_tree() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
	if EventBus.world_layer_changed.is_connected(_on_world_layer_changed):
		EventBus.world_layer_changed.disconnect(_on_world_layer_changed)
	if EventBus.macro_world_generated.is_connected(_on_macro_world_generated):
		EventBus.macro_world_generated.disconnect(_on_macro_world_generated)
	if EventBus.micro_zone_generated.is_connected(_on_micro_zone_generated):
		EventBus.micro_zone_generated.disconnect(_on_micro_zone_generated)


func _unhandled_input(event: InputEvent) -> void:
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if mb == null or not mb.pressed:
		return
	if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
		zoom_by(-zoom_step)
		if get_viewport() != null:
			get_viewport().set_input_as_handled()
	elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		zoom_by(zoom_step)
		if get_viewport() != null:
			get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if _tween != null and _tween.is_running():
		return
	var input_dir: Vector2 = Input.get_vector(
		&"camera_pan_left", &"camera_pan_right", &"camera_pan_forward", &"camera_pan_back")
	if input_dir == Vector2.ZERO:
		return
	var step: Vector2 = input_dir * profile.get_pan_speed(_layer) * delta
	pan_by(step)


func pan_by(delta_xz: Vector2) -> Vector3:
	var bx: float = maxf(_pan_bounds.x, 16.0)
	var bz: float = maxf(_pan_bounds.y, 16.0)
	position.x = clampf(position.x + delta_xz.x, -bx, bx)
	position.z = clampf(position.z + delta_xz.y, -bz, bz)
	return position


func focus_world_position(world_pos: Vector3) -> void:
	var bx: float = maxf(_pan_bounds.x, 16.0)
	var bz: float = maxf(_pan_bounds.y, 16.0)
	position.x = clampf(world_pos.x, -bx, bx)
	position.z = clampf(world_pos.z, -bz, bz)


func zoom_by(delta_factor: float) -> float:
	_zoom_factor = clampf(_zoom_factor + delta_factor, min_zoom_factor, max_zoom_factor)
	_apply_progress(_progress)
	return _zoom_factor


func get_zoom_factor() -> float:
	return _zoom_factor


## True while the cloud transition tween is running.
func is_transitioning() -> bool:
	return _tween != null and _tween.is_running()


## Current 0 (Macro) .. 1 (Micro) interpolation value.
func get_transition_progress() -> float:
	return _progress


func _on_world_layer_changed(_previous: GameEnums.WorldLayer, target_layer: GameEnums.WorldLayer) -> void:
	if _layer == GameEnums.WorldLayer.MACRO and target_layer == GameEnums.WorldLayer.MICRO:
		_macro_focus = global_position
	_layer = target_layer
	_start_progress = _progress
	_target_progress = 1.0 if target_layer == GameEnums.WorldLayer.MICRO else 0.0
	_midpoint_emitted = false

	if _tween != null and _tween.is_running():
		_tween.kill()
	EventBus.layer_transition_started.emit(target_layer, _macro_focus)

	_tween = create_tween()
	_tween.set_trans(profile.transition_type)
	_tween.set_ease(profile.transition_ease)
	_tween.tween_method(_step_transition, 0.0, 1.0, profile.transition_duration_sec)
	_tween.finished.connect(_on_tween_finished)


func _step_transition(fraction: float) -> void:
	_apply_progress(lerpf(_start_progress, _target_progress, fraction))
	var cloud_envelope: float = sin(fraction * PI)
	cloud_veil.color.a = cloud_envelope * profile.cloud_peak_alpha
	if not _midpoint_emitted and fraction >= profile.swap_progress:
		_midpoint_emitted = true
		EventBus.layer_transition_midpoint.emit(_layer)


func _on_tween_finished() -> void:
	_apply_progress(_target_progress)
	cloud_veil.color.a = 0.0
	if not _midpoint_emitted:
		_midpoint_emitted = true
		EventBus.layer_transition_midpoint.emit(_layer)
	EventBus.layer_transition_finished.emit(_layer)


func _apply_progress(value: float) -> void:
	_progress = clampf(value, 0.0, 1.0)
	if profile == null or camera == null:
		return
	var base_height: float = lerpf(profile.macro_height_m, profile.micro_height_m, _progress)
	var height: float = base_height * _zoom_factor
	var pitch_rad: float = deg_to_rad(lerpf(profile.macro_pitch_deg, profile.micro_pitch_deg, _progress))
	var horizontal_back: float = height / tan(maxf(pitch_rad, 0.01))
	camera.position = Vector3(0.0, height, horizontal_back)
	camera.rotation = Vector3(-pitch_rad, 0.0, 0.0)
	camera.fov = lerpf(profile.macro_fov_deg, profile.micro_fov_deg, _progress)


func _on_macro_world_generated(world_state: MacroWorldState) -> void:
	var ext: Vector2 = world_state.get_half_extents()
	if ext.x > 0.0 and ext.y > 0.0:
		_pan_bounds = ext


func _on_micro_zone_generated(zone_state: MicroZoneState) -> void:
	global_position = zone_state.world_center


func _validate() -> bool:
	var missing: PackedStringArray = PackedStringArray()
	if profile == null:
		missing.append("profile")
	if camera == null:
		missing.append("camera")
	if cloud_veil == null:
		missing.append("cloud_veil")
	if not missing.is_empty():
		push_error("DualLayerCamera '%s' missing: %s." % [get_path(), ", ".join(missing)])
		return false
	return true
