extends Node
## Autoload `SeasonManager` (rank 2). Advances the steppe calendar while the
## game is PLAYING and broadcasts `EventBus.season_changed`.

const SEASON_CYCLE_PATH: String = "res://data/seasons/season_cycle.tres"

var _cycle: SeasonCycle = null
var _index: int = 0
var _elapsed_sec: float = 0.0
var _has_started: bool = false


func _ready() -> void:
	set_process(false)
	_cycle = ResourceLoader.load(SEASON_CYCLE_PATH) as SeasonCycle
	if _cycle == null:
		push_error("SeasonManager: failed to load SeasonCycle at %s." % SEASON_CYCLE_PATH)
		return
	var errors: PackedStringArray = _cycle.get_validation_errors()
	for error: String in errors:
		push_error("SeasonManager: %s" % error)
	if not errors.is_empty():
		_cycle = null
		return
	_index = _cycle.starting_index
	EventBus.game_state_changed.connect(_on_game_state_changed)


func _process(delta: float) -> void:
	var season: SeasonData = get_current_season()
	if season == null:
		return
	_elapsed_sec += delta
	if _elapsed_sec >= season.duration_sec:
		_elapsed_sec -= season.duration_sec
		_index = _cycle.get_next_index(_index)
		_broadcast()


## Active season (null until the cycle is loaded).
func get_current_season() -> SeasonData:
	if _cycle == null:
		return null
	return _cycle.get_season(_index)


## Normalised progress (0..1) through the active season.
func get_season_progress() -> float:
	var season: SeasonData = get_current_season()
	if season == null:
		return 0.0
	return clampf(_elapsed_sec / season.duration_sec, 0.0, 1.0)


func _on_game_state_changed(_previous: GameEnums.GameState, new_state: GameEnums.GameState) -> void:
	var is_playing: bool = new_state == GameEnums.GameState.PLAYING
	set_process(is_playing and _cycle != null)
	if is_playing and not _has_started and _cycle != null:
		_has_started = true
		_broadcast()


func _broadcast() -> void:
	var season: SeasonData = get_current_season()
	if season != null:
		EventBus.season_changed.emit(season, _index)
