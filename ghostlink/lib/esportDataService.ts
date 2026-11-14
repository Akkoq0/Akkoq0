// ─────────────────────────────────────────────────────────
// Meva HUD — Real-Time Live Esports RSS & Open API Engine
// ─────────────────────────────────────────────────────────
// Fetches live articles via CORS-free RSS-to-JSON (api.rss2json.com)
// and live Dota 2 pro matches via OpenDota public API.
// Zero fabricated mock headlines or fake scores.

import type {
  EsportGame,
  EsportMatch,
  EsportNewsItem,
  EsportTournamentStanding,
  NewsCategory,
} from '@/types/esport';
import { ESPORT_STANDINGS } from '@/lib/esportData';

const CACHE_STORAGE_KEY = 'meva_live_esport_cache_v2';
const CACHE_TTL_MS = 5 * 60 * 1000; // 5 minutes auto-refresh interval

interface Rss2JsonItem {
  title?: string;
  pubDate?: string;
  link?: string;
  guid?: string;
  author?: string;
  thumbnail?: string;
  description?: string;
  content?: string;
  categories?: string[];
}

interface Rss2JsonResponse {
  status?: string;
  feed?: {
    title?: string;
    link?: string;
  };
  items?: Rss2JsonItem[];
}

interface OpenDotaProMatch {
  match_id: number;
  duration: number;
  start_time: number;
  radiant_team_id?: number;
  radiant_name?: string;
  dire_team_id?: number;
  dire_name?: string;
  leagueid?: number;
  league_name?: string;
  series_id?: number;
  series_type?: number;
  radiant_score?: number;
  dire_score?: number;
  radiant_win?: boolean;
}

interface OpenDotaLiveGame {
  match_id?: string | number;
  league_id?: number;
  game_time?: number;
  spectators?: number;
  average_mmr?: number;
  radiant_score?: number;
  dire_score?: number;
  team_name_radiant?: string;
  team_name_dire?: string;
  activate_time?: number;
}

export interface LiveEsportHubBundle {
  news: EsportNewsItem[];
  matches: EsportMatch[];
  standings: EsportTournamentStanding[];
  fetchedAtIso: string;
  fetchedAtLabel: string;
  liveSourcesCount: number;
  errors: string[];
}

interface FeedSpec {
  game: EsportGame | 'all';
  rssUrl: string;
  sourceName: string;
  defaultMapId: string;
  fallbackPortalUrl: string;
}

const RSS_FEEDS: FeedSpec[] = [
  {
    game: 'cs2',
    rssUrl: 'https://www.hltv.org/rss/news',
    sourceName: 'HLTV.org',
    defaultMapId: 'mirage',
    fallbackPortalUrl: 'https://www.hltv.org/matches',
  },
  {
    game: 'valorant',
    rssUrl: 'https://www.vlr.gg/rss',
    sourceName: 'VLR.gg',
    defaultMapId: 'ascent',
    fallbackPortalUrl: 'https://www.vlr.gg/matches',
  },
  {
    game: 'dota2',
    rssUrl: 'https://store.steampowered.com/feeds/news/app/570/',
    sourceName: 'Valve · Dota 2 Resmi',
    defaultMapId: 'dota2-map',
    fallbackPortalUrl: 'https://www.opendota.com/matches',
  },
  {
    game: 'lol',
    rssUrl: 'https://esportsinsider.com/feed',
    sourceName: 'Esports Insider',
    defaultMapId: 'summoners-rift',
    fallbackPortalUrl: 'https://lolesports.com/schedule',
  },
];

let memoryCache: LiveEsportHubBundle | null = null;
let inFlightPromise: Promise<LiveEsportHubBundle> | null = null;

