// ─────────────────────────────────────────────────────────
// GhostLink — Channel Sidebar v2 (Categories + Full Interactive)
// ─────────────────────────────────────────────────────────

'use client';

import { useEffect, memo, useCallback } from 'react';
import { clsx } from 'clsx';
import { getSupabase } from '@/lib/supabase';
import { useAppStore } from '@/lib/store';
import { useAuth } from '@/hooks/useAuth';
import { useGameBoost } from '@/hooks/useGameBoost';
import { useThemeStore } from '@/store/useThemeStore';
import type { Channel, ChannelCategory, UserStatus } from '@/types';

// ─── Status dot color ───────────────────────────────────

const STATUS_COLORS: Record<UserStatus, string> = {
  'online': 'bg-gl-online',
  'in-game': 'bg-purple-500',
  'idle': 'bg-gl-idle',
  'dnd': 'bg-gl-dnd',
  'offline': 'bg-gray-500',
};

const STATUS_LABELS: Record<UserStatus, string> = {
  'online': 'Çevrimiçi',
  'in-game': 'Oyunda',
  'idle': 'Boşta',
  'dnd': 'Rahatsız Etmeyin',
  'offline': 'Çevrimdışı',
};

// ─── Channel Item (memoized) ────────────────────────────

function ChannelItem({
  channel,
  isActive,
}: {
  channel: Channel;
  isActive: boolean;
}) {
  const setActiveChannel = useAppStore((s) => s.setActiveChannel);
  const setActiveVoiceChannel = useAppStore((s) => s.setActiveVoiceChannel);

  const handleClick = useCallback(() => {
    if (channel.type === 'text') {
      setActiveChannel(channel.id);
    } else {
      setActiveVoiceChannel(channel.id);
    }
  }, [channel.id, channel.type, setActiveChannel, setActiveVoiceChannel]);

  return (
    <button
      onClick={handleClick}
      className={clsx(
        'group flex w-full items-center gap-1.5 rounded-md px-2 py-1.5 text-left text-sm transition-colors',
        isActive
          ? 'bg-gl-bg-active text-gl-text-primary'
          : 'text-gl-text-secondary hover:bg-gl-bg-hover hover:text-gl-text-primary',
      )}
    >
      {channel.type === 'text' ? (
        <span className="flex-shrink-0 text-lg leading-none opacity-50">#</span>
      ) : (
        <svg className="h-5 w-5 flex-shrink-0 opacity-50" fill="currentColor" viewBox="0 0 24 24">
          <path d="M12 3a9 9 0 0 0-9 9v7c0 1.1.9 2 2 2h4v-8H5v-1c0-3.87 3.13-7 7-7s7 3.13 7 7v1h-4v8h4c1.1 0 2-.9 2-2v-7a9 9 0 0 0-9-9z" />
        </svg>
      )}
      <span className="truncate">{channel.name}</span>

      {/* Add user to voice channel icon */}
      {channel.type === 'voice' && (
        <svg
          className="ml-auto h-4 w-4 flex-shrink-0 opacity-0 group-hover:opacity-60"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
          strokeWidth={2}
        >
          <path strokeLinecap="round" strokeLinejoin="round" d="M18 7.5v3m0 0v3m0-3h3m-3 0h-3m-2.25-4.125a3.375 3.375 0 1 1-6.75 0 3.375 3.375 0 0 1 6.75 0ZM3 19.235v-.11a6.375 6.375 0 0 1 12.75 0v.109A12.318 12.318 0 0 1 9.374 21c-2.331 0-4.512-.645-6.374-1.766Z" />
        </svg>
      )}
    </button>
  );
}

const MemoizedChannelItem = memo(ChannelItem);

// ─── Category Group ─────────────────────────────────────

