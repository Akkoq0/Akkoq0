class_name OnlineSessionHost
extends RefCounted
## Authoritative Multiplayer Session Host (rank 2).
## Runs on `NetworkTransportAdapter` (`ENetTransportAdapter` or `LoopbackNetworkTransport`),
## validates and sequences incoming client `CommandEnvelope`s through `CommandBus`,
## detects world-state hash desyncs via `DeterministicStateHasher`, activates
## `OfflineDoctrineConfig` on disconnect, and streams `SaveLoadRepository`
## snapshots on reconnect or desync repair.


class PeerSessionRecord:
	extends RefCounted
	var peer_id: int = 0
	var player_id: int = 0
	var army_id: int = 0
	var connected: bool = false
	var was_disconnected: bool = false
	var reconnect_count: int = 0
	var offline_doctrine_active: bool = false
	var last_reported_tick: int = 0
	var last_reported_hash: String = ""

	func _init(p_peer: int = 0, p_pid: int = 0, p_army: int = 0) -> void:
		peer_id = p_peer
		player_id = p_pid
		army_id = p_army


class DesyncEventRecord:
	extends RefCounted
	var tick: int = 0
	var peer_id: int = 0
	var expected_hash: String = ""
	var received_hash: String = ""

	func _init(p_tick: int = 0, p_peer: int = 0, p_exp: String = "", p_got: String = "") -> void:
		tick = p_tick
		peer_id = p_peer
		expected_hash = p_exp
		received_hash = p_got


var _transport: NetworkTransportAdapter = null
var _room_id: StringName = &""
var _port: int = 7777
var _max_players: int = 8
var _hash_check_interval: int = 2

var _peers: Dictionary[int, PeerSessionRecord] = {}
var _tick_hashes: Dictionary[int, String] = {}
var _desync_reports: Array[DesyncEventRecord] = []
var _last_confirmed_tick: int = 0
var _last_authoritative_hash: String = ""
var _confirmed_envelopes_total: int = 0
var _rejected_commands_total: int = 0
var _resync_packets_sent: int = 0


func _init(p_transport: NetworkTransportAdapter = null, p_hash_check_interval: int = 2) -> void:
	_transport = p_transport
	_hash_check_interval = maxi(p_hash_check_interval, 1)


func bind_transport(transport: NetworkTransportAdapter) -> void:
	_transport = transport


func set_hash_check_interval(interval_ticks: int) -> void:
	_hash_check_interval = maxi(interval_ticks, 1)


func host_room(
		room_id: StringName,
		port: int = 7777,
		max_players: int = 8,
		tick_rate_hz: float = 10.0) -> bool:
	if _transport == null:
		_transport = LoopbackNetworkTransport.new()
	if not _transport.host_room(room_id, port, max_players):
		return false

	_room_id = room_id
	_port = port
	_max_players = maxi(max_players, 2)
	_peers.clear()
	_tick_hashes.clear()
	_desync_reports.clear()
	_confirmed_envelopes_total = 0
	_rejected_commands_total = 0
	_resync_packets_sent = 0

	SessionClockAuthority.configure_session_mode(GameEnums.SessionMode.ONLINE_PERSISTENT_WORLD, 1.0, tick_rate_hz)
	GracePeriodManager.configure_persistent_world(true, GracePeriodManager.get_server_elapsed_hours())
	_last_confirmed_tick = SessionClockAuthority.get_current_tick()
	_last_authoritative_hash = DeterministicStateHasher.compute_world_hash(WorldSnapshotSerializer.export_state_dict())
	_tick_hashes[_last_confirmed_tick] = _last_authoritative_hash
	EventBus.network_room_hosted.emit(_room_id, _port, _max_players)
	return true


func poll_incoming() -> void:
	if _transport == null or not _transport.is_transport_active():
		return

	var events: Array[NetworkTransportAdapter.TransportLifecycleEvent] = _transport.poll_events()
	for ev: NetworkTransportAdapter.TransportLifecycleEvent in events:
		if ev == null:
			continue
		if ev.event_type == &"peer_connected":
			_handle_peer_connected(ev.peer_id, ev.is_reconnect)
		elif ev.event_type == &"peer_disconnected":
			_handle_peer_disconnected(ev.peer_id)

	var packets: Array[NetworkTransportAdapter.NetworkPacket] = _transport.poll_packets()
	for pkt: NetworkTransportAdapter.NetworkPacket in packets:
		if pkt == null:
			continue
		if pkt.packet_type == &"client_command":
			_handle_client_command_packet(pkt)
		elif pkt.packet_type == &"client_hash_report":
			_handle_client_hash_report(pkt)


func step_authoritative_tick(steps: int = 1) -> int:
	if _transport == null or not _transport.is_transport_active():
		return _last_confirmed_tick
	var count: int = maxi(steps, 1)
	for _s: int in range(count):
		poll_incoming()
		var next_tick: int = SessionClockAuthority.advance_tick(1)
		var flushed: int = CommandBus.flush_envelopes_for_tick(next_tick)
		_confirmed_envelopes_total += flushed
		var auth_hash: String = DeterministicStateHasher.compute_world_hash(WorldSnapshotSerializer.export_state_dict())
		_last_confirmed_tick = next_tick
		_last_authoritative_hash = auth_hash
		_tick_hashes[next_tick] = auth_hash

		var check_now: bool = (next_tick % _hash_check_interval) == 0
		var confirm_payload: Dictionary = {
			"flushed_count": flushed,
			"hash_check": check_now,
			"tick": next_tick,
			"world_hash": auth_hash,
		}
		_transport.send_packet(&"tick_confirm", confirm_payload, 0)
		EventBus.network_tick_confirmed.emit(next_tick, flushed, auth_hash)
	return _last_confirmed_tick


