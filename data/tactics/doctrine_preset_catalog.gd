class_name DoctrinePresetCatalog
extends RefCounted
## Data factory (rank 1). Produces fresh, validated instances of all 5 canonical
## Ötüken modular steppe battle doctrines linked to base TacticalDoctrineData `.tres` assets.

const FEIGNED_RETREAT_PATH: String = "res://data/tactics/feigned_retreat.tres"
const STANDARD_CHARGE_PATH: String = "res://data/tactics/standard_charge.tres"
const CRESCENT_ENCIRCLEMENT_PATH: String = "res://data/tactics/crescent_encirclement.tres"
const STEPPE_AMBUSH_PATH: String = "res://data/tactics/steppe_ambush.tres"


static func get_all_preset_ids() -> Array[GameEnums.BattleDoctrinePresetId]:
	return [
		GameEnums.BattleDoctrinePresetId.KURT_KAPANI,
		GameEnums.BattleDoctrinePresetId.BORU_KAMASI,
		GameEnums.BattleDoctrinePresetId.TOLGAMA_KISKACI,
		GameEnums.BattleDoctrinePresetId.ARABA_KALESI,
		GameEnums.BattleDoctrinePresetId.TONYUKUK_YIPRATMASI,
	]


static func create_all_presets() -> Array[BattleDoctrineResource]:
	var list: Array[BattleDoctrineResource] = []
	for pid: GameEnums.BattleDoctrinePresetId in get_all_preset_ids():
		list.append(create_preset(pid))
	return list


static func create_by_id(doctrine_id: StringName) -> BattleDoctrineResource:
	match doctrine_id:
		&"boru_kamasi":
			return create_preset(GameEnums.BattleDoctrinePresetId.BORU_KAMASI)
		&"tolgama_kiskaci":
			return create_preset(GameEnums.BattleDoctrinePresetId.TOLGAMA_KISKACI)
		&"araba_kalesi":
			return create_preset(GameEnums.BattleDoctrinePresetId.ARABA_KALESI)
		&"tonyukuk_yipratmasi":
			return create_preset(GameEnums.BattleDoctrinePresetId.TONYUKUK_YIPRATMASI)
		_:
			return create_preset(GameEnums.BattleDoctrinePresetId.KURT_KAPANI)


