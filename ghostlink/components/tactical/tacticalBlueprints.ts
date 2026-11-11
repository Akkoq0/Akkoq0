// ─────────────────────────────────────────────────────────
// Meva HUD — Esports Stratbook High-Fidelity Tactical Blueprints
// ─────────────────────────────────────────────────────────
// Topographically realistic 2D radar/minimap textures and blueprints
// (LoL 2026 Summoner's Rift & ARAM, Valorant Bind/Ascent/Haven/Split/Lotus,
// CS2 Mirage/Inferno/Dust2/Ancient/Nuke, Dota 2 New Frontiers, PUBG Erangel/Miramar/Sanhok).
//
// CRITICAL RULE:
// ASLA KODLA KUTU ÇİZME (No primitive rectangular wireframe boxes).
// True high-resolution 2D radar textures loaded seamlessly.

export type TacticalGameCategory = 'valorant' | 'cs2' | 'lol' | 'dota2' | 'pubg';

export type TacticalMapId =
  | 'ascent'
  | 'bind'
  | 'haven'
  | 'split'
  | 'lotus'
  | 'breeze'
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

export interface MapMetaSpec {
  title: string;
  game: TacticalGameCategory;
  gameTitle: string;
  subtitle: string;
  compassHeading: string;
  imageUrl?: string;
}

export const GAME_MAP_POOLS: Record<TacticalGameCategory, TacticalMapId[]> = {
  valorant: ['ascent', 'bind', 'haven', 'split', 'lotus', 'breeze'],
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
    imageUrl: 'https://media.valorant-api.com/maps/2c9d57ec-4431-9c5e-2939-8f9ef6dd5cba/displayicon.png',
  },
  ascent: {
    title: 'Ascent',
    game: 'valorant',
    gameTitle: 'VALORANT ARENA',
    subtitle: 'Venedik, İtalya · Geniş Mid & Kapanır Kapılar',
    compassHeading: 'N 18°E',
    imageUrl: 'https://media.valorant-api.com/maps/7eaecc1b-4337-bbf6-6ab9-04b8f06b3319/displayicon.png',
  },
  haven: {
    title: 'Haven',
    game: 'valorant',
    gameTitle: 'VALORANT ARENA (3 BOMBSITE)',
    subtitle: 'Thimphu, Butan · 3 Bombalı Taktik Matrisi',
    compassHeading: 'N 25°E',
    imageUrl: 'https://media.valorant-api.com/maps/2bee0dc9-4ffe-519b-1cbd-7fbe763a6047/displayicon.png',
  },
  split: {
    title: 'Split',
    game: 'valorant',
    gameTitle: 'VALORANT ARENA',
    subtitle: 'Tokyo, Japonya · Dikey Ropes & Vents',
    compassHeading: 'N 04°E',
    imageUrl: 'https://media.valorant-api.com/maps/d960549e-485c-e861-8d71-aa9d1aed12a2/displayicon.png',
  },
  lotus: {
    title: 'Lotus',
    game: 'valorant',
    gameTitle: 'VALORANT ARENA (3 BOMBSITE)',
    subtitle: 'Batı Ghats, Hindistan · Dönen Kapılar & Yıkılan Duvar',
    compassHeading: 'N 14°W',
    imageUrl: 'https://media.valorant-api.com/maps/2fe4ed3a-450a-948b-6d6b-e89a78e680a9/displayicon.png',
  },
  breeze: {
    title: 'Breeze',
    game: 'valorant',
    gameTitle: 'VALORANT ARENA',
    subtitle: 'Bermuda Şeytan Üçgeni · Geniş Açık Alanlar & A Pyramids',
    compassHeading: 'N 10°E',
    imageUrl: 'https://media.valorant-api.com/maps/2fb9a4fd-47b8-4e7d-a969-74b4046ebd53/displayicon.png',
  },

  // ── CS2 ──
  mirage: {
    title: 'Mirage',
    game: 'cs2',
    gameTitle: 'CS2 TAKTİK ARENASI',
    subtitle: 'Fas Çölü · Rekabetçi Espor Standardı',
    compassHeading: 'N 02°E',
    imageUrl: 'https://raw.githubusercontent.com/2mlml/cs2-radar-images/master/de_mirage.png',
  },
  inferno: {
    title: 'Inferno',
    game: 'cs2',
    gameTitle: 'CS2 TAKTİK ARENASI',
    subtitle: 'Toskana, İtalya · Klasik Dar Geçitler & Muz',
    compassHeading: 'N 28°E',
    imageUrl: 'https://raw.githubusercontent.com/2mlml/cs2-radar-images/master/de_inferno.png',
  },
  dust2: {
    title: 'Dust II',
    game: 'cs2',
    gameTitle: 'CS2 TAKTİK ARENASI',
    subtitle: 'Kazablanka, Fas · İkonik Long A & B Tünel',
    compassHeading: 'N 05°E',
    imageUrl: 'https://raw.githubusercontent.com/2mlml/cs2-radar-images/master/de_dust2.png',
  },
  ancient: {
    title: 'Ancient',
    game: 'cs2',
    gameTitle: 'CS2 TAKTİK ARENASI',
    subtitle: 'Mezoamerika Harabeleri · Donut & Cheetah',
    compassHeading: 'N 31°W',
    imageUrl: 'https://raw.githubusercontent.com/2mlml/cs2-radar-images/master/de_ancient.png',
  },
  nuke: {
    title: 'Nuke',
    game: 'cs2',
    gameTitle: 'CS2 TAKTİK ARENASI (ÇİFT KATMAN)',
    subtitle: 'Nükleer Santral · Üst A & Alt B Reaktör Katı',
    compassHeading: 'N 08°E',
    imageUrl: 'https://raw.githubusercontent.com/2mlml/cs2-radar-images/master/de_nuke.png',
  },

  // ── LEAGUE OF LEGENDS ──
  rift: {
    title: 'Sihirdar Vadisi',
    game: 'lol',
    gameTitle: 'MOBA STRATEJİ MATRİSİ',
    subtitle: 'Runeterra · 3 Koridor, 12 Orman Kampı & Baron/Ejder',
    compassHeading: 'N 45°E',
    imageUrl: 'https://ddragon.leagueoflegends.com/cdn/14.1.1/img/map/map11.png',
  },
  aram: {
    title: 'Sonsuz Uçurum (ARAM)',
    game: 'lol',
    gameTitle: 'MOBA KÖPRÜ ÇATIŞMASI',
    subtitle: 'Freljord · Tek Koridor & Kesintisiz Savaş',
    compassHeading: 'N 30°E',
    imageUrl: 'https://ddragon.leagueoflegends.com/cdn/14.1.1/img/map/map12.png',
  },

  // ── DOTA 2 ──
  dota: {
    title: 'Kadimler Vadisi (New Frontiers)',
    game: 'dota2',
    gameTitle: 'DOTA 2 7.33+ STRATEJİ MATRİSİ',
    subtitle: 'Çift Roshan Çukuru · İkiz Kapılar & Tormentors',
    compassHeading: 'N 00°',
    imageUrl: 'https://raw.githubusercontent.com/leejordan/dota2minimap/master/images/minimap.png',
  },

  // ── PUBG ──
  erangel: {
    title: 'Erangel',
    game: 'pubg',
    gameTitle: 'BATTLE ROYALE MATRİSİ',
    subtitle: 'Karadeniz Askeri Ada · 8x8 km Koordinat',
    compassHeading: 'N 12°W',
    imageUrl: 'https://raw.githubusercontent.com/pubg/api-assets/master/Assets/Maps/Erangel_Main_Low_Res.png',
  },
  miramar: {
    title: 'Miramar',
    game: 'pubg',
    gameTitle: 'BATTLE ROYALE ÇÖL MATRİSİ',
    subtitle: 'Meksika Çölü · Los Leones & Pecado',
    compassHeading: 'N 22°E',
    imageUrl: 'https://raw.githubusercontent.com/pubg/api-assets/master/Assets/Maps/Miramar_Main_Low_Res.png',
  },
  sanhok: {
    title: 'Sanhok',
    game: 'pubg',
    gameTitle: 'BATTLE ROYALE YAĞMUR ORMANI',
    subtitle: 'Güneydoğu Asya 4x4 · Bootcamp & Paradise',
    compassHeading: 'N 05°W',
    imageUrl: 'https://raw.githubusercontent.com/pubg/api-assets/master/Assets/Maps/Sanhok_Main_Low_Res.png',
  },
};

