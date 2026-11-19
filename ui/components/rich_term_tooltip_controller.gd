class_name RichTermTooltipController
extends Control
## Smart Dual-Input Strategic Term Tooltip Controller (rank 4).
## Supports desktop mouse hover AND mobile/tablet touch long-press across
## core Steppe terms (`Kut`, `Ülüş`, `Zud`, `Yılkı`, `Toz Perdesi`, `Tolgama`,
## `Börü Kaması`, `Kurt Kapanı`, `Araba Kalesi`, `Tonyukuk`, `Töre Barışı`,
## `Amanat`, `Tuğ`, `Kurgan`, `Toy`, `Veraset`, `Kuyu Sabotajı`, etc.).

signal rich_tooltip_shown(term_id: StringName)
signal rich_tooltip_hidden(term_id: StringName)


class RichTermEntry:
	extends RefCounted
	var term_id: StringName = &""
	var title: String = ""
	var subtitle: String = ""
	var summary: String = ""
	var tactical_tip: String = ""
	var live_impact: String = ""
	var tone_id: StringName = &"gold"


class ControlBinding:
	extends RefCounted
	var target: Control = null
	var term_id: StringName = &""
	var enter_cb: Callable = Callable()
	var exit_cb: Callable = Callable()
	var gui_cb: Callable = Callable()


const EXTENDED_TERMS: Array[StringName] = [
	&"kut",
	&"ulus",
	&"zud",
	&"yilki",
	&"toz_perdesi",
	&"tolgama",
	&"boru_kamasi",
	&"kurt_kapani",
	&"araba_kalesi",
	&"tonyukuk_yipratmasi",
	&"amanat",
	&"tug",
	&"toy",
	&"kurgan",
	&"tore_barisi",
	&"kara_borsa",
	&"veraset",
	&"kuyu_sabotaji",
	&"gazi_mirasi",
	&"savas_nizami",
	&"sistemik_sinerji",
]

@export var long_press_threshold_sec: float = 0.42
@export var hover_delay_sec: float = 0.20

var _vm_ref: WeakRef = null
var _touch_friendly: bool = false
var _active_term_id: StringName = &""
var _pressed_term_id: StringName = &""
var _press_anchor: Rect2 = Rect2()
var _press_elapsed_sec: float = 0.0
var _is_pressing: bool = false

var _hovered_term_id: StringName = &""
var _hover_anchor: Rect2 = Rect2()
var _hover_elapsed_sec: float = 0.0
var _is_hovering: bool = false
var _is_locked: bool = false

var _bindings: Array[ControlBinding] = []

var _built: bool = false
var _card: TamgaCardPanel = null
var _title_lbl: Label = null
var _subtitle_lbl: Label = null
var _summary_lbl: Label = null
var _tip_lbl: Label = null
var _impact_lbl: Label = null
var _close_btn: Button = null
var _close_cb: Callable = Callable()


func _init() -> void:
	name = "RichTermTooltipController"
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(304.0, 148.0)


func _ready() -> void:
	_ensure_built()
	set_process(true)


func _exit_tree() -> void:
	unbind_all_terms()
	if _close_btn != null and is_instance_valid(_close_btn) and not _close_cb.is_null():
		if _close_btn.pressed.is_connected(_close_cb):
			_close_btn.pressed.disconnect(_close_cb)
	_close_cb = Callable()


func _process(delta: float) -> void:
	step_timers(delta)


func step_timers(delta: float) -> void:
	var dt: float = maxf(delta, 0.0)
	if _is_pressing and _pressed_term_id != &"":
		_press_elapsed_sec += dt
		var eff_thresh: float = long_press_threshold_sec * (0.75 if _touch_friendly else 1.0)
		if _press_elapsed_sec >= eff_thresh:
			_is_pressing = false
			_is_locked = true
			show_term(_pressed_term_id, _press_anchor, true)
			return
	if _is_hovering and _hovered_term_id != &"" and not _is_locked:
		_hover_elapsed_sec += dt
		if _hover_elapsed_sec >= hover_delay_sec:
			_is_hovering = false
			show_term(_hovered_term_id, _hover_anchor, false)