func close_host() -> void:
	if _transport != null:
		_transport.close_transport()


func get_peer_record(peer_id: int) -> PeerSessionRecord:
	return _peers.get(peer_id, null)


func get_connected_client_count() -> int:
	var c: int = 0
	for pid: int in _peers:
		var rec: PeerSessionRecord = _peers[pid]
		if rec != null and rec.connected:
			c += 1
	return c


func get_last_confirmed_tick() -> int:
	return _last_confirmed_tick


func get_last_authoritative_hash() -> String:
	return _last_authoritative_hash


func get_confirmed_envelopes_total() -> int:
	return _confirmed_envelopes_total


func get_rejected_commands_total() -> int:
	return _rejected_commands_total


func get_desync_count() -> int:
	return _desync_reports.size()


func get_desync_reports() -> Array[DesyncEventRecord]:
	var copy: Array[DesyncEventRecord] = []
	for d: DesyncEventRecord in _desync_reports:
		copy.append(d)
	return copy


func get_resync_packets_sent() -> int:
	return _resync_packets_sent


func _handle_peer_connected(peer_id: int, transport_reconnect: bool) -> void:
	if peer_id <= 1:
		return
	var rec: PeerSessionRecord = _peers.get(peer_id, null)
	var is_reconn: bool = transport_reconnect or (rec != null and rec.was_disconnected)
	if rec == null:
		rec = PeerSessionRecord.new(peer_id, peer_id, peer_id)
		_peers[peer_id] = rec
		GracePeriodManager.register_player(peer_id, false, Vector2i(8, 8), peer_id)
		CommandBus.register_envelope_army_owner(peer_id, peer_id)
	rec.connected = true
	if is_reconn:
		rec.was_disconnected = false
		rec.reconnect_count += 1
		rec.offline_doctrine_active = false
		GracePeriodManager.clear_player_offline_disconnect(peer_id)
		_send_snapshot_sync_to_peer(peer_id)
	EventBus.network_peer_connected.emit(_room_id, peer_id, is_reconn)


func _handle_peer_disconnected(peer_id: int) -> void:
	if peer_id <= 1:
		return
	var rec: PeerSessionRecord = _peers.get(peer_id, null)
	if rec == null:
		rec = PeerSessionRecord.new(peer_id, peer_id, peer_id)
		_peers[peer_id] = rec
	rec.connected = false
	rec.was_disconnected = true
	rec.offline_doctrine_active = true
	GracePeriodManager.activate_offline_doctrine_for_player(rec.player_id, rec.army_id)
	EventBus.network_peer_disconnected.emit(_room_id, peer_id, true)


func _handle_client_command_packet(pkt: NetworkTransportAdapter.NetworkPacket) -> void:
	var rec: PeerSessionRecord = _peers.get(pkt.sender_peer_id, null)
	if rec == null or not rec.connected:
		_rejected_commands_total += 1
		return
	var d: Dictionary = pkt.payload
	var seq_id: int = DeterministicStateHasher.v_int(d.get("sequence_id", 0), 0)
	var sender_str: String = DeterministicStateHasher.v_str(d.get("sender_player_id", ""))
	var target_tick: int = DeterministicStateHasher.v_int(d.get("target_tick", _last_confirmed_tick + 1), _last_confirmed_tick + 1)
	var cmd_type: String = DeterministicStateHasher.v_str(d.get("command_type", ""))
	var cmd_payload: Dictionary = DeterministicStateHasher.v_dict(d.get("payload", {}))

	var env: CommandEnvelope = CommandEnvelope.new(seq_id, sender_str, target_tick, cmd_type, cmd_payload)
	if env.parse_player_id() != rec.player_id:
		_rejected_commands_total += 1
		return
	var cur_tick: int = SessionClockAuthority.get_current_tick()
	env.target_tick = maxi(env.target_tick, cur_tick)
	if not CommandBus.enqueue_envelope(env, cur_tick):
		_rejected_commands_total += 1


func _handle_client_hash_report(pkt: NetworkTransportAdapter.NetworkPacket) -> void:
	var d: Dictionary = pkt.payload
	var reported_tick: int = DeterministicStateHasher.v_int(d.get("tick", 0), 0)
	var reported_hash: String = DeterministicStateHasher.v_str(d.get("world_hash", ""))
	var rec: PeerSessionRecord = _peers.get(pkt.sender_peer_id, null)
	if rec != null:
		rec.last_reported_tick = reported_tick
		rec.last_reported_hash = reported_hash

	if _tick_hashes.has(reported_tick):
		var expected: String = _tick_hashes[reported_tick]
		if reported_hash != expected:
			var dr: DesyncEventRecord = DesyncEventRecord.new(reported_tick, pkt.sender_peer_id, expected, reported_hash)
			_desync_reports.append(dr)
			EventBus.network_desync_detected.emit(reported_tick, pkt.sender_peer_id, expected, reported_hash)
			_send_snapshot_sync_to_peer(pkt.sender_peer_id)


func _send_snapshot_sync_to_peer(peer_id: int) -> void:
	if _transport == null or not _transport.is_transport_active():
		return
	var pkg: String = SaveLoadRepository.serialize_save_package()
	var auth_hash: String = DeterministicStateHasher.compute_world_hash(WorldSnapshotSerializer.export_state_dict())
	_last_authoritative_hash = auth_hash
	var payload: Dictionary = {
		"package_json": pkg,
		"tick": _last_confirmed_tick,
		"world_hash": auth_hash,
	}
	if _transport.send_packet(&"snapshot_sync", payload, peer_id):
		_resync_packets_sent += 1