// Global in-memory image cache for 60 FPS zero-lag canvas draws
const RADAR_IMAGE_CACHE: Record<string, HTMLImageElement> = {};
const RADAR_LOADING_STATUS: Record<string, 'loading' | 'loaded' | 'error'> = {};

export function preloadMapRadarImage(mapId: string, url: string, onLoaded?: () => void) {
  if (RADAR_IMAGE_CACHE[mapId]?.complete && RADAR_IMAGE_CACHE[mapId]?.naturalWidth > 0) {
    return RADAR_IMAGE_CACHE[mapId];
  }
  if (RADAR_LOADING_STATUS[mapId] === 'loading') return null;

  RADAR_LOADING_STATUS[mapId] = 'loading';
  const img = new Image();
  img.crossOrigin = 'anonymous';
  img.onload = () => {
    RADAR_IMAGE_CACHE[mapId] = img;
    RADAR_LOADING_STATUS[mapId] = 'loaded';
    if (onLoaded) onLoaded();
  };
  img.onerror = () => {
    RADAR_LOADING_STATUS[mapId] = 'error';
  };
  img.src = url;
  return null;
}

// ─────────────────────────────────────────────────────────
// Detailed Topographical Renderers (NO SCHEMATIC BOXES)
// ─────────────────────────────────────────────────────────

export interface TacticalBlueprintOptions {
  gridMode?: 'standard' | 'dense' | 'none';
  showCompass?: boolean;
  accentColor?: string;
}

export function drawRealisticArenaBlueprint(
  ctx: CanvasRenderingContext2D,
  mapId: Exclude<TacticalMapId, 'custom'>,
  onImageLoadedCallback?: () => void,
  options?: TacticalBlueprintOptions,
) {
  ctx.clearRect(0, 0, LOGICAL_W, LOGICAL_H);
  const spec = MAP_BLUEPRINTS[mapId];
  if (!spec) return;

  const accent = options?.accentColor || '#C82333';
  const gridMode = options?.gridMode || 'standard';
  const showCompass = options?.showCompass !== false;

  // 1. Base Layer: Deep Espresso & Obsidian Canvas
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

  // 2. Render Real 2D Minimap Radar Texture if Available
  if (spec.imageUrl) {
    let cachedImg = RADAR_IMAGE_CACHE[mapId];
    if (!cachedImg || !cachedImg.complete) {
      preloadMapRadarImage(mapId, spec.imageUrl, onImageLoadedCallback);
      cachedImg = RADAR_IMAGE_CACHE[mapId];
    }

    if (cachedImg && cachedImg.complete && cachedImg.naturalWidth > 0) {
      ctx.save();
      // Fit maintaining aspect ratio
      const imgAspect = cachedImg.naturalWidth / cachedImg.naturalHeight;
      const canvasAspect = LOGICAL_W / LOGICAL_H;
      let drawW = LOGICAL_W;
      let drawH = LOGICAL_H;
      let drawX = 0;
      let drawY = 0;

      if (imgAspect > canvasAspect) {
        drawW = LOGICAL_W;
        drawH = LOGICAL_W / imgAspect;
        drawY = (LOGICAL_H - drawH) / 2;
      } else {
        drawH = LOGICAL_H;
        drawW = LOGICAL_H * imgAspect;
        drawX = (LOGICAL_W - drawW) / 2;
      }

      ctx.drawImage(cachedImg, drawX, drawY, drawW, drawH);

      // Contrast Vignette Overlay (keeps HUD elements crisp)
      const vignette = ctx.createRadialGradient(
        LOGICAL_W / 2,
        LOGICAL_H / 2,
        180,
        LOGICAL_W / 2,
        LOGICAL_H / 2,
        480,
      );
      vignette.addColorStop(0, 'rgba(4, 2, 3, 0.05)');
      vignette.addColorStop(0.7, 'rgba(4, 2, 3, 0.28)');
      vignette.addColorStop(1, 'rgba(4, 2, 3, 0.65)');
      ctx.fillStyle = vignette;
      ctx.fillRect(0, 0, LOGICAL_W, LOGICAL_H);
      ctx.restore();
    }
  }

  // 3. High-Tech Tactical Radar Grid (Configurable: standard, dense, or none)
  if (gridMode !== 'none') {
    const step = gridMode === 'dense' ? 30 : 60;
    ctx.strokeStyle = `${accent}1F`;
    ctx.lineWidth = 1;
    for (let x = step; x < LOGICAL_W; x += step) {
      ctx.beginPath();
      ctx.moveTo(x, 0);
      ctx.lineTo(x, LOGICAL_H);
      ctx.stroke();
    }
    for (let y = step; y < LOGICAL_H; y += step) {
      ctx.beginPath();
      ctx.moveTo(0, y);
      ctx.lineTo(LOGICAL_W, y);
      ctx.stroke();
    }

    // Crosshairs (+) at every grid intersection
    ctx.strokeStyle = `${accent}44`;
    ctx.lineWidth = 1;
    for (let x = step; x < LOGICAL_W; x += step) {
      for (let y = step; y < LOGICAL_H; y += step) {
        ctx.beginPath();
        ctx.moveTo(x - 3.5, y);
        ctx.lineTo(x + 3.5, y);
        ctx.moveTo(x, y - 3.5);
        ctx.lineTo(x, y + 3.5);
        ctx.stroke();
      }
    }

    // 4. Coordinates Labels (A-N, 1-7)
    ctx.fillStyle = 'rgba(184, 170, 172, 0.35)';
    ctx.font = '700 9px monospace';
    const cols = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N'];
    cols.forEach((c, idx) => {
      ctx.fillText(c, idx * 60 + 26, 13);
    });
    for (let r = 1; r <= 7; r++) {
      ctx.fillText(`${r}`, 6, r * 60 + 4);
    }
  }

  // 5. Stylized Esports Map Header & Compass HUD (Top Left & Top Right)
  ctx.save();
  ctx.fillStyle = `${accent}B8`;
  ctx.font = '600 10px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif';
  ctx.fillText(spec.gameTitle, 24, 26);
  ctx.fillStyle = '#EDE7E9';
  ctx.font = '600 14px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif';
  ctx.fillText(spec.title, 24, 43);
  ctx.fillStyle = '#8E8285';
  ctx.font = '400 9px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif';
  ctx.fillText(spec.subtitle, 24, 57);

  // Compass Rose (Top Right)
  if (showCompass) {
    const cx = LOGICAL_W - 55;
    const cy = 42;
    ctx.beginPath();
    ctx.arc(cx, cy, 20, 0, Math.PI * 2);
    ctx.strokeStyle = `${accent}40`;
    ctx.stroke();
    ctx.fillStyle = accent;
    ctx.font = '600 9.5px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('N', cx, cy - 7);
    ctx.fillStyle = '#EDE7E9';
    ctx.font = '500 8px sans-serif';
    ctx.fillText(spec.compassHeading, cx, cy + 10);

    // Directional Needle
    ctx.beginPath();
    ctx.moveTo(cx, cy - 6);
    ctx.lineTo(cx - 3, cy);
    ctx.lineTo(cx + 3, cy);
    ctx.closePath();
    ctx.fillStyle = accent;
    ctx.fill();
  }
  ctx.restore();
}

