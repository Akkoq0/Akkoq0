'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Broadcast & OBS Studio Transparent Browser Source
// ─────────────────────────────────────────────────────────
// Designed for streamers, tournament casters and esports production.
// Transparent canvas, ultra-low-latency speaker waveforms, score ticker,
// and IGL tactical alert badges.

import React, { useState, useEffect } from 'react';
import { useSearchParams } from 'next/navigation';

interface SpeakerState {
  id: string;
  name: string;
  role: string;
  isSpeaking: boolean;
  dbfs: number; // -60 to 0 dBFS
  team: 'alpha' | 'omega';
}

const DEFAULT_SPEAKERS: SpeakerState[] = [
  { id: 'p1', name: 'Meva_IGL', role: 'IGL', isSpeaking: true, dbfs: -14, team: 'alpha' },
  { id: 'p2', name: 'ShadowAWP', role: 'AWP', isSpeaking: false, dbfs: -60, team: 'alpha' },
  { id: 'p3', name: 'Vortex_Entry', role: 'DUELIST', isSpeaking: false, dbfs: -60, team: 'alpha' },
  { id: 'p4', name: 'Recon_Flex', role: 'SUPPORT', isSpeaking: true, dbfs: -18, team: 'alpha' },
  { id: 'p5', name: 'Anchor_B', role: 'ANCHOR', isSpeaking: false, dbfs: -60, team: 'alpha' },
];

