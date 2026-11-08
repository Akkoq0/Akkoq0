// ─────────────────────────────────────────────────────────
// Meva HUD — Professional 48kHz WebAudio DSP & 3D Spatial Engine
// ─────────────────────────────────────────────────────────
// Full per-operator AudioContext processing chain:
//   MediaStreamAudioSourceNode
//     -> High-Pass BiquadFilterNode (85Hz, Q=0.707 — anti-footstep/rumble)
//     -> Low-Shelf BiquadFilterNode (220Hz — operator EQ warmth contour)
//     -> Peaking BiquadFilterNode (3.5kHz, Q=1.15 — vocal presence boost)
//     -> DynamicsCompressorNode (Auto-Leveler / Rage Peak Limiter)
//     -> GainNode (0%–200% perceptual logarithmic curve + IGL 30% ducking)
//     -> StereoPannerNode (L: -1.0 | C: 0.0 | R: +1.0 spatial stage)
//     -> AnalyserNode (FFT 256 real-time dual-band harmonic extraction)
//     -> Master Gain -> Master Brickwall Limiter -> Destination (48kHz)

export type SpatialPanPosition = 'L' | 'C' | 'R';
export type OperatorEqProfile = 'crisp' | 'balanced' | 'warm';
export type CalloutCueType =
  | 'ready'
  | 'rotate'
  | 'eco'
  | 'drop'
  | 'force'
  | 'gg';

export const SPATIAL_PAN_VALUES: Record<SpatialPanPosition, number> = {
  L: -1.0,
  C: 0.0,
  R: 1.0,
};

export interface EqPresetConfig {
  label: string;
  highpassHz: number;
  lowShelfDb: number;
  presenceFreqHz: number;
  presenceGainDb: number;
  presenceQ: number;
}

export const EQ_PROFILE_CONFIGS: Record<OperatorEqProfile, EqPresetConfig> = {
  crisp: {
    label: 'Keskin Tiz',
    highpassHz: 105,
    lowShelfDb: -3.5,
    presenceFreqHz: 3650,
    presenceGainDb: 5.5,
    presenceQ: 1.2,
  },
  balanced: {
    label: 'Dengeli Vokal',
    highpassHz: 85,
    lowShelfDb: 0.0,
    presenceFreqHz: 3500,
    presenceGainDb: 3.4,
    presenceQ: 1.15,
  },
  warm: {
    label: 'Tok Bas',
    highpassHz: 72,
    lowShelfDb: 4.2,
    presenceFreqHz: 3200,
    presenceGainDb: 1.8,
    presenceQ: 1.0,
  },
};

export interface SpectrumSnapshot {
  /** Overall perceptual loudness 0..100 */
  rmsLevel: number;
  /** Primary vocal fundamental harmonic 0..1 (drives primary sine wave) */
  primaryHarmonic: number;
  /** Secondary upper-presence harmonic 0..1 (drives secondary sine wave) */
  secondaryHarmonic: number;
  /** Peak dBFS approximation (-96..0) */
  peakDb: number;
  /** Gain reduction from Auto-Leveler in dB (0..24) */
  limiterReductionDb: number;
}

interface PeerDspChain {
  peerId: string;
  stream: MediaStream;
  pullSink: HTMLAudioElement;
  source: MediaStreamAudioSourceNode | null;
  highpass: BiquadFilterNode | null;
  lowShelf: BiquadFilterNode | null;
  presenceBoost: BiquadFilterNode | null;
  autoLeveler: DynamicsCompressorNode | null;
  gainNode: GainNode | null;
  pannerNode: StereoPannerNode | null;
  analyser: AnalyserNode | null;
  fftBuffer: Uint8Array<ArrayBuffer> | null;
  timeBuffer: Uint8Array<ArrayBuffer> | null;
  gainPercent: number;
  muted: boolean;
  pan: SpatialPanPosition;
  eqProfile: OperatorEqProfile;
  duckMultiplier: number;
  fallbackMode: boolean;
}

interface SinkCapableAudioContext extends AudioContext {
  setSinkId?: (sinkId: string) => Promise<void>;
}

const SMOOTH_TAU_SEC = 0.022;
const DUCK_ATTACK_TAU_SEC = 0.018;
const DUCK_RELEASE_TAU_SEC = 0.095;
const IGL_DUCK_FACTOR = 0.7; // 30% volume reduction when priority speaker talks

