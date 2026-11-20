class_name TutorialDirector
extends RefCounted
## Pure, unit-testable Interactive Tutorial State Machine (rank 4).
## Keeps onboarding short (6 crisp steps, ~3 minutes), action-driven,
## platform-aware (touch vs desktop phrasing), and skippable.

signal step_changed(step_index: int, step_data: TutorialStep)
signal tutorial_finished(was_skipped: bool)

const DEFAULT_SAVE_PATH: String = "user://otuken_tutorial.json"


class TutorialStep:
	extends RefCounted
	var id: StringName = &""
	var title: String = ""
	var touch_hint: String = ""
	var desktop_hint: String = ""
	var requires_action: bool = false

	func _init(
			p_id: StringName,
			p_title: String,
			p_touch: String,
			p_desktop: String,
			p_req: bool = false) -> void:
		id = p_id
		title = p_title
		touch_hint = p_touch
		desktop_hint = p_desktop
		requires_action = p_req

	func get_body(is_touch: bool) -> String:
		return touch_hint if is_touch else desktop_hint


var _steps: Array[TutorialStep] = []
var _current_index: int = -1
var _active: bool = false
var _completed_persisted: bool = false
var _save_path: String = DEFAULT_SAVE_PATH


func _init(p_save_path: String = DEFAULT_SAVE_PATH) -> void:
	_save_path = p_save_path
	_build_steps()
	_completed_persisted = _load_completed_flag()


func _build_steps() -> void:
	_steps = [
		TutorialStep.new(
			&"camera_move",
			"1/6 · Bozkırı Keşfet",
			"Haritayı kaydırmak için tek parmakla sürükle, yakınlaşmak için iki parmakla kıstır.",
			"Kamerayı gezdirmek için WASD tuşlarını, yakınlaşmak için fare tekerleğini kullan.",
			false),
		TutorialStep.new(
			&"move_order",
			"2/6 · Orduyu Yürüt",
			"Haritada gitmek istediğin noktaya dokun ve öncü birliğine hareket emri ver.",
			"Haritada gitmek istediğin noktaya sağ tıkla ve öncü birliğine hareket emri ver.",
			true),
		TutorialStep.new(
			&"layer_switch",
			"3/6 · Makro & Mikro Görünüm",
			"Sağ alttaki 'Katman' butonuna dokunarak yakın taktik alana geç.",
			"'Tab' tuşuna basarak Makro strateji ve Mikro taktik katmanları arasında geç.",
			true),
		TutorialStep.new(
			&"resources_kut",
			"4/6 · Kut ve Kaynaklar",
			"Üst çubuktaki Kut, Gümüş ve Lojistik göstergelerini takip et. Kut düşerse Kurultay karışır.",
			"Üst çubuktaki Kut, Gümüş ve Lojistik göstergelerini takip et. Kut düşerse Kurultay karışır.",
			false),
		TutorialStep.new(
			&"winter_zud",
			"5/6 · Kış ve Zud Tehlikesi",
			"Kışın yüzey suları donar. Ordunu derin kuyulara ve pınarlara yakın tut.",
			"Kışın yüzey suları donar. Ordunu derin kuyulara ve pınarlara yakın tut.",
			false),
		TutorialStep.new(
			&"victory_goal",
			"6/6 · Zafer Yolu",
			"Bölgeleri fethet, Kut hegemonyası kur veya süre sonunda en güçlü Kağan ol!",
			"Bölgeleri fethet, Kut hegemonyası kur veya süre sonunda en güçlü Kağan ol!",
			false),
	]


func start_tutorial() -> void:
	_active = true
	_current_index = 0
	step_changed.emit(_current_index, get_current_step())


func advance_step() -> void:
	if not _active:
		return
	var cur: TutorialStep = get_current_step()
	if cur != null:
		EventBus.tutorial_step_completed.emit(cur.id)
	_current_index += 1
	if _current_index >= _steps.size():
		_active = false
		_completed_persisted = true
		_save_completed_flag(true)
		tutorial_finished.emit(false)
		return
	step_changed.emit(_current_index, get_current_step())


func notify_action(action_id: StringName) -> bool:
	if not _active:
		return false
	var cur: TutorialStep = get_current_step()
	if cur != null and cur.id == action_id:
		advance_step()
		return true
	return false


func skip_tutorial() -> void:
	if not _active:
		return
	_active = false
	_completed_persisted = true
	_save_completed_flag(true)
	tutorial_finished.emit(true)


func is_active() -> bool:
	return _active


func is_completed() -> bool:
	return _completed_persisted


func get_current_index() -> int:
	return _current_index


func get_step_count() -> int:
	return _steps.size()


func get_current_step() -> TutorialStep:
	if _current_index >= 0 and _current_index < _steps.size():
		return _steps[_current_index]
	return null


func _load_completed_flag() -> bool:
	if not FileAccess.file_exists(_save_path):
		return false
	var f: FileAccess = FileAccess.open(_save_path, FileAccess.READ)
	if f == null:
		return false
	var json: JSON = JSON.new()
	var err: Error = json.parse(f.get_as_text())
	f.close()
	if err == OK and json.data is Dictionary:
		var d: Dictionary = DeterministicStateHasher.v_dict(json.data)
		return DeterministicStateHasher.v_bool(d.get("completed", false), false)
	return false


func _save_completed_flag(done: bool) -> void:
	var f: FileAccess = FileAccess.open(_save_path, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({"completed": done}))
	f.close()
