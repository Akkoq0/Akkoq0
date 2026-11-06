'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Mobile Industrial Command Dock
// ─────────────────────────────────────────────────────────

import { memo, type ComponentType } from 'react';
import { useAppStore } from '@/lib/store';
import {
  IconLayers,
  IconMessage,
  IconUsers,
  IconRadar,
  IconBolt,
} from '@/components/ui/MevaIcons';

interface DockTabProps {
  label: string;
  Icon: ComponentType<{ size?: number; className?: string }>;
  active: boolean;
  onClick: () => void;
  indicator?: 'badge' | 'live' | null;
  badge?: number;
}

function DockTab({
  label,
  Icon,
  active,
  onClick,
  indicator = null,
  badge = 0,
}: DockTabProps) {
  return (
    <button
      onClick={onClick}
      aria-label={label}
      aria-current={active ? 'page' : undefined}
      className={`relative flex-1 flex flex-col items-center justify-center gap-1 min-h-[48px] transition-colors ${
        active
          ? 'text-gl-text-bright bg-[#0C0E12]'
          : 'text-gl-text-muted hover:text-gl-text-normal'
      }`}
    >
      {active && (
        <span
          aria-hidden
          className="absolute inset-x-3 top-0 h-[2px] bg-gl-accent"
        />
      )}
      <Icon
        size={18}
        className={active ? 'text-gl-accent' : 'text-gl-text-muted'}
      />
      <span className="font-mono text-[9px] font-bold tracking-[0.16em]">
        {label}
      </span>

      {indicator === 'badge' && badge > 0 && (
        <span className="absolute top-1.5 right-[calc(50%-18px)] min-w-[14px] h-[14px] px-1 rounded-sm bg-gl-accent text-white text-[9px] font-mono font-bold flex items-center justify-center">
          {badge}
        </span>
      )}
      {indicator === 'live' && (
        <span className="absolute top-2 right-[calc(50%-14px)] w-1.5 h-1.5 rounded-[1px] bg-[#F59E0B]" />
      )}
    </button>
  );
}

export const MobileBottomNav = memo(function MobileBottomNav() {
  const isMobileSidebarOpen = useAppStore((s) => s.isMobileSidebarOpen);
  const isMobileRadarOpen = useAppStore((s) => s.isMobileRadarOpen);
  const showFriendsModal = useAppStore((s) => s.showFriendsModal);
  const showScrimModal = useAppStore((s) => s.showScrimModal);
  const inVoice = useAppStore((s) => s.activeVoiceChannelId !== null);
  const pendingCount = useAppStore(
    (s) => s.friends.reduce((n, f) => n + (f.status === 'pending' ? 1 : 0), 0),
  );

  const setIsMobileSidebarOpen = useAppStore((s) => s.setIsMobileSidebarOpen);
  const setIsMobileRadarOpen = useAppStore((s) => s.setIsMobileRadarOpen);
  const setShowFriendsModal = useAppStore((s) => s.setShowFriendsModal);
  const setShowScrimModal = useAppStore((s) => s.setShowScrimModal);

  const closeAll = () => {
    setIsMobileSidebarOpen(false);
    setIsMobileRadarOpen(false);
    setShowFriendsModal(false);
    setShowScrimModal(false);
  };

  const isChatFocused =
    !isMobileSidebarOpen &&
    !isMobileRadarOpen &&
    !showFriendsModal &&
    !showScrimModal;

  return (
    <nav
      aria-label="Mobil Komuta Barı"
      className="md:hidden relative z-30 flex-shrink-0 select-none bg-[#050608] border-t border-white/[0.06]"
      style={{ paddingBottom: 'env(safe-area-inset-bottom)' }}
    >
      <div className="h-14 flex items-stretch divide-x divide-white/[0.04]">
        <DockTab
          label="KANAL"
          Icon={IconLayers}
          active={isMobileSidebarOpen}
          onClick={() => {
            const next = !isMobileSidebarOpen;
            closeAll();
            setIsMobileSidebarOpen(next);
          }}
        />
        <DockTab
          label="AKIŞ"
          Icon={IconMessage}
          active={isChatFocused}
          onClick={closeAll}
        />
        <DockTab
          label="SCRIM"
          Icon={IconBolt}
          active={showScrimModal}
          onClick={() => {
            closeAll();
            setShowScrimModal(true);
          }}
        />
        <DockTab
          label="EKİP"
          Icon={IconUsers}
          active={showFriendsModal}
          indicator="badge"
          badge={pendingCount}
          onClick={() => {
            closeAll();
            setShowFriendsModal(true);
          }}
        />
        <DockTab
          label="KADRO"
          Icon={IconRadar}
          active={isMobileRadarOpen}
          indicator={inVoice ? 'live' : null}
          onClick={() => {
            const next = !isMobileRadarOpen;
            closeAll();
            setIsMobileRadarOpen(next);
          }}
        />
      </div>
    </nav>
  );
});