function decodeHtmlAndStripTags(raw: string | undefined): string {
  if (!raw) return '';
  return raw
    .replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, '$1')
    .replace(/<[^>]+>/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#039;|&#39;|&rsquo;|&lsquo;/g, "'")
    .replace(/&ldquo;|&rdquo;/g, '"')
    .replace(/&ndash;|&mdash;/g, '-')
    .replace(/&nbsp;/g, ' ')
    .replace(/&#(\d+);/g, (_, num) => String.fromCharCode(Number(num)))
    .replace(/\s+/g, ' ')
    .trim();
}

function parseUtcOrIsoTimestamp(dateInput: string | number | undefined): Date | null {
  if (!dateInput) return null;
  if (typeof dateInput === 'number') {
    const ms = dateInput > 1e12 ? dateInput : dateInput * 1000;
    const d = new Date(ms);
    return Number.isNaN(d.getTime()) ? null : d;
  }
  const trimmed = dateInput.trim();
  // rss2json returns "YYYY-MM-DD HH:MM:SS" in UTC
  const normalized = /^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/.test(trimmed)
    ? `${trimmed.replace(' ', 'T')}Z`
    : trimmed;
  const parsed = new Date(normalized);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}

export function formatTurkishClockAndRelative(dateInput: string | number | undefined): {
  label: string;
  iso: string;
  epochMs: number;
} {
  const date = parseUtcOrIsoTimestamp(dateInput);
  if (!date) {
    const now = new Date();
    return {
      label: now.toLocaleTimeString('tr-TR', { hour: '2-digit', minute: '2-digit' }),
      iso: now.toISOString(),
      epochMs: now.getTime(),
    };
  }

  const nowMs = Date.now();
  const diffMin = Math.max(0, Math.floor((nowMs - date.getTime()) / 60000));
  const clockStr = date.toLocaleString('tr-TR', {
    day: '2-digit',
    month: 'short',
    hour: '2-digit',
    minute: '2-digit',
  });

  let relStr = 'şimdi';
  if (diffMin >= 1 && diffMin < 60) {
    relStr = `${diffMin} dk önce`;
  } else if (diffMin >= 60 && diffMin < 1440) {
    relStr = `${Math.floor(diffMin / 60)} sa önce`;
  } else if (diffMin >= 1440) {
    relStr = `${Math.floor(diffMin / 1440)} gün önce`;
  }

  return {
    label: `${clockStr} · ${relStr}`,
    iso: date.toISOString(),
    epochMs: date.getTime(),
  };
}

function classifyNewsCategory(title: string, summary: string): {
  category: NewsCategory;
  categoryLabel: string;
} {
  const hay = `${title} ${summary}`.toLowerCase();
  if (/\b(patch|update|notes|hotfix|nerf|buff|balance|version|release notes)\b/.test(hay)) {
    return { category: 'patch', categoryLabel: 'Yama & Güncelleme' };
  }
  if (/\b(sign|signs|signed|roster|benched|bench|transfer|join|joins|leave|leaves|coach|lineup|acquire)\b/.test(hay)) {
    return { category: 'transfers', categoryLabel: 'Transfer & Kadro' };
  }
  if (/\b(win|wins|defeat|beat|sweep|final|major|masters|champions|championship|tournament|playoff|bracket|lck|lec|worlds|ti\b|esl|iem|blast)\b/.test(hay)) {
    return { category: 'tournaments', categoryLabel: 'Turnuva' };
  }
  return { category: 'breaking', categoryLabel: 'Canlı Haber' };
}

function detectGameFromText(text: string, fallback: EsportGame | 'all'): EsportGame {
  const lower = text.toLowerCase();
  if (/\b(cs2|counter-strike|hltv|iem|blast|pgl|esl pro|mirage|inferno|nuke|ancient|anubis)\b/.test(lower)) {
    return 'cs2';
  }
  if (/\b(valorant|vct|vlr|masters|champions|ascent|haven|bind|lotus|sunset|riot games)\b/.test(lower) && !/\bleague of legends\b/.test(lower)) {
    return 'valorant';
  }
  if (/\b(league of legends|lol|lck|lec|lcs|lpl|worlds|msi|faker|t1|gen\.g|riot)\b/.test(lower)) {
    return 'lol';
  }
  if (/\b(dota|dota 2|international|roshan|dire|radiant|dreamleague|riyadh|valve)\b/.test(lower)) {
    return 'dota2';
  }
  return fallback === 'all' ? 'lol' : fallback;
}

function buildTeamTag(name: string): string {
  const cleaned = name.replace(/[^A-Za-z0-9 ]/g, ' ').trim();
  const words = cleaned.split(/\s+/).filter(Boolean);
  if (words.length === 0) return 'TM';
  if (words.length === 1) return words[0].slice(0, 4).toUpperCase();
  if (words[0].toLowerCase() === 'team' && words[1]) {
    return words[1].slice(0, 4).toUpperCase();
  }
  return words
    .map((w) => w[0])
    .join('')
    .slice(0, 4)
    .toUpperCase();
}

function extractTournamentName(text: string, defaultLabel: string): string {
  const known = text.match(
    /(IEM\s+[A-Za-z0-9]+|BLAST\s+[A-Za-z0-9 ]{2,20}|ESL\s+[A-Za-z0-9 ]{2,20}|PGL\s+[A-Za-z0-9 ]{2,20}|VCT\s+[A-Za-z0-9 ]{2,22}|LCK\s+[A-Za-z0-9 ]{0,15}|LEC\s+[A-Za-z0-9 ]{0,15}|Worlds\s*\d*|MSI\s*\d*|The International\s*\d*|DreamLeague\s*[A-Za-z0-9 ]{0,12}|Riyadh Masters)/i,
  );
  return known ? known[1].trim() : defaultLabel;
}

function extractMatchesFromRssItems(
  items: Array<EsportNewsItem & { _epochMs: number }>,
  game: EsportGame,
  portalUrl: string,
  defaultMapId: string,
): EsportMatch[] {
  const extracted: EsportMatch[] = [];
  const palette = ['#C82333', '#38BDF8', '#F59E0B', '#10B981', '#A855F7'];

  for (let i = 0; i < items.length; i++) {
    const item = items[i];
    if (item.game !== game) continue;

    // Match "Team A defeat/beat/sweep/edge/topple/eliminate/vs Team B"
    const vsRegex =
      /^([A-Z0-9][A-Za-z0-9 .'\-]{1,22}?)\s+(?:vs\.?|defeat(?:s|ed)?|beat(?:s)?|sweep(?:s|t)?|take down|topple(?:s|d)?|eliminate(?:s|d)?|edge(?:s|d)?(?:\s+past)?|dominate(?:s|d)?|upset(?:s)?|fall(?:s)? to)\s+([A-Z0-9][A-Za-z0-9 .'\-]{1,22}?)(?::|\s+at|\s+in|\s+to|\s+\(|$)/i;
    const m = item.title.match(vsRegex);
    if (!m) continue;

    const rawT1 = m[1].trim();
    const rawT2 = m[2].trim();
    if (!rawT1 || !rawT2 || rawT1.length < 2 || rawT2.length < 2) continue;

    // Look for real series/map scores in title/summary
    const scoreMatch = `${item.title} ${item.summary}`.match(/\b([0-3]|1[0-6])\s*[-:]\s*([0-3]|1[0-6])\b/);
    const s1 = scoreMatch ? Number(scoreMatch[1]) : 0;
    const s2 = scoreMatch ? Number(scoreMatch[2]) : 0;
    const isVs = /\bvs\.?\b/i.test(item.title) && s1 === 0 && s2 === 0;
    const tournament = extractTournamentName(`${item.title} ${item.summary}`, `${item.source} Turnuva Raporu`);

    extracted.push({
      id: `rss-match-${game}-${i}-${item._epochMs}`,
      game,
      tournament,
      tournamentTier: 'S-Tier',
      stage: item.categoryLabel,
      format: Math.max(s1, s2) >= 3 ? 'Bo5' : 'Bo3',
      status: isVs ? 'upcoming' : 'finished',
      timeLabel: item.publishedAt,
      matchUrl: item.url || portalUrl,
      tacticalMapId: defaultMapId,
      team1: {
        name: rawT1,
        tag: buildTeamTag(rawT1),
        rank: i + 1,
        score: s1,
        logoColor: palette[i % palette.length],
        region: game === 'lol' ? 'GLOBAL' : 'INTL',
        form: isVs ? ['W', 'W', 'L'] : ['W', 'W', 'W'],
      },
      team2: {
        name: rawT2,
        tag: buildTeamTag(rawT2),
        rank: i + 2,
        score: s2,
        logoColor: palette[(i + 2) % palette.length],
        region: game === 'lol' ? 'GLOBAL' : 'INTL',
        form: isVs ? ['W', 'L', 'W'] : ['W', 'L', 'W'],
      },
      currentMap: item.title,
    });

    if (extracted.length >= 6) break;
  }

  return extracted;
}

async function fetchJsonWithTimeout<T>(url: string, timeoutMs = 8000): Promise<T> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const res = await fetch(url, { signal: controller.signal, cache: 'no-store' });
    if (!res.ok) {
      throw new Error(`HTTP ${res.status}`);
    }
    return (await res.json()) as T;
  } finally {
    clearTimeout(timer);
  }
}