export default function BroadcastClient() {
  const searchParams = useSearchParams();
  const layout = searchParams?.get('layout') || 'bottom-bar'; // 'bottom-bar' | 'side-dock' | 'full-hud'
  const showScore = searchParams?.get('score') !== 'false';
  const showTactics = searchParams?.get('tactics') !== 'false';

  const [speakers, setSpeakers] = useState<SpeakerState[]>(DEFAULT_SPEAKERS);
  const [activeCallout, setActiveCallout] = useState<string>('A EXECUTE · DUMANLAR AKTİF');
  const [roundScore, setRoundScore] = useState<{ alpha: number; omega: number }>({
    alpha: 11,
    omega: 9,
  });

  // Dynamic audio level fluctuation simulation for OBS preview
  useEffect(() => {
    const timer = setInterval(() => {
      setSpeakers((prev) =>
        prev.map((s) => {
          if (!s.isSpeaking) return s;
          const randomDbfs = Math.min(-6, Math.max(-36, -18 + (Math.random() * 16 - 8)));
          return { ...s, dbfs: Math.round(randomDbfs) };
        }),
      );
    }, 120);

    return () => clearInterval(timer);
  }, []);

  return (
    <div className="w-screen h-screen bg-transparent overflow-hidden select-none font-sans p-4 pointer-events-none">
      {/* ── BROADCAST HUD: BOTTOM BAR LAYOUT (DEFAULT FOR OBS) ── */}
      {layout === 'bottom-bar' && (
        <div className="absolute inset-x-4 bottom-4 flex items-end justify-between gap-4 pointer-events-auto">
          {/* Active Tournament Scoreboard (Left) */}
          {showScore && (
            <div className="rounded-2xl bg-[#070607]/90 border border-[#8F1622]/60 p-3 shadow-[0_8px_32px_rgba(0,0,0,0.85)] flex items-center gap-3 backdrop-blur-md">
              <div className="flex items-center gap-2">
                <span className="w-3 h-3 rounded-full bg-blue-500 shadow-[0_0_8px_rgba(59,130,246,0.8)]" />
                <span className="text-xs font-black tracking-wider text-blue-400">ALPHA</span>
                <span className="text-xl font-black text-white tabular-nums px-2 py-0.5 rounded-lg bg-[#140A0D] border border-[#2A1016]">
                  {roundScore.alpha}
                </span>
              </div>
              <span className="text-xs font-black text-[#8E7E81]">VS</span>
              <div className="flex items-center gap-2">
                <span className="text-xl font-black text-white tabular-nums px-2 py-0.5 rounded-lg bg-[#140A0D] border border-[#2A1016]">
                  {roundScore.omega}
                </span>
                <span className="text-xs font-black tracking-wider text-red-400">OMEGA</span>
                <span className="w-3 h-3 rounded-full bg-red-500 shadow-[0_0_8px_rgba(239,68,68,0.8)]" />
              </div>
            </div>
          )}

          {/* Active IGL Callout / Tactic Banner (Center) */}
          {showTactics && (
            <div className="flex-1 max-w-md mx-auto rounded-xl bg-gradient-to-r from-[#1C0B10]/95 via-[#0D090B]/95 to-[#1C0B10]/95 border border-[#C82333]/70 px-4 py-2 flex items-center justify-center gap-2 shadow-[0_0_20px_rgba(200,35,51,0.35)] backdrop-blur-md">
              <span className="w-2 h-2 rounded-full bg-[#C82333] animate-pulse" />
              <span className="text-[10px] font-black uppercase text-[#F08C96] tracking-widest">
                IGL CALLOUT:
              </span>
              <span className="text-xs font-black text-[#FAF2EE] tracking-wide truncate">
                {activeCallout}
              </span>
            </div>
          )}

          {/* Live Speaking Roster (Right) */}
          <div className="flex items-center gap-2 rounded-2xl bg-[#070607]/90 border border-[#8F1622]/60 p-2.5 shadow-[0_8px_32px_rgba(0,0,0,0.85)] backdrop-blur-md">
            {speakers.map((spk) => (
              <div
                key={spk.id}
                className={`relative flex items-center gap-2 px-2.5 py-1.5 rounded-xl transition-all duration-150 ${
                  spk.isSpeaking
                    ? 'bg-[#1C0B10] border border-[#C82333] shadow-[0_0_12px_rgba(200,35,51,0.5)]'
                    : 'bg-[#12080B]/60 border border-transparent opacity-65'
                }`}
              >
                {/* Operator Avatar */}
                <div
                  className={`w-7 h-7 rounded-lg flex items-center justify-center text-xs font-black text-white border ${
                    spk.isSpeaking
                      ? 'border-[#FF4655] bg-gradient-to-br from-[#8F1622] to-[#450A15]'
                      : 'border-[#2E151C] bg-[#140A0D]'
                  }`}
                >
                  {spk.name.slice(0, 2).toUpperCase()}
                </div>

                <div className="flex flex-col">
                  <span className="text-[11px] font-bold text-[#FAF2EE] leading-none max-w-[80px] truncate">
                    {spk.name}
                  </span>
                  <div className="flex items-center gap-1 mt-1">
                    <span className="text-[8.5px] font-black px-1 rounded bg-[#0A0507] text-[#E08C96] leading-none">
                      {spk.role}
                    </span>
                    {/* Live Waveform Indicator */}
                    {spk.isSpeaking && (
                      <div className="flex items-center gap-0.5 h-2">
                        <span className="w-0.5 h-full bg-[#22C55E] rounded-full animate-pulse" />
                        <span className="w-0.5 h-2/3 bg-[#22C55E] rounded-full animate-pulse delay-75" />
                        <span className="w-0.5 h-full bg-[#22C55E] rounded-full animate-pulse delay-150" />
                      </div>
                    )}
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* ── BROADCAST HUD: SIDE DOCK (VERTICAL FOR RIGHT OF STREAM) ── */}
      {layout === 'side-dock' && (
        <div className="absolute right-4 top-16 bottom-16 w-56 flex flex-col gap-3 pointer-events-auto">
          {/* Header */}
          <div className="rounded-xl bg-[#070607]/90 border border-[#8F1622]/60 p-3 shadow-2xl backdrop-blur-md">
            <span className="text-[10px] font-black tracking-widest text-[#E08C96] uppercase block">
              CANLI TAKIM SESİ
            </span>
            <span className="text-xs font-bold text-[#FAF2EE]">MEVA ESPORTS BROADCAST</span>
          </div>

          {/* Speakers Stack */}
          <div className="flex-1 flex flex-col gap-2 overflow-y-auto">
            {speakers.map((spk) => (
              <div
                key={spk.id}
                className={`flex items-center justify-between p-2.5 rounded-xl border backdrop-blur-md transition-all ${
                  spk.isSpeaking
                    ? 'bg-[#1C0B10]/90 border-[#C82333] shadow-[0_0_14px_rgba(200,35,51,0.4)]'
                    : 'bg-[#0E070A]/80 border-[#241116] opacity-60'
                }`}
              >
                <div className="flex items-center gap-2 min-w-0">
                  <div
                    className={`w-6 h-6 rounded-md flex items-center justify-center text-[10px] font-black text-white ${
                      spk.isSpeaking ? 'bg-[#C82333]' : 'bg-[#1E0B11]'
                    }`}
                  >
                    {spk.name.slice(0, 1)}
                  </div>
                  <div className="truncate">
                    <span className="block text-[11px] font-bold text-[#FAF2EE] truncate">
                      {spk.name}
                    </span>
                    <span className="text-[9px] font-semibold text-[#8E7E81]">{spk.role}</span>
                  </div>
                </div>

                {spk.isSpeaking && (
                  <span className="text-[9px] font-mono font-bold text-[#22C55E]">
                    {spk.dbfs} dB
                  </span>
                )}
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
