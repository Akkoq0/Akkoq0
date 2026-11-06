import type { Config } from 'tailwindcss';

const config: Config = {
  content: [
    './app/**/*.{ts,tsx}',
    './components/**/*.{ts,tsx}',
    './store/**/*.{ts,tsx}',
  ],
  theme: {
    extend: {
      colors: {
        gl: {
          'bg-darkest': 'var(--ghost-bg-darkest, #050608)',
          'bg-dark': 'var(--ghost-bg-dark, #0C0E12)',
          'bg-mid': 'var(--ghost-bg-mid, #12151C)',
          'bg-panel': 'var(--ghost-bg-panel, rgba(12, 14, 18, 0.96))',
          'bg-hover': 'var(--ghost-bg-hover, rgba(239, 68, 68, 0.06))',
          'bg-active': 'var(--ghost-bg-active, rgba(239, 68, 68, 0.12))',
          'accent': 'rgb(var(--ghost-accent-rgb, 239 68 68) / <alpha-value>)',
          'accent-hover': 'var(--ghost-accent-hover, #F87171)',
          'text-primary': 'var(--ghost-text-primary, #F3F4F6)',
          'text-secondary': 'var(--ghost-text-secondary, #9CA3AF)',
          'text-muted': 'var(--ghost-text-muted, #6B7280)',
          'text-bright': 'var(--ghost-text-primary, #F3F4F6)',
          'text-normal': 'var(--ghost-text-secondary, #9CA3AF)',
          'border': 'var(--ghost-border, rgba(255, 255, 255, 0.05))',
          // Industrial Power Accents (Emerald, Amber & Crimson)
          'emerald': '#10B981',
          'amber': '#F59E0B',
          'crimson': '#EF4444',
          'success': '#10B981',
          'danger': '#EF4444',
          'warning': '#F59E0B',
          'online': '#10B981',
          'idle': '#F59E0B',
          'dnd': '#EF4444',
          'voice-active': 'rgb(var(--ghost-accent-rgb, 239 68 68) / <alpha-value>)',
        },
      },
      fontSize: {
        xxs: '0.65rem',
      },
      opacity: {
        '12': '0.12',
        '98': '0.98',
      },
    },
  },
  plugins: [],
};

export default config;
