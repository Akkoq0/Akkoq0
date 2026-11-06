'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Synchronized Operator Telemetry Drawer
// ─────────────────────────────────────────────────────────

import { memo } from 'react';
import { useAppStore } from '@/lib/store';
import { useHUDStore } from '@/store/useHUDStore';
import { OperatorAvatar } from '@/components/ui/HudPrimitives';
import {
  IconClose,
  IconMessage,
  IconMic,
  IconMicOff,
  IconShield,
} from '@/components/ui/MevaIcons';
import type { Profile } from '@/types';

interface TacticalPlayerHUDProps {
  player: Profile | null;
  onClose: () => void;
}

const PEER_RTT: Record<string, number> = {
  'usr-local': 9,
  'usr-1': 11,
  'usr-4': 12,
  'usr-2': 14,
  'usr-3': 13,
};

export const TacticalPlayerHUD = memo(function TacticalPlayerHUD({
  player,
  onClose,
}: TacticalPlayerHUDProps) {
  const setActiveDMUser = useAppStore((s) => s.setActiveDMUser);

  const playerGains = useHUDStore((s) => s.playerGains);
  const localMutes = useHUDStore((s) => s.localMutes);
  const spatialPans = useHUDStore((s) => s.spatialPans);
  const setPlayerGain = useHUDStore((s) => s.setPlayerGain);
  const toggleLocalMute = useHUDStore((s) => s.toggleLocalMute);
  const cycleSpatialPan = useHUDStore((s) => s.cycleSpatialPan);

  if (!player) return null;

  const gain = playerGains[player.id] ?? 100;
  const localMuted = Boolean(localMutes[player.id]) || gain === 0;
  const pan = spatialPans[player.id] ?? 'C';
  const rttMs = PEER_RTT[player.id] ?? 14;

  return (
    <div
      className="fixed inset-0 z-50 flex justify-end bg-black/75 font-sans"
      onClick={onClose}
    >
      <aside
        className="w-full max-w-sm h-full bg-[#080A0E] border-l border-white/[0.08] p-5 flex flex-col justify-between overflow-y-auto shadow-2xl"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="space-y-5">
          {/* ── Top Header ── */}
          <div className="flex items-center justify-between border-b border-white/[0.06] pb-3.5">
            <div className="flex items-center gap-2">
              <span className="w-1.5 h-3.5 rounded-[1px] bg-gl-accent" />
              <span className="font-sans text-xs font-bold uppercase tracking-wider text-gl-text-bright">
                Operatör Telemetrisi
              </span>
            </div>
            <button
              onClick={onClose}
              className="rounded-sm w-9 h-9 bg-[#0C0E12] border border-white/[0.06] flex items-center justify-center text-gl-text-normal hover:text-gl-text-bright"
              aria-label="Kapat"
            >
              <IconClose size={16} />
            </button>
          </div>

          {/* ── Identity Module ── */}
          <div className="rounded-sm p-4 bg-[#0C0E12] border border-white/[0.06] flex items-center gap-3.5">
            <OperatorAvatar
              name={player.username}
              status={player.status}
              size="lg"
            />
            <div className="min-w-0 flex-1">
              <h3 className="text-base font-bold text-gl-text-bright truncate">
                {player.username}
              </h3>
              <p className="text-xs text-gl-text-muted mt-0.5">
                {player.activity ?? 'Hazır Kıta'}
              </p>
            </div>
          </div>

          {/* ── Network Readout ── */}
          <div className="grid grid-cols-3 gap-2 text-center">
            <div className="rounded-sm p-3 bg-[#0C0E12] border border-white/[0.05]">
              <span className="text-[10px] font-semibold text-gl-text-muted block">
                RTT
              </span>
              <span className="text-sm font-mono font-bold text-[#F59E0B] mt-1 block">
                {rttMs} ms
              </span>
            </div>
            <div className="rounded-sm p-3 bg-[#0C0E12] border border-white/[0.05]">
              <span className="text-[10px] font-semibold text-gl-text-muted block">
                KAYIP
              </span>
              <span className="text-sm font-mono font-bold text-[#10B981] mt-1 block">
                0.0%
              </span>
            </div>
            <div className="rounded-sm p-3 bg-[#0C0E12] border border-white/[0.05]">
              <span className="text-[10px] font-semibold text-gl-text-muted block">
                JITTER
              </span>
              <span className="text-sm font-mono font-bold text-gl-text-bright mt-1 block">
                0.2 ms
              </span>
            </div>
          </div>

          {/* ── Audio Gain, 3D Spatial & Actions ── */}
          <div className="rounded-sm p-4 bg-[#0C0E12] border border-white/[0.06] space-y-4">
            <div className="flex items-center justify-between text-xs">
              <span className="font-semibold text-gl-text-normal">
                Ses Kazancı (Gain)
              </span>
              <span className="font-mono font-bold text-gl-accent">
                {localMuted ? '%0' : `%${gain}`}
              </span>
            </div>

            <input
              type="range"
              min={0}
              max={200}
              step={5}
              value={localMuted ? 0 : gain}
              onChange={(e) => setPlayerGain(player.id, Number(e.target.value))}
              className="w-full accent-[var(--ghost-accent)] cursor-pointer h-1.5"
            />

            <div className="flex items-center justify-between pt-1 text-xs border-t border-white/[0.05]">
              <span className="text-gl-text-muted font-medium">
                3D Konumsal Ses Yönü
              </span>
              <button
                type="button"
                onClick={() => cycleSpatialPan(player.id)}
                className="rounded-sm px-2.5 py-1 bg-[#050608] hover:bg-[#12151E] border border-white/[0.08] font-mono text-[11px] font-bold text-[#F59E0B]"
              >
                3D:{pan} ({pan === 'L' ? 'Sol' : pan === 'R' ? 'Sağ' : 'Merkez'})
              </button>
            </div>

            <div className="grid grid-cols-2 gap-2 pt-1">
              <button
                onClick={() => toggleLocalMute(player.id)}
                className={`rounded-sm min-h-[42px] text-xs font-bold border flex items-center justify-center gap-2 transition-colors ${
                  localMuted
                    ? 'bg-gl-danger/15 text-gl-danger border-gl-danger/50'
                    : 'bg-[#050608] text-gl-text-bright border-white/[0.08]'
                }`}
              >
                {localMuted ? <IconMicOff size={14} /> : <IconMic size={14} />}
                <span>{localMuted ? 'Sesi Aç' : 'Sustur'}</span>
              </button>

              {player.id !== 'usr-local' && (
                <button
                  onClick={() => {
                    setActiveDMUser(player.id);
                    onClose();
                  }}
                  className="rounded-sm min-h-[42px] text-xs font-bold bg-gl-accent hover:bg-gl-accent-hover text-white flex items-center justify-center gap-2 transition-colors"
                >
                  <IconMessage size={14} />
                  <span>1v1 Hat Aç</span>
                </button>
              )}
            </div>
          </div>
        </div>

        <div className="pt-4 border-t border-white/[0.05] flex items-center justify-between text-[11px] text-gl-text-muted">
          <span className="flex items-center gap-1.5 font-medium">
            <IconShield size={13} className="text-[#10B981]" />
            <span>DTLS-SRTP P2P Şifreli</span>
          </span>
          <span className="font-mono text-[10px]">Opus 48kHz</span>
        </div>
      </aside>
    </div>
  );
});
