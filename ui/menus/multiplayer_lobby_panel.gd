class_name MultiplayerLobbyPanel
extends TamgaCardPanel
## "Arkadaşlarla Oyna" Multiplayer Lobby Panel (rank 4).
## Supports LAN auto-discovery (UDP 7778), Direct IP / VPN (ENet 7777),
## Host room creation, and 2-4 player roster + AI fill options.

signal lobby_closed()
signal campaign_launch_requested(cfg: GameShellViewModel.NewGameLaunchConfig)

var _coordinator: MultiplayerSessionCoordinator = null
var _built: bool = false

var _tab_host_btn: Button = null
var _tab_join_btn: Button = null
var _host_box: VBoxContainer = null
var _join_box: VBoxContainer = null

var _host_ip_lbl: Label = null
var _room_code_edit: LineEdit = null
var _seed_spin: SpinBox = null
var _quick_match_chk: CheckBox = null
var _ai_fill_chk: CheckBox = null
var _roster_lbl: Label = null
var _host_start_btn: Button = null
var _host_open_btn: Button = null

var _lan_list: ItemList = null
var _manual_ip_edit: LineEdit = null
var _manual_port_spin: SpinBox = null
var _join_connect_btn: Button = null
var _status_lbl: Label = null
var _close_btn: Button = null

var _discovered_rooms: Array[LanDiscoveryBeacon.LanRoomInfo] = []


func _init() -> void:
	name = "MultiplayerLobbyPanel"
	card_id = &"multiplayer_lobby"
	semantic_tone = &"ice"
	clickable = false
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP


func _ready() -> void:
	_ensure_built()


func _exit_tree() -> void:
	if _coordinator != null and is_instance_valid(_coordinator):
		if _coordinator.lobby_roster_changed.is_connected(_on_roster_changed):
			_coordinator.lobby_roster_changed.disconnect(_on_roster_changed)
		if _coordinator.match_launch_received.is_connected(_on_match_launch_received):
			_coordinator.match_launch_received.disconnect(_on_match_launch_received)
		var b: LanDiscoveryBeacon = _coordinator.get_beacon()
		if b != null and b.rooms_updated.is_connected(_on_lan_rooms_updated):
			b.rooms_updated.disconnect(_on_lan_rooms_updated)


func open_lobby(coordinator: MultiplayerSessionCoordinator) -> void:
	_coordinator = coordinator
	_ensure_built()
	if _coordinator != null:
		if not _coordinator.lobby_roster_changed.is_connected(_on_roster_changed):
			_coordinator.lobby_roster_changed.connect(_on_roster_changed)
		if not _coordinator.match_launch_received.is_connected(_on_match_launch_received):
			_coordinator.match_launch_received.connect(_on_match_launch_received)
		var b: LanDiscoveryBeacon = _coordinator.get_beacon()
		if b != null and not b.rooms_updated.is_connected(_on_lan_rooms_updated):
			b.rooms_updated.connect(_on_lan_rooms_updated)
	visible = true
	_switch_tab(true)
	_refresh_local_ip_label()


func close_lobby() -> void:
	if _coordinator != null:
		_coordinator.stop_session()
	visible = false
	lobby_closed.emit()


