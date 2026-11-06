'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Top Industrial Command Bar (GhostNavbar)
// ─────────────────────────────────────────────────────────
// Tactical Brutalism: #050608 titanium deck, 1px hairline
// borders (border-white/[0.05]), sharp rounded-sm modules,
// and pinpoint Crimson/Amber active indicators.

import { memo, type ReactNode } from 'react';
import { useAppStore } from '@/lib/store';
import { useThemeStore } from '@/store/useThemeStore';
import { cleanLabel, serverCode } from '@/lib/format';
import { SignalBars } from '@/components/ui/HudPrimitives';
import {
  IconMevaMark,
  IconBolt,
  IconUsers,
  IconSliders,
  IconRadar,
  IconGauge,
} from '@/components/ui/MevaIcons';

interface CommandButtonProps {
  label: string;
  onClick: () => void;
  active?: boolean;
  className?: string;
  badge?: number;
  children: ReactNode;
}

function CommandButton({
  label,
  onClick,
  active = false,
  className = '',
  badge = 0,
  children,
}: CommandButtonProps) {
  return (
    <button
      onClick={onClick}
      aria-label={label}
      aria-pressed={active}
      title={label}
      className={`relative rounded-sm w-10 h-10 md:w-9 md:h-9 flex items-center justify-center border transition-colors active:scale-[0.98] ${
        active
          ? 'bg-[#12151C] text-gl-accent border-gl-accent/60'
          : 'bg-[#0C0E12] text-gl-text-normal hover:text-gl-text-bright border-white/[0.05] hover:border-white/[0.12]'
      } ${className}`}
    >
      {children}
      {badge > 0 && (
        <span className="absolute -top-1 -right-1 min-w-[15px] h-[15px] px-1 rounded-sm bg-gl-accent text-white text-[9px] font-mono font-bold flex items-center justify-center">
          {badge}
        </span>
      )}
    </button>
  );
}

