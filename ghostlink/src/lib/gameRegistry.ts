// ─────────────────────────────────────────────────────────
// Meva HUD — Multi-Game Community Engine & Dynamic Role Registry
// ─────────────────────────────────────────────────────────
// Covers 18 premier esports titles + Chill/Community:
//   • Dynamic tactical roles, maps, callouts, and capacity presets
//   • 1-Click Server Templates (Streamer Hub, Scrim Clan, Fast Squad)
//   • 1-Click Channel Pills & Smart Tag-Based Channel Recommender

export type GameCategory =
  | 'moba'
  | 'fps'
  | 'br'
  | 'sports'
  | 'strategy'
  | 'mmo'
  | 'chill';

export type SupportedGameId =
  | 'lol'
  | 'cs2'
  | 'valorant'
  | 'dota2'
  | 'pubg'
  | 'mlbb'
  | 'wildrift'
  | 'pubgm'
  | 'r6'
  | 'apex'
  | 'warzone'
  | 'fortnite'
  | 'overwatch2'
  | 'tft'
  | 'rocketleague'
  | 'eafc'
  | 'standoff2'
  | 'albion'
  | 'chill';

export interface GameRoleDef {
  key: string;
  label: string;
  shortLabel: string;
  badgeClass: string;
  desc: string;
}

export interface GameDef {
  id: SupportedGameId;
  name: string;
  shortName: string;
  category: GameCategory;
  defaultMax: number; // 0 = unlimited
  color: string;
  badgeBg: string;
  roles: GameRoleDef[];
  callouts: string[];
  maps: string[];
  tags: string[];
}

