// ─────────────────────────────────────────────────────────
// Meva HUD — Global Esports Hub Type Definitions
// ─────────────────────────────────────────────────────────
// HLTV / VLR.gg tier match schedules, live score telemetry,
// tournament brackets, and verified esports news feeds.

export type EsportGame = 'cs2' | 'valorant' | 'lol' | 'dota2';

export type MainNavViewMode = 'cockpit' | 'esport-hub' | 'tactical';

export type MatchStatus = 'live' | 'upcoming' | 'finished';

export interface EsportTeam {
  name: string;
  tag: string;
  rank: number;
  score: number;
  logoColor: string;
  region: string;
  form: Array<'W' | 'L'>;
  roster?: string[];
}

export interface MapScoreDetail {
  mapName: string;
  score1: number;
  score2: number;
  finished: boolean;
  isCurrent?: boolean;
}

export interface EsportMatch {
  id: string;
  game: EsportGame;
  tournament: string;
  tournamentTier: 'S-Tier' | 'A-Tier' | 'Major';
  stage: string;
  format: 'Bo1' | 'Bo3' | 'Bo5';
  status: MatchStatus;
  timeLabel: string;
  streamUrl?: string;
  streamViewerCount?: string;
  team1: EsportTeam;
  team2: EsportTeam;
  currentMap?: string;
  mapScores?: MapScoreDetail[];
  tacticalMapId?: string;
}

export type NewsCategory = 'breaking' | 'transfers' | 'tournaments' | 'patch';

export interface EsportNewsItem {
  id: string;
  game: EsportGame | 'all';
  category: NewsCategory;
  categoryLabel: string;
  title: string;
  summary: string;
  source: 'HLTV.org' | 'VLR.gg' | 'LoL Esports' | 'Valve' | 'Liquipedia' | 'Meva Intel';
  author: string;
  publishedAt: string;
  readMinutes: number;
  commentCount: number;
  featured?: boolean;
  tags: string[];
  imageUrl?: string;
}

export interface EsportTournamentStanding {
  id: string;
  game: EsportGame;
  tournamentName: string;
  prizePool: string;
  location: string;
  dates: string;
  leaderTeam: string;
  topTeams: Array<{ position: number; team: string; points: string; record: string }>;
}
