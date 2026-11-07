'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Interactive Tactical Strat Canvas & P2P Sync
// ─────────────────────────────────────────────────────────
// Dual-layer zero-re-rasterization HTML5 Canvas architecture:
//   • Layer 1 (bgCanvas): Static architectural radar blueprint for
//     Ascent, Bind, Mirage, and Inferno — rendered ONLY on map change.
//   • Layer 2 (fgCanvas): rAF-coalesced tactical overlay (Smoke spheres,
//     Pop-Flash bursts, Rotation Arrows, Decimated Freehand Pen).
//   • Real-time E2EE P2P sync via MevaCryptoEngine ('strat-op' over
//     RTCDataChannel + BroadcastChannel).

import { memo, useCallback, useEffect, useRef, useState } from 'react';
import { useVoiceSettingsStore } from '@/store/useVoiceSettingsStore';
import { useAppStore } from '@/lib/store';
import { getMevaCryptoEngine } from '@/src/lib/cryptoEngine';
import { getMevaWebRTCMesh } from '@/src/lib/webrtcMesh';
import { useRealtimeChat } from '@/hooks/useRealtimeChat';
import {
  IconClose,
  IconMapBoard,
  IconSend,
  IconShield,
} from '@/components/ui/MevaIcons';

export type TacticalMapId = 'ascent' | 'bind' | 'mirage' | 'inferno';
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
  | { action: 'switch-map'; mapId: TacticalMapId };

interface MapZone {
  label: string;
  x: number;
  y: number;
  w: number;
  h: number;
  isSite?: boolean;
}

const LOGICAL_W = 840;
const LOGICAL_H = 480;

const MAP_BLUEPRINTS: Record<
  TacticalMapId,
  { title: string; game: 'VALORANT' | 'CS2'; zones: MapZone[] }
> = {
  ascent: {
    title: 'Ascent',
    game: 'VALORANT',
    zones: [
      { label: 'A SITE', x: 585, y: 58, w: 175, h: 125, isSite: true },
      { label: 'A HEAVEN', x: 620, y: 20, w: 120, h: 36 },
      { label: 'A MAIN', x: 585, y: 205, w: 135, h: 95 },
      { label: 'TREE', x: 470, y: 125, w: 95, h: 80 },
      { label: 'MID COURTYARD', x: 335, y: 175, w: 155, h: 135 },
      { label: 'CATWALK', x: 470, y: 220, w: 100, h: 55 },
      { label: 'MARKET', x: 220, y: 150, w: 100, h: 85 },
      { label: 'B SITE', x: 75, y: 62, w: 165, h: 125, isSite: true },
      { label: 'B MAIN', x: 95, y: 210, w: 115, h: 105 },
      { label: 'DEFENDER SPAWN', x: 330, y: 36, w: 175, h: 62 },
      { label: 'ATTACKER SPAWN', x: 315, y: 382, w: 205, h: 64 },
    ],
  },
  bind: {
    title: 'Bind',
    game: 'VALORANT',
    zones: [
      { label: 'A SITE', x: 555, y: 78, w: 195, h: 135, isSite: true },
      { label: 'SHOWERS', x: 650, y: 235, w: 110, h: 95 },
      { label: 'A SHORT', x: 455, y: 225, w: 165, h: 80 },
      { label: 'LAMPS / U-HALL', x: 465, y: 95, w: 80, h: 105 },
      { label: 'HOOKAH', x: 245, y: 195, w: 115, h: 85 },
      { label: 'B SITE', x: 80, y: 72, w: 175, h: 135, isSite: true },
      { label: 'B LONG', x: 70, y: 230, w: 135, h: 110 },
      { label: 'TP PORTAL', x: 355, y: 135, w: 90, h: 52 },
      { label: 'DEFENDER SPAWN', x: 315, y: 32, w: 185, h: 55 },
      { label: 'ATTACKER SPAWN', x: 295, y: 385, w: 235, h: 60 },
    ],
  },
  mirage: {
    title: 'Mirage',
    game: 'CS2',
    zones: [
      { label: 'A SITE', x: 560, y: 265, w: 190, h: 135, isSite: true },
      { label: 'PALACE', x: 645, y: 398, w: 125, h: 52 },
      { label: 'A RAMP', x: 555, y: 398, w: 82, h: 52 },
      { label: 'CONNECTOR', x: 425, y: 245, w: 105, h: 90 },
      { label: 'MID / WINDOW', x: 315, y: 190, w: 155, h: 95 },
      { label: 'UNDERPASS', x: 265, y: 130, w: 95, h: 55 },
      { label: 'B SITE', x: 85, y: 58, w: 175, h: 125, isSite: true },
      { label: 'APARTMENTS', x: 270, y: 65, w: 175, h: 55 },
      { label: 'CT SPAWN', x: 365, y: 335, w: 155, h: 65 },
      { label: 'T SPAWN', x: 645, y: 95, w: 125, h: 95 },
    ],
  },
  inferno: {
    title: 'Inferno',
    game: 'CS2',
    zones: [
      { label: 'B SITE', x: 145, y: 48, w: 185, h: 115, isSite: true },
      { label: 'BANANA', x: 185, y: 180, w: 95, h: 155 },
      { label: 'CT CONSTRUCTION', x: 350, y: 55, w: 155, h: 75 },
      { label: 'MID', x: 335, y: 255, w: 155, h: 85 },
      { label: 'ARCH / LIBRARY', x: 505, y: 125, w: 135, h: 95 },
      { label: 'A SITE', x: 560, y: 245, w: 185, h: 125, isSite: true },
      { label: 'APARTMENTS / PIT', x: 615, y: 380, w: 155, h: 65 },
      { label: 'T RAMP', x: 125, y: 365, w: 185, h: 72 },
    ],
  },
};

