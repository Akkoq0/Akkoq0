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
  showProLicenseModal: false,
  subscriptionTier: 'community',

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
  isRadarOpen: true,
  isMobileSidebarOpen: false,
  isMobileRadarOpen: false,
  mobileTab: 'chat',
  mobileHandMode: 'right',
  mobileDensity: 'compact',
  mobileVoiceMode: 'vad',
  showMobileCustomizer: false,

  setActiveServer: (id) =>
    set((state) => {
      const serverChannels = state.channels.filter((c) => !c.server_id || c.server_id === id);
      const firstText = serverChannels.find((c) => c.type === 'text');
      return {
        activeServerId: id,
        activeChannelId: firstText ? firstText.id : null,
        activeDMUserId: null,
        messages: [],
        isMobileSidebarOpen: false,
      };
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
    set((state) => {
      let nextActiveChannelId = state.activeChannelId;
      if (userId === null && !nextActiveChannelId) {
        const srvChannels = state.channels.filter(
          (c) => !c.server_id || c.server_id === state.activeServerId,
        );
        const firstText = srvChannels.find((c) => c.type === 'text');
        nextActiveChannelId = firstText ? firstText.id : null;
      }
      return {
        activeDMUserId: userId,
        activeChannelId: userId ? null : nextActiveChannelId,
        messages: [],
        isMobileSidebarOpen: false,
        showFriendsModal: false,
        mobileTab: 'chat',
      };
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
    set((s) => {
      if (s.voiceParticipants.length === participants.length) {
        let same = true;
        for (let i = 0; i < participants.length; i++) {
          const a = s.voiceParticipants[i];
          const b = participants[i];
          if (
            a.user_id !== b.user_id ||
            a.is_speaking !== b.is_speaking ||
            a.is_muted !== b.is_muted ||
            a.is_deafened !== b.is_deafened
          ) {
            same = false;
            break;
          }
        }
        if (same) return s;
      }
      return { voiceParticipants: participants };
    }),

  setOnlineMembers: (members) =>
    set((s) => {
      if (s.onlineMembers.length === members.length) {
        let same = true;
        for (let i = 0; i < members.length; i++) {
          const a = s.onlineMembers[i];
          const b = members[i];
          if (
            a.id !== b.id ||
            a.status !== b.status ||
            a.username !== b.username ||
            a.activity !== b.activity
          ) {
            same = false;
            break;
          }
        }
        if (same) return s;
      }
      return { onlineMembers: members };
    }),

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
    set((s) => {
      let changed = false;
      for (const key of Object.keys(stats) as Array<keyof NetGuardStats>) {
        if (s.netGuard[key] !== stats[key]) {
          changed = true;
          break;
        }
      }
      if (!changed) return s;
      return { netGuard: { ...s.netGuard, ...stats } };
    }),

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

  setMobileHandMode: (mode) => {
    if (typeof window !== 'undefined') {
      try { localStorage.setItem('meva_mobile_hand', mode); } catch {}
    }
    set({ mobileHandMode: mode });
  },

  setMobileDensity: (density) => {
    if (typeof window !== 'undefined') {
      try { localStorage.setItem('meva_mobile_density', density); } catch {}
    }
    set({ mobileDensity: density });
  },

  setMobileVoiceMode: (mode) => {
    if (typeof window !== 'undefined') {
      try { localStorage.setItem('meva_mobile_voicemode', mode); } catch {}
    }
    set({ mobileVoiceMode: mode });
  },

  setShowMobileCustomizer: (show) => set({ showMobileCustomizer: show }),
  setSubscriptionTier: (tier) => {
    if (typeof window !== 'undefined') {
      try { localStorage.setItem('meva_sub_tier', tier); } catch {}
    }
    set({ subscriptionTier: tier });
  },
  setShowProLicenseModal: (show) => set({ showProLicenseModal: show }),
}));
