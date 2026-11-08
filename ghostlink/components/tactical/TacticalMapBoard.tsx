'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Dynamic Game-Filtered Tactical Map Board & Custom Map Uploader
// ─────────────────────────────────────────────────────────
// Features:
//   1. Dynamic Game Map Isolation: Only displays maps for the active game
//      (LoL: Sihirdar Vadisi, Sonsuz Uçurum; CS2: Mirage, Inferno, Dust2, Ancient;
//       Valorant: Ascent, Bind, Haven, Split; PUBG: Erangel, Miramar; Dota 2: Kadimler Vadisi).
//   2. 0ms Instant Map Switching: Clicking any map immediately redraws the board.
//      No stuck-on-Rift bug or accidental map reset loops.
//   3. Custom Map Upload Engine: [+ Harita Yükle] button allows uploading custom
//      .png / .jpg images, immediately rendering as tactical blueprint and syncing
//      across peers via E2EE DataChannel.
//   4. Dual-layer Canvas: Zero re-rasterization 60 FPS drawing.

import React, { memo, useCallback, useEffect, useRef, useState, useMemo } from 'react';
import { useVoiceSettingsStore } from '@/store/useVoiceSettingsStore';
import { useAppStore } from '@/lib/store';
import { getMevaCryptoEngine } from '@/src/lib/cryptoEngine';
import { getMevaWebRTCMesh } from '@/src/lib/webrtcMesh';
import { getMevaStorageEngine, STORE_PREFS } from '@/src/lib/storageEngine';
import { useRealtimeChat } from '@/hooks/useRealtimeChat';
import {
  detectGameFromChannel,
  getGameById,
  SUPPORTED_GAMES,
} from '@/src/lib/gameRegistry';
import {
  IconClose,
  IconMapBoard,
  IconSend,
  IconShield,
  IconUpload,
} from '@/components/ui/MevaIcons';

export type TacticalGameCategory = 'valorant' | 'cs2' | 'lol' | 'dota2' | 'pubg';

export type TacticalMapId =
  | 'ascent'
  | 'bind'
  | 'haven'
  | 'split'
  | 'mirage'
  | 'inferno'
  | 'dust2'
  | 'ancient'
  | 'rift'
  | 'aram'
  | 'dota'
  | 'erangel'
  | 'miramar'
  | 'custom';

export type StratTool = 'arrow' | 'smoke' | 'flash' | 'pen';

export interface StratPoint {
  x: number;
  y: number;
}

export interface StratOperation {
  id: string;
  mapId: TacticalMapId;
  tool: StratTool;
  color: string;
  author: string;
  points: StratPoint[];
  ts: number;
}

type StratWirePacket =
  | { action: 'add'; op: StratOperation }
  | { action: 'undo'; opId: string; mapId: TacticalMapId }
  | { action: 'clear'; mapId: TacticalMapId }
  | { action: 'switch-map'; mapId: TacticalMapId }
  | { action: 'upload-map'; mapDataUrl: string; mapName: string };

interface MapZone {
  label: string;
  x: number;
  y: number;
  w: number;
  h: number;
  isSite?: boolean;
  accent?: string;
}

const LOGICAL_W = 840;
const LOGICAL_H = 480;

export const GAME_MAP_POOLS: Record<TacticalGameCategory, TacticalMapId[]> = {
  valorant: ['ascent', 'bind', 'haven', 'split'],
  cs2: ['mirage', 'inferno', 'dust2', 'ancient'],
  lol: ['rift', 'aram'],
  dota2: ['dota'],
  pubg: ['erangel', 'miramar'],
};

const MAP_BLUEPRINTS: Record<
  Exclude<TacticalMapId, 'custom'>,
  {
    title: string;
    game: TacticalGameCategory;
    gameTitle: string;
    subtitle: string;
    compassHeading: string;
    zones: MapZone[];
  }
