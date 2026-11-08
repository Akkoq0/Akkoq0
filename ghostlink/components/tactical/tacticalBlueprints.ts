// ─────────────────────────────────────────────────────────
// Meva HUD — Esports Stratbook High-Fidelity Tactical Blueprints
// ─────────────────────────────────────────────────────────
// Topographically realistic minimap vector blueprints matching real
// esports arenas (LoL 2026 Summoner's Rift, Valorant Bind/Ascent/Haven/Split/Lotus,
// CS2 Mirage/Inferno/Dust2/Ancient/Nuke, Dota 2 New Frontiers 7.33+, PUBG Erangel/Miramar/Sanhok).

export type TacticalGameCategory = 'valorant' | 'cs2' | 'lol' | 'dota2' | 'pubg';

export type TacticalMapId =
  | 'ascent'
  | 'bind'
  | 'haven'
  | 'split'
  | 'lotus'
  | 'mirage'
  | 'inferno'
  | 'dust2'
  | 'ancient'
  | 'nuke'
  | 'rift'
  | 'aram'
  | 'dota'
  | 'erangel'
  | 'miramar'
  | 'sanhok'
  | 'custom';

export const LOGICAL_W = 840;
export const LOGICAL_H = 480;

export interface MapZone {
  label: string;
  x: number;
  y: number;
  w: number;
  h: number;
  isSite?: boolean;
  accent?: string;
}

export interface MapMetaSpec {
  title: string;
  game: TacticalGameCategory;
  gameTitle: string;
  subtitle: string;
  compassHeading: string;
  zones: MapZone[];
}

export const GAME_MAP_POOLS: Record<TacticalGameCategory, TacticalMapId[]> = {
  valorant: ['ascent', 'bind', 'haven', 'split', 'lotus'],
  cs2: ['mirage', 'inferno', 'dust2', 'ancient', 'nuke'],
  lol: ['rift', 'aram'],
  dota2: ['dota'],
  pubg: ['erangel', 'miramar', 'sanhok'],
};