// ─────────────────────────────────────────────────────────
// Map Callouts & Tactical Landmarks (LoL, Valorant, Dota, CS2)
// ─────────────────────────────────────────────────────────

export interface MapCallout {
  id: string;
  label: string;
  x: number;
  y: number;
  type: 'site' | 'spawn' | 'portal' | 'choke' | 'objective' | 'neutral';
}

export const MAP_CALLOUT_PRESETS: Partial<Record<TacticalMapId, MapCallout[]>> = {
  // ── VALORANT: BIND ──
  bind: [
    { id: 'b-def', label: 'DEFENDER SPAWN', x: 420, y: 70, type: 'spawn' },
    { id: 'b-atk', label: 'ATTACKER SPAWN', x: 420, y: 420, type: 'spawn' },
    { id: 'b-site-a', label: 'A SITE', x: 510, y: 160, type: 'site' },
    { id: 'b-site-b', label: 'B SITE', x: 305, y: 140, type: 'site' },
    { id: 'b-a-port', label: 'A PORT (Işınlayıcı)', x: 455, y: 195, type: 'portal' },
    { id: 'b-a-exit', label: 'A PORT ÇIKIŞI (B Short)', x: 385, y: 210, type: 'portal' },
    { id: 'b-b-port', label: 'B PORT (Işınlayıcı)', x: 240, y: 205, type: 'portal' },
    { id: 'b-b-exit', label: 'B PORT ÇIKIŞI (A Lobby)', x: 565, y: 300, type: 'portal' },
    { id: 'b-showers', label: 'HAMAM (Showers)', x: 550, y: 210, type: 'choke' },
    { id: 'b-uhall', label: 'LAMBA (U-Hall)', x: 470, y: 160, type: 'choke' },
    { id: 'b-hookah', label: 'NARGİLE (Hookah)', x: 315, y: 230, type: 'choke' },
    { id: 'b-blong', label: 'B UZUN (B Long)', x: 270, y: 250, type: 'choke' },
    { id: 'b-ashort', label: 'A KISA (A Short)', x: 450, y: 250, type: 'choke' },
  ],

  // ── VALORANT: BREEZE ──
  breeze: [
    { id: 'brz-def', label: 'DEFENDER SIDE SPAWN', x: 450, y: 80, type: 'spawn' },
    { id: 'brz-atk', label: 'ATTACKER SIDE SPAWN', x: 375, y: 400, type: 'spawn' },
    { id: 'brz-site-a', label: 'A SITE (Piramitler)', x: 530, y: 230, type: 'site' },
    { id: 'brz-site-b', label: 'B SITE (B Back)', x: 295, y: 160, type: 'site' },
    { id: 'brz-acave', label: 'A MAĞARA (Cave)', x: 530, y: 340, type: 'choke' },
    { id: 'brz-ahall', label: 'A KORİDOR (Hall)', x: 480, y: 260, type: 'choke' },
    { id: 'brz-midchutes', label: 'ORTA KAYDIRAK (Chutes)', x: 410, y: 270, type: 'choke' },
    { id: 'brz-midnest', label: 'ORTA YUVA (Nest)', x: 410, y: 150, type: 'choke' },
    { id: 'brz-bmain', label: 'B ANA (Main)', x: 285, y: 250, type: 'choke' },
    { id: 'brz-belbow', label: 'B DİRSEK (Elbow)', x: 295, y: 200, type: 'choke' },
  ],

  // ── VALORANT: ASCENT ──
  ascent: [
    { id: 'asc-def', label: 'DEFENDER SPAWN', x: 420, y: 80, type: 'spawn' },
    { id: 'asc-atk', label: 'ATTACKER SPAWN', x: 420, y: 410, type: 'spawn' },
    { id: 'asc-site-a', label: 'A SITE (Heaven / Hell)', x: 515, y: 180, type: 'site' },
    { id: 'asc-site-b', label: 'B SITE (Boathouse)', x: 325, y: 190, type: 'site' },
    { id: 'asc-tree', label: 'A AĞAÇ (Tree Door)', x: 465, y: 210, type: 'choke' },
    { id: 'asc-market', label: 'MARKET (B Market)', x: 375, y: 220, type: 'choke' },
    { id: 'asc-mid', label: 'ORTA AVLU (Mid Courtyard)', x: 420, y: 250, type: 'choke' },
    { id: 'asc-amain', label: 'A ANA (A Main)', x: 510, y: 290, type: 'choke' },
    { id: 'asc-bmain', label: 'B ANA (B Main)', x: 330, y: 290, type: 'choke' },
  ],

  // ── VALORANT: HAVEN ──
  haven: [
    { id: 'hvn-def', label: 'DEFENDER SPAWN', x: 420, y: 70, type: 'spawn' },
    { id: 'hvn-atk', label: 'ATTACKER SPAWN', x: 420, y: 425, type: 'spawn' },
    { id: 'hvn-site-a', label: 'A SITE', x: 540, y: 170, type: 'site' },
    { id: 'hvn-site-b', label: 'B SITE', x: 420, y: 180, type: 'site' },
    { id: 'hvn-site-c', label: 'C SITE', x: 300, y: 170, type: 'site' },
    { id: 'hvn-along', label: 'A UZUN (A Long)', x: 570, y: 280, type: 'choke' },
    { id: 'hvn-asewer', label: 'A KANAL (Sewer)', x: 490, y: 290, type: 'choke' },
    { id: 'hvn-aheaven', label: 'A KULE (Heaven)', x: 540, y: 115, type: 'choke' },
    { id: 'hvn-midyard', label: 'ORTA AVLU (Mid)', x: 420, y: 280, type: 'choke' },
    { id: 'hvn-middoor', label: 'GARAJ KAPISI (Garage)', x: 360, y: 240, type: 'choke' },
    { id: 'hvn-midwin', label: 'ORTA PENCERE (Window)', x: 420, y: 340, type: 'choke' },
    { id: 'hvn-clong', label: 'C UZUN (C Long)', x: 265, y: 280, type: 'choke' },
    { id: 'hvn-clink', label: 'C BAĞLANTI (C Link)', x: 335, y: 140, type: 'choke' },
  ],

  // ── VALORANT: SPLIT ──
  split: [
    { id: 'spl-def', label: 'DEFENDER SPAWN', x: 420, y: 75, type: 'spawn' },
    { id: 'spl-atk', label: 'ATTACKER SPAWN', x: 420, y: 420, type: 'spawn' },
    { id: 'spl-site-a', label: 'A SITE', x: 520, y: 190, type: 'site' },
    { id: 'spl-site-b', label: 'B SITE', x: 320, y: 190, type: 'site' },
    { id: 'spl-aropes', label: 'A HALATLAR (Ropes)', x: 470, y: 200, type: 'choke' },
    { id: 'spl-midvent', label: 'HAVALANDIRMA (Vent)', x: 450, y: 240, type: 'choke' },
    { id: 'spl-midmail', label: 'POSTA (Mail)', x: 380, y: 230, type: 'choke' },
    { id: 'spl-btower', label: 'B KULE (B Tower)', x: 330, y: 145, type: 'choke' },
    { id: 'spl-amain', label: 'A ANA (A Main)', x: 530, y: 295, type: 'choke' },
    { id: 'spl-ascreens', label: 'EKRANLAR (Screens)', x: 510, y: 130, type: 'choke' },
    { id: 'spl-bgarage', label: 'B GARAJ / ANA', x: 315, y: 295, type: 'choke' },
    { id: 'spl-balley', label: 'B ARA SOKAK (Alley)', x: 275, y: 170, type: 'choke' },
  ],

  // ── VALORANT: LOTUS ──
  lotus: [
    { id: 'lot-def', label: 'DEFENDER SPAWN', x: 420, y: 75, type: 'spawn' },
    { id: 'lot-atk', label: 'ATTACKER SPAWN', x: 420, y: 425, type: 'spawn' },
    { id: 'lot-site-a', label: 'A SITE', x: 540, y: 170, type: 'site' },
    { id: 'lot-site-b', label: 'B SITE', x: 420, y: 170, type: 'site' },
    { id: 'lot-site-c', label: 'C SITE', x: 300, y: 170, type: 'site' },
    { id: 'lot-atree', label: 'A AĞAÇ (Dönen Kapı)', x: 480, y: 215, type: 'portal' },
    { id: 'lot-aroot', label: 'A HARABE (Root)', x: 545, y: 310, type: 'choke' },
    { id: 'lot-bmain', label: 'B ANA (Main)', x: 420, y: 260, type: 'choke' },
    { id: 'lot-cmound', label: 'C TEPE (Mound)', x: 320, y: 300, type: 'choke' },
    { id: 'lot-chall', label: 'C KORİDOR (Hall)', x: 275, y: 150, type: 'choke' },
    { id: 'lot-cbend', label: 'C KIVRIM (Bend)', x: 345, y: 230, type: 'choke' },
  ],

  // ── LEAGUE OF LEGENDS: SIHIRDAR VADISI ──
  rift: [
    { id: 'lol-blue-base', label: 'MAVİ ÜS (Blue Base)', x: 240, y: 420, type: 'spawn' },
    { id: 'lol-red-base', label: 'KIRMIZI ÜS (Red Base)', x: 600, y: 60, type: 'spawn' },
    { id: 'lol-baron', label: 'BARON NASHOR (20:00+)', x: 350, y: 160, type: 'objective' },
    { id: 'lol-dragon', label: 'EJDERHA ÇUKURU (Dragon)', x: 490, y: 320, type: 'objective' },
    { id: 'lol-herald', label: "VADİ'NİN ALAMETİ / KURT", x: 350, y: 175, type: 'objective' },
    { id: 'lol-blue-buff', label: 'MAVİ GÜÇLENDİRME (1)', x: 330, y: 320, type: 'neutral' },
    { id: 'lol-gromp', label: 'GROMP (2)', x: 290, y: 290, type: 'neutral' },
    { id: 'lol-wolves', label: 'ALACAKURTLAR (3)', x: 345, y: 275, type: 'neutral' },
    { id: 'lol-raptors', label: 'YIRTICILAR (4)', x: 410, y: 305, type: 'neutral' },
    { id: 'lol-red-buff', label: 'KIRMIZI GÜÇLENDİRME (5)', x: 440, y: 335, type: 'neutral' },
    { id: 'lol-krugs', label: 'KAYACILLAR (6)', x: 465, y: 370, type: 'neutral' },
    { id: 'lol-mid', label: 'ORTA KORİDOR (Mid)', x: 420, y: 240, type: 'choke' },
  ],

  // ── LEAGUE OF LEGENDS: SONSUZ UÇURUM (ARAM) ──
  aram: [
    { id: 'aram-blue-nexus', label: 'MAVİ NEXUS (Blue Base)', x: 230, y: 410, type: 'spawn' },
    { id: 'aram-red-nexus', label: 'KIRMIZI NEXUS (Red Base)', x: 610, y: 70, type: 'spawn' },
    { id: 'aram-bridge', label: 'MERKEZ KÖPRÜ (Bridge)', x: 420, y: 240, type: 'choke' },
    { id: 'aram-blue-inhib', label: 'MAVİ İNHİBİTÖR KULESİ', x: 310, y: 340, type: 'objective' },
    { id: 'aram-red-inhib', label: 'KIRMIZI İNHİBİTÖR KULESİ', x: 530, y: 140, type: 'objective' },
    { id: 'aram-relic-north', label: 'CAN PAKETİ (Kuzey Relic)', x: 460, y: 200, type: 'neutral' },
    { id: 'aram-relic-south', label: 'CAN PAKETİ (Güney Relic)', x: 380, y: 280, type: 'neutral' },
    { id: 'aram-bush', label: 'MERKEZ ÇALILIK', x: 430, y: 225, type: 'choke' },
    { id: 'aram-hexgate', label: 'HEXTECH GEÇİDİ (Hexgate)', x: 270, y: 380, type: 'portal' },
  ],

  // ── DOTA 2: KADIMLER VADISI (7.33+ NEW FRONTIERS) ──
  dota: [
    { id: 'dota-rad-base', label: 'RADIANT KADİMİ', x: 235, y: 425, type: 'spawn' },
    { id: 'dota-dire-base', label: 'DIRE KADİMİ', x: 605, y: 55, type: 'spawn' },
    { id: 'dota-roshan-day', label: 'ROSHAN (Gündüz Çukuru)', x: 220, y: 60, type: 'objective' },
    { id: 'dota-roshan-night', label: 'ROSHAN (Gece Çukuru)', x: 620, y: 420, type: 'objective' },
    { id: 'dota-twin-top', label: 'İKİZ GEÇİT (Kuzey)', x: 205, y: 65, type: 'portal' },
    { id: 'dota-twin-bot', label: 'İKİZ GEÇİT (Güney)', x: 635, y: 415, type: 'portal' },
    { id: 'dota-torm-rad', label: 'TORMENTOR (Radiant 20m)', x: 280, y: 330, type: 'objective' },
    { id: 'dota-torm-dire', label: 'TORMENTOR (Dire 20m)', x: 560, y: 150, type: 'objective' },
    { id: 'dota-lotus-top', label: 'LOTUS HAVUZU (Kuzey)', x: 230, y: 180, type: 'neutral' },
    { id: 'dota-lotus-bot', label: 'LOTUS HAVUZU (Güney)', x: 610, y: 300, type: 'neutral' },
    { id: 'dota-mid', label: 'ORTA NEHİR (River Runes)', x: 420, y: 240, type: 'choke' },
  ],

  // ── PUBG: ERANGEL ──
  erangel: [
    { id: 'era-sosnovka', label: 'SOSNOVKA ASKERİ ÜS', x: 450, y: 400, type: 'site' },
    { id: 'era-bridge', label: 'ASKERİ KÖPRÜ', x: 440, y: 330, type: 'choke' },
    { id: 'era-pochinki', label: 'POCHINKI', x: 380, y: 245, type: 'site' },
    { id: 'era-school', label: 'OKUL & HAVUZ', x: 450, y: 235, type: 'site' },
    { id: 'era-rozhok', label: 'ROZHOK', x: 445, y: 195, type: 'choke' },
    { id: 'era-yasnaya', label: 'YASNAYA POLYANA', x: 550, y: 190, type: 'site' },
    { id: 'era-georgo', label: 'GEORGOPOL KONTEYNER', x: 280, y: 170, type: 'site' },
    { id: 'era-mylta', label: 'MYLTA POWER', x: 590, y: 310, type: 'objective' },
    { id: 'era-stalber', label: 'STALBER GÖZETLEME', x: 580, y: 110, type: 'objective' },
    { id: 'era-primorsk', label: 'PRIMORSK', x: 280, y: 380, type: 'spawn' },
  ],

  // ── PUBG: MIRAMAR ──
  miramar: [
    { id: 'mir-losleones', label: 'LOS LEONES', x: 520, y: 330, type: 'site' },
    { id: 'mir-pecado', label: 'PECADO ARENA', x: 390, y: 240, type: 'site' },
    { id: 'mir-hacienda', label: 'HACIENDA DEL PATRÓN', x: 450, y: 180, type: 'site' },
    { id: 'mir-sanmartin', label: 'SAN MARTIN', x: 410, y: 185, type: 'choke' },
    { id: 'mir-elpozo', label: 'EL POZO', x: 260, y: 200, type: 'site' },
    { id: 'mir-chumacera', label: 'CHUMACERA', x: 340, y: 310, type: 'choke' },
    { id: 'mir-montenuevo', label: 'MONTE NUEVO', x: 280, y: 270, type: 'choke' },
    { id: 'mir-puerto', label: 'PUERTO PARAISO', x: 570, y: 410, type: 'spawn' },
    { id: 'mir-crater', label: 'KRATER ALANI', x: 360, y: 120, type: 'objective' },
  ],

  // ── PUBG: SANHOK ──
  sanhok: [
    { id: 'san-bootcamp', label: 'BOOTCAMP', x: 420, y: 220, type: 'site' },
    { id: 'san-paradise', label: 'PARADISE RESORT', x: 490, y: 170, type: 'site' },
    { id: 'san-ruins', label: 'RUINS (HARABELER)', x: 340, y: 270, type: 'site' },
    { id: 'san-painan', label: 'PAI NAN KÖPRÜ', x: 390, y: 290, type: 'choke' },
    { id: 'san-campa', label: 'CAMP ALPHA', x: 290, y: 170, type: 'spawn' },
    { id: 'san-campb', label: 'CAMP BRAVO', x: 550, y: 210, type: 'spawn' },
    { id: 'san-campc', label: 'CAMP CHARLIE', x: 490, y: 380, type: 'spawn' },
    { id: 'san-quarry', label: 'QUARRY TAŞ OCAĞI', x: 470, y: 300, type: 'objective' },
    { id: 'san-hatinh', label: 'HA TINH', x: 340, y: 130, type: 'site' },
    { id: 'san-docks', label: 'DOCKS LİMAN', x: 560, y: 360, type: 'objective' },
  ],

  // ── CS2: MIRAGE ──
  mirage: [
    { id: 'mrg-t', label: 'T BAŞLANGICI (T Spawn)', x: 250, y: 410, type: 'spawn' },
    { id: 'mrg-ct', label: 'CT BAŞLANGICI (CT Spawn)', x: 520, y: 130, type: 'spawn' },
    { id: 'mrg-site-a', label: 'A BOMBSITE', x: 490, y: 240, type: 'site' },
    { id: 'mrg-site-b', label: 'B BOMBSITE', x: 310, y: 170, type: 'site' },
    { id: 'mrg-window', label: 'ORTA PENCERE (Window)', x: 390, y: 260, type: 'choke' },
    { id: 'mrg-conn', label: 'KONNEKTÖR', x: 440, y: 260, type: 'choke' },
    { id: 'mrg-palace', label: 'SARAY (Palace)', x: 540, y: 320, type: 'choke' },
    { id: 'mrg-aramp', label: 'A RAMPA (A Ramp)', x: 470, y: 340, type: 'choke' },
    { id: 'mrg-bapps', label: 'B APARTMANLAR', x: 280, y: 260, type: 'choke' },
    { id: 'mrg-jungle', label: 'ORMAN (Jungle)', x: 460, y: 210, type: 'choke' },
    { id: 'mrg-underpass', label: 'ALT TÜNEL (Underpass)', x: 380, y: 310, type: 'choke' },
    { id: 'mrg-catwalk', label: 'KISA B (Catwalk)', x: 350, y: 230, type: 'choke' },
    { id: 'mrg-stairs', label: 'MERDİVEN (Stairs)', x: 450, y: 240, type: 'choke' },
  ],

  // ── CS2: INFERNO ──
  inferno: [
    { id: 'inf-t', label: 'T BAŞLANGICI (T Spawn)', x: 240, y: 390, type: 'spawn' },
    { id: 'inf-ct', label: 'CT BAŞLANGICI (CT Spawn)', x: 540, y: 120, type: 'spawn' },
    { id: 'inf-site-a', label: 'A BOMBSITE', x: 490, y: 210, type: 'site' },
    { id: 'inf-site-b', label: 'B BOMBSITE', x: 370, y: 140, type: 'site' },
    { id: 'inf-banana', label: 'MUZ (Banana)', x: 340, y: 280, type: 'choke' },
    { id: 'inf-apps', label: 'APARTMANLAR (Apps)', x: 440, y: 230, type: 'choke' },
    { id: 'inf-pit', label: 'ÇUKUR (Pit)', x: 540, y: 220, type: 'choke' },
    { id: 'inf-boiler', label: 'KAZAN (Boiler / Alt Mid)', x: 430, y: 280, type: 'choke' },
    { id: 'inf-arch', label: 'KEMER (Arch)', x: 490, y: 160, type: 'choke' },
    { id: 'inf-library', label: 'KÜTÜPHANE (Library)', x: 530, y: 150, type: 'choke' },
    { id: 'inf-church', label: 'İNŞAAT / KİLİSE', x: 400, y: 160, type: 'choke' },
  ],

  // ── CS2: DUST II ──
  dust2: [
    { id: 'd2-t', label: 'T BAŞLANGICI (T Spawn)', x: 230, y: 410, type: 'spawn' },
    { id: 'd2-ct', label: 'CT BAŞLANGICI (CT Spawn)', x: 460, y: 160, type: 'spawn' },
    { id: 'd2-site-a', label: 'A BOMBSITE', x: 530, y: 190, type: 'site' },
    { id: 'd2-site-b', label: 'B BOMBSITE', x: 280, y: 160, type: 'site' },
    { id: 'd2-along', label: 'UZUN A (A Long)', x: 580, y: 320, type: 'choke' },
    { id: 'd2-pit', label: 'ÇUKUR (Pit)', x: 600, y: 400, type: 'choke' },
    { id: 'd2-short', label: 'KISA A (Catwalk / Short)', x: 470, y: 220, type: 'choke' },
    { id: 'd2-middoors', label: 'ORTA KAPILAR (Mid Doors)', x: 390, y: 240, type: 'choke' },
    { id: 'd2-topmid', label: 'XBOX / YUKARI ORTA', x: 370, y: 310, type: 'choke' },
    { id: 'd2-lowertun', label: 'ALT TÜNEL (Lower Tunnels)', x: 330, y: 260, type: 'choke' },
    { id: 'd2-uppertun', label: 'ÜST TÜNEL (Upper Tunnels)', x: 270, y: 240, type: 'choke' },
    { id: 'd2-bdoors', label: 'B KAPILARI (B Doors)', x: 330, y: 160, type: 'choke' },
    { id: 'd2-bwindow', label: 'B PENCERE (B Window)', x: 320, y: 120, type: 'choke' },
    { id: 'd2-goose', label: 'KAZ (Goose)', x: 540, y: 150, type: 'choke' },
  ],

  // ── CS2: ANCIENT ──
  ancient: [
    { id: 'anc-t', label: 'T BAŞLANGICI (T Spawn)', x: 420, y: 430, type: 'spawn' },
    { id: 'anc-ct', label: 'CT BAŞLANGICI (CT Spawn)', x: 420, y: 80, type: 'spawn' },
    { id: 'anc-site-a', label: 'A BOMBSITE', x: 530, y: 200, type: 'site' },
    { id: 'anc-site-b', label: 'B BOMBSITE', x: 310, y: 200, type: 'site' },
    { id: 'anc-mid', label: 'ORTA AVLU (Mid)', x: 420, y: 240, type: 'choke' },
    { id: 'anc-donut', label: 'ÇÖREK (Donut)', x: 470, y: 210, type: 'choke' },
    { id: 'anc-cave', label: 'MAĞARA (Cheetah / Cave)', x: 360, y: 210, type: 'choke' },
    { id: 'anc-amain', label: 'A ANA GİRİŞ (A Main)', x: 520, y: 310, type: 'choke' },
    { id: 'anc-bramp', label: 'B RAMPA (B Ramp)', x: 320, y: 310, type: 'choke' },
    { id: 'anc-temple', label: 'TAPINAK (Temple)', x: 560, y: 160, type: 'choke' },
    { id: 'anc-house', label: 'KIRMIZI EV (Red House)', x: 390, y: 320, type: 'choke' },
    { id: 'anc-bshort', label: 'B KISA (B Short)', x: 340, y: 150, type: 'choke' },
  ],

  // ── CS2: NUKE ──
  nuke: [
    { id: 'nk-t', label: 'T BAŞLANGICI (T Spawn)', x: 240, y: 330, type: 'spawn' },
    { id: 'nk-ct', label: 'CT BAŞLANGICI (CT Spawn)', x: 590, y: 220, type: 'spawn' },
    { id: 'nk-site-a', label: 'A BOMBSITE (Üst Reaktör)', x: 430, y: 205, type: 'site' },
    { id: 'nk-site-b', label: 'B BOMBSITE (Alt Reaktör)', x: 430, y: 255, type: 'site' },
    { id: 'nk-outside', label: 'DIŞARI (Outside)', x: 380, y: 380, type: 'choke' },
    { id: 'nk-secret', label: 'GİZLİ MERDİVEN (Secret)', x: 480, y: 370, type: 'choke' },
    { id: 'nk-garage', label: 'GARAJ (Garage)', x: 530, y: 370, type: 'choke' },
    { id: 'nk-hut', label: 'KULÜBE (Hut)', x: 380, y: 240, type: 'choke' },
    { id: 'nk-squeaky', label: 'GICIRTILI KAPI (Squeaky)', x: 380, y: 170, type: 'choke' },
    { id: 'nk-vent', label: 'HAVALANDIRMA (Vent)', x: 420, y: 175, type: 'choke' },
    { id: 'nk-ramp', label: 'RAMPA (Ramp)', x: 490, y: 140, type: 'choke' },
    { id: 'nk-heaven', label: 'BALKON (Heaven)', x: 480, y: 210, type: 'choke' },
    { id: 'nk-lobby', label: 'T LOBİ (Lobby)', x: 320, y: 230, type: 'choke' },
  ],
};