export const GhostNavbar = memo(function GhostNavbar() {
  const servers = useAppStore((s) => s.servers);
  const activeServerId = useAppStore((s) => s.activeServerId);
  const activeServerName = useAppStore(
    (s) => s.servers.find((srv) => srv.id === s.activeServerId)?.name,
  );
  const activeChannelName = useAppStore(
    (s) => s.channels.find((c) => c.id === s.activeChannelId)?.name,
  );
  const activeDMName = useAppStore(
    (s) => s.friends.find((f) => f.friend_id === s.activeDMUserId)?.friend?.username,
  );
  const pendingCount = useAppStore(
    (s) => s.friends.reduce((n, f) => n + (f.status === 'pending' ? 1 : 0), 0),
  );
  const qualityScore = useAppStore((s) => s.netGuard.qualityScore);
  const ecoEnabled = useAppStore((s) => s.ecoMode.isEnabled);
  const isRadarOpen = useAppStore((s) => s.isRadarOpen);

  const setActiveServer = useAppStore((s) => s.setActiveServer);
  const toggleEcoEnabled = useAppStore((s) => s.toggleEcoEnabled);
  const setShowScrimModal = useAppStore((s) => s.setShowScrimModal);
  const setShowFriendsModal = useAppStore((s) => s.setShowFriendsModal);
  const toggleRadar = useAppStore((s) => s.toggleRadar);
  const setIsMobileSidebarOpen = useAppStore((s) => s.setIsMobileSidebarOpen);
  const setShowThemeModal = useThemeStore((s) => s.setShowThemeModal);

  const mobileTitle = activeDMName
    ? `@${activeDMName}`
    : activeChannelName
      ? `#${cleanLabel(activeChannelName)}`
      : 'KOMUTA';

  return (
    <header className="relative z-30 h-14 px-3.5 md:px-5 flex items-center justify-between gap-4 flex-shrink-0 select-none bg-[#050608] border-b border-white/[0.05]">
      {/* ── LEFT: Brand Monolith + Server Selector Modules ── */}
      <div className="flex items-center gap-3 min-w-0 flex-1">
        <button
          onClick={() => setIsMobileSidebarOpen(true)}
          aria-label="Kanal Dizinini Aç"
          className="rounded-sm w-9 h-9 flex items-center justify-center bg-[#0C0E12] border border-white/[0.08] text-gl-accent flex-shrink-0 md:pointer-events-none"
        >
          <IconMevaMark size={18} />
        </button>

        {/* Mobile Context Trigger */}
        <button
          onClick={() => setIsMobileSidebarOpen(true)}
          className="md:hidden flex flex-col items-start justify-center min-w-0 min-h-[44px]"
        >
          {activeServerName && (
            <span className="text-[10px] font-mono font-bold tracking-[0.2em] text-gl-text-muted uppercase">
              {serverCode(activeServerName)}
            </span>
          )}
          <span className="text-sm font-bold uppercase tracking-wider text-gl-text-bright truncate max-w-[46vw]">
            {mobileTitle}
          </span>
        </button>

        {/* Desktop Brand Plate */}
        <div className="hidden md:flex items-center gap-2.5 flex-shrink-0">
          <span className="font-sans font-extrabold text-sm tracking-wider text-gl-text-bright">
            MEVA <span className="text-[#F59E0B] font-semibold">HUD</span>
          </span>
          <span className="w-1.5 h-1.5 rounded-full bg-[#10B981]" />
        </div>

        <span aria-hidden className="hidden md:block w-px h-5 bg-white/[0.06]" />

        {/* Desktop Server Tabs (Crisp Sans-Serif Typography) */}
        <nav
          aria-label="Operasyon Sunucuları"
          className="hidden md:flex items-center gap-1.5 overflow-x-auto no-scrollbar"
        >
          {servers.map((server) => {
            const isActive = server.id === activeServerId;
            return (
              <button
                key={server.id}
                onClick={() => setActiveServer(server.id)}
                aria-current={isActive ? 'true' : undefined}
                title={server.name}
                className={`relative rounded-sm h-9 px-3.5 flex items-center gap-2 flex-shrink-0 font-sans text-xs font-semibold border transition-colors ${
                  isActive
                    ? 'bg-[#0C0E14] text-gl-text-bright border-white/[0.1]'
                    : 'bg-transparent text-gl-text-muted hover:text-gl-text-bright border-transparent hover:bg-[#0C0E14]/60'
                }`}
              >
                {isActive && (
                  <span
                    aria-hidden
                    className="absolute inset-x-0 top-0 h-[2px] bg-gl-accent"
                  />
                )}
                <span className={`font-mono text-[10px] font-bold ${isActive ? 'text-[#F59E0B]' : 'text-gl-text-muted'}`}>
                  {serverCode(server.name)}
                </span>
                <span className="text-xs font-semibold">
                  {server.name}
                </span>
              </button>
            );
          })}
        </nav>
      </div>

      {/* ── RIGHT: Telemetry Readout & Heavy-Duty Controls ── */}
      <div className="flex items-center gap-1.5 flex-shrink-0">
        <div className="rounded-sm h-9 px-2.5 bg-[#0C0E14] border border-white/[0.06] flex items-center gap-2 font-mono text-[11px] font-bold text-gl-text-bright">
          <SignalBars score={qualityScore} />
          <span className="hidden sm:inline tabular-nums text-[#10B981]">
            11<span className="text-gl-text-muted ml-0.5">ms</span>
          </span>
        </div>

        <button
          onClick={() => setShowScrimModal(true)}
          className="hidden md:flex rounded-sm h-9 px-3.5 items-center gap-2 bg-[#0C0E14] hover:bg-[#12151E] text-gl-text-bright border border-white/[0.08] hover:border-gl-accent/60 font-sans text-xs font-bold tracking-wide transition-colors active:scale-[0.98]"
        >
          <IconBolt size={14} className="text-gl-accent" />
          <span>Scrim Odası</span>
        </button>

        <CommandButton
          label="Game-Boost Güç Koruması"
          onClick={toggleEcoEnabled}
          active={ecoEnabled}
        >
          <IconGauge size={17} />
        </CommandButton>

        <CommandButton
          label="Operatör Ağı ve 1v1"
          onClick={() => setShowFriendsModal(true)}
          badge={pendingCount}
          className="hidden md:flex"
        >
          <IconUsers size={16} />
        </CommandButton>

        <CommandButton
          label="Yüzey & Vurgu Ayarları"
          onClick={() => setShowThemeModal(true)}
        >
          <IconSliders size={16} />
        </CommandButton>

        <CommandButton
          label="Kadro & Telemetri Paneli"
          onClick={toggleRadar}
          active={isRadarOpen}
          className="hidden md:flex"
        >
          <IconRadar size={16} />
        </CommandButton>
      </div>
    </header>
  );
});
