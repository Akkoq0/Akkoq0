class_name NetworkTransportAdapter
extends RefCounted
## Core Network Transport Interface (rank 2). Abstract base contract implemented
## cleanly by both `ENetTransportAdapter` (real UDP/ENet sockets) and
## `LoopbackNetworkTransport` (deterministic in-memory virtual bus for tests).


class NetworkPacket:
	extends RefCounted
	var packet_type: StringName = &""
	var sender_peer_id: int = 0
	var target_peer_id: int = 0
	var sequence_id: int = 0
	var payload: Dictionary = {}

	func _init(
			p_type: StringName = &"",
			p_sender: int = 0,
			p_target: int = 0,
			p_seq: int = 0,
			p_payload: Dictionary = {}) -> void:
		packet_type = p_type
		sender_peer_id = p_sender
		target_peer_id = p_target
		sequence_id = p_seq
		payload = p_payload.duplicate(true)


class TransportLifecycleEvent:
	extends RefCounted
	var event_type: StringName = &""
	var peer_id: int = 0
	var is_reconnect: bool = false
	var reason: String = ""

	func _init(
			p_type: StringName = &"",
			p_peer_id: int = 0,
			p_reconnect: bool = false,
			p_reason: String = "") -> void:
		event_type = p_type
		peer_id = p_peer_id
		is_reconnect = p_reconnect
		reason = p_reason


func host_room(_room_id: StringName, _port: int = 7777, _max_players: int = 8) -> bool:
	return false


func join_room(
		_room_id: StringName,
		_host_addr: String = "127.0.0.1",
		_port: int = 7777,
		_peer_id: int = 2) -> bool:
	return false


func close_transport() -> void:
	pass


func simulate_disconnect() -> void:
	close_transport()


func is_transport_active() -> bool:
	return false


func is_server_transport() -> bool:
	return false


func get_local_peer_id() -> int:
	return 0


func get_room_id() -> StringName:
	return &""


func get_connected_peer_ids() -> PackedInt32Array:
	return PackedInt32Array()


func send_packet(
		_packet_type: StringName,
		_payload: Dictionary,
		_target_peer_id: int = 0) -> bool:
	return false


func poll_packets() -> Array[NetworkPacket]:
	var empty: Array[NetworkPacket] = []
	return empty


func poll_events() -> Array[TransportLifecycleEvent]:
	var empty: Array[TransportLifecycleEvent] = []
	return empty
