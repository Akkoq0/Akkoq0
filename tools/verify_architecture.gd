class_name ArchitectureVerifier
extends RefCounted
## Static architecture & governance verifier (rank 4).
##
## Audits every `.gd`, `.tres` and `.tscn` file in the repository for:
##  1. Strict static typing (no untyped `var`, `const`, parameter, or missing `-> ReturnType`).
##  2. Acyclic class dependency graph (0 cycles across all `class_name` scripts).
##  3. Layer rank discipline (Foundation=0 -> Data=1 -> Core=2 -> Domain=3 -> Scene=4).
##  4. Resource & scene loadability + schema validation (7 ores, 8 totems on a
##     100-point asymmetrical budget, buildings with ROI, terrain, seasons,
##     camera 0.4 s profile, world configs).

const LAYER_RANKS: Dictionary[String, int] = {
	"res://core/types/": 0,
	"res://data/": 1,
	"res://core/": 2,
	"res://world/": 3,
	"res://units/": 3,
	"res://camera/": 3,
	"res://buildings/": 3,
	"res://input/": 3,
	"res://scenes/": 4,
	"res://tools/": 4,
	"res://tests/": 4,
}


static func run_all_checks() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	var scripts: PackedStringArray = _collect_files("res://", ".gd")
	var resources: PackedStringArray = _collect_files("res://", ".tres")
	var scenes: PackedStringArray = _collect_files("res://", ".tscn")

	errors.append_array(_check_static_typing(scripts))
	errors.append_array(_check_dependency_dag(scripts))
	errors.append_array(_check_resources(resources))
	errors.append_array(_check_scenes(scenes))
	return errors


static func _collect_files(root_dir: String, suffix: String) -> PackedStringArray:
	var found: PackedStringArray = PackedStringArray()
	var dir: DirAccess = DirAccess.open(root_dir)
	if dir == null:
		return found
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while not entry.is_empty():
		if not entry.begins_with("."):
			var full_path: String = root_dir.path_join(entry) if root_dir != "res://" else "res://" + entry
			if dir.current_is_dir():
				found.append_array(_collect_files(full_path, suffix))
			elif entry.ends_with(suffix):
				found.append(full_path)
		entry = dir.get_next()
	dir.list_dir_end()
	found.sort()
	return found


static func _check_static_typing(scripts: PackedStringArray) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	var func_regex: RegEx = RegEx.new()
	func_regex.compile("^\\s*(?:static\\s+)?func\\s+([A-Za-z0-9_]+)\\s*\\(([^)]*)\\)\\s*(->\\s*[A-Za-z0-9_\\[\\],\\s\\.]+)?\\s*:")
	var var_regex: RegEx = RegEx.new()
	var_regex.compile("^\\s*(?:@export[^\\n]*\\s+)?(?:static\\s+)?(var|const)\\s+([A-Za-z0-9_]+)\\s*(:)?")
	var inferred_token: String = ":" + "="

	for path: String in scripts:
		var loaded_script: Script = ResourceLoader.load(path) as Script
		if loaded_script == null or not loaded_script.can_instantiate():
			errors.append("Script failed to compile under strict Godot 4.7 typing: %s" % path)
		var source: String = FileAccess.get_file_as_string(path)
		var lines: PackedStringArray = source.split("\n")
		for i: int in range(lines.size()):
			var raw: String = lines[i]
			var stripped: String = raw.strip_edges()
			if stripped.is_empty() or stripped.begins_with("#"):
				continue
			if raw.find(inferred_token) != -1:
				errors.append("%s:%d uses inferred type operator instead of explicit annotation." % [path, i + 1])
			var var_match: RegExMatch = var_regex.search(raw)
			if var_match != null and var_match.get_string(3) != ":":
				errors.append("%s:%d untyped %s '%s'." % [path, i + 1, var_match.get_string(1), var_match.get_string(2)])
			var func_match: RegExMatch = func_regex.search(raw)
			if func_match != null:
				var fname: String = func_match.get_string(1)
				var params: String = func_match.get_string(2).strip_edges()
				var ret: String = func_match.get_string(3).strip_edges()
				if fname != "_init" and ret.is_empty():
					errors.append("%s:%d func '%s' is missing explicit '-> ReturnType'." % [path, i + 1, fname])
				for param: String in _split_top_level_params(params):
					if param.find(":") == -1:
						errors.append("%s:%d func '%s' has untyped parameter '%s'." % [path, i + 1, fname, param])
	return errors


