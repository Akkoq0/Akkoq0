extends Node
## Autoload `TotemManager` (rank 2). Validates the totem roster against the
## asymmetrical point budget and handles `SummonTotemCommand`.
##
## Payment is delegated to the economy through `SpendResourcesCommand`, so this
## manager never touches stockpiles directly.

const TOTEM_ROSTER_PATH: String = "res://data/totems/totem_roster.tres"

var _roster: TotemRoster = null
var _is_roster_valid: bool = false
## "<player_id>:<totem_id>" -> remaining cooldown seconds.
var _cooldowns: Dictionary[StringName, float] = {}


func _ready() -> void:
	_roster = ResourceLoader.load(TOTEM_ROSTER_PATH) as TotemRoster
	if _roster == null:
		push_error("TotemManager: failed to load TotemRoster at %s." % TOTEM_ROSTER_PATH)
		EventBus.totem_roster_validated.emit(false, PackedStringArray(["Roster missing."]))
		return
	var errors: PackedStringArray = _roster.get_validation_errors()
	for error: String in errors:
		push_error("TotemManager: %s" % error)
	_is_roster_valid = errors.is_empty()
	EventBus.totem_roster_validated.emit(_is_roster_valid, errors)
	CommandBus.register_handler(SummonTotemCommand.ID, _handle_summon)


func _exit_tree() -> void:
	CommandBus.unregister_handler(SummonTotemCommand.ID, _handle_summon)


func _process(delta: float) -> void:
	if _cooldowns.is_empty():
		return
	var expired: Array[StringName] = []
	for key: StringName in _cooldowns:
		var remaining: float = _cooldowns[key] - delta
		_cooldowns[key] = remaining
		if remaining <= 0.0:
			expired.append(key)
	for key: StringName in expired:
		_cooldowns.erase(key)


## True when the roster loaded and passed every budget rule.
func is_roster_valid() -> bool:
	return _is_roster_valid


## Roster resource (null when loading failed).
func get_roster() -> TotemRoster:
	return _roster


## Gameplay values derived from a totem's point allocation.
func get_effective_stats(totem_id: StringName) -> Dictionary[StringName, float]:
	if _roster == null:
		var empty: Dictionary[StringName, float] = {}
		return empty
	return _roster.compute_effective_stats(_roster.find_totem(totem_id))


## Remaining cooldown for `player_id` / `totem_id` (0 when ready).
func get_cooldown_remaining(player_id: int, totem_id: StringName) -> float:
	return _cooldowns.get(_cooldown_key(player_id, totem_id), 0.0)


func _handle_summon(command: GameCommand) -> bool:
	var summon: SummonTotemCommand = command as SummonTotemCommand
	if summon == null:
		return command.reject("Expected SummonTotemCommand.")
	if not _is_roster_valid:
		return command.reject("Totem roster failed validation.")
	var totem: TotemData = _roster.find_totem(summon.totem_id)
	if totem == null:
		return command.reject("Unknown totem '%s'." % summon.totem_id)
	var key: StringName = _cooldown_key(summon.player_id, summon.totem_id)
	if _cooldowns.has(key):
		return command.reject("Totem '%s' is on cooldown (%.1fs)." % [summon.totem_id, _cooldowns[key]])
	var payment: SpendResourcesCommand = SpendResourcesCommand.new(summon.player_id, totem.summon_cost)
	if not CommandBus.dispatch(payment):
		return command.reject("Payment failed: %s" % payment.rejection_reason)
	if totem.summon_cooldown_sec > 0.0:
		_cooldowns[key] = totem.summon_cooldown_sec
	EventBus.totem_summoned.emit(summon.player_id, summon.totem_id, summon.position)
	return true


func _cooldown_key(player_id: int, totem_id: StringName) -> StringName:
	return StringName("%d:%s" % [player_id, totem_id])
