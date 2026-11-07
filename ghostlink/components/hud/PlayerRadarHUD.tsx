'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Right Squad Roster & Luminous Telemetry Module
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
  'usr-1': 11,
  'usr-2': 14,
  'usr-3': 13,
  'usr-4': 12,
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
      title: 'Operasyonda',
      dot: 'bg-[#C82333]',
      members: onlineMembers.filter((m) => m.status === 'in-game'),
    },
    {
      key: 'online',
      title: 'Hazır Kıta',
      dot: 'bg-[#E04856]',
      members: onlineMembers.filter((m) => m.status === 'online'),
    },
    {
      key: 'away',
      title: 'Beklemede',
      dot: 'bg-[#7A6B6E]',
      members: onlineMembers.filter(
        (m) => m.status === 'idle' || m.status === 'dnd',
      ),
    },
  ];

  return (
    <aside className="w-full lg:w-[256px] h-full flex flex-col overflow-hidden select-none titanium-module lg:rounded-xl font-sans tabular-nums">
      {/* ── Module Header ── */}
      <div className="relative h-12 px-4 flex items-center justify-between bg-[linear-gradient(90deg,rgba(128,18,30,0.14)_0%,transparent_70%)] flex-shrink-0">
        <span
          aria-hidden
          className="pointer-events-none absolute inset-x-3 bottom-0 h-px horizon-divider opacity-80"
        />
        <div className="flex items-center gap-2">
          <IconRadar size={15} className="text-[#D63344]" />
          <h3 className="text-[13px] font-extrabold text-[#F4EFF0]">
            Kadro Radarı
          </h3>
          <span className="rounded-md px-2 py-0.5 bg-[#1C0B10] border border-[#7A121D]/55 text-[11px] font-bold text-[#F08C96]">
            {onlineMembers.length}
          </span>
        </div>
        <button
          type="button"
          onClick={() => setIsMobileRadarOpen(false)}
          aria-label="Kapat"
          className="lg:hidden rounded-xl w-9 h-9 flex items-center justify-center bg-[#180B10] border border-[#32151C] text-[#9E8E91] hover:text-[#F4EFF0]"
        >
          <IconClose size={16} />
        </button>
      </div>

      {/* ── Squad Roster ── */}
      <div className="flex-1 min-h-0 overflow-y-auto px-3 py-3.5 space-y-4">
        {groups.map(
          (g) =>
            g.members.length > 0 && (
              <section key={g.key} className="space-y-1.5">
                <h4 className="px-1.5 flex items-center justify-between text-[11px] font-semibold text-[#8E7E81]">
                  <span className="flex items-center gap-2">
                    <span
                      aria-hidden
                      className={`w-1.5 h-1.5 rounded-full ${g.dot}`}
                    />
                    <span>{g.title}</span>
                  </span>
                  <span className="text-[#C82333]">{g.members.length}</span>
                </h4>

                <div className="space-y-1.5">
                  {g.members.map((m) => (
                    <button
                      type="button"
                      key={m.id}
                      onClick={() => select(m)}
                      className="group rounded-xl w-full min-h-[52px] md:min-h-[48px] px-3 py-2 flex items-center gap-3 text-left bg-[linear-gradient(160deg,rgba(32,11,16,0.58)_0%,rgba(11,8,10,0.78)_100%)] hover:border-[#961826]/55 border border-[#2B1319] transition-all duration-150"
                    >
                      <OperatorAvatar
                        name={m.username}
                        status={m.status}
                        size="sm"
                      />
                      <span className="min-w-0 flex-1">
                        <span className="block truncate text-[13px] font-bold text-[#F4EFF0] group-hover:text-[#F28C96] transition-colors">
                          {m.username}
                        </span>
                        {m.activity && (
                          <span className="block truncate text-[11px] text-[#8E7E81] mt-0.5">
                            {m.activity}
                          </span>
                        )}
                      </span>
                      <span className="rounded-md px-2 py-0.5 bg-[#0D080A] border border-[#2B1319] text-[10.5px] font-bold text-[#C9B8BB] tabular-nums">
                        {PING_MAP[m.id] ?? 12}ms
                      </span>
                    </button>
                  ))}
                </div>
              </section>
            ),
        )}
      </div>

      {/* ── Compact Telemetry Footer ── */}
      <div className="relative p-3 bg-[#0A0708]/85 grid grid-cols-3 gap-1.5 text-center">
        <span
          aria-hidden
          className="pointer-events-none absolute inset-x-3 top-0 h-px horizon-divider opacity-70"
        />
        <div className="rounded-xl py-1.5 px-1 bg-[#140A0D] border border-[#281318]">
          <span className="block text-[9px] text-[#827376]">Jitter</span>
          <span className="block text-[11px] font-bold text-[#F4EFF0] mt-0.5">
            {netGuard.jitterMs}ms
          </span>
        </div>
        <div className="rounded-xl py-1.5 px-1 bg-[#140A0D] border border-[#281318]">
          <span className="block text-[9px] text-[#827376]">Kayıp</span>
          <span className="block text-[11px] font-bold text-[#F4EFF0] mt-0.5">
            {netGuard.packetLossPercent}%
          </span>
        </div>
        <div className="rounded-xl py-1.5 px-1 bg-[linear-gradient(160deg,rgba(128,18,30,0.22)_0%,rgba(14,9,11,0.85)_100%)] border border-[#7A121D]/45">
          <span className="block text-[9px] text-[#B8AAAC]">Buffer</span>
          <span className="block text-[11px] font-bold text-[#F08C96] mt-0.5">
            {netGuard.bufferSizeMs}ms
          </span>
        </div>
      </div>
    </aside>
  );
});
