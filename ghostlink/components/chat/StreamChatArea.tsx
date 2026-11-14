'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Forged Oxblood & Titanium Executive Cockpit
// ─────────────────────────────────────────────────────────
//   • Desktop (>= 1024px): 100dvh zero-overflow 3-Module Bento War Room
//   • Mobile / Tablet (< 1024px): Dedicated, spacious, thumb-ergonomic
//     multi-view architecture (İletişim + Canlı Ses Şeridi | Ses Matrisi |
//     P2P Ağ & Scrim) synchronized with MobileBottomNav.

import { memo, useCallback, useEffect, useMemo, useRef, useState } from 'react';
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
import { getMevaCryptoEngine } from '@/src/lib/cryptoEngine';
import {
  getMevaTelemetryEngine,
  type MeshTelemetrySummary,
} from '@/src/lib/telemetryEngine';
import { E2eeFingerprintPopover } from '@/components/chat/E2eeFingerprintPopover';
import { MeshNodeInspectModal } from '@/components/hud/MeshNodeInspectModal';
import {
  OperatorContextMenu,
  type OperatorContextTarget,
} from '@/components/ui/OperatorContextMenu';
import { cleanLabel } from '@/lib/format';
import {
  detectGameFromChannel,
  getGameById,
  SUPPORTED_GAMES,
  type GameRoleDef,
} from '@/src/lib/gameRegistry';
import { OperatorAvatar, FluidWave } from '@/components/ui/HudPrimitives';
import {
  IconVoiceWave,
  IconMic,
  IconMicOff,
  IconSend,
  IconShield,
  IconBolt,
  IconGauge,
  IconMoreDots,
  IconMevaMark,
  IconPlus,
} from '@/components/ui/MevaIcons';
import type { Message, Profile, VoiceControls } from '@/types';

interface SquadOperatorMeta {
  id: string;
  username: string;
  role: string;
  roleTone: 'burgundy' | 'bronze' | 'neutral';
  pingMs: number;
  waveSpeed: number;
}

const CpuLoadBadge = memo(function CpuLoadBadge({
  fallbackCpu,
}: {
  fallbackCpu: number;
}) {
  const ecoCpu = useAppStore((s) => s.ecoMode.cpuEstimate);
  return <>{ecoCpu > 0 ? ecoCpu : fallbackCpu}</>;
});

const MESH_NODES: Array<{
  opIndex: number;
  cx: number;
  cy: number;
  tx: number;
  ty: number;
  anchor: 'middle' | 'start' | 'end';
  tone: 'ruby' | 'bronze';
  r: number;
}> = [
  {
    opIndex: 0,
    cx: 160,
    cy: 22,
    tx: 160,
    ty: 10,
    anchor: 'middle',
    tone: 'ruby',
    r: 6,
  },
  {
    opIndex: 1,
    cx: 82,
    cy: 66,
    tx: 69,
    ty: 69,
    anchor: 'end',
    tone: 'bronze',
    r: 5.5,
  },
  {
    opIndex: 2,
    cx: 238,
    cy: 66,
    tx: 251,
    ty: 69,
    anchor: 'start',
    tone: 'bronze',
    r: 5.5,
  },
  {
    opIndex: 3,
    cx: 108,
    cy: 142,
    tx: 95,
    ty: 146,
    anchor: 'end',
    tone: 'ruby',
    r: 5.5,
  },
  {
    opIndex: 4,
    cx: 212,
    cy: 142,
    tx: 225,
    ty: 146,
    anchor: 'start',
    tone: 'ruby',
    r: 5.5,
  },
];

const ROLE_BADGE_STYLE: Record<SquadOperatorMeta['roleTone'], string> = {
  burgundy:
    'bg-[#7A121D]/30 text-[#F29AA3] border-[#961826]/45',
  bronze:
    'bg-[#4A1118]/35 text-[#E0B0B6] border-[#6E1620]/45',
  neutral:
    'bg-[#170C10] text-[#B8AAAC] border-[#2E161D]',
};

const PAN_TITLE: Record<'L' | 'C' | 'R', string> = {
  L: '3D Sahne: Sol (-1.0) · Değiştirmek için tıklayın',
  C: '3D Sahne: Merkez (0.0) · Değiştirmek için tıklayın',
  R: '3D Sahne: Sağ (+1.0) · Değiştirmek için tıklayın',
};