function CategoryGroup({
  category,
  channels,
  activeChannelId,
  activeVoiceChannelId,
}: {
  category: ChannelCategory | null;
  channels: Channel[];
  activeChannelId: string | null;
  activeVoiceChannelId: string | null;
}) {
  const collapsedCategories = useAppStore((s) => s.collapsedCategories);
  const toggleCategory = useAppStore((s) => s.toggleCategory);

  const isCollapsed = category ? collapsedCategories.has(category.id) : false;

  const textChannels = channels.filter((c) => c.type === 'text');
  const voiceChannels = channels.filter((c) => c.type === 'voice');

  return (
    <div className="mb-3">
      {/* Category header */}
      {category && (
        <button
          onClick={() => toggleCategory(category.id)}
          className="group mb-0.5 flex w-full items-center gap-0.5 px-0.5 text-xxs font-bold uppercase tracking-wider text-gl-text-muted hover:text-gl-text-secondary"
        >
          <svg
            className={clsx(
              'h-3 w-3 transition-transform',
              isCollapsed ? '-rotate-90' : 'rotate-0',
            )}
            fill="currentColor"
            viewBox="0 0 20 20"
          >
            <path fillRule="evenodd" d="M5.23 7.21a.75.75 0 011.06.02L10 11.168l3.71-3.938a.75.75 0 111.08 1.04l-4.25 4.5a.75.75 0 01-1.08 0l-4.25-4.5a.75.75 0 01.02-1.06z" />
          </svg>
          {category.name}
        </button>
      )}

      {/* Channels */}
      {!isCollapsed && (
        <div className="space-y-0.5">
          {textChannels.map((ch) => (
            <MemoizedChannelItem
              key={ch.id}
              channel={ch}
              isActive={ch.id === activeChannelId}
            />
          ))}
          {voiceChannels.map((ch) => (
            <MemoizedChannelItem
              key={ch.id}
              channel={ch}
              isActive={ch.id === activeVoiceChannelId}
            />
          ))}
        </div>
      )}
    </div>
  );
}

// ─── Main Sidebar ───────────────────────────────────────

