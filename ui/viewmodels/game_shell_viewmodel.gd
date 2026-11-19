class_name GameShellViewModel
extends RefCounted
## UI ViewModel (rank 4). Read-only aggregator and persistence coordinator for
## Faz C's complete Game Shell: Main Menu, New Game Setup, Save/Load Manager
## (via `SaveLoadRepository`), Persistent User Settings, Pause Flow, and
## Multi-Series Match Summary History.

const DEFAULT_SAVES_DIR: String = "user://saves"
const DEFAULT_SETTINGS_PATH: String = "user://otuken_settings.json"


class UserSettingsSnapshot:
	extends RefCounted
	var master_volume: float = 0.85
	var music_volume: float = 0.70
	var sfx_volume: float = 0.90
	var graphics_quality: int = 2
	var ui_scale: float = 1.0
	var touch_friendly_layout: bool = false

	func duplicate_settings() -> UserSettingsSnapshot:
		var c: UserSettingsSnapshot = UserSettingsSnapshot.new()
		c.master_volume = master_volume
		c.music_volume = music_volume
		c.sfx_volume = sfx_volume
		c.graphics_quality = graphics_quality
		c.ui_scale = ui_scale
		c.touch_friendly_layout = touch_friendly_layout
		return c

	func to_dict() -> Dictionary:
		return {
			"graphics_quality": graphics_quality,
			"master_volume": master_volume,
			"music_volume": music_volume,
			"sfx_volume": sfx_volume,
			"touch_friendly_layout": touch_friendly_layout,
			"ui_scale": ui_scale,
		}

	static func from_dict(d: Dictionary) -> UserSettingsSnapshot:
		var s: UserSettingsSnapshot = UserSettingsSnapshot.new()
		s.master_volume = clampf(DeterministicStateHasher.v_float(d.get("master_volume", 0.85), 0.85), 0.0, 1.0)
		s.music_volume = clampf(DeterministicStateHasher.v_float(d.get("music_volume", 0.70), 0.70), 0.0, 1.0)
		s.sfx_volume = clampf(DeterministicStateHasher.v_float(d.get("sfx_volume", 0.90), 0.90), 0.0, 1.0)
		s.graphics_quality = clampi(DeterministicStateHasher.v_int(d.get("graphics_quality", 2), 2), 0, 2)
		s.ui_scale = clampf(DeterministicStateHasher.v_float(d.get("ui_scale", 1.0), 1.0), 0.85, 1.25)
		s.touch_friendly_layout = DeterministicStateHasher.v_bool(d.get("touch_friendly_layout", false), false)
		return s


class DifficultyOptionView:
	extends RefCounted
	var tier: GameEnums.AIDifficultyTier = GameEnums.AIDifficultyTier.SANCAK_BEYI
	var title: String = ""
	var description: String = ""
	var stats_line: String = ""


class PersonalityOptionView:
	extends RefCounted
	var personality: GameEnums.SteppeAIPersonality = GameEnums.SteppeAIPersonality.AKINCI_BASKINCI
	var title: String = ""
	var description: String = ""
	var doctrine_line: String = ""


class NewGameLaunchConfig:
	extends RefCounted
	var session_mode: GameEnums.SessionMode = GameEnums.SessionMode.SINGLEPLAYER_SESSION
	var clan_name: String = "Ötüken Kök Boyu"
	var player_personality: GameEnums.SteppeAIPersonality = GameEnums.SteppeAIPersonality.AKINCI_BASKINCI
	var ai_difficulty: GameEnums.AIDifficultyTier = GameEnums.AIDifficultyTier.SANCAK_BEYI
	var ai_personality: GameEnums.SteppeAIPersonality = GameEnums.SteppeAIPersonality.GOLGE_SABOTOR
	var world_seed: int = 1071


class SaveSlotSummary:
	extends RefCounted
	var slot_id: String = ""
	var file_path: String = ""
	var is_valid: bool = false
	var error_reason: String = ""
	var world_hash: String = ""
	var season_label: String = "Bilinmiyor"
	var kut_score: float = 0.0
	var tick_index: int = 0
	var modified_unix: int = 0
	var display_date: String = ""