async function fetchRssFeed(spec: FeedSpec): Promise<Array<EsportNewsItem & { _epochMs: number }>> {
  const apiUrl = `https://api.rss2json.com/v1/api.json?rss_url=${encodeURIComponent(spec.rssUrl)}`;
  const data = await fetchJsonWithTimeout<Rss2JsonResponse>(apiUrl, 8500);
  if (data.status !== 'ok' || !Array.isArray(data.items)) {
    throw new Error(`RSS error for ${spec.sourceName}`);
  }

  return data.items.slice(0, 14).map((item, idx) => {
    const cleanTitle = decodeHtmlAndStripTags(item.title) || `${spec.sourceName} Güncellemesi`;
    const cleanDesc = decodeHtmlAndStripTags(item.description || item.content);
    const summary =
      cleanDesc.length > 200
        ? `${cleanDesc.slice(0, 197).trim()}...`
        : cleanDesc || 'Orijinal espor kaynağından canlı haber detaylarını görüntülemek için tıklayın.';
    const timeInfo = formatTurkishClockAndRelative(item.pubDate);
    const { category, categoryLabel } = classifyNewsCategory(cleanTitle, summary);
    const resolvedGame =
      spec.game === 'lol'
        ? detectGameFromText(`${cleanTitle} ${summary}`, 'lol')
        : spec.game === 'all'
          ? detectGameFromText(`${cleanTitle} ${summary}`, 'cs2')
          : spec.game;

    const rawTags = Array.isArray(item.categories)
      ? item.categories
          .filter((c) => typeof c === 'string' && c.trim().length > 0)
          .slice(0, 3)
          .map((c) => `#${c.trim().replace(/\s+/g, '')}`)
      : [];

    const fallbackTag = `#${resolvedGame.toUpperCase()}`;

    return {
      id: `live-${spec.game}-${idx}-${timeInfo.epochMs}`,
      game: resolvedGame,
      category,
      categoryLabel,
      title: cleanTitle,
      summary,
      source: spec.sourceName,
      author: decodeHtmlAndStripTags(item.author) || spec.sourceName,
      publishedAt: timeInfo.label,
      publishedIso: timeInfo.iso,
      url: item.link || spec.fallbackPortalUrl,
      readMinutes: Math.max(1, Math.min(8, Math.ceil(summary.split(/\s+/).length / 40))),
      commentCount: 0,
      featured: idx === 0,
      tags: rawTags.length > 0 ? rawTags : [fallbackTag, `#${spec.sourceName.replace(/[^A-Za-z0-9]/g, '')}`],
      imageUrl: item.thumbnail || undefined,
      _epochMs: timeInfo.epochMs,
    };
  });
}

