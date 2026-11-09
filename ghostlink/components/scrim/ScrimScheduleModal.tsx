'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Esports Scrim & Tournament Match Schedule
// ─────────────────────────────────────────────────────────
// Professional match calendar, roster check-in, and tournament scheduling.

import React, { useState, useEffect } from 'react';
import { useAppStore } from '@/lib/store';
import { getMevaStorageEngine, STORE_PREFS } from '@/src/lib/storageEngine';
import { IconClose, IconPlus } from '@/components/ui/MevaIcons';
import { TournamentBracketView } from './TournamentBracketView';
import { QuickVetoView } from './QuickVetoView';

interface ScrimMatch {
  id: string;
  opponentTag: string;
  opponentName: string;
  game: 'cs2' | 'valorant' | 'lol' | 'dota2';
  format: 'bo1' | 'bo3' | 'bo5';
  dateTime: string;
  status: 'upcoming' | 'live' | 'finished';
  rosterCheckedCount: number;
}

const DEFAULT_SCRIMS: ScrimMatch[] = [
  {
    id: 'scrim-1',
    opponentTag: 'FUT',
    opponentName: 'FUT Esports Academy',
    game: 'cs2',
    format: 'bo3',
    dateTime: 'Bugün · 20:30',
    status: 'upcoming',
    rosterCheckedCount: 5,
  },
  {
    id: 'scrim-2',
    opponentTag: 'BBL',
    opponentName: 'BBL Queens',
    game: 'valorant',
    format: 'bo3',
    dateTime: 'Yarın · 19:00',
    status: 'upcoming',
    rosterCheckedCount: 4,
  },
  {
    id: 'scrim-3',
    opponentTag: 'NAVI',
    opponentName: 'Natus Vincere Junior',
    game: 'cs2',
    format: 'bo1',
    dateTime: 'Dün · 21:00',
    status: 'finished',
    rosterCheckedCount: 5,
  },
];

interface ScrimScheduleModalProps {
  isOpen: boolean;
  onClose: () => void;
  onLaunchVeto?: () => void;
}

