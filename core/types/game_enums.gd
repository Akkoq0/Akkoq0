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

## Multi-system Causal Chain archetypes (`CausalChainEngine`).
enum CausalChainArchetype {
	ECOLOGICAL_LOGISTICS_COLLAPSE = 0, ## Otlak Tükenmesi -> Zud Erzak Krizi -> Yılkı Kesimi -> Hilal Kapanı Sarkması -> Moral Kırılması & Çeri Kopuşu
	COMBAT_FATIGUE_PSYCHOLOGICAL_ROUT = 1, ## Muharebe Yorgunluğu -> Momentum Kaybı -> Seçkin Öncü Kaybı & Cascade Rout -> 2.1x Arka Darbe & Kut Erimesi
	POLITICAL_ESPIONAGE_COALITION = 2, ## Düşük Kut / Toy Krizi -> Çeri Kopuşu & Koalisyon Tehdidi -> Casusluk veya Şöhret (>=40) ile Zincir Kırılması
	EPIDEMIC_KURGAN_PURIFICATION = 3, ## Zud + Food<=0 -> Salgın (0.50x Hız, %8 Kırım) -> Kurgan Arınması (12 Kut) ile Durdurma
}

## Player counterplay actions that break or reverse an active causal chain.
enum CausalCounterplayAction {
	NONE = 0, ## Karşı Hamle Yok (Zincir Tam Sonucuna Ulaşır)
	MIGRATE_SEFER_ARABASI_OR_RESUPPLY = 1, ## Sefer Arabası Göçü veya İkmal Hattı Onarımı
	ROTATE_RESERVE_OR_TACTICAL_WITHDRAW = 2, ## İhtiyat Rotasyonu veya Taktik Geri Çekilme
	ESPIONAGE_OR_GLORY_WARBAND_RECRUIT = 3, ## Sık Orman Casusluğu veya Şöhret (>=40) ile Çeri Geri Kazanımı
	KURGAN_PURIFICATION_RITUAL = 4, ## Kurgan Şifahanesinde 12 Kut Bedeliyle Salgın Arınması
}

## Phase 18 Graduated Kurultay / Töre Peace server phases (`GracePeriodManager`).
enum TorePeaceStage {
	STAGE_1_FULL_TORE_PEACE = 0, ## 1-2. Gün: Saldırı ve yurt iddiası kilitli; keşif, NPC temizliği, sahipsiz Tuğ, rafinasyon, casusluk serbest
	STAGE_2_BORDER_SKIRMISH = 1, ## 3. Gün: Sınır düğümü süvari akınları açık; ana Oba/Yurt ve Kutsal Kurgan hâlâ kilitli
	STAGE_3_TOTAL_STEPPE = 2, ## 4. Gün+: Topyekûn Bozkır; tüm fetih, elçi, kan davası ve Kurgan mekanikleri açık
}

## Phase 18 Actions audited against graduated Töre Peace & personal protection rules.
enum ToreActionType {
	SCOUTING = 0,
	NPC_CLEANUP = 1,
	UNCLAIMED_NODE_TUG = 2,
	REFINING = 3,
	ESPIONAGE = 4,
	BORDER_NODE_RAID = 5,
	CORE_YURT_CLAIM = 6,
	KURGAN_CONTEST = 7,
	PLAYER_ATTACK = 8,
}

## Phase 18 Triggers for conditional offline / standing steppe watch behavior (`OfflineDoctrineComponent`).
enum OfflineDoctrineTrigger {
	NONE = 0,
	ENEMY_POWER_RATIO_EXCEEDED = 1, ## Rakip güç oranı >= eşik: Çatışma, Sefer Arabasını topla ve Sahte Ricat ile geri çekil
	LOW_SUPPLY_OR_AMMO = 2,
	ORDER_TIMED_OUT_OFFLINE = 3,
	SHELTER_IN_KISLAK = 4,
}

