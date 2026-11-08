'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Pro Stratbook Studio (High-Performance 60 FPS)
// ─────────────────────────────────────────────────────────
// Topographical 2D Minimap Radar Textures, Dynamic Game Filtering,
// Strict Game Mechanics Isolation, Modern Collapsible Tactical Sidebar,
// 60 FPS Direct-DOM Pan/Zoom & Multi-Touch Gestures, Undo/Redo & JSON/PNG Export.
//
// CRITICAL RULES:
// 1. ZERO LAG / 60 FPS STABILITY:
//    - Panning & token dragging use direct DOM mutation & RAF; NO React state thrashing on mousemove.
//    - Bounded memory: history stack capped at 50 ops, undo/redo limited.
// 2. STRICT GAME MECHANICS ISOLATION:
//    - FPS: Smoke, Flash, Molly, Spike/C4, Defuse Kit, Ses/Ayak Sinyali (Audio Ping), Tehlike.
//    - MOBA: Gözetleme Totemi (Ward), Kontrol Totemi (Pink), Bal Suyu, Rün, Roshan/Baron, Gank.
//    - Universal: 1-5 Takım Jetonları, Rota Sıralama Pini, Serbest Kalem, Oklar, Alanlar, Not.
// 3. MODERN TACTICAL SIDEBAR & ZOOM/PAN:
//    - Dedicated collapsible sidebar for phases, tools, colors, team pins, and history.
//    - Top bar freed up for game & map selection.
//    - Direct Zoom (+ / -), %100, %150, %200, 1:1 Reset, Wheel Zoom, Space+Drag & Touch gestures.

import React, {
  useState,
  useRef,
  useEffect,
  useCallback,
  useMemo,
} from 'react';
import { useVoiceSettingsStore } from '@/store/useVoiceSettingsStore';
import { useAppStore } from '@/lib/store';
import { useRealtimeChat } from '@/hooks/useRealtimeChat';
import { getMevaCryptoEngine } from '@/src/lib/cryptoEngine';
import { getMevaWebRTCMesh } from '@/src/lib/webrtcMesh';
import { getMevaStorageEngine, STORE_PREFS } from '@/src/lib/storageEngine';
import {
  LOGICAL_W,
  LOGICAL_H,
  TacticalGameCategory,
  TacticalMapId,
  MAP_BLUEPRINTS,
  GAME_MAP_POOLS,
  drawRealisticArenaBlueprint,
  drawMapCalloutsOverlay,
  drawTeleporterLinksOverlay,
  TacticalPresetStrat,
} from './tacticalBlueprints';
import {
  IconClose,
  IconPlus,
} from '@/components/ui/MevaIcons';
import { MapVetoModal } from './MapVetoModal';
import { TacticalPresetsModal } from './TacticalPresetsModal';
import { NetworkStressModal } from '../telemetry/NetworkStressModal';
import { NotificationDrawer } from '../notifications/NotificationDrawer';
import { EconomyTimerWidget } from './EconomyTimerWidget';
import { MevaErrorBoundary } from '../ui/MevaErrorBoundary';

export { GAME_MAP_POOLS };
export type { TacticalMapId, TacticalGameCategory };

export type StratTool =
  // Universal Vector Tools
  | 'arrow'
  | 'dashed-arrow'
  | 'pen'
  | 'zone-circle'
  | 'zone-box'
  | 'text'
  | 'eraser'
  | 'pan'
  | 'pin-blue'
  | 'pin-red'
  | 'seq-path'
  // Tactical FPS (CS2 / Valorant / Tactical Shooter)
  | 'smoke'
  | 'flash'
  | 'molly'
  | 'spike'
  | 'defuse'
  | 'sensor'
  | 'audio-ping'
  | 'danger'
  | 'site-a'
  | 'site-b'
  | 'teleport'
  // MOBA (LoL / Dota 2)
  | 'ward-yellow'
  | 'ward-pink'
  | 'honeyfruit'
  | 'rune'
  | 'gank'
  | 'boss'
  | 'tormentor'
  | 'watcher'
  | 'twin-gate'
  // Battle Royale (PUBG)
  | 'airdrop'
  | 'flight'
  | 'vehicle'
  | 'bluezone';

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
  phase?: 1 | 2 | 3;
  stratId?: string;
  lineWidth?: number;
  text?: string;
  pinNumber?: number; // 1 to 5 for team pins
  seqNumber?: number; // 1, 2, 3... for path sequence
  team?: 'blue' | 'red';
  radius?: number;
  boxW?: number;
  boxH?: number;
}

export interface CustomGameDef {
  id: string;
  name: string;
  icon: string;
  archetype: 'fps' | 'moba' | 'br';
  maps: { id: string; title: string; subtitle: string }[];
}

type StratWirePacket =
  | { action: 'add'; op: StratOperation }
  | { action: 'update'; op: StratOperation }
  | { action: 'undo'; opId: string; mapId: TacticalMapId }
  | { action: 'clear'; mapId: TacticalMapId; phase?: number }
  | { action: 'switch-map'; mapId: TacticalMapId }
  | { action: 'upload-map'; mapDataUrl: string; mapName: string }
  | { action: 'switch-phase'; phase: 1 | 2 | 3 };

const DEFAULT_GAMES: { id: TacticalGameCategory; name: string; icon: string; archetype: 'fps' | 'moba' | 'br' }[] = [
  { id: 'lol', name: 'League of Legends', icon: '⚔️', archetype: 'moba' },
  { id: 'cs2', name: 'Counter-Strike 2', icon: '🎯', archetype: 'fps' },
  { id: 'valorant', name: 'Valorant', icon: '⚡', archetype: 'fps' },
  { id: 'dota2', name: 'Dota 2', icon: '🛡️', archetype: 'moba' },
  { id: 'pubg', name: 'PUBG', icon: '🪂', archetype: 'br' },
];

const INK_SWATCHES = [
  { hex: '#C82333', label: 'Meva Kırmızı' },
  { hex: '#3B82F6', label: 'Taktik Mavi' },
  { hex: '#10B981', label: 'Görüş Yeşil' },
  { hex: '#EAB308', label: 'Uyarı Sarı' },
  { hex: '#A855F7', label: 'Büyü / Void' },
  { hex: '#FFFFFF', label: 'Beyaz' },
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
    if (id === 'pubg' || id === 'apex' || id === 'warzone' || id === 'fortnite') return 'pubg';
  }
  const hay = `${channelName ?? ''} ${(tags ?? []).join(' ')}`.toLowerCase();
  if (hay.includes('valo') || hay.includes('bind') || hay.includes('ascent') || hay.includes('breeze')) return 'valorant';
  if (hay.includes('cs2') || hay.includes('csgo') || hay.includes('mirage') || hay.includes('dust')) return 'cs2';
  if (hay.includes('lol') || hay.includes('league') || hay.includes('vadi') || hay.includes('aram')) return 'lol';
  if (hay.includes('dota')) return 'dota2';
  if (hay.includes('pubg') || hay.includes('erangel') || hay.includes('miramar')) return 'pubg';
  return 'cs2';
}

// ─────────────────────────────────────────────────────────
// High-Performance Vector & Stamp Renderer
// ─────────────────────────────────────────────────────────

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
    vignette.addColorStop(0.5, 'rgba(4, 2, 3, 0.12)');
    vignette.addColorStop(1, 'rgba(4, 2, 3, 0.65)');
    ctx.fillStyle = vignette;
    ctx.fillRect(0, 0, LOGICAL_W, LOGICAL_H);
  } else {
    ctx.fillStyle = '#0B0608';
    ctx.fillRect(0, 0, LOGICAL_W, LOGICAL_H);
    ctx.fillStyle = '#9E8E91';
    ctx.font = '700 13px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('Özel Taktik Haritası Yükleniyor...', LOGICAL_W / 2, LOGICAL_H / 2);
  }

  // Tactical coordinate grid overlay
  ctx.strokeStyle = 'rgba(200, 35, 51, 0.15)';
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
  ctx.fillText('E2EE P2P SENKRONİZE · 840x480 CANVAS', 24, 60);
  ctx.restore();
}

