'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Industrial Surface & Accent Configuration Modal
// ─────────────────────────────────────────────────────────

import { memo, useState } from 'react';
import {
  useThemeStore,
  THEME_PRESETS,
  type ThemePreset,
} from '@/store/useThemeStore';
import { IconClose, IconSliders } from '@/components/ui/MevaIcons';

export const ThemeSettingsModal = memo(function ThemeSettingsModal() {
  const isOpen = useThemeStore((s) => s.showThemeModal);
  const activePreset = useThemeStore((s) => s.currentTheme);
  const glassOpacity = useThemeStore((s) => s.glassOpacity);
  const customWallpaper = useThemeStore((s) => s.customWallpaper);

  const setTheme = useThemeStore((s) => s.setTheme);
  const setGlassOpacity = useThemeStore((s) => s.setGlassOpacity);
  const setCustomWallpaper = useThemeStore((s) => s.setCustomWallpaper);
  const setShowThemeModal = useThemeStore((s) => s.setShowThemeModal);

  const [tab, setTab] = useState<'themes' | 'wallpaper'>('themes');
  const [wallpaperInput, setWallpaperInput] = useState(customWallpaper ?? '');

  if (!isOpen) return null;

  const presetKeys = Object.keys(THEME_PRESETS) as ThemePreset[];

  return (
    <div
      className="fixed inset-0 z-50 flex items-end sm:items-center justify-center bg-black/80 p-0 sm:p-4"
      onClick={() => setShowThemeModal(false)}
    >
      <div
        className="w-full max-w-lg rounded-none sm:rounded-md bg-[#080A0E] border-t sm:border border-white/[0.08] p-5 sm:p-6 shadow-2xl max-h-[90dvh] overflow-y-auto"
        onClick={(e) => e.stopPropagation()}
      >
        {/* ── Header ── */}
        <div className="flex items-center justify-between border-b border-white/[0.06] pb-4 mb-5">
          <div className="flex items-center gap-3">
            <div className="rounded-sm w-9 h-9 bg-[#0C0E12] border border-white/[0.08] flex items-center justify-center text-gl-accent">
              <IconSliders size={17} />
            </div>
            <div>
              <h2 className="font-mono text-xs font-bold tracking-[0.18em] uppercase text-gl-text-bright">
                ENDÜSTRİYEL YÜZEY VE VURGU MOTORU
              </h2>
              <p className="text-[11px] font-mono text-gl-text-muted mt-0.5">
                Sıfır Re-Render Kök CSS Değişken Mimarisi
              </p>
            </div>
          </div>
          <button
            onClick={() => setShowThemeModal(false)}
            className="rounded-sm w-9 h-9 bg-[#0C0E12] border border-white/[0.06] flex items-center justify-center text-gl-text-normal hover:text-gl-text-bright"
            aria-label="Kapat"
          >
            <IconClose size={16} />
          </button>
        </div>

        {/* ── Tabs ── */}
        <div className="grid grid-cols-2 gap-2 mb-5">
          <button
            onClick={() => setTab('themes')}
            className={`rounded-sm min-h-[40px] font-mono text-[11px] font-bold uppercase tracking-[0.14em] border transition-colors ${
              tab === 'themes'
                ? 'bg-[#12151C] text-gl-text-bright border-gl-accent/60'
                : 'bg-[#0C0E12] text-gl-text-muted border-white/[0.05]'
            }`}
          >
            TAKTİK PALETLER
          </button>
          <button
            onClick={() => setTab('wallpaper')}
            className={`rounded-sm min-h-[40px] font-mono text-[11px] font-bold uppercase tracking-[0.14em] border transition-colors ${
              tab === 'wallpaper'
                ? 'bg-[#12151C] text-gl-text-bright border-gl-accent/60'
                : 'bg-[#0C0E12] text-gl-text-muted border-white/[0.05]'
            }`}
          >
            YÜZEY YOĞUNLUĞU
          </button>
        </div>

        {tab === 'themes' ? (
          <div className="space-y-2.5">
            {presetKeys.map((key) => {
              const preset = THEME_PRESETS[key];
              const isSelected = activePreset === key;
              return (
                <button
                  key={key}
                  onClick={() => setTheme(key)}
                  className={`relative rounded-sm w-full text-left p-4 border transition-colors flex items-center justify-between gap-3 ${
                    isSelected
                      ? 'border-gl-accent/60 bg-[#12151C]'
                      : 'border-white/[0.06] bg-[#0C0E12] hover:border-white/[0.14]'
                  }`}
                >
                  {isSelected && (
                    <span
                      aria-hidden
                      className="absolute left-0 top-1.5 bottom-1.5 w-[2px] bg-gl-accent"
                    />
                  )}
                  <div className="min-w-0">
                    <div className="flex items-center gap-2">
                      <span className="text-sm font-bold text-gl-text-bright">
                        {preset.name}
                      </span>
                      {isSelected && (
                        <span className="rounded-sm text-[9px] font-mono font-bold px-1.5 py-0.5 bg-gl-accent text-white">
                          AKTİF
                        </span>
                      )}
                    </div>
                    <p className="text-xs font-mono text-gl-text-muted mt-1">
                      {preset.tagline}
                    </p>
                  </div>

                  <div className="flex items-center gap-1.5 flex-shrink-0">
                    <span
                      className="rounded-sm w-6 h-6 border border-white/15"
                      style={{ backgroundColor: preset.bgDarkest }}
                    />
                    <span
                      className="rounded-sm w-6 h-6 border border-white/15"
                      style={{ backgroundColor: preset.accent }}
                    />
                  </div>
                </button>
              );
            })}
          </div>
        ) : (
          <div className="space-y-4">
            <div className="rounded-sm p-4 bg-[#0C0E12] border border-white/[0.06]">
              <div className="flex justify-between text-xs font-mono mb-2.5">
                <span className="text-gl-text-normal font-bold">
                  PANEL MATLIK YOĞUNLUĞU
                </span>
                <span className="text-gl-accent font-bold">
                  {Math.round(glassOpacity * 100)}%
                </span>
              </div>
              <input
                type="range"
                min={0.5}
                max={1}
                step={0.02}
                value={glassOpacity}
                onChange={(e) => setGlassOpacity(parseFloat(e.target.value))}
                className="w-full accent-[var(--ghost-accent)] cursor-pointer h-1.5"
              />
            </div>

            <div className="rounded-sm p-4 bg-[#0C0E12] border border-white/[0.06] space-y-3">
              <label className="block text-[11px] font-mono font-bold text-gl-text-normal uppercase tracking-wider">
                ARKA PLAN DOKU URL (İSTEĞE BAĞLI)
              </label>
              <div className="flex gap-2">
                <input
                  type="url"
                  value={wallpaperInput}
                  onChange={(e) => setWallpaperInput(e.target.value)}
                  placeholder="https://..."
                  className="rounded-sm flex-1 h-10 bg-[#050608] text-xs text-gl-text-bright px-3.5 border border-white/[0.08] focus:outline-none focus:border-gl-accent"
                />
                <button
                  onClick={() =>
                    setCustomWallpaper(wallpaperInput.trim() || null)
                  }
                  className="rounded-sm min-h-[40px] px-4 bg-gl-accent hover:bg-gl-accent-hover text-white text-xs font-mono font-bold"
                >
                  UYGULA
                </button>
              </div>
              {customWallpaper && (
                <button
                  onClick={() => {
                    setWallpaperInput('');
                    setCustomWallpaper(null);
                  }}
                  className="text-xs font-mono text-gl-danger hover:underline"
                >
                  Dokuyu kaldır
                </button>
              )}
            </div>
          </div>
        )}
      </div>
    </div>
  );
});
