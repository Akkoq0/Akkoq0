// ─────────────────────────────────────────────────────────
// GhostLink — Tactical Player HUD Store (store/useHUDStore.ts)
// ─────────────────────────────────────────────────────────

import { create } from 'zustand';
import type { Profile } from '@/types';

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
  playerGains: Record<string, number>; // 0 to 200%
  localMutes: Record<string, boolean>;
  metrics: TacticalMetrics;

  openHUD: (player: Profile) => void;
  closeHUD: () => void;
  setPlayerGain: (playerId: string, gain: number) => void;
  toggleLocalMute: (playerId: string) => void;
}

export const useHUDStore = create<HUDState>((set) => ({
  selectedPlayer: null,
  isOpen: false,
  playerGains: {},
  localMutes: {},
  metrics: {
    ping: 18,
    jitter: 1.2,
    packetLoss: 0.0,
    inputBitrate: 24,
    micCodec: 'Opus 48kHz (Mono)',
  },

  openHUD: (player) =>
    set({
      selectedPlayer: player,
      isOpen: true,
      // Generates tactical simulated live network stats for target peer
      metrics: {
        ping: Math.floor(12 + Math.random() * 15),
        jitter: Math.round((0.8 + Math.random() * 1.5) * 10) / 10,
        packetLoss: Math.random() > 0.85 ? 0.4 : 0.0,
        inputBitrate: 24,
        micCodec: 'Opus 48kHz (Mono)',
      },
    }),

  closeHUD: () => set({ isOpen: false, selectedPlayer: null }),

  setPlayerGain: (playerId, gain) =>
    set((s) => ({
      playerGains: { ...s.playerGains, [playerId]: gain },
    })),

  toggleLocalMute: (playerId) =>
    set((s) => ({
      localMutes: {
        ...s.localMutes,
        [playerId]: !s.localMutes[playerId],
      },
    })),
}));

