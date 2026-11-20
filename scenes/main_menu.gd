extends Control
## Ötüken Main Menu & Real ENet LAN Lobby (rank 4).
## Live rotating 3D golden-hour steppe backdrop + Singleplayer, Wi-Fi/LAN Host & Join
## (ENetMultiplayerPeer port 7777), Mobile Graphics Settings, and Quit.

const LAN_PORT: int = 7777
const MAIN_GAME_SCENE: String = "res://scenes/main.tscn"

var _bg_viewport_root: Node3D = null
var _orbit_pivot: Node3D = null
var _orbit_angle: float = 0.0

var _main_card: TamgaCardPanel = null
var _lan_card: TamgaCardPanel = null
var _gfx_modal: GraphicsSettingsModal = null

var _host_ip_big_lbl: Label = null
var _lan_status_lbl: Label = null
var _lan_peers_lbl: Label = null
var _lan_start_btn: Button = null
var _lan_host_btn: Button = null
var _join_ip_edit: LineEdit = null
var _join_connect_btn: Button = null

var _enet_peer: ENetMultiplayerPeer = null
var _connected_peer_ids: PackedInt32Array = PackedInt32Array()
var _lan_seed: int = 1071


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = OtukenThemeFactory.create_theme()
	_build_3d_backdrop()
	_build_ui()
	_connect_multiplayer_signals()

	var saved_gfx: GraphicsQualityApplier.GraphicsConfigData = GraphicsQualityApplier.load_graphics_settings()
	GraphicsQualityApplier.apply_detailed_settings(get_tree(), saved_gfx, false)
	if AudioDirector != null:
		AudioDirector.set_music_mood(AudioDirector.MusicMood.MENU)


func _exit_tree() -> void:
	_disconnect_multiplayer_signals()


func _process(delta: float) -> void:
	if _orbit_pivot != null and is_instance_valid(_orbit_pivot):
		_orbit_angle += delta * 0.085
		_orbit_pivot.rotation.y = _orbit_angle


func _build_3d_backdrop() -> void:
	var svc: SubViewportContainer = SubViewportContainer.new()
	svc.name = "BackdropViewportContainer"
	svc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	svc.stretch = true
	svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(svc)

	var sv: SubViewport = SubViewport.new()
	sv.name = "BackdropViewport"
	sv.own_world_3d = false
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	svc.add_child(sv)

	_bg_viewport_root = Node3D.new()
	_bg_viewport_root.name = "SteppeMenuWorld"
	sv.add_child(_bg_viewport_root)

	var env: Environment = Environment.new()
	var sky: Sky = Sky.new()
	var sky_mat: ProceduralSkyMaterial = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.20, 0.28, 0.38, 1.0)
	sky_mat.sky_horizon_color = Color(0.76, 0.58, 0.38, 1.0)
	sky_mat.ground_bottom_color = Color(0.14, 0.13, 0.10, 1.0)
	sky_mat.ground_horizon_color = Color(0.55, 0.45, 0.33, 1.0)
	sky_mat.sun_angle_max = 18.0
	sky.sky_material = sky_mat
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.65
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.fog_enabled = true
	env.fog_light_color = Color(0.72, 0.58, 0.42, 1.0)
	env.fog_density = 0.008
	env.ssr_enabled = false
	env.sdfgi_enabled = false
	env.volumetric_fog_enabled = false

	var we: WorldEnvironment = WorldEnvironment.new()
	we.environment = env
	_bg_viewport_root.add_child(we)

	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.85, 0.62, 1.0)
	sun.light_energy = 1.65
	sun.shadow_enabled = true
	sun.rotation_degrees = Vector3(-24.0, 38.0, 0.0)
	_bg_viewport_root.add_child(sun)

	# Procedural steppe terrain mesh
	var terrain_mesh: ArrayMesh = _generate_menu_terrain_mesh()
	var terrain_inst: MeshInstance3D = MeshInstance3D.new()
	terrain_inst.mesh = terrain_mesh
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.92
	terrain_inst.material_override = mat
	_bg_viewport_root.add_child(terrain_inst)

	# Stylized central otag silhouette + warm campfire glow
	_spawn_menu_otag(Vector3(0.0, 1.6, 0.0))
	_spawn_menu_otag(Vector3(-8.0, 1.4, 5.0))
	_spawn_menu_otag(Vector3(9.0, 1.5, -4.0))

	_orbit_pivot = Node3D.new()
	_orbit_pivot.position = Vector3(0.0, 1.0, 0.0)
	_bg_viewport_root.add_child(_orbit_pivot)

	var cam: Camera3D = Camera3D.new()
	cam.current = true
	_orbit_pivot.add_child(cam)
	cam.look_at_from_position(Vector3(0.0, 14.0, 32.0), Vector3(0.0, 2.0, 0.0), Vector3.UP)


