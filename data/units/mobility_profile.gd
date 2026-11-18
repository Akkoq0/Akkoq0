class_name MobilityProfile
extends Resource
## Data layer (rank 1). Parameters of the weight-based speed formula and
## Phase 3 Yılkı spare-horse (`remount_horse_ratio`) mobility dynamics.
##
## load_ratio = total_weight / carry_capacity
##   load_ratio <= 1 : factor = 1 - (1 - min_speed_factor) * load_ratio ^ load_exponent
##   load_ratio  > 1 : factor = min_speed_factor * overload_penalty / load_ratio
## remount_mult:
##   remount_ratio <= 0 : dismounted_penalty
##   remount_ratio  > 0 : lerp(dismounted_penalty, full_remount_speed_bonus, clamp(remount_ratio / optimal_remount_horse_ratio, 0, 1))
## speed = slowest_unit_speed * factor * remount_mult * terrain_multiplier * season_multiplier

## Speed fraction retained at exactly full capacity.
@export_range(0.0, 1.0, 0.01) var min_speed_factor: float = 0.55
## Curve shape: >1 penalises heavy loads late, <1 penalises early.
@export_range(0.1, 8.0, 0.01) var load_exponent: float = 1.4
## Extra multiplier applied when overloaded (load_ratio > 1).
@export_range(0.0, 1.0, 0.01) var overload_penalty: float = 0.65
## Distance (m) at which a destination counts as reached.
@export_range(0.01, 100.0, 0.01) var arrival_tolerance_m: float = 0.4
## Acceleration toward the target speed (m/s^2).
@export_range(0.01, 1000.0, 0.01) var acceleration: float = 24.0
## Yaw turn rate (rad/s) when facing the travel direction.
@export_range(0.01, 100.0, 0.01) var turn_rate_rad: float = 8.0

@export_group("Yılkı Spare Horse (Remount) Dynamics")
## Optimal spare horse ratio per warrior for tireless steppe marches.
@export_range(0.1, 5.0, 0.05) var optimal_remount_horse_ratio: float = 1.0
## Speed multiplier when Yılkı remount ratio is at optimal capacity.
@export_range(1.0, 2.5, 0.01) var full_remount_speed_bonus: float = 1.20
## Permanent dismounted infantry speed multiplier when Yılkı horses are lost or slaughtered (`remount_horse_ratio <= 0`).
@export_range(0.1, 1.0, 0.01) var dismounted_penalty: float = 0.42
