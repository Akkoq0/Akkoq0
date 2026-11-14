'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Global Notification & Alert Drawer Store
// ─────────────────────────────────────────────────────────

import { create } from 'zustand';

export type MevaNotificationType = 'tactical' | 'invite' | 'system' | 'audit';

export interface MevaNotification {
  id: string;
  title: string;
  message: string;
  type: MevaNotificationType;
  time: string;
  read: boolean;
  ts: number;
}

interface NotificationState {
  notifications: MevaNotification[];
  isDrawerOpen: boolean;
  openDrawer: () => void;
  closeDrawer: () => void;
  toggleDrawer: () => void;
  pushNotification: (entry: {
    title: string;
    message: string;
    type: MevaNotificationType;
    time?: string;
  }) => void;
  markAsRead: (id: string) => void;
  markAllRead: () => void;
  removeNotification: (id: string) => void;
  clearAll: () => void;
}

function formatShortClock(ts: number): string {
  try {
    return new Date(ts).toLocaleTimeString('tr-TR', {
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
    });
  } catch {
    return 'Şimdi';
  }
}

const INITIAL_NOTIFICATIONS: MevaNotification[] = [
  {
    id: 'notif-boot-e2ee',
    title: 'Donanım Tabanlı E2EE Aktif',
    message: 'WebRTC veri kanalları ECDH P-256 & hardware-derived AES-256-GCM ile korunuyor.',
    type: 'audit',
    time: 'Başlangıç',
    read: false,
    ts: 1,
  },
  {
    id: 'notif-boot-keepalive',
    title: 'Keep-Alive & IndexedDB Kurtarma Hazır',
    message: 'Bağlantı sürekliliği ve anlık oturum/çizim kurtarma modülü çalışıyor.',
    type: 'system',
    time: 'Başlangıç',
    read: true,
    ts: 2,
  },
];

export const useNotificationStore = create<NotificationState>((set) => ({
  notifications: INITIAL_NOTIFICATIONS,
  isDrawerOpen: false,

  openDrawer: () => set({ isDrawerOpen: true }),
  closeDrawer: () => set({ isDrawerOpen: false }),
  toggleDrawer: () => set((s) => ({ isDrawerOpen: !s.isDrawerOpen })),

  pushNotification: ({ title, message, type, time }) =>
    set((state) => {
      const now = Date.now();
      const next: MevaNotification = {
        id: `notif-${now.toString(36)}-${Math.random().toString(36).slice(2, 6)}`,
        title,
        message,
        type,
        time: time ?? formatShortClock(now),
        read: false,
        ts: now,
      };
      return {
        notifications: [next, ...state.notifications].slice(0, 40),
      };
    }),

  markAsRead: (id) =>
    set((state) => ({
      notifications: state.notifications.map((n) =>
        n.id === id ? { ...n, read: true } : n,
      ),
    })),

  markAllRead: () =>
    set((state) => ({
      notifications: state.notifications.map((n) => ({ ...n, read: true })),
    })),

  removeNotification: (id) =>
    set((state) => ({
      notifications: state.notifications.filter((n) => n.id !== id),
    })),

  clearAll: () => set({ notifications: [] }),
}));
