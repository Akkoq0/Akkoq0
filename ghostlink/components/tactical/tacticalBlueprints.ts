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
    imageUrl: 'https://raw.githubusercontent.com/CSGO-Analysis/csgo-maps-overviews/master/overviews/de_mirage_radar.png',
  },
  inferno: {
    title: 'Inferno',
    game: 'cs2',
    gameTitle: 'CS2 TAKTİK ARENASI',
    subtitle: 'Toskana, İtalya · Klasik Dar Geçitler & Muz',
    compassHeading: 'N 28°E',
    imageUrl: 'https://raw.githubusercontent.com/CSGO-Analysis/csgo-maps-overviews/master/overviews/de_inferno_radar.png',
  },
  dust2: {
    title: 'Dust II',
    game: 'cs2',
    gameTitle: 'CS2 TAKTİK ARENASI',
    subtitle: 'Kazablanka, Fas · İkonik Long A & B Tünel',
    compassHeading: 'N 05°E',
    imageUrl: 'https://raw.githubusercontent.com/CSGO-Analysis/csgo-maps-overviews/master/overviews/de_dust2_radar.png',
  },
  ancient: {
    title: 'Ancient',
    game: 'cs2',
    gameTitle: 'CS2 TAKTİK ARENASI',
    subtitle: 'Mezoamerika Harabeleri · Donut & Cheetah',
    compassHeading: 'N 31°W',
    imageUrl: 'https://raw.githubusercontent.com/CSGO-Analysis/csgo-maps-overviews/master/overviews/de_mirage_radar.png',
  },
  nuke: {
    title: 'Nuke',
    game: 'cs2',
    gameTitle: 'CS2 TAKTİK ARENASI (ÇİFT KATMAN)',
    subtitle: 'Nükleer Santral · Üst A & Alt B Reaktör Katı',
    compassHeading: 'N 08°E',
    imageUrl: 'https://raw.githubusercontent.com/CSGO-Analysis/csgo-maps-overviews/master/overviews/de_nuke_radar.png',
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

export function drawRealisticArenaBlueprint(
  ctx: CanvasRenderingContext2D,
  mapId: Exclude<TacticalMapId, 'custom'>,
  onImageLoadedCallback?: () => void,
) {
  ctx.clearRect(0, 0, LOGICAL_W, LOGICAL_H);
  const spec = MAP_BLUEPRINTS[mapId];
  if (!spec) return;

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

  // 3. High-Tech Tactical Radar Grid (60px step with crosshair intersections)
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
  ctx.strokeStyle = 'rgba(200, 35, 51, 0.28)';
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
}
