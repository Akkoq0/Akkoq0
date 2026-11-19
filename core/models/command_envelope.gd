class_name CommandEnvelope
extends RefCounted
## Core model (rank 2). Authoritative sequenced command envelope for
## deterministic dual-mode execution in `CommandBus`.

var sequence_id: int = 0
var sender_player_id: String = ""
var target_tick: int = 0
var command_type: String = ""
var payload: Dictionary = {}

# Execution & validation telemetry
var status: GameEnums.CommandEnvelopeStatus = GameEnums.CommandEnvelopeStatus.ACCEPTED
var rejection_reason: String = ""
var executed_command: GameCommand = null


func _init(
		p_sequence_id: int = 0,
		p_sender_player_id: String = "",
		p_target_tick: int = 0,
		p_command_type: String = "",
		p_payload: Dictionary = {}) -> void:
	sequence_id = p_sequence_id
	sender_player_id = p_sender_player_id
	target_tick = p_target_tick
	command_type = p_command_type
	payload = p_payload.duplicate(true)


func parse_player_id() -> int:
	var trimmed: String = sender_player_id.strip_edges()
	if trimmed.is_empty():
		return -1
	if trimmed.is_valid_int():
		return int(trimmed)
	if trimmed.begins_with("player_"):
		var suffix: String = trimmed.substr(7)
		if suffix.is_valid_int():
			return int(suffix)
	return -1


func duplicate_envelope() -> CommandEnvelope:
	var copy: CommandEnvelope = CommandEnvelope.new(
		sequence_id,
		sender_player_id,
		target_tick,
		command_type,
		payload)
	copy.status = status
	copy.rejection_reason = rejection_reason
	return copy


func export_dict() -> Dictionary:
	return {
		"command_type": command_type,
		"payload": payload.duplicate(true),
		"sender_player_id": sender_player_id,
		"sequence_id": sequence_id,
		"target_tick": target_tick,
	}
