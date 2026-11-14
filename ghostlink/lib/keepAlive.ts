// ─────────────────────────────────────────────────────────
// Meva HUD — Codespaces & Session Keep-Alive Controller
// ─────────────────────────────────────────────────────────
// Prevents Codespaces / browser idle timeouts with a lightweight
// periodic HTTP heartbeat against /api/health plus instant focus/
// network recovery pings.

export interface KeepAliveStatus {
  active: boolean;
  lastBeatAt: number | null;
  lastLatencyMs: number | null;
  totalBeats: number;
  consecutiveFailures: number;
}

const DEFAULT_INTERVAL_MS = 45_000;

export class MevaKeepAliveController {
  private timerId: ReturnType<typeof setInterval> | null = null;
  private boundRecoveryHandler: (() => void) | null = null;
  private listeners = new Set<(status: KeepAliveStatus) => void>();
  private status: KeepAliveStatus = {
    active: false,
    lastBeatAt: null,
    lastLatencyMs: null,
    totalBeats: 0,
    consecutiveFailures: 0,
  };

  public getStatus(): KeepAliveStatus {
    return this.status;
  }

  public subscribe(listener: (status: KeepAliveStatus) => void): () => void {
    this.listeners.add(listener);
    listener(this.status);
    return () => {
      this.listeners.delete(listener);
    };
  }

  private emit(): void {
    for (const listener of this.listeners) {
      listener(this.status);
    }
  }

  public async beat(reason: 'interval' | 'startup' | 'recovery' = 'interval'): Promise<boolean> {
    if (typeof fetch === 'undefined') return false;
    const started = typeof performance !== 'undefined' ? performance.now() : Date.now();
    try {
      const res = await fetch(`/api/health?keepalive=1&reason=${reason}&t=${Date.now()}`, {
        cache: 'no-store',
        keepalive: true,
      });
      const finished = typeof performance !== 'undefined' ? performance.now() : Date.now();
      const latency = Math.max(1, Math.round(finished - started));
      this.status = {
        ...this.status,
        lastBeatAt: Date.now(),
        lastLatencyMs: latency,
        totalBeats: this.status.totalBeats + 1,
        consecutiveFailures: res.ok ? 0 : this.status.consecutiveFailures + 1,
      };
      this.emit();
      return res.ok;
    } catch {
      this.status = {
        ...this.status,
        consecutiveFailures: this.status.consecutiveFailures + 1,
      };
      this.emit();
      return false;
    }
  }

  public start(intervalMs = DEFAULT_INTERVAL_MS): () => void {
    if (this.timerId !== null) {
      return () => this.stop();
    }

    this.status = { ...this.status, active: true };
    this.emit();
    void this.beat('startup');

    this.timerId = setInterval(() => {
      void this.beat('interval');
    }, intervalMs);

    if (typeof window !== 'undefined' && typeof document !== 'undefined') {
      const onRecovery = () => {
        if (document.visibilityState === 'visible') {
          void this.beat('recovery');
        }
      };
      this.boundRecoveryHandler = onRecovery;
      window.addEventListener('online', onRecovery);
      window.addEventListener('focus', onRecovery);
      document.addEventListener('visibilitychange', onRecovery);
    }

    return () => this.stop();
  }

  public stop(): void {
    if (this.timerId !== null) {
      clearInterval(this.timerId);
      this.timerId = null;
    }
    if (
      this.boundRecoveryHandler &&
      typeof window !== 'undefined' &&
      typeof document !== 'undefined'
    ) {
      window.removeEventListener('online', this.boundRecoveryHandler);
      window.removeEventListener('focus', this.boundRecoveryHandler);
      document.removeEventListener('visibilitychange', this.boundRecoveryHandler);
      this.boundRecoveryHandler = null;
    }
    this.status = { ...this.status, active: false };
    this.emit();
  }
}

let sharedKeepAlive: MevaKeepAliveController | null = null;

export function getMevaKeepAlive(): MevaKeepAliveController {
  if (!sharedKeepAlive) {
    sharedKeepAlive = new MevaKeepAliveController();
  }
  return sharedKeepAlive;
}