// ─────────────────────────────────────────────────────────
// Teleporter Connection Overlays (Bind & Dota 2 Twin Gates)
// ─────────────────────────────────────────────────────────

export function drawTeleporterLinksOverlay(ctx: CanvasRenderingContext2D, mapId: TacticalMapId) {
  if (mapId === 'bind') {
    // A Port (455, 195) -> A Port Exit (385, 210)
    ctx.save();
    ctx.setLineDash([5, 4]);
    ctx.strokeStyle = '#22D3EE';
    ctx.lineWidth = 2.2;
    ctx.beginPath();
    ctx.moveTo(455, 195);
    ctx.quadraticCurveTo(420, 185, 385, 210);
    ctx.stroke();

    // Portal Badge A
    ctx.fillStyle = 'rgba(6, 182, 212, 0.25)';
    ctx.beginPath();
    ctx.arc(455, 195, 14, 0, Math.PI * 2);
    ctx.arc(385, 210, 14, 0, Math.PI * 2);
    ctx.fill();

    // B Port (240, 205) -> B Port Exit (565, 300)
    ctx.strokeStyle = '#38BDF8';
    ctx.beginPath();
    ctx.moveTo(240, 205);
    ctx.bezierCurveTo(240, 360, 520, 370, 565, 300);
    ctx.stroke();

    ctx.fillStyle = 'rgba(56, 189, 248, 0.25)';
    ctx.beginPath();
    ctx.arc(240, 205, 14, 0, Math.PI * 2);
    ctx.arc(565, 300, 14, 0, Math.PI * 2);
    ctx.fill();
    ctx.restore();
  } else if (mapId === 'dota') {
    // Twin Gates: North (205, 65) <-> South (635, 415)
    ctx.save();
    ctx.setLineDash([6, 5]);
    ctx.strokeStyle = '#C084FC';
    ctx.lineWidth = 2.4;
    ctx.beginPath();
    ctx.moveTo(205, 65);
    ctx.bezierCurveTo(150, 240, 680, 240, 635, 415);
    ctx.stroke();

    ctx.fillStyle = 'rgba(192, 132, 252, 0.3)';
    ctx.beginPath();
    ctx.arc(205, 65, 16, 0, Math.PI * 2);
    ctx.arc(635, 415, 16, 0, Math.PI * 2);
    ctx.fill();
    ctx.restore();
  }
}