/**
 * Converts UI slider 0%–200% into a smooth perceptual logarithmic linear amplitude.
 * - 0%   -> 0.00 (true digital silence)
 * - 50%  -> ~0.32 (-10 dB perceptual midpoint)
 * - 100% -> 1.00 (0 dB unity reference)
 * - 200% -> ~2.51 (+8 dB boost, protected by Auto-Leveler & Brickwall Limiter)
 */
export function percentToLogarithmicGain(gainPercent: number): number {
  if (!Number.isFinite(gainPercent) || gainPercent <= 0) return 0;
  const clamped = Math.max(0, Math.min(200, gainPercent));
  if (clamped <= 100) {
    const normalized = clamped / 100;
    return Math.pow(normalized, 1.65);
  }
  const boostRatio = (clamped - 100) / 100; // 0..1
  // +8dB max boost on logarithmic dB scale: 10^(8 * boostRatio / 20)
  return Math.pow(10, (8.0 * boostRatio) / 20);
}

const ZERO_SPECTRUM: SpectrumSnapshot = {
  rmsLevel: 0,
  primaryHarmonic: 0.06,
  secondaryHarmonic: 0.05,
  peakDb: -96,
  limiterReductionDb: 0,
};

export class MevaAudioEngine {
  private ctx: AudioContext | null = null;
  private masterGain: GainNode | null = null;
  private masterLimiter: DynamicsCompressorNode | null = null;
  private peers = new Map<string, PeerDspChain>();

  private micSource: MediaStreamAudioSourceNode | null = null;
  private micHighpass: BiquadFilterNode | null = null;
  private micPresence: BiquadFilterNode | null = null;
  private micCompressor: DynamicsCompressorNode | null = null;
  private micAnalyser: AnalyserNode | null = null;
  private micFftBuffer: Uint8Array<ArrayBuffer> | null = null;
  private micTimeBuffer: Uint8Array<ArrayBuffer> | null = null;

  private masterDeafened = false;
  private autoLevelerEnabled = true;
  private acousticCuesEnabled = true;
  private selectedOutputDeviceId: string = 'default';
  private unlockBound: (() => void) | null = null;
  private reusedSnapshot: SpectrumSnapshot = {
    rmsLevel: 0,
    primaryHarmonic: 0.1,
    secondaryHarmonic: 0.1,
    peakDb: -96,
    limiterReductionDb: 0,
  };

  /**
   * Lazily initializes or resumes the 48kHz interactive WebAudio context.
   */
  public ensureContext(): AudioContext | null {
    if (typeof window === 'undefined') return null;

    if (this.ctx && this.ctx.state !== 'closed') {
      if (this.ctx.state === 'suspended') {
        void this.ctx.resume().catch(() => {});
      }
      return this.ctx;
    }

    const AudioCtx =
      window.AudioContext ||
      (window as unknown as { webkitAudioContext?: typeof AudioContext })
        .webkitAudioContext;
    if (!AudioCtx) return null;

    try {
      const ctx = new AudioCtx({
        sampleRate: 48000,
        latencyHint: 'interactive',
      });

      const masterGain = ctx.createGain();
      masterGain.gain.value = this.masterDeafened ? 0 : 1;

      // Final Brickwall Limiter prevents DAC clipping even with 5 peers at 200%
      const masterLimiter = ctx.createDynamicsCompressor();
      masterLimiter.threshold.value = -1.2;
      masterLimiter.knee.value = 4;
      masterLimiter.ratio.value = 18;
      masterLimiter.attack.value = 0.0015;
      masterLimiter.release.value = 0.075;

      masterGain.connect(masterLimiter);
      masterLimiter.connect(ctx.destination);

      this.ctx = ctx;
      this.masterGain = masterGain;
      this.masterLimiter = masterLimiter;
      this.installGestureUnlock();

      if (this.selectedOutputDeviceId && this.selectedOutputDeviceId !== 'default') {
        void this.setOutputDevice(this.selectedOutputDeviceId);
      }

      return ctx;
    } catch {
      return null;
    }
  }

  public getContext(): AudioContext | null {
    return this.ensureContext();
  }

  private installGestureUnlock(): void {
    if (typeof window === 'undefined' || this.unlockBound) return;

    const unlock = () => {
      if (this.ctx && this.ctx.state === 'suspended') {
        void this.ctx.resume().catch(() => {});
      }
      if (this.ctx?.state === 'running') {
        this.removeGestureUnlock();
      }
    };

    this.unlockBound = unlock;
    window.addEventListener('pointerdown', unlock, { passive: true });
    window.addEventListener('keydown', unlock, { passive: true });
  }

