// ─────────────────────────────────────────────────────────
// Meva HUD — Realtime Tactical Comms Hook (Hydration-Safe)
// ─────────────────────────────────────────────────────────

'use client';

import { useEffect, useCallback } from 'react';
import { getSupabase, isSupabaseConfigured } from '@/lib/supabase';
import { useAppStore } from '@/lib/store';
import {
  getMevaAudioEngine,
  type CalloutCueType,
} from '@/src/lib/audioEngine';
import { getMevaCryptoEngine } from '@/src/lib/cryptoEngine';
import { getMevaWebRTCMesh } from '@/src/lib/webrtcMesh';
import { getMevaStorageEngine } from '@/src/lib/storageEngine';
import type { Message } from '@/types';

function inferCalloutCue(content: string): CalloutCueType | undefined {
  const upper = content.toUpperCase();
  if (upper.startsWith('[HAZIR')) return 'ready';
  if (upper.includes('ROTATE')) return 'rotate';
  if (upper.includes('ECO')) return 'eco';
  if (upper.startsWith('[DROP')) return 'drop';
  if (upper.startsWith('[FORCE')) return 'force';
  if (upper.startsWith('[GG')) return 'gg';
  return undefined;
}

const BASE_PROFILE_ISO = '2026-11-06T19:00:00.000Z';

export const INITIAL_TACTICAL_MESSAGES: Message[] = [
  {
    id: 'msg-tac-1',
    channel_id: 'ch-2',
    author_id: 'usr-local',
    content:
      '[ROUND 14 — ECO KARARI] Bu el tam eco, kredi koruyoruz (min 4100). Sadece Sheriff ile Mid-Market info alıyoruz; 15. roundda çift Operator + tam utility ile çıkacağız.',
    created_at: '2026-11-06T19:42:10.000Z',
    author: {
      id: 'usr-local',
      username: 'Operatör',
      avatar_url: null,
      status: 'online',
      activity: 'IGL',
      created_at: BASE_PROFILE_ISO,
    },
  },
  {
    id: 'msg-tac-2',
    channel_id: 'ch-2',
    author_id: 'usr-5',
    content:
      '[SESLİ BRİFİNG · 0:08] Ascent B-Main retake zamanlaması: Killjoy ultisi kurulduğu an Sova recon oku arka duvara düşecek, 1.5 saniye sonra ikili flash ile giriş yapıyoruz.',
    created_at: '2026-11-06T19:44:05.000Z',
    author: {
      id: 'usr-5',
      username: 'AimCoach_Mert',
      avatar_url: null,
      status: 'online',
      activity: 'COACH',
      created_at: BASE_PROFILE_ISO,
    },
  },
  {
    id: 'msg-tac-3',
    channel_id: 'ch-2',
    author_id: 'usr-1',
    content:
      '[TAKTİK ÇAĞRI: ROTATE B] A-Main tamamen temiz, Operator ile Mid-Cubby hattını kilitledim. 3 ayak sesi B-Lobby yönüne kaydı, hızlı rotasyon!',
    created_at: '2026-11-06T19:45:42.000Z',
    author: {
      id: 'usr-1',
      username: 'cNed',
      avatar_url: null,
      status: 'in-game',
      activity: 'AWP',
      created_at: BASE_PROFILE_ISO,
    },
  },
  {
    id: 'msg-tac-4',
    channel_id: 'ch-2',
    author_id: 'usr-4',
    content:
      '[GİRİŞ KOORDİNASYONU] B-Main boğazına tek yön duman + çift flash hazır. Komutla birlikte 3-2-1 patlatıp site içine sızıyoruz, takaslara yakın durun.',
    created_at: '2026-11-06T19:46:55.000Z',
    author: {
      id: 'usr-4',
      username: 'XANTARES',
      avatar_url: null,
      status: 'in-game',
      activity: 'ENTRY',
      created_at: BASE_PROFILE_ISO,
    },
  },
  {
    id: 'msg-tac-5',
    channel_id: 'ch-2',
    author_id: 'usr-2',
    content:
      '[CLUTCH RAPORU — 2v2] Spike B-Default konumuna kuruldu. CT-Spawn ve Market penceresini çapraz ateşe aldık, pozisyon bozmadan süreyi oynuyoruz.',
    created_at: '2026-11-06T19:48:18.000Z',
    author: {
      id: 'usr-2',
      username: 'woxic',
      avatar_url: null,
      status: 'in-game',
      activity: 'LURKER',
      created_at: BASE_PROFILE_ISO,
    },
  },
  {
    id: 'msg-tac-6',
    channel_id: 'ch-2',
    author_id: 'usr-3',
    content:
      '[SAVUNMA KİLİDİ] Lockdown ultisi %100 hazır. Rakip retake denediği an B-Boathouse köşesinden cihazı aktif ediyorum, herkes geri çekilip süreyi eritsin.',
    created_at: '2026-11-06T19:49:30.000Z',
    author: {
      id: 'usr-3',
      username: 'Alfajer',
      avatar_url: null,
      status: 'in-game',
      activity: 'COACH',
      created_at: BASE_PROFILE_ISO,
    },
  },
];

