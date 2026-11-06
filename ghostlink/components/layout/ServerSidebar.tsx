// ─────────────────────────────────────────────────────────
// GhostLink — Server Sidebar v2 (Fully Interactive)
// ─────────────────────────────────────────────────────────

'use client';

import { memo, useState, useCallback } from 'react';
import { clsx } from 'clsx';
import { useAppStore } from '@/lib/store';
import type { Server } from '@/types';

// ─── Server Icon (memoized — zero re-render if props same) ──

function ServerIcon({ server, isActive }: { server: Server; isActive: boolean }) {
  const setActiveServer = useAppStore((s) => s.setActiveServer);
  const [showTooltip, setShowTooltip] = useState(false);

  const initials = server.name
    .split(' ')
    .map((w) => w[0])
    .join('')
    .slice(0, 2)
    .toUpperCase();

  return (
    <div className="relative">
      <button
        onClick={() => setActiveServer(server.id)}
        onMouseEnter={() => setShowTooltip(true)}
        onMouseLeave={() => setShowTooltip(false)}
        className={clsx(
          'group relative flex h-12 w-12 items-center justify-center transition-all duration-200',
          isActive
            ? 'rounded-[16px] bg-gl-accent text-white'
            : 'rounded-[24px] bg-gl-bg-panel text-gl-text-secondary hover:rounded-[16px] hover:bg-gl-accent hover:text-white',
        )}
      >
        {server.icon_url ? (
          <img
            src={server.icon_url}
            alt={server.name}
            className="h-full w-full rounded-[inherit] object-cover"
            loading="lazy"
          />
        ) : (
          <span className="text-sm font-semibold select-none">{initials}</span>
        )}

        {/* Active pill indicator */}
        <span
          className={clsx(
            'absolute -left-[4px] top-1/2 w-1 -translate-y-1/2 rounded-r-full bg-white transition-all duration-200',
            isActive ? 'h-10' : 'h-0 group-hover:h-5',
          )}
        />
      </button>

      {/* Tooltip */}
      {showTooltip && (
        <div className="absolute left-16 top-1/2 z-50 -translate-y-1/2 whitespace-nowrap rounded-md bg-gl-bg-darkest px-3 py-1.5 text-sm font-semibold text-gl-text-primary shadow-xl border border-gl-border">
          {server.name}
          <div className="absolute -left-1 top-1/2 h-2 w-2 -translate-y-1/2 rotate-45 bg-gl-bg-darkest border-l border-b border-gl-border" />
        </div>
      )}
    </div>
  );
}

const MemoizedServerIcon = memo(ServerIcon);

// ─── Main Sidebar ───────────────────────────────────────

export function ServerSidebar() {
  const servers = useAppStore((s) => s.servers);
  const activeServerId = useAppStore((s) => s.activeServerId);
  const setShowScrimModal = useAppStore((s) => s.setShowScrimModal);

  const handleAddServer = useCallback(() => {
    // TODO: Add server creation modal
    console.log('[GhostLink] Server creation coming soon');
  }, []);

  return (
    <aside className="flex w-[72px] flex-shrink-0 flex-col items-center gap-2 overflow-y-auto bg-gl-bg-darkest py-3 scrollbar-none">
      {/* Home / DMs */}
      <button
        className={clsx(
          'flex h-12 w-12 items-center justify-center rounded-[24px] transition-all duration-200',
          !activeServerId
            ? 'rounded-[16px] bg-gl-accent text-white'
            : 'bg-gl-bg-panel text-gl-text-primary hover:rounded-[16px] hover:bg-gl-accent',
        )}
        title="Ana Sayfa"
      >
        <svg className="h-7 w-7" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1.5}>
          <path strokeLinecap="round" strokeLinejoin="round" d="M8.625 12a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0Zm0 0H8.25m4.125 0a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0Zm0 0H12m4.125 0a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0Zm0 0h-.375M21 12c0 4.556-4.03 8.25-9 8.25a9.764 9.764 0 0 1-2.555-.337A5.972 5.972 0 0 1 5.41 20.97a5.969 5.969 0 0 1-.474-.065 4.48 4.48 0 0 0 .978-2.025c.09-.457-.133-.901-.467-1.226C3.93 16.178 3 14.189 3 12c0-4.556 4.03-8.25 9-8.25s9 3.694 9 8.25Z" />
        </svg>
      </button>

      <div className="mx-auto h-px w-8 bg-gl-border" />

      {/* Server list */}
      {servers.map((server) => (
        <MemoizedServerIcon
          key={server.id}
          server={server}
          isActive={server.id === activeServerId}
        />
      ))}

      <div className="mx-auto h-px w-8 bg-gl-border" />

      {/* Add server */}
      <button
        onClick={handleAddServer}
        className="flex h-12 w-12 items-center justify-center rounded-[24px] bg-gl-bg-panel text-gl-online transition-all duration-200 hover:rounded-[16px] hover:bg-gl-online hover:text-white"
        title="Sunucu Ekle"
      >
        <svg className="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={2}>
          <path strokeLinecap="round" strokeLinejoin="round" d="M12 4v16m8-8H4" />
        </svg>
      </button>

      {/* ⚡ Instant Scrim — Innovation #2 */}
      <button
        onClick={() => setShowScrimModal(true)}
        className="flex h-12 w-12 items-center justify-center rounded-[24px] bg-gl-bg-panel text-gl-idle transition-all duration-200 hover:rounded-[16px] hover:bg-gl-idle hover:text-white"
        title="Instant Scrim Link"
      >
        <svg className="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={2}>
          <path strokeLinecap="round" strokeLinejoin="round" d="m3.75 13.5 10.5-11.25L12 10.5h8.25L9.75 21.75 12 13.5H3.75Z" />
        </svg>
      </button>
    </aside>
  );
}
