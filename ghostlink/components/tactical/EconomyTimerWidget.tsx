'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Esports Economy & Objective Timers Widget
// ─────────────────────────────────────────────────────────
// Real-time CS2/Valorant loss-bonus economy calculator and
// LoL/Dota 2 live objective respawn countdown trackers.

import React, { useState, useEffect } from 'react';
import { useAppStore } from '@/lib/store';
import { useRealtimeChat } from '@/hooks/useRealtimeChat';

interface EconomyTimerWidgetProps {
  archetype: 'fps' | 'moba' | 'br';
}

interface ActiveTimer {
  name: string;
  icon: string;
  endTs: number;
}

export const EconomyTimerWidget: React.FC<EconomyTimerWidgetProps> = ({ archetype }) => {
  const activeChannelId = useAppStore((s) => s.activeChannelId);
  const { sendMessage } = useRealtimeChat(activeChannelId);

  // FPS Economy State
  const [lossStreak, setLossStreak] = useState<number>(1);
  const [plantedSpike, setPlantedSpike] = useState<boolean>(false);

  // MOBA Timers State
  const [activeTimers, setActiveTimers] = useState<Record<string, ActiveTimer>>({});
  const [, setTick] = useState(0);

  useEffect(() => {
    const timer = setInterval(() => {
      setTick((t) => t + 1);
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  // CS2/Valorant Economy Calculations
  const lossBonuses = [1400, 1900, 2400, 2900, 3400];
  const currentBonus = lossBonuses[Math.min(4, lossStreak)];
  const totalRoundBonus = currentBonus + (plantedSpike ? 800 : 0);

  const buyStatus =
    totalRoundBonus >= 3400
      ? { label: 'FULL BUY', color: 'text-emerald-400 bg-emerald-950/40 border-emerald-500' }
      : totalRoundBonus >= 2400
      ? { label: 'SEMI / FORCE BUY', color: 'text-amber-400 bg-amber-950/40 border-amber-500' }
      : { label: 'ECO / SAVE', color: 'text-red-400 bg-red-950/40 border-red-500' };

  // MOBA Objective Handlers
  const startTimer = (key: string, name: string, icon: string, seconds: number) => {
    const endTs = Date.now() + seconds * 1000;
    setActiveTimers((prev) => ({
      ...prev,
      [key]: { name, icon, endTs },
    }));
    void sendMessage(`[ZAMANLAYICI] ${name} ${icon} kesildi! Yeniden doğuş: ${Math.round(seconds / 60)} dakika sonra.`);
  };

  const cancelTimer = (key: string) => {
    setActiveTimers((prev) => {
      const next = { ...prev };
      delete next[key];
      return next;
    });
  };

  return (
    <div className="bg-[#12080B] p-2.5 rounded-xl border border-[#241116] space-y-2">
      <div className="flex items-center justify-between">
        <span className="text-[10px] font-black text-[#8E7E81] uppercase tracking-wider">
          {archetype === 'moba' ? 'OBJEKTİF SAYACI (TIMER)' : 'EKONOMİ & ROUND TAKİBİ'}
        </span>
        <span className="text-[9px] font-bold text-amber-400">Canlı</span>
      </div>

      {/* ── FPS Economy Tracker ── */}
      {archetype === 'fps' && (
        <div className="space-y-2 text-xs">
          <div className="flex items-center justify-between bg-[#070305] p-2 rounded-lg border border-[#1E0B11]">
            <span className="text-[10px] text-[#A8989B]">Kayıp Serisi (Loss Streak):</span>
            <div className="flex items-center gap-1">
              {[0, 1, 2, 3, 4].map((streak) => (
                <button
                  key={streak}
                  type="button"
                  onClick={() => setLossStreak(streak)}
                  className={`w-5 h-5 rounded text-[10px] font-black ${
                    lossStreak === streak ? 'bg-[#8F1622] text-white' : 'text-[#8E7E81] hover:text-[#FAF2EE]'
                  }`}
                >
                  {streak}
                </button>
              ))}
            </div>
          </div>

          <div className="flex items-center justify-between text-[11px] px-1">
            <label className="flex items-center gap-1.5 cursor-pointer text-[#FAF2EE]">
              <input
                type="checkbox"
                checked={plantedSpike}
                onChange={(e) => setPlantedSpike(e.target.checked)}
                className="rounded accent-[#C82333]"
              />
              <span>C4 / Spike Kuruldu (+$800)</span>
            </label>
            <span className="font-mono font-black text-emerald-400">${totalRoundBonus}</span>
          </div>

          <div className={`p-1.5 rounded-lg border text-center font-black text-[10px] tracking-wider ${buyStatus.color}`}>
            ÖNERİLEN: {buyStatus.label} (${totalRoundBonus})
          </div>
        </div>
      )}

      {/* ── MOBA Objective Timers ── */}
      {archetype === 'moba' && (
        <div className="grid grid-cols-2 gap-1.5">
          {[
            { key: 'dragon', name: 'Ejder', icon: '🐉', sec: 300 },
            { key: 'baron', name: 'Baron', icon: '🟣', sec: 360 },
            { key: 'roshan', name: 'Roshan', icon: '👹', sec: 480 },
            { key: 'tormentor', name: 'Tormentor', icon: '💎', sec: 600 },
          ].map((obj) => {
            const active = activeTimers[obj.key];
            const remaining = active ? Math.max(0, Math.round((active.endTs - Date.now()) / 1000)) : null;

            return (
              <div
                key={obj.key}
                className="bg-[#070305] p-2 rounded-lg border border-[#1E0B11] flex flex-col justify-between"
              >
                <div className="flex items-center justify-between mb-1">
                  <span className="text-[10.5px] font-black text-white flex items-center gap-1">
                    <span>{obj.icon}</span>
                    <span>{obj.name}</span>
                  </span>
                  {remaining !== null && (
                    <button
                      type="button"
                      onClick={() => cancelTimer(obj.key)}
                      className="text-[9px] text-[#8E7E81] hover:text-red-400"
                    >
                      ×
                    </button>
                  )}
                </div>

                {remaining !== null ? (
                  <div className="flex items-center justify-between font-mono text-[11px] font-black text-amber-400">
                    <span>{Math.floor(remaining / 60)}:{(remaining % 60).toString().padStart(2, '0')}</span>
                    <span className="text-[9px] text-emerald-400 animate-pulse">Aktif</span>
                  </div>
                ) : (
                  <button
                    type="button"
                    onClick={() => startTimer(obj.key, obj.name, obj.icon, obj.sec)}
                    className="w-full py-1 rounded bg-[#1C0D12] hover:bg-[#3B141E] text-[9.5px] font-bold text-[#F08C96] hover:text-white transition-colors"
                  >
                    Başlat ({Math.round(obj.sec / 60)}dk)
                  </button>
                )}
              </div>
            );
          })}
        </div>
      )}

      {/* ── BR Flight & Zone Tracker ── */}
      {archetype === 'br' && (
        <div className="p-2 bg-[#070305] rounded-lg border border-[#1E0B11] text-[11px] text-[#A8989B] space-y-1">
          <div className="flex items-center justify-between text-white font-bold">
            <span>🔵 Daralma Hızı:</span>
            <span className="font-mono text-sky-400">Faz 3 (1:45)</span>
          </div>
          <div className="flex items-center justify-between text-[#8E7E81] text-[10px]">
            <span>Uçak Rotası:</span>
            <span>Kuzeybatı -&gt; Güneydoğu</span>
          </div>
        </div>
      )}
    </div>
  );
};