func set_hud_view_model(vm: OtukenHudViewModel) -> void:
	_vm_ref = weakref(vm) if vm != null else null


func set_touch_friendly(enabled: bool) -> void:
	_touch_friendly = enabled


func bind_term(ctrl: Control, term_id: StringName) -> void:
	if ctrl == null or not is_instance_valid(ctrl):
		return
	var norm: StringName = normalize_rich_term(term_id)
	if norm == &"":
		return
	unbind_term(ctrl)

	var b: ControlBinding = ControlBinding.new()
	b.target = ctrl
	b.term_id = norm
	b.enter_cb = _on_target_mouse_entered.bind(ctrl, norm)
	b.exit_cb = _on_target_mouse_exited.bind(norm)
	b.gui_cb = _on_target_gui_input.bind(ctrl, norm)
	ctrl.mouse_entered.connect(b.enter_cb)
	ctrl.mouse_exited.connect(b.exit_cb)
	ctrl.gui_input.connect(b.gui_cb)
	_bindings.append(b)


func unbind_term(ctrl: Control) -> void:
	if ctrl == null:
		return
	for i: int in range(_bindings.size() - 1, -1, -1):
		var b: ControlBinding = _bindings[i]
		if b != null and b.target == ctrl:
			_disconnect_binding(b)
			_bindings.remove_at(i)


func unbind_all_terms() -> void:
	for b: ControlBinding in _bindings:
		_disconnect_binding(b)
	_bindings.clear()


func show_term(
		raw_term_id: StringName,
		anchor_rect: Rect2 = Rect2(Vector2(24.0, 96.0), Vector2(120.0, 32.0)),
		lock_open: bool = false) -> bool:
	_ensure_built()
	var vm: OtukenHudViewModel = _get_hud_vm()
	var entry: RichTermEntry = resolve_rich_term(raw_term_id, vm)
	if entry.term_id == &"":
		return false

	_active_term_id = entry.term_id
	_is_locked = lock_open
	_card.set_semantic_tone(entry.tone_id, 0.0)
	_title_lbl.text = entry.title
	_subtitle_lbl.text = entry.subtitle
	_summary_lbl.text = entry.summary
	_tip_lbl.text = "İpucu: %s" % entry.tactical_tip
	_impact_lbl.text = entry.live_impact

	var vp_size: Vector2 = _resolve_vp_size()
	var w: float = 316.0
	var h: float = 164.0
	var pos_x: float = clampf(anchor_rect.position.x, 10.0, maxf(vp_size.x - w - 10.0, 10.0))
	var pos_y: float = anchor_rect.position.y + anchor_rect.size.y + 8.0
	if pos_y + h > vp_size.y - 10.0:
		pos_y = maxf(anchor_rect.position.y - h - 8.0, 10.0)
	position = Vector2(pos_x, pos_y)
	size = Vector2(w, h)
	visible = true
	rich_tooltip_shown.emit(_active_term_id)
	return true


func hide_tooltip() -> void:
	_is_hovering = false
	_is_pressing = false
	_is_locked = false
	if not visible:
		return
	var prev: StringName = _active_term_id
	visible = false
	_active_term_id = &""
	rich_tooltip_hidden.emit(prev)


func get_active_term_id() -> StringName:
	return _active_term_id


func is_locked() -> bool:
	return _is_locked


func get_binding_count() -> int:
	return _bindings.size()


static func get_supported_rich_terms() -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for t: StringName in EXTENDED_TERMS:
		out.append(String(t))
	return out


