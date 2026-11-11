'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Luminous Executive Command Bar (GhostNavbar)
// ─────────────────────────────────────────────────────────

import { memo, type ReactNode } from 'react';
import { useAppStore } from '@/lib/store';
import { useThemeStore } from '@/store/useThemeStore';
import { useVoiceSettingsStore } from '@/store/useVoiceSettingsStore';
import { cleanLabel, serverCode } from '@/lib/format';
import { SignalBars } from '@/components/ui/HudPrimitives';
import {
  IconMevaMark,
  IconBolt,
  IconUsers,
  IconSliders,
  IconRadar,
  IconGauge,
  IconMapBoard,
  IconMiniOverlay,
  IconShield,
  IconHelp,
  IconPlus,
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
      type="button"
      onClick={onClick}
      aria-label={label}
      aria-pressed={active}
      title={label}
      className={`relative rounded-xl w-9 h-9 flex items-center justify-center border transition-all duration-150 active:scale-[0.95] ${
        active
          ? 'bg-[linear-gradient(160deg,rgba(148,22,36,0.34)_0%,rgba(22,10,14,0.85)_100%)] text-[#F4EFF0] border-[#C82333]/50'
          : 'bg-[#120A0D]/80 hover:bg-[#1C0D12] text-[#9E8E91] hover:text-[#F4EFF0] border-[#2A1319] hover:border-[#4A1C26]'
      } ${className}`}
    >
      {children}
      {badge > 0 && (
        <span className="absolute -top-1 -right-1 min-w-[16px] h-4 px-1 rounded-full bg-gradient-to-br from-[#F25762] to-[#9E1B24] text-[#F7EEE9] text-[10px] font-bold tabular-nums flex items-center justify-center ring-2 ring-[#0A0608]">
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
    (s) =>
      s.friends.find((f) => f.friend_id === s.activeDMUserId)?.friend?.username ||
      s.onlineMembers.find((m) => m.id === s.activeDMUserId)?.username,
  );
  const pendingCount = useAppStore(
    (s) => s.friends.reduce((n, f) => n + (f.status === 'pending' ? 1 : 0), 0),
  );
  const qualityScore = useAppStore((s) => s.netGuard.qualityScore);
  const jitterMs = useAppStore((s) => s.netGuard.jitterMs);
  const activeScrim = useAppStore((s) => s.activeScrimRoom);
  const ecoEnabled = useAppStore((s) => s.ecoMode.isEnabled);
  const isRadarOpen = useAppStore((s) => s.isRadarOpen);
  const subscriptionTier = useAppStore((s) => s.subscriptionTier);
  const setShowProLicenseModal = useAppStore((s) => s.setShowProLicenseModal);

  const setActiveServer = useAppStore((s) => s.setActiveServer);
  const toggleEcoEnabled = useAppStore((s) => s.toggleEcoEnabled);
  const setShowScrimModal = useAppStore((s) => s.setShowScrimModal);
  const setShowLobbyGate = useAppStore((s) => s.setShowLobbyGate);
  const setShowChannelBuilderModal = useAppStore((s) => s.setShowChannelBuilderModal);
  const setShowTourModal = useAppStore((s) => s.setShowTourModal);
  const setShowOnboardingModal = useAppStore((s) => s.setShowOnboardingModal);
  const setShowFriendsModal = useAppStore((s) => s.setShowFriendsModal);
  const setShowStreamerOverlayModal = useAppStore((s) => s.setShowStreamerOverlayModal);
  const setShowSoundboardModal = useAppStore((s) => s.setShowSoundboardModal);
  const setShowRadialCommandWheel = useAppStore((s) => s.setShowRadialCommandWheel);
  const setShowVoiceClipBufferModal = useAppStore((s) => s.setShowVoiceClipBufferModal);
  const setShowScrimScheduleModal = useAppStore((s) => s.setShowScrimScheduleModal);
  const setShowShortcutsHelpModal = useAppStore((s) => s.setShowShortcutsHelpModal);
  const toggleRadar = useAppStore((s) => s.toggleRadar);
  const setIsMobileSidebarOpen = useAppStore((s) => s.setIsMobileSidebarOpen);
  const setShowThemeModal = useThemeStore((s) => s.setShowThemeModal);
  const showStratBoard = useVoiceSettingsStore((s) => s.showStratBoard);
  const miniHudActive = useVoiceSettingsStore((s) => s.miniHudActive);
  const toggleStratBoard = useVoiceSettingsStore((s) => s.toggleStratBoard);
  const toggleMiniHud = useVoiceSettingsStore((s) => s.toggleMiniHud);
  const setShowMobileCustomizer = useAppStore((s) => s.setShowMobileCustomizer);

  const mobileTitle = activeDMName
    ? `@${activeDMName}`
    : activeChannelName
      ? `#${cleanLabel(activeChannelName)}`
      : 'Komuta';

  return (
    <header className="relative z-30 h-[52px] lg:h-12 px-3.5 lg:px-4 flex items-center justify-between gap-3 flex-shrink-0 select-none bg-[linear-gradient(90deg,rgba(9,7,8,0.96)_0%,rgba(24,10,14,0.93)_50%,rgba(9,7,8,0.96)_100%)] font-sans">
      {/* Subtle Bottom Horizon Hairline */}
      <span
        aria-hidden
        className="pointer-events-none absolute inset-x-0 bottom-0 h-px horizon-divider"
      />

      {/* ── LEFT: Brand + Server Tabs ── */}
      <div className="flex items-center gap-2.5 lg:gap-3 min-w-0 flex-1">
        <button
          type="button"
          onClick={() => setIsMobileSidebarOpen(true)}
          aria-label="Kanal dizinini aç"
          className="crimson-cta rounded-xl w-9 h-9 lg:w-8 lg:h-8 flex items-center justify-center text-[#F4EFF0] flex-shrink-0 lg:pointer-events-none active:scale-95"
        >
          <IconMevaMark size={16} />
        </button>

        {/* Mobile context (spacious & unclipped) */}
        <button
          type="button"
          onClick={() => setIsMobileSidebarOpen(true)}
          className="lg:hidden flex flex-col items-start justify-center min-w-0 py-0.5"
        >
          {activeServerName && (
            <span className="text-[10px] font-semibold uppercase tracking-wider text-[#C82333] leading-none">
              {activeServerName}
            </span>
          )}
          <span className="text-[14px] font-bold text-[#F4EFF0] truncate max-w-[48vw] leading-tight mt-0.5">
            {mobileTitle}
          </span>
        </button>

        {/* Desktop brand */}
        <div className="hidden lg:flex items-center gap-1.5 flex-shrink-0">
          <span className="text-[14px] font-extrabold tracking-tight text-[#F4EFF0]">
            Meva
          </span>
          <span className="rounded-md px-1.5 py-0.5 bg-[#240C12] border border-[#7A121D]/60 text-[10px] font-bold tracking-wider text-[#E35D6A]">
            HUD
          </span>
        </div>

        <span aria-hidden className="hidden lg:block w-px h-5 bg-[#261217]" />

        {/* Desktop server tabs */}
        <nav
          aria-label="Sunucular"
          className="hidden lg:flex items-center gap-1.5 overflow-x-auto no-scrollbar min-w-0"
        >
          {servers.map((server) => {
            const isActive = server.id === activeServerId;
            return (
              <button
                type="button"
                key={server.id}
                onClick={() => setActiveServer(server.id)}
                aria-current={isActive ? 'true' : undefined}
                className={`relative rounded-xl h-8 pl-1.5 pr-3 flex items-center gap-2 flex-shrink-0 text-[12px] font-semibold border transition-all duration-150 ${
                  isActive
                    ? 'bg-[linear-gradient(160deg,rgba(128,18,30,0.24)_0%,rgba(14,9,11,0.85)_100%)] text-[#F4EFF0] border-[#961826]/55'
                    : 'bg-transparent text-[#8F8083] hover:text-[#F4EFF0] border-transparent hover:bg-[#170B0F]'
                }`}
              >
                <span
                  className={`rounded-lg w-5 h-5 flex items-center justify-center text-[9px] font-bold ${
                    isActive
                      ? 'crimson-cta text-[#F4EFF0]'
                      : 'bg-[#170B0F] text-[#9E8E91] border border-[#2A1319]'
                  }`}
                >
                  {serverCode(server.name)}
                </span>
                <span className="whitespace-nowrap">{server.name}</span>
              </button>
            );
          })}

          <button
            type="button"
            onClick={() => setShowChannelBuilderModal(true)}
            title="Yeni Sunucu Oluştur"
            className="rounded-xl h-8 px-2.5 flex items-center gap-1.5 text-[11.5px] font-extrabold text-[#F4EFF0] bg-[#1F0B11] hover:bg-[#2F0F1A] border border-[#C82333]/60 hover:border-[#DC3545] shadow-[0_0_12px_rgba(200,35,51,0.35)] transition-all flex-shrink-0 animate-pulse"
          >
            <IconPlus size={13} className="text-[#F5B5BC]" />
            <span>Sunucu Oluştur</span>
          </button>
        </nav>
      </div>

      {/* ── RIGHT: Decluttered Mobile + Full Desktop Command Controls ── */}
      <div className="flex items-center gap-1.5 flex-shrink-0">
        <button
          type="button"
          onClick={() => setShowTourModal(true)}
          title="Meva İnteraktif Rehber & Tur"
          className="hidden sm:flex rounded-xl h-9 px-2.5 lg:px-3 bg-[#120A0D]/80 hover:bg-[#1C0B10] border border-[#2A1319] hover:border-[#8F1622]/60 items-center gap-1.5 text-[11.5px] lg:text-[12px] font-bold text-[#F4EFF0] transition-colors"
        >
          <IconHelp size={15} className="text-[#C82333]" />
          <span>Meva Rehberi</span>
        </button>

        <div
          title={`Ağ Kalitesi: %${qualityScore} · DTLS-SRTP P2P`}
          className="rounded-xl h-8 lg:h-9 px-2 lg:px-3 bg-[#120A0D]/80 border border-[#2A1319] flex items-center gap-1 lg:gap-2 text-[11px] lg:text-[12px] font-bold text-[#F4EFF0]"
        >
          <SignalBars score={qualityScore} />
          <span className="tabular-nums">
            {Math.max(9, Math.round(11 + jitterMs))}
            <span className="text-[#827376] font-semibold ml-0.5">ms</span>
          </span>
        </div>

        {/* Dedicated Mobile Tactical Map Trigger */}
        <button
          type="button"
          onClick={toggleStratBoard}
          aria-label="Taktik Harita ve Strateji Tahtası"
          title="Taktik Harita ve Strateji Tahtası"
          className={`lg:hidden rounded-xl h-8 px-2.5 flex items-center gap-1.5 text-[11px] font-black border transition-all active:scale-95 ${
            showStratBoard
              ? 'crimson-cta text-[#FAF2EE] shadow-[0_0_12px_rgba(200,35,51,0.4)]'
              : 'bg-[#1C0A10] text-[#FAF2EE] border-[#8F1622]/80 hover:border-[#C82333]'
          }`}
        >
          <span className="text-xs">🗺️</span>
          <span>Taktik</span>
        </button>

        {/* Dedicated Mobile Ergonomic Customizer Pill */}
        <button
          type="button"
          onClick={() => setShowMobileCustomizer(true)}
          aria-label="Mobil Ayarlar"
          title="Mobil Ayarlar"
          className="lg:hidden rounded-xl h-8 px-2.5 bg-[#14080B] hover:bg-[#220D13] border border-[#2A1319] flex items-center gap-1 text-[11px] font-bold text-[#D8C9CC] active:scale-95"
        >
          <span className="text-xs">⚙️</span>
          <span>Ayar</span>
        </button>

        <button
          type="button"
          onClick={() => setShowLobbyGate(true)}
          title="Taktik Lobi Kur veya Koda Göre Katıl"
          className={`hidden lg:flex rounded-xl h-9 px-3.5 items-center gap-2 text-[#F4EFF0] text-[12px] font-bold transition-all active:scale-[0.97] ${
            activeScrim
              ? 'bg-[#2A0E16] border border-[#C82333]/55'
              : 'crimson-cta'
          }`}
        >
          <IconBolt size={14} className="text-[#F5B5BC]" />
          <span>{activeScrim ? `Lobi #${activeScrim.code}` : 'Taktik Lobi'}</span>
        </button>

        <CommandButton
          label="Taktik Harita & Çizim Tahtası (B)"
          onClick={toggleStratBoard}
          active={showStratBoard}
          className="hidden md:flex"
        >
          <IconMapBoard size={16} />
        </CommandButton>

        <CommandButton
          label="Yayıncı & OBS Tarayıcı Kaynağı Modu"
          onClick={() => setShowStreamerOverlayModal(true)}
          className="hidden md:flex"
        >
          <span className="text-sm">🎥</span>
        </CommandButton>

        <CommandButton
          label="Espor Soundboard & Taktik Ses Efektleri (NumPad 1-8)"
          onClick={() => setShowSoundboardModal(true)}
          className="hidden md:flex"
        >
          <span className="text-sm">🎛️</span>
        </CommandButton>

        <CommandButton
          label="IGL Taktik Hızlı Komut Çarkı (C)"
          onClick={() => setShowRadialCommandWheel(true)}
          className="hidden md:flex"
        >
          <span className="text-sm">🎯</span>
        </CommandButton>

        <CommandButton
          label="Son 30 Sn Ses Klibi & Replay (VOD Buffer)"
          onClick={() => setShowVoiceClipBufferModal(true)}
          className="hidden sm:flex"
        >
          <span className="text-sm">🎙️</span>
        </CommandButton>

        <CommandButton
          label="Espor Scrim & Turnuva Maç Takvimi"
          onClick={() => setShowScrimScheduleModal(true)}
          className="hidden lg:flex"
        >
          <span className="text-sm">📅</span>
        </CommandButton>

        <CommandButton
          label="Kompakt Overlay Modu · Mini HUD (O)"
          onClick={toggleMiniHud}
          active={miniHudActive}
          className="hidden sm:flex"
        >
          <IconMiniOverlay size={16} />
        </CommandButton>

        <CommandButton
          label="Operatör Profili & Oyun Tercihleri"
          onClick={() => setShowOnboardingModal(true)}
          className="hidden sm:flex"
        >
          <IconShield size={16} />
        </CommandButton>

        <CommandButton
          label="Operatör Ağı & 1v1 (Arkadaşlar)"
          onClick={() => setShowFriendsModal(true)}
          badge={pendingCount}
          className="hidden sm:flex"
        >
          <IconUsers size={16} />
        </CommandButton>

        <CommandButton
          label="Kadro Radarı & Oyuncu Listesi (R)"
          onClick={toggleRadar}
          active={isRadarOpen}
          className="hidden lg:flex"
        >
          <IconRadar size={16} />
        </CommandButton>

        <button
          type="button"
          onClick={() => setShowProLicenseModal(true)}
          title="Meva HUD Lisans & E-Spor Paketi"
          className={`hidden md:flex items-center gap-1.5 h-8 px-2.5 rounded-xl border text-[11px] font-extrabold tracking-wide transition-all active:scale-95 ${
            subscriptionTier === 'pro'
              ? 'bg-[#400B13]/70 hover:bg-[#590C15] border-[#A61826] text-[#F08C96] shadow-[0_0_10px_rgba(200,35,51,0.3)]'
              : 'bg-[#14080B] hover:bg-[#200A10] border-[#2A1319] hover:border-[#590C15] text-[#9E8E91] hover:text-[#FAF2EE]'
          }`}
        >
          <span className="text-[10px]">⚡</span>
          <span>{subscriptionTier === 'pro' ? 'MEVA PRO' : 'TOPLULUK'}</span>
        </button>

        <CommandButton
          label="Görünüm ve Tema Ayarları"
          onClick={() => setShowThemeModal(true)}
          className="hidden sm:flex"
        >
          <IconSliders size={16} />
        </CommandButton>

        <CommandButton
          label="Taktik Tuş Kısayolları ve Komut Rehberi (?)"
          onClick={() => setShowShortcutsHelpModal(true)}
          className="hidden sm:flex"
        >
          <IconHelp size={16} />
        </CommandButton>
      </div>
    </header>
  );
});