static func create_preset(preset_id: GameEnums.BattleDoctrinePresetId) -> BattleDoctrineResource:
	var doc: BattleDoctrineResource = BattleDoctrineResource.new()
	match preset_id:
		GameEnums.BattleDoctrinePresetId.BORU_KAMASI:
			doc.doctrine_id = &"boru_kamasi"
			doc.preset_id = GameEnums.BattleDoctrinePresetId.BORU_KAMASI
			doc.display_name = "Börü Kaması"
			doc.description = "Zırhlı merkez kamasıyla ince merkez hatlarını yarıp dağıtır; çamur, dik yamaç ve fırtınada ağır yorgunluk riski taşır."
			doc.turan_doctrine = ResourceLoader.load(STANDARD_CHARGE_PATH) as TacticalDoctrineData
			doc.is_heavy_armor_doctrine = true
			doc.center_ratio = 0.60
			doc.flank_ratio = 0.20
			doc.reserve_ratio = 0.20
			doc.opening_tactic = GameEnums.OpeningTactic.DIRECT_WEDGE_CHARGE
			doc.decisive_maneuver = GameEnums.DecisiveManeuver.BORU_HEAVY_WEDGE
			doc.contingency_trigger = GameEnums.OfflineDoctrineTrigger.ENEMY_POWER_RATIO_EXCEEDED
			doc.contingency_power_ratio_threshold = 1.85
			doc.contingency_low_supply_threshold = 0.20
			doc.contingency_action_tactic = GameEnums.TuranTacticPhase.BORU_SHOCK_ANNIHILATION
			doc.contingency_target_terrain_class = GameEnums.TerrainClass.BEREKET_HAVZASI
			doc.contingency_target_geography_class = GameEnums.RegionGeographyClass.SACRED_CORE
			doc.contingency_pack_sefer_arabasi = false
			doc.contingency_evade_combat = false

		GameEnums.BattleDoctrinePresetId.TOLGAMA_KISKACI:
			doc.doctrine_id = &"tolgama_kiskaci"
			doc.preset_id = GameEnums.BattleDoctrinePresetId.TOLGAMA_KISKACI
			doc.display_name = "Tolgama Kıskacı"
			doc.description = "Zayıf tutulmuş merkezle düşmanı içeri çekip devasa sağ ve sol kanatlarla çifte kuşatma kurar."
			doc.turan_doctrine = ResourceLoader.load(CRESCENT_ENCIRCLEMENT_PATH) as TacticalDoctrineData
			doc.is_heavy_armor_doctrine = false
			doc.center_ratio = 0.20
			doc.flank_ratio = 0.60
			doc.reserve_ratio = 0.20
			doc.opening_tactic = GameEnums.OpeningTactic.DUST_SCREEN_FEINT
			doc.decisive_maneuver = GameEnums.DecisiveManeuver.TOLGAMA_DOUBLE_ENVELOPMENT
			doc.contingency_trigger = GameEnums.OfflineDoctrineTrigger.LOW_SUPPLY_OR_AMMO
			doc.contingency_power_ratio_threshold = 1.50
			doc.contingency_low_supply_threshold = 0.25
			doc.contingency_action_tactic = GameEnums.TuranTacticPhase.CRESCENT_ENCIRCLEMENT_TRAP
			doc.contingency_target_terrain_class = GameEnums.TerrainClass.DAMARLI_YAMAC
			doc.contingency_target_geography_class = GameEnums.RegionGeographyClass.HIGH_PLATEAU_YAYLAK
			doc.contingency_pack_sefer_arabasi = true
			doc.contingency_evade_combat = true

		GameEnums.BattleDoctrinePresetId.ARABA_KALESI:
			doc.doctrine_id = &"araba_kalesi"
			doc.preset_id = GameEnums.BattleDoctrinePresetId.ARABA_KALESI
			doc.display_name = "Araba Kalesi"
			doc.description = "Sefer arabalarını dairesel siper çemberine çevirerek manevra hızından vazgeçer, ancak yan (1.45x) ve arka (2.1x) kuşatma hasarını büyük ölçüde sönümler."
			doc.turan_doctrine = ResourceLoader.load(STEPPE_AMBUSH_PATH) as TacticalDoctrineData
			doc.is_heavy_armor_doctrine = false
			doc.center_ratio = 0.50
			doc.flank_ratio = 0.20
			doc.reserve_ratio = 0.30
			doc.opening_tactic = GameEnums.OpeningTactic.YELME_HARASSMENT
			doc.decisive_maneuver = GameEnums.DecisiveManeuver.WAGON_CIRCLE_LAAGER
			doc.laager_mobility_multiplier = 0.55
			doc.laager_flank_damping = 0.65
			doc.laager_rear_damping = 0.70
			doc.contingency_trigger = GameEnums.OfflineDoctrineTrigger.SHELTER_IN_KISLAK
			doc.contingency_power_ratio_threshold = 1.40
			doc.contingency_low_supply_threshold = 0.20
			doc.contingency_action_tactic = GameEnums.TuranTacticPhase.RECON_DUST_SCREEN
			doc.contingency_target_terrain_class = GameEnums.TerrainClass.DAMARLI_YAMAC
			doc.contingency_target_geography_class = GameEnums.RegionGeographyClass.SHELTERED_VALLEY_KISLAK
			doc.contingency_pack_sefer_arabasi = true
			doc.contingency_evade_combat = true

		GameEnums.BattleDoctrinePresetId.TONYUKUK_YIPRATMASI:
			doc.doctrine_id = &"tonyukuk_yipratmasi"
			doc.preset_id = GameEnums.BattleDoctrinePresetId.TONYUKUK_YIPRATMASI
			doc.display_name = "Tonyukuk Yıpratması"
			doc.description = "Meydan savaşını reddedip su kuyularını ve kervan ikmal hatlarını vurarak büyük orduları tüketir; kervansız küçük akın birliklerine karşı zayıftır."
			doc.turan_doctrine = ResourceLoader.load(STEPPE_AMBUSH_PATH) as TacticalDoctrineData
			doc.is_heavy_armor_doctrine = false
			doc.center_ratio = 0.25
			doc.flank_ratio = 0.45
			doc.reserve_ratio = 0.30
			doc.opening_tactic = GameEnums.OpeningTactic.NIGHT_STORM_RAID
			doc.decisive_maneuver = GameEnums.DecisiveManeuver.TONYUKUK_WATER_CARAVAN_ATTRITION
			doc.contingency_trigger = GameEnums.OfflineDoctrineTrigger.ORDER_TIMED_OUT_OFFLINE
			doc.contingency_power_ratio_threshold = 1.35
			doc.contingency_low_supply_threshold = 0.25
			doc.contingency_action_tactic = GameEnums.TuranTacticPhase.WHISTLING_ARROW_HARASSMENT
			doc.contingency_target_terrain_class = GameEnums.TerrainClass.SIK_ORMAN
			doc.contingency_target_geography_class = GameEnums.RegionGeographyClass.FOREST_EDGE
			doc.contingency_pack_sefer_arabasi = true
			doc.contingency_evade_combat = true

		_:
			doc.doctrine_id = &"kurt_kapani"
			doc.preset_id = GameEnums.BattleDoctrinePresetId.KURT_KAPANI
			doc.display_name = "Kurt Kapanı"
			doc.description = "Yelme tacizinin ardından sahte geri çekilmeyle kibirli veya deneyimsiz düşmanı pusuya çekip düzenini ve zırhını çökertir."
			doc.turan_doctrine = ResourceLoader.load(FEIGNED_RETREAT_PATH) as TacticalDoctrineData
			doc.is_heavy_armor_doctrine = false
			doc.center_ratio = 0.25
			doc.flank_ratio = 0.50
			doc.reserve_ratio = 0.25
			doc.opening_tactic = GameEnums.OpeningTactic.YELME_HARASSMENT
			doc.decisive_maneuver = GameEnums.DecisiveManeuver.KURT_KAPANI_FEIGNED_RETREAT
			doc.contingency_trigger = GameEnums.OfflineDoctrineTrigger.ENEMY_POWER_RATIO_EXCEEDED
			doc.contingency_power_ratio_threshold = 1.45
			doc.contingency_low_supply_threshold = 0.20
			doc.contingency_action_tactic = GameEnums.TuranTacticPhase.FEIGNED_RETREAT_LURE
			doc.contingency_target_terrain_class = GameEnums.TerrainClass.SIK_ORMAN
			doc.contingency_target_geography_class = GameEnums.RegionGeographyClass.FOREST_EDGE
			doc.contingency_pack_sefer_arabasi = true
			doc.contingency_evade_combat = true
	return doc
