// ─────────────────────────────────────────────────────────
// Meva HUD — Unified Operator Audio & Telemetry Store
// ─────────────────────────────────────────────────────────
// Synchronizes per-operator gain (0–200%), individual mute,
// and 3D spatial pan (L/C/R) across Squad Pods, Telemetry
// Drawer, and live WebRTC peer audio elements.

import { create } from 'zustand';
import type { Profile } from '@/types';

export type SpatialPan = 'L' | 'C' | 'R';

export interface TacticalMetrics {
  ping: number;
  jitter: number;
  packetLoss: number;
  inputBitrate: number;
  micCodec: string;
}

interface HUDState {
  selectedPlayer: Profile | null;
  isOpen: boolean;
  playerGains: Record<string, number>;
  localMutes: Record<string, boolean>;
  spatialPans: Record<string, SpatialPan>;
  metrics: TacticalMetrics;

  openHUD: (player: Profile) => void;
  closeHUD: () => void;
  setPlayerGain: (playerId: string, gain: number) => void;
  toggleLocalMute: (playerId: string) => void;
  cycleSpatialPan: (playerId: string) => void;
}

export const useHUDStore = create<HUDState>((set) => ({
  selectedPlayer: null,
  isOpen: false,
  playerGains: {
    'usr-local': 100,
    'usr-1': 125,
    'usr-4': 115,
    'usr-2': 100,
    'usr-3': 95,
  },
  localMutes: {},
  spatialPans: {
    'usr-local': 'C',
    'usr-1': 'L',
    'usr-4': 'R',
    'usr-2': 'L',
    'usr-3': 'C',
  },
  metrics: {
    ping: 12,
    jitter: 0.2,
    packetLoss: 0.0,
    inputBitrate: 96,
    micCodec: 'Opus 48kHz (CBR)',
  },

  openHUD: (player) =>
    set({
      selectedPlayer: player,
      isOpen: true,
      metrics: {
        ping: 11,
        jitter: 0.2,
        packetLoss: 0.0,
        inputBitrate: 96,
        micCodec: 'Opus 48kHz (CBR)',
      },
    }),

  closeHUD: () => set({ isOpen: false, selectedPlayer: null }),

  setPlayerGain: (playerId, gain) => {
    const clamped = Math.max(0, Math.min(200, Math.round(gain)));
    set((s) => ({
      playerGains: { ...s.playerGains, [playerId]: clamped },
      localMutes:
        clamped > 0 ? { ...s.localMutes, [playerId]: false } : s.localMutes,
    }));
  },

  toggleLocalMute: (playerId) =>
    set((s) => ({
      localMutes: {
        ...s.localMutes,
        [playerId]: !s.localMutes[playerId],
      },
    })),

  cycleSpatialPan: (playerId) =>
    set((s) => {
      const curr = s.spatialPans[playerId] ?? 'C';
      const next: SpatialPan = curr === 'L' ? 'C' : curr === 'C' ? 'R' : 'L';
      return {
        spatialPans: { ...s.spatialPans, [playerId]: next },
      };
    }),
}));
