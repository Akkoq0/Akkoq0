class_name SupplyProfile
extends Resource
## Data layer (rank 1). Supply-line, Yılkı spare horse (`remount_horse_ratio`),
## quiver ammo (`quiver_ammo_reserve`), and Zud horse-sacrifice parameters.

## Maximum distance (m) beyond a depot's own radius that still counts as connected.
@export_range(0.0, 100000.0, 0.1) var max_supply_range_m: float = 15.0
## Supply units an army can carry.
@export_range(1.0, 1000000.0, 0.1) var supply_capacity: float = 120.0
## Supply units regained per second while connected.
@export_range(0.0, 10000.0, 0.01) var resupply_rate_per_sec: float = 8.0
## Supply ratio (0..1) under which the army is considered starving.
@export_range(0.0, 1.0, 0.01) var low_supply_threshold: float = 0.25
## Minimum change in supply ratio before a change event is broadcast.
@export_range(0.001, 1.0, 0.001) var report_step_ratio: float = 0.05

@export_group("Yılkı Remounts & Quiver Ammo")
@export_range(0.0, 5.0, 0.05) var initial_remount_horse_ratio: float = 1.0
@export_range(1.0, 1000.0, 1.0) var initial_quiver_ammo_reserve: float = 100.0
@export_range(1.0, 1000.0, 1.0) var max_quiver_ammo_reserve: float = 100.0
@export_range(0.0, 500.0, 0.5) var quiver_resupply_rate_per_sec: float = 10.0

@export_group("Winter/Zud Yılkı Sacrifice")
## Spare horse ratio permanently slaughtered per Zud starvation emergency.
@export_range(0.05, 1.0, 0.01) var yilki_sacrifice_ratio_per_starvation: float = 0.50
## Emergency supply ration restored when Yılkı horses are slaughtered.
@export_range(1.0, 1000.0, 1.0) var yilki_sacrifice_supply_restored: float = 45.0
## Battle morale collapse caused by slaughtering the clan's own mounts.
@export_range(0.0, 100.0, 0.5) var yilki_sacrifice_morale_drop: float = 24.0
## Severe Kut (Divine Mandate) penalty inflicted on the Khagan when an isolated army eats its horses.
@export_range(0.0, 100.0, 0.5) var yilki_sacrifice_kut_penalty: float = 14.0
