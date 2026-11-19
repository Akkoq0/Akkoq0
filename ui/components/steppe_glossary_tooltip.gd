class_name SteppeGlossaryTooltip
extends Control
## UI Component (rank 4). Dual-layer hover-lock Glossary Tooltip card for all 13
## core Ötüken steppe concepts (`Kut`, `Zud`, `Yılkı`, `Ülüş`, `Amanat`, `Tuğ`,
## `Toy`, `Kurgan`, `Töre Barışı`, `Kara Borsa`, `Veraset`, `Kuyu Sabotajı`, `Gazi Mirası`).
##
## Every resolved tooltip strictly presents 3 structured layers:
##   1. Native Steppe Term + Plain Functional Equivalent
##   2. Single-sentence clear gameplay rule
##   3. Live numerical impact line driven read-only by `OtukenHudViewModel`

signal tooltip_locked_changed(term_id: StringName, is_locked: bool)
signal tooltip_visibility_changed(term_id: StringName, is_visible_now: bool)

const REQUIRED_TERMS: Array[StringName] = [
	&"kut",
	&"zud",
	&"yilki",
	&"ulus",
	&"amanat",
	&"tug",
	&"toy",
	&"kurgan",
	&"tore_barisi",
	&"kara_borsa",
	&"veraset",
	&"kuyu_sabotaji",
	&"gazi_mirasi",
]

class GlossaryEntry:
	var term_id: StringName = &""
	var native_name: String = ""
	var plain_equivalent: String = ""
	var gameplay_function: String = ""
	var live_impact_line: String = ""
	var tone_id: StringName = &"jade"

	func is_valid_three_layer() -> bool:
		return term_id != &"" \
			and not native_name.is_empty() \
			and not plain_equivalent.is_empty() \
			and not gameplay_function.is_empty() \
			and not live_impact_line.is_empty()


class HoverBindingRecord:
	var control: Control
	var term_id: StringName
	var entered_cb: Callable
	var exited_cb: Callable

	func _init(p_control: Control, p_term: StringName, p_enter: Callable, p_exit: Callable) -> void:
		control = p_control
		term_id = p_term
		entered_cb = p_enter
		exited_cb = p_exit


@export var hover_lock_delay_sec: float = 0.38

var _card: TamgaCardPanel = null
var _native_title_label: Label = null
var _plain_equiv_label: Label = null
var _lock_btn: Button = null
var _close_btn: Button = null
var _function_label: Label = null
var _impact_strip: PanelContainer = null
var _impact_label: Label = null
var _hint_label: Label = null

var _view_model: OtukenHudViewModel = null
var _active_term_id: StringName = &""
var _is_hovering_trigger: bool = false
var _is_hovering_card: bool = false
var _is_locked: bool = false
var _hover_elapsed_sec: float = 0.0
var _bindings: Array[HoverBindingRecord] = []


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	custom_minimum_size = Vector2(310.0, 138.0)


func _ready() -> void:
	_ensure_ui()
	set_process(true)


func _exit_tree() -> void:
	unbind_all_controls()
	if _card != null:
		if _card.mouse_entered.is_connected(_on_card_mouse_entered):
			_card.mouse_entered.disconnect(_on_card_mouse_entered)
		if _card.mouse_exited.is_connected(_on_card_mouse_exited):
			_card.mouse_exited.disconnect(_on_card_mouse_exited)
	if _lock_btn != null and _lock_btn.pressed.is_connected(_on_lock_button_pressed):
		_lock_btn.pressed.disconnect(_on_lock_button_pressed)
	if _close_btn != null and _close_btn.pressed.is_connected(_on_close_button_pressed):
		_close_btn.pressed.disconnect(_on_close_button_pressed)


func _process(delta: float) -> void:
	if not visible:
		return
	if _is_hovering_trigger and not _is_locked:
		step_hover_timer(delta)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var key: InputEventKey = event as InputEventKey
	if key != null and key.pressed and not key.echo:
		if key.keycode == KEY_ESCAPE and _is_locked:
			unlock_tooltip(true)
			get_viewport().set_input_as_handled()
		elif key.keycode == KEY_SHIFT and _is_hovering_trigger:
			toggle_lock()
			get_viewport().set_input_as_handled()


