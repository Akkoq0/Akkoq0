'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Mobile Ergonomic Command Dock (v3 — Customizable)
// ─────────────────────────────────────────────────────────
// Optimized for one-handed thumb ergonomics (Right vs Left hand),
// instant VAD/PTT switching, 4-tab spacious layout, and live floating voice bar.

import { memo, useState, useCallback, type ComponentType } from 'react';
import { useAppStore } from '@/lib/store';
import { useHUDStore } from '@/store/useHUDStore';
import { getMevaVadEngine } from '@/src/lib/vadEngine';
import { cleanLabel } from '@/lib/format';
import {
  IconLayers,
  IconMessage,
  IconVoiceWave,
  IconRadar,
  IconMic,
  IconMicOff,
  IconHeadphones,
  IconClose,
} from '@/components/ui/MevaIcons';
import type { VoiceControls } from '@/types';

interface DockTabProps {
  label: string;
  Icon: ComponentType<{ size?: number; className?: string }>;
  active: boolean;
  onClick: () => void;
  live?: boolean;
  density: 'compact' | 'comfortable';
}

function DockTab({
  label,
  Icon,
  active,
  onClick,
  live = false,
  density,
}: DockTabProps) {
  const isCompact = density === 'compact';
  return (
    <button
      type="button"
      onClick={onClick}
      aria-label={label}
      aria-current={active ? 'page' : undefined}
      className={`relative flex-1 flex flex-col items-center justify-center rounded-xl mx-0.5 my-1 transition-all duration-150 active:scale-[0.96] ${
        isCompact ? 'min-h-[44px] gap-0.5 py-1' : 'min-h-[50px] gap-1 py-1.5'
      } ${
        active
          ? 'text-[#F4EFF0] bg-[linear-gradient(165deg,rgba(138,20,32,0.32)_0%,rgba(16,9,12,0.92)_100%)] border border-[#C82333]/50 shadow-[0_0_12px_rgba(200,35,51,0.2)]'
          : 'text-[#8A797D] hover:text-[#F4EFF0] border border-transparent hover:bg-[#160B0F]/70'
      }`}
    >
      {active && (
        <span
          aria-hidden
          className="absolute inset-x-3 -top-[1px] h-[2px] rounded-full bg-[#C82333]"
        />
      )}
      <Icon
        size={isCompact ? 16 : 18}
        className={active ? 'text-[#FF5A6B]' : 'text-[#8A797D]'}
      />
      <span
        className={`${
          isCompact ? 'text-[10px]' : 'text-[11px]'
        } font-black tracking-tight leading-none`}
      >
        {label}
      </span>

      {live && (
        <span
          aria-hidden
          className="absolute top-1 right-[calc(50%-14px)] w-2 h-2 rounded-full bg-emerald-400 ring-2 ring-[#080607] animate-pulse"
        />
      )}
    </button>
  );
}

interface MobileBottomNavProps {
  voiceControls?: VoiceControls;
}

