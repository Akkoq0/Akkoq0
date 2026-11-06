// ─────────────────────────────────────────────────────────
// Meva HUD — Hardened Supabase Server Client (RSC / Handlers)
// ─────────────────────────────────────────────────────────

import { createServerClient, type CookieOptions } from '@supabase/ssr';
import { cookies } from 'next/headers';

const FALLBACK_SUPABASE_URL = 'https://placeholder.supabase.co';
const FALLBACK_SUPABASE_ANON_KEY =
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.placeholder.signature';

export function createSupabaseServer() {
  const cookieStore = cookies();
  const url =
    process.env.NEXT_PUBLIC_SUPABASE_URL?.trim() || FALLBACK_SUPABASE_URL;
  const key =
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY?.trim() ||
    FALLBACK_SUPABASE_ANON_KEY;

  return createServerClient(url, key, {
    cookies: {
      get(name: string) {
        return cookieStore.get(name)?.value;
      },
      set(name: string, value: string, options: CookieOptions) {
        try {
          cookieStore.set({ name, value, ...options });
        } catch {
          // Server Component — cookie write silently ignored
        }
      },
      remove(name: string, options: CookieOptions) {
        try {
          cookieStore.set({ name, value: '', ...options });
        } catch {
          // Server Component — cookie write silently ignored
        }
      },
    },
  });
}
