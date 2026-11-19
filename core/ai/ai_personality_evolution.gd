class_name AIPersonalityEvolution
extends RefCounted
## Core living AI personality module (rank 2, leaf 2A).
## Tracks dynamic behavioral drift from historical traumas (Zud loss, well
## sabotage, veteran commander death, Amanat betrayal), per-player deterministic
## Kan Davası (Vendetta) scores, and difficulty-governed Emotional Stress vs
## KAGAN_ZEKASI cold-gambit composure without referencing other AI modules.

const MIN_WEIGHT: float = 0.35
const MAX_WEIGHT: float = 2.35
const MAX_TRAUMA_SCORE: float = 150.0
const MAX_VENDETTA_SCORE: float = 100.0
const MAX_HISTORY_ENTRIES: int = 24


class StressDirective:
	extends RefCounted
	var stress_level: float = 0.0
	var in_panic_mode: bool = false
	var in_cold_gambit_mode: bool = false
	var defensive_panic_bonus: float = 0.0
	var gambit_boldness_bonus: float = 0.0
	var panic_noise_mult: float = 1.0


var base_personality: GameEnums.SteppeAIPersonality = GameEnums.SteppeAIPersonality.AKINCI_BASKINCI
var evolved_aggression: float = 1.0
var evolved_sabotage: float = 1.0
var evolved_economy: float = 1.0
var evolved_deception: float = 1.0
var evolved_diplomacy: float = 1.0
var evolved_doctrine_counter: float = 1.0

var trauma_score: float = 0.0
var stress_level: float = 0.0
var vendetta_by_player: Dictionary[int, float] = {}
var trauma_history: PackedStringArray = PackedStringArray()
var last_trauma_tick: int = -100
var _last_zud_tick_recorded: int = -100


func _init(profile: SteppeAIPersonalityProfile = null) -> void:
	if profile != null:
		apply_base_profile(profile)


func apply_base_profile(profile: SteppeAIPersonalityProfile) -> void:
	if profile == null:
		return
	base_personality = profile.personality
	evolved_aggression = clampf(profile.aggression_weight, MIN_WEIGHT, MAX_WEIGHT)
	evolved_sabotage = clampf(profile.sabotage_weight, MIN_WEIGHT, MAX_WEIGHT)
	evolved_economy = clampf(profile.economy_weight, MIN_WEIGHT, MAX_WEIGHT)
	evolved_deception = clampf(profile.deception_weight, MIN_WEIGHT, MAX_WEIGHT)
	evolved_diplomacy = clampf(profile.diplomacy_weight, MIN_WEIGHT, MAX_WEIGHT)
	evolved_doctrine_counter = clampf(profile.doctrine_counter_weight, MIN_WEIGHT, MAX_WEIGHT)


func reset() -> void:
	trauma_score = 0.0
	stress_level = 0.0
	vendetta_by_player.clear()
	trauma_history = PackedStringArray()
	last_trauma_tick = -100
	_last_zud_tick_recorded = -100


func record_trauma(
		trauma_type: GameEnums.AITraumaType,
		instigator_pid: int,
		severity: float = 1.0,
		tick: int = -1,
		detail_tag: String = "") -> float:
	if trauma_type == GameEnums.AITraumaType.NONE:
		return 0.0
	var eff_tick: int = tick if tick >= 0 else last_trauma_tick + 1
	if trauma_type == GameEnums.AITraumaType.ZUD_HEAVY_LOSS and eff_tick == _last_zud_tick_recorded:
		return get_vendetta_score(instigator_pid)
	var sev: float = clampf(severity, 0.20, 2.50)

	match trauma_type:
		GameEnums.AITraumaType.ZUD_HEAVY_LOSS:
			_last_zud_tick_recorded = eff_tick
			evolved_economy = clampf(evolved_economy + 0.22 * sev, MIN_WEIGHT, MAX_WEIGHT)
			evolved_sabotage = clampf(evolved_sabotage + 0.14 * sev, MIN_WEIGHT, MAX_WEIGHT)
			evolved_aggression = clampf(evolved_aggression - 0.05 * sev, MIN_WEIGHT, MAX_WEIGHT)
			trauma_score = clampf(trauma_score + 18.0 * sev, 0.0, MAX_TRAUMA_SCORE)
		GameEnums.AITraumaType.WELL_SABOTAGED:
			evolved_sabotage = clampf(evolved_sabotage + 0.24 * sev, MIN_WEIGHT, MAX_WEIGHT)
			evolved_deception = clampf(evolved_deception + 0.14 * sev, MIN_WEIGHT, MAX_WEIGHT)
			evolved_economy = clampf(evolved_economy + 0.10 * sev, MIN_WEIGHT, MAX_WEIGHT)
			trauma_score = clampf(trauma_score + 22.0 * sev, 0.0, MAX_TRAUMA_SCORE)
			if instigator_pid > 0:
				_add_vendetta(instigator_pid, 28.0 * sev)
		GameEnums.AITraumaType.VETERAN_COMMANDER_FALLEN:
			evolved_aggression = clampf(evolved_aggression + 0.24 * sev, MIN_WEIGHT, MAX_WEIGHT)
			evolved_doctrine_counter = clampf(evolved_doctrine_counter + 0.16 * sev, MIN_WEIGHT, MAX_WEIGHT)
			trauma_score = clampf(trauma_score + 26.0 * sev, 0.0, MAX_TRAUMA_SCORE)
			if instigator_pid > 0:
				_add_vendetta(instigator_pid, 36.0 * sev)
		GameEnums.AITraumaType.AMANAT_BETRAYAL:
			evolved_deception = clampf(evolved_deception + 0.24 * sev, MIN_WEIGHT, MAX_WEIGHT)
			evolved_aggression = clampf(evolved_aggression + 0.16 * sev, MIN_WEIGHT, MAX_WEIGHT)
			evolved_diplomacy = clampf(evolved_diplomacy - 0.22 * sev, MIN_WEIGHT, MAX_WEIGHT)
			trauma_score = clampf(trauma_score + 30.0 * sev, 0.0, MAX_TRAUMA_SCORE)
			if instigator_pid > 0:
				_add_vendetta(instigator_pid, 42.0 * sev)

	last_trauma_tick = eff_tick
	var tag: String = "%d:%d:%s" % [int(trauma_type), instigator_pid, detail_tag]
	trauma_history.append(tag)
	while trauma_history.size() > MAX_HISTORY_ENTRIES:
		trauma_history.remove_at(0)
	return get_vendetta_score(instigator_pid)


