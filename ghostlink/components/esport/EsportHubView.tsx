'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Global Esports Hub (HLTV / VLR.gg Tier Platform)
// ─────────────────────────────────────────────────────────
// Live tournament schedules, real-time scorecards, map telemetry,
// breaking news grid, and direct bridge to Tactical Stratboard.

import { memo, useState, useMemo, useCallback, useEffect } from 'react';
import type {
  EsportGame,
  EsportMatch,
  EsportNewsItem,
  NewsCategory,
} from '@/types/esport';
import { ESPORT_GAMES, ESPORT_STANDINGS } from '@/lib/esportData';
import {
  fetchLiveEsportHubData,
  getCachedEsportHubBundle,
} from '@/lib/esportDataService';
import {
  IconSearch,
  IconMapBoard,
} from '@/components/ui/MevaIcons';

const AUTO_REFRESH_INTERVAL_MS = 5 * 60 * 1000;

interface EsportHubViewProps {
  onOpenTacticalMap?: (mapId?: string) => void;
}

export const EsportHubView = memo(function EsportHubView({
  onOpenTacticalMap,
}: EsportHubViewProps) {
  const [selectedGame, setSelectedGame] = useState<EsportGame>('cs2');
  const [searchQuery, setSearchQuery] = useState('');
  const [activeCategoryFilter, setActiveCategoryFilter] = useState<
    'all' | 'live' | 'upcoming' | 'news' | 'standings'
  >('all');
  const [newsFilter, setNewsFilter] = useState<NewsCategory | 'all'>('all');
  const [selectedMatch, setSelectedMatch] = useState<EsportMatch | null>(null);

  const [liveNews, setLiveNews] = useState<EsportNewsItem[]>([]);
  const [liveMatches, setLiveMatches] = useState<EsportMatch[]>([]);
  const [isRefreshing, setIsRefreshing] = useState<boolean>(false);
  const [lastUpdatedText, setLastUpdatedText] = useState<string>('Yükleniyor...');
  const [isLiveFeedConnected, setIsLiveFeedConnected] = useState<boolean>(false);

  const loadLiveData = useCallback(async (forceRefresh = false) => {
    setIsRefreshing(true);
    try {
      const bundle = await fetchLiveEsportHubData(forceRefresh);
      setLiveNews(bundle.news);
      setLiveMatches(bundle.matches);
      setLastUpdatedText(bundle.fetchedAtLabel);
      setIsLiveFeedConnected(bundle.liveSourcesCount > 0);
    } finally {
      setIsRefreshing(false);
    }
  }, []);

  useEffect(() => {
    const cached = getCachedEsportHubBundle();
    if (cached) {
      setLiveNews(cached.news);
      setLiveMatches(cached.matches);
      setLastUpdatedText(cached.fetchedAtLabel);
      setIsLiveFeedConnected(cached.liveSourcesCount > 0);
    }
    void loadLiveData(false);
    const intervalId = setInterval(() => {
      void loadLiveData(true);
    }, AUTO_REFRESH_INTERVAL_MS);
    return () => clearInterval(intervalId);
  }, [loadLiveData]);

  // Filtered matches from real-time service
  const filteredMatches = useMemo(() => {
    return liveMatches.filter((m) => {
      if (m.game !== selectedGame) return false;
      if (activeCategoryFilter === 'live' && m.status !== 'live') return false;
      if (activeCategoryFilter === 'upcoming' && m.status !== 'upcoming')
        return false;
      if (searchQuery.trim()) {
        const q = searchQuery.toLowerCase();
        const matchTitle = `${m.tournament} ${m.team1.name} ${m.team2.name} ${m.team1.tag} ${m.team2.tag} ${m.currentMap ?? ''}`.toLowerCase();
        return matchTitle.includes(q);
      }
      return true;
    });
  }, [liveMatches, selectedGame, activeCategoryFilter, searchQuery]);

  // Filtered live RSS news
  const filteredNews = useMemo(() => {
    const gameMatches = liveNews.filter((n) => {
      if (n.game !== 'all' && n.game !== selectedGame) return false;
      if (newsFilter !== 'all' && n.category !== newsFilter) return false;
      if (searchQuery.trim()) {
        const q = searchQuery.toLowerCase();
        const text = `${n.title} ${n.summary} ${n.source} ${n.tags.join(' ')}`.toLowerCase();
        return text.includes(q);
      }
      return true;
    });

    // If LoL/global feed has general esports stories when filtered tightly, keep selected game first
    return gameMatches;
  }, [liveNews, selectedGame, newsFilter, searchQuery]);

  // Current Standings for selected game
  const currentStandings = useMemo(() => {
    return ESPORT_STANDINGS.find((s) => s.game === selectedGame);
  }, [selectedGame]);

  const activeGameMeta = useMemo(() => {
    return ESPORT_GAMES.find((g) => g.id === selectedGame) ?? ESPORT_GAMES[0];
  }, [selectedGame]);

  const handleLaunchTacticalMap = useCallback(
    (mapId?: string) => {
      if (onOpenTacticalMap) {
        onOpenTacticalMap(mapId);
      }
    },
    [onOpenTacticalMap],
  );

  return (
    <div className="w-full h-full flex flex-col overflow-y-auto no-scrollbar font-sans select-none text-[#F4EFF0] px-3 sm:px-6 pt-3 pb-24 gap-4">
      {/* ── TOP INDUSTRIAL ESPORT HEADER & GAME FILTER STRIP ── */}
      <header className="flex flex-col gap-3 flex-shrink-0">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-[#8F1622] to-[#3B0E17] border border-[#C82333]/70 flex items-center justify-center text-xl shadow-[0_0_20px_rgba(200,35,51,0.35)] flex-shrink-0">
              🏆
            </div>
            <div className="min-w-0">
              <div className="flex items-center gap-2 flex-wrap">
                <h1 className="text-base sm:text-xl font-black tracking-tight text-[#FAF2EE] whitespace-nowrap">
                  ESPORT COMMAND HUB
                </h1>
                <span className="px-2 py-0.5 rounded-full text-[9.5px] sm:text-[10px] font-mono font-black bg-[#4A0D18] text-[#FF5A6B] border border-[#C82333]/50 animate-pulse whitespace-nowrap flex-shrink-0">
                  ● CANLI TELEMETRİ
                </span>
              </div>
              <p className="text-[11px] sm:text-[11.5px] text-[#A8989B] font-medium leading-snug mt-0.5">
                HLTV &amp; VLR.gg Standartlarında Canlı Maç Skorları, Turnuva Fikstürü &amp; Taktik Köprüsü
              </p>
            </div>
          </div>

          {/* Quick Search Bar */}
          <div className="relative w-full sm:w-auto sm:min-w-[260px]">
            <input
              id="esport-hub-search"
              name="esportSearch"
              type="text"
              aria-label="Takım, turnuva veya harita ara"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Takım, turnuva veya harita ara..."
              className="w-full h-9 pl-8 pr-8 rounded-xl bg-[#12070A]/90 border border-[#2D141B] hover:border-[#8F1622]/60 focus:border-[#C82333] text-xs font-semibold text-[#FAF2EE] placeholder-[#6E5E62] focus:outline-none transition-colors"
            />
            <IconSearch
              size={13}
              className="absolute left-2.5 top-1/2 -translate-y-1/2 text-[#8E7E81]"
            />
            {searchQuery && (
              <button
                type="button"
                onClick={() => setSearchQuery('')}
                className="absolute right-2.5 top-1/2 -translate-y-1/2 text-xs font-bold text-[#8E7E81] hover:text-[#FAF2EE]"
              >
                ✕
              </button>
            )}
          </div>
        </div>

        {/* ── GAME SELECTOR PILLS (CS2, Valorant, LoL, Dota 2) ── */}
        <div className="flex items-center gap-2 overflow-x-auto no-scrollbar py-1">
          {ESPORT_GAMES.map((game) => {
            const isSelected = game.id === selectedGame;
            return (
              <button
                key={game.id}
                type="button"
                onClick={() => setSelectedGame(game.id)}
                className={`h-10 px-4 rounded-xl flex items-center gap-2 text-xs font-black transition-all flex-shrink-0 active:scale-95 border ${
                  isSelected
                    ? 'bg-gradient-to-r from-[#8F1622] via-[#521019] to-[#1E090F] text-[#FAF2EE] border-[#C82333] shadow-[0_0_20px_rgba(200,35,51,0.4)]'
                    : 'bg-[#10070A]/90 text-[#9E8E91] hover:text-[#FAF2EE] border-[#261016] hover:border-[#6E141E]'
                }`}
              >
                <span className="text-base">{game.icon}</span>
                <span>{game.name}</span>
                <span
                  className={`text-[9.5px] px-1.5 py-0.2 rounded-md font-mono ${
                    isSelected
                      ? 'bg-[#2E0B12] text-[#FF7582] border border-[#C82333]/50'
                      : 'bg-[#180A0E] text-[#6E5E61]'
                  }`}
                >
                  {game.badge}
                </span>
              </button>
            );
          })}
        </div>

        {/* View Category Sub-Tabs */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 border-b border-[#241116] pb-2 text-xs font-bold">
          <div className="flex items-center gap-1.5 overflow-x-auto no-scrollbar pb-0.5">
            {[
              { id: 'all', label: 'Tüm Modüller' },
              { id: 'live', label: '🔴 Canlı Maçlar' },
              { id: 'upcoming', label: '📅 Maç Takvimi' },
              { id: 'news', label: '📰 Espor Haberleri' },
              { id: 'standings', label: '📊 Puan Durumu' },
            ].map((tab) => (
              <button
                key={tab.id}
                type="button"
                onClick={() =>
                  setActiveCategoryFilter(
                    tab.id as 'all' | 'live' | 'upcoming' | 'news' | 'standings',
                  )
                }
                className={`h-9 px-3 rounded-xl inline-flex items-center gap-1.5 whitespace-nowrap flex-shrink-0 transition-all active:scale-95 ${
                  activeCategoryFilter === tab.id
                    ? 'bg-[#380E17] text-[#FAF2EE] border border-[#8F1622]'
                    : 'bg-[#11070A] text-[#8E7E81] hover:text-[#FAF2EE] hover:bg-[#150A0E] border border-[#220E14]'
                }`}
              >
                {tab.label}
              </button>
            ))}
          </div>

          <div className="flex items-center gap-2 text-[11px] text-[#A8989B] flex-shrink-0">
            <span
              className={`w-2 h-2 rounded-full ${
                isLiveFeedConnected ? 'bg-emerald-400 animate-pulse' : 'bg-amber-400'
              }`}
            />
            <span className="font-mono whitespace-nowrap">
              {isLiveFeedConnected ? 'CANLI RSS/API AKTİF' : 'BESLEME BEKLENİYOR'} · Son Güncelleme:{' '}
              <strong className="text-[#FAF2EE]">{lastUpdatedText}</strong> (5 dk&apos;da bir otomatik)
            </span>
            <button
              type="button"
              onClick={() => void loadLiveData(true)}
              disabled={isRefreshing}
              title="Canlı espor haber ve maç verilerini şimdi yenile"
              className="h-7 px-2.5 rounded-lg bg-[#1A0A0F] hover:bg-[#380E17] border border-[#6E141E] text-[10.5px] font-extrabold text-[#FAF2EE] flex items-center gap-1 transition-all disabled:opacity-60 active:scale-95"
            >
              <span className={isRefreshing ? 'inline-block animate-spin' : ''}>🔄</span>
              <span>{isRefreshing ? 'Yenileniyor...' : 'Şimdi Yenile'}</span>
            </button>
          </div>
        </div>
      </header>

      {/* ── MAIN CONTENT GRID ── */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-4 flex-1">
        {/* LEFT / CENTER COLUMN (8 Cols): MATCHES & LIVE SCORE TELEMETRY */}
        {(activeCategoryFilter === 'all' ||
          activeCategoryFilter === 'live' ||
          activeCategoryFilter === 'upcoming') && (
          <section
            className={`${
              activeCategoryFilter === 'all' ? 'lg:col-span-8' : 'lg:col-span-12'
            } flex flex-col gap-3.5`}
          >
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <span className="w-2 h-3.5 rounded-sm bg-[#C82333]" />
                <h2 className="text-sm font-extrabold text-[#FAF2EE] tracking-wide">
                  {activeGameMeta.name} Turnuva Maçları & Canlı Skorlar
                </h2>
                <span className="px-2 py-0.5 rounded text-[10px] font-mono bg-[#1C0B10] text-[#E08C96] border border-[#3D141D]">
                  {filteredMatches.length} Maç
                </span>
              </div>
            </div>

            {/* Match Cards List */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
              {filteredMatches.map((match) => {
                const isLive = match.status === 'live';
                return (
                  <div
                    key={match.id}
                    onClick={() => setSelectedMatch(match)}
                    className={`rounded-2xl border p-3.5 flex flex-col justify-between gap-3 transition-all cursor-pointer relative overflow-hidden group ${
                      isLive
                        ? 'bg-gradient-to-b from-[#220B12]/90 to-[#0F0609]/95 border-[#C82333]/80 shadow-[0_4px_24px_rgba(200,35,51,0.22)] ring-1 ring-[#C82333]/30'
                        : 'bg-[#11070A]/85 hover:bg-[#180A0E] border-[#281218] hover:border-[#6E141E]'
                    }`}
                  >
                    {/* Top Tournament Strip */}
                    <div className="flex items-center justify-between text-[10.5px]">
                      <div className="flex items-center gap-1.5 truncate max-w-[70%]">
                        <span className="font-extrabold text-[#FAF2EE] truncate">
                          {match.tournament}
                        </span>
                        <span className="text-[#8E7E81]">· {match.stage}</span>
                      </div>
                      <div className="flex items-center gap-1 flex-shrink-0">
                        <span className="px-1.5 py-0.2 rounded font-mono font-bold bg-[#1E0B12] text-[#E08C96] border border-[#3D141D]">
                          {match.format}
                        </span>
                        {isLive ? (
                          <span className="px-2 py-0.5 rounded-full font-black text-[9.5px] bg-[#590C15] text-[#FF5A6B] border border-[#C82333] animate-pulse flex items-center gap-1">
                            <span className="w-1.5 h-1.5 rounded-full bg-emerald-400" />
                            {match.timeLabel}
                          </span>
                        ) : (
                          <span className="px-2 py-0.5 rounded text-[10px] font-mono font-semibold bg-[#14080B] text-[#A8989B]">
                            {match.timeLabel}
                          </span>
                        )}
                      </div>
                    </div>

                    {/* Team VS Team Row with High-Contrast Scoreboard */}
                    <div className="rounded-xl bg-[#0B0507]/90 border border-[#220E14] p-2.5 flex items-center justify-between gap-2">
                      {/* Team 1 */}
                      <div className="flex-1 flex items-center gap-2.5 min-w-0">
                        <div
                          style={{ borderColor: match.team1.logoColor }}
                          className="w-8 h-8 rounded-lg bg-[#180A0E] border-2 flex items-center justify-center font-black text-xs text-[#FAF2EE] flex-shrink-0 shadow-inner"
                        >
                          {match.team1.tag.slice(0, 3)}
                        </div>
                        <div className="min-w-0">
                          <div className="flex items-center gap-1.5">
                            <span className="font-extrabold text-[13px] text-[#FAF2EE] truncate">
                              {match.team1.name}
                            </span>
                            <span className="text-[9px] font-mono text-[#8E7E81]">
                              #{match.team1.rank}
                            </span>
                          </div>
                          <div className="flex items-center gap-0.5 mt-0.5">
                            {match.team1.form.map((f, i) => (
                              <span
                                key={i}
                                className={`w-3 h-3 rounded-[3px] text-[8px] font-black flex items-center justify-center ${
                                  f === 'W'
                                    ? 'bg-emerald-950 text-emerald-400 border border-emerald-600/40'
                                    : 'bg-rose-950 text-rose-400 border border-rose-600/40'
                                }`}
                              >
                                {f}
                              </span>
                            ))}
                          </div>
                        </div>
                      </div>

                      {/* Scores Pill */}
                      <div className="flex flex-col items-center justify-center px-3 py-1 rounded-lg bg-[#19090E] border border-[#3D141D] flex-shrink-0">
                        <span className="font-mono text-base font-black text-[#FAF2EE] tracking-widest">
                          {match.team1.score} : {match.team2.score}
                        </span>
                        {match.streamViewerCount && (
                          <span className="text-[9px] text-[#FF7582] font-mono mt-0.5">
                            {match.streamViewerCount}
                          </span>
                        )}
                      </div>

                      {/* Team 2 */}
                      <div className="flex-1 flex items-center justify-end gap-2.5 min-w-0 text-right">
                        <div className="min-w-0">
                          <div className="flex items-center justify-end gap-1.5">
                            <span className="text-[9px] font-mono text-[#8E7E81]">
                              #{match.team2.rank}
                            </span>
                            <span className="font-extrabold text-[13px] text-[#FAF2EE] truncate">
                              {match.team2.name}
                            </span>
                          </div>
                          <div className="flex items-center justify-end gap-0.5 mt-0.5">
                            {match.team2.form.map((f, i) => (
                              <span
                                key={i}
                                className={`w-3 h-3 rounded-[3px] text-[8px] font-black flex items-center justify-center ${
                                  f === 'W'
                                    ? 'bg-emerald-950 text-emerald-400 border border-emerald-600/40'
                                    : 'bg-rose-950 text-rose-400 border border-rose-600/40'
                                }`}
                              >
                                {f}
                              </span>
                            ))}
                          </div>
                        </div>
                        <div
                          style={{ borderColor: match.team2.logoColor }}
                          className="w-8 h-8 rounded-lg bg-[#180A0E] border-2 flex items-center justify-center font-black text-xs text-[#FAF2EE] flex-shrink-0 shadow-inner"
                        >
                          {match.team2.tag.slice(0, 3)}
                        </div>
                      </div>
                    </div>

                    {/* Bottom Status, External Match Link & Tactical Strat Bridge */}
                    <div className="flex items-center justify-between gap-2 text-xs pt-0.5 flex-wrap">
                      <span className="text-[11px] text-[#A8989B] truncate max-w-[46%]">
                        {match.currentMap ? `📍 ${match.currentMap}` : 'Resmi Turnuva Kaydı'}
                      </span>

                      <div className="flex items-center gap-1.5 flex-shrink-0">
                        <a
                          href={match.matchUrl || activeGameMeta.matchesPortalUrl}
                          target="_blank"
                          rel="noopener noreferrer"
                          onClick={(e) => e.stopPropagation()}
                          title="Maçın orijinal kaynak sayfasını yeni sekmede aç"
                          className="h-7 px-2.5 rounded-lg bg-[#160A0E] hover:bg-[#261017] text-[#E08C96] hover:text-[#FAF2EE] border border-[#3D141D] font-bold text-[10.5px] transition-all flex items-center gap-1"
                        >
                          <span>Canlı Maç Sayfası ↗</span>
                        </a>

                        {/* Taktik Masası Köprüsü */}
                        <button
                          type="button"
                          onClick={(e) => {
                            e.stopPropagation();
                            handleLaunchTacticalMap(match.tacticalMapId);
                          }}
                          title={`${match.tournament} stratejisini taktik tahtasında çiz`}
                          className="h-7 px-2.5 rounded-lg bg-[#2A0E15] hover:bg-[#590C15] text-[#FF7582] hover:text-[#FAF2EE] border border-[#6E141E] hover:border-[#C82333] font-bold text-[10.5px] transition-all flex items-center gap-1.5 shadow-sm active:scale-95"
                        >
                          <IconMapBoard size={12} />
                          <span>Taktik Tahtasında İncele ↗</span>
                        </button>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>

            {filteredMatches.length === 0 && (
              <div className="p-5 sm:p-6 rounded-2xl bg-[#0F070A]/80 backdrop-blur-md border border-[#8F1622]/45 shadow-[0_8px_28px_rgba(0,0,0,0.65)] flex flex-col sm:flex-row items-center justify-between gap-4">
                <div className="flex items-start gap-3">
                  <div className="w-10 h-10 rounded-xl bg-[#220B12] border border-[#8F1622]/70 flex items-center justify-center text-xl flex-shrink-0">
                    {isRefreshing ? <span className="animate-spin">🔄</span> : activeGameMeta.icon}
                  </div>
                  <div className="space-y-1">
                    <div className="flex items-center gap-2 flex-wrap">
                      <h3 className="text-sm font-black text-[#FAF2EE]">
                        {isRefreshing ? 'Canlı Veri Güncelleniyor...' : `${activeGameMeta.name} — Canlı Veri Güncelleniyor...`}
                      </h3>
                      <span className="px-2 py-0.5 rounded-full text-[9.5px] font-mono font-bold bg-[#2E0B12] text-[#FF7582] border border-[#6E141E] animate-pulse">
                        HLTV.org · VLR.gg · OpenDota · LoL Esports
                      </span>
                    </div>
                    <p className="text-xs text-[#A8989B] max-w-xl leading-relaxed">
                      Gerçek zamanlı RSS/API akışı doğrulanıyor. Resmi{' '}
                      <strong className="text-[#FAF2EE]">{activeGameMeta.name}</strong> fikstürüne doğrudan erişebilir veya akışı anlık yenileyebilirsiniz.
                    </p>
                  </div>
                </div>
                <div className="flex items-center gap-2 flex-shrink-0 flex-wrap">
                  <button
                    type="button"
                    onClick={() => void loadLiveData(true)}
                    disabled={isRefreshing}
                    className="h-9 px-3.5 rounded-xl bg-[#3A0F18] hover:bg-[#590C15] border border-[#8F1622] text-xs font-black text-[#FAF2EE] flex items-center gap-1.5 transition-all disabled:opacity-60"
                  >
                    <span className={isRefreshing ? 'inline-block animate-spin' : ''}>🔄</span>
                    <span>Şimdi Yenile</span>
                  </button>
                  <a
                    href={activeGameMeta.matchesPortalUrl}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="h-9 px-3.5 rounded-xl bg-[#2E0B12] hover:bg-[#590C15] border border-[#8F1622] text-xs font-black text-[#FAF2EE] flex items-center gap-1.5 transition-all"
                  >
                    <span>🌐 {activeGameMeta.portalLabel} ↗</span>
                  </a>
                  <button
                    type="button"
                    onClick={() => handleLaunchTacticalMap(activeGameMeta.defaultMapId)}
                    className="h-9 px-3.5 rounded-xl bg-[#160A0E] hover:bg-[#241016] border border-[#3D141D] text-xs font-bold text-[#E08C96] hover:text-[#FAF2EE] flex items-center gap-1.5 transition-all"
                  >
                    <IconMapBoard size={13} />
                    <span>Taktik Masası</span>
                  </button>
                </div>
              </div>
            )}
          </section>
        )}

        {/* RIGHT COLUMN (4 Cols): HLTV / VLR STYLE NEWS & STANDINGS */}
        {(activeCategoryFilter === 'all' ||
          activeCategoryFilter === 'news' ||
          activeCategoryFilter === 'standings') && (
          <aside
            className={`${
              activeCategoryFilter === 'all' ? 'lg:col-span-4' : 'lg:col-span-12'
            } flex flex-col gap-4`}
          >
            {/* 1. HLTV / VLR STYLE NEWS STREAM */}
            <div className="rounded-2xl bg-[#0E0609]/90 border border-[#281218] p-4 flex flex-col gap-3">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <span className="w-1.5 h-3.5 rounded-full bg-[#C82333]" />
                  <h3 className="text-sm font-black text-[#FAF2EE]">
                    HLTV & VLR Espor Bülteni
                  </h3>
                </div>

                <div className="flex items-center gap-1 text-[10px] font-mono">
                  {(['all', 'breaking', 'patch'] as const).map((cat) => (
                    <button
                      key={cat}
                      type="button"
                      onClick={() => setNewsFilter(cat)}
                      className={`px-2 py-0.5 rounded transition-colors ${
                        newsFilter === cat
                          ? 'bg-[#380E17] text-[#FF5A6B] border border-[#8F1622]'
                          : 'text-[#8E7E81] hover:text-[#FAF2EE]'
                      }`}
                    >
                      {cat === 'all' ? 'Tümü' : cat === 'breaking' ? 'Son Dk' : 'Yama'}
                    </button>
                  ))}
                </div>
              </div>

              {/* News Items List (Live Clickable RSS Articles) */}
              <div className="flex flex-col divide-y divide-[#241116] max-h-[540px] overflow-y-auto no-scrollbar pr-1">
                {filteredNews.length === 0 ? (
                  <div className="py-6 px-4 rounded-xl bg-[#14080D]/85 backdrop-blur-md border border-[#6E141E]/40 text-center flex flex-col items-center gap-2">
                    <div className="flex items-center gap-2 text-xs font-black text-[#FAF2EE]">
                      <span className="w-2 h-2 rounded-full bg-[#FF5A6B] animate-pulse" />
                      <span>Canlı Veri Güncelleniyor...</span>
                    </div>
                    <span className="text-[10.5px] font-mono text-[#A8989B]">
                      HLTV.org · VLR.gg · OpenDota · LoL Esports
                    </span>
                    <button
                      type="button"
                      onClick={() => void loadLiveData(true)}
                      disabled={isRefreshing}
                      className="mt-1 h-7 px-3 rounded-lg bg-[#2E0B12] hover:bg-[#590C15] border border-[#8F1622] text-[11px] font-extrabold text-[#FAF2EE] flex items-center gap-1.5 transition-all disabled:opacity-60"
                    >
                      <span className={isRefreshing ? 'inline-block animate-spin' : ''}>🔄</span>
                      <span>Şimdi Yenile</span>
                    </button>
                  </div>
                ) : (
                  filteredNews.map((news) => (
                    <a
                      key={news.id}
                      href={news.url}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="py-3 flex flex-col gap-1.5 group cursor-pointer hover:bg-[#17090E]/50 px-1.5 -mx-1.5 rounded-xl transition-colors"
                    >
                      <div className="flex items-center justify-between text-[10px] gap-2">
                        <div className="flex items-center gap-1.5 min-w-0">
                          <span className="px-1.5 py-0.2 rounded font-black uppercase text-[9px] bg-[#2E0B12] text-[#FF7582] border border-[#6E141E] flex-shrink-0">
                            {news.source}
                          </span>
                          <span className="text-[#B8A8AB] font-mono truncate">
                            {news.publishedAt}
                          </span>
                        </div>
                        <span className="text-[9.5px] font-bold text-[#E08C96] group-hover:text-[#FF5A6B] flex-shrink-0">
                          Kaynağa Git ↗
                        </span>
                      </div>

                      <h4 className="text-[12.5px] font-extrabold text-[#FAF2EE] group-hover:text-[#FF7582] transition-colors leading-snug">
                        {news.title}
                      </h4>

                      <p className="text-[11px] text-[#A8989B] line-clamp-2 leading-relaxed">
                        {news.summary}
                      </p>

                      <div className="flex items-center gap-1.5 mt-0.5 flex-wrap">
                        {news.tags.map((tag) => (
                          <span
                            key={tag}
                            className="text-[9.5px] font-mono text-[#E08C96] bg-[#14080B] px-1 rounded border border-[#251015]"
                          >
                            {tag}
                          </span>
                        ))}
                      </div>
                    </a>
                  ))
                )}
              </div>
            </div>

            {/* 2. ESPORT TOURNAMENT STANDINGS */}
            {currentStandings && (
              <div className="rounded-2xl bg-[#0E0609]/90 border border-[#281218] p-4 flex flex-col gap-2.5">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <span className="w-1.5 h-3.5 rounded-full bg-amber-500" />
                    <h3 className="text-xs font-black text-[#FAF2EE] truncate">
                      {currentStandings.tournamentName}
                    </h3>
                  </div>
                  <span className="text-[10px] font-mono font-bold text-amber-400">
                    {currentStandings.prizePool}
                  </span>
                </div>

                <div className="space-y-1.5 pt-1">
                  {currentStandings.topTeams.map((row) => (
                    <div
                      key={row.position}
                      className="px-2.5 py-1.5 rounded-xl bg-[#14080C] border border-[#220E14] flex items-center justify-between text-xs font-semibold"
                    >
                      <div className="flex items-center gap-2">
                        <span
                          className={`w-5 h-5 rounded flex items-center justify-center font-mono font-black text-[10px] ${
                            row.position === 1
                              ? 'bg-amber-500/20 text-amber-300 border border-amber-500/50'
                              : row.position === 2
                                ? 'bg-slate-400/20 text-slate-300 border border-slate-400/50'
                                : row.position === 3
                                  ? 'bg-amber-700/20 text-amber-500 border border-amber-700/50'
                                  : 'text-[#8E7E81]'
                          }`}
                        >
                          {row.position}
                        </span>
                        <span className="font-bold text-[#FAF2EE]">{row.team}</span>
                      </div>
                      <div className="flex items-center gap-2 font-mono text-[10.5px]">
                        <span className="text-[#8E7E81]">{row.record}</span>
                        <span className="text-[#FF7582] font-black">{row.points}</span>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </aside>
        )}
      </div>

      {/* ── MODAL: DETAILED MATCH BREAKDOWN ── */}
      {selectedMatch && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center exec-backdrop p-3"
          onClick={() => setSelectedMatch(null)}
        >
          <div
            onClick={(e) => e.stopPropagation()}
            className="w-full max-w-xl rounded-2xl bg-[#0F070A]/95 border border-[#8F1622]/80 shadow-[0_24px_80px_rgba(0,0,0,0.95)] p-5 flex flex-col gap-4 font-sans backdrop-blur-xl animate-in zoom-in-95 duration-150"
          >
            <div className="flex items-center justify-between border-b border-[#281218] pb-3">
              <div className="flex items-center gap-2">
                <span className="text-xl">🏆</span>
                <div>
                  <h3 className="text-base font-black text-[#FAF2EE]">
                    {selectedMatch.tournament}
                  </h3>
                  <span className="text-[11px] text-[#A8989B]">
                    {selectedMatch.stage} · {selectedMatch.format}
                  </span>
                </div>
              </div>
              <button
                type="button"
                onClick={() => setSelectedMatch(null)}
                className="w-7 h-7 rounded-lg bg-[#220B12] hover:bg-[#3D141D] text-[#FAF2EE] flex items-center justify-center font-bold text-xs"
              >
                ✕
              </button>
            </div>

            {/* Scorecard */}
            <div className="p-4 rounded-xl bg-[#090507] border border-[#251016] flex items-center justify-between">
              <div className="text-center flex-1">
                <span className="text-lg font-black block text-[#FAF2EE]">
                  {selectedMatch.team1.name}
                </span>
                <span className="text-xs font-mono text-[#8E7E81]">
                  Dünya #{selectedMatch.team1.rank}
                </span>
              </div>
              <div className="px-4 py-2 rounded-xl bg-[#1C0B11] border border-[#6E141E] text-2xl font-black font-mono text-[#FF5A6B]">
                {selectedMatch.team1.score} : {selectedMatch.team2.score}
              </div>
              <div className="text-center flex-1">
                <span className="text-lg font-black block text-[#FAF2EE]">
                  {selectedMatch.team2.name}
                </span>
                <span className="text-xs font-mono text-[#8E7E81]">
                  Dünya #{selectedMatch.team2.rank}
                </span>
              </div>
            </div>

            {/* Map Breakdown if available */}
            {selectedMatch.mapScores && selectedMatch.mapScores.length > 0 && (
              <div className="space-y-1.5">
                <span className="text-xs font-bold text-[#FAF2EE]">Harita Skorları:</span>
                <div className="space-y-1">
                  {selectedMatch.mapScores.map((ms, idx) => (
                    <div
                      key={idx}
                      className="px-3 py-2 rounded-lg bg-[#14080D] border border-[#261016] flex items-center justify-between text-xs"
                    >
                      <span className="font-extrabold text-[#FAF2EE]">{ms.mapName}</span>
                      <div className="flex items-center gap-2">
                        <span className="font-mono font-black text-[#FF7582]">
                          {ms.score1} - {ms.score2}
                        </span>
                        {ms.finished ? (
                          <span className="text-[10px] text-emerald-400 font-bold">Tamamlandı</span>
                        ) : ms.isCurrent ? (
                          <span className="text-[10px] text-rose-400 font-bold animate-pulse">
                            Oynanıyor
                          </span>
                        ) : (
                          <span className="text-[10px] text-[#6E5E61]">Sırada</span>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Rosters Comparison */}
            <div className="grid grid-cols-2 gap-3 text-xs pt-1">
              <div className="p-2.5 rounded-lg bg-[#14080D] border border-[#241116]">
                <span className="font-extrabold text-[#FF7582] block mb-1">
                  {selectedMatch.team1.tag} Kadrosu:
                </span>
                <div className="text-[11px] text-[#A8989B] space-y-0.5">
                  {selectedMatch.team1.roster?.map((p) => (
                    <div key={p}>• {p}</div>
                  ))}
                </div>
              </div>
              <div className="p-2.5 rounded-lg bg-[#14080D] border border-[#241116]">
                <span className="font-extrabold text-[#FF7582] block mb-1">
                  {selectedMatch.team2.tag} Kadrosu:
                </span>
                <div className="text-[11px] text-[#A8989B] space-y-0.5">
                  {selectedMatch.team2.roster?.map((p) => (
                    <div key={p}>• {p}</div>
                  ))}
                </div>
              </div>
            </div>

            {/* Modal Actions */}
            <div className="flex items-center justify-end gap-2 pt-2 border-t border-[#261016]">
              <a
                href={selectedMatch.matchUrl || activeGameMeta.matchesPortalUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="h-9 px-3.5 rounded-xl bg-[#190A0F] hover:bg-[#2E0F18] border border-[#6E141E] text-[#FAF2EE] text-xs font-bold flex items-center gap-1.5 transition-all"
              >
                <span>Canlı Maç Sayfası ↗</span>
              </a>
              <button
                type="button"
                onClick={() => {
                  const mapId = selectedMatch.tacticalMapId;
                  setSelectedMatch(null);
                  handleLaunchTacticalMap(mapId);
                }}
                className="h-9 px-4 rounded-xl bg-gradient-to-r from-[#8F1622] to-[#C82333] hover:from-[#A81B29] hover:to-[#E02D3F] text-[#FAF2EE] text-xs font-black shadow-[0_0_16px_rgba(200,35,51,0.4)] flex items-center gap-1.5 transition-all"
              >
                <IconMapBoard size={14} />
                <span>Haritayı Taktik Masasında Aç</span>
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
});
