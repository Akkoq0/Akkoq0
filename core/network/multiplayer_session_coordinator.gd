class_name MultiplayerSessionCoordinator
extends Node
## Live Multiplayer Session Coordinator (rank 3).
## Bridges `ENetTransportAdapter` / `LoopbackNetworkTransport`, `OnlineSessionHost`,
## `OnlineSessionClient`, and `LanDiscoveryBeacon` for 2-4 player LAN/IP matches.

signal lobby_roster_changed(roster: Array[Dictionary])
signal match_launch_received(seed: int, quick_match: bool, assigned_player_id: int, assigned_army_id: int)
signal peer_connection_notice(message: String, is_blocking: bool)
signal host_disconnected_match_ended(reason: String)

enum NetRole { NONE, HOST, CLIENT }

const DEFAULT_GAME_PORT: int = 7777
const HOST_TICK_INTERVAL_SEC: float = 0.1
const CLIENT_POLL_INTERVAL_SEC: float = 0.05
const DISCONNECT_AI_TAKEOVER_SEC: float = 20.0

var _role: NetRole = NetRole.NONE
var _transport: NetworkTransportAdapter = null
var _host: OnlineSessionHost = null
var _client: OnlineSessionClient = null
var _beacon: LanDiscoveryBeacon = null

var _room_id: StringName = &"OTUKEN"
var _port: int = DEFAULT_GAME_PORT
var _world_seed: int = 1042
var _quick_match: bool = false
var _fill_ai: bool = true
var _local_player_id: int = 1
var _local_army_id: int = 1
var _in_match: bool = false
var _tick_accum: float = 0.0
var _disconnect_wait_sec: float = 0.0
var _waiting_for_peer: bool = false

# Lobby roster: peer_id -> { peer_id, player_id, army_id, name, ready, is_ai }
var _roster: Dictionary[int, Dictionary] = {}


func _ready() -> void:
	_beacon = LanDiscoveryBeacon.new()


func _exit_tree() -> void:
	stop_session()


func _process(delta: float) -> void:
	if _beacon != null:
		_beacon.poll(delta)

	if _role == NetRole.HOST and _host != null:
		_tick_accum += delta
		if _in_match:
			if _tick_accum >= HOST_TICK_INTERVAL_SEC:
				_tick_accum = 0.0
				_host.step_authoritative_tick(1)
		else:
			if _tick_accum >= CLIENT_POLL_INTERVAL_SEC:
				_tick_accum = 0.0
				_host.poll_incoming()
				_sync_host_roster_from_peers()

		if _waiting_for_peer:
			_disconnect_wait_sec += delta
			if _disconnect_wait_sec >= DISCONNECT_AI_TAKEOVER_SEC:
				_waiting_for_peer = false
				peer_connection_notice.emit("Bağlantısı kopan oyuncu yapay zekaya devredildi.", false)

	elif _role == NetRole.CLIENT and _client != null:
		_tick_accum += delta
		if _tick_accum >= CLIENT_POLL_INTERVAL_SEC:
			_tick_accum = 0.0
			_client.poll_server_updates()
			if not _client.is_connected_to_room():
				if _in_match:
					_in_match = false
					host_disconnected_match_ended.emit("Oda kurucusuyla bağlantı kesildi.")


func host_lobby(
		room_id: StringName,
		port: int = DEFAULT_GAME_PORT,
		world_seed: int = 1042,
		quick_match: bool = false,
		fill_ai: bool = true,
		host_name: String = "Kağan",
		custom_transport: NetworkTransportAdapter = null) -> bool:
	stop_session()
	_role = NetRole.HOST
	_room_id = room_id
	_port = port
	_world_seed = maxi(world_seed, 1)
	_quick_match = quick_match
	_fill_ai = fill_ai
	_local_player_id = 1
	_local_army_id = 1
	_in_match = false

	_transport = custom_transport if custom_transport != null else ENetTransportAdapter.new()
	_host = OnlineSessionHost.new(_transport, 2)
	if not _host.host_room(_room_id, _port, 4, 10.0):
		stop_session()
		return false

	_roster.clear()
	_roster[1] = {
		"peer_id": 1,
		"player_id": 1,
		"army_id": 1,
		"name": host_name,
		"ready": true,
		"is_ai": false,
	}
	if _beacon != null and _transport is ENetTransportAdapter:
		_beacon.start_broadcasting(String(_room_id), host_name, _port, 1, 4, _world_seed, _quick_match)
	lobby_roster_changed.emit(get_roster_list())
	return true