class SaveActionResult:
	extends RefCounted
	var ok: bool = false
	var message: String = ""
	var slot_id: String = ""
	var world_hash: String = ""


class MatchSeriesTrack:
	extends RefCounted
	var series_id: StringName = &""
	var title: String = ""
	var tone_id: StringName = &"jade"
	var values: PackedFloat32Array = PackedFloat32Array()
	var labels: PackedStringArray = PackedStringArray()


class TurningPointItem:
	extends RefCounted
	var season_label: String = ""
	var title: String = ""
	var detail: String = ""
	var tone_id: StringName = &"gold"


class MatchSummarySnapshot:
	extends RefCounted
	var is_victory: bool = true
	var outcome_title: String = "BÜYÜK KURULTAY ZAFERİ"
	var outcome_subtitle: String = ""
	var total_seasons: int = 0
	var final_kut: float = 75.0
	var final_silver: int = 0
	var regions_owned: int = 0
	var research_completed: int = 0
	var series_tracks: Array[MatchSeriesTrack] = []
	var turning_points: Array[TurningPointItem] = []


var _saves_dir: String = DEFAULT_SAVES_DIR
var _settings_path: String = DEFAULT_SETTINGS_PATH
var _cached_settings: UserSettingsSnapshot = UserSettingsSnapshot.new()


func set_saves_directory(dir_path: String) -> void:
	if not dir_path.strip_edges().is_empty():
		_saves_dir = dir_path


func get_saves_directory() -> String:
	return _saves_dir


func set_settings_path(path: String) -> void:
	if not path.strip_edges().is_empty():
		_settings_path = path


func load_user_settings() -> UserSettingsSnapshot:
	if FileAccess.file_exists(_settings_path):
		var raw: String = FileAccess.get_file_as_string(_settings_path)
		var jp: JSON = JSON.new()
		if jp.parse(raw) == OK and jp.data is Dictionary:
			_cached_settings = UserSettingsSnapshot.from_dict(DeterministicStateHasher.v_dict(jp.data))
			return _cached_settings.duplicate_settings()
	_cached_settings = UserSettingsSnapshot.new()
	return _cached_settings.duplicate_settings()


func save_user_settings(settings: UserSettingsSnapshot) -> bool:
	if settings == null:
		return false
	_cached_settings = settings.duplicate_settings()
	apply_runtime_settings(_cached_settings)
	var f: FileAccess = FileAccess.open(_settings_path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(_cached_settings.to_dict(), "  "))
	f.close()
	return true


func reset_default_settings() -> UserSettingsSnapshot:
	var def_s: UserSettingsSnapshot = UserSettingsSnapshot.new()
	save_user_settings(def_s)
	return def_s


func get_cached_settings() -> UserSettingsSnapshot:
	return _cached_settings.duplicate_settings()


func apply_runtime_settings(settings: UserSettingsSnapshot) -> void:
	if settings == null:
		return
	var master_idx: int = AudioServer.get_bus_index("Master")
	if master_idx >= 0:
		var clamped_v: float = clampf(settings.master_volume, 0.0001, 1.0)
		AudioServer.set_bus_volume_db(master_idx, linear_to_db(clamped_v))


