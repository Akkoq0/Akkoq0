class_name CameraProfile
extends Resource
## Data layer (rank 1). Framing + transition parameters for the dual-layer camera.

@export_group("Transition")
## Total duration of a macro <-> micro cloud transition.
@export_range(0.05, 10.0, 0.01) var transition_duration_sec: float = 1.0
@export var transition_type: Tween.TransitionType = Tween.TRANS_LINEAR
@export var transition_ease: Tween.EaseType = Tween.EASE_IN_OUT
## Normalised progress (0..1) at which the visible layer swaps.
@export_range(0.0, 1.0, 0.01) var swap_progress: float = 0.5
@export var cloud_color: Color = Color.WHITE
## Cloud overlay opacity at the swap point.
@export_range(0.0, 1.0, 0.01) var cloud_peak_alpha: float = 1.0

@export_group("Macro Framing")
@export_range(1.0, 10000.0, 0.1) var macro_height_m: float = 1.0
@export_range(5.0, 89.0, 0.1) var macro_pitch_deg: float = 45.0
@export_range(1.0, 179.0, 0.1) var macro_fov_deg: float = 60.0
@export_range(0.0, 10000.0, 0.1) var macro_pan_speed: float = 0.0

@export_group("Micro Framing")
@export_range(1.0, 10000.0, 0.1) var micro_height_m: float = 1.0
@export_range(5.0, 89.0, 0.1) var micro_pitch_deg: float = 45.0
@export_range(1.0, 179.0, 0.1) var micro_fov_deg: float = 60.0
@export_range(0.0, 10000.0, 0.1) var micro_pan_speed: float = 0.0


## Height for `layer`.
func get_height(layer: GameEnums.WorldLayer) -> float:
	return macro_height_m if layer == GameEnums.WorldLayer.MACRO else micro_height_m


## Pitch (degrees below horizon) for `layer`.
func get_pitch_deg(layer: GameEnums.WorldLayer) -> float:
	return macro_pitch_deg if layer == GameEnums.WorldLayer.MACRO else micro_pitch_deg


## Field of view for `layer`.
func get_fov_deg(layer: GameEnums.WorldLayer) -> float:
	return macro_fov_deg if layer == GameEnums.WorldLayer.MACRO else micro_fov_deg


## Pan speed for `layer`.
func get_pan_speed(layer: GameEnums.WorldLayer) -> float:
	return macro_pan_speed if layer == GameEnums.WorldLayer.MACRO else micro_pan_speed
