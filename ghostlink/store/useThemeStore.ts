// ─────────────────────────────────────────────────────────
// Meva HUD — Industrial Command Theme Engine (Hardened)
// ─────────────────────────────────────────────────────────
// Zero-re-render CSS custom properties on documentElement,
// strict HTTPS URL sanitization (prevents CSS url() injection),
// and safe localStorage hydration.

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
    tagline: 'Fırçalanmış Koyu Titanyum (#06070A) & Mat Kan Kırmızısı (#EF4444)',
    bgDarkest: '#06070A',
    bgDark: '#0C0E14',
    bgMid: '#12151E',
    bgPanel: 'rgba(12, 14, 20, 0.95)',
    bgHover: 'rgba(239, 68, 68, 0.07)',
    bgActive: 'rgba(239, 68, 68, 0.12)',
    accent: '#EF4444',
    accentHover: '#F87171',
    border: 'rgba(255, 255, 255, 0.06)',
    textPrimary: '#F3F4F6',
    textSecondary: '#9CA3AF',
    textMuted: '#64748B',
    glowColor: 'rgba(239, 68, 68, 0.16)',
  },
  'ares-crimson': {
    name: 'Amber Ordinance',
    tagline: 'Mat Espor Grisi (#07080B) & Taktiksel Kehribar (#F59E0B)',
    bgDarkest: '#07080B',
    bgDark: '#0E1015',
    bgMid: '#151820',
    bgPanel: 'rgba(14, 16, 21, 0.95)',
    bgHover: 'rgba(245, 158, 11, 0.07)',
    bgActive: 'rgba(245, 158, 11, 0.12)',
    accent: '#F59E0B',
    accentHover: '#FBBF24',
    border: 'rgba(255, 255, 255, 0.06)',
    textPrimary: '#F4F4F5',
    textSecondary: '#A1A1AA',
    textMuted: '#71717A',
    glowColor: 'rgba(245, 158, 11, 0.16)',
  },
  'oled-stealth': {
    name: 'Carbon Monolith',
    tagline: 'Derin Karbon (#040507) & Otoriter Kırmızı (#DC2626)',
    bgDarkest: '#040507',
    bgDark: '#0A0B0F',
    bgMid: '#111319',
    bgPanel: 'rgba(10, 11, 15, 0.97)',
    bgHover: 'rgba(220, 38, 38, 0.07)',
    bgActive: 'rgba(220, 38, 38, 0.12)',
    accent: '#DC2626',
    accentHover: '#EF4444',
    border: 'rgba(255, 255, 255, 0.06)',
    textPrimary: '#E5E7EB',
    textSecondary: '#9CA3AF',
    textMuted: '#6B7280',
    glowColor: 'rgba(220, 38, 38, 0.16)',
  },
};