  private removeGestureUnlock(): void {
    if (typeof window === 'undefined' || !this.unlockBound) return;
    window.removeEventListener('pointerdown', this.unlockBound);
    window.removeEventListener('keydown', this.unlockBound);
    this.unlockBound = null;
  }

  /**
   * Routes master output to a chosen speaker/headset sinkId where supported.
   */
  public async setOutputDevice(deviceId: string): Promise<boolean> {
    this.selectedOutputDeviceId = deviceId || 'default';
    const sinkTarget = this.selectedOutputDeviceId === 'default' ? '' : this.selectedOutputDeviceId;
    let applied = false;

    const ctx = this.ctx as SinkCapableAudioContext | null;
    if (ctx && typeof ctx.setSinkId === 'function') {
      try {
        await ctx.setSinkId(sinkTarget);
        applied = true;
      } catch {
        // Fallback to HTMLAudioElement sinks if AudioContext.setSinkId is restricted
      }
    }

    for (const chain of this.peers.values()) {
      const sinkEl = chain.pullSink as HTMLAudioElement & {
        setSinkId?: (sinkId: string) => Promise<void>;
      };
      if (typeof sinkEl.setSinkId === 'function') {
        try {
          await sinkEl.setSinkId(sinkTarget);
          applied = true;
        } catch {}
      }
    }

    return applied;
  }

  public setAutoLevelerEnabled(enabled: boolean): void {
    this.autoLevelerEnabled = enabled;
    if (!this.ctx) return;
    const now = this.ctx.currentTime;
    for (const chain of this.peers.values()) {
      if (!chain.autoLeveler) continue;
      chain.autoLeveler.threshold.setTargetAtTime(
        enabled ? -14 : -1.5,
        now,
        SMOOTH_TAU_SEC,
      );
      chain.autoLeveler.ratio.setTargetAtTime(
        enabled ? 10 : 2,
        now,
        SMOOTH_TAU_SEC,
      );
    }
  }

  public setAcousticCuesEnabled(enabled: boolean): void {
    this.acousticCuesEnabled = enabled;
  }

