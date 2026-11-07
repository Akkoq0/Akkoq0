// ─────────────────────────────────────────────────────────
// Meva HUD — Luminous Executive Visual Primitives
// ─────────────────────────────────────────────────────────
//   • OperatorAvatar — warm bespoke velvet-gradient monogram
//   • SignalBars     — burgundy-to-champagne gradient meter
//   • FluidWave      — silky multi-stop aurora ribbon wave

import { memo, useId } from 'react';
import type { UserStatus } from '@/types';

const STATUS_DOT: Record<UserStatus, string> = {
  'in-game': 'bg-[#C82333]',
  online: 'bg-[#E04856]',
  idle: 'bg-[#7A6B6E]',
  dnd: 'bg-[#8F1622]',
  offline: 'bg-[#3D3235]',
};

const AVATAR_TONES = [
  'from-[#3B1018] via-[#1C0A0E] to-[#0C0809]',
  'from-[#330E15] via-[#19090D] to-[#0B0809]',
  'from-[#40111B] via-[#1E0A10] to-[#0C080A]',
  'from-[#2E0D14] via-[#17090C] to-[#0B0708]',
  'from-[#380F17] via-[#1A090D] to-[#0B0809]',
] as const;

function pickAvatarTone(name: string): string {
  let hash = 0;
  for (let i = 0; i < name.length; i++) {
    hash = (hash * 31 + name.charCodeAt(i)) >>> 0;
  }
  return AVATAR_TONES[hash % AVATAR_TONES.length];
}

const AVATAR_SIZE = {
  xs: 'w-5 h-5 text-[9px] rounded-md',
  sm: 'w-7 h-7 text-[11px] rounded-lg',
  md: 'w-9 h-9 text-[13px] rounded-xl',
  lg: 'w-12 h-12 text-base rounded-xl',
} as const;

const DOT_SIZE = {
  xs: 'w-1.5 h-1.5',
  sm: 'w-2 h-2',
  md: 'w-2.5 h-2.5',
  lg: 'w-3 h-3',
} as const;

interface OperatorAvatarProps {
  name: string;
  status?: UserStatus;
  size?: keyof typeof AVATAR_SIZE;
  speaking?: boolean;
}

export const OperatorAvatar = memo(function OperatorAvatar({
  name,
  status,
  size = 'md',
  speaking = false,
}: OperatorAvatarProps) {
  const initials = name.trim().slice(0, 2).toUpperCase() || 'OP';
  const tone = pickAvatarTone(name);

  return (
    <span className={`relative inline-flex flex-shrink-0 ${AVATAR_SIZE[size]}`}>
      <span
        className={`rounded-[inherit] w-full h-full flex items-center justify-center font-bold tracking-tight text-[#F4EFF0] bg-gradient-to-br ${tone} border transition-[border-color,box-shadow] duration-200 ${
          speaking
            ? 'border-[#DC3545] shadow-[0_0_0_2px_rgba(200,35,51,0.25),0_0_14px_-2px_rgba(200,35,51,0.65)]'
            : 'border-[#3D1820]'
        }`}
      >
        {initials}
      </span>
      {status && (
        <span
          aria-hidden
          className={`absolute -bottom-0.5 -right-0.5 rounded-full ring-2 ring-[#0B0809] ${DOT_SIZE[size]} ${STATUS_DOT[status]}`}
        />
      )}
    </span>
  );
});

export const SignalBars = memo(function SignalBars({ score }: { score: number }) {
  const level = Math.max(1, Math.ceil(score / 25));
  const tone =
    score >= 80
      ? 'bg-gradient-to-t from-[#7A121D] to-[#D63344]'
      : score >= 50
        ? 'bg-gradient-to-t from-[#630F18] to-[#B02030]'
        : 'bg-gradient-to-t from-[#4D0B12] to-[#8F1622]';

  return (
    <span
      role="img"
      aria-label={`Bağlantı kalitesi %${score}`}
      className="inline-flex items-end gap-[2px] h-3"
    >
      {[1, 2, 3, 4].map((i) => (
        <span
          key={i}
          className={`w-[3px] rounded-[1px] ${i <= level ? tone : 'bg-[#2E181F]'}`}
          style={{ height: `${i * 25}%` }}
        />
      ))}
    </span>
  );
});

// ── Luminous Ribbon Fluid Wave ─────────────────────────────

const WAVE_W = 120;
const WAVE_H = 32;

function buildWavePath(amplitude: number, wavelength: number, phase = 0): string {
  const mid = WAVE_H / 2;
  let d = '';
  for (let x = 0; x <= WAVE_W * 2; x += 2) {
    const y = mid + amplitude * Math.sin((x / wavelength) * Math.PI * 2 + phase);
    d += `${x === 0 ? 'M' : 'L'}${x} ${y.toFixed(2)} `;
  }
  return d.trim();
}

function buildWaveArea(amplitude: number, wavelength: number, phase = 0): string {
  const line = buildWavePath(amplitude, wavelength, phase);
  const mid = WAVE_H / 2;
  return `${line} L${WAVE_W * 2} ${mid} L0 ${mid} Z`;
}