func _generate_menu_terrain_mesh() -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.seed = 1071
	noise.frequency = 0.025
	noise.fractal_octaves = 3

	var res: int = 44
	var span: float = 110.0
	var half: float = span * 0.5
	var step: float = span / float(res)

	for z: int in range(res):
		for x: int in range(res):
			var p00: Vector3 = _sample_menu_hill(noise, -half + float(x) * step, -half + float(z) * step)
			var p10: Vector3 = _sample_menu_hill(noise, -half + float(x + 1) * step, -half + float(z) * step)
			var p01: Vector3 = _sample_menu_hill(noise, -half + float(x) * step, -half + float(z + 1) * step)
			var p11: Vector3 = _sample_menu_hill(noise, -half + float(x + 1) * step, -half + float(z + 1) * step)
			_emit_tri(st, p00, p10, p11)
			_emit_tri(st, p00, p11, p01)

	st.generate_normals()
	return st.commit()


func _sample_menu_hill(noise: FastNoiseLite, wx: float, wz: float) -> Vector3:
	var dist: float = Vector2(wx, wz).length()
	var n: float = (noise.get_noise_2d(wx, wz) + 1.0) * 0.5
	var rim: float = maxf(0.0, (dist - 22.0) * 0.28)
	var h: float = n * 4.5 + rim * (0.6 + n)
	if dist < 14.0:
		h = lerpf(1.4, h, dist / 14.0)
	return Vector3(wx, h, wz)


func _emit_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	for p: Vector3 in [a, b, c]:
		var col: Color = Color(0.32, 0.35, 0.21, 1.0)
		if p.y > 7.0:
			col = Color(0.36, 0.34, 0.31, 1.0)
		elif p.y > 3.5:
			col = Color(0.42, 0.39, 0.24, 1.0)
		st.set_color(col)
		st.add_vertex(p)


func _spawn_menu_otag(pos: Vector3) -> void:
	var g: Node3D = Node3D.new()
	g.position = pos
	_bg_viewport_root.add_child(g)

	var body_mesh: CylinderMesh = CylinderMesh.new()
	body_mesh.top_radius = 1.65
	body_mesh.bottom_radius = 1.8
	body_mesh.height = 1.2
	var body_inst: MeshInstance3D = MeshInstance3D.new()
	body_inst.mesh = body_mesh
	body_inst.position = Vector3(0.0, 0.6, 0.0)
	var felt_mat: StandardMaterial3D = StandardMaterial3D.new()
	felt_mat.albedo_color = Color(0.76, 0.72, 0.63, 1.0)
	felt_mat.roughness = 0.92
	body_inst.material_override = felt_mat
	g.add_child(body_inst)

	var roof_mesh: CylinderMesh = CylinderMesh.new()
	roof_mesh.top_radius = 0.22
	roof_mesh.bottom_radius = 1.75
	roof_mesh.height = 1.0
	var roof_inst: MeshInstance3D = MeshInstance3D.new()
	roof_inst.mesh = roof_mesh
	roof_inst.position = Vector3(0.0, 1.7, 0.0)
	var roof_mat: StandardMaterial3D = StandardMaterial3D.new()
	roof_mat.albedo_color = Color(0.55, 0.42, 0.25, 1.0)
	roof_mat.roughness = 0.88
	roof_inst.material_override = roof_mat
	g.add_child(roof_inst)

	var fire: OmniLight3D = OmniLight3D.new()
	fire.light_color = Color(1.0, 0.56, 0.18, 1.0)
	fire.light_energy = 2.2
	fire.omni_range = 8.0
	fire.position = Vector3(0.0, 1.2, 2.2)
	g.add_child(fire)