static func _split_top_level_params(params: String) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	if params.is_empty():
		return result
	var depth: int = 0
	var current: String = ""
	for i: int in range(params.length()):
		var ch: String = params.substr(i, 1)
		if ch == "[":
			depth += 1
			current += ch
		elif ch == "]":
			depth = maxi(depth - 1, 0)
			current += ch
		elif ch == "," and depth == 0:
			result.append(current.strip_edges())
			current = ""
		else:
			current += ch
	if not current.strip_edges().is_empty():
		result.append(current.strip_edges())
	return result


static func _strip_comments(source: String) -> String:
	var cleaned: PackedStringArray = PackedStringArray()
	for line: String in source.split("\n"):
		var hash_idx: int = line.find("#")
		if hash_idx != -1:
			cleaned.append(line.substr(0, hash_idx))
		else:
			cleaned.append(line)
	return "\n".join(cleaned)


static func _check_dependency_dag(scripts: PackedStringArray) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	var class_to_path: Dictionary[String, String] = {}
	var class_regex: RegEx = RegEx.new()
	class_regex.compile("(?m)^class_name\\s+([A-Za-z0-9_]+)")

	for path: String in scripts:
		var source: String = FileAccess.get_file_as_string(path)
		var m: RegExMatch = class_regex.search(source)
		if m != null:
			class_to_path[m.get_string(1)] = path

	var edges: Dictionary[String, PackedStringArray] = {}
	for path: String in scripts:
		var code_only: String = _strip_comments(FileAccess.get_file_as_string(path))
		var deps: PackedStringArray = PackedStringArray()
		var from_rank: int = _rank_for_path(path)
		for cname: String in class_to_path:
			var target_path: String = class_to_path[cname]
			if target_path == path:
				continue
			var token_regex: RegEx = RegEx.new()
			token_regex.compile("\\b" + cname + "\\b")
			if token_regex.search(code_only) != null:
				deps.append(target_path)
				var to_rank: int = _rank_for_path(target_path)
				if to_rank > from_rank:
					errors.append("Layer violation: %s (rank %d) depends on %s (rank %d)." % [path, from_rank, target_path, to_rank])
		edges[path] = deps

	var state: Dictionary[String, int] = {}
	for path: String in scripts:
		state[path] = 0
	for path: String in scripts:
		if state[path] == 0 and _has_cycle(path, edges, state):
			errors.append("Circular dependency detected involving %s." % path)
	return errors


static func _has_cycle(node: String, edges: Dictionary[String, PackedStringArray], state: Dictionary[String, int]) -> bool:
	state[node] = 1
	var neighbours: PackedStringArray = edges.get(node, PackedStringArray())
	for next_node: String in neighbours:
		var next_state: int = state.get(next_node, 0)
		if next_state == 1:
			return true
		if next_state == 0 and _has_cycle(next_node, edges, state):
			return true
	state[node] = 2
	return false


static func _rank_for_path(path: String) -> int:
	if path.begins_with("res://core/types/"):
		return 0
	for prefix: String in LAYER_RANKS:
		if prefix != "res://core/types/" and path.begins_with(prefix):
			return LAYER_RANKS[prefix]
	return 4