static func normalize_rich_term(raw_key: StringName) -> StringName:
	var base: StringName = SteppeGlossaryTooltip.normalize_term_id(raw_key)
	if base != &"":
		return base
	var clean: String = String(raw_key).strip_edges()
	clean = clean.replace("İ", "i").replace("I", "i").replace("ı", "i")
	clean = clean.replace("Ö", "o").replace("ö", "o").replace("Ü", "u").replace("ü", "u")
	clean = clean.replace("Ğ", "g").replace("ğ", "g").replace("Ş", "s").replace("ş", "s")
	clean = clean.replace("Ç", "c").replace("ç", "c").to_lower()
	clean = clean.replace(" ", "_").replace("-", "_")
	match clean:
		"toz_perdesi", "toz":
			return &"toz_perdesi"
		"tolgama", "tolgama_kiskaci", "cift_kanat_tolgama":
			return &"tolgama"
		"boru_kamasi", "boru":
			return &"boru_kamasi"
		"kurt_kapani":
			return &"kurt_kapani"
		"araba_kalesi":
			return &"araba_kalesi"
		"tonyukuk", "tonyukuk_yipratmasi":
			return &"tonyukuk_yipratmasi"
		_:
			return &""


static func resolve_rich_term(raw_key: StringName, view_model: OtukenHudViewModel = null) -> RichTermEntry:
	var tid: StringName = normalize_rich_term(raw_key)
	var entry: RichTermEntry = RichTermEntry.new()
	if tid == &"":
		return entry

	var vm: OtukenHudViewModel = view_model if view_model != null else OtukenHudViewModel.new()
	var snap: OtukenHudViewModel.PulseSummarySnapshot = vm.capture_snapshot()
	entry.term_id = tid

	match tid:
		&"toz_perdesi":
			entry.title = "Toz Perdesi"
			entry.subtitle = "Yılkı Aldatma & Keşif Karartması"
			entry.summary = "Yedek atların sürüklediği çalılarla ordu gücünü 2.1x fazla gösterir; düşmanın keşfini ve taktik tercihini şaşırtır."
			entry.tactical_tip = "En az %25 yedek at oranında açılabilir; Kurt Kapanı öncesi rakibi korkutmak veya geri çekilmek için kullan."
			entry.tone_id = &"ember" if snap.dust_decoy_active else &"gold"
			entry.live_impact = "Canlı: Toz Perdesi %s · Yedek At %%%.0f" % [
				"AKTİF (~2.1x)" if snap.dust_decoy_active else "Kapalı", snap.remount_horse_ratio * 100.0]
		&"tolgama":
			entry.title = "Tolgama Kıskacı"
			entry.subtitle = "Çift Kanat Çevirme Nizamı"
			entry.summary = "Merkezi %20 ince tutup kanatlara yüklenir; yan ve arka sarmal vuruşlarda %145-%210 kritik darbe üretir."
			entry.tactical_tip = "Ağır Börü Kaması'nın ince merkezi yarmasına karşı açıktır; yüksek Yılkı hızı ve kesintisiz Ülüş sadakati gerektirir."
			entry.tone_id = &"jade"
			entry.live_impact = "Canlı: Etkin Nizam %s · Ülüş Sabotajı %d" % [
				snap.active_battle_doctrine_name, snap.silent_sabotage_beys]
		&"boru_kamasi":
			entry.title = "Börü Kaması"
			entry.subtitle = "Ağır Zırhlı Mızrak Yarması"
			entry.summary = "%60 yoğun merkezle Tolgama gibi ince hatları doğrudan ortadan yarıp dağılma şoku verir."
			entry.tactical_tip = "Çamur, dik yamaç ve Zud öncesi fırtınada ağır yorgunluk çöküşüne uğrar; kuru düzlükte kullan."
			entry.tone_id = &"ember"
			entry.live_impact = "Canlı: Çelik Stoğu %d · Savaş Çarpanı %.2fx" % [
				snap.steel_stockpile, snap.synergy_combat_power_mult]
		&"kurt_kapani":
			entry.title = "Kurt Kapanı"
			entry.subtitle = "Sahte Ricat & Pusu Tuzağı"
			entry.summary = "Öncü atlılarla geri çekilir gibi yapıp kovalayan acemi veya dehşete kapılmış düşmanı pusu arkasına çeker."
			entry.tactical_tip = "Deneyimli Gazi komutanlar takibi erkenden kesebilir; Araba Kalesi kuran orduyu yemlemek zordur."
			entry.tone_id = &"gold"
			entry.live_impact = "Canlı: Ulak Tempo %.2fx · Yedek At %%%.0f" % [
				snap.synergy_courier_tempo_mult, snap.remount_horse_ratio * 100.0]
		&"araba_kalesi":
			entry.title = "Araba Kalesi"
			entry.subtitle = "Zincirli Sefer Arabası Müdafaası"
			entry.summary = "Hareketliliği 0.55x düşürme pahasına yan/arka kuşatma darbelerini %65-70 oranında sönümler."
			entry.tactical_tip = "Tolgama ve Kurt Kapanı'na karşı mükemmeldir; Tonyukuk su/kervan yıpratmasına karşı uzun sürede erir."
			entry.tone_id = &"ice"
			entry.live_impact = "Canlı: İkmal %s · Bölge %d" % [
				"KESİK" if snap.supply_isolated else "Bağlı", snap.owned_regions]
		&"tonyukuk_yipratmasi":
			entry.title = "Tonyukuk Yıpratması"
			entry.subtitle = "Kuyu Zehirleme & Kervan Kesimi"
			entry.summary = "Kalabalık orduların su kaynaklarını ve erzak kervanlarını kurutup muharebeden önce dirençlerini çökerterek yıpratır."
			entry.tactical_tip = "Küçük akıncı bölüklerine karşı etkisi düşüktür; büyük istila ordularına karşı kışın ölümcüldür."
			entry.tone_id = &"ice"
			entry.live_impact = "Canlı: Temiz Su %d · Kervan Açığı %.1f" % [
				snap.usable_water_sources, snap.caravan_ammo_deficit]
		_:
			var base_entry: SteppeGlossaryTooltip.GlossaryEntry = SteppeGlossaryTooltip.resolve_entry(tid, vm)
			entry.title = base_entry.native_name
			entry.subtitle = base_entry.plain_equivalent
			entry.summary = base_entry.gameplay_function
			entry.live_impact = base_entry.live_impact_line
			entry.tone_id = base_entry.tone_id
			entry.tactical_tip = _tactical_tip_for_base(tid)

	return entry