func get_difficulty_options() -> Array[DifficultyOptionView]:
	var out: Array[DifficultyOptionView] = []
	var tiers: Array[GameEnums.AIDifficultyTier] = [
		GameEnums.AIDifficultyTier.OYMAK_BEYI,
		GameEnums.AIDifficultyTier.SANCAK_BEYI,
		GameEnums.AIDifficultyTier.BOZKIR_KURDU,
		GameEnums.AIDifficultyTier.KAGAN_ZEKASI,
	]
	for t: GameEnums.AIDifficultyTier in tiers:
		var p: AIDifficultyProfile = AIDifficultyProfile.create_preset(t)
		var view: DifficultyOptionView = DifficultyOptionView.new()
		view.tier = t
		view.title = p.display_name if p != null else "Bozkır Rakibi"
		match t:
			GameEnums.AIDifficultyTier.OYMAK_BEYI:
				view.description = "Yeni başlayanlar için: yüksek karar gürültüsü, düşük entrika ve sahte ricata kolay kanma (%0 Hile)."
			GameEnums.AIDifficultyTier.SANCAK_BEYI:
				view.description = "Dengeli bozkır beyi: ikmal korur, makul keşif yapar ve zamanla karşı düzen kurar (%0 Hile)."
			GameEnums.AIDifficultyTier.BOZKIR_KURDU:
				view.description = "Sert komutan: çamur/fırtına tuzaklarından kaçınır, kuyu ve ulakları agresif avlar (%0 Hile)."
			_:
				view.description = "Büyük Kağan zekası: çok adımlı kış pususu kurar, sinerji kovalar ve taktiğini hızla uyarlar (%0 Hile)."
		if p != null:
			view.stats_line = "Keşif %%%.0f · Uyum %.2fx · Tuzak Farkındalığı %.2fx" % [
				p.dust_veil_pierce_skill * 100.0,
				p.adaptation_learning_rate,
				p.terrain_trap_awareness,
			]
		out.append(view)
	return out


func get_personality_options() -> Array[PersonalityOptionView]:
	var out: Array[PersonalityOptionView] = []
	var archetypes: Array[GameEnums.SteppeAIPersonality] = [
		GameEnums.SteppeAIPersonality.AKINCI_BASKINCI,
		GameEnums.SteppeAIPersonality.YAYLAK_IMPARATORU,
		GameEnums.SteppeAIPersonality.GOLGE_SABOTOR,
		GameEnums.SteppeAIPersonality.DEMIR_SAVUNMACI,
	]
	for a: GameEnums.SteppeAIPersonality in archetypes:
		var p: SteppeAIPersonalityProfile = SteppeAIPersonalityProfile.create_preset(a)
		var view: PersonalityOptionView = PersonalityOptionView.new()
		view.personality = a
		view.title = p.display_name if p != null else "Boy"
		match a:
			GameEnums.SteppeAIPersonality.AKINCI_BASKINCI:
				view.description = "Çevik süvari baskınları, çift kanat kuşatma ve hızlı yağma ekonomisi."
			GameEnums.SteppeAIPersonality.YAYLAK_IMPARATORU:
				view.description = "Otlak verimi, derin diplomasi ittifakları ve kalabalık boy yönetimi."
			GameEnums.SteppeAIPersonality.GOLGE_SABOTOR:
				view.description = "Toz perdesi, ulak pususu, kuyu kirletme ve kış yıpratma harbi."
			_:
				view.description = "Araba Kalesi savunması, çelik dövme zanaatı ve dirençli hat tutuşu."
		if p != null:
			view.doctrine_line = "Tercih: %s · Taarruz %.2fx · Ekonomi %.2fx" % [
				_format_doctrine_preset_name(p.preferred_doctrine),
				p.aggression_weight,
				p.economy_weight,
			]
		out.append(view)
	return out


func list_save_slots() -> Array[SaveSlotSummary]:
	var out: Array[SaveSlotSummary] = []
	_ensure_saves_dir_exists()
	var dir: DirAccess = DirAccess.open(_saves_dir)
	if dir == null:
		return out
	var files: PackedStringArray = PackedStringArray()
	dir.list_dir_begin()
	var fn: String = dir.get_next()
	while not fn.is_empty():
		if not dir.current_is_dir() and fn.ends_with(".json"):
			files.append(fn)
		fn = dir.get_next()
	dir.list_dir_end()
	files.sort()

	for file_name: String in files:
		var sid: String = file_name.substr(0, file_name.length() - 5)
		var full_path: String = _saves_dir.path_join(file_name)
		var sum: SaveSlotSummary = _inspect_save_file(sid, full_path)
		out.append(sum)

	out.sort_custom(func(a: SaveSlotSummary, b: SaveSlotSummary) -> bool:
		if a.modified_unix != b.modified_unix:
			return a.modified_unix > b.modified_unix
		return a.slot_id < b.slot_id
	)
	return out


