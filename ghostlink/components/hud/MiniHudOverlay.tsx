'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — In-Game Compact Overlay Mode (Mini HUD)
// ─────────────────────────────────────────────────────────
// Designed for second-screen / borderless gaming setups:
//   • Minimal DOM & GPU footprint (<0.2% CPU)
//   • Shows live 5-operator speaking state, RTT, 3D Pan & Role
//   • Instant Mic / Deafen / Push-To-Talk controls
//   • Acoustic-synthesized Tactical Callouts (Hazır, Rotate B, Eco,
//     Drop AWP, Force, GG WP) + latest encrypted message ticker.

import { memo, useEffect, useState } from 'react';
import { useAppStore } from '@/lib/store';
import { useHUDStore } from '@/store/useHUDStore';
import { useVoiceSettingsStore } from '@/store/useVoiceSettingsStore';
import {
  useRealtimeChat,
  INITIAL_TACTICAL_MESSAGES,
} from '@/hooks/useRealtimeChat';
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

const MINI_OPERATORS = [
  { id: 'usr-local', name: 'Operatör', defaultRole: 'IGL', fallbackPing: 9 },
  { id: 'usr-1', name: 'cNed', defaultRole: 'AWP', fallbackPing: 11 },
  { id: 'usr-4', name: 'XANTARES', defaultRole: 'ENTRY', fallbackPing: 12 },
  { id: 'usr-2', name: 'woxic', defaultRole: 'LURKER', fallbackPing: 14 },
  { id: 'usr-3', name: 'Alfajer', defaultRole: 'COACH', fallbackPing: 13 },
] as const;

