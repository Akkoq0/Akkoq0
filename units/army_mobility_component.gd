class_name ArmyMobilityComponent
extends Node
## Units (rank 3). Movement physics, the weight-based speed formula, and
## Phase 3 **Yılkı spare-horse (`remount_horse_ratio`)** speed scaling ONLY.
## Knows nothing about combat, supply, UI or how terrain is looked up.
##
## Speed formula (coefficients from `MobilityProfile`):
##   load_ratio = total_weight / carry_capacity
##   factor     = 1 - (1 - min_speed_factor) * load_ratio ^ load_exponent      (load_ratio <= 1)
##   factor     = min_speed_factor * overload_penalty / load_ratio            (load_ratio  > 1)
##   remount    = dismounted_penalty                                          (remount_ratio <= 0)
##   remount    = lerp(dismounted_penalty, full_remount_speed_bonus, ratio)   (remount_ratio  > 0)
##   speed      = slowest_unit_speed * factor * remount * terrain_mult * season_mult

signal destination_reached(position: Vector3)
## Emitted when the next step would enter an impassable / off-map position.
signal movement_blocked(position: Vector3)

## Node whose transform is driven by this component.
@export var body: Node3D

## Injected predicate `func(world_position: Vector3) -> bool`. Defaults to "always passable".
var passability_check: Callable = Callable()

var _profile: MobilityProfile = null
var _base_speed: float = 0.0
var _unit_weight: float = 0.0
var _carry_capacity: float = 0.0
var _cargo_weight: float = 0.0
var _remount_horse_ratio: float = 1.0
var _terrain_multiplier: float = 1.0
var _season_multiplier: float = 1.0
var _epidemic_multiplier: float = 1.0
var _council_speed_multiplier: float = 1.0
var _destination: Vector3 = Vector3.ZERO
var _has_destination: bool = false
var _current_speed: float = 0.0


func _ready() -> void:
	set_physics_process(false)
	EventBus.season_changed.connect(_on_season_changed)
	EventBus.council_decree_enacted.connect(_on_council_decree_enacted)


## Pure weight-based speed formula, exposed for tests, AI estimates and UI previews.
static func calculate_weighted_speed(base_speed: float, total_weight: float, carry_capacity: float, profile: MobilityProfile) -> float:
	if profile == null or base_speed <= 0.0:
		return 0.0
	var load_ratio: float = 0.0
	if carry_capacity > 0.0:
		load_ratio = maxf(total_weight, 0.0) / carry_capacity
	elif total_weight > 0.0:
		return 0.0
	var factor: float = 0.0
	if load_ratio <= 1.0:
		factor = 1.0 - (1.0 - profile.min_speed_factor) * pow(load_ratio, profile.load_exponent)
	else:
		factor = profile.min_speed_factor * profile.overload_penalty / load_ratio
	return base_speed * factor


## Pure Yılkı spare-horse (`remount_horse_ratio`) speed multiplier.
## Returns `dismounted_penalty` when spare horses are lost or slaughtered (`<= 0`).
static func calculate_remount_speed_multiplier(remount_horse_ratio: float, profile: MobilityProfile) -> float:
	if profile == null:
		return 1.0
	if remount_horse_ratio <= 0.0:
		return profile.dismounted_penalty
	var normalised: float = clampf(remount_horse_ratio / maxf(profile.optimal_remount_horse_ratio, 0.1), 0.0, 1.0)
	return lerpf(profile.dismounted_penalty, profile.full_remount_speed_bonus, normalised)


## Reads the army composition. Returns false when required data is missing.
func configure(template: ArmyTemplate) -> bool:
	if body == null:
		push_error("ArmyMobilityComponent '%s': body is not assigned." % get_path())
		return false
	if template == null or template.mobility_profile == null:
		push_error("ArmyMobilityComponent '%s': template or mobility_profile missing." % get_path())
		return false
	_profile = template.mobility_profile
	_base_speed = template.get_slowest_base_speed()
	_unit_weight = template.get_total_unit_weight()
	_carry_capacity = template.get_total_carry_capacity()
	_remount_horse_ratio = _profile.optimal_remount_horse_ratio
	_epidemic_multiplier = 1.0
	_council_speed_multiplier = 1.0
	return true


