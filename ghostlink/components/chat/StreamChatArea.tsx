'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Tactical Bento Cockpit (StreamChatArea)
// ─────────────────────────────────────────────────────────
//   • TOP STAGE: 5-Operator Live Squad Voice Matrix with
//     24-micro-bar high-res audio spectrum, acoustic avatar ring,
//     3D Spatial Audio (L/C/R) selector, non-truncated 2-line
//     agent/loadout hierarchy, and 0-200% Gain slider.
//   • BOTTOM-LEFT: Pre-populated Tactical Comms & Callout Stream
//     with voice-note waveform player and instant callout cards.
//   • BOTTOM-RIGHT: Visualized P2P Mesh & System Telemetry with
//     sparklines, radial CPU gauge, and an interactive 5-vertex
//     Pentagon P2P Mesh SVG with flowing data packets.

import { memo, useCallback, useEffect, useRef, useState } from 'react';
import { useAppStore } from '@/lib/store';
import {
  useRealtimeChat,
  INITIAL_TACTICAL_MESSAGES,
} from '@/hooks/useRealtimeChat';
import { cleanLabel } from '@/lib/format';
import { OperatorAvatar } from '@/components/ui/HudPrimitives';
import {
  IconVoiceWave,
  IconMic,
  IconMicOff,
  IconSend,
  IconShield,
} from '@/components/ui/MevaIcons';
import type { Profile, VoiceControls } from '@/types';

type SpatialPan = 'L' | 'C' | 'R';

interface SquadOperatorMeta {
  id: string;
  username: string;
  role: 'IGL' | 'AWP' | 'ENTRY' | 'LURKER' | 'COACH';
  roleBadgeCls: string;
  pingMs: number;
  jitterMs: number;
  loadoutByServer: Record<string, { agent: string; detail: string }>;
}

const SQUAD_OPERATORS: SquadOperatorMeta[] = [
  {
    id: 'usr-local',
    username: 'Operatör',
    role: 'IGL',
    roleBadgeCls: 'text-[#F59E0B] border-[#F59E0B]/40 bg-[#F59E0B]/10',
    pingMs: 9,
    jitterMs: 0.1,
    loadoutByServer: {
      'srv-1': { agent: 'Omen • Taktik Komuta', detail: 'Radiant IGL · Lider' },
      'srv-2': { agent: 'Taktik Kaptan • IGL', detail: 'Faceit 3200 ELO' },
      'srv-3': { agent: 'Asıl Kadro • Komutan', detail: 'Turnuva Hattı' },
    },
  },
  {
    id: 'usr-1',
    username: 'cNed',
    role: 'AWP',
    roleBadgeCls: 'text-[#EF4444] border-[#EF4444]/40 bg-[#EF4444]/10',
    pingMs: 11,
    jitterMs: 0.2,
    loadoutByServer: {
      'srv-1': { agent: 'Jett • Operator', detail: 'Radiant #14 · Keskin Nişancı' },
      'srv-2': { agent: 'Birincil AWP • Mirage', detail: 'Faceit Lvl 10 · 1.42 K/D' },
      'srv-3': { agent: 'Duelist • Operator', detail: 'VCT Şampiyonu' },
    },
  },
  {
    id: 'usr-4',
    username: 'XANTARES',
    role: 'ENTRY',
    roleBadgeCls: 'text-[#10B981] border-[#10B981]/40 bg-[#10B981]/10',
    pingMs: 12,
    jitterMs: 0.2,
    loadoutByServer: {
      'srv-1': { agent: 'Raze • Entry Fragger', detail: 'Alan Açıcı · %64 HS' },
      'srv-2': { agent: 'AK-47 • Space Creator', detail: '3140 ELO · FPL Yıldızı' },
      'srv-3': { agent: 'Başlangıç Taarruz', detail: 'Agresif Giriş' },
    },
  },
  {
    id: 'usr-2',
    username: 'woxic',
    role: 'LURKER',
    roleBadgeCls: 'text-[#F59E0B] border-[#F59E0B]/40 bg-[#F59E0B]/10',
    pingMs: 14,
    jitterMs: 0.3,
    loadoutByServer: {
      'srv-1': { agent: 'Sova • Recon & Clutch', detail: 'Harita İstihbarat · Lvl 10' },
      'srv-2': { agent: 'Hibrit AWP • Clutch', detail: 'Sol El Uzmanı · 3090 ELO' },
      'srv-3': { agent: 'Arka Hat Sızma', detail: 'Geç Rotasyon Kontrolü' },
    },
  },
  {
    id: 'usr-3',
    username: 'Alfajer',
    role: 'COACH',
    roleBadgeCls: 'text-gl-text-bright border-white/20 bg-white/[0.06]',
    pingMs: 13,
    jitterMs: 0.2,
    loadoutByServer: {
      'srv-1': { agent: 'Killjoy • Site Anchor', detail: 'Savunma Kilidi & Analiz' },
      'srv-2': { agent: 'B-Site Savunma • Analist', detail: 'Taktik Gözlem' },
      'srv-3': { agent: 'Harita Koçu & VOD', detail: 'Canlı Strateji' },
    },
  },
];

