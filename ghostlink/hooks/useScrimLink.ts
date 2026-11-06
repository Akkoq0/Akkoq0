// ─────────────────────────────────────────────────────────
// Meva HUD — Ephemeral Scrim Link Hook (CSPRNG + Sanitized)
// ─────────────────────────────────────────────────────────

'use client';

import { useCallback, useEffect, useRef } from 'react';
import { useAppStore } from '@/lib/store';
import type { ScrimRoom } from '@/types';

const SCRIM_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
const SCRIM_TTL = 4 * 60 * 60 * 1000;

export function generateSecureScrimCode(length = 6): string {
  const array = new Uint8Array(length);
  if (typeof crypto !== 'undefined' && crypto.getRandomValues) {
    crypto.getRandomValues(array);
  } else {
    for (let i = 0; i < length; i++) {
      array[i] = Math.floor(Math.random() * 256);
    }
  }
  let code = '';
  for (let i = 0; i < length; i++) {
    code += SCRIM_ALPHABET[array[i] % SCRIM_ALPHABET.length];
  }
  return code;
}

export function sanitizeScrimCode(raw: string): string {
  return raw.replace(/[^A-Za-z0-9_-]/g, '').slice(0, 16);
}

export function useScrimLink() {
  const setActiveScrimRoom = useAppStore((s) => s.setActiveScrimRoom);
  const setShowScrimModal = useAppStore((s) => s.setShowScrimModal);
  const activeScrimRoom = useAppStore((s) => s.activeScrimRoom);
  const expiryTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const clearExpiryTimer = useCallback(() => {
    if (expiryTimerRef.current !== null) {
      clearTimeout(expiryTimerRef.current);
      expiryTimerRef.current = null;
    }
  }, []);

  useEffect(() => {
    return () => clearExpiryTimer();
  }, [clearExpiryTimer]);

  const createScrimRoom = useCallback(
    (options: {
      name: string;
      password?: string;
      maxParticipants?: number;
      creatorId: string;
    }) => {
      clearExpiryTimer();
      const safeName =
        options.name.replace(/[\u0000-\u001F\u007F]/g, '').trim().slice(0, 40) ||
        'Scrim Odası';

      const room: ScrimRoom = {
        code: generateSecureScrimCode(),
        name: safeName,
        created_by: options.creatorId,
        password: options.password || null,
        max_participants: Math.max(2, Math.min(20, options.maxParticipants || 10)),
        created_at: Date.now(),
        ttl: SCRIM_TTL,
      };

      setActiveScrimRoom(room);
      setShowScrimModal(false);

      expiryTimerRef.current = setTimeout(() => {
        setActiveScrimRoom(null);
      }, SCRIM_TTL);

      return room;
    },
    [setActiveScrimRoom, setShowScrimModal, clearExpiryTimer],
  );

  const joinScrimRoom = useCallback(
    async (code: string, password?: string) => {
      const safeCode = sanitizeScrimCode(code).toUpperCase();
      if (safeCode.length < 3) return null;

      const room: ScrimRoom = {
        code: safeCode,
        name: `Scrim #${safeCode}`,
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

  const leaveScrimRoom = useCallback(() => {
    clearExpiryTimer();
    setActiveScrimRoom(null);
  }, [setActiveScrimRoom, clearExpiryTimer]);

  const getShareLink = useCallback(() => {
    if (!activeScrimRoom || typeof window === 'undefined') return '';
    const safeCode = sanitizeScrimCode(activeScrimRoom.code);
    return `${window.location.origin}/scrim/${encodeURIComponent(safeCode)}`;
  }, [activeScrimRoom]);

  const copyShareLink = useCallback(async () => {
    const link = getShareLink();
    if (!link || typeof navigator === 'undefined' || !navigator.clipboard) {
      return false;
    }
    try {
      await navigator.clipboard.writeText(link);
      return true;
    } catch {
      return false;
    }
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