func _add_vendetta(instigator_pid: int, amount: float) -> void:
	if instigator_pid <= 0:
		return
	var cur: float = vendetta_by_player.get(instigator_pid, 0.0)
	vendetta_by_player[instigator_pid] = clampf(cur + maxf(amount, 0.0), 0.0, MAX_VENDETTA_SCORE)


func get_vendetta_score(target_pid: int) -> float:
	if target_pid <= 0:
		return 0.0
	return vendetta_by_player.get(target_pid, 0.0)


func get_vendetta_multiplier(target_pid: int) -> float:
	var v: float = get_vendetta_score(target_pid)
	return 1.0 + clampf(v / MAX_VENDETTA_SCORE, 0.0, 1.0) * 0.65


func decay_seasonal_state(vendetta_decay: float = 1.5, trauma_decay: float = 1.0) -> void:
	trauma_score = clampf(trauma_score - maxf(trauma_decay, 0.0), 0.0, MAX_TRAUMA_SCORE)
	var keys: Array[int] = vendetta_by_player.keys()
	keys.sort()
	for pid: int in keys:
		var next_v: float = maxf(vendetta_by_player[pid] - maxf(vendetta_decay, 0.0), 0.0)
		if next_v <= 0.01:
			vendetta_by_player.erase(pid)
		else:
			vendetta_by_player[pid] = next_v


func build_effective_profile(base: SteppeAIPersonalityProfile) -> SteppeAIPersonalityProfile:
	var out: SteppeAIPersonalityProfile = SteppeAIPersonalityProfile.new()
	if base != null:
		out.profile_id = base.profile_id
		out.personality = base.personality
		out.display_name = base.display_name
		out.preferred_scheme = base.preferred_scheme
		out.preferred_doctrine = base.preferred_doctrine
	else:
		out.personality = base_personality
	out.aggression_weight = evolved_aggression
	out.sabotage_weight = evolved_sabotage
	out.economy_weight = evolved_economy
	out.deception_weight = evolved_deception
	out.diplomacy_weight = evolved_diplomacy
	out.doctrine_counter_weight = evolved_doctrine_counter
	return out