const CALLOUTS = [
  {
    label: 'READY',
    tag: 'HAZIRLIK ONAYI',
    tone: 'emerald',
    text: '[READY] Ses frekansı ve ekipman kontrolü tamamlandı. Lobi maça hazır!',
  },
  {
    label: 'ROTATE B',
    tag: 'ACİL ROTASYON',
    tone: 'crimson',
    text: '[TAKTİK ÇAĞRI: ROTATE B] B-Site yönüne hızlı rotasyon! Mid üzerinden 2 oyuncu sızıyor.',
  },
  {
    label: 'ECO ROUND',
    tag: 'EKONOMİ KARARI',
    tone: 'amber',
    text: '[ROUND 14 - ECO] Bu el tam eco, kredi koruyoruz (min 4100). Sonraki el tam teçhizat.',
  },
  {
    label: 'DROP AWP',
    tag: 'SİLAH TALEBİ',
    tone: 'amber',
    text: '[DROP AWP] cNed için Operator / AWP drop gerekiyor, kredisi uygun olan atsın.',
  },
  {
    label: 'FORCE BUY',
    tag: 'KRİTİK TUR',
    tone: 'crimson',
    text: '[FORCE BUY] Kritik round! Tüm krediyle zırh + tüfek + tam utility çekiyoruz.',
  },
  {
    label: 'GG WP',
    tag: 'MAÇ SONU',
    tone: 'emerald',
    text: '[GG WP] Kusursuz iletişim ve sıfır gecikme. Elinize sağlık takım!',
  },
] as const;

// 24 fine vertical micro-bars for high-resolution audio spectrum
const SPECTRUM_PROFILE = [
  24, 42, 68, 88, 54, 96, 74, 46, 82, 100, 64, 38, 76, 92, 58, 84, 98, 62, 44,
  86, 72, 52, 66, 32,
];

interface StreamChatAreaProps {
  userId: string;
  username: string;
  onSelectPlayer?: (member: Profile) => void;
  voiceControls?: VoiceControls;
}

