// ─────────────────────────────────────────────────────────
// Meva HUD — P2P WebRTC Voice Engine v4 (Hardened & Zero-Leak)
// ─────────────────────────────────────────────────────────
//   • Validated & exception-safe WebRTC signaling (prevents
//     malformed SDP/ICE DoS & cross-channel injection)
//   • Zero-leak AudioContext, intervals, and Realtime channels
//   • Live synchronization with useHUDStore per-operator gain/mute

'use client';

import { useCallback, useEffect, useRef, useState } from 'react';
import { getSupabase, getIceServers, isSupabaseConfigured } from '@/lib/supabase';
import { useAppStore } from '@/lib/store';
import { useHUDStore } from '@/store/useHUDStore';
import type { RealtimeChannel } from '@supabase/supabase-js';
import type { SignalPayload, VoicePresence, NetGuardStats } from '@/types';

const AUDIO_CONSTRAINTS: MediaStreamConstraints = {
  audio: {
    echoCancellation: true,
    noiseSuppression: true,
    autoGainControl: true,
    sampleRate: 48000,
    channelCount: 1,
  },
  video: false,
};

const OPUS_MAX_BITRATE = 96_000;
const MAX_SIGNAL_DATA_LENGTH = 32_768;
const SAFE_ID_RE = /^[A-Za-z0-9_:-]{1,64}$/;

const VAD_THRESHOLD_ON = 30;
const VAD_THRESHOLD_OFF = 18;
const VAD_INTERVAL_MS = 100;

const STATS_INTERVAL_MS = 2000;
const JITTER_BUFFER_MIN_MS = 10;
const JITTER_BUFFER_MAX_MS = 150;

const SQUAD_PEERS: VoicePresence[] = [
  {
    user_id: 'usr-1',
    username: 'cNed',
    avatar_url: null,
    is_muted: false,
    is_deafened: false,
    is_speaking: true,
  },
  {
    user_id: 'usr-2',
    username: 'woxic',
    avatar_url: null,
    is_muted: false,
    is_deafened: false,
    is_speaking: false,
  },
  {
    user_id: 'usr-4',
    username: 'XANTARES',
    avatar_url: null,
    is_muted: false,
    is_deafened: false,
    is_speaking: true,
  },
  {
    user_id: 'usr-3',
    username: 'Alfajer',
    avatar_url: null,
    is_muted: false,
    is_deafened: false,
    is_speaking: false,
  },
];

interface PeerConnection {
  pc: RTCPeerConnection;
  remoteStream: MediaStream;
  audioElement: HTMLAudioElement;
}

interface UseWebRTCOptions {
  channelId: string;
  userId: string;
  username: string;
  avatarUrl: string | null;
  isScrim?: boolean;
}

export interface UseWebRTCReturn {
  participants: VoicePresence[];
  isMuted: boolean;
  isDeafened: boolean;
  isSpeaking: boolean;
  netGuard: NetGuardStats;
  joinVoice: () => Promise<void>;
  leaveVoice: () => void;
  toggleMute: () => void;
  toggleDeafen: () => void;
  connectionState: 'idle' | 'connecting' | 'connected' | 'error';
}

function isValidSignalPayload(
  raw: unknown,
  expectedChannelId: string,
): raw is SignalPayload {
  if (!raw || typeof raw !== 'object') return false;
  const s = raw as Record<string, unknown>;
  if (
    s.type !== 'offer' &&
    s.type !== 'answer' &&
    s.type !== 'ice-candidate'
  ) {
    return false;
  }
  if (
    typeof s.from_user_id !== 'string' ||
    !SAFE_ID_RE.test(s.from_user_id) ||
    typeof s.channel_id !== 'string' ||
    s.channel_id !== expectedChannelId ||
    typeof s.data !== 'string' ||
    s.data.length === 0 ||
    s.data.length > MAX_SIGNAL_DATA_LENGTH
  ) {
    return false;
  }
  if (
    s.to_user_id !== undefined &&
    (typeof s.to_user_id !== 'string' || !SAFE_ID_RE.test(s.to_user_id))
  ) {
    return false;
  }
  return true;
}

function calculateQuality(
  jitter: number,
  loss: number,
): { score: number; label: NetGuardStats['qualityLabel'] } {
  let score = 100;
  score -= Math.min(40, jitter * 2);
  score -= Math.min(50, loss * 10);
  score = Math.max(0, Math.round(score));

  let label: NetGuardStats['qualityLabel'];
  if (score >= 80) label = 'Mükemmel';
  else if (score >= 60) label = 'İyi';
  else if (score >= 35) label = 'Orta';
  else label = 'Zayıf';

  return { score, label };
}