func has_resumable_save() -> bool:
	return not get_latest_valid_slot_id().is_empty()


func get_latest_valid_slot_id() -> String:
	for s: SaveSlotSummary in list_save_slots():
		if s != null and s.is_valid:
			return s.slot_id
	return ""


func save_to_slot(raw_slot_id: String) -> SaveActionResult:
	var res: SaveActionResult = SaveActionResult.new()
	var slot_id: String = _sanitize_slot_id(raw_slot_id)
	if slot_id.is_empty():
		res.ok = false
		res.message = "Geçerli bir kayıt adı girin."
		return res
	_ensure_saves_dir_exists()
	var path: String = _saves_dir.path_join(slot_id + ".json")
	var payload: String = SaveLoadRepository.serialize_save_package()
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		res.ok = false
		res.message = "Kayıt dosyası yazılamadı: %s" % slot_id
		return res
	file.store_string(payload)
	file.close()

	var sum: SaveSlotSummary = _inspect_save_file(slot_id, path)
	res.ok = sum.is_valid
	res.slot_id = slot_id
	res.world_hash = sum.world_hash
	res.message = "Sefer kaydedildi (%s · #%s)." % [slot_id, sum.world_hash.substr(0, 8)]
	return res


func load_from_slot(raw_slot_id: String) -> SaveActionResult:
	var res: SaveActionResult = SaveActionResult.new()
	var slot_id: String = _sanitize_slot_id(raw_slot_id)
	var path: String = _saves_dir.path_join(slot_id + ".json")
	if not FileAccess.file_exists(path):
		res.ok = false
		res.message = "Kayıt dosyası bulunamadı: %s" % slot_id
		return res
	var content: String = FileAccess.get_file_as_string(path)
	var sum: SaveSlotSummary = _inspect_save_file(slot_id, path)
	if not sum.is_valid:
		res.ok = false
		res.slot_id = slot_id
		res.message = "Kayıt yüklenemedi (Bozuk Dosya): %s" % sum.error_reason
		return res
	var loaded: bool = SaveLoadRepository.load_save_package(content)
	if not loaded:
		res.ok = false
		res.slot_id = slot_id
		res.message = "Dünya durumu geri yüklenirken bütünlük reddedildi."
		return res
	res.ok = true
	res.slot_id = slot_id
	res.world_hash = sum.world_hash
	res.message = "Kayıt yüklendi: %s (#%s)." % [slot_id, sum.world_hash.substr(0, 8)]
	return res


func delete_save_slot(raw_slot_id: String) -> bool:
	var slot_id: String = _sanitize_slot_id(raw_slot_id)
	if slot_id.is_empty():
		return false
	var path: String = _saves_dir.path_join(slot_id + ".json")
	if not FileAccess.file_exists(path):
		return false
	var dir: DirAccess = DirAccess.open(_saves_dir)
	if dir == null:
		return false
	return dir.remove(slot_id + ".json") == OK