const INK_SWATCHES = [
  { hex: '#C82333', label: 'Saldırı' },
  { hex: '#F08C96', label: 'Destek' },
  { hex: '#F4EFF0', label: 'Komuta' },
] as const;

function drawBlueprintLayer(ctx: CanvasRenderingContext2D, mapId: TacticalMapId) {
  ctx.clearRect(0, 0, LOGICAL_W, LOGICAL_H);

  // Matte espresso-obsidian backdrop
  const bg = ctx.createLinearGradient(0, 0, LOGICAL_W, LOGICAL_H);
  bg.addColorStop(0, '#080607');
  bg.addColorStop(0.5, '#12080C');
  bg.addColorStop(1, '#080607');
  ctx.fillStyle = bg;
  ctx.fillRect(0, 0, LOGICAL_W, LOGICAL_H);

  // Tactical 60px coordinate grid
  ctx.strokeStyle = 'rgba(148, 26, 40, 0.11)';
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

  // Grid coordinate indices
  ctx.fillStyle = 'rgba(184, 170, 172, 0.32)';
  ctx.font = '700 9px monospace';
  const cols = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M'];
  cols.forEach((c, idx) => {
    ctx.fillText(c, idx * 60 + 26, 14);
  });

  const spec = MAP_BLUEPRINTS[mapId];

  // Connecting tactical lanes (subtle dashed)
  ctx.save();
  ctx.setLineDash([5, 5]);
  ctx.strokeStyle = 'rgba(200, 35, 51, 0.20)';
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

  // Architectural zones & bombsites
  for (const z of spec.zones) {
    ctx.save();
    ctx.beginPath();
    ctx.roundRect(z.x, z.y, z.w, z.h, 8);
    ctx.fillStyle = z.isSite
      ? 'rgba(143, 22, 34, 0.22)'
      : 'rgba(22, 11, 15, 0.86)';
    ctx.fill();
    ctx.lineWidth = z.isSite ? 1.75 : 1.15;
    ctx.strokeStyle = z.isSite
      ? 'rgba(200, 35, 51, 0.68)'
      : 'rgba(136, 26, 38, 0.34)';
    ctx.stroke();

    if (z.isSite) {
      // Plant radius indicator
      ctx.beginPath();
      ctx.arc(z.x + z.w / 2, z.y + z.h / 2 + 8, 22, 0, Math.PI * 2);
      ctx.setLineDash([4, 3]);
      ctx.strokeStyle = 'rgba(240, 140, 150, 0.35)';
      ctx.stroke();
      ctx.setLineDash([]);
    }

    ctx.fillStyle = z.isSite ? '#F4EFF0' : '#B8AAAC';
    ctx.font = z.isSite ? '800 11px sans-serif' : '700 9.5px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText(z.label, z.x + z.w / 2, z.y + 18);
    ctx.restore();
  }
}

