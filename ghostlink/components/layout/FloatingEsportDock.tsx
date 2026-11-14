'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Floating Dynamic Esport Dock (Alt Fay Hattı)
// ─────────────────────────────────────────────────────────
// Translucent glass cockpit (`backdrop-filter: blur(16px)`),
// Left & Right telemetric wings, and neon-highlighted Center Esport Hub.

import { memo } from 'react';
import type { MainNavViewMode } from '@/types/esport';
import type { VoiceControls } from '@/types';
import { useAppStore } from '@/lib/store';
import { useVoiceSettingsStore } from '@/store/useVoiceSettingsStore';
import {
  IconVoiceWave,
  IconMapBoard,
  IconMic,
  IconMicOff,
  IconHeadphones,
  IconDeafen,
  IconSettingsGear,
} from '@/components/ui/MevaIcons';

interface FloatingEsportDockProps {
  activeView: MainNavViewMode;
  onSelectView: (view: MainNavViewMode) => void;
  voiceControls?: VoiceControls;
}

export const FloatingEsportDock = memo(function FloatingEsportDock({
  activeView,
  onSelectView,
  voiceControls,
}: FloatingEsportDockProps) {
  const activeVoiceChannelId = useAppStore((s) => s.activeVoiceChannelId);
  const isMobileSidebarOpen = useAppStore((s) => s.isMobileSidebarOpen);
  const setIsMobileSidebarOpen = useAppStore((s) => s.setIsMobileSidebarOpen);
  const setShowCommandSettingsModal = useVoiceSettingsStore(
    (s) => s.setShowCommandSettingsModal,
  );

  const inVoice = Boolean(activeVoiceChannelId);
  const isMuted = voiceControls?.isMuted ?? false;
  const isDeafened = voiceControls?.isDeafened ?? false;

  return (
    <nav
      aria-label="Meva HUD Ana Esport Dock Barı"
      className="fixed bottom-2.5 sm:bottom-3.5 left-1/2 -translate-x-1/2 z-40 select-none font-sans w-[96vw] max-w-[760px] pointer-events-auto"
      style={{
        paddingBottom: 'env(safe-area-inset-bottom, 0px)',
      }}
    >
      <div className="relative rounded-2xl bg-[#0A0507]/90 backdrop-blur-xl border border-[#8F1622]/55 shadow-[0_16px_50px_rgba(0,0,0,0.92),0_0_24px_rgba(143,22,34,0.22)] px-2.5 sm:px-4 py-1.5 flex items-center justify-between gap-1.5 sm:gap-3 transition-all duration-200">
        {/* Subtle Ambient Back-Glow */}
        <div
          aria-hidden
          className="pointer-events-none absolute -inset-0.5 rounded-2xl bg-gradient-to-r from-[#8F1622]/20 via-[#C82333]/25 to-[#8F1622]/20 opacity-70 blur-md -z-10"
        />

        {/* ── 1. SOL KANAT (LEFT WING: BRAND & TELEMETRY STATUS) ── */}
        <div className="flex items-center gap-1.5 sm:gap-2.5 flex-shrink-0">
          {/* Meva Emblem */}
          <div className="w-8 h-8 rounded-xl bg-gradient-to-br from-[#2E0B12] to-[#12070A] border border-[#8F1622]/70 flex items-center justify-center font-black text-xs text-[#FAF2EE] shadow-inner flex-shrink-0">
            M
          </div>

          {/* Telemetry Status Strip */}
          <div className="hidden sm:flex flex-col text-[10px] font-mono leading-tight">
            <div className="flex items-center gap-1.5">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse" />
              <span className="font-black text-[#FAF2EE]">11ms</span>
              <span className="text-[#8E7E81]">RTT</span>
            </div>
            <div className="flex items-center gap-1 text-[#FF7582] text-[9.5px]">
              <span>🔒 E2EE</span>
              <span className="text-[#6E5E61]">·</span>
              <span>P2P</span>
            </div>
          </div>
        </div>

        {/* ── 2. MERKEZ SEKME GRUBU (CENTER NAVIGATION TABS) ── */}
        <div className="flex items-center gap-1 sm:gap-2 flex-1 justify-center max-w-[460px]">
          {/* TAB 1: MEVA SUNUCU */}
          <button
            type="button"
            onClick={() => onSelectView('cockpit')}
            aria-current={activeView === 'cockpit' ? 'page' : undefined}
            className={`relative flex-1 h-11 px-2 rounded-xl flex items-center justify-center gap-1.5 font-black text-xs transition-all duration-150 active:scale-95 border ${
              activeView === 'cockpit'
                ? 'bg-[linear-gradient(165deg,rgba(143,22,34,0.38)_0%,rgba(16,9,12,0.95)_100%)] text-[#FAF2EE] border-[#C82333]/70 shadow-[0_0_16px_rgba(200,35,51,0.25)]'
                : 'bg-[#12070A]/80 text-[#8E7E81] hover:text-[#FAF2EE] border-[#220D13] hover:border-[#4A141E]'
            }`}
          >
            {activeView === 'cockpit' && (
              <span
                aria-hidden
                className="absolute inset-x-3 -top-[1px] h-[2px] rounded-full bg-[#C82333] shadow-[0_0_8px_#C82333]"
              />
            )}
            <IconVoiceWave
              size={15}
              className={activeView === 'cockpit' ? 'text-[#FF5A6B]' : 'text-[#8E7E81]'}
            />
            <span className="hidden min-[480px]:inline truncate">Meva Sunucu</span>
            <span className="min-[480px]:hidden">Sunucu</span>
            {inVoice && (
              <span className="w-2 h-2 rounded-full bg-emerald-400 ring-2 ring-[#0A0507] animate-pulse" />
            )}
          </button>

          {/* TAB 2: MERKEZ (ESPORT HUB BUTONU) — ÖZEL NEON VURGUSU */}
          <button
            type="button"
            onClick={() => onSelectView('esport-hub')}
            aria-current={activeView === 'esport-hub' ? 'page' : undefined}
            className={`relative flex-[1.25] h-11 sm:h-12 px-2.5 sm:px-4 rounded-xl flex items-center justify-center gap-1.5 font-black text-xs transition-all duration-200 active:scale-95 border ${
              activeView === 'esport-hub'
                ? 'bg-gradient-to-r from-[#B81F2E] via-[#E02638] to-[#8F1622] text-[#FAF2EE] border-[#FAF2EE] shadow-[0_0_24px_rgba(224,38,56,0.6)] scale-[1.03]'
                : 'bg-gradient-to-r from-[#3A0F17] via-[#52131F] to-[#250910] text-[#FF9EAA] hover:text-[#FAF2EE] border-[#8F1622]/80 hover:border-[#C82333] shadow-[0_0_14px_rgba(143,22,34,0.3)]'
            }`}
          >
            {/* Center Neon Underscore Glow */}
            {activeView === 'esport-hub' && (
              <span
                aria-hidden
                className="absolute inset-x-2 -bottom-[1px] h-[3px] rounded-full bg-[#FFF] shadow-[0_0_10px_#FFF,0_0_16px_#C82333]"
              />
            )}
            <span className="text-base sm:text-lg animate-pulse">🏆</span>
            <span className="tracking-wide uppercase text-[11.5px] sm:text-xs">
              Esport Hub
            </span>
            <span className="px-1.5 py-0.2 rounded text-[9px] font-mono bg-[#0F0508]/80 text-[#FFD1D6] border border-[#FF5A6B]/50 hidden sm:inline">
              LIVE
            </span>
          </button>

          {/* TAB 3: TAKTİKSEL STRATEJİ MASASI */}
          <button
            type="button"
            onClick={() => onSelectView('tactical')}
            aria-current={activeView === 'tactical' ? 'page' : undefined}
            className={`relative flex-1 h-11 px-2 rounded-xl flex items-center justify-center gap-1.5 font-black text-xs transition-all duration-150 active:scale-95 border ${
              activeView === 'tactical'
                ? 'bg-[linear-gradient(165deg,rgba(143,22,34,0.38)_0%,rgba(16,9,12,0.95)_100%)] text-[#FAF2EE] border-[#C82333]/70 shadow-[0_0_16px_rgba(200,35,51,0.25)]'
                : 'bg-[#12070A]/80 text-[#8E7E81] hover:text-[#FAF2EE] border-[#220D13] hover:border-[#4A141E]'
            }`}
          >
            {activeView === 'tactical' && (
              <span
                aria-hidden
                className="absolute inset-x-3 -top-[1px] h-[2px] rounded-full bg-[#C82333] shadow-[0_0_8px_#C82333]"
              />
            )}
            <IconMapBoard
              size={15}
              className={activeView === 'tactical' ? 'text-[#FF5A6B]' : 'text-[#8E7E81]'}
            />
            <span className="hidden min-[480px]:inline truncate">Taktik Masası</span>
            <span className="min-[480px]:hidden">Taktik</span>
          </button>
        </div>

        {/* ── 3. SAĞ KANAT (RIGHT WING: QUICK CONTROLS & SETTINGS) ── */}
        <div className="flex items-center gap-1 sm:gap-1.5 flex-shrink-0">
          {/* Quick Mic Mute */}
          {voiceControls && (
            <button
              type="button"
              onClick={voiceControls.toggleMute}
              title={isMuted ? 'Mikrofonu Aç' : 'Mikrofonu Sustur'}
              aria-label={isMuted ? 'Mikrofonu aç' : 'Mikrofonu sustur'}
              className={`w-8 h-8 rounded-xl flex items-center justify-center transition-all ${
                isMuted
                  ? 'bg-[#4A0D18] text-[#FF5A6B] border border-[#C82333]/80 animate-pulse'
                  : 'bg-[#150A0E] text-[#B8AAAC] hover:text-[#FAF2EE] border border-[#2D141B] hover:border-[#6E141E]'
              }`}
            >
              {isMuted ? <IconMicOff size={14} /> : <IconMic size={14} />}
            </button>
          )}

          {/* Quick Deafen */}
          {voiceControls && (
            <button
              type="button"
              onClick={voiceControls.toggleDeafen}
              title={isDeafened ? 'Kulaklığı Aç' : 'Sağırlaştır'}
              aria-label={isDeafened ? 'Kulaklığı aç' : 'Sağırlaştır'}
              className={`hidden sm:flex w-8 h-8 rounded-xl items-center justify-center transition-all ${
                isDeafened
                  ? 'bg-[#4A0D18] text-[#FF5A6B] border border-[#C82333]/80'
                  : 'bg-[#150A0E] text-[#B8AAAC] hover:text-[#FAF2EE] border border-[#2D141B] hover:border-[#6E141E]'
              }`}
            >
              {isDeafened ? <IconDeafen size={14} /> : <IconHeadphones size={14} />}
            </button>
          )}

          {/* Settings Gear */}
          <button
            type="button"
            onClick={() => setShowCommandSettingsModal(true)}
            title="Meva DSP & Sistem Ayarları"
            aria-label="Ayarlar"
            className="w-8 h-8 rounded-xl bg-[#150A0E] text-[#8E7E81] hover:text-[#FAF2EE] border border-[#261016] hover:border-[#6E141E] flex items-center justify-center transition-all"
          >
            <IconSettingsGear size={14} />
          </button>
        </div>
      </div>
    </nav>
  );
});