## Phase 19 Seasonal steppe region geography archetypes (`RegionData`).
enum RegionGeographyClass {
	HIGH_PLATEAU_YAYLAK = 0, ## Bahar/Yazda yüksek otlak & yılkı üremesi; Kışın donup ağır yıpranma cezası verir
	SHELTERED_VALLEY_KISLAK = 1, ## Kış/Zud döneminde korunaklı hayatta kalma merkezi
	FOREST_EDGE = 2, ## Odun & Sık Orman pusu sınırı
	SACRED_CORE = 3, ## Kutsal Kurgan barındıran stratejik özek bölge
}

## Phase 19 Strategic frontier sub-nodes inside each macro region (`BorderNode`).
enum BorderNodeType {
	ORE_QUARRY_NODE = 0, ## 7-Cevher Ocağı
	CARAVAN_PASS_NODE = 1, ## Kervan Geçidi
	RIVER_CROSSING_NODE = 2, ## Nehir Geçiş Kıyısı
	WATCHTOWER_HILL_NODE = 3, ## Gözetleme Tepesi
}

## Phase 19 Contested Yurt Claim FSM states (`ClaimContestationFSM`).
enum ClaimContestationStage {
	NONE = 0,
	WINDOW_OPEN = 1, ## Çekişme penceresi (12-24 saat eşdeğeri) açık
	PITCHED_BATTLE_ACCEPTED = 2, ## Savunan Meydanı Kabul Etti
	TRIBUTE_FROZEN = 3, ## Ülüş/Haraç ile dondurulmuş iddia
	BLOOD_FEUD_TOTAL_WAR = 4, ## Elçi katli -> Kan Davası topyekûn savaş
	RESOLVED = 5,
}

## Phase 19 Three strategic defender reactions to a Yurt Claim (`RespondToYurtClaimCommand`).
enum ClaimDefenseResponse {
	ACCEPT_PITCHED_BATTLE = 0, ## Meydanı Kabul Et (Turan Taktiği ile kesin savaş)
	PAY_ULUS_TRIBUTE = 1, ## Ülüş / Haraç Öde (Çelik / Gök Demiri / Yılkı ile dondur)
	KILL_ENVOY_KAN_DAVASI = 2, ## Elçiyi Öldür -> Anında topyekûn savaş + ağır itibar/koalisyon cezası
}

## Phase 19 Post-conquest aftermath options (*Crusader* evolution).
enum ConquestAftermathChoice {
	SCORCHED_EARTH_PILLAGE = 0, ## Talan / Yakıp Geç (`Kavruk Bozkır`: Ganimet+Toy al, düşmana hız/ikmal cezalı yanık bölge bırak)
	HOLD_GARRISON_CONTROL = 1, ## %20 Denetimle Yurt Tut + Garnizon/Toy ile yükselt
	APPOINT_VASSAL_BEY = 2, ## Yerel Tâbi Bey atayarak istikrarı hızla artır
}

## Phase 20 Asymmetric collapse recovery FSM states (`CollapseRecoveryFSM`).
enum CollapseState {
	SOVEREIGN = 0, ## Normal independent Khaganate / Oba
	TRUCE_WITHDRAWAL = 1, ## Çift yönlü 18 saatlik kaçış & ateşkes penceresi
	VASSAL_BEYLIK = 2, ## Tâbi Beylik (%15-%25 haraç, Kut <= 50, hükümran gözetim & darbe çıkışı)
	HOMELESS_EXILE = 3, ## Yersiz Yurtsuz Mülteci Güç (sabit ocak yok, 160 tavan, hızlı/ucuz, umut/sadakat sayacı)
	FRONTIER_MARCH_LORD = 4, ## Uç Beyliği Sürgünü (dış sınırda zayıf otlak & sert Zud ile temiz başlangıç)
	DYNASTY_EXTINCT = 5, ## Hanedan Sönümü (son araba düşerse / Umut 0'lanırsa bekleme + sıfır Şöhretle yeniden doğuş)
}

## Phase 20 Player strategic recovery paths upon defeat.
enum CollapsePathChoice {
	SUBMIT_VASSAL = 0,
	FLEE_HOMELESS_EXILE = 1,
	REBUILD_AT_FRONTIER = 2,
}

## Phase 21 Courier physical dispatch FSM (`CourierDispatchSystem`).
enum CourierStatus {
	IN_TRANSIT = 0,
	DELIVERED = 1,
	AMBUSHED_LOST = 2,
}

