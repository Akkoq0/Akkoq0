/**
 * @file serverArchitectService.ts
 * @description Clean Domain Service for Server and Channel architecture.
 * Implements Single Responsibility Principle, Factory & Builder patterns for esports servers.
 */

import type { Server, ChannelCategory, Channel } from '@/types';
import {
  type ServerTemplate,
  type QuickChannelPreset,
  type SupportedGameId,
  SUPPORTED_GAMES,
  getGameById,
} from '@/src/lib/gameRegistry';
import { getMevaStorageEngine, STORE_PREFS } from '@/src/lib/storageEngine';
import { generatePrefixedId, assertInvariant } from './cleanCodeUtils';

export interface CustomChannelOptions {
  name: string;
  gameId: SupportedGameId;
  type: 'voice' | 'text';
  maxParticipants: number;
}

export interface BuildServerResult {
  server: Server;
  categories: ChannelCategory[];
  channels: Channel[];
  firstVoiceChannelId: string | null;
  firstTextChannelId: string | null;
  primaryRole: string;
}

export interface BuildChannelResult {
  category: ChannelCategory;
  channel: Channel;
  missingRoles: string[];
  isNewCategory: boolean;
}

export class ServerArchitectService {
  /**
   * Ensures an active server exists or creates a default 'Meva Komuta Karargahı'.
   */
  public static ensureActiveServer(
    activeServerId: string | null,
    currentServers: Server[],
  ): { activeId: string; servers: Server[]; isCreated: boolean } {
    if (activeServerId && currentServers.some((s) => s.id === activeServerId)) {
      return { activeId: activeServerId, servers: currentServers, isCreated: false };
    }

    const defaultServer: Server = {
      id: generatePrefixedId('srv-hub'),
      name: 'Meva Komuta Karargahı',
      icon_url: null,
      owner_id: 'usr-local',
      invite_code: 'MEVA01',
      created_at: new Date().toISOString(),
    };

    const updated = [defaultServer, ...currentServers];
    return { activeId: defaultServer.id, servers: updated, isCreated: true };
  }

  /**
   * Builds a complete server structure from a community template.
   */
  public static buildServerFromTemplate(template: ServerTemplate): BuildServerResult {
    assertInvariant(Boolean(template && template.id), 'Geçersiz sunucu şablonu belirtildi.');

    const serverId = `srv-${template.id}-${Date.now().toString(36)}`;
    const nowIso = new Date().toISOString();

    const server: Server = {
      id: serverId,
      name: template.serverName,
      icon_url: null,
      owner_id: 'usr-local',
      invite_code: template.id.toUpperCase().slice(0, 6),
      created_at: nowIso,
    };

    const categories: ChannelCategory[] = [];
    const channels: Channel[] = [];

    template.categories.forEach((catDef, catIdx) => {
      const catId = `cat-${serverId}-${catIdx}`;
      categories.push({
        id: catId,
        server_id: serverId,
        name: catDef.name,
        position: catIdx,
        is_collapsed: false,
      });

      catDef.channels.forEach((chDef, chIdx) => {
        channels.push({
          id: `ch-${serverId}-${catIdx}-${chIdx}`,
          server_id: serverId,
          category_id: catId,
          name: chDef.name,
          type: chDef.type,
          position: chIdx,
          created_at: nowIso,
          game_id: chDef.gameId,
          max_participants: chDef.maxParticipants,
          tags: chDef.tags,
        });
      });
    });

    const firstVoice = channels.find((c) => c.type === 'voice');
    const firstText = channels.find((c) => c.type === 'text');
    const game = firstVoice?.game_id ? getGameById(firstVoice.game_id) : null;
    const primaryRole = game?.roles[0]?.key || 'IGL';

    return {
      server,
      categories,
      channels,
      firstVoiceChannelId: firstVoice ? firstVoice.id : null,
      firstTextChannelId: firstText ? firstText.id : null,
      primaryRole,
    };
  }

