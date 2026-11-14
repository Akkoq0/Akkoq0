'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Mobile Thumb-First Ergonomic Command Pill
// ─────────────────────────────────────────────────────────
// Adapts automatically to `mobileHandMode` (left/right thumb zone),
// renders a tactile Hold-to-Talk trigger in PTT mode, or quick-reach
// Squad Radar + IGL Command Wheel triggers during active voice sessions.

import React, { memo, useState, useCallback } from 'react';
import { useAppStore } from '@/lib/store';
import type { VoiceControls } from '@/types';
import type { MainNavViewMode } from '@/types/esport';
import { IconMic, IconMicOff, IconRadar } from '@/components/ui/MevaIcons';

interface MobileThumbCommandPillProps {
  activeView: MainNavViewMode;
  voiceControls?: VoiceControls;
}

export const MobileThumbCommandPill = memo(function MobileThumbCommandPill({
  activeView,
  voiceControls,
}: MobileThumbCommandPillProps) {
  const mobileHandMode = useAppStore((s) => s.mobileHandMode);
  const mobileVoiceMode = useAppStore((s) => s.mobileVoiceMode);
  const activeVoiceChannelId = useAppStore((s) => s.activeVoiceChannelId);
  const setIsMobileRadarOpen = useAppStore((s) => s.setIsMobileRadarOpen);
  const setShowRadialWheel = useAppStore((s) => s.setShowRadialCommandWheel);

  const [isPttHolding, setIsPttHolding] = useState(false);

  const handlePttStart = useCallback(
    (e: React.PointerEvent<HTMLButtonElement>) => {
      e.preventDefault();
      if (!voiceControls) return;
      setIsPttHolding(true);
      if (voiceControls.isMuted) {
        voiceControls.toggleMute();
      }
      if (typeof navigator !== 'undefined' && typeof navigator.vibrate === 'function') {
        navigator.vibrate(12);
      }
    },
    [voiceControls],
  );

  const handlePttEnd = useCallback(
    (e: React.PointerEvent<HTMLButtonElement>) => {
      e.preventDefault();
      if (!isPttHolding || !voiceControls) return;
      setIsPttHolding(false);
      if (!voiceControls.isMuted) {
        voiceControls.toggleMute();
      }
    },
    [isPttHolding, voiceControls],
  );

  if (activeView !== 'cockpit') return null;

  const isLeft = mobileHandMode === 'left';
  const showPttTrigger = mobileVoiceMode === 'ptt' && Boolean(voiceControls);
  const showVoiceQuickBar = Boolean(activeVoiceChannelId);

  if (!showPttTrigger && !showVoiceQuickBar) return null;

  return (
    <div
      className={`lg:hidden fixed z-30 flex items-center gap-2 select-none pointer-events-auto ${
        isLeft ? 'left-3' : 'right-3'
      }`}
      style={{
        bottom: 'calc(env(safe-area-inset-bottom, 0px) + 74px)',
      }}
    >
      {showVoiceQuickBar && (
        <>
          <button
            type="button"
            onClick={() => setIsMobileRadarOpen(true)}
            aria-label="Kadro Radarı"
            title="Kadro Radarı"
            className="h-10 px-3 rounded-2xl bg-[#0D0609]/92 backdrop-blur-lg border border-[#8F1622]/65 text-[#F4EFF0] text-[11px] font-black flex items-center gap-1.5 shadow-[0_8px_24px_rgba(0,0,0,0.85)] active:scale-95"
          >
            <IconRadar size={14} className="text-[#FF5A6B]" />
            <span>Radar</span>
          </button>

          <button
            type="button"
            onClick={() => setShowRadialWheel(true)}
            aria-label="IGL Hızlı Komut Çarkı"
            title="IGL Hızlı Komut Çarkı"
            className="h-10 w-10 rounded-2xl bg-[#180A0F]/92 backdrop-blur-lg border border-[#8F1622]/65 text-[#F4EFF0] text-sm flex items-center justify-center shadow-[0_8px_24px_rgba(0,0,0,0.85)] active:scale-95"
          >
            🎯
          </button>
        </>
      )}

      {showPttTrigger && (
        <button
          type="button"
          onPointerDown={handlePttStart}
          onPointerUp={handlePttEnd}
          onPointerCancel={handlePttEnd}
          onPointerLeave={handlePttEnd}
          aria-label="Bas-Konuş (Basılı Tut)"
          className={`h-11 px-4 rounded-2xl font-black text-xs flex items-center gap-2 border transition-all touch-none ${
            isPttHolding
              ? 'bg-gradient-to-r from-[#C82333] to-[#8F1622] text-white border-[#FAF2EE] shadow-[0_0_24px_rgba(200,35,51,0.75)] scale-105'
              : 'bg-[#12070A]/92 backdrop-blur-lg text-[#FAF2EE] border-[#8F1622]/80 shadow-[0_10px_28px_rgba(0,0,0,0.9)]'
          }`}
        >
          {isPttHolding ? (
            <IconMic size={15} className="text-white animate-pulse" />
          ) : (
            <IconMicOff size={15} className="text-[#FF7582]" />
          )}
          <span>{isPttHolding ? 'İLETİLİYOR' : 'BAS-KONUŞ'}</span>
        </button>
      )}
    </div>
  );
});
