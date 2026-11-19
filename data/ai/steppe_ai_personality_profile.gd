class_name SteppeAIPersonalityProfile
extends Resource
## Data layer (rank 1). Four asymmetrical Steppe tribal AI archetypes shaping
## strategic priorities, scheme preference, and baseline battle doctrine affinity.

@export var profile_id: StringName = &"akinci_baskinci"
@export var personality: GameEnums.SteppeAIPersonality = GameEnums.SteppeAIPersonality.AKINCI_BASKINCI
@export var display_name: String = "Akıncı Baskıncı"

@export_group("Utility Archetype Weights")
@export_range(0.1, 3.0, 0.05) var aggression_weight: float = 1.35
@export_range(0.1, 3.0, 0.05) var sabotage_weight: float = 0.90
@export_range(0.1, 3.0, 0.05) var economy_weight: float = 0.75
@export_range(0.1, 3.0, 0.05) var deception_weight: float = 0.95
@export_range(0.1, 3.0, 0.05) var diplomacy_weight: float = 0.85
@export_range(0.1, 3.0, 0.05) var doctrine_counter_weight: float = 1.05

@export_group("Signature Scheme & Doctrine Affinity")
@export var preferred_scheme: GameEnums.AISchemeType = GameEnums.AISchemeType.OPPORTUNISTIC_CRISIS_STRIKE
@export var preferred_doctrine: GameEnums.BattleDoctrinePresetId = GameEnums.BattleDoctrinePresetId.TOLGAMA_KISKACI


func duplicate_profile() -> SteppeAIPersonalityProfile:
	var copy: SteppeAIPersonalityProfile = SteppeAIPersonalityProfile.new()
	copy.profile_id = profile_id
	copy.personality = personality
	copy.display_name = display_name
	copy.aggression_weight = aggression_weight
	copy.sabotage_weight = sabotage_weight
	copy.economy_weight = economy_weight
	copy.deception_weight = deception_weight
	copy.diplomacy_weight = diplomacy_weight
	copy.doctrine_counter_weight = doctrine_counter_weight
	copy.preferred_scheme = preferred_scheme
	copy.preferred_doctrine = preferred_doctrine
	return copy


func get_validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if profile_id == &"":
		errors.append("SteppeAIPersonalityProfile: profile_id cannot be empty.")
	if display_name.strip_edges().is_empty():
		errors.append("SteppeAIPersonalityProfile: display_name cannot be empty.")
	if aggression_weight <= 0.0 or sabotage_weight <= 0.0 or economy_weight <= 0.0:
		errors.append("SteppeAIPersonalityProfile: utility weights must be > 0.")
	return errors


static func create_preset(p: GameEnums.SteppeAIPersonality) -> SteppeAIPersonalityProfile:
	var prof: SteppeAIPersonalityProfile = SteppeAIPersonalityProfile.new()
	prof.personality = p
	match p:
		GameEnums.SteppeAIPersonality.YAYLAK_IMPARATORU:
			prof.profile_id = &"yaylak_imparatoru"
			prof.display_name = "Yaylak İmparatoru"
			prof.aggression_weight = 0.80
			prof.sabotage_weight = 0.65
			prof.economy_weight = 1.50
			prof.deception_weight = 0.70
			prof.diplomacy_weight = 1.35
			prof.doctrine_counter_weight = 1.00
			prof.preferred_scheme = GameEnums.AISchemeType.OPPORTUNISTIC_CRISIS_STRIKE
			prof.preferred_doctrine = GameEnums.BattleDoctrinePresetId.ARABA_KALESI
		GameEnums.SteppeAIPersonality.GOLGE_SABOTOR:
			prof.profile_id = &"golge_sabotor"
			prof.display_name = "Gölge Sabotör"
			prof.aggression_weight = 0.90
			prof.sabotage_weight = 1.55
			prof.economy_weight = 0.85
			prof.deception_weight = 1.50
			prof.diplomacy_weight = 1.25
			prof.doctrine_counter_weight = 1.15
			prof.preferred_scheme = GameEnums.AISchemeType.POISONED_WINTER_TRAP
			prof.preferred_doctrine = GameEnums.BattleDoctrinePresetId.TONYUKUK_YIPRATMASI
		GameEnums.SteppeAIPersonality.DEMIR_SAVUNMACI:
			prof.profile_id = &"demir_savunmaci"
			prof.display_name = "Demir Savunmacı"
			prof.aggression_weight = 0.75
			prof.sabotage_weight = 0.70
			prof.economy_weight = 1.30
			prof.deception_weight = 0.85
			prof.diplomacy_weight = 1.15
			prof.doctrine_counter_weight = 1.35
			prof.preferred_scheme = GameEnums.AISchemeType.DUST_VEIL_COURIER_AMBUSH
			prof.preferred_doctrine = GameEnums.BattleDoctrinePresetId.ARABA_KALESI
		_:
			prof.profile_id = &"akinci_baskinci"
			prof.display_name = "Akıncı Baskıncı"
			prof.aggression_weight = 1.45
			prof.sabotage_weight = 0.95
			prof.economy_weight = 0.75
			prof.deception_weight = 1.10
			prof.diplomacy_weight = 0.85
			prof.doctrine_counter_weight = 1.05
			prof.preferred_scheme = GameEnums.AISchemeType.OPPORTUNISTIC_CRISIS_STRIKE
			prof.preferred_doctrine = GameEnums.BattleDoctrinePresetId.TOLGAMA_KISKACI
	return prof