const CALLOUTS: ReadonlyArray<{
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
    text: '[DROP İSTEĞİ] Silah / AWP drop gerekiyor, kredisi uygun olan atsın.',
  },
  {
    label: 'Force',
    cue: 'force',
    text: '[FORCE BUY] Kritik tur! Tam teçhizat çekiyoruz.',
  },
  {
    label: 'GG WP',
    cue: 'gg',
    text: '[GG WP] Kusursuz iletişim ve sıfır gecikme, elinize sağlık takım.',
  },
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
  const activeServerId = useAppStore((s) => s.activeServerId);
  const activeChannelId = useAppStore((s) => s.activeChannelId);
  const activeVoiceChannelId = useAppStore((s) => s.activeVoiceChannelId);
  const activeDMUserId = useAppStore((s) => s.activeDMUserId);
  const servers = useAppStore((s) => s.servers);
  const channels = useAppStore((s) => s.channels);
  const friends = useAppStore((s) => s.friends);
  const onlineMembers = useAppStore((s) => s.onlineMembers);
  const storeMessages = useAppStore((s) => s.messages);
  const ecoActive = useAppStore((s) => s.ecoMode.isActive);
  const ecoEnabled = useAppStore((s) => s.ecoMode.isEnabled);
  const activeScrim = useAppStore((s) => s.activeScrimRoom);
  const mobileTab = useAppStore((s) => s.mobileTab);
  const voiceParticipants = useAppStore((s) => s.voiceParticipants);
  const slotBeacons = useAppStore((s) => s.slotBeacons);
  const setSlotBeacon = useAppStore((s) => s.setSlotBeacon);
  const clearSlotBeacon = useAppStore((s) => s.clearSlotBeacon);
  const duoLink = useAppStore((s) => s.duoLink);
  const setDuoLinkPartner = useAppStore((s) => s.setDuoLinkPartner);
  const setDuoLinkActive = useAppStore((s) => s.setDuoLinkActive);
  const activeSonarTargetId = useAppStore((s) => s.activeSonarTargetId);
  const triggerSonarPulse = useAppStore((s) => s.triggerSonarPulse);
  const setSelectedGameFilter = useAppStore((s) => s.setSelectedGameFilter);
  const [inviteCopied, setInviteCopied] = useState(false);
  const [beaconToast, setBeaconToast] = useState<string | null>(null);

  const setActiveVoiceChannel = useAppStore((s) => s.setActiveVoiceChannel);
  const setActiveDMUser = useAppStore((s) => s.setActiveDMUser);
  const setMobileTab = useAppStore((s) => s.setMobileTab);
  const setShowScrimModal = useAppStore((s) => s.setShowScrimModal);
  const setShowChannelBuilderModal = useAppStore((s) => s.setShowChannelBuilderModal);
  const setShowTourModal = useAppStore((s) => s.setShowTourModal);
  const setShowLobbyGate = useAppStore((s) => s.setShowLobbyGate);
  const toggleEcoEnabled = useAppStore((s) => s.toggleEcoEnabled);

  const { sendMessage } = useRealtimeChat(activeChannelId);

  const activeVoiceChannel = useMemo(
    () => channels.find((c) => c.id === activeVoiceChannelId),
    [channels, activeVoiceChannelId],
  );

  const activeGame = useMemo(() => {
    if (activeVoiceChannel) {
      return activeVoiceChannel.game_id
        ? getGameById(activeVoiceChannel.game_id)
        : detectGameFromChannel(activeVoiceChannel.name, activeVoiceChannel.tags);
    }
    return SUPPORTED_GAMES.cs2;
  }, [activeVoiceChannel]);

  const dynamicCallouts = useMemo(() => {
    return activeGame.callouts.map((label: string) => ({
      label,
      cue: 'rotate' as CalloutCueType,
      text: `[${activeGame.shortName.toUpperCase()} TAKTİK]: ${label}`,
    }));
  }, [activeGame]);

  const messages =
    storeMessages.length > 0 ? storeMessages : INITIAL_TACTICAL_MESSAGES;

  const gains = useHUDStore((s) => s.playerGains);
  const mutedPeers = useHUDStore((s) => s.localMutes);
  const spatialPans = useHUDStore((s) => s.spatialPans);
  const operatorRoles = useHUDStore((s) => s.operatorRoles);
  const prioritySpeakers = useHUDStore((s) => s.prioritySpeakers);
  const iglDuckingEnabled = useHUDStore((s) => s.iglDuckingEnabled);
  const setPlayerGain = useHUDStore((s) => s.setPlayerGain);
  const togglePeerMute = useHUDStore((s) => s.toggleLocalMute);
  const cycleSpatialPan = useHUDStore((s) => s.cycleSpatialPan);

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
  const [telemetry, setTelemetry] = useState<MeshTelemetrySummary>(() =>
    getMevaTelemetryEngine().getSummary(),
  );
  const [inspectedNodeId, setInspectedNodeId] = useState<string | null>(null);
  const [contextTarget, setContextTarget] =
    useState<OperatorContextTarget | null>(null);
  const stressTestActive = telemetry.stressActive;
  const simMetrics = {
    rtt: telemetry.rttMs,
    jitter: telemetry.jitterMs,
    cpu: telemetry.cpuPercent,
    stability: telemetry.stabilityPercent,
  };

  const [input, setInput] = useState('');
  const [searchOpen, setSearchOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [activeTagFilter, setActiveTagFilter] = useState<string | null>(null);
  const [showFingerprintModal, setShowFingerprintModal] = useState(false);
  const [localFingerprint, setLocalFingerprint] = useState('ECDH-256');
  const [copiedMsgId, setCopiedMsgId] = useState<string | null>(null);

  const bottomRef = useRef<HTMLDivElement>(null);
  const pulseTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    const cryptoEngine = getMevaCryptoEngine();
    void cryptoEngine.initialize();
    if (typeof window !== 'undefined') {
      (window as any).__MEVA_STORE__ = useAppStore;
      (window as any).__MEVA_HUD_STORE__ = useHUDStore;
    }
    return cryptoEngine.subscribeStatus((snap) => {
      if (snap.initialized) {
        setLocalFingerprint(snap.localFingerprint.slice(0, 9));
      }
    });
  }, []);

  // Duo-Link Tactical Alt-PTT Hotkey listener ('KeyB')
  useEffect(() => {
    if (!duoLink.partnerId) return;
    const handleKeyDown = (e: KeyboardEvent) => {
      if (
        e.target instanceof HTMLInputElement ||
        e.target instanceof HTMLTextAreaElement ||
        (e.target as HTMLElement)?.isContentEditable
      ) {
        return;
      }
      if (e.code === 'KeyB' && !e.repeat) {
        setDuoLinkActive(true);
      }
    };
    const handleKeyUp = (e: KeyboardEvent) => {
      if (e.code === 'KeyB') {
        setDuoLinkActive(false);
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    window.addEventListener('keyup', handleKeyUp);
    return () => {
      window.removeEventListener('keydown', handleKeyDown);
      window.removeEventListener('keyup', handleKeyUp);
    };
  }, [duoLink.partnerId, setDuoLinkActive]);

  const filteredMessages = useMemo(() => {
    const q = searchQuery.trim().toLowerCase();
    return messages.filter((m) => {
      if (activeTagFilter && !m.content.toUpperCase().includes(activeTagFilter)) {
        return false;
      }
      if (!q) return true;
      return (
        m.content.toLowerCase().includes(q) ||
        (m.author?.username.toLowerCase().includes(q) ?? false)
      );
    });
  }, [messages, searchQuery, activeTagFilter]);

  const handleCopyMessage = useCallback(async (msg: Message) => {
    try {
      await navigator.clipboard?.writeText(msg.content);
      setCopiedMsgId(msg.id);
      setTimeout(() => {
        setCopiedMsgId((curr) => (curr === msg.id ? null : curr));
      }, 1500);
    } catch {}
  }, []);

  const handleInsertTacticalTag = useCallback((tag: string) => {
    setInput((prev) => {
      const stripped = prev.replace(/^\[[^\]]+\]\s*/, '');
      return `[${tag}] ${stripped}`;
    });
  }, []);

  useEffect(() => {
    return () => {
      if (pulseTimerRef.current) clearTimeout(pulseTimerRef.current);
    };
  }, []);

  // Bind real VAD/PTT engine + real WebRTC/Crypto Telemetry engine
  useEffect(() => {
    const vad = getMevaVadEngine();
    const unsubVad = vad.subscribe((snap) => {
      setPttActive(snap.pttPressed);
      setSpeakingPeers((prev) => {
        const wasSpeaking = Boolean(prev['usr-local']);
        if (wasSpeaking === snap.transmitting) return prev;
        return { ...prev, 'usr-local': snap.transmitting };
      });
    });

    const tel = getMevaTelemetryEngine();
    tel.start();
    const unsubTel = tel.subscribe(setTelemetry);

    return () => {
      unsubVad();
      unsubTel();
    };
  }, []);

  // Apply IGL Priority Ducking (-30% on non-priority peers when IGL speaks)
  useEffect(() => {
    const prioSet = new Set(
      Object.entries(prioritySpeakers)
        .filter(([, active]) => active)
        .map(([id]) => id),
    );
    const anyPrioSpeaking = Array.from(prioSet).some((id) =>
      id === 'usr-local'
        ? pttActive || Boolean(speakingPeers['usr-local'])
        : Boolean(speakingPeers[id]),
    );
    getMevaAudioEngine().applyPriorityDucking(
      anyPrioSpeaking,
      prioSet,
      iglDuckingEnabled,
    );
  }, [prioritySpeakers, speakingPeers, pttActive, iglDuckingEnabled]);

  const handleToggleStressTest = useCallback(() => {
    const tel = getMevaTelemetryEngine();
    tel.setStressTest(!tel.getSummary().stressActive);
  }, []);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth', block: 'end' });
  }, [messages.length, activeChannelId, activeDMUserId]);

  const voiceChannels = useMemo(() => {
    return channels.filter(
      (c) => c.type === 'voice' && (!activeServerId || !c.server_id || c.server_id === activeServerId),
    );
  }, [channels, activeServerId]);
  const activeTextChannel = channels.find((c) => c.id === activeChannelId);
  const dmUser = useMemo(() => {
    if (!activeDMUserId) return null;
    const friendUser = friends.find((f) => f.friend_id === activeDMUserId)?.friend;
    if (friendUser) return friendUser;
    const memberUser = onlineMembers.find((m) => m.id === activeDMUserId);
    if (memberUser) return memberUser;
    return { id: activeDMUserId, username: 'Operatör' } as Profile;
  }, [activeDMUserId, friends, onlineMembers]);

  const triggerSelfSpeakingPulse = useCallback(() => {
    setSpeakingPeers((prev) => ({ ...prev, 'usr-local': true }));
    if (pulseTimerRef.current) clearTimeout(pulseTimerRef.current);
    pulseTimerRef.current = setTimeout(() => {
      setSpeakingPeers((prev) => ({ ...prev, 'usr-local': false }));
    }, 2000);
  }, []);

  const handleCallout = useCallback(
    (text: string, cue?: CalloutCueType) => {
      if (cue) {
        getMevaAudioEngine().playCalloutCue(cue);
      }
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
      onSelectPlayer(
        found ?? {
          id: op.id,
          username: op.id === 'usr-local' ? username : op.username,
          avatar_url: null,
          status: 'in-game',
          activity: op.role,
          created_at: '2026-11-06T19:00:00.000Z',
        },
      );
    },
    [onlineMembers, onSelectPlayer, username],
  );

  const activeRoomName = activeVoiceChannel
    ? cleanLabel(activeVoiceChannel.name)
    : activeVoiceChannelId?.startsWith('scrim-')
      ? `Scrim #${activeVoiceChannelId.slice(6)}`
      : 'Taktik Lobi #1';

  const chatTitle = dmUser
    ? `@${dmUser.username}`
    : activeTextChannel
      ? `#${cleanLabel(activeTextChannel.name)}`
      : '#genel-sohbet';

  const selfMuted =
    (voiceControls?.isMuted ?? false) || Boolean(mutedPeers['usr-local']);
  const selfTransmitting =
    !selfMuted &&
    (pttActive ||
      Boolean(voiceControls?.isSpeaking) ||
      Boolean(speakingPeers['usr-local']));

  const activePeers = useMemo(() => {
    return voiceParticipants.filter(
      (p) => p.user_id !== 'usr-local' && p.user_id !== userId,
    );
  }, [voiceParticipants, userId]);

  const activeSquadOperators = useMemo<SquadOperatorMeta[]>(() => {
    const list: SquadOperatorMeta[] = [
      {
        id: 'usr-local',
        username: username || 'Operatör',
        role:
          operatorRoles['usr-local'] ??
          activeGame.roles[0]?.shortLabel ??
          'IGL',
        roleTone: 'burgundy',
        pingMs: 9,
        waveSpeed: 1.35,
      },
    ];

    for (let i = 0; i < activePeers.length && list.length < 5; i++) {
      const p = activePeers[i];
      const fallbackRole =
        activeGame.roles[(i + 1) % activeGame.roles.length]?.shortLabel ??
        'ENTRY';
      const role = operatorRoles[p.user_id] ?? fallbackRole;
      list.push({
        id: p.user_id,
        username: p.username || `Operatör #${i + 2}`,
        role,
        roleTone:
          role.includes('IGL') || role.includes('MID') || role.includes('JUNGLE')
            ? 'burgundy'
            : role.includes('AWP') || role.includes('ADC') || role.includes('CARRY')
              ? 'bronze'
              : 'neutral',
        pingMs: telemetry.nodes[p.user_id]?.rttMs ?? 11,
        waveSpeed: 1.2,
      });
    }

    return list;
  }, [username, operatorRoles, activePeers, telemetry.nodes, activeGame]);

  const renderOperatorCards = (mobileComfort: boolean) => {
    const cards = activeSquadOperators.map((op) => {
      const isSelf = op.id === 'usr-local';
      const displayName = isSelf ? username : op.username;
      const isMuted = isSelf
        ? selfMuted
        : Boolean(mutedPeers[op.id]) || (gains[op.id] ?? 100) === 0;
      const isSpeaking =
        !isMuted &&
        (isSelf ? selfTransmitting : Boolean(speakingPeers[op.id]));
      const gainVal = isMuted ? 0 : (gains[op.id] ?? 100);
      const pan = spatialPans[op.id] ?? 'C';
      const activeRole = operatorRoles[op.id] ?? op.role;
      const isBoosted = gainVal > 100;
      const livePing = telemetry.nodes[op.id]?.rttMs ?? op.pingMs;

      const isDuoPartner = !isSelf && duoLink.partnerId === op.id;
      const isDuoTransmitting = isDuoPartner && duoLink.isTransmitting;
      const isSonarTarget = activeSonarTargetId === op.id;

      return (
        <div
          key={op.id}
          onContextMenu={(e) => {
            e.preventDefault();
            setContextTarget({
              id: op.id,
              username: displayName,
              x: e.clientX,
              y: e.clientY,
              pingMs: livePing,
            });
          }}
          className={`cockpit-pod rounded-xl ${
            mobileComfort ? 'p-3.5 gap-2.5' : 'p-3 gap-2'
          } flex flex-col justify-between transition-all duration-200 ${
            isSonarTarget
              ? 'ring-2 ring-[#FF334B] shadow-[0_0_26px_rgba(255,51,75,0.75)] border-[#FF334B] animate-pulse'
              : isDuoTransmitting
                ? 'bg-[#07242E] border-cyan-400 shadow-[0_0_22px_rgba(6,182,212,0.6)]'
                : isDuoPartner
                  ? 'border-cyan-500/70 shadow-[0_0_14px_rgba(6,182,212,0.35)] bg-[#07171C]/80'
                  : isSpeaking
                    ? 'cockpit-pod-live'
                    : isMuted
                      ? 'cockpit-pod-muted opacity-85'
                      : ''
          }`}
        >
          {/* Row 1: Avatar + Full Unclipped Name + Mute + Tactical Menu */}
          <div className="flex items-center justify-between gap-1.5">
            <button
              type="button"
              onClick={() => handleInspectOperator(op)}
              className="flex items-center gap-2.5 min-w-0 text-left group"
            >
              <OperatorAvatar
                name={displayName}
                status={isMuted ? 'dnd' : isSpeaking ? 'online' : 'in-game'}
                size={mobileComfort ? 'md' : 'sm'}
                speaking={isSpeaking}
              />
              <div className="min-w-0 flex-1">
                <div className="flex items-center gap-1.5 min-w-0">
                  <span className="block text-[12.5px] font-bold text-[#F4EFF0] group-hover:text-[#F29AA3] transition-colors truncate leading-tight">
                    {displayName}
                  </span>
                  {isDuoPartner && (
                    <span className="text-[9px] font-black px-1 py-0.2 rounded bg-cyan-950 text-cyan-300 border border-cyan-500/60 shadow-[0_0_6px_rgba(6,182,212,0.4)] animate-pulse flex-shrink-0">
                      {isDuoTransmitting ? 'DUO CANLI' : 'DUO'}
                    </span>
                  )}
                </div>
                {mobileComfort && (
                  <span className="block text-[11px] font-semibold text-[#827376] mt-0.5">
                    {isMuted
                      ? 'Mikrofon Kapalı'
                      : isSpeaking
                        ? 'Canlı İletimde'
                        : 'Bağlı · Hazır'}
                  </span>
                )}
              </div>
            </button>

            <div className="flex items-center gap-1 flex-shrink-0">
              <button
                type="button"
                onClick={() =>
                  isSelf && voiceControls
                    ? voiceControls.toggleMute()
                    : togglePeerMute(op.id)
                }
                aria-label={isMuted ? 'Sesi aç' : 'Sustur'}
                title={isMuted ? 'Sesi aç' : 'Operatörü sustur'}
                className={`rounded-lg ${
                  mobileComfort ? 'w-9 h-9' : 'w-7 h-7'
                } flex items-center justify-center border flex-shrink-0 transition-colors ${
                  isMuted
                    ? 'bg-[#8F1622]/25 text-[#F08C96] border-[#C82333]/50'
                    : 'bg-[#120A0D] text-[#9E8E91] hover:text-[#F4EFF0] border-[#281318] hover:border-[#4A1C26]'
                }`}
              >
                {isMuted ? <IconMicOff size={14} /> : <IconMic size={14} />}
              </button>
              <button
                type="button"
                onClick={(e) => {
                  const rect = e.currentTarget.getBoundingClientRect();
                  setContextTarget({
                    id: op.id,
                    username: displayName,
                    x: rect.left,
                    y: rect.bottom + 6,
                    pingMs: livePing,
                  });
                }}
                aria-label={`${displayName} taktik komuta menüsü`}
                title="Taktik Komuta Menüsü (Duo-Link, Sonar, 3D Ses)"
                className={`rounded-lg ${
                  mobileComfort ? 'w-9 h-9' : 'w-7 h-7'
                } flex items-center justify-center bg-[#120A0D] text-[#8E7E81] hover:text-[#F4EFF0] border border-[#281318] hover:border-[#4A1C26] transition-colors`}
              >
                <IconMoreDots size={13} />
              </button>
            </div>
          </div>

          {/* Row 2: Single Role Badge + 3D Spatial Pan + Crisp Ping */}
          <div className="flex items-center justify-between gap-1.5">
            <span
              className={`rounded-md px-2 py-0.5 text-[10px] font-extrabold tracking-wider border ${
                activeGame.roles.find(
                  (r: GameRoleDef) => r.key === activeRole || r.shortLabel === activeRole,
                )?.badgeClass ?? ROLE_BADGE_STYLE[op.roleTone]
              }`}
            >
              {activeRole}
            </span>

            <div className="flex items-center gap-1.5">
              {!isSelf && (
                <button
                  type="button"
                  onClick={() => cycleSpatialPan(op.id)}
                  title={PAN_TITLE[pan]}
                  aria-label={`${displayName} 3D ses yönü: ${pan}`}
                  className={`rounded-md ${
                    mobileComfort ? 'h-7 px-2.5 text-[11px]' : 'h-5 px-1.5 text-[10px]'
                  } font-bold border transition-colors ${
                    pan !== 'C'
                      ? 'bg-[#8F1622]/25 text-[#F29AA3] border-[#961826]/50'
                      : 'bg-[#120A0D] text-[#9E8E91] hover:text-[#F4EFF0] border-[#281318]'
                  }`}
                >
                  {mobileComfort ? `3D · ${pan}` : pan}
                </button>
              )}
              <span
                className={`text-[11.5px] lg:text-[11px] font-bold tabular-nums ${
                  isMuted
                    ? 'text-[#D63344]'
                    : isSpeaking
                      ? 'text-[#F29AA3]'
                      : 'text-[#827376]'
                }`}
              >
                {isMuted ? 'Sessiz' : `${livePing} ms`}
              </span>
            </div>
          </div>

          {/* Row 3: Smooth Fluid SVG Audio Wave */}
          <div
            onClick={() =>
              setSpeakingPeers((p) => ({ ...p, [op.id]: !p[op.id] }))
            }
            title="Ses dalgasını test etmek için tıklayın"
            className={`cursor-pointer rounded-lg ${
              mobileComfort ? 'h-9' : 'h-8'
            } px-2.5 border flex items-center transition-all duration-200 ${
              isSpeaking
                ? 'bg-[linear-gradient(90deg,#0E080A_0%,#260D14_50%,#0E080A_100%)] border-[#C82333]/45'
                : 'bg-[#0B0709] border-[#221015]'
            }`}
          >
            <FluidWave
              peerId={op.id}
              active={isSpeaking && !ecoActive}
              muted={isMuted}
              speed={op.waveSpeed}
              className="w-full h-6"
            />
          </div>

          {/* Row 4: High-Contrast Crimson/Bronze Gain Slider */}
          <div className="flex items-center gap-2 pt-0.5 min-w-0">
            <input
              type="range"
              min={0}
              max={200}
              step={5}
              value={gainVal}
              onChange={(e) => setPlayerGain(op.id, Number(e.target.value))}
              onDoubleClick={() => setPlayerGain(op.id, 100)}
              title="Çift tıklayarak %100 seviyesine sıfırlayın"
              style={
                {
                  '--fill': `${Math.round((gainVal / 200) * 100)}%`,
                } as React.CSSProperties
              }
              suppressHydrationWarning
              aria-label={`${displayName} ses seviyesi`}
              className="exec-range flex-1 min-w-0"
            />
            <span
              className={`text-[11px] font-bold tabular-nums text-right flex-shrink-0 ${
                isBoosted ? 'text-[#F29AA3]' : 'text-[#B8AAAC]'
              }`}
            >
              %{gainVal}
            </span>
          </div>
        </div>
      );
    });

    // Multi-Purpose Slot Beacon Handlers: Single click leaves beacon/copies link, double click triggers discovery & lobby match
    const handleBeaconSlotClick = (slotIdx: number) => {
      const beacon = slotBeacons[slotIdx];
      const code =
        activeScrim?.code ??
        activeVoiceChannelId?.replace(/^scrim-/, '') ??
        'MEVA-8492';

      if (beacon && beacon.beaconActive && beacon.targetRole) {
        const role = beacon.targetRole;
        const link =
          typeof window !== 'undefined'
            ? `${window.location.origin}/?room=${code}&role=${role}`
            : code;
        void navigator.clipboard.writeText(link);
        setInviteCopied(true);
        setBeaconToast(`🔗 ${role} davet linki panoya kopyalandı!`);
        setTimeout(() => {
          setInviteCopied(false);
          setBeaconToast(null);
        }, 2500);
      } else {
        const assignedRoles = new Set(
          Object.values(slotBeacons)
            .filter((b) => b?.beaconActive && b?.targetRole)
            .map((b) => b.targetRole),
        );
        const candidateRole =
          activeGame.roles.find((r: GameRoleDef) => !assignedRoles.has(r.shortLabel))?.shortLabel ??
          activeGame.roles[slotIdx % activeGame.roles.length]?.shortLabel ??
          'PRO';

        setSlotBeacon(slotIdx, candidateRole);

        const link =
          typeof window !== 'undefined'
            ? `${window.location.origin}/?room=${code}&role=${candidateRole}`
            : code;
        void navigator.clipboard.writeText(link);
        setInviteCopied(true);
        setBeaconToast(`⚡ [${candidateRole}] Oyuncu davet linki kopyalandı!`);
        setTimeout(() => {
          setInviteCopied(false);
          setBeaconToast(null);
        }, 2500);
      }
    };

    const handleBeaconSlotDoubleClick = (slotIdx: number) => {
      setSelectedGameFilter(activeGame.id);
      setShowLobbyGate(true);
      setBeaconToast(`🎯 ${activeGame.name} hızlı lobi eşleşmesi başlatıldı!`);
      setTimeout(() => setBeaconToast(null), 2500);
    };

    // Render empty slots up to 5 with Multi-Purpose Meva-native Slot Beacons
    for (let i = activeSquadOperators.length; i < 5; i++) {
      const rawBeacon = slotBeacons[i];
      const isBeaconActive = Boolean(rawBeacon?.beaconActive && rawBeacon?.targetRole);
      const beaconRole = isBeaconActive ? rawBeacon.targetRole : null;

      cards.push(
        <div
          key={`slot-${i}`}
          onClick={() => handleBeaconSlotClick(i)}
          onDoubleClick={() => handleBeaconSlotDoubleClick(i)}
          title={isBeaconActive ? "Davet linkini kopyala veya çağrıyı yönet" : "Oyuncu davet etmek için dokunun"}
          className={`cockpit-pod rounded-xl cursor-pointer select-none transition-all duration-200 group flex flex-col justify-between items-center text-center ${
            isBeaconActive
              ? 'border-2 border-[#C82333]/90 shadow-[0_0_20px_rgba(200,35,51,0.22)] bg-gradient-to-b from-[#2B0A13]/90 to-[#0F0609]/95'
              : 'border border-[#281318] bg-[#0E0709]/80 hover:border-[#6E141E]/70 hover:bg-[#140A0D]'
          } ${
            mobileComfort
              ? 'p-3.5 gap-2 min-h-[140px]'
              : 'p-3 gap-2 min-h-[130px]'
          }`}
        >
          <div className="w-full flex items-center justify-between">
            <span
              className={`text-[10px] font-bold tracking-wide px-2 py-0.5 rounded border ${
                isBeaconActive
                  ? 'text-[#FF5A6B] bg-[#590C15]/70 border-[#C82333]/60'
                  : 'text-[#8E7E81] bg-[#14080B] border-[#221014]'
              }`}
            >
              {isBeaconActive ? `⚡ ${beaconRole} ÇAĞRISI` : `KOLTUK #${i + 1}`}
            </span>
            {isBeaconActive ? (
              <button
                type="button"
                onClick={(e) => {
                  e.stopPropagation();
                  clearSlotBeacon(i);
                }}
                className="w-5 h-5 rounded-md flex items-center justify-center text-[#9E8E91] hover:text-[#FAF2EE] hover:bg-[#3D0F18] transition-colors text-xs font-bold"
                title="Çağrıyı Kaldır"
              >
                ✕
              </button>
            ) : (
              <span className="w-5 h-5 rounded-md flex items-center justify-center text-[12px] text-[#6E5E61] group-hover:text-[#FF5A6B] group-hover:bg-[#200D12] transition-all">
                +
              </span>
            )}
          </div>

          <div className="my-1.5 flex flex-col items-center">
            <span className="text-[13px] font-extrabold text-[#FAF2EE] tracking-wide block">
              {isBeaconActive ? `${beaconRole} Bekleniyor` : 'Boş Koltuk'}
            </span>
            <span className="text-[11px] text-[#A8989B] font-medium mt-0.5 block">
              {isBeaconActive
                ? `${activeGame.name} kadro sinyali yayında`
                : 'Oyuncu davet etmek için dokun'}
            </span>
          </div>

          <div
            className={`w-full py-1.5 px-2 rounded-lg text-[11px] font-bold transition-all flex items-center justify-center gap-1.5 border ${
              isBeaconActive
                ? 'bg-[#3D0D16] border-[#8F1622]/60 text-[#FAF2EE] group-hover:bg-[#52121E]'
                : 'bg-[#140A0D] border-[#261217] text-[#A8989B] group-hover:border-[#6E141E]/70 group-hover:text-[#FAF2EE]'
            }`}
          >
            <span>
              {isBeaconActive
                ? inviteCopied
                  ? '✓ Link Kopyalandı'
                  : '🔗 Davet Linki Kopyala'
                : '+ Oyuncu Çağır'}
            </span>
          </div>
        </div>,
      );
    }

    return cards;
  };

  const renderMeshSvg = (maxHeightClass: string, idPrefix: string) => (
    <svg
      viewBox="0 0 320 164"
      className={`w-full h-full ${maxHeightClass}`}
      preserveAspectRatio="xMidYMid meet"
      aria-label="5-Operatör P2P Mesh Ağ Topolojisi"
    >
      <defs>
        <radialGradient id={`${idPrefix}-core`} cx="50%" cy="52%" r="50%">
          <stop offset="0%" stopColor="#961826" stopOpacity="0.22" />
          <stop offset="55%" stopColor="#4A0B12" stopOpacity="0.08" />
          <stop offset="100%" stopColor="#070607" stopOpacity="0" />
        </radialGradient>
        <linearGradient id={`${idPrefix}-edge`} x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stopColor="#B81F2E" stopOpacity="0.65" />
          <stop offset="50%" stopColor="#7A121D" stopOpacity="0.45" />
          <stop offset="100%" stopColor="#B81F2E" stopOpacity="0.65" />
        </linearGradient>
        <radialGradient id={`${idPrefix}-ruby`} cx="35%" cy="35%" r="65%">
          <stop offset="0%" stopColor="#E35D6A" />
          <stop offset="55%" stopColor="#A61B29" />
          <stop offset="100%" stopColor="#3B080E" />
        </radialGradient>
        <radialGradient id={`${idPrefix}-bronze`} cx="35%" cy="35%" r="65%">
          <stop offset="0%" stopColor="#C98A92" />
          <stop offset="55%" stopColor="#7A1824" />
          <stop offset="100%" stopColor="#2B090E" />
        </radialGradient>
      </defs>

      <ellipse cx="160" cy="86" rx="108" ry="70" fill={`url(#${idPrefix}-core)`} />

      <circle
        cx="160"
        cy="86"
        r="64"
        fill="none"
        stroke={`url(#${idPrefix}-edge)`}
        strokeOpacity="0.30"
        strokeWidth="1"
      />
      <circle
        cx="160"
        cy="86"
        r="34"
        fill="none"
        stroke="#8F1622"
        strokeOpacity="0.22"
        strokeWidth="1"
      />

      <g stroke={`url(#${idPrefix}-edge)`} strokeWidth="1.3">
        <line x1="160" y1="22" x2="82" y2="66" />
        <line x1="160" y1="22" x2="238" y2="66" />
        <line x1="160" y1="22" x2="108" y2="142" />
        <line x1="160" y1="22" x2="212" y2="142" />
        <line x1="82" y1="66" x2="238" y2="66" />
        <line x1="82" y1="66" x2="108" y2="142" />
        <line x1="82" y1="66" x2="212" y2="142" />
        <line x1="238" y1="66" x2="108" y2="142" />
        <line x1="238" y1="66" x2="212" y2="142" />
        <line x1="108" y1="142" x2="212" y2="142" />
      </g>

      {!ecoActive && (
        <>
          <circle r="3" fill="#E35D6A">
            <animateMotion
              dur={stressTestActive ? '1.2s' : '2.2s'}
              repeatCount="indefinite"
              path="M160,22 L82,66 L108,142 L212,142 L238,66 Z"
            />
          </circle>
          <circle r="3" fill="#B81F2E">
            <animateMotion
              dur={stressTestActive ? '1.5s' : '2.8s'}
              repeatCount="indefinite"
              path="M160,22 L212,142 L82,66 L238,66 L108,142 Z"
            />
          </circle>
        </>
      )}

      <g fontSize="10" fontWeight="700" fill="#F4EFF0">
        {MESH_NODES.map((node) => {
          const op = activeSquadOperators[node.opIndex];
          if (!op) {
            return (
              <g key={`empty-mesh-${node.opIndex}`} className="opacity-40">
                <circle
                  cx={node.cx}
                  cy={node.cy}
                  r={node.r}
                  fill="#15080C"
                  stroke="#3D121A"
                  strokeWidth="1.5"
                  strokeDasharray="2 2"
                />
                <text
                  x={node.tx}
                  y={node.ty}
                  textAnchor={node.anchor}
                  fontSize="9.5"
                  fontWeight="600"
                  fill="#7A686B"
                >
                  Slot #{node.opIndex + 1}
                </text>
              </g>
            );
          }
          const isSelf = op.id === 'usr-local';
          const callsign = isSelf ? username : op.username;
          const nodeSpeaking = isSelf
            ? selfTransmitting
            : Boolean(speakingPeers[op.id]);
          const sphereGrad =
            node.tone === 'bronze'
              ? `url(#${idPrefix}-bronze)`
              : `url(#${idPrefix}-ruby)`;

          return (
            <g
              key={op.id}
              onClick={() => setInspectedNodeId(op.id)}
              className="cursor-pointer"
            >
              {nodeSpeaking && (
                <circle
                  cx={node.cx}
                  cy={node.cy}
                  r={node.r + 5.5}
                  fill="rgba(196,30,46,0.16)"
                  stroke="#D63344"
                  strokeOpacity="0.75"
                  strokeWidth="1.25"
                />
              )}
              <circle
                cx={node.cx}
                cy={node.cy}
                r={node.r + 0.5}
                fill={sphereGrad}
                stroke={nodeSpeaking ? '#F4EFF0' : '#090708'}
                strokeWidth="1.4"
              />
              <text
                x={node.tx}
                y={node.ty}
                textAnchor={node.anchor}
                fill={nodeSpeaking ? '#F4EFF0' : '#B8AAAC'}
              >
                {callsign} · {telemetry.nodes[op.id]?.rttMs ?? op.pingMs}ms
              </text>
            </g>
          );
        })}
      </g>
    </svg>
  );

  if (servers.length === 0) {
    return (
      <main className="flex-1 h-full min-h-0 flex flex-col items-center justify-center overflow-y-auto overflow-x-hidden min-w-0 w-full p-4 sm:p-6 pb-28 select-none bg-[radial-gradient(ellipse_at_center,rgba(143,22,34,0.12)_0%,rgba(7,5,7,0.98)_70%)] font-sans">
        <div className="max-w-2xl w-full mx-auto flex flex-col items-center text-center space-y-4 sm:space-y-6 my-auto rounded-3xl bg-[#0E070A]/55 backdrop-blur-md border border-[#2A1319] shadow-[0_24px_70px_rgba(0,0,0,0.6)] px-4 py-6 sm:px-8 sm:py-8">
          {/* Logo & Clean Status */}
          <div className="flex flex-col items-center gap-2.5">
            <div className="w-16 h-16 sm:w-20 sm:h-20 rounded-2xl sm:rounded-3xl bg-[#180A0E] border-2 border-[#8F1622] shadow-[0_0_28px_rgba(200,35,51,0.3)] flex items-center justify-center text-[#C82333] transition-transform hover:scale-105">
              <IconMevaMark size={34} />
            </div>

            <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-[#180A0E] border border-[#8F1622]/50 text-[#F08C96] text-[10.5px] font-bold tracking-wide uppercase">
              <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
              <span>Sıfır Gecikme · Uçtan Uca Şifreli</span>
            </div>
          </div>

          {/* Heading & Subtitle */}
          <div className="space-y-1.5 max-w-md mx-auto">
            <h1 className="text-2xl sm:text-3xl font-black text-[#FAF2EE] tracking-tight">
              Meva Takım İletişimi
            </h1>
            <p className="text-xs sm:text-sm text-[#A8989B] leading-relaxed">
              Oyun performansınızı düşürmeyen, kristal netliğinde ses ve espor taktik stüdyosu.
            </p>
          </div>

          {/* 3 Large, Clean, Intuitive Action Cards */}
          <div className="w-full grid grid-cols-1 sm:grid-cols-3 gap-2.5 sm:gap-3.5 pt-1">
            <button
              type="button"
              onClick={() => setShowChannelBuilderModal(true)}
              className="p-3.5 sm:p-4 rounded-xl sm:rounded-2xl bg-gradient-to-r sm:bg-gradient-to-b from-[#2B0E16] to-[#12070A] hover:from-[#3B141F] hover:to-[#1C0B10] border border-[#8F1622]/80 hover:border-[#C82333] shadow-[0_4px_20px_rgba(200,35,51,0.2)] flex flex-row sm:flex-col items-center gap-3 sm:gap-2.5 transition-all active:scale-[0.98] group text-left sm:text-center"
            >
              <div className="w-10 h-10 sm:w-11 sm:h-11 rounded-xl bg-[#4A0D18] text-[#FAF2EE] flex items-center justify-center text-lg font-bold group-hover:scale-105 transition-transform flex-shrink-0 shadow-inner">
                ➕
              </div>
              <div className="space-y-0.5 min-w-0 flex-1">
                <span className="block text-sm font-black text-[#FAF2EE] group-hover:text-[#FF5A6B] transition-colors truncate">
                  Sunucu Kur
                </span>
                <span className="block text-[11px] text-[#A8989B] leading-tight">
                  Özel ses ve sohbet odanızı açın.
                </span>
              </div>
              <span className="sm:hidden text-lg text-[#C82333] font-bold">›</span>
            </button>

            <button
              type="button"
              onClick={() => setShowLobbyGate(true)}
              className="p-3.5 sm:p-4 rounded-xl sm:rounded-2xl bg-[#120A0D] hover:bg-[#1C0B10] border border-[#2A1319] hover:border-[#8F1622]/70 flex flex-row sm:flex-col items-center gap-3 sm:gap-2.5 transition-all active:scale-[0.98] group text-left sm:text-center"
            >
              <div className="w-10 h-10 sm:w-11 sm:h-11 rounded-xl bg-[#1C0B10] border border-[#2E151C] text-amber-400 flex items-center justify-center text-lg font-bold group-hover:scale-105 transition-transform flex-shrink-0 shadow-inner">
                ⚡
              </div>
              <div className="space-y-0.5 min-w-0 flex-1">
                <span className="block text-sm font-black text-[#FAF2EE] group-hover:text-amber-300 transition-colors truncate">
                  Odaya Katıl
                </span>
                <span className="block text-[11px] text-[#A8989B] leading-tight">
                  Davet koduyla odaya bağlanın.
                </span>
              </div>
              <span className="sm:hidden text-lg text-[#8F1622] font-bold">›</span>
            </button>

            <button
              type="button"
              onClick={() => useVoiceSettingsStore.getState().toggleStratBoard()}
              className="p-3.5 sm:p-4 rounded-xl sm:rounded-2xl bg-[#120A0D] hover:bg-[#1C0B10] border border-[#2A1319] hover:border-cyan-500/50 flex flex-row sm:flex-col items-center gap-3 sm:gap-2.5 transition-all active:scale-[0.98] group text-left sm:text-center"
            >
              <div className="w-10 h-10 sm:w-11 sm:h-11 rounded-xl bg-[#09151A] border border-[#103440] text-cyan-400 flex items-center justify-center text-lg font-bold group-hover:scale-105 transition-transform flex-shrink-0 shadow-inner">
                🗺️
              </div>
              <div className="space-y-0.5 min-w-0 flex-1">
                <span className="block text-sm font-black text-[#FAF2EE] group-hover:text-cyan-300 transition-colors truncate">
                  Taktik Tahtası
                </span>
                <span className="block text-[11px] text-[#A8989B] leading-tight">
                  CS2, Valorant ve LoL haritaları.
                </span>
              </div>
              <span className="sm:hidden text-lg text-cyan-500 font-bold">›</span>
            </button>
          </div>

          {/* Minimal Tour Guide Link */}
          <div className="pt-2">
            <button
              type="button"
              onClick={() => setShowTourModal(true)}
              className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-bold text-[#A8989B] hover:text-[#FAF2EE] hover:bg-[#180A0E] transition-colors"
            >
              <span>❓</span>
              <span>Nasıl Çalışır? (30 sn rehber)</span>
            </button>
          </div>
        </div>
      </main>
    );
  }

  return (
    <main className="flex-1 h-full min-h-0 flex flex-col overflow-hidden min-w-0 gap-2.5 p-2.5 lg:p-0 font-sans tabular-nums">
      {/* ═══════════════════════════════════════════════════════
          MOBILE / TABLET (< 1024px) DEDICATED BREATHABLE COCKPIT
         ═══════════════════════════════════════════════════════ */}

      {/* MOBILE VIEW 1: SPACIOUS TACTICAL CHAT + LIVE VOICE STRIP */}
      {mobileTab === 'chat' && (
        <div className="lg:hidden flex-1 min-h-0 flex flex-col gap-2.5 overflow-hidden">
          {/* Breathable Compact Live Voice Banner */}
          <div className="titanium-module rounded-xl px-3.5 py-2.5 flex items-center justify-between gap-2.5 flex-shrink-0">
            <button
              type="button"
              onClick={() => setMobileTab('voice')}
              className="flex items-center gap-2.5 min-w-0 flex-1 text-left"
            >
              <span className="rounded-lg w-8 h-8 crimson-cta flex items-center justify-center text-[#F4EFF0] flex-shrink-0">
                <IconVoiceWave size={15} />
              </span>
              <div className="min-w-0">
                <div className="flex items-center gap-1.5">
                  <span className="truncate text-[13px] font-extrabold text-[#F4EFF0]">
                    {activeRoomName}
                  </span>
                  <span className="rounded px-1.5 py-0.5 bg-[#7A121D]/30 border border-[#961826]/45 text-[10px] font-bold text-[#F29AA3]">
                    5/5
                  </span>
                </div>
                <span className="block truncate text-[11px] font-medium text-[#827376]">
                  Ses matrisini ve DSP ayarlarını açmak için dokun
                </span>
              </div>
            </button>

            <div className="flex items-center gap-1.5 flex-shrink-0">
              <button
                type="button"
                onClick={() =>
                  voiceControls
                    ? voiceControls.toggleMute()
                    : togglePeerMute('usr-local')
                }
                aria-label={selfMuted ? 'Mikrofonu aç' : 'Mikrofonu sustur'}
                className={`rounded-xl w-10 h-10 flex items-center justify-center border transition-all active:scale-95 ${
                  selfMuted
                    ? 'bg-[#8F1622]/25 text-[#F08C96] border-[#C82333]/50'
                    : 'bg-[#120A0D] text-[#F4EFF0] border-[#2C141A]'
                }`}
              >
                {selfMuted ? <IconMicOff size={16} /> : <IconMic size={16} />}
              </button>
            </div>
          </div>

          {/* Spacious Full-Height Mobile Chat Card */}
          <section className="titanium-module rounded-xl flex-1 min-h-0 flex flex-col overflow-hidden">
            {/* Clean Uncluttered Mobile Chat Header */}
            <div className="relative h-11 px-3.5 flex items-center justify-between gap-2 bg-[#0D080A]/70 flex-shrink-0">
              <span
                aria-hidden
                className="pointer-events-none absolute inset-x-3 bottom-0 h-px horizon-divider opacity-80"
              />
              <div className="flex items-center gap-2 min-w-0">
                <span className="w-1.5 h-4 rounded-full bg-[#C82333]" />
                <h3 className="text-[13.5px] font-extrabold text-[#F4EFF0] truncate">
                  {chatTitle}
                </h3>
                {dmUser && (
                  <button
                    type="button"
                    onClick={() => setActiveDMUser(null)}
                    className="rounded-lg px-2.5 py-1 bg-[#180B10] border border-[#32151C] text-[11px] font-bold text-[#F29AA3]"
                  >
                    Genel Akış
                  </button>
                )}
              </div>
              <div className="flex items-center gap-1.5 flex-shrink-0">
                <button
                  type="button"
                  onClick={() => setSearchOpen((v) => !v)}
                  className={`rounded-lg px-2 py-1 text-[10.5px] font-bold border transition-colors ${
                    searchOpen || searchQuery || activeTagFilter
                      ? 'bg-[#7A121D]/30 text-[#F08C96] border-[#A61B29]/50'
                      : 'bg-[#140A0D] text-[#8E7E81] border-[#281318]'
                  }`}
                >
                  Ara
                </button>
                <button
                  type="button"
                  onClick={() => setShowFingerprintModal(true)}
                  className="rounded-lg px-2 py-1 bg-[#160A0E] border border-[#881A26]/40 text-[10.5px] font-mono font-bold text-[#ED8793]"
                  title="ECDH P-256 & AES-256-GCM Anahtar Parmak İzini Doğrula"
                >
                  🔒 {localFingerprint}
                </button>
              </div>
            </div>

            {searchOpen && (
              <div className="px-3 py-2 bg-[#0B0709] border-b border-[#241116] flex flex-wrap items-center gap-1.5 flex-shrink-0">
                <input
                  type="text"
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  placeholder="Mesaj veya operatör ara..."
                  className="rounded-lg flex-1 min-w-[140px] h-7 px-2.5 bg-[#120A0D] border border-[#2C141A] focus:border-[#C82333]/65 text-[11.5px] text-[#F4EFF0] placeholder:text-[#7D6E71] outline-none"
                />
                {(['ROTATE', 'ECO', 'CLUTCH', 'FORCE'] as const).map((t) => (
                  <button
                    key={t}
                    type="button"
                    onClick={() =>
                      setActiveTagFilter((curr) => (curr === t ? null : t))
                    }
                    className={`rounded-md h-7 px-2 text-[10px] font-bold border ${
                      activeTagFilter === t
                        ? 'crimson-cta text-[#F4EFF0]'
                        : 'bg-[#140A0D] text-[#B8AAAC] border-[#2C141A]'
                    }`}
                  >
                    #{t}
                  </button>
                ))}
              </div>
            )}

            <TacticalMessageFeed
              messages={filteredMessages}
              userId={userId}
              playingVoiceNoteId={playingVoiceNoteId}
              onToggleVoiceNote={setPlayingVoiceNoteId}
              copiedMsgId={copiedMsgId}
              onCopyMessage={handleCopyMessage}
              ecoActive={ecoActive}
              bottomRef={bottomRef}
            />

            {/* Breathable Dedicated Swipeable Callout Bar */}
            <div className="px-3 py-2 bg-[#0A0708]/80 border-t border-[#221015] flex items-center gap-1.5 overflow-x-auto no-scrollbar flex-shrink-0">
              {dynamicCallouts.map((c) => (
                <button
                  key={c.label}
                  type="button"
                  onClick={() => handleCallout(c.text, c.cue)}
                  className="rounded-lg h-8 px-3 bg-[linear-gradient(160deg,#1E0B10_0%,#0E080A_100%)] active:scale-95 text-[#F4EFF0] border border-[#30151C] text-[11.5px] font-bold whitespace-nowrap flex-shrink-0"
                >
                  {c.label}
                </button>
              ))}
            </div>

            {/* Ergonomic Mobile Input */}
            <form
              onSubmit={handleSubmit}
              className="p-2.5 bg-[#090608]/90 border-t border-[#221015] flex items-center gap-2 flex-shrink-0"
            >
              <input
                type="text"
                value={input}
                onChange={(e) => setInput(e.target.value)}
                placeholder={`${chatTitle} kanalına mesaj yaz...`}
                className="rounded-xl flex-1 min-w-0 h-11 px-3.5 bg-[#11090B] border border-[#2C141A] focus:border-[#C82333]/70 text-[13px] text-[#F4EFF0] placeholder:text-[#7D6E71] outline-none"
              />
              <button
                type="submit"
                disabled={!input.trim()}
                className="crimson-cta rounded-xl h-11 px-4 text-[#F4EFF0] disabled:text-[#6E5F62] text-[12.5px] font-bold flex items-center gap-1.5 flex-shrink-0 active:scale-95"
              >
                <IconSend size={14} />
                <span>Gönder</span>
              </button>
            </form>
          </section>
        </div>
      )}

      {/* MOBILE VIEW 2: SPACIOUS SCROLLABLE 5-OPERATOR VOICE MATRIX */}
      {mobileTab === 'voice' && (
        <section className="lg:hidden titanium-module rounded-xl flex-1 min-h-0 flex flex-col p-3.5 gap-3 overflow-hidden">
          <div className="flex items-center justify-between gap-2 flex-shrink-0">
            <div className="flex items-center gap-2 min-w-0">
              <span className="w-2 h-2 rounded-full bg-[#C82333]" />
              <h2 className="text-[14px] font-extrabold text-[#F4EFF0] truncate">
                Kadro Ses Matrisi
              </h2>
            </div>
            <span className="rounded-md px-2.5 py-1 bg-[#1A0B10] border border-[#7A121D]/50 text-[11px] font-bold text-[#F08C96]">
              Opus 48kHz · 5/5
            </span>
          </div>

          {/* Swipeable Room Switcher Pills */}
          <div className="flex items-center gap-2 overflow-x-auto no-scrollbar flex-shrink-0 pb-0.5">
            {voiceChannels.map((vc) => {
              const isSelected =
                vc.id === (activeVoiceChannelId ?? activeVoiceChannel?.id);
              return (
                <button
                  key={vc.id}
                  type="button"
                  onClick={() => setActiveVoiceChannel(vc.id)}
                  className={`rounded-xl h-9 px-3.5 text-[12px] font-bold border flex items-center gap-2 whitespace-nowrap flex-shrink-0 transition-all ${
                    isSelected
                      ? 'crimson-cta text-[#F4EFF0]'
                      : 'bg-[#11090B] text-[#9E8E91] border-[#281318]'
                  }`}
                >
                  <IconVoiceWave size={13} />
                  <span>{cleanLabel(vc.name)}</span>
                </button>
              );
            })}
          </div>

          {/* Spacious Scrollable Operator DSP List */}
          <div className="flex-1 min-h-0 overflow-y-auto pr-0.5 grid grid-cols-1 sm:grid-cols-2 gap-2.5 content-start">
            {renderOperatorCards(true)}
          </div>

          {/* Pinned Ergonomic Mobile Push-To-Talk Bar */}
          <div className="pt-2 border-t border-[#241116] flex items-center gap-2 flex-shrink-0">
            <button
              type="button"
              onPointerDown={() => {
                setPttActive(true);
                getMevaVadEngine().setPttPressed(true);
              }}
              onPointerUp={() => {
                setPttActive(false);
                getMevaVadEngine().setPttPressed(false);
                triggerSelfSpeakingPulse();
              }}
              onPointerLeave={() => {
                setPttActive(false);
                getMevaVadEngine().setPttPressed(false);
              }}
              onPointerCancel={() => {
                setPttActive(false);
                getMevaVadEngine().setPttPressed(false);
              }}
              className={`flex-1 rounded-xl h-12 px-4 text-[13px] font-extrabold flex items-center justify-center gap-2 transition-all active:scale-[0.98] ${
                selfTransmitting
                  ? 'crimson-cta text-[#F4EFF0] ring-2 ring-[#C82333]/40'
                  : 'bg-[linear-gradient(160deg,#220C12_0%,#0E080A_100%)] text-[#F4EFF0] border border-[#7A121D]/55'
              }`}
            >
              <IconMic size={16} />
              <span>
                {pttActive ? 'Canlı İletiliyor...' : 'Basılı Tut ve Konuş (PTT)'}
              </span>
            </button>
          </div>
        </section>
      )}

      {/* MOBILE VIEW 3: SPACIOUS P2P MESH, TELEMETRY & SCRIM HUB */}
      {mobileTab === 'mesh' && (
        <section className="lg:hidden titanium-module rounded-xl flex-1 min-h-0 flex flex-col p-3.5 gap-3 overflow-y-auto">
          {/* Quick Mobile Action Cards: Scrim & Game-Boost */}
          <div className="grid grid-cols-2 gap-2.5 flex-shrink-0">
            <button
              type="button"
              onClick={() => setShowScrimModal(true)}
              className="crimson-cta rounded-xl p-3 text-left flex flex-col justify-between gap-1.5 active:scale-[0.98]"
            >
              <div className="flex items-center justify-between">
                <IconBolt size={16} className="text-[#F5B5BC]" />
                <span className="text-[10px] font-bold uppercase tracking-wider text-[#F5B5BC]">
                  Anında Oda
                </span>
              </div>
              <span className="text-[13px] font-extrabold text-[#F4EFF0]">
                {activeScrim ? `Scrim #${activeScrim.code}` : 'Scrim Odası Kur'}
              </span>
            </button>

            <button
              type="button"
              onClick={toggleEcoEnabled}
              className={`rounded-xl p-3 text-left flex flex-col justify-between gap-1.5 border transition-all active:scale-[0.98] ${
                ecoEnabled
                  ? 'bg-[linear-gradient(160deg,rgba(128,18,30,0.24)_0%,rgba(12,8,10,0.85)_100%)] border-[#961826]/55 text-[#F4EFF0]'
                  : 'bg-[#11090B] border-[#281318] text-[#9E8E91]'
              }`}
            >
              <div className="flex items-center justify-between">
                <IconGauge
                  size={16}
                  className={ecoEnabled ? 'text-[#E35D6A]' : 'text-[#827376]'}
                />
                <span className="text-[10px] font-bold uppercase tracking-wider text-[#E35D6A]">
                  {ecoEnabled ? 'Aktif' : 'Kapalı'}
                </span>
              </div>
              <span className="text-[13px] font-extrabold text-[#F4EFF0]">
                Game-Boost Modu
              </span>
            </button>
          </div>

          {/* 2x2 Breathable Mobile Telemetry Cards */}
          <div className="grid grid-cols-2 gap-2 flex-shrink-0">
            <div className="rounded-xl p-3 bg-[linear-gradient(160deg,#1A0B10_0%,#0B0809_100%)] border border-[#2A1319]">
              <span className="block text-[10.5px] font-semibold text-[#827376]">
                Ses Kodek Motoru
              </span>
              <span className="block text-[14px] font-extrabold text-[#F4EFF0] mt-0.5">
                Opus 48kHz
              </span>
            </div>
            <div className="rounded-xl p-3 bg-[linear-gradient(160deg,#1A0B10_0%,#0B0809_100%)] border border-[#2A1319]">
              <span className="block text-[10.5px] font-semibold text-[#827376]">
                Oyun Etkisi
              </span>
              <span className="block text-[14px] font-extrabold text-[#F08C96] mt-0.5">
                0 FPS Kaybı
              </span>
            </div>
            <div className="rounded-xl p-3 bg-[linear-gradient(160deg,#1A0B10_0%,#0B0809_100%)] border border-[#2A1319]">
              <span className="block text-[10.5px] font-semibold text-[#827376]">
                İşlemci Yükü
              </span>
              <span className="block text-[14px] font-extrabold text-[#F4EFF0] mt-0.5">
                %<CpuLoadBadge fallbackCpu={simMetrics.cpu} /> CPU
              </span>
            </div>
            <div className="rounded-xl p-3 bg-[linear-gradient(160deg,#1A0B10_0%,#0B0809_100%)] border border-[#2A1319]">
              <span className="block text-[10.5px] font-semibold text-[#827376]">
                Mesh Kararlılığı
              </span>
              <span className="block text-[14px] font-extrabold text-[#F08C96] mt-0.5">
                %{simMetrics.stability} P2P
              </span>
            </div>
          </div>

          {/* Full-Size Mobile Pentagon P2P Mesh Card */}
          <div className="flex-1 min-h-[250px] rounded-xl mesh-surface border border-[#2C141A] p-3.5 flex flex-col justify-between">
            <div className="flex items-center justify-between gap-2">
              <div>
                <span className="block text-[12.5px] font-extrabold text-[#F4EFF0]">
                  5-Operatör P2P Mesh Topolojisi
                </span>
                <span className="block text-[11px] font-bold text-[#E35D6A] mt-0.5">
                  {simMetrics.rtt}ms RTT · {simMetrics.jitter}ms Jitter
                </span>
              </div>
              <button
                type="button"
                onClick={handleToggleStressTest}
                className={`rounded-lg h-8 px-3 text-[11px] font-bold border transition-all ${
                  stressTestActive
                    ? 'crimson-cta text-[#F4EFF0]'
                    : 'bg-[#140A0D] text-[#B8AAAC] border-[#2E151C]'
                }`}
              >
                {stressTestActive
                  ? `Test · ${telemetry.throughputKbps} kbps`
                  : 'Ağ Stres Testi'}
              </button>
            </div>

            <div className="my-2 flex-1 flex items-center justify-center">
              {renderMeshSvg('max-h-[210px]', 'm-mesh')}
            </div>

            <div className="pt-2 border-t border-[#241116] flex items-center justify-between text-[11px]">
              <span className="text-[#827376] font-medium">
                E2EE Kriptolu Doğrudan Ağ
              </span>
              <span className="font-extrabold text-[#E35D6A]">
                Meva Secure Mesh Core
              </span>
            </div>
          </div>
        </section>
      )}

      {/* ═══════════════════════════════════════════════════════
          DESKTOP (>= 1024px) 100dvh BENTO WAR ROOM (ZERO CLIPPING)
         ═══════════════════════════════════════════════════════ */}

      {/* 1. DESKTOP TOP STAGE: 5-OPERATOR EXECUTIVE VOICE MATRIX */}
      <section className="hidden lg:flex titanium-module rounded-xl px-4 py-3 flex-col gap-2.5 flex-shrink-0">
        <div className="flex items-center justify-between gap-3">
          <div className="flex items-center gap-2.5 min-w-0 flex-shrink-0">
            <span className="w-2 h-2 rounded-full bg-[#C82333] flex-shrink-0" />
            <h2 className="text-[14px] font-extrabold tracking-tight text-[#F4EFF0] whitespace-nowrap">
              Canlı Kadro Ses Matrisi
            </h2>
            <span className="text-xs text-[#827376] font-semibold whitespace-nowrap">
              · {activeRoomName}
            </span>
            <span className="inline-flex items-center rounded-md px-2.5 py-0.5 bg-[#190B10] border border-[#7A121D]/45 text-[11px] font-bold text-[#F08C96] whitespace-nowrap">
              {activeSquadOperators.length}/5 Aktif · 96 kbps Opus
            </span>
          </div>

          <div className="flex items-center gap-2 min-w-0">
            <div className="flex items-center gap-1.5 overflow-x-auto max-w-[460px] no-scrollbar py-0.5">
              {voiceChannels.map((vc) => {
                const isSelected =
                  vc.id === (activeVoiceChannelId ?? activeVoiceChannel?.id);
                return (
                  <button
                    key={vc.id}
                    type="button"
                    onClick={() => setActiveVoiceChannel(vc.id)}
                    className={`rounded-lg h-7 px-2.5 text-[11px] font-bold border transition-all duration-150 flex items-center gap-1.5 flex-shrink-0 whitespace-nowrap ${
                      isSelected
                        ? 'bg-[linear-gradient(160deg,rgba(138,20,32,0.4)_0%,rgba(16,9,11,0.85)_100%)] text-[#FAF2EE] border-[#961826]/70 shadow-[0_0_10px_rgba(200,35,51,0.2)]'
                        : 'bg-[#11090B] text-[#8E7E81] hover:text-[#FAF2EE] border-[#281318] hover:border-[#451B24]'
                    }`}
                  >
                    <IconVoiceWave size={11} className={isSelected ? 'text-[#FF5A6B]' : 'text-[#6E5E61]'} />
                    <span>{cleanLabel(vc.name)}</span>
                  </button>
                );
              })}
            </div>

            <button
              type="button"
              onPointerDown={() => {
                setPttActive(true);
                getMevaVadEngine().setPttPressed(true);
              }}
              onPointerUp={() => {
                setPttActive(false);
                getMevaVadEngine().setPttPressed(false);
                triggerSelfSpeakingPulse();
              }}
              onPointerLeave={() => {
                setPttActive(false);
                getMevaVadEngine().setPttPressed(false);
              }}
              onPointerCancel={() => {
                setPttActive(false);
                getMevaVadEngine().setPttPressed(false);
              }}
              onKeyDown={(e) => {
                if (e.key === ' ' || e.key === 'Enter') {
                  setPttActive(true);
                  getMevaVadEngine().setPttPressed(true);
                }
              }}
              onKeyUp={(e) => {
                if (e.key === ' ' || e.key === 'Enter') {
                  setPttActive(false);
                  getMevaVadEngine().setPttPressed(false);
                  triggerSelfSpeakingPulse();
                }
              }}
              className={`rounded-lg h-7 px-3 text-[11px] font-bold border transition-all duration-150 flex items-center gap-1.5 flex-shrink-0 whitespace-nowrap ${
                selfTransmitting
                  ? 'crimson-cta text-[#F4EFF0]'
                  : 'bg-[#150A0E] hover:bg-[#1E0C12] text-[#F4EFF0] hover:border-[#961826]/55 border-[#2E151C]'
              }`}
              title="Bas-Konuş (Basılı tutun veya V tuşunu kullanın)"
            >
              <IconMic size={12} />
              <span>{pttActive ? 'İletiliyor...' : 'Bas-Konuş · V'}</span>
            </button>
          </div>
        </div>

        {beaconToast && (
          <div className="py-1 px-3 rounded-lg bg-[#590C15]/70 border border-[#C82333]/80 text-[#FAF2EE] text-[11px] font-extrabold flex items-center justify-between shadow-[0_0_16px_rgba(200,35,51,0.35)] animate-in fade-in duration-150">
            <span>{beaconToast}</span>
            <span className="text-[10px] text-[#FF5A6B]">P2P Link Hazır ✓</span>
          </div>
        )}

        <div className="grid grid-cols-5 gap-2.5">
          {renderOperatorCards(false)}
        </div>
      </section>

      {/* 2. DESKTOP BOTTOM SPLIT DECK */}
      <div className="hidden lg:grid flex-1 min-h-0 grid-cols-12 gap-2.5 overflow-hidden">
        {/* LEFT-BOTTOM (7 Cols): Unified Tactical Comms Stream */}
        <section className="col-span-7 titanium-module rounded-xl flex flex-col overflow-hidden min-h-0">
          <div className="relative min-h-[44px] px-3.5 py-1.5 flex items-center justify-between gap-2 bg-[#0C080A]/75 flex-shrink-0 overflow-x-auto no-scrollbar">
            <span
              aria-hidden
              className="pointer-events-none absolute inset-x-3 bottom-0 h-px horizon-divider opacity-80"
            />
            <div className="flex items-center gap-2 flex-shrink-0">
              <span className="w-1.5 h-3.5 rounded-full bg-[#C82333]" />
              <h3 className="text-[13px] font-extrabold text-[#F4EFF0] whitespace-nowrap">
                Taktiksel İletişim
              </h3>
              <span className="rounded-md px-2 py-0.5 bg-[#180B10] border border-[#6E121D]/45 text-[11px] font-bold text-[#F08C96] whitespace-nowrap">
                {chatTitle}
              </span>
              {dmUser && (
                <button
                  type="button"
                  onClick={() => setActiveDMUser(null)}
                  className="rounded-lg px-2 py-0.5 bg-[#180B10] hover:bg-[#220D13] border border-[#32151C] text-[11px] font-bold text-[#F08C96] transition-colors"
                >
                  Genel Akış
                </button>
              )}
              <button
                type="button"
                onClick={() => setShowFingerprintModal(true)}
                title="ECDH P-256 & AES-256-GCM Anahtar Parmak İzi Doğrulaması"
                className="rounded-md px-2 py-0.5 bg-[#14090D] hover:bg-[#210C12] border border-[#881A26]/35 text-[10px] font-mono font-bold text-[#ED8793] transition-colors whitespace-nowrap"
              >
                🔒 {localFingerprint}
              </button>
              <button
                type="button"
                onClick={() => setSearchOpen((v) => !v)}
                title="Mesaj Ara & Taktik Etiket Filtrele"
                className={`rounded-md px-2 py-0.5 text-[10.5px] font-bold border transition-colors whitespace-nowrap ${
                  searchOpen || searchQuery || activeTagFilter
                    ? 'bg-[#7A121D]/35 text-[#F08C96] border-[#A61B29]/55'
                    : 'bg-[#14090D] hover:bg-[#1E0C11] text-[#9E8E91] hover:text-[#F4EFF0] border-[#2A1319]'
                }`}
              >
                Ara
              </button>
            </div>

            <div className="flex items-center gap-1 flex-shrink-0">
              {dynamicCallouts.map((c: { label: string; cue: CalloutCueType; text: string }) => (
                <button
                  key={c.label}
                  type="button"
                  onClick={() => handleCallout(c.text, c.cue)}
                  className="rounded-lg h-7 px-2.5 bg-[#140A0D] hover:bg-[#7A121D] text-[#F4EFF0] border border-[#2C141A] hover:border-[#C82333]/55 text-[11px] font-bold transition-all duration-150 active:scale-95 whitespace-nowrap"
                >
                  {c.label}
                </button>
              ))}
            </div>
          </div>

          {searchOpen && (
            <div className="px-3.5 py-1.5 bg-[#0A0708]/95 border-b border-[#241116] flex items-center justify-between gap-2 flex-shrink-0">
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Mesaj içeriği veya operatör ara..."
                className="rounded-lg flex-1 h-7 px-2.5 bg-[#120A0D] border border-[#2C141A] focus:border-[#C82333]/65 text-[11.5px] text-[#F4EFF0] placeholder:text-[#7D6E71] outline-none"
              />
              <div className="flex items-center gap-1 flex-shrink-0">
                {(['ROTATE', 'ECO', 'INFO', 'CLUTCH'] as const).map((tag) => (
                  <button
                    key={tag}
                    type="button"
                    onClick={() =>
                      setActiveTagFilter((curr) => (curr === tag ? null : tag))
                    }
                    onDoubleClick={() => handleInsertTacticalTag(tag)}
                    title="Tıkla: Filtrele · Çift tıkla: Mesaja etiket ekle"
                    className={`rounded-md h-6 px-2 text-[10px] font-bold border transition-colors ${
                      activeTagFilter === tag
                        ? 'crimson-cta text-[#F4EFF0]'
                        : 'bg-[#140A0D] hover:bg-[#1E0C12] text-[#B8AAAC] border-[#2C141A]'
                    }`}
                  >
                    #{tag}
                  </button>
                ))}
                {(searchQuery || activeTagFilter) && (
                  <button
                    type="button"
                    onClick={() => {
                      setSearchQuery('');
                      setActiveTagFilter(null);
                    }}
                    className="rounded-md h-6 px-2 bg-[#1A0B10] text-[10px] font-bold text-[#F08C96] border border-[#7A121D]/45"
                  >
                    Temizle
                  </button>
                )}
              </div>
            </div>
          )}

          <TacticalMessageFeed
            messages={filteredMessages}
            userId={userId}
            playingVoiceNoteId={playingVoiceNoteId}
            onToggleVoiceNote={setPlayingVoiceNoteId}
            copiedMsgId={copiedMsgId}
            onCopyMessage={handleCopyMessage}
            ecoActive={ecoActive}
            bottomRef={bottomRef}
          />

          <form
            onSubmit={handleSubmit}
            className="relative p-2.5 bg-[#0A0708]/85 flex items-center gap-2 flex-shrink-0"
          >
            <span
              aria-hidden
              className="pointer-events-none absolute inset-x-3 top-0 h-px horizon-divider opacity-75"
            />
            <div className="relative flex-1 min-w-0">
              <input
                type="text"
                value={input}
                onChange={(e) => setInput(e.target.value)}
                placeholder={`${chatTitle} kanalına taktik mesaj yazın...`}
                className="rounded-xl w-full h-9 pl-3.5 pr-9 bg-[#11090B] border border-[#2A1319] focus:border-[#C82333]/70 text-xs text-[#F4EFF0] placeholder:text-[#7D6E71] outline-none transition-colors"
              />
              <span
                aria-hidden
                className="pointer-events-none absolute right-2.5 top-1/2 -translate-y-1/2 rounded px-1.5 py-0.5 bg-[#1B0C10] text-[10px] font-bold text-[#827376]"
              >
                ↵
              </span>
            </div>
            <button
              type="submit"
              disabled={!input.trim()}
              className="crimson-cta rounded-xl h-9 px-4 text-[#F4EFF0] disabled:text-[#6E5F62] text-xs font-bold flex items-center gap-1.5 transition-all"
            >
              <IconSend size={13} />
              <span>Gönder</span>
            </button>
          </form>
        </section>

        {/* RIGHT-BOTTOM (5 Cols): 4-Metric Strip + Interactive P2P Mesh */}
        <section className="col-span-5 titanium-module rounded-xl flex flex-col p-3.5 gap-2.5 overflow-hidden min-h-0">
          <div className="flex items-center justify-between gap-2 flex-shrink-0">
            <div className="flex items-center gap-2">
              <IconShield size={14} className="text-[#D63344]" />
              <h3 className="text-[13px] font-extrabold text-[#F4EFF0]">
                P2P Mesh & Sistem Telemetrisi
              </h3>
            </div>
            <button
              type="button"
              onClick={handleToggleStressTest}
              className={`rounded-lg px-2.5 py-1 text-[11px] font-bold border transition-all ${
                stressTestActive
                  ? 'crimson-cta text-[#F4EFF0]'
                  : 'bg-[#140A0D] hover:bg-[#1E0C12] text-[#B8AAAC] hover:text-[#F4EFF0] border-[#2C141A] hover:border-[#8F1622]/55'
              }`}
            >
              {stressTestActive
                ? `Test Aktif · ${telemetry.throughputKbps} kbps`
                : 'Ağ Stres Testi'}
            </button>
          </div>

          <div className="rounded-xl bg-[#0F080A] border border-[#241116] p-2 grid grid-cols-4 gap-1.5 flex-shrink-0">
            <div className="flex flex-col items-center justify-center p-1 rounded-lg bg-[#140A0D] border border-[#200F14] min-w-0">
              <span className="text-[10px] font-medium text-[#8E7E81] truncate w-full text-center">
                Kodek
              </span>
              <span className="text-[11px] font-bold text-[#F4EFF0] mt-0.5 truncate w-full text-center">
                Opus 48k
              </span>
            </div>
            <div className="flex flex-col items-center justify-center p-1 rounded-lg bg-[#140A0D] border border-[#200F14] min-w-0">
              <span className="text-[10px] font-medium text-[#8E7E81] truncate w-full text-center">
                Performans
              </span>
              <span className="text-[11px] font-bold text-[#34D399] mt-0.5 truncate w-full text-center">
                0 Kayıp
              </span>
            </div>
            <div className="flex flex-col items-center justify-center p-1 rounded-lg bg-[#140A0D] border border-[#200F14] min-w-0">
              <span className="text-[10px] font-medium text-[#8E7E81] truncate w-full text-center">
                İşlemci
              </span>
              <span className="text-[11px] font-bold text-[#F4EFF0] mt-0.5 truncate w-full text-center">
                %<CpuLoadBadge fallbackCpu={simMetrics.cpu} />
              </span>
            </div>
            <div className="flex flex-col items-center justify-center p-1 rounded-lg bg-[#140A0D] border border-[#200F14] min-w-0">
              <span className="text-[10px] font-medium text-[#8E7E81] truncate w-full text-center">
                P2P Ağ
              </span>
              <span className="text-[11px] font-bold text-[#F08C96] mt-0.5 truncate w-full text-center">
                %{simMetrics.stability}
              </span>
            </div>
          </div>

          <div className="flex-1 min-h-0 rounded-xl mesh-surface border border-[#2A1319] px-3.5 py-2.5 flex flex-col justify-between overflow-hidden">
            <div className="flex items-center justify-between text-[11px] flex-shrink-0">
              <span className="font-bold text-[#B8AAAC]">
                5-Operatör P2P Mesh Topolojisi
              </span>
              <span className="font-bold text-[#E35D6A] tabular-nums">
                {simMetrics.rtt}ms RTT · {simMetrics.jitter}ms Jitter
              </span>
            </div>

            <div className="flex-1 min-h-0 flex items-center justify-center">
              {renderMeshSvg('max-h-[180px]', 'd-mesh')}
            </div>

            <div className="relative flex items-center justify-between text-[10.5px] text-[#827376] pt-2 flex-shrink-0">
              <span
                aria-hidden
                className="pointer-events-none absolute inset-x-0 top-0 h-px horizon-divider opacity-75"
              />
              <span className="font-medium">
                E2EE Kriptolu Doğrudan Eşler Arası Ağ
              </span>
              <span className="font-extrabold text-[#E35D6A]">
                Meva Secure Mesh Core
              </span>
            </div>
          </div>
        </section>
      </div>

      {showFingerprintModal && (
        <E2eeFingerprintPopover
          open={showFingerprintModal}
          onClose={() => setShowFingerprintModal(false)}
        />
      )}

      {inspectedNodeId && (
        <MeshNodeInspectModal
          node={telemetry.nodes[inspectedNodeId] ?? null}
          onClose={() => setInspectedNodeId(null)}
          onOpenDspDrawer={(id) => {
            const op = activeSquadOperators.find((o) => o.id === id);
            if (op) handleInspectOperator(op);
          }}
        />
      )}

      <OperatorContextMenu
        target={contextTarget}
        onClose={() => setContextTarget(null)}
        onOpenDspDrawer={(id) => {
          const op = activeSquadOperators.find((o) => o.id === id);
          if (op) handleInspectOperator(op);
        }}
        voiceControls={voiceControls}
      />
    </main>
  );
});

