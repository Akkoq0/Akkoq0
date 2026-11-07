// ─────────────────────────────────────────────────────────
// Meva HUD — Global State Store (Zustand — Selector Optimized)
// ─────────────────────────────────────────────────────────

import { create } from 'zustand';
import type {
  AppState,
  Message,
  EcoModeState,
  NetGuardStats,
  Friendship,
} from '@/types';

const SEED_ISO = '2026-11-06T19:00:00.000Z';

const DEFAULT_FRIENDS: Friendship[] = [];

export const useAppStore = create<AppState>((set) => ({
  activeServerId: 'srv-1',
  activeChannelId: 'ch-2',
  activeVoiceChannelId: 'ch-4',
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

  setCategories: (categories) => set({ categories }),

  setChannels: (channels) => set({ channels }),

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
