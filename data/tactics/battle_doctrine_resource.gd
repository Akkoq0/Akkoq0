class_name BattleDoctrineResource
extends Resource
## Data layer (rank 1). Phase 27B 4-layer modular Steppe Battle Doctrine schema:
##   Layer 1: Center / Flank / Reserve allocation ratios (sum == 1.0)
##   Layer 2: Opening tactic (`OpeningTactic`)
##   Layer 3: Decisive maneuver (`DecisiveManeuver`)
##   Layer 4: Offline standby contingency parameters (`GameEnums` Rank 0 only)

const RATIO_TOLERANCE: float = 0.001
const THIN_CENTER_THRESHOLD: float = 0.30

@export var doctrine_id: StringName = &"kurt_kapani"
@export var preset_id: GameEnums.BattleDoctrinePresetId = GameEnums.BattleDoctrinePresetId.KURT_KAPANI
@export var display_name: String = "Kurt Kapanı"
@export_multiline var description: String = ""
@export var turan_doctrine: TacticalDoctrineData = null
@export var is_heavy_armor_doctrine: bool = false

@export_group("Layer 1: Force Allocation")
@export_range(0.0, 1.0, 0.01) var center_ratio: float = 0.25
@export_range(0.0, 1.0, 0.01) var flank_ratio: float = 0.50
@export_range(0.0, 1.0, 0.01) var reserve_ratio: float = 0.25

@export_group("Layer 2 & 3: Opening & Decisive Maneuver")
@export var opening_tactic: GameEnums.OpeningTactic = GameEnums.OpeningTactic.YELME_HARASSMENT
@export var decisive_maneuver: GameEnums.DecisiveManeuver = GameEnums.DecisiveManeuver.KURT_KAPANI_FEIGNED_RETREAT

@export_group("Laager Defense & Mobility Tuning")
@export_range(0.10, 1.0, 0.01) var laager_mobility_multiplier: float = 0.55
@export_range(0.0, 0.95, 0.01) var laager_flank_damping: float = 0.65
@export_range(0.0, 0.95, 0.01) var laager_rear_damping: float = 0.70

@export_group("Layer 4: Standby Contingency Rule")
@export var contingency_trigger: GameEnums.OfflineDoctrineTrigger = GameEnums.OfflineDoctrineTrigger.ENEMY_POWER_RATIO_EXCEEDED
@export_range(1.05, 10.0, 0.05) var contingency_power_ratio_threshold: float = 1.50
@export_range(0.05, 0.85, 0.01) var contingency_low_supply_threshold: float = 0.20
@export var contingency_action_tactic: GameEnums.TuranTacticPhase = GameEnums.TuranTacticPhase.FEIGNED_RETREAT_LURE
@export var contingency_target_terrain_class: GameEnums.TerrainClass = GameEnums.TerrainClass.SIK_ORMAN
@export var contingency_target_geography_class: GameEnums.RegionGeographyClass = GameEnums.RegionGeographyClass.FOREST_EDGE
@export var contingency_pack_sefer_arabasi: bool = true
@export var contingency_evade_combat: bool = true


static func _sanitize_ratio(val: float) -> float:
	if is_nan(val) or is_inf(val):
		return 0.0
	return maxf(val, 0.0)


func has_non_finite_ratios() -> bool:
	return is_nan(center_ratio) or is_inf(center_ratio) \
		or is_nan(flank_ratio) or is_inf(flank_ratio) \
		or is_nan(reserve_ratio) or is_inf(reserve_ratio)


func get_allocation_sum() -> float:
	return center_ratio + flank_ratio + reserve_ratio


## Normalizes negative / unscaled ratios so center + flank + reserve equals 1.0.
func normalize_ratios() -> void:
	var c: float = _sanitize_ratio(center_ratio)
	var f: float = _sanitize_ratio(flank_ratio)
	var r: float = _sanitize_ratio(reserve_ratio)
	var total: float = c + f + r
	if total <= 0.0001:
		center_ratio = 0.34
		flank_ratio = 0.46
		reserve_ratio = 0.20
		return
	center_ratio = clampf(c / total, 0.0, 1.0)
	flank_ratio = clampf(f / total, 0.0, 1.0)
	reserve_ratio = clampf(1.0 - center_ratio - flank_ratio, 0.0, 1.0)


func has_thin_center() -> bool:
	if has_non_finite_ratios():
		return false
	return center_ratio < THIN_CENTER_THRESHOLD