func capture_match_summary(
		analytics_vm: MetricAnalyticsViewModel = null,
		forced_outcome: int = -1,
		player_id: int = 1) -> MatchSummarySnapshot:
	var snap: MatchSummarySnapshot = MatchSummarySnapshot.new()
	var vm: MetricAnalyticsViewModel = analytics_vm if analytics_vm != null else MetricAnalyticsViewModel.new(player_id, 1)
	snap.final_kut = GameManager.get_kut_score()
	snap.final_silver = ResourceManager.get_amount(player_id, &"silver_gold")
	snap.regions_owned = TerritoryManager.count_owned_regions(player_id)
	snap.research_completed = TraditionResearchManager.get_player_bonuses(player_id).completed_count

	var is_khagan: bool = TerritoryManager.is_great_khagan_candidate(player_id)
	if forced_outcome == 1:
		snap.is_victory = true
	elif forced_outcome == 0:
		snap.is_victory = false
	else:
		snap.is_victory = is_khagan or snap.final_kut >= 50.0

	if snap.is_victory:
		snap.outcome_title = "BÜYÜK KURULTAY ZAFERİ"
		snap.outcome_subtitle = "Bozkır birliği sağlandı · Kut %.0f · Bölge %d · Araştırma %d" % [
			snap.final_kut, snap.regions_owned, snap.research_completed]
	else:
		snap.outcome_title = "BOZKIRDA SANCAK DÜŞTÜ"
		snap.outcome_subtitle = "Hanedan direnişi kırıldı · Kut %.0f · Bölge %d" % [
			snap.final_kut, snap.regions_owned]

	var series_defs: Array[StringName] = [
		MetricAnalyticsViewModel.METRIC_KUT,
		MetricAnalyticsViewModel.METRIC_ORDU,
		MetricAnalyticsViewModel.METRIC_HAZINE,
	]
	var titles: Dictionary[StringName, String] = {
		MetricAnalyticsViewModel.METRIC_KUT: "Kut İstikrarı",
		MetricAnalyticsViewModel.METRIC_ORDU: "Ordu Gücü",
		MetricAnalyticsViewModel.METRIC_HAZINE: "Gümüş Hazine",
	}
	var tones: Dictionary[StringName, StringName] = {
		MetricAnalyticsViewModel.METRIC_KUT: &"jade",
		MetricAnalyticsViewModel.METRIC_ORDU: &"ice",
		MetricAnalyticsViewModel.METRIC_HAZINE: &"gold",
	}

	var max_seasons: int = 0
	for mid: StringName in series_defs:
		var mb: MetricAnalyticsViewModel.MetricBreakdownSnapshot = vm.capture_metric_breakdown(mid)
		var tr: MatchSeriesTrack = MatchSeriesTrack.new()
		tr.series_id = mid
		tr.title = titles[mid] if titles.has(mid) else String(mid)
		tr.tone_id = tones[mid] if tones.has(mid) else &"gold"
		if mb != null:
			for pt: MetricAnalyticsViewModel.TimeSeriesPoint in mb.history_points:
				if pt != null:
					tr.values.append(pt.value)
					tr.labels.append(pt.season_label)
		if tr.values.is_empty():
			var fallback_v: float = snap.final_kut if mid == MetricAnalyticsViewModel.METRIC_KUT else (float(snap.final_silver) if mid == MetricAnalyticsViewModel.METRIC_HAZINE else 100.0)
			tr.values.append(fallback_v)
			tr.labels.append("M1")
		max_seasons = maxi(max_seasons, tr.values.size())
		snap.series_tracks.append(tr)
	snap.total_seasons = maxi(max_seasons, 1)

	var entries: Array[MetricAnalyticsViewModel.ChronicleEntry] = vm.get_chronicle_entries(MetricAnalyticsViewModel.CHRONICLE_ALL)
	var limit: int = mini(entries.size(), 6)
	for i: int in range(limit):
		var ce: MetricAnalyticsViewModel.ChronicleEntry = entries[i]
		if ce == null:
			continue
		var tp: TurningPointItem = TurningPointItem.new()
		tp.season_label = ce.season_label
		tp.title = ce.title
		tp.detail = ce.detail
		tp.tone_id = ce.tone_id
		snap.turning_points.append(tp)

	if snap.turning_points.is_empty():
		var tp_default: TurningPointItem = TurningPointItem.new()
		tp_default.season_label = "M1"
		tp_default.title = "Ötüken Otağı Kuruldu"
		tp_default.detail = "Kut %.0f ve %d Gümüş ile bozkır seferi başlatıldı." % [snap.final_kut, snap.final_silver]
		tp_default.tone_id = &"jade"
		snap.turning_points.append(tp_default)

	return snap


