'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Executive Surface & Accent Configuration Modal
// ─────────────────────────────────────────────────────────

import { memo, useEffect, useState } from 'react';
import {
  useThemeStore,
  THEME_PRESETS,
  FONT_PRESETS,
  type ThemePreset,
  type FontPreset,
} from '@/store/useThemeStore';
import { IconClose, IconSliders } from '@/components/ui/MevaIcons';

export const ThemeSettingsModal = memo(function ThemeSettingsModal() {
  const isOpen = useThemeStore((s) => s.showThemeModal);
  const activePreset = useThemeStore((s) => s.currentTheme);
  const activeFont = useThemeStore((s) => s.currentFont);
  const glassOpacity = useThemeStore((s) => s.glassOpacity);
  const blurIntensity = useThemeStore((s) => s.blurIntensity);
  const customWallpaper = useThemeStore((s) => s.customWallpaper);

  const setTheme = useThemeStore((s) => s.setTheme);
  const setFont = useThemeStore((s) => s.setFont);
  const setGlassOpacity = useThemeStore((s) => s.setGlassOpacity);
  const setBlurIntensity = useThemeStore((s) => s.setBlurIntensity);
  const setCustomWallpaper = useThemeStore((s) => s.setCustomWallpaper);
  const setShowThemeModal = useThemeStore((s) => s.setShowThemeModal);

  const [tab, setTab] = useState<'themes' | 'fonts' | 'wallpaper'>('themes');
  const [wallpaperInput, setWallpaperInput] = useState(customWallpaper ?? '');
  const [urlError, setUrlError] = useState<string | null>(null);

  useEffect(() => {
    if (isOpen) {
      setWallpaperInput(customWallpaper ?? '');
      setUrlError(null);
    }
  }, [isOpen, customWallpaper]);

  if (!isOpen) return null;

  const presetKeys = Object.keys(THEME_PRESETS) as ThemePreset[];

  const handleApplyWallpaper = () => {
    const trimmed = wallpaperInput.trim();
    if (!trimmed) {
      setCustomWallpaper(null);
      setUrlError(null);
      return;
    }
    const ok = setCustomWallpaper(trimmed);
    if (!ok) {
      setUrlError(
        'Güvenlik kuralı: Yalnızca geçerli bir HTTPS görsel adresi (https://...) kullanılabilir.',
      );
    } else {
      setUrlError(null);
    }
  };

  return (
    <div
      className="fixed inset-0 z-50 flex items-end sm:items-center justify-center exec-backdrop p-0 sm:p-4 font-sans tabular-nums"
      onClick={() => setShowThemeModal(false)}
    >
      <div
        className="w-full max-w-lg rounded-t-2xl sm:rounded-2xl exec-modal p-5 sm:p-6 max-h-[90dvh] overflow-y-auto"
        onClick={(e) => e.stopPropagation()}
      >
        {/* ── Header ── */}
        <div className="flex items-center justify-between border-b border-[#881A26]/20 pb-4 mb-5">
          <div className="flex items-center gap-3">
            <div className="rounded-xl w-10 h-10 bg-gradient-to-br from-[#591019]/50 to-[#0C0809] border border-[#881A26]/40 flex items-center justify-center text-[#E35D6A]">
              <IconSliders size={18} />
            </div>
            <div>
              <h2 className="text-sm font-bold tracking-tight text-[#F4EFF0]">
                Görünüm ve Yüzey Motoru
              </h2>
              <p className="text-xs text-[#8E7F83] mt-0.5">
                Siyah & Derin Bordo Kök CSS Değişken Mimarisi
              </p>
            </div>
          </div>
          <button
            type="button"
            onClick={() => setShowThemeModal(false)}
            className="rounded-xl w-9 h-9 bg-[#120A0D] hover:bg-[#1B0D12] border border-[#881A26]/25 flex items-center justify-center text-[#9E8F93] hover:text-[#F4EFF0] transition-colors"
            aria-label="Kapat"
          >
            <IconClose size={16} />
          </button>
        </div>

        {/* ── Tabs ── */}
        <div className="grid grid-cols-3 gap-1.5 p-1 rounded-xl bg-[#0A0708] border border-[#881A26]/20 mb-5">
          <button
            type="button"
            onClick={() => setTab('themes')}
            className={`rounded-lg min-h-[38px] text-xs font-bold transition-all ${
              tab === 'themes'
                ? 'bg-gradient-to-b from-[#2A0E15] to-[#13090C] text-[#F4EFF0] border border-[#881A26]/40'
                : 'text-[#8E7F83] hover:text-[#F4EFF0] border border-transparent'
            }`}
          >
            Temalar
          </button>
          <button
            type="button"
            onClick={() => setTab('fonts')}
            className={`rounded-lg min-h-[38px] text-xs font-bold transition-all ${
              tab === 'fonts'
                ? 'bg-gradient-to-b from-[#2A0E15] to-[#13090C] text-[#F4EFF0] border border-[#881A26]/40'
                : 'text-[#8E7F83] hover:text-[#F4EFF0] border border-transparent'
            }`}
          >
            Yazı Tipleri
          </button>
          <button
            type="button"
            onClick={() => setTab('wallpaper')}
            className={`rounded-lg min-h-[38px] text-xs font-bold transition-all ${
              tab === 'wallpaper'
                ? 'bg-gradient-to-b from-[#2A0E15] to-[#13090C] text-[#F4EFF0] border border-[#881A26]/40'
                : 'text-[#8E7F83] hover:text-[#F4EFF0] border border-transparent'
            }`}
          >
            Yüzey & Cam
          </button>
        </div>

        {tab === 'fonts' && (
          <div className="space-y-2.5">
            {(Object.keys(FONT_PRESETS) as FontPreset[]).map((key) => {
              const f = FONT_PRESETS[key];
              const isSelected = activeFont === key;
              return (
                <button
                  type="button"
                  key={key}
                  onClick={() => setFont(key)}
                  className={`relative rounded-2xl w-full text-left p-4 border transition-all flex items-center justify-between gap-3 ${
                    isSelected
                      ? 'border-[#A61B29]/55 bg-gradient-to-r from-[#240C12] to-[#0D080A] shadow-[0_0_15px_rgba(200,35,51,0.25)]'
                      : 'border-[#881A26]/20 bg-[#10080B] hover:border-[#881A26]/40'
                  }`}
                  style={{ fontFamily: f.fontFamily }}
                >
                  <div className="min-w-0">
                    <span className="text-sm font-bold text-[#F4EFF0] block">
                      {f.label}
                    </span>
                    <span className="text-xs text-[#8E7F83] mt-0.5 block font-sans">
                      {f.tagline}
                    </span>
                    <span className="text-xs text-[#E35D6A] mt-1.5 block tracking-widest uppercase">
                      CS2 · VALORANT · LOL · DOTA 2 • 144Hz HUD
                    </span>
                  </div>
                  {isSelected && (
                    <div className="w-5 h-5 rounded-full bg-[#C82333] flex items-center justify-center text-white text-[11px] font-black flex-shrink-0 font-sans shadow-md">
                      ✓
                    </div>
                  )}
                </button>
              );
            })}
          </div>
        )}

        {tab === 'themes' ? (
          <div className="space-y-2.5">
            {presetKeys.map((key) => {
              const preset = THEME_PRESETS[key];
              const isSelected = activePreset === key;
              return (
                <button
                  type="button"
                  key={key}
                  onClick={() => setTheme(key)}
                  className={`relative rounded-2xl w-full text-left p-4 border transition-all flex items-center justify-between gap-3 ${
                    isSelected
                      ? 'border-[#A61B29]/55 bg-gradient-to-r from-[#240C12] to-[#0D080A]'
                      : 'border-[#881A26]/20 bg-[#10080B] hover:border-[#881A26]/40'
                  }`}
                >
                  <div className="min-w-0">
                    <div className="flex items-center gap-2">
                      <span className="text-sm font-bold text-[#F4EFF0]">
                        {preset.name}
                      </span>
                      {isSelected && (
                        <span className="rounded-full text-[10px] font-bold px-2 py-0.5 bg-[#7A121D]/35 text-[#F08C96] border border-[#A61B29]/55">
                          Aktif
                        </span>
                      )}
                    </div>
                    <p className="text-xs text-[#8E7F83] mt-1">
                      {preset.tagline}
                    </p>
                  </div>

                  <div className="flex items-center gap-1.5 flex-shrink-0">
                    <span
                      className="rounded-lg w-7 h-7 border border-[#881A26]/35 shadow-inner"
                      style={{
                        background: `linear-gradient(135deg, ${preset.bgMid} 0%, ${preset.bgDarkest} 100%)`,
                      }}
                    />
                    <span
                      className="rounded-lg w-9 h-7 border border-[#A61B29]/45 shadow-inner"
                      style={{
                        background: `linear-gradient(135deg, ${preset.accent} 0%, ${preset.secondaryAccent} 100%)`,
                      }}
                    />
                  </div>
                </button>
              );
            })}
          </div>
        ) : (
          <div className="space-y-4">
            <div className="rounded-2xl p-4 bg-[#11090C]/90 border border-[#881A26]/25 space-y-4">
              <div>
                <div className="flex justify-between text-xs mb-2.5">
                  <span className="text-[#C4B6BA] font-semibold">
                    Cam Yüzey Yoğunluğu (Şeffaflık)
                  </span>
                  <span className="text-[#F08C96] font-bold">
                    %{Math.round(glassOpacity * 100)}
                  </span>
                </div>
                <input
                  type="range"
                  min={0.45}
                  max={0.96}
                  step={0.02}
                  value={glassOpacity}
                  onChange={(e) => setGlassOpacity(parseFloat(e.target.value))}
                  style={
                    {
                      '--fill': `${Math.round(((glassOpacity - 0.45) / 0.51) * 100)}%`,
                    } as React.CSSProperties
                  }
                  className="exec-range w-full"
                />
              </div>

              <div>
                <div className="flex justify-between text-xs mb-2.5">
                  <span className="text-[#C4B6BA] font-semibold">
                    Buzlu Cam Bulanıklığı (Blur)
                  </span>
                  <span className="text-[#F08C96] font-bold">
                    {blurIntensity} px
                  </span>
                </div>
                <input
                  type="range"
                  min={0}
                  max={28}
                  step={2}
                  value={blurIntensity}
                  onChange={(e) => setBlurIntensity(Number(e.target.value))}
                  style={
                    {
                      '--fill': `${Math.round((blurIntensity / 28) * 100)}%`,
                    } as React.CSSProperties
                  }
                  className="exec-range w-full"
                />
              </div>
            </div>

            <div className="rounded-2xl p-4 bg-[#11090C]/90 border border-[#881A26]/25 space-y-3">
              <label className="block text-xs font-semibold text-[#C4B6BA]">
                Özel Arka Plan Görseli (Yalnızca HTTPS)
              </label>
              <div className="flex gap-2">
                <input
                  type="url"
                  value={wallpaperInput}
                  onChange={(e) => {
                    setWallpaperInput(e.target.value);
                    if (urlError) setUrlError(null);
                  }}
                  placeholder="https://..."
                  maxLength={512}
                  className="rounded-xl flex-1 h-10 bg-[#0A0708] text-xs text-[#F4EFF0] placeholder:text-[#786A6E] px-3.5 border border-[#881A26]/25 focus:outline-none focus:border-[#B51D2C]/65 transition-colors"
                />
                <button
                  type="button"
                  onClick={handleApplyWallpaper}
                  className="rounded-xl min-h-[40px] px-4 crimson-cta text-xs font-bold transition-all"
                >
                  Uygula
                </button>
              </div>
              {urlError && (
                <p className="text-xs text-[#F08C96] font-medium">{urlError}</p>
              )}
              {customWallpaper && (
                <button
                  type="button"
                  onClick={() => {
                    setWallpaperInput('');
                    setUrlError(null);
                    setCustomWallpaper(null);
                  }}
                  className="text-xs font-semibold text-[#ED8793] hover:underline"
                >
                  Varsayılan yüzeye dön
                </button>
              )}
            </div>
          </div>
        )}
      </div>
    </div>
  );
});
