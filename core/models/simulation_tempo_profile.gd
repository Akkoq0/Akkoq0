class_name SimulationTempoProfile
extends RefCounted
## Core model (rank 2). Defines the Phase 28 dual-mode simulation tempo
## contract for `SINGLEPLAYER_SESSION` (pausable, 1x/2x/4x) and
## `ONLINE_PERSISTENT_WORLD` (unpausable fixed tick rate, active offline watch).

var session_mode: GameEnums.SessionMode = GameEnums.SessionMode.SINGLEPLAYER_SESSION
var can_pause: bool = true
var is_paused: bool = false
var speed_scale: float = 1.0
var authoritative_tick_rate_hz: float = 10.0
var offline_doctrine_protection_active: bool = false


static func create_singleplayer(p_speed_scale: float = 1.0, p_paused: bool = false) -> SimulationTempoProfile:
	var prof: SimulationTempoProfile = SimulationTempoProfile.new()
	prof.session_mode = GameEnums.SessionMode.SINGLEPLAYER_SESSION
	prof.can_pause = true
	prof.is_paused = p_paused
	prof.speed_scale = clampf(p_speed_scale, 1.0, 4.0)
	prof.authoritative_tick_rate_hz = 10.0
	prof.offline_doctrine_protection_active = false
	return prof


static func create_online_persistent(p_tick_rate_hz: float = 10.0) -> SimulationTempoProfile:
	var prof: SimulationTempoProfile = SimulationTempoProfile.new()
	prof.session_mode = GameEnums.SessionMode.ONLINE_PERSISTENT_WORLD
	prof.can_pause = false
	prof.is_paused = false
	prof.speed_scale = 1.0
	prof.authoritative_tick_rate_hz = clampf(p_tick_rate_hz, 1.0, 60.0)
	prof.offline_doctrine_protection_active = true
	return prof


func duplicate_profile() -> SimulationTempoProfile:
	var copy: SimulationTempoProfile = SimulationTempoProfile.new()
	copy.session_mode = session_mode
	copy.can_pause = can_pause
	copy.is_paused = is_paused
	copy.speed_scale = speed_scale
	copy.authoritative_tick_rate_hz = authoritative_tick_rate_hz
	copy.offline_doctrine_protection_active = offline_doctrine_protection_active
	return copy


func export_dict() -> Dictionary:
	return {
		"authoritative_tick_rate_hz": authoritative_tick_rate_hz,
		"can_pause": can_pause,
		"is_paused": is_paused,
		"offline_doctrine_protection_active": offline_doctrine_protection_active,
		"session_mode": int(session_mode),
		"speed_scale": speed_scale,
	}


static func from_dict(data: Dictionary) -> SimulationTempoProfile:
	var mode_val: int = DeterministicStateHasher.v_int(
		data.get("session_mode", int(GameEnums.SessionMode.SINGLEPLAYER_SESSION)),
		int(GameEnums.SessionMode.SINGLEPLAYER_SESSION))
	var prof: SimulationTempoProfile = SimulationTempoProfile.new()
	if mode_val == int(GameEnums.SessionMode.ONLINE_PERSISTENT_WORLD):
		prof.session_mode = GameEnums.SessionMode.ONLINE_PERSISTENT_WORLD
		prof.can_pause = false
		prof.is_paused = false
		prof.speed_scale = 1.0
		var off_raw: Variant = data.get("offline_doctrine_protection_active", true)
		prof.offline_doctrine_protection_active = off_raw if typeof(off_raw) == TYPE_BOOL else true
	else:
		prof.session_mode = GameEnums.SessionMode.SINGLEPLAYER_SESSION
		var cp_raw: Variant = data.get("can_pause", true)
		prof.can_pause = cp_raw if typeof(cp_raw) == TYPE_BOOL else true
		var ip_raw: Variant = data.get("is_paused", false)
		prof.is_paused = ip_raw if typeof(ip_raw) == TYPE_BOOL else false
		var ss_raw: Variant = data.get("speed_scale", 1.0)
		var ss_val: float = 1.0
		if typeof(ss_raw) == TYPE_FLOAT:
			ss_val = ss_raw
		elif typeof(ss_raw) == TYPE_INT:
			var ss_i: int = ss_raw
			ss_val = float(ss_i)
		prof.speed_scale = clampf(ss_val, 1.0, 4.0)
		var off2_raw: Variant = data.get("offline_doctrine_protection_active", false)
		prof.offline_doctrine_protection_active = off2_raw if typeof(off2_raw) == TYPE_BOOL else false
	var hz_raw: Variant = data.get("authoritative_tick_rate_hz", 10.0)
	var hz_val: float = 10.0
	if typeof(hz_raw) == TYPE_FLOAT:
		hz_val = hz_raw
	elif typeof(hz_raw) == TYPE_INT:
		var hz_i: int = hz_raw
		hz_val = float(hz_i)
	prof.authoritative_tick_rate_hz = clampf(hz_val, 1.0, 60.0)
	return prof
