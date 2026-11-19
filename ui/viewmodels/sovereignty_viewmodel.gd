class_name SovereigntyViewModel
extends RefCounted
## UI ViewModel (rank 3). Strictly read-only projection for Phase 30 Kurultai
## Council Ring, Commander Scar Medallion, Dread vs Honor/Töre Balance Scale,
## Hybrid Conquest Aftermath, and 3-Way Collapse Recovery Flow.

var player_id: int = 1
var tracked_army_id: int = 1
var target_coord: Vector2i = Vector2i.ZERO


class VassalCouncilEntry:
	var bey_id: StringName = &""
	var loyalty: float = 75.0
	var silent_sabotage_active: bool = false
	var reinforcement_delay_hours: float = 0.0

	func _init(
			p_bey_id: StringName,
			p_loyalty: float,
			p_sabotage: bool,
			p_delay: float) -> void:
		bey_id = p_bey_id
		loyalty = p_loyalty
		silent_sabotage_active = p_sabotage
		reinforcement_delay_hours = p_delay


class SovereigntySnapshot:
	var player_id: int = 1
	var army_id: int = 1
	var target_coord: Vector2i = Vector2i.ZERO

	# Kurultai Council Ring
	var vassals: Array[VassalCouncilEntry] = []
	var direct_regions: int = 0
	var direct_cap: int = 4
	var silent_sabotage_count: int = 0
	var max_delay_hours: float = 0.0

	# Commander Scar Medallion & Heir Warning
	var commander_name: String = "Kül Tigin"
	var commander_age_years: int = 26
	var commander_scars: int = 0
	var commander_veteran_score: float = 0.0
	var commander_trait: GameEnums.CommanderTrait = GameEnums.CommanderTrait.NONE
	var commander_alive: bool = true
	var ruler_name: String = "Bilge Kağan"
	var generation: int = 1
	var heir_name: String = "Tigin"
	var heir_ready: bool = true
	var heir_amanat: bool = false
	var regency_status: GameEnums.RegencyStatus = GameEnums.RegencyStatus.STABLE_RULE

	# Dread vs Honor/Töre Sword Balance
	var dread_score: float = 0.0
	var honor_score: float = 50.0
	var word_reliability: float = 100.0

	# Collapse & Conquest Flow
	var collapse_state: GameEnums.CollapseState = GameEnums.CollapseState.SOVEREIGN
	var kut_ceiling: float = 100.0
	var can_select_collapse_path: bool = false


func _init(
		p_player_id: int = 1,
		p_army_id: int = 1,
		p_target_coord: Vector2i = Vector2i.ZERO) -> void:
	player_id = p_player_id
	tracked_army_id = p_army_id
	target_coord = p_target_coord


func set_context(p_player_id: int, p_army_id: int, p_coord: Vector2i) -> void:
	player_id = p_player_id
	tracked_army_id = p_army_id
	target_coord = p_coord


func capture_snapshot() -> SovereigntySnapshot:
	var snap: SovereigntySnapshot = SovereigntySnapshot.new()
	snap.player_id = player_id
	snap.army_id = tracked_army_id
	snap.target_coord = target_coord

	snap.direct_regions = GovernanceManager.get_direct_region_count(player_id)
	snap.direct_cap = GovernanceManager.get_direct_cap(player_id)
	var assigned: Array[VassalBeyAssignment] = GovernanceManager.get_vassals_for_suzerain(player_id)
	for v: VassalBeyAssignment in assigned:
		if v == null:
			continue
		snap.vassals.append(VassalCouncilEntry.new(
			v.bey_id, v.loyalty, v.silent_sabotage_active, v.reinforcement_delay_hours))
		if v.silent_sabotage_active:
			snap.silent_sabotage_count += 1
		if v.reinforcement_delay_hours > snap.max_delay_hours:
			snap.max_delay_hours = v.reinforcement_delay_hours

	var cmd: CommanderProfile = SuccessionManager.get_commander_for_army(tracked_army_id)
	if cmd != null:
		snap.commander_name = String(cmd.commander_name)
		snap.commander_age_years = cmd.get_age_years(4)
		snap.commander_scars = cmd.scars
		snap.commander_veteran_score = cmd.veteran_score
		snap.commander_trait = cmd.commander_trait
		snap.commander_alive = cmd.is_alive

	var dyn: DynastyRulerProfile = SuccessionManager.get_dynasty(player_id)
	if dyn != null:
		snap.ruler_name = String(dyn.ruler_name)
		snap.generation = dyn.generation
		snap.heir_name = String(dyn.designated_heir_name)
		snap.heir_ready = dyn.is_heir_ready(SuccessionManager.get_rules())
		snap.heir_amanat = dyn.heir_held_as_amanat
		snap.regency_status = dyn.regency_status

	snap.dread_score = ReputationAndPactSystem.get_dread_score(player_id)
	snap.honor_score = ReputationAndPactSystem.get_honor_score(player_id)
	snap.word_reliability = ReputationAndPactSystem.get_word_reliability(player_id)

	snap.collapse_state = CollapseRecoveryFSM.get_player_state(player_id)
	snap.kut_ceiling = CollapseRecoveryFSM.get_kut_ceiling_for_player(player_id)
	snap.can_select_collapse_path = snap.collapse_state == GameEnums.CollapseState.TRUCE_WITHDRAWAL

	return snap