interface TacticalMessageFeedProps {
  messages: Message[];
  userId: string;
  playingVoiceNoteId: string | null;
  onToggleVoiceNote: (id: string | null) => void;
  copiedMsgId: string | null;
  onCopyMessage: (msg: Message) => void;
  ecoActive: boolean;
  bottomRef: React.RefObject<HTMLDivElement>;
}

const TacticalMessageFeed = memo(function TacticalMessageFeed({
  messages,
  userId,
  playingVoiceNoteId,
  onToggleVoiceNote,
  copiedMsgId,
  onCopyMessage,
  ecoActive,
  bottomRef,
}: TacticalMessageFeedProps) {
  return (
    <div className="flex-1 min-h-0 overflow-y-auto px-3.5 py-3 lg:py-2.5 space-y-2.5 lg:space-y-2 no-scrollbar virtualized-stream">
      {messages.map((msg) => {
        const isOwn =
          msg.author_id === userId || msg.author_id === 'usr-local';
        const isVoiceNote = msg.content.includes('[SESLİ BRİFİNG');
        const isCallout = msg.content.startsWith('[');
        const isUrgent =
          msg.content.includes('ROTATE') || msg.content.includes('FORCE');
        const authorName = msg.author?.username ?? 'Operatör';
        const time = new Date(msg.created_at).toLocaleTimeString('tr-TR', {
          hour: '2-digit',
          minute: '2-digit',
        });
        const isPlayingThis = playingVoiceNoteId === msg.id;

        const bracketEnd = msg.content.indexOf(']');
        const tagText =
          isCallout && bracketEnd > 1 ? msg.content.slice(1, bracketEnd) : null;
        const bodyText =
          tagText && bracketEnd > 1
            ? msg.content.slice(bracketEnd + 1).trim()
            : msg.content;

        return (
          <div
            key={msg.id}
            className={`virtualized-list relative rounded-xl px-3.5 py-2.5 lg:py-2 border transition-colors ${
              isUrgent
                ? 'bg-[linear-gradient(95deg,rgba(138,20,32,0.22)_0%,rgba(14,9,11,0.78)_75%)] border-[#961826]/45'
                : isVoiceNote
                  ? 'bg-[linear-gradient(95deg,rgba(104,18,28,0.20)_0%,rgba(14,9,11,0.78)_75%)] border-[#7A121D]/45'
                  : isOwn
                    ? 'bg-[linear-gradient(160deg,rgba(36,12,18,0.62)_0%,rgba(11,8,10,0.80)_100%)] border-[#32151C]'
                    : 'bg-[linear-gradient(160deg,rgba(24,10,14,0.55)_0%,rgba(10,8,9,0.78)_100%)] border-[#241116] hover:border-[#3A1820]'
            }`}
          >
            {(isUrgent || isVoiceNote) && (
              <span
                aria-hidden
                className={`absolute left-0 top-2 bottom-2 w-[3px] rounded-full ${
                  isUrgent ? 'bg-[#C82333]' : 'bg-[#8F1622]'
                }`}
              />
            )}
            <div className="flex items-center justify-between gap-2 mb-1 lg:mb-0.5">
              <div className="flex items-center gap-2 min-w-0 flex-wrap">
                <OperatorAvatar name={authorName} size="xs" />
                <span className="text-[12.5px] lg:text-[12px] font-extrabold text-[#F4EFF0]">
                  {authorName}
                </span>
                {tagText && (
                  <span
                    className={`rounded-md px-2 py-0.5 text-[10px] font-bold ${
                      isUrgent
                        ? 'bg-[#8F1622]/30 text-[#F5A8B0] border border-[#C82333]/40'
                        : 'bg-[#5E0E17]/35 text-[#E8ABB2] border border-[#8F1622]/40'
                    }`}
                  >
                    {tagText}
                  </span>
                )}
              </div>
              <div className="flex items-center gap-2 flex-shrink-0">
                <button
                  type="button"
                  onClick={() => onCopyMessage(msg)}
                  title="Mesajı panoya kopyala"
                  className="rounded px-1.5 py-0.5 bg-[#120A0D]/80 hover:bg-[#1E0C12] border border-[#2C141A] text-[10px] font-bold text-[#9E8E91] hover:text-[#F4EFF0] transition-colors"
                >
                  {copiedMsgId === msg.id ? 'Kopyalandı' : 'Kopyala'}
                </button>
                <time
                  suppressHydrationWarning
                  className="text-[11px] font-semibold text-[#827376] tabular-nums"
                >
                  {time}
                </time>
              </div>
            </div>

            <p className="text-[13px] lg:text-[12.5px] leading-relaxed lg:leading-snug text-[#F4EFF0]/95 break-words pl-7">
              {bodyText}
            </p>

            {isVoiceNote && (
              <div className="mt-2 lg:mt-1.5 ml-7 rounded-xl px-3 py-2 lg:py-1.5 bg-[#0C080A] border border-[#2E151C] flex items-center gap-3">
                <button
                  type="button"
                  onClick={() =>
                    onToggleVoiceNote(isPlayingThis ? null : msg.id)
                  }
                  className="crimson-cta rounded-lg px-2.5 py-1 text-[#F4EFF0] text-[10.5px] font-bold flex-shrink-0"
                >
                  {isPlayingThis ? 'Durdur' : 'Dinle · 0:08'}
                </button>
                <FluidWave
                  level={0.85}
                  active={isPlayingThis && !ecoActive}
                  speed={1.2}
                  className="flex-1 h-5"
                />
                <span className="hidden sm:inline text-[10px] font-bold text-[#E35D6A] flex-shrink-0">
                  Opus 48kHz
                </span>
              </div>
            )}
          </div>
        );
      })}
      <div ref={bottomRef} />
    </div>
  );
});
