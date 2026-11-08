// ─────────────────────────────────────────────────────────
// Meva HUD — Channel Discovery & Smart Tag Matching Engine
// ─────────────────────────────────────────────────────────
// Evaluates user's primary esports game, active role, community style tags,
// and live Squad Pod Slot Beacons to surface pinpoint recommendations:
//   • e.g. "%98 Uyumlu — Senin Rolün Aranıyor (Jungle Bekleniyor)"
//   • Multi-Game Frequency Filter (TÜMÜ, SANA UYGUN, LoL, CS2, VALO, DOTA2, PUBG, CHILL)

import {
  SUPPORTED_GAMES,
  detectGameFromChannel,
  getGameById,
  type SupportedGameId,
  type GameDef,
} from '@/src/lib/gameRegistry';
import type { Channel } from '@/types';

export interface UserTacticalProfile {
  primaryGame: string;
  favoriteGames: string[];
  gameRoles: Record<string, string>;
  communityTags: string[];
}

export interface PodMatchResult {
  channelId: string;
  channelName: string;
  game: GameDef;
  score: number; // 0-100
  badgeText: string;
  isBeaconMatch: boolean;
  neededRole: string;
  occupancy: number;
  capacity: number;
}

export interface SlotBeaconState {
  targetRole: string | null;
  beaconActive: boolean;
}

/**
 * Evaluates match quality between an operator's profile and a live squad pod (channel).
 */
export function evaluatePodMatch(
  channel: Channel,
  profile: UserTacticalProfile,
  slotBeacons: Record<number, SlotBeaconState> = {},
  occupancy: number = 0,
): PodMatchResult | null {
  if (channel.type !== 'voice') return null;

  const game = channel.game_id
    ? getGameById(channel.game_id)
    : detectGameFromChannel(channel.name, channel.tags);

  const capacity = channel.max_participants ?? game.defaultMax;
  if (capacity > 0 && occupancy >= capacity) {
    return null; // Pod is already full
  }

  const userRole = (
    profile.gameRoles[game.id] ||
    profile.gameRoles[profile.primaryGame] ||
    game.roles[0]?.shortLabel ||
    'IGL'
  ).toUpperCase();

  // 1. Check for Active Slot Beacon demand (Highest Priority)
  let beaconMatchedRole: string | null = null;
  for (const beacon of Object.values(slotBeacons)) {
    if (beacon?.beaconActive && beacon.targetRole) {
      const bRole = beacon.targetRole.toUpperCase();
      if (bRole === userRole || userRole.includes(bRole) || bRole.includes(userRole)) {
        beaconMatchedRole = beacon.targetRole;
        break;
      }
    }
  }

  if (beaconMatchedRole) {
    return {
      channelId: channel.id,
      channelName: channel.name,
      game,
      score: 98,
      badgeText: `⚡ %98 Uyumlu — Senin Rolün Aranıyor (${beaconMatchedRole} Bekleniyor)`,
      isBeaconMatch: true,
      neededRole: beaconMatchedRole,
      occupancy,
      capacity,
    };
  }

  // 2. Game match evaluation
  const isPrimary = game.id === profile.primaryGame;
  const isFavorite = profile.favoriteGames.includes(game.id as SupportedGameId);

  let score = isPrimary ? 75 : isFavorite ? 60 : 35;

  // Occupancy bonus: 4/5 or near-full gets priority
  if (capacity > 1 && occupancy === capacity - 1) {
    score += 18; // "1 Kişi Eksik! Acil kadro tamamlama"
  } else if (occupancy > 0) {
    score += 10;
  }

  // Tag overlap bonus (#Tryhard, #Scrim, etc.)
  if (channel.tags && profile.communityTags) {
    const commonTags = channel.tags.filter((t) =>
      profile.communityTags.some((pt) => pt.toLowerCase() === t.toLowerCase()),
    );
    score += Math.min(10, commonTags.length * 5);
  }

  score = Math.min(96, Math.max(20, score));

  // Determine needed role preview
  const missingRole =
    game.roles[(occupancy + 1) % game.roles.length]?.shortLabel ?? userRole;

  return {
    channelId: channel.id,
    channelName: channel.name,
    game,
    score,
    badgeText: `⚡ %${score} Eşleşme — ${occupancy}/${capacity || '∞'} (${missingRole} Eksik)`,
    isBeaconMatch: false,
    neededRole: missingRole,
    occupancy,
    capacity,
  };
}

/**
 * Returns prioritized list of recommended frequency squad pods.
 */
export function getRecommendedSquadPods(
  channels: Channel[],
  profile: UserTacticalProfile,
  slotBeacons: Record<number, SlotBeaconState> = {},
  occupancies: Record<string, number> = {},
): PodMatchResult[] {
  const matches: PodMatchResult[] = [];

  for (const ch of channels) {
    if (ch.type !== 'voice') continue;
    const occ = occupancies[ch.id] ?? 0;
    const match = evaluatePodMatch(ch, profile, slotBeacons, occ);
    if (match && match.score >= 50) {
      matches.push(match);
    }
  }

  return matches.sort((a, b) => b.score - a.score);
}
