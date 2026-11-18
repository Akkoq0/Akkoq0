class_name CombatRules
extends Resource
## Data layer (rank 1). Coefficients of the combat resolution formula.
##
## eff_attack  = attack  * (1 + totem_offense) * lerp(out_of_supply_attack_factor, 1, supply_ratio)
## eff_defense = defense * (1 + totem_defense) * terrain.defense_multiplier * season.defense_multiplier
## damage      = max(minimum_damage, eff_attack * damage_multiplier * K / (K + eff_defense)) * rng(1 +/- spread)
## counter     = same formula reversed (no terrain bonus), scaled by counter_attack_ratio

@export_range(0.0, 100.0, 0.001) var damage_multiplier: float = 1.0
## Mitigation constant K. Higher K = defense matters less.
@export_range(0.001, 100000.0, 0.01) var mitigation_constant: float = 1.0
@export_range(0.0, 100000.0, 0.01) var minimum_damage: float = 0.0
## Random spread (0..1) applied symmetrically around 1.0.
@export_range(0.0, 1.0, 0.01) var random_spread: float = 0.0
## Fraction of attack retained by a fully starved (supply 0) army.
@export_range(0.0, 1.0, 0.01) var out_of_supply_attack_factor: float = 1.0
## Fraction of the defender's damage dealt back to the attacker.
@export_range(0.0, 2.0, 0.01) var counter_attack_ratio: float = 0.0
