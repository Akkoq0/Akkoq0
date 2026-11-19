class_name SaveLoadRepository
extends RefCounted
## Core repository (rank 2). Persists and restores `WorldSnapshotSerializer`
## packages with `schema_version` and SHA-256 `world_hash` integrity checks.
## Corrupted JSON, mismatched schema, or tampered hashes return `false` without
## mutating live world state.

const SCHEMA_VERSION: int = 1


static func serialize_save_package() -> String:
	var state: Dictionary = WorldSnapshotSerializer.export_state_dict()
	var world_hash: String = DeterministicStateHasher.compute_world_hash(state)
	var pkg: Dictionary = {
		"schema_version": SCHEMA_VERSION,
		"state": state,
		"world_hash": world_hash,
	}
	EventBus.world_state_saved.emit(world_hash, SCHEMA_VERSION)
	return JSON.stringify(pkg)


static func load_save_package(json_text: String) -> bool:
	if json_text.strip_edges().is_empty():
		return false
	var jp: JSON = JSON.new()
	if jp.parse(json_text) != OK:
		return false
	var parsed: Variant = jp.data
	if not (parsed is Dictionary):
		return false
	var pkg: Dictionary = DeterministicStateHasher.v_dict(parsed)
	if DeterministicStateHasher.v_int(pkg.get("schema_version", -1), -1) != SCHEMA_VERSION:
		return false
	var expected_hash: String = DeterministicStateHasher.v_str(pkg.get("world_hash", ""))
	if expected_hash.length() != 64:
		return false
	var state_var: Variant = pkg.get("state")
	if not (state_var is Dictionary):
		return false
	var state_dict: Dictionary = DeterministicStateHasher.v_dict(state_var)
	if not WorldSnapshotSerializer.validate_state_dict(state_dict):
		return false
	var actual_hash: String = DeterministicStateHasher.compute_world_hash(state_dict)
	if actual_hash != expected_hash:
		return false
	var ok: bool = WorldSnapshotSerializer.import_state_dict(state_dict)
	if ok:
		EventBus.world_state_loaded.emit(actual_hash, SCHEMA_VERSION)
	return ok


static func save_to_file(path: String) -> bool:
	var payload: String = serialize_save_package()
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(payload)
	file.close()
	return true


static func load_from_file(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var content: String = FileAccess.get_file_as_string(path)
	return load_save_package(content)
