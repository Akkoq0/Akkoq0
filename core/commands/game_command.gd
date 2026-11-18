class_name GameCommand
extends RefCounted
## Core command (rank 2). Base class for every request routed via CommandBus.
##
## A command is a typed message object: senders fill in the request fields,
## exactly one registered handler executes it and may write result fields.
## Handlers return `true` on success or call `reject()` and return `false`.

var rejection_reason: String = ""


## Unique routing key. Every subclass MUST override this.
func get_command_id() -> StringName:
	return &""


## Marks the command as rejected. Returns false so handlers can `return reject(...)`.
func reject(reason: String) -> bool:
	rejection_reason = reason
	return false


## True when a handler rejected this command.
func is_rejected() -> bool:
	return not rejection_reason.is_empty()
