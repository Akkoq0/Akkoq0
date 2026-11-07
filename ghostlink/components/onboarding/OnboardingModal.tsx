'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — 18-Game Dynamic Profile & Onboarding Engine
// ─────────────────────────────────────────────────────────
// 3-Step 100% Optional Flow with "Hızlı Geç (Skip)":
//   • Step 1: 18 Root Esports Games selection (Primary & Favorites)
//   • Step 2: Dynamic per-game tactical roles (LoL, CS2, Dota 2, PUBG, Valo, etc.)
//   • Step 3: Community Style Tags (#Tryhard-Dereceli, #Scrim-Turnuva, etc.)
//   • IndexedDB Persistence & Live Store Hydration

import React, { useState, useEffect } from 'react';
import { useAppStore } from '@/lib/store';
import { useHUDStore } from '@/store/useHUDStore';
import { getMevaStorageEngine, STORE_PREFS } from '@/src/lib/storageEngine';
import {
  SUPPORTED_GAMES,
  COMMUNITY_TAGS,
  type SupportedGameId,
} from '@/src/lib/gameRegistry';
import {
  IconClose,
  IconShield,
  IconBolt,
  IconCheck,
} from '@/components/ui/MevaIcons';

interface OnboardingModalProps {
  isOpen: boolean;
  onClose: () => void;
  onCompleted?: (callsign: string, primaryGame: SupportedGameId, role: string) => void;
}

