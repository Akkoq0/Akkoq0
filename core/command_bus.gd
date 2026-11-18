extends Node
## Autoload `CommandBus` (rank 2). Routes typed `GameCommand` objects to
## exactly one registered handler `Callable(command: GameCommand) -> bool`.
##
## Decouples senders (input, AI, UI, other managers) from the system that owns
## the behaviour: senders only know the command class, never the handler node.

signal command_dispatched(command: GameCommand)
signal command_rejected(command: GameCommand, reason: String)

var _handlers: Dictionary[StringName, Callable] = {}


## Registers `handler` as the single owner of `command_id`.
## Returns false (and logs) when the id is empty, taken, or the handler invalid.
func register_handler(command_id: StringName, handler: Callable) -> bool:
	if command_id == &"":
		push_error("CommandBus: cannot register an empty command id.")
		return false
	if not handler.is_valid():
		push_error("CommandBus: invalid handler for '%s'." % command_id)
		return false
	if _handlers.has(command_id) and _handlers[command_id].is_valid():
		push_error("CommandBus: '%s' already has a handler." % command_id)
		return false
	_handlers[command_id] = handler
	return true


## Removes the handler for `command_id` if it is `handler`.
func unregister_handler(command_id: StringName, handler: Callable) -> void:
	if _handlers.has(command_id) and _handlers[command_id] == handler:
		_handlers.erase(command_id)


## True when a valid handler exists for `command_id`.
func has_handler(command_id: StringName) -> bool:
	return _handlers.has(command_id) and _handlers[command_id].is_valid()


## Executes `command` synchronously. Returns true on success.
func dispatch(command: GameCommand) -> bool:
	if command == null:
		push_error("CommandBus: dispatch called with null command.")
		return false
	var command_id: StringName = command.get_command_id()
	if not has_handler(command_id):
		_handlers.erase(command_id)
		return _fail(command, "No handler registered for '%s'." % command_id)
	var handler: Callable = _handlers[command_id]
	var outcome: Variant = handler.call(command)
	if typeof(outcome) != TYPE_BOOL:
		return _fail(command, "Handler for '%s' did not return bool." % command_id)
	var succeeded: bool = outcome
	if not succeeded:
		var reason: String = command.rejection_reason
		if reason.is_empty():
			reason = "Rejected by handler."
		return _fail(command, reason)
	command_dispatched.emit(command)
	return true


func _fail(command: GameCommand, reason: String) -> bool:
	if command.rejection_reason.is_empty():
		command.rejection_reason = reason
	command_rejected.emit(command, reason)
	return false
