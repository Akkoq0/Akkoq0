class_name CombatRules
extends Resource
## Data layer (rank 1). Coefficients of the Phase 3 **Triple Collapse Model**
## (Physical Casualties + Formation Cohesion + Battle Will/Fear), vectorial
## dot-product flanking math, and 7-Ore combat integration.

@export_group("Base Damage & Mitigation")
@export_range(0.0, 100.0, 0.001) var damage_multiplier: float = 1.0
## Mitigation constant K. Higher K = defense matters less.
@export_range(0.001, 100000.0, 0.01) var mitigation_constant: float = 200.0
@export_range(0.0, 100000.0, 0.01) var minimum_damage: float = 5.0
## Random spread (0..1) applied symmetrically around 1.0.
@export_range(0.0, 1.0, 0.01) var random_spread: float = 0.05
## Fraction of attack retained by a fully starved (supply 0) army.
@export_range(0.0, 1.0, 0.01) var out_of_supply_attack_factor: float = 0.5
## Fraction of the defender's damage dealt back to the attacker.
@export_range(0.0, 2.0, 0.01) var counter_attack_ratio: float = 0.65

@export_group("Vectorial Dot-Product Flanking")
## Dot product threshold separating Front (`dot <= -threshold`), Flank (`|dot| < threshold`), and Rear (`dot >= threshold`).
@export_range(0.05, 0.95, 0.01) var flank_dot_threshold: float = 0.35
@export_range(1.0, 5.0, 0.01) var front_damage_multiplier: float = 1.0
@export_range(1.0, 5.0, 0.01) var flank_damage_multiplier: float = 1.45
@export_range(1.0, 5.0, 0.01) var rear_damage_multiplier: float = 2.1
@export_range(1.0, 5.0, 0.01) var front_cohesion_multiplier: float = 1.0
@export_range(1.0, 5.0, 0.01) var flank_cohesion_multiplier: float = 2.0
@export_range(1.0, 5.0, 0.01) var rear_cohesion_multiplier: float = 2.25
@export_range(0.0, 100.0, 0.1) var rear_panic_morale_drop: float = 28.0

@export_group("7-Ore Combat Integration")
## Fraction of enemy armor ignored when attacker uses Steel (`steel.tres`).
@export_range(0.0, 0.95, 0.01) var steel_armor_penetration_ratio: float = 0.35
## Extra shield-breaking damage & cohesion multiplier from Steel weapons.
@export_range(1.0, 3.0, 0.01) var steel_shield_break_multiplier: float = 1.25
## Sulfur (`sulfur.tres`) fire & smoke trap area damage in choke points.
@export_range(0.0, 5000.0, 1.0) var sulfur_trap_area_damage: float = 140.0
@export_range(0.0, 100.0, 0.1) var sulfur_base_cohesion_drop: float = 16.0
@export_range(0.0, 100.0, 0.1) var sulfur_base_morale_drop: float = 14.0
## Multiplier applied to cohesion & morale loss when Sulfur smoke spooks enemy cavalry horses.
@export_range(1.0, 5.0, 0.01) var sulfur_cavalry_panic_multiplier: float = 2.25
@export_range(1, 1000) var sulfur_ore_cost_per_trap: int = 10
## Critical shock multiplier granted by a Meteoric Iron (`meteoric_iron.tres`) bound commander weapon.
@export_range(1.0, 5.0, 0.01) var meteoric_iron_crit_shock_multiplier: float = 1.40
## Divine Dread ("İlahi Dehşet") morale drop inflicted on enemy ranks by Meteoric Iron.
@export_range(0.0, 100.0, 0.1) var meteoric_iron_dread_morale_drop: float = 22.0

@export_group("Triple Collapse, Rout & Toy Loot")
@export_range(0.01, 2.0, 0.01) var base_cohesion_damage_ratio: float = 0.12
@export_range(0.01, 2.0, 0.01) var base_morale_damage_ratio: float = 0.10
## Formation cohesion threshold (`< 15.0`) below which the army collapses into `ROUTED`.
@export_range(1.0, 50.0, 0.5) var rout_cohesion_threshold: float = 15.0
## Morale threshold below which a shaken army routs.
@export_range(1.0, 50.0, 0.5) var rout_morale_threshold: float = 20.0
## Toy loot trade value (weapons & Yılkı horses) captured per unit of health when an encircled army is annihilated.
@export_range(0.01, 10.0, 0.01) var annihilation_loot_per_health: float = 0.45


## Classifies the engagement angle from `attack_vector` (direction of blow)
## and `defender_facing` (direction defender is looking) using `Vector3.dot`.
func classify_engagement_angle(attack_vector: Vector3, defender_facing: Vector3) -> GameEnums.CombatEngagementAngle:
	var atk_norm: Vector3 = attack_vector.normalized() if attack_vector.length_squared() > 0.0001 else Vector3.BACK
	var def_norm: Vector3 = defender_facing.normalized() if defender_facing.length_squared() > 0.0001 else Vector3.FORWARD
	var dot_val: float = atk_norm.dot(def_norm)
	if dot_val <= -flank_dot_threshold:
		return GameEnums.CombatEngagementAngle.FRONT
	if dot_val >= flank_dot_threshold:
		return GameEnums.CombatEngagementAngle.REAR
	return GameEnums.CombatEngagementAngle.FLANK


## Damage multiplier for `angle`.
func get_directional_damage_multiplier(angle: GameEnums.CombatEngagementAngle) -> float:
	if angle == GameEnums.CombatEngagementAngle.REAR:
		return rear_damage_multiplier
	if angle == GameEnums.CombatEngagementAngle.FLANK:
		return flank_damage_multiplier
	return front_damage_multiplier


## Cohesion destruction multiplier for `angle`.
func get_directional_cohesion_multiplier(angle: GameEnums.CombatEngagementAngle) -> float:
	if angle == GameEnums.CombatEngagementAngle.REAR:
		return rear_cohesion_multiplier
	if angle == GameEnums.CombatEngagementAngle.FLANK:
		return flank_cohesion_multiplier
	return front_cohesion_multiplier
