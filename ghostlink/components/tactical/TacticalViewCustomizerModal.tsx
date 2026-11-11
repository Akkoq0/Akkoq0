'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Stratbook Tactical View & Customization Matrix
// ─────────────────────────────────────────────────────────
// Professional esports dark-mode aesthetics, custom color palettes,
// topographical grid density options, dynamic radar contrast filters,
// and HUD visibility toggles with persistent state.

import React from 'react';
import { IconClose } from '@/components/ui/MevaIcons';

export type TacticalThemeKey = 'crimson' | 'cyan' | 'emerald' | 'amber' | 'purple';
export type TacticalGridMode = 'standard' | 'dense' | 'none';
export type TacticalRadarFilter = 'normal' | 'high-contrast' | 'oled-dark' | 'tactical-thermal';
export type TacticalUiDensity = 'comfortable' | 'compact';

export interface TacticalThemeDef {
  id: TacticalThemeKey;
  name: string;
  badge: string;
  primary: string;
  hover: string;
  glow: string;
  border: string;
  accentText: string;
  defaultInk: string;
  sampleBg: string;
}

export const TACTICAL_THEME_CONFIG: Record<TacticalThemeKey, TacticalThemeDef> = {
  crimson: {
    id: 'crimson',
    name: 'Meva Crimson',
    badge: 'Espor Standart',
    primary: '#C82333',
    hover: '#DC3545',
    glow: 'rgba(200, 35, 51, 0.45)',
    border: '#8F1622',
    accentText: '#F08C96',
    defaultInk: '#C82333',
    sampleBg: 'linear-gradient(135deg, #18090D 0%, #2E0F17 100%)',
  },
  cyan: {
    id: 'cyan',
    name: 'Cyber Cyan',
    badge: 'Siber Buzul',
    primary: '#00F0FF',
    hover: '#38BDF8',
    glow: 'rgba(0, 240, 255, 0.45)',
    border: '#0284C7',
    accentText: '#7DD3FC',
    defaultInk: '#00F0FF',
    sampleBg: 'linear-gradient(135deg, #051923 0%, #082F49 100%)',
  },
  emerald: {
    id: 'emerald',
    name: 'Emerald Recon',
    badge: 'Gece Operasyonu',
    primary: '#10B981',
    hover: '#34D399',
    glow: 'rgba(16, 185, 129, 0.45)',
    border: '#047857',
    accentText: '#6EE7B7',
    defaultInk: '#10B981',
    sampleBg: 'linear-gradient(135deg, #051A14 0%, #064E3B 100%)',
  },
  amber: {
    id: 'amber',
    name: 'Volt Amber',
    badge: 'Askeri Çöl',
    primary: '#F59E0B',
    hover: '#FBBF24',
    glow: 'rgba(245, 158, 11, 0.45)',
    border: '#B45309',
    accentText: '#FCD34D',
    defaultInk: '#F59E0B',
    sampleBg: 'linear-gradient(135deg, #1C1205 0%, #78350F 100%)',
  },
  purple: {
    id: 'purple',
    name: 'Amethyst SpecOps',
    badge: 'Kozmik Gizlilik',
    primary: '#A855F7',
    hover: '#C084FC',
    glow: 'rgba(168, 85, 247, 0.45)',
    border: '#7E22CE',
    accentText: '#D8B4FE',
    defaultInk: '#A855F7',
    sampleBg: 'linear-gradient(135deg, #180824 0%, #581C87 100%)',
  },
};

export interface TacticalViewCustomizerProps {
  isOpen: boolean;
  onClose: () => void;
  theme: TacticalThemeKey;
  onSelectTheme: (t: TacticalThemeKey) => void;
  gridMode: TacticalGridMode;
  onSelectGridMode: (g: TacticalGridMode) => void;
  radarFilter: TacticalRadarFilter;
  onSelectRadarFilter: (f: TacticalRadarFilter) => void;
  showCallouts: boolean;
  onToggleCallouts: () => void;
  showCompassHud: boolean;
  onToggleCompassHud: () => void;
  showZoomDock: boolean;
  onToggleZoomDock: () => void;
  showCoordinatesHud: boolean;
  onToggleCoordinatesHud: () => void;
  uiDensity: TacticalUiDensity;
  onSelectUiDensity: (d: TacticalUiDensity) => void;
  onResetDefaults: () => void;
}

