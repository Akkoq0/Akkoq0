// ─────────────────────────────────────────────────────────
// Meva HUD — Hardened OAuth Callback Handler
// ─────────────────────────────────────────────────────────

'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { getSupabase, isSupabaseConfigured } from '@/lib/supabase';
import { IconMevaMark } from '@/components/ui/MevaIcons';

export default function AuthCallbackPage() {
  const router = useRouter();

  useEffect(() => {
    if (!isSupabaseConfigured()) {
      router.replace('/');
      return;
    }

    const supabase = getSupabase();

    // Check if PKCE exchange already resolved session before listener mounted
    supabase.auth
      .getSession()
      .then(({ data: { session } }) => {
        if (session) router.replace('/');
      })
      .catch(() => {
        router.replace('/');
      });

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((event) => {
      if (event === 'SIGNED_IN' || event === 'TOKEN_REFRESHED') {
        router.replace('/');
      }
    });

    // Fallback safety redirect so user is never stranded
    const fallbackTimer = setTimeout(() => {
      router.replace('/');
    }, 5000);

    return () => {
      clearTimeout(fallbackTimer);
      subscription.unsubscribe();
    };
  }, [router]);

  return (
    <div className="flex h-[100dvh] w-screen items-center justify-center ambient-shell font-sans">
      <div className="exec-modal rounded-2xl px-8 py-6 text-center space-y-3.5">
        <div className="mx-auto w-11 h-11 rounded-xl bg-gradient-to-br from-[#8F1622] to-[#1A080C] border border-[#B51D2C]/45 flex items-center justify-center text-[#F4EFF0]">
          <IconMevaMark size={20} />
        </div>
        <p className="text-sm font-bold text-[#F4EFF0]">
          Komuta Yetkisi Doğrulanıyor...
        </p>
        <div className="mx-auto h-1.5 w-48 overflow-hidden rounded-full bg-[#180B10]">
          <div className="h-full w-1/2 animate-pulse rounded-full bg-gradient-to-r from-[#591019] to-[#C82333]" />
        </div>
      </div>
    </div>
  );
}