  /**
   * Attaches a remote operator's MediaStream into the dedicated 48kHz DSP pipeline.
   */
  public attachPeer(
    peerId: string,
    stream: MediaStream,
    gainPercent = 100,
    muted = false,
    pan: SpatialPanPosition = 'C',
    eqProfile: OperatorEqProfile = 'balanced',
  ): void {
    this.detachPeer(peerId);

    const pullSink = new Audio();
    pullSink.autoplay = true;
    pullSink.srcObject = stream;

    const ctx = this.ensureContext();
    if (!ctx || !this.masterGain) {
      pullSink.muted = this.masterDeafened || muted || gainPercent <= 0;
      pullSink.volume = Math.max(0, Math.min(1, gainPercent / 100));
      void pullSink.play().catch(() => {});
      this.peers.set(peerId, {
        peerId,
        stream,
        pullSink,
        source: null,
        highpass: null,
        lowShelf: null,
        presenceBoost: null,
        autoLeveler: null,
        gainNode: null,
        pannerNode: null,
        analyser: null,
        fftBuffer: null,
        timeBuffer: null,
        gainPercent,
        muted,
        pan,
        eqProfile,
        duckMultiplier: 1.0,
        fallbackMode: true,
      });
      return;
    }

    // Keep RTP packet pull active in Chromium while WebAudio renders output
    pullSink.muted = true;
    pullSink.volume = 0;
    void pullSink.play().catch(() => {});

    try {
      const eq = EQ_PROFILE_CONFIGS[eqProfile] ?? EQ_PROFILE_CONFIGS.balanced;
      const source = ctx.createMediaStreamSource(stream);

      // 1. High-Pass 85Hz vocal clarity filter (eliminates sub-bass footsteps/explosions)
      const highpass = ctx.createBiquadFilter();
      highpass.type = 'highpass';
      highpass.frequency.value = eq.highpassHz;
      highpass.Q.value = 0.707;

      // 2. Low-Shelf 220Hz contour filter (operator EQ body control)
      const lowShelf = ctx.createBiquadFilter();
      lowShelf.type = 'lowshelf';
      lowShelf.frequency.value = 220;
      lowShelf.gain.value = eq.lowShelfDb;

      // 3. Peaking 3.5kHz Presence Boost filter (cuts through gunfire & utility audio)
      const presenceBoost = ctx.createBiquadFilter();
      presenceBoost.type = 'peaking';
      presenceBoost.frequency.value = eq.presenceFreqHz;
      presenceBoost.Q.value = eq.presenceQ;
      presenceBoost.gain.value = eq.presenceGainDb;

      // 4. Smart Rage / Shout Auto-Leveler (DynamicsCompressorNode)
      const autoLeveler = ctx.createDynamicsCompressor();
      autoLeveler.threshold.value = this.autoLevelerEnabled ? -14 : -1.5;
      autoLeveler.knee.value = 8;
      autoLeveler.ratio.value = this.autoLevelerEnabled ? 10 : 2;
      autoLeveler.attack.value = 0.002;
      autoLeveler.release.value = 0.095;

      // 5. Logarithmic 0-200% GainNode + IGL Ducking stage
      const gainNode = ctx.createGain();
      const baseLinear = muted ? 0 : percentToLogarithmicGain(gainPercent);
      gainNode.gain.value = baseLinear;

      // 6. True 3D Spatial Panner (L: -1.0, C: 0.0, R: +1.0)
      const pannerNode =
        typeof ctx.createStereoPanner === 'function'
          ? ctx.createStereoPanner()
          : null;
      if (pannerNode) {
        pannerNode.pan.value = SPATIAL_PAN_VALUES[pan] ?? 0;
      }

      // 7. Real-Time FFT 256 AnalyserNode for dual-layer sine wave visualization
      const analyser = ctx.createAnalyser();
      analyser.fftSize = 256;
      analyser.smoothingTimeConstant = 0.52;
      const fftBuffer = new Uint8Array(
        new ArrayBuffer(analyser.frequencyBinCount),
      );
      const timeBuffer = new Uint8Array(new ArrayBuffer(analyser.fftSize));

      source.connect(highpass);
      highpass.connect(lowShelf);
      lowShelf.connect(presenceBoost);
      presenceBoost.connect(autoLeveler);
      autoLeveler.connect(gainNode);

      if (pannerNode) {
        gainNode.connect(pannerNode);
        pannerNode.connect(analyser);
      } else {
        gainNode.connect(analyser);
      }
      analyser.connect(this.masterGain);

      this.peers.set(peerId, {
        peerId,
        stream,
        pullSink,
        source,
        highpass,
        lowShelf,
        presenceBoost,
        autoLeveler,
        gainNode,
        pannerNode,
        analyser,
        fftBuffer,
        timeBuffer,
        gainPercent,
        muted,
        pan,
        eqProfile,
        duckMultiplier: 1.0,
        fallbackMode: false,
      });
    } catch {
      pullSink.muted = this.masterDeafened || muted || gainPercent <= 0;
      pullSink.volume = Math.max(0, Math.min(1, gainPercent / 100));
      this.peers.set(peerId, {
        peerId,
        stream,
        pullSink,
        source: null,
        highpass: null,
        lowShelf: null,
        presenceBoost: null,
        autoLeveler: null,
        gainNode: null,
        pannerNode: null,
        analyser: null,
        fftBuffer: null,
        timeBuffer: null,
        gainPercent,
        muted,
        pan,
        eqProfile,
        duckMultiplier: 1.0,
        fallbackMode: true,
      });
    }
  }

