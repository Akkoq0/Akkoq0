'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Esports Stratbook & Interactive Tactical Map Board
// ─────────────────────────────────────────────────────────
// Full-Featured Production Stratbook Engine:
//   1. Real Game Blueprints: Topographical 2026 vector terrain for
//      LoL (Summoner's Rift & ARAM), Valorant (Bind, Ascent, Haven, Split, Lotus),
//      CS2 (Mirage, Inferno, Dust2, Ancient, Nuke), Dota 2 (New Frontiers 7.33+),
//      PUBG (Erangel, Miramar, Sanhok).
//   2. Numbered Strategy Tokens (1-5): Blue & Red team tokens with draggable physics.
//   3. Auto Sequence Pathing (1 -> 2 -> 3 -> 4...): Auto-incrementing numbered tokens
//      with directional dashed vector lines for jungle pathing & site executes.
//   4. Tactical Toolbar: Freehand pen, solid attack arrow, dashed rotation arrow,
//      tactical zones (circle/box), text callout stamps, and utility stamps
//      (Smoke, Flash, Molly, Ward, Danger Ping, Spike/Objective).
//   5. Multi-Phase Stratbook: Phase 1 (Early/Lvl 1), Phase 2 (Mid/Execute),
//      Phase 3 (Post-Plant/Late) with cumulative view mode.
//   6. Custom Map Loader: Local file upload (.png, .jpg, .webp) + Direct Image URL
//      with IndexedDB persistence and E2EE WebRTC sync.
//   7. Zoom & Pan: 0.6x - 2.5x wheel zoom, Space-drag pan, and 100% reset.
//   8. Dual-Layer Canvas: Zero re-rasterization 60 FPS performance.

import React, { memo, useCallback, useEffect, useRef, useState, useMemo } from 'react';
import { useVoiceSettingsStore } from '@/store/useVoiceSettingsStore';
import { useAppStore } from '@/lib/store';
import { getMevaCryptoEngine } from '@/src/lib/cryptoEngine';
import { getMevaWebRTCMesh } from '@/src/lib/webrtcMesh';
import { getMevaStorageEngine, STORE_PREFS } from '@/src/lib/storageEngine';
import { useRealtimeChat } from '@/hooks/useRealtimeChat';
import {
  IconClose,
  IconMapBoard,
  IconSend,
  IconShield,
  IconUpload,
  IconCheck,
  IconTrash,
} from '@/components/ui/MevaIcons';
import {
  LOGICAL_W,
  LOGICAL_H,
  TacticalGameCategory,
  TacticalMapId,
  GAME_MAP_POOLS,
  MAP_BLUEPRINTS,
  drawRealisticArenaBlueprint,
} from './tacticalBlueprints';

export {
  type TacticalGameCategory,
  type TacticalMapId,
  LOGICAL_W,
  LOGICAL_H,
  GAME_MAP_POOLS,
  MAP_BLUEPRINTS,
};

export type StratTool =
  | 'pen'
  | 'arrow'
  | 'dashed-arrow'
  | 'zone-circle'
  | 'zone-box'
  | 'text'
  | 'smoke'
  | 'flash'
  | 'molly'
  | 'ward'
  | 'danger'
  | 'spike'
  | 'pin-blue'
  | 'pin-red'
  | 'seq-path'
  | 'eraser'
  | 'pan';

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
  lineWidth?: number;
  text?: string;
  pinNumber?: number; // 1 to 5 for team pins
  seqNumber?: number; // 1, 2, 3... for path sequence
  team?: 'blue' | 'red';
  radius?: number;
  boxW?: number;
  boxH?: number;
}