// ─────────────────────────────────────────────────────────
// Map Callouts Renderer (Clean Esports Typography & Badges)
// ─────────────────────────────────────────────────────────

function formatCalloutLabel(raw: string): string {
  if (!raw) return '';
  return raw.replace(/([A-ZÇĞİÖŞÜa-zçğıöşü0-9+:\/]+)/g, (word) => {
    const upper = word.toUpperCase();
    if (['CT', 'T', 'A', 'B', 'C4', 'MID', 'BO1', 'BO3', 'BO5', 'DPS', 'IGL', 'ARAM', 'CS2'].includes(upper)) {
      return upper;
    }
    if (word.length <= 2 && word === upper) return word;
    return word.charAt(0).toUpperCase() + word.slice(1).toLocaleLowerCase('tr-TR');
  });
}

export function drawMapCalloutsOverlay(ctx: CanvasRenderingContext2D, mapId: TacticalMapId) {
  const callouts = MAP_CALLOUT_PRESETS[mapId];
  if (!callouts || callouts.length === 0) return;

  ctx.save();
  ctx.font = '500 9.5px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Inter", sans-serif';

  for (const c of callouts) {
    const displayLabel = formatCalloutLabel(c.label);
    const textWidth = ctx.measureText(displayLabel).width;
    const padX = 6;
    const w = textWidth + padX * 2 + 8;
    const h = 18;
    const rx = c.x - w / 2;
    const ry = c.y - h / 2;

    // Background pill: soft dark glass
    ctx.fillStyle = 'rgba(13, 9, 12, 0.88)';
    ctx.beginPath();
    ctx.roundRect(rx, ry, w, h, 5);
    ctx.fill();

    let borderColor = 'rgba(160, 145, 148, 0.20)';
    let dotColor = '#9E8E91';
    let textColor = '#ECE5E7';

    if (c.type === 'site') {
      borderColor = 'rgba(215, 65, 78, 0.38)';
      dotColor = '#E05362';
      textColor = '#F8E8EA';
    } else if (c.type === 'portal') {
      borderColor = 'rgba(45, 175, 205, 0.35)';
      dotColor = '#38BDF8';
      textColor = '#E0F2FE';
    } else if (c.type === 'objective') {
      borderColor = 'rgba(165, 115, 220, 0.35)';
      dotColor = '#A78BFA';
      textColor = '#EDE9FE';
    } else if (c.type === 'neutral') {
      borderColor = 'rgba(52, 180, 130, 0.35)';
      dotColor = '#34D399';
      textColor = '#D1FAE5';
    } else if (c.type === 'spawn') {
      borderColor = 'rgba(130, 145, 165, 0.25)';
      dotColor = '#94A3B8';
      textColor = '#CBD5E1';
    } else if (c.type === 'choke') {
      borderColor = 'rgba(210, 60, 75, 0.35)';
      dotColor = '#E11D48';
      textColor = '#FDE8E8';
    }

    ctx.strokeStyle = borderColor;
    ctx.lineWidth = 1;
    ctx.stroke();

    // Type indicator dot
    ctx.fillStyle = dotColor;
    ctx.beginPath();
    ctx.arc(rx + 6.5, ry + h / 2, 2.5, 0, Math.PI * 2);
    ctx.fill();

    // Label
    ctx.fillStyle = textColor;
    ctx.textAlign = 'left';
    ctx.textBaseline = 'middle';
    ctx.fillText(displayLabel, rx + 13, ry + h / 2 + 0.5);
  }
  ctx.restore();
}