export const ScrimScheduleModal: React.FC<ScrimScheduleModalProps> = ({
  isOpen,
  onClose,
  onLaunchVeto,
}) => {
  const [activeTab, setActiveTab] = useState<'schedule' | 'bracket' | 'veto'>('schedule');
  const [scrims, setScrims] = useState<ScrimMatch[]>(DEFAULT_SCRIMS);
  const [showAddForm, setShowAddForm] = useState<boolean>(false);

  // New Scrim Form state
  const [opponentTag, setOpponentTag] = useState('');
  const [opponentName, setOpponentName] = useState('');
  const [game, setGame] = useState<'cs2' | 'valorant' | 'lol' | 'dota2'>('cs2');
  const [format, setFormat] = useState<'bo1' | 'bo3' | 'bo5'>('bo3');
  const [dateTime, setDateTime] = useState('');

  // Hydrate scrims from storage
  useEffect(() => {
    try {
      const storage = getMevaStorageEngine();
      void storage
        .getRecord<ScrimMatch[]>(STORE_PREFS, 'esports_scrim_schedules')
        .then((saved) => {
          if (Array.isArray(saved) && saved.length > 0) {
            setScrims(saved);
          }
        });
    } catch {}
  }, []);

  const handleSaveNewScrim = (e: React.FormEvent) => {
    e.preventDefault();
    if (!opponentTag.trim() || !dateTime.trim()) return;

    const newMatch: ScrimMatch = {
      id: `scrim-${Date.now().toString(36)}`,
      opponentTag: opponentTag.trim().toUpperCase(),
      opponentName: opponentName.trim() || `${opponentTag.trim().toUpperCase()} Team`,
      game,
      format,
      dateTime: dateTime.trim(),
      status: 'upcoming',
      rosterCheckedCount: 5,
    };

    const updated = [newMatch, ...scrims];
    setScrims(updated);

    try {
      const storage = getMevaStorageEngine();
      storage.scheduleWrite(STORE_PREFS, 'esports_scrim_schedules', updated);
      void storage.flushPendingWrites();
    } catch {}

    setOpponentTag('');
    setOpponentName('');
    setDateTime('');
    setShowAddForm(false);
  };

  if (!isOpen) return null;

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center exec-backdrop p-2 sm:p-4 font-sans select-none"
      onClick={(e) => {
        e.preventDefault();
        onClose();
      }}
    >
      <div
        className="w-full max-w-2xl bg-[#0B0608] border border-[#8F1622] rounded-2xl shadow-[0_24px_80px_rgba(0,0,0,0.95)] flex flex-col overflow-hidden"
        onClick={(e) => {
          e.preventDefault();
          e.stopPropagation();
        }}
      >
        {/* Header */}
        <div className="px-5 py-4 border-b border-[#241116] flex items-center justify-between bg-gradient-to-r from-[#1C0B10] to-[#0B0608]">
          <div className="flex items-center gap-2.5">
            <span className="w-9 h-9 rounded-xl bg-[#8F1622] text-white flex items-center justify-center text-lg font-bold shadow-md">
              📅
            </span>
            <div>
              <h2 className="text-sm font-black text-white tracking-wide uppercase">
                Espor Scrim & Maç Takvimi
              </h2>
              <p className="text-[11px] text-[#A8989B]">
                Takım antrenman maçları, kadro check-in ve turnuva planlaması
              </p>
            </div>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="w-8 h-8 rounded-lg flex items-center justify-center bg-[#140A0D] text-[#8E7E81] hover:text-white border border-[#2A1319]"
          >
            <IconClose size={14} />
          </button>
        </div>

        {/* Tab Switcher */}
        <div className="px-5 pt-3 border-b border-[#241116] flex gap-3 bg-[#0A0507]">
          <button
            type="button"
            onClick={() => setActiveTab('schedule')}
            className={`pb-2.5 text-xs font-bold transition-all relative ${
              activeTab === 'schedule'
                ? 'text-[#F4EFF0]'
                : 'text-[#8E7E81] hover:text-[#C5B5B8]'
            }`}
          >
            📅 Maç Takvimi
            {activeTab === 'schedule' && (
              <span className="absolute bottom-0 inset-x-0 h-0.5 bg-[#C82333]" />
            )}
          </button>
          <button
            type="button"
            onClick={() => setActiveTab('bracket')}
            className={`pb-2.5 text-xs font-bold transition-all relative ${
              activeTab === 'bracket'
                ? 'text-[#F4EFF0]'
                : 'text-[#8E7E81] hover:text-[#C5B5B8]'
            }`}
          >
            🏆 Turnuva Ağacı (Bracket)
            {activeTab === 'bracket' && (
              <span className="absolute bottom-0 inset-x-0 h-0.5 bg-[#C82333]" />
            )}
          </button>
          <button
            type="button"
            onClick={() => setActiveTab('veto')}
            className={`pb-2.5 text-xs font-bold transition-all relative ${
              activeTab === 'veto'
                ? 'text-[#F4EFF0]'
                : 'text-[#8E7E81] hover:text-[#C5B5B8]'
            }`}
          >
            ⚖️ Harita Veto & Yazı-Tura
            {activeTab === 'veto' && (
              <span className="absolute bottom-0 inset-x-0 h-0.5 bg-[#C82333]" />
            )}
          </button>
        </div>

        {/* Body */}
        <div className="p-5 space-y-4 overflow-y-auto max-h-[70vh]">
          {activeTab === 'bracket' && <TournamentBracketView />}
          {activeTab === 'veto' && <QuickVetoView />}
          {activeTab === 'schedule' && (
            <>
              {/* Action Header */}
              <div className="flex items-center justify-between">
                <span className="text-[10px] font-black text-[#8E7E81] uppercase tracking-wider">
                  PLANLANAN KARŞILAŞMALAR ({scrims.length})
                </span>
                <button
                  type="button"
                  onClick={() => setShowAddForm((s) => !s)}
                  className="h-7 px-2.5 rounded-lg crimson-cta text-xs font-black text-white flex items-center gap-1 shadow-md"
                >
                  <IconPlus size={12} />
                  <span>+ Yeni Scrim Ekle</span>
                </button>
              </div>

          {/* New Scrim Creation Form */}
          {showAddForm && (
            <form
              onSubmit={handleSaveNewScrim}
              className="p-4 rounded-xl bg-[#12080B] border border-[#8F1622] space-y-3"
            >
              <div className="flex items-center justify-between">
                <span className="text-xs font-black text-[#FAF2EE] uppercase">
                  Yeni Scrim Planla
                </span>
                <button
                  type="button"
                  onClick={() => setShowAddForm(false)}
                  className="text-xs text-[#8E7E81] hover:text-white"
                >
                  ✕
                </button>
              </div>

              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="text-[9.5px] font-black text-[#8E7E81] uppercase block mb-1">
                    Rakip Takım Tag
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="Örn: FUT, NAVI, BBL"
                    value={opponentTag}
                    onChange={(e) => setOpponentTag(e.target.value)}
                    className="w-full px-2.5 py-1.5 rounded-lg bg-[#070406] border border-[#2E151C] text-xs text-white uppercase focus:outline-hidden"
                  />
                </div>
                <div>
                  <label className="text-[9.5px] font-black text-[#8E7E81] uppercase block mb-1">
                    Tarih & Saat
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="Örn: Bugün 21:00"
                    value={dateTime}
                    onChange={(e) => setDateTime(e.target.value)}
                    className="w-full px-2.5 py-1.5 rounded-lg bg-[#070406] border border-[#2E151C] text-xs text-white focus:outline-hidden"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="text-[9.5px] font-black text-[#8E7E81] uppercase block mb-1">
                    Oyun
                  </label>
                  <select
                    value={game}
                    onChange={(e) => setGame(e.target.value as any)}
                    className="w-full px-2 py-1.5 rounded-lg bg-[#070406] border border-[#2E151C] text-xs text-white"
                  >
                    <option value="cs2">Counter-Strike 2</option>
                    <option value="valorant">Valorant</option>
                    <option value="lol">League of Legends</option>
                    <option value="dota2">Dota 2</option>
                  </select>
                </div>
                <div>
                  <label className="text-[9.5px] font-black text-[#8E7E81] uppercase block mb-1">
                    Format
                  </label>
                  <select
                    value={format}
                    onChange={(e) => setFormat(e.target.value as any)}
                    className="w-full px-2 py-1.5 rounded-lg bg-[#070406] border border-[#2E151C] text-xs text-white"
                  >
                    <option value="bo1">BO1 (Tek Harita)</option>
                    <option value="bo3">BO3 (3 Harita)</option>
                    <option value="bo5">BO5 (5 Harita Final)</option>
                  </select>
                </div>
              </div>

              <div className="flex items-center justify-end gap-2 pt-1">
                <button
                  type="button"
                  onClick={() => setShowAddForm(false)}
                  className="px-3 py-1.5 rounded-lg text-xs font-bold text-[#8E7E81] hover:text-white"
                >
                  İptal
                </button>
                <button
                  type="submit"
                  className="px-4 py-1.5 rounded-lg crimson-cta text-xs font-black text-white"
                >
                  Takvime Ekle
                </button>
              </div>
            </form>
          )}

          {/* Scrim List */}
          <div className="space-y-2">
            {scrims.map((scrim) => (
              <div
                key={scrim.id}
                className="p-3.5 rounded-xl bg-[#12080B] border border-[#241116] hover:border-[#8F1622]/60 flex items-center justify-between gap-3 transition-colors"
              >
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-xl bg-[#1C0B10] border border-[#3C141E] flex items-center justify-center text-xs font-black text-[#FAF2EE]">
                    [{scrim.opponentTag}]
                  </div>

                  <div>
                    <div className="flex items-center gap-2">
                      <span className="text-xs font-black text-[#FAF2EE]">
                        vs {scrim.opponentName}
                      </span>
                      <span className="text-[9px] font-mono px-1.5 py-0.2 rounded bg-black/50 text-[#F08C96] border border-[#2E151C] uppercase">
                        {scrim.game} · {scrim.format.toUpperCase()}
                      </span>
                    </div>
                    <div className="flex items-center gap-2 pt-0.5 text-[10px] text-[#A8989B]">
                      <span>⏰ {scrim.dateTime}</span>
                      <span>•</span>
                      <span className="text-emerald-400 font-mono">
                        Kadro: {scrim.rosterCheckedCount}/5 Hazır
                      </span>
                    </div>
                  </div>
                </div>

                <div className="flex items-center gap-2">
                  {onLaunchVeto && (
                    <button
                      type="button"
                      onClick={() => {
                        onClose();
                        onLaunchVeto();
                      }}
                      className="px-2.5 py-1 rounded-lg bg-[#1F0C13] hover:bg-[#3B141E] border border-[#8F1622] text-[10.5px] font-black text-[#FAF2EE] flex items-center gap-1"
                    >
                      <span>⚖️</span>
                      <span>Veto Aç</span>
                    </button>
                  )}
                  <span
                    className={`text-[9.5px] font-bold px-2 py-0.5 rounded-full border ${
                      scrim.status === 'live'
                        ? 'bg-emerald-950 text-emerald-300 border-emerald-500'
                        : scrim.status === 'finished'
                        ? 'bg-[#140A0D] text-[#8E7E81] border-[#2C141A]'
                        : 'bg-[#1C0B10] text-[#F08C96] border-[#8F1622]/60'
                    }`}
                  >
                    {scrim.status === 'live'
                      ? 'CANLI'
                      : scrim.status === 'finished'
                      ? 'TAMAMLANDI'
                      : 'PLANLANDI'}
                  </span>
                </div>
              </div>
            ))}
          </div>
            </>
          )}
        </div>

        {/* Footer */}
        <div className="p-4 border-t border-[#241116] flex items-center justify-end bg-[#0E070A]">
          <button
            type="button"
            onClick={onClose}
            className="px-4 py-2 rounded-xl bg-[#180B10] hover:bg-[#281016] border border-[#3C141E] text-xs font-bold text-[#FAF2EE]"
          >
            Kapat
          </button>
        </div>
      </div>
    </div>
  );
};