  /**
   * Smoothly updates per-operator logarithmic gain (0–200%), mute, 3D pan (-1/0/+1), and EQ profile.
   */
  public updatePeerMix(
    peerId: string,
    gainPercent: number,
    muted: boolean,
    pan: SpatialPanPosition,
    eqProfile?: OperatorEqProfile,
  ): void {
    const chain = this.peers.get(peerId);
    if (!chain) return;

    chain.gainPercent = gainPercent;
    chain.muted = muted;
    chain.pan = pan;
    if (eqProfile) chain.eqProfile = eqProfile;

    if (chain.fallbackMode || !this.ctx || !chain.gainNode) {
      chain.pullSink.muted = this.masterDeafened || muted || gainPercent <= 0;
      chain.pullSink.volume = Math.max(
        0,
        Math.min(1, (gainPercent / 100) * chain.duckMultiplier),
      );
      return;
    }

    const now = this.ctx.currentTime;
    const targetGain = muted
      ? 0
      : percentToLogarithmicGain(gainPercent) * chain.duckMultiplier;
    chain.gainNode.gain.setTargetAtTime(targetGain, now, SMOOTH_TAU_SEC);

    if (chain.pannerNode) {
      const targetPan = SPATIAL_PAN_VALUES[pan] ?? 0;
      chain.pannerNode.pan.setTargetAtTime(targetPan, now, SMOOTH_TAU_SEC);
    }

    if (eqProfile && chain.highpass && chain.lowShelf && chain.presenceBoost) {
      const eq = EQ_PROFILE_CONFIGS[eqProfile] ?? EQ_PROFILE_CONFIGS.balanced;
      chain.highpass.frequency.setTargetAtTime(
        eq.highpassHz,
        now,
        SMOOTH_TAU_SEC,
      );
      chain.lowShelf.gain.setTargetAtTime(eq.lowShelfDb, now, SMOOTH_TAU_SEC);
      chain.presenceBoost.frequency.setTargetAtTime(
        eq.presenceFreqHz,
        now,
        SMOOTH_TAU_SEC,
      );
      chain.presenceBoost.Q.setTargetAtTime(eq.presenceQ, now, SMOOTH_TAU_SEC);
      chain.presenceBoost.gain.setTargetAtTime(
        eq.presenceGainDb,
        now,
        SMOOTH_TAU_SEC,
      );
    }
  }

  /**
   * Applies IGL Priority Speaker Ducking:
   * When any priority speaker (IGL) is actively speaking, non-priority peers
   * smoothly duck by 30% (multiplier = 0.70), restoring smoothly when IGL stops.
   */
  public applyPriorityDucking(
    priorityPeerSpeaking: boolean,
    prioritySpeakerIds: ReadonlySet<string>,
    enabled = true,
  ): void {
    const shouldDuck = enabled && priorityPeerSpeaking;
    const now = this.ctx?.currentTime ?? 0;

    for (const chain of this.peers.values()) {
      const isPriority = prioritySpeakerIds.has(chain.peerId);
      const nextMultiplier = shouldDuck && !isPriority ? IGL_DUCK_FACTOR : 1.0;
      if (Math.abs(chain.duckMultiplier - nextMultiplier) < 0.005) continue;

      chain.duckMultiplier = nextMultiplier;
      if (chain.fallbackMode || !this.ctx || !chain.gainNode) {
        chain.pullSink.volume = Math.max(
          0,
          Math.min(1, (chain.gainPercent / 100) * nextMultiplier),
        );
        continue;
      }

      const targetGain = chain.muted
        ? 0
        : percentToLogarithmicGain(chain.gainPercent) * nextMultiplier;
      const tau =
        nextMultiplier < 1.0 ? DUCK_ATTACK_TAU_SEC : DUCK_RELEASE_TAU_SEC;
      chain.gainNode.gain.setTargetAtTime(targetGain, now, tau);
    }
  }

  public setPeerEqProfile(peerId: string, eqProfile: OperatorEqProfile): void {
    const chain = this.peers.get(peerId);
    if (!chain) return;
    this.updatePeerMix(
      peerId,
      chain.gainPercent,
      chain.muted,
      chain.pan,
      eqProfile,
    );
  }

  public setMasterDeafen(deafened: boolean): void {
    this.masterDeafened = deafened;
    if (this.ctx && this.masterGain) {
      this.masterGain.gain.setTargetAtTime(
        deafened ? 0 : 1,
        this.ctx.currentTime,
        SMOOTH_TAU_SEC,
      );
    }
    for (const chain of this.peers.values()) {
      if (chain.fallbackMode) {
        chain.pullSink.muted = deafened || chain.muted;
      }
    }
  }

