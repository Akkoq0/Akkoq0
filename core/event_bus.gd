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
signal supply_line_restored(army_id: int, depot_id: int)
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

# --- Phase 5 Dynasty Diplomacy, Coalition Wars, Council Matrix & Khagan Glory
signal dynasty_stance_changed(dynasty_id: StringName, previous_stance: GameEnums.DynastyAttitude, new_stance: GameEnums.DynastyAttitude, trust_index: float)
signal coalition_war_declared(coalition_dynasties: PackedStringArray, player_kut: float)
signal council_decree_enacted(player_id: int, choice: GameEnums.CouncilDilemmaChoice, resulting_kut: float, income_multiplier: float, speed_multiplier: float, loot_multiplier: float)
signal kagan_glory_changed(army_id: int, previous_glory: float, new_glory: float, reason: StringName)
signal rogue_warband_joined_by_glory(army_id: int, bey_id: StringName, joined_troops: int, glory_score: float)

# --- Phase 6 Micro Building Placement, Nomadic Workers & AI Commander -------
signal building_placed_on_micro_grid(instance_id: int, player_id: int, building_id: StringName, zone_id: StringName, origin_coord: Vector2i, world_position: Vector3)
signal worker_gathering_started(worker_id: int, player_id: int, resource_id: StringName, target_coord: Vector2i, target_world_position: Vector3)
signal worker_caravan_delivered(worker_id: int, player_id: int, resource_id: StringName, amount: int, camp_world_position: Vector3)
signal ai_commander_phase_changed(agent_id: StringName, previous_phase: GameEnums.AICommanderPhase, new_phase: GameEnums.AICommanderPhase)
signal ai_raid_launched(agent_id: StringName, is_rogue_warband: bool, raid_target_type: StringName, target_army_id: int, turan_phase: GameEnums.TuranTacticPhase, ambition: float, discipline: float)

# --- Phase 7 Pasture Ecology, Atmospheric Ballistics & Captive Labor --------
signal pasture_depleted_starving_livestock(region_coord: Vector2i, herd_size: int, migration_required: bool)
signal camp_migrated_by_sefer_arabasi(player_id: int, from_coord: Vector2i, to_coord: Vector2i, restored_pasture_capacity: float)
signal overgrazing_rebellion_triggered(player_id: int, region_coord: Vector2i, kut_penalty: float)
signal wind_weather_changed(wind_vector: Vector3, temperature_celsius: float, weather_state: GameEnums.WindWeatherState)
signal atmospheric_volley_resolved(shooter_id: int, range_multiplier: float, accuracy_multiplier: float, morale_damage_multiplier: float, ammo_consumption_multiplier: float)
signal noble_captives_ransomed_or_exchanged(player_id: int, noble_count: int, mode: StringName, bullion_gained: int, trust_bonus: float)
signal captive_labor_assigned(player_id: int, total_slave_workers: int, core_clan_population: int, build_time_saved_ratio: float, cost_discount_ratio: float)
signal slave_revolt_triggered(player_id: int, slave_workers: int, clan_population: int, revolt_risk: float)

# --- Phase 8 Emergent Sandbox, Multi-Sovereignty & Modular Force Splitting --
signal sovereignty_alignment_evolved(player_id: int, previous_alignment: GameEnums.SovereigntyAlignment, new_alignment: GameEnums.SovereigntyAlignment, dominant_score: float)
signal emergent_causal_chain_triggered(chain_id: StringName, region_coord: Vector2i, severity: float, available_response_ids: PackedStringArray)
signal inter_faction_conflict_erupted(attacker_faction_id: StringName, defender_faction_id: StringName, region_coord: Vector2i, contested_driver: StringName)
signal player_intervened_in_faction_conflict(player_id: int, attacker_faction_id: StringName, defender_faction_id: StringName, stance: GameEnums.EmergentInterventionStance, gained_reward_value: float)
signal nomadic_outpost_relocated(player_id: int, outpost_id: StringName, from_coord: Vector2i, to_coord: Vector2i)
signal force_detached_from_army(parent_army_id: int, detachment_army_id: int, role: GameEnums.DetachmentRole, detached_riders: int, speed_bonus_multiplier: float)
signal forces_merged_into_army(target_army_id: int, merged_detachment_id: int, total_riders: int)

