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
          DEFAULT: '#C88A5B',
          light: '#E0A878',
        },
        cream: '#F5EBE6',
        sand: '#A38F8A',
        gl: {
          'bg-darkest': 'var(--ghost-bg-darkest, #0B0708)',
          'bg-dark': 'var(--ghost-bg-dark, #130C0E)',
          'bg-mid': 'var(--ghost-bg-mid, #1C1215)',
          'bg-panel': 'var(--ghost-bg-panel, rgba(19, 12, 14, 0.96))',
          'bg-hover': 'var(--ghost-bg-hover, rgba(158, 27, 36, 0.08))',
          'bg-active': 'var(--ghost-bg-active, rgba(158, 27, 36, 0.14))',
          accent: 'rgb(var(--ghost-accent-rgb, 225 45 57) / <alpha-value>)',
          'accent-hover': 'var(--ghost-accent-hover, #F0525C)',
          'text-primary': 'var(--ghost-text-primary, #F5EBE6)',
          'text-secondary': 'var(--ghost-text-secondary, #CBB8B1)',
          'text-muted': 'var(--ghost-text-muted, #A38F8A)',
          'text-bright': 'var(--ghost-text-primary, #F5EBE6)',
          'text-normal': 'var(--ghost-text-secondary, #CBB8B1)',
          border: 'var(--ghost-border, #382328)',
          // Semantic accents — no raw greens anywhere in the product
          emerald: '#C88A5B',
          amber: '#C88A5B',
          crimson: '#E12D39',
          success: '#C88A5B',
          danger: '#E12D39',
          warning: '#C88A5B',
          online: '#C88A5B',
          idle: '#7A6763',
          dnd: '#9E1B24',
          'voice-active':
            'rgb(var(--ghost-accent-rgb, 225 45 57) / <alpha-value>)',
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
