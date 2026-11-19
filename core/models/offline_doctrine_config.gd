class_name OfflineDoctrineConfig
extends RefCounted
## Core model (rank 2). Stored rule configuration for an army's Phase 18
## **Bozkır Nöbeti (Offline & Standby Doctrine)** configured via CommandBus.

var army_id: int = 1
var player_id: int = 1
var trigger_condition: GameEnums.OfflineDoctrineTrigger = GameEnums.OfflineDoctrineTrigger.ENEMY_POWER_RATIO_EXCEEDED
var power_ratio_threshold: float = 1.5
var low_supply_threshold: float = 0.20
var action_tactic: GameEnums.TuranTacticPhase = GameEnums.TuranTacticPhase.FEIGNED_RETREAT_LURE
var pack_sefer_arabasi: bool = true
var evade_combat: bool = true
var target_terrain_class: GameEnums.TerrainClass = GameEnums.TerrainClass.SIK_ORMAN
var target_geography_class: GameEnums.RegionGeographyClass = GameEnums.RegionGeographyClass.FOREST_EDGE


static func format_trigger_label(trigger: GameEnums.OfflineDoctrineTrigger, ratio_threshold: float, supply_threshold: float) -> String:
	match trigger:
		GameEnums.OfflineDoctrineTrigger.LOW_SUPPLY_OR_AMMO:
			return "İkmal / Sadak <= %%%.0f" % (supply_threshold * 100.0)
		GameEnums.OfflineDoctrineTrigger.SHELTER_IN_KISLAK:
			return "Kış / Zud Fırtınası"
		GameEnums.OfflineDoctrineTrigger.ORDER_TIMED_OUT_OFFLINE:
			return "Ulak / Çevrimdışı Aşım"
		GameEnums.OfflineDoctrineTrigger.NONE:
			return "Pasif Nöbet"
		_:
			return "Düşman Güç >= %.1fx" % ratio_threshold


static func format_action_label(tactic: GameEnums.TuranTacticPhase, pack_cart: bool, evade: bool) -> String:
	var tactic_name: String = "Sahte Ricat"
	match tactic:
		GameEnums.TuranTacticPhase.RECON_DUST_SCREEN:
			tactic_name = "Toz Perdesi"
		GameEnums.TuranTacticPhase.WHISTLING_ARROW_HARASSMENT:
			tactic_name = "Islıklı Ok Vur-Kaç"
		GameEnums.TuranTacticPhase.CRESCENT_ENCIRCLEMENT_TRAP:
			tactic_name = "Hilal Pusu"
		GameEnums.TuranTacticPhase.BORU_SHOCK_ANNIHILATION:
			tactic_name = "Börü Karşı Taarruz"
		_:
			tactic_name = "Sahte Ricat"
	var suffix: String = " + Sefer Arabası" if pack_cart else (" (Geri Çekil)" if evade else " (Kargı Hücum)")
	return tactic_name + suffix


static func format_target_label(terrain_cls: GameEnums.TerrainClass, geo_cls: GameEnums.RegionGeographyClass) -> String:
	if geo_cls == GameEnums.RegionGeographyClass.SHELTERED_VALLEY_KISLAK:
		return "Kışlak Vadisi"
	match terrain_cls:
		GameEnums.TerrainClass.DAMARLI_YAMAC:
			return "Damarlı Yamaç"
		GameEnums.TerrainClass.HAKIMIYET_PLATOSU:
			return "Hakimiyet Platosu"
		GameEnums.TerrainClass.BEREKET_HAVZASI:
			return "Bereket Havzası"
		_:
			return "Sık Orman"


func format_summary() -> String:
	return "EĞER [%s] -> YAP [%s] -> HEDEF [%s]" % [
		format_trigger_label(trigger_condition, power_ratio_threshold, low_supply_threshold),
		format_action_label(action_tactic, pack_sefer_arabasi, evade_combat),
		format_target_label(target_terrain_class, target_geography_class),
	]
