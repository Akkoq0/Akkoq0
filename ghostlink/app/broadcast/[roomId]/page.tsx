'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Broadcast & OBS Studio Transparent Browser Source
// ─────────────────────────────────────────────────────────
// Designed for streamers, tournament casters and esports production.
// Transparent canvas, ultra-low-latency speaker waveforms, score ticker,
// and IGL tactical alert badges.

import React, { useState, useEffect, useMemo } from 'react';
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

export default function BroadcastOverlayPage({
  params,
}: {
  params: { roomId: string };
}) {
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
        prev.map((sp) => {
          // Randomize speaking state realistically
          const speakingChance = Math.random() > 0.45;
          const nextDb = speakingChance ? Math.round(-30 + Math.random() * 25) : -60;
          return {
            ...sp,
            isSpeaking: speakingChance && nextDb > -45,
            dbfs: nextDb,
          };
        }),
      );
    }, 450);

    return () => clearInterval(timer);
  }, []);

  return (
    <div className="fixed inset-0 w-screen h-screen overflow-hidden bg-transparent select-none pointer-events-none font-sans tabular-nums p-6 flex flex-col justify-between">
      {/* ── TOP LAYER: Tournament Match Scoreboard (if enabled) ── */}
      {showScore && (
        <div className="self-center flex items-center gap-3 px-6 py-2 rounded-2xl bg-[#070607]/90 backdrop-blur-md border border-[#8F1622]/80 shadow-[0_8px_32px_rgba(0,0,0,0.85)]">
          <div className="flex items-center gap-2">
            <span className="w-3 h-3 rounded-full bg-[#3B82F6] ring-2 ring-blue-400/50 shadow-xs" />
            <span className="text-xs font-black text-white tracking-widest uppercase">
              ALPHA
            </span>
            <span className="text-xl font-black text-[#FAF2EE] px-2 py-0.5 rounded-lg bg-[#160B10] border border-[#2E151C]">
              {roundScore.alpha}
            </span>
          </div>

          <div className="flex flex-col items-center px-3 border-x border-[#2E151C]">
            <span className="text-[10px] font-black text-[#F08C96] tracking-wider uppercase">
              MEVA ESPORTS
            </span>
            <span className="text-[9px] font-mono text-[#8E7E81]">
              #{params.roomId.toUpperCase()}
            </span>
          </div>

          <div className="flex items-center gap-2">
            <span className="text-xl font-black text-[#FAF2EE] px-2 py-0.5 rounded-lg bg-[#160B10] border border-[#2E151C]">
              {roundScore.omega}
            </span>
            <span className="text-xs font-black text-white tracking-widest uppercase">
              OMEGA
            </span>
            <span className="w-3 h-3 rounded-full bg-[#EF4444] ring-2 ring-red-400/50 shadow-xs" />
          </div>
        </div>
      )}

      {/* ── MIDDLE / CALLOUT TICKER ── */}
      {showTactics && activeCallout && (
        <div className="self-start mt-2 px-4 py-1.5 rounded-xl bg-[#12080B]/90 backdrop-blur-md border border-[#C82333]/80 shadow-lg flex items-center gap-2 animate-pulse">
          <span className="text-xs">📢</span>
          <span className="text-[11px] font-black text-[#FAF2EE] uppercase tracking-wider">
            {activeCallout}
          </span>
        </div>
      )}

      {/* ── BOTTOM OR SIDE SPEAKER HUD ── */}
      {layout === 'side-dock' ? (
        // Side Dock Layout (Vertical Left/Right)
        <div className="absolute right-6 top-1/3 flex flex-col gap-2.5">
          {speakers.map((sp) => (
            <div
              key={sp.id}
              className={`px-3 py-2 rounded-xl backdrop-blur-md border transition-all duration-200 flex items-center gap-3 ${
                sp.isSpeaking
                  ? 'bg-[#1C0B10]/95 border-[#C82333] shadow-[0_0_20px_rgba(200,35,51,0.55)] scale-105'
                  : 'bg-[#070607]/75 border-[#241116] opacity-75'
              }`}
            >
              <div className="relative">
                <div
                  className={`w-9 h-9 rounded-xl flex items-center justify-center font-black text-xs text-white border ${
                    sp.isSpeaking
                      ? 'bg-[#8F1622] border-[#FF4655]'
                      : 'bg-[#140A0D] border-[#2A1319]'
                  }`}
                >
                  {sp.name.slice(0, 2).toUpperCase()}
                </div>
                {sp.isSpeaking && (
                  <span className="absolute -top-1 -right-1 w-3 h-3 rounded-full bg-emerald-500 ring-2 ring-[#070607] animate-ping" />
                )}
              </div>
              <div className="flex flex-col">
                <span className="text-xs font-black text-[#FAF2EE] leading-tight">
                  {sp.name}
                </span>
                <span className="text-[9.5px] font-mono text-[#F08C96]">{sp.role}</span>
              </div>
            </div>
          ))}
        </div>
      ) : (
        // Bottom Bar Layout (Horizontal Bottom)
        <div className="self-center flex items-center gap-3 pb-2">
          {speakers.map((sp) => (
            <div
              key={sp.id}
              className={`px-3 py-2 rounded-2xl backdrop-blur-md border transition-all duration-200 flex items-center gap-2.5 ${
                sp.isSpeaking
                  ? 'bg-[#1C0B10]/95 border-[#C82333] shadow-[0_0_24px_rgba(200,35,51,0.6)] -translate-y-1'
                  : 'bg-[#070607]/80 border-[#241116] opacity-80'
              }`}
            >
              <div className="relative">
                <div
                  className={`w-8 h-8 rounded-xl flex items-center justify-center font-black text-xs text-white border ${
                    sp.isSpeaking
                      ? 'bg-[#8F1622] border-[#FF4655]'
                      : 'bg-[#140A0D] border-[#2A1319]'
                  }`}
                >
                  {sp.name.slice(0, 2).toUpperCase()}
                </div>
                {sp.isSpeaking && (
                  <span className="absolute -bottom-0.5 -right-0.5 w-2.5 h-2.5 rounded-full bg-emerald-500 ring-2 ring-[#070607]" />
                )}
              </div>

              <div className="flex flex-col min-w-0">
                <div className="flex items-center gap-1.5">
                  <span className="text-[11.5px] font-black text-[#FAF2EE] truncate max-w-[90px]">
                    {sp.name}
                  </span>
                  <span className="text-[9px] font-mono px-1 py-0.2 rounded bg-black/50 text-[#F08C96]">
                    {sp.role}
                  </span>
                </div>

                {/* Animated Waveform Meter */}
                <div className="flex items-center gap-0.5 h-1.5 pt-0.5">
                  {[1, 2, 3, 4, 5, 6].map((bar) => {
                    const activeBars = sp.isSpeaking
                      ? Math.min(6, Math.max(1, Math.round(((sp.dbfs + 60) / 60) * 6)))
                      : 1;
                    const isLit = bar <= activeBars;
                    return (
                      <div
                        key={bar}
                        style={{
                          height: isLit ? `${Math.min(10, 3 + bar * 1.2)}px` : '3px',
                        }}
                        className={`w-1 rounded-full transition-all duration-75 ${
                          isLit
                            ? sp.isSpeaking
                              ? 'bg-[#FF4655]'
                              : 'bg-emerald-500'
                            : 'bg-[#2E151C]'
                        }`}
                      />
                    );
                  })}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
