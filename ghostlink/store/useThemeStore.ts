// ─────────────────────────────────────────────────────────
// Meva HUD — Industrial Command Theme Engine
// ─────────────────────────────────────────────────────────
// Zero-re-render CSS custom properties on documentElement.
// Palette philosophy: Brushed dark titanium (#050608 / #0C0E12)
// with Matte Blood Crimson (#EF4444) & Tactical Amber (#F59E0B).

import { create } from 'zustand';

export type ThemePreset = 'ghost-cyberpunk' | 'ares-crimson' | 'oled-stealth';

export interface ThemeColors {
  name: string;
  tagline: string;
  bgDarkest: string;
  bgDark: string;
  bgMid: string;
  bgPanel: string;
  bgHover: string;
  bgActive: string;
  accent: string;
  accentHover: string;
  border: string;
  textPrimary: string;
  textSecondary: string;
  textMuted: string;
  glowColor: string;
}

export const THEME_PRESETS: Record<ThemePreset, ThemeColors> = {
  'ghost-cyberpunk': {
    name: 'Crimson Spec-Ops',
    tagline: 'Fırçalanmış Koyu Titanyum (#060709) & Mat Kan Kırmızısı (#EF4444)',
    bgDarkest: '#060709',
    bgDark: '#0D0E12',
    bgMid: '#14161D',
    bgPanel: 'rgba(13, 14, 18, 0.94)',
    bgHover: 'rgba(239, 68, 68, 0.06)',
    bgActive: 'rgba(239, 68, 68, 0.12)',
    accent: '#EF4444',
    accentHover: '#F87171',
    border: 'rgba(255, 255, 255, 0.06)',
    textPrimary: '#F3F4F6',
    textSecondary: '#9CA3AF',
    textMuted: '#64748B',
    glowColor: 'rgba(239, 68, 68, 0.15)',
  },
  'ares-crimson': {
    name: 'Amber Ordinance',
    tagline: 'Mat Espor Grisi (#07080A) & Taktiksel Kehribar (#F59E0B)',
    bgDarkest: '#07080A',
    bgDark: '#0E1014',
    bgMid: '#15181F',
    bgPanel: 'rgba(14, 16, 20, 0.94)',
    bgHover: 'rgba(245, 158, 11, 0.06)',
    bgActive: 'rgba(245, 158, 11, 0.12)',
    accent: '#F59E0B',
    accentHover: '#FBBF24',
    border: 'rgba(255, 255, 255, 0.06)',
    textPrimary: '#F4F4F5',
    textSecondary: '#A1A1AA',
    textMuted: '#71717A',
    glowColor: 'rgba(245, 158, 11, 0.15)',
  },
  'oled-stealth': {
    name: 'Carbon Monolith',
    tagline: 'Derin Karbon (#040507) & Otoriter Kırmızı (#DC2626)',
    bgDarkest: '#040507',
    bgDark: '#0A0B0E',
    bgMid: '#111318',
    bgPanel: 'rgba(10, 11, 14, 0.96)',
    bgHover: 'rgba(220, 38, 38, 0.06)',
    bgActive: 'rgba(220, 38, 38, 0.12)',
    accent: '#DC2626',
    accentHover: '#EF4444',
    border: 'rgba(255, 255, 255, 0.06)',
    textPrimary: '#E5E7EB',
    textSecondary: '#9CA3AF',
    textMuted: '#6B7280',
    glowColor: 'rgba(220, 38, 38, 0.15)',
  },
};

interface ThemeState {
  currentTheme: ThemePreset;
  customWallpaper: string | null;
  glassOpacity: number;
  blurIntensity: number;
  showThemeModal: boolean;

  setTheme: (preset: ThemePreset) => void;
  setCustomWallpaper: (url: string | null) => void;
  setGlassOpacity: (opacity: number) => void;
  setBlurIntensity: (blur: number) => void;
  setShowThemeModal: (show: boolean) => void;
  applyCSSVariables: () => void;
}

