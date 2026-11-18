class_name TerrainSensorComponent
extends Node
## Units (rank 3). Reports the terrain under its body and answers
## passability queries, using the macro map received via the EventBus.

signal terrain_changed(terrain: TerrainData)

## Node whose position is sampled.
@export var body: Node3D

var _world_state: MacroWorldState = null
var _current_coord: Vector2i = Vector2i(-1, -1)
var _current_terrain: TerrainData = null


func _ready() -> void:
	EventBus.macro_world_generated.connect(_on_macro_world_generated)
	set_physics_process(body != null)
	if body == null:
		push_error("TerrainSensorComponent '%s': body is not assigned." % get_path())


## Terrain currently under the body (null before the map exists / off-map).
func get_current_terrain() -> TerrainData:
	return _current_terrain


## True when `world_position` is on the map and its terrain is passable.
## Before the macro map exists every position is considered passable.
func is_position_passable(world_position: Vector3) -> bool:
	if _world_state == null:
		return true
	var region: MacroRegion = _world_state.get_region_at(world_position)
	return region != null and region.terrain != null and region.terrain.is_passable


func _physics_process(_delta: float) -> void:
	if _world_state == null:
		return
	var coord: Vector2i = _world_state.world_to_coord(body.global_position)
	if coord == _current_coord:
		return
	_current_coord = coord
	var region: MacroRegion = _world_state.get_region(coord)
	var terrain: TerrainData = region.terrain if region != null else null
	if terrain != _current_terrain:
		_current_terrain = terrain
		terrain_changed.emit(terrain)


func _on_macro_world_generated(world_state: MacroWorldState) -> void:
	_world_state = world_state
	_current_coord = Vector2i(-1, -1)
	_current_terrain = null
