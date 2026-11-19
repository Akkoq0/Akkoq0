class_name WorldSnapshotSerializer
extends RefCounted
## Core serializer (rank 2). Exports and restores a canonical, key-sorted world
## state dictionary across all simulation managers without mutating live state on
## invalid schema or malformed payloads.

const SCHEMA_VERSION: int = 1
const REQUIRED_SECTIONS: Array[String] = [
	"collapse_recovery_fsm",
	"combat_calculator",
	"command_bus",
	"diplomacy_manager",
	"game_manager",
	"governance_manager",
	"grace_period_manager",
	"intelligence_manager",
	"regional_market_engine",
	"reputation_system",
	"resource_manager",
	"season_manager",
	"session",
	"succession_manager",
	"territory_manager",
	"water_route_manager",
]


static func export_state_dict() -> Dictionary:
	var syn_snap: SynergyEvaluationSnapshot = SystemicSynergyMatrix.evaluate_player(1, 1)
	var syn_dict: Dictionary = {}
	if syn_snap != null:
		syn_dict = {
			"active_resonances": syn_snap.active_resonances,
			"black_market_scarcity_mult": syn_snap.black_market_scarcity_mult,
			"courier_tempo_mult": syn_snap.courier_tempo_mult,
			"doctrine_exposed": syn_snap.doctrine_exposed,
			"effective_combat_power_mult": syn_snap.effective_combat_power_mult,
			"kut_entropy_net_drift": syn_snap.kut_entropy_net_drift,
		}
	var raw: Dictionary = {
		"collapse_recovery_fsm": CollapseRecoveryFSM.export_state_dict(),
		"combat_calculator": CombatCalculator.export_state_dict(),
		"command_bus": CommandBus.export_envelope_state_dict(),
		"diplomacy_manager": DiplomacyManager.export_state_dict(),
		"game_manager": GameManager.export_state_dict(),
		"governance_manager": GovernanceManager.export_state_dict(),
		"grace_period_manager": GracePeriodManager.export_state_dict(),
		"intelligence_manager": IntelligenceManager.export_state_dict(),
		"regional_market_engine": RegionalMarketEngine.export_state_dict(),
		"reputation_system": ReputationAndPactSystem.export_state_dict(),
		"resource_manager": ResourceManager.export_state_dict(),
		"schema_version": SCHEMA_VERSION,
		"season_manager": SeasonManager.export_state_dict(),
		"session": SessionClockAuthority.export_state_dict(),
		"succession_manager": SuccessionManager.export_state_dict(),
		"synergy_summary": syn_dict,
		"territory_manager": TerritoryManager.export_state_dict(),
		"water_route_manager": WaterRouteManager.export_state_dict(),
	}
	return raw


static func validate_state_dict(data: Dictionary) -> bool:
	if data.is_empty():
		return false
	var sv_int: int = DeterministicStateHasher.v_int(data.get("schema_version", -1), -1)
	var sv_str: String = DeterministicStateHasher.v_str(data.get("schema_version", ""))
	if sv_int != SCHEMA_VERSION and sv_str != str(SCHEMA_VERSION):
		return false
	for sec: String in REQUIRED_SECTIONS:
		if not data.has(sec) or not (data[sec] is Dictionary):
			return false
	return true


static func import_state_dict(data: Dictionary) -> bool:
	if not validate_state_dict(data):
		return false
	if not SessionClockAuthority.import_state_dict(DeterministicStateHasher.v_dict(data.get("session"))):
		return false
	if not CommandBus.import_envelope_state_dict(DeterministicStateHasher.v_dict(data.get("command_bus"))):
		return false
	if not GameManager.import_state_dict(DeterministicStateHasher.v_dict(data.get("game_manager"))):
		return false
	if not SeasonManager.import_state_dict(DeterministicStateHasher.v_dict(data.get("season_manager"))):
		return false
	if not ResourceManager.import_state_dict(DeterministicStateHasher.v_dict(data.get("resource_manager"))):
		return false
	if not TerritoryManager.import_state_dict(DeterministicStateHasher.v_dict(data.get("territory_manager"))):
		return false
	if not WaterRouteManager.import_state_dict(DeterministicStateHasher.v_dict(data.get("water_route_manager"))):
		return false
	if not RegionalMarketEngine.import_state_dict(DeterministicStateHasher.v_dict(data.get("regional_market_engine"))):
		return false
	if not CombatCalculator.import_state_dict(DeterministicStateHasher.v_dict(data.get("combat_calculator"))):
		return false
	if not GracePeriodManager.import_state_dict(DeterministicStateHasher.v_dict(data.get("grace_period_manager"))):
		return false
	if not GovernanceManager.import_state_dict(DeterministicStateHasher.v_dict(data.get("governance_manager"))):
		return false
	if not DiplomacyManager.import_state_dict(DeterministicStateHasher.v_dict(data.get("diplomacy_manager"))):
		return false
	if not ReputationAndPactSystem.import_state_dict(DeterministicStateHasher.v_dict(data.get("reputation_system"))):
		return false
	if not SuccessionManager.import_state_dict(DeterministicStateHasher.v_dict(data.get("succession_manager"))):
		return false
	if not IntelligenceManager.import_state_dict(DeterministicStateHasher.v_dict(data.get("intelligence_manager"))):
		return false
	if not CollapseRecoveryFSM.import_state_dict(DeterministicStateHasher.v_dict(data.get("collapse_recovery_fsm"))):
		return false
	return true