func set_view_model(view_model: OtukenHudViewModel) -> void:
	_view_model = view_model


static func normalize_term_id(raw_key: StringName) -> StringName:
	var clean: String = String(raw_key).strip_edges()
	clean = clean.replace("İ", "i").replace("I", "i").replace("ı", "i")
	clean = clean.replace("Ö", "o").replace("ö", "o").replace("Ü", "u").replace("ü", "u")
	clean = clean.replace("Ğ", "g").replace("ğ", "g").replace("Ş", "s").replace("ş", "s")
	clean = clean.replace("Ç", "c").replace("ç", "c").to_lower()
	clean = clean.replace(" ", "_").replace("-", "_")
	match clean:
		"kut":
			return &"kut"
		"zud", "jut":
			return &"zud"
		"yilki":
			return &"yilki"
		"ulus":
			return &"ulus"
		"amanat":
			return &"amanat"
		"tug":
			return &"tug"
		"toy":
			return &"toy"
		"kurgan":
			return &"kurgan"
		"tore_barisi", "tore", "kurultay_barisi":
			return &"tore_barisi"
		"kara_borsa":
			return &"kara_borsa"
		"veraset":
			return &"veraset"
		"kuyu_sabotaji", "kuyu_kirletme":
			return &"kuyu_sabotaji"
		"gazi_mirasi", "komutan_mirasi":
			return &"gazi_mirasi"
		_:
			return &""


static func has_term(term_key: StringName) -> bool:
	return normalize_term_id(term_key) != &""


static func get_supported_term_ids() -> PackedStringArray:
	var list: PackedStringArray = PackedStringArray()
	for tid: StringName in REQUIRED_TERMS:
		list.append(String(tid))
	return list


