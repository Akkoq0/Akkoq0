class_name SupplyProfile
extends Resource
## Data layer (rank 1). Supply-line parameters for an army.

## Maximum distance (m) beyond a depot's own radius that still counts as connected.
@export_range(0.0, 100000.0, 0.1) var max_supply_range_m: float = 0.0
## Supply units an army can carry.
@export_range(1.0, 1000000.0, 0.1) var supply_capacity: float = 1.0
## Supply units regained per second while connected.
@export_range(0.0, 10000.0, 0.01) var resupply_rate_per_sec: float = 0.0
## Supply ratio (0..1) under which the army is considered starving.
@export_range(0.0, 1.0, 0.01) var low_supply_threshold: float = 0.0
## Minimum change in supply ratio before a change event is broadcast.
@export_range(0.001, 1.0, 0.001) var report_step_ratio: float = 0.05
