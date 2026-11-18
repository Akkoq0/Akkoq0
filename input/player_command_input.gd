class_name PlayerCommandInput
extends Node
## Input (rank 3). Translates InputMap actions into `CommandBus` dispatches.
## Never touches game systems directly.

@export var controlled_army_id: int = 1


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"toggle_world_layer"):
		var current: GameEnums.WorldLayer = GameManager.get_world_layer()
		var target: GameEnums.WorldLayer = GameEnums.WorldLayer.MICRO \
			if current == GameEnums.WorldLayer.MACRO else GameEnums.WorldLayer.MACRO
		CommandBus.dispatch(SwitchLayerCommand.new(target))
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"issue_move_order"):
		var hit: Vector3 = _project_mouse_to_ground()
		if not is_inf(hit.x):
			CommandBus.dispatch(MoveArmyCommand.new(controlled_army_id, hit))
			get_viewport().set_input_as_handled()


func _project_mouse_to_ground() -> Vector3:
	var active_camera: Camera3D = get_viewport().get_camera_3d()
	if active_camera == null:
		return Vector3.INF
	var mouse: Vector2 = get_viewport().get_mouse_position()
	var origin: Vector3 = active_camera.project_ray_origin(mouse)
	var direction: Vector3 = active_camera.project_ray_normal(mouse)
	var hit: Variant = Plane.PLANE_XZ.intersects_ray(origin, direction)
	if hit == null:
		return Vector3.INF
	return hit as Vector3
