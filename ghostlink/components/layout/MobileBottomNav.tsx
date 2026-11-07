'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Mobile Executive Command Dock (Spacious & Ergonomic)
// ─────────────────────────────────────────────────────────

import { memo, type ComponentType } from 'react';
import { useAppStore } from '@/lib/store';
import {
  IconLayers,
  IconMessage,
  IconVoiceWave,
  IconShield,
  IconRadar,
} from '@/components/ui/MevaIcons';

interface DockTabProps {
  label: string;
  Icon: ComponentType<{ size?: number; className?: string }>;
  active: boolean;
  onClick: () => void;
  live?: boolean;
}

function DockTab({
  label,
  Icon,
  active,
  onClick,
  live = false,
}: DockTabProps) {
  return (
    <button
      type="button"
      onClick={onClick}
      aria-label={label}
      aria-current={active ? 'page' : undefined}
      className={`relative flex-1 flex flex-col items-center justify-center gap-1 rounded-xl mx-0.5 my-1.5 min-h-[46px] transition-all duration-150 active:scale-[0.96] ${
        active
          ? 'text-[#F4EFF0] bg-[linear-gradient(165deg,rgba(138,20,32,0.28)_0%,rgba(12,9,10,0.86)_100%)] border border-[#961826]/45'
          : 'text-[#827376] hover:text-[#F4EFF0] border border-transparent hover:bg-[#160B0F]/60'
      }`}
    >
      {active && (
        <span
          aria-hidden
          className="absolute inset-x-3.5 -top-[1px] h-[2px] rounded-full bg-[#C82333]"
        />
      )}
      <Icon
        size={18}
        className={active ? 'text-[#D63344]' : 'text-[#827376]'}
      />
      <span className="text-[10.5px] font-bold tracking-tight">{label}</span>

      {live && (
        <span
          aria-hidden
          className="absolute top-1.5 right-[calc(50%-15px)] w-2 h-2 rounded-full bg-[#C82333] ring-2 ring-[#080607]"
        />
      )}
    </button>
  );
}

export const MobileBottomNav = memo(function MobileBottomNav() {
  const isMobileSidebarOpen = useAppStore((s) => s.isMobileSidebarOpen);
  const isMobileRadarOpen = useAppStore((s) => s.isMobileRadarOpen);
  const mobileTab = useAppStore((s) => s.mobileTab);
  const inVoice = useAppStore((s) => s.activeVoiceChannelId !== null);

  const setIsMobileSidebarOpen = useAppStore((s) => s.setIsMobileSidebarOpen);
  const setIsMobileRadarOpen = useAppStore((s) => s.setIsMobileRadarOpen);
  const setShowFriendsModal = useAppStore((s) => s.setShowFriendsModal);
  const setShowScrimModal = useAppStore((s) => s.setShowScrimModal);
  const setMobileTab = useAppStore((s) => s.setMobileTab);

  const closeOverlays = () => {
    setIsMobileSidebarOpen(false);
    setIsMobileRadarOpen(false);
    setShowFriendsModal(false);
    setShowScrimModal(false);
  };

  const noDrawerOpen = !isMobileSidebarOpen && !isMobileRadarOpen;

  return (
    <nav
      aria-label="Mobil Komuta Barı"
      className="lg:hidden relative z-30 flex-shrink-0 select-none bg-[linear-gradient(180deg,rgba(18,9,12,0.88)_0%,rgba(7,6,7,0.94)_100%)] backdrop-blur-xl font-sans px-1.5"
      style={{ paddingBottom: 'env(safe-area-inset-bottom)' }}
    >
      <div className="horizon-divider h-px w-full" aria-hidden />
      <div className="h-[60px] flex items-stretch">
        <DockTab
          label="Kanallar"
          Icon={IconLayers}
          active={isMobileSidebarOpen}
          onClick={() => {
            const next = !isMobileSidebarOpen;
            closeOverlays();
            setIsMobileSidebarOpen(next);
          }}
        />
        <DockTab
          label="İletişim"
          Icon={IconMessage}
          active={noDrawerOpen && mobileTab === 'chat'}
          onClick={() => setMobileTab('chat')}
        />
        <DockTab
          label="Ses Matrisi"
          Icon={IconVoiceWave}
          active={noDrawerOpen && mobileTab === 'voice'}
          onClick={() => setMobileTab('voice')}
          live={inVoice}
        />
        <DockTab
          label="Ağ & Scrim"
          Icon={IconShield}
          active={noDrawerOpen && mobileTab === 'mesh'}
          onClick={() => setMobileTab('mesh')}
        />
        <DockTab
          label="Kadro"
          Icon={IconRadar}
          active={isMobileRadarOpen}
          onClick={() => {
            const next = !isMobileRadarOpen;
            closeOverlays();
            setIsMobileRadarOpen(next);
          }}
        />
      </div>
    </nav>
  );
});
