// ─────────────────────────────────────────────────────────
// Meva HUD — Master RAF Audio Wave Ticker (Zero-Re-Render SVG Path Engine)
// ─────────────────────────────────────────────────────────
// Single centralized animation loop with 30 FPS frame-limiter (33.3ms delta).
// Mutates SVG <path ref={pathRef}> ('d' attribute) directly via DOM mutation.
// Non-speaking operators sleep with zero rAF cycles and static baseline path.

import { getMevaAudioEngine } from '@/src/lib/audioEngine';
import { getMevaVisibilityManager } from '@/src/lib/visibilityManager';

interface RegisteredWaveItem {
  id: string;
  path: SVGPathElement;
  peerId?: string;
  active: boolean;
  muted: boolean;
  speed: number;
  phase: number;
  isSleeping: boolean;
}

const STATIC_PATH = 'M 0 12 L 200 12';
const FPS_INTERVAL_MS = 1000 / 30; // 33.3ms for strict 30 FPS rate-limiter

export class MasterWaveTicker {
  private items = new Map<string, RegisteredWaveItem>();
  private activeCount = 0;
  private rafId: number | null = null;
  private lastFrameTime = 0;
  private isPaused = false;

  constructor() {
    getMevaVisibilityManager().subscribe((hidden) => {
      if (hidden) {
        this.pause();
      } else {
        this.resume();
      }
    });
  }

  public register(
    id: string,
    path: SVGPathElement,
    options: {
      peerId?: string;
      active: boolean;
      muted?: boolean;
      speed?: number;
    },
  ): void {
    const item: RegisteredWaveItem = {
      id,
      path,
      peerId: options.peerId,
      active: options.active,
      muted: options.muted ?? false,
      speed: options.speed ?? 1.4,
      phase: 0,
      isSleeping: true,
    };

    this.items.set(id, item);

    if (item.active && !item.muted) {
      item.isSleeping = false;
      this.activeCount++;
      this.ensureRunning();
    } else {
      path.setAttribute('d', STATIC_PATH);
    }
  }

  public updateSpeakerState(
    id: string,
    active: boolean,
    muted: boolean,
    peerId?: string,
  ): void {
    const item = this.items.get(id);
    if (!item) return;

    const prevWasSpeaking = item.active && !item.muted;
    const nextIsSpeaking = active && !muted;

    item.active = active;
    item.muted = muted;
    if (peerId !== undefined) item.peerId = peerId;

    if (prevWasSpeaking !== nextIsSpeaking) {
      if (nextIsSpeaking) {
        this.activeCount++;
        item.isSleeping = false;
        this.ensureRunning();
      } else {
        this.activeCount = Math.max(0, this.activeCount - 1);
        item.isSleeping = true;
        item.path.setAttribute('d', STATIC_PATH);
        if (this.activeCount === 0 && this.rafId !== null) {
          cancelAnimationFrame(this.rafId);
          this.rafId = null;
        }
      }
    }
  }

  public unregister(id: string): void {
    const item = this.items.get(id);
    if (!item) return;
    if (item.active && !item.muted) {
      this.activeCount = Math.max(0, this.activeCount - 1);
    }
    this.items.delete(id);
    if (this.activeCount === 0 && this.rafId !== null) {
      cancelAnimationFrame(this.rafId);
      this.rafId = null;
    }
  }

  public pause(): void {
    this.isPaused = true;
    if (this.rafId !== null) {
      cancelAnimationFrame(this.rafId);
      this.rafId = null;
    }
  }

  public resume(): void {
    this.isPaused = false;
    this.ensureRunning();
  }

  private ensureRunning(): void {
    if (this.isPaused || this.activeCount === 0 || this.rafId !== null) return;
    this.lastFrameTime = performance.now();
    this.rafId = requestAnimationFrame(this.tick);
  }

  private tick = (now: number): void => {
    this.rafId = null;
    if (this.isPaused || this.activeCount === 0) return;

    const elapsed = now - this.lastFrameTime;
    if (elapsed >= FPS_INTERVAL_MS) {
      const dt = Math.min(0.06, elapsed / 1000);
      this.lastFrameTime = now - (elapsed % FPS_INTERVAL_MS);

      for (const item of this.items.values()) {
        if (!item.isSleeping && item.active && !item.muted) {
          this.drawItem(item, dt);
        }
      }
    }

    if (this.activeCount > 0 && !this.isPaused) {
      this.rafId = requestAnimationFrame(this.tick);
    }
  };

  private drawItem(item: RegisteredWaveItem, dt: number): void {
    if (item.muted || !item.active) {
      item.path.setAttribute('d', STATIC_PATH);
      item.isSleeping = true;
      return;
    }

    item.phase += dt * (item.speed * 4.2);

    let primaryHarmonic = 0.55;
    try {
      const audio = getMevaAudioEngine();
      if (item.peerId === 'usr-local') {
        const mic = audio.sampleMicSpectrum();
        if (mic.rmsLevel > 2) primaryHarmonic = mic.primaryHarmonic;
      } else if (item.peerId) {
        const spec = audio.samplePeerSpectrum(item.peerId);
        if (spec.rmsLevel > 1) primaryHarmonic = spec.primaryHarmonic;
      }
    } catch {}

    const amp = Math.max(3, Math.min(10, primaryHarmonic * 11));
    const p = item.phase;
    const y1 = (12 + Math.sin(p) * amp).toFixed(1);
    const y2 = (12 - Math.sin(p + 1.2) * (amp * 0.8)).toFixed(1);
    const y3 = (12 + Math.sin(p + 2.4) * (amp * 0.9)).toFixed(1);
    const y4 = (12 - Math.sin(p + 3.6) * (amp * 0.6)).toFixed(1);

    item.path.setAttribute(
      'd',
      `M 0 12 C 30 ${y1}, 60 ${y2}, 100 12 C 140 ${y3}, 170 ${y4}, 200 12`,
    );
  }
}

let sharedWaveTicker: MasterWaveTicker | null = null;

export function getMasterWaveTicker(): MasterWaveTicker {
  if (!sharedWaveTicker) {
    sharedWaveTicker = new MasterWaveTicker();
  }
  return sharedWaveTicker;
}
