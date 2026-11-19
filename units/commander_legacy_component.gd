class_name CommanderLegacyComponent
extends Node
## Units (rank 3). Phase 24 **Commander Aging, Veteran Turan Readiness,
## Battle Scars, and Instant Morale/FSM Impact Upon Commander Loss**.

const DEFAULT_RULES_PATH: String = "res://data/governance/succession_rules.tres"

@export var rules: SuccessionRules

var _commander_id: int = 0
var _army_id: int = 0
var _player_id: int = 1
var _turan_tactics: TuranTacticsComponent = null
var _morale_component: MoraleComponent = null

var _veteran_score: float = 0.0
var _scars: int = 0
var _trait: GameEnums.CommanderTrait = GameEnums.CommanderTrait.NONE
var _is_alive: bool = true
var _turan_speed_multiplier: float = 1.0
var _rout_resistance: float = 0.0


func _ready() -> void:
	if rules == null:
		rules = ResourceLoader.load(DEFAULT_RULES_PATH) as SuccessionRules
	if not EventBus.commander_legacy_updated.is_connected(_on_commander_legacy_updated):
		EventBus.commander_legacy_updated.connect(_on_commander_legacy_updated)
	if not EventBus.commander_fallen_in_battle.is_connected(_on_commander_fallen_in_battle):
		EventBus.commander_fallen_in_battle.connect(_on_commander_fallen_in_battle)


func _exit_tree() -> void:
	if EventBus.commander_legacy_updated.is_connected(_on_commander_legacy_updated):
		EventBus.commander_legacy_updated.disconnect(_on_commander_legacy_updated)
	if EventBus.commander_fallen_in_battle.is_connected(_on_commander_fallen_in_battle):
		EventBus.commander_fallen_in_battle.disconnect(_on_commander_fallen_in_battle)


func configure(
		p_army_id: int,
		p_player_id: int = 1,
		p_turan_tactics: TuranTacticsComponent = null,
		p_morale_component: MoraleComponent = null,
		p_commander_id: int = 0) -> void:
	_army_id = maxi(p_army_id, 0)
	_player_id = maxi(p_player_id, 1)
	_turan_tactics = p_turan_tactics
	_morale_component = p_morale_component
	_commander_id = p_commander_id
	sync_from_succession_manager()


func sync_from_succession_manager() -> void:
	var profile: CommanderProfile = null
	if _commander_id > 0:
		profile = SuccessionManager.get_commander(_commander_id)
	elif _army_id > 0:
		profile = SuccessionManager.get_commander_for_army(_army_id)
	if profile == null:
		_turan_speed_multiplier = 1.0
		_rout_resistance = 0.0
		_is_alive = true
		return
	_commander_id = profile.commander_id
	_veteran_score = profile.veteran_score
	_scars = profile.scars
	_trait = profile.commander_trait
	_is_alive = profile.is_alive
	_turan_speed_multiplier = profile.get_turan_speed_multiplier(rules)
	_rout_resistance = profile.get_cascade_rout_resistance(rules)
	_push_bonuses_to_siblings()


func get_turan_speed_multiplier() -> float:
	return _turan_speed_multiplier


func get_cascade_rout_resistance() -> float:
	return _rout_resistance


func is_commander_alive() -> bool:
	return _is_alive


func get_veteran_score() -> float:
	return _veteran_score


func get_scar_count() -> int:
	return _scars


func _push_bonuses_to_siblings() -> void:
	if _turan_tactics != null:
		_turan_tactics.set_commander_readiness_multiplier(_turan_speed_multiplier)
		if not _is_alive and _turan_tactics.is_commander_alive():
			_turan_tactics.notify_commander_lost(false)
	if _morale_component != null:
		_morale_component.set_commander_rout_resistance(_rout_resistance)


func _on_commander_legacy_updated(
		p_commander_id: int,
		p_army_id: int,
		p_veteran_score: float,
		p_scars: int,
		p_trait: GameEnums.CommanderTrait) -> void:
	var matches: bool = (_commander_id > 0 and p_commander_id == _commander_id) \
		or (_army_id > 0 and p_army_id == _army_id)
	if not matches:
		return
	_commander_id = p_commander_id
	_veteran_score = p_veteran_score
	_scars = p_scars
	_trait = p_trait
	sync_from_succession_manager()


func _on_commander_fallen_in_battle(
		p_commander_id: int,
		p_army_id: int,
		_player_id: int,
		_morale_shock: float,
		_cohesion_shock: float) -> void:
	var matches: bool = (_commander_id > 0 and p_commander_id == _commander_id) \
		or (_army_id > 0 and p_army_id == _army_id)
	if not matches:
		return
	_is_alive = false
	_turan_speed_multiplier = 0.72
	_rout_resistance = 0.0
	_push_bonuses_to_siblings()