export const MAP_BLUEPRINTS: Record<Exclude<TacticalMapId, 'custom'>, MapMetaSpec> = {
  // ── VALORANT ──
  bind: {
    title: 'Bind',
    game: 'valorant',
    gameTitle: 'VALORANT ARENA',
    subtitle: 'Rabat, Fas · İki Işınlayıcı & A/B Spike Siteleri',
    compassHeading: 'N 42°W',
    zones: [
      { label: 'A SITE (SPIKE)', x: 550, y: 70, w: 190, h: 125, isSite: true, accent: '#10B981' },
      { label: 'B SITE (SPIKE)', x: 90, y: 70, w: 180, h: 125, isSite: true, accent: '#10B981' },
      { label: 'LAMPS / U-HALL', x: 465, y: 80, w: 75, h: 95 },
      { label: 'A SHORT', x: 465, y: 215, w: 140, h: 70 },
      { label: 'SHOWERS (BANYO)', x: 650, y: 220, w: 110, h: 95 },
      { label: 'HOOKAH (NARGİLE)', x: 235, y: 185, w: 115, h: 80 },
      { label: 'B LONG / GARDEN', x: 80, y: 220, w: 135, h: 105 },
      { label: 'ELBOW', x: 75, y: 140, w: 60, h: 65 },
      { label: '⚡ A PORT (TP)', x: 440, y: 165, w: 70, h: 42, accent: '#00F0FF' },
      { label: '⚡ B PORT (TP)', x: 85, y: 185, w: 70, h: 42, accent: '#00F0FF' },
      { label: 'DEFENDER BASE', x: 325, y: 25, w: 180, h: 50 },
      { label: 'ATTACKER CAVE', x: 305, y: 395, w: 220, h: 55 },
    ],
  },
  ascent: {
    title: 'Ascent',
    game: 'valorant',
    gameTitle: 'VALORANT ARENA',
    subtitle: 'Venedik, İtalya · Geniş Mid & Kapanır Kapılar',
    compassHeading: 'N 18°E',
    zones: [
      { label: 'A SITE (SPIKE)', x: 580, y: 55, w: 180, h: 130, isSite: true, accent: '#10B981' },
      { label: 'B SITE (SPIKE)', x: 75, y: 60, w: 175, h: 130, isSite: true, accent: '#10B981' },
      { label: 'A HEAVEN / RAFTERS', x: 620, y: 18, w: 120, h: 36 },
      { label: 'A MAIN & WINE', x: 590, y: 205, w: 130, h: 95 },
      { label: 'A TREE (AĞAÇ)', x: 470, y: 120, w: 95, h: 75 },
      { label: 'MID COURTYARD', x: 335, y: 170, w: 155, h: 135, accent: '#F08C96' },
      { label: 'CATWALK & PIZZA', x: 470, y: 215, w: 100, h: 55 },
      { label: 'MARKET / PIZZA', x: 220, y: 145, w: 100, h: 85 },
      { label: 'B MAIN & LOBBY', x: 95, y: 210, w: 115, h: 100 },
      { label: 'DEFENDER BASE', x: 330, y: 30, w: 175, h: 58 },
      { label: 'ATTACKER BASE', x: 315, y: 390, w: 205, h: 60 },
    ],
  },
  haven: {
    title: 'Haven',
    game: 'valorant',
    gameTitle: 'VALORANT ARENA (3 BOMBSITE)',
    subtitle: 'Thimphu, Butan · 3 Bombalı Taktik Matrisi',
    compassHeading: 'N 25°E',
    zones: [
      { label: 'A SITE', x: 620, y: 70, w: 155, h: 120, isSite: true, accent: '#10B981' },
      { label: 'B SITE', x: 350, y: 115, w: 140, h: 110, isSite: true, accent: '#10B981' },
      { label: 'C SITE', x: 75, y: 70, w: 150, h: 120, isSite: true, accent: '#10B981' },
      { label: 'A LONG / SEWERS', x: 650, y: 220, w: 125, h: 90 },
      { label: 'GARAGE (GARAJ)', x: 235, y: 210, w: 90, h: 85 },
      { label: 'C LONG', x: 65, y: 220, w: 110, h: 105 },
      { label: 'MID COURTYARD', x: 345, y: 245, w: 150, h: 80, accent: '#F08C96' },
      { label: 'DEFENDER BASE', x: 340, y: 30, w: 160, h: 55 },
      { label: 'ATTACKER BASE', x: 320, y: 390, w: 200, h: 60 },
    ],
  },
  split: {
    title: 'Split',
    game: 'valorant',
    gameTitle: 'VALORANT ARENA',
    subtitle: 'Tokyo, Japonya · Dikey Ropes & Vents',
    compassHeading: 'N 04°E',
    zones: [
      { label: 'A SITE (KULE)', x: 570, y: 65, w: 180, h: 130, isSite: true, accent: '#10B981' },
      { label: 'B SITE', x: 80, y: 65, w: 170, h: 130, isSite: true, accent: '#10B981' },
      { label: 'A HEAVEN', x: 600, y: 25, w: 120, h: 35 },
      { label: 'MID VENTS & ROPES', x: 360, y: 155, w: 120, h: 100, accent: '#00F0FF' },
      { label: 'B HEAVEN / MAIL', x: 230, y: 125, w: 110, h: 85 },
      { label: 'A MAIN', x: 590, y: 215, w: 130, h: 95 },
      { label: 'B MAIN / GARAJ', x: 85, y: 215, w: 120, h: 100 },
      { label: 'DEFENDER BASE', x: 340, y: 30, w: 160, h: 55 },
      { label: 'ATTACKER BASE', x: 320, y: 385, w: 200, h: 60 },
    ],
  },
  lotus: {
    title: 'Lotus',
    game: 'valorant',
    gameTitle: 'VALORANT ARENA (3 BOMBSITE)',
    subtitle: 'Batı Ghats, Hindistan · Dönen Kapılar & Yıkılan Duvar',
    compassHeading: 'N 14°W',
    zones: [
      { label: 'A SITE (SPIKE)', x: 610, y: 75, w: 165, h: 120, isSite: true, accent: '#10B981' },
      { label: 'B SITE (SPIKE)', x: 350, y: 95, w: 135, h: 105, isSite: true, accent: '#10B981' },
      { label: 'C SITE (SPIKE)', x: 75, y: 80, w: 155, h: 120, isSite: true, accent: '#10B981' },
      { label: 'A ROTATING DOOR', x: 535, y: 175, w: 85, h: 55, accent: '#EAB308' },
      { label: 'C ROTATING DOOR', x: 225, y: 185, w: 85, h: 55, accent: '#EAB308' },
      { label: 'BREAKABLE WALL', x: 375, y: 215, w: 85, h: 45, accent: '#EF4444' },
      { label: 'A MAIN & LOBBY', x: 630, y: 235, w: 125, h: 95 },
      { label: 'C MAIN & MOUND', x: 75, y: 230, w: 120, h: 95 },
      { label: 'DEFENDER BASE', x: 335, y: 25, w: 170, h: 55 },
      { label: 'ATTACKER BASE', x: 315, y: 385, w: 210, h: 60 },
    ],
  },

  // ── CS2 ──
  mirage: {
    title: 'Mirage',
    game: 'cs2',
    gameTitle: 'CS2 TAKTİK ARENASI',
    subtitle: 'Fas Çölü · Rekabetçi Espor Standardı',
    compassHeading: 'N 02°E',
    zones: [
      { label: 'A SITE (BOMB A)', x: 560, y: 260, w: 190, h: 135, isSite: true, accent: '#C82333' },
      { label: 'B SITE (BOMB B)', x: 85, y: 55, w: 175, h: 125, isSite: true, accent: '#C82333' },
      { label: 'PALACE (SARAY)', x: 645, y: 395, w: 125, h: 55 },
      { label: 'A RAMP', x: 555, y: 395, w: 82, h: 55 },
      { label: 'CONNECTOR', x: 425, y: 240, w: 105, h: 90 },
      { label: 'MID / PENCERE', x: 315, y: 185, w: 155, h: 95, accent: '#E5A93C' },
      { label: 'UNDERPASS', x: 265, y: 125, w: 95, h: 55 },
      { label: 'APARTMANLAR', x: 270, y: 60, w: 175, h: 55 },
      { label: 'CT BASE', x: 365, y: 330, w: 155, h: 65 },
      { label: 'T BASE', x: 645, y: 90, w: 125, h: 95 },
    ],
  },
  inferno: {
    title: 'Inferno',
    game: 'cs2',
    gameTitle: 'CS2 TAKTİK ARENASI',
    subtitle: 'Toskana, İtalya · Klasik Dar Geçitler & Muz',
    compassHeading: 'N 28°E',
    zones: [
      { label: 'A SITE (BOMB A)', x: 560, y: 240, w: 185, h: 125, isSite: true, accent: '#C82333' },
      { label: 'B SITE (ÇEŞME)', x: 145, y: 45, w: 185, h: 115, isSite: true, accent: '#C82333' },
      { label: 'MUZ (BANANA)', x: 185, y: 175, w: 95, h: 155, accent: '#E5A93C' },
      { label: 'CT İNŞAAT', x: 350, y: 50, w: 155, h: 75 },
      { label: 'ORTA (MID)', x: 335, y: 250, w: 155, h: 85 },
      { label: 'KÜTÜPHANE / KEMER', x: 505, y: 120, w: 135, h: 95 },
      { label: 'EV / ÇUKUR (PIT)', x: 615, y: 375, w: 155, h: 65 },
      { label: 'T RAMP', x: 125, y: 360, w: 185, h: 72 },
    ],
  },
  dust2: {
    title: 'Dust II',
    game: 'cs2',
    gameTitle: 'CS2 TAKTİK ARENASI',
    subtitle: 'Kazablanka, Fas · İkonik Long A & B Tünel',
    compassHeading: 'N 05°E',
    zones: [
      { label: 'A SITE (BOMB A)', x: 610, y: 110, w: 170, h: 120, isSite: true, accent: '#C82333' },
      { label: 'B SITE (BOMB B)', x: 90, y: 90, w: 170, h: 120, isSite: true, accent: '#C82333' },
      { label: 'LONG A KORİDORU', x: 640, y: 245, w: 120, h: 140 },
      { label: 'A SHORT / CATWALK', x: 470, y: 150, w: 120, h: 75 },
      { label: 'ORTA KAPILAR (MID)', x: 360, y: 220, w: 120, h: 100, accent: '#E5A93C' },
      { label: 'ÜST TÜNELLER', x: 110, y: 230, w: 110, h: 85 },
      { label: 'ALT TÜNELLER', x: 235, y: 260, w: 105, h: 75 },
      { label: 'T BASE', x: 260, y: 380, w: 220, h: 65 },
      { label: 'CT BASE', x: 440, y: 50, w: 140, h: 60 },
    ],
  },
  ancient: {
    title: 'Ancient',
    game: 'cs2',
    gameTitle: 'CS2 TAKTİK ARENASI',
    subtitle: 'Mezoamerika Harabeleri · Donut & Cheetah',
    compassHeading: 'N 31°W',
    zones: [
      { label: 'A SITE (TAPINAK)', x: 570, y: 120, w: 185, h: 130, isSite: true, accent: '#C82333' },
      { label: 'B SITE (RAMPA)', x: 85, y: 110, w: 175, h: 130, isSite: true, accent: '#C82333' },
      { label: 'DONUT BÖLGESİ', x: 460, y: 160, w: 90, h: 85, accent: '#E5A93C' },
      { label: 'ORTA (MID)', x: 350, y: 200, w: 140, h: 90 },
      { label: 'MAĞARA / CHEETAH', x: 235, y: 180, w: 95, h: 90 },
      { label: 'RED ROOM', x: 250, y: 100, w: 85, h: 70 },
      { label: 'CT BASE', x: 350, y: 45, w: 160, h: 65 },
      { label: 'T BASE', x: 330, y: 380, w: 200, h: 65 },
    ],
  },
  nuke: {
    title: 'Nuke',
    game: 'cs2',
    gameTitle: 'CS2 TAKTİK ARENASI (ÇİFT KATMAN)',
    subtitle: 'Nükleer Santral · Üst A & Alt B Reaktör Katı',
    compassHeading: 'N 08°E',
    zones: [
      { label: 'A SITE (ÜST KAT)', x: 340, y: 105, w: 165, h: 110, isSite: true, accent: '#C82333' },
      { label: 'B SITE (ALT KAT)', x: 340, y: 260, w: 165, h: 110, isSite: true, accent: '#EAB308' },
      { label: 'OUTSIDE / YARD', x: 570, y: 150, w: 180, h: 180, accent: '#38BDF8' },
      { label: 'RAMP (RAMPA)', x: 170, y: 220, w: 130, h: 90 },
      { label: 'HUT & SQUEAKY', x: 245, y: 120, w: 85, h: 70 },
      { label: 'GARAGE & SECRET', x: 620, y: 340, w: 120, h: 80 },
      { label: 'T ROOF & LOBBY', x: 120, y: 70, w: 120, h: 95 },
      { label: 'CT BASE', x: 490, y: 45, w: 130, h: 60 },
    ],
  },

  // ── LEAGUE OF LEGENDS ──
  rift: {
    title: 'Sihirdar Vadisi',
    game: 'lol',
    gameTitle: 'MOBA STRATEJİ MATRİSİ',
    subtitle: 'Runeterra · 3 Koridor, 12 Orman Kampı & Baron/Ejder',
    compassHeading: 'N 45°E',
    zones: [
      { label: 'BARON NASHOR ÇUKURU', x: 250, y: 120, w: 140, h: 95, isSite: true, accent: '#A855F7' },
      { label: 'KADİM EJDER ÇUKURU', x: 460, y: 250, w: 140, h: 95, isSite: true, accent: '#EF4444' },
      { label: 'ÜST KORİDOR (TOP)', x: 105, y: 55, w: 230, h: 55, accent: '#38BDF8' },
      { label: 'ORTA KORİDOR (MID)', x: 315, y: 180, w: 210, h: 85, accent: '#38BDF8' },
      { label: 'ALT KORİDOR (BOT)', x: 505, y: 340, w: 230, h: 55, accent: '#38BDF8' },
      { label: 'MAVİ GÜÇLENDİRME (BLUE)', x: 225, y: 240, w: 90, h: 60, accent: '#0284C7' },
      { label: 'KIRMIZI GÜÇLENDİRME (RED)', x: 525, y: 160, w: 90, h: 60, accent: '#DC2626' },
      { label: 'MAVİ NEXUS (BASE)', x: 70, y: 360, w: 120, h: 75, accent: '#0284C7' },
      { label: 'KIRMIZI NEXUS (BASE)', x: 650, y: 45, w: 120, h: 75, accent: '#DC2626' },
    ],
  },
  aram: {
    title: 'Sonsuz Uçurum (ARAM)',
    game: 'lol',
    gameTitle: 'MOBA KÖPRÜ ÇATIŞMASI',
    subtitle: 'Freljord · Tek Koridor & Kesintisiz Savaş',
    compassHeading: 'N 30°E',
    zones: [
      { label: 'ORTA KÖPRÜ (ÇATIŞMA HATTI)', x: 310, y: 190, w: 220, h: 90, isSite: true, accent: '#00F0FF' },
      { label: 'KUZEY CAN KALINTISI', x: 240, y: 140, w: 85, h: 60, accent: '#10B981' },
      { label: 'GÜNEY CAN KALINTISI', x: 515, y: 280, w: 85, h: 60, accent: '#10B981' },
      { label: 'MAVİ KULELER & NEXUS', x: 75, y: 80, w: 165, h: 110, accent: '#0284C7' },
      { label: 'KIRMIZI KULELER & NEXUS', x: 600, y: 290, w: 165, h: 110, accent: '#DC2626' },
    ],
  },

  // ── DOTA 2 ──
  dota: {
    title: 'Kadimler Vadisi (New Frontiers)',
    game: 'dota2',
    gameTitle: 'DOTA 2 7.33+ STRATEJİ MATRİSİ',
    subtitle: 'Çift Roshan Çukuru · İkiz Kapılar & Tormentors',
    compassHeading: 'N 00°',
    zones: [
      { label: 'ROSHAN ÇUKURU (KUZEY-BATI)', x: 130, y: 70, w: 145, h: 75, isSite: true, accent: '#DC2626' },
      { label: 'ROSHAN ÇUKURU (GÜNEY-DOĞU)', x: 575, y: 335, w: 145, h: 75, isSite: true, accent: '#DC2626' },
      { label: 'İKİZ KAPI (TWIN GATE KUZEY)', x: 80, y: 65, w: 45, h: 45, accent: '#00F0FF' },
      { label: 'İKİZ KAPI (TWIN GATE GÜNEY)', x: 720, y: 370, w: 45, h: 45, accent: '#00F0FF' },
      { label: 'TORMENTOR (KUZEY/DIRE)', x: 245, y: 70, w: 100, h: 55, accent: '#A855F7' },
      { label: 'TORMENTOR (GÜNEY/RADIANT)', x: 495, y: 355, w: 100, h: 55, accent: '#A855F7' },
      { label: 'RADIANT SAFE LANE', x: 520, y: 370, w: 180, h: 50, accent: '#10B981' },
      { label: 'DIRE SAFE LANE', x: 140, y: 55, w: 180, h: 50, accent: '#991B1B' },
      { label: 'NEHİR & RUNE NOKTALARI', x: 330, y: 200, w: 180, h: 75, accent: '#06B6D4' },
      { label: 'RADIANT ANCIENT', x: 85, y: 360, w: 110, h: 70, accent: '#10B981' },
      { label: 'DIRE ANCIENT', x: 645, y: 55, w: 110, h: 70, accent: '#DC2626' },
    ],
  },

  // ── PUBG ──
  erangel: {
    title: 'Erangel',
    game: 'pubg',
    gameTitle: 'BATTLE ROYALE MATRİSİ',
    subtitle: 'Karadeniz Askeri Ada · 8x8 km Koordinat',
    compassHeading: 'N 12°W',
    zones: [
      { label: 'POCHINKI (MERKEZ)', x: 340, y: 205, w: 160, h: 90, isSite: true, accent: '#C82333' },
      { label: 'SOSNOVKA ASKERİ ÜS', x: 330, y: 365, w: 180, h: 85, isSite: true, accent: '#C82333' },
      { label: 'OKUL & APARTMANLAR', x: 420, y: 155, w: 130, h: 75, accent: '#E5A93C' },
      { label: 'ROZHOK SU ŞEHRİ', x: 340, y: 125, w: 110, h: 65 },
      { label: 'YASNAYA POLYANA', x: 535, y: 110, w: 155, h: 85 },
      { label: 'GEORGOPOOL LİMAN', x: 130, y: 85, w: 160, h: 90 },
      { label: 'MYLTA POWER', x: 640, y: 285, w: 120, h: 80 },
    ],
  },
  miramar: {
    title: 'Miramar',
    game: 'pubg',
    gameTitle: 'BATTLE ROYALE ÇÖL MATRİSİ',
    subtitle: 'Meksika Çölü · Los Leones & Pecado',
    compassHeading: 'N 22°E',
    zones: [
      { label: 'LOS LEONES BÜYÜK ŞEHİR', x: 520, y: 260, w: 190, h: 125, isSite: true, accent: '#C82333' },
      { label: 'PECADO CASINO & ARENA', x: 340, y: 190, w: 155, h: 95, isSite: true, accent: '#C82333' },
      { label: 'HACIENDA DEL PATRÓN', x: 440, y: 115, w: 120, h: 75, accent: '#E5A93C' },
      { label: 'CHUMACERA', x: 230, y: 290, w: 130, h: 80 },
      { label: 'SAN MARTIN', x: 320, y: 95, w: 110, h: 75 },
      { label: 'EL POZO', x: 95, y: 160, w: 135, h: 85 },
    ],
  },
  sanhok: {
    title: 'Sanhok',
    game: 'pubg',
    gameTitle: 'BATTLE ROYALE YAĞMUR ORMANI',
    subtitle: 'Güneydoğu Asya 4x4 · Bootcamp & Paradise',
    compassHeading: 'N 05°W',
    zones: [
      { label: 'BOOTCAMP (MERKEZ KAMP)', x: 340, y: 190, w: 160, h: 100, isSite: true, accent: '#C82333' },
      { label: 'PARADISE RESORT', x: 470, y: 100, w: 145, h: 85, isSite: true, accent: '#C82333' },
      { label: 'RUINS (TAPINAK HARABE)', x: 220, y: 230, w: 130, h: 85, accent: '#E5A93C' },
      { label: 'CAMP ALPHA', x: 140, y: 95, w: 115, h: 75 },
      { label: 'CAMP BRAVO', x: 570, y: 220, w: 120, h: 80 },
      { label: 'CAMP CHARLIE', x: 450, y: 350, w: 120, h: 80 },
      { label: 'CAVE / MAĞARA', x: 310, y: 330, w: 110, h: 75 },
    ],
  },
};