function hexToRgbChannels(hex: string): string {
  const raw = hex.replace('#', '');
  const full = raw.length === 3 ? raw.split('').map((c) => c + c).join('') : raw;
  const n = parseInt(full, 16);
  return `${(n >> 16) & 255} ${(n >> 8) & 255} ${n & 255}`;
}

function applyThemeToDOM(
  preset: ThemePreset,
  opacity: number,
  blur: number,
  wallpaper: string | null,
) {
  if (typeof document === 'undefined') return;

  const root = document.documentElement;
  const theme = THEME_PRESETS[preset];

  root.style.setProperty('--ghost-bg-darkest', theme.bgDarkest);
  root.style.setProperty('--ghost-bg-dark', theme.bgDark);
  root.style.setProperty('--ghost-bg-mid', theme.bgMid);
  root.style.setProperty('--ghost-bg-panel', theme.bgPanel);
  root.style.setProperty('--ghost-bg-hover', theme.bgHover);
  root.style.setProperty('--ghost-bg-active', theme.bgActive);
  root.style.setProperty('--ghost-accent', theme.accent);
  root.style.setProperty('--ghost-accent-rgb', hexToRgbChannels(theme.accent));
  root.style.setProperty('--ghost-accent-hover', theme.accentHover);
  root.style.setProperty('--ghost-border', theme.border);
  root.style.setProperty('--ghost-text-primary', theme.textPrimary);
  root.style.setProperty('--ghost-text-secondary', theme.textSecondary);
  root.style.setProperty('--ghost-text-muted', theme.textMuted);
  root.style.setProperty('--ghost-glow', theme.glowColor);
  root.style.setProperty('--ghost-glass-opacity', opacity.toString());
  root.style.setProperty('--ghost-glass-blur', `${blur}px`);

  if (wallpaper) {
    root.style.setProperty('--ghost-wallpaper', `url("${wallpaper}")`);
    document.body.classList.add('has-custom-wallpaper');
  } else {
    root.style.removeProperty('--ghost-wallpaper');
    document.body.classList.remove('has-custom-wallpaper');
  }
}

export const useThemeStore = create<ThemeState>((set, get) => ({
  currentTheme: 'ghost-cyberpunk',
  customWallpaper: null,
  glassOpacity: 0.96,
  blurIntensity: 6,
  showThemeModal: false,

  setTheme: (preset) => {
    set({ currentTheme: preset });
    const { glassOpacity, blurIntensity, customWallpaper } = get();
    applyThemeToDOM(preset, glassOpacity, blurIntensity, customWallpaper);
    try {
      localStorage.setItem('ghost_theme', preset);
    } catch {}
  },

  setCustomWallpaper: (url) => {
    set({ customWallpaper: url });
    const { currentTheme, glassOpacity, blurIntensity } = get();
    applyThemeToDOM(currentTheme, glassOpacity, blurIntensity, url);
    try {
      if (url) localStorage.setItem('ghost_wallpaper', url);
      else localStorage.removeItem('ghost_wallpaper');
    } catch {}
  },

  setGlassOpacity: (opacity) => {
    set({ glassOpacity: opacity });
    const { currentTheme, blurIntensity, customWallpaper } = get();
    applyThemeToDOM(currentTheme, opacity, blurIntensity, customWallpaper);
    try {
      localStorage.setItem('ghost_opacity', opacity.toString());
    } catch {}
  },

  setBlurIntensity: (blur) => {
    set({ blurIntensity: blur });
    const { currentTheme, glassOpacity, customWallpaper } = get();
    applyThemeToDOM(currentTheme, glassOpacity, blur, customWallpaper);
    try {
      localStorage.setItem('ghost_blur', blur.toString());
    } catch {}
  },

  setShowThemeModal: (show) => set({ showThemeModal: show }),

  applyCSSVariables: () => {
    const { currentTheme, glassOpacity, blurIntensity, customWallpaper } = get();
    applyThemeToDOM(currentTheme, glassOpacity, blurIntensity, customWallpaper);
  },
}));
