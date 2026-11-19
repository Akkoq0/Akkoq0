class_name ENetTransportAdapter
extends NetworkTransportAdapter
## Real ENet Socket Transport Adapter (rank 2) wrapping Godot 4.7's
## `ENetMultiplayerPeer` with clean UTF-8 JSON framing and strict signal cleanup.

var _enet: ENetMultiplayerPeer = null
var _room_id: StringName = &""
var _is_server: bool = false
var _active: bool = false
var _local_peer_id: int = 0
var _seq: int = 0
var _connected_peers: Dictionary[int, bool] = {}
var _known_peers: Dictionary[int, bool] = {}
var _pending_events: Array[NetworkTransportAdapter.TransportLifecycleEvent] = []
var _peer_conn_cb: Callable = Callable()
var _peer_disc_cb: Callable = Callable()


func host_room(room_id: StringName, port: int = 7777, max_players: int = 8) -> bool:
	close_transport()
	_enet = ENetMultiplayerPeer.new()
	var err: Error = _enet.create_server(port, maxi(max_players, 2))
	if err != OK:
		_enet = null
		return false
	_room_id = room_id
	_is_server = true
	_active = true
	_local_peer_id = 1
	_connected_peers.clear()
	_connected_peers[1] = true
	_bind_enet_signals()
	return true


func join_room(
		room_id: StringName,
		host_addr: String = "127.0.0.1",
		port: int = 7777,
		_peer_id: int = 2) -> bool:
	close_transport()
	_enet = ENetMultiplayerPeer.new()
	var err: Error = _enet.create_client(host_addr, port)
	if err != OK:
		_enet = null
		return false
	_room_id = room_id
	_is_server = false
	_active = true
	_local_peer_id = _enet.get_unique_id()
	_connected_peers.clear()
	_bind_enet_signals()
	return true


func close_transport() -> void:
	_unbind_enet_signals()
	if _enet != null:
		_enet.close()
		_enet = null
	_active = false
	_connected_peers.clear()


func is_transport_active() -> bool:
	return _active and _enet != null


func is_server_transport() -> bool:
	return _is_server


func get_local_peer_id() -> int:
	if _enet != null and _local_peer_id == 0:
		_local_peer_id = _enet.get_unique_id()
	return _local_peer_id


func get_room_id() -> StringName:
	return _room_id


func get_connected_peer_ids() -> PackedInt32Array:
	var out: PackedInt32Array = PackedInt32Array()
	var keys: Array[int] = []
	for pid: int in _connected_peers:
		if _connected_peers[pid]:
			keys.append(pid)
	keys.sort()
	for k: int in keys:
		out.append(k)
	return out


func send_packet(
		packet_type: StringName,
		payload: Dictionary,
		target_peer_id: int = 0) -> bool:
	if not is_transport_active() or packet_type == &"":
		return false
	_enet.poll()
	_seq += 1
	var frame: Dictionary = {
		"payload": payload,
		"sender": get_local_peer_id(),
		"seq": _seq,
		"type": String(packet_type),
	}
	var bytes: PackedByteArray = JSON.stringify(frame).to_utf8_buffer()
	var target: int = 1 if not _is_server else target_peer_id
	_enet.set_target_peer(target)
	return _enet.put_packet(bytes) == OK


func poll_packets() -> Array[NetworkPacket]:
	var out: Array[NetworkPacket] = []
	if not is_transport_active():
		return out
	_enet.poll()
	while _enet.get_available_packet_count() > 0:
		var from_peer: int = _enet.get_packet_peer()
		var raw: PackedByteArray = _enet.get_packet()
		var txt: String = raw.get_string_from_utf8()
		var jp: JSON = JSON.new()
		if jp.parse(txt) == OK and jp.data is Dictionary:
			var d: Dictionary = DeterministicStateHasher.v_dict(jp.data)
			var p_type: StringName = StringName(DeterministicStateHasher.v_str(d.get("type", "")))
			var seq_val: int = DeterministicStateHasher.v_int(d.get("seq", 0), 0)
			var payload_dict: Dictionary = DeterministicStateHasher.v_dict(d.get("payload", {}))
			out.append(NetworkPacket.new(p_type, from_peer, get_local_peer_id(), seq_val, payload_dict))
	return out


func poll_events() -> Array[TransportLifecycleEvent]:
	var out: Array[TransportLifecycleEvent] = []
	if _enet != null:
		_enet.poll()
	for ev: TransportLifecycleEvent in _pending_events:
		out.append(ev)
	_pending_events.clear()
	return out


func _bind_enet_signals() -> void:
	if _enet == null:
		return
	_peer_conn_cb = _on_enet_peer_connected
	_peer_disc_cb = _on_enet_peer_disconnected
	if not _enet.peer_connected.is_connected(_peer_conn_cb):
		_enet.peer_connected.connect(_peer_conn_cb)
	if not _enet.peer_disconnected.is_connected(_peer_disc_cb):
		_enet.peer_disconnected.connect(_peer_disc_cb)


func _unbind_enet_signals() -> void:
	if _enet == null:
		return
	if _peer_conn_cb.is_valid() and _enet.peer_connected.is_connected(_peer_conn_cb):
		_enet.peer_connected.disconnect(_peer_conn_cb)
	if _peer_disc_cb.is_valid() and _enet.peer_disconnected.is_connected(_peer_disc_cb):
		_enet.peer_disconnected.disconnect(_peer_disc_cb)
	_peer_conn_cb = Callable()
	_peer_disc_cb = Callable()


func _on_enet_peer_connected(peer_id: int) -> void:
	var is_reconn: bool = _known_peers.has(peer_id) and not _connected_peers.get(peer_id, false)
	_connected_peers[peer_id] = true
	_known_peers[peer_id] = true
	_pending_events.append(TransportLifecycleEvent.new(&"peer_connected", peer_id, is_reconn, "enet_connected"))


func _on_enet_peer_disconnected(peer_id: int) -> void:
	_connected_peers[peer_id] = false
	_pending_events.append(TransportLifecycleEvent.new(&"peer_disconnected", peer_id, false, "enet_disconnected"))
