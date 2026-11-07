// ─────────────────────────────────────────────────────────
// Meva HUD — Master RAF Audio Wave Ticker (Zero-Re-Render)
// ─────────────────────────────────────────────────────────
// Single centralized animation loop with smart idle sleeping and
// 45–60 FPS rate-limiting. Bypasses React state & Zustand entirely:
// mutates Canvas 2D contexts directly without triggering re-renders.

import { getMevaAudioEngine } from '@/src/lib/audioEngine';

interface RegisteredWaveItem {
  id: string;
  canvas: HTMLCanvasElement;
  ctx: CanvasRenderingContext2D;
  peerId?: string;
  active: boolean;
  muted: boolean;
  speed: number;
  phase: number;
  isSleeping: boolean;
}

const LOGICAL_W = 240;
const LOGICAL_H = 64;
const MID_Y = 32;
const FPS_INTERVAL_MS = 1000 / 50; // ~50 FPS limiter (silky smooth, zero heat)

export class MasterWaveTicker {
  private items = new Map<string, RegisteredWaveItem>();
  private activeCount = 0;
  private rafId: number | null = null;
  private lastFrameTime = 0;
  private isPaused = false;

  constructor() {
    if (typeof window !== 'undefined') {
      window.addEventListener('visibilitychange', () => {
        if (document.hidden) {
          this.pause();
        } else {
          this.resume();
        }
      });
    }
  }

  public register(
    id: string,
    canvas: HTMLCanvasElement,
    options: {
      peerId?: string;
      active: boolean;
      muted?: boolean;
      speed?: number;
    },
  ): void {
    const ctx = canvas.getContext('2d', { alpha: true });
    if (!ctx) return;

    // Fixed internal resolution for crisp retina rendering
    canvas.width = LOGICAL_W;
    canvas.height = LOGICAL_H;

    const item: RegisteredWaveItem = {
      id,
      canvas,
      ctx,
      peerId: options.peerId,
      active: options.active,
      muted: options.muted ?? false,
      speed: options.speed ?? 1.4,
      phase: Math.random() * Math.PI * 2,
      isSleeping: false,
    };

    this.items.set(id, item);

    // Initial render (idle/muted or live)
    this.drawItem(item, 0.016);

    if (item.active && !item.muted) {
      this.activeCount++;
      this.ensureRunning();
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
        // Force immediate render to static baseline line and sleep
        item.isSleeping = false;
        this.drawItem(item, 0.016);
        item.isSleeping = true;
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
    const { ctx, canvas } = item;
    const w = canvas.width;
    const h = canvas.height;

    ctx.clearRect(0, 0, w, h);

    // Baseline horizontal line
    ctx.beginPath();
    ctx.moveTo(0, MID_Y);
    ctx.lineTo(w, MID_Y);
    ctx.lineWidth = 1;

    if (item.muted) {
      ctx.strokeStyle = '#B3222C';
      ctx.globalAlpha = 0.72;
      ctx.stroke();
      ctx.globalAlpha = 1.0;
      item.isSleeping = true;
      return;
    }

    if (!item.active) {
      ctx.strokeStyle = '#3B242B';
      ctx.globalAlpha = 0.85;
      ctx.stroke();
      ctx.globalAlpha = 1.0;
      item.isSleeping = true;
      return;
    }

    // Dynamic wave synthesis directly from WebAudio DSP harmonics
    let primary = 0.55;
    let secondary = 0.42;

    try {
      const audio = getMevaAudioEngine();
      if (item.peerId === 'usr-local') {
        const mic = audio.sampleMicSpectrum();
        if (mic.rmsLevel > 2) {
          primary = mic.primaryHarmonic;
          secondary = mic.secondaryHarmonic;
        }
      } else if (item.peerId) {
        const spec = audio.samplePeerSpectrum(item.peerId);
        if (spec.rmsLevel > 1) {
          primary = spec.primaryHarmonic;
          secondary = spec.secondaryHarmonic;
        }
      }
    } catch {}

    item.phase += dt * (item.speed * 3.6);

    const primaryAmp = Math.max(3.5, Math.min(22, primary * 25));
    const secondaryAmp = Math.max(2.5, Math.min(14, secondary * 17));

    // Secondary Wave (Delicate Silk Harmonic: presence 2kHz–6kHz)
    ctx.beginPath();
    for (let x = 0; x <= w; x += 4) {
      const env = Math.sin((x / w) * Math.PI); // Window envelope drops smoothly to 0 at edges
      const y =
        MID_Y +
        secondaryAmp *
          env *
          Math.sin((x / 34) * Math.PI * 2 + item.phase * 1.35 + 1.2);
      if (x === 0) ctx.moveTo(x, y);
      else ctx.lineTo(x, y);
    }
    ctx.strokeStyle = 'rgba(240, 140, 150, 0.42)';
    ctx.lineWidth = 1.25;
    ctx.stroke();

    // Primary Wave Area Gradient (Ribbon Glow)
    const areaGrad = ctx.createLinearGradient(0, 0, 0, h);
    areaGrad.addColorStop(0, 'rgba(200, 35, 51, 0.26)');
    areaGrad.addColorStop(0.65, 'rgba(110, 17, 27, 0.08)');
    areaGrad.addColorStop(1, 'rgba(9, 7, 8, 0)');

    ctx.beginPath();
    ctx.moveTo(0, MID_Y);
    for (let x = 0; x <= w; x += 3) {
      const env = Math.sin((x / w) * Math.PI);
      const y =
        MID_Y +
        primaryAmp * env * Math.sin((x / 42) * Math.PI * 2 + item.phase);
      ctx.lineTo(x, y);
    }
    ctx.lineTo(w, MID_Y);
    ctx.closePath();
    ctx.fillStyle = areaGrad;
    ctx.fill();

    // Primary Wave Stroke (Vocal Fundamental Band 180Hz–1.8kHz)
    const strokeGrad = ctx.createLinearGradient(0, 0, w, 0);
    strokeGrad.addColorStop(0, '#7A121D');
    strokeGrad.addColorStop(0.5, '#C82333');
    strokeGrad.addColorStop(1, '#E34B5A');

    ctx.beginPath();
    for (let x = 0; x <= w; x += 3) {
      const env = Math.sin((x / w) * Math.PI);
      const y =
        MID_Y +
        primaryAmp * env * Math.sin((x / 42) * Math.PI * 2 + item.phase);
      if (x === 0) ctx.moveTo(x, y);
      else ctx.lineTo(x, y);
    }
    ctx.strokeStyle = strokeGrad;
    ctx.lineWidth = 1.8;
    ctx.stroke();
  }
}

let sharedWaveTicker: MasterWaveTicker | null = null;

export function getMasterWaveTicker(): MasterWaveTicker {
  if (!sharedWaveTicker) {
    sharedWaveTicker = new MasterWaveTicker();
  }
  return sharedWaveTicker;
}
