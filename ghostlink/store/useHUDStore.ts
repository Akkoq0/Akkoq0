// ─────────────────────────────────────────────────────────
// Meva HUD — Unified Operator DSP, EQ, Ducking & Telemetry Store
// ─────────────────────────────────────────────────────────
// Synchronizes per-operator logarithmic gain (0–200%), local mute,
// 3D spatial pan (L: -1 / C: 0 / R: +1), per-operator EQ profile
// (Crisp / Balanced / Warm), IGL Priority Ducking (-30%), Tactical
// Roles, and live FFT 256 dual-harmonic wave levels.

import { create } from 'zustand';
import {
  getMevaAudioEngine,
  type OperatorEqProfile,
} from '@/src/lib/audioEngine';
import type { Profile } from '@/types';

export type SpatialPan = 'L' | 'C' | 'R';
export type TacticalRole = 'IGL' | 'AWP' | 'ENTRY' | 'LURKER' | 'COACH';

export interface TacticalMetrics {
  ping: number;
  jitter: number;
  packetLoss: number;
  inputBitrate: number;
  micCodec: string;
}

export interface DualWaveLevel {
  primary: number;
  secondary: number;
  rms: number;
}

interface HUDState {
  selectedPlayer: Profile | null;
  isOpen: boolean;
  playerGains: Record<string, number>;
  localMutes: Record<string, boolean>;
  spatialPans: Record<string, SpatialPan>;
  eqProfiles: Record<string, OperatorEqProfile>;
  prioritySpeakers: Record<string, boolean>;
  operatorRoles: Record<string, TacticalRole>;
  iglDuckingEnabled: boolean;
  autoLevelerEnabled: boolean;
  acousticCuesEnabled: boolean;
  peerSpectrums: Record<string, DualWaveLevel>;
  metrics: TacticalMetrics;

  openHUD: (player: Profile) => void;
  closeHUD: () => void;
  setPlayerGain: (playerId: string, gain: number) => void;
  toggleLocalMute: (playerId: string) => void;
  cycleSpatialPan: (playerId: string) => void;
  setSpatialPan: (playerId: string, pan: SpatialPan) => void;
  setEqProfile: (playerId: string, eq: OperatorEqProfile) => void;
  togglePrioritySpeaker: (playerId: string) => void;
  setOperatorRole: (playerId: string, role: TacticalRole) => void;
  setIglDuckingEnabled: (enabled: boolean) => void;
  setAutoLevelerEnabled: (enabled: boolean) => void;
  setAcousticCuesEnabled: (enabled: boolean) => void;
  setPeerSpectrum: (playerId: string, spectrum: DualWaveLevel) => void;
  hydrateAudioPrefs: (prefs: Partial<{
    playerGains: Record<string, number>;
    localMutes: Record<string, boolean>;
    spatialPans: Record<string, SpatialPan>;
    eqProfiles: Record<string, OperatorEqProfile>;
    prioritySpeakers: Record<string, boolean>;
    operatorRoles: Record<string, TacticalRole>;
    iglDuckingEnabled: boolean;
    autoLevelerEnabled: boolean;
    acousticCuesEnabled: boolean;
  }>) => void;
}