// ─────────────────────────────────────────────────────────
// Detailed Topographical Renderers
// ─────────────────────────────────────────────────────────

export function drawRealisticArenaBlueprint(
  ctx: CanvasRenderingContext2D,
  mapId: Exclude<TacticalMapId, 'custom'>,
) {
  ctx.clearRect(0, 0, LOGICAL_W, LOGICAL_H);
  const spec = MAP_BLUEPRINTS[mapId];
  if (!spec) return;

  // 1. Base Layer: Deep Espresso & Obsidian Canvas with High-Contrast Vignette
  const bgGrad = ctx.createRadialGradient(
    LOGICAL_W / 2,
    LOGICAL_H / 2,
    40,
    LOGICAL_W / 2,
    LOGICAL_H / 2,
    520,
  );
  bgGrad.addColorStop(0, '#150A0E');
  bgGrad.addColorStop(0.55, '#0B0608');
  bgGrad.addColorStop(1, '#040203');
  ctx.fillStyle = bgGrad;
  ctx.fillRect(0, 0, LOGICAL_W, LOGICAL_H);

  // 2. High-Tech Tactical Radar Grid (60px step with crosshair intersections)
  ctx.strokeStyle = 'rgba(143, 22, 34, 0.12)';
  ctx.lineWidth = 1;
  for (let x = 60; x < LOGICAL_W; x += 60) {
    ctx.beginPath();
    ctx.moveTo(x, 0);
    ctx.lineTo(x, LOGICAL_H);
    ctx.stroke();
  }
  for (let y = 60; y < LOGICAL_H; y += 60) {
    ctx.beginPath();
    ctx.moveTo(0, y);
    ctx.lineTo(LOGICAL_W, y);
    ctx.stroke();
  }

  // Crosshairs (+) at every grid intersection
  ctx.strokeStyle = 'rgba(200, 35, 51, 0.32)';
  ctx.lineWidth = 1;
  for (let x = 60; x < LOGICAL_W; x += 60) {
    for (let y = 60; y < LOGICAL_H; y += 60) {
      ctx.beginPath();
      ctx.moveTo(x - 3.5, y);
      ctx.lineTo(x + 3.5, y);
      ctx.moveTo(x, y - 3.5);
      ctx.lineTo(x, y + 3.5);
      ctx.stroke();
    }
  }

  // 3. Concentric Range Radar Rings
  ctx.save();
  ctx.setLineDash([4, 6]);
  ctx.strokeStyle = 'rgba(200, 35, 51, 0.12)';
  ctx.lineWidth = 1.2;
  [110, 230, 360].forEach((r) => {
    ctx.beginPath();
    ctx.arc(LOGICAL_W / 2, LOGICAL_H / 2, r, 0, Math.PI * 2);
    ctx.stroke();
  });
  ctx.restore();

  // 4. Coordinates Labels (A-N, 1-8)
  ctx.fillStyle = 'rgba(184, 170, 172, 0.32)';
  ctx.font = '700 9px monospace';
  const cols = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N'];
  cols.forEach((c, idx) => {
    ctx.fillText(c, idx * 60 + 26, 13);
  });
  for (let r = 1; r <= 7; r++) {
    ctx.fillText(`${r}`, 6, r * 60 + 4);
  }

  // 5. Stylized Esports Map Header & Compass HUD (Top Left & Top Right)
  ctx.save();
  ctx.fillStyle = '#C82333';
  ctx.font = '900 11px sans-serif';
  ctx.fillText(spec.gameTitle, 24, 28);
  ctx.fillStyle = '#FAF2EE';
  ctx.font = '800 15px sans-serif';
  ctx.fillText(spec.title.toUpperCase(), 24, 46);
  ctx.fillStyle = '#9E8E91';
  ctx.font = '600 9.5px monospace';
  ctx.fillText(spec.subtitle, 24, 60);

  // Compass Rose (Top Right)
  const cx = LOGICAL_W - 55;
  const cy = 42;
  ctx.beginPath();
  ctx.arc(cx, cy, 22, 0, Math.PI * 2);
  ctx.strokeStyle = 'rgba(200, 35, 51, 0.4)';
  ctx.stroke();
  ctx.fillStyle = '#FF4655';
  ctx.font = '900 10px sans-serif';
  ctx.textAlign = 'center';
  ctx.fillText('N', cx, cy - 8);
  ctx.fillStyle = '#FAF2EE';
  ctx.font = '700 8.5px monospace';
  ctx.fillText(spec.compassHeading, cx, cy + 12);

  // Directional Needle
  ctx.beginPath();
  ctx.moveTo(cx, cy - 6);
  ctx.lineTo(cx - 3, cy);
  ctx.lineTo(cx + 3, cy);
  ctx.closePath();
  ctx.fillStyle = '#C82333';
  ctx.fill();
  ctx.restore();

  // 6. Game-Specific Realistic Topographic Render
  if (mapId === 'rift') {
    drawLoLSummonersRift(ctx);
  } else if (mapId === 'bind') {
    drawValorantBindRealistic(ctx);
  } else if (mapId === 'dota') {
    drawDota2NewFrontiersRealistic(ctx);
  } else if (mapId === 'mirage' || mapId === 'dust2' || mapId === 'inferno') {
    drawCS2TacticalTerrain(ctx, mapId);
  } else if (mapId === 'erangel') {
    drawPUBGErangelRealistic(ctx);
  } else {
    // Generic Flow Lines connecting zones
    ctx.save();
    ctx.setLineDash([4, 4]);
    ctx.strokeStyle = 'rgba(200, 35, 51, 0.22)';
    ctx.lineWidth = 1.5;
    for (let i = 0; i < spec.zones.length - 1; i++) {
      const a = spec.zones[i];
      const b = spec.zones[i + 1];
      ctx.beginPath();
      ctx.moveTo(a.x + a.w / 2, a.y + a.h / 2);
      ctx.lineTo(b.x + b.w / 2, b.y + b.h / 2);
      ctx.stroke();
    }
    ctx.restore();
  }

  // 7. Architectural Zones, Bombsites & Terrain Features
  for (const z of spec.zones) {
    ctx.save();
    ctx.beginPath();
    ctx.roundRect(z.x, z.y, z.w, z.h, 7);

    if (z.isSite) {
      const siteGrad = ctx.createLinearGradient(z.x, z.y, z.x, z.y + z.h);
      siteGrad.addColorStop(0, 'rgba(143, 22, 34, 0.45)');
      siteGrad.addColorStop(1, 'rgba(28, 11, 16, 0.85)');
      ctx.fillStyle = siteGrad;
      ctx.fill();
      ctx.lineWidth = 1.8;
      ctx.strokeStyle = z.accent || '#C82333';
      ctx.stroke();

      // Outer plant zone pulse ring
      ctx.beginPath();
      ctx.arc(z.x + z.w / 2, z.y + z.h / 2 + 8, 22, 0, Math.PI * 2);
      ctx.setLineDash([4, 4]);
      ctx.strokeStyle = z.accent ? `${z.accent}88` : 'rgba(255, 70, 85, 0.55)';
      ctx.lineWidth = 1.5;
      ctx.stroke();
      ctx.setLineDash([]);

      ctx.beginPath();
      ctx.arc(z.x + z.w / 2, z.y + z.h / 2 + 8, 4.5, 0, Math.PI * 2);
      ctx.fillStyle = z.accent || '#FF334B';
      ctx.fill();
    } else {
      ctx.fillStyle = z.accent
        ? 'rgba(20, 10, 14, 0.92)'
        : 'rgba(16, 8, 12, 0.88)';
      ctx.fill();
      ctx.lineWidth = 1.2;
      ctx.strokeStyle = z.accent || 'rgba(143, 22, 34, 0.4)';
      ctx.stroke();
    }

    ctx.fillStyle = z.isSite ? '#FAF2EE' : '#D8CBCE';
    ctx.font = z.isSite ? '900 11px sans-serif' : '700 9.5px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText(z.label, z.x + z.w / 2, z.y + 18);

    ctx.restore();
  }
}

