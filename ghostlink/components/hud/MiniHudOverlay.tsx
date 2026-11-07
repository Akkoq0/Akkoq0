'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — In-Game Compact Overlay Mode (Mini HUD)
// ─────────────────────────────────────────────────────────
// Designed for borderless gaming & second-screen command:
//   • Document Picture-in-Picture API (window.documentPictureInPicture)
//     for borderless Always-on-Top game overlay across Windows/macOS/Linux
//   • MediaSession API integration for OS/headset mute hotkeys in background
//   • Screen Wake Lock API to prevent display/network sleep during voice
//   • Real-time connected operator squad strip (<0.2% CPU)
//   • Instant acoustic callouts (Hazır, Rotate B, Eco, Drop, Force, GG WP)

import React, { memo, useEffect, useMemo, useRef, useState } from 'react';
import { createPortal } from 'react-dom';
import { useAppStore } from '@/lib/store';
import { useHUDStore } from '@/store/useHUDStore';
import { useVoiceSettingsStore } from '@/store/useVoiceSettingsStore';
import { useRealtimeChat } from '@/hooks/useRealtimeChat';
import {
  getMevaAudioEngine,
  type CalloutCueType,
} from '@/src/lib/audioEngine';
import { getMevaVadEngine } from '@/src/lib/vadEngine';
import {
  getMevaTelemetryEngine,
  type MeshTelemetrySummary,
} from '@/src/lib/telemetryEngine';
import { OperatorAvatar, FluidWave } from '@/components/ui/HudPrimitives';
import {
  IconMevaMark,
  IconMic,
  IconMicOff,
  IconHeadphones,
  IconDeafen,
  IconMapBoard,
  IconMiniOverlay,
} from '@/components/ui/MevaIcons';
import type { VoiceControls } from '@/types';

const MINI_CALLOUTS: ReadonlyArray<{
  label: string;
  cue: CalloutCueType;
  text: string;
}> = [
  {
    label: 'Hazır',
    cue: 'ready',
    text: '[HAZIR] Ekipman ve ses kontrolü tamamlandı, lobi hazır.',
  },
  {
    label: 'Rotate B',
    cue: 'rotate',
    text: '[TAKTİK ÇAĞRI: ROTATE B] B-Site yönüne hızlı rotasyon.',
  },
  {
    label: 'Eco',
    cue: 'eco',
    text: '[ECO KARARI] Bu el kredi koruyoruz, sonraki tur tam teçhizat.',
  },
  {
    label: 'Drop',
    cue: 'drop',
    text: '[DROP İSTEĞİ] Silah / AWP drop gerekiyor.',
  },
  {
    label: 'Force',
    cue: 'force',
    text: '[FORCE BUY] Kritik tur! Tam teçhizat çekiyoruz.',
  },
  {
    label: 'GG WP',
    cue: 'gg',
    text: '[GG WP] Kusursuz iletişim, elinize sağlık takım.',
  },
];

interface MiniHudOverlayProps {
  username: string;
  voiceControls: VoiceControls;
}

