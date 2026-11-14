// ─────────────────────────────────────────────────────────
// Meva HUD — Voice Gate, Keybind, Device & Pro Analytics Store
// ─────────────────────────────────────────────────────────

import { create } from 'zustand';
import { getMevaAudioEngine, type RogerBeepStyle } from '@/src/lib/audioEngine';
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

export type OverlayPosition =
  | 'top-left'
  | 'top-right'
  | 'bottom-left'
  | 'bottom-right';

export type OverlayDisplayMode = 'stealth' | 'compact' | 'tactical-full';

export type CommandSettingsTab =
  | 'audio'
  | 'gate'
  | 'overlay'
  | 'keybinds'
  | 'theme_pro'
  | 'lider_rbac';

interface VoiceSettingsState {
  inputMode: VoiceInputMode;
  noiseGate: NoiseGateConfig;
  keybinds: KeybindMap;
  inputDeviceId: string;
  outputDeviceId: string;
  showCommandSettingsModal: boolean;
  commandSettingsTab: CommandSettingsTab;
  showStratBoard: boolean;
  miniHudActive: boolean;
  proAnalyticsEnabled: boolean;
  rogerBeepEnabled: boolean;
  rogerBeepStyle: RogerBeepStyle;
  rogerBeepVolume: number;
  inGameOverlayEnabled: boolean;
  inGameOverlayPosition: OverlayPosition;
  inGameOverlayMode: OverlayDisplayMode;
  inGameOverlayOpacity: number;
  inGameOverlayAutoFade: boolean;

  setInputMode: (mode: VoiceInputMode) => void;
  updateNoiseGate: (partial: Partial<NoiseGateConfig>) => void;
  setKeybind: (action: keyof KeybindMap, code: string) => void;
  setInputDeviceId: (deviceId: string) => void;
  setOutputDeviceId: (deviceId: string) => void;
  setShowCommandSettingsModal: (show: boolean) => void;
  setCommandSettingsTab: (tab: CommandSettingsTab) => void;
  openCommandSettingsAtTab: (tab: CommandSettingsTab) => void;
  setShowStratBoard: (show: boolean) => void;
  toggleStratBoard: () => void;
  setMiniHudActive: (active: boolean) => void;
  toggleMiniHud: () => void;
  setProAnalyticsEnabled: (enabled: boolean) => void;
  setRogerBeepEnabled: (enabled: boolean) => void;
  setRogerBeepStyle: (style: RogerBeepStyle) => void;
  setRogerBeepVolume: (volume: number) => void;
  setInGameOverlayEnabled: (enabled: boolean) => void;
  setInGameOverlayPosition: (pos: OverlayPosition) => void;
  setInGameOverlayMode: (mode: OverlayDisplayMode) => void;
  setInGameOverlayOpacity: (opacity: number) => void;
  setInGameOverlayAutoFade: (autoFade: boolean) => void;
  hydrateSettings: (partial: Partial<{
    inputMode: VoiceInputMode;
    noiseGate: NoiseGateConfig;
    keybinds: KeybindMap;
    inputDeviceId: string;
    outputDeviceId: string;
    proAnalyticsEnabled: boolean;
    rogerBeepEnabled: boolean;
    rogerBeepStyle: RogerBeepStyle;
    rogerBeepVolume: number;
    inGameOverlayEnabled: boolean;
    inGameOverlayPosition: OverlayPosition;
    inGameOverlayMode: OverlayDisplayMode;
    inGameOverlayOpacity: number;
    inGameOverlayAutoFade: boolean;
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
  commandSettingsTab: 'audio',
  showStratBoard: false,
  miniHudActive: false,
  proAnalyticsEnabled: false,
  rogerBeepEnabled: true,
  rogerBeepStyle: 'classic-milsim',
  rogerBeepVolume: 0.75,
  inGameOverlayEnabled: false,
  inGameOverlayPosition: 'top-left',
  inGameOverlayMode: 'compact',
  inGameOverlayOpacity: 0.9,
  inGameOverlayAutoFade: true,

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

  setCommandSettingsTab: (tab) => set({ commandSettingsTab: tab }),

  openCommandSettingsAtTab: (tab) =>
    set({ showCommandSettingsModal: true, commandSettingsTab: tab }),

  setShowStratBoard: (show) => set({ showStratBoard: show }),

  toggleStratBoard: () => set((s) => ({ showStratBoard: !s.showStratBoard })),

  setMiniHudActive: (active) => set({ miniHudActive: active }),

  toggleMiniHud: () => set((s) => ({ miniHudActive: !s.miniHudActive })),

  setProAnalyticsEnabled: (enabled) => set({ proAnalyticsEnabled: enabled }),

  setRogerBeepEnabled: (enabled) => set({ rogerBeepEnabled: enabled }),

  setRogerBeepStyle: (style) => set({ rogerBeepStyle: style }),

  setRogerBeepVolume: (volume) => set({ rogerBeepVolume: Math.max(0, Math.min(1, volume)) }),

  setInGameOverlayEnabled: (enabled) => set({ inGameOverlayEnabled: enabled }),

  setInGameOverlayPosition: (pos) => set({ inGameOverlayPosition: pos }),

  setInGameOverlayMode: (mode) => set({ inGameOverlayMode: mode }),

  setInGameOverlayOpacity: (opacity) =>
    set({ inGameOverlayOpacity: Math.max(0.2, Math.min(1, opacity)) }),

  setInGameOverlayAutoFade: (autoFade) => set({ inGameOverlayAutoFade: autoFade }),

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
        rogerBeepEnabled: partial.rogerBeepEnabled ?? s.rogerBeepEnabled,
        rogerBeepStyle: partial.rogerBeepStyle ?? s.rogerBeepStyle,
        rogerBeepVolume: partial.rogerBeepVolume ?? s.rogerBeepVolume,
        inGameOverlayEnabled:
          partial.inGameOverlayEnabled ?? s.inGameOverlayEnabled,
        inGameOverlayPosition:
          partial.inGameOverlayPosition ?? s.inGameOverlayPosition,
        inGameOverlayMode: partial.inGameOverlayMode ?? s.inGameOverlayMode,
        inGameOverlayOpacity:
          partial.inGameOverlayOpacity ?? s.inGameOverlayOpacity,
        inGameOverlayAutoFade:
          partial.inGameOverlayAutoFade ?? s.inGameOverlayAutoFade,
      };
    }),
}));
