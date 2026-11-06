'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Right Squad Roster & Telemetry Module
// ─────────────────────────────────────────────────────────

import { memo } from 'react';
import { useAppStore } from '@/lib/store';
import { OperatorAvatar } from '@/components/ui/HudPrimitives';
import { IconRadar, IconClose } from '@/components/ui/MevaIcons';
import type { Profile } from '@/types';

interface PlayerRadarHUDProps {
  onSelectPlayer: (member: Profile) => void;
}

const PING_MAP: Record<string, number> = {
  'usr-1': 12,
  'usr-2': 18,
  'usr-3': 24,
  'usr-4': 15,
};

export const PlayerRadarHUD = memo(function PlayerRadarHUD({
  onSelectPlayer,
}: PlayerRadarHUDProps) {
  const isRadarOpen = useAppStore((s) => s.isRadarOpen);
  const isMobileRadarOpen = useAppStore((s) => s.isMobileRadarOpen);
  const onlineMembers = useAppStore((s) => s.onlineMembers);
  const netGuard = useAppStore((s) => s.netGuard);
  const setIsMobileRadarOpen = useAppStore((s) => s.setIsMobileRadarOpen);

  if (!isRadarOpen && !isMobileRadarOpen) return null;

  const select = (m: Profile) => {
    setIsMobileRadarOpen(false);
    onSelectPlayer(m);
  };

  const groups = [
    {
      key: 'in-game',
      title: 'OPERASYONDA',
      dot: 'bg-[#EF4444]',
      members: onlineMembers.filter((m) => m.status === 'in-game'),
    },
    {
      key: 'online',
      title: 'HAZIR KITA',
      dot: 'bg-[#F59E0B]',
      members: onlineMembers.filter((m) => m.status === 'online'),
    },
    {
      key: 'away',
      title: 'BEKLEMEDE',
      dot: 'bg-[#64748B]',
      members: onlineMembers.filter(
        (m) => m.status === 'idle' || m.status === 'dnd',
      ),
    },
  ];

  return (
    <aside className="w-full md:w-[264px] h-full flex flex-col overflow-hidden select-none titanium-module md:rounded-sm font-sans">
      {/* ── Module Header ── */}
      <div className="h-12 px-4 flex items-center justify-between border-b border-white/[0.06] flex-shrink-0">
        <div className="flex items-center gap-2">
          <IconRadar size={15} className="text-gl-accent" />
          <h3 className="font-sans text-xs font-bold tracking-wider text-gl-text-bright uppercase">
            Kadro Radarı
          </h3>
        </div>
        <span className="rounded-sm px-1.5 py-0.5 bg-[#060709] border border-white/[0.06] font-mono text-[10px] font-bold text-gl-text-normal">
          {onlineMembers.length}
        </span>
        <button
          onClick={() => setIsMobileRadarOpen(false)}
          aria-label="Kapat"
          className="md:hidden rounded-sm w-8 h-8 flex items-center justify-center bg-[#060709] border border-white/[0.06] text-gl-text-normal hover:text-gl-text-bright"
        >
          <IconClose size={15} />
        </button>
      </div>

      {/* ── Squad Roster ── */}
      <div className="flex-1 overflow-y-auto px-3 py-4 space-y-5">
        {groups.map(
          (g) =>
            g.members.length > 0 && (
              <section key={g.key} className="space-y-2">
                <h4 className="px-1.5 flex items-center justify-between font-sans text-[11px] font-bold tracking-wider text-gl-text-muted">
                  <span className="flex items-center gap-2">
                    <span
                      aria-hidden
                      className={`w-1.5 h-1.5 rounded-[1px] ${g.dot}`}
                    />
                    <span>{g.title}</span>
                  </span>
                  <span className="font-mono">{g.members.length}</span>
                </h4>

                <div className="space-y-1.5">
                  {g.members.map((m) => (
                    <button
                      key={m.id}
                      onClick={() => select(m)}
                      className="group rounded-sm w-full min-h-[52px] px-3 py-2 flex items-center gap-3 text-left bg-[#060709]/70 hover:bg-[#14161D] border border-white/[0.05] hover:border-white/[0.12] transition-colors"
                    >
                      <OperatorAvatar
                        name={m.username}
                        status={m.status}
                        size="md"
                      />
                      <span className="min-w-0 flex-1">
                        <span className="block truncate text-[13px] font-bold text-gl-text-bright group-hover:text-gl-accent transition-colors">
                          {m.username}
                        </span>
                        {m.activity && (
                          <span className="block truncate font-sans text-[11px] text-gl-text-muted mt-0.5">
                            {m.activity}
                          </span>
                        )}
                      </span>
                      <span className="font-mono text-[10px] font-bold text-[#F59E0B] tabular-nums">
                        {PING_MAP[m.id] ?? 16}ms
                      </span>
                    </button>
                  ))}
                </div>
              </section>
            ),
        )}
      </div>

      {/* ── Compact Industrial Telemetry Footer ── */}
      <div className="p-3.5 bg-[#060709] border-t border-white/[0.06] grid grid-cols-3 gap-1.5 text-center font-mono">
        <div className="rounded-sm py-2 px-1 bg-[#0D0E12] border border-white/[0.06]">
          <span className="block text-[9px] text-gl-text-muted">JITTER</span>
          <span className="block text-[11px] font-bold text-gl-text-bright mt-0.5">
            {netGuard.jitterMs}ms
          </span>
        </div>
        <div className="rounded-sm py-2 px-1 bg-[#0D0E12] border border-white/[0.06]">
          <span className="block text-[9px] text-gl-text-muted">KAYIP</span>
          <span className="block text-[11px] font-bold text-gl-text-bright mt-0.5">
            {netGuard.packetLossPercent}%
          </span>
        </div>
        <div className="rounded-sm py-2 px-1 bg-[#0D0E12] border border-white/[0.06]">
          <span className="block text-[9px] text-gl-text-muted">BUFFER</span>
          <span className="block text-[11px] font-bold text-[#F59E0B] mt-0.5">
            {netGuard.bufferSizeMs}ms
          </span>
        </div>
      </div>
    </aside>
  );
});