static func _check_resources(resources: PackedStringArray) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	for path: String in resources:
		var res: Resource = ResourceLoader.load(path)
		if res == null:
			errors.append("Failed to load resource: %s" % path)
			continue
		if res is OreData:
			errors.append_array((res as OreData).get_validation_errors())
		elif res is OreRegistry:
			errors.append_array((res as OreRegistry).get_validation_errors())
		elif res is BuildingData:
			errors.append_array((res as BuildingData).get_validation_errors())
		elif res is TotemRoster:
			errors.append_array((res as TotemRoster).get_validation_errors())
		elif res is TerrainData:
			errors.append_array((res as TerrainData).get_validation_errors())
		elif res is SeasonData:
			errors.append_array((res as SeasonData).get_validation_errors())
		elif res is SeasonCycle:
			errors.append_array((res as SeasonCycle).get_validation_errors())
		elif res is UnitData:
			errors.append_array((res as UnitData).get_validation_errors())
		elif res is ArmyTemplate:
			errors.append_array((res as ArmyTemplate).get_validation_errors())
		elif res is MacroWorldConfig:
			errors.append_array((res as MacroWorldConfig).get_validation_errors())
		elif res is MicroZoneConfig:
			errors.append_array((res as MicroZoneConfig).get_validation_errors())
		elif res is RefiningRecipe:
			errors.append_array((res as RefiningRecipe).get_validation_errors())
		elif res is EconomyRules:
			errors.append_array((res as EconomyRules).get_validation_errors())
		elif res is KutRules:
			errors.append_array((res as KutRules).get_validation_errors())
		elif res is ToyDistributionRules:
			errors.append_array((res as ToyDistributionRules).get_validation_errors())
		elif res is TacticalDoctrineData:
			errors.append_array((res as TacticalDoctrineData).get_validation_errors())
		elif res is SupplyConvoyData:
			errors.append_array((res as SupplyConvoyData).get_validation_errors())
		elif res is DiplomacyRules:
			errors.append_array((res as DiplomacyRules).get_validation_errors())
		elif res is DynastyProfile:
			errors.append_array((res as DynastyProfile).get_validation_errors())
		elif res is CouncilCrisisEvent:
			errors.append_array((res as CouncilCrisisEvent).get_validation_errors())
		elif res is WorkerGatheringProfile:
			errors.append_array((res as WorkerGatheringProfile).get_validation_errors())
		elif res is AIBehaviorProfile:
			errors.append_array((res as AIBehaviorProfile).get_validation_errors())
		elif res is PastureData:
			errors.append_array((res as PastureData).get_validation_errors())
		elif res is BallisticsRules:
			errors.append_array((res as BallisticsRules).get_validation_errors())
		elif res is CaptiveLaborRules:
			errors.append_array((res as CaptiveLaborRules).get_validation_errors())
		elif res is SovereigntyProfileData:
			errors.append_array((res as SovereigntyProfileData).get_validation_errors())
		elif res is EmergentWorldRules:
			errors.append_array((res as EmergentWorldRules).get_validation_errors())
		elif res is CataclysmEventData:
			errors.append_array((res as CataclysmEventData).get_validation_errors())
		elif res is KinshipIntrigueRules:
			errors.append_array((res as KinshipIntrigueRules).get_validation_errors())
		elif res is AttritionCasualtyProfile:
			errors.append_array((res as AttritionCasualtyProfile).get_validation_errors())
		elif res is CausalFrictionCalibration:
			errors.append_array((res as CausalFrictionCalibration).get_validation_errors())
		elif res is PersistentWorldRules:
			errors.append_array((res as PersistentWorldRules).get_validation_errors())
		elif res is ConquestRules:
			errors.append_array((res as ConquestRules).get_validation_errors())
		elif res is CollapseRecoveryRules:
			errors.append_array((res as CollapseRecoveryRules).get_validation_errors())
		elif res is CourierAndCaravanRules:
			errors.append_array((res as CourierAndCaravanRules).get_validation_errors())
	return errors


static func _check_scenes(scenes: PackedStringArray) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	for path: String in scenes:
		var packed: PackedScene = ResourceLoader.load(path) as PackedScene
		if packed == null or not packed.can_instantiate():
			errors.append("Failed to load or instantiate scene: %s" % path)
	return errors
