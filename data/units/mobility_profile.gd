class_name MobilityProfile
extends Resource
## Data layer (rank 1). Parameters of the weight-based speed formula.
##
## load_ratio = total_weight / carry_capacity
##   load_ratio <= 1 : factor = 1 - (1 - min_speed_factor) * load_ratio ^ load_exponent
##   load_ratio  > 1 : factor = min_speed_factor * overload_penalty / load_ratio
## speed = slowest_unit_speed * factor * terrain_multiplier * season_multiplier

## Speed fraction retained at exactly full capacity.
@export_range(0.0, 1.0, 0.01) var min_speed_factor: float = 1.0
## Curve shape: >1 penalises heavy loads late, <1 penalises early.
@export_range(0.1, 8.0, 0.01) var load_exponent: float = 1.0
## Extra multiplier applied when overloaded (load_ratio > 1).
@export_range(0.0, 1.0, 0.01) var overload_penalty: float = 1.0
## Distance (m) at which a destination counts as reached.
@export_range(0.01, 100.0, 0.01) var arrival_tolerance_m: float = 1.0
## Acceleration toward the target speed (m/s^2).
@export_range(0.01, 1000.0, 0.01) var acceleration: float = 1.0
## Yaw turn rate (rad/s) when facing the travel direction.
@export_range(0.01, 100.0, 0.01) var turn_rate_rad: float = 1.0
