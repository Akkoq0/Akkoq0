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

const DEFAULT_FRIENDS: Friendship[] = [
  {
    id: 'f-1',
    user_id: 'usr-current',
    friend_id: 'usr-1',
    status: 'accepted',
    friend: {
      id: 'usr-1',
      username: 'cNed',
      avatar_url: null,
      status: 'in-game',
      activity: 'Valorant — Radiant #14',
      created_at: SEED_ISO,
    },
    created_at: SEED_ISO,
  },
  {
    id: 'f-2',
    user_id: 'usr-current',
    friend_id: 'usr-2',
    status: 'accepted',
    friend: {
      id: 'usr-2',
      username: 'woxic',
      avatar_url: null,
      status: 'in-game',
      activity: 'CS2 — Faceit Lvl 10',
      created_at: SEED_ISO,
    },
    created_at: SEED_ISO,
  },
  {
    id: 'f-3',
    user_id: 'usr-current',
    friend_id: 'usr-4',
    status: 'accepted',
    friend: {
      id: 'usr-4',
      username: 'XANTARES',
      avatar_url: null,
      status: 'in-game',
      activity: 'CS2 — 3140 ELO Entry',
      created_at: SEED_ISO,
    },
    created_at: SEED_ISO,
  },
  {
    id: 'f-4',
    user_id: 'usr-current',
    friend_id: 'usr-3',
    status: 'accepted',
    friend: {
      id: 'usr-3',
      username: 'Alfajer',
      avatar_url: null,
      status: 'online',
      activity: 'Valorant — Sentinel / Analiz',
      created_at: SEED_ISO,
    },
    created_at: SEED_ISO,
  },
];

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
    }),

  setActiveVoiceChannel: (id) =>
    set({ activeVoiceChannelId: id, isMobileSidebarOpen: false }),

  setActiveDMUser: (userId) =>
    set({
      activeDMUserId: userId,
      activeChannelId: null,
      messages: [],
      isMobileSidebarOpen: false,
    }),

  setServers: (servers) => set({ servers }),

  setCategories: (categories) => set({ categories }),

  setChannels: (channels) => set({ channels }),

  addMessage: (message: Message) =>
    set((s) => ({
      messages: [...s.messages.slice(-99), message],
    })),

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
}));