export const TacticalViewCustomizerModal: React.FC<TacticalViewCustomizerProps> = ({
  isOpen,
  onClose,
  theme,
  onSelectTheme,
  gridMode,
  onSelectGridMode,
  radarFilter,
  onSelectRadarFilter,
  showCallouts,
  onToggleCallouts,
  showCompassHud,
  onToggleCompassHud,
  showZoomDock,
  onToggleZoomDock,
  showCoordinatesHud,
  onToggleCoordinatesHud,
  uiDensity,
  onSelectUiDensity,
  onResetDefaults,
}) => {
  if (!isOpen) return null;

  const currentTheme = TACTICAL_THEME_CONFIG[theme] || TACTICAL_THEME_CONFIG.crimson;

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-label="Taktik Harita Görünüm ve Özelleştirme"
      className="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-4 bg-black/80 backdrop-blur-md animate-fade-in"
      onClick={onClose}
    >
      <div
        className="relative w-full max-w-lg bg-[#0A0608] border border-[#2A1016] rounded-2xl shadow-[0_24px_60px_rgba(0,0,0,0.95)] overflow-hidden flex flex-col max-h-[90vh]"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Modal Header */}
        <div className="flex items-center justify-between px-4 py-3 border-b border-[#1E0B11] bg-[#0E070A]">
          <div className="flex items-center gap-2">
            <span className="text-base">🎛️</span>
            <div>
              <h2 className="text-xs font-black tracking-wider text-[#FAF2EE] uppercase">
                GÖRÜNÜM & ÖZELLEŞTİRME
              </h2>
              <p className="text-[10px] text-[#8E7E81]">
                Taktik stüdyo teması, ızgara sıklığı, radar netliği ve HUD katmanları
              </p>
            </div>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="w-7 h-7 rounded-lg bg-[#140A0D] hover:bg-[#2A1016] text-[#8E7E81] hover:text-white flex items-center justify-center transition-colors border border-[#241116]"
            aria-label="Görünüm Ayarlarını Kapat"
          >
            <IconClose size={14} />
          </button>
        </div>

        {/* Modal Content Scroll */}
        <div className="flex-1 overflow-y-auto p-4 space-y-4">
          {/* 1. Tactical Theme Presets */}
          <section className="space-y-2">
            <div className="flex items-center justify-between">
              <span className="text-[10px] font-black uppercase tracking-wider text-[#8E7E81]">
                1. Vurgu Teması & Espor Paleti
              </span>
              <span
                className="text-[9.5px] font-bold px-2 py-0.5 rounded-full border"
                style={{
                  color: currentTheme.primary,
                  borderColor: currentTheme.border,
                  backgroundColor: `${currentTheme.primary}1A`,
                }}
              >
                {currentTheme.name}
              </span>
            </div>

            <div className="grid grid-cols-2 sm:grid-cols-3 gap-2">
              {Object.values(TACTICAL_THEME_CONFIG).map((t) => {
                const isSelected = t.id === theme;
                return (
                  <button
                    key={t.id}
                    type="button"
                    onClick={() => onSelectTheme(t.id)}
                    className={`p-2 rounded-xl border text-left transition-all relative overflow-hidden flex flex-col gap-1 active:scale-98 ${
                      isSelected
                        ? 'border-[#FAF2EE] shadow-md'
                        : 'border-[#1E0B11] hover:border-[#3C141E] bg-[#0E070A]'
                    }`}
                    style={{
                      background: isSelected ? t.sampleBg : undefined,
                    }}
                  >
                    <div className="flex items-center justify-between w-full">
                      <div
                        className="w-3.5 h-3.5 rounded-full shadow-sm"
                        style={{ backgroundColor: t.primary }}
                      />
                      <span className="text-[8.5px] font-mono opacity-60 text-[#FAF2EE]">
                        {t.badge}
                      </span>
                    </div>
                    <span className="text-[11px] font-extrabold text-[#FAF2EE] leading-tight mt-0.5">
                      {t.name}
                    </span>
                  </button>
                );
              })}
            </div>
          </section>

          {/* 2. Tactical Grid Mode */}
          <section className="space-y-2">
            <span className="text-[10px] font-black uppercase tracking-wider text-[#8E7E81]">
              2. Koordinat Izgara Yoğunluğu
            </span>
            <div className="grid grid-cols-3 gap-2">
              {[
                { id: 'standard', label: 'Standart (60px)', desc: 'Espor turnuva standardı' },
                { id: 'dense', label: 'Yoğun (30px)', desc: 'Mikro strateji kılavuzu' },
                { id: 'none', label: 'Saf Radar', desc: 'Minimalist ızgarasız' },
              ].map((g) => {
                const isSelected = gridMode === g.id;
                return (
                  <button
                    key={g.id}
                    type="button"
                    onClick={() => onSelectGridMode(g.id as TacticalGridMode)}
                    className={`p-2 rounded-xl border text-left transition-all ${
                      isSelected
                        ? 'bg-[#180C10] border-[#FF4655] shadow-xs'
                        : 'bg-[#0E070A] text-[#8E7E81] hover:text-[#FAF2EE] border-[#1E0B11]'
                    }`}
                  >
                    <span
                      className={`text-[11px] font-black block leading-tight ${
                        isSelected ? 'text-[#FAF2EE]' : 'text-[#8E7E81]'
                      }`}
                    >
                      {g.label}
                    </span>
                    <span className="text-[9px] opacity-70 block mt-0.5 leading-snug">
                      {g.desc}
                    </span>
                  </button>
                );
              })}
            </div>
          </section>

          {/* 3. Radar Visual Filter (Contrast & Night Mode) */}
          <section className="space-y-2">
            <span className="text-[10px] font-black uppercase tracking-wider text-[#8E7E81]">
              3. Radar Netlik & Görüş Filtresi
            </span>
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
              {[
                { id: 'normal', label: 'Doğal Espor', icon: '☀️' },
                { id: 'high-contrast', label: 'Yüksek Kontrast', icon: '👁️' },
                { id: 'oled-dark', label: 'OLED Gece', icon: '🌑' },
                { id: 'tactical-thermal', label: 'Termal Görüş', icon: '🌡️' },
              ].map((f) => {
                const isSelected = radarFilter === f.id;
                return (
                  <button
                    key={f.id}
                    type="button"
                    onClick={() => onSelectRadarFilter(f.id as TacticalRadarFilter)}
                    className={`p-2 rounded-xl border text-center transition-all ${
                      isSelected
                        ? 'bg-[#180C10] border-[#00F0FF] text-[#FAF2EE] shadow-[0_0_10px_rgba(0,240,255,0.2)]'
                        : 'bg-[#0E070A] text-[#8E7E81] hover:text-[#FAF2EE] border-[#1E0B11]'
                    }`}
                  >
                    <span className="text-sm block mb-0.5">{f.icon}</span>
                    <span className="text-[10px] font-black block">{f.label}</span>
                  </button>
                );
              })}
            </div>
          </section>

          {/* 4. HUD Overlays & Interface Toggles */}
          <section className="space-y-2">
            <span className="text-[10px] font-black uppercase tracking-wider text-[#8E7E81]">
              4. HUD & Arayüz Katmanları
            </span>
            <div className="grid grid-cols-2 gap-2">
              {[
                {
                  id: 'callouts',
                  label: 'Bölge İsimleri (Calloutlar)',
                  active: showCallouts,
                  toggle: onToggleCallouts,
                  icon: '🏷️',
                },
                {
                  id: 'compass',
                  label: 'Pusula & Başlık HUD',
                  active: showCompassHud,
                  toggle: onToggleCompassHud,
                  icon: '🧭',
                },
                {
                  id: 'zoomDock',
                  label: 'Dikey Zoom Sidebarı',
                  active: showZoomDock,
                  toggle: onToggleZoomDock,
                  icon: '🔍',
                },
                {
                  id: 'telemetry',
                  label: 'Alt Telemetri & Aşama',
                  active: showCoordinatesHud,
                  toggle: onToggleCoordinatesHud,
                  icon: '📊',
                },
              ].map((item) => (
                <button
                  key={item.id}
                  type="button"
                  onClick={item.toggle}
                  className={`p-2.5 rounded-xl border flex items-center justify-between text-left transition-all ${
                    item.active
                      ? 'bg-[#180C10] border-[#8F1622] text-[#FAF2EE]'
                      : 'bg-[#0E070A] border-[#1E0B11] text-[#8E7E81] opacity-70'
                  }`}
                >
                  <div className="flex items-center gap-1.5 min-w-0">
                    <span className="text-xs">{item.icon}</span>
                    <span className="text-[10px] font-bold truncate">{item.label}</span>
                  </div>
                  <span
                    className={`w-4 h-4 rounded-full flex items-center justify-center text-[9px] font-black ${
                      item.active ? 'bg-[#C82333] text-white' : 'bg-[#241116] text-[#8E7E81]'
                    }`}
                  >
                    {item.active ? '✓' : '✕'}
                  </span>
                </button>
              ))}
            </div>
          </section>

          {/* 5. UI Layout Density */}
          <section className="space-y-2">
            <span className="text-[10px] font-black uppercase tracking-wider text-[#8E7E81]">
              5. Çalışma Alanı Yoğunluğu
            </span>
            <div className="grid grid-cols-2 gap-2">
              {[
                {
                  id: 'comfortable',
                  label: 'Rahat Stüdyo',
                  desc: 'Geniş paneller ve büyük butonlar',
                  icon: '🖥️',
                },
                {
                  id: 'compact',
                  label: 'Pro Kompakt',
                  desc: 'Maksimum harita görüş alanı',
                  icon: '🗜️',
                },
              ].map((d) => {
                const isSelected = uiDensity === d.id;
                return (
                  <button
                    key={d.id}
                    type="button"
                    onClick={() => onSelectUiDensity(d.id as TacticalUiDensity)}
                    className={`p-2 rounded-xl border flex items-center gap-2 text-left transition-all ${
                      isSelected
                        ? 'bg-[#180C10] border-[#FF4655] text-[#FAF2EE] shadow-xs'
                        : 'bg-[#0E070A] text-[#8E7E81] hover:text-[#FAF2EE] border-[#1E0B11]'
                    }`}
                  >
                    <span className="text-base">{d.icon}</span>
                    <div>
                      <span className="text-[10.5px] font-black block leading-tight">
                        {d.label}
                      </span>
                      <span className="text-[9px] opacity-70 block leading-tight mt-0.5">
                        {d.desc}
                      </span>
                    </div>
                  </button>
                );
              })}
            </div>
          </section>
        </div>

        {/* Modal Footer */}
        <div className="px-4 py-3 border-t border-[#1E0B11] bg-[#0E070A] flex items-center justify-between">
          <button
            type="button"
            onClick={onResetDefaults}
            className="text-[10px] font-bold text-[#F08C96] hover:text-white transition-colors"
          >
            ⟲ Varsayılanlara Sıfırla
          </button>
          <button
            type="button"
            onClick={onClose}
            aria-label="Görünüm Ayarlarını Onayla"
            className="h-8 px-5 rounded-xl text-white text-xs font-black transition-all shadow-md active:scale-95"
            style={{
              backgroundColor: currentTheme.primary,
              boxShadow: `0 0 14px ${currentTheme.glow}`,
            }}
          >
            Tamam
          </button>
        </div>
      </div>
    </div>
  );
};