func join_lobby(
		room_id: StringName,
		host_addr: String,
		port: int = DEFAULT_GAME_PORT,
		player_name: String = "Börü",
		custom_transport: NetworkTransportAdapter = null) -> bool:
	stop_session()
	_role = NetRole.CLIENT
	_room_id = room_id
	_port = port
	_local_player_id = 2
	_local_army_id = 2
	_in_match = false

	_transport = custom_transport if custom_transport != null else ENetTransportAdapter.new()
	_client = OnlineSessionClient.new(_transport, 2)
	if not _client.connect_to_room(_room_id, 2, host_addr, _port):
		stop_session()
		return false

	_roster.clear()
	_roster[1] = {
		"peer_id": 1,
		"player_id": 1,
		"army_id": 1,
		"name": "Kurucu",
		"ready": true,
		"is_ai": false,
	}
	_roster[2] = {
		"peer_id": 2,
		"player_id": 2,
		"army_id": 2,
		"name": player_name,
		"ready": true,
		"is_ai": false,
	}
	lobby_roster_changed.emit(get_roster_list())
	return true


func start_lan_discovery() -> bool:
	if _beacon == null:
		_beacon = LanDiscoveryBeacon.new()
	return _beacon.start_listening()


func get_beacon() -> LanDiscoveryBeacon:
	return _beacon


func update_host_lobby_settings(world_seed: int, quick_match: bool, fill_ai: bool) -> void:
	_world_seed = maxi(world_seed, 1)
	_quick_match = quick_match
	_fill_ai = fill_ai
	if _beacon != null and _role == NetRole.HOST and _transport is ENetTransportAdapter:
		var host_entry: Dictionary = _roster[1] if _roster.has(1) else {}
		_beacon.update_broadcast_metadata(
			String(_room_id),
			str(host_entry.get("name", "Kağan")),
			_port,
			_roster.size(),
			4,
			_world_seed,
			_quick_match)


func host_launch_match() -> void:
	if _role != NetRole.HOST or _host == null:
		return
	if _beacon != null:
		_beacon.stop()
	_in_match = true
	if _transport != null:
		_transport.send_packet(&"lobby_launch", {
			"world_seed": _world_seed,
			"quick_match": _quick_match,
			"fill_ai": _fill_ai,
			"roster": get_roster_list(),
		}, 0)
	match_launch_received.emit(_world_seed, _quick_match, _local_player_id, _local_army_id)


func submit_player_command(command_type: String, payload: Dictionary) -> bool:
	if _role == NetRole.CLIENT and _client != null:
		var env: CommandEnvelope = _client.submit_command(command_type, payload, _local_army_id)
		return env != null
	return false


func stop_session() -> void:
	if _beacon != null:
		_beacon.stop()
	if _transport != null:
		_transport.close_transport()
		_transport = null
	_host = null
	_client = null
	_role = NetRole.NONE
	_in_match = false
	_waiting_for_peer = false
	_disconnect_wait_sec = 0.0
	_roster.clear()


func get_role() -> NetRole:
	return _role


func is_host() -> bool:
	return _role == NetRole.HOST


func is_client() -> bool:
	return _role == NetRole.CLIENT


func is_in_match() -> bool:
	return _in_match


func get_local_player_id() -> int:
	return _local_player_id


func get_local_army_id() -> int:
	return _local_army_id


func get_roster_list() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var keys: Array[int] = _roster.keys()
	keys.sort()
	for k: int in keys:
		out.append(_roster[k].duplicate())
	return out


func _sync_host_roster_from_peers() -> void:
	if _host == null or _transport == null:
		return
	var peer_ids: PackedInt32Array = _transport.get_connected_peer_ids()
	var changed: bool = false
	var next_slot: int = 2
	for pid: int in peer_ids:
		if not _roster.has(pid):
			_roster[pid] = {
				"peer_id": pid,
				"player_id": next_slot,
				"army_id": next_slot,
				"name": "Oyuncu %d" % next_slot,
				"ready": true,
				"is_ai": false,
			}
			changed = true
		next_slot += 1
	if changed:
		lobby_roster_changed.emit(get_roster_list())