static func resolve_entry(term_key: StringName, view_model: OtukenHudViewModel = null) -> GlossaryEntry:
	var tid: StringName = normalize_term_id(term_key)
	var entry: GlossaryEntry = GlossaryEntry.new()
	if tid == &"":
		return entry
	var vm: OtukenHudViewModel = view_model if view_model != null else OtukenHudViewModel.new()
	var snap: OtukenHudViewModel.PulseSummarySnapshot = vm.capture_snapshot()
	entry.term_id = tid

	match tid:
		&"kut":
			entry.native_name = "Kut"
			entry.plain_equivalent = "Göksel Meşruiyet & Hanedan İstikrarı"
			entry.gameplay_function = "30'un altına düşerse Ak Sakallılar Konseyi toplanır, meşruiyet azalır ve komşu hanedanlar koalisyon kurabilir."
			entry.tone_id = &"ember" if snap.kut_score < 30.0 else &"jade"
			entry.live_impact_line = "Canlı Etki: Kut %.1f/100 · Meşruiyet %%%.0f · Konsey %s" % [
				snap.kut_score, snap.legitimacy_multiplier * 100.0, "AKTİF" if snap.council_active else "Sakin"]
		&"zud":
			entry.native_name = "Zud"
			entry.plain_equivalent = "Bozkır Kış Kıranı & Salgın Baskısı"
			entry.gameplay_function = "Kışın erzak sıfırlanırsa sürü açlığı, Kut düşüşü ve Bozkır Vebası salgını tetiklenir."
			entry.tone_id = &"ember" if (snap.plague_active or snap.water_crisis_active or (snap.season_type == GameEnums.SeasonType.WINTER and snap.food_reserve <= 0)) else &"ice"
			entry.live_impact_line = "Canlı Etki: Erzak %d · Kış Ufku %.1f mevsim · Su %d kaynak" % [
				snap.food_reserve, snap.winter_horizon_seasons, snap.usable_water_sources]
		&"yilki":
			entry.native_name = "Yılkı"
			entry.plain_equivalent = "Yedek At Sürüsü & Süvari İkmali"
			entry.gameplay_function = "Kuşatılmış kıtlıkta kesilerek orduyu besler fakat süvari manevra hızını ve ahlakı kalıcı düşürür."
			entry.tone_id = &"ember" if snap.remount_horse_ratio < 0.45 else &"jade"
			entry.live_impact_line = "Canlı Etki: Yılkı Sürüsü %d · Yedek At %%%.0f · İkmal %s" % [
				snap.yilki_herd_count, snap.remount_horse_ratio * 100.0, "KESİLDİ" if snap.supply_isolated else "Bağlı"]
		&"ulus":
			entry.native_name = "Ülüş"
			entry.plain_equivalent = "Boy Payı & Tâbi Bey Sözleşmesi"
			entry.gameplay_function = "Yönetişim sınırı aşıldığında devredilen beylere eksik pay verilirse sessiz sabotaj ve gecikmeli takviye doğar."
			entry.tone_id = &"ember" if snap.silent_sabotage_beys > 0 else &"gold"
			entry.live_impact_line = "Canlı Etki: Doğrudan %d/%d · Tâbi Bey %d · Sabotaj %d" % [
				snap.direct_regions, snap.direct_cap, snap.delegated_regions, snap.silent_sabotage_beys]
		&"amanat":
			entry.native_name = "Amanat"
			entry.plain_equivalent = "Diplomatik Rehin & Söz Güvencesi"
			entry.gameplay_function = "Rehin verilen veliaht ya da Yeşim mühür bozulursa itibar güveni çöker ve kanlı veraset krizine kapı aralar."
			entry.tone_id = &"ember" if (snap.heir_amanat_locked or snap.word_reliability < 50.0) else &"gold"
			entry.live_impact_line = "Canlı Etki: Söz Güveni %.0f/100 · Rehin Veliaht %s" % [
				snap.word_reliability, "KİLİTLİ" if snap.heir_amanat_locked else "Özgür"]
		&"tug":
			entry.native_name = "Tuğ"
			entry.plain_equivalent = "Sancak Hakimiyet Küresi & Kervan Denetimi"
			entry.gameplay_function = "Sınır düğümlerine dikilen Tuğ etki yarıçapı Yeşim ile büyür ve çakışan düşman kervanlarını %85'e kadar keser."
			entry.tone_id = &"jade"
			entry.live_impact_line = "Canlı Etki: Tuğ Yarıçapı %.0fm · Yeşim Otoritesi %.2fx" % [
				snap.tug_radius_m, snap.jade_authority_mult]
		&"toy":
			entry.native_name = "Toy"
			entry.plain_equivalent = "Ganimet Şöleni & Boy Bağlılığı"
			entry.gameplay_function = "Savaş ganimeti ve et şöleninin beylerle adil paylaşımı yeni fetih istikrarı sağlar; cimrilik Yersiz Yurtsuz isyanı doğurur."
			entry.tone_id = &"gold"
			entry.live_impact_line = "Canlı Etki: Hazine %d Gümüş · Şöhret/Onur %.0f · Dehşet %.0f" % [
				snap.silver_bullion, snap.honor_score, snap.dread_score]
		&"kurgan":
			entry.native_name = "Kurgan"
			entry.plain_equivalent = "Kutsal Ata Ocağı & Salgın Arınması"
			entry.gameplay_function = "Kutsal Kurganların %51 çoğunluğu Büyük Kağan adaylığını açar ve 12+ Kut bedeliyle bozkır salgınını arındırır."
			entry.tone_id = &"jade"
			entry.live_impact_line = "Canlı Etki: Kurgan %d/%d · Adaylık %s" % [
				snap.player_kurgans, snap.total_kurgans,
				"EVET" if TerritoryManager.is_great_khagan_candidate(snap.player_id) else "Yok"]
		&"tore_barisi":
			entry.native_name = "Töre Barışı"
			entry.plain_equivalent = "Kademeli Savaş Kısıtı & Koruma Kalkanı"
			entry.gameplay_function = "İlk aşamalarda ana Oba baskınını engeller; saldırgan eylem kişisel 48 saatlik koruma kalkanını anında düşürür."
			entry.tone_id = &"jade" if snap.personal_peace_hours > 0.0 else &"ice"
			entry.live_impact_line = "Canlı Etki: %s · Kişisel Kalkan %.1f sa · Mod %s" % [
				OtukenHudViewModel.format_tore_stage_short(snap.tore_stage),
				snap.personal_peace_hours,
				"Kalıcı" if snap.persistent_mode_active else "Serbest"]
		&"kara_borsa":
			entry.native_name = "Kara Borsa"
			entry.plain_equivalent = "Kıtlık & Sürgün Kaçak Takas Ağı"
			entry.gameplay_function = "Kervan kesintisi kıtlığı yükseltirken Yersiz Yurtsuz sürgünler loncadan men edilip yalnızca kaçak takasa erişir."
			entry.tone_id = &"ember" if snap.market_scarcity_steel >= 1.3 else &"gold"
			entry.live_impact_line = "Canlı Etki: Çelik Kıtlık %.2fx · Durum %s" % [
				snap.market_scarcity_steel, OtukenHudViewModel.format_collapse_state_short(snap.collapse_state)]
		&"veraset":
			entry.native_name = "Veraset"
			entry.plain_equivalent = "Taht Ardıllığı & Kurultay Naibliği"
			entry.gameplay_function = "Yetkin olmayan, çocuk ya da Amanat rehinli veliahtla taht değişirse hırslı beyler Kurultay Veraset Krizi başlatır."
			entry.tone_id = &"ember" if snap.regency_status == GameEnums.RegencyStatus.KURULTAY_SUCCESSION_CRISIS else &"jade"
			entry.live_impact_line = "Canlı Etki: Nesil %d · %s · Vergi %%%.0f" % [
				snap.generation, OtukenHudViewModel.format_regency_short(snap.regency_status), snap.regency_tax_multiplier * 100.0]
		&"kuyu_sabotaji":
			entry.native_name = "Kuyu Sabotajı"
			entry.plain_equivalent = "Su Hattı Zehirlenmesi & Susuzluk Şoku"
			entry.gameplay_function = "Bölge kuyularının kirletilmesi veya Zud'da donması kullanılabilir suyu sıfırlayıp Yılkı kaybı ve moral düşüşü yaratır."
			entry.tone_id = &"ember" if (snap.water_crisis_active or snap.usable_water_sources <= 0) else &"ice"
			entry.live_impact_line = "Canlı Etki: Aktif Su Kaynağı %d · Su Krizi %s · Yedek At %%%.0f" % [
				snap.usable_water_sources, "AKTİF" if snap.water_crisis_active else "Güvenli", snap.remount_horse_ratio * 100.0]
		&"gazi_mirasi":
			var cmdr: CommanderProfile = SuccessionManager.get_commander_for_army(snap.tracked_army_id)
			var s_rules: SuccessionRules = SuccessionManager.get_rules()
			var vet_score: float = cmdr.veteran_score if cmdr != null else 0.0
			var scars: int = cmdr.scars if cmdr != null else 0
			var speed_mult: float = cmdr.get_turan_speed_multiplier(s_rules) if cmdr != null else 1.0
			var rout_res: float = cmdr.get_cascade_rout_resistance(s_rules) if cmdr != null else 0.0
			var cmdr_alive: bool = cmdr.is_alive if cmdr != null else true
			entry.native_name = "Gazi Mirası"
			entry.plain_equivalent = "Komutan Gaziliği, Yara İzi & Panik Direnci"
			entry.gameplay_function = "Seferde pişen komutanlar Turan manevra hızını ve panik direncini artırır; düşerse ordu anında komuta şokuna girer."
			entry.tone_id = &"ember" if not cmdr_alive else (&"gold" if scars > 0 else &"jade")
			entry.live_impact_line = "Canlı Etki: Gazi %.0f · Yara %d · Turan %.2fx · Direnç %%%.0f (%s)" % [
				vet_score, scars, speed_mult, rout_res * 100.0, "Sağ" if cmdr_alive else "DÜŞTÜ"]
		_:
			pass

	return entry


