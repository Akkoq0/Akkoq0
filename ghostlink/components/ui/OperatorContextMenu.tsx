'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Right-Click Tactical Operator Command Menu
// ─────────────────────────────────────────────────────────
// Zero main-screen clutter: surfaces Per-Operator EQ (Crisp / Balanced / Warm),
// 3D Spatial Pan, Local Mute, IGL Priority Speaker (-30% Ducking),
// Role Assignment (IGL / AWP / ENTRY / LURKER / COACH), and ICE Connection Reset.

import { memo, useEffect, useState, useMemo } from 'react';
import { useAppStore } from '@/lib/store';
import {
  detectGameFromChannel,
  getGameById,
  SUPPORTED_GAMES,
  type GameRoleDef,
} from '@/src/lib/gameRegistry';
import {
  useHUDStore,
  type SpatialPan,
  type TacticalRole,
} from '@/store/useHUDStore';
import type { OperatorEqProfile } from '@/src/lib/audioEngine';
import { getMevaWebRTCMesh } from '@/src/lib/webrtcMesh';
import { OperatorAvatar } from '@/components/ui/HudPrimitives';
import {
  IconClose,
  IconMic,
  IconMicOff,
  IconBolt,
  IconSliders,
} from '@/components/ui/MevaIcons';
import type { VoiceControls } from '@/types';

export interface OperatorContextTarget {
  id: string;
  username: string;
  x: number;
  y: number;
  pingMs?: number;
}

interface OperatorContextMenuProps {
  target: OperatorContextTarget | null;
  onClose: () => void;
  onOpenDspDrawer?: (operatorId: string) => void;
  voiceControls?: VoiceControls;
}

const EQ_OPTIONS: ReadonlyArray<{
  key: OperatorEqProfile;
  label: string;
  hint: string;
}> = [
  { key: 'crisp', label: 'Keskin Tiz', hint: '+4.5dB 3.5kHz' },
  { key: 'balanced', label: 'Dengeli', hint: 'Referans Vokal' },
  { key: 'warm', label: 'Tok Bas', hint: '+3.2dB 220Hz' },
];

const ROLES: ReadonlyArray<TacticalRole> = [
  'IGL',
  'AWP',
  'ENTRY',
  'LURKER',
  'COACH',
];

const PANS: ReadonlyArray<{ key: SpatialPan; label: string }> = [
  { key: 'L', label: 'Sol (-1)' },
  { key: 'C', label: 'Merkez (0)' },
  { key: 'R', label: 'Sağ (+1)' },
];

