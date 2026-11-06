// ─────────────────────────────────────────────────────────
// Meva HUD — Realtime Tactical Comms Hook (Pre-Populated)
// ─────────────────────────────────────────────────────────

'use client';

import { useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { useAppStore } from '@/lib/store';
import type { Message } from '@/types';

export const INITIAL_TACTICAL_MESSAGES: Message[] = [
  {
    id: 'msg-tac-1',
    channel_id: 'ch-2',
    author_id: 'usr-local',
    content:
      '[ROUND 14 — ECO KARARI] Bu el tam eco, kredi koruyoruz (min 4100). Sadece Sheriff ile Mid-Market info alıyoruz; 15. roundda çift Operator + tam utility ile çıkacağız.',
    created_at: new Date(Date.now() - 420_000).toISOString(),
    author: {
      id: 'usr-local',
      username: 'Operatör',
      avatar_url: null,
      status: 'online',
      activity: 'IGL · Taktik Komuta',
      created_at: new Date().toISOString(),
    },
  },
  {
    id: 'msg-tac-2',
    channel_id: 'ch-2',
    author_id: 'usr-5',
    content:
      '[SESLİ BRİFİNG · 0:08] Ascent B-Main retake zamanlaması: Killjoy ultisi kurulduğu an Sova recon oku arka duvara düşecek, 1.5 saniye sonra ikili flash ile giriş yapıyoruz.',
    created_at: new Date(Date.now() - 310_000).toISOString(),
    author: {
      id: 'usr-5',
      username: 'AimCoach_Mert',
      avatar_url: null,
      status: 'online',
      activity: 'Baş Antrenör · Analist',
      created_at: new Date().toISOString(),
    },
  },
  {
    id: 'msg-tac-3',
    channel_id: 'ch-2',
    author_id: 'usr-1',
    content:
      '[TAKTİK ÇAĞRI: ROTATE B] A-Main tamamen temiz, Operator ile Mid-Cubby hattını kilitledim. 3 ayak sesi B-Lobby yönüne kaydı, hızlı rotasyon!',
    created_at: new Date(Date.now() - 210_000).toISOString(),
    author: {
      id: 'usr-1',
      username: 'cNed',
      avatar_url: null,
      status: 'in-game',
      activity: 'AWP · Jett (Radiant #14)',
      created_at: new Date().toISOString(),
    },
  },
  {
    id: 'msg-tac-4',
    channel_id: 'ch-2',
    author_id: 'usr-4',
    content:
      '[GİRİŞ KOORDİNASYONU] B-Main boğazına tek yön duman + çift flash hazır. Komutla birlikte 3-2-1 patlatıp site içine sızıyoruz, takaslara yakın durun.',
    created_at: new Date(Date.now() - 140_000).toISOString(),
    author: {
      id: 'usr-4',
      username: 'XANTARES',
      avatar_url: null,
      status: 'in-game',
      activity: 'ENTRY · Raze / AK-47',
      created_at: new Date().toISOString(),
    },
  },
  {
    id: 'msg-tac-5',
    channel_id: 'ch-2',
    author_id: 'usr-2',
    content:
      '[CLUTCH RAPORU — 2v2] Spike B-Default konumuna kuruldu. CT-Spawn ve Market penceresini çapraz ateşe aldık, pozisyon bozmadan süreyi oynuyoruz.',
    created_at: new Date(Date.now() - 75_000).toISOString(),
    author: {
      id: 'usr-2',
      username: 'woxic',
      avatar_url: null,
      status: 'in-game',
      activity: 'LURKER · Sova (Faceit Lvl 10)',
      created_at: new Date().toISOString(),
    },
  },
  {
    id: 'msg-tac-6',
    channel_id: 'ch-2',
    author_id: 'usr-3',
    content:
      '[SAVUNMA KİLİDİ] Lockdown ultisi %100 hazır. Rakip retake denediği an B-Boathouse köşesinden cihazı aktif ediyorum, herkes geri çekilip süreyi eritsin.',
    created_at: new Date(Date.now() - 25_000).toISOString(),
    author: {
      id: 'usr-3',
      username: 'Alfajer',
      avatar_url: null,
      status: 'in-game',
      activity: 'ANCHOR · Killjoy',
      created_at: new Date().toISOString(),
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
        '[TURNUVA DUYURUSU] VCT EMEA Kapalı Eleme Scrim bloğu saat 20:00\'de başlıyor. Tüm kadro Taktik Lobi #1 frekansında (96kbps Opus P2P) hazır bulunsun.',
      created_at: new Date(Date.now() - 600_000).toISOString(),
      author: {
        id: 'usr-5',
        username: 'AimCoach_Mert',
        avatar_url: null,
        status: 'online',
        activity: 'Baş Antrenör',
        created_at: new Date().toISOString(),
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
      created_at: new Date(Date.now() - 500_000).toISOString(),
      author: {
        id: 'usr-1',
        username: 'cNed',
        avatar_url: null,
        status: 'in-game',
        activity: 'AWP · Radiant #14',
        created_at: new Date().toISOString(),
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
      created_at: new Date(Date.now() - 480_000).toISOString(),
      author: {
        id: 'usr-3',
        username: 'Alfajer',
        avatar_url: null,
        status: 'in-game',
        activity: 'ANCHOR · Analiz',
        created_at: new Date().toISOString(),
      },
    },
    ...INITIAL_TACTICAL_MESSAGES.slice(1, 5),
  ],
};

export function useRealtimeChat(channelId: string | null) {
  const addMessage = useAppStore((s) => s.addMessage);
  const setMessages = useAppStore((s) => s.setMessages);
  const activeDMUserId = useAppStore((s) => s.activeDMUserId);
  const friends = useAppStore((s) => s.friends);

  const effectiveTargetId = activeDMUserId
    ? `dm:${activeDMUserId}`
    : channelId || 'ch-2';

  useEffect(() => {
    if (activeDMUserId) {
      const targetFriend = friends.find(
        (f) => f.friend_id === activeDMUserId,
      )?.friend;
      const friendName = targetFriend?.username ?? 'Operatör';
      setMessages([
        {
          id: `dm-seed-1-${activeDMUserId}`,
          channel_id: effectiveTargetId,
          author_id: activeDMUserId,
          content: `[DOĞRUDAN P2P HAT] Selam komutan, 1v1 şifreli ses ve metin hattı aktif (11ms). Maç öncesi taktik üzerinden geçelim mi?`,
          created_at: new Date(Date.now() - 240_000).toISOString(),
          author: targetFriend ?? {
            id: activeDMUserId,
            username: friendName,
            avatar_url: null,
            status: 'in-game',
            activity: 'Doğrudan P2P Bağlantı',
            created_at: new Date().toISOString(),
          },
        },
        {
          id: `dm-seed-2-${activeDMUserId}`,
          channel_id: effectiveTargetId,
          author_id: 'usr-local',
          content: `[ONAYLANDI] Taktik Lobi #1 frekansına geçiyorum, harita dizilimini orada netleştirelim.`,
          created_at: new Date(Date.now() - 120_000).toISOString(),
          author: {
            id: 'usr-local',
            username: 'Operatör',
            avatar_url: null,
            status: 'online',
            activity: 'IGL · Taktik Komuta',
            created_at: new Date().toISOString(),
          },
        },
      ]);
      return;
    }

    const seeded =
      SEED_BY_CHANNEL[effectiveTargetId] ?? INITIAL_TACTICAL_MESSAGES;
    setMessages(seeded);
  }, [effectiveTargetId, activeDMUserId, friends, setMessages]);

  const sendMessage = useCallback(
    async (content: string) => {
      const trimmed = content.trim();
      if (!trimmed) return;

      const optimisticMsg: Message = {
        id: `local-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`,
        channel_id: effectiveTargetId,
        author_id: 'usr-local',
        content: trimmed,
        created_at: new Date().toISOString(),
        author: {
          id: 'usr-local',
          username: 'Operatör',
          avatar_url: null,
          status: 'online',
          activity: 'IGL · Taktik Komuta',
          created_at: new Date().toISOString(),
        },
      };
      addMessage(optimisticMsg);

      try {
        const supabase = getSupabase();
        const {
          data: { user },
        } = await supabase.auth.getUser();
        if (user && !activeDMUserId) {
          await supabase.from('messages').insert({
            channel_id: effectiveTargetId,
            author_id: user.id,
            content: trimmed,
          });
        }
      } catch {
        // Optimistic message already rendered
      }
    },
    [effectiveTargetId, activeDMUserId, addMessage],
  );

  return { sendMessage };
}