func show_for_term(
		term_key: StringName,
		anchor_global_rect: Rect2 = Rect2(Vector2(24.0, 74.0), Vector2(180.0, 48.0)),
		view_model: OtukenHudViewModel = null) -> bool:
	_ensure_ui()
	var active_vm: OtukenHudViewModel = view_model if view_model != null else _view_model
	var entry: GlossaryEntry = resolve_entry(term_key, active_vm)
	if not entry.is_valid_three_layer():
		return false

	_active_term_id = entry.term_id
	_apply_entry(entry)
	visible = true
	_position_near(anchor_global_rect)
	tooltip_visibility_changed.emit(_active_term_id, true)
	return true


func begin_hover(
		term_key: StringName,
		anchor_global_rect: Rect2 = Rect2(Vector2(24.0, 74.0), Vector2(180.0, 48.0)),
		view_model: OtukenHudViewModel = null) -> bool:
	_is_hovering_trigger = true
	if _is_locked and _active_term_id != &"" and normalize_term_id(term_key) == _active_term_id:
		return show_for_term(term_key, anchor_global_rect, view_model)
	_hover_elapsed_sec = 0.0
	if _is_locked:
		set_locked(false)
	return show_for_term(term_key, anchor_global_rect, view_model)


func end_hover() -> void:
	_is_hovering_trigger = false
	if _is_locked or _is_hovering_card:
		return
	hide_tooltip()