func get_validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if doctrine_id == &"":
		errors.append("BattleDoctrineResource: doctrine_id cannot be empty.")
	if display_name.strip_edges().is_empty():
		errors.append("BattleDoctrineResource '%s': display_name cannot be empty." % String(doctrine_id))
	if has_non_finite_ratios():
		errors.append("BattleDoctrineResource '%s': allocation ratios must be finite." % String(doctrine_id))
	else:
		if center_ratio < 0.0 or flank_ratio < 0.0 or reserve_ratio < 0.0:
			errors.append("BattleDoctrineResource '%s': allocation ratios cannot be negative." % String(doctrine_id))
		if absf(get_allocation_sum() - 1.0) > RATIO_TOLERANCE:
			errors.append("BattleDoctrineResource '%s': center + flank + reserve must equal 1.0 (got %.4f)." % [String(doctrine_id), get_allocation_sum()])
	if is_nan(laager_mobility_multiplier) or is_inf(laager_mobility_multiplier) \
			or laager_mobility_multiplier <= 0.0 or laager_mobility_multiplier > 1.0:
		errors.append("BattleDoctrineResource '%s': laager_mobility_multiplier out of bounds." % String(doctrine_id))
	if is_nan(laager_flank_damping) or is_inf(laager_flank_damping) \
			or laager_flank_damping < 0.0 or laager_flank_damping > 0.95:
		errors.append("BattleDoctrineResource '%s': laager_flank_damping out of bounds." % String(doctrine_id))
	if is_nan(laager_rear_damping) or is_inf(laager_rear_damping) \
			or laager_rear_damping < 0.0 or laager_rear_damping > 0.95:
		errors.append("BattleDoctrineResource '%s': laager_rear_damping out of bounds." % String(doctrine_id))
	if is_nan(contingency_power_ratio_threshold) or is_inf(contingency_power_ratio_threshold) \
			or contingency_power_ratio_threshold < 1.05 or contingency_power_ratio_threshold > 10.0:
		errors.append("BattleDoctrineResource '%s': contingency_power_ratio_threshold out of bounds." % String(doctrine_id))
	if is_nan(contingency_low_supply_threshold) or is_inf(contingency_low_supply_threshold) \
			or contingency_low_supply_threshold < 0.05 or contingency_low_supply_threshold > 0.85:
		errors.append("BattleDoctrineResource '%s': contingency_low_supply_threshold out of bounds." % String(doctrine_id))
	if turan_doctrine != null:
		errors.append_array(turan_doctrine.get_validation_errors())
	return errors


func is_valid() -> bool:
	return get_validation_errors().is_empty()


func duplicate_clean() -> BattleDoctrineResource:
	var copy: BattleDoctrineResource = BattleDoctrineResource.new()
	copy.doctrine_id = doctrine_id
	copy.preset_id = preset_id
	copy.display_name = display_name
	copy.description = description
	copy.turan_doctrine = turan_doctrine
	copy.is_heavy_armor_doctrine = is_heavy_armor_doctrine
	copy.center_ratio = center_ratio
	copy.flank_ratio = flank_ratio
	copy.reserve_ratio = reserve_ratio
	copy.opening_tactic = opening_tactic
	copy.decisive_maneuver = decisive_maneuver
	copy.laager_mobility_multiplier = laager_mobility_multiplier
	copy.laager_flank_damping = laager_flank_damping
	copy.laager_rear_damping = laager_rear_damping
	copy.contingency_trigger = contingency_trigger
	copy.contingency_power_ratio_threshold = contingency_power_ratio_threshold
	copy.contingency_low_supply_threshold = contingency_low_supply_threshold
	copy.contingency_action_tactic = contingency_action_tactic
	copy.contingency_target_terrain_class = contingency_target_terrain_class
	copy.contingency_target_geography_class = contingency_target_geography_class
	copy.contingency_pack_sefer_arabasi = contingency_pack_sefer_arabasi
	copy.contingency_evade_combat = contingency_evade_combat
	return copy


static func format_opening_tactic(tactic: GameEnums.OpeningTactic) -> String:
	match tactic:
		GameEnums.OpeningTactic.DUST_SCREEN_FEINT:
			return "Toz Perdesi Yanıltması"
		GameEnums.OpeningTactic.NIGHT_STORM_RAID:
			return "Gece / Fırtına Baskını"
		GameEnums.OpeningTactic.DIRECT_WEDGE_CHARGE:
			return "Doğrudan Kama Hücumu"
		_:
			return "Yelme Taciz Atışı"


static func format_decisive_maneuver(maneuver: GameEnums.DecisiveManeuver) -> String:
	match maneuver:
		GameEnums.DecisiveManeuver.TOLGAMA_DOUBLE_ENVELOPMENT:
			return "Tolgama Çift Kanat"
		GameEnums.DecisiveManeuver.BORU_HEAVY_WEDGE:
			return "Börü Ağır Kama"
		GameEnums.DecisiveManeuver.WAGON_CIRCLE_LAAGER:
			return "Araba Kalesi Çemberi"
		GameEnums.DecisiveManeuver.TONYUKUK_WATER_CARAVAN_ATTRITION:
			return "Tonyukuk Su/Kervan Yıpratma"
		_:
			return "Kurt Kapanı Sahte Ricat"


func format_summary() -> String:
	return "%s [M %%%.0f / K %%%.0f / İ %%%.0f] · %s -> %s" % [
		display_name,
		center_ratio * 100.0,
		flank_ratio * 100.0,
		reserve_ratio * 100.0,
		format_opening_tactic(opening_tactic),
		format_decisive_maneuver(decisive_maneuver),
	]
