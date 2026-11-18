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

# --- Armies -----------------------------------------------------------------
signal army_spawned(army_id: int, owner_id: int, position: Vector3)
signal army_despawned(army_id: int)
signal army_move_ordered(army_id: int, destination: Vector3)
signal army_destination_reached(army_id: int, position: Vector3)
signal army_supply_changed(army_id: int, supply_ratio: float, is_connected: bool)

# --- Supply network ---------------------------------------------------------
signal supply_depot_registered(depot_id: int, owner_id: int, position: Vector3, radius_m: float)
signal supply_depot_unregistered(depot_id: int)
## Late joiners (e.g. freshly spawned armies) ask depots to re-announce.
signal supply_depots_resync_requested()

# --- Combat -----------------------------------------------------------------
signal combat_resolved(result: CombatResult)
