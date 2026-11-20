class_name TouchGestureRecognizer
extends RefCounted
## Pure, unit-testable multi-touch gesture recognizer (rank 3).
## Disambiguates tap, long-press, one-finger pan, two-finger pinch zoom,
## and two-finger twist from synthetic or live `InputEventScreenTouch` /
## `InputEventScreenDrag` events.

signal tap_detected(screen_pos: Vector2)
signal long_press_detected(screen_pos: Vector2)
signal pan_delta(screen_delta: Vector2)
signal pinch_zoom_delta(zoom_scale_delta: float, focus_pos: Vector2)
signal twist_delta(angle_rad: float)

const DEFAULT_TAP_THRESHOLD_DP: float = 14.0
const DEFAULT_LONG_PRESS_SEC: float = 0.55

var _dpi_scale: float = 1.0
var _tap_threshold_px: float = DEFAULT_TAP_THRESHOLD_DP
var _long_press_sec: float = DEFAULT_LONG_PRESS_SEC

var _touches: Dictionary[int, Vector2] = {}
var _start_pos: Vector2 = Vector2.ZERO
var _elapsed_sec: float = 0.0
var _dragged: bool = false
var _long_press_fired: bool = false
var _pinch_active: bool = false
var _prev_pinch_dist: float = 0.0
var _prev_pinch_angle: float = 0.0


func _init(p_dpi: int = 160, p_long_press_sec: float = DEFAULT_LONG_PRESS_SEC) -> void:
	set_screen_dpi(p_dpi)
	_long_press_sec = maxf(p_long_press_sec, 0.2)


func set_screen_dpi(p_dpi: int) -> void:
	_dpi_scale = clampf(float(maxi(p_dpi, 120)) / 160.0, 1.0, 4.0)
	_tap_threshold_px = DEFAULT_TAP_THRESHOLD_DP * _dpi_scale


func get_tap_threshold_px() -> float:
	return _tap_threshold_px


func get_active_touch_count() -> int:
	return _touches.size()


func reset() -> void:
	_touches.clear()
	_elapsed_sec = 0.0
	_dragged = false
	_long_press_fired = false
	_pinch_active = false
	_prev_pinch_dist = 0.0
	_prev_pinch_angle = 0.0


func tick(delta_sec: float) -> void:
	if _touches.size() != 1 or _dragged or _long_press_fired or _pinch_active:
		return
	_elapsed_sec += maxf(delta_sec, 0.0)
	if _elapsed_sec >= _long_press_sec:
		_long_press_fired = true
		long_press_detected.emit(_start_pos)


func process_event(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return _handle_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		return _handle_drag(event as InputEventScreenDrag)
	return false


func _handle_touch(ev: InputEventScreenTouch) -> bool:
	if ev.pressed:
		_touches[ev.index] = ev.position
		if _touches.size() == 1:
			_start_pos = ev.position
			_elapsed_sec = 0.0
			_dragged = false
			_long_press_fired = false
			_pinch_active = false
		elif _touches.size() == 2:
			_dragged = true
			_pinch_active = true
			_sync_two_finger_baseline()
		return true

	# Released
	var had_index: bool = _touches.has(ev.index)
	_touches.erase(ev.index)
	if _touches.size() < 2:
		_pinch_active = false
	if _touches.is_empty():
		if had_index and not _dragged and not _long_press_fired:
			if ev.position.distance_to(_start_pos) <= _tap_threshold_px:
				tap_detected.emit(ev.position)
		_elapsed_sec = 0.0
		_dragged = false
		_long_press_fired = false
	return had_index


func _handle_drag(ev: InputEventScreenDrag) -> bool:
	if not _touches.has(ev.index):
		_touches[ev.index] = ev.position
	else:
		_touches[ev.index] = ev.position

	if _touches.size() == 1:
		if not _dragged and ev.position.distance_to(_start_pos) > _tap_threshold_px:
			_dragged = true
		if _dragged:
			pan_delta.emit(ev.relative)
		return true

	if _touches.size() >= 2:
		_dragged = true
		var keys: Array[int] = _touches.keys()
		keys.sort()
		var p0: Vector2 = _touches[keys[0]]
		var p1: Vector2 = _touches[keys[1]]
		var dist: float = p0.distance_to(p1)
		var angle: float = (p1 - p0).angle()
		if not _pinch_active or _prev_pinch_dist <= 1.0:
			_pinch_active = true
			_prev_pinch_dist = maxf(dist, 1.0)
			_prev_pinch_angle = angle
			return true
		var focus: Vector2 = (p0 + p1) * 0.5
		if absf(dist - _prev_pinch_dist) >= 2.0 and _prev_pinch_dist > 1.0:
			var ratio_delta: float = (dist - _prev_pinch_dist) / _prev_pinch_dist
			pinch_zoom_delta.emit(ratio_delta, focus)
			_prev_pinch_dist = maxf(dist, 1.0)
		var angle_diff: float = wrapf(angle - _prev_pinch_angle, -PI, PI)
		if absf(angle_diff) >= 0.01:
			twist_delta.emit(angle_diff)
			_prev_pinch_angle = angle
		return true

	return false


func _sync_two_finger_baseline() -> void:
	var keys: Array[int] = _touches.keys()
	if keys.size() < 2:
		return
	keys.sort()
	var p0: Vector2 = _touches[keys[0]]
	var p1: Vector2 = _touches[keys[1]]
	_prev_pinch_dist = maxf(p0.distance_to(p1), 1.0)
	_prev_pinch_angle = (p1 - p0).angle()