func _ensure_built() -> void:
	if _built:
		return
	_built = true

	var root: VBoxContainer = VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 18.0
	root.offset_top = 14.0
	root.offset_right = -18.0
	root.offset_bottom = -14.0
	root.add_theme_constant_override(&"separation", 8)
	add_child(root)

	var title_row: HBoxContainer = HBoxContainer.new()
	root.add_child(title_row)
	var title: Label = Label.new()
	title.text = "ARKADAŞLARLA OYNA (2-4 OYUNCU)"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override(&"font_size", 17)
	title.add_theme_color_override(&"font_color", NeoSteppePalette.GOLD_PALE)
	title_row.add_child(title)

	_close_btn = Button.new()
	_close_btn.text = "Geri"
	_close_btn.custom_minimum_size = Vector2(72.0, 36.0)
	OtukenThemeFactory.apply_button_semantic_styles(_close_btn, NeoSteppePalette.BRONZE_WEATHERED, false, 8, 4)
	_close_btn.pressed.connect(close_lobby)
	title_row.add_child(_close_btn)

	# Tab switcher
	var tab_row: HBoxContainer = HBoxContainer.new()
	tab_row.add_theme_constant_override(&"separation", 8)
	root.add_child(tab_row)
	_tab_host_btn = Button.new()
	_tab_host_btn.text = "Oda Kur (Kurucu)"
	_tab_host_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tab_host_btn.custom_minimum_size = Vector2(0.0, 40.0)
	_tab_host_btn.pressed.connect(_on_tab_host)
	tab_row.add_child(_tab_host_btn)

	_tab_join_btn = Button.new()
	_tab_join_btn.text = "Odaya Katıl (Wi-Fi / IP)"
	_tab_join_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tab_join_btn.custom_minimum_size = Vector2(0.0, 40.0)
	_tab_join_btn.pressed.connect(_on_tab_join)
	tab_row.add_child(_tab_join_btn)

	# HOST PANEL
	_host_box = VBoxContainer.new()
	_host_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_host_box.add_theme_constant_override(&"separation", 6)
	root.add_child(_host_box)

	_host_ip_lbl = Label.new()
	_host_ip_lbl.text = "Yerel IP: Tespit ediliyor... (Port: 7777)"
	_host_ip_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.ICE_FROST)
	_host_box.add_child(_host_ip_lbl)

	var cfg_row: HBoxContainer = HBoxContainer.new()
	cfg_row.add_theme_constant_override(&"separation", 8)
	_host_box.add_child(cfg_row)

	var code_lbl: Label = Label.new()
	code_lbl.text = "Oda Adı:"
	cfg_row.add_child(code_lbl)
	_room_code_edit = LineEdit.new()
	_room_code_edit.text = "OTUKEN-%d" % (randi() % 900 + 100)
	_room_code_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cfg_row.add_child(_room_code_edit)

	var seed_lbl: Label = Label.new()
	seed_lbl.text = "Tohum:"
	cfg_row.add_child(seed_lbl)
	_seed_spin = SpinBox.new()
	_seed_spin.min_value = 1
	_seed_spin.max_value = 999999
	_seed_spin.value = 1042
	cfg_row.add_child(_seed_spin)

	var opts_row: HBoxContainer = HBoxContainer.new()
	opts_row.add_theme_constant_override(&"separation", 12)
	_host_box.add_child(opts_row)
	_quick_match_chk = CheckBox.new()
	_quick_match_chk.text = "Hızlı Maç (20-30 dk)"
	_quick_match_chk.button_pressed = true
	opts_row.add_child(_quick_match_chk)
	_ai_fill_chk = CheckBox.new()
	_ai_fill_chk.text = "Boş slotları YZ doldur"
	_ai_fill_chk.button_pressed = true
	opts_row.add_child(_ai_fill_chk)

	_roster_lbl = Label.new()
	_roster_lbl.text = "Oyuncular: Oda henüz açılmadı."
	_roster_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_roster_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_host_box.add_child(_roster_lbl)

	var host_btns: HBoxContainer = HBoxContainer.new()
	host_btns.add_theme_constant_override(&"separation", 8)
	_host_box.add_child(host_btns)
	_host_open_btn = Button.new()
	_host_open_btn.text = "Odayı Aç (Yayınla)"
	_host_open_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_host_open_btn.custom_minimum_size = Vector2(0.0, 44.0)
	OtukenThemeFactory.apply_button_semantic_styles(_host_open_btn, NeoSteppePalette.ICE_BLUE, true, 10, 6)
	_host_open_btn.pressed.connect(_on_host_open_pressed)
	host_btns.add_child(_host_open_btn)

	_host_start_btn = Button.new()
	_host_start_btn.text = "Seferi Başlat"
	_host_start_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_host_start_btn.custom_minimum_size = Vector2(0.0, 44.0)
	_host_start_btn.disabled = true
	OtukenThemeFactory.apply_button_semantic_styles(_host_start_btn, NeoSteppePalette.JADE_PRIMARY, true, 10, 6)
	_host_start_btn.pressed.connect(_on_host_start_pressed)
	host_btns.add_child(_host_start_btn)

	# JOIN PANEL
	_join_box = VBoxContainer.new()
	_join_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_join_box.add_theme_constant_override(&"separation", 6)
	_join_box.visible = false
	root.add_child(_join_box)

	var lan_hdr: Label = Label.new()
	lan_hdr.text = "Aynı Wi-Fi'da Bulunan Odalar (Otomatik):"
	_join_box.add_child(lan_hdr)

	_lan_list = ItemList.new()
	_lan_list.custom_minimum_size = Vector2(0.0, 96.0)
	_lan_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lan_list.item_selected.connect(_on_lan_room_selected)
	_join_box.add_child(_lan_list)

	var ip_row: HBoxContainer = HBoxContainer.new()
	ip_row.add_theme_constant_override(&"separation", 8)
	_join_box.add_child(ip_row)
	_manual_ip_edit = LineEdit.new()
	_manual_ip_edit.placeholder_text = "Kurucu IP (örn. 192.168.1.25 veya VPN IP)"
	_manual_ip_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ip_row.add_child(_manual_ip_edit)
	_manual_port_spin = SpinBox.new()
	_manual_port_spin.min_value = 1024
	_manual_port_spin.max_value = 65535
	_manual_port_spin.value = 7777
	ip_row.add_child(_manual_port_spin)

	var help_lbl: Label = Label.new()
	help_lbl.text = "İpucu: İnternetten oynamak için Radmin / ZeroTier / Tailscale VPN IP'si veya 7777 UDP port yönlendirme kullanın."
	help_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help_lbl.add_theme_font_size_override(&"font_size", 11)
	help_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.TEXT_MUTED)
	_join_box.add_child(help_lbl)

	_join_connect_btn = Button.new()
	_join_connect_btn.text = "Odaya Bağlan"
	_join_connect_btn.custom_minimum_size = Vector2(0.0, 44.0)
	OtukenThemeFactory.apply_button_semantic_styles(_join_connect_btn, NeoSteppePalette.JADE_PRIMARY, true, 10, 6)
	_join_connect_btn.pressed.connect(_on_join_connect_pressed)
	_join_box.add_child(_join_connect_btn)

	_status_lbl = Label.new()
	_status_lbl.text = ""
	_status_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.GOLD_PALE)
	root.add_child(_status_lbl)