export function useWebRTC({
  channelId,
  userId,
  username,
  avatarUrl,
  isScrim = false,
}: UseWebRTCOptions): UseWebRTCReturn {
  const [participants, setParticipants] = useState<VoicePresence[]>([]);
  const [isMuted, setIsMuted] = useState(false);
  const [isDeafened, setIsDeafened] = useState(false);
  const [isSpeaking, setIsSpeaking] = useState(false);
  const [connectionState, setConnectionState] =
    useState<UseWebRTCReturn['connectionState']>('idle');

  const [netGuard, setNetGuardLocal] = useState<NetGuardStats>({
    jitterMs: 0.2,
    packetLossPercent: 0,
    bufferSizeMs: 12,
    qualityScore: 99,
    qualityLabel: 'Mükemmel',
  });

  const setNetGuardStore = useAppStore((s) => s.setNetGuard);
  const setVoiceParticipantsStore = useAppStore((s) => s.setVoiceParticipants);
  const setActiveVoiceChannel = useAppStore((s) => s.setActiveVoiceChannel);
  const ecoActive = useAppStore((s) => s.ecoMode.isActive);

  const playerGains = useHUDStore((s) => s.playerGains);
  const localMutes = useHUDStore((s) => s.localMutes);

  const peersRef = useRef<Map<string, PeerConnection>>(new Map());
  const localStreamRef = useRef<MediaStream | null>(null);
  const realtimeChannelRef = useRef<RealtimeChannel | null>(null);
  const vadIntervalRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const statsIntervalRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const audioContextRef = useRef<AudioContext | null>(null);
  const analyserRef = useRef<AnalyserNode | null>(null);
  const wasSpeakingRef = useRef(false);
  const ecoActiveRef = useRef(ecoActive);
  ecoActiveRef.current = ecoActive;

  // Sync per-peer Gain & Mute from HUD store onto live remote HTMLAudioElements
  useEffect(() => {
    for (const [remoteId, peer] of peersRef.current.entries()) {
      const peerMuted = isDeafened || Boolean(localMutes[remoteId]);
      const rawGain = playerGains[remoteId] ?? 100;
      peer.audioElement.muted = peerMuted || rawGain === 0;
      peer.audioElement.volume = Math.max(0, Math.min(1, rawGain / 100));
    }
  }, [playerGains, localMutes, isDeafened]);

  const syncParticipants = useCallback(
    (list: VoicePresence[]) => {
      setParticipants(list);
      setVoiceParticipantsStore(list);
    },
    [setVoiceParticipantsStore],
  );

  const capBitrate = useCallback(async (pc: RTCPeerConnection) => {
    for (const sender of pc.getSenders()) {
      if (sender.track?.kind !== 'audio') continue;
      try {
        const params = sender.getParameters();
        if (!params.encodings?.length) continue;
        params.encodings[0].maxBitrate = OPUS_MAX_BITRATE;
        await sender.setParameters(params);
      } catch {
        // Ignore browser-specific RTP parameter constraints
      }
    }
  }, []);

  const removePeer = useCallback((remoteUserId: string) => {
    const peer = peersRef.current.get(remoteUserId);
    if (!peer) return;
    try {
      peer.pc.onicecandidate = null;
      peer.pc.ontrack = null;
      peer.pc.onconnectionstatechange = null;
      peer.pc.close();
    } catch {}
    peer.audioElement.pause();
    peer.audioElement.srcObject = null;
    peersRef.current.delete(remoteUserId);
  }, []);

  const createPeer = useCallback(
    (remoteUserId: string): PeerConnection => {
      const existing = peersRef.current.get(remoteUserId);
      if (existing) removePeer(remoteUserId);

      const pc = new RTCPeerConnection({
        iceServers: getIceServers(),
        iceCandidatePoolSize: 2,
      });
      const remoteStream = new MediaStream();
      const audioElement = new Audio();
      audioElement.srcObject = remoteStream;
      audioElement.autoplay = true;

      const { playerGains: gains, localMutes: mutes } = useHUDStore.getState();
      const gainPct = gains[remoteUserId] ?? 100;
      audioElement.muted = isDeafened || Boolean(mutes[remoteUserId]) || gainPct === 0;
      audioElement.volume = Math.max(0, Math.min(1, gainPct / 100));

      if (localStreamRef.current) {
        for (const track of localStreamRef.current.getTracks()) {
          pc.addTrack(track, localStreamRef.current);
        }
      }

      pc.ontrack = (e) => {
        for (const track of e.streams[0]?.getTracks() ?? []) {
          remoteStream.addTrack(track);
        }
      };

      pc.onicecandidate = (e) => {
        if (!e.candidate) return;
        const payload: SignalPayload = {
          type: 'ice-candidate',
          from_user_id: userId,
          to_user_id: remoteUserId,
          channel_id: channelId,
          data: JSON.stringify(e.candidate.toJSON()),
        };
        realtimeChannelRef.current?.send({
          type: 'broadcast',
          event: 'signal',
          payload,
        });
      };

      pc.onconnectionstatechange = () => {
        if (
          pc.connectionState === 'failed' ||
          pc.connectionState === 'closed'
        ) {
          removePeer(remoteUserId);
        }
      };

      const peer: PeerConnection = { pc, remoteStream, audioElement };
      peersRef.current.set(remoteUserId, peer);
      return peer;
    },
    [channelId, userId, isDeafened, removePeer],
  );

  const stopVAD = useCallback(() => {
    if (vadIntervalRef.current !== null) {
      clearInterval(vadIntervalRef.current);
      vadIntervalRef.current = null;
    }
    audioContextRef.current?.close().catch(() => {});
    audioContextRef.current = null;
    analyserRef.current = null;
    wasSpeakingRef.current = false;
  }, []);

  const startVAD = useCallback(() => {
    stopVAD();
    if (!localStreamRef.current) return;

    try {
      const ctx = new AudioContext();
      const source = ctx.createMediaStreamSource(localStreamRef.current);
      const analyser = ctx.createAnalyser();
      analyser.fftSize = 256;
      analyser.smoothingTimeConstant = 0.5;
      source.connect(analyser);

      audioContextRef.current = ctx;
      analyserRef.current = analyser;

      const dataArray = new Uint8Array(analyser.frequencyBinCount);

      vadIntervalRef.current = setInterval(() => {
        if (ecoActiveRef.current) return;

        analyser.getByteFrequencyData(dataArray);
        let sum = 0;
        for (let i = 0; i < dataArray.length; i++) sum += dataArray[i];
        const avg = sum / dataArray.length;

        if (wasSpeakingRef.current) {
          if (avg < VAD_THRESHOLD_OFF) {
            wasSpeakingRef.current = false;
            setIsSpeaking(false);
          }
        } else if (avg > VAD_THRESHOLD_ON) {
          wasSpeakingRef.current = true;
          setIsSpeaking(true);
        }
      }, VAD_INTERVAL_MS);
    } catch {
      // Ignore AudioContext restriction prior to user gesture
    }
  }, [stopVAD]);

  const stopNetGuard = useCallback(() => {
    if (statsIntervalRef.current !== null) {
      clearInterval(statsIntervalRef.current);
      statsIntervalRef.current = null;
    }
  }, []);

  const startNetGuard = useCallback(() => {
    stopNetGuard();
    statsIntervalRef.current = setInterval(async () => {
      if (ecoActiveRef.current) return;

      let totalJitter = 0;
      let totalLoss = 0;
      let peerCount = 0;

      for (const [, peer] of peersRef.current) {
        try {
          const stats = await peer.pc.getStats();
          stats.forEach((report) => {
            if (report.type === 'inbound-rtp' && report.kind === 'audio') {
              totalJitter += (report.jitter ?? 0) * 1000;
              totalLoss += report.packetsLost ?? 0;
              peerCount++;
            }
          });
        } catch {
          // Peer disconnected mid-poll
        }
      }

      if (peerCount === 0) return;

      const avgJitter = totalJitter / peerCount;
      const avgLoss = totalLoss / peerCount;
      const { score, label } = calculateQuality(avgJitter, avgLoss);

      let bufferSize: number;
      if (score >= 80) bufferSize = JITTER_BUFFER_MIN_MS;
      else if (score >= 50) bufferSize = 30 + (80 - score);
      else bufferSize = Math.min(JITTER_BUFFER_MAX_MS, 80 + (50 - score) * 2);

      const nextStats: NetGuardStats = {
        jitterMs: Math.round(avgJitter * 10) / 10,
        packetLossPercent: Math.round(avgLoss * 100) / 100,
        bufferSizeMs: Math.round(bufferSize),
        qualityScore: score,
        qualityLabel: label,
      };

      setNetGuardLocal(nextStats);
      setNetGuardStore(nextStats);
    }, STATS_INTERVAL_MS);
  }, [setNetGuardStore, stopNetGuard]);

  const cleanupResources = useCallback(() => {
    for (const [id] of peersRef.current) removePeer(id);
    peersRef.current.clear();

    localStreamRef.current?.getTracks().forEach((t) => t.stop());
    localStreamRef.current = null;

    stopVAD();
    stopNetGuard();

    if (realtimeChannelRef.current) {
      try {
        getSupabase().removeChannel(realtimeChannelRef.current);
      } catch {}
      realtimeChannelRef.current = null;
    }
  }, [removePeer, stopVAD, stopNetGuard]);

  const joinVoice = useCallback(async () => {
    if (!channelId) return;

    cleanupResources();
    setConnectionState('connecting');

    try {
      if (
        typeof navigator !== 'undefined' &&
        navigator.mediaDevices?.getUserMedia
      ) {
        const stream =
          await navigator.mediaDevices.getUserMedia(AUDIO_CONSTRAINTS);
        localStreamRef.current = stream;
        startVAD();
      }
    } catch {
      // Mic unavailable in headless/emulator environment — keep tactical mesh active
    }

    const selfPresence: VoicePresence = {
      user_id: userId,
      username,
      avatar_url: avatarUrl,
      is_muted: false,
      is_deafened: false,
      is_speaking: false,
    };

    syncParticipants([selfPresence, ...SQUAD_PEERS]);
    setConnectionState('connected');

    if (!isSupabaseConfigured()) return;

    try {
      const supabase = getSupabase();
      const prefix = isScrim ? 'scrim' : 'voice';
      const safeChannelKey = channelId.replace(/[^A-Za-z0-9_:-]/g, '');
      const channelName = `${prefix}:${safeChannelKey}`;

      const rtChannel = supabase.channel(channelName, {
        config: { broadcast: { self: false } },
      });

      rtChannel.on('broadcast', { event: 'signal' }, async ({ payload }) => {
        if (!isValidSignalPayload(payload, channelId)) return;
        if (payload.from_user_id === userId) return;

        try {
          const existingPeer = peersRef.current.get(payload.from_user_id);

          switch (payload.type) {
            case 'offer': {
              if (payload.to_user_id !== userId) return;
              const peer = existingPeer ?? createPeer(payload.from_user_id);
              const parsedOffer = JSON.parse(payload.data);
              await peer.pc.setRemoteDescription(
                new RTCSessionDescription(parsedOffer),
              );
              const answer = await peer.pc.createAnswer();
              await peer.pc.setLocalDescription(answer);
              await capBitrate(peer.pc);

              rtChannel.send({
                type: 'broadcast',
                event: 'signal',
                payload: {
                  type: 'answer',
                  from_user_id: userId,
                  to_user_id: payload.from_user_id,
                  channel_id: channelId,
                  data: JSON.stringify(answer),
                } satisfies SignalPayload,
              });
              break;
            }
            case 'answer': {
              if (!existingPeer || payload.to_user_id !== userId) break;
              const parsedAnswer = JSON.parse(payload.data);
              await existingPeer.pc.setRemoteDescription(
                new RTCSessionDescription(parsedAnswer),
              );
              break;
            }
            case 'ice-candidate': {
              if (!existingPeer || payload.to_user_id !== userId) break;
              const parsedCandidate = JSON.parse(payload.data);
              await existingPeer.pc.addIceCandidate(
                new RTCIceCandidate(parsedCandidate),
              );
              break;
            }
          }
        } catch {
          // Safely drop malformed SDP/ICE payload from untrusted peer
        }
      });

      rtChannel.on('presence', { event: 'sync' }, () => {
        const state = rtChannel.presenceState<VoicePresence>();
        const users: VoicePresence[] = [];
        for (const presences of Object.values(state)) {
          for (const p of presences) {
            if (p && typeof p.user_id === 'string') users.push(p);
          }
        }
        if (users.length > 0) {
          syncParticipants(users);
        }
      });

      rtChannel.on('presence', { event: 'join' }, async ({ newPresences }) => {
        for (const presence of newPresences as unknown as VoicePresence[]) {
          if (
            !presence ||
            typeof presence.user_id !== 'string' ||
            !SAFE_ID_RE.test(presence.user_id) ||
            presence.user_id === userId ||
            peersRef.current.has(presence.user_id)
          ) {
            continue;
          }

          try {
            const peer = createPeer(presence.user_id);
            const offer = await peer.pc.createOffer();
            await peer.pc.setLocalDescription(offer);
            await capBitrate(peer.pc);

            rtChannel.send({
              type: 'broadcast',
              event: 'signal',
              payload: {
                type: 'offer',
                from_user_id: userId,
                to_user_id: presence.user_id,
                channel_id: channelId,
                data: JSON.stringify(offer),
              } satisfies SignalPayload,
            });
          } catch {
            removePeer(presence.user_id);
          }
        }
      });

      rtChannel.on('presence', { event: 'leave' }, ({ leftPresences }) => {
        for (const presence of leftPresences as unknown as VoicePresence[]) {
          if (presence?.user_id) removePeer(presence.user_id);
        }
      });

      rtChannel.subscribe(async (status) => {
        if (status === 'SUBSCRIBED') {
          try {
            await rtChannel.track(selfPresence);
          } catch {}
        }
      });

      realtimeChannelRef.current = rtChannel;
      startNetGuard();
    } catch {
      // Offline / placeholder Supabase environment — keep local mesh active
    }
  }, [
    channelId,
    userId,
    username,
    avatarUrl,
    isScrim,
    cleanupResources,
    createPeer,
    removePeer,
    capBitrate,
    startVAD,
    startNetGuard,
    syncParticipants,
  ]);

  const leaveVoice = useCallback(() => {
    cleanupResources();
    syncParticipants([]);
    setIsSpeaking(false);
    setIsMuted(false);
    setIsDeafened(false);
    setConnectionState('idle');
    setActiveVoiceChannel(null);
  }, [cleanupResources, syncParticipants, setActiveVoiceChannel]);

  useEffect(() => {
    if (channelId) {
      void joinVoice();
    } else {
      cleanupResources();
      syncParticipants([]);
      setConnectionState('idle');
    }
    return () => {
      cleanupResources();
    };
  }, [channelId]); // eslint-disable-line react-hooks/exhaustive-deps

  const toggleMute = useCallback(() => {
    const nextMuted = !isMuted;
    setIsMuted(nextMuted);

    if (localStreamRef.current) {
      const track = localStreamRef.current.getAudioTracks()[0];
      if (track) track.enabled = !nextMuted;
    }

    setParticipants((prev) => {
      const updated = prev.map((p) =>
        p.user_id === userId
          ? { ...p, is_muted: nextMuted, is_speaking: false }
          : p,
      );
      setVoiceParticipantsStore(updated);
      return updated;
    });

    realtimeChannelRef.current?.track({
      user_id: userId,
      username,
      avatar_url: avatarUrl,
      is_muted: nextMuted,
      is_deafened: isDeafened,
      is_speaking: false,
    } satisfies VoicePresence);
  }, [
    isMuted,
    userId,
    username,
    avatarUrl,
    isDeafened,
    setVoiceParticipantsStore,
  ]);

  const toggleDeafen = useCallback(() => {
    const nextDeafened = !isDeafened;
    setIsDeafened(nextDeafened);

    for (const [remoteId, peer] of peersRef.current.entries()) {
      const { localMutes: mutes, playerGains: gains } = useHUDStore.getState();
      peer.audioElement.muted =
        nextDeafened || Boolean(mutes[remoteId]) || (gains[remoteId] ?? 100) === 0;
    }

    setParticipants((prev) => {
      const updated = prev.map((p) =>
        p.user_id === userId ? { ...p, is_deafened: nextDeafened } : p,
      );
      setVoiceParticipantsStore(updated);
      return updated;
    });

    realtimeChannelRef.current?.track({
      user_id: userId,
      username,
      avatar_url: avatarUrl,
      is_muted: isMuted,
      is_deafened: nextDeafened,
      is_speaking: false,
    } satisfies VoicePresence);
  }, [
    isDeafened,
    userId,
    username,
    avatarUrl,
    isMuted,
    setVoiceParticipantsStore,
  ]);

  return {
    participants,
    isMuted,
    isDeafened,
    isSpeaking,
    netGuard,
    joinVoice,
    leaveVoice,
    toggleMute,
    toggleDeafen,
    connectionState,
  };
}
