class_name MatchSessionConfig
extends RefCounted
## Core Match Session Config (rank 2). Carries Singleplayer / LAN Multiplayer
## launch parameters cleanly across scene transitions (`main_menu.tscn` -> `main.tscn`).

enum LaunchMode { SINGLEPLAYER, LAN_HOST, LAN_CLIENT }

static var active_mode: LaunchMode = LaunchMode.SINGLEPLAYER
static var local_player_id: int = 1
static var world_seed: int = 1071
static var ai_difficulty: int = 1
static var host_ip: String = "127.0.0.1"
static var port: int = 7777
static var quick_match: bool = false


static func reset_to_singleplayer(seed_val: int = 1071, difficulty: int = 1) -> void:
	active_mode = LaunchMode.SINGLEPLAYER
	local_player_id = 1
	world_seed = maxi(seed_val, 1)
	ai_difficulty = clampi(difficulty, 0, 3)
	host_ip = "127.0.0.1"
	port = 7777
	quick_match = false


static func configure_lan_host(seed_val: int = 1071, p_port: int = 7777) -> void:
	active_mode = LaunchMode.LAN_HOST
	local_player_id = 1
	world_seed = maxi(seed_val, 1)
	port = clampi(p_port, 1024, 65535)
	host_ip = "127.0.0.1"


static func configure_lan_client(ip_addr: String, seed_val: int = 1071, p_port: int = 7777) -> void:
	active_mode = LaunchMode.LAN_CLIENT
	local_player_id = 2
	world_seed = maxi(seed_val, 1)
	host_ip = ip_addr.strip_edges()
	port = clampi(p_port, 1024, 65535)


static func is_multiplayer_session() -> bool:
	return active_mode != LaunchMode.SINGLEPLAYER
