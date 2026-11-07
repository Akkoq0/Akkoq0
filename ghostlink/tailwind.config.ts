import path from 'path';
import type { Config } from 'tailwindcss';

// Modern humanist sans stack. `mono` intentionally maps to the same stack so
// no typewriter/code face can leak into the executive interface.
const EXECUTIVE_SANS = [
  'Inter',
  '"Plus Jakarta Sans"',
  'ui-sans-serif',
  'system-ui',
  '-apple-system',
  '"Segoe UI"',
  'Roboto',
  '"Helvetica Neue"',
  'Arial',
  'sans-serif',
];

const config: Config = {
  content: [
    path.join(__dirname, 'app/**/*.{ts,tsx}'),
    path.join(__dirname, 'components/**/*.{ts,tsx}'),
    path.join(__dirname, 'store/**/*.{ts,tsx}'),
    path.join(__dirname, 'hooks/**/*.{ts,tsx}'),
    path.join(__dirname, 'src/**/*.{ts,tsx}'),
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: EXECUTIVE_SANS,
        mono: EXECUTIVE_SANS,
      },
      colors: {
        // Deep Espresso & Oxblood Burgundy executive palette
        espresso: {
          950: '#0B0708',
          900: '#130C0E',
          800: '#1C1215',
          700: '#2A1A1E',
          600: '#382328',
        },
        wine: {
          DEFAULT: '#9E1B24',
          bright: '#E12D39',
        },
        bronze: {
          DEFAULT: '#8F1622',
          light: '#E35D6A',
        },
        cream: '#F4EFF0',
        sand: '#8E7F83',
        gl: {
          'bg-darkest': 'var(--ghost-bg-darkest, #070607)',
          'bg-dark': 'var(--ghost-bg-dark, #0D090B)',
          'bg-mid': 'var(--ghost-bg-mid, #1C0B10)',
          'bg-panel': 'var(--ghost-bg-panel, rgba(14, 9, 11, 0.82))',
          'bg-hover': 'var(--ghost-bg-hover, rgba(148, 22, 36, 0.12))',
          'bg-active': 'var(--ghost-bg-active, rgba(148, 22, 36, 0.20))',
          accent: 'rgb(var(--ghost-accent-rgb, 200 35 51) / <alpha-value>)',
          'accent-hover': 'var(--ghost-accent-hover, #DC3545)',
          'text-primary': 'var(--ghost-text-primary, #F4EFF0)',
          'text-secondary': 'var(--ghost-text-secondary, #B8AAAC)',
          'text-muted': 'var(--ghost-text-muted, #827376)',
          'text-bright': 'var(--ghost-text-primary, #F4EFF0)',
          'text-normal': 'var(--ghost-text-secondary, #B8AAAC)',
          border: 'var(--ghost-border, rgba(136, 26, 38, 0.24))',
          // Semantic accents — pure Matte Black & Deep Burgundy
          emerald: '#C82333',
          amber: '#8F1622',
          crimson: '#C82333',
          success: '#C82333',
          danger: '#E12D39',
          warning: '#8F1622',
          online: '#C82333',
          idle: '#7A6B6E',
          dnd: '#9E1B24',
          'voice-active':
            'rgb(var(--ghost-accent-rgb, 200 35 51) / <alpha-value>)',
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
