'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Esports Map Veto & Pick/Ban Module (BO1/BO3/BO5)
// ─────────────────────────────────────────────────────────
// Competitive tournament-grade interactive map veto engine.
// Strict turns, automated decider resolution, and 1-click P2P chat broadcast.

import React, { useState, useMemo } from 'react';
import { useAppStore } from '@/lib/store';
import { useRealtimeChat } from '@/hooks/useRealtimeChat';
import { MAP_BLUEPRINTS, TacticalMapId } from './tacticalBlueprints';
import { IconClose } from '@/components/ui/MevaIcons';

interface MapVetoModalProps {
  isOpen: boolean;
  onClose: () => void;
}

type VetoFormat = 'bo1' | 'bo3' | 'bo5';

interface VetoAction {
  team: 1 | 2;
  action: 'ban' | 'pick';
  mapId: TacticalMapId;
  side?: 'attack' | 'defense';
}

const DEFAULT_VETO_POOLS: Record<string, TacticalMapId[]> = {
  cs2: ['mirage', 'inferno', 'dust2', 'ancient', 'nuke'],
  valorant: ['ascent', 'bind', 'haven', 'split', 'lotus', 'breeze'],
};

export const MapVetoModal: React.FC<MapVetoModalProps> = ({ isOpen, onClose }) => {
  const [selectedGame, setSelectedGame] = useState<'cs2' | 'valorant'>('cs2');
  const [format, setFormat] = useState<VetoFormat>('bo3');
  const [team1Name, setTeam1Name] = useState('Takım Alpha (Mavi)');
  const [team2Name, setTeam2Name] = useState('Takım Omega (Kırmızı)');
  const [history, setHistory] = useState<VetoAction[]>([]);

  const activeChannelId = useAppStore((s) => s.activeChannelId);
  const { sendMessage } = useRealtimeChat(activeChannelId);

  const mapPool = useMemo(() => {
    return DEFAULT_VETO_POOLS[selectedGame] || DEFAULT_VETO_POOLS.cs2;
  }, [selectedGame]);

  // Determine banned and picked maps
  const bannedMaps = useMemo(() => {
    return new Set(history.filter((h) => h.action === 'ban').map((h) => h.mapId));
  }, [history]);

  const pickedMaps = useMemo(() => {
    return history.filter((h) => h.action === 'pick');
  }, [history]);

  const remainingMaps = useMemo(() => {
    const decided = new Set(history.map((h) => h.mapId));
    return mapPool.filter((m) => !decided.has(m));
  }, [mapPool, history]);

  // Turn calculation logic
  const isComplete = useMemo(() => {
    if (format === 'bo1') return remainingMaps.length <= 1;
    if (format === 'bo3') return pickedMaps.length >= 2 || remainingMaps.length <= 1;
    if (format === 'bo5') return pickedMaps.length >= 4 || remainingMaps.length <= 1;
    return false;
  }, [format, pickedMaps, remainingMaps]);

  // Current turn instruction
  const currentTurn = useMemo<{ team: 1 | 2; action: 'ban' | 'pick' } | null>(() => {
    if (isComplete) return null;
    const step = history.length;
    if (format === 'bo1') {
      // Ban, Ban, Ban, Ban... until 1 map remains
      return { team: step % 2 === 0 ? 1 : 2, action: 'ban' };
    }
    if (format === 'bo3') {
      // Step 0: Team 1 Ban
      // Step 1: Team 2 Ban
      // Step 2: Team 1 Pick
      // Step 3: Team 2 Pick
      // Remaining is Decider
      if (step === 0) return { team: 1, action: 'ban' };
      if (step === 1) return { team: 2, action: 'ban' };
      if (step === 2) return { team: 1, action: 'pick' };
      if (step === 3) return { team: 2, action: 'pick' };
    }
    if (format === 'bo5') {
      if (step === 0) return { team: 1, action: 'ban' };
      if (step === 1) return { team: 2, action: 'ban' };
      return { team: step % 2 === 0 ? 1 : 2, action: 'pick' };
    }
    return { team: 1, action: 'ban' };
  }, [format, history.length, isComplete]);

  const handleSelectMap = (mapId: TacticalMapId) => {
    if (!currentTurn || isComplete) return;
    setHistory((prev) => [
      ...prev,
      {
        team: currentTurn.team,
        action: currentTurn.action,
        mapId,
      },
    ]);
  };

  const handleResetVeto = () => {
    setHistory([]);
  };

  const deciderMap = useMemo(() => {
    if (isComplete && remainingMaps.length === 1) {
      return remainingMaps[0];
    }
    return null;
  }, [isComplete, remainingMaps]);

  const handleBroadcastVeto = async () => {
    const picks = pickedMaps
      .map((p) => `${MAP_BLUEPRINTS[p.mapId as Exclude<TacticalMapId, 'custom'>]?.title} (${p.team === 1 ? team1Name : team2Name} Seçti)`)
      .join(', ');
    const bans = history
      .filter((h) => h.action === 'ban')
      .map((b) => MAP_BLUEPRINTS[b.mapId as Exclude<TacticalMapId, 'custom'>]?.title)
      .join(', ');
    const decider = deciderMap ? MAP_BLUEPRINTS[deciderMap as Exclude<TacticalMapId, 'custom'>]?.title : 'Belirlenmedi';

    const msg = `[ESPOR MAP VETO · ${format.toUpperCase()}] ${selectedGame.toUpperCase()} Harita Seçimi Tamamlandı!
• Seçilenler: ${picks || 'BO1 Tek Harita'}
• Decider: ${decider}
• Yasaklananlar: ${bans}`;

    await sendMessage(msg);
    onClose();
  };

  if (!isOpen) return null;

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/85 p-3 sm:p-5 backdrop-blur-xs select-none"
      onClick={(e) => {
        e.preventDefault();
        onClose();
      }}
    >
      <div
        onClick={(e) => {
          e.preventDefault();
          e.stopPropagation();
        }}
        className="w-full max-w-4xl bg-[#090507] rounded-2xl border border-[#8F1622]/70 shadow-[0_24px_80px_rgba(0,0,0,0.95)] flex flex-col overflow-hidden"
      >
        {/* Header */}
        <div className="p-3 sm:p-4 border-b border-[#241116] flex items-center justify-between bg-gradient-to-r from-[#1C0B10] via-[#0E0609] to-[#070406]">
          <div className="flex items-center gap-2">
            <span className="text-lg">⚖️</span>
            <div>
              <h2 className="text-sm font-black text-[#FAF2EE] uppercase tracking-wider">
                ESPOR MAP VETO & PICK-BAN MODÜLÜ
              </h2>
              <p className="text-[10px] text-[#9E8E91] font-mono">
                Turnuva Standardı Sıralı Harita Seçim & Yasaklama Motoru
              </p>
            </div>
          </div>

          <button
            type="button"
            onClick={(e) => {
              e.preventDefault();
              onClose();
            }}
            className="w-7 h-7 rounded-xl flex items-center justify-center bg-[#140A0D] hover:bg-[#220D13] text-[#9E8E91] hover:text-[#FAF2EE] border border-[#2C141A]"
          >
            <IconClose size={14} />
          </button>
        </div>

        {/* Configuration Bar */}
        <div className="px-4 py-2 border-b border-[#1E0B11] flex flex-wrap items-center justify-between gap-3 bg-[#0D070A]">
          <div className="flex items-center gap-3">
            {/* Game Selector */}
            <div className="flex items-center gap-1 bg-[#060305] p-1 rounded-lg border border-[#241116]">
              <span className="text-[9.5px] font-black text-[#8E7E81] px-1">OYUN:</span>
              <button
                type="button"
                onClick={() => {
                  setSelectedGame('cs2');
                  handleResetVeto();
                }}
                className={`px-2 py-0.5 rounded text-xs font-black transition-colors ${
                  selectedGame === 'cs2' ? 'bg-[#8F1622] text-white' : 'text-[#8E7E81] hover:text-[#FAF2EE]'
                }`}
              >
                CS2
              </button>
              <button
                type="button"
                onClick={() => {
                  setSelectedGame('valorant');
                  handleResetVeto();
                }}
                className={`px-2 py-0.5 rounded text-xs font-black transition-colors ${
                  selectedGame === 'valorant' ? 'bg-[#8F1622] text-white' : 'text-[#8E7E81] hover:text-[#FAF2EE]'
                }`}
              >
                Valorant
              </button>
            </div>

            {/* Format Selector */}
            <div className="flex items-center gap-1 bg-[#060305] p-1 rounded-lg border border-[#241116]">
              <span className="text-[9.5px] font-black text-[#8E7E81] px-1">FORMAT:</span>
              {(['bo1', 'bo3', 'bo5'] as const).map((fmt) => (
                <button
                  key={fmt}
                  type="button"
                  onClick={() => {
                    setFormat(fmt);
                    handleResetVeto();
                  }}
                  className={`px-2 py-0.5 rounded text-xs font-black uppercase transition-colors ${
                    format === fmt ? 'bg-[#8F1622] text-white' : 'text-[#8E7E81] hover:text-[#FAF2EE]'
                  }`}
                >
                  {fmt}
                </button>
              ))}
            </div>
          </div>

          {/* Teams Input */}
          <div className="flex items-center gap-2">
            <input
              type="text"
              value={team1Name}
              onChange={(e) => setTeam1Name(e.target.value)}
              className="px-2 py-1 rounded bg-[#060305] border border-[#241116] text-[11px] font-bold text-blue-400 w-32 focus:outline-hidden"
            />
            <span className="text-xs font-black text-[#8E7E81]">VS</span>
            <input
              type="text"
              value={team2Name}
              onChange={(e) => setTeam2Name(e.target.value)}
              className="px-2 py-1 rounded bg-[#060305] border border-[#241116] text-[11px] font-bold text-red-400 w-32 focus:outline-hidden"
            />
          </div>
        </div>

        {/* Turn Status Alert */}
        <div className="px-4 py-2 bg-[#12080B] border-b border-[#241116] flex items-center justify-between">
          {!isComplete && currentTurn ? (
            <div className="flex items-center gap-2">
              <span className="animate-pulse w-2 h-2 rounded-full bg-[#C82333]" />
              <span className="text-xs font-black text-[#FAF2EE]">
                {currentTurn.team === 1 ? team1Name : team2Name} SIRASI:
              </span>
              <span
                className={`text-xs font-bold uppercase px-2 py-0.5 rounded ${
                  currentTurn.action === 'ban' ? 'bg-red-950 text-red-300 border border-red-700' : 'bg-emerald-950 text-emerald-300 border border-emerald-700'
                }`}
              >
                {currentTurn.action === 'ban' ? 'HARİTA YASAKLA (BAN)' : 'HARİTA SEÇ (PICK)'}
              </span>
            </div>
          ) : (
            <div className="flex items-center gap-2 text-emerald-400 font-black text-xs">
              <span>✅</span>
              <span>HARİTA VETO SÜRECİ TAMAMLANDI!</span>
            </div>
          )}

          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={handleResetVeto}
              className="text-[10.5px] font-bold text-[#F08C96] hover:text-white px-2 py-1 rounded hover:bg-[#1E0B11]"
            >
              Veto Sıfırla
            </button>
            {isComplete && (
              <button
                type="button"
                onClick={handleBroadcastVeto}
                className="px-3 py-1 rounded-lg crimson-cta text-xs font-black text-white shadow-md flex items-center gap-1.5"
              >
                <span>📢</span>
                <span>Odaya Sonucu Bildir</span>
              </button>
            )}
          </div>
        </div>

        {/* Map Pool Grid */}
        <div className="p-4 grid grid-cols-2 sm:grid-cols-3 md:grid-cols-5 gap-3 max-h-[55vh] overflow-y-auto">
          {mapPool.map((mKey) => {
            const spec = MAP_BLUEPRINTS[mKey as Exclude<TacticalMapId, 'custom'>];
            const title = spec?.title || mKey;
            const isBanned = bannedMaps.has(mKey);
            const banRecord = history.find((h) => h.mapId === mKey && h.action === 'ban');
            const pickRecord = history.find((h) => h.mapId === mKey && h.action === 'pick');
            const isDecider = deciderMap === mKey;

            return (
              <div
                key={mKey}
                onClick={() => !isBanned && !pickRecord && !isDecider && handleSelectMap(mKey)}
                className={`relative rounded-xl overflow-hidden border p-3 flex flex-col justify-between transition-all aspect-[4/3] ${
                  isBanned
                    ? 'bg-[#0E0608] opacity-50 border-red-900/60 grayscale cursor-not-allowed'
                    : pickRecord
                    ? 'bg-emerald-950/40 border-emerald-500 shadow-[0_0_15px_rgba(16,185,129,0.3)]'
                    : isDecider
                    ? 'bg-amber-950/40 border-amber-400 shadow-[0_0_20px_rgba(245,158,11,0.4)]'
                    : 'bg-[#12080B] hover:bg-[#1C0D12] border-[#2A1319] hover:border-[#8F1622] cursor-pointer hover:scale-[1.02]'
                }`}
              >
                {/* Background image if available */}
                {spec?.imageUrl && (
                  <div
                    className="absolute inset-0 bg-cover bg-center opacity-25 pointer-events-none"
                    style={{ backgroundImage: `url(${spec.imageUrl})` }}
                  />
                )}

                <div className="relative z-10 flex items-start justify-between">
                  <span className="text-xs font-black text-white uppercase tracking-wider">{title}</span>
                  {isBanned && <span className="text-red-500 font-black text-sm">❌</span>}
                  {pickRecord && <span className="text-emerald-400 font-black text-sm">✓</span>}
                  {isDecider && <span className="text-amber-400 font-black text-sm">★</span>}
                </div>

                <div className="relative z-10">
                  {isBanned ? (
                    <div className="text-[10px] font-mono font-bold text-red-400">
                      YASAKLANDI ({banRecord?.team === 1 ? team1Name : team2Name})
                    </div>
                  ) : pickRecord ? (
                    <div className="text-[10px] font-mono font-bold text-emerald-400">
                      SEÇİLDİ ({pickRecord.team === 1 ? team1Name : team2Name})
                    </div>
                  ) : isDecider ? (
                    <div className="text-[10px] font-mono font-bold text-amber-300">
                      DECIDER (DÖNÜM NOKTASI)
                    </div>
                  ) : (
                    <div className="text-[10px] font-bold text-[#8E7E81] flex items-center justify-between">
                      <span>Kalan Havuz</span>
                      <span className="text-white bg-[#8F1622] px-1.5 py-0.5 rounded text-[9px] uppercase">
                        {currentTurn?.action === 'ban' ? 'YASAKLA' : 'SEÇ'}
                      </span>
                    </div>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};