export const StreamChatArea = memo(function StreamChatArea({
  userId,
  username,
  onSelectPlayer,
  voiceControls,
}: StreamChatAreaProps) {
  const activeServerId = useAppStore((s) => s.activeServerId) ?? 'srv-1';
  const activeChannelId = useAppStore((s) => s.activeChannelId);
  const activeVoiceChannelId = useAppStore((s) => s.activeVoiceChannelId);
  const activeDMUserId = useAppStore((s) => s.activeDMUserId);
  const channels = useAppStore((s) => s.channels);
  const friends = useAppStore((s) => s.friends);
  const onlineMembers = useAppStore((s) => s.onlineMembers);
  const storeMessages = useAppStore((s) => s.messages);
  const ecoActive = useAppStore((s) => s.ecoMode.isActive);

  const setActiveVoiceChannel = useAppStore((s) => s.setActiveVoiceChannel);
  const setActiveDMUser = useAppStore((s) => s.setActiveDMUser);

  const { sendMessage } = useRealtimeChat(activeChannelId);

  // Never allow the feed to render empty
  const messages =
    storeMessages.length > 0 ? storeMessages : INITIAL_TACTICAL_MESSAGES;

  // Individual operator gain (0-200%), mute, and 3D spatial audio pan (L/C/R)
  const [gains, setGains] = useState<Record<string, number>>({
    'usr-local': 100,
    'usr-1': 125,
    'usr-4': 115,
    'usr-2': 100,
    'usr-3': 95,
  });

  const [spatialPan, setSpatialPan] = useState<Record<string, SpatialPan>>({
    'usr-local': 'C',
    'usr-1': 'L',
    'usr-4': 'R',
    'usr-2': 'L',
    'usr-3': 'C',
  });

  const [mutedPeers, setMutedPeers] = useState<Record<string, boolean>>({});
  const [speakingPeers, setSpeakingPeers] = useState<Record<string, boolean>>({
    'usr-1': true,
    'usr-4': true,
    'usr-2': false,
    'usr-3': false,
    'usr-local': false,
  });

  const [pttActive, setPttActive] = useState(false);
  const [playingVoiceNoteId, setPlayingVoiceNoteId] = useState<string | null>(
    null,
  );
  const [stressTestActive, setStressTestActive] = useState(false);
  const [simMetrics, setSimMetrics] = useState({
    rtt: 11,
    jitter: 0.2,
    cpu: 0.3,
    ram: 14,
    buffer: 12,
    stability: 99.4,
  });

  const [input, setInput] = useState('');
  const bottomRef = useRef<HTMLDivElement>(null);

  // Live voice activity & telemetry simulation
  useEffect(() => {
    if (ecoActive) return;
    const interval = setInterval(() => {
      setSpeakingPeers((prev) => ({
        ...prev,
        'usr-1': Math.random() > 0.32,
        'usr-4': Math.random() > 0.42,
        'usr-2': Math.random() > 0.62,
        'usr-3': Math.random() > 0.72,
      }));

      if (stressTestActive) {
        setSimMetrics({
          rtt: Math.floor(18 + Math.random() * 14),
          jitter: Number((0.8 + Math.random() * 1.4).toFixed(1)),
          cpu: Number((0.4 + Math.random() * 0.3).toFixed(1)),
          ram: 15,
          buffer: Math.floor(28 + Math.random() * 16),
          stability: Number((94.2 + Math.random() * 3.5).toFixed(1)),
        });
      } else {
        setSimMetrics({
          rtt: Math.floor(10 + Math.random() * 3),
          jitter: Number((0.1 + Math.random() * 0.2).toFixed(1)),
          cpu: 0.3,
          ram: 14,
          buffer: 12,
          stability: Number((99.1 + Math.random() * 0.8).toFixed(1)),
        });
      }
    }, 1600);

    return () => clearInterval(interval);
  }, [ecoActive, stressTestActive]);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth', block: 'end' });
  }, [messages.length, activeChannelId, activeDMUserId]);

  const voiceChannels = channels.filter((c) => c.type === 'voice');
  const activeVoiceChannel =
    channels.find((c) => c.id === activeVoiceChannelId) ?? voiceChannels[0];
  const activeTextChannel = channels.find((c) => c.id === activeChannelId);
  const dmFriend = friends.find((f) => f.friend_id === activeDMUserId)?.friend;

  const triggerSelfSpeakingPulse = useCallback(() => {
    setSpeakingPeers((prev) => ({ ...prev, 'usr-local': true }));
    setTimeout(() => {
      setSpeakingPeers((prev) => ({ ...prev, 'usr-local': false }));
    }, 2200);
  }, []);

  const handleCallout = useCallback(
    (text: string) => {
      sendMessage(text);
      triggerSelfSpeakingPulse();
    },
    [sendMessage, triggerSelfSpeakingPulse],
  );

  const handleSubmit = useCallback(
    (e: React.FormEvent) => {
      e.preventDefault();
      if (!input.trim()) return;
      sendMessage(input);
      setInput('');
      triggerSelfSpeakingPulse();
    },
    [input, sendMessage, triggerSelfSpeakingPulse],
  );

  const handleInspectOperator = useCallback(
    (op: SquadOperatorMeta) => {
      if (!onSelectPlayer) return;
      const found = onlineMembers.find((m) => m.id === op.id);
      const loadout = op.loadoutByServer[activeServerId] ?? {
        agent: 'Taktik Operatör',
        detail: 'Hazır Kıta',
      };
      onSelectPlayer(
        found ?? {
          id: op.id,
          username: op.id === 'usr-local' ? username : op.username,
          avatar_url: null,
          status: 'in-game',
          activity: `${loadout.agent} (${loadout.detail})`,
          created_at: new Date().toISOString(),
        },
      );
    },
    [onlineMembers, onSelectPlayer, username, activeServerId],
  );

  const togglePeerMute = useCallback((id: string) => {
    setMutedPeers((prev) => ({ ...prev, [id]: !prev[id] }));
  }, []);

  const cycleSpatialPan = useCallback((id: string) => {
    setSpatialPan((prev) => {
      const curr = prev[id] ?? 'C';
      const next: SpatialPan = curr === 'L' ? 'C' : curr === 'C' ? 'R' : 'L';
      return { ...prev, [id]: next };
    });
  }, []);

  const handleGainChange = useCallback((id: string, val: number) => {
    setGains((prev) => ({ ...prev, [id]: val }));
    if (val > 0) {
      setMutedPeers((prev) => ({ ...prev, [id]: false }));
    }
  }, []);

  const activeRoomName = activeVoiceChannel
    ? cleanLabel(activeVoiceChannel.name)
    : 'Taktik Lobi #1';

  const chatTitle = dmFriend
    ? `@${dmFriend.username}`
    : activeTextChannel
      ? `#${cleanLabel(activeTextChannel.name)}`
      : '#genel-sohbet';

  return (
    <main className="flex-1 h-full flex flex-col overflow-y-auto lg:overflow-hidden min-w-0 gap-2.5 p-2 md:p-0 font-sans">
      {/* ═══════════════════════════════════════════════════════
          1. TOP STAGE: 5-OPERATOR LIVE SQUAD VOICE MATRIX
         ═══════════════════════════════════════════════════════ */}
      <section className="titanium-module rounded-sm p-3.5 md:p-4 flex flex-col gap-3 flex-shrink-0">
        {/* Matrix Header */}
        <div className="flex flex-wrap items-center justify-between gap-2 border-b border-white/[0.06] pb-2.5">
          <div className="flex items-center gap-2.5 min-w-0">
            <span className="w-2 h-2 rounded-full bg-[#10B981] shadow-[0_0_8px_#10B981] animate-pulse flex-shrink-0" />
            <div className="min-w-0">
              <div className="flex items-center gap-2 flex-wrap">
                <h2 className="font-sans text-[13px] md:text-sm font-bold tracking-tight text-gl-text-bright">
                  Canlı Operatör Ses Matrisi — {activeRoomName}
                </h2>
                <span className="rounded-sm px-2 py-0.5 bg-[#10B981]/12 border border-[#10B981]/35 font-mono text-[10px] font-bold text-[#10B981]">
                  5/5 P2P MESH
                </span>
                <span className="hidden sm:inline-block rounded-sm px-2 py-0.5 bg-[#F59E0B]/10 border border-[#F59E0B]/30 font-mono text-[10px] font-semibold text-[#F59E0B]">
                  96kbps Opus · 48kHz
                </span>
              </div>
            </div>
          </div>

          {/* Room Switcher Pills & Push-To-Talk */}
          <div className="flex items-center gap-1.5 flex-wrap">
            {voiceChannels.map((vc) => {
              const isSelected =
                vc.id === (activeVoiceChannelId ?? activeVoiceChannel?.id);
              return (
                <button
                  key={vc.id}
                  onClick={() => setActiveVoiceChannel(vc.id)}
                  className={`rounded-sm h-7 px-2.5 font-sans text-xs font-semibold border transition-all flex items-center gap-1.5 ${
                    isSelected
                      ? 'bg-[#12151E] text-[#F59E0B] border-[#F59E0B]/50'
                      : 'bg-[#06070A] text-gl-text-muted hover:text-gl-text-bright border-white/[0.06]'
                  }`}
                >
                  <IconVoiceWave size={12} />
                  <span>{cleanLabel(vc.name)}</span>
                </button>
              );
            })}

            <button
              onMouseDown={() => setPttActive(true)}
              onMouseUp={() => setPttActive(false)}
              onMouseLeave={() => setPttActive(false)}
              onClick={() => {
                setPttActive((v) => !v);
                triggerSelfSpeakingPulse();
              }}
              className={`rounded-sm h-7 px-3 font-sans text-xs font-bold border transition-all flex items-center gap-1.5 ${
                pttActive || speakingPeers['usr-local']
                  ? 'bg-[#10B981] text-[#06070A] border-[#10B981]'
                  : 'bg-[#06070A] text-gl-text-bright hover:border-[#F59E0B]/50 border-white/[0.08]'
              }`}
              title="Bas-Konuş (PTT)"
            >
              <IconMic size={12} />
              <span>{pttActive ? 'İletiliyor...' : 'Bas-Konuş (PTT)'}</span>
            </button>
          </div>
        </div>

        {/* 5-Operator Squad Pods Grid */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-2.5">
          {SQUAD_OPERATORS.map((op) => {
            const isSelf = op.id === 'usr-local';
            const displayName = isSelf ? username : op.username;
            const isMuted = isSelf
              ? (voiceControls?.isMuted ?? false) ||
                (mutedPeers[op.id] ?? false)
              : (mutedPeers[op.id] ?? false) || (gains[op.id] ?? 100) === 0;
            const isSpeaking =
              !isMuted &&
              (isSelf
                ? pttActive || (speakingPeers[op.id] ?? false)
                : (speakingPeers[op.id] ?? false));
            const gainVal = isMuted ? 0 : (gains[op.id] ?? 100);
            const pan = spatialPan[op.id] ?? 'C';
            const loadout = op.loadoutByServer[activeServerId] ?? {
              agent: 'Taktik Operatör',
              detail: 'Hazır Kıta',
            };

            return (
              <div
                key={op.id}
                className={`cockpit-pod hud-corners rounded-sm p-3 flex flex-col justify-between gap-2.5 transition-all duration-300 ${
                  isSpeaking
                    ? 'hud-corners-emerald border-[#10B981]/45 bg-[#0D1517]'
                    : isMuted
                      ? 'border-[#EF4444]/30 opacity-85'
                      : 'hover:border-white/[0.14]'
                }`}
              >
                {/* Pod Top: Avatar with Acoustic Ring + Callsign + Spatial & Mute Buttons */}
                <div className="flex items-start justify-between gap-1.5">
                  <button
                    type="button"
                    onClick={() => handleInspectOperator(op)}
                    className="flex items-center gap-2.5 min-w-0 text-left group"
                  >
                    <div
                      className={`relative rounded-sm transition-all duration-300 ${
                        isSpeaking
                          ? 'ring-2 ring-[#10B981]/70 shadow-[0_0_14px_rgba(16,185,129,0.35)]'
                          : ''
                      }`}
                    >
                      <OperatorAvatar
                        name={displayName}
                        status={
                          isMuted ? 'dnd' : isSpeaking ? 'online' : 'in-game'
                        }
                        size="md"
                        speaking={isSpeaking}
                      />
                    </div>
                    <div className="min-w-0">
                      <span className="block font-sans text-[13px] font-bold text-gl-text-bright group-hover:text-[#F59E0B] transition-colors leading-tight">
                        {displayName}
                      </span>
                      <span
                        className={`inline-block mt-1 rounded-sm px-1.5 py-0.2 border font-sans text-[9px] font-bold tracking-wider ${op.roleBadgeCls}`}
                      >
                        {op.role}
                      </span>
                    </div>
                  </button>

                  {/* Top-Right Controls: 3D Spatial Audio (L/C/R) + Individual Mute */}
                  <div className="flex items-center gap-1 flex-shrink-0">
                    <button
                      type="button"
                      onClick={() => cycleSpatialPan(op.id)}
                      title={`3D Konumsal Ses Yönü: ${
                        pan === 'L' ? 'Sol' : pan === 'R' ? 'Sağ' : 'Merkez'
                      } (Değiştirmek için tıklayın)`}
                      className="rounded-sm h-6 px-1.5 bg-[#06070A] hover:bg-[#12151E] border border-white/[0.07] font-mono text-[9px] font-bold text-gl-text-normal hover:text-[#F59E0B] transition-colors"
                    >
                      3D:{pan}
                    </button>

                    <button
                      type="button"
                      onClick={() =>
                        isSelf && voiceControls
                          ? voiceControls.toggleMute()
                          : togglePeerMute(op.id)
                      }
                      aria-label={isMuted ? 'Sesi Aç' : 'Sustur'}
                      title={
                        isMuted ? 'Operatör Sesini Aç' : 'Operatörü Bireysel Sustur'
                      }
                      className={`rounded-sm w-6 h-6 flex items-center justify-center border transition-colors ${
                        isMuted
                          ? 'bg-[#EF4444]/20 text-[#EF4444] border-[#EF4444]/50'
                          : 'bg-[#06070A] text-gl-text-muted hover:text-gl-text-bright border-white/[0.07]'
                      }`}
                    >
                      {isMuted ? (
                        <IconMicOff size={12} />
                      ) : (
                        <IconMic size={12} />
                      )}
                    </button>
                  </div>
                </div>

                {/* Pod Middle: Non-Truncated 2-Line Loadout Hierarchy + P2P Badge */}
                <div className="rounded-sm px-2.5 py-1.5 bg-[#06070A]/70 border border-white/[0.04] space-y-1">
                  <div className="text-[11px] font-sans font-semibold text-gl-text-bright leading-snug">
                    {loadout.agent}
                  </div>
                  <div className="flex items-center justify-between gap-1 text-[10px]">
                    <span className="font-sans text-gl-text-muted leading-tight">
                      {loadout.detail}
                    </span>
                    <span
                      className={`font-mono font-bold tabular-nums flex-shrink-0 ${
                        isMuted
                          ? 'text-[#EF4444]'
                          : isSpeaking
                            ? 'text-[#10B981]'
                            : 'text-[#F59E0B]'
                      }`}
                    >
                      {isMuted ? 'SESSİZ' : `${op.pingMs}ms P2P`}
                    </span>
                  </div>
                </div>

                {/* 24-Micro-Bar High-Resolution Audio Spectrum */}
                <div
                  onClick={() =>
                    setSpeakingPeers((p) => ({ ...p, [op.id]: !p[op.id] }))
                  }
                  title="Akustik spektrumu test etmek için tıklayın"
                  className="cursor-pointer rounded-sm h-8 px-2 py-1.5 bg-[#06070A] border border-white/[0.05] flex items-end justify-between gap-[2px]"
                >
                  {SPECTRUM_PROFILE.map((h, idx) => {
                    const animClass =
                      idx % 3 === 0
                        ? 'eq-bar-1'
                        : idx % 3 === 1
                          ? 'eq-bar-2'
                          : 'eq-bar-3';
                    return (
                      <span
                        key={idx}
                        className={`w-[2px] rounded-full transition-all duration-300 ${
                          isMuted
                            ? 'bg-[#EF4444]/40 h-[2px]'
                            : isSpeaking
                              ? idx % 4 === 0
                                ? `bg-[#F59E0B] ${animClass}`
                                : `bg-[#10B981] ${animClass}`
                              : 'bg-white/[0.14] h-[3px]'
                        }`}
                        style={
                          isSpeaking && !isMuted
                            ? {
                                height: `${Math.min(
                                  100,
                                  Math.max(18, Math.round((h * gainVal) / 115)),
                                )}%`,
                              }
                            : undefined
                        }
                      />
                    );
                  })}
                </div>

                {/* Pod Bottom: Interactive 0-200% Gain Slider */}
                <div className="pt-1 border-t border-white/[0.05] space-y-1">
                  <div className="flex items-center justify-between text-[10px]">
                    <span className="font-sans font-medium text-gl-text-muted">
                      Ses Kazancı ·{' '}
                      <span className="font-mono">{op.jitterMs}ms</span>
                    </span>
                    <span className="font-mono font-bold text-gl-text-bright tabular-nums">
                      %{gainVal}
                    </span>
                  </div>
                  <input
                    type="range"
                    min={0}
                    max={200}
                    step={5}
                    value={gainVal}
                    onChange={(e) =>
                      handleGainChange(op.id, Number(e.target.value))
                    }
                    aria-label={`${displayName} ses seviyesi`}
                    className="w-full h-1.5 accent-[#F59E0B] bg-[#06070A] rounded-full cursor-pointer"
                  />
                </div>
              </div>
            );
          })}
        </div>
      </section>

      {/* ═══════════════════════════════════════════════════════
          2. BOTTOM SPLIT DECK: TACTICAL STREAM (LEFT) + TELEMETRY (RIGHT)
         ═══════════════════════════════════════════════════════ */}
      <div className="flex-1 grid grid-cols-1 lg:grid-cols-12 gap-2.5 min-h-[360px] lg:min-h-0 overflow-hidden">
        {/* ── LEFT-BOTTOM MODULE (7 Cols): Tactical Comms & Callout Stream ── */}
        <section className="lg:col-span-7 titanium-module rounded-sm flex flex-col overflow-hidden min-h-[320px] lg:min-h-0">
          {/* Stream Header */}
          <div className="h-10 px-4 flex items-center justify-between border-b border-white/[0.06] bg-[#080A0F] flex-shrink-0">
            <div className="flex items-center gap-2 min-w-0">
              <span className="w-1.5 h-3.5 rounded-[1px] bg-[#F59E0B]" />
              <h3 className="font-sans text-xs font-bold tracking-wide text-gl-text-bright truncate">
                Taktiksel İletişim & Callout Akışı —{' '}
                <span className="text-[#F59E0B]">{chatTitle}</span>
              </h3>
            </div>

            <div className="flex items-center gap-2">
              {dmFriend && (
                <button
                  onClick={() => setActiveDMUser(null)}
                  className="rounded-sm px-2 py-0.5 bg-[#06070A] border border-white/[0.08] font-sans text-[10px] font-semibold text-[#F59E0B]"
                >
                  Genel Akışa Dön
                </button>
              )}
              <span className="font-mono text-[10px] text-[#10B981] font-semibold">
                {messages.length} Kayıt
              </span>
            </div>
          </div>

          {/* 1-Tap Instant Tactical Callout Bar */}
          <div className="px-3.5 py-2 bg-[#06070A]/90 border-b border-white/[0.05] flex items-center gap-1.5 overflow-x-auto no-scrollbar flex-shrink-0">
            <span className="font-sans text-[10px] font-bold uppercase tracking-wider text-[#F59E0B] mr-1 flex-shrink-0">
              Hızlı Çağrı:
            </span>
            {CALLOUTS.map((c) => (
              <button
                key={c.label}
                type="button"
                onClick={() => handleCallout(c.text)}
                className="rounded-sm h-7 px-2.5 flex-shrink-0 bg-[#12151E] hover:bg-[#EF4444] text-gl-text-bright hover:text-white border border-white/[0.07] hover:border-[#EF4444] font-sans text-[11px] font-bold tracking-wide transition-all active:scale-95"
              >
                {c.label}
              </button>
            ))}
          </div>

          {/* Rich Pre-Populated Scrim & Match Message Feed */}
          <div className="flex-1 overflow-y-auto px-4 py-3 space-y-2">
            {messages.map((msg) => {
              const isOwn =
                msg.author_id === userId || msg.author_id === 'usr-local';
              const isVoiceNote = msg.content.includes('[SESLİ BRİFİNG');
              const isCallout = msg.content.startsWith('[');
              const isRotateOrForce =
                msg.content.includes('ROTATE') || msg.content.includes('FORCE');
              const authorName = msg.author?.username ?? 'Operatör';
              const authorRole = msg.author?.activity ?? 'Taktik Kadro';
              const time = new Date(msg.created_at).toLocaleTimeString('tr-TR', {
                hour: '2-digit',
                minute: '2-digit',
                second: '2-digit',
              });
              const isPlayingThis = playingVoiceNoteId === msg.id;

              // Extract bracketed tag if present
              const bracketEnd = msg.content.indexOf(']');
              const tagText =
                isCallout && bracketEnd > 1
                  ? msg.content.slice(1, bracketEnd)
                  : null;
              const bodyText =
                tagText && bracketEnd > 1
                  ? msg.content.slice(bracketEnd + 1).trim()
                  : msg.content;

              return (
                <div
                  key={msg.id}
                  className={`rounded-sm px-3.5 py-2.5 border transition-colors ${
                    isRotateOrForce
                      ? 'bg-[#EF4444]/[0.07] border-[#EF4444]/40'
                      : isVoiceNote
                        ? 'bg-[#10B981]/[0.06] border-[#10B981]/35'
                        : isCallout
                          ? 'bg-[#F59E0B]/[0.06] border-[#F59E0B]/35'
                          : isOwn
                            ? 'bg-[#12151E] border-white/[0.08]'
                            : 'bg-[#06070A]/80 border-white/[0.05]'
                  }`}
                >
                  <div className="flex items-center justify-between gap-2 mb-1">
                    <div className="flex items-center gap-2 flex-wrap">
                      <span className="font-sans text-xs font-bold text-gl-text-bright">
                        {authorName}
                      </span>
                      <span className="font-sans text-[10px] font-medium text-gl-text-muted">
                        {authorRole}
                      </span>
                      {tagText && (
                        <span
                          className={`rounded-sm px-1.5 py-0.2 font-sans text-[10px] font-bold ${
                            isRotateOrForce
                              ? 'bg-[#EF4444]/20 text-[#EF4444]'
                              : isVoiceNote
                                ? 'bg-[#10B981]/20 text-[#10B981]'
                                : 'bg-[#F59E0B]/20 text-[#F59E0B]'
                          }`}
                        >
                          {tagText}
                        </span>
                      )}
                    </div>
                    <time className="font-mono text-[10px] text-gl-text-muted tabular-nums flex-shrink-0">
                      {time}
                    </time>
                  </div>

                  <p className="font-sans text-[13px] leading-relaxed text-gl-text-bright/95 break-words">
                    {bodyText}
                  </p>

                  {/* Interactive Voice Briefing Waveform Preview */}
                  {isVoiceNote && (
                    <div className="mt-2 rounded-sm px-3 py-1.5 bg-[#06070A] border border-white/[0.06] flex items-center gap-3">
                      <button
                        type="button"
                        onClick={() =>
                          setPlayingVoiceNoteId(isPlayingThis ? null : msg.id)
                        }
                        className="rounded-sm px-2 py-1 bg-[#10B981] text-[#06070A] font-sans text-[10px] font-bold flex items-center gap-1 flex-shrink-0"
                      >
                        <span>{isPlayingThis ? '■ DURDUR' : '▶ DİNLE'}</span>
                      </button>
                      <div className="flex-1 h-5 flex items-center gap-[2px]">
                        {SPECTRUM_PROFILE.map((v, i) => (
                          <span
                            key={i}
                            className={`flex-1 rounded-full ${
                              isPlayingThis
                                ? 'bg-[#10B981] eq-bar-2'
                                : 'bg-[#10B981]/50'
                            }`}
                            style={{ height: `${Math.max(22, v)}%` }}
                          />
                        ))}
                      </div>
                      <span className="font-mono text-[10px] text-[#10B981] flex-shrink-0">
                        0:08 · 96kbps
                      </span>
                    </div>
                  )}
                </div>
              );
            })}
            <div ref={bottomRef} />
          </div>

          {/* Command Input Form */}
          <form
            onSubmit={handleSubmit}
            className="p-2.5 bg-[#06070A] border-t border-white/[0.06] flex items-center gap-2 flex-shrink-0"
          >
            <input
              type="text"
              value={input}
              onChange={(e) => setInput(e.target.value)}
              placeholder={`${chatTitle} kanalına taktik mesaj veya round notu yazın...`}
              className="rounded-sm flex-1 min-w-0 h-10 px-3.5 bg-[#0C0E14] border border-white/[0.07] focus:border-[#F59E0B]/70 font-sans text-xs text-gl-text-bright placeholder:text-gl-text-muted outline-none transition-colors"
            />
            <button
              type="submit"
              disabled={!input.trim()}
              className="rounded-sm h-10 px-4 bg-[#EF4444] hover:bg-[#F87171] disabled:bg-[#12151E] disabled:text-gl-text-muted text-white font-sans text-xs font-bold flex items-center gap-1.5 transition-colors"
            >
              <IconSend size={14} />
              <span>Gönder</span>
            </button>
          </form>
        </section>

        {/* ── RIGHT-BOTTOM MODULE (5 Cols): Visualized Telemetry & 5-Vertex P2P Mesh Topology ── */}
        <section className="lg:col-span-5 titanium-module rounded-sm flex flex-col justify-between p-3.5 md:p-4 gap-3 overflow-y-auto">
          {/* Header + Interactive Stress Test Trigger */}
          <div className="flex items-center justify-between border-b border-white/[0.06] pb-2">
            <div className="flex items-center gap-2">
              <IconShield size={14} className="text-[#10B981]" />
              <h3 className="font-sans text-xs font-bold tracking-wide text-gl-text-bright">
                Meva P2P Mesh & Sistem Telemetrisi
              </h3>
            </div>
            <button
              type="button"
              onClick={() => setStressTestActive((v) => !v)}
              className={`rounded-sm px-2.5 py-1 font-sans text-[10px] font-bold border transition-all ${
                stressTestActive
                  ? 'bg-[#EF4444]/20 text-[#EF4444] border-[#EF4444]/60 animate-pulse'
                  : 'bg-[#06070A] text-gl-text-normal hover:text-gl-text-bright border-white/[0.08]'
              }`}
            >
              {stressTestActive ? 'Simülasyon Aktif (Kapat)' : 'Ağ Stres Testi'}
            </button>
          </div>

          {/* 4 KPI Cards with Embedded Live Mini-Charts */}
          <div className="grid grid-cols-2 gap-2">
            {/* Card 1: Audio Engine + Mini Sparkline Bars */}
            <div className="rounded-sm p-2.5 bg-[#06070A] border border-white/[0.05] flex items-center justify-between gap-2">
              <div>
                <span className="font-sans text-[10px] font-medium text-gl-text-muted block">
                  Ses Motoru
                </span>
                <span className="font-mono text-xs font-bold text-[#10B981] mt-0.5 block">
                  Opus 48kHz
                </span>
                <span className="font-mono text-[10px] text-gl-text-muted">
                  96kbps CBR
                </span>
              </div>
              <div className="flex items-end gap-[2px] h-7">
                {[55, 80, 95, 70, 100, 85, 90].map((v, i) => (
                  <span
                    key={i}
                    className="w-[3px] rounded-full bg-[#10B981]/80 eq-bar-1"
                    style={{ height: `${v}%` }}
                  />
                ))}
              </div>
            </div>

            {/* Card 2: In-Game FPS Impact + Flatline Sparkline SVG */}
            <div className="rounded-sm p-2.5 bg-[#06070A] border border-white/[0.05] flex items-center justify-between gap-2">
              <div>
                <span className="font-sans text-[10px] font-medium text-gl-text-muted block">
                  Oyun Etkisi
                </span>
                <span className="font-mono text-xs font-bold text-[#F59E0B] mt-0.5 block">
                  0 FPS Kaybı
                </span>
                <span className="font-sans text-[10px] text-gl-text-muted">
                  Game-Boost
                </span>
              </div>
              <svg width="42" height="24" viewBox="0 0 42 24" className="flex-shrink-0">
                <polyline
                  fill="none"
                  stroke="#F59E0B"
                  strokeWidth="2"
                  points="0,8 8,8 16,7 24,8 32,8 42,7"
                />
                <line
                  x1="0"
                  y1="20"
                  x2="42"
                  y2="20"
                  stroke="rgba(255,255,255,0.08)"
                  strokeWidth="1"
                />
              </svg>
            </div>

            {/* Card 3: System Load + Circular Radial Gauge */}
            <div className="rounded-sm p-2.5 bg-[#06070A] border border-white/[0.05] flex items-center justify-between gap-2">
              <div>
                <span className="font-sans text-[10px] font-medium text-gl-text-muted block">
                  Sistem Yükü
                </span>
                <span className="font-mono text-xs font-bold text-gl-text-bright mt-0.5 block">
                  %{simMetrics.cpu} CPU
                </span>
                <span className="font-mono text-[10px] text-[#10B981]">
                  {simMetrics.ram}MB RAM
                </span>
              </div>
              <svg width="32" height="32" viewBox="0 0 36 36" className="flex-shrink-0">
                <circle
                  cx="18"
                  cy="18"
                  r="14"
                  fill="none"
                  stroke="rgba(255,255,255,0.08)"
                  strokeWidth="3.5"
                />
                <circle
                  cx="18"
                  cy="18"
                  r="14"
                  fill="none"
                  stroke="#10B981"
                  strokeWidth="3.5"
                  strokeDasharray="88"
                  strokeDashoffset={stressTestActive ? '68' : '78'}
                  strokeLinecap="round"
                />
              </svg>
            </div>

            {/* Card 4: Net-Guard Adaptive Buffer & Stability */}
            <div className="rounded-sm p-2.5 bg-[#06070A] border border-white/[0.05] flex items-center justify-between gap-2">
              <div>
                <span className="font-sans text-[10px] font-medium text-gl-text-muted block">
                  Ağ İstikrarı
                </span>
                <span className="font-mono text-xs font-bold text-[#10B981] mt-0.5 block">
                  %{simMetrics.stability}
                </span>
                <span className="font-mono text-[10px] text-gl-text-muted">
                  Buffer: {simMetrics.buffer}ms
                </span>
              </div>
              <div className="flex flex-col items-end gap-1">
                <span className="font-mono text-[10px] font-bold text-[#F59E0B]">
                  {simMetrics.rtt}ms
                </span>
                <div className="w-10 h-1.5 bg-white/10 rounded-full overflow-hidden">
                  <div
                    className={`h-full transition-all duration-300 ${
                      stressTestActive ? 'w-3/4 bg-[#F59E0B]' : 'w-full bg-[#10B981]'
                    }`}
                  />
                </div>
              </div>
            </div>
          </div>

          {/* Expanded 5-Vertex Pentagon P2P Mesh Topology Radar (Interactive SVG) */}
          <div className="flex-1 rounded-sm p-3 bg-[#06070A] border border-white/[0.05] flex flex-col justify-between min-h-[155px]">
            <div className="flex items-center justify-between">
              <span className="font-sans text-[11px] font-bold text-gl-text-bright">
                5-Köşeli Doğrudan P2P Mesh Topolojisi
              </span>
              <span className="font-mono text-[10px] text-[#10B981] font-semibold">
                10 Aktif Tünel · {simMetrics.jitter}ms Jitter
              </span>
            </div>

            <div className="flex items-center justify-between gap-3 my-auto py-1">
              <svg
                width="170"
                height="126"
                viewBox="0 0 180 132"
                className="mx-auto flex-shrink-0"
                aria-label="5-Köşeli P2P Mesh Ağ Topolojisi"
              >
                {/* Concentric Radar Rings */}
                <circle
                  cx="90"
                  cy="68"
                  r="52"
                  fill="none"
                  stroke="rgba(255,255,255,0.04)"
                  strokeDasharray="3 3"
                />
                <circle
                  cx="90"
                  cy="68"
                  r="28"
                  fill="none"
                  stroke="rgba(255,255,255,0.04)"
                />

                {/* All 10 Pentagon Full-Mesh Connections */}
                <g
                  stroke={
                    stressTestActive
                      ? 'rgba(245, 158, 11, 0.45)'
                      : 'rgba(16, 185, 129, 0.32)'
                  }
                  strokeWidth="1.2"
                >
                  <line id="p1" x1="90" y1="14" x2="34" y2="52" />
                  <line id="p2" x1="90" y1="14" x2="146" y2="52" />
                  <line id="p3" x1="90" y1="14" x2="54" y2="116" />
                  <line id="p4" x1="90" y1="14" x2="126" y2="116" />
                  <line id="p5" x1="34" y1="52" x2="146" y2="52" />
                  <line x1="34" y1="52" x2="54" y2="116" />
                  <line x1="34" y1="52" x2="126" y2="116" />
                  <line x1="146" y1="52" x2="54" y2="116" />
                  <line x1="146" y1="52" x2="126" y2="116" />
                  <line x1="54" y1="116" x2="126" y2="116" />
                </g>

                {/* Flowing Live P2P Audio Data Packets */}
                <circle r="2.5" fill="#10B981">
                  <animateMotion
                    dur={stressTestActive ? '0.9s' : '1.6s'}
                    repeatCount="indefinite"
                    path="M90,14 L34,52 L54,116 L126,116 L146,52 Z"
                  />
                </circle>
                <circle r="2.5" fill="#F59E0B">
                  <animateMotion
                    dur={stressTestActive ? '1.1s' : '2.1s'}
                    repeatCount="indefinite"
                    path="M90,14 L126,116 L34,52 L146,52 L54,116 Z"
                  />
                </circle>

                {/* 5 Operator Vertices + Callsign Labels */}
                <g className="font-sans" fontSize="9" fontWeight="700" fill="#F3F4F6">
                  {/* Top: Operatör */}
                  <circle cx="90" cy="14" r="5.5" fill="#F59E0B" />
                  <text x="90" y="7" textAnchor="middle">
                    SEN (9ms)
                  </text>

                  {/* Left: cNed */}
                  <circle cx="34" cy="52" r="5" fill="#10B981" />
                  <text x="24" y="46" textAnchor="end">
                    cNed
                  </text>

                  {/* Right: XANTARES */}
                  <circle cx="146" cy="52" r="5" fill="#10B981" />
                  <text x="154" y="46" textAnchor="start">
                    XANTARES
                  </text>

                  {/* Bottom-Left: woxic */}
                  <circle cx="54" cy="116" r="5" fill="#F59E0B" />
                  <text x="46" y="128" textAnchor="end">
                    woxic
                  </text>

                  {/* Bottom-Right: Alfajer */}
                  <circle cx="126" cy="116" r="5" fill="#EF4444" />
                  <text x="134" y="128" textAnchor="start">
                    Alfajer
                  </text>
                </g>
              </svg>

              <div className="hidden sm:flex flex-col justify-center space-y-1.5 text-[11px] border-l border-white/[0.05] pl-3">
                <div>
                  <span className="text-gl-text-muted block text-[10px]">
                    Mimari
                  </span>
                  <span className="font-semibold text-gl-text-bright">
                    Tam Örgü (Full-Mesh)
                  </span>
                </div>
                <div>
                  <span className="text-gl-text-muted block text-[10px]">
                    Şifreleme
                  </span>
                  <span className="font-mono text-[11px] font-bold text-[#10B981]">
                    DTLS-SRTP
                  </span>
                </div>
                <div>
                  <span className="text-gl-text-muted block text-[10px]">
                    Sunucu Maliyeti
                  </span>
                  <span className="font-mono text-[11px] font-bold text-[#F59E0B]">
                    $0.00 / Ay
                  </span>
                </div>
              </div>
            </div>
          </div>
        </section>
      </div>
    </main>
  );
});
