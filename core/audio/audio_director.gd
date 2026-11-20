extends Node
## AudioDirector Autoload (rank 2).
## Manages Music state machine (menu/explore/battle/winter/victory) with smooth
## crossfades, SFX polyphony pool, global BaseButton UI click hook, and
## persistent bus volume synchronization.

enum MusicMood { NONE, MENU, EXPLORE, BATTLE, WINTER, VICTORY }

const MUSIC_PATHS: Dictionary[MusicMood, String] = {
	MusicMood.MENU: "res://assets/audio/music/menu.ogg",
	MusicMood.EXPLORE: "res://assets/audio/music/explore.ogg",
	MusicMood.BATTLE: "res://assets/audio/music/battle.ogg",
	MusicMood.WINTER: "res://assets/audio/music/winter.ogg",
	MusicMood.VICTORY: "res://assets/audio/music/victory.ogg",
}

const SFX_PATHS: Dictionary[StringName, String] = {
	&"ui_click": "res://assets/audio/sfx/ui_click.ogg",
	&"horn_war": "res://assets/audio/sfx/horn_war.ogg",
	&"alert_ping": "res://assets/audio/sfx/alert_ping.ogg",
	&"march_hooves": "res://assets/audio/sfx/march_hooves.ogg",
	&"sword_clash": "res://assets/audio/sfx/sword_clash.ogg",
	&"winter_wind": "res://assets/audio/sfx/winter_wind.ogg",
}

const SFX_POOL_SIZE: int = 8
const CROSSFADE_SEC: float = 1.2

var _music_a: AudioStreamPlayer = null
var _music_b: AudioStreamPlayer = null
var _active_music_is_a: bool = true
var _current_mood: MusicMood = MusicMood.NONE
var _fade_tween: Tween = null

var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_cursor: int = 0
var _sfx_cache: Dictionary[StringName, AudioStream] = {}
var _music_cache: Dictionary[MusicMood, AudioStream] = {}
var _is_headless: bool = false


func _ready() -> void:
	_is_headless = DisplayServer.get_name().to_lower().contains("headless")
	_setup_players()
	_connect_signals()
	if not _is_headless:
		set_music_mood(MusicMood.MENU)


func _exit_tree() -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	_disconnect_signals()


func apply_volumes(master_linear: float, music_linear: float, sfx_linear: float) -> void:
	_set_bus_linear(&"Master", master_linear)
	_set_bus_linear(&"Music", music_linear)
	_set_bus_linear(&"SFX", sfx_linear)
	_set_bus_linear(&"UI", sfx_linear)


func set_music_mood(mood: MusicMood) -> void:
	if mood == _current_mood or mood == MusicMood.NONE:
		return
	_current_mood = mood
	if _is_headless:
		return
	var stream: AudioStream = _load_music(mood)
	if stream == null:
		return

	var incoming: AudioStreamPlayer = _music_b if _active_music_is_a else _music_a
	var outgoing: AudioStreamPlayer = _music_a if _active_music_is_a else _music_b
	_active_music_is_a = not _active_music_is_a

	incoming.stream = stream
	incoming.volume_db = -40.0
	incoming.play()

	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.set_parallel(true)
	_fade_tween.tween_property(incoming, "volume_db", 0.0, CROSSFADE_SEC)
	if outgoing.playing:
		_fade_tween.tween_property(outgoing, "volume_db", -40.0, CROSSFADE_SEC)
		_fade_tween.chain().tween_callback(outgoing.stop)


func play_sfx(sfx_id: StringName, bus_name: StringName = &"SFX", pitch_jitter: float = 0.04) -> void:
	if _is_headless or _sfx_pool.is_empty():
		return
	var stream: AudioStream = _load_sfx(sfx_id)
	if stream == null:
		return
	var player: AudioStreamPlayer = _sfx_pool[_sfx_cursor]
	_sfx_cursor = (_sfx_cursor + 1) % _sfx_pool.size()
	player.stream = stream
	player.bus = bus_name
	player.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter) if pitch_jitter > 0.0 else 1.0
	player.play()


func get_current_mood() -> MusicMood:
	return _current_mood