static func _tactical_tip_for_base(tid: StringName) -> String:
	match tid:
		&"kut":
			return "Kut 30'un altına inmeden Toy ve Zafer kazanımıyla Ak Sakallılar Konseyi'ni önle."
		&"zud":
			return "Güz mevsiminden itibaren erzak ve su depolarını doldur; Kurgan arındırması için 12+ Kut sakla."
		&"ulus":
			return "Yönetişim sınırı aşılmışsa sadık beylere Ülüş sözleşmesiyle bölge devret."
		&"yilki":
			return "Acil at kesimi son çaredir; %25 altına inersen Toz Perdesi kapanır."
		&"tug":
			return "Yeşim rezervini koruyarak Tuğ küresini genişlet ve rakip kervanları sınırda kes."
		&"amanat":
			return "Önemli antlaşmalarda söz güvenini koru; zamansız ihanet koalisyon fitilini ateşler."
	return "Detaylar için ilgili domain çekmecesini ve Devlet Defteri'ni incele."


func _ensure_built() -> void:
	if _built:
		return
	_built = true

	_card = TamgaCardPanel.new()
	_card.name = "RichTooltipCard"
	_card.semantic_tone = &"gold"
	_card.clickable = false
	_card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_card)

	var margin: MarginContainer = _card.get_content_container()
	margin.add_theme_constant_override(&"margin_left", 10)
	margin.add_theme_constant_override(&"margin_right", 10)
	margin.add_theme_constant_override(&"margin_top", 8)
	margin.add_theme_constant_override(&"margin_bottom", 8)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override(&"separation", 3)
	margin.add_child(vbox)

	var hdr: HBoxContainer = HBoxContainer.new()
	hdr.add_theme_constant_override(&"separation", 4)
	vbox.add_child(hdr)

	_title_lbl = Label.new()
	_title_lbl.theme_type_variation = &"TitleLabel"
	_title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr.add_child(_title_lbl)

	_close_btn = Button.new()
	_close_btn.name = "RichTooltipCloseBtn"
	_close_btn.theme_type_variation = &"GhostIconButton"
	_close_btn.text = "✕"
	OtukenThemeFactory.apply_button_semantic_styles(_close_btn, NeoSteppePalette.BRONZE_WEATHERED, false, 5, 1)
	_close_cb = hide_tooltip
	_close_btn.pressed.connect(_close_cb)
	hdr.add_child(_close_btn)

	_subtitle_lbl = Label.new()
	_subtitle_lbl.theme_type_variation = &"CaptionLabel"
	_subtitle_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.GOLD_PALE)
	_subtitle_lbl.clip_text = true
	vbox.add_child(_subtitle_lbl)

	_summary_lbl = Label.new()
	_summary_lbl.theme_type_variation = &"BodyLabel"
	_summary_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_summary_lbl.add_theme_font_size_override(&"font_size", 10)
	vbox.add_child(_summary_lbl)

	_tip_lbl = Label.new()
	_tip_lbl.theme_type_variation = &"CaptionLabel"
	_tip_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tip_lbl.add_theme_font_size_override(&"font_size", 10)
	_tip_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.JADE_BRIGHT)
	vbox.add_child(_tip_lbl)

	_impact_lbl = Label.new()
	_impact_lbl.theme_type_variation = &"MutedLabel"
	_impact_lbl.clip_text = true
	_impact_lbl.add_theme_font_size_override(&"font_size", 9)
	vbox.add_child(_impact_lbl)


