'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Interactive Esports Tournament Bracket Engine
// ─────────────────────────────────────────────────────────
// Clean, zero-CPU interactive 4-Team / 8-Team Elimination Bracket
// Optimized for mobile touch & PC desktop (0 frame drop, 0 storage thrash).

import React, { useState } from 'react';
import { IconShield, IconBolt } from '@/components/ui/MevaIcons';

interface BracketMatch {
  id: string;
  round: 'semi' | 'final';
  team1: { name: string; tag: string; score: number };
  team2: { name: string; tag: string; score: number };
  winnerTag: string | null;
}

const INITIAL_MATCHES: BracketMatch[] = [
  {
    id: 'm1',
    round: 'semi',
    team1: { name: 'Meva Tactical', tag: 'MEVA', score: 2 },
    team2: { name: 'FUT Academy', tag: 'FUT', score: 1 },
    winnerTag: 'MEVA',
  },
  {
    id: 'm2',
    round: 'semi',
    team1: { name: 'BBL Esports', tag: 'BBL', score: 2 },
    team2: { name: 'Natus Vincere Jr', tag: 'NAVI', score: 0 },
    winnerTag: 'BBL',
  },
  {
    id: 'm3',
    round: 'final',
    team1: { name: 'Meva Tactical', tag: 'MEVA', score: 0 },
    team2: { name: 'BBL Esports', tag: 'BBL', score: 0 },
    winnerTag: null,
  },
];

