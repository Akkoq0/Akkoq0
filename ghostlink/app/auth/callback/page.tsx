// ─────────────────────────────────────────────────────────
// GhostLink — Auth Callback (Supabase OAuth redirect handler)
// ─────────────────────────────────────────────────────────

'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { getSupabase } from '@/lib/supabase';

export default function AuthCallbackPage() {
  const router = useRouter();

  useEffect(() => {
    const supabase = getSupabase();

    supabase.auth.onAuthStateChange((event) => {
      if (event === 'SIGNED_IN') {
        router.replace('/');
      }
    });
  }, [router]);

  return (
    <div className="flex h-screen w-screen items-center justify-center bg-gl-bg-darkest">
      <div className="text-center">
        <div className="mb-4 text-4xl">👻</div>
        <p className="text-lg text-gl-text-primary">Giriş yapılıyor...</p>
        <div className="mt-4 h-1 w-48 overflow-hidden rounded-full bg-gl-bg-hover">
          <div className="h-full w-1/3 animate-pulse rounded-full bg-gl-accent" />
        </div>
      </div>
    </div>
  );
}