func step_hover_timer(delta: float) -> bool:
	if not visible or _is_locked or not _is_hovering_trigger:
		return _is_locked
	_hover_elapsed_sec += maxf(delta, 0.0)
	if _hover_elapsed_sec >= maxf(hover_lock_delay_sec, 0.01):
		lock_tooltip()
		return true
	return false


func lock_tooltip() -> void:
	set_locked(true)


func unlock_tooltip(hide_after: bool = true) -> void:
	set_locked(false)
	if hide_after:
		hide_tooltip()


func toggle_lock() -> bool:
	set_locked(not _is_locked)
	return _is_locked


func set_locked(locked: bool) -> void:
	var changed: bool = _is_locked != locked
	_is_locked = locked
	_sync_lock_chrome()
	if changed:
		tooltip_locked_changed.emit(_active_term_id, _is_locked)


func hide_tooltip() -> void:
	var prev: StringName = _active_term_id
	_is_hovering_trigger = false
	_is_hovering_card = false
	_hover_elapsed_sec = 0.0
	_is_locked = false
	visible = false
	_sync_lock_chrome()
	if prev != &"":
		tooltip_visibility_changed.emit(prev, false)


func is_hover_locked() -> bool:
	return _is_locked


func get_active_term_id() -> StringName:
	return _active_term_id


func get_layer_texts() -> Dictionary[StringName, String]:
	_ensure_ui()
	return {
		&"native": _native_title_label.text,
		&"plain": _plain_equiv_label.text,
		&"function": _function_label.text,
		&"live_impact": _impact_label.text,
	}


func bind_control(control: Control, term_key: StringName) -> bool:
	if control == null or not has_term(term_key):
		return false
	var tid: StringName = normalize_term_id(term_key)
	var enter_cb: Callable = _on_bound_mouse_entered.bind(control, tid)
	var exit_cb: Callable = _on_bound_mouse_exited.bind(control, tid)
	if not control.mouse_entered.is_connected(enter_cb):
		control.mouse_entered.connect(enter_cb)
	if not control.mouse_exited.is_connected(exit_cb):
		control.mouse_exited.connect(exit_cb)
	_bindings.append(HoverBindingRecord.new(control, tid, enter_cb, exit_cb))
	return true