export const SUPPORTED_GAMES: Record<SupportedGameId, GameDef> = {
  lol: {
    id: 'lol',
    name: 'League of Legends (LoL)',
    shortName: 'LoL',
    category: 'moba',
    defaultMax: 5,
    color: '#0AC8B9',
    badgeBg: 'rgba(10, 200, 185, 0.15)',
    roles: [
      { key: 'JUNGLE', label: 'Ormancı (Jungle)', shortLabel: 'JUNGLE', badgeClass: 'bg-[#0B2A26] text-[#0AC8B9] border-[#10564D]', desc: 'Harita Kontrolü & Erken Baskı' },
      { key: 'MID', label: 'Orta Koridor (Mid)', shortLabel: 'MID', badgeClass: 'bg-[#2A180E] text-[#E68A4E] border-[#663A1E]', desc: 'Büyücü / Suikastçı & Hızlı Rotasyon' },
      { key: 'TOP', label: 'Üst Koridor (Top)', shortLabel: 'TOP', badgeClass: 'bg-[#2A0E1A] text-[#D65D9E] border-[#5E1A38]', desc: 'Dayanıklı Dövüşçü & Split-Push' },
      { key: 'ADC', label: 'Alt Taşıyıcı (ADC)', shortLabel: 'ADC', badgeClass: 'bg-[#3D0A14] text-[#E04856] border-[#7A121D]', desc: 'Yüksek Hasarlı Sürekli Menzilli Saldırı' },
      { key: 'SUPPORT', label: 'Destek (Support)', shortLabel: 'SUPPORT', badgeClass: 'bg-[#121E2A] text-[#5DA5D6] border-[#1E435E]', desc: 'Görüş Sağlama, Kalkan & Kitle Kontrol' },
      { key: 'FILL', label: 'Joker / Fill', shortLabel: 'FILL', badgeClass: 'bg-[#1A1A1E] text-[#A0A0A8] border-[#383842]', desc: 'Tüm Rollere Uyumlu Esnek Oyuncu' },
    ],
    callouts: ['Miss Mid (SS)', 'Baron / Ejder', 'Gank Bot', 'Ulti Hazır', 'Dive Yapalım', 'Geri Çekil'],
    maps: ["Sihirdar Vadisi", "ARAM (Sonsuz Uçurum)"],
    tags: ['#LoL', '#Dereceli-5v5', '#Tryhard', '#Vadi'],
  },
  cs2: {
    id: 'cs2',
    name: 'Counter-Strike 2 (CS2)',
    shortName: 'CS2',
    category: 'fps',
    defaultMax: 5,
    color: '#E09F3E',
    badgeBg: 'rgba(224, 159, 62, 0.15)',
    roles: [
      { key: 'IGL', label: 'In-Game Leader (IGL)', shortLabel: 'IGL', badgeClass: 'bg-[#3D0A14] text-[#E04856] border-[#7A121D]', desc: 'Taktik Komutan & Ducking Önceliği' },
      { key: 'ENTRY', label: 'Entry Fragger', shortLabel: 'ENTRY', badgeClass: 'bg-[#2A0E1A] text-[#D65D9E] border-[#5E1A38]', desc: 'İlk Temas & Alan Açıcı' },
      { key: 'AWP', label: 'AWP / Sniper', shortLabel: 'AWP', badgeClass: 'bg-[#2A180E] text-[#E68A4E] border-[#663A1E]', desc: 'Uzun Hat Keskin Nişancısı' },
      { key: 'LURKER', label: 'Lurker / Flank', shortLabel: 'LURKER', badgeClass: 'bg-[#121E2A] text-[#5DA5D6] border-[#1E435E]', desc: 'Arka Hat Avcısı & Sessiz Bilgi' },
      { key: 'SUPPORT', label: 'Support / Flash', shortLabel: 'SUPPORT', badgeClass: 'bg-[#1A1A1E] text-[#A0A0A8] border-[#383842]', desc: 'Flaş & Sis Yardımcısı' },
      { key: 'ANCHOR', label: 'Site Anchor', shortLabel: 'ANCHOR', badgeClass: 'bg-[#192418] text-[#6FCF97] border-[#294B2E]', desc: 'Bölgeyi Tek Başına Savunan Çapa' },
    ],
    callouts: ['Rotate B', 'Eco Round', 'Drop AWP', 'Force Buy', 'Rush A', 'Save Silah'],
    maps: ['Mirage', 'Dust II', 'Inferno', 'Nuke', 'Ancient', 'Anubis', 'Vertigo'],
    tags: ['#CS2', '#Premier', '#Faceit', '#Scrim'],
  },
  valorant: {
    id: 'valorant',
    name: 'Valorant',
    shortName: 'Valo',
    category: 'fps',
    defaultMax: 5,
    color: '#FF4655',
    badgeBg: 'rgba(255, 70, 85, 0.15)',
    roles: [
      { key: 'DUELIST', label: 'Düellocu (Duelist)', shortLabel: 'DUELIST', badgeClass: 'bg-[#3D0A14] text-[#FF4655] border-[#7A121D]', desc: 'İlk Kan & Hızlı Alan Baskısı' },
      { key: 'INITIATOR', label: 'Öncü (Initiator)', shortLabel: 'INITIATOR', badgeClass: 'bg-[#2A180E] text-[#E68A4E] border-[#663A1E]', desc: 'Düşman Taraması & Bilgi Alma' },
      { key: 'CONTROLLER', label: 'Kontrol Uzmanı (Smoke)', shortLabel: 'CONTROLLER', badgeClass: 'bg-[#121E2A] text-[#5DA5D6] border-[#1E435E]', desc: 'Görüş Kapatma & Sis Perdesi' },
      { key: 'SENTINEL', label: 'Gözcü (Sentinel)', shortLabel: 'SENTINEL', badgeClass: 'bg-[#192418] text-[#6FCF97] border-[#294B2E]', desc: 'Bölge Kilitleme & Arkacı Avı' },
      { key: 'IGL', label: 'Kaptan (IGL)', shortLabel: 'IGL', badgeClass: 'bg-[#2A0E1A] text-[#D65D9E] border-[#5E1A38]', desc: 'Taktik Karar & Ajan Koordinesi' },
      { key: 'FLEX', label: 'Esnek / Flex', shortLabel: 'FLEX', badgeClass: 'bg-[#1A1A1E] text-[#A0A0A8] border-[#383842]', desc: 'Her Role Uyumlu İkinci Destek' },
    ],
    callouts: ['Rotate B', 'Eco Round', 'Operator Bırak', 'Full Buy', 'Rush A', 'Spike Kur'],
    maps: ['Ascent', 'Bind', 'Haven', 'Lotus', 'Sunset', 'Abyss', 'Split'],
    tags: ['#Valorant', '#5Stack', '#Tryhard-Dereceli', '#Taktik'],
  },
  dota2: {
    id: 'dota2',
    name: 'Dota 2',
    shortName: 'Dota 2',
    category: 'moba',
    defaultMax: 5,
    color: '#F03E3E',
    badgeBg: 'rgba(240, 62, 62, 0.15)',
    roles: [
      { key: 'POS 1 (CARRY)', label: 'Pos 1 (Saf Taşıyıcı)', shortLabel: 'POS 1', badgeClass: 'bg-[#3D0A14] text-[#E04856] border-[#7A121D]', desc: 'Geç Oyun Taşıyıcısı & Farm Odağı' },
      { key: 'POS 2 (MID)', label: 'Pos 2 (Orta Koridor)', shortLabel: 'POS 2', badgeClass: 'bg-[#2A180E] text-[#E68A4E] border-[#663A1E]', desc: 'Hızlı Seviye & Erken Tempo' },
      { key: 'POS 3 (OFFLANE)', label: 'Pos 3 (Offlane / Tank)', shortLabel: 'POS 3', badgeClass: 'bg-[#2A0E1A] text-[#D65D9E] border-[#5E1A38]', desc: 'Takım Savaşı Başlatıcı & Tank' },
      { key: 'POS 4 (ROAMER)', label: 'Pos 4 (Gezgin Destek)', shortLabel: 'POS 4', badgeClass: 'bg-[#121E2A] text-[#5DA5D6] border-[#1E435E]', desc: 'Harita Baskısı & Erken Gank' },
      { key: 'POS 5 (HARD SUPP)', label: 'Pos 5 (Sert Destek)', shortLabel: 'POS 5', badgeClass: 'bg-[#1A1A1E] text-[#A0A0A8] border-[#383842]', desc: 'Totemler, Koruma & Taşıyıcı Dadılığı' },
    ],
    callouts: ['Miss Mid (SS)', 'Roshan', 'Smoke Gank', 'BKB Hazır', 'Buyback Var', 'Geri Çekil'],
    maps: ['Dota 2 Haritası'],
    tags: ['#Dota2', '#Ranked', '#Immortal', '#BattleCup'],
  },
  pubg: {
    id: 'pubg',
    name: 'PUBG: Battlegrounds',
    shortName: 'PUBG',
    category: 'br',
    defaultMax: 4,
    color: '#F2A900',
    badgeBg: 'rgba(242, 169, 0, 0.15)',
    roles: [
      { key: 'IGL', label: 'Squad Lideri (IGL)', shortLabel: 'IGL', badgeClass: 'bg-[#3D0A14] text-[#E04856] border-[#7A121D]', desc: 'Bölge Rotasyonu & Araç Planı' },
      { key: 'FRAGGER', label: 'Entry Fragger', shortLabel: 'FRAGGER', badgeClass: 'bg-[#2A0E1A] text-[#D65D9E] border-[#5E1A38]', desc: 'Yakın Mesafe Temas & Bina Kuşatma' },
      { key: 'SNIPER / DMR', label: 'DMR / Sniper', shortLabel: 'SNIPER', badgeClass: 'bg-[#2A180E] text-[#E68A4E] border-[#663A1E]', desc: 'Uzun Menzilli Hasar & Düşürme' },
      { key: 'SCOUT', label: 'Öncü Keşifçi (Scout)', shortLabel: 'SCOUT', badgeClass: 'bg-[#121E2A] text-[#5DA5D6] border-[#1E435E]', desc: 'Bilek & Yol Güzergah Kontrolü' },
      { key: 'SUPPORT', label: 'Medik / Destek', shortLabel: 'SUPPORT', badgeClass: 'bg-[#1A1A1E] text-[#A0A0A8] border-[#383842]', desc: 'Sis Mühimmatı & Kaldırma Desteği' },
    ],
    callouts: ['AirDrop Alalım', 'Zone Daralıyor', 'Düşman Pinglendi', 'Revive / Kaldır', 'Araç Buldum', 'Ev Pushla'],
    maps: ['Erangel', 'Miramar', 'Taego', 'Rondo', 'Vikendi', 'Deston'],
    tags: ['#PUBG', '#Squad', '#Dereceli', '#ChickenDinner'],
  },
  mlbb: {
    id: 'mlbb',
    name: 'Mobile Legends (MLBB)',
    shortName: 'MLBB',
    category: 'moba',
    defaultMax: 5,
    color: '#3B82F6',
    badgeBg: 'rgba(59, 130, 246, 0.15)',
    roles: [
      { key: 'JUNGLE', label: 'Ormancı / Retribution', shortLabel: 'JUNGLE', badgeClass: 'bg-[#0B2A26] text-[#0AC8B9] border-[#10564D]', desc: 'Canavar Avcısı & Hızlı Farm' },
      { key: 'MID', label: 'Büyücü Mid', shortLabel: 'MID', badgeClass: 'bg-[#2A180E] text-[#E68A4E] border-[#663A1E]', desc: 'Alan Büyüsü & Hasar' },
      { key: 'EXP LANE', label: 'EXP Koridoru', shortLabel: 'EXP', badgeClass: 'bg-[#2A0E1A] text-[#D65D9E] border-[#5E1A38]', desc: 'Ön Hat Savaşçısı' },
      { key: 'GOLD LANE', label: 'Altın Nişancı', shortLabel: 'GOLD', badgeClass: 'bg-[#3D0A14] text-[#E04856] border-[#7A121D]', desc: 'Geç Oyun Fiziksel Gücü' },
      { key: 'ROAMER', label: 'Tank / Roamer', shortLabel: 'ROAM', badgeClass: 'bg-[#121E2A] text-[#5DA5D6] border-[#1E435E]', desc: 'Harita Dolaşımı & Takım Kalkanı' },
      { key: 'FILL', label: 'Esnek / Fill', shortLabel: 'FILL', badgeClass: 'bg-[#1A1A1E] text-[#A0A0A8] border-[#383842]', desc: 'Her Kahramana Uyumlu' },
    ],
    callouts: ['Lord Alalım', 'Kaplumbağa', 'Gank Geliyor', 'Ulti Hazır', 'Kule Pushla', 'Geri Çekil'],
    maps: ['Şafak Vadisi'],
    tags: ['#MLBB', '#Mythic', '#Squad', '#Turnuva'],
  },
  wildrift: {
    id: 'wildrift',
    name: 'LoL: Wild Rift',
    shortName: 'Wild Rift',
    category: 'moba',
    defaultMax: 5,
    color: '#06B6D4',
    badgeBg: 'rgba(6, 182, 212, 0.15)',
    roles: [
      { key: 'JUNGLE', label: 'Ormancı', shortLabel: 'JUNGLE', badgeClass: 'bg-[#0B2A26] text-[#0AC8B9] border-[#10564D]', desc: 'Çarp & Objektif Baskısı' },
      { key: 'MID', label: 'Orta Koridor', shortLabel: 'MID', badgeClass: 'bg-[#2A180E] text-[#E68A4E] border-[#663A1E]', desc: 'Suikastçı & Büyücü' },
      { key: 'BARON LANE', label: 'Baron Koridoru', shortLabel: 'BARON', badgeClass: 'bg-[#2A0E1A] text-[#D65D9E] border-[#5E1A38]', desc: 'Solo Dövüşçü' },
      { key: 'DRAGON LANE', label: 'Ejder Nişancısı', shortLabel: 'DRAGON', badgeClass: 'bg-[#3D0A14] text-[#E04856] border-[#7A121D]', desc: 'Nişancı Hasar Taşıyıcısı' },
      { key: 'SUPPORT', label: 'Destek', shortLabel: 'SUPP', badgeClass: 'bg-[#121E2A] text-[#5DA5D6] border-[#1E435E]', desc: 'Koruma & Şifa' },
    ],
    callouts: ['Ejder Geldi', 'Baron Nashor', 'Gank Bot', 'Ulti Var', 'Kule İttir', 'Geri Dön'],
    maps: ['Vadi Haritası'],
    tags: ['#WildRift', '#Ranked', '#Duo', '#MobaMobile'],
  },
  pubgm: {
    id: 'pubgm',
    name: 'PUBG Mobile',
    shortName: 'PUBG-M',
    category: 'br',
    defaultMax: 4,
    color: '#F97316',
    badgeBg: 'rgba(249, 115, 22, 0.15)',
    roles: [
      { key: 'IGL', label: 'Takım Kaptanı', shortLabel: 'IGL', badgeClass: 'bg-[#3D0A14] text-[#E04856] border-[#7A121D]', desc: 'Dönüş & Çember Yönetimi' },
      { key: 'ASSAULTER', label: 'Hücumcu (Assaulter)', shortLabel: 'ASSAULT', badgeClass: 'bg-[#2A0E1A] text-[#D65D9E] border-[#5E1A38]', desc: 'CQC / Yakın Mesafe Canavarı' },
      { key: 'SNIPER', label: 'Keskin Nişancı', shortLabel: 'SNIPER', badgeClass: 'bg-[#2A180E] text-[#E68A4E] border-[#663A1E]', desc: 'AWM / Kar98k Ustası' },
      { key: 'SUPPORT', label: 'Destek & Sis', shortLabel: 'SUPPORT', badgeClass: 'bg-[#1A1A1E] text-[#A0A0A8] border-[#383842]', desc: 'İlk Yardım & Sis Barikatı' },
      { key: 'SCOUT', label: 'Öncü Tarayıcı', shortLabel: 'SCOUT', badgeClass: 'bg-[#121E2A] text-[#5DA5D6] border-[#1E435E]', desc: 'Buggy ile Alan Kontrolü' },
    ],
    callouts: ['AirDrop', 'Alan Kapanıyor', 'Düşman Görüldü', 'Sis At Can Bas', 'Araç Geliyor', 'Rush'],
    maps: ['Erangel', 'Livik', 'Miramar', 'Sanhok'],
    tags: ['#PUBGMobile', '#Fatih', '#Squad', '#PMSC'],
  },
  r6: {
    id: 'r6',
    name: 'Rainbow Six Siege (R6)',
    shortName: 'R6',
    category: 'fps',
    defaultMax: 5,
    color: '#FACC15',
    badgeBg: 'rgba(250, 204, 21, 0.15)',
    roles: [
      { key: 'ENTRY', label: 'Entry Fragger', shortLabel: 'ENTRY', badgeClass: 'bg-[#3D0A14] text-[#E04856] border-[#7A121D]', desc: 'Hızlı Delik Açma & İlk Temas' },
      { key: 'HARD BREACH', label: 'Hard Breach', shortLabel: 'BREACH', badgeClass: 'bg-[#2A180E] text-[#E68A4E] border-[#663A1E]', desc: 'Güçlendirilmiş Duvar Yıkımı' },
      { key: 'SUPPORT', label: 'Destek / Drone', shortLabel: 'SUPPORT', badgeClass: 'bg-[#1A1A1E] text-[#A0A0A8] border-[#383842]', desc: 'Bilgi Sağlama & EMP' },
      { key: 'ROAMER', label: 'Gezgin (Roamer)', shortLabel: 'ROAMER', badgeClass: 'bg-[#121E2A] text-[#5DA5D6] border-[#1E435E]', desc: 'Zaman Çalma & Arkadan Av' },
      { key: 'ANCHOR', label: 'Site Anchor', shortLabel: 'ANCHOR', badgeClass: 'bg-[#192418] text-[#6FCF97] border-[#294B2E]', desc: 'Bomba Alanı Son Savunma' },
      { key: 'IGL', label: 'Taktik Lider', shortLabel: 'IGL', badgeClass: 'bg-[#2A0E1A] text-[#D65D9E] border-[#5E1A38]', desc: 'Tur Kurgusu & Planlama' },
    ],
    callouts: ['Breach Açıldı', 'Drone Atıyorum', 'Plant Başladı', 'Defuse Et', 'C4 Geldi', 'Flank Koru'],
    maps: ['Clubhouse', 'Oregon', 'Bank', 'Kafe Dostoyevsky', 'Border', 'Chalet'],
    tags: ['#R6Siege', '#Ranked', '#Champion', '#Taktik'],
  },
  apex: {
    id: 'apex',
    name: 'Apex Legends',
    shortName: 'Apex',
    category: 'br',
    defaultMax: 3,
    color: '#DC2626',
    badgeBg: 'rgba(220, 38, 38, 0.15)',
    roles: [
      { key: 'IGL', label: 'Trio Kaptanı', shortLabel: 'IGL', badgeClass: 'bg-[#3D0A14] text-[#E04856] border-[#7A121D]', desc: 'Konum Alma & Çatışma Zamanı' },
      { key: 'FRAGGER', label: 'Fragger / Skirmisher', shortLabel: 'FRAGGER', badgeClass: 'bg-[#2A0E1A] text-[#D65D9E] border-[#5E1A38]', desc: 'Hareketlilik & Açılış Hasarı' },
      { key: 'RECON', label: 'Keşifçi (Recon)', shortLabel: 'RECON', badgeClass: 'bg-[#121E2A] text-[#5DA5D6] border-[#1E435E]', desc: 'Halka Tarama & Konum Tespit' },
      { key: 'SUPPORT', label: 'Destek / Canlandırma', shortLabel: 'SUPPORT', badgeClass: 'bg-[#1A1A1E] text-[#A0A0A8] border-[#383842]', desc: 'Kalkan & Banner Üretimi' },
      { key: 'ANCHOR', label: 'Alan Koruyucu (Controller)', shortLabel: 'ANCHOR', badgeClass: 'bg-[#192418] text-[#6FCF97] border-[#294B2E]', desc: 'Kapı / Alan Savunması' },
    ],
    callouts: ['Halka Daralıyor', '3. Parti Geliyor', 'Kalkan Kırıldı', 'Ulti Açtım', 'Beacon Tara', 'Baskı Kur'],
    maps: ["World's Edge", 'Olympus', 'Storm Point', "King's Canyon"],
    tags: ['#Apex', '#Predator', '#Ranked', '#Trio'],
  },
  warzone: {
    id: 'warzone',
    name: 'Call of Duty: Warzone',
    shortName: 'Warzone',
    category: 'br',
    defaultMax: 4,
    color: '#84CC16',
    badgeBg: 'rgba(132, 204, 22, 0.15)',
    roles: [
      { key: 'IGL', label: 'Birlik Komutanı', shortLabel: 'IGL', badgeClass: 'bg-[#3D0A14] text-[#E04856] border-[#7A121D]', desc: 'Kontrat & Alan Kararları' },
      { key: 'SLAYER', label: 'Slayer / Fragger', shortLabel: 'SLAYER', badgeClass: 'bg-[#2A0E1A] text-[#D65D9E] border-[#5E1A38]', desc: 'SMG İtme & Agresif Temas' },
      { key: 'SNIPER', label: 'Keskin Nişancı', shortLabel: 'SNIPER', badgeClass: 'bg-[#2A180E] text-[#E68A4E] border-[#663A1E]', desc: 'Çatı Kontrolü & Uzun Atış' },
      { key: 'SUPPORT', label: 'Mühimmat & Takviye', shortLabel: 'SUPPORT', badgeClass: 'bg-[#1A1A1E] text-[#A0A0A8] border-[#383842]', desc: 'Zırh / Mermi & Canlandırma' },
    ],
    callouts: ['Loadout Geldi', 'Gaz Kapanıyor', 'UAV Açıldı', 'Kulede Keskin', 'Zırh Bas', 'Revive'],
    maps: ['Urzikstan', 'Rebirth Island', "Fortune's Keep"],
    tags: ['#Warzone', '#Resurgence', '#NukeQuest'],
  },
  fortnite: {
    id: 'fortnite',
    name: 'Fortnite',
    shortName: 'Fortnite',
    category: 'br',
    defaultMax: 4,
    color: '#A855F7',
    badgeBg: 'rgba(168, 85, 247, 0.15)',
    roles: [
      { key: 'IGL', label: 'Squad Lideri', shortLabel: 'IGL', badgeClass: 'bg-[#3D0A14] text-[#E04856] border-[#7A121D]', desc: 'Taktik Rotasyon & Halka Planı' },
      { key: 'FRAGGER', label: 'Fragger', shortLabel: 'FRAGGER', badgeClass: 'bg-[#2A0E1A] text-[#D65D9E] border-[#5E1A38]', desc: 'Pompalı Temas & Kutu Kırma' },
      { key: 'TARPER / BUILDER', label: 'Tarper / İnşaatçı', shortLabel: 'TARPER', badgeClass: 'bg-[#121E2A] text-[#5DA5D6] border-[#1E435E]', desc: 'Tünel Açma & Güvenli Geçiş' },
      { key: 'SUPPORT', label: 'Destek / İyileştirici', shortLabel: 'SUPPORT', badgeClass: 'bg-[#1A1A1E] text-[#A0A0A8] border-[#383842]', desc: 'Can / Kalkan Eşyaları Taşıyıcı' },
    ],
    callouts: ['Kutuya Girdi', 'Kalkan 100 Vurdum', 'Yukarı Tırman', 'Fırtına Kaç', 'Medkit Var', 'Resetle'],
    maps: ['Battle Royale Adası'],
    tags: ['#Fortnite', '#ZeroBuild', '#Ranked', '#FNCS'],
  },
  overwatch2: {
    id: 'overwatch2',
    name: 'Overwatch 2',
    shortName: 'OW2',
    category: 'fps',
    defaultMax: 5,
    color: '#FA9C1E',
    badgeBg: 'rgba(250, 156, 30, 0.15)',
    roles: [
      { key: 'TANK', label: 'Tank (Ön Hat)', shortLabel: 'TANK', badgeClass: 'bg-[#2A180E] text-[#E68A4E] border-[#663A1E]', desc: 'Alan Yaratma & Hasar Soğurma' },
      { key: 'HITSCAN DPS', label: 'Hitscan DPS', shortLabel: 'HITSCAN', badgeClass: 'bg-[#3D0A14] text-[#E04856] border-[#7A121D]', desc: 'Uzaktan Hassas Hasar' },
      { key: 'FLEX DPS', label: 'Esnek / Projektil DPS', shortLabel: 'FLEX DPS', badgeClass: 'bg-[#2A0E1A] text-[#D65D9E] border-[#5E1A38]', desc: 'Flank & Alan Hasarı' },
      { key: 'MAIN SUPPORT', label: 'Ana Şifacı (Main Healer)', shortLabel: 'MAIN HEAL', badgeClass: 'bg-[#192418] text-[#6FCF97] border-[#294B2E]', desc: 'Yoğun İyileştirme & Hayatta Tutma' },
      { key: 'FLEX SUPPORT', label: 'Destek & Ulti Yönetimi', shortLabel: 'FLEX SUPP', badgeClass: 'bg-[#121E2A] text-[#5DA5D6] border-[#1E435E]', desc: 'Hız, Hasar Güçlendirme & Kitle Kontrol' },
    ],
    callouts: ['Ulti Hazır', 'Arka Hat Dalın', 'Tankı İndirdik', 'Nanoboost Ver', 'Point Conteste', 'Geri Çekil'],
    maps: ["King's Row", 'Circuit Royal', 'Esperança', 'Midtown', 'Colosseo'],
    tags: ['#Overwatch2', '#Grandmaster', '#Competitive'],
  },
  tft: {
    id: 'tft',
    name: 'Teamfight Tactics (TFT)',
    shortName: 'TFT',
    category: 'strategy',
    defaultMax: 8,
    color: '#10B981',
    badgeBg: 'rgba(16, 185, 129, 0.15)',
    roles: [
      { key: 'STRATEGIST', label: 'Ana Stratejist', shortLabel: 'STRAT', badgeClass: 'bg-[#192418] text-[#6FCF97] border-[#294B2E]', desc: 'Ekonomi Yönetimi & Komp Analizi' },
      { key: 'FLEX', label: 'Esnek / Pivot Oyuncusu', shortLabel: 'FLEX', badgeClass: 'bg-[#121E2A] text-[#5DA5D6] border-[#1E435E]', desc: 'Eşyaya Göre Geçiş Yapan' },
      { key: 'SCOUT', label: 'Harita Gözlemcisi', shortLabel: 'SCOUT', badgeClass: 'bg-[#2A180E] text-[#E68A4E] border-[#663A1E]', desc: 'Rakiplerin Dizilimini İzleyen' },
    ],
    callouts: ['Level Bas', 'Fast 8 Yap', 'Reroll Atıyorum', 'Pivot Aldım', 'Eşya Paylaş', 'GG WP'],
    maps: ['Hextech Arenası', 'Yıldız Muhafızı Arenası'],
    tags: ['#TFT', '#Challenger', '#HyperRoll', '#DoubleUp'],
  },
  rocketleague: {
    id: 'rocketleague',
    name: 'Rocket League',
    shortName: 'RL',
    category: 'sports',
    defaultMax: 3,
    color: '#0284C7',
    badgeBg: 'rgba(2, 132, 199, 0.15)',
    roles: [
      { key: 'STRIKER', label: 'Forvet (Striker)', shortLabel: 'STRIKER', badgeClass: 'bg-[#3D0A14] text-[#E04856] border-[#7A121D]', desc: 'Hava Topu & Bitirici Vuruş' },
      { key: 'PLAYMAKER', label: 'Oyun Kurucu / Pasör', shortLabel: 'PASÖR', badgeClass: 'bg-[#2A180E] text-[#E68A4E] border-[#663A1E]', desc: 'Köşe Ortaları & Boş Alan Açma' },
      { key: 'GOALKEEPER', label: 'Kaleci / Son Adam', shortLabel: 'KALECİ', badgeClass: 'bg-[#192418] text-[#6FCF97] border-[#294B2E]', desc: 'Kurtarış & Karşı Atak Başlatıcı' },
      { key: 'ROTATOR', label: 'Rotasyon Ustası', shortLabel: 'ROTATOR', badgeClass: 'bg-[#121E2A] text-[#5DA5D6] border-[#1E435E]', desc: 'Sürekli Destek & Boost Kontrolü' },
    ],
    callouts: ['Ortala', 'Ben Çıktım', 'Defans Bende', 'Boost Lazım', 'Pas Geldi', 'Güzel Gol'],
    maps: ['DFH Stadium', 'Mannfield', 'Champions Field', 'Utopia Coliseum'],
    tags: ['#RocketLeague', '#SupersonicLegend', '#Competitive-3v3'],
  },
  eafc: {
    id: 'eafc',
    name: 'EA Sports FC',
    shortName: 'FC 25',
    category: 'sports',
    defaultMax: 11,
    color: '#10B981',
    badgeBg: 'rgba(16, 185, 129, 0.15)',
    roles: [
      { key: 'FORWARD', label: 'Forvet (ST / CF)', shortLabel: 'FORVET', badgeClass: 'bg-[#3D0A14] text-[#E04856] border-[#7A121D]', desc: 'Bitiricilik & Hücum Koşuları' },
      { key: 'MIDFIELDER', label: 'Orta Saha (CAM / CM / CDM)', shortLabel: 'ORTA SAHA', badgeClass: 'bg-[#2A180E] text-[#E68A4E] border-[#663A1E]', desc: 'Pas Dağıtımı & Oyun Kurma' },
      { key: 'DEFENDER', label: 'Defans (CB / LB / RB)', shortLabel: 'DEFANS', badgeClass: 'bg-[#192418] text-[#6FCF97] border-[#294B2E]', desc: 'Top Kapma & Kademe Savunması' },
      { key: 'GOALKEEPER', label: 'Kaleci (GK)', shortLabel: 'KALECİ', badgeClass: 'bg-[#121E2A] text-[#5DA5D6] border-[#1E435E]', desc: 'Refleks & Ceza Sahası Hakimiyeti' },
      { key: 'CAPTAIN', label: 'Takım Kaptanı', shortLabel: 'KAPTAN', badgeClass: 'bg-[#2A0E1A] text-[#D65D9E] border-[#5E1A38]', desc: 'Taktik ve Duruş Ayarı' },
    ],
    callouts: ['Araya Bırak', 'Kanada Aç', 'Pres Yap', 'Ofsayt Taktiği', 'Şut Çek', 'Dön Geriye'],
    maps: ['Stadyum Sahası', 'Antrenman Sahası'],
    tags: ['#FC25', '#ProClubs', '#UltimateTeam'],
  },
  standoff2: {
    id: 'standoff2',
    name: 'Standoff 2',
    shortName: 'Standoff 2',
    category: 'fps',
    defaultMax: 5,
    color: '#E11D48',
    badgeBg: 'rgba(225, 29, 72, 0.15)',
    roles: [
      { key: 'IGL', label: 'Kaptan (IGL)', shortLabel: 'IGL', badgeClass: 'bg-[#3D0A14] text-[#E04856] border-[#7A121D]', desc: 'Taktik Lider' },
      { key: 'ENTRY', label: 'Entry Fragger', shortLabel: 'ENTRY', badgeClass: 'bg-[#2A0E1A] text-[#D65D9E] border-[#5E1A38]', desc: 'İlk Baskı & Kill' },
      { key: 'SNIPER', label: 'Keskin Nişancı', shortLabel: 'SNIPER', badgeClass: 'bg-[#2A180E] text-[#E68A4E] border-[#663A1E]', desc: 'AWM Taşıyıcı' },
      { key: 'LURKER', label: 'Lurker', shortLabel: 'LURKER', badgeClass: 'bg-[#121E2A] text-[#5DA5D6] border-[#1E435E]', desc: 'Arka Hat Avı' },
      { key: 'SUPPORT', label: 'Destek', shortLabel: 'SUPPORT', badgeClass: 'bg-[#1A1A1E] text-[#A0A0A8] border-[#383842]', desc: 'Flaş & Sis Yardımı' },
    ],
    callouts: ['A Rush', 'B Dönün', 'Drop Silah', 'Eco Kal', 'Bomba Kuruldu', 'Save Al'],
    maps: ['Sandstone', 'Rust', 'Province', 'Sakura'],
    tags: ['#Standoff2', '#MobilFPS', '#Dereceli'],
  },
  albion: {
    id: 'albion',
    name: 'Albion Online',
    shortName: 'Albion',
    category: 'mmo',
    defaultMax: 10,
    color: '#D97706',
    badgeBg: 'rgba(217, 119, 6, 0.15)',
    roles: [
      { key: 'TANK', label: 'ZvZ / Dungeon Tank', shortLabel: 'TANK', badgeClass: 'bg-[#2A180E] text-[#E68A4E] border-[#663A1E]', desc: 'Kitle Kontrolü & Başlatma' },
      { key: 'HEALER', label: 'Healer / Şifacı', shortLabel: 'HEALER', badgeClass: 'bg-[#192418] text-[#6FCF97] border-[#294B2E]', desc: 'Grup Canını Koruma' },
      { key: 'DPS', label: 'Alan DPS / Burst', shortLabel: 'DPS', badgeClass: 'bg-[#3D0A14] text-[#E04856] border-[#7A121D]', desc: 'Büyük Çatışma Hasarı' },
      { key: 'SHOTCALLER', label: 'Shotcaller', shortLabel: 'CALLER', badgeClass: 'bg-[#2A0E1A] text-[#D65D9E] border-[#5E1A38]', desc: 'ZvZ Yönlendirme & Pozisyon' },
      { key: 'SCOUT', label: 'Gözcü / Scout', shortLabel: 'SCOUT', badgeClass: 'bg-[#121E2A] text-[#5DA5D6] border-[#1E435E]', desc: 'Ganker Tespiti & Harita Uyarı' },
    ],
    callouts: ['Engage Başla', 'Heal Bas', 'Choke Noktası', 'ZvZ Pozisyonu', 'Dön Reset', 'Loot Al'],
    maps: ['Kara Bölgeler (Black Zone)', 'Kraliyet Kıtası', 'Sisler (Mists)'],
    tags: ['#AlbionOnline', '#ZvZ', '#Guild', '#PVP'],
  },
  chill: {
    id: 'chill',
    name: 'Chill & Topluluk',
    shortName: 'Chill',
    category: 'chill',
    defaultMax: 0,
    color: '#8E7E81',
    badgeBg: 'rgba(142, 126, 129, 0.15)',
    roles: [
      { key: 'SHOTCALLER', label: 'Yayıncı / Lider', shortLabel: 'LEADER', badgeClass: 'bg-[#3D0A14] text-[#E04856] border-[#7A121D]', desc: 'Topluluk Yöneticisi' },
      { key: 'CAPTAIN', label: 'Moderatör', shortLabel: 'MOD', badgeClass: 'bg-[#2A180E] text-[#E68A4E] border-[#663A1E]', desc: 'Düzen Sağlayıcı' },
      { key: 'FLEX', label: 'Dost / Misafir', shortLabel: 'DOST', badgeClass: 'bg-[#121E2A] text-[#5DA5D6] border-[#1E435E]', desc: 'Sohbete Katılan' },
      { key: 'CHILL', label: 'Sakin Dinleyici', shortLabel: 'CHILL', badgeClass: 'bg-[#1A1A1E] text-[#A0A0A8] border-[#383842]', desc: 'Arka Planda Dinleyen' },
    ],
    callouts: ['Selam 👋', 'AFK 5 Dk', 'Yayındayım 🔴', 'Müzik Önerisi', 'GG WP', 'Mola Verdim ☕'],
    maps: ['Kahve Köşesi & Müzik Sahnesi', 'Genel Sohbet Salonu'],
    tags: ['#Chill', '#Sohbet', '#Müzik', '#Yayın'],
  },
};