func _build_ui() -> void:
	var vignette: ColorRect = ColorRect.new()
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.color = Color(0.03, 0.035, 0.045, 0.42)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	# --- Main Menu Card ---
	_main_card = TamgaCardPanel.new()
	_main_card.name = "MainMenuForgedCard"
	_main_card.semantic_tone = &"gold"
	_main_card.clickable = false
	_main_card.custom_minimum_size = Vector2(440.0, 420.0)
	center.add_child(_main_card)

	var m_pad: MarginContainer = _main_card.get_content_container()
	m_pad.add_theme_constant_override(&"margin_left", 24)
	m_pad.add_theme_constant_override(&"margin_right", 24)
	m_pad.add_theme_constant_override(&"margin_top", 22)
	m_pad.add_theme_constant_override(&"margin_bottom", 22)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override(&"separation", 12)
	m_pad.add_child(vbox)

	var title_lbl: Label = Label.new()
	title_lbl.text = "ÖTÜKEN"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override(&"font_size", 40)
	title_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.GOLD_TAMGA)
	vbox.add_child(title_lbl)

	var sub_lbl: Label = Label.new()
	sub_lbl.text = "BOZKIRIN HÂKİMİYETİ · GERÇEK ZAMANLI STRATEJİ"
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_font_size_override(&"font_size", 12)
	sub_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.GOLD_PALE)
	vbox.add_child(sub_lbl)

	var sep: HSeparator = HSeparator.new()
	vbox.add_child(sep)

	var btn_sp: Button = _make_menu_button("Tek Oyunculu (Sefer)", NeoSteppePalette.GOLD_TAMGA, true, _on_singleplayer_pressed)
	vbox.add_child(btn_sp)

	var btn_lan: Button = _make_menu_button("Aynı Wi-Fi / LAN Oyna", NeoSteppePalette.ICE_BLUE, false, _on_open_lan_pressed)
	vbox.add_child(btn_lan)

	var btn_gfx: Button = _make_menu_button("Grafik Ayarları", NeoSteppePalette.BRONZE_WEATHERED, false, _on_open_graphics_pressed)
	vbox.add_child(btn_gfx)

	var btn_quit: Button = _make_menu_button("Çıkış", NeoSteppePalette.EMBER_RED, false, _on_quit_pressed)
	vbox.add_child(btn_quit)

	# --- LAN / Wi-Fi Lobby Card ---
	_lan_card = TamgaCardPanel.new()
	_lan_card.name = "LanLobbyCard"
	_lan_card.semantic_tone = &"ice"
	_lan_card.clickable = false
	_lan_card.visible = false
	_lan_card.custom_minimum_size = Vector2(560.0, 470.0)
	center.add_child(_lan_card)

	var l_pad: MarginContainer = _lan_card.get_content_container()
	l_pad.add_theme_constant_override(&"margin_left", 22)
	l_pad.add_theme_constant_override(&"margin_right", 22)
	l_pad.add_theme_constant_override(&"margin_top", 18)
	l_pad.add_theme_constant_override(&"margin_bottom", 18)

	var l_box: VBoxContainer = VBoxContainer.new()
	l_box.add_theme_constant_override(&"separation", 10)
	l_pad.add_child(l_box)

	var l_hdr: HBoxContainer = HBoxContainer.new()
	l_box.add_child(l_hdr)
	var l_title: Label = Label.new()
	l_title.text = "AYNI WI-FI / LAN LOBİSİ (PORT 7777)"
	l_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l_title.add_theme_font_size_override(&"font_size", 18)
	l_title.add_theme_color_override(&"font_color", NeoSteppePalette.ICE_FROST)
	l_hdr.add_child(l_title)

	var l_back: Button = Button.new()
	l_back.text = "Geri"
	l_back.custom_minimum_size = Vector2(80.0, 40.0)
	OtukenThemeFactory.apply_button_semantic_styles(l_back, NeoSteppePalette.BRONZE_WEATHERED, false, 10, 4)
	l_back.pressed.connect(_on_lan_back_pressed)
	l_hdr.add_child(l_back)

	# Host section
	var host_panel: PanelContainer = PanelContainer.new()
	host_panel.add_theme_stylebox_override(&"panel", OtukenThemeFactory.build_card_style(
		NeoSteppePalette.GOLD_TAMGA, 1, Color(0.08, 0.10, 0.13, 0.92), 10, 8))
	l_box.add_child(host_panel)

	var h_vbox: VBoxContainer = VBoxContainer.new()
	h_vbox.add_theme_constant_override(&"separation", 6)
	host_panel.add_child(h_vbox)

	var h_lbl: Label = Label.new()
	h_lbl.text = "1. ODA KUR (HOST)"
	h_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.GOLD_PALE)
	h_vbox.add_child(h_lbl)

	_host_ip_big_lbl = Label.new()
	_host_ip_big_lbl.text = "IP: " + _get_primary_lan_ip()
	_host_ip_big_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_host_ip_big_lbl.add_theme_font_size_override(&"font_size", 24)
	_host_ip_big_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.GOLD_TAMGA)
	h_vbox.add_child(_host_ip_big_lbl)

	var h_btns: HBoxContainer = HBoxContainer.new()
	h_btns.add_theme_constant_override(&"separation", 8)
	h_vbox.add_child(h_btns)

	_lan_host_btn = _make_menu_button("Oda Kur (Host)", NeoSteppePalette.ICE_BLUE, true, _on_lan_host_pressed)
	_lan_host_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h_btns.add_child(_lan_host_btn)

	_lan_start_btn = _make_menu_button("Maçı Başlat", NeoSteppePalette.JADE_PRIMARY, true, _on_lan_start_pressed)
	_lan_start_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lan_start_btn.disabled = true
	h_btns.add_child(_lan_start_btn)

	_lan_peers_lbl = Label.new()
	_lan_peers_lbl.text = "Durum: Oda henüz kurulmadı."
	_lan_peers_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.TEXT_MUTED)
	h_vbox.add_child(_lan_peers_lbl)

	# Join section
	var join_panel: PanelContainer = PanelContainer.new()
	join_panel.add_theme_stylebox_override(&"panel", OtukenThemeFactory.build_card_style(
		NeoSteppePalette.JADE_PRIMARY, 1, Color(0.08, 0.10, 0.13, 0.92), 10, 8))
	l_box.add_child(join_panel)

	var j_vbox: VBoxContainer = VBoxContainer.new()
	j_vbox.add_theme_constant_override(&"separation", 6)
	join_panel.add_child(j_vbox)

	var j_lbl: Label = Label.new()
	j_lbl.text = "2. ODAYA KATIL (JOIN)"
	j_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.JADE_BRIGHT)
	j_vbox.add_child(j_lbl)

	var j_row: HBoxContainer = HBoxContainer.new()
	j_row.add_theme_constant_override(&"separation", 8)
	j_vbox.add_child(j_row)

	_join_ip_edit = LineEdit.new()
	_join_ip_edit.placeholder_text = "Kurucu Yerel IP (örn. 192.168.1.35)"
	_join_ip_edit.text = "127.0.0.1"
	_join_ip_edit.custom_minimum_size = Vector2(240.0, 48.0)
	_join_ip_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	j_row.add_child(_join_ip_edit)

	_join_connect_btn = _make_menu_button("Bağlan", NeoSteppePalette.JADE_PRIMARY, true, _on_lan_join_pressed)
	_join_connect_btn.custom_minimum_size = Vector2(130.0, 48.0)
	j_row.add_child(_join_connect_btn)

	_lan_status_lbl = Label.new()
	_lan_status_lbl.text = "İki cihazı aynı Wi-Fi ağına bağlayın veya IP girin."
	_lan_status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lan_status_lbl.add_theme_color_override(&"font_color", NeoSteppePalette.GOLD_PALE)
	l_box.add_child(_lan_status_lbl)

	_gfx_modal = GraphicsSettingsModal.new()
	add_child(_gfx_modal)


