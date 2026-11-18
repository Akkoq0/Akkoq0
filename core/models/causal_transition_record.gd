class_name CausalTransitionRecord
extends RefCounted
## Core model (rank 2). Type-safe telemetry payload emitted on `EventBus`
## whenever a multi-step causal chain or continuous simulation tick propagates
## cause-and-effect across Ötüken's core subsystems.

var chain_archetype: GameEnums.CausalChainArchetype = GameEnums.CausalChainArchetype.ECOLOGICAL_LOGISTICS_COLLAPSE
var step_id: StringName = &""
var cause_source: StringName = &""
var effect_target: StringName = &""
var impact_magnitude: float = 0.0
var accumulated_pressure: float = 0.0
var is_recovery: bool = false


func _init(p_archetype: GameEnums.CausalChainArchetype, p_step_id: StringName, p_cause_source: StringName, p_effect_target: StringName, p_impact_magnitude: float, p_accumulated_pressure: float, p_is_recovery: bool = false) -> void:
	chain_archetype = p_archetype
	step_id = p_step_id
	cause_source = p_cause_source
	effect_target = p_effect_target
	impact_magnitude = p_impact_magnitude
	accumulated_pressure = p_accumulated_pressure
	is_recovery = p_is_recovery