// ─────────────────────────────────────────────────────────
// Cached Callout & Teleport Blit Layer (Zero-lag 60 FPS)
// ─────────────────────────────────────────────────────────

const CALLOUTS_LAYER_CACHE: Partial<Record<TacticalMapId, HTMLCanvasElement>> = {};

export function getCachedCalloutsLayer(mapId: TacticalMapId): HTMLCanvasElement | null {
  if (typeof document === 'undefined') return null;
  if (CALLOUTS_LAYER_CACHE[mapId]) {
    return CALLOUTS_LAYER_CACHE[mapId]!;
  }
  const canvas = document.createElement('canvas');
  canvas.width = LOGICAL_W;
  canvas.height = LOGICAL_H;
  const ctx = canvas.getContext('2d');
  if (!ctx) return null;

  drawTeleporterLinksOverlay(ctx, mapId);
  drawMapCalloutsOverlay(ctx, mapId);

  CALLOUTS_LAYER_CACHE[mapId] = canvas;
  return canvas;
}

// ─────────────────────────────────────────────────────────
// Esports Preset Strategies (LoL, Valorant, CS2, Dota 2)
// ─────────────────────────────────────────────────────────

export interface TacticalPresetStrat {
  id: string;
  title: string;
  description: string;
  mapId: TacticalMapId;
  game: TacticalGameCategory;
  tags: string[];
  operations: Array<{
    tool: string;
    points: Array<{ x: number; y: number }>;
    color?: string;
    text?: string;
    seqNumber?: number;
    pinNumber?: number;
    team?: 'blue' | 'red';
  }>;
}

