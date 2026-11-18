class_name EspionageComponent
extends Node
## Units (rank 3). Per-army espionage & counter-intelligence component.
## Computes infiltration probabilities from commander leadership and `SIK_ORMAN`
## terrain stealth, dispatches scouts to uncover enemy `quiver_ammo` and Turan
## tactic intentions, and executes envoy assassinations via `CommandBus`.

@export var rules: DiplomacyRules
@export_range(0.0, 100.0, 0.5) var commander_leadership: float = 75.0
@export_range(0.0, 0.85, 0.01) var counter_espionage_rating: float = 0.10


## Pure calculation of spy infiltration success chance on `terrain`.
func calculate_stealth_success_chance(terrain: TerrainData, target_counter_espionage: float = 0.0) -> float:
	if rules == null:
		return 0.0
	return rules.calculate_espionage_success_chance(
		commander_leadership, terrain, target_counter_espionage)


## Dispatches a spy network mission to uncover an enemy army's quiver reserve
## (`quiver_ammo`) and active Turan tactic intention.
func infiltrate_target_army(spy_owner_id: int, target_faction_id: int, target_army_id: int, terrain: TerrainData, target_quiver_ammo: float, target_tactic_intent: GameEnums.TuranTacticPhase, target_doctrine: GameEnums.TacticalDoctrineType = GameEnums.TacticalDoctrineType.FEIGNED_RETREAT, target_counter_espionage: float = 0.0, rng_seed: int = 42) -> EspionageReport:
	var cmd: DispatchSpyCommand = DispatchSpyCommand.new(
		spy_owner_id,
		target_faction_id,
		target_army_id,
		commander_leadership,
		terrain,
		target_quiver_ammo,
		target_tactic_intent,
		target_doctrine,
		target_counter_espionage,
		rng_seed)
	CommandBus.dispatch(cmd)
	return cmd.report


## Executes an enemy dynasty's envoy, boosting the Khagan's Kut score while
## provoking an immediate Total War (`TOTAL_WAR_GREAT_RAID`).
func assassinate_enemy_envoy(instigator_faction_id: int, target_faction_id: int, envoy_id: StringName) -> bool:
	var cmd: AssassinateEnvoyCommand = AssassinateEnvoyCommand.new(
		instigator_faction_id, target_faction_id, envoy_id)
	return CommandBus.dispatch(cmd)