func _switch_tab(is_host_tab: bool) -> void:
	_host_box.visible = is_host_tab
	_join_box.visible = not is_host_tab
	OtukenThemeFactory.apply_button_semantic_styles(_tab_host_btn, NeoSteppePalette.ICE_BLUE, is_host_tab, 8, 4)
	OtukenThemeFactory.apply_button_semantic_styles(_tab_join_btn, NeoSteppePalette.JADE_PRIMARY, not is_host_tab, 8, 4)
	if not is_host_tab and _coordinator != null:
		_coordinator.start_lan_discovery()


func _refresh_local_ip_label() -> void:
	var ips: PackedStringArray = LanDiscoveryBeacon.get_local_lan_ips()
	var ip_str: String = ", ".join(ips) if not ips.is_empty() else "127.0.0.1"
	_host_ip_lbl.text = "Yerel Wi-Fi IP: %s  |  Port: 7777 UDP" % ip_str


func _on_tab_host() -> void:
	_switch_tab(true)


func _on_tab_join() -> void:
	_switch_tab(false)


func _on_host_open_pressed() -> void:
	if _coordinator == null:
		return
	var rname: StringName = StringName(_room_code_edit.text.strip_edges())
	if rname == &"":
		rname = &"OTUKEN"
	var ok: bool = _coordinator.host_lobby(
		rname, 7777, int(_seed_spin.value), _quick_match_chk.button_pressed, _ai_fill_chk.button_pressed)
	if ok:
		_status_lbl.text = "Oda açıldı! Arkadaşların Wi-Fi listesinde görebilir."
		_host_start_btn.disabled = false
	else:
		_status_lbl.text = "Oda açılamadı (7777 portu meşgul olabilir)."


func _on_host_start_pressed() -> void:
	if _coordinator != null:
		_coordinator.update_host_lobby_settings(
			int(_seed_spin.value), _quick_match_chk.button_pressed, _ai_fill_chk.button_pressed)
		_coordinator.host_launch_match()


func _on_lan_rooms_updated(rooms: Array[LanDiscoveryBeacon.LanRoomInfo]) -> void:
	_discovered_rooms = rooms
	_lan_list.clear()
	for r: LanDiscoveryBeacon.LanRoomInfo in rooms:
		var mode_tag: String = "Hızlı" if r.quick_match else "Uzun"
		_lan_list.add_item("%s (%s) — %d/%d Oyuncu [%s]" % [r.room_id, r.host_ip, r.player_count, r.max_players, mode_tag])


func _on_lan_room_selected(idx: int) -> void:
	if idx >= 0 and idx < _discovered_rooms.size():
		var r: LanDiscoveryBeacon.LanRoomInfo = _discovered_rooms[idx]
		_manual_ip_edit.text = r.host_ip
		_manual_port_spin.value = r.port


func _on_join_connect_pressed() -> void:
	if _coordinator == null:
		return
	var ip_str: String = _manual_ip_edit.text.strip_edges()
	if ip_str.is_empty():
		_status_lbl.text = "Lütfen kurucu IP adresi girin veya listeden oda seçin."
		return
	var port: int = int(_manual_port_spin.value)
	var ok: bool = _coordinator.join_lobby(&"OTUKEN", ip_str, port)
	_status_lbl.text = "Bağlanıldı! Kurucunun başlatması bekleniyor..." if ok else "Bağlantı başarısız oldu."


func _on_roster_changed(roster: Array[Dictionary]) -> void:
	var lines: PackedStringArray = PackedStringArray()
	for p: Dictionary in roster:
		var pid: int = DeterministicStateHasher.v_int(p.get("player_id", 1), 1)
		lines.append("• %s (Klan %d) — Hazır" % [str(p.get("name", "Oyuncu")), pid])
	_roster_lbl.text = "Oyuncular (%d/4):\n%s" % [roster.size(), "\n".join(lines)]


func _on_match_launch_received(seed: int, quick_match: bool, _pid: int, _aid: int) -> void:
	var cfg: GameShellViewModel.NewGameLaunchConfig = GameShellViewModel.NewGameLaunchConfig.new()
	cfg.session_mode = GameEnums.SessionMode.ONLINE_PERSISTENT_WORLD
	cfg.world_seed = seed
	cfg.quick_match = quick_match
	visible = false
	campaign_launch_requested.emit(cfg)