function renderSingleOp(ctx: CanvasRenderingContext2D, op: StratOperation) {
  if (op.points.length === 0) return;
  ctx.save();
  const start = op.points[0];
  const end = op.points[op.points.length - 1];

  if (op.tool === 'smoke') {
    const rad = 30;
    const grad = ctx.createRadialGradient(
      end.x,
      end.y,
      4,
      end.x,
      end.y,
      rad,
    );
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
    // 8-ray tactical flash burst
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

export const TacticalStratDrawer = memo(function TacticalStratDrawer() {
  const open = useVoiceSettingsStore((s) => s.showStratBoard);
  const setOpen = useVoiceSettingsStore((s) => s.setShowStratBoard);
  const activeChannelId = useAppStore((s) => s.activeChannelId);
  const { sendMessage } = useRealtimeChat(activeChannelId);

  const [mapId, setMapId] = useState<TacticalMapId>('ascent');
  const [tool, setTool] = useState<StratTool>('arrow');
  const [inkColor, setInkColor] = useState<string>('#C82333');
  const [ops, setOps] = useState<StratOperation[]>([]);
  const [syncedPackets, setSyncedPackets] = useState(0);

  const bgCanvasRef = useRef<HTMLCanvasElement | null>(null);
  const fgCanvasRef = useRef<HTMLCanvasElement | null>(null);
  const draftOpRef = useRef<StratOperation | null>(null);
  const opsRef = useRef<StratOperation[]>([]);
  const rafIdRef = useRef<number | null>(null);

  opsRef.current = ops;

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

  // Paint static architectural blueprint ONLY when drawer opens or mapId changes
  useEffect(() => {
    if (!open) return;
    const bg = bgCanvasRef.current;
    if (bg) {
      const ctx = bg.getContext('2d');
      if (ctx) drawBlueprintLayer(ctx, mapId);
    }
    scheduleOverlayPaint();
  }, [open, mapId, scheduleOverlayPaint]);

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
    } catch {
      // Local canvas state remains authoritative
    }
  }, []);

  // Listen to real-time E2EE P2P strat packets across the 5-operator mesh
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

  const handleSwitchMap = (next: TacticalMapId) => {
    setMapId(next);
    void broadcastStratPacket({ action: 'switch-map', mapId: next });
  };

  const handleShareBriefToChat = async () => {
    const mapOps = ops.filter((o) => o.mapId === mapId);
    const smokes = mapOps.filter((o) => o.tool === 'smoke').length;
    const flashes = mapOps.filter((o) => o.tool === 'flash').length;
    const arrows = mapOps.filter((o) => o.tool === 'arrow').length;
    const title = MAP_BLUEPRINTS[mapId].title.toUpperCase();
    await sendMessage(
      `[TAKTİK TAHTASI · ${title}] IGL çizimi P2P senkronize edildi (${smokes} Smoke, ${flashes} Flash, ${arrows} Rotasyon Oku). Taktik tahtasını (B) açarak inceleyin.`,
    );
  };

  const currentMapCount = ops.filter((o) => o.mapId === mapId).length;

  if (!open) return null;

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center exec-backdrop p-2.5 sm:p-5 font-sans tabular-nums"
      onClick={() => setOpen(false)}
    >
      <div
        onClick={(e) => e.stopPropagation()}
        className="w-full max-w-4xl max-h-[92dvh] rounded-2xl exec-modal flex flex-col overflow-hidden"
      >
        {/* Top Bar */}
        <div className="px-4 py-3 border-b border-[#2A1319] flex flex-wrap items-center justify-between gap-2.5 flex-shrink-0">
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-xl crimson-cta flex items-center justify-center text-[#F4EFF0]">
              <IconMapBoard size={16} />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h2 className="text-sm font-extrabold text-[#F4EFF0]">
                  Taktiksel Harita & Çizim Tahtası
                </h2>
                <span className="rounded-md px-2 py-0.5 bg-[#180B10] border border-[#7A121D]/45 text-[10px] font-bold text-[#F08C96] flex items-center gap-1">
                  <IconShield size={11} />
                  <span>E2EE DataChannel Canlı Senkron ({syncedPackets})</span>
                </span>
              </div>
              <p className="text-[11px] text-[#8E7F83]">
                Çizimleriniz AES-256-GCM ile şifrelenerek diğer 4 operatörün
                ekranında anında belirir.
              </p>
            </div>
          </div>

          {/* Map Selector */}
          <div className="flex items-center gap-1.5">
            {(Object.keys(MAP_BLUEPRINTS) as TacticalMapId[]).map((mKey) => (
              <button
                key={mKey}
                type="button"
                onClick={() => handleSwitchMap(mKey)}
                className={`rounded-lg h-8 px-2.5 text-[11px] font-extrabold border transition-all ${
                  mapId === mKey
                    ? 'crimson-cta text-[#F4EFF0]'
                    : 'bg-[#120A0D] hover:bg-[#1C0D12] text-[#B8AAAC] border-[#2A1319]'
                }`}
              >
                {MAP_BLUEPRINTS[mKey].title}
              </button>
            ))}
            <button
              type="button"
              onClick={() => setOpen(false)}
              aria-label="Kapat"
              className="rounded-xl w-8 h-8 ml-1 flex items-center justify-center bg-[#140A0D] hover:bg-[#220D13] border border-[#2C141A] text-[#9E8E91] hover:text-[#F4EFF0]"
            >
              <IconClose size={15} />
            </button>
          </div>
        </div>

        {/* Tactical Tool Strip */}
        <div className="px-4 py-2 bg-[#0B0709]/90 border-b border-[#241116] flex flex-wrap items-center justify-between gap-2 flex-shrink-0">
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
                onClick={() => setTool(t.id)}
                className={`rounded-lg h-8 px-3 text-[11px] font-bold border transition-all ${
                  tool === t.id
                    ? 'bg-[#8F1622]/40 text-[#F4EFF0] border-[#C82333]/65'
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
                onClick={() => setInkColor(sw.hex)}
                title={sw.label}
                className={`rounded-lg h-7 px-2 flex items-center gap-1.5 border text-[10.5px] font-bold ${
                  inkColor === sw.hex
                    ? 'bg-[#1C0C11] border-[#C82333]/65 text-[#F4EFF0]'
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
              onClick={handleUndo}
              disabled={currentMapCount === 0}
              className="rounded-lg h-8 px-2.5 bg-[#120A0D] hover:bg-[#1B0C11] disabled:opacity-40 border border-[#2A1319] text-[11px] font-bold text-[#B8AAAC]"
            >
              Geri Al
            </button>
            <button
              type="button"
              onClick={handleClear}
              disabled={currentMapCount === 0}
              className="rounded-lg h-8 px-2.5 bg-[#190B10] hover:bg-[#7A121D]/35 disabled:opacity-40 border border-[#7A121D]/45 text-[11px] font-bold text-[#F08C96]"
            >
              Temizle ({currentMapCount})
            </button>
            <button
              type="button"
              onClick={() => void handleShareBriefToChat()}
              className="crimson-cta rounded-lg h-8 px-3 text-[11px] font-bold text-[#F4EFF0] flex items-center gap-1.5"
            >
              <IconSend size={12} />
              <span>Kanala Brifing At</span>
            </button>
          </div>
        </div>

        {/* Dual-Layer Tactical Blueprint Canvas */}
        <div className="flex-1 min-h-0 p-3 sm:p-4 bg-[#070506] flex items-center justify-center overflow-hidden">
          <div className="relative w-full max-w-[840px] aspect-[840/480] rounded-xl overflow-hidden border border-[#2E151C] shadow-[0_12px_36px_rgba(0,0,0,0.85)] touch-none">
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