export const OperatorContextMenu = memo(function OperatorContextMenu({
  target,
  onClose,
  onOpenDspDrawer,
  voiceControls,
}: OperatorContextMenuProps) {
  const localMutes = useHUDStore((s) => s.localMutes);
  const eqProfiles = useHUDStore((s) => s.eqProfiles);
  const spatialPans = useHUDStore((s) => s.spatialPans);
  const prioritySpeakers = useHUDStore((s) => s.prioritySpeakers);
  const operatorRoles = useHUDStore((s) => s.operatorRoles);
  const iglDuckingEnabled = useHUDStore((s) => s.iglDuckingEnabled);

  const toggleLocalMute = useHUDStore((s) => s.toggleLocalMute);
  const setPlayerGain = useHUDStore((s) => s.setPlayerGain);
  const setEqProfile = useHUDStore((s) => s.setEqProfile);
  const setSpatialPan = useHUDStore((s) => s.setSpatialPan);
  const togglePrioritySpeaker = useHUDStore((s) => s.togglePrioritySpeaker);
  const setOperatorRole = useHUDStore((s) => s.setOperatorRole);
  const setIglDuckingEnabled = useHUDStore((s) => s.setIglDuckingEnabled);

  const channels = useAppStore((s) => s.channels);
  const activeVoiceChannelId = useAppStore((s) => s.activeVoiceChannelId);
  const activeVoiceChannel = channels.find((c) => c.id === activeVoiceChannelId);
  const activeGame = useMemo(() => {
    if (activeVoiceChannel) {
      return activeVoiceChannel.game_id
        ? getGameById(activeVoiceChannel.game_id)
        : detectGameFromChannel(activeVoiceChannel.name, activeVoiceChannel.tags);
    }
    return SUPPORTED_GAMES.cs2;
  }, [activeVoiceChannel]);

  const dynamicRoles = activeGame.roles;

  const [iceResetFeedback, setIceResetFeedback] = useState(false);

  useEffect(() => {
    setIceResetFeedback(false);
  }, [target?.id]);

  useEffect(() => {
    if (!target) return;
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        e.stopPropagation();
        onClose();
      }
    };
    window.addEventListener('keydown', handleKeyDown, true);
    return () => window.removeEventListener('keydown', handleKeyDown, true);
  }, [target, onClose]);

  if (!target) return null;

  const isSelf = target.id === 'usr-local';
  const isMuted = isSelf
    ? Boolean(voiceControls?.isMuted)
    : Boolean(localMutes[target.id]);
  const activeEq = eqProfiles[target.id] ?? 'balanced';
  const activePan = spatialPans[target.id] ?? 'C';
  const isPriority = Boolean(prioritySpeakers[target.id]);
  const activeRole = operatorRoles[target.id] ?? (isSelf ? 'IGL' : 'ENTRY');

  const vw = typeof window !== 'undefined' ? window.innerWidth : 1280;
  const vh = typeof window !== 'undefined' ? window.innerHeight : 800;
  const menuW = 296;
  const menuH = 420;
  const safeLeft = Math.max(12, Math.min(target.x, vw - menuW - 12));
  const safeTop = Math.max(12, Math.min(target.y, vh - menuH - 12));

  const handleResetConnection = () => {
    void getMevaWebRTCMesh().resetPeerConnection(target.id);
    setPlayerGain(target.id, 100);
    setIceResetFeedback(true);
    setTimeout(() => setIceResetFeedback(false), 1600);
  };

  return (
    <div
      className="fixed inset-0 z-50 font-sans tabular-nums"
      onClick={onClose}
      onContextMenu={(e) => {
        e.preventDefault();
        onClose();
      }}
    >
      <div
        style={{ left: safeLeft, top: safeTop, width: menuW }}
        onClick={(e) => e.stopPropagation()}
        onContextMenu={(e) => e.preventDefault()}
        className="fixed rounded-2xl exec-modal p-3.5 space-y-3 shadow-[0_24px_60px_rgba(0,0,0,0.92)] border border-[#881A26]/40"
      >
        {/* Operator Header */}
        <div className="flex items-center justify-between gap-2 pb-2.5 border-b border-[#2A1319]">
          <div className="flex items-center gap-2.5 min-w-0">
            <OperatorAvatar
              name={target.username}
              status={isMuted ? 'dnd' : 'online'}
              size="sm"
            />
            <div className="min-w-0">
              <div className="flex items-center gap-1.5">
                <span className="text-[13px] font-extrabold text-[#F4EFF0] truncate">
                  {target.username}
                </span>
                <span className="rounded px-1.5 py-0.5 bg-[#7A121D]/35 border border-[#A61B29]/45 text-[9.5px] font-extrabold text-[#F08C96]">
                  {activeRole}
                </span>
              </div>
              <span className="block text-[10.5px] text-[#8E7F83]">
                Taktiksel Komuta · {target.pingMs ?? 11} ms P2P
              </span>
            </div>
          </div>
          <button
            type="button"
            onClick={onClose}
            aria-label="Kapat"
            className="rounded-lg w-7 h-7 flex items-center justify-center bg-[#140A0D] hover:bg-[#220D13] border border-[#2C141A] text-[#9E8E91] hover:text-[#F4EFF0]"
          >
            <IconClose size={13} />
          </button>
        </div>

        {/* 1. Per-Operator EQ Profile */}
        <div className="space-y-1.5">
          <div className="flex items-center justify-between text-[10.5px]">
            <span className="font-bold text-[#B8AAAC]">
              Operatöre Özel EQ Profili
            </span>
            <span className="text-[#E35D6A] font-semibold">
              {EQ_OPTIONS.find((e) => e.key === activeEq)?.hint}
            </span>
          </div>
          <div className="grid grid-cols-3 gap-1.5">
            {EQ_OPTIONS.map((opt) => {
              const selected = activeEq === opt.key;
              return (
                <button
                  key={opt.key}
                  type="button"
                  onClick={() => setEqProfile(target.id, opt.key)}
                  className={`rounded-lg py-1.5 px-1.5 text-[11px] font-bold border transition-all ${
                    selected
                      ? 'crimson-cta text-[#F4EFF0]'
                      : 'bg-[#120A0D] hover:bg-[#1C0D12] text-[#B8AAAC] hover:text-[#F4EFF0] border-[#2A1319]'
                  }`}
                >
                  {opt.label}
                </button>
              );
            })}
          </div>
        </div>

        {/* 2. 3D Spatial Audio Pan */}
        {!isSelf && (
          <div className="space-y-1.5">
            <span className="block text-[10.5px] font-bold text-[#B8AAAC]">
              3D Konumsal Ses Yönü (StereoPanner)
            </span>
            <div className="grid grid-cols-3 gap-1.5">
              {PANS.map((p) => (
                <button
                  key={p.key}
                  type="button"
                  onClick={() => setSpatialPan(target.id, p.key)}
                  className={`rounded-lg py-1 text-[10.5px] font-bold border transition-all ${
                    activePan === p.key
                      ? 'bg-[#7A121D]/35 text-[#F4EFF0] border-[#C82333]/55'
                      : 'bg-[#120A0D] text-[#9E8E91] hover:text-[#F4EFF0] border-[#2A1319]'
                  }`}
                >
                  {p.label}
                </button>
              ))}
            </div>
          </div>
        )}

        {/* 3. Local Mute & IGL Priority Speaker Ducking */}
        <div className="space-y-1.5">
          <div className="grid grid-cols-2 gap-1.5">
            <button
              type="button"
              onClick={() =>
                isSelf && voiceControls
                  ? voiceControls.toggleMute()
                  : toggleLocalMute(target.id)
              }
              className={`rounded-xl h-8 px-2.5 text-[11px] font-bold border flex items-center justify-center gap-1.5 transition-all ${
                isMuted
                  ? 'bg-[#8F1622]/30 text-[#F08C96] border-[#C82333]/55'
                  : 'bg-[#120A0D] hover:bg-[#1B0C11] text-[#F4EFF0] border-[#2A1319]'
              }`}
            >
              {isMuted ? <IconMicOff size={13} /> : <IconMic size={13} />}
              <span>{isMuted ? 'Sesi Aç' : 'Yerel Sustur'}</span>
            </button>

            <button
              type="button"
              onClick={() => togglePrioritySpeaker(target.id)}
              title="Öncelikli konuşmacı aktifken diğer operatörler otomatik %30 kısılır"
              className={`rounded-xl h-8 px-2.5 text-[11px] font-bold border flex items-center justify-center gap-1.5 transition-all ${
                isPriority
                  ? 'crimson-cta text-[#F4EFF0]'
                  : 'bg-[#120A0D] hover:bg-[#1B0C11] text-[#B8AAAC] hover:text-[#F4EFF0] border-[#2A1319]'
              }`}
            >
              <IconBolt size={12} />
              <span>{isPriority ? 'Öncelikli ✓' : 'IGL Öncelik'}</span>
            </button>
          </div>

          <button
            type="button"
            onClick={() => setIglDuckingEnabled(!iglDuckingEnabled)}
            className="rounded-lg w-full py-1.5 px-2.5 bg-[#0E080A] hover:bg-[#170B0F] border border-[#261217] flex items-center justify-between text-[10.5px]"
          >
            <span className="text-[#B8AAAC] font-semibold">
              IGL Priority Ducking (%30 Otomatik Kısma)
            </span>
            <span
              className={`font-extrabold ${
                iglDuckingEnabled ? 'text-[#F08C96]' : 'text-[#7D6E71]'
              }`}
            >
              {iglDuckingEnabled ? 'AKTİF' : 'KAPALI'}
            </span>
          </button>
        </div>

        {/* 4. Tactical Role Switcher */}
        <div className="space-y-1.5">
          <div className="flex items-center justify-between text-[10.5px]">
            <span className="font-bold text-[#B8AAAC]">
              Taktik Rol Ataması
            </span>
            <span className="text-[10px] font-semibold text-[#ED8793]">
              {activeGame.shortName}
            </span>
          </div>
          <div className="grid grid-cols-3 sm:grid-cols-6 gap-1">
            {dynamicRoles.map((r: GameRoleDef) => {
              const roleKey = r.shortLabel;
              const isSelected = activeRole === roleKey || activeRole === r.key;
              return (
                <button
                  key={r.key}
                  type="button"
                  onClick={() => setOperatorRole(target.id, roleKey)}
                  title={r.label}
                  className={`rounded-lg py-1 px-1 text-[9.5px] font-extrabold border transition-all truncate ${
                    isSelected
                      ? 'bg-[#8F1622]/45 text-[#F4EFF0] border-[#C82333]'
                      : 'bg-[#11090B] text-[#8E7F83] hover:text-[#F4EFF0] border-[#261217]'
                  }`}
                >
                  {roleKey}
                </button>
              );
            })}
          </div>
        </div>

        {/* 5. Connection Reset & Advanced DSP Drawer */}
        <div className="pt-2 border-t border-[#261217] flex items-center gap-1.5">
          <button
            type="button"
            onClick={handleResetConnection}
            className="flex-1 rounded-xl h-8 px-2.5 bg-[#140A0D] hover:bg-[#220D13] border border-[#2E151C] hover:border-[#8F1622]/55 text-[11px] font-bold text-[#F4EFF0] transition-colors"
          >
            {iceResetFeedback ? 'ICE Sıfırlandı ✓' : 'Bağlantıyı Sıfırla'}
          </button>
          {onOpenDspDrawer && !isSelf && (
            <button
              type="button"
              onClick={() => {
                onOpenDspDrawer(target.id);
                onClose();
              }}
              title="Gelişmiş DSP çekmecesini aç"
              className="rounded-xl h-8 px-2.5 bg-[#1A0B10] hover:bg-[#7A121D]/40 border border-[#7A121D]/50 text-[11px] font-bold text-[#F08C96] flex items-center gap-1"
            >
              <IconSliders size={12} />
              <span>DSP</span>
            </button>
          )}
        </div>
      </div>
    </div>
  );
});