  /**
   * Computes FFT 256 spectrum snapshot from an AnalyserNode without heap allocations.
   */
  private extractSpectrum(
    analyser: AnalyserNode | null,
    fftBuffer: Uint8Array<ArrayBuffer> | null,
    timeBuffer: Uint8Array<ArrayBuffer> | null,
    compressor: DynamicsCompressorNode | null,
  ): SpectrumSnapshot {
    if (!analyser || !fftBuffer || !timeBuffer) return ZERO_SPECTRUM;

    analyser.getByteFrequencyData(fftBuffer);
    analyser.getByteTimeDomainData(timeBuffer);

    // At 48kHz & FFT 256 -> each bin = 48000 / 256 = 187.5 Hz
    // Vocal fundamental & chest/mid harmonics: bins 1..10 (~187Hz..1875Hz)
    let lowMidSum = 0;
    const lowMidEnd = Math.min(11, fftBuffer.length);
    for (let i = 1; i < lowMidEnd; i++) {
      lowMidSum += fftBuffer[i];
    }
    const lowMidAvg = lowMidSum / Math.max(1, lowMidEnd - 1);

    // Vocal presence & articulation harmonics: bins 11..34 (~2.0kHz..6.4kHz)
    let presenceSum = 0;
    const presenceEnd = Math.min(35, fftBuffer.length);
    for (let i = 11; i < presenceEnd; i++) {
      presenceSum += fftBuffer[i];
    }
    const presenceAvg = presenceSum / Math.max(1, presenceEnd - 11);

    // Time-domain true RMS & Peak dBFS
    let sqSum = 0;
    let peakSample = 0;
    for (let i = 0; i < timeBuffer.length; i++) {
      const centered = (timeBuffer[i] - 128) / 128;
      const abs = Math.abs(centered);
      if (abs > peakSample) peakSample = abs;
      sqSum += centered * centered;
    }
    const rms = Math.sqrt(sqSum / timeBuffer.length);
    const peakDb =
      peakSample > 0.00002 ? Math.max(-96, 20 * Math.log10(peakSample)) : -96;

    const rmsLevel = Math.min(
      100,
      Math.round(rms * 240 + (lowMidAvg / 255) * 38),
    );
    const primaryHarmonic = Math.min(
      1,
      Math.max(0.06, (lowMidAvg / 255) * 1.35 + rms * 0.85),
    );
    const secondaryHarmonic = Math.min(
      1,
      Math.max(0.05, (presenceAvg / 255) * 1.55 + rms * 0.55),
    );
    const limiterReductionDb = compressor
      ? Math.abs(Math.min(0, compressor.reduction))
      : 0;

    this.reusedSnapshot.rmsLevel = rmsLevel;
    this.reusedSnapshot.primaryHarmonic = primaryHarmonic;
    this.reusedSnapshot.secondaryHarmonic = secondaryHarmonic;
    this.reusedSnapshot.peakDb = peakDb;
    this.reusedSnapshot.limiterReductionDb = limiterReductionDb;

    return this.reusedSnapshot;
  }

  public samplePeerSpectrum(peerId: string): SpectrumSnapshot {
    const chain = this.peers.get(peerId);
    if (!chain || chain.muted) return ZERO_SPECTRUM;
    return this.extractSpectrum(
      chain.analyser,
      chain.fftBuffer,
      chain.timeBuffer,
      chain.autoLeveler,
    );
  }

  public samplePeerLevel(peerId: string): number {
    return this.samplePeerSpectrum(peerId).rmsLevel;
  }

  public attachLocalMic(stream: MediaStream): void {
    this.detachLocalMic();
    const ctx = this.ensureContext();
    if (!ctx) return;

    try {
      const source = ctx.createMediaStreamSource(stream);
      const highpass = ctx.createBiquadFilter();
      highpass.type = 'highpass';
      highpass.frequency.value = 85;
      highpass.Q.value = 0.707;

      const presence = ctx.createBiquadFilter();
      presence.type = 'peaking';
      presence.frequency.value = 3500;
      presence.Q.value = 1.15;
      presence.gain.value = 3.2;

      const compressor = ctx.createDynamicsCompressor();
      compressor.threshold.value = -14;
      compressor.knee.value = 8;
      compressor.ratio.value = 8;
      compressor.attack.value = 0.002;
      compressor.release.value = 0.085;

      const analyser = ctx.createAnalyser();
      analyser.fftSize = 256;
      analyser.smoothingTimeConstant = 0.48;

      source.connect(highpass);
      highpass.connect(presence);
      presence.connect(compressor);
      compressor.connect(analyser);

      this.micSource = source;
      this.micHighpass = highpass;
      this.micPresence = presence;
      this.micCompressor = compressor;
      this.micAnalyser = analyser;
      this.micFftBuffer = new Uint8Array(
        new ArrayBuffer(analyser.frequencyBinCount),
      );
      this.micTimeBuffer = new Uint8Array(new ArrayBuffer(analyser.fftSize));
    } catch {
      this.detachLocalMic();
    }
  }

  public sampleMicSpectrum(): SpectrumSnapshot {
    return this.extractSpectrum(
      this.micAnalyser,
      this.micFftBuffer,
      this.micTimeBuffer,
      this.micCompressor,
    );
  }