func _setup_players() -> void:
	_music_a = AudioStreamPlayer.new()
	_music_a.bus = &"Music"
	add_child(_music_a)

	_music_b = AudioStreamPlayer.new()
	_music_b.bus = &"Music"
	add_child(_music_b)

	for _i: int in range(SFX_POOL_SIZE):
		var sp: AudioStreamPlayer = AudioStreamPlayer.new()
		sp.bus = &"SFX"
		add_child(sp)
		_sfx_pool.append(sp)


func _connect_signals() -> void:
	if get_tree() != null and not get_tree().node_added.is_connected(_on_scene_node_added):
		get_tree().node_added.connect(_on_scene_node_added)
	if not EventBus.macro_world_generated.is_connected(_on_macro_world_generated):
		EventBus.macro_world_generated.connect(_on_macro_world_generated)
	if not EventBus.season_changed.is_connected(_on_season_changed):
		EventBus.season_changed.connect(_on_season_changed)
	if not EventBus.army_move_ordered.is_connected(_on_army_move_ordered):
		EventBus.army_move_ordered.connect(_on_army_move_ordered)
	if not EventBus.match_concluded.is_connected(_on_match_concluded):
		EventBus.match_concluded.connect(_on_match_concluded)


func _disconnect_signals() -> void:
	if get_tree() != null and get_tree().node_added.is_connected(_on_scene_node_added):
		get_tree().node_added.disconnect(_on_scene_node_added)
	if EventBus.macro_world_generated.is_connected(_on_macro_world_generated):
		EventBus.macro_world_generated.disconnect(_on_macro_world_generated)
	if EventBus.season_changed.is_connected(_on_season_changed):
		EventBus.season_changed.disconnect(_on_season_changed)
	if EventBus.army_move_ordered.is_connected(_on_army_move_ordered):
		EventBus.army_move_ordered.disconnect(_on_army_move_ordered)
	if EventBus.match_concluded.is_connected(_on_match_concluded):
		EventBus.match_concluded.disconnect(_on_match_concluded)


func _on_scene_node_added(node: Node) -> void:
	if node is BaseButton:
		var btn: BaseButton = node as BaseButton
		if not btn.pressed.is_connected(_on_any_button_pressed):
			btn.pressed.connect(_on_any_button_pressed)


func _on_any_button_pressed() -> void:
	play_sfx(&"ui_click", &"UI", 0.03)


func _on_macro_world_generated(_state: MacroWorldState) -> void:
	set_music_mood(MusicMood.EXPLORE)


func _on_season_changed(season: SeasonData, _cycle_index: int) -> void:
	if season != null and season.season_type == GameEnums.SeasonType.WINTER:
		set_music_mood(MusicMood.WINTER)
		play_sfx(&"winter_wind", &"SFX", 0.05)
	elif _current_mood == MusicMood.WINTER:
		set_music_mood(MusicMood.EXPLORE)


func _on_army_move_ordered(_army_id: int, _dest: Vector3) -> void:
	play_sfx(&"march_hooves", &"SFX", 0.06)


func _on_match_concluded(_winner_id: int, _reason: StringName) -> void:
	set_music_mood(MusicMood.VICTORY)
	play_sfx(&"horn_war", &"SFX", 0.0)


func _set_bus_linear(bus_name: StringName, linear_val: float) -> void:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	var clamped: float = clampf(linear_val, 0.0, 1.0)
	AudioServer.set_bus_mute(idx, clamped <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(clamped, 0.0001)))


func _load_music(mood: MusicMood) -> AudioStream:
	if _music_cache.has(mood):
		return _music_cache[mood]
	var path: String = MUSIC_PATHS.get(mood, "")
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var res: Resource = ResourceLoader.load(path)
	if res is AudioStream:
		_music_cache[mood] = res as AudioStream
		return res as AudioStream
	return null


func _load_sfx(sfx_id: StringName) -> AudioStream:
	if _sfx_cache.has(sfx_id):
		return _sfx_cache[sfx_id]
	var path: String = SFX_PATHS.get(sfx_id, "")
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var res: Resource = ResourceLoader.load(path)
	if res is AudioStream:
		_sfx_cache[sfx_id] = res as AudioStream
		return res as AudioStream
	return null