## Phase 21 Non-teleporting physical caravan states (`CaravanLogisticsManager`).
enum CaravanCargoState {
	EN_ROUTE = 0,
	DELIVERED = 1,
	INTERCEPTED = 2,
}

## Phase 22 Vassal Bey personality traits (`GovernanceManager`).
enum VassalPersonalityTrait {
	AMBITIOUS = 0, ## Hırslı: yüksek özerklik & darbe fırsatı arar
	LOYAL = 1, ## Sadık: küçük ülüş açıklarını tolere eder, düşük sabotaj
	CAUTIOUS = 2, ## İhtiyatlı: tehlike artınca asker sakınır
	GREEDY = 3, ## Tamahkâr: ülüş eksikliğinde ağır sessiz sabotaj ve gecikme uygular
}

## Phase 22 Diplomatic Amanat (hostage / pledge) instrument types (`ReputationAndPactSystem`).
enum AmanatHostageType {
	COMMANDER_HOSTAGE = 0,
	HEIR_HOSTAGE = 1,
	JADE_TAMGA_SEAL = 2,
}

## Phase 23 Steppe water route sources (`WaterRouteManager`).
enum WaterSourceType {
	WELL = 0, ## Yeraltı kuyusu: kışın donmaz, Kavruk Bozkır / sabotajla kirletilebilir
	STEPPE_STREAM = 1, ## Açık bozkır deresi: Zud kışında yüzeyi donar
	OASIS_SPRING = 2, ## Korunaklı vahalar / kaplıca pınarı: kışın donmaya kısmen dirençli
}

## Phase 23 Dynamic scarcity market barter directions (`RegionalMarketEngine`).
enum BarterDirection {
	BUY_FROM_MARKET = 0,
	SELL_TO_MARKET = 1,
}

## Phase 24 Regency and Kurultay succession states (`SuccessionManager`).
enum RegencyStatus {
	STABLE_RULE = 0, ## Güçlü ve ergin hükümdar yönetiminde istikrarlı düzen
	AK_SAKALLILAR_REGENCY = 1, ## Çocuk/zayıf veliaht veya rehin Amanat nedeniyle Ak Sakallılar Konseyi naibliği
	KURULTAY_SUCCESSION_CRISIS = 2, ## Veraset krizi: Hırslı beylerin hak iddiası, sadakat düşüşü ve bölge ihtilafı
}

## Phase 24 Commander legacy specializations earned across campaigns (`CommanderProfile`).
enum CommanderTrait {
	NONE = 0,
	BOZKIR_KURDU = 1, ## Bozkır Kurdu: Turan taktiği hızı ve kanat çevikliği bonusu
	BORU_YUREK = 2, ## Börü Yürek: Cascade rout paniğine karşı yüksek direnç ve şok
	KERVAN_GAZISI = 3, ## Kervan Gazisi: İkmal ve uzun sefer dayanıklılığı
	SAGIR_YARA = 4, ## Ağır Savaş Yarası: Ek muharebe gaziliği ancak süvari hızında hafif aksama
}

## Phase 24 Strategic responses to resolve an active Kurultay succession crisis.
enum SuccessionCrisisResponse {
	COUNCIL_REGENCY_TRANSITION = 0, ## Ak Sakallılar Konseyi naibliğinde kademeli geçiş
	PURGE_AMBITIOUS_CLAIMANTS = 1, ## Muhalif beyleri sert bastırma (Yüksek Dehşet, gümüş ve zayiat bedeli)
	CEDE_AUTONOMY_AND_ULUS = 2, ## Ülüş ve özerklik taviziyle tahtı yatıştırma (Düşük Kut & vergi bedeli)
}

## Bit flags (1 << WorldLayer) used by `@export_flags` layer masks.
const LAYER_FLAG_MACRO: int = 1 << WorldLayer.MACRO
const LAYER_FLAG_MICRO: int = 1 << WorldLayer.MICRO


## Returns true when `layer_mask` contains the bit for `layer`.
static func layer_mask_has(layer_mask: int, layer: WorldLayer) -> bool:
	return (layer_mask & (1 << layer)) != 0







