class_name BallisticVolleyResult
extends RefCounted
## Core model (rank 2). Immutable ballistic computation output for a `Whistling
## Arrow` or Turan harassment volley under dynamic steppe wind and storm conditions.

var shooter_id: int = 1
var shot_direction: Vector3 = Vector3.FORWARD
var wind_vector: Vector3 = Vector3.ZERO
var wind_alignment_dot: float = 0.0
var temperature_celsius: float = 15.0
var weather_state: GameEnums.WindWeatherState = GameEnums.WindWeatherState.CALM
var base_range_m: float = 120.0
var effective_range_m: float = 120.0
var range_multiplier: float = 1.0
var accuracy_multiplier: float = 1.0
var whistling_morale_multiplier: float = 1.0
var ammo_consumption_multiplier: float = 1.0