export const useHUDStore = create<HUDState>((set, get) => ({
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
  eqProfiles: {
    'usr-local': 'balanced',
    'usr-1': 'crisp',
    'usr-4': 'crisp',
    'usr-2': 'balanced',
    'usr-3': 'warm',
  },
  prioritySpeakers: {
    'usr-local': true,
  },
  operatorRoles: {
    'usr-local': 'IGL',
    'usr-1': 'AWP',
    'usr-4': 'ENTRY',
    'usr-2': 'LURKER',
    'usr-3': 'COACH',
  },
  iglDuckingEnabled: true,
  autoLevelerEnabled: true,
  acousticCuesEnabled: true,
  peerSpectrums: {},
  metrics: {
    ping: 11,
    jitter: 0.2,
    packetLoss: 0.0,
    inputBitrate: 96,
    micCodec: 'Opus 48kHz (FEC+DTX)',
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
        micCodec: 'Opus 48kHz (FEC+DTX)',
      },
    }),

  closeHUD: () => set({ isOpen: false, selectedPlayer: null }),

  setPlayerGain: (playerId, gain) => {
    const clamped = Math.max(0, Math.min(200, Math.round(gain)));
    set((s) => {
      const nextMutes =
        clamped > 0 ? { ...s.localMutes, [playerId]: false } : s.localMutes;
      const pan = s.spatialPans[playerId] ?? 'C';
      const eq = s.eqProfiles[playerId] ?? 'balanced';
      getMevaAudioEngine().updatePeerMix(
        playerId,
        clamped,
        Boolean(nextMutes[playerId]),
        pan,
        eq,
      );
      return {
        playerGains: { ...s.playerGains, [playerId]: clamped },
        localMutes: nextMutes,
      };
    });
  },

  toggleLocalMute: (playerId) =>
    set((s) => {
      const nextMuted = !s.localMutes[playerId];
      const gain = s.playerGains[playerId] ?? 100;
      const pan = s.spatialPans[playerId] ?? 'C';
      const eq = s.eqProfiles[playerId] ?? 'balanced';
      getMevaAudioEngine().updatePeerMix(playerId, gain, nextMuted, pan, eq);
      return {
        localMutes: {
          ...s.localMutes,
          [playerId]: nextMuted,
        },
      };
    }),

  cycleSpatialPan: (playerId) =>
    set((s) => {
      const curr = s.spatialPans[playerId] ?? 'C';
      const next: SpatialPan = curr === 'L' ? 'C' : curr === 'C' ? 'R' : 'L';
      const gain = s.playerGains[playerId] ?? 100;
      const muted = Boolean(s.localMutes[playerId]);
      const eq = s.eqProfiles[playerId] ?? 'balanced';
      getMevaAudioEngine().updatePeerMix(playerId, gain, muted, next, eq);
      return {
        spatialPans: { ...s.spatialPans, [playerId]: next },
      };
    }),

  setSpatialPan: (playerId, pan) =>
    set((s) => {
      const gain = s.playerGains[playerId] ?? 100;
      const muted = Boolean(s.localMutes[playerId]);
      const eq = s.eqProfiles[playerId] ?? 'balanced';
      getMevaAudioEngine().updatePeerMix(playerId, gain, muted, pan, eq);
      return {
        spatialPans: { ...s.spatialPans, [playerId]: pan },
      };
    }),

  setEqProfile: (playerId, eq) =>
    set((s) => {
      const gain = s.playerGains[playerId] ?? 100;
      const muted = Boolean(s.localMutes[playerId]);
      const pan = s.spatialPans[playerId] ?? 'C';
      getMevaAudioEngine().updatePeerMix(playerId, gain, muted, pan, eq);
      return {
        eqProfiles: { ...s.eqProfiles, [playerId]: eq },
      };
    }),

  togglePrioritySpeaker: (playerId) =>
    set((s) => ({
      prioritySpeakers: {
        ...s.prioritySpeakers,
        [playerId]: !s.prioritySpeakers[playerId],
      },
    })),

  setOperatorRole: (playerId, role) =>
    set((s) => ({
      operatorRoles: { ...s.operatorRoles, [playerId]: role },
      prioritySpeakers:
        role === 'IGL'
          ? { ...s.prioritySpeakers, [playerId]: true }
          : s.prioritySpeakers,
    })),

  setIglDuckingEnabled: (enabled) => set({ iglDuckingEnabled: enabled }),

  setAutoLevelerEnabled: (enabled) => {
    getMevaAudioEngine().setAutoLevelerEnabled(enabled);
    set({ autoLevelerEnabled: enabled });
  },

  setAcousticCuesEnabled: (enabled) => {
    getMevaAudioEngine().setAcousticCuesEnabled(enabled);
    set({ acousticCuesEnabled: enabled });
  },

  setPeerSpectrum: (playerId, spectrum) => {
    const prev = get().peerSpectrums[playerId];
    if (
      prev &&
      Math.abs(prev.primary - spectrum.primary) < 0.025 &&
      Math.abs(prev.secondary - spectrum.secondary) < 0.025
    ) {
      return;
    }
    set((s) => ({
      peerSpectrums: { ...s.peerSpectrums, [playerId]: spectrum },
    }));
  },

  hydrateAudioPrefs: (prefs) =>
    set((s) => ({
      playerGains: prefs.playerGains ?? s.playerGains,
      localMutes: prefs.localMutes ?? s.localMutes,
      spatialPans: prefs.spatialPans ?? s.spatialPans,
      eqProfiles: prefs.eqProfiles ?? s.eqProfiles,
      prioritySpeakers: prefs.prioritySpeakers ?? s.prioritySpeakers,
      operatorRoles: prefs.operatorRoles ?? s.operatorRoles,
      iglDuckingEnabled: prefs.iglDuckingEnabled ?? s.iglDuckingEnabled,
      autoLevelerEnabled: prefs.autoLevelerEnabled ?? s.autoLevelerEnabled,
      acousticCuesEnabled: prefs.acousticCuesEnabled ?? s.acousticCuesEnabled,
    })),
}));
