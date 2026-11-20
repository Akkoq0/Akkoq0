class_name LanDiscoveryBeacon
extends RefCounted
## Lightweight UDP LAN Room Discovery Beacon (rank 2).
## Host broadcasts room metadata on port 7778; Clients listen and surface
## discovered LAN rooms without blocking.

signal rooms_updated(rooms: Array[LanRoomInfo])

const DISCOVERY_PORT: int = 7778
const BROADCAST_INTERVAL_SEC: float = 1.0
const ROOM_EXPIRE_SEC: float = 4.5


class LanRoomInfo:
	extends RefCounted
	var room_id: String = ""
	var host_name: String = "Kağan"
	var host_ip: String = ""
	var port: int = 7777
	var player_count: int = 1
	var max_players: int = 4
	var world_seed: int = 1042
	var quick_match: bool = false
	var last_seen_msec: int = 0

	func to_dict() -> Dictionary:
		return {
			"room_id": room_id,
			"host_name": host_name,
			"port": port,
			"player_count": player_count,
			"max_players": max_players,
			"world_seed": world_seed,
			"quick_match": quick_match,
		}


var _udp: PacketPeerUDP = null
var _is_broadcasting: bool = false
var _is_listening: bool = false
var _broadcast_accum: float = 0.0
var _room_payload: Dictionary = {}
var _discovered: Dictionary[String, LanRoomInfo] = {}


func start_broadcasting(
		room_id: String,
		host_name: String,
		game_port: int,
		player_count: int,
		max_players: int,
		world_seed: int,
		quick_match: bool) -> bool:
	stop()
	_udp = PacketPeerUDP.new()
	_udp.set_broadcast_enabled(true)
	var err: Error = _udp.set_dest_address("255.255.255.255", DISCOVERY_PORT)
	if err != OK:
		_udp.close()
		_udp = null
		return false
	_is_broadcasting = true
	update_broadcast_metadata(room_id, host_name, game_port, player_count, max_players, world_seed, quick_match)
	_send_beacon_now()
	return true


func update_broadcast_metadata(
		room_id: String,
		host_name: String,
		game_port: int,
		player_count: int,
		max_players: int,
		world_seed: int,
		quick_match: bool) -> void:
	_room_payload = {
		"otuken_lan": 1,
		"room_id": room_id,
		"host_name": host_name,
		"port": game_port,
		"player_count": player_count,
		"max_players": max_players,
		"world_seed": world_seed,
		"quick_match": quick_match,
	}


func start_listening() -> bool:
	stop()
	_udp = PacketPeerUDP.new()
	var err: Error = _udp.bind(DISCOVERY_PORT, "*")
	if err != OK:
		_udp.close()
		_udp = null
		return false
	_is_listening = true
	_discovered.clear()
	return true


func stop() -> void:
	if _udp != null:
		_udp.close()
		_udp = null
	_is_broadcasting = false
	_is_listening = false
	_broadcast_accum = 0.0


func poll(delta: float) -> void:
	if _udp == null:
		return
	if _is_broadcasting:
		_broadcast_accum += delta
		if _broadcast_accum >= BROADCAST_INTERVAL_SEC:
			_broadcast_accum = 0.0
			_send_beacon_now()
		return

	if _is_listening:
		var changed: bool = false
		while _udp.get_available_packet_count() > 0:
			var pkt_bytes: PackedByteArray = _udp.get_packet()
			var sender_ip: String = _udp.get_packet_ip()
			var text: String = pkt_bytes.get_string_from_utf8()
			var json: JSON = JSON.new()
			if json.parse(text) == OK and json.data is Dictionary:
				var d: Dictionary = DeterministicStateHasher.v_dict(json.data)
				if DeterministicStateHasher.v_int(d.get("otuken_lan", 0), 0) == 1:
					var info: LanRoomInfo = LanRoomInfo.new()
					info.room_id = str(d.get("room_id", "OTUKEN"))
					info.host_name = str(d.get("host_name", "Kağan"))
					info.host_ip = sender_ip
					info.port = DeterministicStateHasher.v_int(d.get("port", 7777), 7777)
					info.player_count = DeterministicStateHasher.v_int(d.get("player_count", 1), 1)
					info.max_players = DeterministicStateHasher.v_int(d.get("max_players", 4), 4)
					info.world_seed = DeterministicStateHasher.v_int(d.get("world_seed", 1042), 1042)
					info.quick_match = DeterministicStateHasher.v_bool(d.get("quick_match", false), false)
					info.last_seen_msec = Time.get_ticks_msec()
					var key: String = "%s:%d" % [sender_ip, info.port]
					_discovered[key] = info
					changed = true
		var now_msec: int = Time.get_ticks_msec()
		var expired: Array[String] = []
		for k: String in _discovered.keys():
			if float(now_msec - _discovered[k].last_seen_msec) * 0.001 > ROOM_EXPIRE_SEC:
				expired.append(k)
		for ek: String in expired:
			_discovered.erase(ek)
			changed = true
		if changed:
			rooms_updated.emit(get_discovered_rooms())


func get_discovered_rooms() -> Array[LanRoomInfo]:
	var out: Array[LanRoomInfo] = []
	for k: String in _discovered.keys():
		out.append(_discovered[k])
	return out


static func get_local_lan_ips() -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for addr: String in IP.get_local_addresses():
		if addr.contains(":") or addr.begins_with("127.") or addr.begins_with("169.254."):
			continue
		out.append(addr)
	return out


func _send_beacon_now() -> void:
	if _udp == null or _room_payload.is_empty():
		return
	var json_str: String = JSON.stringify(_room_payload)
	_udp.put_packet(json_str.to_utf8_buffer())