// ─────────────────────────────────────────────────────────
// Specific Map Engines matching Reference Images
// ─────────────────────────────────────────────────────────

function drawLoLSummonersRift(ctx: CanvasRenderingContext2D) {
  ctx.save();

  // 1. River Bed (Diagonal winding river from top-left to bottom-right)
  ctx.beginPath();
  ctx.moveTo(170, 70);
  ctx.bezierCurveTo(240, 140, 310, 180, 420, 240);
  ctx.bezierCurveTo(530, 300, 600, 340, 680, 410);
  ctx.strokeStyle = 'rgba(14, 116, 144, 0.35)';
  ctx.lineWidth = 42;
  ctx.lineCap = 'round';
  ctx.stroke();

  // River water center highlight
  ctx.beginPath();
  ctx.moveTo(170, 70);
  ctx.bezierCurveTo(240, 140, 310, 180, 420, 240);
  ctx.bezierCurveTo(530, 300, 600, 340, 680, 410);
  ctx.strokeStyle = 'rgba(6, 182, 212, 0.2)';
  ctx.lineWidth = 16;
  ctx.stroke();

  // 2. Three Lanes (Top, Mid, Bot)
  ctx.strokeStyle = 'rgba(180, 140, 100, 0.18)';
  ctx.lineWidth = 26;

  // Top Lane: (100, 380) -> (100, 80) -> (700, 80)
  ctx.beginPath();
  ctx.moveTo(120, 360);
  ctx.lineTo(120, 95);
  ctx.lineTo(670, 95);
  ctx.stroke();

  // Mid Lane: Diagonal (120, 360) -> (670, 95)
  ctx.beginPath();
  ctx.moveTo(120, 360);
  ctx.lineTo(670, 95);
  ctx.stroke();

  // Bot Lane: (120, 360) -> (670, 360) -> (670, 95)
  ctx.beginPath();
  ctx.moveTo(120, 360);
  ctx.lineTo(670, 360);
  ctx.lineTo(670, 95);
  ctx.stroke();

  // 3. Baron Nashor Pit & Dragon Pit Wall Outlines
  // Baron Pit Wall (Horseshoe at top-left river: ~280, 140)
  ctx.beginPath();
  ctx.arc(310, 155, 32, Math.PI * 0.7, Math.PI * 1.8);
  ctx.lineWidth = 6;
  ctx.strokeStyle = '#A855F7';
  ctx.stroke();

  // Dragon Pit Wall (Horseshoe at bottom-right river: ~520, 280)
  ctx.beginPath();
  ctx.arc(520, 280, 32, Math.PI * 1.7, Math.PI * 0.8);
  ctx.lineWidth = 6;
  ctx.strokeStyle = '#EF4444';
  ctx.stroke();

  // 4. Strategic Jungle Brushes (Çalılar)
  const brushes = [
    { x: 260, y: 195, w: 26, h: 14 },
    { x: 375, y: 155, w: 28, h: 14 },
    { x: 450, y: 225, w: 28, h: 14 },
    { x: 550, y: 235, w: 26, h: 14 },
    { x: 195, y: 95, w: 28, h: 14 },
    { x: 620, y: 360, w: 28, h: 14 },
    { x: 205, y: 300, w: 24, h: 16 },
    { x: 590, y: 180, w: 24, h: 16 },
  ];
  brushes.forEach((b) => {
    ctx.beginPath();
    ctx.ellipse(b.x, b.y, b.w / 2, b.h / 2, 0, 0, Math.PI * 2);
    ctx.fillStyle = 'rgba(22, 101, 52, 0.65)';
    ctx.fill();
    ctx.strokeStyle = 'rgba(34, 197, 94, 0.7)';
    ctx.lineWidth = 1.2;
    ctx.stroke();
  });

  // 5. Jungle Camp Markers (Reference Image 4 jungle path tokens)
  const camps = [
    { name: 'Gromp', x: 175, y: 200, color: '#38BDF8' },
    { name: 'Mavi (Blue)', x: 240, y: 230, color: '#3B82F6' },
    { name: 'Kurtlar', x: 265, y: 280, color: '#93C5FD' },
    { name: 'Keskingaga', x: 480, y: 205, color: '#F87171' },
    { name: 'Kırmızı (Red)', x: 535, y: 170, color: '#EF4444' },
    { name: 'Kayacıl', x: 590, y: 140, color: '#FCA5A5' },
  ];
  camps.forEach((c) => {
    ctx.beginPath();
    ctx.arc(c.x, c.y, 8, 0, Math.PI * 2);
    ctx.fillStyle = 'rgba(15, 23, 42, 0.85)';
    ctx.fill();
    ctx.lineWidth = 1.8;
    ctx.strokeStyle = c.color;
    ctx.stroke();
    ctx.beginPath();
    ctx.arc(c.x, c.y, 3, 0, Math.PI * 2);
    ctx.fillStyle = c.color;
    ctx.fill();
  });

  ctx.restore();
}