  public sampleMicLevel(): number {
    return this.sampleMicSpectrum().rmsLevel;
  }

  public detachLocalMic(): void {
    try {
      this.micSource?.disconnect();
      this.micHighpass?.disconnect();
      this.micPresence?.disconnect();
      this.micCompressor?.disconnect();
      this.micAnalyser?.disconnect();
    } catch {}
    this.micSource = null;
    this.micHighpass = null;
    this.micPresence = null;
    this.micCompressor = null;
    this.micAnalyser = null;
    this.micFftBuffer = null;
    this.micTimeBuffer = null;
  }

  /**
   * Synthesizes a subtle, studio-grade WebAudio micro-chirp for Push-To-Talk engage/release.
   */
  public playPttBeep(phase: 'engage' | 'release'): void {
    if (!this.acousticCuesEnabled || this.masterDeafened) return;
    const ctx = this.ensureContext();
    if (!ctx || !this.masterGain) return;

    try {
      const now = ctx.currentTime;
      const osc = ctx.createOscillator();
      const env = ctx.createGain();

      osc.type = 'sine';
      if (phase === 'engage') {
        osc.frequency.setValueAtTime(740, now);
        osc.frequency.exponentialRampToValueAtTime(1108, now + 0.036);
      } else {
        osc.frequency.setValueAtTime(988, now);
        osc.frequency.exponentialRampToValueAtTime(659, now + 0.038);
      }

      env.gain.setValueAtTime(0.0001, now);
      env.gain.linearRampToValueAtTime(0.045, now + 0.006);
      env.gain.exponentialRampToValueAtTime(0.0001, now + 0.044);

      osc.connect(env);
      env.connect(this.masterGain);
      osc.start(now);
      osc.stop(now + 0.048);
    } catch {}
  }

  /**
   * Synthesizes distinct, minimalist esports tactical callout cues via WebAudio oscillators.
   */
  public playCalloutCue(cue: CalloutCueType): void {
    if (!this.acousticCuesEnabled || this.masterDeafened) return;
    const ctx = this.ensureContext();
    if (!ctx || !this.masterGain) return;

    const patterns: Record<CalloutCueType, Array<[number, number, number]>> = {
      ready: [
        [659.25, 0.0, 0.055],
        [880.0, 0.06, 0.075],
      ],
      rotate: [
        [987.77, 0.0, 0.045],
        [1318.5, 0.052, 0.045],
        [987.77, 0.104, 0.055],
      ],
      eco: [
        [587.33, 0.0, 0.06],
        [440.0, 0.068, 0.08],
      ],
      drop: [
        [783.99, 0.0, 0.05],
        [1046.5, 0.055, 0.07],
      ],
      force: [
        [523.25, 0.0, 0.045],
        [659.25, 0.05, 0.045],
        [1046.5, 0.1, 0.085],
      ],
      gg: [
        [523.25, 0.0, 0.05],
        [659.25, 0.055, 0.05],
        [783.99, 0.11, 0.09],
      ],
    };

    try {
      const baseTime = ctx.currentTime;
      for (const [freq, offset, dur] of patterns[cue]) {
        const osc = ctx.createOscillator();
        const env = ctx.createGain();
        osc.type = 'triangle';
        osc.frequency.setValueAtTime(freq, baseTime + offset);

        env.gain.setValueAtTime(0.0001, baseTime + offset);
        env.gain.linearRampToValueAtTime(0.052, baseTime + offset + 0.008);
        env.gain.exponentialRampToValueAtTime(
          0.0001,
          baseTime + offset + dur,
        );

        osc.connect(env);
        env.connect(this.masterGain);
        osc.start(baseTime + offset);
        osc.stop(baseTime + offset + dur + 0.006);
      }
    } catch {}
  }