// ─── 1-Click Channel Presets ─────────────────────────────
export interface QuickChannelPreset {
  id: string;
  label: string;
  name: string;
  gameId: SupportedGameId;
  type: 'voice' | 'text';
  maxParticipants: number;
  categoryName: string;
  badge: string;
}

export const QUICK_CHANNEL_PRESETS: ReadonlyArray<QuickChannelPreset> = [
  {
    id: 'pill-lol-5v5',
    label: '+ LoL 5v5 Lobi',
    name: 'lol-dereceli-5v5',
    gameId: 'lol',
    type: 'voice',
    maxParticipants: 5,
    categoryName: '⚔️ MOBA KANALLARI',
    badge: '5v5',
  },
  {
    id: 'pill-cs2-premier',
    label: '+ CS2 Premier',
    name: 'cs2-premier-lobi',
    gameId: 'cs2',
    type: 'voice',
    maxParticipants: 5,
    categoryName: '🎯 TAKTİK FPS',
    badge: 'Premier',
  },
  {
    id: 'pill-valo-5stack',
    label: '+ Valorant 5-Stack',
    name: 'valo-5stack-tryhard',
    gameId: 'valorant',
    type: 'voice',
    maxParticipants: 5,
    categoryName: '🎯 TAKTİK FPS',
    badge: '5-Stack',
  },
  {
    id: 'pill-dota-ranked',
    label: '+ Dota 2 Ranked',
    name: 'dota2-ranked-5v5',
    gameId: 'dota2',
    type: 'voice',
    maxParticipants: 5,
    categoryName: '⚔️ MOBA KANALLARI',
    badge: 'Ranked',
  },
  {
    id: 'pill-pubg-squad',
    label: '+ PUBG Squad',
    name: 'pubg-squad-erangel',
    gameId: 'pubg',
    type: 'voice',
    maxParticipants: 4,
    categoryName: '🪂 BATTLE ROYALE',
    badge: '4 Kişi',
  },
  {
    id: 'pill-chill-music',
    label: '+ Chill / Müzik',
    name: 'kahve-muhabbet-muzik',
    gameId: 'chill',
    type: 'voice',
    maxParticipants: 0,
    categoryName: '☕ TOPLULUK & CHILL',
    badge: 'Sınırsız',
  },
];