func evaluate_stress_directive(
		diff: AIDifficultyProfile,
		enemy_dread: float,
		supply_crisis: bool,
		own_sabotaged_wells: int) -> StressDirective:
	var dir: StressDirective = StressDirective.new()
	var dread_load: float = clampf((enemy_dread - 30.0) / 70.0, 0.0, 1.0) * 0.42
	var famine_load: float = 0.28 if supply_crisis else 0.0
	var well_load: float = minf(float(maxi(own_sabotaged_wells, 0)) * 0.16, 0.30)
	var trauma_load: float = clampf(trauma_score / 110.0, 0.0, 0.32)
	var raw_load: float = clampf(dread_load + famine_load + well_load + trauma_load, 0.0, 1.0)

	var tier: GameEnums.AIDifficultyTier = diff.difficulty_tier if diff != null else GameEnums.AIDifficultyTier.SANCAK_BEYI
	match tier:
		GameEnums.AIDifficultyTier.OYMAK_BEYI:
			stress_level = clampf(raw_load * 1.15, 0.0, 1.0)
			if stress_level >= 0.35:
				dir.in_panic_mode = true
				dir.defensive_panic_bonus = 32.0 + stress_level * 40.0
				dir.panic_noise_mult = 1.0 + stress_level * 0.45
		GameEnums.AIDifficultyTier.SANCAK_BEYI:
			stress_level = clampf(raw_load * 0.90, 0.0, 1.0)
			if stress_level >= 0.56:
				dir.in_panic_mode = true
				dir.defensive_panic_bonus = 18.0 + stress_level * 22.0
				dir.panic_noise_mult = 1.0 + stress_level * 0.20
		GameEnums.AIDifficultyTier.BOZKIR_KURDU:
			stress_level = clampf(raw_load * 0.65, 0.0, 1.0)
			if raw_load >= 0.45:
				dir.in_cold_gambit_mode = true
				dir.gambit_boldness_bonus = 22.0 + raw_load * 20.0
				dir.panic_noise_mult = 0.90
		GameEnums.AIDifficultyTier.KAGAN_ZEKASI:
			stress_level = clampf(raw_load * 0.40, 0.0, 1.0)
			dir.panic_noise_mult = 0.65
			if raw_load >= 0.30:
				dir.in_cold_gambit_mode = true
				dir.gambit_boldness_bonus = 38.0 + raw_load * 32.0

	dir.stress_level = stress_level
	return dir


func export_state_dict() -> Dictionary:
	var vend_dict: Dictionary = {}
	var keys: Array[int] = vendetta_by_player.keys()
	keys.sort()
	for pid: int in keys:
		vend_dict[str(pid)] = vendetta_by_player[pid]
	var hist: Array[String] = []
	for tag: String in trauma_history:
		hist.append(tag)
	return {
		"base_personality": int(base_personality),
		"evolved_aggression": evolved_aggression,
		"evolved_deception": evolved_deception,
		"evolved_diplomacy": evolved_diplomacy,
		"evolved_doctrine_counter": evolved_doctrine_counter,
		"evolved_economy": evolved_economy,
		"evolved_sabotage": evolved_sabotage,
		"last_trauma_tick": last_trauma_tick,
		"last_zud_tick_recorded": _last_zud_tick_recorded,
		"stress_level": stress_level,
		"trauma_history": hist,
		"trauma_score": trauma_score,
		"vendetta_by_player": vend_dict,
	}


func import_state_dict(data: Dictionary) -> bool:
	var bp_int: int = clampi(DeterministicStateHasher.v_int(data.get("base_personality", 0), 0), 0, 3)
	base_personality = bp_int as GameEnums.SteppeAIPersonality
	evolved_aggression = clampf(DeterministicStateHasher.v_float(data.get("evolved_aggression", 1.0), 1.0), MIN_WEIGHT, MAX_WEIGHT)
	evolved_sabotage = clampf(DeterministicStateHasher.v_float(data.get("evolved_sabotage", 1.0), 1.0), MIN_WEIGHT, MAX_WEIGHT)
	evolved_economy = clampf(DeterministicStateHasher.v_float(data.get("evolved_economy", 1.0), 1.0), MIN_WEIGHT, MAX_WEIGHT)
	evolved_deception = clampf(DeterministicStateHasher.v_float(data.get("evolved_deception", 1.0), 1.0), MIN_WEIGHT, MAX_WEIGHT)
	evolved_diplomacy = clampf(DeterministicStateHasher.v_float(data.get("evolved_diplomacy", 1.0), 1.0), MIN_WEIGHT, MAX_WEIGHT)
	evolved_doctrine_counter = clampf(DeterministicStateHasher.v_float(data.get("evolved_doctrine_counter", 1.0), 1.0), MIN_WEIGHT, MAX_WEIGHT)
	trauma_score = clampf(DeterministicStateHasher.v_float(data.get("trauma_score", 0.0), 0.0), 0.0, MAX_TRAUMA_SCORE)
	stress_level = clampf(DeterministicStateHasher.v_float(data.get("stress_level", 0.0), 0.0), 0.0, 1.0)
	last_trauma_tick = DeterministicStateHasher.v_int(data.get("last_trauma_tick", -100), -100)
	_last_zud_tick_recorded = DeterministicStateHasher.v_int(data.get("last_zud_tick_recorded", -100), -100)

	vendetta_by_player.clear()
	var vd: Dictionary = DeterministicStateHasher.v_dict(data.get("vendetta_by_player", {}))
	for k: Variant in vd:
		var pid: int = DeterministicStateHasher.v_str(k).to_int()
		if pid > 0:
			vendetta_by_player[pid] = clampf(DeterministicStateHasher.v_float(vd[k], 0.0), 0.0, MAX_VENDETTA_SCORE)

	trauma_history = PackedStringArray()
	for h_v: Variant in DeterministicStateHasher.v_arr(data.get("trauma_history", [])):
		trauma_history.append(DeterministicStateHasher.v_str(h_v))
	return true