export const MobileBottomNav = memo(function MobileBottomNav({
  voiceControls,
}: MobileBottomNavProps) {
  const isMobileSidebarOpen = useAppStore((s) => s.isMobileSidebarOpen);
  const isMobileRadarOpen = useAppStore((s) => s.isMobileRadarOpen);
  const mobileTab = useAppStore((s) => s.mobileTab);
  const activeVoiceChannelId = useAppStore((s) => s.activeVoiceChannelId);
  const channels = useAppStore((s) => s.channels);
  const handMode = useAppStore((s) => s.mobileHandMode);
  const density = useAppStore((s) => s.mobileDensity);
  const voiceMode = useAppStore((s) => s.mobileVoiceMode);

  const setIsMobileSidebarOpen = useAppStore((s) => s.setIsMobileSidebarOpen);
  const setIsMobileRadarOpen = useAppStore((s) => s.setIsMobileRadarOpen);
  const setShowFriendsModal = useAppStore((s) => s.setShowFriendsModal);
  const setShowScrimModal = useAppStore((s) => s.setShowScrimModal);
  const setMobileTab = useAppStore((s) => s.setMobileTab);
  const setActiveVoiceChannel = useAppStore((s) => s.setActiveVoiceChannel);

  const localMutes = useHUDStore((s) => s.localMutes);
  const toggleLocalMute = useHUDStore((s) => s.toggleLocalMute);

  const [fallbackDeafened, setFallbackDeafened] = useState(false);
  const [pttHeld, setPttHeld] = useState(false);

  const inVoice = activeVoiceChannelId !== null;
  const activeVoiceChannel = channels.find((c) => c.id === activeVoiceChannelId);
  const voiceChannelName = activeVoiceChannel
    ? cleanLabel(activeVoiceChannel.name)
    : activeVoiceChannelId?.startsWith('scrim-')
      ? `Scrim #${activeVoiceChannelId.slice(6)}`
      : 'Taktik Ses';

  const isMuted =
    (voiceControls?.isMuted ?? false) || Boolean(localMutes['usr-local']);
  const isDeafened = voiceControls?.isDeafened ?? fallbackDeafened;

  const handleToggleMute = useCallback(() => {
    if (voiceControls?.toggleMute) {
      voiceControls.toggleMute();
    } else {
      toggleLocalMute('usr-local');
    }
  }, [voiceControls, toggleLocalMute]);

  const handleToggleDeafen = useCallback(() => {
    if (voiceControls?.toggleDeafen) {
      voiceControls.toggleDeafen();
    } else {
      setFallbackDeafened((prev) => !prev);
    }
  }, [voiceControls]);

  const handleLeaveVoice = useCallback(() => {
    if (voiceControls?.leaveVoice) {
      voiceControls.leaveVoice();
    }
    setActiveVoiceChannel(null);
  }, [voiceControls, setActiveVoiceChannel]);

  const handlePttDown = useCallback((e: React.SyntheticEvent) => {
    e.preventDefault();
    setPttHeld(true);
    getMevaVadEngine().setPttPressed(true);
  }, []);

  const handlePttUp = useCallback((e: React.SyntheticEvent) => {
    e.preventDefault();
    setPttHeld(false);
    getMevaVadEngine().setPttPressed(false);
  }, []);

  const closeOverlays = () => {
    setIsMobileSidebarOpen(false);
    setIsMobileRadarOpen(false);
    setShowFriendsModal(false);
    setShowScrimModal(false);
  };

  const noDrawerOpen = !isMobileSidebarOpen && !isMobileRadarOpen;
  const isLeftHand = handMode === 'left';
  const isCompact = density === 'compact';

  return (
    <>
      {/* ── 1. FLOATING THUMB PTT BUTTON (When Voice Mode is PTT and In Voice) ── */}
      {inVoice && voiceMode === 'ptt' && (
        <div
          className={`fixed z-40 lg:hidden pointer-events-auto transition-all duration-200 ${
            isLeftHand ? 'left-4' : 'right-4'
          }`}
          style={{ bottom: 'calc(env(safe-area-inset-bottom, 20px) + 115px)' }}
        >
          <button
            type="button"
            onTouchStart={handlePttDown}
            onTouchEnd={handlePttUp}
            onTouchCancel={handlePttUp}
            onMouseDown={handlePttDown}
            onMouseUp={handlePttUp}
            onMouseLeave={handlePttUp}
            aria-label="Başparmak Bas-Konuş Tuşu"
            className={`w-16 h-16 rounded-full flex flex-col items-center justify-center font-black select-none shadow-[0_8px_30px_rgba(0,0,0,0.8)] border-2 transition-transform duration-100 ${
              pttHeld
                ? 'bg-gradient-to-br from-[#FF3B4E] to-[#990D1C] border-[#FAF2EE] text-[#FAF2EE] scale-110 shadow-[0_0_30px_rgba(255,59,78,0.7)]'
                : 'bg-gradient-to-br from-[#2B0B13] to-[#12070A] border-[#8F1622] text-[#F4EFF0] active:scale-95 hover:border-[#C82333]'
            }`}
          >
            <IconMic size={20} className={pttHeld ? 'animate-bounce' : ''} />
            <span className="text-[9px] uppercase tracking-wider mt-0.5 font-extrabold">
              {pttHeld ? 'YAYIN' : 'BAS-KONUŞ'}
            </span>
          </button>
        </div>
      )}

      {/* ── 2. MOBILE DOCK CONTAINER ── */}
      <nav
        aria-label="Mobil Komuta Barı"
        className="lg:hidden relative z-30 flex-shrink-0 select-none bg-[linear-gradient(180deg,rgba(16,9,12,0.98)_0%,rgba(6,5,6,0.99)_100%)] font-sans px-2"
        style={{ paddingBottom: 'env(safe-area-inset-bottom)' }}
      >
        <div className="horizon-divider h-px w-full" aria-hidden />

        {/* ── FLOATING ERGONOMIC VOICE HUD STRIP (When Connected to Voice) ── */}
        {inVoice && (
          <div
            className={`w-full py-1.5 px-2 mt-1 rounded-xl bg-[linear-gradient(90deg,rgba(26,10,14,0.95)_0%,rgba(14,8,11,0.95)_100%)] border border-[#8F1622]/50 flex items-center justify-between gap-2 shadow-lg ${
              isLeftHand ? 'flex-row-reverse' : 'flex-row'
            }`}
          >
            {/* Room Info + Secondary Controls */}
            <div
              className={`flex items-center gap-2 min-w-0 flex-1 ${
                isLeftHand ? 'justify-end' : 'justify-start'
              }`}
            >
              <button
                type="button"
                onClick={handleLeaveVoice}
                title="Ses Odasından Ayrıl"
                aria-label="Ses odasından ayrıl"
                className="w-8 h-8 rounded-lg bg-[#2B0E14] hover:bg-[#4A121F] border border-[#8F1622]/60 text-[#FF6B7A] flex items-center justify-center transition-colors flex-shrink-0 active:scale-95"
              >
                <IconClose size={14} />
              </button>

              <button
                type="button"
                onClick={handleToggleDeafen}
                title={isDeafened ? 'Sağırlaştırmayı Kapat' : 'Sağırlaştır'}
                aria-label={isDeafened ? 'Sağırlaştırmayı kapat' : 'Sağırlaştır'}
                className={`w-8 h-8 rounded-lg flex items-center justify-center border transition-colors flex-shrink-0 active:scale-95 ${
                  isDeafened
                    ? 'bg-[#3D141F] text-[#FF5A6B] border-[#C82333]'
                    : 'bg-[#140A0D] text-[#8F8083] border-[#2A1319]'
                }`}
              >
                <IconHeadphones size={15} />
              </button>

              <button
                type="button"
                onClick={() => setMobileTab('voice')}
                className="flex flex-col min-w-0 text-left"
              >
                <div className="flex items-center gap-1.5">
                  <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse flex-shrink-0" />
                  <span className="text-[12px] font-black text-[#FAF2EE] truncate max-w-[120px]">
                    {voiceChannelName}
                  </span>
                </div>
                <span className="text-[9.5px] font-bold text-[#E08C96] leading-none">
                  DTLS-SRTP • 9ms
                </span>
              </button>
            </div>

            {/* Primary Big Thumb Mic Toggle (Positioned by Hand Mode) */}
            <button
              type="button"
              onClick={handleToggleMute}
              aria-label={isMuted ? 'Mikrofonu Aç' : 'Mikrofonu Kapat'}
              className={`h-10 px-3.5 rounded-xl flex items-center gap-2 font-black text-[12px] transition-all flex-shrink-0 active:scale-95 shadow-md ${
                isMuted
                  ? 'bg-gradient-to-r from-[#3D0F19] to-[#240A10] text-[#FF6B7A] border border-[#C82333] shadow-[0_0_12px_rgba(200,35,51,0.35)]'
                  : 'bg-gradient-to-r from-[#0C3322] to-[#061F14] text-emerald-300 border border-emerald-500/80 shadow-[0_0_14px_rgba(16,185,129,0.35)] animate-pulse'
              }`}
            >
              {isMuted ? <IconMicOff size={16} /> : <IconMic size={16} />}
              <span>{isMuted ? 'SUSTURULDU' : 'MİK AÇIK'}</span>
            </button>
          </div>
        )}

        {/* ── 4 STREAMLINED COCKPIT TABS ── */}
        <div className={`flex items-stretch ${isCompact ? 'h-[50px]' : 'h-[58px]'}`}>
          <DockTab
            label="Kanallar"
            Icon={IconLayers}
            active={isMobileSidebarOpen}
            density={density}
            onClick={() => {
              const next = !isMobileSidebarOpen;
              closeOverlays();
              setIsMobileSidebarOpen(next);
            }}
          />
          <DockTab
            label="Sohbet"
            Icon={IconMessage}
            active={noDrawerOpen && mobileTab === 'chat'}
            density={density}
            onClick={() => setMobileTab('chat')}
          />
          <DockTab
            label="Ses Odası"
            Icon={IconVoiceWave}
            active={noDrawerOpen && mobileTab === 'voice'}
            density={density}
            live={inVoice}
            onClick={() => setMobileTab('voice')}
          />
          <DockTab
            label="Kadro"
            Icon={IconRadar}
            active={isMobileRadarOpen}
            density={density}
            onClick={() => {
              const next = !isMobileRadarOpen;
              closeOverlays();
              setIsMobileRadarOpen(next);
            }}
          />
        </div>
      </nav>
    </>
  );
});