export const TournamentBracketView: React.FC = () => {
  const [matches, setMatches] = useState<BracketMatch[]>(INITIAL_MATCHES);

  const handlePickWinner = (matchId: string, winningTag: string) => {
    setMatches((prev) => {
      const next = prev.map((m) => {
        if (m.id === matchId) {
          return {
            ...m,
            winnerTag: winningTag,
            team1: {
              ...m.team1,
              score: m.team1.tag === winningTag ? 2 : 1,
            },
            team2: {
              ...m.team2,
              score: m.team2.tag === winningTag ? 2 : 1,
            },
          };
        }
        return m;
      });

      // Update grand final teams if semi-finals changed
      const sf1 = next.find((m) => m.id === 'm1');
      const sf2 = next.find((m) => m.id === 'm2');
      const finalMatch = next.find((m) => m.id === 'm3');

      if (finalMatch && sf1?.winnerTag && sf2?.winnerTag) {
        finalMatch.team1 = {
          name: sf1.winnerTag === sf1.team1.tag ? sf1.team1.name : sf1.team2.name,
          tag: sf1.winnerTag,
          score: finalMatch.team1.tag === sf1.winnerTag ? finalMatch.team1.score : 0,
        };
        finalMatch.team2 = {
          name: sf2.winnerTag === sf2.team1.tag ? sf2.team1.name : sf2.team2.name,
          tag: sf2.winnerTag,
          score: finalMatch.team2.tag === sf2.winnerTag ? finalMatch.team2.score : 0,
        };
      }

      return [...next];
    });
  };

  const grandFinal = matches.find((m) => m.id === 'm3');
  const championTag = grandFinal?.winnerTag;
  const championName =
    championTag === grandFinal?.team1.tag
      ? grandFinal?.team1.name
      : championTag === grandFinal?.team2.tag
        ? grandFinal?.team2.name
        : null;

  const handleResetBracket = () => {
    setMatches(INITIAL_MATCHES);
  };

  return (
    <div className="space-y-4 font-sans select-none">
      {/* Top Banner */}
      <div className="flex items-center justify-between p-3 rounded-xl bg-[#14080B] border border-[#2A1319]">
        <div className="flex items-center gap-2">
          <span className="text-sm">🏆</span>
          <div>
            <span className="text-xs font-extrabold text-[#FAF2EE] block">
              Meva Espor Turnuva Ağacı (Playoffs)
            </span>
            <span className="text-[10px] text-[#8E7E81]">
              Takıma tıklayarak tur kazananını belirleyin veya skoru ilerletin.
            </span>
          </div>
        </div>
        <button
          type="button"
          onClick={handleResetBracket}
          className="px-2.5 py-1 rounded-lg bg-[#1E0C12] hover:bg-[#2A1018] border border-[#590C15] text-[10px] font-bold text-[#F08C96] transition-colors"
        >
          Sıfırla
        </button>
      </div>

      {/* Champion Podium if decided */}
      {championName && (
        <div className="p-3.5 rounded-xl bg-gradient-to-r from-[#2B0E16] via-[#1A080D] to-[#2B0E16] border border-[#A61826] flex items-center justify-between animate-fade-in shadow-md">
          <div className="flex items-center gap-2.5">
            <span className="text-2xl">👑</span>
            <div>
              <span className="text-[10px] font-bold uppercase tracking-wider text-[#F08C96] block">
                Turnuva Şampiyonu
              </span>
              <span className="text-sm font-black text-[#FAF2EE] tracking-wide">
                {championName} [{championTag}]
              </span>
            </div>
          </div>
          <span className="text-xs font-black text-amber-400 bg-amber-950/40 border border-amber-800/50 px-2.5 py-1 rounded-lg">
            1. SIRA 🥇
          </span>
        </div>
      )}

      {/* Bracket Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {/* Semi Finals */}
        <div className="space-y-3">
          <span className="text-[10px] font-extrabold uppercase tracking-wider text-[#A58D8E] block">
            Yarı Finaller (BO3)
          </span>

          {matches
            .filter((m) => m.round === 'semi')
            .map((match, idx) => (
              <div
                key={match.id}
                className="p-3 rounded-xl bg-[#11070A] border border-[#2A1319] space-y-1.5 shadow-sm"
              >
                <span className="text-[9px] font-bold uppercase text-[#8E7E81] block mb-1">
                  Maç #{idx + 1}
                </span>

                {/* Team 1 */}
                <button
                  type="button"
                  onClick={() => handlePickWinner(match.id, match.team1.tag)}
                  className={`w-full flex items-center justify-between p-2 rounded-lg text-xs font-extrabold transition-all ${
                    match.winnerTag === match.team1.tag
                      ? 'bg-[#3B0E17] text-[#FAF2EE] border border-[#A61826]'
                      : 'bg-[#180A0E] text-[#8E7E81] hover:text-[#FAF2EE] border border-transparent'
                  }`}
                >
                  <span className="truncate">{match.team1.name}</span>
                  <span className="tabular-nums font-mono">{match.team1.score}</span>
                </button>

                {/* Team 2 */}
                <button
                  type="button"
                  onClick={() => handlePickWinner(match.id, match.team2.tag)}
                  className={`w-full flex items-center justify-between p-2 rounded-lg text-xs font-extrabold transition-all ${
                    match.winnerTag === match.team2.tag
                      ? 'bg-[#3B0E17] text-[#FAF2EE] border border-[#A61826]'
                      : 'bg-[#180A0E] text-[#8E7E81] hover:text-[#FAF2EE] border border-transparent'
                  }`}
                >
                  <span className="truncate">{match.team2.name}</span>
                  <span className="tabular-nums font-mono">{match.team2.score}</span>
                </button>
              </div>
            ))}
        </div>

        {/* Grand Final */}
        <div className="space-y-3">
          <span className="text-[10px] font-extrabold uppercase tracking-wider text-[#A58D8E] block">
            Büyük Final (BO3)
          </span>

          {grandFinal && (
            <div className="p-3.5 rounded-xl bg-[#14080B] border border-[#8F1622]/60 space-y-2 shadow-md">
              <span className="text-[9px] font-black uppercase text-[#F08C96] block mb-1">
                🏆 Şampiyonluk Maçı
              </span>

              {/* Final Team 1 */}
              <button
                type="button"
                onClick={() => handlePickWinner('m3', grandFinal.team1.tag)}
                className={`w-full flex items-center justify-between p-2.5 rounded-lg text-xs font-black transition-all ${
                  grandFinal.winnerTag === grandFinal.team1.tag
                    ? 'bg-[#590C15] text-[#FAF2EE] border border-[#FF4655] shadow-sm'
                    : 'bg-[#180A0E] text-[#8E7E81] hover:text-[#FAF2EE] border border-transparent'
                }`}
              >
                <span className="truncate">{grandFinal.team1.name}</span>
                <span className="tabular-nums font-mono text-sm">
                  {grandFinal.winnerTag === grandFinal.team1.tag ? '🏆 2' : grandFinal.team1.score}
                </span>
              </button>

              {/* Final Team 2 */}
              <button
                type="button"
                onClick={() => handlePickWinner('m3', grandFinal.team2.tag)}
                className={`w-full flex items-center justify-between p-2.5 rounded-lg text-xs font-black transition-all ${
                  grandFinal.winnerTag === grandFinal.team2.tag
                    ? 'bg-[#590C15] text-[#FAF2EE] border border-[#FF4655] shadow-sm'
                    : 'bg-[#180A0E] text-[#8E7E81] hover:text-[#FAF2EE] border border-transparent'
                }`}
              >
                <span className="truncate">{grandFinal.team2.name}</span>
                <span className="tabular-nums font-mono text-sm">
                  {grandFinal.winnerTag === grandFinal.team2.tag ? '🏆 2' : grandFinal.team2.score}
                </span>
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
