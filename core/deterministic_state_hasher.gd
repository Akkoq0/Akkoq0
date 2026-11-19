class_name DeterministicStateHasher
extends RefCounted
## Core hasher (rank 2). Produces canonical key-sorted JSON representations and
## bit-for-bit deterministic SHA-256 hashes of serialized world state dicts.


static func canonicalize(value: Variant) -> Variant:
	if value is Dictionary:
		var src_dict: Dictionary = value
		var keys: Array = src_dict.keys()
		keys.sort_custom(func(a: Variant, b: Variant) -> bool:
			return var_to_str(a) < var_to_str(b)
		)
		var out_dict: Dictionary = {}
		for k: Variant in keys:
			var ks: String = v_str(k, "")
			if ks.is_empty():
				ks = var_to_str(k)
			out_dict[ks] = canonicalize(src_dict[k])
		return out_dict
	if value is Array:
		var src_arr: Array = value
		var out_arr: Array = []
		for item: Variant in src_arr:
			out_arr.append(canonicalize(item))
		return out_arr
	if value is PackedStringArray:
		var p_str: PackedStringArray = value
		var out_p_str: Array = []
		for s: String in p_str:
			out_p_str.append(s)
		return out_p_str
	if value is PackedInt32Array:
		var p_int: PackedInt32Array = value
		var out_p_int: Array = []
		for iv: int in p_int:
			out_p_int.append(iv)
		return out_p_int
	if value is int:
		var iv: int = value
		return String.num_int64(iv)
	if value is float:
		var f: float = value
		if is_nan(f):
			return "NAN"
		if is_inf(f):
			return "INF" if f > 0.0 else "-INF"
		var snapped: float = snappedf(f, 0.0001)
		if is_zero_approx(snapped):
			snapped = 0.0
		var rounded: int = roundi(snapped)
		if is_equal_approx(snapped, float(rounded)) and absf(snapped) < 2147483647.0:
			return String.num_int64(rounded)
		return String.num(snapped, 4)
	if value is Vector2i:
		var v2i: Vector2i = value
		return {"x": String.num_int64(v2i.x), "y": String.num_int64(v2i.y)}
	if value is Vector3:
		var v3: Vector3 = value
		return {
			"x": canonicalize(v3.x),
			"y": canonicalize(v3.y),
			"z": canonicalize(v3.z),
		}
	if value is StringName:
		var sn: StringName = value
		return String(sn)
	return value


static func canonical_json(state_dict: Dictionary) -> String:
	var canon: Variant = canonicalize(state_dict)
	return JSON.stringify(canon, "", true)


static func compute_world_hash(state_dict: Dictionary) -> String:
	var payload: String = canonical_json(state_dict)
	var ctx: HashingContext = HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(payload.to_utf8_buffer())
	var digest: PackedByteArray = ctx.finish()
	return digest.hex_encode()


static func v_int(val: Variant, fallback: int = 0) -> int:
	if typeof(val) == TYPE_INT:
		var iv: int = val
		return iv
	if typeof(val) == TYPE_FLOAT:
		var fv: float = val
		return int(fv)
	if typeof(val) == TYPE_BOOL:
		var bv: bool = val
		return 1 if bv else 0
	if typeof(val) == TYPE_STRING:
		var sv: String = val
		if sv.is_valid_int():
			return sv.to_int()
		if sv.is_valid_float():
			return int(sv.to_float())
	return fallback


static func v_float(val: Variant, fallback: float = 0.0) -> float:
	if typeof(val) == TYPE_FLOAT:
		var fv: float = val
		return fv
	if typeof(val) == TYPE_INT:
		var iv: int = val
		return float(iv)
	if typeof(val) == TYPE_STRING:
		var sv: String = val
		if sv.is_valid_float():
			return sv.to_float()
	return fallback


static func v_bool(val: Variant, fallback: bool = false) -> bool:
	if typeof(val) == TYPE_BOOL:
		var bv: bool = val
		return bv
	if typeof(val) == TYPE_INT:
		var iv: int = val
		return iv != 0
	return fallback


static func v_str(val: Variant, fallback: String = "") -> String:
	if typeof(val) == TYPE_STRING:
		var sv: String = val
		return sv
	if typeof(val) == TYPE_STRING_NAME:
		var sn: StringName = val
		return String(sn)
	return fallback


static func v_dict(val: Variant) -> Dictionary:
	if typeof(val) == TYPE_DICTIONARY:
		var dv: Dictionary = val
		return dv
	return {}


static func v_arr(val: Variant) -> Array:
	if typeof(val) == TYPE_ARRAY:
		var av: Array = val
		return av
	return []

