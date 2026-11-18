class_name LayerVisibilityComponent
extends Node
## Core component (rank 2). Shows its parent `Node3D` only on the configured
## world layers. Swaps exactly at the cloud-covered transition midpoint so the
## change is never visible to the player.

## Layers on which the parent is visible (bit 0 = Macro, bit 1 = Micro).
@export_flags("Macro", "Micro") var visible_layers: int = GameEnums.LAYER_FLAG_MACRO
## Layer assumed before the first transition.
@export var initial_layer: GameEnums.WorldLayer = GameEnums.WorldLayer.MACRO

var _target: Node3D = null


func _ready() -> void:
	_target = get_parent() as Node3D
	if _target == null:
		push_error("LayerVisibilityComponent '%s' must be a child of a Node3D." % get_path())
		return
	EventBus.layer_transition_midpoint.connect(_on_layer_transition_midpoint)
	_apply(initial_layer)


func _on_layer_transition_midpoint(target_layer: GameEnums.WorldLayer) -> void:
	_apply(target_layer)


func _apply(layer: GameEnums.WorldLayer) -> void:
	if _target != null:
		_target.visible = GameEnums.layer_mask_has(visible_layers, layer)
