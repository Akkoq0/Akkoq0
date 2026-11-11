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

export const INITIAL_TACTICAL_MESSAGES: Message[] = [];

const SEED_BY_CHANNEL: Record<string, Message[]> = {};

export function useRealtimeChat(channelId: string | null) {
  const addMessage = useAppStore((s) => s.addMessage);
  const setMessages = useAppStore((s) => s.setMessages);
  const activeDMUserId = useAppStore((s) => s.activeDMUserId);

  const effectiveTargetId = activeDMUserId
    ? `dm:${activeDMUserId}`
    : channelId;

  useEffect(() => {
    if (!effectiveTargetId) {
      setMessages([]);
      return;
    }

    setMessages([]);

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
            const incomingMsg: Message = {
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
            };
            addMessage(incomingMsg);
            void getMevaStorageEngine().appendChannelMessage(wire.channelId, incomingMsg);
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
      if (!sanitized || !effectiveTargetId) return;

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
      void getMevaStorageEngine().appendChannelMessage(effectiveTargetId, optimisticMsg);

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
