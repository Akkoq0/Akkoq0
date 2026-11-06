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
    <div className="flex h-[100dvh] w-screen items-center justify-center bg-[#06070A] font-sans">
      <div className="titanium-module rounded-sm px-8 py-6 text-center space-y-3">
        <div className="mx-auto w-10 h-10 rounded-sm bg-[#0C0E14] border border-white/[0.08] flex items-center justify-center text-[#EF4444]">
          <IconMevaMark size={20} />
        </div>
        <p className="text-sm font-bold text-gl-text-bright">
          Komuta Yetkisi Doğrulanıyor...
        </p>
        <div className="mx-auto h-1 w-48 overflow-hidden rounded-full bg-white/[0.08]">
          <div className="h-full w-1/2 animate-pulse rounded-full bg-[#EF4444]" />
        </div>
      </div>
    </div>
  );
}
