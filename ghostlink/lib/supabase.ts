// ─────────────────────────────────────────────────────────
// Meva HUD — Hardened Supabase Client & ICE Validator
// ─────────────────────────────────────────────────────────

import { createBrowserClient } from '@supabase/ssr';

const FALLBACK_SUPABASE_URL = 'https://placeholder.supabase.co';
const FALLBACK_SUPABASE_ANON_KEY =
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.placeholder.signature';

const DEFAULT_ICE_SERVERS: RTCIceServer[] = [
  { urls: 'stun:stun.l.google.com:19302' },
  { urls: 'stun:stun1.l.google.com:19302' },
];

const SAFE_ICE_SCHEME_RE = /^(stuns?|turns?):[A-Za-z0-9._:?=&-]+$/i;

let client: ReturnType<typeof createBrowserClient> | null = null;

export function isSupabaseConfigured(): boolean {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL?.trim();
  const key = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY?.trim();
  return Boolean(
    url &&
      key &&
      url.startsWith('https://') &&
      !url.includes('placeholder.supabase.co') &&
      !url.includes('your-project-id'),
  );
}

export function getSupabase() {
  if (client) return client;

  const url =
    process.env.NEXT_PUBLIC_SUPABASE_URL?.trim() || FALLBACK_SUPABASE_URL;
  const key =
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY?.trim() ||
    FALLBACK_SUPABASE_ANON_KEY;

  client = createBrowserClient(url, key);
  return client;
}

export function getIceServers(): RTCIceServer[] {
  const raw = process.env.NEXT_PUBLIC_ICE_SERVERS?.trim();
  if (!raw) return DEFAULT_ICE_SERVERS;

  try {
    const parsed: unknown = JSON.parse(raw);
    if (!Array.isArray(parsed) || parsed.length === 0) {
      return DEFAULT_ICE_SERVERS;
    }

    const sanitized: RTCIceServer[] = [];
    for (const item of parsed) {
      if (!item || typeof item !== 'object') continue;
      const candidate = item as Record<string, unknown>;
      const rawUrls = candidate.urls;
      const urlList = Array.isArray(rawUrls)
        ? rawUrls.filter(
            (u): u is string => typeof u === 'string' && SAFE_ICE_SCHEME_RE.test(u),
          )
        : typeof rawUrls === 'string' && SAFE_ICE_SCHEME_RE.test(rawUrls)
          ? [rawUrls]
          : [];

      if (urlList.length === 0) continue;

      const entry: RTCIceServer = { urls: urlList };
      if (typeof candidate.username === 'string') {
        entry.username = candidate.username.slice(0, 128);
      }
      if (typeof candidate.credential === 'string') {
        entry.credential = candidate.credential.slice(0, 256);
      }
      sanitized.push(entry);
    }

    return sanitized.length > 0 ? sanitized : DEFAULT_ICE_SERVERS;
  } catch {
    return DEFAULT_ICE_SERVERS;
  }
}