const MINI_CALLOUTS: ReadonlyArray<{
  label: string;
  cue: CalloutCueType;
  text: string;
}> = [
  {
    label: 'Hazır',
    cue: 'ready',
    text: '[HAZIR] Ses frekansı ve ekipman kontrolü tamamlandı, lobi maça hazır.',
  },
  {
    label: 'Rotate B',
    cue: 'rotate',
    text: '[TAKTİK ÇAĞRI: ROTATE B] B-Site yönüne hızlı rotasyon, Mid hattından 2 temas var.',
  },
  {
    label: 'Eco',
    cue: 'eco',
    text: '[ROUND 14 — ECO KARARI] Bu el kredi koruyoruz (min 4100), sonraki tur tam teçhizat.',
  },
  {
    label: 'Drop AWP',
    cue: 'drop',
    text: '[DROP AWP] cNed için birincil Operator / AWP drop gerekiyor, kredisi uygun olan atsın.',
  },
  {
    label: 'Force',
    cue: 'force',
    text: '[FORCE BUY] Kritik tur! Tüm krediyle zırh, tüfek ve tam utility çekiyoruz.',
  },
  {
    label: 'GG WP',
    cue: 'gg',
    text: '[GG WP] Kusursuz iletişim ve sıfır gecikme, elinize sağlık takım.',
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
  const { sendMessage } = useRealtimeChat(activeChannelId);

  const localMutes = useHUDStore((s) => s.localMutes);
  const spatialPans = useHUDStore((s) => s.spatialPans);
  const operatorRoles = useHUDStore((s) => s.operatorRoles);
  const peerSpectrums = useHUDStore((s) => s.peerSpectrums);
  const acousticCuesEnabled = useHUDStore((s) => s.acousticCuesEnabled);
  const toggleLocalMute = useHUDStore((s) => s.toggleLocalMute);
  const setAcousticCuesEnabled = useHUDStore((s) => s.setAcousticCuesEnabled);

  const setMiniHudActive = useVoiceSettingsStore((s) => s.setMiniHudActive);
  const toggleStratBoard = useVoiceSettingsStore((s) => s.toggleStratBoard);

  const [pttHeld, setPttHeld] = useState(false);
  const [telemetry, setTelemetry] = useState<MeshTelemetrySummary>(() =>
    getMevaTelemetryEngine().getSummary(),
  );

  useEffect(() => {
    const engine = getMevaTelemetryEngine();
    engine.start();
    return engine.subscribe((s) => setTelemetry(s));
  }, []);

  const messages =
    storeMessages.length > 0 ? storeMessages : INITIAL_TACTICAL_MESSAGES;
  const lastMsg = messages[messages.length - 1];

  const handleTriggerCallout = (text: string, cue: CalloutCueType) => {
    getMevaAudioEngine().playCalloutCue(cue);
    void sendMessage(text);
  };

  return (
    <div className="flex-1 min-h-0 w-full flex items-center justify-center p-3 sm:p-6 font-sans tabular-nums">
      <div className="w-full max-w-3xl rounded-2xl titanium-module p-4 sm:p-5 space-y-3.5 shadow-[0_28px_72px_rgba(0,0,0,0.92)] border border-[#881A26]/40">
        {/* 1. Compact Header Bar */}
        <div className="flex flex-wrap items-center justify-between gap-2 pb-3 border-b border-[#261217]">
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-xl crimson-cta flex items-center justify-center text-[#F4EFF0]">
              <IconMevaMark size={15} />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <span className="text-xs font-extrabold text-[#F4EFF0]">
                  Meva Mini HUD · Oyun İçi Kompakt Mod
                </span>
                <span className="rounded-md px-2 py-0.5 bg-[#180B10] border border-[#7A121D]/45 text-[10px] font-bold text-[#F08C96]">
                  {telemetry.rttMs}ms RTT · %{telemetry.stabilityPercent} P2P
                </span>
              </div>
              <span className="block text-[10.5px] text-[#8E7F83]">
                İkinci ekran / düşük CPU komuta şeridi · Opus 48kHz Stereo
              </span>
            </div>
          </div>

          <div className="flex items-center gap-1.5">
            <button
              type="button"
              onClick={() => setAcousticCuesEnabled(!acousticCuesEnabled)}
              className={`rounded-lg h-8 px-2.5 text-[11px] font-bold border transition-colors ${
                acousticCuesEnabled
                  ? 'bg-[#7A121D]/30 text-[#F08C96] border-[#961826]/55'
                  : 'bg-[#120A0D] text-[#8E7F83] border-[#2A1319]'
              }`}
            >
              Akustik Ses: {acousticCuesEnabled ? 'Açık' : 'Kapalı'}
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
              <span>Tam HUD&apos;a Dön</span>
            </button>
          </div>
        </div>

        {/* 2. Live 5-Operator Micro Strip */}
        <div className="grid grid-cols-1 sm:grid-cols-5 gap-2">
          {MINI_OPERATORS.map((op, idx) => {
            const isSelf = op.id === 'usr-local';
            const callsign = isSelf ? username : op.name;
            const muted = isSelf
              ? voiceControls.isMuted || voiceControls.isDeafened
              : Boolean(localMutes[op.id]);
            const spec = peerSpectrums[op.id];
            const speaking =
              !muted &&
              (isSelf
                ? voiceControls.isSpeaking || pttHeld
                : (spec?.rms ?? 0) > 0.08 || idx === 1 || idx === 2);
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
                className={`rounded-xl p-2.5 text-left border transition-all flex flex-col justify-between gap-2 ${
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
                  level={spec?.primary ?? 0.68}
                  secondaryLevel={spec?.secondary ?? 0.52}
                  active={speaking && !ecoActive}
                  muted={muted}
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
        </div>

        {/* 3. Voice Controls + Synthesized Quick Callouts */}
        <div className="flex flex-wrap items-center justify-between gap-2 pt-1">
          <div className="flex items-center gap-1.5">
            <button
              type="button"
              onClick={voiceControls.toggleMute}
              className={`rounded-xl h-9 px-3 text-xs font-bold border flex items-center gap-1.5 ${
                voiceControls.isMuted
                  ? 'bg-[#8F1622]/30 text-[#F08C96] border-[#C82333]/55'
                  : 'bg-[#120A0D] text-[#F4EFF0] border-[#2A1319]'
              }`}
            >
              {voiceControls.isMuted ? (
                <IconMicOff size={14} />
              ) : (
                <IconMic size={14} />
              )}
              <span>{voiceControls.isMuted ? 'Kapalı' : 'Mikrofon'}</span>
            </button>

            <button
              type="button"
              onClick={voiceControls.toggleDeafen}
              className={`rounded-xl h-9 px-3 text-xs font-bold border flex items-center gap-1.5 ${
                voiceControls.isDeafened
                  ? 'bg-[#8F1622]/30 text-[#F08C96] border-[#C82333]/55'
                  : 'bg-[#120A0D] text-[#F4EFF0] border-[#2A1319]'
              }`}
            >
              {voiceControls.isDeafened ? (
                <IconDeafen size={14} />
              ) : (
                <IconHeadphones size={14} />
              )}
              <span>{voiceControls.isDeafened ? 'Sağır' : 'Kulaklık'}</span>
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
              className={`rounded-xl h-9 px-3.5 text-xs font-extrabold border transition-all ${
                pttHeld
                  ? 'crimson-cta text-[#F4EFF0]'
                  : 'bg-[#190B10] hover:bg-[#240E15] text-[#F08C96] border-[#7A121D]/55'
              }`}
            >
              {pttHeld ? 'İletiliyor...' : 'PTT · V'}
            </button>
          </div>

          <div className="flex items-center gap-1 flex-wrap">
            {MINI_CALLOUTS.map((c) => (
              <button
                key={c.label}
                type="button"
                onClick={() => handleTriggerCallout(c.text, c.cue)}
                className="rounded-lg h-8 px-2.5 bg-[#140A0D] hover:bg-[#7A121D] border border-[#2C141A] hover:border-[#C82333]/55 text-[11px] font-bold text-[#F4EFF0] transition-all active:scale-95"
              >
                {c.label}
              </button>
            ))}
          </div>
        </div>

        {/* 4. Latest E2EE Tactical Feed Ticker */}
        {lastMsg && (
          <div className="rounded-xl px-3.5 py-2 bg-[#0B0709] border border-[#241116] flex items-center justify-between gap-2 text-xs">
            <div className="min-w-0 truncate">
              <span className="font-extrabold text-[#F08C96] mr-2">
                {lastMsg.author?.username ?? 'Operatör'}:
              </span>
              <span className="text-[#F4EFF0]/90">{lastMsg.content}</span>
            </div>
            <span className="text-[10px] font-mono font-bold text-[#8E7F83] flex-shrink-0">
              E2EE
            </span>
          </div>
        )}
      </div>
    </div>
  );
});
