class_name AIDifficultyProfile
extends Resource
## Data layer (rank 1). Configurable bounded-rationality difficulty profile
## (`OYMAK_BEYI`, `SANCAK_BEYI`, `BOZKIR_KURDU`, `KAGAN_ZEKASI`) with ZERO
## hidden resource, income, or map-visibility cheats.

@export var profile_id: StringName = &"sancak_beyi"
@export var difficulty_tier: GameEnums.AIDifficultyTier = GameEnums.AIDifficultyTier.SANCAK_BEYI
@export var display_name: String = "Sancak Beyi (Normal)"

@export_group("Bounded Rationality & Decision Noise")
@export_range(0.01, 2.50, 0.01) var decision_temperature: float = 0.32
@export_range(0.0, 60.0, 0.5) var mistake_noise_amplitude: float = 11.0
@export_range(0.0, 1.0, 0.01) var feigned_retreat_susceptibility: float = 0.45
@export_range(0.0, 1.0, 0.01) var anti_spam_memory_weight: float = 0.55

@export_group("Perception, Foresight & Adaptation (0% Cheat)")
@export_range(0.0, 1.0, 0.01) var dust_veil_pierce_skill: float = 0.45
@export_range(0.0, 2.0, 0.05) var adaptation_learning_rate: float = 0.60
@export_range(0.0, 2.0, 0.05) var synergy_pursuit_weight: float = 0.55
@export_range(0.0, 2.0, 0.05) var scheme_planning_weight: float = 0.55
@export_range(0.0, 2.0, 0.05) var foresight_zud_horizon_weight: float = 0.65
@export_range(0.0, 2.0, 0.05) var terrain_trap_awareness: float = 0.60


func duplicate_profile() -> AIDifficultyProfile:
	var copy: AIDifficultyProfile = AIDifficultyProfile.new()
	copy.profile_id = profile_id
	copy.difficulty_tier = difficulty_tier
	copy.display_name = display_name
	copy.decision_temperature = decision_temperature
	copy.mistake_noise_amplitude = mistake_noise_amplitude
	copy.feigned_retreat_susceptibility = feigned_retreat_susceptibility
	copy.anti_spam_memory_weight = anti_spam_memory_weight
	copy.dust_veil_pierce_skill = dust_veil_pierce_skill
	copy.adaptation_learning_rate = adaptation_learning_rate
	copy.synergy_pursuit_weight = synergy_pursuit_weight
	copy.scheme_planning_weight = scheme_planning_weight
	copy.foresight_zud_horizon_weight = foresight_zud_horizon_weight
	copy.terrain_trap_awareness = terrain_trap_awareness
	return copy


func get_effective_scout_strength() -> float:
	return clampf(35.0 + dust_veil_pierce_skill * 55.0, 10.0, 95.0)


func get_validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if profile_id == &"":
		errors.append("AIDifficultyProfile: profile_id cannot be empty.")
	if display_name.strip_edges().is_empty():
		errors.append("AIDifficultyProfile: display_name cannot be empty.")
	if decision_temperature <= 0.0:
		errors.append("AIDifficultyProfile: decision_temperature must be > 0.")
	if mistake_noise_amplitude < 0.0:
		errors.append("AIDifficultyProfile: mistake_noise_amplitude cannot be negative.")
	return errors


static func create_preset(tier: GameEnums.AIDifficultyTier) -> AIDifficultyProfile:
	var prof: AIDifficultyProfile = AIDifficultyProfile.new()
	prof.difficulty_tier = tier
	match tier:
		GameEnums.AIDifficultyTier.OYMAK_BEYI:
			prof.profile_id = &"oymak_beyi"
			prof.display_name = "Oymak Beyi (Kolay)"
			prof.decision_temperature = 0.90
			prof.mistake_noise_amplitude = 28.0
			prof.feigned_retreat_susceptibility = 0.80
			prof.anti_spam_memory_weight = 0.15
			prof.dust_veil_pierce_skill = 0.15
			prof.adaptation_learning_rate = 0.25
			prof.synergy_pursuit_weight = 0.20
			prof.scheme_planning_weight = 0.10
			prof.foresight_zud_horizon_weight = 0.25
			prof.terrain_trap_awareness = 0.15
		GameEnums.AIDifficultyTier.BOZKIR_KURDU:
			prof.profile_id = &"bozkir_kurdu"
			prof.display_name = "Bozkır Kurdu (Zor)"
			prof.decision_temperature = 0.10
			prof.mistake_noise_amplitude = 3.5
			prof.feigned_retreat_susceptibility = 0.15
			prof.anti_spam_memory_weight = 0.85
			prof.dust_veil_pierce_skill = 0.72
			prof.adaptation_learning_rate = 0.90
			prof.synergy_pursuit_weight = 1.05
			prof.scheme_planning_weight = 1.15
			prof.foresight_zud_horizon_weight = 1.10
			prof.terrain_trap_awareness = 1.00
		GameEnums.AIDifficultyTier.KAGAN_ZEKASI:
			prof.profile_id = &"kagan_zekasi"
			prof.display_name = "Kağan Zekâsı (Usta)"
			prof.decision_temperature = 0.02
			prof.mistake_noise_amplitude = 0.5
			prof.feigned_retreat_susceptibility = 0.02
			prof.anti_spam_memory_weight = 1.00
			prof.dust_veil_pierce_skill = 0.95
			prof.adaptation_learning_rate = 1.25
			prof.synergy_pursuit_weight = 1.40
			prof.scheme_planning_weight = 1.50
			prof.foresight_zud_horizon_weight = 1.45
			prof.terrain_trap_awareness = 1.25
		_:
			prof.profile_id = &"sancak_beyi"
			prof.display_name = "Sancak Beyi (Normal)"
			prof.decision_temperature = 0.32
			prof.mistake_noise_amplitude = 11.0
			prof.feigned_retreat_susceptibility = 0.45
			prof.anti_spam_memory_weight = 0.55
			prof.dust_veil_pierce_skill = 0.45
			prof.adaptation_learning_rate = 0.60
			prof.synergy_pursuit_weight = 0.55
			prof.scheme_planning_weight = 0.55
			prof.foresight_zud_horizon_weight = 0.65
			prof.terrain_trap_awareness = 0.60
	return prof
