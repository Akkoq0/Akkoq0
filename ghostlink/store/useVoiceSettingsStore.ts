// ─────────────────────────────────────────────────────────
// Meva HUD — Voice Gate, Keybind, Device & Pro Analytics Store
// ─────────────────────────────────────────────────────────

import { create } from 'zustand';
import { getMevaAudioEngine } from '@/src/lib/audioEngine';
import {
  getMevaVadEngine,
  type NoiseGateConfig,
  type VoiceInputMode,
} from '@/src/lib/vadEngine';

export interface KeybindMap {
  pttKey: string;
  muteKey: string;
  deafenKey: string;
  stratBoardKey: string;
  miniHudKey: string;
}

interface VoiceSettingsState {
  inputMode: VoiceInputMode;
  noiseGate: NoiseGateConfig;
  keybinds: KeybindMap;
  inputDeviceId: string;
  outputDeviceId: string;
  showCommandSettingsModal: boolean;
  showStratBoard: boolean;
  miniHudActive: boolean;
  proAnalyticsEnabled: boolean;

  setInputMode: (mode: VoiceInputMode) => void;
  updateNoiseGate: (partial: Partial<NoiseGateConfig>) => void;
  setKeybind: (action: keyof KeybindMap, code: string) => void;
  setInputDeviceId: (deviceId: string) => void;
  setOutputDeviceId: (deviceId: string) => void;
  setShowCommandSettingsModal: (show: boolean) => void;
  setShowStratBoard: (show: boolean) => void;
  toggleStratBoard: () => void;
  setMiniHudActive: (active: boolean) => void;
  toggleMiniHud: () => void;
  setProAnalyticsEnabled: (enabled: boolean) => void;
  hydrateSettings: (partial: Partial<{
    inputMode: VoiceInputMode;
    noiseGate: NoiseGateConfig;
    keybinds: KeybindMap;
    inputDeviceId: string;
    outputDeviceId: string;
    proAnalyticsEnabled: boolean;
  }>) => void;
}

export const useVoiceSettingsStore = create<VoiceSettingsState>((set) => ({
  inputMode: 'vad',
  noiseGate: {
    thresholdDb: -44,
    attackMs: 8,
    holdMs: 165,
    releaseMs: 135,
    keyboardClickFilter: true,
  },
  keybinds: {
    pttKey: 'KeyV',
    muteKey: 'KeyM',
    deafenKey: 'KeyD',
    stratBoardKey: 'KeyB',
    miniHudKey: 'KeyO',
  },
  inputDeviceId: 'default',
  outputDeviceId: 'default',
  showCommandSettingsModal: false,
  showStratBoard: false,
  miniHudActive: false,
  proAnalyticsEnabled: false,

  setInputMode: (mode) => {
    getMevaVadEngine().setMode(mode);
    set({ inputMode: mode });
  },

  updateNoiseGate: (partial) =>
    set((s) => {
      const next = { ...s.noiseGate, ...partial };
      getMevaVadEngine().updateConfig(next);
      return { noiseGate: next };
    }),

  setKeybind: (action, code) =>
    set((s) => {
      const clean = code.trim().slice(0, 32) || s.keybinds[action];
      if (action === 'pttKey') {
        getMevaVadEngine().setPttKeyCode(clean);
      }
      return {
        keybinds: {
          ...s.keybinds,
          [action]: clean,
        },
      };
    }),

  setInputDeviceId: (deviceId) => {
    set({ inputDeviceId: deviceId || 'default' });
  },

  setOutputDeviceId: (deviceId) => {
    const clean = deviceId || 'default';
    void getMevaAudioEngine().setOutputDevice(clean);
    set({ outputDeviceId: clean });
  },

  setShowCommandSettingsModal: (show) => set({ showCommandSettingsModal: show }),

  setShowStratBoard: (show) => set({ showStratBoard: show }),

  toggleStratBoard: () => set((s) => ({ showStratBoard: !s.showStratBoard })),

  setMiniHudActive: (active) => set({ miniHudActive: active }),

  toggleMiniHud: () => set((s) => ({ miniHudActive: !s.miniHudActive })),

  setProAnalyticsEnabled: (enabled) => set({ proAnalyticsEnabled: enabled }),

  hydrateSettings: (partial) =>
    set((s) => {
      const nextMode = partial.inputMode ?? s.inputMode;
      const nextGate = partial.noiseGate ?? s.noiseGate;
      const nextKeybinds = partial.keybinds ?? s.keybinds;
      getMevaVadEngine().setMode(nextMode);
      getMevaVadEngine().updateConfig(nextGate);
      getMevaVadEngine().setPttKeyCode(nextKeybinds.pttKey);
      if (partial.outputDeviceId) {
        void getMevaAudioEngine().setOutputDevice(partial.outputDeviceId);
      }
      return {
        inputMode: nextMode,
        noiseGate: nextGate,
        keybinds: nextKeybinds,
        inputDeviceId: partial.inputDeviceId ?? s.inputDeviceId,
        outputDeviceId: partial.outputDeviceId ?? s.outputDeviceId,
        proAnalyticsEnabled:
          partial.proAnalyticsEnabled ?? s.proAnalyticsEnabled,
      };
    }),
}));
