class_name ArmyRegistry
extends Node3D
## Units (rank 3). Owns the `MoveArmyCommand` handler and routes orders to
## the `ArmyController` children it tracks. Senders never see army nodes.

var _armies: Dictionary[int, ArmyController] = {}


func _ready() -> void:
	for child: Node in get_children():
		_track(child)
	child_entered_tree.connect(_track)
	child_exiting_tree.connect(_untrack)
	CommandBus.register_handler(MoveArmyCommand.ID, _handle_move)


func _exit_tree() -> void:
	CommandBus.unregister_handler(MoveArmyCommand.ID, _handle_move)


## Number of tracked armies.
func get_army_count() -> int:
	return _armies.size()


func get_army(army_id: int) -> ArmyController:
	if _armies.has(army_id):
		var a: ArmyController = _armies[army_id]
		if a != null and is_instance_valid(a):
			return a
	return null


func get_all_armies() -> Array[ArmyController]:
	var out: Array[ArmyController] = []
	for aid: int in _armies:
		var a: ArmyController = _armies[aid]
		if a != null and is_instance_valid(a):
			out.append(a)
	return out


func _handle_move(command: GameCommand) -> bool:
	var move: MoveArmyCommand = command as MoveArmyCommand
	if move == null:
		return command.reject("Expected MoveArmyCommand.")
	if not _armies.has(move.army_id):
		return command.reject("Unknown army %d." % move.army_id)
	var army: ArmyController = _armies[move.army_id]
	if not army.move_to(move.destination):
		return command.reject("Army %d is not operational." % move.army_id)
	return true


func _track(node: Node) -> void:
	var army: ArmyController = node as ArmyController
	if army == null:
		return
	if _armies.has(army.army_id) and _armies[army.army_id] != army:
		push_error("ArmyRegistry: duplicate army_id %d ('%s')." % [army.army_id, army.name])
		return
	_armies[army.army_id] = army


func _untrack(node: Node) -> void:
	var army: ArmyController = node as ArmyController
	if army != null and _armies.get(army.army_id) == army:
		_armies.erase(army.army_id)