# --- Phase 9 Steppe Cataclysms, Kinship Intrigue & Realistic Casualties -----
signal cataclysm_erupted(cataclysm_id: StringName, cataclysm_type: GameEnums.CataclysmType, region_coord: Vector2i, pasture_mult: float, caravan_speed_mult: float, structural_wear: float, refugee_influx: int)
signal cataclysm_subsided(cataclysm_id: StringName, region_coord: Vector2i)
signal kinship_plot_escalated(bey_id: StringName, stage: GameEnums.IntriguePlotStage, loyalty: float, ambition: float, grievance: float)
signal internal_betrayal_triggered(bey_id: StringName, stage: GameEnums.IntriguePlotStage, defected_troops: int, supply_sabotaged: bool, kut_drain: float)
signal kinship_crisis_resolved(bey_id: StringName, action: GameEnums.IntrigueResolutionAction, restored_loyalty: float)
signal battle_wounded_recorded(army_id: int, new_wounded: int, total_wounded_pool: int, speed_penalty_multiplier: float)
signal wounded_troops_recovered(army_id: int, recovered_troops: int, remaining_wounded_pool: int)
signal veteran_casualty_shock_applied(army_id: int, veteran_loss_ratio: float, tactical_efficiency_multiplier: float, cohesion_cap: float)

# --- Causal Chain Propagation & Friction Calibration ------------------------
signal causal_chain_step_propagated(archetype: GameEnums.CausalChainArchetype, step_count: int, steps_executed: PackedStringArray, counterplay_broken: bool)
signal causal_chain_counterplay_applied(archetype: GameEnums.CausalChainArchetype, counterplay: GameEnums.CausalCounterplayAction, recovery_summary: StringName)
signal causal_transition_recorded(record: CausalTransitionRecord)

# --- Phase 18 Persistent World Physics, Töre Peace & Anti-Snowball ----------
signal tore_peace_stage_changed(previous_stage: GameEnums.TorePeaceStage, new_stage: GameEnums.TorePeaceStage, elapsed_hours: float)
signal personal_tore_peace_granted(player_id: int, duration_hours: float, rim_coord: Vector2i)
signal personal_tore_peace_forfeited(player_id: int, reason: StringName)
signal anti_snowball_upkeep_applied(player_id: int, food_spoiled: int, steel_upkeep: int, iron_upkeep: int, kut_stagnation_drain: float, exp_pasture_multiplier: float)
signal offline_doctrine_executed(army_id: int, trigger_reason: GameEnums.OfflineDoctrineTrigger, evade_combat: bool, packed_sefer_arabasi: bool, retreat_terrain_class: GameEnums.TerrainClass)

# --- Phase 19 Hybrid Steppe Conquest, Tuğ Spheres & Kurgan Hegemony ----------
signal border_node_captured(region_coord: Vector2i, node_id: StringName, previous_owner_id: int, new_owner_id: int, tug_radius_m: float, overlapping_enemies: int)
signal yurt_claim_opened(claim_id: StringName, challenger_id: int, defender_id: int, target_coord: Vector2i, contestation_hours: float)
signal yurt_claim_responded(claim_id: StringName, response: GameEnums.ClaimDefenseResponse, resulting_stage: GameEnums.ClaimContestationStage, new_owner_id: int)
signal region_control_changed(region_coord: Vector2i, owner_id: int, control_percent: float, aftermath_choice: GameEnums.ConquestAftermathChoice, scorched_seasons: int)
signal great_khagan_candidate_proclaimed(player_id: int, owned_kurgans: int, total_kurgans: int, coalition_triggered: bool)

# --- Phase 20 Asymmetric Collapse, Vassal, Exile Kingmaker & Rebirth ----------
signal collapse_triggered(player_id: int, conqueror_id: int, truce_hours: float)
signal collapse_truce_ended(player_id: int)
signal collapse_path_selected(player_id: int, choice: GameEnums.CollapsePathChoice, new_state: GameEnums.CollapseState, overlord_id: int)
signal exile_dynasty_extinct(player_id: int, reason: StringName)
signal dynasty_reborn_at_frontier(player_id: int, frontier_coord: Vector2i, glory_reset: float)
signal vassal_coup_attempted(vassal_id: int, overlord_id: int, succeeded: bool, reason: StringName)

