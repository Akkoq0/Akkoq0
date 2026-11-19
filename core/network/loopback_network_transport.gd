class_name LoopbackNetworkTransport
extends NetworkTransportAdapter
## Deterministic in-memory virtual transport (rank 2). Routes typed packets
## and connect/disconnect/reconnect lifecycle events between `OnlineSessionHost`
## and multiple `OnlineSessionClient` peers within headless tests or local co-sim.


class PacketMailbox:
	extends RefCounted
	var items: Array[NetworkTransportAdapter.NetworkPacket] = []


class EventMailbox:
	extends RefCounted
	var items: Array[NetworkTransportAdapter.TransportLifecycleEvent] = []


class LoopbackRoom:
	extends RefCounted
	var room_id: StringName = &""
	var host_peer_id: int = 1
	var max_players: int = 8
	var active_peers: Dictionary[int, bool] = {}
	var known_peers: Dictionary[int, bool] = {}
	var packet_boxes: Dictionary[int, PacketMailbox] = {}
	var event_boxes: Dictionary[int, EventMailbox] = {}
	var seq_counter: int = 0

	func _init(p_room_id: StringName = &"", p_max_players: int = 8) -> void:
		room_id = p_room_id
		max_players = maxi(p_max_players, 2)


static var _rooms: Dictionary[StringName, LoopbackRoom] = {}

var _room_id: StringName = &""
var _local_peer_id: int = 0
var _is_server: bool = false
var _is_connected: bool = false


static func reset_loopback_rooms() -> void:
	_rooms.clear()


static func has_room(room_id: StringName) -> bool:
	return _rooms.has(room_id)


func host_room(room_id: StringName, _port: int = 7777, max_players: int = 8) -> bool:
	if room_id == &"":
		return false
	var room: LoopbackRoom = LoopbackRoom.new(room_id, max_players)
	room.host_peer_id = 1
	room.active_peers[1] = true
	room.known_peers[1] = true
	room.packet_boxes[1] = PacketMailbox.new()
	room.event_boxes[1] = EventMailbox.new()
	_rooms[room_id] = room

	_room_id = room_id
	_local_peer_id = 1
	_is_server = true
	_is_connected = true
	return true


func join_room(
		room_id: StringName,
		_host_addr: String = "127.0.0.1",
		_port: int = 7777,
		peer_id: int = 2) -> bool:
	if room_id == &"" or not _rooms.has(room_id):
		return false
	var room: LoopbackRoom = _rooms[room_id]
	var resolved_pid: int = maxi(peer_id, 2)
	if room.active_peers.size() >= room.max_players and not room.active_peers.has(resolved_pid):
		return false

	var is_reconn: bool = room.known_peers.has(resolved_pid) and not room.active_peers.get(resolved_pid, false)
	room.active_peers[resolved_pid] = true
	room.known_peers[resolved_pid] = true
	if not room.packet_boxes.has(resolved_pid):
		room.packet_boxes[resolved_pid] = PacketMailbox.new()
	if not room.event_boxes.has(resolved_pid):
		room.event_boxes[resolved_pid] = EventMailbox.new()

	_room_id = room_id
	_local_peer_id = resolved_pid
	_is_server = false
	_is_connected = true

	var host_events: EventMailbox = room.event_boxes.get(room.host_peer_id, null)
	if host_events != null:
		host_events.items.append(TransportLifecycleEvent.new(&"peer_connected", resolved_pid, is_reconn, "joined"))
	var self_events: EventMailbox = room.event_boxes.get(resolved_pid, null)
	if self_events != null:
		self_events.items.append(TransportLifecycleEvent.new(&"peer_connected", resolved_pid, is_reconn, "connected_to_host"))
	return true


func close_transport() -> void:
	if not _is_connected or _room_id == &"" or not _rooms.has(_room_id):
		_is_connected = false
		return
	var room: LoopbackRoom = _rooms[_room_id]
	if _is_server:
		var peer_keys: Array[int] = []
		for pid: int in room.active_peers:
			peer_keys.append(pid)
		peer_keys.sort()
		for pid2: int in peer_keys:
			if pid2 != _local_peer_id and room.event_boxes.has(pid2):
				room.event_boxes[pid2].items.append(TransportLifecycleEvent.new(&"peer_disconnected", _local_peer_id, false, "host_closed"))
		_rooms.erase(_room_id)
	else:
		room.active_peers[_local_peer_id] = false
		if room.event_boxes.has(room.host_peer_id):
			room.event_boxes[room.host_peer_id].items.append(
				TransportLifecycleEvent.new(&"peer_disconnected", _local_peer_id, false, "client_disconnected"))
		if room.event_boxes.has(_local_peer_id):
			room.event_boxes[_local_peer_id].items.append(
				TransportLifecycleEvent.new(&"peer_disconnected", _local_peer_id, false, "self_disconnected"))
	_is_connected = false


func simulate_disconnect() -> void:
	close_transport()


func is_transport_active() -> bool:
	return _is_connected and _rooms.has(_room_id)


func is_server_transport() -> bool:
	return _is_server


func get_local_peer_id() -> int:
	return _local_peer_id


func get_room_id() -> StringName:
	return _room_id


func get_connected_peer_ids() -> PackedInt32Array:
	var out: PackedInt32Array = PackedInt32Array()
	if not _rooms.has(_room_id):
		return out
	var room: LoopbackRoom = _rooms[_room_id]
	var keys: Array[int] = []
	for pid: int in room.active_peers:
		if room.active_peers[pid]:
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
	var room: LoopbackRoom = _rooms[_room_id]
	room.seq_counter += 1
	var seq: int = room.seq_counter

	if not _is_server:
		var host_box: PacketMailbox = room.packet_boxes.get(room.host_peer_id, null)
		if host_box == null:
			return false
		host_box.items.append(NetworkPacket.new(packet_type, _local_peer_id, room.host_peer_id, seq, payload))
		return true

	if target_peer_id > 0:
		if not room.active_peers.get(target_peer_id, false):
			return false
		var target_box: PacketMailbox = room.packet_boxes.get(target_peer_id, null)
		if target_box == null:
			return false
		target_box.items.append(NetworkPacket.new(packet_type, _local_peer_id, target_peer_id, seq, payload))
		return true

	# Broadcast to all active non-server peers deterministically
	var pids: Array[int] = []
	for pid: int in room.active_peers:
		if pid != _local_peer_id and room.active_peers[pid]:
			pids.append(pid)
	pids.sort()
	for dst_pid: int in pids:
		var box: PacketMailbox = room.packet_boxes.get(dst_pid, null)
		if box != null:
			box.items.append(NetworkPacket.new(packet_type, _local_peer_id, dst_pid, seq, payload))
	return true


func poll_packets() -> Array[NetworkPacket]:
	var out: Array[NetworkPacket] = []
	if not _rooms.has(_room_id):
		return out
	var room: LoopbackRoom = _rooms[_room_id]
	var box: PacketMailbox = room.packet_boxes.get(_local_peer_id, null)
	if box == null or box.items.is_empty():
		return out
	for pkt: NetworkPacket in box.items:
		out.append(pkt)
	box.items.clear()
	return out


func poll_events() -> Array[TransportLifecycleEvent]:
	var out: Array[TransportLifecycleEvent] = []
	if not _rooms.has(_room_id):
		return out
	var room: LoopbackRoom = _rooms[_room_id]
	var box: EventMailbox = room.event_boxes.get(_local_peer_id, null)
	if box == null or box.items.is_empty():
		return out
	for ev: TransportLifecycleEvent in box.items:
		out.append(ev)
	box.items.clear()
	return out
