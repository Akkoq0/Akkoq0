extends Node
## Autoload `EventBus` (rank 2). Strongly-typed, fire-and-forget notifications.
##
## Rules:
##  * Signals describe facts that already happened (past tense / *_changed).
##  * Requests that need validation or a single owner go through CommandBus.
##  * This script contains NO logic and holds NO state.

# --- Game flow --------------------------------------------------------------
signal game_state_changed(previous_state: GameEnums.GameState, new_state: GameEnums.GameState)
signal world_layer_changed(previous_layer: GameEnums.WorldLayer, new_layer: GameEnums.WorldLayer)

# --- Layer transition (camera-driven presentation timing) -------------------
signal layer_transition_started(target_layer: GameEnums.WorldLayer, focus_position: Vector3)
## Emitted when clouds fully cover the screen; presentation layers swap here.
signal layer_transition_midpoint(target_layer: GameEnums.WorldLayer)
signal layer_transition_finished(layer: GameEnums.WorldLayer)

# --- World ------------------------------------------------------------------
signal macro_world_generated(world_state: MacroWorldState)
signal micro_zone_generated(zone_state: MicroZoneState)

# --- Economy & 7-Ore Pipeline -----------------------------------------------
signal resource_amount_changed(player_id: int, ore_id: StringName, new_amount: int, delta: int)
signal ore_refined(player_id: int, recipe_id: StringName, building_id: StringName, batches: int)
signal regional_tax_collected(player_id: int, tax_amount: int, authority_multiplier: float)
signal tamga_authority_updated(player_id: int, multiplier: float)
signal meteoric_iron_bound(player_id: int, target_id: StringName, for_totem_ascension: bool, consumed_amount: int)

# --- Seasons & Zud ----------------------------------------------------------
signal season_changed(season: SeasonData, cycle_index: int)
signal zud_starvation_ticked(food_remaining: int, season: SeasonData)

# --- Kut (Divine Mandate) & Ak Sakallılar Council ---------------------------
signal kut_changed(previous_kut: float, new_kut: float, reason: StringName)
signal ak_sakallilar_council_convened(current_kut: float, legitimacy_penalty: float, trigger_skirmish: bool)

# --- Toy & Meat Distribution Siyaseti ---------------------------------------
signal toy_loot_distributed(bey_id: StringName, total_loot_value: float, allocated_bey_value: float, satisfaction_delta: float)
signal bey_rebelled_as_rogue_warband(bey_id: StringName, warband_title: String, satisfaction: float)

# --- Totems -----------------------------------------------------------------
signal totem_summoned(player_id: int, totem_id: StringName, position: Vector3)
signal totem_roster_validated(is_valid: bool, errors: PackedStringArray)

# --- Armies & 5-Stage Turan Tactics FSM -------------------------------------
signal army_spawned(army_id: int, owner_id: int, position: Vector3)
signal army_despawned(army_id: int)
signal army_move_ordered(army_id: int, destination: Vector3)
signal army_destination_reached(army_id: int, position: Vector3)
signal army_supply_changed(army_id: int, supply_ratio: float, is_connected: bool)
signal turan_phase_changed(army_id: int, previous_phase: GameEnums.TuranTacticPhase, new_phase: GameEnums.TuranTacticPhase)
signal feigned_retreat_lured(army_id: int, pursuer_id: int, overextension_m: float, formation_entropy: float, armor_collapse_ratio: float)
signal formation_entropy_critical(army_id: int, formation_entropy: float, armor_collapse_ratio: float)
signal crescent_trap_sprung(army_id: int, target_id: int, flank_angle_rad: float, is_escape_vector_sealed: bool)
signal quiver_ammo_depleted(army_id: int)

# --- Supply network, Interdiction & Yılkı Sacrifice -------------------------
signal supply_depot_registered(depot_id: int, owner_id: int, position: Vector3, radius_m: float)
signal supply_depot_unregistered(depot_id: int)
## Late joiners (e.g. freshly spawned armies) ask depots to re-announce.
signal supply_depots_resync_requested()
signal supply_line_severed(army_id: int, depot_id: int, raider_id: StringName, captured_loot_value: float)
signal yilki_horses_sacrificed_for_ration(army_id: int, remaining_remount_ratio: float, morale_drop: float, kut_penalty: float)

# --- Combat & Triple Collapse -----------------------------------------------
signal combat_resolved(result: CombatResult)
signal sulfur_fire_trap_detonated(player_id: int, target_id: int, area_damage: float, cohesion_drop: float, morale_drop: float)
signal army_routed(army_id: int, is_annihilated: bool, captured_toy_loot_value: float)
signal cascade_rout_triggered(army_id: int, destroyed_elite_unit_id: StringName, remaining_morale: float)
signal routed_troops_enslaved_to_toy(army_id: int, captured_slave_workers: int, added_toy_loot_value: float)

# --- Espionage, Intelligence & Envoy Provocation ----------------------------
signal espionage_mission_completed(report: EspionageReport)
signal envoy_assassinated(instigator_faction_id: int, target_faction_id: int, envoy_id: StringName, kut_gained: float)
signal total_war_declared(instigator_faction_id: int, target_faction_id: int, stance: GameEnums.DiplomaticStance)

# --- Steppe Diseases & Zud Epidemic -----------------------------------------
signal outbreak_epidemic_started(army_id: int, speed_multiplier: float, daily_attrition_ratio: float)
signal epidemic_daily_attrition_ticked(army_id: int, remaining_troops: int, casualties: int)
signal epidemic_purified_at_kurgan(army_id: int, shrine_building_id: StringName, kut_spent: float)