  /**
   * 3D Akustik Sonar (Spatial Attention Pulse):
   * Synthesizes an authentic spatial radar ping sweeping through StereoPannerNode (-0.8 to +0.8 or target pan).
   */
  public play3DSonarPulse(pan: number = 0): void {
    if (this.masterDeafened) return;
    const ctx = this.ensureContext();
    if (!ctx || !this.masterGain) return;

    try {
      const now = ctx.currentTime;
      const osc = ctx.createOscillator();
      const harmonicOsc = ctx.createOscillator();
      const panner = ctx.createStereoPanner ? ctx.createStereoPanner() : null;
      const env = ctx.createGain();

      // Chirp sweep: 640Hz -> 1880Hz
      osc.type = 'sine';
      osc.frequency.setValueAtTime(640, now);
      osc.frequency.exponentialRampToValueAtTime(1880, now + 0.18);

      harmonicOsc.type = 'triangle';
      harmonicOsc.frequency.setValueAtTime(1280, now);
      harmonicOsc.frequency.exponentialRampToValueAtTime(2560, now + 0.18);

      // Amplitude envelope
      env.gain.setValueAtTime(0.0001, now);
      env.gain.linearRampToValueAtTime(0.09, now + 0.012);
      env.gain.exponentialRampToValueAtTime(0.0001, now + 0.36);

      if (panner) {
        const startPan = pan !== 0 ? pan : -0.7;
        const endPan = pan !== 0 ? pan : 0.7;
        panner.pan.setValueAtTime(startPan, now);
        panner.pan.linearRampToValueAtTime(endPan, now + 0.28);
        osc.connect(env);
        harmonicOsc.connect(env);
        env.connect(panner);
        panner.connect(this.masterGain);
      } else {
        osc.connect(env);
        harmonicOsc.connect(env);
        env.connect(this.masterGain);
      }

      osc.start(now);
      harmonicOsc.start(now);
      osc.stop(now + 0.38);
      harmonicOsc.stop(now + 0.38);
    } catch {}
  }

  /**
   * Tactile chirp when Duo-Link toggles.
   */
  public playDuoLinkChirp(isLinked: boolean): void {
    if (this.masterDeafened) return;
    const ctx = this.ensureContext();
    if (!ctx || !this.masterGain) return;
    try {
      const now = ctx.currentTime;
      const osc = ctx.createOscillator();
      const env = ctx.createGain();
      osc.type = 'sine';
      if (isLinked) {
        osc.frequency.setValueAtTime(587.33, now);
        osc.frequency.setValueAtTime(880.0, now + 0.05);
      } else {
        osc.frequency.setValueAtTime(880.0, now);
        osc.frequency.setValueAtTime(440.0, now + 0.05);
      }
      env.gain.setValueAtTime(0.0001, now);
      env.gain.linearRampToValueAtTime(0.06, now + 0.008);
      env.gain.exponentialRampToValueAtTime(0.0001, now + 0.12);
      osc.connect(env);
      env.connect(this.masterGain);
      osc.start(now);
      osc.stop(now + 0.13);
    } catch {}
  }

  private duoLinkPartnerId: string | null = null;
  private duoLinkTransmitting: boolean = false;

  public setDuoLinkPartner(partnerId: string | null): void {
    this.duoLinkPartnerId = partnerId;
  }

  public getDuoLinkPartner(): string | null {
    return this.duoLinkPartnerId;
  }

  public setDuoLinkTransmitting(active: boolean): void {
    this.duoLinkTransmitting = active;
  }

  public isDuoLinkTransmitting(): boolean {
    return this.duoLinkTransmitting;
  }

  public detachPeer(peerId: string): void {
    const chain = this.peers.get(peerId);
    if (!chain) return;

    try {
      chain.source?.disconnect();
      chain.highpass?.disconnect();
      chain.lowShelf?.disconnect();
      chain.presenceBoost?.disconnect();
      chain.autoLeveler?.disconnect();
      chain.gainNode?.disconnect();
      chain.pannerNode?.disconnect();
      chain.analyser?.disconnect();
    } catch {}

    chain.pullSink.pause();
    chain.pullSink.srcObject = null;
    this.peers.delete(peerId);
  }

  public getAttachedPeerIds(): string[] {
    return Array.from(this.peers.keys());
  }

  public dispose(): void {
    this.destroy();
  }

  public destroy(): void {
    this.removeGestureUnlock();
    this.detachLocalMic();
    for (const peerId of Array.from(this.peers.keys())) {
      this.detachPeer(peerId);
    }

    try {
      this.masterGain?.disconnect();
      this.masterLimiter?.disconnect();
    } catch {}

    if (this.ctx && this.ctx.state !== 'closed') {
      void this.ctx.close().catch(() => {});
    }
    this.ctx = null;
    this.masterGain = null;
    this.masterLimiter = null;
  }
}

let sharedAudioEngine: MevaAudioEngine | null = null;

export function getMevaAudioEngine(): MevaAudioEngine {
  if (!sharedAudioEngine) {
    sharedAudioEngine = new MevaAudioEngine();
  }
  return sharedAudioEngine;
}
