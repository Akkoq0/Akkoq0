class_name ModularForceComponent
extends Node
## Units (rank 3). Phase 8 **Modular Force Splitting, Detachment & Merging**
## component (`res://units/modular_force_component.gd`).
##
## Allows an army to detach fast cavalry recon/raider columns, supply escorts,
## or outpost garrisons via `SplitDetachForceCommand` and re-merge them on the
## open steppe via `MergeForcesCommand`.

var _army_id: int = 1
var _initial_riders: int = 1000
var _active_detachment_ids: Array[int] = []


func configure(p_army_id: int, p_initial_riders: int = 1000) -> void:
	_army_id = p_army_id
	_initial_riders = maxi(p_initial_riders, 1)
	_active_detachment_ids.clear()


func split_detachment(detachment_id: int, riders: int, role: GameEnums.DetachmentRole) -> SplitDetachForceCommand:
	var cmd: SplitDetachForceCommand = SplitDetachForceCommand.new(_army_id, detachment_id, riders, role, _initial_riders)
	if CommandBus.dispatch(cmd):
		if not _active_detachment_ids.has(detachment_id):
			_active_detachment_ids.append(detachment_id)
	return cmd


func merge_detachment(detachment_id: int) -> MergeForcesCommand:
	var cmd: MergeForcesCommand = MergeForcesCommand.new(_army_id, detachment_id)
	if CommandBus.dispatch(cmd):
		_active_detachment_ids.erase(detachment_id)
	return cmd


func get_active_detachment_count() -> int:
	return _active_detachment_ids.size()
