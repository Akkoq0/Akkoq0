class_name ArmyController
extends Node3D
## Units (rank 3). Thin orchestrator: wires its components (`mobility`,
## `supply`, `terrain_sensor`, and optional `turan_tactics`) together and
## bridges their local signals to the EventBus. Contains no formulas.

@export var army_id: int = 0
@export var owner_id: int = 0
@export var template: ArmyTemplate
@export var mobility: ArmyMobilityComponent
@export var supply: SupplyLineComponent
@export var terrain_sensor: TerrainSensorComponent
@export var turan_tactics: TuranTacticsComponent
@export var morale_component: MoraleComponent
@export var espionage_component: EspionageComponent

var _is_operational: bool = false


func _ready() -> void:
	if not _validate():
		return
	if not mobility.configure(template) or not supply.configure(template, owner_id, army_id):
		return
	mobility.set_remount_horse_ratio(supply.get_remount_horse_ratio())
	if turan_tactics != null and turan_tactics.doctrine != null:
		turan_tactics.configure(army_id, turan_tactics.doctrine, supply.get_quiver_ammo_reserve())
	if morale_component != null:
		morale_component.configure(army_id)
	mobility.passability_check = terrain_sensor.is_position_passable
	terrain_sensor.terrain_changed.connect(_on_terrain_changed)
	mobility.destination_reached.connect(_on_destination_reached)
	mobility.movement_blocked.connect(_on_movement_blocked)
	supply.supply_changed.connect(_on_supply_changed)
	supply.remount_horse_ratio_changed.connect(_on_remount_horse_ratio_changed)
	_is_operational = true
	EventBus.army_spawned.emit(army_id, owner_id, global_position)


func _exit_tree() -> void:
	if _is_operational:
		EventBus.army_despawned.emit(army_id)


## True when every component is wired and configured.
func is_operational() -> bool:
	return _is_operational


## Orders a march. Returns false when the army is not operational.
func move_to(destination: Vector3) -> bool:
	if not _is_operational:
		return false
	mobility.set_destination(destination)
	EventBus.army_move_ordered.emit(army_id, destination)
	return true


## Adds carried ore; its weight slows the army through the mobility formula.
func load_cargo(ore: OreData, amount: int) -> void:
	if not _is_operational or ore == null:
		return
	mobility.add_cargo_weight(ore.weight_per_unit * float(amount))


## Snapshot for combat resolution, including morale, battle fatigue, and active Turan tactic phase.
func get_combatant_stats() -> CombatantStats:
	if not _is_operational:
		return null
	var stats: CombatantStats = CombatantStats.new(
		army_id,
		template.get_total_attack(),
		template.get_total_defense(),
		template.get_total_health(),
		supply.get_supply_ratio())
	stats.morale = supply.get_battle_morale()
	if morale_component != null:
		stats.fatigue = morale_component.get_battle_fatigue()
		stats.morale = minf(stats.morale, morale_component.get_current_morale())
		stats.elite_vanguard_destroyed = not morale_component.is_elite_vanguard_alive()
		stats.is_fleeing_rout = morale_component.is_cascade_routing()
	if turan_tactics != null:
		stats.active_tactic_phase = turan_tactics.get_current_phase()
	return stats


func _validate() -> bool:
	var missing: PackedStringArray = PackedStringArray()
	if template == null:
		missing.append("template")
	if mobility == null:
		missing.append("mobility")
	if supply == null:
		missing.append("supply")
	if terrain_sensor == null:
		missing.append("terrain_sensor")
	if not missing.is_empty():
		push_error("ArmyController '%s' missing: %s." % [get_path(), ", ".join(missing)])
		return false
	var errors: PackedStringArray = template.get_validation_errors()
	for error: String in errors:
		push_error("ArmyController '%s': %s" % [get_path(), error])
	return errors.is_empty()


func _on_terrain_changed(terrain: TerrainData) -> void:
	mobility.set_terrain(terrain)
	supply.set_terrain(terrain)


func _on_destination_reached(position_reached: Vector3) -> void:
	EventBus.army_destination_reached.emit(army_id, position_reached)


func _on_movement_blocked(position_blocked: Vector3) -> void:
	EventBus.army_destination_reached.emit(army_id, position_blocked)


func _on_supply_changed(supply_ratio: float, is_connected: bool) -> void:
	EventBus.army_supply_changed.emit(army_id, supply_ratio, is_connected)


func _on_remount_horse_ratio_changed(new_ratio: float) -> void:
	mobility.set_remount_horse_ratio(new_ratio)
