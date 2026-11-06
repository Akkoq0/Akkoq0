// ─────────────────────────────────────────────────────────
// GhostLink — Auth Hook
// ─────────────────────────────────────────────────────────

'use client';

import { useEffect, useState } from 'react';
import { getSupabase } from '@/lib/supabase';
import type { User } from '@supabase/supabase-js';
import type { Profile } from '@/types';

export function useAuth() {
  const [user, setUser] = useState<User | null>(null);
  const [profile, setProfile] = useState<Profile | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const supabase = getSupabase();

    // Get initial session
    supabase.auth.getSession().then(({ data: { session } }) => {
      setUser(session?.user ?? null);
      if (session?.user) fetchProfile(session.user.id);
      setLoading(false);
    });

    // Listen for auth changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      (_event, session) => {
        setUser(session?.user ?? null);
        if (session?.user) fetchProfile(session.user.id);
        else setProfile(null);
      },
    );

    return () => subscription.unsubscribe();
  }, []);

  async function fetchProfile(userId: string) {
    const supabase = getSupabase();
    const { data } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .single();
    if (data) setProfile(data as Profile);
  }

  const signInWithDiscord = async () => {
    const supabase = getSupabase();
    await supabase.auth.signInWithOAuth({
      provider: 'discord',
      options: { redirectTo: `${window.location.origin}/auth/callback` },
    });
  };

  const signInWithEmail = async (email: string, password: string) => {
    const supabase = getSupabase();
    return supabase.auth.signInWithPassword({ email, password });
  };

  const signUp = async (email: string, password: string, username: string) => {
    const supabase = getSupabase();
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: { data: { username } },
    });
    return { data, error };
  };

  const signOut = async () => {
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