// ─── 1-Click Server Templates ────────────────────────────
export interface TemplateCategoryDef {
  name: string;
  channels: Array<{
    name: string;
    type: 'text' | 'voice';
    gameId: SupportedGameId;
    maxParticipants: number;
    tags: string[];
  }>;
}

export interface ServerTemplate {
  id: string;
  title: string;
  subtitle: string;
  icon: string;
  serverName: string;
  categories: TemplateCategoryDef[];
}

export const COMMUNITY_SERVER_TEMPLATES: ReadonlyArray<ServerTemplate> = [
  {
    id: 'streamer-hub',
    title: '🎥 YouTuber Hub',
    subtitle: 'MOBA, FPS, Battle Royale ve Chill kanallarını aynı anda barındıran komple topluluk merkezi',
    icon: '🎥',
    serverName: 'YouTuber Hub',
    categories: [
      {
        name: '📌 LOBİ & SOHBET',
        channels: [
          { name: 'genel-sohbet', type: 'text', gameId: 'chill', maxParticipants: 0, tags: ['#Genel', '#Sohbet'] },
          { name: 'yayin-bildirim', type: 'text', gameId: 'chill', maxParticipants: 0, tags: ['#Yayın'] },
          { name: 'klip-paylasim', type: 'text', gameId: 'chill', maxParticipants: 0, tags: ['#Klip'] },
        ],
      },
      {
        name: '⚔️ MOBA [LoL / Dota / MLBB]',
        channels: [
          { name: 'lol-dereceli-5v5', type: 'voice', gameId: 'lol', maxParticipants: 5, tags: ['#LoL', '#Dereceli-5v5'] },
          { name: 'dota2-ranked', type: 'voice', gameId: 'dota2', maxParticipants: 5, tags: ['#Dota2', '#Ranked'] },
          { name: 'mlbb-squad', type: 'voice', gameId: 'mlbb', maxParticipants: 5, tags: ['#MLBB', '#Squad'] },
        ],
      },
      {
        name: '🎯 TAKTİK FPS [CS2 / Valo]',
        channels: [
          { name: 'cs2-premier', type: 'voice', gameId: 'cs2', maxParticipants: 5, tags: ['#CS2', '#Premier'] },
          { name: 'cs2-faceit-lobi', type: 'voice', gameId: 'cs2', maxParticipants: 5, tags: ['#CS2', '#Faceit'] },
          { name: 'valorant-5stack', type: 'voice', gameId: 'valorant', maxParticipants: 5, tags: ['#Valorant', '#5Stack'] },
        ],
      },
      {
        name: '🪂 BATTLE ROYALE [PUBG / Apex]',
        channels: [
          { name: 'pubg-squad-erangel', type: 'voice', gameId: 'pubg', maxParticipants: 4, tags: ['#PUBG', '#Squad'] },
          { name: 'apex-ranked-trio', type: 'voice', gameId: 'apex', maxParticipants: 3, tags: ['#Apex', '#Trio'] },
        ],
      },
      {
        name: '☕ CHILL & MÜZİK',
        channels: [
          { name: 'kahve-muhabbet', type: 'voice', gameId: 'chill', maxParticipants: 0, tags: ['#Chill', '#Müzik'] },
        ],
      },
    ],
  },
  {
    id: 'scrim-clan',
    title: '🏆 Espor Scrim Karargahı',
    subtitle: 'Resmi maç odaları, taktik analiz & koçluk ve yedek bekleme lobileri',
    icon: '🏆',
    serverName: 'Espor Scrim Karargahı',
    categories: [
      {
        name: '🏆 MAÇ & TURNUVA ODALARI',
        channels: [
          { name: 'scrim-oda-1-cs2', type: 'voice', gameId: 'cs2', maxParticipants: 5, tags: ['#Scrim', '#CS2'] },
          { name: 'scrim-oda-2-valo', type: 'voice', gameId: 'valorant', maxParticipants: 5, tags: ['#Scrim', '#Valo'] },
          { name: 'scrim-chat', type: 'text', gameId: 'cs2', maxParticipants: 0, tags: ['#Scrim', '#Skorlar'] },
        ],
      },
      {
        name: '🧠 TAKTİK & KOÇLUK',
        channels: [
          { name: 'taktik-analiz-koc', type: 'voice', gameId: 'cs2', maxParticipants: 10, tags: ['#Koç', '#Analiz'] },
          { name: 'vod-review', type: 'text', gameId: 'cs2', maxParticipants: 0, tags: ['#VOD', '#Notlar'] },
        ],
      },
      {
        name: '⚡ YEDEK LOBİ & ISINMA',
        channels: [
          { name: 'isinma-dm', type: 'voice', gameId: 'cs2', maxParticipants: 10, tags: ['#Isınma', '#DM'] },
          { name: 'yedekler', type: 'voice', gameId: 'cs2', maxParticipants: 5, tags: ['#Yedek'] },
        ],
      },
    ],
  },
  {
    id: 'fast-squad',
    title: '⚡ Serbest Agalar',
    subtitle: 'Sade ve anında hazır: 1 genel sohbet ve doğrudan oyun odaları',
    icon: '⚡',
    serverName: 'Serbest Agalar',
    categories: [
      {
        name: '☕ CHILL / MUHABBET',
        channels: [
          { name: 'kahve-muhabbet', type: 'voice', gameId: 'chill', maxParticipants: 0, tags: ['#Chill'] },
          { name: 'sohbet', type: 'text', gameId: 'chill', maxParticipants: 0, tags: ['#Sohbet'] },
        ],
      },
      {
        name: '🎮 ANA OYUN ODALARI',
        channels: [
          { name: 'oyun-odasi-1-valo', type: 'voice', gameId: 'valorant', maxParticipants: 5, tags: ['#Valorant'] },
          { name: 'oyun-odasi-2-lol', type: 'voice', gameId: 'lol', maxParticipants: 5, tags: ['#LoL'] },
        ],
      },
    ],
  },
];

