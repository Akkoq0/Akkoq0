// ─────────────────────────────────────────────────────────
// Meva HUD — Global Esports Ecosystem Registry & Metadata
// ─────────────────────────────────────────────────────────
// Official game registries, regional competitive metadata, and
// baseline league definitions paired with live esportDataService feeds.

import type {
  EsportGame,
  EsportMatch,
  EsportNewsItem,
  EsportTournamentStanding,
} from '@/types/esport';

export interface GameOption {
  id: EsportGame;
  name: string;
  tag: string;
  icon: string;
  color: string;
  badge: string;
  matchesPortalUrl: string;
  portalLabel: string;
  defaultMapId: string;
}

export const ESPORT_GAMES: GameOption[] = [
  {
    id: 'cs2',
    name: 'Counter-Strike 2',
    tag: 'CS2',
    icon: '🎯',
    color: '#FF7043',
    badge: 'HLTV Live RSS',
    matchesPortalUrl: 'https://www.hltv.org/matches',
    portalLabel: 'HLTV.org Maç Merkezi',
    defaultMapId: 'mirage',
  },
  {
    id: 'valorant',
    name: 'Valorant',
    tag: 'VAL',
    icon: '⚡',
    color: '#FF4655',
    badge: 'VLR.gg Live RSS',
    matchesPortalUrl: 'https://www.vlr.gg/matches',
    portalLabel: 'VLR.gg Maç Merkezi',
    defaultMapId: 'ascent',
  },
  {
    id: 'lol',
    name: 'League of Legends',
    tag: 'LoL',
    icon: '⚔️',
    color: '#C8AA6E',
    badge: 'LoL Esports Live',
    matchesPortalUrl: 'https://lolesports.com/schedule',
    portalLabel: 'LoL Esports Fikstür',
    defaultMapId: 'summoners-rift',
  },
  {
    id: 'dota2',
    name: 'Dota 2',
    tag: 'DOTA',
    icon: '🛡️',
    color: '#E53935',
    badge: 'OpenDota + Steam Live',
    matchesPortalUrl: 'https://liquipedia.net/dota2/Liquipedia:Upcoming_and_ongoing_matches',
    portalLabel: 'Liquipedia / OpenDota Canlı',
    defaultMapId: 'dota2-map',
  },
];

// Live feeds are populated exclusively by lib/esportDataService.ts
export const ESPORT_MATCHES: EsportMatch[] = [];
export const ESPORT_NEWS: EsportNewsItem[] = [];

export const ESPORT_STANDINGS: EsportTournamentStanding[] = [
  {
    id: 'st-cs2',
    game: 'cs2',
    tournamentName: 'HLTV Dünya Sıralaması & Sezon Takibi',
    prizePool: 'HLTV.org',
    location: 'Küresel',
    dates: 'Canlı Turnuva Döngüsü',
    leaderTeam: 'Natus Vincere',
    topTeams: [
      { position: 1, team: 'Natus Vincere', points: 'VRS #1', record: 'HLTV Live' },
      { position: 2, team: 'Team Vitality', points: 'VRS #2', record: 'HLTV Live' },
      { position: 3, team: 'MOUZ', points: 'VRS #3', record: 'HLTV Live' },
      { position: 4, team: 'FaZe Clan', points: 'VRS #4', record: 'HLTV Live' },
      { position: 5, team: 'Eternal Fire', points: 'TR Top', record: 'HLTV Live' },
    ],
  },
  {
    id: 'st-val',
    game: 'valorant',
    tournamentName: 'VCT EMEA & Küresel Güç Sıralaması',
    prizePool: 'VLR.gg',
    location: 'EMEA / APAC / AMER',
    dates: 'VCT Sezonu',
    leaderTeam: 'Fnatic',
    topTeams: [
      { position: 1, team: 'Fnatic', points: 'EMEA #1', record: 'VLR Live' },
      { position: 2, team: 'Team Heretics', points: 'EMEA #2', record: 'VLR Live' },
      { position: 3, team: 'FUT Esports', points: 'TR Top', record: 'VLR Live' },
      { position: 4, team: 'Sentinels', points: 'AMER', record: 'VLR Live' },
      { position: 5, team: 'Paper Rex', points: 'APAC', record: 'VLR Live' },
    ],
  },
  {
    id: 'st-lol',
    game: 'lol',
    tournamentName: 'LoL Esports Küresel Ligler (LCK / LEC / LPL)',
    prizePool: 'LoL Esports',
    location: 'Seul / Berlin / Şanghay',
    dates: 'Bölgesel Ligler',
    leaderTeam: 'Gen.G',
    topTeams: [
      { position: 1, team: 'Gen.G', points: 'LCK', record: 'LoL Esports' },
      { position: 2, team: 'T1', points: 'LCK', record: 'LoL Esports' },
      { position: 3, team: 'G2 Esports', points: 'LEC', record: 'LoL Esports' },
      { position: 4, team: 'Bilibili Gaming', points: 'LPL', record: 'LoL Esports' },
      { position: 5, team: 'Fnatic', points: 'LEC', record: 'LoL Esports' },
    ],
  },
  {
    id: 'st-dota2',
    game: 'dota2',
    tournamentName: 'Dota 2 Pro Circuit & ESL Pro Tour',
    prizePool: 'OpenDota API',
    location: 'Küresel',
    dates: 'Canlı Turnuva Akışı',
    leaderTeam: 'Team Spirit',
    topTeams: [
      { position: 1, team: 'Team Spirit', points: 'EPT', record: 'OpenDota' },
      { position: 2, team: 'Team Falcons', points: 'EPT', record: 'OpenDota' },
      { position: 3, team: 'Team Liquid', points: 'EPT', record: 'OpenDota' },
      { position: 4, team: 'Tundra Esports', points: 'EPT', record: 'OpenDota' },
      { position: 5, team: 'PARIVISION', points: 'EPT', record: 'OpenDota' },
    ],
  },
];
