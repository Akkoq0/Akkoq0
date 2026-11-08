// ─────────────────────────────────────────────────────────
// Meva HUD — Global State Store (Zustand — Selector Optimized)
// ─────────────────────────────────────────────────────────

import { create } from 'zustand';
import { getMevaAudioEngine } from '@/src/lib/audioEngine';
import type {
  AppState,
  Message,
  EcoModeState,
  NetGuardStats,
  Friendship,
  SlotBeacon,
  DuoLinkState,
} from '@/types';

const SEED_ISO = '2026-11-06T19:00:00.000Z';

const DEFAULT_FRIENDS: Friendship[] = [];

export const useAppStore = create<AppState>((set) => ({
  activeServerId: null,
  activeChannelId: null,
  activeVoiceChannelId: null,
  activeDMUserId: null,

  servers: [],
  categories: [],
  channels: [],
  messages: [],
  voiceParticipants: [],
  onlineMembers: [],
  friends: DEFAULT_FRIENDS,

  ecoMode: {
    isActive: false,
    isEnabled: true,
    cpuEstimate: 0,
    animationsPaused: false,
  },

  activeScrimRoom: null,
  showScrimModal: false,
  showLobbyGate: false,
  showChannelBuilderModal: false,
  showOnboardingModal: false,
  showTourModal: false,
  showStreamerOverlayModal: false,
  showSoundboardModal: false,
  showRadialCommandWheel: false,
  showVoiceClipBufferModal: false,
  showScrimScheduleModal: false,
  showShortcutsHelpModal: false,

  selectedGameFilter: 'all',
  userPrimaryGame: 'cs2',
  userFavoriteGames: ['cs2', 'valorant', 'lol'],
  userGameRoles: { cs2: 'IGL', valorant: 'DUELIST', lol: 'JUNGLE' },
  userCommunityTags: ['#Tryhard-Dereceli', '#Scrim-Turnuva'],

  slotBeacons: {
    1: { slotIndex: 1, targetRole: null, beaconActive: false },
    2: { slotIndex: 2, targetRole: null, beaconActive: false },
    3: { slotIndex: 3, targetRole: null, beaconActive: false },
    4: { slotIndex: 4, targetRole: null, beaconActive: false },
  },
  duoLink: {
    partnerId: null,
    partnerName: null,
    isActive: false,
    isTransmitting: false,
  },
  activeSonarTargetId: null,

  netGuard: {
    jitterMs: 0.2,
    packetLossPercent: 0,
    bufferSizeMs: 12,
    qualityScore: 99,
    qualityLabel: 'Mükemmel',
  },

  showUserSettings: false,
  showFriendsModal: false,
  collapsedCategories: new Set<string>(),
  isRadarOpen: false,
  isMobileSidebarOpen: false,
  isMobileRadarOpen: false,
  mobileTab: 'chat',

  setActiveServer: (id) =>
    set({
      activeServerId: id,
      activeChannelId: null,
      activeDMUserId: null,
      messages: [],
      categories: [],
      channels: [],
      isMobileSidebarOpen: false,
    }),

  setActiveChannel: (id) =>
    set({
      activeChannelId: id,
      activeDMUserId: null,
      messages: [],
      isMobileSidebarOpen: false,
      mobileTab: 'chat',
    }),

  setActiveVoiceChannel: (id) =>
    set({ activeVoiceChannelId: id, isMobileSidebarOpen: false }),

  setActiveDMUser: (userId) =>
    set({
      activeDMUserId: userId,
      activeChannelId: null,
      messages: [],
      isMobileSidebarOpen: false,
      showFriendsModal: false,
      mobileTab: 'chat',
    }),

  setServers: (servers) => set({ servers }),

  removeServer: (serverId) =>
    set((s) => {
      const remainingServers = s.servers.filter((srv) => srv.id !== serverId);
      const remainingCategories = s.categories.filter((cat) => cat.server_id !== serverId);
      const remainingChannels = s.channels.filter((chan) => chan.server_id !== serverId);
      const nextActiveServer = remainingServers[0]?.id ?? null;
      const nextActiveChannel =
        remainingChannels.find((c) => c.server_id === nextActiveServer && c.type === 'text')?.id ?? null;
      const nextActiveVoice =
        remainingChannels.find((c) => c.server_id === nextActiveServer && c.type === 'voice')?.id ?? null;
      return {
        servers: remainingServers,
        categories: remainingCategories,
        channels: remainingChannels,
        activeServerId: nextActiveServer,
        activeChannelId: nextActiveChannel,
        activeVoiceChannelId: nextActiveVoice,
      };
    }),

  setCategories: (categories) => set({ categories }),

  removeCategory: (categoryId) =>
    set((s) => ({
      categories: s.categories.filter((cat) => cat.id !== categoryId),
      channels: s.channels.filter((chan) => chan.category_id !== categoryId),
    })),

  setChannels: (channels) => set({ channels }),

  addChannel: (channel) =>
    set((s) => {
      if (s.channels.some((c) => c.id === channel.id)) return s;
      return { channels: [...s.channels, channel] };
    }),

  removeChannel: (channelId) =>
    set((s) => {
      const remaining = s.channels.filter((chan) => chan.id !== channelId);
      const nextVoice =
        s.activeVoiceChannelId === channelId
          ? remaining.find((c) => c.server_id === s.activeServerId && c.type === 'voice')?.id ?? null
          : s.activeVoiceChannelId;
      const nextText =
        s.activeChannelId === channelId
          ? remaining.find((c) => c.server_id === s.activeServerId && c.type === 'text')?.id ?? null
          : s.activeChannelId;
      return {
        channels: remaining,
        activeVoiceChannelId: nextVoice,
        activeChannelId: nextText,
      };
    }),

  addCategory: (category) =>
    set((s) => {
      if (s.categories.some((c) => c.id === category.id)) return s;
      return { categories: [...s.categories, category] };
    }),

  addMessage: (message: Message) =>
    set((s) => {
      if (s.messages.some((m) => m.id === message.id)) return s;
      return {
        messages: [...s.messages.slice(-99), message],
      };
    }),

  setMessages: (messages) => set({ messages }),

  setVoiceParticipants: (participants) =>
    set({ voiceParticipants: participants }),

  setOnlineMembers: (members) => set({ onlineMembers: members }),

  setFriends: (friends) => set({ friends }),

  addFriendRequest: (username) =>
    set((s) => {
      const cleanName = username
        .replace(/[\u0000-\u001F\u007F]/g, '')
        .trim()
        .slice(0, 32);
      if (cleanName.length < 2) return s;

      const exists = s.friends.some(
        (f) => f.friend?.username.toLowerCase() === cleanName.toLowerCase(),
      );
      if (exists) return s;

      const uid =
        typeof crypto !== 'undefined' && 'randomUUID' in crypto
          ? crypto.randomUUID()
          : `${Date.now()}`;
      const nowIso = new Date().toISOString();

      const newFriendship: Friendship = {
        id: `f-${uid}`,
        user_id: 'usr-current',
        friend_id: `usr-${uid}`,
        status: 'pending',
        friend: {
          id: `usr-${uid}`,
          username: cleanName,
          avatar_url: null,
          status: 'online',
          activity: 'Çağrı Bekleniyor',
          created_at: nowIso,
        },
        created_at: nowIso,
      };
      return { friends: [...s.friends, newFriendship] };
    }),

  acceptFriendRequest: (friendshipId) =>
    set((s) => ({
      friends: s.friends.map((f) =>
        f.id === friendshipId ? { ...f, status: 'accepted' } : f,
      ),
    })),

  removeFriend: (friendId) =>
    set((s) => ({
      friends: s.friends.filter((f) => f.friend_id !== friendId),
      activeDMUserId: s.activeDMUserId === friendId ? null : s.activeDMUserId,
    })),

  setEcoMode: (update: Partial<EcoModeState>) =>
    set((s) => ({ ecoMode: { ...s.ecoMode, ...update } })),

  toggleEcoEnabled: () =>
    set((s) => ({
      ecoMode: { ...s.ecoMode, isEnabled: !s.ecoMode.isEnabled },
    })),

  setActiveScrimRoom: (room) => set({ activeScrimRoom: room }),

  setShowScrimModal: (show) => set({ showScrimModal: show }),

  setShowLobbyGate: (show) => set({ showLobbyGate: show }),

  setShowChannelBuilderModal: (show) => set({ showChannelBuilderModal: show }),

  setShowOnboardingModal: (show) => set({ showOnboardingModal: show }),

  setShowTourModal: (show) => set({ showTourModal: show }),

  setShowStreamerOverlayModal: (show) => set({ showStreamerOverlayModal: show }),

  setShowSoundboardModal: (show) => set({ showSoundboardModal: show }),

  setShowRadialCommandWheel: (show) => set({ showRadialCommandWheel: show }),

  setShowVoiceClipBufferModal: (show) => set({ showVoiceClipBufferModal: show }),

  setShowScrimScheduleModal: (show) => set({ showScrimScheduleModal: show }),

  setShowShortcutsHelpModal: (show) => set({ showShortcutsHelpModal: show }),

  setSelectedGameFilter: (filter) => set({ selectedGameFilter: filter }),

  setUserPrimaryGame: (gameId) => set({ userPrimaryGame: gameId }),

  setUserFavoriteGames: (games) => set({ userFavoriteGames: games }),

  setUserGameRole: (gameId, role) =>
    set((s) => ({
      userGameRoles: { ...s.userGameRoles, [gameId]: role },
    })),

  setUserCommunityTags: (tags) => set({ userCommunityTags: tags }),

  setSlotBeacon: (slotIndex, targetRole) =>
    set((s) => ({
      slotBeacons: {
        ...s.slotBeacons,
        [slotIndex]: {
          slotIndex,
          targetRole,
          beaconActive: Boolean(targetRole),
        },
      },
    })),

  clearSlotBeacon: (slotIndex) =>
    set((s) => ({
      slotBeacons: {
        ...s.slotBeacons,
        [slotIndex]: {
          slotIndex,
          targetRole: null,
          beaconActive: false,
        },
      },
    })),

  setDuoLinkPartner: (partnerId, partnerName = null) => {
    const isNew = Boolean(partnerId);
    getMevaAudioEngine().playDuoLinkChirp(isNew);
    getMevaAudioEngine().setDuoLinkPartner(partnerId);
    set({
      duoLink: {
        partnerId,
        partnerName: partnerName ?? (partnerId ? 'Partner' : null),
        isActive: isNew,
        isTransmitting: false,
      },
    });
  },

  setDuoLinkActive: (active) => {
    getMevaAudioEngine().setDuoLinkTransmitting(active);
    set((s) => ({
      duoLink: {
        ...s.duoLink,
        isTransmitting: active,
        isActive: active || Boolean(s.duoLink.partnerId),
      },
    }));
  },

  triggerSonarPulse: (targetId, pan = 0) => {
    getMevaAudioEngine().play3DSonarPulse(pan);
    set({ activeSonarTargetId: targetId });
    setTimeout(() => {
      if (useAppStore.getState().activeSonarTargetId === targetId) {
        set({ activeSonarTargetId: null });
      }
    }, 2200);
  },

  setNetGuard: (stats: Partial<NetGuardStats>) =>
    set((s) => ({ netGuard: { ...s.netGuard, ...stats } })),

  toggleCategory: (categoryId) =>
    set((s) => {
      const next = new Set(s.collapsedCategories);
      if (next.has(categoryId)) next.delete(categoryId);
      else next.add(categoryId);
      return { collapsedCategories: next };
    }),

  setShowUserSettings: (show) => set({ showUserSettings: show }),

  setShowFriendsModal: (show) => set({ showFriendsModal: show }),

  toggleRadar: () => set((s) => ({ isRadarOpen: !s.isRadarOpen })),

  setIsMobileSidebarOpen: (open) => set({ isMobileSidebarOpen: open }),

  setIsMobileRadarOpen: (open) => set({ isMobileRadarOpen: open }),

  setMobileTab: (tab) =>
    set({
      mobileTab: tab,
      isMobileSidebarOpen: false,
      isMobileRadarOpen: false,
      showFriendsModal: false,
      showScrimModal: false,
    }),
}));