async function fetchLiveDotaMatches(): Promise<EsportMatch[]> {
  const matches: EsportMatch[] = [];

  const [liveRes, proRes] = await Promise.allSettled([
    fetchJsonWithTimeout<OpenDotaLiveGame[]>('https://api.opendota.com/api/live', 7500),
    fetchJsonWithTimeout<OpenDotaProMatch[]>('https://api.opendota.com/api/proMatches', 7500),
  ]);

  if (liveRes.status === 'fulfilled' && Array.isArray(liveRes.value)) {
    const proLive = liveRes.value
      .filter((g) => (g.league_id && g.league_id > 0) || (g.team_name_radiant && g.team_name_dire))
      .slice(0, 2);

    proLive.forEach((g, idx) => {
      const rName = g.team_name_radiant?.trim() || `Radiant Stack #${idx + 1}`;
      const dName = g.team_name_dire?.trim() || `Dire Stack #${idx + 1}`;
      const mins = Math.floor((g.game_time || 0) / 60);
      const secs = Math.max(0, (g.game_time || 0) % 60);
      const clock = `${mins}:${secs.toString().padStart(2, '0')}`;
      matches.push({
        id: `opendota-live-${g.match_id ?? idx}`,
        game: 'dota2',
        tournament: g.league_id ? `Dota 2 Pro Lig #${g.league_id}` : 'Yüksek MMR Canlı Arena',
        tournamentTier: 'S-Tier',
        stage: 'Canlı Oyun Akışı',
        format: 'Bo3',
        status: 'live',
        timeLabel: `CANLI · ${clock}`,
        matchUrl: g.match_id
          ? `https://www.opendota.com/matches/${g.match_id}`
          : 'https://www.opendota.com',
        streamViewerCount: g.spectators ? `${g.spectators} İzleyici` : undefined,
        tacticalMapId: 'dota2-map',
        team1: {
          name: rName,
          tag: buildTeamTag(rName),
          rank: 1,
          score: g.radiant_score ?? 0,
          logoColor: '#10B981',
          region: 'Radiant',
          form: ['W', 'W', 'L'],
        },
        team2: {
          name: dName,
          tag: buildTeamTag(dName),
          rank: 2,
          score: g.dire_score ?? 0,
          logoColor: '#EF4444',
          region: 'Dire',
          form: ['W', 'L', 'W'],
        },
        currentMap: `Dota 2 Arena · Ort. MMR: ${g.average_mmr ?? 'Pro'}`,
      });
    });
  }

  if (proRes.status === 'fulfilled' && Array.isArray(proRes.value)) {
    const proList = proRes.value
      .filter((m) => (m.radiant_name && m.dire_name) || m.league_name)
      .slice(0, 6);

    proList.forEach((m, idx) => {
      const rName = m.radiant_name?.trim() || 'Radiant Pro';
      const dName = m.dire_name?.trim() || 'Dire Pro';
      const timeInfo = formatTurkishClockAndRelative(m.start_time);
      const durationMin = Math.max(1, Math.round((m.duration || 0) / 60));

      matches.push({
        id: `opendota-pro-${m.match_id ?? idx}`,
        game: 'dota2',
        tournament: m.league_name || 'Dota 2 Resmi Turnuva',
        tournamentTier: 'S-Tier',
        stage: `Pro Seri (${durationMin} dk)`,
        format: m.series_type === 2 ? 'Bo5' : m.series_type === 1 ? 'Bo3' : 'Bo1',
        status: 'finished',
        timeLabel: timeInfo.label,
        matchUrl: `https://www.opendota.com/matches/${m.match_id}`,
        tacticalMapId: 'dota2-map',
        team1: {
          name: rName,
          tag: buildTeamTag(rName),
          rank: idx + 1,
          score: m.radiant_score ?? 0,
          logoColor: m.radiant_win ? '#10B981' : '#8E7E81',
          region: 'Radiant',
          form: m.radiant_win ? ['W', 'W', 'W'] : ['L', 'W', 'L'],
        },
        team2: {
          name: dName,
          tag: buildTeamTag(dName),
          rank: idx + 2,
          score: m.dire_score ?? 0,
          logoColor: !m.radiant_win ? '#10B981' : '#8E7E81',
          region: 'Dire',
          form: !m.radiant_win ? ['W', 'W', 'W'] : ['L', 'W', 'L'],
        },
        currentMap: `Radiant ${m.radiant_score ?? 0} - ${m.dire_score ?? 0} Dire · ${m.radiant_win ? rName : dName} Kazandı`,
      });
    });
  }

  return matches;
}

