extends Node
## Headless Night Behavior & UI Audit (rank 4).
## Run with: `godot --headless --path . res://tests/night_behavior_audit.tscn`
## Simulates 120 seconds of real-time RTS play (player build/train, active AI
## economy/building/training/raid, CombatCalculator damage, and HUD non-overlap
## at 1920x1080 and 1600x720).

var _failures: PackedStringArray = PackedStringArray()
var _assertions: int = 0
var _combat_hits: int = 0
var _total_damage: float = 0.0
var _first_combat_sec: float = -1.0
var _sim_clock: float = 0.0


func _ready() -> void:
	_run_audit.call_deferred()


func _expect(cond: bool, msg: String) -> void:
	_assertions += 1
	if not cond:
		_failures.append(msg)


func _on_combat_hit(_atk_id: int, _tgt_id: int, dmg: float, _pos: Vector3, _ranged: bool) -> void:
	_combat_hits += 1
	_total_damage += dmg
	if _first_combat_sec < 0.0:
		_first_combat_sec = _sim_clock


func _run_audit() -> void:
	MatchSessionConfig.reset_to_singleplayer(1071, 1)
	var packed: PackedScene = ResourceLoader.load("res://scenes/main.tscn") as PackedScene
	_expect(packed != null, "Main scene loads for night behavior audit.")
	var main_node: Node = packed.instantiate()
	add_child(main_node)

	var bfm: RtsBattlefieldManager = main_node.get_node_or_null("RtsBattlefieldManager") as RtsBattlefieldManager
	var hud: MobileRtsHud = main_node.get_node_or_null("HudLayer/MobileRtsHud") as MobileRtsHud
	_expect(bfm != null and hud != null, "RtsBattlefieldManager and MobileRtsHud mounted in main.tscn.")

	if bfm == null or hud == null:
		_finish(main_node)
		return

	EventBus.rts_combat_hit.connect(_on_combat_hit)

	# 1. Player Building & Economy Verification
	var p1_econ: RtsBattlefieldManager.FactionEconomy = bfm.get_economy(1)
	var stone_before: int = p1_econ.stone
	var build_ok: bool = bfm.issue_build_command(1, &"ger_camp", Vector3(-24.0, 0.0, 26.0))
	_expect(build_ok and p1_econ.stone == stone_before - 60,
		"Player can place ger_camp and spend 60 stone (%d -> %d)." % [stone_before, p1_econ.stone])

	var train_ok: bool = bfm.issue_train_command(1, &"horse_archer", 100)
	_expect(train_ok, "Player can train Horse Archer from Head Otag.")

	# Step 10 seconds to verify real-time resource production
	var food_before: int = p1_econ.food
	for _i: int in range(20):
		_sim_clock += 0.5
		bfm.step_simulation(0.5)
	_expect(p1_econ.food > food_before,
		"Economy produces real-time food (%d -> %d)." % [food_before, p1_econ.food])

	# 2. 120-Second Accelerated Simulation (AI build, AI train, AI raid, real combat HP loss)
	var ai_first_build_sec: float = -1.0
	var ai_first_train_sec: float = -1.0
	var ai_unit_moved: bool = false
	var step_dt: float = 0.5
	var total_steps: int = 240
	for _s: int in range(total_steps):
		_sim_clock += step_dt
		bfm.step_simulation(step_dt)
		if ai_first_build_sec < 0.0 and bfm.get_buildings_built_count(2) >= 1:
			ai_first_build_sec = _sim_clock
		if ai_first_train_sec < 0.0 and bfm.get_units_trained_count(2) >= 1:
			ai_first_train_sec = _sim_clock
		if _combat_hits > 0:
			ai_unit_moved = true

	_expect(bfm.get_buildings_built_count(2) >= 1,
		"AI constructed >= 1 building within 120s (built=%d, t=%.1fs)." % [bfm.get_buildings_built_count(2), ai_first_build_sec])
	_expect(bfm.get_units_trained_count(2) >= 1,
		"AI trained >= 1 unit within 120s (trained=%d, t=%.1fs)." % [bfm.get_units_trained_count(2), ai_first_train_sec])
	_expect(ai_unit_moved and _combat_hits > 0 and _total_damage > 0.0,
		"Real combat triggered & HP reduced (hits=%d, total_dmg=%.1f, first_t=%.1fs)." % [_combat_hits, _total_damage, _first_combat_sec])

	# 3. Geometry Grounding Audit (0 floating or buried entities)
	var y_errs: PackedStringArray = bfm.get_all_entity_y_errors()
	_expect(y_errs.is_empty(), "All buildings and units sit strictly at get_height_at(x, z) (%d errors)." % y_errs.size())

	# 4. HUD Overlap Audit at 1920x1080 and 1600x720
	for res: Vector2 in [Vector2(1920.0, 1080.0), Vector2(1600.0, 720.0)]:
		get_tree().root.size = Vector2i(int(res.x), int(res.y))
		hud.set_context_build()
		await get_tree().process_frame
		await get_tree().process_frame
		_check_hud_no_overlap(hud, res, "build")
		hud.set_context_army("Bölük\nHP 110/110")
		await get_tree().process_frame
		await get_tree().process_frame
		_check_hud_no_overlap(hud, res, "army")

	EventBus.rts_combat_hit.disconnect(_on_combat_hit)

	print("[AUDIT] AI_Build=%.1fs | AI_Train=%.1fs | First_Combat=%.1fs | Hits=%d | TotalDmg=%.1f" % [
		ai_first_build_sec, ai_first_train_sec, _first_combat_sec, _combat_hits, _total_damage
	])
	_finish(main_node)


func _check_hud_no_overlap(hud: MobileRtsHud, res: Vector2, ctx_name: String) -> void:
	var btns: Array[Button] = hud.collect_visible_buttons()
	var rects: Array[Rect2] = []
	var names: Array[String] = []
	for b: Button in btns:
		var r: Rect2 = b.get_global_rect()
		if r.size.x > 1.0 and r.size.y > 1.0:
			rects.append(r)
			names.append(b.text.replace("\n", " "))
	var overlap_found: bool = false
	var overlap_desc: String = ""
	for i: int in range(rects.size()):
		for j: int in range(i + 1, rects.size()):
			var shrunk_a: Rect2 = rects[i].grow(-1.0)
			var shrunk_b: Rect2 = rects[j].grow(-1.0)
			if shrunk_a.intersects(shrunk_b):
				overlap_found = true
				overlap_desc = "'%s' %s vs '%s' %s" % [names[i], rects[i], names[j], rects[j]]
				break
		if overlap_found:
			break
	_expect(not overlap_found, "HUD %s buttons have 0 overlap at %.0fx%.0f (%s)." % [ctx_name, res.x, res.y, overlap_desc])


func _finish(main_node: Node) -> void:
	if main_node != null:
		remove_child(main_node)
		main_node.free()
	if _failures.is_empty():
		print("[PASS] Night Behavior & HUD Audit succeeded (%d assertions, 0 failures)." % _assertions)
		get_tree().quit(0)
	else:
		for f: String in _failures:
			push_error("[FAIL] %s" % f)
		get_tree().quit(1)
