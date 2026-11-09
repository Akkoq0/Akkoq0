'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Quick Coin-Flip & Map Veto Hub
// ─────────────────────────────────────────────────────────
// Lightweight competitive coin-flip and interactive map ban/pick tool (0 CPU).

import React, { useState } from 'react';

const MAP_POOL = ['Mirage', 'Inferno', 'Dust II', 'Nuke', 'Ancient', 'Anubis'];

export const QuickVetoView: React.FC = () => {
  const [coinResult, setCoinResult] = useState<'YAZI' | 'TURA' | null>(null);
  const [flipping, setFlipping] = useState(false);
  const [bannedMaps, setBannedMaps] = useState<Set<string>>(new Set());
  const [pickedMap, setPickedMap] = useState<string | null>(null);

  const handleFlipCoin = () => {
    if (flipping) return;
    setFlipping(true);
    setCoinResult(null);

    setTimeout(() => {
      const result = Math.random() > 0.5 ? 'YAZI' : 'TURA';
      setCoinResult(result);
      setFlipping(false);
    }, 450);
  };

  const handleToggleBan = (mapName: string) => {
    if (pickedMap === mapName) setPickedMap(null);
    setBannedMaps((prev) => {
      const next = new Set(prev);
      if (next.has(mapName)) {
        next.delete(mapName);
      } else {
        next.add(mapName);
      }
      return next;
    });
  };

  const handlePick = (mapName: string) => {
    if (bannedMaps.has(mapName)) return;
    setPickedMap((prev) => (prev === mapName ? null : mapName));
  };

  const handleReset = () => {
    setCoinResult(null);
    setBannedMaps(new Set());
    setPickedMap(null);
  };

  return (
    <div className="space-y-4 font-sans select-none">
      {/* Coin-Flip Card */}
      <div className="p-4 rounded-xl bg-[#14080B] border border-[#2A1319] flex items-center justify-between gap-3 shadow-sm">
        <div>
          <span className="text-[10px] font-bold uppercase tracking-wider text-[#8E7E81] block">
            Taraf & Ban Sırası Belirleme
          </span>
          <span className="text-sm font-extrabold text-[#FAF2EE]">
            Hakem Yazı - Tura Simülatörü
          </span>
        </div>

        <div className="flex items-center gap-3">
          {coinResult && (
            <span className="text-xs font-black px-3 py-1 rounded-lg bg-amber-950/40 border border-amber-700/60 text-amber-300">
              🪙 {coinResult} ÇIKTI!
            </span>
          )}
          <button
            type="button"
            onClick={handleFlipCoin}
            disabled={flipping}
            className="h-8 px-3 rounded-lg crimson-cta text-xs font-black text-[#FAF2EE] shadow-sm transition-all active:scale-95 disabled:opacity-50"
          >
            {flipping ? 'Dönüyor...' : 'Yazı-Tura At'}
          </button>
        </div>
      </div>

      {/* Map Veto Card */}
      <div className="p-4 rounded-xl bg-[#11070A] border border-[#2A1319] space-y-3 shadow-sm">
        <div className="flex items-center justify-between">
          <div>
            <span className="text-xs font-extrabold text-[#FAF2EE] block">
              Hızlı Harita Ban / Pick Havuzu (CS2 Standart)
            </span>
            <span className="text-[10px] text-[#8E7E81]">
              Yasaklamak için BAN, seçmek için SEÇ butonuna basın.
            </span>
          </div>

          <button
            type="button"
            onClick={handleReset}
            className="text-[10px] font-bold text-[#F08C96] hover:underline"
          >
            Sıfırla
          </button>
        </div>

        <div className="grid grid-cols-2 sm:grid-cols-3 gap-2.5">
          {MAP_POOL.map((map) => {
            const isBanned = bannedMaps.has(map);
            const isPicked = pickedMap === map;

            return (
              <div
                key={map}
                className={`p-2.5 rounded-xl border transition-all flex flex-col justify-between gap-2 ${
                  isPicked
                    ? 'bg-[#3B0E17] border-emerald-500 shadow-sm'
                    : isBanned
                      ? 'bg-[#0E0608] border-[#200A10] opacity-50'
                      : 'bg-[#160A0E] border-[#2A1319]'
                }`}
              >
                <div className="flex items-center justify-between">
                  <span
                    className={`text-xs font-extrabold ${
                      isPicked
                        ? 'text-emerald-400'
                        : isBanned
                          ? 'text-[#6E5D60] line-through'
                          : 'text-[#FAF2EE]'
                    }`}
                  >
                    {map}
                  </span>
                  {isPicked && (
                    <span className="text-[9px] font-black text-emerald-400 bg-emerald-950 px-1.5 py-0.5 rounded">
                      SEÇİLDİ
                    </span>
                  )}
                  {isBanned && (
                    <span className="text-[9px] font-black text-[#8E7E81] bg-[#180A0E] px-1.5 py-0.5 rounded">
                      BANLANDI
                    </span>
                  )}
                </div>

                <div className="flex gap-1.5">
                  <button
                    type="button"
                    onClick={() => handleToggleBan(map)}
                    className={`flex-1 py-1 rounded text-[10px] font-bold transition-colors ${
                      isBanned
                        ? 'bg-[#2A1016] text-[#FAF2EE]'
                        : 'bg-[#1C0B10] text-[#A58D8E] hover:text-[#FAF2EE]'
                    }`}
                  >
                    {isBanned ? 'Geri Al' : 'Banla'}
                  </button>
                  <button
                    type="button"
                    onClick={() => handlePick(map)}
                    disabled={isBanned}
                    className={`flex-1 py-1 rounded text-[10px] font-bold transition-colors ${
                      isPicked
                        ? 'bg-emerald-900 text-emerald-200'
                        : 'bg-[#1C0B10] text-[#A58D8E] hover:text-[#FAF2EE] disabled:opacity-30'
                    }`}
                  >
                    Seç
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};