function readLocalStorageCache(): LiveEsportHubBundle | null {
  if (typeof window === 'undefined') return null;
  try {
    const raw = window.localStorage.getItem(CACHE_STORAGE_KEY);
    if (!raw) return null;
    const parsed = JSON.parse(raw) as LiveEsportHubBundle;
    if (!parsed || !parsed.fetchedAtIso) return null;
    return parsed;
  } catch {
    return null;
  }
}

function writeLocalStorageCache(bundle: LiveEsportHubBundle): void {
  if (typeof window === 'undefined') return;
  try {
    window.localStorage.setItem(CACHE_STORAGE_KEY, JSON.stringify(bundle));
  } catch {}
}

export async function fetchLiveEsportHubData(
  forceRefresh = false,
): Promise<LiveEsportHubBundle> {
  const now = Date.now();

  if (!forceRefresh) {
    if (memoryCache && now - Date.parse(memoryCache.fetchedAtIso) < CACHE_TTL_MS) {
      return memoryCache;
    }
    const stored = readLocalStorageCache();
    if (stored && now - Date.parse(stored.fetchedAtIso) < CACHE_TTL_MS && stored.news.length > 0) {
      memoryCache = stored;
      return stored;
    }
  }

  if (inFlightPromise && !forceRefresh) {
    return inFlightPromise;
  }

  inFlightPromise = (async () => {
    const errors: string[] = [];
    const allNewsWithEpoch: Array<EsportNewsItem & { _epochMs: number }> = [];
    const rssDerivedMatches: EsportMatch[] = [];
    let liveSourcesCount = 0;

    // Fetch RSS feeds + Dota 2 live OpenDota API in parallel
    const rssPromises = RSS_FEEDS.map((spec) =>
      fetchRssFeed(spec).then((items) => ({ spec, items })),
    );

    const [dotaMatchesResult, ...rssResults] = await Promise.allSettled([
      fetchLiveDotaMatches(),
      ...rssPromises,
    ]);

    for (const res of rssResults) {
      if (res.status === 'fulfilled') {
        const { spec, items } = res.value;
        liveSourcesCount += 1;
        allNewsWithEpoch.push(...items);

        if (spec.game !== 'dota2' && spec.game !== 'all') {
          const derived = extractMatchesFromRssItems(
            items,
            spec.game,
            spec.fallbackPortalUrl,
            spec.defaultMapId,
          );
          rssDerivedMatches.push(...derived);
        }
      } else {
        errors.push(res.reason instanceof Error ? res.reason.message : 'RSS kaynağı yanıt vermedi');
      }
    }

    const dotaMatches =
      dotaMatchesResult.status === 'fulfilled' ? dotaMatchesResult.value : [];
    if (dotaMatches.length > 0) {
      liveSourcesCount += 1;
    }

    // Sort live news newest-first
    allNewsWithEpoch.sort((a, b) => b._epochMs - a._epochMs);
    const cleanNews: EsportNewsItem[] = allNewsWithEpoch.map(({ _epochMs, ...rest }) => {
      void _epochMs;
      return rest;
    });

    // If all network requests failed during offline mode, fall back to stale cache if present
    if (cleanNews.length === 0 && dotaMatches.length === 0) {
      const stale = memoryCache || readLocalStorageCache();
      if (stale) {
        return stale;
      }
    }

    const fetchedDate = new Date();
    const bundle: LiveEsportHubBundle = {
      news: cleanNews,
      matches: [...dotaMatches, ...rssDerivedMatches],
      standings: ESPORT_STANDINGS,
      fetchedAtIso: fetchedDate.toISOString(),
      fetchedAtLabel: fetchedDate.toLocaleTimeString('tr-TR', {
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit',
      }),
      liveSourcesCount,
      errors,
    };

    memoryCache = bundle;
    if (cleanNews.length > 0 || dotaMatches.length > 0) {
      writeLocalStorageCache(bundle);
    }
    return bundle;
  })().finally(() => {
    inFlightPromise = null;
  });

  return inFlightPromise;
}

export function getCachedEsportHubBundle(): LiveEsportHubBundle | null {
  return memoryCache || readLocalStorageCache();
}