func _inspect_save_file(slot_id: String, path: String) -> SaveSlotSummary:
	var sum: SaveSlotSummary = SaveSlotSummary.new()
	sum.slot_id = slot_id
	sum.file_path = path
	if not FileAccess.file_exists(path):
		sum.is_valid = false
		sum.error_reason = "Dosya yok"
		return sum

	sum.modified_unix = int(FileAccess.get_modified_time(path))
	sum.display_date = Time.get_datetime_string_from_unix_time(sum.modified_unix, true)
	var content: String = FileAccess.get_file_as_string(path)
	var jp: JSON = JSON.new()
	if jp.parse(content) != OK or not (jp.data is Dictionary):
		sum.is_valid = false
		sum.error_reason = "Bozuk JSON biçimi"
		return sum

	var pkg: Dictionary = DeterministicStateHasher.v_dict(jp.data)
	var schema_ver: int = DeterministicStateHasher.v_int(pkg.get("schema_version", -1), -1)
	if schema_ver != SaveLoadRepository.SCHEMA_VERSION:
		sum.is_valid = false
		sum.error_reason = "Uyumsuz şema v%d" % schema_ver
		return sum

	var expected_hash: String = DeterministicStateHasher.v_str(pkg.get("world_hash", ""))
	if expected_hash.length() != 64:
		sum.is_valid = false
		sum.error_reason = "Eksik SHA-256 hash"
		return sum

	var state_var: Variant = pkg.get("state")
	if not (state_var is Dictionary):
		sum.is_valid = false
		sum.error_reason = "Eksik dünya durumu"
		return sum

	var state_dict: Dictionary = DeterministicStateHasher.v_dict(state_var)
	if not WorldSnapshotSerializer.validate_state_dict(state_dict):
		sum.is_valid = false
		sum.error_reason = "Eksik simülasyon bölümü"
		return sum

	var actual_hash: String = DeterministicStateHasher.compute_world_hash(state_dict)
	if actual_hash != expected_hash:
		sum.is_valid = false
		sum.error_reason = "SHA-256 uyuşmazlığı (Bozuk)"
		return sum

	sum.is_valid = true
	sum.world_hash = expected_hash

	var gm: Dictionary = DeterministicStateHasher.v_dict(state_dict.get("game_manager", {}))
	sum.kut_score = DeterministicStateHasher.v_float(gm.get("kut_score", 75.0), 75.0)
	var sm: Dictionary = DeterministicStateHasher.v_dict(state_dict.get("season_manager", {}))
	var s_idx: int = DeterministicStateHasher.v_int(sm.get("current_index", sm.get("index", 0)), 0)
	var cyc: int = DeterministicStateHasher.v_int(sm.get("cycle_count", sm.get("cycle", 0)), 0)
	var season_names: PackedStringArray = PackedStringArray(["İlkbahar", "Yaz", "Güz", "Kış"])
	var s_name: String = season_names[clampi(s_idx, 0, 3)]
	sum.season_label = "%s (Yıl %d)" % [s_name, cyc + 1]
	var clk: Dictionary = DeterministicStateHasher.v_dict(state_dict.get("session_clock", {}))
	sum.tick_index = DeterministicStateHasher.v_int(clk.get("current_tick", 0), 0)
	return sum


func _ensure_saves_dir_exists() -> void:
	if not DirAccess.dir_exists_absolute(_saves_dir):
		DirAccess.make_dir_recursive_absolute(_saves_dir)


static func _sanitize_slot_id(raw: String) -> String:
	var cleaned: String = raw.strip_edges()
	cleaned = cleaned.replace("/", "_").replace("\\", "_").replace("..", "_").replace(" ", "_")
	if cleaned.ends_with(".json"):
		cleaned = cleaned.substr(0, cleaned.length() - 5)
	return cleaned


static func _format_doctrine_preset_name(p_id: GameEnums.BattleDoctrinePresetId) -> String:
	match p_id:
		GameEnums.BattleDoctrinePresetId.TOLGAMA_KISKACI:
			return "Tolgama Kıskacı"
		GameEnums.BattleDoctrinePresetId.BORU_KAMASI:
			return "Börü Kaması"
		GameEnums.BattleDoctrinePresetId.KURT_KAPANI:
			return "Kurt Kapanı"
		GameEnums.BattleDoctrinePresetId.ARABA_KALESI:
			return "Araba Kalesi"
		GameEnums.BattleDoctrinePresetId.TONYUKUK_YIPRATMASI:
			return "Tonyukuk Yıpratması"
	return "Bozkır Nizamı"