// Wavelengths divide WAVE_W (120) evenly for seamless infinite loop
const PRIMARY_WAVE = buildWavePath(11, 40);
const PRIMARY_AREA = buildWaveArea(11, 40);
const SECONDARY_WAVE = buildWavePath(7.5, 30, 1.35);

interface FluidWaveProps {
  /** 0–1 primary vocal harmonic amplitude (FFT low-mid band) */
  level: number;
  /** Optional 0–1 secondary presence harmonic amplitude (FFT 2kHz–6kHz band) */
  secondaryLevel?: number;
  /** Animate the flow (speaking / playing) */
  active: boolean;
  muted?: boolean;
  className?: string;
  /** Seconds per loop for the primary wave */
  speed?: number;
}

export const FluidWave = memo(function FluidWave({
  level,
  secondaryLevel,
  active,
  muted = false,
  className = '',
  speed = 1.4,
}: FluidWaveProps) {
  const uid = useId().replace(/:/g, '');
  const strokeId = `wave-stroke-${uid}`;
  const areaId = `wave-area-${uid}`;
  const fadeId = `wave-fade-${uid}`;
  const maskId = `wave-mask-${uid}`;

  const primaryScale = muted
    ? 0
    : active
      ? Math.max(0.18, Math.min(1, level))
      : 0.07;
  const secondaryScale = muted
    ? 0
    : active
      ? Math.max(
          0.14,
          Math.min(1, secondaryLevel !== undefined ? secondaryLevel : level * 0.86),
        )
      : 0.06;

  return (
    <svg
      viewBox={`0 0 ${WAVE_W} ${WAVE_H}`}
      preserveAspectRatio="none"
      className={className}
      aria-hidden
    >
      <defs>
        <linearGradient
          id={strokeId}
          gradientUnits="userSpaceOnUse"
          x1="0"
          y1="0"
          x2="60"
          y2="0"
          spreadMethod="reflect"
        >
          <stop offset="0%" stopColor="#6E111B" />
          <stop offset="50%" stopColor="#C82333" />
          <stop offset="100%" stopColor="#E34B5A" />
        </linearGradient>

        <linearGradient id={areaId} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#C82333" stopOpacity="0.26" />
          <stop offset="60%" stopColor="#6E111B" stopOpacity="0.08" />
          <stop offset="100%" stopColor="#090708" stopOpacity="0" />
        </linearGradient>

        <linearGradient id={fadeId} x1="0" y1="0" x2="1" y2="0">
          <stop offset="0%" stopColor="#fff" stopOpacity="0" />
          <stop offset="12%" stopColor="#fff" stopOpacity="1" />
          <stop offset="88%" stopColor="#fff" stopOpacity="1" />
          <stop offset="100%" stopColor="#fff" stopOpacity="0" />
        </linearGradient>

        <mask id={maskId}>
          <rect width={WAVE_W} height={WAVE_H} fill={`url(#${fadeId})`} />
        </mask>
      </defs>

      <line
        x1="0"
        y1={WAVE_H / 2}
        x2={WAVE_W}
        y2={WAVE_H / 2}
        stroke={muted ? '#B3222C' : '#3B242B'}
        strokeOpacity={muted ? 0.72 : 0.85}
        strokeWidth="1"
        vectorEffect="non-scaling-stroke"
      />

      <g mask={`url(#${maskId})`}>
        {/* Secondary Silk Harmonic (Presence Band 2kHz–6kHz) */}
        <g
          style={{
            transform: `scaleY(${secondaryScale})`,
            transformOrigin: 'center',
            transformBox: 'view-box',
            transition: 'transform 160ms cubic-bezier(0.22, 1, 0.36, 1)',
          }}
        >
          <g>
            <path
              d={SECONDARY_WAVE}
              fill="none"
              stroke={`url(#${strokeId})`}
              strokeOpacity="0.48"
              strokeWidth="1.3"
              strokeLinecap="round"
              vectorEffect="non-scaling-stroke"
            />
            {active && !muted && (
              <animateTransform
                attributeName="transform"
                type="translate"
                from="0 0"
                to={`-${WAVE_W} 0`}
                dur={`${speed * 1.65}s`}
                repeatCount="indefinite"
              />
            )}
          </g>
        </g>

        {/* Primary Ribbon Glow + Crest (Vocal Fundamental Band 180Hz–1.8kHz) */}
        <g
          style={{
            transform: `scaleY(${primaryScale})`,
            transformOrigin: 'center',
            transformBox: 'view-box',
            transition: 'transform 140ms cubic-bezier(0.22, 1, 0.36, 1)',
          }}
        >
          <g>
            <path d={PRIMARY_AREA} fill={`url(#${areaId})`} />
            <path
              d={PRIMARY_WAVE}
              fill="none"
              stroke={`url(#${strokeId})`}
              strokeWidth="1.85"
              strokeLinecap="round"
              vectorEffect="non-scaling-stroke"
            />
            {active && !muted && (
              <animateTransform
                attributeName="transform"
                type="translate"
                from="0 0"
                to={`-${WAVE_W} 0`}
                dur={`${speed}s`}
                repeatCount="indefinite"
              />
            )}
          </g>
        </g>
      </g>
    </svg>
  );
});