// ─── Style & Community Tags ──────────────────────────────
export const COMMUNITY_TAGS: ReadonlyArray<string> = [
  '#Tryhard-Dereceli',
  '#Scrim-Turnuva',
  '#Duo-Takım-Arama',
  '#Topluluk-Etkinlik',
  '#Chill-Muhabbet',
  '#Gece-Tayfası',
];

// ─── Helper Functions ────────────────────────────────────
export function getGameById(gameId?: string | null): GameDef {
  if (!gameId) return SUPPORTED_GAMES.cs2;
  return SUPPORTED_GAMES[gameId as SupportedGameId] ?? SUPPORTED_GAMES.cs2;
}

export function detectGameFromChannel(channelName: string, channelTags?: string[]): GameDef {
  const lower = channelName.toLowerCase();
  if (channelTags && channelTags.length > 0) {
    for (const tag of channelTags) {
      const tagLower = tag.toLowerCase().replace('#', '');
      if (tagLower.includes('lol') || tagLower.includes('league')) return SUPPORTED_GAMES.lol;
      if (tagLower.includes('cs') || tagLower.includes('faceit') || tagLower.includes('premier')) return SUPPORTED_GAMES.cs2;
      if (tagLower.includes('val')) return SUPPORTED_GAMES.valorant;
      if (tagLower.includes('dota')) return SUPPORTED_GAMES.dota2;
      if (tagLower.includes('pubg')) return SUPPORTED_GAMES.pubg;
      if (tagLower.includes('apex')) return SUPPORTED_GAMES.apex;
      if (tagLower.includes('mlbb')) return SUPPORTED_GAMES.mlbb;
      if (tagLower.includes('chill') || tagLower.includes('sohbet')) return SUPPORTED_GAMES.chill;
    }
  }

  if (lower.includes('lol') || lower.includes('vadi')) return SUPPORTED_GAMES.lol;
  if (lower.includes('cs') || lower.includes('faceit') || lower.includes('premier') || lower.includes('mirage')) return SUPPORTED_GAMES.cs2;
  if (lower.includes('val') || lower.includes('ascent') || lower.includes('bind')) return SUPPORTED_GAMES.valorant;
  if (lower.includes('dota') || lower.includes('roshan')) return SUPPORTED_GAMES.dota2;
  if (lower.includes('pubg') || lower.includes('erangel')) return SUPPORTED_GAMES.pubg;
  if (lower.includes('apex') || lower.includes('trio')) return SUPPORTED_GAMES.apex;
  if (lower.includes('mlbb') || lower.includes('mobile-legends')) return SUPPORTED_GAMES.mlbb;
  if (lower.includes('wild') || lower.includes('rift')) return SUPPORTED_GAMES.wildrift;
  if (lower.includes('r6') || lower.includes('siege')) return SUPPORTED_GAMES.r6;
  if (lower.includes('warzone') || lower.includes('cod')) return SUPPORTED_GAMES.warzone;
  if (lower.includes('fortnite')) return SUPPORTED_GAMES.fortnite;
  if (lower.includes('ow') || lower.includes('overwatch')) return SUPPORTED_GAMES.overwatch2;
  if (lower.includes('tft') || lower.includes('tactics')) return SUPPORTED_GAMES.tft;
  if (lower.includes('rocket') || lower.includes('rl')) return SUPPORTED_GAMES.rocketleague;
  if (lower.includes('eafc') || lower.includes('fifa') || lower.includes('fc25')) return SUPPORTED_GAMES.eafc;
  if (lower.includes('standoff')) return SUPPORTED_GAMES.standoff2;
  if (lower.includes('albion') || lower.includes('zvz')) return SUPPORTED_GAMES.albion;
  if (lower.includes('chill') || lower.includes('sohbet') || lower.includes('muhabbet') || lower.includes('muzik') || lower.includes('müzik')) return SUPPORTED_GAMES.chill;

  return SUPPORTED_GAMES.cs2;
}