const SEED_BY_CHANNEL: Record<string, Message[]> = {
  'ch-1': [
    {
      id: 'msg-ch1-1',
      channel_id: 'ch-1',
      author_id: 'usr-5',
      content:
        "[TURNUVA DUYURUSU] VCT EMEA Kapalı Eleme Scrim bloğu saat 20:00'de başlıyor. Tüm kadro Taktik Lobi #1 frekansında (96kbps Opus P2P) hazır bulunsun.",
      created_at: '2026-11-06T19:38:00.000Z',
      author: {
        id: 'usr-5',
        username: 'AimCoach_Mert',
        avatar_url: null,
        status: 'online',
        activity: 'Baş Antrenör',
        created_at: BASE_PROFILE_ISO,
      },
    },
    ...INITIAL_TACTICAL_MESSAGES.slice(0, 4),
  ],
  'ch-2': INITIAL_TACTICAL_MESSAGES,
  'ch-3': [
    {
      id: 'msg-ch3-1',
      channel_id: 'ch-3',
      author_id: 'usr-1',
      content:
        '[SCRIM ARAMA — BO3] Saat 21:00 için Ascent / Bind / Lotus BO3 antrenman maçı arıyoruz. Sunucu: Frankfurt / İstanbul P2P (11ms).',
      created_at: '2026-11-06T19:40:15.000Z',
      author: {
        id: 'usr-1',
        username: 'cNed',
        avatar_url: null,
        status: 'in-game',
        activity: 'AWP',
        created_at: BASE_PROFILE_ISO,
      },
    },
    ...INITIAL_TACTICAL_MESSAGES.slice(2),
  ],
  'ch-vod': [
    {
      id: 'msg-vod-1',
      channel_id: 'ch-vod',
      author_id: 'usr-3',
      content:
        '[SESLİ BRİFİNG · 0:14] FUT vs Fnatic Lotus haritası C-Bend savunma dizilimi ve erken rotasyon zamanlamaları analiz kaydı.',
      created_at: '2026-11-06T19:41:00.000Z',
      author: {
        id: 'usr-3',
        username: 'Alfajer',
        avatar_url: null,
        status: 'in-game',
        activity: 'ANCHOR · Analiz',
        created_at: BASE_PROFILE_ISO,
      },
    },
    ...INITIAL_TACTICAL_MESSAGES.slice(1, 5),
  ],
};