func _make_menu_button(txt: String, col: Color, highlighted: bool, cb: Callable) -> Button:
	var btn: Button = Button.new()
	btn.text = txt
	btn.custom_minimum_size = Vector2(0.0, 56.0)
	OtukenThemeFactory.apply_button_semantic_styles(btn, col, highlighted, 14, 8)
	btn.pressed.connect(cb)
	return btn


func _get_primary_lan_ip() -> String:
	var candidates: PackedStringArray = PackedStringArray()
	for addr: String in IP.get_local_addresses():
		if addr.begins_with("192.168.") or addr.begins_with("10."):
			candidates.append(addr)
		elif addr.begins_with("172."):
			var parts: PackedStringArray = addr.split(".")
			if parts.size() >= 2:
				var second: int = parts[1].to_int()
				if second >= 16 and second <= 31:
					candidates.append(addr)
	if not candidates.is_empty():
		return " / ".join(candidates)
	return "127.0.0.1"


func _on_singleplayer_pressed() -> void:
	_close_enet()
	MatchSessionConfig.reset_to_singleplayer(1071, 1)
	get_tree().change_scene_to_file(MAIN_GAME_SCENE)


func _on_open_lan_pressed() -> void:
	_main_card.visible = false
	_lan_card.visible = true
	_host_ip_big_lbl.text = "YEREL IP: " + _get_primary_lan_ip()