export interface RecommendationMatch {
  channelId: string;
  score: number; // 0-100
  badgeText: string;
  missingRole: string;
  currentCount: number;
  maxCount: number;
}

export function evaluateChannelMatch(
  channel: { id: string; name: string; game_id?: string; tags?: string[]; max_participants?: number },
  userPrimaryGame: SupportedGameId,
  userSelectedRole: string,
  occupancy: number = 0,
): RecommendationMatch | null {
  const game = channel.game_id
    ? getGameById(channel.game_id)
    : detectGameFromChannel(channel.name, channel.tags);

  const capacity = channel.max_participants ?? game.defaultMax;
  if (capacity > 0 && occupancy >= capacity) return null; // Full

  const isGameMatch = game.id === userPrimaryGame;
  let score = isGameMatch ? 70 : 40;

  if (occupancy === capacity - 1 && capacity > 1) {
    score += 25; // "4/5 Kişi - 1 Kişi Eksik!"
  } else if (occupancy > 0) {
    score += 15;
  }

  const roleLabel = userSelectedRole.split(' ')[0] || 'Oyuncu';
  const badgeText = `⚡ Sana Uygun (%${Math.min(99, score)} Eşleşme — ${occupancy}/${capacity || '∞'} Kişi, ${roleLabel} Eksik)`;

  return {
    channelId: channel.id,
    score,
    badgeText,
    missingRole: roleLabel,
    currentCount: occupancy,
    maxCount: capacity,
  };
}