  /**
   * Builds a single channel from a quick 1-click preset pill.
   */
  public static buildChannelFromPreset(
    preset: QuickChannelPreset,
    serverId: string,
    existingCategories: ChannelCategory[],
  ): BuildChannelResult {
    assertInvariant(Boolean(preset && preset.id), 'Geçersiz kanal şablonu.');
    assertInvariant(Boolean(serverId), 'Aktif sunucu kimliği bulunamadı.');

    let targetCat = existingCategories.find(
      (c) => c.server_id === serverId && c.name.toLowerCase() === preset.categoryName.toLowerCase(),
    );
    let isNewCategory = false;

    if (!targetCat) {
      targetCat = {
        id: generatePrefixedId(`cat-${serverId}`),
        server_id: serverId,
        name: preset.categoryName,
        position: existingCategories.filter((c) => c.server_id === serverId).length,
        is_collapsed: false,
      };
      isNewCategory = true;
    }

    const gameDef = SUPPORTED_GAMES[preset.gameId] || getGameById(preset.gameId);
    const missingRoles = (gameDef?.roles || []).slice(1, 5).map((r) => r.shortLabel);

    const channel: Channel = {
      id: generatePrefixedId(`ch-${preset.gameId}`),
      server_id: serverId,
      category_id: targetCat.id,
      name: preset.name,
      type: preset.type,
      position: 99,
      created_at: new Date().toISOString(),
      game_id: preset.gameId,
      max_participants: preset.maxParticipants,
      tags: [
        ...(SUPPORTED_GAMES[preset.gameId]?.tags ?? ['#Oyun']),
        ...(missingRoles[0] ? [`#${missingRoles[0]}-Aranıyor`] : []),
      ],
    };

    return { category: targetCat, channel, missingRoles, isNewCategory };
  }

  /**
   * Builds a custom user-defined channel and assigns appropriate tactical categories.
   */
  public static buildCustomChannel(
    options: CustomChannelOptions,
    serverId: string,
    existingCategories: ChannelCategory[],
  ): BuildChannelResult {
    assertInvariant(Boolean(serverId), 'Aktif sunucu kimliği bulunamadı.');

    const cleanName =
      options.name.trim().replace(/\s+/g, '-').toLowerCase() || `${options.gameId}-odasi`;

    const gameDef = SUPPORTED_GAMES[options.gameId] || getGameById(options.gameId);
    const missingRoles = (gameDef?.roles || []).slice(1, 5).map((r) => r.shortLabel);

    const categoryName =
      gameDef.category === 'moba'
        ? '⚔️ MOBA KANALLARI'
        : gameDef.category === 'fps'
          ? '🎯 TAKTİK FPS'
          : gameDef.category === 'br'
            ? '🪂 BATTLE ROYALE'
            : '☕ TOPLULUK & CHILL';

    let targetCat = existingCategories.find(
      (c) => c.server_id === serverId && c.name === categoryName,
    );
    let isNewCategory = false;

    if (!targetCat) {
      targetCat = {
        id: generatePrefixedId(`cat-${serverId}`),
        server_id: serverId,
        name: categoryName,
        position: existingCategories.filter((c) => c.server_id === serverId).length,
        is_collapsed: false,
      };
      isNewCategory = true;
    }

    const channel: Channel = {
      id: generatePrefixedId('ch-cust'),
      server_id: serverId,
      category_id: targetCat.id,
      name: cleanName,
      type: options.type,
      position: 100,
      created_at: new Date().toISOString(),
      game_id: options.gameId,
      max_participants: options.maxParticipants,
      tags: [
        ...gameDef.tags,
        ...(missingRoles[0] ? [`#${missingRoles[0]}-Aranıyor`] : []),
      ],
    };

    return { category: targetCat, channel, missingRoles, isNewCategory };
  }

  /**
   * Persists server, category, and channel structures to IndexedDB with batch coalescing.
   */
  public static persistHubStructure(
    servers: Server[],
    categories: ChannelCategory[],
    channels: Channel[],
  ): void {
    try {
      const storage = getMevaStorageEngine();
      storage.scheduleWrite(STORE_PREFS, 'custom_servers', servers);
      storage.scheduleWrite(STORE_PREFS, 'custom_categories', categories);
      storage.scheduleWrite(STORE_PREFS, 'custom_channels', channels);
      void storage.flushPendingWrites();
    } catch {
      // Storage errors handled gracefully without UI crash
    }
  }
}