function renderSingleOp(ctx: CanvasRenderingContext2D, op: StratOperation) {
  if (!op.points || op.points.length === 0) return;
  const start = op.points[0];
  const end = op.points[op.points.length - 1];
  const lw = op.lineWidth || 3;

  // 1. Tactical FPS Equipment (Smoke, Flash, Molly, Spike, Defuse, Audio Ping, Danger)
  if (op.tool === 'smoke') {
    ctx.save();
    ctx.beginPath();
    ctx.arc(end.x, end.y, 28, 0, Math.PI * 2);
    ctx.fillStyle = 'rgba(160, 160, 175, 0.35)';
    ctx.fill();
    ctx.strokeStyle = 'rgba(230, 230, 245, 0.85)';
    ctx.lineWidth = 1.8;
    ctx.setLineDash([4, 4]);
    ctx.stroke();
    ctx.setLineDash([]);

    ctx.beginPath();
    ctx.arc(end.x, end.y, 6, 0, Math.PI * 2);
    ctx.fillStyle = '#FAF2EE';
    ctx.fill();
    ctx.fillStyle = '#0B0608';
    ctx.font = '800 8.5px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('S', end.x, end.y + 3);
    ctx.restore();
  } else if (op.tool === 'flash') {
    ctx.beginPath();
    ctx.arc(end.x, end.y, 18, 0, Math.PI * 2);
    ctx.fillStyle = 'rgba(250, 204, 21, 0.3)';
    ctx.fill();
    ctx.strokeStyle = '#FACC15';
    ctx.lineWidth = 1.8;
    ctx.stroke();

    ctx.fillStyle = '#FACC15';
    ctx.font = '900 13px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('⚡', end.x, end.y + 4.5);
  } else if (op.tool === 'molly') {
    ctx.beginPath();
    ctx.arc(end.x, end.y, 24, 0, Math.PI * 2);
    ctx.fillStyle = 'rgba(239, 68, 68, 0.3)';
    ctx.fill();
    ctx.strokeStyle = '#EF4444';
    ctx.lineWidth = 1.8;
    ctx.stroke();

    ctx.fillStyle = '#EF4444';
    ctx.font = '900 12px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('🔥', end.x, end.y + 4);
  } else if (op.tool === 'spike') {
    ctx.beginPath();
    ctx.rect(end.x - 11, end.y - 11, 22, 22);
    ctx.fillStyle = '#DC2626';
    ctx.fill();
    ctx.strokeStyle = '#FAF2EE';
    ctx.lineWidth = 2;
    ctx.stroke();

    ctx.fillStyle = '#FAF2EE';
    ctx.font = '900 10px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('C4', end.x, end.y + 3.5);
  } else if (op.tool === 'defuse') {
    ctx.beginPath();
    ctx.arc(end.x, end.y, 11, 0, Math.PI * 2);
    ctx.fillStyle = '#0284C7';
    ctx.fill();
    ctx.strokeStyle = '#FFFFFF';
    ctx.lineWidth = 1.8;
    ctx.stroke();

    ctx.fillStyle = '#FFFFFF';
    ctx.font = '900 9px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('KIT', end.x, end.y + 3.5);
  } else if (op.tool === 'sensor') {
    ctx.beginPath();
    ctx.arc(end.x, end.y, 20, 0, Math.PI * 2);
    ctx.setLineDash([3, 3]);
    ctx.strokeStyle = '#00F0FF';
    ctx.lineWidth = 1.5;
    ctx.stroke();
    ctx.setLineDash([]);

    ctx.beginPath();
    ctx.arc(end.x, end.y, 5, 0, Math.PI * 2);
    ctx.fillStyle = '#00F0FF';
    ctx.fill();
  } else if (op.tool === 'audio-ping') {
    // Concentric Sonar Audio Ping Rings
    ctx.beginPath();
    ctx.arc(end.x, end.y, 25, 0, Math.PI * 2);
    ctx.strokeStyle = 'rgba(56, 189, 248, 0.4)';
    ctx.setLineDash([4, 4]);
    ctx.lineWidth = 1.5;
    ctx.stroke();
    ctx.setLineDash([]);

    ctx.beginPath();
    ctx.arc(end.x, end.y, 14, 0, Math.PI * 2);
    ctx.strokeStyle = '#38BDF8';
    ctx.lineWidth = 1.8;
    ctx.stroke();

    ctx.beginPath();
    ctx.arc(end.x, end.y, 9, 0, Math.PI * 2);
    ctx.fillStyle = '#0369A1';
    ctx.fill();
    ctx.strokeStyle = '#FFFFFF';
    ctx.lineWidth = 1.5;
    ctx.stroke();

    ctx.fillStyle = '#FFFFFF';
    ctx.font = '900 10px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('🔊', end.x, end.y + 3.5);
  } else if (op.tool === 'danger') {
    ctx.beginPath();
    ctx.arc(end.x, end.y, 14, 0, Math.PI * 2);
    ctx.fillStyle = 'rgba(220, 38, 38, 0.85)';
    ctx.fill();
    ctx.strokeStyle = '#FFFFFF';
    ctx.lineWidth = 1.8;
    ctx.stroke();

    ctx.fillStyle = '#FFFFFF';
    ctx.font = '900 13px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('!', end.x, end.y + 4.5);
  } else if (op.tool === 'site-a') {
    ctx.beginPath();
    ctx.arc(end.x, end.y + 2, 14, 0, Math.PI * 2);
    ctx.fillStyle = 'rgba(0, 0, 0, 0.5)';
    ctx.fill();
    ctx.beginPath();
    ctx.arc(end.x, end.y, 14, 0, Math.PI * 2);
    ctx.fillStyle = '#EF4444';
    ctx.fill();
    ctx.strokeStyle = '#FFFFFF';
    ctx.lineWidth = 2.2;
    ctx.stroke();
    ctx.fillStyle = '#FFFFFF';
    ctx.font = '900 13px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('A', end.x, end.y + 4.5);
  } else if (op.tool === 'site-b') {
    ctx.beginPath();
    ctx.arc(end.x, end.y + 2, 14, 0, Math.PI * 2);
    ctx.fillStyle = 'rgba(0, 0, 0, 0.5)';
    ctx.fill();
    ctx.beginPath();
    ctx.arc(end.x, end.y, 14, 0, Math.PI * 2);
    ctx.fillStyle = '#DC2626';
    ctx.fill();
    ctx.strokeStyle = '#FFFFFF';
    ctx.lineWidth = 2.2;
    ctx.stroke();
    ctx.fillStyle = '#FFFFFF';
    ctx.font = '900 13px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('B', end.x, end.y + 4.5);
  } else if (op.tool === 'teleport') {
    ctx.beginPath();
    ctx.rect(end.x - 13, end.y - 13, 26, 26);
    ctx.fillStyle = 'rgba(6, 182, 212, 0.85)';
    ctx.fill();
    ctx.strokeStyle = '#22D3EE';
    ctx.lineWidth = 2;
    ctx.stroke();
    ctx.fillStyle = '#083344';
    ctx.font = '900 12px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('🌀', end.x, end.y + 4);
  }

  // 2. MOBA Equipment (LoL & Dota 2: Stealth Ward, Control Pink Ward, Honeyfruit, Rune, Gank, Boss, Tormentor, Watcher, Twin Gate)
  else if (op.tool === 'ward-yellow') {
    ctx.beginPath();
    ctx.arc(end.x, end.y, 35, -Math.PI / 4, Math.PI / 4);
    ctx.lineTo(end.x, end.y);
    ctx.closePath();
    ctx.fillStyle = 'rgba(234, 179, 8, 0.22)';
    ctx.fill();
    ctx.strokeStyle = '#EAB308';
    ctx.lineWidth = 1.2;
    ctx.stroke();

    ctx.beginPath();
    ctx.arc(end.x, end.y, 9, 0, Math.PI * 2);
    ctx.fillStyle = '#422006';
    ctx.fill();
    ctx.strokeStyle = '#EAB308';
    ctx.lineWidth = 2;
    ctx.stroke();

    ctx.fillStyle = '#EAB308';
    ctx.font = '900 9px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('👁', end.x, end.y + 3);
  } else if (op.tool === 'ward-pink') {
    ctx.beginPath();
    ctx.arc(end.x, end.y, 40, 0, Math.PI * 2);
    ctx.setLineDash([4, 4]);
    ctx.strokeStyle = '#EC4899';
    ctx.lineWidth = 1.5;
    ctx.stroke();
    ctx.setLineDash([]);

    ctx.beginPath();
    ctx.arc(end.x, end.y, 10, 0, Math.PI * 2);
    ctx.fillStyle = '#831843';
    ctx.fill();
    ctx.strokeStyle = '#F472B6';
    ctx.lineWidth = 2;
    ctx.stroke();

    ctx.fillStyle = '#FFFFFF';
    ctx.font = '900 9px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('PW', end.x, end.y + 3);
  } else if (op.tool === 'honeyfruit') {
    ctx.beginPath();
    ctx.arc(end.x, end.y, 11, 0, Math.PI * 2);
    ctx.fillStyle = '#10B981';
    ctx.fill();
    ctx.strokeStyle = '#ECFDF5';
    ctx.lineWidth = 1.8;
    ctx.stroke();

    ctx.fillStyle = '#FFFFFF';
    ctx.font = '900 10px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('🌿', end.x, end.y + 3.5);
  } else if (op.tool === 'rune') {
    ctx.beginPath();
    ctx.arc(end.x, end.y, 12, 0, Math.PI * 2);
    ctx.fillStyle = '#06B6D4';
    ctx.fill();
    ctx.strokeStyle = '#FFFFFF';
    ctx.lineWidth = 2;
    ctx.stroke();

    ctx.fillStyle = '#FFFFFF';
    ctx.font = '900 9px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('RÜN', end.x, end.y + 3.5);
  } else if (op.tool === 'gank') {
    ctx.beginPath();
    ctx.arc(end.x, end.y, 14, 0, Math.PI * 2);
    ctx.fillStyle = '#DC2626';
    ctx.fill();
    ctx.strokeStyle = '#FFFFFF';
    ctx.lineWidth = 2;
    ctx.stroke();

    ctx.fillStyle = '#FFFFFF';
    ctx.font = '900 9.5px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('GANK', end.x, end.y + 3.5);
  } else if (op.tool === 'boss') {
    ctx.beginPath();
    ctx.arc(end.x, end.y, 15, 0, Math.PI * 2);
    ctx.fillStyle = '#7E22CE';
    ctx.fill();
    ctx.strokeStyle = '#E9D5FF';
    ctx.lineWidth = 2;
    ctx.stroke();

    ctx.fillStyle = '#FFFFFF';
    ctx.font = '900 11px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('BOSS', end.x, end.y + 4);
  } else if (op.tool === 'tormentor') {
    ctx.beginPath();
    ctx.rect(end.x - 12, end.y - 12, 24, 24);
    ctx.fillStyle = '#7E22CE';
    ctx.fill();
    ctx.strokeStyle = '#E9D5FF';
    ctx.lineWidth = 2;
    ctx.stroke();
    ctx.fillStyle = '#FFFFFF';
    ctx.font = '900 8.5px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('TRM', end.x, end.y + 3);
  } else if (op.tool === 'watcher') {
    ctx.beginPath();
    ctx.arc(end.x, end.y, 12, 0, Math.PI * 2);
    ctx.fillStyle = '#0D9488';
    ctx.fill();
    ctx.strokeStyle = '#5EEAD4';
    ctx.lineWidth = 1.8;
    ctx.stroke();
    ctx.fillStyle = '#FFFFFF';
    ctx.font = '900 9px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('👁', end.x, end.y + 3);
  } else if (op.tool === 'twin-gate') {
    ctx.beginPath();
    ctx.arc(end.x, end.y, 13, 0, Math.PI * 2);
    ctx.fillStyle = '#6366F1';
    ctx.fill();
    ctx.strokeStyle = '#C7D2FE';
    ctx.lineWidth = 2;
    ctx.stroke();
    ctx.fillStyle = '#FFFFFF';
    ctx.font = '900 8.5px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('GATE', end.x, end.y + 3);
  }

  // 3. Battle Royale Equipment (PUBG: Airdrop, Flight, Vehicle, Bluezone)
  else if (op.tool === 'airdrop') {
    ctx.beginPath();
    ctx.rect(end.x - 12, end.y - 12, 24, 24);
    ctx.fillStyle = '#DC2626';
    ctx.fill();
    ctx.strokeStyle = '#1D4ED8';
    ctx.lineWidth = 2.5;
    ctx.stroke();
    ctx.fillStyle = '#FFFFFF';
    ctx.font = '900 9.5px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('DROP', end.x, end.y + 3.5);
  } else if (op.tool === 'flight') {
    ctx.beginPath();
    ctx.moveTo(start.x, start.y);
    ctx.lineTo(end.x, end.y);
    ctx.setLineDash([6, 4]);
    ctx.strokeStyle = '#F59E0B';
    ctx.lineWidth = 3;
    ctx.stroke();
    ctx.setLineDash([]);
    ctx.fillStyle = '#F59E0B';
    ctx.font = '900 14px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('✈', end.x, end.y + 5);
  } else if (op.tool === 'vehicle') {
    ctx.beginPath();
    ctx.arc(end.x, end.y, 13, 0, Math.PI * 2);
    ctx.fillStyle = '#3B82F6';
    ctx.fill();
    ctx.strokeStyle = '#FFFFFF';
    ctx.lineWidth = 1.8;
    ctx.stroke();
    ctx.fillStyle = '#FFFFFF';
    ctx.font = '900 11px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('🚗', end.x, end.y + 4);
  } else if (op.tool === 'bluezone') {
    const r = Math.max(15, Math.hypot(end.x - start.x, end.y - start.y));
    ctx.beginPath();
    ctx.arc(start.x, start.y, r, 0, Math.PI * 2);
    ctx.fillStyle = 'rgba(59, 130, 246, 0.15)';
    ctx.fill();
    ctx.strokeStyle = '#3B82F6';
    ctx.lineWidth = 2;
    ctx.setLineDash([5, 3]);
    ctx.stroke();
    ctx.setLineDash([]);
  }

  // 4. Universal Strategy Tokens (Pins, Sequence, Arrows, Zones, Text, Pen)
  else if (op.tool === 'pin-blue' || op.tool === 'pin-red') {
    const isBlue = op.tool === 'pin-blue';
    const num = op.pinNumber || 1;
    const r = 14;

    ctx.beginPath();
    ctx.arc(end.x, end.y + 2, r, 0, Math.PI * 2);
    ctx.fillStyle = 'rgba(0, 0, 0, 0.6)';
    ctx.fill();

    ctx.beginPath();
    ctx.arc(end.x, end.y, r, 0, Math.PI * 2);
    const grad = ctx.createLinearGradient(end.x - r, end.y - r, end.x + r, end.y + r);
    if (isBlue) {
      grad.addColorStop(0, '#3B82F6');
      grad.addColorStop(1, '#1D4ED8');
    } else {
      grad.addColorStop(0, '#EF4444');
      grad.addColorStop(1, '#B91C1C');
    }
    ctx.fillStyle = grad;
    ctx.fill();

    ctx.strokeStyle = '#FAF2EE';
    ctx.lineWidth = 2.2;
    ctx.stroke();

    ctx.fillStyle = '#FFFFFF';
    ctx.font = '900 13.5px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText(`${num}`, end.x, end.y + 4.5);
  } else if (op.tool === 'seq-path') {
    if (op.points.length > 1) {
      const p1 = op.points[0];
      const p2 = op.points[1];

      ctx.save();
      ctx.beginPath();
      ctx.moveTo(p1.x, p1.y);
      ctx.lineTo(p2.x, p2.y);
      ctx.setLineDash([4, 4]);
      ctx.strokeStyle = '#38BDF8';
      ctx.lineWidth = 2.4;
      ctx.stroke();

      const dx = p2.x - p1.x;
      const dy = p2.y - p1.y;
      const dist = Math.hypot(dx, dy);
      if (dist > 25) {
        const mx = p1.x + dx * 0.55;
        const my = p1.y + dy * 0.55;
        const ang = Math.atan2(dy, dx);
        ctx.setLineDash([]);
        ctx.beginPath();
        ctx.moveTo(mx, my);
        ctx.lineTo(mx - 8 * Math.cos(ang - Math.PI / 6), my - 8 * Math.sin(ang - Math.PI / 6));
        ctx.lineTo(mx - 8 * Math.cos(ang + Math.PI / 6), my - 8 * Math.sin(ang + Math.PI / 6));
        ctx.closePath();
        ctx.fillStyle = '#38BDF8';
        ctx.fill();
      }
      ctx.restore();
    }

    const num = op.seqNumber || 1;
    const r = 15;

    ctx.beginPath();
    ctx.arc(end.x, end.y + 2, r, 0, Math.PI * 2);
    ctx.fillStyle = 'rgba(0, 0, 0, 0.5)';
    ctx.fill();

    ctx.beginPath();
    ctx.arc(end.x, end.y, r, 0, Math.PI * 2);
    ctx.fillStyle = '#BAE6FD';
    ctx.fill();
    ctx.strokeStyle = '#FFFFFF';
    ctx.lineWidth = 2.2;
    ctx.stroke();

    ctx.fillStyle = '#0369A1';
    ctx.font = '900 14px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText(`${num}`, end.x, end.y + 5);
  } else if (op.tool === 'arrow' || op.tool === 'dashed-arrow') {
    const dx = end.x - start.x;
    const dy = end.y - start.y;
    const len = Math.hypot(dx, dy);

    ctx.strokeStyle = op.color;
    ctx.fillStyle = op.color;
    ctx.lineWidth = lw;
    ctx.lineCap = 'round';

    if (op.tool === 'dashed-arrow') {
      ctx.setLineDash([6, 4]);
    } else {
      ctx.setLineDash([]);
    }

    ctx.beginPath();
    ctx.moveTo(start.x, start.y);
    ctx.lineTo(end.x, end.y);
    ctx.stroke();
    ctx.setLineDash([]);

    if (len > 12) {
      const ang = Math.atan2(dy, dx);
      const headLen = Math.min(18, Math.max(10, lw * 3.5));
      ctx.beginPath();
      ctx.moveTo(end.x, end.y);
      ctx.lineTo(
        end.x - headLen * Math.cos(ang - Math.PI / 6),
        end.y - headLen * Math.sin(ang - Math.PI / 6),
      );
      ctx.lineTo(
        end.x - headLen * Math.cos(ang + Math.PI / 6),
        end.y - headLen * Math.sin(ang + Math.PI / 6),
      );
      ctx.closePath();
      ctx.fill();
    }
  } else if (op.tool === 'zone-circle') {
    const r = Math.max(10, Math.hypot(end.x - start.x, end.y - start.y));
    ctx.beginPath();
    ctx.arc(start.x, start.y, r, 0, Math.PI * 2);
    ctx.fillStyle = `${op.color}22`;
    ctx.fill();
    ctx.strokeStyle = op.color;
    ctx.lineWidth = lw;
    ctx.setLineDash([5, 4]);
    ctx.stroke();
    ctx.setLineDash([]);
  } else if (op.tool === 'zone-box') {
    const w = end.x - start.x;
    const h = end.y - start.y;
    ctx.beginPath();
    ctx.rect(start.x, start.y, w, h);
    ctx.fillStyle = `${op.color}20`;
    ctx.fill();
    ctx.strokeStyle = op.color;
    ctx.lineWidth = lw;
    ctx.stroke();
  } else if (op.tool === 'text') {
    const txt = op.text || 'CALLOUT';
    ctx.font = '800 12px sans-serif';
    const m = ctx.measureText(txt);
    const pw = m.width + 12;
    const ph = 22;

    ctx.beginPath();
    ctx.rect(end.x - 4, end.y - 14, pw, ph);
    ctx.fillStyle = 'rgba(7, 6, 7, 0.92)';
    ctx.fill();
    ctx.strokeStyle = op.color;
    ctx.lineWidth = 1.5;
    ctx.stroke();

    ctx.fillStyle = '#FFFFFF';
    ctx.textAlign = 'left';
    ctx.fillText(txt, end.x + 2, end.y + 2);
  } else if (op.tool === 'pen') {
    if (op.points.length < 2) return;
    ctx.strokeStyle = op.color;
    ctx.lineWidth = lw;
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';
    ctx.beginPath();
    ctx.moveTo(op.points[0].x, op.points[0].y);
    for (let i = 1; i < op.points.length; i++) {
      ctx.lineTo(op.points[i].x, op.points[i].y);
    }
    ctx.stroke();
  }
}

