// ─────────────────────────────────────────────────────────
// Meva HUD — Luminous Executive Visual Primitives
// ─────────────────────────────────────────────────────────
//   • OperatorAvatar — warm bespoke velvet-gradient monogram
//   • SignalBars     — burgundy-to-champagne gradient meter
//   • FluidWave      — silky multi-stop aurora ribbon wave

import { memo, useId, useEffect, useRef } from 'react';
import type { UserStatus } from '@/types';
import { getMasterWaveTicker } from '@/src/lib/waveMasterTicker';

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

// ── High-Performance Canvas 2D Fluid Wave (Zero-React-Render) ─────

interface FluidWaveProps {
  /** Optional operator ID for direct WebAudio DSP FFT sampling */
  peerId?: string;
  /** Animate the flow (speaking / playing) */
  active: boolean;
  muted?: boolean;
  className?: string;
  /** Seconds per loop for the primary wave */
  speed?: number;
  /** Legacy compatibility props (no-op in zero-re-render architecture) */
  level?: number;
  secondaryLevel?: number;
}

export const FluidWave = memo(function FluidWave({
  peerId,
  active,
  muted = false,
  className = '',
  speed = 1.4,
}: FluidWaveProps) {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const waveId = useId();

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ticker = getMasterWaveTicker();
    ticker.register(waveId, canvas, { peerId, active, muted, speed });

    return () => {
      ticker.unregister(waveId);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [waveId, peerId, speed]); // initial mount and geometry bindings

  useEffect(() => {
    getMasterWaveTicker().updateSpeakerState(waveId, active, muted, peerId);
  }, [waveId, active, muted, peerId]);

  return (
    <canvas
      ref={canvasRef}
      className={`block w-full h-full ${className}`}
      style={{ contain: 'strict' }}
      aria-hidden
    />
  );
});
