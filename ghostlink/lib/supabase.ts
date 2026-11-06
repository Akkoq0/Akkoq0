// ─────────────────────────────────────────────────────────
// GhostLink — Supabase Client (Browser)
// ─────────────────────────────────────────────────────────
// Single-instance pattern — no re-creates on each render.

import { createBrowserClient } from '@supabase/ssr';

let client: ReturnType<typeof createBrowserClient> | null = null;

export function getSupabase() {
  if (client) return client;

  client = createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
  );

  return client;
}

// ─── ICE Server config (free STUN) ─────────────────────

export function getIceServers(): RTCIceServer[] {
  try {
    return JSON.parse(process.env.NEXT_PUBLIC_ICE_SERVERS ?? '[]');
  } catch {
    return [
      { urls: 'stun:stun.l.google.com:19302' },
      { urls: 'stun:stun1.l.google.com:19302' },
    ];
  }
}