func _on_lan_back_pressed() -> void:
	_close_enet()
	_lan_card.visible = false
	_main_card.visible = true


func _on_open_graphics_pressed() -> void:
	_gfx_modal.open_modal()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_lan_host_pressed() -> void:
	_close_enet()
	_enet_peer = ENetMultiplayerPeer.new()
	var err: Error = _enet_peer.create_server(LAN_PORT, 4)
	if err != OK:
		_enet_peer = null
		_lan_status_lbl.text = "Hata: Port %d açılamadı (%d)." % [LAN_PORT, err]
		return
	get_tree().get_multiplayer().multiplayer_peer = _enet_peer
	_connected_peer_ids.clear()
	_connected_peer_ids.append(1)
	_host_ip_big_lbl.text = "YEREL IP: " + _get_primary_lan_ip()
	_lan_peers_lbl.text = "Kurucu Hazır (1 Oyuncu). Arkadaşının bağlanması bekleniyor..."
	_lan_status_lbl.text = "Sunucu açık (Port %d). İstediğin an maçı başlatabilirsin." % LAN_PORT
	_lan_start_btn.disabled = false


func _on_lan_join_pressed() -> void:
	var ip_txt: String = _join_ip_edit.text.strip_edges()
	if ip_txt.is_empty():
		_lan_status_lbl.text = "Lütfen kurucu IP adresini girin."
		return
	_close_enet()
	_enet_peer = ENetMultiplayerPeer.new()
	var err: Error = _enet_peer.create_client(ip_txt, LAN_PORT)
	if err != OK:
		_enet_peer = null
		_lan_status_lbl.text = "Bağlantı başlatılamadı (%d)." % err
		return
	get_tree().get_multiplayer().multiplayer_peer = _enet_peer
	_lan_status_lbl.text = "%s:%d adresine bağlanılıyor..." % [ip_txt, LAN_PORT]


func _on_lan_start_pressed() -> void:
	if _enet_peer == null or not get_tree().get_multiplayer().is_server():
		return
	_rpc_launch_lan_match.rpc(_lan_seed)