## Starts marching toward `destination` (XZ plane; height is preserved).
func set_destination(destination: Vector3) -> void:
	if _profile == null:
		return
	_destination = Vector3(destination.x, body.global_position.y, destination.z)
	_has_destination = true
	set_physics_process(true)


## Halts immediately.
func stop() -> void:
	_has_destination = false
	_current_speed = 0.0
	set_physics_process(false)


## Adds (or removes, if negative) carried cargo weight.
func add_cargo_weight(delta_weight: float) -> void:
	_cargo_weight = maxf(_cargo_weight + delta_weight, 0.0)


## Sets the army's Yılkı spare-horse ratio (`remount_horse_ratio`).
func set_remount_horse_ratio(ratio: float) -> void:
	_remount_horse_ratio = maxf(ratio, 0.0)


func get_remount_horse_ratio() -> float:
	return _remount_horse_ratio


## Sets the Zud epidemic speed multiplier (`0.50` when plague-stricken, `1.0` when healthy).
func set_epidemic_speed_multiplier(mult: float) -> void:
	_epidemic_multiplier = clampf(mult, 0.1, 1.0)


func get_epidemic_speed_multiplier() -> float:
	return _epidemic_multiplier


## Applies the movement multiplier of the terrain currently under the army.
func set_terrain(terrain: TerrainData) -> void:
	_terrain_multiplier = terrain.get_effective_movement_multiplier() if terrain != null else 1.0


## Applies the movement multiplier of the active season.
func set_season(season: SeasonData) -> void:
	_season_multiplier = season.movement_multiplier if season != null else 1.0


func get_total_weight() -> float:
	return _unit_weight + _cargo_weight


func get_carry_capacity() -> float:
	return _carry_capacity


func get_current_speed() -> float:
	return _current_speed


func is_moving() -> bool:
	return _has_destination


## Desired cruising speed with weight, Yılkı remount, terrain, season, epidemic, and council multipliers applied.
func get_target_speed() -> float:
	if _base_speed <= 0.0 or _terrain_multiplier <= 0.0 or _season_multiplier <= 0.0:
		return 0.0
	var weighted: float = calculate_weighted_speed(_base_speed, get_total_weight(), _carry_capacity, _profile)
	var remount_mult: float = calculate_remount_speed_multiplier(_remount_horse_ratio, _profile)
	var raw_speed: float = weighted * remount_mult * _terrain_multiplier * _season_multiplier * _epidemic_multiplier * _council_speed_multiplier
	return maxf(raw_speed, _base_speed * 0.12)


func _physics_process(delta: float) -> void:
	if not _has_destination or _profile == null:
		return
	var to_target: Vector3 = _destination - body.global_position
	to_target.y = 0.0
	var distance: float = to_target.length()
	if distance <= _profile.arrival_tolerance_m:
		stop()
		destination_reached.emit(body.global_position)
		return
	_current_speed = move_toward(_current_speed, get_target_speed(), _profile.acceleration * delta)
	var direction: Vector3 = to_target / distance
	var next_position: Vector3 = body.global_position + direction * minf(_current_speed * delta, distance)
	if not _is_passable(next_position):
		stop()
		movement_blocked.emit(body.global_position)
		return
	body.global_position = next_position
	_face(direction, delta)


func _is_passable(world_position: Vector3) -> bool:
	if not passability_check.is_valid():
		return true
	var outcome: Variant = passability_check.call(world_position)
	return typeof(outcome) == TYPE_BOOL and outcome == true


func _face(direction: Vector3, delta: float) -> void:
	var target_yaw: float = atan2(-direction.x, -direction.z)
	body.rotation.y = rotate_toward(body.rotation.y, target_yaw, _profile.turn_rate_rad * delta)


func _on_season_changed(season: SeasonData, _cycle_index: int) -> void:
	set_season(season)


func _on_council_decree_enacted(_player_id: int, _choice: GameEnums.CouncilDilemmaChoice, _kut: float, _income_mult: float, speed_mult: float, _loot_mult: float) -> void:
	_council_speed_multiplier = clampf(speed_mult, 0.1, 1.5)