type StratWirePacket =
  | { action: 'add'; op: StratOperation }
  | { action: 'update'; op: StratOperation }
  | { action: 'undo'; opId: string; mapId: TacticalMapId }
  | { action: 'clear'; mapId: TacticalMapId; phase?: number }
  | { action: 'switch-map'; mapId: TacticalMapId }
  | { action: 'upload-map'; mapDataUrl: string; mapName: string }
  | { action: 'switch-phase'; phase: 1 | 2 | 3 };

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
    if (id === 'pubg' || id === 'pubgm' || id === 'apex' || id === 'warzone' || id === 'fortnite') return 'pubg';
  }
  if (channelName) {
    const n = channelName.toLowerCase();
    if (n.includes('val') || n.includes('ascent') || n.includes('bind') || n.includes('haven') || n.includes('lotus')) return 'valorant';
    if (n.includes('cs') || n.includes('mirage') || n.includes('faceit') || n.includes('dust') || n.includes('inferno') || n.includes('nuke')) return 'cs2';
    if (n.includes('lol') || n.includes('rift') || n.includes('dereceli') || n.includes('aram')) return 'lol';
    if (n.includes('dota')) return 'dota2';
    if (n.includes('pubg') || n.includes('erangel') || n.includes('miramar') || n.includes('sanhok') || n.includes('apex')) return 'pubg';
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

// ─────────────────────────────────────────────────────────
// Comprehensive Operation Renderer
// ─────────────────────────────────────────────────────────

function renderSingleOp(ctx: CanvasRenderingContext2D, op: StratOperation) {
  if (op.points.length === 0) return;
  ctx.save();

  const start = op.points[0];
  const end = op.points[op.points.length - 1];
  const lw = op.lineWidth || 2.5;

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
    ctx.font = '900 9px sans-serif';
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
    ctx.strokeStyle = '#FAF2EE';
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
  } else if (op.tool === 'molly') {
    const rad = 28;
    const grad = ctx.createRadialGradient(end.x, end.y, 3, end.x, end.y, rad);
    grad.addColorStop(0, 'rgba(239, 68, 68, 0.55)');
    grad.addColorStop(0.7, 'rgba(249, 115, 22, 0.3)');
    grad.addColorStop(1, 'rgba(239, 68, 68, 0.05)');
    ctx.fillStyle = grad;
    ctx.beginPath();
    ctx.arc(end.x, end.y, rad, 0, Math.PI * 2);
    ctx.fill();

    ctx.strokeStyle = '#F97316';
    ctx.lineWidth = 1.8;
    ctx.stroke();

    ctx.fillStyle = '#FFFFFF';
    ctx.font = '900 10px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('🔥 ATEŞ', end.x, end.y + 3.5);
  } else if (op.tool === 'ward') {
    ctx.beginPath();
    ctx.arc(end.x, end.y, 35, -Math.PI / 4, Math.PI / 4);
    ctx.lineTo(end.x, end.y);
    ctx.closePath();
    ctx.fillStyle = 'rgba(6, 182, 212, 0.22)';
    ctx.fill();
    ctx.strokeStyle = '#00F0FF';
    ctx.lineWidth = 1.2;
    ctx.stroke();

    ctx.beginPath();
    ctx.arc(end.x, end.y, 9, 0, Math.PI * 2);
    ctx.fillStyle = '#083344';
    ctx.fill();
    ctx.strokeStyle = '#00F0FF';
    ctx.lineWidth = 2;
    ctx.stroke();

    ctx.fillStyle = '#00F0FF';
    ctx.font = '900 9px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('👁', end.x, end.y + 3);
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
  } else if (op.tool === 'spike') {
    const sz = 12;
    ctx.beginPath();
    ctx.moveTo(end.x, end.y - sz);
    ctx.lineTo(end.x + sz, end.y);
    ctx.lineTo(end.x, end.y + sz);
    ctx.lineTo(end.x - sz, end.y);
    ctx.closePath();
    ctx.fillStyle = '#EAB308';
    ctx.fill();
    ctx.strokeStyle = '#FAF2EE';
    ctx.lineWidth = 2;
    ctx.stroke();

    ctx.fillStyle = '#000000';
    ctx.font = '900 9px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('OBJ', end.x, end.y + 3);
  } else if (op.tool === 'pin-blue' || op.tool === 'pin-red') {
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
      ctx.setLineDash([5, 4]);
    }

    ctx.beginPath();
    ctx.moveTo(start.x, start.y);
    ctx.lineTo(end.x, end.y);
    ctx.stroke();
    ctx.setLineDash([]);

    if (len > 6) {
      const angle = Math.atan2(dy, dx);
      const head = Math.max(10, lw * 3.5);
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
  } else if (op.tool === 'zone-circle') {
    const rx = Math.abs(end.x - start.x);
    const ry = Math.abs(end.y - start.y);
    const rad = Math.max(12, Math.hypot(rx, ry));

    ctx.beginPath();
    ctx.arc(start.x, start.y, rad, 0, Math.PI * 2);
    ctx.fillStyle = `${op.color}33`;
    ctx.fill();
    ctx.strokeStyle = op.color;
    ctx.lineWidth = 1.8;
    ctx.setLineDash([4, 4]);
    ctx.stroke();
    ctx.setLineDash([]);
  } else if (op.tool === 'zone-box') {
    const minX = Math.min(start.x, end.x);
    const minY = Math.min(start.y, end.y);
    const bw = Math.abs(end.x - start.x);
    const bh = Math.abs(end.y - start.y);

    ctx.beginPath();
    ctx.roundRect(minX, minY, bw, bh, 6);
    ctx.fillStyle = `${op.color}33`;
    ctx.fill();
    ctx.strokeStyle = op.color;
    ctx.lineWidth = 1.8;
    ctx.setLineDash([4, 4]);
    ctx.stroke();
    ctx.setLineDash([]);
  } else if (op.tool === 'text') {
    const text = op.text || 'TAKTİK NOT';
    ctx.font = '800 11.5px sans-serif';
    const metrics = ctx.measureText(text);
    const pad = 6;
    const boxW = metrics.width + pad * 2;
    const boxH = 22;

    ctx.beginPath();
    ctx.roundRect(end.x - boxW / 2, end.y - boxH / 2, boxW, boxH, 4);
    ctx.fillStyle = 'rgba(15, 7, 10, 0.9)';
    ctx.fill();
    ctx.strokeStyle = op.color;
    ctx.lineWidth = 1.4;
    ctx.stroke();

    ctx.fillStyle = '#FAF2EE';
    ctx.textAlign = 'center';
    ctx.fillText(text, end.x, end.y + 4);
  } else if (op.tool === 'pen') {
    ctx.strokeStyle = op.color;
    ctx.lineWidth = lw;
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

  const availableMaps = useMemo(() => {
    return GAME_MAP_POOLS[currentGameCategory] || GAME_MAP_POOLS.cs2;
  }, [currentGameCategory]);

  const [mapId, setMapId] = useState<TacticalMapId>(() => availableMaps[0] || 'bind');
  const [tool, setTool] = useState<StratTool>('arrow');
  const [inkColor, setInkColor] = useState<string>('#C82333');
  const [lineWidth, setLineWidth] = useState<number>(3);
  const [selectedPinNumber, setSelectedPinNumber] = useState<number>(1);
  const [activePhase, setActivePhase] = useState<1 | 2 | 3>(1);
  const [showAllPhases, setShowAllPhases] = useState<boolean>(false);
  const [seqCounter, setSeqCounter] = useState<number>(1);
  const [lastSeqPoint, setLastSeqPoint] = useState<StratPoint | null>(null);

  // Strat Operations Stack & Undo/Redo
  const [ops, setOps] = useState<StratOperation[]>([]);
  const [redoStack, setRedoStack] = useState<StratOperation[]>([]);
  const [syncedPackets, setSyncedPackets] = useState(0);

  // Zoom & Pan
  const [zoomScale, setZoomScale] = useState<number>(1.0);
  const [panOffset, setPanOffset] = useState<{ x: number; y: number }>({ x: 0, y: 0 });
  const isPanningRef = useRef(false);
  const panStartRef = useRef<{ x: number; y: number }>({ x: 0, y: 0 });

  // Custom Map Image State & Persistence
  const [customMapUrl, setCustomMapUrl] = useState<string | null>(null);
  const [customMapName, setCustomMapName] = useState<string>('Özel Harita');
  const [showUrlModal, setShowUrlModal] = useState<boolean>(false);
  const [urlInput, setUrlInput] = useState<string>('');
  const customImgRef = useRef<HTMLImageElement | null>(null);
  const fileInputRef = useRef<HTMLInputElement | null>(null);

  // Text Prompt Modal State
  const [showTextModal, setShowTextModal] = useState<boolean>(false);
  const [pendingTextPoint, setPendingTextPoint] = useState<StratPoint | null>(null);
  const [textInput, setTextInput] = useState<string>('');

  const bgCanvasRef = useRef<HTMLCanvasElement | null>(null);
  const fgCanvasRef = useRef<HTMLCanvasElement | null>(null);
  const draftOpRef = useRef<StratOperation | null>(null);
  const draggedOpRef = useRef<StratOperation | null>(null);
  const opsRef = useRef<StratOperation[]>([]);
  const rafIdRef = useRef<number | null>(null);

  opsRef.current = ops;

  // Hydrate custom map & tactical map drawings cache from IndexedDB
  useEffect(() => {
    try {
      const storage = getMevaStorageEngine();
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

  // Persist tactical drawings to IndexedDB per map
  useEffect(() => {
    if (ops.length === 0) return;
    try {
      const storage = getMevaStorageEngine();
      void storage
        .getRecord<Record<string, StratOperation[]>>(STORE_PREFS, 'tactical_map_drawings_cache')
        .then((cached) => {
          const updated = {
            ...(cached || {}),
            [mapId]: ops.filter((o) => o.mapId === mapId),
          };
          storage.scheduleWrite(STORE_PREFS, 'tactical_map_drawings_cache', updated);
          void storage.flushPendingWrites();
        });
    } catch {}
  }, [ops, mapId]);

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

  // Auto-switch initial map ONLY when channel game category changes
  const lastGameCatRef = useRef<TacticalGameCategory | null>(null);
  useEffect(() => {
    if (lastGameCatRef.current !== currentGameCategory) {
      lastGameCatRef.current = currentGameCategory;
      if (mapId !== 'custom') {
        const pool = GAME_MAP_POOLS[currentGameCategory] || GAME_MAP_POOLS.cs2;
        if (!pool.includes(mapId)) {
          setMapId(pool[0]);
        }
      }
    }
  }, [currentGameCategory, mapId]);

  // Overlay Paint Scheduler
  const scheduleOverlayPaint = useCallback(() => {
    if (rafIdRef.current !== null) return;
    rafIdRef.current = requestAnimationFrame(() => {
      rafIdRef.current = null;
      const fg = fgCanvasRef.current;
      if (!fg) return;
      const ctx = fg.getContext('2d');
      if (!ctx) return;
      ctx.clearRect(0, 0, LOGICAL_W, LOGICAL_H);

      const visibleOps = opsRef.current.filter((op) => {
        if (op.mapId !== mapId) return false;
        if (showAllPhases) return true;
        return !op.phase || op.phase === activePhase;
      });

      for (const op of visibleOps) {
        renderSingleOp(ctx, op);
      }
      if (draftOpRef.current && draftOpRef.current.mapId === mapId) {
        renderSingleOp(ctx, draftOpRef.current);
      }
    });
  }, [mapId, activePhase, showAllPhases]);

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
                prev.some((x) => x.id === pkt.op.id) ? prev : [...prev.slice(-150), pkt.op],
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

  // Hit test for tokens to allow dragging or eraser
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

  const handlePointerDown = (e: React.PointerEvent<HTMLCanvasElement>) => {
    e.currentTarget.setPointerCapture(e.pointerId);

    // Pan Mode Check
    if (tool === 'pan' || e.button === 1 || e.altKey) {
      isPanningRef.current = true;
      panStartRef.current = { x: e.clientX - panOffset.x, y: e.clientY - panOffset.y };
      return;
    }

    const pt = toLogicalCoords(e);

    // Eraser Tool Check
    if (tool === 'eraser') {
      const hit = hitTestToken(pt);
      if (hit) {
        setOps((prev) => prev.filter((o) => o.id !== hit.id));
        void broadcastStratPacket({ action: 'undo', opId: hit.id, mapId });
      }
      return;
    }

    // Hit test existing draggable token
    const hit = hitTestToken(pt);
    if (hit && (hit.tool.startsWith('pin-') || hit.tool === 'seq-path' || hit.tool.startsWith('stamp') || hit.tool === 'text')) {
      draggedOpRef.current = hit;
      return;
    }

    const opId = `st-${Date.now().toString(36)}-${(++stratOpSeq).toString(36)}`;

    // Text Callout Prompt
    if (tool === 'text') {
      setPendingTextPoint(pt);
      setTextInput('');
      setShowTextModal(true);
      return;
    }

    // Numbered Team Pins (1 to 5)
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
        pinNumber: selectedPinNumber,
        team: tool === 'pin-blue' ? 'blue' : 'red',
      };
      setOps((prev) => [...prev.slice(-150), pinOp]);
      setRedoStack([]);
      void broadcastStratPacket({ action: 'add', op: pinOp });
      setSelectedPinNumber((n) => (n >= 5 ? 1 : n + 1));
      return;
    }

    // Auto Sequence Pathing (1 -> 2 -> 3 -> 4... matching Reference Image 4)
    if (tool === 'seq-path') {
      const points = lastSeqPoint ? [lastSeqPoint, pt] : [pt];
      const seqOp: StratOperation = {
        id: opId,
        mapId,
        tool: 'seq-path',
        color: '#0284C7',
        author: 'IGL',
        points,
        ts: Date.now(),
        phase: activePhase,
        seqNumber: seqCounter,
      };
      setOps((prev) => [...prev.slice(-150), seqOp]);
      setRedoStack([]);
      setLastSeqPoint(pt);
      setSeqCounter((c) => c + 1);
      void broadcastStratPacket({ action: 'add', op: seqOp });
      return;
    }

    // Utility Stamps (Smoke, Flash, Molly, Ward, Danger, Spike)
    if (
      tool === 'smoke' ||
      tool === 'flash' ||
      tool === 'molly' ||
      tool === 'ward' ||
      tool === 'danger' ||
      tool === 'spike'
    ) {
      const stampOp: StratOperation = {
        id: opId,
        mapId,
        tool,
        color: inkColor,
        author: 'IGL',
        points: [pt],
        ts: Date.now(),
        phase: activePhase,
      };
      setOps((prev) => [...prev.slice(-150), stampOp]);
      setRedoStack([]);
      void broadcastStratPacket({ action: 'add', op: stampOp });
      return;
    }

    // Drawing Tools (Pen, Arrow, Dashed Arrow, Zone Circle, Zone Box)
    draftOpRef.current = {
      id: opId,
      mapId,
      tool,
      color: inkColor,
      author: 'IGL',
      points: [pt, pt],
      ts: Date.now(),
      phase: activePhase,
      lineWidth,
    };
    scheduleOverlayPaint();
  };

  const handlePointerMove = (e: React.PointerEvent<HTMLCanvasElement>) => {
    // Pan Movement
    if (isPanningRef.current) {
      setPanOffset({
        x: e.clientX - panStartRef.current.x,
        y: e.clientY - panStartRef.current.y,
      });
      return;
    }

    // Dragging an existing token
    if (draggedOpRef.current) {
      const pt = toLogicalCoords(e);
      const updated = {
        ...draggedOpRef.current,
        points: [pt],
      };
      draggedOpRef.current = updated;
      setOps((prev) => prev.map((o) => (o.id === updated.id ? updated : o)));
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

  const finalizeDraft = () => {
    if (isPanningRef.current) {
      isPanningRef.current = false;
      return;
    }

    if (draggedOpRef.current) {
      const finalOp = draggedOpRef.current;
      draggedOpRef.current = null;
      void broadcastStratPacket({ action: 'update', op: finalOp });
      return;
    }

    const draft = draftOpRef.current;
    if (!draft) return;
    draftOpRef.current = null;
    setOps((prev) => [...prev.slice(-150), draft]);
    setRedoStack([]);
    void broadcastStratPacket({ action: 'add', op: draft });
  };

  const handleTextModalSubmit = (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    if (!pendingTextPoint || !textInput.trim()) {
      setShowTextModal(false);
      return;
    }
    const opId = `st-txt-${Date.now().toString(36)}-${(++stratOpSeq).toString(36)}`;
    const textOp: StratOperation = {
      id: opId,
      mapId,
      tool: 'text',
      color: inkColor,
      author: 'IGL',
      points: [pendingTextPoint],
      ts: Date.now(),
      phase: activePhase,
      text: textInput.trim(),
    };
    setOps((prev) => [...prev.slice(-150), textOp]);
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
    setRedoStack((prev) => [...prev, last]);
    void broadcastStratPacket({ action: 'undo', opId: last.id, mapId });
  }, [ops, mapId, broadcastStratPacket]);

  // Redo (Ctrl+Y)
  const handleRedo = useCallback(() => {
    if (redoStack.length === 0) return;
    const next = redoStack[redoStack.length - 1];
    setRedoStack((prev) => prev.slice(0, -1));
    setOps((prev) => [...prev, next]);
    void broadcastStratPacket({ action: 'add', op: next });
  }, [redoStack, broadcastStratPacket]);

  // Clear Map or Current Phase
  const handleClear = () => {
    setOps((prev) => prev.filter((o) => o.mapId !== mapId));
    setRedoStack([]);
    setLastSeqPoint(null);
    setSeqCounter(1);
    void broadcastStratPacket({ action: 'clear', mapId });
  };

  // Reset Path Sequence back to 1
  const handleResetSequence = () => {
    setSeqCounter(1);
    setLastSeqPoint(null);
  };

  // Keyboard Shortcuts (Ctrl+Z, Ctrl+Y, Esc)
  useEffect(() => {
    const onKeyDown = (e: KeyboardEvent) => {
      if (e.target instanceof HTMLInputElement || e.target instanceof HTMLTextAreaElement) return;
      if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'z') {
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
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [handleUndo, handleRedo, scheduleOverlayPaint]);

  // Wheel Zoom (0.6x - 2.5x)
  const handleWheelZoom = (e: React.WheelEvent) => {
    e.preventDefault();
    const zoomFactor = e.deltaY < 0 ? 1.1 : 0.9;
    setZoomScale((z) => Math.min(2.5, Math.max(0.6, z * zoomFactor)));
  };

  const handleResetZoomPan = () => {
    setZoomScale(1.0);
    setPanOffset({ x: 0, y: 0 });
  };

  // Instant Map Switcher — 0ms delay with automatic cached drawing recall
  const handleSwitchMap = (next: TacticalMapId, e?: React.SyntheticEvent) => {
    if (e) {
      e.preventDefault();
      e.stopPropagation();
    }
    setMapId(next);
    setLastSeqPoint(null);
    setSeqCounter(1);

    try {
      const storage = getMevaStorageEngine();
      void storage
        .getRecord<Record<string, StratOperation[]>>(STORE_PREFS, 'tactical_map_drawings_cache')
        .then((cached) => {
          if (cached && cached[next] && Array.isArray(cached[next])) {
            const saved = cached[next];
            setOps((prev) => {
              const seen = new Set(prev.map((o) => o.id));
              const toAdd = saved.filter((o) => !seen.has(o.id));
              return toAdd.length > 0 ? [...prev, ...toAdd] : prev;
            });
          }
        });
    } catch {}

    void broadcastStratPacket({ action: 'switch-map', mapId: next });
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

  const handleCustomUrlSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!urlInput.trim()) return;

    const img = new Image();
    img.crossOrigin = 'anonymous';
    img.onload = () => {
      const oc = document.createElement('canvas');
      oc.width = LOGICAL_W;
      oc.height = LOGICAL_H;
      const octx = oc.getContext('2d');
      if (octx) {
        octx.drawImage(img, 0, 0, LOGICAL_W, LOGICAL_H);
        const optimized = oc.toDataURL('image/jpeg', 0.85);
        setCustomMapUrl(optimized);
        setCustomMapName('Web Haritası');
        setMapId('custom');

        try {
          const storage = getMevaStorageEngine();
          storage.scheduleWrite(STORE_PREFS, 'custom_tactical_map', {
            url: optimized,
            name: 'Web Haritası',
          });
          void storage.flushPendingWrites();
        } catch {}

        void broadcastStratPacket({
          action: 'upload-map',
          mapDataUrl: optimized,
          mapName: 'Web Haritası',
        });
      }
      setShowUrlModal(false);
      setUrlInput('');
    };
    img.onerror = () => {
      alert('Görsel yüklenemedi. Lütfen doğrudan bir görsel URL\'si (örn: .jpg, .png) girdiğinizden emin olun.');
    };
    img.src = urlInput.trim();
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

  const currentMapCount = ops.filter((o) => o.mapId === mapId).length;

  if (!open) return null;

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center exec-backdrop p-2 sm:p-4 font-sans tabular-nums select-none"
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
        className="w-full max-w-6xl max-h-[96dvh] rounded-2xl exec-modal flex flex-col overflow-hidden shadow-[0_24px_90px_rgba(0,0,0,0.95)] border border-[#8F1622]/60"
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
        <div className="px-4 py-2.5 border-b border-[#2A1319] flex flex-wrap items-center justify-between gap-2.5 flex-shrink-0 bg-gradient-to-r from-[#1C0B10] via-[#0D090B] to-[#070607]">
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-xl crimson-cta flex items-center justify-center text-[#F4EFF0] shadow-sm">
              <IconMapBoard size={16} />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h2 className="text-sm font-extrabold text-[#F4EFF0] tracking-wide">
                  İnteraktif Taktik Masası & Stratbook
                </h2>
                <span className="rounded-md px-2 py-0.5 bg-[#250C13] border border-[#C82333]/50 text-[10px] font-black uppercase text-[#FF5A6B] tracking-wider">
                  {currentGameCategory.toUpperCase()}
                </span>
                <span className="rounded-md px-2 py-0.5 bg-[#180B10] border border-[#7A121D]/55 text-[10px] font-bold text-[#F08C96] flex items-center gap-1 shadow-xs">
                  <IconShield size={11} className="text-[#FF4655]" />
                  <span>E2EE Canlı ({syncedPackets})</span>
                </span>
              </div>
              <p className="text-[10.5px] text-[#A8989B] mt-0.5">
                Kanalınıza göre filtrelenmiş profesyonel espor minimap matrisi.
              </p>
            </div>
          </div>

          {/* Dynamic Game-Filtered Map Selector & [+ Harita Yükle] */}
          <div className="flex items-center gap-1.5 flex-wrap">
            {availableMaps.map((mKey) => {
              const spec = MAP_BLUEPRINTS[mKey as Exclude<TacticalMapId, 'custom'>];
              if (!spec) return null;
              const isActive = mapId === mKey;
              const mapOpsCount = ops.filter((o) => o.mapId === mKey).length;
              return (
                <button
                  key={mKey}
                  type="button"
                  onClick={(e) => handleSwitchMap(mKey, e)}
                  title={`${spec.title} haritasına geç ve taktik çizimlerini yükle`}
                  className={`rounded-lg h-7 px-2.5 text-[11px] font-extrabold border transition-all flex items-center gap-1 ${
                    isActive
                      ? 'crimson-cta text-[#F4EFF0] shadow-[0_0_12px_rgba(200,35,51,0.45)]'
                      : 'bg-[#120A0D] hover:bg-[#1C0D12] text-[#B8AAAC] hover:text-[#FAF2EE] border-[#2A1319]'
                  }`}
                >
                  <span>{spec.title}</span>
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
                className={`rounded-lg h-7 px-2.5 text-[11px] font-extrabold border transition-all ${
                  mapId === 'custom'
                    ? 'bg-cyan-950/90 text-cyan-300 border-cyan-400 shadow-[0_0_12px_rgba(6,182,212,0.4)]'
                    : 'bg-[#0E0709] hover:bg-cyan-950/40 text-cyan-400/80 border-[#2A1319]'
                }`}
              >
                🗺️ {customMapName}
              </button>
            )}

            {/* [+ Harita Yükle] Dropdown / Split Action */}
            <div className="flex items-center rounded-lg border border-[#8F1622]/60 bg-[#1F0C13] overflow-hidden">
              <button
                type="button"
                onClick={(e) => {
                  e.preventDefault();
                  fileInputRef.current?.click();
                }}
                title="Bilgisayarınızdan harita yükleyin (.png, .jpg, .webp)"
                className="h-7 px-2 hover:bg-[#3B141E] text-[11px] font-extrabold text-[#F08C96] hover:text-[#FAF2EE] flex items-center gap-1 transition-colors"
              >
                <IconUpload size={12} className="text-[#FF4655]" />
                <span>+ Dosya</span>
              </button>
              <span className="w-px h-4 bg-[#8F1622]/40" />
              <button
                type="button"
                onClick={(e) => {
                  e.preventDefault();
                  setShowUrlModal(true);
                }}
                title="Web bağlantısından (URL) harita yükleyin"
                className="h-7 px-2 hover:bg-[#3B141E] text-[11px] font-extrabold text-[#F08C96] hover:text-[#FAF2EE] transition-colors"
              >
                URL
              </button>
            </div>

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

        {/* ── Sub-Bar: Multi-Phase Tabs + Stratbook Tool Strip ── */}
        <div className="px-4 py-2 bg-[#0B0709]/95 border-b border-[#241116] flex flex-wrap items-center justify-between gap-2.5 flex-shrink-0">
          {/* Left: Phase Planning Tabs */}
          <div className="flex items-center gap-1 bg-[#120A0D] p-1 rounded-xl border border-[#2A1319]">
            <span className="text-[10px] font-black text-[#8E7E81] uppercase px-1.5 tracking-wider">
              FAZ:
            </span>
            {([1, 2, 3] as const).map((ph) => {
              const label =
                ph === 1 ? '1: Erken / Lvl 1' : ph === 2 ? '2: Execute / Mid' : '3: Post-Plant / Late';
              const isActive = activePhase === ph;
              return (
                <button
                  key={ph}
                  type="button"
                  onClick={() => {
                    setActivePhase(ph);
                    void broadcastStratPacket({ action: 'switch-phase', phase: ph });
                  }}
                  className={`rounded-lg px-2.5 py-1 text-[10.5px] font-extrabold transition-all ${
                    isActive
                      ? 'bg-[#C82333] text-white shadow-xs'
                      : 'text-[#9E8E91] hover:text-[#FAF2EE] hover:bg-[#200A11]'
                  }`}
                >
                  {label}
                </button>
              );
            })}
            <button
              type="button"
              onClick={() => setShowAllPhases((s) => !s)}
              title="Tüm fazların çizimlerini birleşik göster"
              className={`rounded-lg px-2 py-1 text-[10px] font-bold border transition-colors ${
                showAllPhases
                  ? 'bg-amber-950/80 text-amber-300 border-amber-500/50'
                  : 'text-[#8E7E81] hover:text-[#B8AAAC] border-transparent'
              }`}
            >
              {showAllPhases ? '👁️ Tüm Fazlar Aktif' : 'Tek Faz'}
            </button>
          </div>

          {/* Right: Quick Action Controls (Undo, Redo, Clear, Zoom, Share) */}
          <div className="flex items-center gap-1.5 flex-wrap">
            <button
              type="button"
              onClick={handleUndo}
              disabled={currentMapCount === 0}
              title="Geri Al (Ctrl+Z)"
              className="rounded-lg h-7 px-2 bg-[#120A0D] hover:bg-[#1B0C11] disabled:opacity-35 border border-[#2A1319] text-[11px] font-bold text-[#B8AAAC] transition-colors"
            >
              ↶ Geri
            </button>
            <button
              type="button"
              onClick={handleRedo}
              disabled={redoStack.length === 0}
              title="İleri Al (Ctrl+Y)"
              className="rounded-lg h-7 px-2 bg-[#120A0D] hover:bg-[#1B0C11] disabled:opacity-35 border border-[#2A1319] text-[11px] font-bold text-[#B8AAAC] transition-colors"
            >
              ↷ İleri
            </button>
            <button
              type="button"
              onClick={handleClear}
              disabled={currentMapCount === 0}
              title="Bu haritadaki tüm çizimleri sil"
              className="rounded-lg h-7 px-2.5 bg-[#190B10] hover:bg-[#7A121D]/40 disabled:opacity-35 border border-[#7A121D]/55 text-[11px] font-bold text-[#F08C96] transition-colors"
            >
              <IconTrash size={11} className="inline mr-1" />
              Temizle ({currentMapCount})
            </button>

            {/* Zoom Controls */}
            <div className="flex items-center gap-1 bg-[#120A0D] px-2 py-0.5 rounded-lg border border-[#2A1319]">
              <button
                type="button"
                onClick={() => setZoomScale((z) => Math.max(0.6, z - 0.15))}
                title="Uzaklaştır"
                className="text-[#9E8E91] hover:text-[#FAF2EE] text-xs px-1 font-bold"
              >
                -
              </button>
              <button
                type="button"
                onClick={handleResetZoomPan}
                title="Ölçeği Sıfırla (%100)"
                className="text-[10px] font-mono font-bold text-[#F08C96] hover:text-[#FAF2EE] px-1"
              >
                {Math.round(zoomScale * 100)}%
              </button>
              <button
                type="button"
                onClick={() => setZoomScale((z) => Math.min(2.5, z + 0.15))}
                title="Yakınlaştır"
                className="text-[#9E8E91] hover:text-[#FAF2EE] text-xs px-1 font-bold"
              >
                +
              </button>
            </div>

            <button
              type="button"
              onClick={() => void handleShareBriefToChat()}
              className="crimson-cta rounded-lg h-7 px-3 text-[11px] font-bold text-[#F4EFF0] flex items-center gap-1.5 shadow-sm active:scale-95"
            >
              <IconSend size={11} />
              <span>Brifing Gönder</span>
            </button>
          </div>
        </div>

        {/* ── Precision Esports Tactical Toolbar ── */}
        <div className="px-4 py-2 bg-[#080406] border-b border-[#200D12] flex flex-wrap items-center justify-between gap-2 flex-shrink-0">
          <div className="flex items-center gap-2 flex-wrap">
            {/* Group 1: Numbered Strategy Pins & Sequence (Reference Image 4) */}
            <div className="flex items-center gap-1 bg-[#120A0D] p-1 rounded-xl border border-[#2E1218]">
              <span className="text-[9.5px] font-black text-[#8E7E81] uppercase px-1">PİNLER:</span>
              <button
                type="button"
                onClick={() => setTool('pin-blue')}
                title="Mavi Takım Numaralı Pin (1-5)"
                className={`rounded-lg px-2 h-6 text-[11px] font-black flex items-center gap-1 transition-all ${
                  tool === 'pin-blue'
                    ? 'bg-blue-600 text-white shadow-xs'
                    : 'text-blue-400/80 hover:bg-blue-950/40 hover:text-blue-300'
                }`}
              >
                <span className="w-4 h-4 rounded-full bg-blue-500 text-white text-[10px] flex items-center justify-center font-bold">
                  {selectedPinNumber}
                </span>
                <span>Dost</span>
              </button>

              <button
                type="button"
                onClick={() => setTool('pin-red')}
                title="Kırmızı Takım Numaralı Pin (1-5)"
                className={`rounded-lg px-2 h-6 text-[11px] font-black flex items-center gap-1 transition-all ${
                  tool === 'pin-red'
                    ? 'bg-red-600 text-white shadow-xs'
                    : 'text-red-400/80 hover:bg-red-950/40 hover:text-red-300'
                }`}
              >
                <span className="w-4 h-4 rounded-full bg-red-600 text-white text-[10px] flex items-center justify-center font-bold">
                  {selectedPinNumber}
                </span>
                <span>Düşman</span>
              </button>

              {/* Number Selector 1..5 */}
              <div className="flex items-center gap-0.5 ml-0.5">
                {([1, 2, 3, 4, 5] as const).map((n) => (
                  <button
                    key={n}
                    type="button"
                    onClick={() => setSelectedPinNumber(n)}
                    className={`w-4 h-5 rounded text-[10px] font-black transition-colors ${
                      selectedPinNumber === n
                        ? 'bg-[#FAF2EE] text-black'
                        : 'text-[#8E7E81] hover:text-[#FAF2EE]'
                    }`}
                  >
                    {n}
                  </button>
                ))}
              </div>

              <span className="w-px h-4 bg-[#2A1319] mx-1" />

              {/* Auto Sequence Pathing Tool (Dignitas LoL 1 -> 2 -> 3 -> 4...) */}
              <button
                type="button"
                onClick={() => setTool('seq-path')}
                title="Numaralı Rota Dizilimi (Tıkladıkça 1 -> 2 -> 3 -> 4... otomatik artan rotalar çizer)"
                className={`rounded-lg px-2 h-6 text-[11px] font-black flex items-center gap-1.5 transition-all ${
                  tool === 'seq-path'
                    ? 'bg-sky-500 text-slate-950 shadow-xs'
                    : 'text-sky-400 hover:bg-sky-950/40 hover:text-sky-300'
                }`}
              >
                <span className="w-4 h-4 rounded-full bg-sky-200 text-sky-900 text-[10px] flex items-center justify-center font-bold">
                  {seqCounter}
                </span>
                <span>Rota #{seqCounter}</span>
              </button>

              {seqCounter > 1 && (
                <button
                  type="button"
                  onClick={handleResetSequence}
                  title="Rota sayacını 1'e sıfırla (Yeni rota başlat)"
                  className="text-[9.5px] font-bold text-[#F08C96] hover:text-[#FAF2EE] px-1"
                >
                  Sıfırla
                </button>
              )}
            </div>

            {/* Group 2: Tactical Utility & Ability Stamps */}
            <div className="flex items-center gap-0.5 bg-[#120A0D] p-1 rounded-xl border border-[#2E1218]">
              <span className="text-[9.5px] font-black text-[#8E7E81] uppercase px-1">EKİPMAN:</span>
              {[
                { id: 'smoke', label: 'Smoke', icon: '⭕' },
                { id: 'flash', label: 'Flash', icon: '⚡' },
                { id: 'molly', label: 'Molly', icon: '🔥' },
                { id: 'ward', label: 'Totem', icon: '👁️' },
                { id: 'danger', label: 'Tehlike', icon: '⚠️' },
                { id: 'spike', label: 'Spike', icon: '💣' },
              ].map((st) => (
                <button
                  key={st.id}
                  type="button"
                  onClick={() => setTool(st.id as StratTool)}
                  title={`${st.label} Damgası`}
                  className={`h-6 px-1.5 rounded-lg text-xs flex items-center gap-1 transition-colors ${
                    tool === st.id
                      ? 'bg-[#8F1622] text-white shadow-xs'
                      : 'text-[#9E8E91] hover:text-[#FAF2EE] hover:bg-[#200A11]'
                  }`}
                >
                  <span>{st.icon}</span>
                  <span className="text-[10px] font-bold hidden sm:inline">{st.label}</span>
                </button>
              ))}
            </div>

            {/* Group 3: Core Drawing Tools */}
            <div className="flex items-center gap-0.5 bg-[#120A0D] p-1 rounded-xl border border-[#2E1218]">
              <span className="text-[9.5px] font-black text-[#8E7E81] uppercase px-1">ÇİZİM:</span>
              {[
                { id: 'arrow', label: 'Saldırı Oku', icon: '➡️' },
                { id: 'dashed-arrow', label: 'Rotasyon', icon: '⇢' },
                { id: 'pen', label: 'Kalem', icon: '✏️' },
                { id: 'zone-circle', label: 'Alan ◯', icon: '◯' },
                { id: 'zone-box', label: 'Bölge ▢', icon: '▢' },
                { id: 'text', label: 'Not', icon: '💬' },
                { id: 'eraser', label: 'Silgi', icon: '🧹' },
                { id: 'pan', label: 'Taşı (Pan)', icon: '✋' },
              ].map((dt) => (
                <button
                  key={dt.id}
                  type="button"
                  onClick={() => setTool(dt.id as StratTool)}
                  title={dt.label}
                  className={`h-6 px-1.5 rounded-lg text-xs flex items-center gap-1 transition-colors ${
                    tool === dt.id
                      ? 'bg-[#C82333] text-white shadow-xs'
                      : 'text-[#9E8E91] hover:text-[#FAF2EE] hover:bg-[#200A11]'
                  }`}
                >
                  <span>{dt.icon}</span>
                  <span className="text-[10px] font-bold hidden md:inline">{dt.label}</span>
                </button>
              ))}
            </div>
          </div>

          {/* Color Swatches & Stroke Width */}
          <div className="flex items-center gap-2">
            {/* Stroke Width Selector */}
            <div className="flex items-center gap-1 bg-[#120A0D] px-1.5 py-1 rounded-lg border border-[#2A1319]">
              {([2, 4, 7] as const).map((w) => (
                <button
                  key={w}
                  type="button"
                  onClick={() => setLineWidth(w)}
                  title={`Çizgi Kalınlığı: ${w === 2 ? 'İnce' : w === 4 ? 'Orta' : 'Kalın'}`}
                  className={`w-4 h-4 rounded flex items-center justify-center transition-colors ${
                    lineWidth === w ? 'bg-[#8F1622] text-white' : 'text-[#8E7E81] hover:text-[#FAF2EE]'
                  }`}
                >
                  <span
                    className="rounded-full bg-current"
                    style={{ width: `${w * 1.5}px`, height: `${w * 1.5}px` }}
                  />
                </button>
              ))}
            </div>

            {/* Ink Swatches */}
            <div className="flex items-center gap-1.5 bg-[#120A0D] px-2 py-1 rounded-lg border border-[#2A1319]">
              {INK_SWATCHES.map((sw) => (
                <button
                  key={sw.hex}
                  type="button"
                  onClick={() => setInkColor(sw.hex)}
                  title={sw.label}
                  className={`w-4 h-4 rounded-full transition-transform flex items-center justify-center ${
                    inkColor === sw.hex
                      ? 'ring-2 ring-[#C82333] scale-110 shadow-xs'
                      : 'hover:scale-105 opacity-80 hover:opacity-100'
                  }`}
                  style={{ background: sw.hex }}
                />
              ))}
            </div>
          </div>
        </div>

        {/* ── Dual-Layer Tactical Blueprint Canvas & Viewport ── */}
        <div
          className="flex-1 min-h-0 p-3 sm:p-4 bg-[#050304] flex items-center justify-center overflow-hidden cursor-crosshair select-none relative"
          onWheel={handleWheelZoom}
        >
          <div
            style={{
              transform: `translate(${panOffset.x}px, ${panOffset.y}px) scale(${zoomScale})`,
              transformOrigin: 'center center',
              transition: isPanningRef.current ? 'none' : 'transform 0.05s ease-out',
            }}
            className="relative w-full max-w-[840px] aspect-[840/480] rounded-xl overflow-hidden border border-[#2E151C] shadow-[0_20px_60px_rgba(0,0,0,0.95)] touch-none flex-shrink-0"
          >
            {/* Background Blueprint Layer (0 FPS idle) */}
            <canvas
              ref={bgCanvasRef}
              width={LOGICAL_W}
              height={LOGICAL_H}
              className="absolute inset-0 w-full h-full pointer-events-none"
            />
            {/* Foreground Interactive Strat Layer */}
            <canvas
              ref={fgCanvasRef}
              width={LOGICAL_W}
              height={LOGICAL_H}
              onPointerDown={handlePointerDown}
              onPointerMove={handlePointerMove}
              onPointerUp={finalizeDraft}
              onPointerCancel={finalizeDraft}
              className={`absolute inset-0 w-full h-full ${
                tool === 'pan' ? 'cursor-grab active:cursor-grabbing' : 'cursor-crosshair'
              }`}
            />
          </div>

          {/* Quick Info Pill at Bottom Left */}
          <div className="absolute bottom-5 left-6 pointer-events-none bg-black/60 backdrop-blur-md px-2.5 py-1 rounded-lg border border-white/10 text-[10px] text-[#A8989B] flex items-center gap-2">
            <span>🖱️ Tekerlek: Zoom</span>
            <span>•</span>
            <span>✋ Space/Alt: Kaydır</span>
            <span>•</span>
            <span>⌨️ Ctrl+Z / Y</span>
          </div>
        </div>

        {/* ── Modal: Custom Map Direct URL Input ── */}
        {showUrlModal && (
          <div
            className="fixed inset-0 z-60 flex items-center justify-center bg-black/75 p-4"
            onClick={() => setShowUrlModal(false)}
          >
            <div
              onClick={(e) => e.stopPropagation()}
              className="w-full max-w-md bg-[#12080B] border border-[#8F1622] rounded-2xl p-5 shadow-2xl"
            >
              <h3 className="text-sm font-extrabold text-[#FAF2EE] mb-1">
                Web Bağlantısından Harita Yükle
              </h3>
              <p className="text-xs text-[#A8989B] mb-3">
                Doğrudan görsel bağlantısını (.png, .jpg) yapıştırın:
              </p>
              <form onSubmit={handleCustomUrlSubmit}>
                <input
                  type="url"
                  placeholder="https://example.com/map.jpg"
                  value={urlInput}
                  onChange={(e) => setUrlInput(e.target.value)}
                  autoFocus
                  className="w-full px-3 py-2 bg-[#090406] border border-[#2E1218] rounded-xl text-xs text-[#FAF2EE] focus:outline-none focus:border-[#C82333] mb-4"
                />
                <div className="flex justify-end gap-2">
                  <button
                    type="button"
                    onClick={() => setShowUrlModal(false)}
                    className="px-3 py-1.5 rounded-xl text-xs font-bold text-[#A8989B] hover:text-[#FAF2EE] bg-[#180A0E]"
                  >
                    Vazgeç
                  </button>
                  <button
                    type="submit"
                    className="crimson-cta px-4 py-1.5 rounded-xl text-xs font-bold text-white shadow-sm"
                  >
                    Yükle ve Uygula
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}

        {/* ── Modal: Callout Text Input ── */}
        {showTextModal && (
          <div
            className="fixed inset-0 z-60 flex items-center justify-center bg-black/75 p-4"
            onClick={() => setShowTextModal(false)}
          >
            <div
              onClick={(e) => e.stopPropagation()}
              className="w-full max-w-md bg-[#12080B] border border-[#8F1622] rounded-2xl p-5 shadow-2xl"
            >
              <h3 className="text-sm font-extrabold text-[#FAF2EE] mb-1">
                Taktik Notu Ekle
              </h3>
              <p className="text-xs text-[#A8989B] mb-3">
                Harita üzerine bırakılacak espor callout notu (Örn: 01:30 Baron Kontrol, B Fake):
              </p>
              <form onSubmit={handleTextModalSubmit}>
                <input
                  type="text"
                  placeholder="Örn: 01:30 Baron Kontrol, B Fake..."
                  value={textInput}
                  onChange={(e) => setTextInput(e.target.value)}
                  autoFocus
                  className="w-full px-3 py-2 bg-[#090406] border border-[#2E1218] rounded-xl text-xs text-[#FAF2EE] focus:outline-none focus:border-[#C82333] mb-4"
                />
                <div className="flex justify-end gap-2">
                  <button
                    type="button"
                    onClick={() => setShowTextModal(false)}
                    className="px-3 py-1.5 rounded-xl text-xs font-bold text-[#A8989B] hover:text-[#FAF2EE] bg-[#180A0E]"
                  >
                    İptal
                  </button>
                  <button
                    type="submit"
                    className="crimson-cta px-4 py-1.5 rounded-xl text-xs font-bold text-white shadow-sm flex items-center gap-1"
                  >
                    <IconCheck size={12} />
                    <span>Haritaya Ekle</span>
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}
      </div>
    </div>
  );
});

// Re-export as TacticalStratDrawer for seamless backwards compatibility
export const TacticalStratDrawer = TacticalMapBoard;