# --- Phase 21 Realistic Physics, Courier Delay, Dust Deception & Caravans --
signal courier_dispatched(order_id: StringName, player_id: int, target_army_id: int, eta_sec: float)
signal courier_order_delivered(order_id: StringName, player_id: int, target_army_id: int, command_type: StringName)
signal courier_ambushed_plan_exposed(order_id: StringName, victim_player_id: int, ambusher_id: int, leaked_plan: GameEnums.TuranTacticPhase)
signal dust_deception_evaluated(observer_id: int, target_army_id: int, true_power: float, perceived_power: float, sees_through: bool)
signal caravan_dispatched(caravan_id: StringName, owner_id: int, origin_coord: Vector2i, dest_coord: Vector2i, eta_sec: float)
signal caravan_delivered(caravan_id: StringName, owner_id: int, steel_amt: int, food_amt: int, ammo_amt: float)
signal army_caravan_resupply_delivered(army_id: int, quiver_ammo_amt: float, food_amt: int)
signal caravan_intercepted_crisis(caravan_id: StringName, owner_id: int, raider_id: int, dest_army_id: int, ammo_lost: float, supply_drop: float)
signal artisans_captured(victim_id: int, captor_id: int, captured_masters: int, steel_quality_after: float)

# --- Phase 22 Governance Cap, Ülüş Sabotage, Amanat Pacts & Reputation ------
signal governance_cap_exceeded(player_id: int, owned_regions: int, direct_cap: int, kut_penalty: float, tax_penalty_ratio: float)
signal region_delegated_to_vassal(player_id: int, coord: Vector2i, bey_id: StringName, personality_trait: GameEnums.VassalPersonalityTrait)
signal ulus_contract_settled(bey_id: StringName, fulfilled: bool, shortfall_ratio: float, loyalty_delta: float)
signal vassal_silent_sabotage_delayed(bey_id: StringName, delay_hours: float, troop_multiplier: float)
signal amanat_pact_sealed(pact_id: StringName, party_a: int, party_b: int, hostage_type: GameEnums.AmanatHostageType)
signal amanat_pact_broken(pact_id: StringName, betrayer_id: int, hostage_forfeited: bool, reliability_after: float)
signal proxy_war_sponsored(sponsor_id: int, warband_id: StringName, target_id: int, silver_cost: int)
signal proxy_war_exposed_casus_belli(sponsor_id: int, discoverer_id: int, warband_id: StringName, penalty_free_casus_belli: bool)
signal reputation_memory_changed(player_id: int, word_reliability: float, dread_score: float, honor_tore_score: float)

# --- Phase 23 Steppe Water Routes, Well Sabotage & Dynamic Scarcity Market --
signal water_source_sabotaged(region_coord: Vector2i, source_id: StringName, saboteur_id: int, duration_seasons: int)
signal water_source_restored(region_coord: Vector2i, source_id: StringName, restorer_id: int)
signal water_crisis_inflicted(army_id: int, region_coord: Vector2i, remount_drain: float, morale_penalty: float, is_zud_frozen: bool)
signal regional_market_scarcity_shifted(region_coord: Vector2i, commodity_id: StringName, scarcity_multiplier: float, reason: StringName)
signal barter_trade_executed(player_id: int, region_coord: Vector2i, commodity_id: StringName, direction: GameEnums.BarterDirection, quantity: int, silver_delta: int, is_black_market: bool)

# --- Phase 24 Commander Legacy, Aging & Kurultay Succession Crises ----------
signal ruler_died_succession_started(player_id: int, deceased_name: StringName, new_ruler_name: StringName, generation: int, crisis_triggered: bool, regency_status: GameEnums.RegencyStatus)
signal kurultay_succession_crisis_triggered(player_id: int, crisis_id: StringName, claimant_bey_id: StringName, contested_coord: Vector2i, reason: StringName)
signal succession_crisis_resolved(player_id: int, crisis_id: StringName, response: GameEnums.SuccessionCrisisResponse, new_regency_status: GameEnums.RegencyStatus)
signal commander_legacy_updated(commander_id: int, army_id: int, veteran_score: float, scars: int, commander_trait: GameEnums.CommanderTrait)
signal commander_fallen_in_battle(commander_id: int, army_id: int, player_id: int, morale_shock: float, cohesion_shock: float)