function drawValorantBindRealistic(ctx: CanvasRenderingContext2D) {
  ctx.save();

  // Reference Image 1 matching:
  // Cyan Teleporter Route Lines
  // A Port -> A Port Exit (X)
  ctx.beginPath();
  ctx.moveTo(475, 185);
  ctx.lineTo(440, 220);
  ctx.lineTo(390, 220);
  ctx.setLineDash([3, 3]);
  ctx.strokeStyle = '#00F0FF';
  ctx.lineWidth = 2.2;
  ctx.stroke();
  ctx.setLineDash([]);

  // Teleporter Arrowhead at Exit
  ctx.beginPath();
  ctx.arc(385, 220, 11, 0, Math.PI * 2);
  ctx.fillStyle = 'rgba(0, 240, 255, 0.2)';
  ctx.fill();
  ctx.strokeStyle = '#00F0FF';
  ctx.lineWidth = 1.5;
  ctx.stroke();
  ctx.fillStyle = '#00F0FF';
  ctx.font = '900 11px sans-serif';
  ctx.textAlign = 'center';
  ctx.fillText('X', 385, 224);

  // B Port -> B Port Exit (X)
  ctx.beginPath();
  ctx.moveTo(105, 205);
  ctx.lineTo(105, 345);
  ctx.lineTo(350, 345);
  ctx.lineTo(650, 345);
  ctx.lineTo(690, 290);
  ctx.setLineDash([3, 3]);
  ctx.strokeStyle = '#00F0FF';
  ctx.lineWidth = 2.2;
  ctx.stroke();
  ctx.setLineDash([]);

  ctx.beginPath();
  ctx.arc(690, 285, 11, 0, Math.PI * 2);
  ctx.fillStyle = 'rgba(0, 240, 255, 0.2)';
  ctx.fill();
  ctx.strokeStyle = '#00F0FF';
  ctx.lineWidth = 1.5;
  ctx.stroke();
  ctx.fillStyle = '#00F0FF';
  ctx.font = '900 11px sans-serif';
  ctx.textAlign = 'center';
  ctx.fillText('X', 690, 289);

  // Corridor walls (Dark purple/blue polygon fills)
  ctx.fillStyle = 'rgba(30, 41, 59, 0.25)';
  // A Site planting zone inner box
  ctx.strokeStyle = '#10B981';
  ctx.lineWidth = 2;
  ctx.strokeRect(605, 105, 75, 55);

  // B Site planting zone inner box
  ctx.strokeRect(140, 105, 75, 55);

  // Red barrier lines
  ctx.strokeStyle = '#EF4444';
  ctx.lineWidth = 2.5;
  // B Long barrier
  ctx.beginPath();
  ctx.moveTo(80, 275);
  ctx.lineTo(135, 275);
  ctx.stroke();
  // A Short barrier
  ctx.beginPath();
  ctx.moveTo(470, 260);
  ctx.lineTo(530, 260);
  ctx.stroke();
  // Showers barrier
  ctx.beginPath();
  ctx.moveTo(655, 270);
  ctx.lineTo(715, 270);
  ctx.stroke();

  ctx.restore();
}

