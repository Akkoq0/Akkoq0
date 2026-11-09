'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Comprehensive Executive Command Settings Modal
// ─────────────────────────────────────────────────────────
// Triggered via the bottom-left settings gear icon in TacticalSidebar.
// Provides real Audio I/O device selection, Live Microphone dBFS Meter
// & Loopback Test, Noise Gate DSP controls, Custom Keybind Recorder,
// Theme Engine (*Deep Espresso & Burgundy*, *Tactical Stealth Carbon*,
// *Obsidian Gold*), and Meva Pro Post-Match Acoustic Analytics.

import { memo, useCallback, useEffect, useState } from 'react';
import {
  useVoiceSettingsStore,
  type KeybindMap,
} from '@/store/useVoiceSettingsStore';
import { useHUDStore } from '@/store/useHUDStore';
import {
  useThemeStore,
  THEME_PRESETS,
  type ThemePreset,
} from '@/store/useThemeStore';
import {
  getMevaVadEngine,
  type VadTelemetrySnapshot,
} from '@/src/lib/vadEngine';
import { getMevaTelemetryEngine } from '@/src/lib/telemetryEngine';
import {
  getMevaStorageEngine,
  type ProAnalyticsReport,
} from '@/src/lib/storageEngine';
import {
  getMevaAudioEngine,
  type RogerBeepStyle,
} from '@/src/lib/audioEngine';
import {
  IconClose,
  IconMic,
  IconHeadphones,
  IconSliders,
  IconShield,
  IconBolt,
  IconVoiceWave,
} from '@/components/ui/MevaIcons';

type SettingsTab = 'audio' | 'gate' | 'overlay' | 'keybinds' | 'theme_pro';

const KEYBIND_LABELS: ReadonlyArray<{
  key: keyof KeybindMap;
  title: string;
  desc: string;
}> = [
  {
    key: 'pttKey',
    title: 'Bas-Konuş (Push-to-Talk)',
    desc: 'Basılı tutulduğunda Noise Gate kapısını açar ve akustik bip üretir',
  },
  {
    key: 'muteKey',
    title: 'Mikrofon Sustur / Aç',
    desc: 'Anında yerel mikrofon akışını susturur',
  },
  {
    key: 'deafenKey',
    title: 'Kulaklık Sağırlaştır',
    desc: 'Tüm gelen ve giden ses kanallarını geçici olarak kapatır',
  },
  {
    key: 'stratBoardKey',
    title: 'Taktik Tahtası (Strat Canvas)',
    desc: 'Canlı P2P senkronize harita ve çizim çekmecesini açar',
  },
  {
    key: 'miniHudKey',
    title: 'Kompakt Overlay Modu (Mini HUD)',
    desc: 'İkinci ekran için ultra-minimalist oyun içi komuta şeridine geçer',
  },
];

function formatKeyCode(code: string): string {
  if (code.startsWith('Key')) return code.slice(3);
  if (code.startsWith('Digit')) return code.slice(5);
  if (code === 'Space') return 'SPACE';
  return code.toUpperCase();
}

