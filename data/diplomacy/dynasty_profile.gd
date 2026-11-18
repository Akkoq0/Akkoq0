class_name DynastyProfile
extends Resource
## Data layer (rank 1). Personality, military posture, and Threat Matrix
## coefficients for a rival steppe dynasty (e.g., Karluk, Kıpçak, Oğuz Beylikleri).

@export var dynasty_id: StringName = &""
@export var display_name: String = ""

@export_group("Dynasty Personality Traits")
## Ambition (`0..1`): propensity to exploit Khaganate weakness and join anti-Khagan coalitions.
@export_range(0.0, 1.0, 0.01) var ambition: float = 0.65
## Discipline (`0..1`): tactical cohesion and resistance to Feigned Retreat lures.
@export_range(0.0, 1.0, 0.01) var discipline: float = 0.70
## Initial Trust Index (`0..100`) toward the player's Khaganate.
@export_range(0.0, 100.0, 0.5) var trust_index: float = 55.0
## Baseline standing army strength of this dynasty.
@export_range(100.0, 100000.0, 10.0) var base_military_power: float = 1000.0

@export_group("Threat Matrix & Stance Thresholds")
## Threat score `<= ally_threshold` produces `ALLY` (Müttefik).
@export_range(5.0, 90.0, 1.0) var ally_threshold: float = 25.0
## Threat score `<= neutral_threshold` produces `NEUTRAL` (Tarafsız).
@export_range(10.0, 95.0, 1.0) var neutral_threshold: float = 50.0
## Threat score `<= threatening_threshold` produces `THREATENING` (Tehditkar); above produces `HOSTILE` (Düşman).
@export_range(15.0, 99.0, 1.0) var threatening_threshold: float = 72.0
## Kut threshold (`< 30.0`) below which ambitious dynasties form an opportunistic coalition war.
@export_range(5.0, 60.0, 1.0) var coalition_kut_threshold: float = 30.0


## Computes the composite Threat Score (`0..100`) from the player's Kut score
## (`0..100`), army strength relative to `base_military_power`, border raid
## frequency (`0..10`), and current `trust_override` (`0..100`).
func calculate_threat_score(player_kut: float, player_army_size: float, raid_frequency: float, trust_override: float = -1.0) -> float:
	var active_trust: float = trust_override if trust_override >= 0.0 else trust_index
	var kut_weakness: float = clampf((100.0 - clampf(player_kut, 0.0, 100.0)) * 0.45, 0.0, 45.0)
	var army_ratio: float = clampf(player_army_size / maxf(base_military_power, 1.0), 0.1, 3.0)
	var military_vulnerability: float = clampf((1.5 - army_ratio) * 20.0, -15.0, 30.0)
	var raid_provocation: float = clampf(raid_frequency * 6.5, 0.0, 45.0)
	var trust_mitigation: float = (clampf(active_trust, 0.0, 100.0) - 50.0) * 0.55
	var ambition_boost: float = ambition * 28.0
	var raw_threat: float = ambition_boost + kut_weakness + military_vulnerability + raid_provocation - trust_mitigation
	return clampf(raw_threat, 0.0, 100.0)


## Evaluates the dynasty's diplomatic attitude (`ALLY`, `NEUTRAL`, `THREATENING`, `HOSTILE`).
func calculate_dynasty_stance(player_kut: float, player_army_size: float, raid_frequency: float, trust_override: float = -1.0) -> GameEnums.DynastyAttitude:
	var threat: float = calculate_threat_score(player_kut, player_army_size, raid_frequency, trust_override)
	if threat <= ally_threshold:
		return GameEnums.DynastyAttitude.ALLY
	if threat <= neutral_threshold:
		return GameEnums.DynastyAttitude.NEUTRAL
	if threat <= threatening_threshold:
		return GameEnums.DynastyAttitude.THREATENING
	return GameEnums.DynastyAttitude.HOSTILE


## True when the player's Kut dropped below `coalition_kut_threshold` (`< 30`)
## and this dynasty is ambitious or hostile enough to join a Coalition War.
func should_join_coalition(player_kut: float, player_army_size: float, raid_frequency: float, trust_override: float = -1.0) -> bool:
	if player_kut >= coalition_kut_threshold:
		return false
	var stance: GameEnums.DynastyAttitude = calculate_dynasty_stance(player_kut, player_army_size, raid_frequency, trust_override)
	return ambition >= 0.50 and (stance == GameEnums.DynastyAttitude.THREATENING or stance == GameEnums.DynastyAttitude.HOSTILE)


## Returns schema violations (empty when valid).
func get_validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if dynasty_id == &"":
		errors.append("DynastyProfile: dynasty_id cannot be empty.")
	if display_name.is_empty():
		errors.append("DynastyProfile '%s': display_name cannot be empty." % dynasty_id)
	if not (ally_threshold < neutral_threshold and neutral_threshold < threatening_threshold):
		errors.append("DynastyProfile '%s': thresholds must satisfy ally < neutral < threatening." % dynasty_id)
	return errors