function drawDota2NewFrontiersRealistic(ctx: CanvasRenderingContext2D) {
  ctx.save();

  // Reference Image 3: Dota 2 New Frontiers 7.33+
  // Diagonal River Bed
  ctx.beginPath();
  ctx.moveTo(130, 380);
  ctx.lineTo(700, 110);
  ctx.strokeStyle = 'rgba(6, 182, 212, 0.28)';
  ctx.lineWidth = 36;
  ctx.lineCap = 'round';
  ctx.stroke();

  // Top-Left Roshan Pit (Dire Cavern) with glowing purple-red aura
  ctx.beginPath();
  ctx.arc(195, 105, 28, 0, Math.PI * 2);
  ctx.fillStyle = 'rgba(220, 38, 38, 0.3)';
  ctx.fill();
  ctx.strokeStyle = '#DC2626';
  ctx.lineWidth = 2.5;
  ctx.stroke();
  ctx.fillStyle = '#FFFFFF';
  ctx.font = '900 10px sans-serif';
  ctx.textAlign = 'center';
  ctx.fillText('ROSHAN', 195, 109);

  // Bottom-Right Roshan Pit (Radiant Cavern)
  ctx.beginPath();
  ctx.arc(645, 370, 28, 0, Math.PI * 2);
  ctx.fillStyle = 'rgba(220, 38, 38, 0.3)';
  ctx.fill();
  ctx.strokeStyle = '#DC2626';
  ctx.lineWidth = 2.5;
  ctx.stroke();
  ctx.fillStyle = '#FFFFFF';
  ctx.font = '900 10px sans-serif';
  ctx.textAlign = 'center';
  ctx.fillText('ROSHAN', 645, 374);

  // Twin Gates (Cyan Portal Nodes connecting corners)
  ctx.beginPath();
  ctx.moveTo(100, 85);
  ctx.lineTo(740, 390);
  ctx.setLineDash([4, 6]);
  ctx.strokeStyle = 'rgba(0, 240, 255, 0.35)';
  ctx.lineWidth = 1.8;
  ctx.stroke();
  ctx.setLineDash([]);

  // Watchers & Tormentor Markers
  const watchers = [
    { x: 310, y: 130 },
    { x: 420, y: 160 },
    { x: 260, y: 260 },
    { x: 530, y: 220 },
    { x: 410, y: 320 },
    { x: 580, y: 290 },
  ];
  watchers.forEach((w) => {
    ctx.beginPath();
    ctx.arc(w.x, w.y, 6.5, 0, Math.PI * 2);
    ctx.fillStyle = '#EAB308';
    ctx.fill();
    ctx.strokeStyle = '#FAF2EE';
    ctx.lineWidth = 1;
    ctx.stroke();
  });

  // Radiant Green Base & Dire Red Base Ancients
  ctx.fillStyle = '#10B981';
  ctx.fillRect(125, 375, 24, 24);
  ctx.fillStyle = '#EF4444';
  ctx.fillRect(685, 80, 24, 24);

  ctx.restore();
}