export const OnboardingModal: React.FC<OnboardingModalProps> = ({
  isOpen,
  onClose,
  onCompleted,
}) => {
  const [step, setStep] = useState<1 | 2 | 3>(1);
  const [callsign, setCallsign] = useState('Operatör');
  const [primaryGame, setPrimaryGame] = useState<SupportedGameId>('cs2');
  const [favoriteGames, setFavoriteGames] = useState<SupportedGameId[]>([
    'cs2',
    'valorant',
    'lol',
  ]);
  const [gameRoles, setGameRoles] = useState<Record<string, string>>({
    cs2: 'IGL',
    valorant: 'DUELIST',
    lol: 'JUNGLE',
    dota2: 'POS 1 (CARRY)',
    pubg: 'IGL',
  });
  const [selectedTags, setSelectedTags] = useState<string[]>([
    '#Tryhard-Dereceli',
    '#Scrim-Turnuva',
  ]);

  const setUserPrimaryGame = useAppStore((s) => s.setUserPrimaryGame);
  const setUserFavoriteGames = useAppStore((s) => s.setUserFavoriteGames);
  const setUserGameRole = useAppStore((s) => s.setUserGameRole);
  const setUserCommunityTags = useAppStore((s) => s.setUserCommunityTags);
  const setOperatorRole = useHUDStore((s) => s.setOperatorRole);

  useEffect(() => {
    let active = true;
    async function loadSaved() {
      try {
        const storage = getMevaStorageEngine();
        const saved = await storage.getRecord<any>(STORE_PREFS, 'operator_identity');
        if (active && saved) {
          if (saved.callsign) setCallsign(saved.callsign);
          if (saved.primaryGame) setPrimaryGame(saved.primaryGame);
          if (saved.favoriteGames) setFavoriteGames(saved.favoriteGames);
          if (saved.gameRoles) setGameRoles(saved.gameRoles);
          if (saved.tags) setSelectedTags(saved.tags);
        }
      } catch {}
    }
    void loadSaved();
    return () => {
      active = false;
    };
  }, []);

  if (!isOpen) return null;

  const toggleFavorite = (gId: SupportedGameId) => {
    if (favoriteGames.includes(gId)) {
      if (favoriteGames.length > 1) {
        setFavoriteGames(favoriteGames.filter((id) => id !== gId));
        if (primaryGame === gId) {
          const next = favoriteGames.find((id) => id !== gId) ?? 'cs2';
          setPrimaryGame(next);
        }
      }
    } else {
      setFavoriteGames([...favoriteGames, gId]);
    }
  };

  const toggleTag = (tag: string) => {
    if (selectedTags.includes(tag)) {
      setSelectedTags(selectedTags.filter((t) => t !== tag));
    } else {
      setSelectedTags([...selectedTags, tag]);
    }
  };

  const handleFinish = async () => {
    const assignedRole = gameRoles[primaryGame] || 'IGL';

    // Store in Zustand
    setUserPrimaryGame(primaryGame);
    setUserFavoriteGames(favoriteGames);
    Object.entries(gameRoles).forEach(([gid, r]) => setUserGameRole(gid, r));
    setUserCommunityTags(selectedTags);
    setOperatorRole('usr-local', assignedRole);

    // Persist to IndexedDB
    try {
      const storage = getMevaStorageEngine();
      storage.scheduleWrite(STORE_PREFS, 'operator_identity', {
        callsign: callsign.trim() || 'Operatör',
        primaryGame,
        favoriteGames,
        gameRoles,
        role: assignedRole,
        tags: selectedTags,
        updatedAt: Date.now(),
      });
      void storage.flushPendingWrites();
    } catch {}

    if (onCompleted) {
      onCompleted(callsign.trim() || 'Operatör', primaryGame, assignedRole);
    }
    onClose();
  };

  const currentGameDef = SUPPORTED_GAMES[primaryGame] ?? SUPPORTED_GAMES.cs2;

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-3.5 sm:p-4 exec-backdrop"
      onClick={onClose}
    >
      <div
        className="w-full max-w-2xl bg-[#0F080B]/98 border border-[#7A121D]/55 rounded-2xl shadow-[0_24px_80px_rgba(0,0,0,0.85)] flex flex-col max-h-[92vh] overflow-hidden font-sans"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Top Header */}
        <div className="px-5 py-4 border-b border-[#7A121D]/35 flex items-center justify-between bg-gradient-to-r from-[#2A0910]/80 via-[#14080B] to-[#12070A]">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-[#590C15]/40 border border-[#A61826]/60 flex items-center justify-center text-[#F08C96]">
              <IconShield size={20} />
            </div>
            <div>
              <h2 className="text-base font-extrabold text-[#FAF2EE] tracking-wide">
                18 Oyunlu Dinamik Operatör Profili
              </h2>
              <p className="text-xs text-[#A58D8E]">
                Adım {step}/3 · {step === 1 ? 'Köklü Espor Oyunları' : step === 2 ? 'Oyuna Özel Roller' : 'Kanal Tarzı Etiketleri'}
              </p>
            </div>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="w-8 h-8 rounded-lg bg-[#180A0E] hover:bg-[#281016] border border-[#590C15]/45 text-[#A58D8E] hover:text-[#FAF2EE] flex items-center justify-center transition-colors"
          >
            <IconClose size={16} />
          </button>
        </div>

        {/* Step Progress Bar & Skip Button */}
        <div className="px-5 py-2.5 bg-[#14080B] border-b border-[#3B141C] flex items-center justify-between">
          <div className="flex items-center gap-2">
            {[1, 2, 3].map((s) => (
              <button
                key={s}
                type="button"
                onClick={() => setStep(s as any)}
                className={`flex items-center gap-1.5 px-3 py-1 rounded-lg text-xs font-bold transition-all ${
                  step === s
                    ? 'bg-[#7A121D] text-[#FAF2EE]'
                    : step > s
                      ? 'bg-[#2E0B12] text-[#F08C96]'
                      : 'bg-[#180A0E] text-[#8E7E81]'
                }`}
              >
                <span>{s}</span>
                <span className="hidden sm:inline">
                  {s === 1 ? 'Oyunlar' : s === 2 ? 'Roller' : 'Etiketler'}
                </span>
              </button>
            ))}
          </div>

          <button
            type="button"
            onClick={handleFinish}
            className="text-xs font-bold text-[#A58D8E] hover:text-[#FAF2EE] px-2.5 py-1 rounded hover:bg-[#240C12] transition-colors"
          >
            Hızlı Geç (Skip) ⏩
          </button>
        </div>

        {/* Step Content */}
        <div className="flex-1 overflow-y-auto p-5 space-y-5">
          {/* ── STEP 1: 18 Köklü Espor Oyunu ── */}
          {step === 1 && (
            <div className="space-y-4">
              <div>
                <label className="text-xs font-bold uppercase tracking-wider text-[#C4B2B5] block mb-1">
                  Operatör Çağrı Adın (Callsign)
                </label>
                <input
                  type="text"
                  value={callsign}
                  onChange={(e) => setCallsign(e.target.value)}
                  placeholder="örn: Ghost_TR"
                  maxLength={24}
                  className="w-full h-10 px-3 rounded-xl bg-[#14080B] border border-[#48121B] focus:border-[#C82333] text-sm font-bold text-[#FAF2EE] outline-none"
                />
              </div>

              <div>
                <div className="flex items-center justify-between mb-2">
                  <span className="text-xs font-bold uppercase tracking-wider text-[#C4B2B5]">
                    Aktif Oynadığın Oyunlar (18 Köklü Espor Başlığı)
                  </span>
                  <span className="text-[11px] text-[#A58D8E]">
                    Birincil: <strong className="text-[#F08C96]">{SUPPORTED_GAMES[primaryGame]?.shortName}</strong>
                  </span>
                </div>

                <div className="grid grid-cols-2 sm:grid-cols-3 gap-2">
                  {Object.values(SUPPORTED_GAMES).map((g) => {
                    const isSelected = favoriteGames.includes(g.id);
                    const isPrimary = primaryGame === g.id;

                    return (
                      <div
                        key={g.id}
                        className={`p-2.5 rounded-xl border text-left transition-all flex flex-col justify-between ${
                          isPrimary
                            ? 'bg-[#3D0A14] border-[#A61826] shadow-[0_0_12px_rgba(200,35,51,0.25)]'
                            : isSelected
                              ? 'bg-[#1F0A12] border-[#590C15] text-[#FAF2EE]'
                              : 'bg-[#14080B] border-[#2A1016] text-[#8E7E81] hover:bg-[#1A0A0F]'
                        }`}
                      >
                        <div className="flex items-center justify-between mb-1">
                          <button
                            type="button"
                            onClick={() => toggleFavorite(g.id)}
                            className="flex items-center gap-1.5 min-w-0 flex-1 text-left"
                          >
                            <span
                              className="w-2 h-2 rounded-full flex-shrink-0"
                              style={{ backgroundColor: g.color }}
                            />
                            <span className="text-xs font-bold truncate text-[#FAF2EE]">
                              {g.shortName}
                            </span>
                          </button>
                          {isSelected && (
                            <span className="text-[10px] text-[#F08C96]">
                              <IconCheck size={12} />
                            </span>
                          )}
                        </div>

                        <div className="flex items-center justify-between pt-1 border-t border-[#3B141C]/40 text-[10.5px]">
                          <span className="text-[#8E7E81] uppercase">{g.category}</span>
                          <button
                            type="button"
                            onClick={() => {
                              if (!favoriteGames.includes(g.id)) {
                                setFavoriteGames([...favoriteGames, g.id]);
                              }
                              setPrimaryGame(g.id);
                            }}
                            className={`px-1.5 py-0.5 rounded text-[10px] font-bold ${
                              isPrimary
                                ? 'bg-[#C82333] text-[#FAF2EE]'
                                : 'text-[#A58D8E] hover:text-[#FAF2EE]'
                            }`}
                          >
                            {isPrimary ? 'Ana Oyun' : 'Ana Yap'}
                          </button>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            </div>
          )}

          {/* ── STEP 2: Seçilen Her Oyuna Özel Dinamik Roller ── */}
          {step === 2 && (
            <div className="space-y-5">
              <div>
                <span className="text-xs font-bold uppercase tracking-wider text-[#C4B2B5] block mb-1">
                  {currentGameDef.name} — Taktik Rol Seçimi
                </span>
                <p className="text-xs text-[#A58D8E] mb-3">
                  Bu oyuna girdiğinde veya lobide bu oyun oynandığında rozetinde ve taktik ses motorunda bu rol görünür.
                </p>

                <div className="space-y-2">
                  {currentGameDef.roles.map((r) => {
                    const currentRole = gameRoles[primaryGame] || currentGameDef.roles[0]?.key;
                    const isSelected = currentRole === r.key;

                    return (
                      <button
                        key={r.key}
                        type="button"
                        onClick={() =>
                          setGameRoles((prev) => ({ ...prev, [primaryGame]: r.key }))
                        }
                        className={`w-full p-3 rounded-xl border text-left flex items-center justify-between transition-all ${
                          isSelected
                            ? 'bg-[#3D0A14] border-[#A61826] shadow-[0_0_12px_rgba(200,35,51,0.25)]'
                            : 'bg-[#14080B] border-[#3B141C] hover:bg-[#1C0A10]'
                        }`}
                      >
                        <div className="flex items-center gap-3 min-w-0">
                          <span
                            className={`px-2 py-0.5 rounded text-[11px] font-extrabold border ${r.badgeClass}`}
                          >
                            {r.shortLabel}
                          </span>
                          <div className="min-w-0">
                            <span className="text-xs font-bold text-[#FAF2EE] block truncate">
                              {r.label}
                            </span>
                            <span className="text-[11px] text-[#A58D8E] block truncate">
                              {r.desc}
                            </span>
                          </div>
                        </div>

                        {isSelected && (
                          <div className="w-6 h-6 rounded-full bg-[#C82333] flex items-center justify-center text-[#FAF2EE] flex-shrink-0">
                            <IconCheck size={14} />
                          </div>
                        )}
                      </button>
                    );
                  })}
                </div>
              </div>

              {/* Quick Switch Primary Game if multi selected */}
              {favoriteGames.length > 1 && (
                <div className="pt-3 border-t border-[#3B141C]">
                  <span className="text-[11px] font-semibold text-[#A58D8E] block mb-2">
                    Diğer favori oyunlarının rollerini de düzenle:
                  </span>
                  <div className="flex flex-wrap gap-1.5">
                    {favoriteGames.map((gid) => {
                      const g = SUPPORTED_GAMES[gid];
                      const active = primaryGame === gid;
                      return (
                        <button
                          key={gid}
                          type="button"
                          onClick={() => setPrimaryGame(gid)}
                          className={`px-2.5 py-1 rounded-lg text-xs font-bold border transition-colors ${
                            active
                              ? 'bg-[#7A121D] border-[#A61826] text-[#FAF2EE]'
                              : 'bg-[#14080B] border-[#3B141C] text-[#8E7E81]'
                          }`}
                        >
                          {g?.shortName} ({gameRoles[gid] ?? g?.roles[0]?.shortLabel})
                        </button>
                      );
                    })}
                  </div>
                </div>
              )}
            </div>
          )}

          {/* ── STEP 3: Kanal Tarzı Etiketleri ── */}
          {step === 3 && (
            <div className="space-y-4">
              <div>
                <span className="text-xs font-bold uppercase tracking-wider text-[#C4B2B5] block mb-1">
                  Kanal & Topluluk Tarzı Etiketleri
                </span>
                <p className="text-xs text-[#A58D8E] mb-3">
                  Sunucudaki kanalları sana göre eşleştirmek ve tavsiye etmek için tercih ettiğin oyun stillerini seç:
                </p>

                <div className="grid grid-cols-2 gap-2.5">
                  {COMMUNITY_TAGS.map((tag) => {
                    const isSelected = selectedTags.includes(tag);
                    return (
                      <button
                        key={tag}
                        type="button"
                        onClick={() => toggleTag(tag)}
                        className={`p-3 rounded-xl border text-left flex items-center justify-between transition-all ${
                          isSelected
                            ? 'bg-[#3D0A14] border-[#A61826] text-[#FAF2EE]'
                            : 'bg-[#14080B] border-[#3B141C] text-[#8E7E81] hover:bg-[#1C0A10]'
                        }`}
                      >
                        <span className="text-xs font-extrabold">{tag}</span>
                        {isSelected && (
                          <span className="text-[#F08C96]">
                            <IconCheck size={14} />
                          </span>
                        )}
                      </button>
                    );
                  })}
                </div>
              </div>

              {/* Summary Card */}
              <div className="p-3.5 rounded-xl bg-[#160A0E] border border-[#590C15]/50 flex items-center justify-between">
                <div>
                  <span className="text-xs font-extrabold text-[#FAF2EE] block">
                    Hazır mısın, {callsign}?
                  </span>
                  <span className="text-[11px] text-[#A58D8E]">
                    Ana Oyun: {currentGameDef.name} · Rol: {gameRoles[primaryGame] || 'IGL'}
                  </span>
                </div>
                <div className="w-8 h-8 rounded-lg bg-[#590C15]/40 border border-[#A61826]/60 flex items-center justify-center text-[#F08C96]">
                  <IconBolt size={16} />
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Footer Navigation */}
        <div className="px-5 py-3.5 border-t border-[#7A121D]/35 bg-[#12070A] flex items-center justify-between">
          {step > 1 ? (
            <button
              type="button"
              onClick={() => setStep((s) => (s - 1) as any)}
              className="h-9 px-4 rounded-xl bg-[#1A0A0F] border border-[#3B141C] text-xs font-bold text-[#A58D8E] hover:text-[#FAF2EE] transition-colors"
            >
              ← Geri
            </button>
          ) : (
            <div />
          )}

          <div className="flex gap-2">
            {step < 3 ? (
              <button
                type="button"
                onClick={() => setStep((s) => (s + 1) as any)}
                className="h-9 px-5 rounded-xl bg-[#C82333] hover:bg-[#D63344] text-xs font-extrabold text-[#FAF2EE] shadow-md transition-all"
              >
                İleri →
              </button>
            ) : (
              <button
                type="button"
                onClick={handleFinish}
                className="h-9 px-6 rounded-xl bg-[#C82333] hover:bg-[#D63344] text-xs font-extrabold text-[#FAF2EE] shadow-md transition-all flex items-center gap-1.5"
              >
                <IconCheck size={14} />
                <span>Profili Kaydet & Başla</span>
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};