> = {
  // ── VALORANT ──
  ascent: {
    title: 'Ascent',
    game: 'valorant',
    gameTitle: 'VALORANT ARENA',
    subtitle: 'Venedik, İtalya · 45°26\'N 12°20\'E',
    compassHeading: 'N 18°E',
    zones: [
      { label: 'A SITE (BOMBSITE)', x: 585, y: 55, w: 175, h: 125, isSite: true, accent: '#C82333' },
      { label: 'A HEAVEN', x: 620, y: 18, w: 120, h: 36 },
      { label: 'A MAIN', x: 585, y: 200, w: 135, h: 95 },
      { label: 'TREE (AĞAÇ)', x: 470, y: 120, w: 95, h: 80 },
      { label: 'MID COURTYARD', x: 335, y: 170, w: 155, h: 135, accent: '#F08C96' },
      { label: 'CATWALK', x: 470, y: 215, w: 100, h: 55 },
      { label: 'MARKET', x: 220, y: 145, w: 100, h: 85 },
      { label: 'B SITE (BOMBSITE)', x: 75, y: 60, w: 165, h: 125, isSite: true, accent: '#C82333' },
      { label: 'B MAIN', x: 95, y: 205, w: 115, h: 105 },
      { label: 'DEFENDER BASE', x: 330, y: 32, w: 175, h: 62 },
      { label: 'ATTACKER BASE', x: 315, y: 385, w: 205, h: 64 },
    ],
  },
  bind: {
    title: 'Bind',
    game: 'valorant',
    gameTitle: 'VALORANT ARENA',
    subtitle: 'Rabat, Fas · 34°01\'N 06°50\'W',
    compassHeading: 'N 42°W',
    zones: [
      { label: 'A SITE (BOMBSITE)', x: 555, y: 75, w: 195, h: 135, isSite: true, accent: '#C82333' },
      { label: 'SHOWERS (BANYO)', x: 650, y: 230, w: 110, h: 95 },
      { label: 'A SHORT', x: 455, y: 220, w: 165, h: 80 },
      { label: 'LAMPS / U-HALL', x: 465, y: 90, w: 80, h: 105 },
      { label: 'HOOKAH (NARGİLE)', x: 245, y: 190, w: 115, h: 85 },
      { label: 'B SITE (BOMBSITE)', x: 80, y: 70, w: 175, h: 135, isSite: true, accent: '#C82333' },
      { label: 'B LONG', x: 70, y: 225, w: 135, h: 110 },
      { label: '⚡ TP PORTAL 1', x: 355, y: 130, w: 90, h: 52, accent: '#00F0FF' },
      { label: 'DEFENDER BASE', x: 315, y: 30, w: 185, h: 55 },
      { label: 'ATTACKER BASE', x: 295, y: 385, w: 235, h: 60 },
    ],
  },
  haven: {
    title: 'Haven',
    game: 'valorant',
    gameTitle: 'VALORANT ARENA (3 BOMBSITE)',
    subtitle: 'Thimphu, Butan · 3 Bombalı Taktik Matrisi',
    compassHeading: 'N 25°E',
    zones: [
      { label: 'A SITE', x: 620, y: 70, w: 155, h: 120, isSite: true, accent: '#C82333' },
      { label: 'A LONG / SEWERS', x: 650, y: 220, w: 125, h: 90 },
      { label: 'B SITE', x: 350, y: 120, w: 140, h: 105, isSite: true, accent: '#C82333' },
      { label: 'MID COURTYARD', x: 345, y: 245, w: 150, h: 80, accent: '#F08C96' },
      { label: 'GARAGE (GARAJ)', x: 235, y: 210, w: 90, h: 85 },
      { label: 'C SITE', x: 75, y: 70, w: 150, h: 120, isSite: true, accent: '#C82333' },
      { label: 'C LONG', x: 65, y: 220, w: 110, h: 105 },
      { label: 'DEFENDER BASE', x: 340, y: 30, w: 160, h: 60 },
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
      { label: 'A SITE (KULE)', x: 570, y: 65, w: 180, h: 130, isSite: true, accent: '#C82333' },
      { label: 'A RAFTERS / HEAVEN', x: 600, y: 25, w: 120, h: 35 },
      { label: 'A MAIN', x: 590, y: 215, w: 130, h: 95 },
      { label: 'MID VENTS & ROPES', x: 360, y: 155, w: 120, h: 100, accent: '#00F0FF' },
      { label: 'B HEAVEN / MAIL', x: 230, y: 125, w: 110, h: 85 },
      { label: 'B SITE', x: 80, y: 65, w: 170, h: 130, isSite: true, accent: '#C82333' },
      { label: 'B MAIN / GARAJ', x: 85, y: 215, w: 120, h: 100 },
      { label: 'DEFENDER BASE', x: 340, y: 30, w: 160, h: 60 },
      { label: 'ATTACKER BASE', x: 320, y: 385, w: 200, h: 60 },
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
      { label: 'PALACE (SARAY)', x: 645, y: 395, w: 125, h: 55 },
      { label: 'A RAMP', x: 555, y: 395, w: 82, h: 55 },
      { label: 'CONNECTOR', x: 425, y: 240, w: 105, h: 90 },
      { label: 'MID / PENCERE', x: 315, y: 185, w: 155, h: 95, accent: '#E5A93C' },
      { label: 'UNDERPASS', x: 265, y: 125, w: 95, h: 55 },
      { label: 'B SITE (BOMB B)', x: 85, y: 55, w: 175, h: 125, isSite: true, accent: '#C82333' },
      { label: 'APARTMANLAR', x: 270, y: 60, w: 175, h: 55 },
      { label: 'CT BASE', x: 365, y: 330, w: 155, h: 65 },
      { label: 'T BASE', x: 645, y: 90, w: 125, h: 95 },
    ],
  },
  inferno: {
    title: 'Inferno',
    game: 'cs2',
    gameTitle: 'CS2 TAKTİK ARENASI',
    subtitle: 'Toskana, İtalya · Klasik Dar Geçitler',
    compassHeading: 'N 28°E',
    zones: [
      { label: 'B SITE (ÇEŞME)', x: 145, y: 45, w: 185, h: 115, isSite: true, accent: '#C82333' },
      { label: 'MUZ (BANANA)', x: 185, y: 175, w: 95, h: 155, accent: '#E5A93C' },
      { label: 'CT İNŞAAT', x: 350, y: 50, w: 155, h: 75 },
      { label: 'ORTA (MID)', x: 335, y: 250, w: 155, h: 85 },
      { label: 'KÜTÜPHANE / KEMER', x: 505, y: 120, w: 135, h: 95 },
      { label: 'A SITE (BOMB A)', x: 560, y: 240, w: 185, h: 125, isSite: true, accent: '#C82333' },
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
      { label: 'LONG A KORİDORU', x: 640, y: 245, w: 120, h: 140 },
      { label: 'A SHORT / CATWALK', x: 470, y: 150, w: 120, h: 75 },
      { label: 'ORTA KAPILAR (MID)', x: 360, y: 220, w: 120, h: 100, accent: '#E5A93C' },
      { label: 'B SITE (BOMB B)', x: 90, y: 90, w: 170, h: 120, isSite: true, accent: '#C82333' },
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
      { label: 'DONUT BÖLGESİ', x: 460, y: 160, w: 90, h: 85, accent: '#E5A93C' },
      { label: 'ORTA (MID)', x: 350, y: 200, w: 140, h: 90 },
      { label: 'MAĞARA / CHEETAH', x: 235, y: 180, w: 95, h: 90 },
      { label: 'B SITE (RAMPA)', x: 85, y: 110, w: 175, h: 130, isSite: true, accent: '#C82333' },
      { label: 'RED ROOM', x: 250, y: 100, w: 85, h: 70 },
      { label: 'CT BASE', x: 350, y: 45, w: 160, h: 65 },
      { label: 'T BASE', x: 330, y: 380, w: 200, h: 65 },
    ],
  },

  // ── LEAGUE OF LEGENDS ──
  rift: {
    title: 'Sihirdar Vadisi',
    game: 'lol',
    gameTitle: 'MOBA STRATEJİ MATRİSİ',
    subtitle: 'Runeterra · 3 Koridor, Baron & Kadim Ejder',
    compassHeading: 'N 45°E',
    zones: [
      { label: 'BARON NASHOR ÇUKURU', x: 250, y: 125, w: 135, h: 95, isSite: true, accent: '#A855F7' },
      { label: 'KADİM EJDER ÇUKURU', x: 460, y: 245, w: 135, h: 95, isSite: true, accent: '#EF4444' },
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
    title: 'Kadimler Vadisi',
    game: 'dota2',
    gameTitle: 'DOTA 2 STRATEJİ MATRİSİ',
    subtitle: 'Kadimler Savaşı · Nehir & Roshan',
    compassHeading: 'N 00°',
    zones: [
      { label: 'ROSHAN ÇUKURU (KUZEY)', x: 160, y: 105, w: 130, h: 75, isSite: true, accent: '#DC2626' },
      { label: 'ROSHAN ÇUKURU (GÜNEY)', x: 550, y: 295, w: 130, h: 75, isSite: true, accent: '#DC2626' },
      { label: 'RADIANT SAFE LANE', x: 520, y: 345, w: 190, h: 60, accent: '#10B981' },
      { label: 'DIRE SAFE LANE', x: 120, y: 65, w: 190, h: 60, accent: '#991B1B' },
      { label: 'NEHİR / ORTA RUNE', x: 330, y: 200, w: 180, h: 75, accent: '#06B6D4' },
      { label: 'TORMENTOR BÖLGESİ', x: 640, y: 215, w: 100, h: 65 },
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
      { label: 'POCHINKI', x: 340, y: 205, w: 160, h: 95, isSite: true, accent: '#C82333' },
      { label: 'SOSNOVKA ASKERİ ÜS', x: 330, y: 365, w: 180, h: 85, isSite: true, accent: '#C82333' },
      { label: 'OKUL & APARTMANLAR', x: 410, y: 145, w: 130, h: 80, accent: '#E5A93C' },
      { label: 'ROZHOK SU ŞEHRİ', x: 330, y: 125, w: 120, h: 70 },
      { label: 'YASNAYA POLYANA', x: 530, y: 105, w: 160, h: 90 },
      { label: 'GEORGOPOOL LİMAN', x: 130, y: 85, w: 160, h: 90 },
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
};

const INK_SWATCHES = [
  { hex: '#C82333', label: 'Saldırı' },
  { hex: '#F08C96', label: 'Destek' },
  { hex: '#00F0FF', label: 'Taktik' },
  { hex: '#F4EFF0', label: 'Komuta' },
] as const;

function resolveGameCategory(
  gameId?: string,
  channelName?: string,
  tags?: string[],
): TacticalGameCategory {
  if (gameId) {
    const id = gameId.toLowerCase();
    if (id === 'valorant') return 'valorant';
    if (id === 'cs2' || id === 'csgo' || id === 'standoff2' || id === 'r6') return 'cs2';
    if (id === 'lol' || id === 'wildrift' || id === 'mlbb') return 'lol';
    if (id === 'dota2' || id === 'dota') return 'dota2';
    if (id === 'pubg' || id === 'pubgm' || id === 'apex' || id === 'warzone' || id === 'fortnite') return 'pubg';
  }
  if (channelName) {
    const n = channelName.toLowerCase();
    if (n.includes('val') || n.includes('ascent') || n.includes('bind') || n.includes('haven')) return 'valorant';
    if (n.includes('cs') || n.includes('mirage') || n.includes('faceit') || n.includes('dust') || n.includes('inferno')) return 'cs2';
    if (n.includes('lol') || n.includes('rift') || n.includes('dereceli') || n.includes('aram')) return 'lol';
    if (n.includes('dota')) return 'dota2';
    if (n.includes('pubg') || n.includes('erangel') || n.includes('miramar') || n.includes('apex')) return 'pubg';
  }
  if (tags && tags.length > 0) {
    const joined = tags.join(' ').toLowerCase();
    if (joined.includes('val')) return 'valorant';
    if (joined.includes('cs')) return 'cs2';
    if (joined.includes('lol')) return 'lol';
    if (joined.includes('dota')) return 'dota2';
    if (joined.includes('pubg')) return 'pubg';
  }
  return 'cs2';
}

function drawRealisticArenaBlueprint(
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
  bgGrad.addColorStop(0, '#140A0E');
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
  ctx.strokeStyle = 'rgba(200, 35, 51, 0.35)';
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

  // 3. Concentric Range Radar Rings centered on map
  ctx.save();
  ctx.setLineDash([4, 6]);
  ctx.strokeStyle = 'rgba(200, 35, 51, 0.13)';
  ctx.lineWidth = 1.25;
  [110, 230, 360].forEach((r) => {
    ctx.beginPath();
    ctx.arc(LOGICAL_W / 2, LOGICAL_H / 2, r, 0, Math.PI * 2);
    ctx.stroke();
  });
  ctx.restore();

  // 4. Coordinates Labels (A-M, 1-8)
  ctx.fillStyle = 'rgba(184, 170, 172, 0.35)';
  ctx.font = '700 9px monospace';
  const cols = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M'];
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
  ctx.fillText(spec.gameTitle, 24, 30);
  ctx.fillStyle = '#FAF2EE';
  ctx.font = '800 15px sans-serif';
  ctx.fillText(spec.title.toUpperCase(), 24, 48);
  ctx.fillStyle = '#9E8E91';
  ctx.font = '600 9.5px monospace';
  ctx.fillText(spec.subtitle, 24, 62);

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

  // 6. Connecting Tactical Flow Lines (Corridors & Rotations)
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

  // 7. Architectural Zones, Bombsites & Terrain Features
  for (const z of spec.zones) {
    ctx.save();
    ctx.beginPath();
    ctx.roundRect(z.x, z.y, z.w, z.h, 8);

    if (z.isSite) {
      const siteGrad = ctx.createLinearGradient(z.x, z.y, z.x, z.y + z.h);
      siteGrad.addColorStop(0, 'rgba(143, 22, 34, 0.45)');
      siteGrad.addColorStop(1, 'rgba(28, 11, 16, 0.85)');
      ctx.fillStyle = siteGrad;
      ctx.fill();
      ctx.lineWidth = 2;
      ctx.strokeStyle = '#C82333';
      ctx.stroke();

      ctx.beginPath();
      ctx.arc(z.x + z.w / 2, z.y + z.h / 2 + 8, 24, 0, Math.PI * 2);
      ctx.setLineDash([4, 4]);
      ctx.strokeStyle = 'rgba(255, 70, 85, 0.55)';
      ctx.lineWidth = 1.5;
      ctx.stroke();
      ctx.setLineDash([]);

      ctx.beginPath();
      ctx.arc(z.x + z.w / 2, z.y + z.h / 2 + 8, 5, 0, Math.PI * 2);
      ctx.fillStyle = '#FF334B';
      ctx.fill();
    } else {
      ctx.fillStyle = z.accent
        ? 'rgba(20, 10, 14, 0.92)'
        : 'rgba(16, 8, 12, 0.88)';
      ctx.fill();
      ctx.lineWidth = 1.25;
      ctx.strokeStyle = z.accent || 'rgba(143, 22, 34, 0.4)';
      ctx.stroke();
    }

    ctx.fillStyle = z.isSite ? '#FAF2EE' : '#D8CBCE';
    ctx.font = z.isSite ? '900 11.5px sans-serif' : '700 10px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText(z.label, z.x + z.w / 2, z.y + 19);

    ctx.restore();
  }
}

function drawCustomUploadedMap(
  ctx: CanvasRenderingContext2D,
  img: HTMLImageElement | null,
  mapName: string,
) {
  ctx.clearRect(0, 0, LOGICAL_W, LOGICAL_H);

  if (img && img.complete && img.naturalWidth > 0) {
    ctx.drawImage(img, 0, 0, LOGICAL_W, LOGICAL_H);

    const vignette = ctx.createLinearGradient(0, 0, 0, LOGICAL_H);
    vignette.addColorStop(0, 'rgba(4, 2, 3, 0.45)');
    vignette.addColorStop(0.5, 'rgba(4, 2, 3, 0.15)');
    vignette.addColorStop(1, 'rgba(4, 2, 3, 0.65)');
    ctx.fillStyle = vignette;
    ctx.fillRect(0, 0, LOGICAL_W, LOGICAL_H);
  } else {
    ctx.fillStyle = '#0B0608';
    ctx.fillRect(0, 0, LOGICAL_W, LOGICAL_H);
    ctx.fillStyle = '#9E8E91';
    ctx.font = '700 13px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('Özel Taktiksel Harita Hazırlanıyor...', LOGICAL_W / 2, LOGICAL_H / 2);
  }

  ctx.strokeStyle = 'rgba(200, 35, 51, 0.16)';
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

  ctx.save();
  ctx.fillStyle = '#C82333';
  ctx.font = '900 11px sans-serif';
  ctx.fillText('ÖZEL TAKTİK HARİTASI', 24, 28);
  ctx.fillStyle = '#FAF2EE';
  ctx.font = '800 15px sans-serif';
  ctx.fillText(mapName.toUpperCase(), 24, 46);
  ctx.fillStyle = '#00F0FF';
  ctx.font = '700 9.5px monospace';
  ctx.fillText('E2EE DATACHANNEL SENKRONİZE · 840x480 CANVAS', 24, 60);
  ctx.restore();
}

function renderSingleOp(ctx: CanvasRenderingContext2D, op: StratOperation) {
  if (op.points.length === 0) return;
  ctx.save();
  const start = op.points[0];
  const end = op.points[op.points.length - 1];

  if (op.tool === 'smoke') {
    const rad = 30;
    const grad = ctx.createRadialGradient(end.x, end.y, 4, end.x, end.y, rad);
    grad.addColorStop(0, 'rgba(244, 239, 240, 0.44)');
    grad.addColorStop(0.65, 'rgba(184, 170, 172, 0.24)');
    grad.addColorStop(1, 'rgba(122, 18, 29, 0.06)');
    ctx.fillStyle = grad;
    ctx.beginPath();
    ctx.arc(end.x, end.y, rad, 0, Math.PI * 2);
    ctx.fill();

    ctx.setLineDash([4, 3]);
    ctx.strokeStyle = op.color;
    ctx.lineWidth = 1.6;
    ctx.stroke();
    ctx.setLineDash([]);

    ctx.fillStyle = '#F4EFF0';
    ctx.font = '800 9px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('SMK', end.x, end.y + 3);
  } else if (op.tool === 'flash') {
    if (op.points.length > 1) {
      ctx.setLineDash([3, 3]);
      ctx.strokeStyle = op.color;
      ctx.lineWidth = 1.5;
      ctx.beginPath();
      ctx.moveTo(start.x, start.y);
      ctx.lineTo(end.x, end.y);
      ctx.stroke();
      ctx.setLineDash([]);
    }
    ctx.strokeStyle = '#F4EFF0';
    ctx.fillStyle = op.color;
    ctx.lineWidth = 1.8;
    for (let i = 0; i < 8; i++) {
      const ang = (Math.PI / 4) * i;
      const r1 = 5;
      const r2 = i % 2 === 0 ? 15 : 10;
      ctx.beginPath();
      ctx.moveTo(end.x + Math.cos(ang) * r1, end.y + Math.sin(ang) * r1);
      ctx.lineTo(end.x + Math.cos(ang) * r2, end.y + Math.sin(ang) * r2);
      ctx.stroke();
    }
    ctx.beginPath();
    ctx.arc(end.x, end.y, 4.5, 0, Math.PI * 2);
    ctx.fill();
  } else if (op.tool === 'arrow') {
    const dx = end.x - start.x;
    const dy = end.y - start.y;
    const len = Math.hypot(dx, dy);
    ctx.strokeStyle = op.color;
    ctx.fillStyle = op.color;
    ctx.lineWidth = 2.6;
    ctx.lineCap = 'round';

    ctx.beginPath();
    ctx.moveTo(start.x, start.y);
    ctx.lineTo(end.x, end.y);
    ctx.stroke();

    if (len > 6) {
      const angle = Math.atan2(dy, dx);
      const head = 11;
      ctx.beginPath();
      ctx.moveTo(end.x, end.y);
      ctx.lineTo(
        end.x - head * Math.cos(angle - Math.PI / 6),
        end.y - head * Math.sin(angle - Math.PI / 6),
      );
      ctx.lineTo(
        end.x - head * Math.cos(angle + Math.PI / 6),
        end.y - head * Math.sin(angle + Math.PI / 6),
      );
      ctx.closePath();
      ctx.fill();
    }
  } else if (op.tool === 'pen') {
    ctx.strokeStyle = op.color;
    ctx.lineWidth = 2.4;
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';
    ctx.beginPath();
    ctx.moveTo(start.x, start.y);
    for (let i = 1; i < op.points.length; i++) {
      ctx.lineTo(op.points[i].x, op.points[i].y);
    }
    ctx.stroke();
  }

  ctx.restore();
}

let stratOpSeq = 0;

export const TacticalMapBoard = memo(function TacticalMapBoard() {
  const open = useVoiceSettingsStore((s) => s.showStratBoard);
  const setOpen = useVoiceSettingsStore((s) => s.setShowStratBoard);
  const activeChannelId = useAppStore((s) => s.activeChannelId);
  const activeVoiceChannelId = useAppStore((s) => s.activeVoiceChannelId);
  const channels = useAppStore((s) => s.channels);
  const { sendMessage } = useRealtimeChat(activeChannelId);

  // 1. Identify active game category
  const activeVoiceChannel = channels.find((c) => c.id === activeVoiceChannelId);
  const activeTextChannel = channels.find((c) => c.id === activeChannelId);

  const currentGameCategory: TacticalGameCategory = useMemo(() => {
    if (activeVoiceChannel) {
      return resolveGameCategory(
        activeVoiceChannel.game_id,
        activeVoiceChannel.name,
        activeVoiceChannel.tags,
      );
    }
    if (activeTextChannel) {
      return resolveGameCategory(
        activeTextChannel.game_id,
        activeTextChannel.name,
        activeTextChannel.tags,
      );
    }
    return 'cs2';
  }, [activeVoiceChannel, activeTextChannel]);

  // Maps filtered strictly for the active game
  const availableMaps = useMemo(() => {
    return GAME_MAP_POOLS[currentGameCategory] || GAME_MAP_POOLS.cs2;
  }, [currentGameCategory]);

  const [mapId, setMapId] = useState<TacticalMapId>(() => availableMaps[0] || 'mirage');
  const [tool, setTool] = useState<StratTool>('arrow');
  const [inkColor, setInkColor] = useState<string>('#C82333');
  const [ops, setOps] = useState<StratOperation[]>([]);
  const [syncedPackets, setSyncedPackets] = useState(0);

  // Custom Map Image State & Persistence
  const [customMapUrl, setCustomMapUrl] = useState<string | null>(null);
  const [customMapName, setCustomMapName] = useState<string>('Özel Harita');
  const customImgRef = useRef<HTMLImageElement | null>(null);
  const fileInputRef = useRef<HTMLInputElement | null>(null);

  const bgCanvasRef = useRef<HTMLCanvasElement | null>(null);
  const fgCanvasRef = useRef<HTMLCanvasElement | null>(null);
  const draftOpRef = useRef<StratOperation | null>(null);
  const opsRef = useRef<StratOperation[]>([]);
  const rafIdRef = useRef<number | null>(null);

  opsRef.current = ops;

  // Hydrate custom map from IndexedDB on initial mount
  useEffect(() => {
    try {
      const storage = getMevaStorageEngine();
      void storage
        .getRecord<{ url: string; name: string }>(
          STORE_PREFS,
          'custom_tactical_map',
        )
        .then((saved) => {
          if (saved?.url) {
            setCustomMapUrl(saved.url);
            if (saved.name) setCustomMapName(saved.name);
          }
        });
    } catch {}
  }, []);

  // Preload custom image object whenever customMapUrl changes
  useEffect(() => {
    if (!customMapUrl) {
      customImgRef.current = null;
      return;
    }
    const img = new Image();
    img.crossOrigin = 'anonymous';
    img.onload = () => {
      customImgRef.current = img;
      if (mapId === 'custom') {
        const bg = bgCanvasRef.current;
        if (bg) {
          const ctx = bg.getContext('2d');
          if (ctx) drawCustomUploadedMap(ctx, img, customMapName);
        }
      }
    };
    img.src = customMapUrl;
  }, [customMapUrl, customMapName, mapId]);

  // Auto-switch initial map ONLY when active channel changes — NEVER resets when clicking map buttons!
  const lastChannelRef = useRef<string | null>(null);
  useEffect(() => {
    const currentChannel = activeVoiceChannelId || activeChannelId;
    if (!currentChannel) return;

    if (lastChannelRef.current !== currentChannel) {
      lastChannelRef.current = currentChannel;
      if (mapId !== 'custom') {
        const pool = GAME_MAP_POOLS[currentGameCategory] || GAME_MAP_POOLS.cs2;
        if (!pool.includes(mapId)) {
          setMapId(pool[0]);
        }
      }
    }
  }, [activeVoiceChannelId, activeChannelId, currentGameCategory, mapId]);

  const scheduleOverlayPaint = useCallback(() => {
    if (rafIdRef.current !== null) return;
    rafIdRef.current = requestAnimationFrame(() => {
      rafIdRef.current = null;
      const fg = fgCanvasRef.current;
      if (!fg) return;
      const ctx = fg.getContext('2d');
      if (!ctx) return;
      ctx.clearRect(0, 0, LOGICAL_W, LOGICAL_H);
      for (const op of opsRef.current) {
        if (op.mapId === mapId) {
          renderSingleOp(ctx, op);
        }
      }
      if (draftOpRef.current && draftOpRef.current.mapId === mapId) {
        renderSingleOp(ctx, draftOpRef.current);
      }
    });
  }, [mapId]);

  // Redraw blueprint immediately whenever mapId or custom map changes
  useEffect(() => {
    if (!open) return;
    const bg = bgCanvasRef.current;
    if (bg) {
      const ctx = bg.getContext('2d');
      if (ctx) {
        if (mapId === 'custom') {
          drawCustomUploadedMap(ctx, customImgRef.current, customMapName);
        } else {
          drawRealisticArenaBlueprint(ctx, mapId as Exclude<TacticalMapId, 'custom'>);
        }
      }
    }
    scheduleOverlayPaint();
  }, [open, mapId, customMapName, scheduleOverlayPaint]);

  useEffect(() => {
    if (open) scheduleOverlayPaint();
  }, [open, ops, scheduleOverlayPaint]);

  useEffect(() => {
    return () => {
      if (rafIdRef.current !== null) cancelAnimationFrame(rafIdRef.current);
    };
  }, []);

  const broadcastStratPacket = useCallback(async (pkt: StratWirePacket) => {
    try {
      await getMevaCryptoEngine().sendEncryptedMeshPacket(
        'strat-op',
        JSON.stringify(pkt),
      );
    } catch {}
  }, []);

  // Listen to real-time E2EE P2P strat packets across the mesh
  useEffect(() => {
    const cryptoEngine = getMevaCryptoEngine();
    void cryptoEngine.initialize();
    const mesh = getMevaWebRTCMesh();

    return mesh.onDataPacket((envelope) => {
      if (envelope.kind !== 'strat-op') return;
      void cryptoEngine
        .decryptPayload(
          envelope.payload,
          envelope.room,
          'strat-op',
          envelope.from,
        )
        .then((res) => {
          if (!res) return;
          try {
            const pkt = JSON.parse(res.plaintext) as StratWirePacket;
            setSyncedPackets((c) => c + 1);
            if (pkt.action === 'add') {
              setOps((prev) =>
                prev.some((x) => x.id === pkt.op.id)
                  ? prev
                  : [...prev.slice(-120), pkt.op],
              );
            } else if (pkt.action === 'undo') {
              setOps((prev) => prev.filter((x) => x.id !== pkt.opId));
            } else if (pkt.action === 'clear') {
              setOps((prev) => prev.filter((x) => x.mapId !== pkt.mapId));
            } else if (pkt.action === 'switch-map') {
              setMapId(pkt.mapId);
            } else if (pkt.action === 'upload-map') {
              setCustomMapUrl(pkt.mapDataUrl);
              setCustomMapName(pkt.mapName || 'Özel Harita');
              setMapId('custom');
            }
          } catch {}
        });
    });
  }, []);

  if (!open) return null;

  const toLogicalCoords = (
    e: React.PointerEvent<HTMLCanvasElement>,
  ): StratPoint => {
    const rect = e.currentTarget.getBoundingClientRect();
    const x = ((e.clientX - rect.left) / Math.max(1, rect.width)) * LOGICAL_W;
    const y = ((e.clientY - rect.top) / Math.max(1, rect.height)) * LOGICAL_H;
    return {
      x: Math.round(Math.max(0, Math.min(LOGICAL_W, x)) * 10) / 10,
      y: Math.round(Math.max(0, Math.min(LOGICAL_H, y)) * 10) / 10,
    };
  };

  const handlePointerDown = (e: React.PointerEvent<HTMLCanvasElement>) => {
    e.currentTarget.setPointerCapture(e.pointerId);
    const pt = toLogicalCoords(e);
    const opId = `st-${Date.now().toString(36)}-${(++stratOpSeq).toString(36)}`;

    if (tool === 'smoke') {
      const smokeOp: StratOperation = {
        id: opId,
        mapId,
        tool: 'smoke',
        color: inkColor,
        author: 'IGL',
        points: [pt],
        ts: Date.now(),
      };
      setOps((prev) => [...prev.slice(-120), smokeOp]);
      void broadcastStratPacket({ action: 'add', op: smokeOp });
      return;
    }

    draftOpRef.current = {
      id: opId,
      mapId,
      tool,
      color: inkColor,
      author: 'IGL',
      points: [pt, pt],
      ts: Date.now(),
    };
    scheduleOverlayPaint();
  };

  const handlePointerMove = (e: React.PointerEvent<HTMLCanvasElement>) => {
    const draft = draftOpRef.current;
    if (!draft) return;
    const pt = toLogicalCoords(e);
    if (draft.tool === 'pen') {
      const last = draft.points[draft.points.length - 1];
      if (Math.hypot(pt.x - last.x, pt.y - last.y) >= 4.5) {
        draft.points.push(pt);
      }
    } else {
      draft.points[1] = pt;
    }
    scheduleOverlayPaint();
  };

  const finalizeDraft = () => {
    const draft = draftOpRef.current;
    if (!draft) return;
    draftOpRef.current = null;
    setOps((prev) => [...prev.slice(-120), draft]);
    void broadcastStratPacket({ action: 'add', op: draft });
  };

  const handleUndo = () => {
    const mapOps = ops.filter((o) => o.mapId === mapId);
    const last = mapOps[mapOps.length - 1];
    if (!last) return;
    setOps((prev) => prev.filter((o) => o.id !== last.id));
    void broadcastStratPacket({ action: 'undo', opId: last.id, mapId });
  };

  const handleClear = () => {
    setOps((prev) => prev.filter((o) => o.mapId !== mapId));
    void broadcastStratPacket({ action: 'clear', mapId });
  };

  // Instant Map Switcher — 0ms delay
  const handleSwitchMap = (next: TacticalMapId, e?: React.SyntheticEvent) => {
    if (e) {
      e.preventDefault();
      e.stopPropagation();
    }
    setMapId(next);
    void broadcastStratPacket({ action: 'switch-map', mapId: next });
  };

  // Custom Map Uploader Handler
  const handleCustomFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const cleanTitle = file.name
      .replace(/\.[^/.]+$/, '')
      .replace(/[_-]/g, ' ')
      .slice(0, 18);

    const reader = new FileReader();
    reader.onload = () => {
      const rawDataUrl = reader.result as string;
      const img = new Image();
      img.onload = () => {
        const oc = document.createElement('canvas');
        oc.width = LOGICAL_W;
        oc.height = LOGICAL_H;
        const octx = oc.getContext('2d');
        if (octx) {
          octx.drawImage(img, 0, 0, LOGICAL_W, LOGICAL_H);
          const optimized = oc.toDataURL('image/jpeg', 0.84);
          setCustomMapUrl(optimized);
          setCustomMapName(cleanTitle);
          setMapId('custom');

          try {
            const storage = getMevaStorageEngine();
            storage.scheduleWrite(STORE_PREFS, 'custom_tactical_map', {
              url: optimized,
              name: cleanTitle,
            });
            void storage.flushPendingWrites();
          } catch {}

          void broadcastStratPacket({
            action: 'upload-map',
            mapDataUrl: optimized,
            mapName: cleanTitle,
          });
        }
      };
      img.src = rawDataUrl;
    };
    reader.readAsDataURL(file);
    e.target.value = '';
  };

  const handleShareBriefToChat = async () => {
    const mapOps = ops.filter((o) => o.mapId === mapId);
    const smokes = mapOps.filter((o) => o.tool === 'smoke').length;
    const flashes = mapOps.filter((o) => o.tool === 'flash').length;
    const arrows = mapOps.filter((o) => o.tool === 'arrow').length;
    const title =
      mapId === 'custom'
        ? customMapName.toUpperCase()
        : (MAP_BLUEPRINTS[mapId as Exclude<TacticalMapId, 'custom'>]?.title ?? 'TAKTİK').toUpperCase();
    await sendMessage(
      `[TAKTİK TAHTASI · ${title}] IGL çizimi P2P senkronize edildi (${smokes} Smoke, ${flashes} Flash, ${arrows} Rotasyon Oku). Taktik tahtasını (B) açarak inceleyin.`,
    );
  };

  const currentMapCount = ops.filter((o) => o.mapId === mapId).length;

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center exec-backdrop p-2.5 sm:p-5 font-sans tabular-nums select-none"
      onClick={(e) => {
        e.preventDefault();
        setOpen(false);
      }}
    >
      <div
        onClick={(e) => {
          e.preventDefault();
          e.stopPropagation();
        }}
        className="w-full max-w-5xl max-h-[94dvh] rounded-2xl exec-modal flex flex-col overflow-hidden shadow-[0_24px_80px_rgba(0,0,0,0.92)] border border-[#8F1622]/55"
      >
        {/* Hidden File Input for Custom Tactical Map Upload */}
        <input
          ref={fileInputRef}
          type="file"
          accept="image/png,image/jpeg,image/webp"
          className="hidden"
          onChange={handleCustomFileSelect}
        />

        {/* ── Top Bar: Title + Game Badge + Filtered Map Buttons + [+ Harita Yükle] ── */}
        <div className="px-4 py-3 border-b border-[#2A1319] flex flex-wrap items-center justify-between gap-2.5 flex-shrink-0 bg-gradient-to-r from-[#1C0B10] via-[#0D090B] to-[#070607]">
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-xl crimson-cta flex items-center justify-center text-[#F4EFF0]">
              <IconMapBoard size={16} />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h2 className="text-sm font-extrabold text-[#F4EFF0]">
                  Taktiksel Harita & Çizim Tahtası
                </h2>
                <span className="rounded-md px-2 py-0.5 bg-[#250C13] border border-[#C82333]/50 text-[10px] font-black uppercase text-[#FF5A6B] tracking-wider">
                  {currentGameCategory.toUpperCase()} HARİTALARI
                </span>
                <span className="rounded-md px-2 py-0.5 bg-[#180B10] border border-[#7A121D]/55 text-[10px] font-bold text-[#F08C96] flex items-center gap-1 shadow-sm">
                  <IconShield size={11} className="text-[#FF4655]" />
                  <span>E2EE Canlı ({syncedPackets})</span>
                </span>
              </div>
              <p className="text-[11px] text-[#A8989B] mt-0.5">
                Oyun kanalınıza göre filtrelenmiş resmi harita havuzu.
              </p>
            </div>
          </div>

          {/* Dynamic Game-Filtered Map Selector & [+ Harita Yükle] */}
          <div className="flex items-center gap-1.5 flex-wrap">
            {availableMaps.map((mKey) => {
              const spec = MAP_BLUEPRINTS[mKey as Exclude<TacticalMapId, 'custom'>];
              if (!spec) return null;
              const isActive = mapId === mKey;
              return (
                <button
                  key={mKey}
                  type="button"
                  onClick={(e) => handleSwitchMap(mKey, e)}
                  className={`rounded-lg h-7 px-2.5 text-[11px] font-extrabold border transition-all ${
                    isActive
                      ? 'crimson-cta text-[#F4EFF0] shadow-[0_0_12px_rgba(200,35,51,0.4)]'
                      : 'bg-[#120A0D] hover:bg-[#1C0D12] text-[#B8AAAC] hover:text-[#FAF2EE] border-[#2A1319]'
                  }`}
                >
                  {spec.title}
                </button>
              );
            })}

            {/* Custom Map Pill (if custom map exists) */}
            {customMapUrl && (
              <button
                type="button"
                onClick={(e) => handleSwitchMap('custom', e)}
                className={`rounded-lg h-7 px-2.5 text-[11px] font-extrabold border transition-all ${
                  mapId === 'custom'
                    ? 'bg-cyan-950/90 text-cyan-300 border-cyan-400 shadow-[0_0_12px_rgba(6,182,212,0.4)]'
                    : 'bg-[#0E0709] hover:bg-cyan-950/40 text-cyan-400/80 border-[#2A1319]'
                }`}
              >
                🗺️ {customMapName}
              </button>
            )}

            {/* [+ Harita Yükle] Button */}
            <button
              type="button"
              onClick={(e) => {
                e.preventDefault();
                e.stopPropagation();
                fileInputRef.current?.click();
              }}
              title="Bilgisayarınızdan özel taktik haritası (.png, .jpg) yükleyin"
              className="rounded-lg h-7 px-2.5 bg-[#1F0C13] hover:bg-[#3B141E] border border-[#8F1622]/60 hover:border-[#C82333] text-[11px] font-extrabold text-[#F08C96] hover:text-[#FAF2EE] flex items-center gap-1.5 transition-all shadow-sm active:scale-95"
            >
              <IconUpload size={12} className="text-[#FF4655]" />
              <span>[+ Harita Yükle]</span>
            </button>

            <button
              type="button"
              onClick={(e) => {
                e.preventDefault();
                setOpen(false);
              }}
              aria-label="Kapat"
              className="rounded-xl w-7 h-7 ml-1 flex items-center justify-center bg-[#140A0D] hover:bg-[#220D13] border border-[#2C141A] text-[#9E8E91] hover:text-[#F4EFF0] transition-colors"
            >
              <IconClose size={14} />
            </button>
          </div>
        </div>

        {/* ── Tactical Tool Strip ── */}
        <div className="px-4 py-2 bg-[#0B0709]/95 border-b border-[#241116] flex flex-wrap items-center justify-between gap-2 flex-shrink-0">
          <div className="flex items-center gap-1.5 flex-wrap">
            {(
              [
                { id: 'arrow', label: 'Rotasyon Oku' },
                { id: 'smoke', label: 'Duman (Smoke)' },
                { id: 'flash', label: 'Flaş (Pop-Flash)' },
                { id: 'pen', label: 'Serbest Çizim' },
              ] as const
            ).map((t) => (
              <button
                key={t.id}
                type="button"
                onClick={(e) => {
                  e.preventDefault();
                  setTool(t.id);
                }}
                className={`rounded-lg h-7 px-3 text-[11px] font-bold border transition-all ${
                  tool === t.id
                    ? 'bg-[#8F1622]/50 text-[#F4EFF0] border-[#C82333]/80 shadow-[0_0_10px_rgba(200,35,51,0.35)]'
                    : 'bg-[#120A0D] hover:bg-[#1B0C11] text-[#B8AAAC] border-[#2A1319]'
                }`}
              >
                {t.label}
              </button>
            ))}

            <span className="w-px h-5 bg-[#2A1319] mx-1" />

            {INK_SWATCHES.map((sw) => (
              <button
                key={sw.hex}
                type="button"
                onClick={(e) => {
                  e.preventDefault();
                  setInkColor(sw.hex);
                }}
                title={sw.label}
                className={`rounded-lg h-7 px-2 flex items-center gap-1.5 border text-[10.5px] font-bold ${
                  inkColor === sw.hex
                    ? 'bg-[#1C0C11] border-[#C82333]/80 text-[#F4EFF0]'
                    : 'bg-[#11090B] border-[#261217] text-[#8E7F83]'
                }`}
              >
                <span
                  style={{ background: sw.hex }}
                  className="w-2.5 h-2.5 rounded-full"
                />
                <span>{sw.label}</span>
              </button>
            ))}
          </div>

          <div className="flex items-center gap-1.5">
            <button
              type="button"
              onClick={(e) => {
                e.preventDefault();
                handleUndo();
              }}
              disabled={currentMapCount === 0}
              className="rounded-lg h-7 px-2.5 bg-[#120A0D] hover:bg-[#1B0C11] disabled:opacity-40 border border-[#2A1319] text-[11px] font-bold text-[#B8AAAC]"
            >
              Geri Al
            </button>
            <button
              type="button"
              onClick={(e) => {
                e.preventDefault();
                handleClear();
              }}
              disabled={currentMapCount === 0}
              className="rounded-lg h-7 px-2.5 bg-[#190B10] hover:bg-[#7A121D]/40 disabled:opacity-40 border border-[#7A121D]/55 text-[11px] font-bold text-[#F08C96]"
            >
              Temizle ({currentMapCount})
            </button>
            <button
              type="button"
              onClick={(e) => {
                e.preventDefault();
                void handleShareBriefToChat();
              }}
              className="crimson-cta rounded-lg h-7 px-3 text-[11px] font-bold text-[#F4EFF0] flex items-center gap-1.5 shadow-sm active:scale-95"
            >
              <IconSend size={11} />
              <span>Kanala Brifing At</span>
            </button>
          </div>
        </div>

        {/* ── Dual-Layer Tactical Blueprint Canvas ── */}
        <div className="flex-1 min-h-0 p-3 sm:p-4 bg-[#050304] flex items-center justify-center overflow-hidden">
          <div className="relative w-full max-w-[840px] aspect-[840/480] rounded-xl overflow-hidden border border-[#2E151C] shadow-[0_16px_48px_rgba(0,0,0,0.92)] touch-none">
            <canvas
              ref={bgCanvasRef}
              width={LOGICAL_W}
              height={LOGICAL_H}
              className="absolute inset-0 w-full h-full pointer-events-none"
            />
            <canvas
              ref={fgCanvasRef}
              width={LOGICAL_W}
              height={LOGICAL_H}
              onPointerDown={handlePointerDown}
              onPointerMove={handlePointerMove}
              onPointerUp={finalizeDraft}
              onPointerCancel={finalizeDraft}
              className="absolute inset-0 w-full h-full cursor-crosshair"
            />
          </div>
        </div>
      </div>
    </div>
  );
});

// Re-export as TacticalStratDrawer for seamless backwards compatibility
export const TacticalStratDrawer = TacticalMapBoard;
