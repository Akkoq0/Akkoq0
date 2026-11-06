// ─────────────────────────────────────────────────────────
// Meva HUD — Auth Hook (Unmount-Safe & Sanitized)
// ─────────────────────────────────────────────────────────

'use client';

import { useEffect, useState } from 'react';
import { getSupabase, isSupabaseConfigured } from '@/lib/supabase';
import type { User } from '@supabase/supabase-js';
import type { Profile } from '@/types';

export function useAuth() {
  const [user, setUser] = useState<User | null>(null);
  const [profile, setProfile] = useState<Profile | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!isSupabaseConfigured()) {
      setLoading(false);
      return;
    }

    let mounted = true;
    const supabase = getSupabase();

    async function fetchProfile(userId: string) {
      try {
        const { data } = await supabase
          .from('profiles')
          .select('*')
          .eq('id', userId)
          .single();
        if (mounted && data) setProfile(data as Profile);
      } catch {
        // Ignore profile lookup errors when offline
      }
    }

    supabase.auth
      .getSession()
      .then(({ data: { session } }) => {
        if (!mounted) return;
        setUser(session?.user ?? null);
        if (session?.user) void fetchProfile(session.user.id);
        setLoading(false);
      })
      .catch(() => {
        if (mounted) setLoading(false);
      });

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, session) => {
      if (!mounted) return;
      setUser(session?.user ?? null);
      if (session?.user) void fetchProfile(session.user.id);
      else setProfile(null);
    });

    return () => {
      mounted = false;
      subscription.unsubscribe();
    };
  }, []);

  const signInWithDiscord = async () => {
    if (!isSupabaseConfigured()) return;
    const supabase = getSupabase();
    await supabase.auth.signInWithOAuth({
      provider: 'discord',
      options: { redirectTo: `${window.location.origin}/auth/callback` },
    });
  };

  const signInWithEmail = async (email: string, password: string) => {
    const supabase = getSupabase();
    return supabase.auth.signInWithPassword({
      email: email.trim(),
      password,
    });
  };

  const signUp = async (email: string, password: string, username: string) => {
    const supabase = getSupabase();
    const cleanUsername = username
      .replace(/[\u0000-\u001F\u007F]/g, '')
      .trim()
      .slice(0, 32);
    const { data, error } = await supabase.auth.signUp({
      email: email.trim(),
      password,
      options: { data: { username: cleanUsername } },
    });
    return { data, error };
  };

  const signOut = async () => {
    if (!isSupabaseConfigured()) return;
    const supabase = getSupabase();
    await supabase.auth.signOut();
  };

  return {
    user,
    profile,
    loading,
    signInWithDiscord,
    signInWithEmail,
    signUp,
    signOut,
  };
}