const UNSAFE_CSS_URL_CHARS = /[\s"'()\\;<>`]/;

/**
 * Strictly validates external wallpaper URLs to prevent CSS url() injection
 * and insecure cleartext HTTP fetches.
 */
export function sanitizeWallpaperUrl(raw: string | null | undefined): string | null {
  if (!raw) return null;
  const trimmed = raw.trim();
  if (!trimmed || trimmed.length > 512 || UNSAFE_CSS_URL_CHARS.test(trimmed)) {
    return null;
  }
  try {
    const parsed = new URL(trimmed);
    if (parsed.protocol !== 'https:') return null;
    return parsed.href;
  } catch {
    return null;
  }
}

function clamp(value: number, min: number, max: number, fallback: number): number {
  if (!Number.isFinite(value)) return fallback;
  return Math.min(max, Math.max(min, value));
}

function isThemePreset(val: string | null): val is ThemePreset {
  return Boolean(val && Object.prototype.hasOwnProperty.call(THEME_PRESETS, val));
}

interface ThemeState {
  currentTheme: ThemePreset;
  customWallpaper: string | null;
  glassOpacity: number;
  blurIntensity: number;
  showThemeModal: boolean;

  setTheme: (preset: ThemePreset) => void;
  setCustomWallpaper: (url: string | null) => boolean;
  setGlassOpacity: (opacity: number) => void;
  setBlurIntensity: (blur: number) => void;
  setShowThemeModal: (show: boolean) => void;
  applyCSSVariables: () => void;
}

function hexToRgbChannels(hex: string): string {
  const raw = hex.replace('#', '');
  const full =
    raw.length === 3
      ? raw
          .split('')
          .map((c) => c + c)
          .join('')
      : raw;
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
  const theme = THEME_PRESETS[preset] ?? THEME_PRESETS['ghost-cyberpunk'];
  const safeOpacity = clamp(opacity, 0.5, 1, 0.96);
  const safeBlur = clamp(blur, 0, 24, 6);
  const safeWallpaper = sanitizeWallpaperUrl(wallpaper);

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
  root.style.setProperty('--ghost-glass-opacity', safeOpacity.toString());
  root.style.setProperty('--ghost-glass-blur', `${safeBlur}px`);

  if (safeWallpaper) {
    root.style.setProperty('--ghost-wallpaper', `url("${safeWallpaper}")`);
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
    if (!isThemePreset(preset)) return;
    set({ currentTheme: preset });
    const { glassOpacity, blurIntensity, customWallpaper } = get();
    applyThemeToDOM(preset, glassOpacity, blurIntensity, customWallpaper);
    try {
      localStorage.setItem('ghost_theme', preset);
    } catch {}
  },

  setCustomWallpaper: (url) => {
    if (!url || !url.trim()) {
      set({ customWallpaper: null });
      const { currentTheme, glassOpacity, blurIntensity } = get();
      applyThemeToDOM(currentTheme, glassOpacity, blurIntensity, null);
      try {
        localStorage.removeItem('ghost_wallpaper');
      } catch {}
      return true;
    }

    const safe = sanitizeWallpaperUrl(url);
    if (!safe) return false;

    set({ customWallpaper: safe });
    const { currentTheme, glassOpacity, blurIntensity } = get();
    applyThemeToDOM(currentTheme, glassOpacity, blurIntensity, safe);
    try {
      localStorage.setItem('ghost_wallpaper', safe);
    } catch {}
    return true;
  },

  setGlassOpacity: (opacity) => {
    const safeOpacity = clamp(opacity, 0.5, 1, 0.96);
    set({ glassOpacity: safeOpacity });
    const { currentTheme, blurIntensity, customWallpaper } = get();
    applyThemeToDOM(currentTheme, safeOpacity, blurIntensity, customWallpaper);
    try {
      localStorage.setItem('ghost_opacity', safeOpacity.toString());
    } catch {}
  },

  setBlurIntensity: (blur) => {
    const safeBlur = clamp(blur, 0, 24, 6);
    set({ blurIntensity: safeBlur });
    const { currentTheme, glassOpacity, customWallpaper } = get();
    applyThemeToDOM(currentTheme, glassOpacity, safeBlur, customWallpaper);
    try {
      localStorage.setItem('ghost_blur', safeBlur.toString());
    } catch {}
  },

  setShowThemeModal: (show) => set({ showThemeModal: show }),

  applyCSSVariables: () => {
    let { currentTheme, glassOpacity, blurIntensity, customWallpaper } = get();

    if (typeof window !== 'undefined') {
      try {
        const storedTheme = localStorage.getItem('ghost_theme');
        const storedOpacity = localStorage.getItem('ghost_opacity');
        const storedBlur = localStorage.getItem('ghost_blur');
        const storedWallpaper = localStorage.getItem('ghost_wallpaper');

        if (isThemePreset(storedTheme)) currentTheme = storedTheme;
        if (storedOpacity !== null) {
          glassOpacity = clamp(parseFloat(storedOpacity), 0.5, 1, 0.96);
        }
        if (storedBlur !== null) {
          blurIntensity = clamp(parseFloat(storedBlur), 0, 24, 6);
        }
        customWallpaper = sanitizeWallpaperUrl(storedWallpaper);

        set({ currentTheme, glassOpacity, blurIntensity, customWallpaper });
      } catch {}
    }

    applyThemeToDOM(currentTheme, glassOpacity, blurIntensity, customWallpaper);
  },
}));
