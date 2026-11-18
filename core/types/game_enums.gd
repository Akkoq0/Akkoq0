class_name GameEnums
extends RefCounted
## Foundation layer (rank 0). Shared, dependency-free enumerations.
##
## Every other layer may depend on this file; this file depends on nothing.

## The two simulation/presentation layers of the world.
enum WorldLayer {
	MACRO = 0, ## Strategic map of regions (armies, supply lines).
	MICRO = 1, ## Settlement zone inside a single macro region (buildings, ore nodes).
}

## Strict terrain typing shared by macro regions and micro tiles.
enum TerrainType {
	STEPPE = 0,
	FOREST = 1,
	MOUNTAIN = 2,
	RIVER = 3,
	DESERT = 4,
	TUNDRA = 5,
	HILLS = 6,
	LAKE = 7,
}

## Tactical steppe terrain archetypes for combat & ambush bonuses.
enum TerrainClass {
	BEREKET_HAVZASI = 0, ## Open fertile basin: cavalry charge momentum bonus.
	HAKIMIYET_PLATOSU = 1, ## High plateau: elevated bow range & arrow damage bonus.
	SIK_ORMAN = 2, ## Dense forest: ambush concealment & Crescent trap seal.
	DAMARLI_YAMAC = 3, ## Veined rocky slope: chokepoint defense & trap seal.
}

## High-level application state machine.
enum GameState {
	BOOT = 0,
	LOADING = 1,
	PLAYING = 2,
	PAUSED = 3,
	GAME_OVER = 4,
}

## Steppe calendar.
enum SeasonType {
	SPRING = 0, ## Bahar
	SUMMER = 1, ## Yaz
	AUTUMN = 2, ## Güz
	WINTER = 3, ## Kış / Zud
}

## 5-stage deterministic Turan Tactic finite state machine phases.
enum TuranTacticPhase {
	RECON_DUST_SCREEN = 0, ## Keşif ve Toz Perdesi
	WHISTLING_ARROW_HARASSMENT = 1, ## Islıklı Ok Yağmuru & Vur-Kaç
	FEIGNED_RETREAT_LURE = 2, ## Sahte Ricat & Bozkır Çekimi
	CRESCENT_ENCIRCLEMENT_TRAP = 3, ## Hilal Kapanı & Pusu Kıskacı
	BORU_SHOCK_ANNIHILATION = 4, ## Börü Ağır Kargı İmhası
}

## High-level nomadic military doctrines.
enum TacticalDoctrineType {
	STANDARD_CHARGE = 0,
	FEIGNED_RETREAT = 1,
	CRESCENT_ENCIRCLEMENT = 2,
	STEPPE_AMBUSH = 3,
}

## Vectorial engagement sector derived from attack vs facing dot product.
enum CombatEngagementAngle {
	FRONT = 0, ## 1.0x damage, 1.0x cohesion destruction.
	FLANK = 1, ## 1.45x damage, 2.0x cohesion destruction.
	REAR = 2, ## 2.1x damage, 2.0x cohesion destruction + instant panic.
}

## Operational connectivity state of an army's supply corridor.
enum SupplyLineStatus {
	CONNECTED = 0,
	UNCONNECTED = 1,
	ISOLATED = 2, ## Active convoy interdicted / severed by raiders.
}

## Inter-dynasty diplomatic posture on the steppe.
enum DiplomaticStance {
	TRUCE = 0, ## Ateşkes / Elçi Dokunulmazlığı
	BORDER_SKIRMISH = 1, ## Sınır Boyu Akınları
	TOTAL_WAR_GREAT_RAID = 2, ## Büyük Yağma Dönemi (Total Savaş)
}

## Zud / Winter biological health status of an army or settlement camp.
enum EpidemicState {
	HEALTHY = 0,
	OUTBREAK_EPIDEMIC = 1, ## Bozkır Vebası / Salgın Hastalık
	PURIFIED = 2, ## Kurgan / Şifahane Arınma Ritüeli Tamamlandı
}

## Neighboring dynasty attitude derived from the Phase 5 Threat Matrix.
enum DynastyAttitude {
	ALLY = 0, ## Müttefik
	NEUTRAL = 1, ## Tarafsız
	THREATENING = 2, ## Tehditkar
	HOSTILE = 3, ## Düşman
}

## Strategic crisis dilemma options presented when Ak Sakallılar Konseyi convenes (Kut < 30).
enum CouncilDilemmaChoice {
	TRADITION = 0, ## Töreye Bağlılık: +Kut, -Ekonomik Gelir, -Ordu Hızı
	EXPANSION = 1, ## Yağma ve Sefer Serbestisi: +Askeri Moral, +Ganimet, -Hanedan Diplomasisi
	SACRIFICE = 2, ## Hazine Fedakarlığı: -Çelik, -Altın/Gümüş, +Halk Sadakati / Kut
}

## Phase 6 nomadic worker detachment (`Oymak İşçileri`) gathering state machine.
enum WorkerGatherState {
	IDLE = 0,
	WALKING_TO_RESOURCE = 1, ## Walking from GerCamp to nearest 7-ore node or forest
	HARVESTING = 2, ## Extracting stone, iron, coal, or wood
	HAULING_TO_GER_CAMP = 3, ## Physical caravan movement hauling cargo back to GerCamp
}

## Phase 6 deterministic AI Commander & rogue warband strategic behavior loop.
enum AICommanderPhase {
	GATHER_RESOURCES = 0, ## 1. Kaynak ve erzak birikimi
	UPGRADE_FORGE = 1, ## 2. Göçebe demir ocağı ve pusat geliştirme
	LAUNCH_RAID = 2, ## 3. Oyuncu ikmal hatlarına veya obasına Turan formasyonunda baskın
}

