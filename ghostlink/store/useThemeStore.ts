// ─────────────────────────────────────────────────────────
// Meva HUD — Industrial Command Theme Engine (Hardened)
// ─────────────────────────────────────────────────────────
// Zero-re-render CSS custom properties on documentElement,
// strict HTTPS URL sanitization (prevents CSS url() injection),
// and safe localStorage hydration.

import { create } from 'zustand';

export type ThemePreset =
  | 'ghost-cyberpunk'
  | 'velvet-copper'
  | 'ares-crimson'
  | 'oled-stealth';

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
  secondaryAccent: string;
  border: string;
  textPrimary: string;
  textSecondary: string;
  textMuted: string;
  glowColor: string;
  secondaryGlow: string;
}

export const THEME_PRESETS: Record<ThemePreset, ThemeColors> = {
  'ghost-cyberpunk': {
    name: 'Obsidian & Deep Burgundy',
    tagline: 'Saf siyah zemin üzerinde hafif ve dengeli koyu bordo geçiş',
    bgDarkest: '#070607',
    bgDark: '#0D090B',
    bgMid: '#1C0B10',
    bgPanel: 'rgba(14, 9, 11, 0.82)',
    bgHover: 'rgba(148, 22, 36, 0.12)',
    bgActive: 'rgba(148, 22, 36, 0.20)',
    accent: '#C82333',
    accentHover: '#DC3545',
    secondaryAccent: '#8F1622',
    border: 'rgba(136, 26, 38, 0.24)',
    textPrimary: '#F4EFF0',
    textSecondary: '#B8AAAC',
    textMuted: '#827376',
    glowColor: 'rgba(128, 18, 30, 0.22)',
    secondaryGlow: 'rgba(84, 12, 20, 0.14)',
  },
  'velvet-copper': {
    name: 'Midnight & Bordeaux',
    tagline: 'Gece siyahı ile yumuşak şarap bordosu ton geçişi',
    bgDarkest: '#080608',
    bgDark: '#100A0D',
    bgMid: '#210C14',
    bgPanel: 'rgba(16, 10, 13, 0.82)',
    bgHover: 'rgba(156, 24, 44, 0.12)',
    bgActive: 'rgba(156, 24, 44, 0.20)',
    accent: '#C9263E',
    accentHover: '#DE3B53',
    secondaryAccent: '#8A1729',
    border: 'rgba(142, 28, 46, 0.24)',
    textPrimary: '#F5EFF1',
    textSecondary: '#BBA9AF',
    textMuted: '#857379',
    glowColor: 'rgba(132, 20, 38, 0.22)',
    secondaryGlow: 'rgba(88, 14, 26, 0.14)',
  },
  'ares-crimson': {
    name: 'Charcoal & Dark Crimson',
    tagline: 'Koyu antrasit siyah ve hafif kızıl-bordo derinlik',
    bgDarkest: '#090708',
    bgDark: '#110B0D',
    bgMid: '#230D12',
    bgPanel: 'rgba(17, 11, 13, 0.82)',
    bgHover: 'rgba(168, 26, 38, 0.12)',
    bgActive: 'rgba(168, 26, 38, 0.20)',
    accent: '#D12838',
    accentHover: '#E33E4E',
    secondaryAccent: '#961A26',
    border: 'rgba(148, 30, 42, 0.25)',
    textPrimary: '#F5F0F1',
    textSecondary: '#BCADAF',
    textMuted: '#867779',
    glowColor: 'rgba(142, 22, 34, 0.24)',
    secondaryGlow: 'rgba(92, 14, 22, 0.15)',
  },
  'oled-stealth': {
    name: 'Pure Black & Subtle Oxblood',
    tagline: 'Tam siyah zemin ve çok hafif bordo gölge geçişi',
    bgDarkest: '#040405',
    bgDark: '#0A0708',
    bgMid: '#16090D',
    bgPanel: 'rgba(10, 7, 8, 0.86)',
    bgHover: 'rgba(136, 20, 32, 0.12)',
    bgActive: 'rgba(136, 20, 32, 0.18)',
    accent: '#B81F2E',
    accentHover: '#CC2E3D',
    secondaryAccent: '#7D131E',
    border: 'rgba(118, 22, 32, 0.22)',
    textPrimary: '#F2EDEE',
    textSecondary: '#B2A4A6',
    textMuted: '#7A6C6F',
    glowColor: 'rgba(110, 16, 26, 0.18)',
    secondaryGlow: 'rgba(68, 10, 16, 0.12)',
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
  const safeOpacity = clamp(opacity, 0.45, 0.96, 0.82);
  const safeBlur = clamp(blur, 0, 28, 16);
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
  root.style.setProperty('--ghost-bronze', theme.secondaryAccent);
  root.style.setProperty('--ghost-border', theme.border);
  root.style.setProperty('--ghost-text-primary', theme.textPrimary);
  root.style.setProperty('--ghost-text-secondary', theme.textSecondary);
  root.style.setProperty('--ghost-text-muted', theme.textMuted);
  root.style.setProperty('--ghost-glow', theme.glowColor);
  root.style.setProperty('--ghost-glow-secondary', theme.secondaryGlow);
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
  glassOpacity: 0.82,
  blurIntensity: 16,
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
    const safeOpacity = clamp(opacity, 0.45, 0.96, 0.82);
    set({ glassOpacity: safeOpacity });
    const { currentTheme, blurIntensity, customWallpaper } = get();
    applyThemeToDOM(currentTheme, safeOpacity, blurIntensity, customWallpaper);
    try {
      localStorage.setItem('ghost_opacity_v3', safeOpacity.toString());
    } catch {}
  },

  setBlurIntensity: (blur) => {
    const safeBlur = clamp(blur, 0, 28, 16);
    set({ blurIntensity: safeBlur });
    const { currentTheme, glassOpacity, customWallpaper } = get();
    applyThemeToDOM(currentTheme, glassOpacity, safeBlur, customWallpaper);
    try {
      localStorage.setItem('ghost_blur_v3', safeBlur.toString());
    } catch {}
  },

  setShowThemeModal: (show) => set({ showThemeModal: show }),

  applyCSSVariables: () => {
    let { currentTheme, glassOpacity, blurIntensity, customWallpaper } = get();

    if (typeof window !== 'undefined') {
      try {
        const storedTheme = localStorage.getItem('ghost_theme');
        const storedOpacity = localStorage.getItem('ghost_opacity_v3');
        const storedBlur = localStorage.getItem('ghost_blur_v3');
        const storedWallpaper = localStorage.getItem('ghost_wallpaper');

        if (isThemePreset(storedTheme)) currentTheme = storedTheme;
        if (storedOpacity !== null) {
          glassOpacity = clamp(parseFloat(storedOpacity), 0.45, 0.96, 0.82);
        }
        if (storedBlur !== null) {
          blurIntensity = clamp(parseFloat(storedBlur), 0, 28, 16);
        }
        customWallpaper = sanitizeWallpaperUrl(storedWallpaper);

        set({ currentTheme, glassOpacity, blurIntensity, customWallpaper });
      } catch {}
    }

    applyThemeToDOM(currentTheme, glassOpacity, blurIntensity, customWallpaper);
  },
}));
