class_name SynergyEvaluationSnapshot
extends RefCounted
## Core model (rank 2). Typed, read-only snapshot published via
## `EventBus.systemic_synergy_evaluated` capturing all 5 closed-form equilibrium
## equations and active cross-domain resonances from `SystemicSynergyMatrix`.

var player_id: int = 1
var army_id: int = 1
var region_coord: Vector2i = Vector2i.ZERO
var season_index: int = 0

# Eq 1: Combat Power & Harmonic Bottleneck
var water_logistics_ratio: float = 1.0
var yilki_remount_ratio: float = 1.0
var supply_bottleneck_factor: float = 1.0
var artisan_quality_factor: float = 1.0
var commander_career_factor: float = 1.0
var effective_combat_power_mult: float = 1.0

# Eq 2: Capped Black Market & Scarcity Elasticity
var black_market_scarcity_mult: float = 1.0

# Eq 3: Dynamic Kut Entropy Anti-Snowball Drift
var kut_entropy_net_drift: float = 0.0

# Eq 4: Logarithmic Courier & Information Tempo
var courier_delay_sec: float = 0.0
var doctrine_exposed: bool = false
var courier_tempo_mult: float = 1.0

# Eq 5: Multiplicative Dread-Honor Coalition Pressure
var dread_score: float = 0.0
var honor_score: float = 50.0
var threat_events_sum: float = 0.0
var coalition_pressure_score: float = 0.0

# Cross-System Resonances
var active_resonances: Array[GameEnums.SynergyResonanceId] = []


func has_resonance(res_id: GameEnums.SynergyResonanceId) -> bool:
	return active_resonances.has(res_id)


func get_resonance_count() -> int:
	return active_resonances.size()


func get_primary_resonance_label() -> String:
	if active_resonances.is_empty():
		return "Yok"
	return format_resonance_name(active_resonances[0])


func is_finite_and_bounded() -> bool:
	var floats: Array[float] = [
		water_logistics_ratio,
		yilki_remount_ratio,
		supply_bottleneck_factor,
		artisan_quality_factor,
		commander_career_factor,
		effective_combat_power_mult,
		black_market_scarcity_mult,
		kut_entropy_net_drift,
		courier_delay_sec,
		courier_tempo_mult,
		dread_score,
		honor_score,
		threat_events_sum,
		coalition_pressure_score,
	]
	for val: float in floats:
		if is_nan(val) or is_inf(val):
			return false
	if supply_bottleneck_factor < 0.249 or supply_bottleneck_factor > 1.001:
		return false
	if artisan_quality_factor < 1.0 or artisan_quality_factor > 1.501:
		return false
	if commander_career_factor < 0.549 or commander_career_factor > 1.381:
		return false
	if effective_combat_power_mult < 0.0 or effective_combat_power_mult > 3.001:
		return false
	if black_market_scarcity_mult < 1.0 or black_market_scarcity_mult > 3.4001:
		return false
	if kut_entropy_net_drift < -30.001 or kut_entropy_net_drift > 30.001:
		return false
	if courier_tempo_mult < 0.349 or courier_tempo_mult > 1.851:
		return false
	if coalition_pressure_score < 0.0 or coalition_pressure_score > 500.001:
		return false
	return true


static func format_resonance_name(res_id: GameEnums.SynergyResonanceId) -> String:
	match res_id:
		GameEnums.SynergyResonanceId.SHADOW_FAMINE_STRIKE:
			return "Gölge Kıtlık Darbesi"
		GameEnums.SynergyResonanceId.DREAD_MIRAGE_TRAP:
			return "Dehşet Serap Kapanı"
		GameEnums.SynergyResonanceId.ARTISAN_BORU_SPEARHEAD:
			return "Zanaatkar Börü Mızrak Başı"
		GameEnums.SynergyResonanceId.TORE_KURULTAY_NETWORK:
			return "Töre Kurultayı Ağı"
		GameEnums.SynergyResonanceId.EXILE_KINGMAKER_NET:
			return "Yersiz Yurtsuz Kral-Yapıcı Ağı"
		_:
			return "Yok"