## Phase 7 Macro region seasonal pasture & grazing health status.
enum PastureCondition {
	LUSH = 0, ## Gür Otlak: %100 et/süt üretimi, sağlıklı yılkı ve koyun sürüleri
	GRAZED = 1, ## Yıpranmış Mera: Kapasite azalıyor
	DEPLETED_STARVING = 2, ## Çoraklaşmış Mera (Overgrazed): Hayvanlar zayıflar (starving_livestock), et/süt durur, Sefer Arabası göçü zorunlu
}

## Phase 7 Steppe atmospheric wind & storm regime for arrow ballistics.
enum WindWeatherState {
	CALM = 0, ## Dingin Bozkır Havası
	TAILWIND_BREEZE = 1, ## Arkadan Esen Uygun Rüzgar (+%25 menzil, yüksek isabet)
	PRE_ZUD_GALE_STORM = 2, ## Zud Öncesi Şiddetli Bora / Fırtına (düşük menzil, zayıf ıslıklı ok morali, yüksek sadak tüketimi)
}

## Phase 8 Dynamic behavioral Sovereignty Alignment (non-locking sandbox evolution).
enum SovereigntyAlignment {
	ULU_KAGAN_TORE_GUARDIAN = 0, ## Ulu Kağan & Töre Koruyucusu (Yüksek Kut, Konsey ve Töre uyumu)
	STEPPE_RAIDER_WARLORD = 1, ## Bozkır Akıncısı & Yağma Beyi (Akın, İkmal Kesme, Toy Ganimeti ve Şöhret)
	NOMADIC_MERCHANT_FORGEMASTER = 2, ## Göçebe Tüccar & Demirci Hanedanı (7-Cevher Rafinasyonu, Vergi, Sefer Arabası Üretim Ağı)
	REBEL_INDEPENDENT_CLAN = 3, ## Asi / Bağımsız Oymak (Konseye/Otoriteye Başkaldırı, Özerk Bozkır Yasası)
}

## Phase 8 Player intervention choices in autonomous inter-faction steppe conflicts.
enum EmergentInterventionStance {
	NEUTRAL_TRADE_PROFITEER = 0, ## Tarafsız Kalıp Silah/Cevher Ticareti Yapma
	JOIN_ATTACKER = 1, ## Saldıran Hanedanın Yanında Savaşa Girme
	JOIN_DEFENDER = 2, ## Savunan Hanedanın Yanında Savaşa Girme
	OPPORTUNISTIC_STRIKE_BOTH = 3, ## İki Tarafın Yıpranmasını Bekleyip Son Darbeyi Vurma
}

## Phase 8 Modular army detachment roles when splitting forces (`SplitDetachForceCommand`).
enum DetachmentRole {
	VANGUARD_MAIN = 0, ## Ana Ordu Kolu
	FAST_CAVALRY_RECON_RAIDER = 1, ## Hızlı Süvari Keşif ve Akın Müfrezesi (+Hız Çarpanı)
	SUPPLY_ESCORT_GUARD = 2, ## İkmal ve Yılkı Kervanı Koruma Birliği
	OUTPOST_GARRISON = 3, ## İleri Karakol / Ocak Muhafız Birliği
}

## Phase 9 Major steppe cataclysm archetypes (`CataclysmEngine`).
enum CataclysmType {
	NONE = 0,
	KARA_ZUD_ICE_TRAP = 1, ## Kara Zud ve Buz Kapanı: Mera donması, Yılkı ve ikmal kervanı felci
	STEPPE_WILDFIRE_SCORCH = 2, ## Bozkır Yangını ve Kurak Rüzgar: Otlak ve Sık Orman pusu örtüsü yangını
	GREAT_FLOOD_QUAKE_EXODUS = 3, ## Büyük Göç Dalgası ve Yıkım Depremi / Sel Taşkını: Yapısal hasar ve mülteci akını
}

## Phase 9 Intra-dynasty kinship plot & betrayal escalation stages (`KinshipIntrigueManager`).
enum IntriguePlotStage {
	LOYAL_CALM = 0, ## Sadık ve Dengeli Boy Beyi
	FACTION_PLOT_BREWING = 1, ## Gizli Hizipleşme (faction_plot)
	DEFECTION_OR_SABOTAGE = 2, ## Ordu/Kaynak Çekerek Kopuş (defection) ve İkmal Sabotajı
	INTERNAL_UPRISING = 3, ## Açık İç Ayaklanma ve Taht/Otağ Darbesi (internal_uprising)
}

## Phase 9 Open-ended player responses to kinship intrigue and betrayal.
enum IntrigueResolutionAction {
	BESTOW_TITLE_AND_TOY_SHARE = 0, ## Ödül, Ünvan ve Ülüş/Toy Ganimeti Dağıtma
	SUPPRESS_WITH_LOYAL_GUARD = 1, ## Sadık Muhafız Birlikleriyle Bastırma
	NEGOTIATE_KINSHIP_BALANCE = 2, ## Kan Bağı Müzakeresi ve Konsey Uzlaşısı
}

## Bit flags (1 << WorldLayer) used by `@export_flags` layer masks.
const LAYER_FLAG_MACRO: int = 1 << WorldLayer.MACRO
const LAYER_FLAG_MICRO: int = 1 << WorldLayer.MICRO


## Returns true when `layer_mask` contains the bit for `layer`.
static func layer_mask_has(layer_mask: int, layer: WorldLayer) -> bool:
	return (layer_mask & (1 << layer)) != 0






