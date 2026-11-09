/**
 * @file useHubArchitect.ts
 * @description Clean Custom Hook encapsulating Hub Architect business state,
 * event handling, and ServerArchitectService integration (Single Responsibility).
 */

import { useState, useEffect, useCallback } from 'react';
import { useAppStore } from '@/lib/store';
import { useHUDStore } from '@/store/useHUDStore';
import {
  type ServerTemplate,
  type QuickChannelPreset,
  type SupportedGameId,
  SUPPORTED_GAMES,
} from '@/src/lib/gameRegistry';
import {
  ServerArchitectService,
  type CustomChannelOptions,
} from '@/src/services/serverArchitectService';

export function useHubArchitect(isOpen: boolean, onClose: () => void) {
  const [activeTab, setActiveTab] = useState<'server' | 'channel'>('server');
  const [customName, setCustomName] = useState('');
  const [customGame, setCustomGame] = useState<SupportedGameId>('cs2');
  const [customType, setCustomType] = useState<'voice' | 'text'>('voice');
  const [customMax, setCustomMax] = useState(5);
  const [feedback, setFeedback] = useState<string | null>(null);

  const activeServerId = useAppStore((s) => s.activeServerId);
  const servers = useAppStore((s) => s.servers);
  const categories = useAppStore((s) => s.categories);
  const channels = useAppStore((s) => s.channels);

  const setServers = useAppStore((s) => s.setServers);
  const setActiveServer = useAppStore((s) => s.setActiveServer);
  const setCategories = useAppStore((s) => s.setCategories);
  const setChannels = useAppStore((s) => s.setChannels);
  const addCategory = useAppStore((s) => s.addCategory);
  const addChannel = useAppStore((s) => s.addChannel);
  const setActiveChannel = useAppStore((s) => s.setActiveChannel);
  const setActiveVoiceChannel = useAppStore((s) => s.setActiveVoiceChannel);

  // If no servers exist yet, default to server creation tab
  useEffect(() => {
    if (servers.length === 0) {
      setActiveTab('server');
    }
  }, [servers.length]);

  // Clean keyboard listener for Escape key
  useEffect(() => {
    if (!isOpen) return;
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        e.preventDefault();
        onClose();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [isOpen, onClose]);

  // Ensures active server exists before channels are added
  const getEnsuredActiveServerId = useCallback((): string => {
    const { activeId, servers: updatedServers, isCreated } =
      ServerArchitectService.ensureActiveServer(activeServerId, servers);

    if (isCreated) {
      setServers(updatedServers);
      setActiveServer(activeId);
      ServerArchitectService.persistHubStructure(updatedServers, categories, channels);
    }
    return activeId;
  }, [activeServerId, servers, categories, channels, setServers, setActiveServer]);

  // Applies community server template
  const applyServerTemplate = useCallback(
    (template: ServerTemplate) => {
      const result = ServerArchitectService.buildServerFromTemplate(template);

      const updatedServers = [result.server, ...servers.filter((s) => s.id !== result.server.id)];
      const updatedCategories = [
        ...categories.filter((c) => c.server_id !== result.server.id),
        ...result.categories,
      ];
      const updatedChannels = [
        ...channels.filter((c) => c.server_id !== result.server.id),
        ...result.channels,
      ];

      setServers(updatedServers);
      setActiveServer(result.server.id);
      setCategories(updatedCategories);
      setChannels(updatedChannels);

      if (result.firstVoiceChannelId) {
        setActiveVoiceChannel(result.firstVoiceChannelId);
        useHUDStore.getState().setOperatorRole('usr-local', result.primaryRole);
      }
      if (result.firstTextChannelId) {
        setActiveChannel(result.firstTextChannelId);
      }

      ServerArchitectService.persistHubStructure(
        updatedServers,
        updatedCategories,
        updatedChannels,
      );

      setFeedback(`🎉 "${template.serverName}" başarıyla kuruldu ve bağlandı!`);
      setTimeout(() => {
        onClose();
      }, 600);
    },
    [
      servers,
      categories,
      channels,
      setServers,
      setActiveServer,
      setCategories,
      setChannels,
      setActiveVoiceChannel,
      setActiveChannel,
      onClose,
    ],
  );

  // Applies quick channel preset
  const applyPresetChannel = useCallback(
    (preset: QuickChannelPreset) => {
      const serverId = getEnsuredActiveServerId();
      const result = ServerArchitectService.buildChannelFromPreset(preset, serverId, categories);

      if (result.isNewCategory) {
        addCategory(result.category);
      }
      addChannel(result.channel);

      if (preset.type === 'voice') {
        setActiveVoiceChannel(result.channel.id);
        result.missingRoles.forEach((role, idx) => {
          useAppStore.getState().setSlotBeacon(idx + 1, role);
        });
      } else {
        setActiveChannel(result.channel.id);
      }

      const latestCategories = result.isNewCategory
        ? [...categories, result.category]
        : categories;
      const latestChannels = [...channels, result.channel];
      ServerArchitectService.persistHubStructure(servers, latestCategories, latestChannels);

      setFeedback(`✅ #${preset.name} kanalı başarıyla eklendi!`);
      setTimeout(() => {
        onClose();
      }, 550);
    },
    [
      categories,
      channels,
      servers,
      getEnsuredActiveServerId,
      addCategory,
      addChannel,
      setActiveVoiceChannel,
      setActiveChannel,
      onClose,
    ],
  );

  // Creates custom channel
  const createCustomChannel = useCallback(
    (e: React.FormEvent) => {
      e.preventDefault();
      const serverId = getEnsuredActiveServerId();
      const options: CustomChannelOptions = {
        name: customName,
        gameId: customGame,
        type: customType,
        maxParticipants: customMax,
      };

      const result = ServerArchitectService.buildCustomChannel(options, serverId, categories);

      if (result.isNewCategory) {
        addCategory(result.category);
      }
      addChannel(result.channel);

      if (options.type === 'voice') {
        setActiveVoiceChannel(result.channel.id);
        result.missingRoles.forEach((role, idx) => {
          useAppStore.getState().setSlotBeacon(idx + 1, role);
        });
      } else {
        setActiveChannel(result.channel.id);
      }

      const latestCategories = result.isNewCategory
        ? [...categories, result.category]
        : categories;
      const latestChannels = [...channels, result.channel];
      ServerArchitectService.persistHubStructure(servers, latestCategories, latestChannels);

      onClose();
    },
    [
      customName,
      customGame,
      customType,
      customMax,
      categories,
      channels,
      servers,
      getEnsuredActiveServerId,
      addCategory,
      addChannel,
      setActiveVoiceChannel,
      setActiveChannel,
      onClose,
    ],
  );

  const handleGameChange = useCallback((newGame: SupportedGameId) => {
    setCustomGame(newGame);
    setCustomMax(SUPPORTED_GAMES[newGame]?.defaultMax ?? 5);
  }, []);

  return {
    activeTab,
    setActiveTab,
    customName,
    setCustomName,
    customGame,
    handleGameChange,
    customType,
    setCustomType,
    customMax,
    setCustomMax,
    feedback,
    applyServerTemplate,
    applyPresetChannel,
    createCustomChannel,
  };
}
