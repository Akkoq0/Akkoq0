// ─────────────────────────────────────────────────────────
// Meva HUD — Central Page Visibility & Background Sleep Manager
// ─────────────────────────────────────────────────────────
// Freezes 100% of UI animations, SVG morphing, WebAudio polling,
// and telemetry ticks when user alt-tabs or switches tabs (document.hidden).
// Resumes immediately with zero lag upon returning.

export type VisibilityListener = (hidden: boolean) => void;

class MevaVisibilityManager {
  private listeners = new Set<VisibilityListener>();
  private isHidden = false;

  constructor() {
    if (typeof window !== 'undefined' && typeof document !== 'undefined') {
      this.isHidden = document.hidden;
      document.addEventListener(
        'visibilitychange',
        () => {
          this.isHidden = document.hidden;
          for (const listener of this.listeners) {
            listener(this.isHidden);
          }
        },
        { passive: true },
      );
    }
  }

  public isDocumentHidden(): boolean {
    return this.isHidden;
  }

  public subscribe(listener: VisibilityListener): () => void {
    this.listeners.add(listener);
    return () => {
      this.listeners.delete(listener);
    };
  }
}

let sharedVisibilityManager: MevaVisibilityManager | null = null;

export function getMevaVisibilityManager(): MevaVisibilityManager {
  if (!sharedVisibilityManager) {
    sharedVisibilityManager = new MevaVisibilityManager();
  }
  return sharedVisibilityManager;
}