export function useRealtimeChat(channelId: string | null) {
  const addMessage = useAppStore((s) => s.addMessage);
  const setMessages = useAppStore((s) => s.setMessages);
  const activeDMUserId = useAppStore((s) => s.activeDMUserId);

  const effectiveTargetId = activeDMUserId
    ? `dm:${activeDMUserId}`
    : channelId || 'ch-2';

  useEffect(() => {
    if (activeDMUserId) {
      const currentFriends = useAppStore.getState().friends;
      const targetFriend = currentFriends.find(
        (f) => f.friend_id === activeDMUserId,
      )?.friend;
      const friendName = targetFriend?.username ?? 'Operatör';
      setMessages([
        {
          id: `dm-seed-1-${activeDMUserId}`,
          channel_id: effectiveTargetId,
          author_id: activeDMUserId,
          content:
            '[DOĞRUDAN P2P HAT] Selam komutan, 1v1 şifreli ses ve metin hattı aktif (11ms). Maç öncesi taktik üzerinden geçelim mi?',
          created_at: '2026-11-06T19:46:00.000Z',
          author: targetFriend ?? {
            id: activeDMUserId,
            username: friendName,
            avatar_url: null,
            status: 'in-game',
            activity: 'Doğrudan P2P Bağlantı',
            created_at: BASE_PROFILE_ISO,
          },
        },
        {
          id: `dm-seed-2-${activeDMUserId}`,
          channel_id: effectiveTargetId,
          author_id: 'usr-local',
          content:
            '[ONAYLANDI] Taktik Lobi #1 frekansına geçiyorum, harita dizilimini orada netleştirelim.',
          created_at: '2026-11-06T19:48:00.000Z',
          author: {
            id: 'usr-local',
            username: 'Operatör',
            avatar_url: null,
            status: 'online',
            activity: 'IGL · Taktik Komuta',
            created_at: BASE_PROFILE_ISO,
          },
        },
      ]);
      return;
    }

    const seeded =
      SEED_BY_CHANNEL[effectiveTargetId] ?? INITIAL_TACTICAL_MESSAGES;
    setMessages(seeded);

    let disposed = false;
    void getMevaStorageEngine()
      .loadChannelMessages(effectiveTargetId)
      .then((persisted) => {
        if (!disposed && persisted && persisted.length > 0) {
          setMessages(persisted);
        }
      });

    // Initialize ECDH P-256 + AES-256-GCM E2EE engine and listen for encrypted DataChannel chat/callouts
    const cryptoEngine = getMevaCryptoEngine();
    void cryptoEngine.initialize();
    const mesh = getMevaWebRTCMesh();

    const unsubMesh = mesh.onDataPacket((envelope) => {
      if (envelope.kind !== 'e2ee-chat' && envelope.kind !== 'e2ee-callout') {
        return;
      }
      void cryptoEngine
        .decryptPayload(
          envelope.payload,
          envelope.room,
          envelope.kind,
          envelope.from,
        )
        .then((result) => {
          if (!result) return;
          try {
            const wire = JSON.parse(result.plaintext) as {
              id: string;
              channelId: string;
              content: string;
              createdAt: string;
              authorName: string;
              role?: string;
              cue?: CalloutCueType;
            };
            if (wire.channelId !== effectiveTargetId) return;
            if (envelope.kind === 'e2ee-callout') {
              const cue = wire.cue ?? inferCalloutCue(wire.content);
              if (cue) getMevaAudioEngine().playCalloutCue(cue);
            }
            addMessage({
              id: wire.id,
              channel_id: wire.channelId,
              author_id: envelope.from,
              content: wire.content,
              created_at: wire.createdAt,
              author: {
                id: envelope.from,
                username: wire.authorName || envelope.fromName || 'Operatör',
                avatar_url: null,
                status: 'online',
                activity: wire.role ?? 'P2P E2EE',
                created_at: BASE_PROFILE_ISO,
              },
            });
          } catch {}
        });
    });

    if (!isSupabaseConfigured()) {
      return () => {
        disposed = true;
        unsubMesh();
      };
    }

    const safeChan = effectiveTargetId.replace(/[^A-Za-z0-9_:-]/g, '');
    if (!safeChan) {
      return () => {
        disposed = true;
        unsubMesh();
      };
    }

    let cancelled = false;
    const supabase = getSupabase();

    supabase
      .from('messages')
      .select('*, author:profiles(*)')
      .eq('channel_id', safeChan)
      .order('created_at', { ascending: true })
      .limit(100)
      .then(
        ({ data }) => {
          if (!cancelled && Array.isArray(data) && data.length > 0) {
            setMessages(data as Message[]);
          }
        },
        () => {},
      );

    const rtSub = supabase
      .channel(`chat:${safeChan}`)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'messages',
          filter: `channel_id=eq.${safeChan}`,
        },
        (payload) => {
          if (cancelled || !payload.new) return;
          const incoming = payload.new as Message;
          if (
            typeof incoming.id === 'string' &&
            typeof incoming.content === 'string'
          ) {
            addMessage(incoming);
          }
        },
      )
      .subscribe();

    return () => {
      disposed = true;
      cancelled = true;
      unsubMesh();
      void supabase.removeChannel(rtSub);
    };
  }, [effectiveTargetId, activeDMUserId, setMessages, addMessage]);

  const sendMessage = useCallback(
    async (content: string) => {
      // Strip non-printable control characters and cap at 2000 chars (matches DB CHECK)
      const sanitized = content
        .replace(/[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]/g, '')
        .trim()
        .slice(0, 2000);
      if (!sanitized) return;

      const msgId =
        typeof crypto !== 'undefined' && 'randomUUID' in crypto
          ? `local-${crypto.randomUUID()}`
          : `local-${Date.now()}`;
      const nowIso = new Date().toISOString();

      const optimisticMsg: Message = {
        id: msgId,
        channel_id: effectiveTargetId,
        author_id: 'usr-local',
        content: sanitized,
        created_at: nowIso,
        author: {
          id: 'usr-local',
          username: 'Operatör',
          avatar_url: null,
          status: 'online',
          activity: 'IGL · Taktik Komuta',
          created_at: BASE_PROFILE_ISO,
        },
      };
      addMessage(optimisticMsg);
      getMevaStorageEngine().recordTacticalMessage(sanitized);

      // Encrypt with AES-256-GCM and transmit over WebRTC DataChannel / Mesh
      const isCallout = sanitized.startsWith('[');
      const cue = isCallout ? inferCalloutCue(sanitized) : undefined;
      try {
        await getMevaCryptoEngine().sendEncryptedMeshPacket(
          isCallout ? 'e2ee-callout' : 'e2ee-chat',
          JSON.stringify({
            id: msgId,
            channelId: effectiveTargetId,
            content: sanitized,
            createdAt: nowIso,
            authorName: 'Operatör',
            role: 'IGL',
            cue,
          }),
        );
      } catch {
        // Local optimistic render remains intact
      }

      if (!isSupabaseConfigured()) return;

      try {
        const supabase = getSupabase();
        const {
          data: { user },
        } = await supabase.auth.getUser();
        if (user && !activeDMUserId) {
          await supabase.from('messages').insert({
            channel_id: effectiveTargetId,
            author_id: user.id,
            content: sanitized,
          });
        }
      } catch {
        // Optimistic message already rendered locally
      }
    },
    [effectiveTargetId, activeDMUserId, addMessage],
  );

  return { sendMessage };
}