func unbind_control(control: Control) -> void:
	if control == null:
		return
	for idx: int in range(_bindings.size() - 1, -1, -1):
		var rec: HoverBindingRecord = _bindings[idx]
		if rec.control == control:
			if is_instance_valid(rec.control):
				if rec.control.mouse_entered.is_connected(rec.entered_cb):
					rec.control.mouse_entered.disconnect(rec.entered_cb)
				if rec.control.mouse_exited.is_connected(rec.exited_cb):
					rec.control.mouse_exited.disconnect(rec.exited_cb)
			_bindings.remove_at(idx)


func unbind_all_controls() -> void:
	for rec: HoverBindingRecord in _bindings:
		if rec.control != null and is_instance_valid(rec.control):
			if rec.control.mouse_entered.is_connected(rec.entered_cb):
				rec.control.mouse_entered.disconnect(rec.entered_cb)
			if rec.control.mouse_exited.is_connected(rec.exited_cb):
				rec.control.mouse_exited.disconnect(rec.exited_cb)
	_bindings.clear()


func _ensure_ui() -> void:
	if _card != null:
		return
	_card = TamgaCardPanel.new()
	_card.name = "GlossaryCard"
	_card.card_id = &"glossary_tooltip_card"
	_card.theme_type_variation = &"TooltipCard"
	_card.custom_minimum_size = Vector2(310.0, 134.0)
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	_card.mouse_entered.connect(_on_card_mouse_entered)
	_card.mouse_exited.connect(_on_card_mouse_exited)
	add_child(_card)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.name = "GlossaryLayout"
	vbox.add_theme_constant_override(&"separation", 5)
	_card.get_content_container().add_child(vbox)

	# Katman 1: Özgün Ad + Sade İşlevsel Karşılık + Hover-Lock / Close controls
	var header_row: HBoxContainer = HBoxContainer.new()
	header_row.add_theme_constant_override(&"separation", 8)
	vbox.add_child(header_row)

	var title_stack: VBoxContainer = VBoxContainer.new()
	title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_stack.add_theme_constant_override(&"separation", 1)
	header_row.add_child(title_stack)

	_native_title_label = Label.new()
	_native_title_label.name = "Layer1NativeTerm"
	_native_title_label.theme_type_variation = &"TitleLabel"
	title_stack.add_child(_native_title_label)

	_plain_equiv_label = Label.new()
	_plain_equiv_label.name = "Layer1PlainEquivalent"
	_plain_equiv_label.theme_type_variation = &"CaptionLabel"
	title_stack.add_child(_plain_equiv_label)

	_lock_btn = Button.new()
	_lock_btn.name = "HoverLockButton"
	_lock_btn.theme_type_variation = &"GhostIconButton"
	_lock_btn.text = "Sabitle"
	OtukenThemeFactory.apply_button_semantic_styles(_lock_btn, NeoSteppePalette.BRONZE_WEATHERED, false, 6, 2)
	_lock_btn.pressed.connect(_on_lock_button_pressed)
	header_row.add_child(_lock_btn)

	_close_btn = Button.new()
	_close_btn.name = "CloseTooltipButton"
	_close_btn.theme_type_variation = &"GhostIconButton"
	_close_btn.text = "✕"
	OtukenThemeFactory.apply_button_semantic_styles(_close_btn, NeoSteppePalette.BRONZE_DARK, false, 6, 2)
	_close_btn.pressed.connect(_on_close_button_pressed)
	header_row.add_child(_close_btn)

	var sep: HSeparator = HSeparator.new()
	vbox.add_child(sep)

	# Katman 2: Tek Cümlelik Net Oynanış İşlevi
	_function_label = Label.new()
	_function_label.name = "Layer2GameplayFunction"
	_function_label.theme_type_variation = &"Label"
	_function_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_function_label)

	# Katman 3: Canlı Sayısal Etki Satırı
	_impact_strip = PanelContainer.new()
	_impact_strip.name = "Layer3ImpactStrip"
	_impact_strip.add_theme_stylebox_override(&"panel", OtukenThemeFactory.build_card_style(
		NeoSteppePalette.JADE_PRIMARY, 1, NeoSteppePalette.CHARCOAL_SURFACE, 8, 4))
	vbox.add_child(_impact_strip)

	_impact_label = Label.new()
	_impact_label.name = "Layer3LiveImpact"
	_impact_label.theme_type_variation = &"CaptionLabel"
	_impact_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_impact_strip.add_child(_impact_label)

	_hint_label = Label.new()
	_hint_label.name = "HoverLockHint"
	_hint_label.theme_type_variation = &"MutedLabel"
	_hint_label.text = "İpucu sabitlenene dek imleci üzerinde tutun (Shift: Kilitle)"
	vbox.add_child(_hint_label)
	_sync_lock_chrome()