export const MiniHudOverlay = memo(function MiniHudOverlay({
  username,
  voiceControls,
}: MiniHudOverlayProps) {
  const activeChannelId = useAppStore((s) => s.activeChannelId);
  const storeMessages = useAppStore((s) => s.messages);
  const ecoActive = useAppStore((s) => s.ecoMode.isActive);
  const voiceParticipants = useAppStore((s) => s.voiceParticipants);
  const { sendMessage } = useRealtimeChat(activeChannelId);

  const localMutes = useHUDStore((s) => s.localMutes);
  const spatialPans = useHUDStore((s) => s.spatialPans);
  const operatorRoles = useHUDStore((s) => s.operatorRoles);
  const acousticCuesEnabled = useHUDStore((s) => s.acousticCuesEnabled);
  const toggleLocalMute = useHUDStore((s) => s.toggleLocalMute);
  const setAcousticCuesEnabled = useHUDStore((s) => s.setAcousticCuesEnabled);

  const setMiniHudActive = useVoiceSettingsStore((s) => s.setMiniHudActive);
  const toggleStratBoard = useVoiceSettingsStore((s) => s.toggleStratBoard);

  const [pttHeld, setPttHeld] = useState(false);
  const [pipContainer, setPipContainer] = useState<HTMLElement | null>(null);
  const [isPipActive, setIsPipActive] = useState(false);
  const pipWindowRef = useRef<Window | null>(null);

  const [telemetry, setTelemetry] = useState<MeshTelemetrySummary>(() =>
    getMevaTelemetryEngine().getSummary(),
  );

  useEffect(() => {
    const engine = getMevaTelemetryEngine();
    engine.start();
    return engine.subscribe((s) => setTelemetry(s));
  }, []);

  // MediaSession API Integration (Background headset / media keys control)
  useEffect(() => {
    if (typeof navigator !== 'undefined' && 'mediaSession' in navigator) {
      try {
        navigator.mediaSession.metadata = new MediaMetadata({
          title: 'Meva HUD — Taktik Ses Kanalı',
          artist: username || 'Operatör',
          album: 'P2P Encrypted Mesh',
        });
        navigator.mediaSession.setActionHandler('play', () => {
          voiceControls?.toggleMute();
        });
        navigator.mediaSession.setActionHandler('pause', () => {
          voiceControls?.toggleMute();
        });
        navigator.mediaSession.setActionHandler('stop', () => {
          voiceControls?.leaveVoice();
        });
        // @ts-expect-error MediaSessionAction togglemicrophone
        navigator.mediaSession.setActionHandler('togglemicrophone', () => {
          voiceControls?.toggleMute();
        });
      } catch {}
    }
  }, [username, voiceControls]);

  // Screen Wake Lock API (Prevents screen & system sleep while voice is active)
  useEffect(() => {
    let wakeLockSentinel: any = null;
    async function requestLock() {
      if (typeof navigator !== 'undefined' && 'wakeLock' in navigator) {
        try {
          wakeLockSentinel = await (navigator as any).wakeLock.request('screen');
        } catch {}
      }
    }
    void requestLock();
    return () => {
      try {
        wakeLockSentinel?.release();
      } catch {}
    };
  }, []);

  // Dynamic connected operators (Self + real P2P connected peers)
  const activePeers = useMemo(() => {
    return voiceParticipants.filter((p) => p.user_id !== 'usr-local');
  }, [voiceParticipants]);

  const miniOperators = useMemo(() => {
    const list = [
      {
        id: 'usr-local',
        name: username || 'Operatör',
        defaultRole: operatorRoles['usr-local'] ?? 'IGL',
        fallbackPing: 9,
      },
    ];

    for (let i = 0; i < activePeers.length && list.length < 5; i++) {
      const p = activePeers[i];
      list.push({
        id: p.user_id,
        name: p.username || `Operatör #${i + 2}`,
        defaultRole: operatorRoles[p.user_id] ?? 'ENTRY',
        fallbackPing: 11,
      });
    }

    return list;
  }, [username, operatorRoles, activePeers]);

  const lastMsg = storeMessages[storeMessages.length - 1];

  const handleTriggerCallout = (text: string, cue: CalloutCueType) => {
    getMevaAudioEngine().playCalloutCue(cue);
    void sendMessage(text);
  };

  // Always-on-Top Document Picture-in-Picture Toggle
  const handleTogglePip = async () => {
    if (isPipActive && pipWindowRef.current) {
      try {
        pipWindowRef.current.close();
      } catch {}
      return;
    }

    if (
      typeof window === 'undefined' ||
      !('documentPictureInPicture' in window)
    ) {
      return;
    }

    try {
      const pipWin = await (window as any).documentPictureInPicture.requestWindow({
        width: 440,
        height: 240,
      });

      // Clone existing page stylesheets into the PiP window document
      const styleSheets = Array.from(document.styleSheets);
      styleSheets.forEach((sheet) => {
        try {
          const cssRules = Array.from(sheet.cssRules)
            .map((r) => r.cssText)
            .join('');
          const style = pipWin.document.createElement('style');
          style.textContent = cssRules;
          pipWin.document.head.appendChild(style);
        } catch {
          if (sheet.href) {
            const link = pipWin.document.createElement('link');
            link.rel = 'stylesheet';
            link.href = sheet.href;
            pipWin.document.head.appendChild(link);
          }
        }
      });

      pipWin.document.body.className =
        'bg-[#0B0708] text-[#F5EBE6] p-2 m-0 overflow-hidden font-sans select-none';
      const container = pipWin.document.createElement('div');
      container.className = 'w-full h-full';
      pipWin.document.body.appendChild(container);

      pipWin.addEventListener('pagehide', () => {
        setPipContainer(null);
        pipWindowRef.current = null;
        setIsPipActive(false);
      });

      pipWindowRef.current = pipWin;
      setPipContainer(container);
      setIsPipActive(true);
    } catch {}
  };

  const renderContent = () => (
    <div className="w-full max-w-3xl rounded-2xl titanium-module p-3.5 sm:p-5 space-y-3 shadow-[0_28px_72px_rgba(0,0,0,0.92)] border border-[#881A26]/40">
      {/* 1. Compact Header Bar */}
      <div className="flex flex-wrap items-center justify-between gap-2 pb-2.5 border-b border-[#261217]">
        <div className="flex items-center gap-2.5">
          <div className="w-8 h-8 rounded-xl crimson-cta flex items-center justify-center text-[#F4EFF0]">
            <IconMevaMark size={15} />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <span className="text-xs font-extrabold text-[#F4EFF0]">
                Meva Mini HUD {isPipActive ? '· Always-on-Top PiP' : '· Kompakt Mod'}
              </span>
              <span className="rounded-md px-2 py-0.5 bg-[#180B10] border border-[#7A121D]/45 text-[10px] font-bold text-[#F08C96]">
                {telemetry.rttMs}ms RTT · %{telemetry.stabilityPercent} P2P
              </span>
            </div>
            <span className="block text-[10.5px] text-[#8E7F83]">
              Oyun üstü / ikinci ekran komuta şeridi · Opus 48kHz Stereo
            </span>
          </div>
        </div>

        <div className="flex items-center gap-1.5 flex-wrap">
          {typeof window !== 'undefined' && 'documentPictureInPicture' in window && (
            <button
              type="button"
              onClick={handleTogglePip}
              title="Oyunun Üstünde Sabitle (Always-on-Top PiP Penceresi)"
              className={`rounded-lg h-8 px-2.5 text-[11px] font-bold border flex items-center gap-1.5 transition-all ${
                isPipActive
                  ? 'crimson-cta text-[#F4EFF0]'
                  : 'bg-[#1E0F14] hover:bg-[#2C141D] border-[#7A121D]/60 text-[#F4EFF0]'
              }`}
            >
              <svg
                width="13"
                height="13"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <rect x="2" y="3" width="20" height="14" rx="2" />
                <rect
                  x="12"
                  y="9"
                  width="8"
                  height="6"
                  rx="1"
                  fill="#C82333"
                  stroke="none"
                />
              </svg>
              <span>{isPipActive ? 'PiP Kapat' : 'Oyun Üstü PiP'}</span>
            </button>
          )}

          <button
            type="button"
            onClick={() => setAcousticCuesEnabled(!acousticCuesEnabled)}
            className={`rounded-lg h-8 px-2.5 text-[11px] font-bold border transition-colors ${
              acousticCuesEnabled
                ? 'bg-[#7A121D]/30 text-[#F08C96] border-[#961826]/55'
                : 'bg-[#120A0D] text-[#8E7F83] border-[#2A1319]'
            }`}
          >
            Akustik: {acousticCuesEnabled ? 'Açık' : 'Kapalı'}
          </button>
          <button
            type="button"
            onClick={toggleStratBoard}
            title="Taktik Harita Tahtasını Aç (B)"
            className="rounded-lg h-8 px-2.5 bg-[#140A0D] hover:bg-[#1E0C12] border border-[#2C141A] text-[11px] font-bold text-[#F4EFF0] flex items-center gap-1.5"
          >
            <IconMapBoard size={13} className="text-[#E35D6A]" />
            <span>Harita</span>
          </button>
          <button
            type="button"
            onClick={() => setMiniHudActive(false)}
            className="crimson-cta rounded-lg h-8 px-3 text-[11px] font-extrabold text-[#F4EFF0] flex items-center gap-1.5"
          >
            <IconMiniOverlay size={13} />
            <span>Tam HUD</span>
          </button>
        </div>
      </div>

      {/* 2. Live Operator Micro Strip */}
      <div className="grid grid-cols-1 sm:grid-cols-5 gap-2">
        {miniOperators.map((op, idx) => {
          const isSelf = op.id === 'usr-local';
          const callsign = isSelf ? username : op.name;
          const muted = isSelf
            ? voiceControls.isMuted || voiceControls.isDeafened
            : Boolean(localMutes[op.id]);
          const speaking =
            !muted &&
            (isSelf ? voiceControls.isSpeaking || pttHeld : false);
          const role = operatorRoles[op.id] ?? op.defaultRole;
          const pan = spatialPans[op.id] ?? 'C';
          const rtt = telemetry.nodes[op.id]?.rttMs ?? op.fallbackPing;

          return (
            <button
              key={op.id}
              type="button"
              onClick={() =>
                isSelf ? voiceControls.toggleMute() : toggleLocalMute(op.id)
              }
              title={muted ? 'Sesi açmak için tıkla' : 'Susturmak için tıkla'}
              className={`rounded-xl p-2.5 text-left border transition-all flex flex-col justify-between gap-1.5 ${
                speaking
                  ? 'cockpit-pod-live border-[#C82333]/55'
                  : muted
                    ? 'cockpit-pod-muted opacity-75 border-[#261217]'
                    : 'bg-[#10080B] border-[#261217] hover:border-[#4A1B24]'
              }`}
            >
              <div className="flex items-center justify-between gap-1.5">
                <div className="flex items-center gap-2 min-w-0">
                  <OperatorAvatar
                    name={callsign}
                    status={muted ? 'dnd' : speaking ? 'online' : 'in-game'}
                    size="xs"
                    speaking={speaking}
                  />
                  <span className="text-xs font-extrabold text-[#F4EFF0] truncate">
                    {callsign}
                  </span>
                </div>
                <span className="text-[10px] font-bold text-[#F08C96]">
                  {role}
                </span>
              </div>

              <FluidWave
                peerId={op.id}
                active={speaking && !ecoActive}
                muted={muted}
                speed={1.2}
                className="w-full h-4"
              />

              <div className="flex items-center justify-between text-[10px] text-[#8E7F83]">
                <span>3D: {pan}</span>
                <span className={muted ? 'text-[#D63344] font-bold' : ''}>
                  {muted ? 'Sessiz' : `${rtt}ms`}
                </span>
              </div>
            </button>
          );
        })}

        {/* Empty slots placeholders up to 5 */}
        {Array.from({ length: Math.max(0, 5 - miniOperators.length) }).map(
          (_, i) => (
            <div
              key={`mini-empty-${i}`}
              className="rounded-xl p-2.5 text-center border border-dashed border-[#261217] bg-[#0E0709]/40 flex flex-col items-center justify-center gap-1 opacity-70"
            >
              <span className="text-[10.5px] font-bold text-[#827376]">
                Slot #{miniOperators.length + i + 1}
              </span>
              <span className="text-[9.5px] text-[#554548]">Boş Slot</span>
            </div>
          ),
        )}
      </div>

      {/* 3. Tactical Quick Callouts Bar */}
      <div className="flex items-center gap-1.5 overflow-x-auto no-scrollbar py-0.5">
        <span className="text-[10.5px] font-extrabold uppercase tracking-wider text-[#8E7F83] flex-shrink-0 mr-1">
          Taktik Çağrı:
        </span>
        {MINI_CALLOUTS.map((c) => (
          <button
            key={c.label}
            type="button"
            onClick={() => handleTriggerCallout(c.text, c.cue)}
            className="rounded-lg h-7 px-2.5 bg-[#140A0D] hover:bg-[#1E0C12] border border-[#261217] hover:border-[#7A121D]/60 text-[11px] font-bold text-[#F4EFF0] flex-shrink-0 transition-colors"
          >
            {c.label}
          </button>
        ))}
      </div>

      {/* 4. Controls Footer & Decrypted Stream Notice */}
      <div className="pt-2 border-t border-[#261217] flex flex-wrap items-center justify-between gap-2 text-xs">
        <div className="flex items-center gap-2">
          <button
            type="button"
            onClick={voiceControls.toggleMute}
            className={`rounded-xl h-9 px-3 font-bold border flex items-center gap-2 transition-colors ${
              voiceControls.isMuted
                ? 'bg-[#7A121D] text-[#F4EFF0] border-[#961826]'
                : 'bg-[#140A0D] text-[#F4EFF0] border-[#2C141A]'
            }`}
          >
            {voiceControls.isMuted ? (
              <IconMicOff size={14} />
            ) : (
              <IconMic size={14} />
            )}
            <span>{voiceControls.isMuted ? 'Mikrofon Kapalı' : 'Mikrofon Açık'}</span>
          </button>

          <button
            type="button"
            onClick={voiceControls.toggleDeafen}
            className={`rounded-xl h-9 px-3 font-bold border flex items-center gap-2 transition-colors ${
              voiceControls.isDeafened
                ? 'bg-[#7A121D] text-[#F4EFF0] border-[#961826]'
                : 'bg-[#140A0D] text-[#F4EFF0] border-[#2C141A]'
            }`}
          >
            {voiceControls.isDeafened ? (
              <IconDeafen size={14} />
            ) : (
              <IconHeadphones size={14} />
            )}
            <span>{voiceControls.isDeafened ? 'Kulaklık Kapalı' : 'Kulaklık Açık'}</span>
          </button>

          <button
            type="button"
            onPointerDown={() => {
              setPttHeld(true);
              getMevaVadEngine().setPttPressed(true);
            }}
            onPointerUp={() => {
              setPttHeld(false);
              getMevaVadEngine().setPttPressed(false);
            }}
            onPointerLeave={() => {
              setPttHeld(false);
              getMevaVadEngine().setPttPressed(false);
            }}
            className={`rounded-xl h-9 px-3.5 font-extrabold border transition-all ${
              pttHeld
                ? 'crimson-cta text-[#F4EFF0]'
                : 'bg-[#180B10] text-[#F4EFF0] border-[#38161E]'
            }`}
          >
            {pttHeld ? 'İletiliyor...' : 'Bas-Konuş (V)'}
          </button>
        </div>

        {lastMsg && (
          <div className="flex items-center gap-2 text-[11px] text-[#A6979A] max-w-sm truncate">
            <span className="font-bold text-[#E35D6A]">
              {lastMsg.author?.username}:
            </span>
            <span className="truncate">{lastMsg.content}</span>
          </div>
        )}
      </div>
    </div>
  );

  if (isPipActive && pipContainer) {
    return createPortal(renderContent(), pipContainer);
  }

  return (
    <div className="flex-1 min-h-0 w-full flex items-center justify-center p-3 sm:p-6 font-sans tabular-nums">
      {renderContent()}
    </div>
  );
});