function drawCS2TacticalTerrain(
  ctx: CanvasRenderingContext2D,
  mapId: 'mirage' | 'dust2' | 'inferno',
) {
  ctx.save();
  if (mapId === 'mirage') {
    // Palace -> A Site dashed entry
    ctx.beginPath();
    ctx.moveTo(700, 395);
    ctx.lineTo(650, 320);
    ctx.setLineDash([4, 3]);
    ctx.strokeStyle = '#C82333';
    ctx.lineWidth = 2;
    ctx.stroke();

    // A Ramp -> A Site
    ctx.beginPath();
    ctx.moveTo(590, 395);
    ctx.lineTo(600, 320);
    ctx.stroke();

    // Connector & Window to Mid
    ctx.strokeRect(360, 210, 65, 45);
    ctx.setLineDash([]);
  } else if (mapId === 'dust2') {
    // Long A corner and double doors
    ctx.strokeRect(670, 280, 45, 60);
    // B Tunnels
    ctx.strokeRect(130, 240, 70, 45);
  } else if (mapId === 'inferno') {
    // Banana curved lane
    ctx.beginPath();
    ctx.moveTo(170, 350);
    ctx.quadraticCurveTo(230, 260, 230, 160);
    ctx.strokeStyle = 'rgba(229, 169, 60, 0.45)';
    ctx.lineWidth = 18;
    ctx.stroke();
  }
  ctx.restore();
}

function drawPUBGErangelRealistic(ctx: CanvasRenderingContext2D) {
  ctx.save();
  // Coastline of Erangel & Sosnovka Island
  ctx.strokeStyle = 'rgba(56, 189, 248, 0.35)';
  ctx.lineWidth = 3;

  // Main Island Coastline
  ctx.strokeRect(100, 65, 640, 270);

  // Sosnovka Island at Bottom
  ctx.strokeRect(260, 350, 320, 100);

  // Two Bridges connecting main island to Sosnovka
  ctx.fillStyle = '#E5A93C';
  ctx.fillRect(330, 335, 12, 16);
  ctx.fillRect(510, 335, 12, 16);

  ctx.restore();
}
