// ─────────────────────────────────────────────────────────
// Meva HUD — Industrial Command Visual Primitives
// ─────────────────────────────────────────────────────────

import { memo } from 'react';
import type { UserStatus } from '@/types';

const STATUS_DOT: Record<UserStatus, string> = {
  'in-game': 'bg-[#EF4444]',
  online: 'bg-[#F59E0B]',
  idle: 'bg-[#6B7280]',
  dnd: 'bg-[#DC2626]',
  offline: 'bg-[#374151]',
};

const AVATAR_SIZE = {
  xs: 'w-6 h-6 text-[10px]',
  sm: 'w-7 h-7 text-[11px]',
  md: 'w-9 h-9 text-xs',
  lg: 'w-12 h-12 text-base',
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
  return (
    <span className={`relative inline-flex flex-shrink-0 ${AVATAR_SIZE[size]}`}>
      <span
        className={`rounded-sm w-full h-full flex items-center justify-center font-mono font-bold border transition-colors ${
          speaking
            ? 'bg-gl-accent/15 text-gl-accent border-gl-accent'
            : 'bg-[#12151C] text-gl-text-bright border-white/[0.07]'
        }`}
      >
        {name[0]?.toUpperCase() ?? 'OP'}
      </span>
      {status && (
        <span
          aria-hidden
          className={`absolute -bottom-0.5 -right-0.5 w-2 h-2 rounded-[1px] ring-2 ring-[#050608] ${STATUS_DOT[status]}`}
        />
      )}
    </span>
  );
});

export const SignalBars = memo(function SignalBars({ score }: { score: number }) {
  const level = Math.max(1, Math.ceil(score / 25));
  const tone =
    score >= 80
      ? 'bg-[#F59E0B]'
      : score >= 50
        ? 'bg-[#D97706]'
        : 'bg-[#EF4444]';
  return (
    <span
      role="img"
      aria-label={`Bağlantı kalitesi %${score}`}
      className="inline-flex items-end gap-[2px] h-3"
    >
      {[1, 2, 3, 4].map((i) => (
        <span
          key={i}
          className={`w-[2.5px] rounded-[0.5px] ${i <= level ? tone : 'bg-white/[0.12]'}`}
          style={{ height: `${i * 25}%` }}
        />
      ))}
    </span>
  );
});
