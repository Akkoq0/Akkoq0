// ─────────────────────────────────────────────────────────
// GhostLink — INNOVATION #2: Instant Scrim Link
// ─────────────────────────────────────────────────────────
//
// WHAT IT DOES:
//   Creates a temporary, zero-database P2P voice room with
//   a shareable short link. Perfect for scrimmages (practice
//   matches) against rival teams.
//
// HOW IT WORKS:
//   1. Generate a short random code (e.g. "xK3m9p")
//   2. Use Supabase Realtime Broadcast channel as signaling
//      (ephemeral — nothing written to DB)
//   3. Share link: ghostlink.gg/scrim/xK3m9p
//   4. Room auto-expires after 4 hours (TTL in-memory)
//   5. Optional password protection
//
// ZERO DB COST:
//   Broadcast channels are ephemeral — no row inserts,
//   no storage consumed. True $0.
// ─────────────────────────────────────────────────────────

'use client';

import { useCallback, useRef } from 'react';
import { getSupabase } from '@/lib/supabase';
import { useAppStore } from '@/lib/store';
import type { ScrimRoom } from '@/types';

/** Generate a short alphanumeric code */
function generateCode(length = 6): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
  let code = '';
  const array = new Uint8Array(length);
  crypto.getRandomValues(array);
  for (let i = 0; i < length; i++) {
    code += chars[array[i] % chars.length];
  }
  return code;
}

/** 4 hours in milliseconds */
const SCRIM_TTL = 4 * 60 * 60 * 1000;

export function useScrimLink() {
  const setActiveScrimRoom = useAppStore((s) => s.setActiveScrimRoom);
  const setShowScrimModal = useAppStore((s) => s.setShowScrimModal);
  const activeScrimRoom = useAppStore((s) => s.activeScrimRoom);
  const expiryTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  // ── Create a new scrim room ──
  const createScrimRoom = useCallback(
    (options: { name: string; password?: string; maxParticipants?: number; creatorId: string }) => {
      const room: ScrimRoom = {
        code: generateCode(),
        name: options.name || 'Scrim Odası',
        created_by: options.creatorId,
        password: options.password || null,
        max_participants: options.maxParticipants || 10,
        created_at: Date.now(),
        ttl: SCRIM_TTL,
      };

      setActiveScrimRoom(room);
      setShowScrimModal(false);

      // Auto-expire
      expiryTimerRef.current = setTimeout(() => {
        setActiveScrimRoom(null);
      }, SCRIM_TTL);

      return room;
    },
    [setActiveScrimRoom, setShowScrimModal],
  );

  // ── Join existing scrim room by code ──
  const joinScrimRoom = useCallback(
    async (code: string, password?: string) => {
      // In a real app, we'd verify via broadcast presence.
      // For now, construct the room reference and connect.
      const room: ScrimRoom = {
        code,
        name: `Scrim #${code}`,
        created_by: '',
        password: password || null,
        max_participants: 10,
        created_at: Date.now(),
        ttl: SCRIM_TTL,
      };

      setActiveScrimRoom(room);
      return room;
    },
    [setActiveScrimRoom],
  );

  // ── Leave / destroy scrim room ──
  const leaveScrimRoom = useCallback(() => {
    if (expiryTimerRef.current) {
      clearTimeout(expiryTimerRef.current);
      expiryTimerRef.current = null;
    }
    setActiveScrimRoom(null);
  }, [setActiveScrimRoom]);

  // ── Get shareable link ──
  const getShareLink = useCallback(() => {
    if (!activeScrimRoom) return '';
    if (typeof window === 'undefined') return '';
    return `${window.location.origin}/scrim/${activeScrimRoom.code}`;
  }, [activeScrimRoom]);

  // ── Copy link to clipboard ──
  const copyShareLink = useCallback(async () => {
    const link = getShareLink();
    if (link) {
      await navigator.clipboard.writeText(link);
      return true;
    }
    return false;
  }, [getShareLink]);

  return {
    activeScrimRoom,
    createScrimRoom,
    joinScrimRoom,
    leaveScrimRoom,
    getShareLink,
    copyShareLink,
  };
}

