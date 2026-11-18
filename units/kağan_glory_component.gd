class_name GloryComponent
extends Node
## Units (rank 3). Phase 5 **Campaign Spirit & Khagan's Glory Score
## (`glory_score`)** component (`res://units/kağan_glory_component.gd`).
##
## Responsibilities:
##  * Tracks the Khagan's leadership prestige (`glory_score`).
##  * Automatically awards Glory for successful Turan tactics (Crescent traps),
##    Feigned Retreat lures, and Envoy Assassinations.
##  * Allows free, hostage-less recruitment of roaming rogue warbands
##    (`Yersiz Yurtsuz Çeriler`) directly into the army once `glory_score`
##    reaches `free_warband_recruitment_glory_threshold`.

const DEFAULT_RULES_PATH: String = "res://data/diplomacy/diplomacy_rules.tres"
const REASON_TURAN_TACTIC: StringName = &"turan_tactic_victory"
const REASON_FEIGNED_RETREAT: StringName = &"feigned_retreat_lure"
const REASON_ENVOY_ASSASSINATION: StringName = &"envoy_assassination"

@export var rules: DiplomacyRules

var glory_score: float = 0.0
var _army_id: int = 1
var _recruited_troops: int = 0
var _recruited_warbands: PackedStringArray = PackedStringArray()


func _ready() -> void:
	if rules == null:
		rules = ResourceLoader.load(DEFAULT_RULES_PATH) as DiplomacyRules
	EventBus.crescent_trap_sprung.connect(_on_crescent_trap_sprung)
	EventBus.feigned_retreat_lured.connect(_on_feigned_retreat_lured)
	EventBus.envoy_assassinated.connect(_on_envoy_assassinated)


## Configures the component for `p_army_id` and resets `glory_score`.
func configure(p_army_id: int, p_rules: DiplomacyRules = null) -> void:
	_army_id = p_army_id
	if p_rules != null:
		rules = p_rules
	elif rules == null:
		rules = ResourceLoader.load(DEFAULT_RULES_PATH) as DiplomacyRules
	glory_score = 0.0
	_recruited_troops = 0
	_recruited_warbands = PackedStringArray()


## Awards Glory for executing a successful Turan Tactic (e.g. Crescent Encirclement).
func record_successful_turan_tactic() -> float:
	if rules == null:
		return glory_score
	return _add_glory(rules.glory_per_turan_tactic, REASON_TURAN_TACTIC)


## Awards Glory for luring an enemy commander into a Feigned Retreat overextension trap.
func record_successful_feigned_retreat() -> float:
	if rules == null:
		return glory_score
	return _add_glory(rules.glory_per_feigned_retreat_lure, REASON_FEIGNED_RETREAT)


## Awards Glory for executing a rival dynasty's envoy.
func record_envoy_assassination() -> float:
	if rules == null:
		return glory_score
	return _add_glory(rules.glory_per_envoy_assassination, REASON_ENVOY_ASSASSINATION)


func get_glory_score() -> float:
	return glory_score


## True when `glory_score` is high enough to recruit independent `Yersiz Yurtsuz Çeriler`
## warbands directly into the army without taking hostages or paying ransom.
func can_recruit_rogue_warband_freely() -> bool:
	if rules == null:
		return false
	return glory_score >= rules.free_warband_recruitment_glory_threshold


## Recruits a roaming rogue warband (`bey_id`) directly into the Khagan's army
## without hostages when `can_recruit_rogue_warband_freely()` is true.
## Returns the number of veteran steppe riders added (`0` if ineligible).
func recruit_rogue_warband(bey_id: StringName) -> int:
	if rules == null or bey_id == &"" or not can_recruit_rogue_warband_freely():
		return 0
	if not CommandBus.reintegrate_rogue_warband(bey_id):
		return 0
	var added_troops: int = rules.rogue_warband_troop_size
	_recruited_troops += added_troops
	_recruited_warbands.append(String(bey_id))
	EventBus.rogue_warband_joined_by_glory.emit(_army_id, bey_id, added_troops, glory_score)
	return added_troops


func get_recruited_troops() -> int:
	return _recruited_troops


func get_recruited_warbands() -> PackedStringArray:
	return _recruited_warbands


func _add_glory(delta: float, reason: StringName) -> float:
	var max_glory: float = rules.max_glory_score if rules != null else 100.0
	var previous: float = glory_score
	glory_score = clampf(glory_score + delta, 0.0, max_glory)
	if not is_equal_approx(previous, glory_score):
		EventBus.kagan_glory_changed.emit(_army_id, previous, glory_score, reason)
	return glory_score


func _on_crescent_trap_sprung(trap_army_id: int, _target_id: int, _angle: float, _sealed: bool) -> void:
	if trap_army_id == _army_id:
		record_successful_turan_tactic()


func _on_feigned_retreat_lured(luring_army_id: int, _pursuer_id: int, _overext: float, _entropy: float, _collapse: float) -> void:
	if luring_army_id == _army_id:
		record_successful_feigned_retreat()


func _on_envoy_assassinated(_instigator_id: int, _target_id: int, _envoy_id: StringName, _kut_gained: float) -> void:
	record_envoy_assassination()
