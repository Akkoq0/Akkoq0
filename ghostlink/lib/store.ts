// ─────────────────────────────────────────────────────────
// GhostLink — Global State v2 (Zustand — Full Interactive)
// ─────────────────────────────────────────────────────────
// ~1 KB gzipped. Selector pattern: each panel subscribes
// only to its own slice → zero cross-panel re-renders.

import { create } from 'zustand';
import type { AppState, Message, EcoModeState, NetGuardStats, Friendship } from '@/types';

// Default esports friends for instant 1v1 testing
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
      activity: 'Valorant — Radiant',
      created_at: new Date().toISOString(),
    },
    created_at: new Date().toISOString(),
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
      created_at: new Date().toISOString(),
    },
    created_at: new Date().toISOString(),
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
      created_at: new Date().toISOString(),
    },
    created_at: new Date().toISOString(),
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
      created_at: new Date().toISOString(),
    },
    created_at: new Date().toISOString(),
  },
];

export const useAppStore = create<AppState>((set, get) => ({
  // ════════════════════════════════════════════════════
  // STATE
  // ════════════════════════════════════════════════════

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
    isEnabled: true,     // On by default — competitive advantage
    cpuEstimate: 0,
    animationsPaused: false,
  },

  activeScrimRoom: null,
  showScrimModal: false,

  netGuard: {
    jitterMs: 0,
    packetLossPercent: 0,
    bufferSizeMs: 20,
    qualityScore: 100,
    qualityLabel: 'Mükemmel',
  },

  showUserSettings: false,
  showFriendsModal: false,
  collapsedCategories: new Set<string>(),
  isRadarOpen: false,
  isMobileSidebarOpen: false,
  isMobileRadarOpen: false,

  // ════════════════════════════════════════════════════
  // ACTIONS — Navigation
  // ════════════════════════════════════════════════════

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
    set({ activeChannelId: id, activeDMUserId: null, messages: [], isMobileSidebarOpen: false }),

  setActiveVoiceChannel: (id) =>
    set({ activeVoiceChannelId: id, isMobileSidebarOpen: false }),

  setActiveDMUser: (userId) =>
    set({ activeDMUserId: userId, activeChannelId: null, messages: [], isMobileSidebarOpen: false }),

  // ════════════════════════════════════════════════════
  // ACTIONS — Data
  // ════════════════════════════════════════════════════

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
      const cleanName = username.trim();
      if (!cleanName) return s;
      const newFriendship: Friendship = {
        id: `f-${Date.now()}`,
        user_id: 'usr-current',
        friend_id: `usr-${Date.now()}`,
        status: 'pending',
        friend: {
          id: `usr-${Date.now()}`,
          username: cleanName,
          avatar_url: null,
          status: 'online',
          activity: null,
          created_at: new Date().toISOString(),
        },
        created_at: new Date().toISOString(),
      };
      return { friends: [...s.friends, newFriendship] };
    }),

  acceptFriendRequest: (friendshipId) =>
    set((s) => ({
      friends: s.friends.map((f) =>
        f.id === friendshipId ? { ...f, status: 'accepted' } : f
      ),
    })),

  removeFriend: (friendId) =>
    set((s) => ({
      friends: s.friends.filter((f) => f.friend_id !== friendId),
      activeDMUserId: s.activeDMUserId === friendId ? null : s.activeDMUserId,
    })),

  // ════════════════════════════════════════════════════
  // ACTIONS — Eco Mode (Innovation #1)
  // ════════════════════════════════════════════════════

  setEcoMode: (update: Partial<EcoModeState>) =>
    set((s) => ({ ecoMode: { ...s.ecoMode, ...update } })),

  toggleEcoEnabled: () =>
    set((s) => ({
      ecoMode: { ...s.ecoMode, isEnabled: !s.ecoMode.isEnabled },
    })),

  // ════════════════════════════════════════════════════
  // ACTIONS — Scrim (Innovation #2)
  // ════════════════════════════════════════════════════

  setActiveScrimRoom: (room) => set({ activeScrimRoom: room }),

  setShowScrimModal: (show) => set({ showScrimModal: show }),

  // ════════════════════════════════════════════════════
  // ACTIONS — Net-Guard (Innovation #3)
  // ════════════════════════════════════════════════════

  setNetGuard: (stats: Partial<NetGuardStats>) =>
    set((s) => ({ netGuard: { ...s.netGuard, ...stats } })),

  // ════════════════════════════════════════════════════
  // ACTIONS — UI & Mobile
  // ════════════════════════════════════════════════════

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