func _on_target_mouse_entered(ctrl: Control, term_id: StringName) -> void:
	if ctrl == null or not is_instance_valid(ctrl):
		return
	_hovered_term_id = term_id
	_hover_anchor = ctrl.get_global_rect()
	_hover_elapsed_sec = 0.0
	_is_hovering = true


func _on_target_mouse_exited(term_id: StringName) -> void:
	if _hovered_term_id == term_id:
		_is_hovering = false
		_hover_elapsed_sec = 0.0
	_is_pressing = false
	if not _is_locked and _active_term_id == term_id:
		hide_tooltip()


func _on_target_gui_input(event: InputEvent, ctrl: Control, term_id: StringName) -> void:
	if ctrl == null or not is_instance_valid(ctrl):
		return
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if mb != null and mb.button_index == MOUSE_BUTTON_LEFT:
		if mb.pressed:
			_pressed_term_id = term_id
			_press_anchor = ctrl.get_global_rect()
			_press_elapsed_sec = 0.0
			_is_pressing = true
		else:
			_is_pressing = false
		return
	var st: InputEventScreenTouch = event as InputEventScreenTouch
	if st != null:
		if st.pressed:
			_pressed_term_id = term_id
			_press_anchor = ctrl.get_global_rect()
			_press_elapsed_sec = 0.0
			_is_pressing = true
		else:
			_is_pressing = false


func _disconnect_binding(b: ControlBinding) -> void:
	if b == null or b.target == null or not is_instance_valid(b.target):
		return
	if b.enter_cb.is_valid() and b.target.mouse_entered.is_connected(b.enter_cb):
		b.target.mouse_entered.disconnect(b.enter_cb)
	if b.exit_cb.is_valid() and b.target.mouse_exited.is_connected(b.exit_cb):
		b.target.mouse_exited.disconnect(b.exit_cb)
	if b.gui_cb.is_valid() and b.target.gui_input.is_connected(b.gui_cb):
		b.target.gui_input.disconnect(b.gui_cb)


func _get_hud_vm() -> OtukenHudViewModel:
	if _vm_ref == null:
		return null
	var obj: Object = _vm_ref.get_ref()
	if obj != null and is_instance_valid(obj):
		return obj as OtukenHudViewModel
	return null


func _resolve_vp_size() -> Vector2:
	var vp: Viewport = get_viewport()
	if vp != null:
		var vr: Rect2 = vp.get_visible_rect()
		if vr.size.x >= 320.0 and vr.size.y >= 240.0:
			return vr.size
	return Vector2(1152.0, 648.0)