export const TACTICAL_PRESET_STRATS: TacticalPresetStrat[] = [
  // ── 1. LEAGUE OF LEGENDS: DIGNITAS FULL CLEAR JUNGLE ROUTE (1-6) ──
  {
    id: 'lol-dignitas-full-clear',
    title: 'Dignitas Pro Full Clear Orman Rotası (1-6)',
    description: '1: Mavi -> 2: Gromp -> 3: Kurtlar -> 4: Yırtıcılar -> 5: Kırmızı -> 6: Yampiri. Profesyonel espor tempo rotası.',
    mapId: 'rift',
    game: 'lol',
    tags: ['ORMAN', 'DİGNİTAS', 'META 2026'],
    operations: [
      { tool: 'seq-path', points: [{ x: 330, y: 320 }], seqNumber: 1, color: '#38BDF8' },
      { tool: 'seq-path', points: [{ x: 330, y: 320 }, { x: 290, y: 290 }], seqNumber: 2, color: '#38BDF8' },
      { tool: 'seq-path', points: [{ x: 290, y: 290 }, { x: 345, y: 275 }], seqNumber: 3, color: '#38BDF8' },
      { tool: 'seq-path', points: [{ x: 345, y: 275 }, { x: 410, y: 305 }], seqNumber: 4, color: '#38BDF8' },
      { tool: 'seq-path', points: [{ x: 410, y: 305 }, { x: 440, y: 335 }], seqNumber: 5, color: '#38BDF8' },
      { tool: 'seq-path', points: [{ x: 440, y: 335 }, { x: 490, y: 380 }], seqNumber: 6, color: '#38BDF8' },
      { tool: 'ward-yellow', points: [{ x: 510, y: 340 }] },
      { tool: 'arrow', points: [{ x: 490, y: 380 }, { x: 540, y: 400 }], color: '#22C55E' },
      { tool: 'text', points: [{ x: 330, y: 235 }], text: 'Dignitas Orman Rotası (3:15 Yampiri Hazır)' },
    ],
  },

  // ── 2. VALORANT BIND: A HAMAM & KISA PINCER EXECUTE ──
  {
    id: 'val-bind-a-pincer',
    title: 'Bind: A Hamam & A Kısa Çifte Kıskanç Baskın',
    description: 'U-Hall (Lamba) ve Heaven sisleri, hamam ve kısa üzerinden eşzamanlı çifte giriş ve default A plantı.',
    mapId: 'bind',
    game: 'valorant',
    tags: ['A EXECUTE', 'PRO STRAT', 'SMOKES'],
    operations: [
      { tool: 'site-a', points: [{ x: 510, y: 160 }] },
      { tool: 'smoke', points: [{ x: 470, y: 160 }] }, // U-Hall (Lamba) Smoke
      { tool: 'smoke', points: [{ x: 510, y: 115 }] }, // Heaven Smoke
      { tool: 'arrow', points: [{ x: 450, y: 250 }, { x: 500, y: 170 }], color: '#22C55E' }, // A Short Entry
      { tool: 'arrow', points: [{ x: 550, y: 210 }, { x: 520, y: 165 }], color: '#38BDF8' }, // Showers Entry
      { tool: 'flash', points: [{ x: 495, y: 175 }] },
      { tool: 'spike', points: [{ x: 510, y: 160 }] },
      { tool: 'text', points: [{ x: 430, y: 310 }], text: 'A Bölgesi Eşzamanlı Giriş & Lamba Kapatma' },
    ],
  },

  // ── 3. VALORANT BIND: IŞINLAYICI FAKE & B KISA SPLIT ──
  {
    id: 'val-bind-teleport-fake',
    title: 'Bind: A Port Işınlayıcı Fake & B Kısa Split',
    description: 'A Hamam ses gürültüsü sonrası A Porttan B Kısa çıkışına ışınlanma, Elbow dumanı ve B Site hızlı kurulumu.',
    mapId: 'bind',
    game: 'valorant',
    tags: ['PORTAL', 'FAKE', 'B SPLIT'],
    operations: [
      { tool: 'audio-ping', points: [{ x: 550, y: 230 }] },
      { tool: 'teleport', points: [{ x: 455, y: 195 }] }, // A Port Entry
      { tool: 'dashed-arrow', points: [{ x: 455, y: 195 }, { x: 385, y: 210 }], color: '#22D3EE' },
      { tool: 'smoke', points: [{ x: 280, y: 140 }] }, // B Elbow
      { tool: 'smoke', points: [{ x: 320, y: 100 }] }, // B Hall
      { tool: 'arrow', points: [{ x: 385, y: 210 }, { x: 310, y: 140 }], color: '#22C55E' },
      { tool: 'site-b', points: [{ x: 305, y: 140 }] },
      { tool: 'spike', points: [{ x: 305, y: 140 }] },
    ],
  },

  // ── 4. VALORANT BREEZE: A VIPER DUVARI & PIRAMIT FAST PLANT ──
  {
    id: 'val-breeze-a-viper',
    title: 'Breeze: A Site Viper Zehir Duvarı & Hızlı Piramit Plant',
    description: 'Piramitleri ikiye bölen Viper duvarı, A Mağara çıkışı ve A Site piramit arkası güvenli plant.',
    mapId: 'breeze',
    game: 'valorant',
    tags: ['A VIPER', 'BREEZE', 'RED BULL'],
    operations: [
      { tool: 'site-a', points: [{ x: 530, y: 230 }] },
      { tool: 'site-b', points: [{ x: 295, y: 160 }] },
      { tool: 'dashed-arrow', points: [{ x: 510, y: 190 }, { x: 550, y: 270 }], color: '#22C55E' }, // Viper Wall
      { tool: 'smoke', points: [{ x: 530, y: 310 }] }, // Poison Orb
      { tool: 'arrow', points: [{ x: 530, y: 340 }, { x: 530, y: 245 }], color: '#22C55E' },
      { tool: 'spike', points: [{ x: 530, y: 230 }] },
      { tool: 'text', points: [{ x: 470, y: 370 }], text: 'Red Bull Breeze A Piramit Plantı' },
    ],
  },

  // ── 5. CS2 MIRAGE: PRO A BOMBSITE EXECUTE (STAIRS, JUNGLE, CT) ──
  {
    id: 'cs2-mirage-a-exec',
    title: 'CS2 Mirage: Pro A Sis Girişi (Merdiven + Orman + CT)',
    description: 'Merdiven, Orman ve CT Spawn sisleri ile A Ramp ve Saraydan eşzamanlı Tetris temizliği ve A Bombsite plantı.',
    mapId: 'mirage',
    game: 'cs2',
    tags: ['A EXECUTE', 'MIRAGE', 'SMOKES'],
    operations: [
      { tool: 'smoke', points: [{ x: 505, y: 170 }] }, // CT Smoke
      { tool: 'smoke', points: [{ x: 460, y: 210 }] }, // Jungle Smoke
      { tool: 'smoke', points: [{ x: 445, y: 240 }] }, // Stairs Smoke
      { tool: 'flash', points: [{ x: 470, y: 280 }] },
      { tool: 'arrow', points: [{ x: 470, y: 340 }, { x: 480, y: 260 }], color: '#EF4444' }, // A Ramp to Tetris
      { tool: 'arrow', points: [{ x: 540, y: 310 }, { x: 495, y: 240 }], color: '#F59E0B' }, // Palace to Site
      { tool: 'spike', points: [{ x: 490, y: 240 }] }, // Bomb Default
      { tool: 'site-a', points: [{ x: 490, y: 240 }] },
    ],
  },

  // ── 6. CS2 MIRAGE: B APARTMAN BASKINI & KISA BÖLÜNME ──
  {
    id: 'cs2-mirage-b-split',
    title: 'CS2 Mirage: B Apartman Baskını & Market Sisi',
    description: 'Market pencere ve kapı sisleri, araba alevi ve apartman + kısa üzerinden B Bombsite kuşatması.',
    mapId: 'mirage',
    game: 'cs2',
    tags: ['B SPLIT', 'MIRAGE', 'APARTMAN'],
    operations: [
      { tool: 'smoke', points: [{ x: 330, y: 150 }] }, // Market Window
      { tool: 'smoke', points: [{ x: 310, y: 130 }] }, // Market Door
      { tool: 'molly', points: [{ x: 270, y: 200 }] }, // Van Molly
      { tool: 'flash', points: [{ x: 290, y: 230 }] },
      { tool: 'arrow', points: [{ x: 280, y: 260 }, { x: 310, y: 170 }], color: '#EF4444' },
      { tool: 'dashed-arrow', points: [{ x: 350, y: 210 }, { x: 315, y: 175 }], color: '#38BDF8' },
      { tool: 'spike', points: [{ x: 310, y: 170 }] },
      { tool: 'site-b', points: [{ x: 310, y: 170 }] },
    ],
  },

  // ── 7. CS2 INFERNO: BANANA KONTROLÜ & B SITE GİRİŞİ ──
  {
    id: 'cs2-inferno-banana',
    title: 'CS2 Inferno: Muz Kontrolü & Tabut Sisi Girişi',
    description: 'Muz araba alevi, tabut ve CT spawn sisleri ile B Bombsite hızlı giriş ve havuz arkası plant.',
    mapId: 'inferno',
    game: 'cs2',
    tags: ['BANANA', 'INFERNO', 'B SITE'],
    operations: [
      { tool: 'molly', points: [{ x: 340, y: 260 }] }, // Car Molly
      { tool: 'smoke', points: [{ x: 350, y: 130 }] }, // Coffins
      { tool: 'smoke', points: [{ x: 410, y: 130 }] }, // CT Spawn
      { tool: 'flash', points: [{ x: 335, y: 230 }] },
      { tool: 'arrow', points: [{ x: 340, y: 280 }, { x: 370, y: 140 }], color: '#EF4444' },
      { tool: 'spike', points: [{ x: 370, y: 140 }] },
      { tool: 'site-b', points: [{ x: 370, y: 140 }] },
    ],
  },

  // ── 8. DOTA 2: RADIANT SAFE LANE & İKİZ GEÇİT BASKINI ──
  {
    id: 'dota-twin-gate-gank',
    title: 'Dota 2: Radiant Güvenli Koridor & İkiz Geçit Baskını',
    description: 'Güney ikiz geçidini kullanarak Kuzey koridoruna ani ışınlanma, Watcher görüşü ve Tormentor hazırlığı.',
    mapId: 'dota',
    game: 'dota2',
    tags: ['7.33+', 'TWIN GATE', 'GANK', 'ROSHAN'],
    operations: [
      { tool: 'twin-gate', points: [{ x: 205, y: 65 }] },
      { tool: 'twin-gate', points: [{ x: 635, y: 415 }] },
      { tool: 'arrow', points: [{ x: 580, y: 420 }, { x: 635, y: 415 }], color: '#C084FC' },
      { tool: 'dashed-arrow', points: [{ x: 205, y: 65 }, { x: 260, y: 100 }], color: '#EF4444' },
      { tool: 'watcher', points: [{ x: 340, y: 180 }] },
      { tool: 'tormentor', points: [{ x: 280, y: 330 }] },
      { tool: 'gank', points: [{ x: 260, y: 100 }] },
      { tool: 'text', points: [{ x: 380, y: 70 }], text: 'İkiz Geçit İle Kuzey Gank Rotası' },
    ],
  },

  // ── 9. DOTA 2: 7.33+ TAKTİKSEL ÇİFTLİK VE GÜVENLİ BÖLGE HARİTASI ──
  {
    id: 'dota-safe-zones',
    title: 'Dota 2 7.33+: Güvenli Çiftlik Bölgeleri & Çift Roshan Tuzağı',
    description: 'IGN / Reddit taktik rehberine göre Radiant ve Dire güvenli orman sınırları ve Gündüz/Gece Roshan pusu hatları.',
    mapId: 'dota',
    game: 'dota2',
    tags: ['FARM ZONE', '7.33+', 'IGN GUIDE'],
    operations: [
      { tool: 'boss', points: [{ x: 220, y: 60 }] }, // Day Roshan
      { tool: 'boss', points: [{ x: 620, y: 420 }] }, // Night Roshan
      { tool: 'zone-box', points: [{ x: 240, y: 280 }, { x: 390, y: 410 }], color: '#22C55E' }, // Radiant Safe Jungle
      { tool: 'zone-box', points: [{ x: 440, y: 80 }, { x: 590, y: 210 }], color: '#EF4444' }, // Dire Safe Jungle
      { tool: 'rune', points: [{ x: 420, y: 240 }] },
      { tool: 'text', points: [{ x: 250, y: 350 }], text: 'Radiant Güvenli Çiftlik Bölgesi' },
      { tool: 'text', points: [{ x: 450, y: 140 }], text: 'Dire Güvenli Çiftlik Bölgesi' },
    ],
  },
];