// ─────────────────────────────────────────────────────────
// Main Component
// ─────────────────────────────────────────────────────────

export const TacticalMapBoard: React.FC = () => {
  const open = useVoiceSettingsStore((s) => s.showStratBoard);
  const setOpen = useVoiceSettingsStore((s) => s.setShowStratBoard);
  const activeChannelId = useAppStore((s) => s.activeChannelId);
  const activeVoiceChannelId = useAppStore((s) => s.activeVoiceChannelId);
  const channels = useAppStore((s) => s.channels);
  const activeChannel = channels.find((c) => c.id === (activeVoiceChannelId || activeChannelId));
  const { sendMessage } = useRealtimeChat(activeChannelId);

  // Detect initial game archetype from active channel context
  const detectedGameCat = useMemo(() => {
    return resolveGameCategory(undefined, activeChannel?.name, activeChannel?.tags);
  }, [activeChannel]);

  // Selected horizontal game tab
  const [selectedGameTab, setSelectedGameTab] = useState<string>(detectedGameCat);

  // Dynamic Custom Games state
  const [customGames, setCustomGames] = useState<CustomGameDef[]>([]);
  const [showAddGameModal, setShowAddGameModal] = useState(false);
  const [newGameName, setNewGameName] = useState('');
  const [newGameArchetype, setNewGameArchetype] = useState<'fps' | 'moba' | 'br'>('fps');
  const [newGameMaps, setNewGameMaps] = useState('');

  // Combine Default & Custom Games
  const allGameTabs = useMemo(() => {
    return [
      ...DEFAULT_GAMES,
      ...customGames.map((cg) => ({
        id: cg.id,
        name: cg.name,
        icon: cg.icon,
        archetype: cg.archetype,
        isCustom: true,
      })),
    ];
  }, [customGames]);

  // Active Game Meta & Archetype
  const activeGameMeta = useMemo(() => {
    return (
      allGameTabs.find((g) => g.id === selectedGameTab) ||
      allGameTabs.find((g) => g.id === detectedGameCat) ||
      DEFAULT_GAMES[1]
    );
  }, [allGameTabs, selectedGameTab, detectedGameCat]);

  // Available Maps Filtered Strictly by Game Tab
  const availableMaps = useMemo<TacticalMapId[]>(() => {
    const customMatch = customGames.find((cg) => cg.id === selectedGameTab);
    if (customMatch) {
      return customMatch.maps.map((m) => m.id as TacticalMapId);
    }
    const cat = (selectedGameTab in GAME_MAP_POOLS ? selectedGameTab : 'cs2') as TacticalGameCategory;
    return GAME_MAP_POOLS[cat] || GAME_MAP_POOLS.cs2;
  }, [selectedGameTab, customGames]);

  // Active map state
  const [mapId, setMapId] = useState<TacticalMapId>(availableMaps[0] || 'mirage');

  // Stratbook operations and phase states
  const [ops, setOps] = useState<StratOperation[]>([]);
  const [redoStack, setRedoStack] = useState<StratOperation[]>([]);
  const [tool, setTool] = useState<StratTool>('arrow');
  const [inkColor, setInkColor] = useState<string>('#C82333');
  const [lineWidth, setLineWidth] = useState<number>(3);
  const [activePhase, setActivePhase] = useState<1 | 2 | 3>(1);
  const [showAllPhases, setShowAllPhases] = useState<boolean>(true);
  const [selectedPinNumber, setSelectedPinNumber] = useState<number>(1);
  const [seqCounter, setSeqCounter] = useState<number>(1);
  const [lastSeqPoint, setLastSeqPoint] = useState<StratPoint | null>(null);
  const [syncedPackets, setSyncedPackets] = useState(0);

  // Modern Tactical Sidebar Toggle State
  const [sidebarOpen, setSidebarOpen] = useState<boolean>(true);

  // High-Performance Direct DOM Zoom & Pan
  const [zoomScale, setZoomScale] = useState<number>(1.0);
  const [panOffset, setPanOffset] = useState<{ x: number; y: number }>({ x: 0, y: 0 });
  const boardTransformRef = useRef<HTMLDivElement | null>(null);
  const panOffsetRef = useRef<{ x: number; y: number }>({ x: 0, y: 0 });
  const zoomScaleRef = useRef<number>(1.0);
  const isPanningRef = useRef(false);
  const panStartRef = useRef<{ x: number; y: number }>({ x: 0, y: 0 });
  const isSpacePressedRef = useRef(false);

  // Multi-Touch tracking for mobile 60 FPS pinch-zoom & pan
  const activePointersRef = useRef<Map<number, { x: number; y: number }>>(new Map());
  const initialPinchDistRef = useRef<number | null>(null);
  const initialPinchZoomRef = useRef<number>(1.0);
  const initialPanRef = useRef<{ x: number; y: number }>({ x: 0, y: 0 });
  const initialMidpointRef = useRef<{ x: number; y: number }>({ x: 0, y: 0 });

  // Custom Map Image State & Persistence
  const [customMapUrl, setCustomMapUrl] = useState<string | null>(null);
  const [customMapName, setCustomMapName] = useState<string>('Özel Harita');
  const customImgRef = useRef<HTMLImageElement | null>(null);
  const fileInputRef = useRef<HTMLInputElement | null>(null);
  const jsonImportInputRef = useRef<HTMLInputElement | null>(null);

  // Text Prompt Modal State
  const [showTextModal, setShowTextModal] = useState<boolean>(false);
  const [pendingTextPoint, setPendingTextPoint] = useState<StratPoint | null>(null);
  const [textInput, setTextInput] = useState<string>('');

  // Enterprise Modal States
  const [showMapVetoModal, setShowMapVetoModal] = useState<boolean>(false);
  const [showNetworkStressModal, setShowNetworkStressModal] = useState<boolean>(false);
  const [showNotificationDrawer, setShowNotificationDrawer] = useState<boolean>(false);
  const [showPresetModal, setShowPresetModal] = useState<boolean>(false);
  const [showCallouts, setShowCallouts] = useState<boolean>(true);

  // Timeline Playback Replay State (Adım 27-28)
  const [isPlayingTimeline, setIsPlayingTimeline] = useState<boolean>(false);
  const [timelineProgress, setTimelineProgress] = useState<number>(100);

  // Multi-Stratbook Tabs State (Adım 10)
  const [stratTabs, setStratTabs] = useState<Array<{ id: string; name: string }>>([
    { id: 'main', name: 'Ana Taktik' },
    { id: 'attack', name: 'A Hücumu' },
    { id: 'defense', name: 'B Tutuşu' },
    { id: 'eco', name: 'Eko / Tabanca' },
  ]);
  const [activeStratId, setActiveStratId] = useState<string>('main');

  // Timeline Playback Interval (Adım 27-28)
  useEffect(() => {
    if (!isPlayingTimeline) return;
    const interval = setInterval(() => {
      setTimelineProgress((prev) => {
        if (prev >= 100) {
          setIsPlayingTimeline(false);
          return 100;
        }
        return Math.min(100, prev + 2);
      });
    }, 60);
    return () => clearInterval(interval);
  }, [isPlayingTimeline]);

  const bgCanvasRef = useRef<HTMLCanvasElement | null>(null);
  const fgCanvasRef = useRef<HTMLCanvasElement | null>(null);
  const draftOpRef = useRef<StratOperation | null>(null);
  const draggedOpRef = useRef<StratOperation | null>(null);
  const opsRef = useRef<StratOperation[]>([]);
  const rafIdRef = useRef<number | null>(null);

  opsRef.current = ops;

  // Hydrate custom games & drawings cache from IndexedDB
  useEffect(() => {
    try {
      const storage = getMevaStorageEngine();
      void storage
        .getRecord<CustomGameDef[]>(STORE_PREFS, 'tactical_custom_games')
        .then((savedGames) => {
          if (Array.isArray(savedGames) && savedGames.length > 0) {
            setCustomGames(savedGames);
          }
        });

      void storage
        .getRecord<{ url: string; name: string }>(STORE_PREFS, 'custom_tactical_map')
        .then((saved) => {
          if (saved?.url) {
            setCustomMapUrl(saved.url);
            if (saved.name) setCustomMapName(saved.name);
          }
        });

      void storage
        .getRecord<Record<string, StratOperation[]>>(STORE_PREFS, 'tactical_map_drawings_cache')
        .then((cached) => {
          if (cached && typeof cached === 'object') {
            const allOps: StratOperation[] = [];
            Object.values(cached).forEach((list) => {
              if (Array.isArray(list)) allOps.push(...list);
            });
            if (allOps.length > 0) {
              setOps((prev) => {
                const seen = new Set(prev.map((o) => o.id));
                const toAdd = allOps.filter((o) => !seen.has(o.id));
                return toAdd.length > 0 ? [...prev, ...toAdd] : prev;
              });
            }
          }
        });
    } catch {}
  }, []);

  // Persist tactical drawings to IndexedDB per map (bounded size)
  useEffect(() => {
    if (ops.length === 0) return;
    try {
      const storage = getMevaStorageEngine();
      void storage
        .getRecord<Record<string, StratOperation[]>>(STORE_PREFS, 'tactical_map_drawings_cache')
        .then((cached) => {
          const updated = {
            ...(cached || {}),
            [mapId]: ops.filter((o) => o.mapId === mapId).slice(-60),
          };
          storage.scheduleWrite(STORE_PREFS, 'tactical_map_drawings_cache', updated);
          void storage.flushPendingWrites();
        });
    } catch {}
  }, [ops, mapId]);

  // Preload custom image object whenever customMapUrl changes
  useEffect(() => {
    if (!customMapUrl) return;
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

  // Overlay Paint Scheduler (RAF-batched)
  const scheduleOverlayPaint = useCallback(() => {
    if (rafIdRef.current !== null) return;
    rafIdRef.current = requestAnimationFrame(() => {
      rafIdRef.current = null;
      const fg = fgCanvasRef.current;
      if (!fg) return;
      const ctx = fg.getContext('2d');
      if (!ctx) return;
      ctx.clearRect(0, 0, LOGICAL_W, LOGICAL_H);

      let visibleOps = opsRef.current.filter((op) => {
        if (op.mapId !== mapId) return false;
        if (op.stratId && activeStratId && op.stratId !== activeStratId) return false;
        if (showAllPhases) return true;
        return !op.phase || op.phase === activePhase;
      });

      if (timelineProgress < 100 && visibleOps.length > 0) {
        const count = Math.max(1, Math.ceil((visibleOps.length * timelineProgress) / 100));
        visibleOps = visibleOps.slice(0, count);
      }

      for (const op of visibleOps) {
        // If this op is being actively dragged, draw draggedOpRef instead
        if (draggedOpRef.current && draggedOpRef.current.id === op.id) {
          renderSingleOp(ctx, draggedOpRef.current);
        } else {
          renderSingleOp(ctx, op);
        }
      }
      if (draftOpRef.current && draftOpRef.current.mapId === mapId) {
        renderSingleOp(ctx, draftOpRef.current);
      }

      // Render Teleporter Links & Map Callouts Overlay if enabled
      if (showCallouts && mapId !== 'custom') {
        drawTeleporterLinksOverlay(ctx, mapId as TacticalMapId);
        drawMapCalloutsOverlay(ctx, mapId as TacticalMapId);
      }
    });
  }, [mapId, activePhase, showAllPhases, activeStratId, timelineProgress, showCallouts]);

  // Redraw blueprint immediately whenever mapId or custom map changes
  const redrawCurrentMapBlueprint = useCallback(() => {
    const bg = bgCanvasRef.current;
    if (!bg) return;
    const ctx = bg.getContext('2d');
    if (!ctx) return;
    if (mapId === 'custom') {
      drawCustomUploadedMap(ctx, customImgRef.current, customMapName);
    } else {
      drawRealisticArenaBlueprint(
        ctx,
        mapId as Exclude<TacticalMapId, 'custom'>,
        () => {
          redrawCurrentMapBlueprint();
        },
      );
    }
  }, [mapId, customMapName]);

  useEffect(() => {
    if (!open) return;
    redrawCurrentMapBlueprint();
    scheduleOverlayPaint();
  }, [open, mapId, customMapName, redrawCurrentMapBlueprint, scheduleOverlayPaint]);

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
      await getMevaCryptoEngine().sendEncryptedMeshPacket('strat-op', JSON.stringify(pkt));
    } catch {}
  }, []);

  // Listen to real-time E2EE P2P strat packets
  useEffect(() => {
    const cryptoEngine = getMevaCryptoEngine();
    void cryptoEngine.initialize();
    const mesh = getMevaWebRTCMesh();

    return mesh.onDataPacket((envelope) => {
      if (envelope.kind !== 'strat-op') return;
      void cryptoEngine
        .decryptPayload(envelope.payload, envelope.room, 'strat-op', envelope.from)
        .then((res) => {
          if (!res) return;
          try {
            const pkt = JSON.parse(res.plaintext) as StratWirePacket;
            setSyncedPackets((c) => c + 1);
            if (pkt.action === 'add') {
              setOps((prev) =>
                prev.some((x) => x.id === pkt.op.id) ? prev : [...prev.slice(-100), pkt.op],
              );
            } else if (pkt.action === 'update') {
              setOps((prev) => prev.map((x) => (x.id === pkt.op.id ? pkt.op : x)));
            } else if (pkt.action === 'undo') {
              setOps((prev) => prev.filter((x) => x.id !== pkt.opId));
            } else if (pkt.action === 'clear') {
              setOps((prev) =>
                pkt.phase
                  ? prev.filter((x) => !(x.mapId === pkt.mapId && x.phase === pkt.phase))
                  : prev.filter((x) => x.mapId !== pkt.mapId),
              );
            } else if (pkt.action === 'switch-map') {
              setMapId(pkt.mapId);
            } else if (pkt.action === 'upload-map') {
              setCustomMapUrl(pkt.mapDataUrl);
              setCustomMapName(pkt.mapName || 'Özel Harita');
              setMapId('custom');
            } else if (pkt.action === 'switch-phase') {
              setActivePhase(pkt.phase);
            }
          } catch {}
        });
    });
  }, []);

  const toLogicalCoords = (e: React.PointerEvent<HTMLCanvasElement>): StratPoint => {
    const rect = e.currentTarget.getBoundingClientRect();
    const x = ((e.clientX - rect.left) / Math.max(1, rect.width)) * LOGICAL_W;
    const y = ((e.clientY - rect.top) / Math.max(1, rect.height)) * LOGICAL_H;
    return {
      x: Math.round(Math.max(0, Math.min(LOGICAL_W, x)) * 10) / 10,
      y: Math.round(Math.max(0, Math.min(LOGICAL_H, y)) * 10) / 10,
    };
  };

  const hitTestToken = (pt: StratPoint): StratOperation | null => {
    const visibleOps = ops.filter(
      (o) => o.mapId === mapId && (showAllPhases || !o.phase || o.phase === activePhase),
    );
    for (let i = visibleOps.length - 1; i >= 0; i--) {
      const op = visibleOps[i];
      const end = op.points[op.points.length - 1];
      const d = Math.hypot(pt.x - end.x, pt.y - end.y);
      if (d <= 20) return op;
    }
    return null;
  };

  // ─────────────────────────────────────────────────────────
  // 60 FPS Direct-DOM Pan & Multi-Touch Gestures
  // ─────────────────────────────────────────────────────────

  const applyCanvasTransform = (x: number, y: number, scale: number) => {
    panOffsetRef.current = { x, y };
    zoomScaleRef.current = scale;
    if (boardTransformRef.current) {
      boardTransformRef.current.style.transform = `translate(${x}px, ${y}px) scale(${scale})`;
    }
  };

  const handlePointerDown = (e: React.PointerEvent<HTMLCanvasElement>) => {
    e.currentTarget.setPointerCapture(e.pointerId);
    activePointersRef.current.set(e.pointerId, { x: e.clientX, y: e.clientY });

    // Multi-touch pinch-to-zoom detected (2 fingers)
    if (activePointersRef.current.size === 2) {
      draftOpRef.current = null;
      draggedOpRef.current = null;
      const pts = Array.from(activePointersRef.current.values());
      initialPinchDistRef.current = Math.hypot(pts[0].x - pts[1].x, pts[0].y - pts[1].y);
      initialPinchZoomRef.current = zoomScaleRef.current;
      initialPanRef.current = { ...panOffsetRef.current };
      initialMidpointRef.current = { x: (pts[0].x + pts[1].x) / 2, y: (pts[0].y + pts[1].y) / 2 };
      return;
    }

    // Single pointer Pan (Middle Click, Space+Drag, or Pan Tool)
    if (e.button === 1 || isSpacePressedRef.current || tool === 'pan') {
      isPanningRef.current = true;
      panStartRef.current = { x: e.clientX - panOffsetRef.current.x, y: e.clientY - panOffsetRef.current.y };
      return;
    }

    const pt = toLogicalCoords(e);

    // Eraser Tool
    if (tool === 'eraser') {
      const hit = hitTestToken(pt);
      if (hit) {
        setOps((prev) => prev.filter((o) => o.id !== hit.id));
        setRedoStack((prev) => [...prev.slice(-30), hit]);
        void broadcastStratPacket({ action: 'undo', opId: hit.id, mapId });
      }
      return;
    }

    // Check if dragging existing token
    const hit = hitTestToken(pt);
    if (hit) {
      draggedOpRef.current = hit;
      return;
    }

    // Text tool
    if (tool === 'text') {
      setPendingTextPoint(pt);
      setTextInput('');
      setShowTextModal(true);
      return;
    }

    const opId = `op-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 6)}`;

    // Team Numbered Pins (1-5)
    if (tool === 'pin-blue' || tool === 'pin-red') {
      const pinOp: StratOperation = {
        id: opId,
        mapId,
        tool,
        color: tool === 'pin-blue' ? '#3B82F6' : '#EF4444',
        author: 'IGL',
        points: [pt],
        ts: Date.now(),
        phase: activePhase,
        stratId: activeStratId,
        pinNumber: selectedPinNumber,
        team: tool === 'pin-blue' ? 'blue' : 'red',
      };
      setOps((prev) => [...prev.slice(-100), pinOp]);
      setRedoStack([]);
      void broadcastStratPacket({ action: 'add', op: pinOp });
      return;
    }

    // Auto-Incrementing Path Sequence (1 -> 2 -> 3...)
    if (tool === 'seq-path') {
      const pts = lastSeqPoint ? [lastSeqPoint, pt] : [pt];
      const seqOp: StratOperation = {
        id: opId,
        mapId,
        tool: 'seq-path',
        color: '#38BDF8',
        author: 'IGL',
        points: pts,
        ts: Date.now(),
        phase: activePhase,
        stratId: activeStratId,
        seqNumber: seqCounter,
      };
      setOps((prev) => [...prev.slice(-100), seqOp]);
      setRedoStack([]);
      setLastSeqPoint(pt);
      setSeqCounter((c) => c + 1);
      void broadcastStratPacket({ action: 'add', op: seqOp });
      return;
    }

    // Stamp placement tools (Smoke, Flash, Ward, Spike, Audio Ping, Site A/B, Tormentor, etc.)
    const isStamp = [
      'smoke',
      'flash',
      'molly',
      'spike',
      'defuse',
      'sensor',
      'audio-ping',
      'danger',
      'site-a',
      'site-b',
      'teleport',
      'ward-yellow',
      'ward-pink',
      'honeyfruit',
      'rune',
      'gank',
      'boss',
      'tormentor',
      'watcher',
      'twin-gate',
      'airdrop',
      'vehicle',
    ].includes(tool);

    if (isStamp) {
      const stampOp: StratOperation = {
        id: opId,
        mapId,
        tool,
        color: inkColor,
        author: 'IGL',
        points: [pt],
        ts: Date.now(),
        phase: activePhase,
        stratId: activeStratId,
      };
      setOps((prev) => [...prev.slice(-100), stampOp]);
      setRedoStack([]);
      void broadcastStratPacket({ action: 'add', op: stampOp });
      return;
    }

    // Vector Drawing Tools (Pen, Arrow, Dashed Arrow, Zone Circle, Zone Box)
    draftOpRef.current = {
      id: opId,
      mapId,
      tool,
      color: inkColor,
      author: 'IGL',
      points: [pt, pt],
      ts: Date.now(),
      phase: activePhase,
      stratId: activeStratId,
      lineWidth,
    };
    scheduleOverlayPaint();
  };

  const handlePointerMove = (e: React.PointerEvent<HTMLCanvasElement>) => {
    if (activePointersRef.current.has(e.pointerId)) {
      activePointersRef.current.set(e.pointerId, { x: e.clientX, y: e.clientY });
    }

    // 2-Finger Pinch Zoom & Pan (Zero lag direct DOM)
    if (activePointersRef.current.size === 2 && initialPinchDistRef.current !== null) {
      const pts = Array.from(activePointersRef.current.values());
      const curDist = Math.hypot(pts[0].x - pts[1].x, pts[0].y - pts[1].y);
      const scaleRatio = curDist / Math.max(10, initialPinchDistRef.current);
      const nextZoom = Math.min(3.0, Math.max(0.5, initialPinchZoomRef.current * scaleRatio));

      const curMid = { x: (pts[0].x + pts[1].x) / 2, y: (pts[0].y + pts[1].y) / 2 };
      const dMidX = curMid.x - initialMidpointRef.current.x;
      const dMidY = curMid.y - initialMidpointRef.current.y;
      const nextPanX = initialPanRef.current.x + dMidX;
      const nextPanY = initialPanRef.current.y + dMidY;

      applyCanvasTransform(nextPanX, nextPanY, nextZoom);
      return;
    }

    // Direct DOM Pan Movement (Zero React state updates during drag!)
    if (isPanningRef.current) {
      const nextPanX = e.clientX - panStartRef.current.x;
      const nextPanY = e.clientY - panStartRef.current.y;
      applyCanvasTransform(nextPanX, nextPanY, zoomScaleRef.current);
      return;
    }

    // Dragging an existing token (RAF batched, zero React state re-render during drag!)
    if (draggedOpRef.current) {
      const pt = toLogicalCoords(e);
      draggedOpRef.current = {
        ...draggedOpRef.current,
        points: [pt],
      };
      scheduleOverlayPaint();
      return;
    }

    const draft = draftOpRef.current;
    if (!draft) return;
    const pt = toLogicalCoords(e);
    if (draft.tool === 'pen') {
      const last = draft.points[draft.points.length - 1];
      if (Math.hypot(pt.x - last.x, pt.y - last.y) >= 4) {
        draft.points.push(pt);
      }
    } else {
      draft.points[1] = pt;
    }
    scheduleOverlayPaint();
  };

  const finalizeDraft = (e: React.PointerEvent<HTMLCanvasElement>) => {
    activePointersRef.current.delete(e.pointerId);

    if (activePointersRef.current.size < 2 && initialPinchDistRef.current !== null) {
      initialPinchDistRef.current = null;
      setZoomScale(zoomScaleRef.current);
      setPanOffset({ ...panOffsetRef.current });
    }

    if (isPanningRef.current) {
      isPanningRef.current = false;
      setPanOffset({ ...panOffsetRef.current });
      return;
    }

    if (draggedOpRef.current) {
      const finalOp = draggedOpRef.current;
      draggedOpRef.current = null;
      setOps((prev) => prev.map((o) => (o.id === finalOp.id ? finalOp : o)));
      void broadcastStratPacket({ action: 'update', op: finalOp });
      scheduleOverlayPaint();
      return;
    }

    const draft = draftOpRef.current;
    if (!draft) return;
    draftOpRef.current = null;
    setOps((prev) => [...prev.slice(-100), draft]);
    setRedoStack([]);
    void broadcastStratPacket({ action: 'add', op: draft });
  };

  const handleTextModalSubmit = (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    if (!pendingTextPoint || !textInput.trim()) {
      setShowTextModal(false);
      setPendingTextPoint(null);
      return;
    }
    const textOp: StratOperation = {
      id: `op-text-${Date.now().toString(36)}`,
      mapId,
      tool: 'text',
      color: inkColor,
      author: 'IGL',
      points: [pendingTextPoint],
      text: textInput.trim().toUpperCase(),
      ts: Date.now(),
      phase: activePhase,
      stratId: activeStratId,
    };
    setOps((prev) => [...prev.slice(-100), textOp]);
    setRedoStack([]);
    setShowTextModal(false);
    setPendingTextPoint(null);
    setTextInput('');
    void broadcastStratPacket({ action: 'add', op: textOp });
  };

  // Undo (Ctrl+Z)
  const handleUndo = useCallback(() => {
    const mapOps = ops.filter((o) => o.mapId === mapId);
    const last = mapOps[mapOps.length - 1];
    if (!last) return;
    setOps((prev) => prev.filter((o) => o.id !== last.id));
    setRedoStack((prev) => [...prev.slice(-30), last]);
    void broadcastStratPacket({ action: 'undo', opId: last.id, mapId });
  }, [ops, mapId, broadcastStratPacket]);

  // Redo (Ctrl+Y)
  const handleRedo = useCallback(() => {
    if (redoStack.length === 0) return;
    const next = redoStack[redoStack.length - 1];
    setRedoStack((prev) => prev.slice(0, -1));
    setOps((prev) => [...prev.slice(-100), next]);
    void broadcastStratPacket({ action: 'add', op: next });
  }, [redoStack, broadcastStratPacket]);

  // Clear Map
  const handleClear = () => {
    setOps((prev) => prev.filter((o) => o.mapId !== mapId));
    setRedoStack([]);
    setLastSeqPoint(null);
    setSeqCounter(1);
    void broadcastStratPacket({ action: 'clear', mapId });
  };

  const handleClearPhase = () => {
    setOps((prev) => prev.filter((o) => !(o.mapId === mapId && o.phase === activePhase)));
    setRedoStack([]);
    void broadcastStratPacket({ action: 'clear', mapId, phase: activePhase });
  };

  const handleResetSequence = () => {
    setSeqCounter(1);
    setLastSeqPoint(null);
  };

  // Keyboard Shortcuts (Ctrl+Z, Ctrl+Y, Esc, Space Pan)
  useEffect(() => {
    const onKeyDown = (e: KeyboardEvent) => {
      if (e.target instanceof HTMLInputElement || e.target instanceof HTMLTextAreaElement) return;
      if (e.code === 'Space') {
        isSpacePressedRef.current = true;
      } else if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'z') {
        if (e.shiftKey) {
          handleRedo();
        } else {
          handleUndo();
        }
      } else if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'y') {
        handleRedo();
      } else if (e.key === 'Escape') {
        draftOpRef.current = null;
        scheduleOverlayPaint();
      }
    };
    const onKeyUp = (e: KeyboardEvent) => {
      if (e.code === 'Space') {
        isSpacePressedRef.current = false;
      }
    };
    window.addEventListener('keydown', onKeyDown);
    window.addEventListener('keyup', onKeyUp);
    return () => {
      window.removeEventListener('keydown', onKeyDown);
      window.removeEventListener('keyup', onKeyUp);
    };
  }, [handleUndo, handleRedo, scheduleOverlayPaint]);

  // Zoom Presets & Controls
  const handleSetZoomLevel = (lvl: number) => {
    setZoomScale(lvl);
    applyCanvasTransform(panOffsetRef.current.x, panOffsetRef.current.y, lvl);
  };

  const handleZoomIn = () => {
    const next = Math.min(2.5, Math.round((zoomScaleRef.current + 0.25) * 100) / 100);
    setZoomScale(next);
    applyCanvasTransform(panOffsetRef.current.x, panOffsetRef.current.y, next);
  };

  const handleZoomOut = () => {
    const next = Math.max(0.6, Math.round((zoomScaleRef.current - 0.25) * 100) / 100);
    setZoomScale(next);
    applyCanvasTransform(panOffsetRef.current.x, panOffsetRef.current.y, next);
  };

  const handleResetZoomPan = () => {
    setZoomScale(1.0);
    setPanOffset({ x: 0, y: 0 });
    applyCanvasTransform(0, 0, 1.0);
  };

  const handleWheelZoom = (e: React.WheelEvent) => {
    e.preventDefault();
    const zoomFactor = e.deltaY < 0 ? 1.1 : 0.9;
    const next = Math.min(2.5, Math.max(0.6, Math.round(zoomScaleRef.current * zoomFactor * 100) / 100));
    setZoomScale(next);
    applyCanvasTransform(panOffsetRef.current.x, panOffsetRef.current.y, next);
  };

  // Instant Map Switcher
  const handleSwitchMap = (next: TacticalMapId, e?: React.SyntheticEvent) => {
    if (e) {
      e.preventDefault();
      e.stopPropagation();
    }
    setMapId(next);
    setLastSeqPoint(null);
    setSeqCounter(1);
    void broadcastStratPacket({ action: 'switch-map', mapId: next });
  };

  // 1-Click Pro Strat Preset Applicator
  const handleApplyPresetStrat = useCallback(
    (preset: TacticalPresetStrat) => {
      setMapId(preset.mapId);

      for (const [cat, maps] of Object.entries(GAME_MAP_POOLS)) {
        if ((maps as TacticalMapId[]).includes(preset.mapId)) {
          setSelectedGameTab(cat as TacticalGameCategory);
          break;
        }
      }

      let maxSeq = seqCounter;
      const newOps: StratOperation[] = preset.operations.map((item, idx) => {
        if (item.seqNumber && item.seqNumber >= maxSeq) {
          maxSeq = item.seqNumber + 1;
        }
        return {
          id: `preset-${preset.id}-${Date.now()}-${idx}`,
          mapId: preset.mapId,
          tool: item.tool as StratTool,
          color: item.color || '#EF4444',
          author: 'Pro Stratbook',
          points: item.points,
          ts: Date.now() + idx,
          phase: activePhase,
          stratId: activeStratId,
          text: item.text,
          seqNumber: item.seqNumber,
          pinNumber: item.pinNumber,
          team: item.team,
        };
      });

      setOps((prev) => [...prev.slice(-80), ...newOps]);
      setRedoStack([]);
      setSeqCounter(maxSeq);
      setShowPresetModal(false);

      for (const op of newOps) {
        void broadcastStratPacket({ action: 'add', op });
      }
    },
    [activePhase, activeStratId, broadcastStratPacket, seqCounter],
  );

  // Game Switcher with Strict Tool Isolation Sanitization
  const handleSwitchGameTab = (gameTabId: string) => {
    setSelectedGameTab(gameTabId);
    setLastSeqPoint(null);
    setSeqCounter(1);

    const meta = allGameTabs.find((g) => g.id === gameTabId) || DEFAULT_GAMES[0];
    const isFPS = meta.archetype === 'fps';
    const isMOBA = meta.archetype === 'moba';

    const fpsStamps: StratTool[] = ['smoke', 'flash', 'molly', 'spike', 'defuse', 'sensor', 'audio-ping', 'danger', 'site-a', 'site-b', 'teleport'];
    const mobaStamps: StratTool[] = ['ward-yellow', 'ward-pink', 'honeyfruit', 'rune', 'gank', 'boss', 'danger', 'tormentor', 'watcher', 'twin-gate'];
    const universal: StratTool[] = ['arrow', 'dashed-arrow', 'pen', 'zone-circle', 'zone-box', 'text', 'eraser', 'pan', 'pin-blue', 'pin-red', 'seq-path'];

    // Sanitization: If current tool does not match the newly selected archetype, reset tool to a valid default
    if (isFPS && !fpsStamps.includes(tool) && !universal.includes(tool)) {
      setTool('smoke');
    } else if (isMOBA && !mobaStamps.includes(tool) && !universal.includes(tool)) {
      setTool('ward-yellow');
    }

    // Auto-select first map of this game
    const customMatch = customGames.find((cg) => cg.id === gameTabId);
    let nextMap: TacticalMapId = 'mirage';
    if (customMatch && customMatch.maps.length > 0) {
      nextMap = customMatch.maps[0].id as TacticalMapId;
    } else {
      const cat = (gameTabId in GAME_MAP_POOLS ? gameTabId : 'cs2') as TacticalGameCategory;
      const pool = GAME_MAP_POOLS[cat];
      if (pool && pool.length > 0) {
        nextMap = pool[0];
      }
    }
    setMapId(nextMap);
    void broadcastStratPacket({ action: 'switch-map', mapId: nextMap });
  };

  // Create Custom Game Handler
  const handleCreateCustomGame = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newGameName.trim()) return;

    const gameId = `cg-${Date.now().toString(36)}`;
    const parsedMaps = newGameMaps
      .split('\n')
      .map((line) => line.trim())
      .filter((line) => line.length > 0)
      .map((line, idx) => ({
        id: `${gameId}-map-${idx + 1}`,
        title: line,
        subtitle: `${newGameName.trim()} Haritası #${idx + 1}`,
      }));

    const newGame: CustomGameDef = {
      id: gameId,
      name: newGameName.trim(),
      icon: newGameArchetype === 'moba' ? '⚔️' : newGameArchetype === 'br' ? '🪂' : '🎯',
      archetype: newGameArchetype,
      maps: parsedMaps.length > 0 ? parsedMaps : [{ id: `${gameId}-map1`, title: 'Harita 1', subtitle: 'Varsayılan' }],
    };

    const updated = [...customGames, newGame];
    setCustomGames(updated);
    try {
      const storage = getMevaStorageEngine();
      storage.scheduleWrite(STORE_PREFS, 'tactical_custom_games', updated);
      void storage.flushPendingWrites();
    } catch {}

    setShowAddGameModal(false);
    setNewGameName('');
    setNewGameMaps('');
    handleSwitchGameTab(gameId);
  };

  // Delete Custom Game Handler
  const handleDeleteCustomGame = (gameId: string, e: React.MouseEvent) => {
    e.stopPropagation();
    const updated = customGames.filter((g) => g.id !== gameId);
    setCustomGames(updated);
    try {
      const storage = getMevaStorageEngine();
      storage.scheduleWrite(STORE_PREFS, 'tactical_custom_games', updated);
      void storage.flushPendingWrites();
    } catch {}
    if (selectedGameTab === gameId) {
      handleSwitchGameTab('cs2');
    }
  };

  // Custom Map Uploader Handlers
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
          const optimized = oc.toDataURL('image/jpeg', 0.85);
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

  // ── EXPORT: Stratbook Backup as JSON ──
  const handleExportJSON = () => {
    const mapOps = ops.filter((o) => o.mapId === mapId);
    const payload = {
      version: 'meva-stratbook-v2',
      game: selectedGameTab,
      mapId,
      exportedAt: new Date().toISOString(),
      operations: mapOps,
    };

    const blob = new Blob([JSON.stringify(payload, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `taktik-${selectedGameTab}-${mapId}-${Date.now().toString(36)}.json`;
    a.click();
    URL.revokeObjectURL(url);
  };

  // ── EXPORT: Merged High-Resolution PNG ──
  const handleExportPNG = () => {
    const bgCanvas = bgCanvasRef.current;
    const fgCanvas = fgCanvasRef.current;
    if (!bgCanvas || !fgCanvas) return;

    const exportCanvas = document.createElement('canvas');
    exportCanvas.width = LOGICAL_W;
    exportCanvas.height = LOGICAL_H;
    const ctx = exportCanvas.getContext('2d');
    if (!ctx) return;

    ctx.drawImage(bgCanvas, 0, 0);
    ctx.drawImage(fgCanvas, 0, 0);

    // Tactical Watermark
    ctx.fillStyle = 'rgba(250, 242, 238, 0.4)';
    ctx.font = '700 9px monospace';
    ctx.textAlign = 'right';
    ctx.fillText('MEVA STRATBOOK STUDIO · ZERO-LATENCY ESPORTS', LOGICAL_W - 16, LOGICAL_H - 12);

    const link = document.createElement('a');
    link.download = `meva-taktik-masasi-${mapId}-${Date.now().toString(36)}.png`;
    link.href = exportCanvas.toDataURL('image/png');
    link.click();
  };

  // ── IMPORT: JSON Stratbook ──
  const handleImportJSON = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = () => {
      try {
        const parsed = JSON.parse(reader.result as string);
        if (parsed && Array.isArray(parsed.operations)) {
          setOps((prev) => {
            const existingIds = new Set(prev.map((o) => o.id));
            const newOps = parsed.operations.filter((o: StratOperation) => !existingIds.has(o.id));
            return [...prev.slice(-100), ...newOps];
          });
          if (parsed.mapId) setMapId(parsed.mapId);
          if (parsed.game) setSelectedGameTab(parsed.game);

          for (const op of parsed.operations) {
            void broadcastStratPacket({ action: 'add', op });
          }
        }
      } catch {
        alert('Taktik dosyası okunamadı. Geçerli bir Meva JSON dosyası seçiniz.');
      }
    };
    reader.readAsText(file);
    e.target.value = '';
  };

  const handleShareBriefToChat = async () => {
    const mapOps = ops.filter((o) => o.mapId === mapId);
    const pins = mapOps.filter((o) => o.tool.startsWith('pin-')).length;
    const seqs = mapOps.filter((o) => o.tool === 'seq-path').length;
    const smokes = mapOps.filter((o) => o.tool === 'smoke').length;
    const arrows = mapOps.filter((o) => o.tool.includes('arrow')).length;
    const title =
      mapId === 'custom'
        ? customMapName.toUpperCase()
        : (MAP_BLUEPRINTS[mapId as Exclude<TacticalMapId, 'custom'>]?.title ?? 'TAKTİK').toUpperCase();

    await sendMessage(
      `[ESPOR TAKTİK MASASI · ${title}] IGL brifingi P2P senkronize edildi (${pins} Takım Pini, ${seqs} Rota Adımı, ${smokes} Smoke, ${arrows} Ok). Harita tahtasını (B) açarak canlı stratejiyi inceleyin.`,
    );
  };

  if (!open) return null;

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center exec-backdrop p-1 sm:p-3 font-sans tabular-nums select-none"
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
        className="w-full max-w-[1500px] h-full max-h-[96dvh] rounded-2xl exec-modal flex flex-col overflow-hidden shadow-[0_24px_90px_rgba(0,0,0,0.95)] border border-[#8F1622]/60"
      >
        <MevaErrorBoundary fallbackTitle="Taktik Masası Koruma Modu">
        {/* Hidden Inputs for File Upload & JSON Import */}
        <input
          ref={fileInputRef}
          type="file"
          accept="image/png,image/jpeg,image/webp"
          className="hidden"
          onChange={handleCustomFileSelect}
        />
        <input
          ref={jsonImportInputRef}
          type="file"
          accept=".json,application/json"
          className="hidden"
          onChange={handleImportJSON}
        />

        {/* ── TOP HEADER LAYER 1: Game Tabs & Close Studio ── */}
        <div className="px-3 sm:px-4 py-2 border-b border-[#2A1319] flex items-center justify-between gap-2 bg-[#090507] overflow-x-auto flex-shrink-0">
          <div className="flex items-center gap-1.5 flex-nowrap">
            <span className="text-[10px] font-black text-[#8E7E81] uppercase px-1 tracking-wider whitespace-nowrap">
              OYUN:
            </span>
            {allGameTabs.map((g) => {
              const isActive = selectedGameTab === g.id;
              return (
                <div key={g.id} className="relative group flex-shrink-0">
                  <button
                    type="button"
                    onClick={() => handleSwitchGameTab(g.id)}
                    className={`h-7 px-2.5 rounded-lg text-xs font-black flex items-center gap-1.5 transition-all whitespace-nowrap border ${
                      isActive
                        ? 'crimson-cta text-white shadow-[0_0_12px_rgba(200,35,51,0.5)] border-[#FF4655]'
                        : 'bg-[#120A0D] text-[#A8989B] hover:text-[#FAF2EE] hover:bg-[#1F0C13] border-[#2A1319]'
                    }`}
                  >
                    <span>{g.icon}</span>
                    <span>{g.name}</span>
                  </button>
                  {'isCustom' in g && Boolean(g.isCustom) ? (
                    <button
                      type="button"
                      onClick={(e) => handleDeleteCustomGame(g.id, e)}
                      title="Bu oyunu sil"
                      className="absolute -top-1 -right-1 w-3.5 h-3.5 rounded-full bg-red-800 text-white text-[9px] font-black flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity"
                    >
                      ×
                    </button>
                  ) : null}
                </div>
              );
            })}

            {/* [+ Yeni Oyun Ekle] Button */}
            <button
              type="button"
              onClick={() => setShowAddGameModal(true)}
              title="Yeni espor oyunu, haritaları ve mekaniklerini ekleyin"
              className="h-7 px-2 rounded-lg bg-[#180B10] hover:bg-[#2E1218] border border-[#8F1622]/50 text-xs font-bold text-[#F08C96] hover:text-[#FAF2EE] flex items-center gap-1 transition-colors whitespace-nowrap flex-shrink-0"
            >
              <IconPlus size={12} />
              <span>+ Oyun Ekle</span>
            </button>
          </div>

          <div className="flex items-center gap-2 flex-shrink-0">
            {/* Pro Stratbook Presets Modal Button */}
            <button
              type="button"
              onClick={() => setShowPresetModal(true)}
              title="Profesyonel Espor Taktik ve Orman Rotası Şablonları"
              className="h-7 px-2.5 rounded-lg bg-[#2E1218] hover:bg-[#451822] border border-[#C82333]/70 text-xs font-black text-[#FAF2EE] flex items-center gap-1.5 transition-all shadow-[0_0_10px_rgba(200,35,51,0.3)] whitespace-nowrap"
            >
              <span>📋</span>
              <span className="hidden sm:inline">Şablonlar</span>
            </button>

            {/* Map Veto & Pick-Ban Button */}
            <button
              type="button"
              onClick={() => setShowMapVetoModal(true)}
              title="Espor Harita Veto & Pick-Ban Matrisi (BO1/BO3/BO5)"
              className="h-7 px-2 rounded-lg bg-[#180B10] hover:bg-[#2E1218] border border-[#8F1622]/60 text-xs font-bold text-[#F08C96] hover:text-[#FAF2EE] flex items-center gap-1 transition-colors whitespace-nowrap"
            >
              <span>⚖️</span>
              <span className="hidden sm:inline">Map Veto</span>
            </button>

            {/* Network P2P Stress Test Button */}
            <button
              type="button"
              onClick={() => setShowNetworkStressModal(true)}
              title="P2P Mesh Ağı Gecikme ve Stres Testi Telemetrisi"
              className="h-7 px-2 rounded-lg bg-[#140A0D] hover:bg-[#240F15] border border-[#2C141A] text-xs font-bold text-[#A8989B] hover:text-[#FAF2EE] flex items-center gap-1 transition-colors whitespace-nowrap"
            >
              <span>📡</span>
              <span className="hidden sm:inline">Ağ Testi</span>
            </button>

            {/* Tactical Notifications Drawer Button */}
            <button
              type="button"
              onClick={() => setShowNotificationDrawer(true)}
              title="Taktik Bildirim ve Emir Merkezi"
              className="h-7 px-2 rounded-lg bg-[#140A0D] hover:bg-[#240F15] border border-[#2C141A] text-xs font-bold text-[#A8989B] hover:text-[#FAF2EE] flex items-center gap-1 transition-colors relative whitespace-nowrap"
            >
              <span>🔔</span>
              <span className="w-1.5 h-1.5 rounded-full bg-[#C82333] absolute top-1 right-1" />
            </button>

            {/* Sidebar Toggle for Desktop / Mobile */}
            <button
              type="button"
              onClick={() => setSidebarOpen((s) => !s)}
              title="Taktiksel Kontrol Panelini Aç/Kapat"
              className={`h-7 px-2.5 rounded-lg text-xs font-bold flex items-center gap-1.5 border transition-all ${
                sidebarOpen
                  ? 'bg-[#2E1218] text-[#FAF2EE] border-[#8F1622]'
                  : 'bg-[#140A0D] text-[#9E8E91] hover:text-[#FAF2EE] border-[#2C141A]'
              }`}
            >
              <span>📐</span>
              <span className="hidden sm:inline">Taktik Paneli</span>
            </button>

            {/* Close Studio Button */}
            <button
              type="button"
              onClick={(e) => {
                e.preventDefault();
                setOpen(false);
              }}
              aria-label="Kapat"
              className="rounded-xl w-7 h-7 flex items-center justify-center bg-[#140A0D] hover:bg-[#220D13] border border-[#2C141A] text-[#9E8E91] hover:text-[#F4EFF0] transition-colors flex-shrink-0"
            >
              <IconClose size={14} />
            </button>
          </div>
        </div>

        {/* ── TOP HEADER LAYER 2: Map Selector + Zoom Controls + Quick Export ── */}
        <div className="px-3 sm:px-4 py-1.5 border-b border-[#241116] flex flex-wrap items-center justify-between gap-2 flex-shrink-0 bg-gradient-to-r from-[#1C0B10] via-[#0D090B] to-[#070607]">
          {/* Map Selector Chips */}
          <div className="flex items-center gap-1.5 flex-wrap overflow-x-auto">
            <span className="text-[10px] font-black text-[#8E7E81] uppercase px-1 tracking-wider whitespace-nowrap">
              HARİTA:
            </span>
            {availableMaps.map((mKey) => {
              const spec = MAP_BLUEPRINTS[mKey as Exclude<TacticalMapId, 'custom'>];
              const title = spec?.title || mKey;
              const isActive = mapId === mKey;
              const mapOpsCount = ops.filter((o) => o.mapId === mKey).length;
              return (
                <button
                  key={mKey}
                  type="button"
                  onClick={(e) => handleSwitchMap(mKey, e)}
                  title={`${title} haritasına geç ve taktik çizimlerini yükle`}
                  className={`rounded-lg h-6 px-2 text-[11px] font-extrabold border transition-all flex items-center gap-1 whitespace-nowrap ${
                    isActive
                      ? 'crimson-cta text-[#F4EFF0] shadow-[0_0_12px_rgba(200,35,51,0.45)]'
                      : 'bg-[#120A0D] hover:bg-[#1C0D12] text-[#B8AAAC] hover:text-[#FAF2EE] border-[#2A1319]'
                  }`}
                >
                  <span>{title}</span>
                  {mapOpsCount > 0 && (
                    <span className="text-[9px] px-1 py-0.2 rounded bg-black/50 text-[#FAF2EE] tabular-nums font-mono">
                      {mapOpsCount}
                    </span>
                  )}
                </button>
              );
            })}

            {/* Custom Map Pill */}
            {customMapUrl && (
              <button
                type="button"
                onClick={(e) => handleSwitchMap('custom', e)}
                className={`rounded-lg h-6 px-2 text-[11px] font-extrabold border transition-all whitespace-nowrap ${
                  mapId === 'custom'
                    ? 'bg-cyan-950/90 text-cyan-300 border-cyan-400 shadow-[0_0_12px_rgba(6,182,212,0.4)]'
                    : 'bg-[#0E0709] hover:bg-cyan-950/40 text-cyan-400/80 border-[#2A1319]'
                }`}
              >
                🗺️ {customMapName}
              </button>
            )}

            {/* [+ Harita Yükle] */}
            <button
              type="button"
              onClick={(e) => {
                e.preventDefault();
                fileInputRef.current?.click();
              }}
              title="Bilgisayarınızdan harita yükleyin (.png, .jpg, .webp)"
              className="h-6 px-2 rounded-lg bg-[#1F0C13] hover:bg-[#3B141E] border border-[#8F1622]/60 text-[10.5px] font-extrabold text-[#F08C96] hover:text-[#FAF2EE] flex items-center gap-1 transition-colors whitespace-nowrap"
            >
              <IconPlus size={10} />
              <span>Harita Yükle</span>
            </button>

            {/* [🏷️ Calloutlar] Toggle */}
            <button
              type="button"
              onClick={() => {
                setShowCallouts((prev) => !prev);
              }}
              title="Resmi espor harita bölge ve callout isimlerini göster/gizle"
              className={`h-6 px-2 rounded-lg text-[10.5px] font-extrabold flex items-center gap-1 border transition-all whitespace-nowrap ${
                showCallouts
                  ? 'bg-[#8F1622] text-[#FAF2EE] border-[#FF4655]'
                  : 'bg-[#10070A] text-[#9E8E91] hover:text-[#FAF2EE] border-[#2A1016]'
              }`}
            >
              <span>🏷️</span>
              <span>Calloutlar</span>
            </button>
          </div>

          {/* Zoom Controls & Export Actions */}
          <div className="flex items-center gap-1.5 flex-shrink-0 ml-auto">
            {/* Zoom (+ / -) & Percentage Pill */}
            <div className="flex items-center bg-[#10070A] p-0.5 rounded-lg border border-[#2A1016]">
              <button
                type="button"
                onClick={handleZoomOut}
                title="Uzaklaştır (% -25)"
                className="w-6 h-6 rounded flex items-center justify-center text-[#9E8E91] hover:text-white hover:bg-[#1E0B11] font-bold text-xs"
              >
                -
              </button>

              <div className="flex items-center px-1 gap-1 text-[10px] font-mono font-bold">
                {[1.0, 1.5, 2.0].map((lvl) => (
                  <button
                    key={lvl}
                    type="button"
                    onClick={() => handleSetZoomLevel(lvl)}
                    className={`px-1 rounded transition-colors ${
                      Math.abs(zoomScale - lvl) < 0.05
                        ? 'bg-[#8F1622] text-white'
                        : 'text-[#8E7E81] hover:text-[#FAF2EE]'
                    }`}
                  >
                    %{Math.round(lvl * 100)}
                  </button>
                ))}
              </div>

              <button
                type="button"
                onClick={handleZoomIn}
                title="Yakınlaştır (% +25)"
                className="w-6 h-6 rounded flex items-center justify-center text-[#9E8E91] hover:text-white hover:bg-[#1E0B11] font-bold text-xs"
              >
                +
              </button>

              <button
                type="button"
                onClick={handleResetZoomPan}
                title="Ölçeği ve Konumu Sıfırla (1:1)"
                className="px-1.5 h-6 text-[10px] font-bold text-[#F08C96] hover:text-white hover:bg-[#2E1218] rounded transition-colors"
              >
                ⟲
              </button>
            </div>

            {/* Quick Export / Backup */}
            <div className="flex items-center gap-1 bg-[#10070A] p-0.5 rounded-lg border border-[#2A1016]">
              <button
                type="button"
                onClick={handleExportPNG}
                title="Yüksek çözünürlüklü taktik şemasını PNG olarak indirin"
                className="h-6 px-2 rounded text-[10.5px] font-extrabold text-[#A8989B] hover:text-[#FAF2EE] hover:bg-[#1E0B11] flex items-center gap-1"
              >
                <span>📥</span>
                <span className="hidden sm:inline">PNG</span>
              </button>

              <button
                type="button"
                onClick={handleExportJSON}
                title="Taktik dosyasını (.json) bilgisayarınıza yedekleyin"
                className="h-6 px-2 rounded text-[10.5px] font-extrabold text-[#A8989B] hover:text-[#FAF2EE] hover:bg-[#1E0B11] flex items-center gap-1"
              >
                <span>💾</span>
                <span className="hidden sm:inline">JSON</span>
              </button>

              <button
                type="button"
                onClick={() => jsonImportInputRef.current?.click()}
                title="Önceden kaydedilmiş taktik JSON dosyasını haritaya yükleyin"
                className="h-6 px-2 rounded text-[10.5px] font-extrabold text-[#A8989B] hover:text-[#FAF2EE] hover:bg-[#1E0B11] flex items-center gap-1"
              >
                <span>📤</span>
                <span className="hidden sm:inline">Yükle</span>
              </button>
            </div>
          </div>
        </div>

        {/* ── MAIN STUDIO BODY: Canvas Area + Modern Tactical Sidebar ── */}
        <div className="flex-1 flex flex-col md:flex-row overflow-hidden relative">
          {/* ── CANVAS WORKSPACE (Left / Center) ── */}
          <div
            className={`flex-1 flex items-center justify-center p-2 sm:p-4 bg-[#050304] overflow-hidden relative cursor-default ${
              tool === 'pan' ? 'cursor-grab active:cursor-grabbing' : ''
            }`}
            onWheel={handleWheelZoom}
          >
            {/* Transform Container with direct DOM translation for 60 FPS */}
            <div
              ref={boardTransformRef}
              style={{
                transformOrigin: 'center center',
                willChange: 'transform',
              }}
              className="relative w-full max-w-[840px] aspect-[840/480] rounded-xl overflow-hidden border border-[#2E151C] shadow-[0_20px_60px_rgba(0,0,0,0.95)] touch-none flex-shrink-0"
            >
              {/* Background 2D Radar Texture Layer */}
              <canvas
                ref={bgCanvasRef}
                width={LOGICAL_W}
                height={LOGICAL_H}
                className="absolute inset-0 w-full h-full pointer-events-none"
              />
              {/* Foreground Interactive Stratbook Layer */}
              <canvas
                ref={fgCanvasRef}
                width={LOGICAL_W}
                height={LOGICAL_H}
                onPointerDown={handlePointerDown}
                onPointerMove={handlePointerMove}
                onPointerUp={finalizeDraft}
                onPointerCancel={finalizeDraft}
                className="absolute inset-0 w-full h-full z-10 touch-none"
              />
            </div>

            {/* Floating Canvas HUD Overlay */}
            <div className="absolute bottom-3 left-4 flex items-center gap-2 pointer-events-none text-[10px] font-mono text-[#8E7E81]">
              <span className="bg-[#0B0608]/90 px-2 py-0.5 rounded border border-[#241116] text-[#FAF2EE]">
                {tool.toUpperCase()}
              </span>
              <span className="bg-[#0B0608]/90 px-2 py-0.5 rounded border border-[#241116]">
                ÖLÇEK: %{Math.round(zoomScale * 100)}
              </span>
              <span className="bg-[#0B0608]/90 px-2 py-0.5 rounded border border-[#241116] hidden sm:inline">
                AŞAMA {activePhase} ({ops.filter((o) => o.mapId === mapId).length} ÇİZİM)
              </span>
            </div>

            {/* Mobile Bottom Quick-Toggle Bar */}
            <div className="md:hidden absolute bottom-3 right-4 flex items-center gap-1.5 z-20">
              <button
                type="button"
                onClick={() => setSidebarOpen((s) => !s)}
                className="h-8 px-3 rounded-xl bg-[#8F1622] text-white text-xs font-black shadow-lg flex items-center gap-1.5"
              >
                <span>📐</span>
                <span>Taktik Paneli</span>
              </button>
            </div>
          </div>

          {/* ── MODERN TACTICAL SIDEBAR (Right) ── */}
          {sidebarOpen && (
            <aside
              className="w-full md:w-72 lg:w-80 bg-[#0B0608] border-t md:border-t-0 md:border-l border-[#241116] flex flex-col flex-shrink-0 z-30 overflow-y-auto max-h-[45vh] md:max-h-none shadow-2xl transition-all"
            >
              {/* Sidebar Header */}
              <div className="p-3 border-b border-[#1E0B11] flex items-center justify-between bg-[#0E070A]">
                <div className="flex items-center gap-1.5">
                  <span className="text-xs">🎯</span>
                  <span className="text-xs font-black text-[#FAF2EE] uppercase tracking-wider">
                    STRATBOOK KONTROLÜ
                  </span>
                </div>
                <button
                  type="button"
                  onClick={() => setSidebarOpen(false)}
                  className="md:hidden text-[#9E8E91] hover:text-white p-1"
                >
                  ✕
                </button>
              </div>

              <div className="p-3 space-y-3.5">
                {/* ── SECTION 0: ÇOKLU TAKTİK DEFTERLERİ (MULTI-STRATBOOK) ── */}
                <div className="bg-[#12080B] p-2.5 rounded-xl border border-[#241116]">
                  <div className="flex items-center justify-between mb-1.5">
                    <span className="text-[10px] font-black text-[#8E7E81] uppercase tracking-wider">
                      STRATBOOK DEFTERLERİ
                    </span>
                    <button
                      type="button"
                      onClick={() => {
                        const name = prompt('Yeni taktik defteri adı (Örn: A Split Execute, Pistol Eco):');
                        if (name && name.trim()) {
                          const newId = `strat-${Date.now().toString(36)}`;
                          setStratTabs((prev) => [...prev, { id: newId, name: name.trim() }]);
                          setActiveStratId(newId);
                        }
                      }}
                      className="text-[9.5px] font-bold text-[#F08C96] hover:text-white"
                    >
                      + Ekle
                    </button>
                  </div>
                  <div className="flex items-center gap-1 overflow-x-auto pb-1">
                    {stratTabs.map((st) => (
                      <button
                        key={st.id}
                        type="button"
                        onClick={() => {
                          setActiveStratId(st.id);
                          setTimelineProgress(100);
                        }}
                        className={`px-2 py-1 rounded text-[10px] font-bold whitespace-nowrap border transition-all ${
                          activeStratId === st.id
                            ? 'bg-[#8F1622] text-white border-[#FF4655]'
                            : 'bg-[#090507] text-[#8E7E81] hover:text-white border-[#1E0B11]'
                        }`}
                      >
                        {st.name}
                      </button>
                    ))}
                  </div>
                </div>

                {/* ── SECTION 0B: ZAMAN ÇİZELGESİ & REPLAY OYNATICI (TIMELINE) ── */}
                <div className="bg-[#12080B] p-2.5 rounded-xl border border-[#241116] space-y-1.5">
                  <div className="flex items-center justify-between">
                    <span className="text-[10px] font-black text-[#8E7E81] uppercase tracking-wider">
                      ZAMAN ÇİZELGESİ (REPLAY)
                    </span>
                    <span className="text-[9.5px] font-mono text-[#F08C96]">%{timelineProgress}</span>
                  </div>
                  <div className="flex items-center gap-1.5">
                    <button
                      type="button"
                      onClick={() => {
                        if (timelineProgress >= 100) setTimelineProgress(0);
                        setIsPlayingTimeline((p) => !p);
                      }}
                      className="h-6 px-2 rounded bg-[#1C0D12] hover:bg-[#2E1218] border border-[#3C141E] text-[10px] font-black text-[#FAF2EE] flex items-center gap-1"
                    >
                      {isPlayingTimeline ? '⏸ Durdur' : '▶ Oynat'}
                    </button>
                    <input
                      type="range"
                      min={0}
                      max={100}
                      value={timelineProgress}
                      onChange={(e) => {
                        setIsPlayingTimeline(false);
                        setTimelineProgress(Number(e.target.value));
                      }}
                      className="flex-1 accent-[#C82333] h-1.5 bg-[#090507] rounded-lg cursor-pointer"
                    />
                    <button
                      type="button"
                      onClick={() => {
                        setIsPlayingTimeline(false);
                        setTimelineProgress(100);
                      }}
                      title="Canlı Konuma Git"
                      className="h-6 px-1.5 rounded bg-[#0A0507] text-[9.5px] font-bold text-[#8E7E81] hover:text-white"
                    >
                      Canlı
                    </button>
                  </div>
                </div>

                {/* ── SECTION 1: AŞAMA & KADEME YÖNETİMİ (PHASES) ── */}
                <div className="bg-[#12080B] p-2.5 rounded-xl border border-[#241116]">
                  <div className="flex items-center justify-between mb-1.5">
                    <span className="text-[10px] font-black text-[#8E7E81] uppercase tracking-wider">
                      1. AŞAMA VE KADEME
                    </span>
                    <button
                      type="button"
                      onClick={() => setShowAllPhases((s) => !s)}
                      className={`text-[9.5px] font-bold px-1.5 py-0.5 rounded transition-colors ${
                        showAllPhases ? 'bg-[#8F1622] text-white' : 'text-[#8E7E81] hover:text-[#FAF2EE]'
                      }`}
                    >
                      {showAllPhases ? 'Kümülatif (Tümü)' : 'Tek Aşama'}
                    </button>
                  </div>

                  <div className="grid grid-cols-3 gap-1">
                    {[
                      { id: 1, label: 'Erken / Lvl 1' },
                      { id: 2, label: 'Mid / Execute' },
                      { id: 3, label: 'Late / Post' },
                    ].map((ph) => {
                      const isActive = activePhase === ph.id;
                      const count = ops.filter((o) => o.mapId === mapId && o.phase === ph.id).length;
                      return (
                        <button
                          key={ph.id}
                          type="button"
                          onClick={() => {
                            setActivePhase(ph.id as 1 | 2 | 3);
                            void broadcastStratPacket({ action: 'switch-phase', phase: ph.id as 1 | 2 | 3 });
                          }}
                          className={`py-1.5 px-1 rounded-lg text-[10px] font-extrabold flex flex-col items-center justify-center border transition-all ${
                            isActive
                              ? 'crimson-cta text-white border-[#FF4655] shadow-xs'
                              : 'bg-[#0A0507] text-[#9E8E91] hover:text-[#FAF2EE] border-[#1E0B11]'
                          }`}
                        >
                          <span>{ph.label}</span>
                          <span className="text-[8.5px] opacity-70">({count})</span>
                        </button>
                      );
                    })}
                  </div>
                </div>

                {/* ── SECTION 2: OYUNA ÖZEL MEKANİKLER (STRICT ISOLATION) ── */}
                <div className="bg-[#12080B] p-2.5 rounded-xl border border-[#241116]">
                  <div className="flex items-center justify-between mb-1.5">
                    <span className="text-[10px] font-black text-[#8E7E81] uppercase tracking-wider">
                      2. {activeGameMeta.name.toUpperCase()} EKİPMANLARI
                    </span>
                  </div>

                  {/* 2A. Tactical FPS Equipment (Strictly for FPS) */}
                  {activeGameMeta.archetype === 'fps' && (
                    <div className="grid grid-cols-2 gap-1">
                      {[
                        { id: 'smoke', label: 'Smoke (Duman)', icon: '⭕' },
                        { id: 'flash', label: 'Flash (Kör)', icon: '⚡' },
                        { id: 'molly', label: 'Molly / Yanıcı', icon: '🔥' },
                        { id: 'spike', label: 'Spike / C4', icon: '💣' },
                        { id: 'defuse', label: 'İmha Kiti', icon: '✂️' },
                        { id: 'audio-ping', label: 'Ses / Ayak İzi', icon: '🔊' },
                        { id: 'sensor', label: 'Kapan / Tuzak', icon: '📡' },
                        { id: 'danger', label: 'Tehlike Sinyali', icon: '⚠️' },
                        { id: 'site-a', label: 'A Site (Bölge)', icon: '🅰️' },
                        { id: 'site-b', label: 'B Site (Bölge)', icon: '🅱️' },
                        { id: 'teleport', label: 'Işınlayıcı / Port', icon: '🌀' },
                      ].map((st) => (
                        <button
                          key={st.id}
                          type="button"
                          onClick={() => setTool(st.id as StratTool)}
                          className={`h-7 px-2 rounded-lg text-xs font-bold flex items-center gap-1.5 transition-all border ${
                            tool === st.id
                              ? 'bg-[#8F1622] text-white border-[#FF4655] shadow-xs'
                              : 'bg-[#0A0507] text-[#A8989B] hover:text-[#FAF2EE] border-[#1E0B11]'
                          }`}
                        >
                          <span>{st.icon}</span>
                          <span className="text-[10px] truncate">{st.label}</span>
                        </button>
                      ))}
                    </div>
                  )}

                  {/* 2B. MOBA Equipment (Strictly for LoL & Dota 2) */}
                  {activeGameMeta.archetype === 'moba' && (
                    <div className="grid grid-cols-2 gap-1">
                      {[
                        { id: 'ward-yellow', label: 'Görüş Totemi', icon: '👁️' },
                        { id: 'ward-pink', label: 'Pembe Totem', icon: '🛡️' },
                        { id: 'honeyfruit', label: 'Bal Suyu / Çiçek', icon: '🌿' },
                        { id: 'rune', label: 'Nehir Rünü', icon: '💎' },
                        { id: 'gank', label: 'Baskın (Gank)', icon: '⚔️' },
                        { id: 'boss', label: 'Roshan / Baron', icon: '🐉' },
                        { id: 'tormentor', label: 'Tormentor', icon: '💎' },
                        { id: 'watcher', label: 'Watcher (Gözcü)', icon: '👁️' },
                        { id: 'twin-gate', label: 'İkiz Geçit', icon: '⛩️' },
                        { id: 'danger', label: 'Tehlike Sinyali', icon: '⚠️' },
                      ].map((st) => (
                        <button
                          key={st.id}
                          type="button"
                          onClick={() => setTool(st.id as StratTool)}
                          className={`h-7 px-2 rounded-lg text-xs font-bold flex items-center gap-1.5 transition-all border ${
                            tool === st.id
                              ? 'bg-[#7E22CE] text-white border-purple-400 shadow-xs'
                              : 'bg-[#0A0507] text-[#A8989B] hover:text-[#FAF2EE] border-[#1E0B11]'
                          }`}
                        >
                          <span>{st.icon}</span>
                          <span className="text-[10px] truncate">{st.label}</span>
                        </button>
                      ))}
                    </div>
                  )}

                  {/* 2C. Battle Royale Equipment (Strictly for PUBG) */}
                  {activeGameMeta.archetype === 'br' && (
                    <div className="grid grid-cols-2 gap-1">
                      {[
                        { id: 'smoke', label: 'Smoke', icon: '⭕' },
                        { id: 'airdrop', label: 'Air Drop', icon: '📦' },
                        { id: 'flight', label: 'Uçak Rotası', icon: '✈️' },
                        { id: 'vehicle', label: 'Araç / Buggy', icon: '🚗' },
                        { id: 'bluezone', label: 'Alan (Bluezone)', icon: '🔵' },
                        { id: 'danger', label: 'Tehlike Pini', icon: '⚠️' },
                      ].map((st) => (
                        <button
                          key={st.id}
                          type="button"
                          onClick={() => setTool(st.id as StratTool)}
                          className={`h-7 px-2 rounded-lg text-xs font-bold flex items-center gap-1.5 transition-all border ${
                            tool === st.id
                              ? 'bg-[#B45309] text-white border-amber-400 shadow-xs'
                              : 'bg-[#0A0507] text-[#A8989B] hover:text-[#FAF2EE] border-[#1E0B11]'
                          }`}
                        >
                          <span>{st.icon}</span>
                          <span className="text-[10px] truncate">{st.label}</span>
                        </button>
                      ))}
                    </div>
                  )}
                </div>

                {/* ── SECTION 2B: EKONOMİ VE OBJEKTİF SAYACI (ADIM 26) ── */}
                <EconomyTimerWidget archetype={activeGameMeta.archetype} />

                {/* ── SECTION 3: TAKIM JETONLARI & SIRALI ROTA ── */}
                <div className="bg-[#12080B] p-2.5 rounded-xl border border-[#241116]">
                  <span className="text-[10px] font-black text-[#8E7E81] uppercase tracking-wider block mb-1.5">
                    3. TAKIM JETONLARI VE ROTA
                  </span>

                  {/* 1-5 Number Picker */}
                  <div className="flex items-center justify-between mb-2 bg-[#090507] p-1 rounded-lg border border-[#1E0B11]">
                    <span className="text-[9.5px] font-black text-[#8E7E81] px-1">NUMARA:</span>
                    <div className="flex items-center gap-1">
                      {([1, 2, 3, 4, 5] as const).map((n) => (
                        <button
                          key={n}
                          type="button"
                          onClick={() => setSelectedPinNumber(n)}
                          className={`w-5 h-5 rounded text-[10px] font-black transition-colors ${
                            selectedPinNumber === n ? 'bg-[#FAF2EE] text-black shadow-xs' : 'text-[#8E7E81] hover:text-[#FAF2EE]'
                          }`}
                        >
                          {n}
                        </button>
                      ))}
                    </div>
                  </div>

                  <div className="grid grid-cols-2 gap-1 mb-1.5">
                    <button
                      type="button"
                      onClick={() => setTool('pin-blue')}
                      className={`h-7 px-2 rounded-lg text-xs font-black flex items-center justify-center gap-1.5 border transition-all ${
                        tool === 'pin-blue' ? 'bg-blue-600 text-white border-blue-400' : 'bg-[#0A0507] text-blue-400 border-[#1E0B11]'
                      }`}
                    >
                      <span className="w-4 h-4 rounded-full bg-blue-500 text-white text-[9.5px] flex items-center justify-center font-bold">
                        {selectedPinNumber}
                      </span>
                      <span className="text-[10px]">Dost Pin</span>
                    </button>

                    <button
                      type="button"
                      onClick={() => setTool('pin-red')}
                      className={`h-7 px-2 rounded-lg text-xs font-black flex items-center justify-center gap-1.5 border transition-all ${
                        tool === 'pin-red' ? 'bg-red-600 text-white border-red-400' : 'bg-[#0A0507] text-red-400 border-[#1E0B11]'
                      }`}
                    >
                      <span className="w-4 h-4 rounded-full bg-red-600 text-white text-[9.5px] flex items-center justify-center font-bold">
                        {selectedPinNumber}
                      </span>
                      <span className="text-[10px]">Düşman Pin</span>
                    </button>
                  </div>

                  {/* Sequential Path Button (Dignitas Style) */}
                  <div className="flex items-center gap-1 bg-[#090507] p-1 rounded-lg border border-[#1E0B11]">
                    <button
                      type="button"
                      onClick={() => setTool('seq-path')}
                      className={`flex-1 h-7 px-2 rounded text-xs font-black flex items-center justify-center gap-1.5 transition-all ${
                        tool === 'seq-path' ? 'bg-sky-500 text-slate-950 font-black' : 'text-sky-400 hover:text-sky-200'
                      }`}
                    >
                      <span className="w-4 h-4 rounded-full bg-sky-200 text-sky-950 text-[9.5px] flex items-center justify-center font-bold">
                        {seqCounter}
                      </span>
                      <span className="text-[10.5px]">Sıralı Rota #{seqCounter}</span>
                    </button>
                    {seqCounter > 1 && (
                      <button
                        type="button"
                        onClick={handleResetSequence}
                        title="Sayacı 1'e Sıfırla"
                        className="text-[9.5px] font-bold text-[#F08C96] hover:text-white px-2 h-7 rounded hover:bg-[#1E0B11]"
                      >
                        Sıfırla
                      </button>
                    )}
                  </div>
                </div>

                {/* ── SECTION 4: VEKTÖREL ÇİZİM & KALEM AYARLARI ── */}
                <div className="bg-[#12080B] p-2.5 rounded-xl border border-[#241116]">
                  <span className="text-[10px] font-black text-[#8E7E81] uppercase tracking-wider block mb-1.5">
                    4. ÇİZİM ARAÇLARI VE RENK
                  </span>

                  <div className="grid grid-cols-4 gap-1 mb-2">
                    {[
                      { id: 'arrow', label: 'Saldırı', icon: '➡️' },
                      { id: 'dashed-arrow', label: 'Rotasyon', icon: '⇢' },
                      { id: 'pen', label: 'Kalem', icon: '✏️' },
                      { id: 'zone-circle', label: 'Alan ◯', icon: '◯' },
                      { id: 'zone-box', label: 'Bölge ▢', icon: '▢' },
                      { id: 'text', label: 'Not', icon: '💬' },
                      { id: 'eraser', label: 'Silgi', icon: '🧹' },
                      { id: 'pan', label: 'Pan (Kaydır)', icon: '✋' },
                    ].map((dt) => (
                      <button
                        key={dt.id}
                        type="button"
                        onClick={() => setTool(dt.id as StratTool)}
                        title={dt.label}
                        className={`h-7 rounded flex flex-col items-center justify-center text-[10px] font-bold transition-all border ${
                          tool === dt.id
                            ? 'bg-[#8F1622] text-white border-[#FF4655]'
                            : 'bg-[#0A0507] text-[#A8989B] hover:text-[#FAF2EE] border-[#1E0B11]'
                        }`}
                      >
                        <span className="text-xs">{dt.icon}</span>
                      </button>
                    ))}
                  </div>

                  {/* Ink Swatches */}
                  <div className="flex items-center justify-between mb-2 bg-[#090507] p-1.5 rounded-lg border border-[#1E0B11]">
                    <span className="text-[9.5px] font-black text-[#8E7E81]">RENK:</span>
                    <div className="flex items-center gap-1">
                      {INK_SWATCHES.map((sw) => (
                        <button
                          key={sw.hex}
                          type="button"
                          onClick={() => setInkColor(sw.hex)}
                          title={sw.label}
                          style={{ backgroundColor: sw.hex }}
                          className={`w-4 h-4 rounded-full transition-transform ${
                            inkColor === sw.hex ? 'scale-125 ring-2 ring-white shadow-xs' : 'opacity-70 hover:opacity-100'
                          }`}
                        />
                      ))}
                    </div>
                  </div>

                  {/* Stroke Width Slider */}
                  <div className="flex items-center justify-between bg-[#090507] p-1.5 rounded-lg border border-[#1E0B11]">
                    <span className="text-[9.5px] font-black text-[#8E7E81]">KALINLIK:</span>
                    <div className="flex items-center gap-1">
                      {[2, 3, 5, 8].map((w) => (
                        <button
                          key={w}
                          type="button"
                          onClick={() => setLineWidth(w)}
                          className={`px-1.5 py-0.5 rounded text-[9.5px] font-black ${
                            lineWidth === w ? 'bg-[#8F1622] text-white' : 'text-[#8E7E81] hover:text-[#FAF2EE]'
                          }`}
                        >
                          {w}px
                        </button>
                      ))}
                    </div>
                  </div>
                </div>

                {/* ── SECTION 5: GEÇMİŞ VE İŞLEM YÖNETİMİ ── */}
                <div className="bg-[#12080B] p-2.5 rounded-xl border border-[#241116] space-y-1.5">
                  <div className="flex items-center gap-1">
                    <button
                      type="button"
                      onClick={handleUndo}
                      title="Geri Al (Ctrl+Z)"
                      className="flex-1 h-7 rounded bg-[#0A0507] hover:bg-[#1C0D12] border border-[#2A1319] text-[10.5px] font-bold text-[#FAF2EE] flex items-center justify-center gap-1"
                    >
                      <span>↶</span>
                      <span>Geri Al</span>
                    </button>
                    <button
                      type="button"
                      onClick={handleRedo}
                      title="İleri Al (Ctrl+Y)"
                      className="flex-1 h-7 rounded bg-[#0A0507] hover:bg-[#1C0D12] border border-[#2A1319] text-[10.5px] font-bold text-[#FAF2EE] flex items-center justify-center gap-1"
                    >
                      <span>↷</span>
                      <span>İleri Al</span>
                    </button>
                  </div>

                  <div className="flex items-center gap-1">
                    <button
                      type="button"
                      onClick={handleClearPhase}
                      title="Sadece mevcut aktif aşamadaki çizimleri temizler"
                      className="flex-1 h-7 rounded bg-[#1C0A0E] hover:bg-[#2E1016] border border-[#3C141E] text-[10px] font-bold text-[#F08C96] hover:text-white"
                    >
                      Aşamayı Sil
                    </button>
                    <button
                      type="button"
                      onClick={handleClear}
                      title="Tüm haritadaki taktik çizimlerini sıfırlar"
                      className="flex-1 h-7 rounded bg-[#1C0A0E] hover:bg-[#2E1016] border border-[#3C141E] text-[10px] font-bold text-red-400 hover:text-white"
                    >
                      Tümünü Sil
                    </button>
                  </div>

                  <button
                    type="button"
                    onClick={handleShareBriefToChat}
                    className="w-full h-7 rounded-lg bg-[#1F0C13] hover:bg-[#3B141E] border border-[#8F1622] text-[10.5px] font-black text-[#FAF2EE] flex items-center justify-center gap-1 transition-colors"
                  >
                    <span>📢</span>
                    <span>Odaya Taktik Brifingi Gönder</span>
                  </button>
                </div>
              </div>
            </aside>
          )}
        </div>

        {/* ── MODAL: CALLOUT TEXT NOTE ── */}
        {showTextModal && (
          <div className="absolute inset-0 z-50 flex items-center justify-center bg-black/80 p-4">
            <form
              onSubmit={handleTextModalSubmit}
              className="w-full max-w-sm bg-[#12080B] p-4 rounded-2xl border border-[#8F1622] shadow-2xl flex flex-col gap-3"
            >
              <div className="flex items-center justify-between">
                <span className="text-xs font-black text-white uppercase tracking-wider">
                  💬 Taktik Notu Ekle
                </span>
                <button
                  type="button"
                  onClick={() => setShowTextModal(false)}
                  className="text-[#9E8E91] hover:text-white text-sm"
                >
                  ✕
                </button>
              </div>
              <input
                type="text"
                value={textInput}
                onChange={(e) => setTextInput(e.target.value)}
                placeholder="Örn: A SHORT, MID PUSH, FLASH ÇUKURU..."
                autoFocus
                className="w-full px-3 py-2 rounded-lg bg-[#070406] border border-[#2E151C] text-sm text-white focus:outline-hidden focus:border-[#C82333]"
              />
              <div className="flex items-center justify-end gap-2">
                <button
                  type="button"
                  onClick={() => setShowTextModal(false)}
                  className="px-3 py-1.5 rounded-lg text-xs font-bold text-[#9E8E91] hover:text-white"
                >
                  İptal
                </button>
                <button
                  type="submit"
                  className="px-4 py-1.5 rounded-lg crimson-cta text-xs font-black text-white"
                >
                  Haritaya Ekle
                </button>
              </div>
            </form>
          </div>
        )}

        {/* ── MODAL: ADD CUSTOM GAME ── */}
        {showAddGameModal && (
          <div className="absolute inset-0 z-50 flex items-center justify-center bg-black/80 p-4">
            <form
              onSubmit={handleCreateCustomGame}
              className="w-full max-w-md bg-[#12080B] p-5 rounded-2xl border border-[#8F1622] shadow-2xl flex flex-col gap-3.5"
            >
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <span className="text-base">🎮</span>
                  <span className="text-sm font-black text-white uppercase tracking-wider">
                    Yeni Espor Oyunu Ekle
                  </span>
                </div>
                <button
                  type="button"
                  onClick={() => setShowAddGameModal(false)}
                  className="text-[#9E8E91] hover:text-white text-sm"
                >
                  ✕
                </button>
              </div>

              <div>
                <label className="text-[10px] font-black text-[#8E7E81] uppercase block mb-1">
                  Oyun Adı
                </label>
                <input
                  type="text"
                  value={newGameName}
                  onChange={(e) => setNewGameName(e.target.value)}
                  placeholder="Örn: Rainbow Six Siege, Overwatch 2, Mobile Legends"
                  className="w-full px-3 py-2 rounded-lg bg-[#070406] border border-[#2E151C] text-xs text-white focus:outline-hidden focus:border-[#C82333]"
                  required
                />
              </div>

              <div>
                <label className="text-[10px] font-black text-[#8E7E81] uppercase block mb-1">
                  Oyun Mekanik Türü (Araç Kiti Filtresi)
                </label>
                <div className="grid grid-cols-3 gap-1.5">
                  {[
                    { id: 'fps', label: 'FPS / Shooter', icon: '🎯' },
                    { id: 'moba', label: 'MOBA', icon: '⚔️' },
                    { id: 'br', label: 'Battle Royale', icon: '🪂' },
                  ].map((arch) => (
                    <button
                      key={arch.id}
                      type="button"
                      onClick={() => setNewGameArchetype(arch.id as any)}
                      className={`py-2 rounded-lg text-xs font-bold flex flex-col items-center justify-center gap-1 border transition-all ${
                        newGameArchetype === arch.id
                          ? 'crimson-cta text-white border-[#FF4655]'
                          : 'bg-[#070406] text-[#9E8E91] hover:text-white border-[#241116]'
                      }`}
                    >
                      <span className="text-sm">{arch.icon}</span>
                      <span className="text-[10px]">{arch.label}</span>
                    </button>
                  ))}
                </div>
              </div>

              <div>
                <label className="text-[10px] font-black text-[#8E7E81] uppercase block mb-1">
                  Harita Listesi (Her satıra bir harita)
                </label>
                <textarea
                  value={newGameMaps}
                  onChange={(e) => setNewGameMaps(e.target.value)}
                  placeholder={"Bank\nClubhouse\nOregon\nChalet"}
                  rows={4}
                  className="w-full px-3 py-2 rounded-lg bg-[#070406] border border-[#2E151C] text-xs text-white focus:outline-hidden focus:border-[#C82333] font-mono"
                />
              </div>

              <div className="flex items-center justify-end gap-2 pt-2 border-t border-[#241116]">
                <button
                  type="button"
                  onClick={() => setShowAddGameModal(false)}
                  className="px-3 py-1.5 rounded-lg text-xs font-bold text-[#9E8E91] hover:text-white"
                >
                  İptal
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 rounded-lg crimson-cta text-xs font-black text-white"
                >
                  Oyunu ve Haritaları Kaydet
                </button>
              </div>
            </form>
          </div>
        )}

        {/* ── ENTERPRISE MODALS ── */}
        <MapVetoModal isOpen={showMapVetoModal} onClose={() => setShowMapVetoModal(false)} />
        <NetworkStressModal isOpen={showNetworkStressModal} onClose={() => setShowNetworkStressModal(false)} />
        <NotificationDrawer isOpen={showNotificationDrawer} onClose={() => setShowNotificationDrawer(false)} />
        <TacticalPresetsModal
          open={showPresetModal}
          onClose={() => setShowPresetModal(false)}
          onApplyPreset={handleApplyPresetStrat}
          currentMapId={mapId}
        />
        </MevaErrorBoundary>
      </div>
    </div>
  );
};

export const TacticalStratDrawer = TacticalMapBoard;
