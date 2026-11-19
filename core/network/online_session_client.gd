class_name OnlineSessionClient
extends RefCounted
## Multiplayer Session Client (rank 2). Connects via `NetworkTransportAdapter`
## (`ENetTransportAdapter` or `LoopbackNetworkTransport`), dispatches typed
## `CommandEnvelope` submissions to `OnlineSessionHost`, verifies periodic
## deterministic SHA-256 hashes, and resynchronizes from `SaveLoadRepository`
## snapshots upon reconnect or desync repair.

var _transport: NetworkTransportAdapter = null
var _room_id: StringName = &""
var _player_id: int = 2
var _host_addr: String = "127.0.0.1"
var _port: int = 7777
var _seq: int = 0

var _last_confirmed_tick: int = 0
var _last_authoritative_hash: String = ""
var _ticks_confirmed_count: int = 0
var _resync_count: int = 0
var _debug_hash_override: String = ""


func _init(p_transport: NetworkTransportAdapter = null, p_player_id: int = 2) -> void:
	_transport = p_transport
	_player_id = maxi(p_player_id, 2)


func bind_transport(transport: NetworkTransportAdapter) -> void:
	_transport = transport


func connect_to_room(
		room_id: StringName,
		player_id: int = 2,
		host_addr: String = "127.0.0.1",
		port: int = 7777) -> bool:
	if _transport == null:
		_transport = LoopbackNetworkTransport.new()
	_room_id = room_id
	_player_id = maxi(player_id, 2)
	_host_addr = host_addr
	_port = port
	var ok: bool = _transport.join_room(_room_id, _host_addr, _port, _player_id)
	if ok:
		_seq = maxi(_seq, CommandBus.get_last_sequence_for_sender(str(_player_id)))
	return ok


func disconnect_from_room() -> void:
	if _transport != null:
		_transport.simulate_disconnect()


func reconnect_to_room(
		room_id: StringName = &"",
		host_addr: String = "",
		port: int = -1) -> bool:
	var target_room: StringName = room_id if room_id != &"" else _room_id
	var target_host: String = host_addr if not host_addr.is_empty() else _host_addr
	var target_port: int = port if port > 0 else _port
	return connect_to_room(target_room, _player_id, target_host, target_port)


func is_connected_to_room() -> bool:
	return _transport != null and _transport.is_transport_active()


func submit_command(
		command_type: String,
		payload: Dictionary,
		target_tick_offset: int = 1) -> CommandEnvelope:
	if not is_connected_to_room():
		return null
	var sender_str: String = str(_player_id)
	_seq = maxi(_seq + 1, CommandBus.get_last_sequence_for_sender(sender_str) + 1)
	var base_tick: int = maxi(_last_confirmed_tick, SessionClockAuthority.get_current_tick())
	var target_tick: int = base_tick + maxi(target_tick_offset, 0)
	var env: CommandEnvelope = CommandEnvelope.new(_seq, sender_str, target_tick, command_type, payload)

	var net_payload: Dictionary = {
		"command_type": command_type,
		"payload": payload,
		"sender_player_id": sender_str,
		"sequence_id": _seq,
		"target_tick": target_tick,
	}
	if not _transport.send_packet(&"client_command", net_payload, 1):
		return null
	return env


func set_debug_hash_override(fake_hash: String) -> void:
	_debug_hash_override = fake_hash


func poll_server_updates() -> void:
	if _transport == null:
		return
	var _events: Array[NetworkTransportAdapter.TransportLifecycleEvent] = _transport.poll_events()
	var packets: Array[NetworkTransportAdapter.NetworkPacket] = _transport.poll_packets()
	for pkt: NetworkTransportAdapter.NetworkPacket in packets:
		if pkt == null:
			continue
		if pkt.packet_type == &"tick_confirm":
			_handle_tick_confirm(pkt.payload)
		elif pkt.packet_type == &"snapshot_sync":
			_handle_snapshot_sync(pkt.payload)


func compute_local_hash() -> String:
	if not _debug_hash_override.is_empty():
		return _debug_hash_override
	return DeterministicStateHasher.compute_world_hash(WorldSnapshotSerializer.export_state_dict())


func get_player_id() -> int:
	return _player_id


func get_last_confirmed_tick() -> int:
	return _last_confirmed_tick


func get_last_authoritative_hash() -> String:
	return _last_authoritative_hash


func get_ticks_confirmed_count() -> int:
	return _ticks_confirmed_count


func get_resync_count() -> int:
	return _resync_count


func _handle_tick_confirm(d: Dictionary) -> void:
	var tick: int = DeterministicStateHasher.v_int(d.get("tick", 0), 0)
	var auth_hash: String = DeterministicStateHasher.v_str(d.get("world_hash", ""))
	var hash_check: bool = DeterministicStateHasher.v_bool(d.get("hash_check", false), false)
	_last_confirmed_tick = tick
	_last_authoritative_hash = auth_hash
	_ticks_confirmed_count += 1

	if hash_check:
		var report_payload: Dictionary = {
			"tick": tick,
			"world_hash": compute_local_hash(),
		}
		_transport.send_packet(&"client_hash_report", report_payload, 1)


func _handle_snapshot_sync(d: Dictionary) -> void:
	var pkg_json: String = DeterministicStateHasher.v_str(d.get("package_json", ""))
	var sync_tick: int = DeterministicStateHasher.v_int(d.get("tick", 0), 0)
	if pkg_json.is_empty():
		return
	_debug_hash_override = ""
	if SaveLoadRepository.load_save_package(pkg_json):
		_last_confirmed_tick = sync_tick
		_last_authoritative_hash = DeterministicStateHasher.compute_world_hash(WorldSnapshotSerializer.export_state_dict())
		_resync_count += 1
		EventBus.network_snapshot_resynced.emit(_player_id, sync_tick, _last_authoritative_hash)
