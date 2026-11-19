class_name SessionClockAuthority
extends RefCounted
## Core clock & tempo authority (rank 2). Governs dual-mode simulation time:
##  - `SINGLEPLAYER_SESSION`: pausable, `1.0x / 2.0x / 4.0x` scalable speed.
##  - `ONLINE_PERSISTENT_WORLD`: unpausable (`REJECTED_PAUSE_IN_ONLINE`), fixed
##    authoritative tick rate, and active `OfflineDoctrineConfig` protection.

static var _profile: SimulationTempoProfile = SimulationTempoProfile.create_singleplayer(1.0, false)
static var _current_tick: int = 0
static var _last_pause_rejection_code: StringName = &""
static var _last_pause_rejection_sender: String = ""


static func reset_session_clock() -> void:
	_profile = SimulationTempoProfile.create_singleplayer(1.0, false)
	_current_tick = 0
	_last_pause_rejection_code = &""
	_last_pause_rejection_sender = ""


static func configure_session_mode(
		mode: GameEnums.SessionMode,
		speed_scale: float = 1.0,
		tick_rate_hz: float = 10.0) -> SimulationTempoProfile:
	if mode == GameEnums.SessionMode.ONLINE_PERSISTENT_WORLD:
		_profile = SimulationTempoProfile.create_online_persistent(tick_rate_hz)
	else:
		_profile = SimulationTempoProfile.create_singleplayer(_snap_singleplayer_speed(speed_scale), false)
	_last_pause_rejection_code = &""
	_last_pause_rejection_sender = ""
	EventBus.session_tempo_changed.emit(
		_profile.session_mode,
		_profile.is_paused,
		_profile.speed_scale,
		_profile.offline_doctrine_protection_active)
	return _profile.duplicate_profile()


static func _snap_singleplayer_speed(raw_scale: float) -> float:
	if is_nan(raw_scale) or is_inf(raw_scale):
		return 1.0
	if raw_scale >= 3.0:
		return 4.0
	if raw_scale >= 1.5:
		return 2.0
	return 1.0


static func get_profile() -> SimulationTempoProfile:
	return _profile.duplicate_profile()


static func get_session_mode() -> GameEnums.SessionMode:
	return _profile.session_mode


static func can_pause() -> bool:
	return _profile.can_pause


static func is_paused() -> bool:
	return _profile.is_paused


static func get_speed_scale() -> float:
	return _profile.speed_scale


static func get_current_tick() -> int:
	return _current_tick


static func is_offline_doctrine_protection_active() -> bool:
	return _profile.offline_doctrine_protection_active


static func get_last_pause_rejection_code() -> StringName:
	return _last_pause_rejection_code


static func clear_pause_rejection() -> void:
	_last_pause_rejection_code = &""
	_last_pause_rejection_sender = ""


static func request_pause(paused: bool, sender_player_id: String = "1") -> bool:
	if paused and not _profile.can_pause:
		_last_pause_rejection_code = &"REJECTED_PAUSE_IN_ONLINE"
		_last_pause_rejection_sender = sender_player_id
		EventBus.session_pause_rejected.emit(sender_player_id, &"REJECTED_PAUSE_IN_ONLINE")
		return false
	_profile.is_paused = paused
	if not paused:
		_last_pause_rejection_code = &""
	EventBus.session_tempo_changed.emit(
		_profile.session_mode,
		_profile.is_paused,
		_profile.speed_scale,
		_profile.offline_doctrine_protection_active)
	return true


static func set_speed_scale(scale: float) -> bool:
	if _profile.session_mode == GameEnums.SessionMode.ONLINE_PERSISTENT_WORLD:
		if not is_equal_approx(scale, 1.0):
			return false
		_profile.speed_scale = 1.0
		return true
	_profile.speed_scale = _snap_singleplayer_speed(scale)
	EventBus.session_tempo_changed.emit(
		_profile.session_mode,
		_profile.is_paused,
		_profile.speed_scale,
		_profile.offline_doctrine_protection_active)
	return true


static func advance_tick(steps: int = 1) -> int:
	if _profile.is_paused:
		return _current_tick
	var safe_steps: int = maxi(steps, 0)
	_current_tick += safe_steps
	return _current_tick


static func export_state_dict() -> Dictionary:
	return {
		"current_tick": _current_tick,
		"last_pause_rejection_code": String(_last_pause_rejection_code),
		"profile": _profile.export_dict(),
	}


static func import_state_dict(data: Dictionary) -> bool:
	if not data.has("current_tick") or not (data.get("profile") is Dictionary):
		return false
	_current_tick = maxi(DeterministicStateHasher.v_int(data.get("current_tick", 0)), 0)
	_profile = SimulationTempoProfile.from_dict(DeterministicStateHasher.v_dict(data.get("profile")))
	_last_pause_rejection_code = StringName(DeterministicStateHasher.v_str(data.get("last_pause_rejection_code", "")))
	_last_pause_rejection_sender = ""
	EventBus.session_tempo_changed.emit(
		_profile.session_mode,
		_profile.is_paused,
		_profile.speed_scale,
		_profile.offline_doctrine_protection_active)
	return true