export const MevaCommandSettingsModal = memo(function MevaCommandSettingsModal() {
  const open = useVoiceSettingsStore((s) => s.showCommandSettingsModal);
  const setOpen = useVoiceSettingsStore((s) => s.setShowCommandSettingsModal);

  const inputMode = useVoiceSettingsStore((s) => s.inputMode);
  const noiseGate = useVoiceSettingsStore((s) => s.noiseGate);
  const keybinds = useVoiceSettingsStore((s) => s.keybinds);
  const inputDeviceId = useVoiceSettingsStore((s) => s.inputDeviceId);
  const outputDeviceId = useVoiceSettingsStore((s) => s.outputDeviceId);
  const proAnalyticsEnabled = useVoiceSettingsStore(
    (s) => s.proAnalyticsEnabled,
  );
  const rogerBeepEnabled = useVoiceSettingsStore((s) => s.rogerBeepEnabled);
  const rogerBeepStyle = useVoiceSettingsStore((s) => s.rogerBeepStyle);
  const rogerBeepVolume = useVoiceSettingsStore((s) => s.rogerBeepVolume);
  const inGameOverlayEnabled = useVoiceSettingsStore((s) => s.inGameOverlayEnabled);
  const inGameOverlayPosition = useVoiceSettingsStore((s) => s.inGameOverlayPosition);
  const inGameOverlayMode = useVoiceSettingsStore((s) => s.inGameOverlayMode);
  const inGameOverlayOpacity = useVoiceSettingsStore((s) => s.inGameOverlayOpacity);
  const inGameOverlayAutoFade = useVoiceSettingsStore((s) => s.inGameOverlayAutoFade);
  const setRogerBeepEnabled = useVoiceSettingsStore((s) => s.setRogerBeepEnabled);
  const setRogerBeepStyle = useVoiceSettingsStore((s) => s.setRogerBeepStyle);
  const setRogerBeepVolume = useVoiceSettingsStore((s) => s.setRogerBeepVolume);
  const setInGameOverlayEnabled = useVoiceSettingsStore((s) => s.setInGameOverlayEnabled);
  const setInGameOverlayPosition = useVoiceSettingsStore((s) => s.setInGameOverlayPosition);
  const setInGameOverlayMode = useVoiceSettingsStore((s) => s.setInGameOverlayMode);
  const setInGameOverlayOpacity = useVoiceSettingsStore((s) => s.setInGameOverlayOpacity);
  const setInGameOverlayAutoFade = useVoiceSettingsStore((s) => s.setInGameOverlayAutoFade);

  const setInputMode = useVoiceSettingsStore((s) => s.setInputMode);
  const updateNoiseGate = useVoiceSettingsStore((s) => s.updateNoiseGate);
  const setKeybind = useVoiceSettingsStore((s) => s.setKeybind);
  const setInputDeviceId = useVoiceSettingsStore((s) => s.setInputDeviceId);
  const setOutputDeviceId = useVoiceSettingsStore((s) => s.setOutputDeviceId);
  const setProAnalyticsEnabled = useVoiceSettingsStore(
    (s) => s.setProAnalyticsEnabled,
  );

  const iglDuckingEnabled = useHUDStore((s) => s.iglDuckingEnabled);
  const autoLevelerEnabled = useHUDStore((s) => s.autoLevelerEnabled);
  const acousticCuesEnabled = useHUDStore((s) => s.acousticCuesEnabled);
  const setIglDuckingEnabled = useHUDStore((s) => s.setIglDuckingEnabled);
  const setAutoLevelerEnabled = useHUDStore((s) => s.setAutoLevelerEnabled);
  const setAcousticCuesEnabled = useHUDStore((s) => s.setAcousticCuesEnabled);

  const currentTheme = useThemeStore((s) => s.currentTheme);
  const glassOpacity = useThemeStore((s) => s.glassOpacity);
  const blurIntensity = useThemeStore((s) => s.blurIntensity);
  const setTheme = useThemeStore((s) => s.setTheme);
  const setGlassOpacity = useThemeStore((s) => s.setGlassOpacity);
  const setBlurIntensity = useThemeStore((s) => s.setBlurIntensity);

  const [tab, setTab] = useState<SettingsTab>('audio');
  const [inputs, setInputs] = useState<MediaDeviceInfo[]>([]);
  const [outputs, setOutputs] = useState<MediaDeviceInfo[]>([]);
  const [vadSnap, setVadSnap] = useState<VadTelemetrySnapshot>(() =>
    getMevaVadEngine().getSnapshot(),
  );
  const [proReport, setProReport] = useState<ProAnalyticsReport>(() =>
    getMevaStorageEngine().getProReport(),
  );
  const [loopbackActive, setLoopbackActive] = useState(false);
  const [micTesting, setMicTesting] = useState(false);
  const [recordingKeyFor, setRecordingKeyFor] = useState<
    keyof KeybindMap | null
  >(null);

  const refreshDevices = useCallback(async () => {
    const res = await getMevaVadEngine().enumerateAudioDevices();
    setInputs(res.inputs);
    setOutputs(res.outputs);
  }, []);

  useEffect(() => {
    if (!open) {
      getMevaVadEngine().setMicLoopbackTest(false);
      setLoopbackActive(false);
      setRecordingKeyFor(null);
      return;
    }
    void refreshDevices();
    const unsub = getMevaVadEngine().subscribe((snap) => setVadSnap(snap));
    const unsubPro = getMevaStorageEngine().subscribeProReport((rep) =>
      setProReport(rep),
    );
    return () => {
      unsub();
      unsubPro();
      getMevaVadEngine().setMicLoopbackTest(false);
    };
  }, [open, refreshDevices]);

  // Interactive keybind capture
  useEffect(() => {
    if (!open || !recordingKeyFor) return;
    const onKeyDown = (e: KeyboardEvent) => {
      e.preventDefault();
      e.stopPropagation();
      if (e.code === 'Escape') {
        setRecordingKeyFor(null);
        return;
      }
      setKeybind(recordingKeyFor, e.code);
      setRecordingKeyFor(null);
    };
    window.addEventListener('keydown', onKeyDown, true);
    return () => window.removeEventListener('keydown', onKeyDown, true);
  }, [open, recordingKeyFor, setKeybind]);

  if (!open) return null;

  const handleStartMicProbe = async () => {
    setMicTesting(true);
    await getMevaVadEngine().acquireMicrophoneStream(
      inputDeviceId !== 'default' ? inputDeviceId : undefined,
    );
    await refreshDevices();
    setMicTesting(false);
  };

  const handleToggleLoopback = async () => {
    if (!loopbackActive) {
      await getMevaVadEngine().acquireMicrophoneStream(
        inputDeviceId !== 'default' ? inputDeviceId : undefined,
      );
      getMevaVadEngine().setMicLoopbackTest(true);
      setLoopbackActive(true);
    } else {
      getMevaVadEngine().setMicLoopbackTest(false);
      setLoopbackActive(false);
    }
  };

  const handleSelectInput = async (id: string) => {
    setInputDeviceId(id);
    await getMevaVadEngine().acquireMicrophoneStream(
      id !== 'default' ? id : undefined,
    );
  };

  const meterPercent = Math.max(
    0,
    Math.min(100, ((vadSnap.inputDb + 80) / 80) * 100),
  );
  const thresholdPercent = Math.max(
    0,
    Math.min(100, ((noiseGate.thresholdDb + 80) / 80) * 100),
  );
  const telemetry = getMevaTelemetryEngine().getSummary();

  const orderedThemes: ThemePreset[] = [
    'ghost-cyberpunk',
    'oled-stealth',
    'velvet-copper',
    'ares-crimson',
  ];

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center exec-backdrop p-3 sm:p-5 font-sans tabular-nums"
      onClick={() => setOpen(false)}
    >
      <div
        onClick={(e) => e.stopPropagation()}
        className="w-full max-w-2xl max-h-[90dvh] rounded-2xl exec-modal flex flex-col overflow-hidden"
      >
        {/* Modal Header */}
        <div className="px-5 py-4 border-b border-[#2A1319] flex items-center justify-between gap-3 flex-shrink-0">
          <div className="flex items-center gap-2.5">
            <div className="w-9 h-9 rounded-xl crimson-cta flex items-center justify-center text-[#F4EFF0]">
              <IconSliders size={17} />
            </div>
            <div>
              <h2 className="text-[15px] font-extrabold text-[#F4EFF0]">
                Meva Komuta & DSP Ayarları
              </h2>
              <p className="text-[11px] text-[#8E7F83]">
                48kHz WebAudio Zinciri · Spektral Noise Gate · Kısayollar · Tema
              </p>
            </div>
          </div>
          <button
            type="button"
            onClick={() => setOpen(false)}
            aria-label="Kapat"
            className="rounded-xl w-8 h-8 flex items-center justify-center bg-[#140A0D] hover:bg-[#220D13] border border-[#2C141A] text-[#9E8E91] hover:text-[#F4EFF0]"
          >
            <IconClose size={15} />
          </button>
        </div>

        {/* Navigation Tabs */}
        <div className="px-5 pt-3 pb-2 border-b border-[#221015] flex items-center gap-1.5 overflow-x-auto no-scrollbar flex-shrink-0">
          {(
            [
              { id: 'audio', label: 'Ses & Cihazlar' },
              { id: 'gate', label: 'Noise Gate & VAD' },
              { id: 'overlay', label: 'Oyun İçi Overlay' },
              { id: 'keybinds', label: 'Kısayol Atayıcı' },
              { id: 'theme_pro', label: 'Tema & Meva Pro' },
            ] as const
          ).map((t) => (
            <button
              key={t.id}
              type="button"
              onClick={() => setTab(t.id)}
              className={`rounded-xl h-9 px-3.5 text-[11.5px] font-bold border whitespace-nowrap active:scale-95 transition-all ${
                tab === t.id
                  ? 'crimson-cta text-[#F4EFF0]'
                  : 'bg-[#120A0D] hover:bg-[#1B0C11] text-[#B8AAAC] hover:text-[#F4EFF0] border-[#2A1319]'
              }`}
            >
              {t.label}
            </button>
          ))}
        </div>

        {/* Tab Body */}
        <div className="flex-1 min-h-0 overflow-y-auto p-5 space-y-4">
          {/* ── TAB 1: AUDIO & LIVE MIC METER ── */}
          {tab === 'audio' && (
            <>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <label className="block space-y-1.5">
                  <span className="flex items-center gap-1.5 text-[11px] font-bold text-[#B8AAAC]">
                    <IconMic size={13} className="text-[#E35D6A]" />
                    <span>Giriş Cihazı (Mikrofon)</span>
                  </span>
                  <select
                    value={inputDeviceId}
                    onChange={(e) => void handleSelectInput(e.target.value)}
                    className="rounded-xl w-full h-10 px-3 bg-[#11090C] border border-[#2C141A] focus:border-[#C82333] text-xs font-semibold text-[#F4EFF0] outline-none"
                  >
                    {(inputs.length > 0
                      ? inputs.map((d, idx) => ({
                          deviceId: d.deviceId || `in-${idx}`,
                          label: d.label || `Mikrofon #${idx + 1}`,
                        }))
                      : [
                          {
                            deviceId: 'default',
                            label: 'Varsayılan Stüdyo Mikrofonu',
                          },
                        ]
                    ).map((d) => (
                      <option key={d.deviceId} value={d.deviceId}>
                        {d.label}
                      </option>
                    ))}
                  </select>
                </label>

                <label className="block space-y-1.5">
                  <span className="flex items-center gap-1.5 text-[11px] font-bold text-[#B8AAAC]">
                    <IconHeadphones size={13} className="text-[#E35D6A]" />
                    <span>Çıkış Cihazı (Kulaklık / Hoparlör)</span>
                  </span>
                  <select
                    value={outputDeviceId}
                    onChange={(e) => setOutputDeviceId(e.target.value)}
                    className="rounded-xl w-full h-10 px-3 bg-[#11090C] border border-[#2C141A] focus:border-[#C82333] text-xs font-semibold text-[#F4EFF0] outline-none"
                  >
                    {(outputs.length > 0
                      ? outputs.map((d, idx) => ({
                          deviceId: d.deviceId || `out-${idx}`,
                          label: d.label || `Hoparlör / Kulaklık #${idx + 1}`,
                        }))
                      : [
                          {
                            deviceId: 'default',
                            label: 'Varsayılan Espor Kulaklığı',
                          },
                        ]
                    ).map((d) => (
                      <option key={d.deviceId} value={d.deviceId}>
                        {d.label}
                      </option>
                    ))}
                  </select>
                </label>
              </div>

              {/* Live Microphone Test Bar */}
              <div className="rounded-xl p-4 bg-[#10080B] border border-[#2C141A] space-y-3">
                <div className="flex items-center justify-between gap-2 flex-wrap">
                  <div>
                    <span className="block text-xs font-extrabold text-[#F4EFF0]">
                      Canlı Mikrofon Sinyal & Eşik Testi
                    </span>
                    <span className="block text-[11px] text-[#8E7F83]">
                      Giriş: {vadSnap.inputDb} dBFS · Eşik:{' '}
                      {noiseGate.thresholdDb} dBFS · Vokal Oranı: %
                      {Math.round(vadSnap.vocalRatio * 100)}
                    </span>
                  </div>
                  <div className="flex items-center gap-1.5">
                    <button
                      type="button"
                      onClick={() => void handleStartMicProbe()}
                      className="rounded-lg h-8 px-3 bg-[#180B10] hover:bg-[#240E15] border border-[#7A121D]/50 text-[11px] font-bold text-[#F08C96]"
                    >
                      {micTesting ? 'Bağlanıyor...' : 'Mikrofonu Etkinleştir'}
                    </button>
                    <button
                      type="button"
                      onClick={() => void handleToggleLoopback()}
                      className={`rounded-lg h-8 px-3 text-[11px] font-bold border transition-all ${
                        loopbackActive
                          ? 'crimson-cta text-[#F4EFF0]'
                          : 'bg-[#140A0D] hover:bg-[#1E0C12] text-[#B8AAAC] border-[#2C141A]'
                      }`}
                    >
                      {loopbackActive ? 'Dinleme Açık' : 'Sesimi Dinle'}
                    </button>
                  </div>
                </div>

                {/* Real-time dBFS bar with Threshold Marker */}
                <div className="relative h-4 rounded-full bg-[#080506] border border-[#261217] overflow-hidden">
                  <div
                    style={{ width: `${meterPercent}%` }}
                    className={`h-full transition-[width] duration-75 ${
                      vadSnap.gateOpen
                        ? 'bg-gradient-to-r from-[#7A121D] via-[#C82333] to-[#F08C96]'
                        : 'bg-[#4D141C]'
                    }`}
                  />
                  <div
                    style={{ left: `${thresholdPercent}%` }}
                    title={`Noise Gate Eşiği: ${noiseGate.thresholdDb} dB`}
                    className="absolute top-0 bottom-0 w-0.5 bg-[#F4EFF0] shadow-[0_0_6px_#F4EFF0]"
                  />
                </div>

                <div className="flex items-center justify-between text-[10.5px] text-[#8E7F83]">
                  <span>-80 dBFS (Sessizlik)</span>
                  <span
                    className={`font-bold ${
                      vadSnap.gateOpen ? 'text-[#F08C96]' : 'text-[#8E7F83]'
                    }`}
                  >
                    {vadSnap.gateOpen
                      ? 'KAPAK AÇIK · İLETİLİYOR'
                      : 'NOISE GATE KAPALI'}
                  </span>
                  <span>0 dBFS (Peak Limiter)</span>
                </div>
              </div>

              {/* Studio DSP Processing Switches */}
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-2.5">
                <ToggleCard
                  title="Auto-Leveler / Limiter"
                  desc="Ani bağırmaları (Rage/Peak) DynamicsCompressor ile dengeler"
                  enabled={autoLevelerEnabled}
                  onToggle={() => setAutoLevelerEnabled(!autoLevelerEnabled)}
                />
                <ToggleCard
                  title="IGL Priority Ducking"
                  desc="Takım kaptanı konuşurken diğer sesleri %30 kısar"
                  enabled={iglDuckingEnabled}
                  onToggle={() => setIglDuckingEnabled(!iglDuckingEnabled)}
                />
                <ToggleCard
                  title="Akustik Sentez Sesleri"
                  desc="PTT ve hızlı Callout'larda zarif WebAudio mikro-bip"
                  enabled={acousticCuesEnabled}
                  onToggle={() => setAcousticCuesEnabled(!acousticCuesEnabled)}
                />
                <div className="rounded-xl p-3 bg-[#11090C] border border-[#2A1319] space-y-3">
                  <div className="flex items-center justify-between gap-3">
                    <div className="flex-1 pr-2">
                      <div className="flex items-center gap-2">
                        <span className="block text-xs font-extrabold text-[#F4EFF0]">
                          Mil-Sim Roger Beep (Taktik Bip)
                        </span>
                        <span className="text-[10px] px-1.5 py-0.5 rounded bg-[#2D1217] text-[#F08C96] font-mono font-bold">
                          %0 CPU
                        </span>
                      </div>
                      <span className="block text-[11px] text-[#8E7F83] mt-0.5">
                        Bas-konuş bırakıldığında donanım sentezli taktik telsiz kapanış sesi çalar.
                      </span>
                    </div>
                    <button
                      type="button"
                      role="switch"
                      aria-checked={rogerBeepEnabled}
                      onClick={() => setRogerBeepEnabled(!rogerBeepEnabled)}
                      className={`relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none ${
                        rogerBeepEnabled ? 'bg-[#C82333]' : 'bg-[#2A1319]'
                      }`}
                    >
                      <span
                        className={`pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out ${
                          rogerBeepEnabled ? 'translate-x-5' : 'translate-x-0'
                        }`}
                      />
                    </button>
                  </div>

                  {rogerBeepEnabled && (
                    <div className="pt-2 border-t border-[#1F0D12] space-y-2.5">
                      <div className="flex items-center justify-between gap-2">
                        <span className="text-[11px] font-bold text-[#B8AAAC]">
                          Bip Karakteri & Telsiz Tonu:
                        </span>
                        <button
                          type="button"
                          onClick={() =>
                            getMevaAudioEngine().previewRogerBeep(
                              rogerBeepStyle,
                              rogerBeepVolume,
                            )
                          }
                          className="px-2.5 py-1 rounded-lg bg-[#220D13] hover:bg-[#34121B] border border-[#7A121D]/60 text-[11px] font-bold text-[#F08C96] flex items-center gap-1.5 transition-colors"
                        >
                          <IconVoiceWave size={13} />
                          <span>Sesi Dinle</span>
                        </button>
                      </div>

                      <div className="grid grid-cols-2 sm:grid-cols-4 gap-1.5">
                        {[
                          {
                            id: 'classic-milsim' as const,
                            label: 'Askeri (Mil-Sim)',
                            desc: '1.0 kHz Klasik',
                          },
                          {
                            id: 'swat-squawk' as const,
                            label: 'SWAT Çift Ton',
                            desc: 'Polis Telsizi',
                          },
                          {
                            id: 'quindar-nasa' as const,
                            label: 'NASA Apollo',
                            desc: '2.47 kHz Quindar',
                          },
                          {
                            id: 'subtle-esports' as const,
                            label: 'Espor Soft',
                            desc: '1.8 kHz Mikro',
                          },
                        ].map((styleOption) => (
                          <button
                            key={styleOption.id}
                            type="button"
                            onClick={() => {
                              setRogerBeepStyle(styleOption.id);
                              getMevaAudioEngine().previewRogerBeep(
                                styleOption.id,
                                rogerBeepVolume,
                              );
                            }}
                            className={`p-2 rounded-lg text-left border transition-all ${
                              rogerBeepStyle === styleOption.id
                                ? 'bg-[#3A1017] border-[#C82333] text-[#F4EFF0] shadow-[0_0_8px_rgba(200,35,51,0.25)]'
                                : 'bg-[#150A0E] border-[#251016] text-[#8E7F83] hover:text-[#B8AAAC] hover:border-[#38151D]'
                            }`}
                          >
                            <span className="block text-[11px] font-bold">
                              {styleOption.label}
                            </span>
                            <span className="block text-[9.5px] opacity-70">
                              {styleOption.desc}
                            </span>
                          </button>
                        ))}
                      </div>

                      <div className="flex items-center justify-between gap-3 pt-1">
                        <span className="text-[11px] text-[#8E7F83]">
                          Bip Seviyesi: %{Math.round(rogerBeepVolume * 100)}
                        </span>
                        <input
                          type="range"
                          min={0.1}
                          max={1}
                          step={0.05}
                          value={rogerBeepVolume}
                          onChange={(e) =>
                            setRogerBeepVolume(parseFloat(e.target.value))
                          }
                          className="w-36 accent-[#C82333] cursor-pointer"
                        />
                      </div>
                    </div>
                  )}
                </div>
              </div>
            </>
          )}

          {/* ── TAB 2: NOISE GATE & VAD/PTT ── */}
          {tab === 'gate' && (
            <>
              <div className="grid grid-cols-2 gap-2.5">
                <button
                  type="button"
                  onClick={() => setInputMode('vad')}
                  className={`rounded-xl p-3.5 text-left border transition-all ${
                    inputMode === 'vad'
                      ? 'bg-[linear-gradient(160deg,rgba(138,20,32,0.28)_0%,rgba(14,9,11,0.9)_100%)] border-[#C82333]/60'
                      : 'bg-[#11090C] border-[#2A1319]'
                  }`}
                >
                  <span className="block text-xs font-extrabold text-[#F4EFF0]">
                    VAD · Ses Aktivasyonu
                  </span>
                  <span className="block text-[11px] text-[#8E7F83] mt-0.5">
                    Vokal eşiği aşıldığında kapıyı otomatik açar
                  </span>
                </button>
                <button
                  type="button"
                  onClick={() => setInputMode('ptt')}
                  className={`rounded-xl p-3.5 text-left border transition-all ${
                    inputMode === 'ptt'
                      ? 'bg-[linear-gradient(160deg,rgba(138,20,32,0.28)_0%,rgba(14,9,11,0.9)_100%)] border-[#C82333]/60'
                      : 'bg-[#11090C] border-[#2A1319]'
                  }`}
                >
                  <span className="block text-xs font-extrabold text-[#F4EFF0]">
                    PTT · Bas-Konuş ({formatKeyCode(keybinds.pttKey)})
                  </span>
                  <span className="block text-[11px] text-[#8E7F83] mt-0.5">
                    Sadece tuş basılıyken mikrofonu iletir + mikro-bip
                  </span>
                </button>
              </div>

              <div className="rounded-xl p-4 bg-[#10080B] border border-[#2C141A] space-y-3.5">
                <SliderRow
                  label="Noise Gate Eşiği (Threshold)"
                  valueLabel={`${noiseGate.thresholdDb} dB`}
                  min={-70}
                  max={-15}
                  step={1}
                  value={noiseGate.thresholdDb}
                  onChange={(v) => updateNoiseGate({ thresholdDb: v })}
                />
                <SliderRow
                  label="Açılma Hızı (Attack)"
                  valueLabel={`${noiseGate.attackMs} ms`}
                  min={2}
                  max={50}
                  step={1}
                  value={noiseGate.attackMs}
                  onChange={(v) => updateNoiseGate({ attackMs: v })}
                />
                <SliderRow
                  label="Tutma Süresi (Hold)"
                  valueLabel={`${noiseGate.holdMs} ms`}
                  min={40}
                  max={500}
                  step={5}
                  value={noiseGate.holdMs}
                  onChange={(v) => updateNoiseGate({ holdMs: v })}
                />
                <SliderRow
                  label="Bırakma Süresi (Release)"
                  valueLabel={`${noiseGate.releaseMs} ms`}
                  min={30}
                  max={500}
                  step={5}
                  value={noiseGate.releaseMs}
                  onChange={(v) => updateNoiseGate({ releaseMs: v })}
                />
              </div>

              <ToggleCard
                title="Mekanik Klavye (Switch) & Fan Spektral Filtresi"
                desc="300Hz–3.4kHz vokal enerjisini 4kHz–10kHz switch klikleriyle oranlayarak klavye seslerini keser"
                enabled={noiseGate.keyboardClickFilter}
                onToggle={() =>
                  updateNoiseGate({
                    keyboardClickFilter: !noiseGate.keyboardClickFilter,
                  })
                }
              />
            </>
          )}

          {/* ── TAB: IN-GAME TACTICAL VOICE OVERLAY ── */}
          {tab === 'overlay' && (
            <div className="space-y-4">
              {/* Master Toggle */}
              <div className="rounded-xl p-3.5 bg-[#10080B] border border-[#2C141A] flex items-center justify-between gap-3">
                <div className="flex-1 pr-2">
                  <div className="flex items-center gap-2">
                    <span className="block text-xs font-extrabold text-[#F4EFF0]">
                      Oyun İçi Sesli İletişim Overlay&apos;i
                    </span>
                    <span className="text-[10px] px-1.5 py-0.5 rounded bg-[#2D1217] text-[#F08C96] font-mono font-bold">
                      Discord Alternatifi
                    </span>
                  </div>
                  <span className="block text-[11px] text-[#8E7F83] mt-0.5">
                    Oyun oynarken veya sekme arka plandayken ekranda kimin konuştuğunu, rollerini ve pingini gösterir (%0 DLL hooking, ban riski yok).
                  </span>
                </div>
                <button
                  type="button"
                  role="switch"
                  aria-checked={inGameOverlayEnabled}
                  onClick={() => setInGameOverlayEnabled(!inGameOverlayEnabled)}
                  className={`relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none ${
                    inGameOverlayEnabled ? 'bg-[#C82333]' : 'bg-[#2A1319]'
                  }`}
                >
                  <span
                    className={`pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out ${
                      inGameOverlayEnabled ? 'translate-x-5' : 'translate-x-0'
                    }`}
                  />
                </button>
              </div>

              {inGameOverlayEnabled && (
                <>
                  {/* Screen Position Picker */}
                  <div className="rounded-xl p-3.5 bg-[#10080B] border border-[#2C141A] space-y-2.5">
                    <span className="block text-xs font-extrabold text-[#F4EFF0]">
                      Ekran Konumu
                    </span>
                    <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
                      {[
                        { id: 'top-left' as const, label: 'Sol Üst', desc: 'Radar Yanı' },
                        { id: 'top-right' as const, label: 'Sağ Üst', desc: 'Killfeed Üstü' },
                        { id: 'bottom-left' as const, label: 'Sol Alt', desc: 'Can / Zırh Yanı' },
                        { id: 'bottom-right' as const, label: 'Sağ Alt', desc: 'Mühimmat Yanı' },
                      ].map((pos) => (
                        <button
                          key={pos.id}
                          type="button"
                          onClick={() => setInGameOverlayPosition(pos.id)}
                          className={`p-2.5 rounded-lg text-left border transition-all ${
                            inGameOverlayPosition === pos.id
                              ? 'bg-[#3A1017] border-[#C82333] text-[#F4EFF0] shadow-[0_0_8px_rgba(200,35,51,0.25)]'
                              : 'bg-[#150A0E] border-[#251016] text-[#8E7F83] hover:text-[#B8AAAC] hover:border-[#38151D]'
                          }`}
                        >
                          <span className="block text-xs font-bold">{pos.label}</span>
                          <span className="block text-[9.5px] opacity-70">{pos.desc}</span>
                        </button>
                      ))}
                    </div>
                  </div>

                  {/* Display Mode */}
                  <div className="rounded-xl p-3.5 bg-[#10080B] border border-[#2C141A] space-y-2.5">
                    <span className="block text-xs font-extrabold text-[#F4EFF0]">
                      Görünüm Karakteri
                    </span>
                    <div className="grid grid-cols-1 sm:grid-cols-3 gap-2">
                      {[
                        {
                          id: 'compact' as const,
                          label: 'Standart Kompakt',
                          desc: 'Tüm oda üyeleri, ses barları & roller',
                        },
                        {
                          id: 'stealth' as const,
                          label: 'Akıllı Gizli (Stealth)',
                          desc: 'Yalnızca konuşulduğunda ekrana gelir',
                        },
                        {
                          id: 'tactical-full' as const,
                          label: 'Espor Cockpit',
                          desc: 'Canlı ping, ducking ve hızlı taktik butonları',
                        },
                      ].map((m) => (
                        <button
                          key={m.id}
                          type="button"
                          onClick={() => setInGameOverlayMode(m.id)}
                          className={`p-2.5 rounded-lg text-left border transition-all ${
                            inGameOverlayMode === m.id
                              ? 'bg-[#3A1017] border-[#C82333] text-[#F4EFF0] shadow-[0_0_8px_rgba(200,35,51,0.25)]'
                              : 'bg-[#150A0E] border-[#251016] text-[#8E7F83] hover:text-[#B8AAAC] hover:border-[#38151D]'
                          }`}
                        >
                          <span className="block text-xs font-bold">{m.label}</span>
                          <span className="block text-[9.5px] opacity-70 mt-0.5">{m.desc}</span>
                        </button>
                      ))}
                    </div>
                  </div>

                  {/* Stealth Auto-Fade & Opacity */}
                  <div className="rounded-xl p-3.5 bg-[#10080B] border border-[#2C141A] space-y-3">
                    <ToggleCard
                      title="Akıllı Saydamlaşma (Stealth Auto-Fade)"
                      desc="Sessizlikte 2.5 saniye sonra %20 saydamlaşır; konuşma başladığında anında parlar (crosshair'ı engellemez)"
                      enabled={inGameOverlayAutoFade}
                      onToggle={() => setInGameOverlayAutoFade(!inGameOverlayAutoFade)}
                    />

                    <SliderRow
                      label="Maksimum Overlay Opaklığı"
                      valueLabel={`%${Math.round(inGameOverlayOpacity * 100)}`}
                      min={0.3}
                      max={1.0}
                      step={0.05}
                      value={inGameOverlayOpacity}
                      onChange={(v) => setInGameOverlayOpacity(v)}
                    />
                  </div>
                </>
              )}
            </div>
          )}

          {/* ── TAB 3: KEYBIND RECORDER ── */}
          {tab === 'keybinds' && (
            <div className="space-y-2.5">
              {KEYBIND_LABELS.map((item) => {
                const isRecording = recordingKeyFor === item.key;
                return (
                  <div
                    key={item.key}
                    className="rounded-xl px-4 py-3 bg-[#10080B] border border-[#2C141A] flex items-center justify-between gap-3"
                  >
                    <div>
                      <span className="block text-xs font-extrabold text-[#F4EFF0]">
                        {item.title}
                      </span>
                      <span className="block text-[11px] text-[#8E7F83] mt-0.5">
                        {item.desc}
                      </span>
                    </div>
                    <button
                      type="button"
                      onClick={() =>
                        setRecordingKeyFor(isRecording ? null : item.key)
                      }
                      className={`rounded-xl h-9 min-w-[104px] px-3 text-xs font-mono font-extrabold border transition-all ${
                        isRecording
                          ? 'crimson-cta text-[#F4EFF0] animate-pulse'
                          : 'bg-[#180B10] hover:bg-[#230D14] text-[#F08C96] border-[#7A121D]/50'
                      }`}
                    >
                      {isRecording
                        ? 'Tuşa Basın...'
                        : formatKeyCode(keybinds[item.key])}
                    </button>
                  </div>
                );
              })}
            </div>
          )}

          {/* ── TAB 4: THEME ENGINE & MEVA PRO ANALYTICS ── */}
          {tab === 'theme_pro' && (
            <>
              <div className="space-y-2">
                <span className="block text-xs font-extrabold text-[#F4EFF0]">
                  Yönetici Tema Seçici
                </span>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
                  {orderedThemes.map((presetKey) => {
                    const preset = THEME_PRESETS[presetKey];
                    const active = currentTheme === presetKey;
                    return (
                      <button
                        key={presetKey}
                        type="button"
                        onClick={() => setTheme(presetKey)}
                        className={`rounded-xl p-3 text-left border transition-all ${
                          active
                            ? 'bg-[linear-gradient(160deg,rgba(138,20,32,0.26)_0%,rgba(14,9,11,0.92)_100%)] border-[#C82333]/65'
                            : 'bg-[#10080B] hover:bg-[#170B10] border-[#2A1319]'
                        }`}
                      >
                        <div className="flex items-center justify-between gap-2">
                          <span className="text-xs font-extrabold text-[#F4EFF0]">
                            {preset.name}
                          </span>
                          <span className="flex items-center gap-1">
                            <span
                              style={{ background: preset.bgDarkest }}
                              className="w-3.5 h-3.5 rounded-full border border-white/15"
                            />
                            <span
                              style={{ background: preset.bgMid }}
                              className="w-3.5 h-3.5 rounded-full border border-white/15"
                            />
                            <span
                              style={{ background: preset.accent }}
                              className="w-3.5 h-3.5 rounded-full border border-white/15"
                            />
                          </span>
                        </div>
                        <span className="block text-[10.5px] text-[#8E7F83] mt-1">
                          {preset.tagline}
                        </span>
                      </button>
                    );
                  })}
                </div>
              </div>

              <div className="rounded-xl p-4 bg-[#10080B] border border-[#2C141A] space-y-3">
                <SliderRow
                  label="Cam Panel Opaklığı"
                  valueLabel={`%${Math.round(glassOpacity * 100)}`}
                  min={0.5}
                  max={0.95}
                  step={0.01}
                  value={glassOpacity}
                  onChange={setGlassOpacity}
                />
                <SliderRow
                  label="Arka Plan Bulanıklık (Backdrop Blur)"
                  valueLabel={`${blurIntensity} px`}
                  min={0}
                  max={28}
                  step={1}
                  value={blurIntensity}
                  onChange={setBlurIntensity}
                />
              </div>

              {/* Meva Pro Post-Match Acoustic & Comms Analytics */}
              <div className="rounded-xl p-4 bg-[linear-gradient(145deg,rgba(128,18,30,0.20)_0%,rgba(11,8,10,0.92)_100%)] border border-[#881A26]/45 space-y-3">
                <div className="flex items-center justify-between gap-3">
                  <div className="flex items-center gap-2">
                    <IconShield size={16} className="text-[#E35D6A]" />
                    <div>
                      <span className="block text-xs font-extrabold text-[#F4EFF0]">
                        Meva Pro · Maç Sonu Akustik & İletişim Analitiği
                      </span>
                      <span className="block text-[11px] text-[#B8AAAC]">
                        IGL Callout yoğunluğu, konuşma netliği, Auto-Leveler ve
                        P2P kararlılık raporu
                      </span>
                    </div>
                  </div>
                  <button
                    type="button"
                    onClick={() => setProAnalyticsEnabled(!proAnalyticsEnabled)}
                    className={`rounded-xl h-8 px-3.5 text-[11px] font-extrabold border transition-all flex items-center gap-1.5 ${
                      proAnalyticsEnabled
                        ? 'crimson-cta text-[#F4EFF0]'
                        : 'bg-[#140A0D] text-[#B8AAAC] border-[#2E151C]'
                    }`}
                  >
                    <IconBolt size={12} />
                    <span>{proAnalyticsEnabled ? 'Pro Aktif' : 'Etkinleştir'}</span>
                  </button>
                </div>

                {proAnalyticsEnabled && (
                  <div className="space-y-3 pt-1">
                    <div className="grid grid-cols-3 gap-2">
                      <div className="rounded-lg p-2.5 bg-[#0C0709]/85 border border-[#2C141A]">
                        <span className="block text-[10px] text-[#8E7F83]">
                          İletişim Netlik Skoru
                        </span>
                        <span className="block text-sm font-extrabold text-[#F08C96] mt-0.5">
                          {proReport.clarityScore} / 100
                        </span>
                      </div>
                      <div className="rounded-lg p-2.5 bg-[#0C0709]/85 border border-[#2C141A]">
                        <span className="block text-[10px] text-[#8E7F83]">
                          Ortalama Mesh RTT
                        </span>
                        <span className="block text-sm font-extrabold text-[#F4EFF0] mt-0.5">
                          {proReport.avgRttMs || telemetry.rttMs} ms · %
                          {proReport.meshStabilityPercent}
                        </span>
                      </div>
                      <div className="rounded-lg p-2.5 bg-[#0C0709]/85 border border-[#2C141A]">
                        <span className="block text-[10px] text-[#8E7F83]">
                          Auto-Leveler Koruması
                        </span>
                        <span className="block text-sm font-extrabold text-[#F4EFF0] mt-0.5">
                          {proReport.peakLimiterSaves} Peak Engellendi
                        </span>
                      </div>
                    </div>

                    {/* Callout Density & Operator Talk Balance */}
                    <div className="rounded-lg p-3 bg-[#0C0709]/85 border border-[#2C141A] space-y-2">
                      <div className="flex items-center justify-between text-[10.5px]">
                        <span className="font-bold text-[#B8AAAC]">
                          Taktik Çağrı Yoğunluğu ({proReport.totalCallouts} /{' '}
                          {proReport.totalMessages} Mesaj)
                        </span>
                        <button
                          type="button"
                          onClick={() => getMevaStorageEngine().resetProReport()}
                          className="text-[10px] font-bold text-[#E35D6A] hover:underline"
                        >
                          Raporu Sıfırla
                        </button>
                      </div>
                      <div className="flex flex-wrap items-center gap-1.5">
                        {Object.entries(proReport.calloutBreakdown).map(
                          ([tag, count]) => (
                            <span
                              key={tag}
                              className="rounded-md px-2 py-0.5 bg-[#180B10] border border-[#7A121D]/45 text-[10px] font-bold text-[#F08C96]"
                            >
                              #{tag}: {count}
                            </span>
                          ),
                        )}
                      </div>
                      <p className="text-[11px] text-[#B8AAAC] leading-snug pt-0.5">
                        {proReport.iglInsight}
                      </p>
                    </div>
                  </div>
                )}
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  );
});

function ToggleCard({
  title,
  desc,
  enabled,
  onToggle,
}: {
  title: string;
  desc: string;
  enabled: boolean;
  onToggle: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onToggle}
      className={`rounded-xl p-3 text-left border transition-all flex flex-col justify-between gap-2 ${
        enabled
          ? 'bg-[linear-gradient(160deg,rgba(128,18,30,0.20)_0%,rgba(12,8,10,0.88)_100%)] border-[#881A26]/50'
          : 'bg-[#10080B] border-[#261217]'
      }`}
    >
      <div className="flex items-center justify-between gap-2 w-full">
        <span className="text-[11.5px] font-extrabold text-[#F4EFF0]">
          {title}
        </span>
        <span
          className={`rounded px-1.5 py-0.5 text-[9.5px] font-extrabold ${
            enabled
              ? 'bg-[#8F1622]/40 text-[#F08C96]'
              : 'bg-[#1A0D11] text-[#7D6E71]'
          }`}
        >
          {enabled ? 'AÇIK' : 'KAPALI'}
        </span>
      </div>
      <span className="text-[10.5px] text-[#8E7F83] leading-snug">{desc}</span>
    </button>
  );
}

function SliderRow({
  label,
  valueLabel,
  min,
  max,
  step,
  value,
  onChange,
}: {
  label: string;
  valueLabel: string;
  min: number;
  max: number;
  step: number;
  value: number;
  onChange: (val: number) => void;
}) {
  const pct = Math.round(((value - min) / (max - min)) * 100);
  return (
    <div className="space-y-1.5">
      <div className="flex items-center justify-between text-[11px]">
        <span className="font-bold text-[#B8AAAC]">{label}</span>
        <span className="font-extrabold text-[#F08C96]">{valueLabel}</span>
      </div>
      <input
        type="range"
        min={min}
        max={max}
        step={step}
        value={value}
        onChange={(e) => onChange(Number(e.target.value))}
        style={{ '--fill': `${pct}%` } as React.CSSProperties}
        className="exec-range w-full"
      />
    </div>
  );
}