export function ChannelSidebar() {
  const activeServerId = useAppStore((s) => s.activeServerId);
  const activeChannelId = useAppStore((s) => s.activeChannelId);
  const activeVoiceChannelId = useAppStore((s) => s.activeVoiceChannelId);
  const channels = useAppStore((s) => s.channels);
  const categories = useAppStore((s) => s.categories);
  const setChannels = useAppStore((s) => s.setChannels);
  const setCategories = useAppStore((s) => s.setCategories);
  const servers = useAppStore((s) => s.servers);
  const ecoMode = useAppStore((s) => s.ecoMode);

  const { user, profile, signOut } = useAuth();
  const { isEnabled: ecoEnabled, toggleEcoEnabled } = useGameBoost();
  const setShowThemeModal = useThemeStore((s) => s.setShowThemeModal);

  const serverName = servers.find((s) => s.id === activeServerId)?.name ?? 'GhostLink';

  // Fetch channels + categories when server changes
  useEffect(() => {
    if (!activeServerId) return;
    const supabase = getSupabase();

    (async () => {
      const [channelRes, categoryRes] = await Promise.all([
        supabase
          .from('channels')
          .select('*')
          .eq('server_id', activeServerId)
          .order('position', { ascending: true }),
        supabase
          .from('channel_categories')
          .select('*')
          .eq('server_id', activeServerId)
          .order('position', { ascending: true }),
      ]);

      if (channelRes.data) setChannels(channelRes.data as Channel[]);
      if (categoryRes.data) setCategories(categoryRes.data as ChannelCategory[]);
    })();
  }, [activeServerId, setChannels, setCategories]);

  // Group channels by category
  const uncategorized = channels.filter((c) => !c.category_id);
  const grouped = categories.map((cat) => ({
    category: cat,
    channels: channels.filter((c) => c.category_id === cat.id),
  }));

  const currentStatus = (profile?.status ?? 'online') as UserStatus;

  return (
    <aside className="flex w-60 flex-shrink-0 flex-col bg-gl-bg-dark">
      {/* ── Server header ── */}
      <div className="flex h-12 items-center justify-between border-b border-gl-border px-4 shadow-sm">
        <h2 className="truncate text-sm font-bold text-gl-text-primary">
          {serverName}
        </h2>
        {/* Eco mode badge */}
        {ecoMode.isActive && (
          <span className="flex items-center gap-1 rounded-full bg-gl-online/20 px-2 py-0.5 text-xxs font-bold text-gl-online">
            <span className="h-1.5 w-1.5 rounded-full bg-gl-online" />
            ECO
          </span>
        )}
      </div>

      {/* ── Channel list ── */}
      <nav className="flex-1 overflow-y-auto px-2 py-3 scrollbar-none">
        {/* Uncategorized channels */}
        {uncategorized.length > 0 && (
          <CategoryGroup
            category={null}
            channels={uncategorized}
            activeChannelId={activeChannelId}
            activeVoiceChannelId={activeVoiceChannelId}
          />
        )}

        {/* Categorized channels */}
        {grouped.map(({ category, channels: catChannels }) => (
          <CategoryGroup
            key={category.id}
            category={category}
            channels={catChannels}
            activeChannelId={activeChannelId}
            activeVoiceChannelId={activeVoiceChannelId}
          />
        ))}

        {/* Fallback: show flat list if no categories exist */}
        {categories.length === 0 && uncategorized.length === 0 && channels.length > 0 && (
          <>
            <h3 className="mb-1 px-1 text-xxs font-bold uppercase tracking-wider text-gl-text-muted">
              Metin Kanalları
            </h3>
            {channels.filter((c) => c.type === 'text').map((ch) => (
              <MemoizedChannelItem key={ch.id} channel={ch} isActive={ch.id === activeChannelId} />
            ))}
            <h3 className="mb-1 mt-4 px-1 text-xxs font-bold uppercase tracking-wider text-gl-text-muted">
              Ses Kanalları
            </h3>
            {channels.filter((c) => c.type === 'voice').map((ch) => (
              <MemoizedChannelItem key={ch.id} channel={ch} isActive={ch.id === activeVoiceChannelId} />
            ))}
          </>
        )}
      </nav>

      {/* ── User panel (bottom) ── */}
      <div className="flex items-center gap-2 border-t border-gl-border bg-gl-bg-darkest px-2 py-2">
        {/* Avatar + status */}
        <div className="relative h-8 w-8 flex-shrink-0">
          <div className="h-8 w-8 rounded-full bg-gl-bg-mid">
            {profile?.avatar_url && (
              <img src={profile.avatar_url} alt="" className="h-full w-full rounded-full object-cover" />
            )}
          </div>
          <span className={clsx(
            'absolute -bottom-0.5 -right-0.5 h-3.5 w-3.5 rounded-full border-[2.5px] border-gl-bg-darkest',
            STATUS_COLORS[currentStatus],
          )} />
        </div>

        {/* Username + status label */}
        <div className="min-w-0 flex-1">
          <p className="truncate text-xs font-semibold text-gl-text-primary">
            {profile?.username ?? 'Oyuncu'}
          </p>
          <p className="truncate text-xxs text-gl-text-muted">
            {STATUS_LABELS[currentStatus]}
          </p>
        </div>

        {/* Action buttons */}
        <div className="flex items-center gap-0.5">
          {/* Eco Mode toggle */}
          <button
            onClick={toggleEcoEnabled}
            className={clsx(
              'rounded p-1 transition-colors',
              ecoEnabled
                ? 'text-gl-online hover:bg-gl-online/20'
                : 'text-gl-text-muted hover:text-gl-text-secondary',
            )}
            title={ecoEnabled ? 'Eco Mode: AÇIK' : 'Eco Mode: KAPALI'}
          >
            <svg className="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="m3.75 13.5 10.5-11.25L12 10.5h8.25L9.75 21.75 12 13.5H3.75Z" />
            </svg>
          </button>

          {/* Settings / Ghost-Engine Theme */}
          <button
            onClick={() => setShowThemeModal(true)}
            className="rounded p-1 text-gl-text-secondary transition-colors hover:text-gl-accent hover:bg-gl-bg-hover"
            title="Ghost-Engine Tema & HUD Ayarları"
          >
            <svg className="h-4 w-4" fill="currentColor" viewBox="0 0 24 24">
              <path d="M19.14 12.94c.04-.3.06-.61.06-.94 0-.32-.02-.64-.07-.94l2.03-1.58a.49.49 0 0 0 .12-.61l-1.92-3.32a.488.488 0 0 0-.59-.22l-2.39.96c-.5-.38-1.03-.7-1.62-.94l-.36-2.54a.484.484 0 0 0-.48-.41h-3.84c-.24 0-.43.17-.47.41l-.36 2.54c-.59.24-1.13.57-1.62.94l-2.39-.96c-.22-.08-.47 0-.59.22L2.74 8.87c-.12.21-.08.47.12.61l2.03 1.58c-.05.3-.07.62-.07.94s.02.64.07.94l-2.03 1.58a.49.49 0 0 0-.12.61l1.92 3.32c.12.22.37.29.59.22l2.39-.96c.5.38 1.03.7 1.62.94l.36 2.54c.05.24.24.41.48.41h3.84c.24 0 .44-.17.47-.41l.36-2.54c.59-.24 1.13-.56 1.62-.94l2.39.96c.22.08.47 0 .59-.22l1.92-3.32c.12-.22.07-.47-.12-.61l-2.01-1.58zM12 15.6A3.6 3.6 0 1 1 12 8.4a3.6 3.6 0 0 1 0 7.2z" />
            </svg>
          </button>

          {/* Sign out */}
          {user && (
            <button
              onClick={signOut}
              className="rounded p-1 text-gl-text-muted transition-colors hover:text-gl-dnd"
              title="Çıkış Yap"
            >
              <svg className="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={2}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M15.75 9V5.25A2.25 2.25 0 0 0 13.5 3h-6a2.25 2.25 0 0 0-2.25 2.25v13.5A2.25 2.25 0 0 0 7.5 21h6a2.25 2.25 0 0 0 2.25-2.25V15m3 0 3-3m0 0-3-3m3 3H9" />
              </svg>
            </button>
          )}
        </div>
      </div>
    </aside>
  );
}