@rpc("authority", "call_local", "reliable")
func _rpc_launch_lan_match(seed_val: int) -> void:
	var mp: MultiplayerAPI = get_tree().get_multiplayer()
	if mp.is_server():
		MatchSessionConfig.configure_lan_host(seed_val, LAN_PORT)
	else:
		MatchSessionConfig.configure_lan_client(_join_ip_edit.text.strip_edges(), seed_val, LAN_PORT)
	get_tree().change_scene_to_file(MAIN_GAME_SCENE)


func _connect_multiplayer_signals() -> void:
	var mp: MultiplayerAPI = get_tree().get_multiplayer()
	if mp == null:
		return
	if not mp.peer_connected.is_connected(_on_mp_peer_connected):
		mp.peer_connected.connect(_on_mp_peer_connected)
	if not mp.peer_disconnected.is_connected(_on_mp_peer_disconnected):
		mp.peer_disconnected.connect(_on_mp_peer_disconnected)
	if not mp.connected_to_server.is_connected(_on_mp_connected_to_server):
		mp.connected_to_server.connect(_on_mp_connected_to_server)
	if not mp.connection_failed.is_connected(_on_mp_connection_failed):
		mp.connection_failed.connect(_on_mp_connection_failed)


func _disconnect_multiplayer_signals() -> void:
	if not is_inside_tree():
		return
	var mp: MultiplayerAPI = get_tree().get_multiplayer()
	if mp == null:
		return
	if mp.peer_connected.is_connected(_on_mp_peer_connected):
		mp.peer_connected.disconnect(_on_mp_peer_connected)
	if mp.peer_disconnected.is_connected(_on_mp_peer_disconnected):
		mp.peer_disconnected.disconnect(_on_mp_peer_disconnected)
	if mp.connected_to_server.is_connected(_on_mp_connected_to_server):
		mp.connected_to_server.disconnect(_on_mp_connected_to_server)
	if mp.connection_failed.is_connected(_on_mp_connection_failed):
		mp.connection_failed.disconnect(_on_mp_connection_failed)


func _on_mp_peer_connected(id: int) -> void:
	if not _connected_peer_ids.has(id):
		_connected_peer_ids.append(id)
	_lan_peers_lbl.text = "Bağlı Oyuncular: %d (Kurucu + %d)" % [_connected_peer_ids.size(), maxi(_connected_peer_ids.size() - 1, 0)]
	_lan_status_lbl.text = "Oyuncu bağlandı (ID: %d)! Maçı başlatabilirsiniz." % id


func _on_mp_peer_disconnected(id: int) -> void:
	var idx: int = _connected_peer_ids.find(id)
	if idx >= 0:
		_connected_peer_ids.remove_at(idx)
	_lan_peers_lbl.text = "Bağlı Oyuncular: %d" % _connected_peer_ids.size()
	_lan_status_lbl.text = "Oyuncu ayrıldı (ID: %d)." % id


func _on_mp_connected_to_server() -> void:
	_lan_status_lbl.text = "Kurucuya bağlanıldı! Maçın başlatılması bekleniyor..."
	_lan_peers_lbl.text = "Bağlantı aktif · Kırmızı/Kuzeydoğu Boyu"


func _on_mp_connection_failed() -> void:
	_lan_status_lbl.text = "Bağlantı başarısız! IP ve aynı Wi-Fi ağını kontrol edin."
	_close_enet()


func _close_enet() -> void:
	if _enet_peer != null:
		_enet_peer.close()
		_enet_peer = null
	if is_inside_tree():
		var mp: MultiplayerAPI = get_tree().get_multiplayer()
		if mp != null:
			mp.multiplayer_peer = null
	_connected_peer_ids.clear()
	if _lan_start_btn != null:
		_lan_start_btn.disabled = true
	if _lan_peers_lbl != null:
		_lan_peers_lbl.text = "Durum: Oda henüz kurulmadı."
