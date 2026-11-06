'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Industrial Operator Telemetry Drawer
// ─────────────────────────────────────────────────────────

import { memo, useState } from 'react';
import { useAppStore } from '@/lib/store';
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

export const TacticalPlayerHUD = memo(function TacticalPlayerHUD({
  player,
  onClose,
}: TacticalPlayerHUDProps) {
  const [gain, setGain] = useState(100);
  const [localMuted, setLocalMuted] = useState(false);
  const setActiveDMUser = useAppStore((s) => s.setActiveDMUser);

  if (!player) return null;

  return (
    <div
      className="fixed inset-0 z-50 flex justify-end bg-black/75"
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
              <span className="font-mono text-xs font-bold uppercase tracking-[0.18em] text-gl-text-bright">
                OPERATÖR TELEMETRİSİ
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
              <p className="text-[11px] font-mono text-gl-text-muted mt-0.5">
                {player.activity ?? 'Hazır Kıta'}
              </p>
            </div>
          </div>

          {/* ── Network Readout ── */}
          <div className="grid grid-cols-3 gap-2 font-mono text-center">
            <div className="rounded-sm p-3 bg-[#0C0E12] border border-white/[0.05]">
              <span className="text-[9px] text-gl-text-muted block">RTT</span>
              <span className="text-sm font-bold text-[#F59E0B] mt-1 block">
                14 ms
              </span>
            </div>
            <div className="rounded-sm p-3 bg-[#0C0E12] border border-white/[0.05]">
              <span className="text-[9px] text-gl-text-muted block">KAYIP</span>
              <span className="text-sm font-bold text-gl-text-bright mt-1 block">
                0.0%
              </span>
            </div>
            <div className="rounded-sm p-3 bg-[#0C0E12] border border-white/[0.05]">
              <span className="text-[9px] text-gl-text-muted block">JITTER</span>
              <span className="text-sm font-bold text-gl-text-bright mt-1 block">
                1.8 ms
              </span>
            </div>
          </div>

          {/* ── Audio Gain & Actions ── */}
          <div className="rounded-sm p-4 bg-[#0C0E12] border border-white/[0.06] space-y-4">
            <div className="flex items-center justify-between font-mono text-xs">
              <span className="font-bold text-gl-text-normal">SES KAZANCI</span>
              <span className="font-bold text-gl-accent">
                {localMuted ? '0%' : `${gain}%`}
              </span>
            </div>

            <input
              type="range"
              min={0}
              max={200}
              step={5}
              value={localMuted ? 0 : gain}
              onChange={(e) => {
                setLocalMuted(false);
                setGain(Number(e.target.value));
              }}
              className="w-full accent-[var(--ghost-accent)] cursor-pointer h-1.5"
            />

            <div className="grid grid-cols-2 gap-2 pt-1">
              <button
                onClick={() => setLocalMuted((v) => !v)}
                className={`rounded-sm min-h-[42px] font-mono text-[11px] font-bold border flex items-center justify-center gap-2 transition-colors ${
                  localMuted
                    ? 'bg-gl-danger/15 text-gl-danger border-gl-danger/50'
                    : 'bg-[#050608] text-gl-text-bright border-white/[0.08]'
                }`}
              >
                {localMuted ? <IconMicOff size={14} /> : <IconMic size={14} />}
                <span>{localMuted ? 'SESİ AÇ' : 'SUSTUR'}</span>
              </button>

              <button
                onClick={() => {
                  setActiveDMUser(player.id);
                  onClose();
                }}
                className="rounded-sm min-h-[42px] font-mono text-[11px] font-bold bg-gl-accent hover:bg-gl-accent-hover text-white flex items-center justify-center gap-2 transition-colors"
              >
                <IconMessage size={14} />
                <span>1V1 HAT</span>
              </button>
            </div>
          </div>
        </div>

        <div className="pt-4 border-t border-white/[0.05] flex items-center justify-between text-[10px] font-mono text-gl-text-muted">
          <span className="flex items-center gap-1.5">
            <IconShield size={12} className="text-gl-accent" />
            <span>DTLS-SRTP P2P</span>
          </span>
          <span>OPUS 48KHZ</span>
        </div>
      </aside>
    </div>
  );
});
