'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Synchronized Operator Telemetry & 3D DSP Drawer
// ─────────────────────────────────────────────────────────

import { memo } from 'react';
import { useAppStore } from '@/lib/store';
import { useHUDStore, type SpatialPan } from '@/store/useHUDStore';
import type { OperatorEqProfile } from '@/src/lib/audioEngine';
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

const PAN_OPTIONS: Array<{ key: SpatialPan; label: string; hint: string }> = [
  { key: 'L', label: 'Sol · L', hint: '-100% (-1.0)' },
  { key: 'C', label: 'Merkez · C', hint: '0% (0.0)' },
  { key: 'R', label: 'Sağ · R', hint: '+100% (+1.0)' },
];

const EQ_PROFILES: Array<{
  key: OperatorEqProfile;
  label: string;
  sub: string;
}> = [
  { key: 'crisp', label: 'Keskin Tiz', sub: '+4.5dB 3.5kHz' },
  { key: 'balanced', label: 'Dengeli', sub: 'Referans EQ' },
  { key: 'warm', label: 'Tok Bas', sub: '+3.2dB 220Hz' },
];

export const TacticalPlayerHUD = memo(function TacticalPlayerHUD({
  player,
  onClose,
}: TacticalPlayerHUDProps) {
  const setActiveDMUser = useAppStore((s) => s.setActiveDMUser);
  const duoLink = useAppStore((s) => s.duoLink);
  const setDuoLinkPartner = useAppStore((s) => s.setDuoLinkPartner);
  const triggerSonarPulse = useAppStore((s) => s.triggerSonarPulse);

  const playerGains = useHUDStore((s) => s.playerGains);
  const localMutes = useHUDStore((s) => s.localMutes);
  const spatialPans = useHUDStore((s) => s.spatialPans);
  const eqProfiles = useHUDStore((s) => s.eqProfiles);
  const prioritySpeakers = useHUDStore((s) => s.prioritySpeakers);
  const operatorRoles = useHUDStore((s) => s.operatorRoles);
  const setPlayerGain = useHUDStore((s) => s.setPlayerGain);
  const toggleLocalMute = useHUDStore((s) => s.toggleLocalMute);
  const setSpatialPan = useHUDStore((s) => s.setSpatialPan);
  const setEqProfile = useHUDStore((s) => s.setEqProfile);
  const togglePrioritySpeaker = useHUDStore((s) => s.togglePrioritySpeaker);

  if (!player) return null;

  const isSelf = player.id === 'usr-local';
  const gain = playerGains[player.id] ?? 100;
  const localMuted = Boolean(localMutes[player.id]) || gain === 0;
  const activePan = spatialPans[player.id] ?? 'C';
  const activeEq = eqProfiles[player.id] ?? 'balanced';
  const isPriority = Boolean(prioritySpeakers[player.id]);
  const rttMs = PEER_RTT[player.id] ?? 12;

  return (
    <div
      className="fixed inset-0 z-50 flex justify-end exec-backdrop font-sans tabular-nums"
      onClick={onClose}
    >
      <aside
        className="w-full max-w-sm h-full exec-drawer p-5 flex flex-col justify-between overflow-y-auto"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="space-y-4">
          {/* ── Top Header ── */}
          <div className="flex items-center justify-between border-b border-[#881A26]/20 pb-3.5">
            <div className="flex items-center gap-2">
              <span className="w-1.5 h-3.5 rounded-full bg-[#C82333]" />
              <span className="text-xs font-bold tracking-wider uppercase text-[#F4EFF0]">
                Operatör DSP & Telemetri
              </span>
            </div>
            <button
              type="button"
              onClick={onClose}
              className="rounded-xl w-9 h-9 bg-[#120A0D] hover:bg-[#1B0D12] border border-[#881A26]/25 flex items-center justify-center text-[#9E8F93] hover:text-[#F4EFF0] transition-colors"
              aria-label="Kapat"
            >
              <IconClose size={16} />
            </button>
          </div>

          {/* ── Identity Module ── */}
          <div className="rounded-2xl p-4 bg-[#11090C]/90 border border-[#881A26]/25 flex items-center gap-3.5">
            <OperatorAvatar
              name={player.username}
              status={player.status}
              size="lg"
            />
            <div className="min-w-0 flex-1">
              <h3 className="text-base font-bold text-[#F4EFF0] truncate">
                {player.username}
              </h3>
              <div className="flex items-center gap-1.5 mt-0.5">
                <span className="rounded px-1.5 py-0.5 text-[10px] font-extrabold bg-[#590C15]/40 text-[#F08C96] border border-[#881A26]/40">
                  {operatorRoles[player.id] ?? player.activity ?? 'IGL'}
                </span>
                <span className="text-[11px] text-[#A5908A] font-medium truncate">
                  Taktik Operatör
                </span>
              </div>
            </div>
          </div>

          {/* ── Network Readout ── */}
          <div className="grid grid-cols-3 gap-2 text-center">
            <div className="rounded-xl p-3 bg-[#11090C]/90 border border-[#881A26]/20">
              <span className="text-[10px] font-semibold text-[#8E7F83] block">
                RTT
              </span>
              <span className="text-sm font-bold text-[#F08C96] mt-1 block">
                {rttMs} ms
              </span>
            </div>
            <div className="rounded-xl p-3 bg-[#11090C]/90 border border-[#881A26]/20">
              <span className="text-[10px] font-semibold text-[#8E7F83] block">
                Paket Kaybı
              </span>
              <span className="text-sm font-bold text-[#F4EFF0] mt-1 block">
                0.0%
              </span>
            </div>
            <div className="rounded-xl p-3 bg-[#11090C]/90 border border-[#881A26]/20">
              <span className="text-[10px] font-semibold text-[#8E7F83] block">
                Jitter
              </span>
              <span className="text-sm font-bold text-[#F4EFF0] mt-1 block">
                0.2 ms
              </span>
            </div>
          </div>

          {/* ── 3D Spatial Audio Stage (StereoPannerNode) ── */}
          {!isSelf && (
            <div className="rounded-2xl p-4 bg-[#11090C]/90 border border-[#881A26]/25 space-y-3">
              <div className="flex items-center justify-between text-xs">
                <span className="font-semibold text-[#C4B6BA]">
                  3D Konumsal Sahne
                </span>
                <span className="text-[11px] font-semibold text-[#E35D6A]">
                  StereoPanner 48kHz
                </span>
              </div>

              <div className="grid grid-cols-3 gap-1.5 p-1 rounded-xl bg-[#090608] border border-[#881A26]/20">
                {PAN_OPTIONS.map((opt) => {
                  const selected = activePan === opt.key;
                  return (
                    <button
                      key={opt.key}
                      type="button"
                      onClick={() => setSpatialPan(player.id, opt.key)}
                      className={`rounded-lg py-2 px-2 text-center transition-all ${
                        selected
                          ? 'bg-gradient-to-b from-[#6B111B]/45 to-[#1F0B10]/80 text-[#F4EFF0] border border-[#A61B29]/55'
                          : 'text-[#8E7F83] hover:text-[#F4EFF0] border border-transparent'
                      }`}
                    >
                      <span className="block text-[11px] font-bold">
                        {opt.label}
                      </span>
                      <span className="block text-[9.5px] text-[#E35D6A] mt-0.5">
                        {opt.hint}
                      </span>
                    </button>
                  );
                })}
              </div>
            </div>
          )}

          {/* ── Per-Operator Biquad EQ & Priority Ducking ── */}
          <div className="rounded-2xl p-4 bg-[#11090C]/90 border border-[#881A26]/25 space-y-3">
            <div className="flex items-center justify-between text-xs">
              <span className="font-semibold text-[#C4B6BA]">
                BiquadFilter EQ Profili
              </span>
              <span className="text-[11px] font-semibold text-[#E35D6A]">
                85Hz HPF + 3.5kHz
              </span>
            </div>

            <div className="grid grid-cols-3 gap-1.5 p-1 rounded-xl bg-[#090608] border border-[#881A26]/20">
              {EQ_PROFILES.map((eq) => {
                const selected = activeEq === eq.key;
                return (
                  <button
                    key={eq.key}
                    type="button"
                    onClick={() => setEqProfile(player.id, eq.key)}
                    className={`rounded-lg py-2 px-1.5 text-center transition-all ${
                      selected
                        ? 'bg-gradient-to-b from-[#6B111B]/45 to-[#1F0B10]/80 text-[#F4EFF0] border border-[#A61B29]/55'
                        : 'text-[#8E7F83] hover:text-[#F4EFF0] border border-transparent'
                    }`}
                  >
                    <span className="block text-[11px] font-bold">
                      {eq.label}
                    </span>
                    <span className="block text-[9px] text-[#E35D6A] mt-0.5">
                      {eq.sub}
                    </span>
                  </button>
                );
              })}
            </div>

            <button
              type="button"
              onClick={() => togglePrioritySpeaker(player.id)}
              className={`rounded-xl w-full py-2 px-3 text-xs font-bold border flex items-center justify-between transition-all ${
                isPriority
                  ? 'crimson-cta text-[#F4EFF0]'
                  : 'bg-[#090608] hover:bg-[#140A0E] text-[#B8AAAC] border-[#881A26]/25'
              }`}
            >
              <span>IGL Öncelikli Konuşmacı (Arka Plan %30 Seviyesine Düşer)</span>
              <span>{isPriority ? 'AKTİF ✓' : 'KAPALI'}</span>
            </button>
          </div>

          {/* ── Audio Gain & Actions ── */}
          <div className="rounded-2xl p-4 bg-[#11090C]/90 border border-[#881A26]/25 space-y-4">
            <div className="flex items-center justify-between text-xs">
              <span className="font-semibold text-[#C4B6BA]">
                DSP Ses Kazancı (0–200%)
              </span>
              <div className="flex items-center gap-2">
                {gain !== 100 && (
                  <button
                    type="button"
                    onClick={() => setPlayerGain(player.id, 100)}
                    className="rounded-md px-1.5 py-0.5 bg-[#090608] border border-[#881A26]/25 text-[10px] font-semibold text-[#8E7F83] hover:text-[#F4EFF0] transition-colors"
                  >
                    %100 Sıfırla
                  </button>
                )}
                <span className="font-bold text-[#F08C96]">
                  {localMuted ? '%0' : `%${gain}`}
                </span>
              </div>
            </div>

            <input
              type="range"
              min={0}
              max={200}
              step={5}
              value={localMuted ? 0 : gain}
              onChange={(e) => setPlayerGain(player.id, Number(e.target.value))}
              style={
                {
                  '--fill': `${Math.round(((localMuted ? 0 : gain) / 200) * 100)}%`,
                } as React.CSSProperties
              }
              className="exec-range w-full"
            />

            <div
              className={`grid gap-2 pt-1 ${
                isSelf ? 'grid-cols-1' : 'grid-cols-2'
              }`}
            >
              <button
                type="button"
                onClick={() => toggleLocalMute(player.id)}
                className={`rounded-xl min-h-[42px] text-xs font-bold border flex items-center justify-center gap-2 transition-colors ${
                  localMuted
                    ? 'bg-[#7A121D]/30 text-[#F08C96] border-[#A61B29]/55'
                    : 'bg-[#090608] hover:bg-[#140A0E] text-[#F4EFF0] border-[#881A26]/25'
                }`}
              >
                {localMuted ? <IconMicOff size={14} /> : <IconMic size={14} />}
                <span>{localMuted ? 'Sesi Aç' : 'Sustur'}</span>
              </button>

              {!isSelf && (
                <button
                  type="button"
                  onClick={() => {
                    setActiveDMUser(player.id);
                    onClose();
                  }}
                  className="rounded-xl min-h-[42px] text-xs font-bold crimson-cta flex items-center justify-center gap-2 transition-all"
                >
                  <IconMessage size={14} />
                  <span>1v1 Hat Aç</span>
                </button>
              )}
            </div>

            {!isSelf && (
              <div className="grid grid-cols-2 gap-2 pt-1">
                <button
                  type="button"
                  onClick={() => {
                    if (duoLink.partnerId === player.id) {
                      setDuoLinkPartner(null);
                    } else {
                      setDuoLinkPartner(player.id, player.username);
                    }
                  }}
                  className={`rounded-xl min-h-[40px] text-xs font-extrabold border flex items-center justify-center gap-1.5 transition-all ${
                    duoLink.partnerId === player.id
                      ? 'bg-cyan-950/90 text-cyan-300 border-cyan-400 shadow-[0_0_12px_rgba(6,182,212,0.4)]'
                      : 'bg-[#090608] hover:bg-cyan-950/40 text-[#9E8E91] hover:text-cyan-300 border-[#881A26]/25 hover:border-cyan-800'
                  }`}
                >
                  <span>🔗</span>
                  <span>
                    {duoLink.partnerId === player.id
                      ? 'Duo-Link Kopar'
                      : 'Duo-Link (B)'}
                  </span>
                </button>

                <button
                  type="button"
                  onClick={() =>
                    triggerSonarPulse(
                      player.id,
                      activePan === 'L' ? -0.8 : activePan === 'R' ? 0.8 : 0,
                    )
                  }
                  className="rounded-xl min-h-[40px] text-xs font-extrabold border bg-[#090608] hover:bg-[#8F1622]/40 text-[#9E8E91] hover:text-[#FF4655] border-[#881A26]/25 hover:border-[#8F1622] flex items-center justify-center gap-1.5 transition-all active:scale-95"
                >
                  <span>📡</span>
                  <span>3D Sonar</span>
                </button>
              </div>
            )}
          </div>
        </div>

        <div className="pt-4 border-t border-[#881A26]/20 flex items-center justify-between text-[11px] text-[#8E7F83]">
          <span className="flex items-center gap-1.5 font-medium">
            <IconShield size={13} className="text-[#E35D6A]" />
            <span>DTLS-SRTP P2P Şifreli</span>
          </span>
          <span className="text-[11px] font-semibold text-[#ED8793]">
            Opus 48kHz · 10ms
          </span>
        </div>
      </aside>
    </div>
  );
});