func _apply_entry(entry: GlossaryEntry) -> void:
	_native_title_label.text = entry.native_name.to_upper()
	_plain_equiv_label.text = entry.plain_equivalent
	_function_label.text = entry.gameplay_function
	_impact_label.text = entry.live_impact_line
	var accent: Color = NeoSteppePalette.get_semantic_color(entry.tone_id)
	_card.set_semantic_tone(entry.tone_id, 0.2 if entry.tone_id == &"ember" else 0.0)
	_impact_strip.add_theme_stylebox_override(&"panel", OtukenThemeFactory.build_card_style(
		accent, 1, NeoSteppePalette.CHARCOAL_SURFACE, 8, 4))
	_impact_label.add_theme_color_override(&"font_color", accent.lerp(NeoSteppePalette.TEXT_PRIMARY, 0.45))


func _sync_lock_chrome() -> void:
	if _lock_btn == null or _card == null:
		return
	_lock_btn.text = "Kilitli" if _is_locked else "Sabitle"
	OtukenThemeFactory.apply_button_semantic_styles(
		_lock_btn,
		NeoSteppePalette.GOLD_TAMGA if _is_locked else NeoSteppePalette.BRONZE_WEATHERED,
		_is_locked,
		6,
		2)
	_close_btn.visible = _is_locked
	_card.set_selected(_is_locked)
	_hint_label.text = "KİLİTLİ · İmleç çekilse de açık (Esc: Kapat)" if _is_locked else "Katman 1/2 · Sabitlemek için bekleyin veya Shift'e basın"


func _position_near(anchor_global_rect: Rect2) -> void:
	var vp_size: Vector2 = get_viewport_rect().size
	if vp_size.x <= 10.0 or vp_size.y <= 10.0:
		vp_size = Vector2(1152.0, 648.0)
	var card_size: Vector2 = _card.get_combined_minimum_size().max(custom_minimum_size)
	var target_pos: Vector2 = Vector2(anchor_global_rect.position.x, anchor_global_rect.end.y + 8.0)
	if target_pos.y + card_size.y > vp_size.y - 12.0:
		target_pos.y = anchor_global_rect.position.y - card_size.y - 8.0
	target_pos.x = clampf(target_pos.x, 12.0, maxf(vp_size.x - card_size.x - 12.0, 12.0))
	target_pos.y = clampf(target_pos.y, 12.0, maxf(vp_size.y - card_size.y - 12.0, 12.0))
	global_position = target_pos
	size = card_size


func _on_bound_mouse_entered(control: Control, term_id: StringName) -> void:
	if control != null and is_instance_valid(control):
		begin_hover(term_id, control.get_global_rect(), _view_model)


func _on_bound_mouse_exited(_control: Control, _term_id: StringName) -> void:
	end_hover()


func _on_card_mouse_entered() -> void:
	_is_hovering_card = true


func _on_card_mouse_exited() -> void:
	_is_hovering_card = false
	if not _is_locked and not _is_hovering_trigger:
		hide_tooltip()


func _on_lock_button_pressed() -> void:
	toggle_lock()


func _on_close_button_pressed() -> void:
	unlock_tooltip(true)
