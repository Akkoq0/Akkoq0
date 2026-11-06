// ─────────────────────────────────────────────────────────
// Meva HUD — Game-Boost Eco Mode (Zero-Leak Optimizer)
// ─────────────────────────────────────────────────────────

'use client';

import { useEffect, useCallback, useRef } from 'react';
import { useAppStore } from '@/lib/store';

const CPU_SAMPLE_INTERVAL = 2000;

export function useGameBoost() {
  const isEnabled = useAppStore((s) => s.ecoMode.isEnabled);
  const setEcoMode = useAppStore((s) => s.setEcoMode);
  const toggleEcoEnabled = useAppStore((s) => s.toggleEcoEnabled);
  const cpuTimerRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const idleHandleRef = useRef<number | null>(null);

  const clearSamplers = useCallback(() => {
    if (cpuTimerRef.current !== null) {
      clearInterval(cpuTimerRef.current);
      cpuTimerRef.current = null;
    }
    if (
      idleHandleRef.current !== null &&
      typeof window !== 'undefined' &&
      'cancelIdleCallback' in window
    ) {
      window.cancelIdleCallback(idleHandleRef.current);
      idleHandleRef.current = null;
    }
  }, []);

  const activateEco = useCallback(() => {
    if (!isEnabled || typeof document === 'undefined') return;

    document.body.classList.add('eco-active');
    setEcoMode({ isActive: true, animationsPaused: true });

    // Prevent duplicate intervals when both blur & visibilitychange fire
    clearSamplers();

    cpuTimerRef.current = setInterval(() => {
      const start = performance.now();
      if ('requestIdleCallback' in window) {
        idleHandleRef.current = window.requestIdleCallback(
          () => {
            const idleWait = performance.now() - start;
            // Longer wait before idle = busier main thread (0ms -> ~0.2%, 50ms+ -> 100%)
            const estimate = Math.max(
              0.2,
              Math.min(100, (idleWait / 50) * 100),
            );
            setEcoMode({ cpuEstimate: Math.round(estimate * 10) / 10 });
          },
          { timeout: 100 },
        );
      }
    }, CPU_SAMPLE_INTERVAL);
  }, [isEnabled, setEcoMode, clearSamplers]);

  const deactivateEco = useCallback(() => {
    if (typeof document !== 'undefined') {
      document.body.classList.remove('eco-active');
    }
    clearSamplers();
    setEcoMode({ isActive: false, animationsPaused: false, cpuEstimate: 0 });
  }, [setEcoMode, clearSamplers]);

  useEffect(() => {
    if (!isEnabled) {
      deactivateEco();
      return;
    }

    const handleVisibility = () => {
      if (document.hidden) activateEco();
      else deactivateEco();
    };

    const handleBlur = () => activateEco();
    const handleFocus = () => deactivateEco();

    document.addEventListener('visibilitychange', handleVisibility);
    window.addEventListener('blur', handleBlur);
    window.addEventListener('focus', handleFocus);

    return () => {
      document.removeEventListener('visibilitychange', handleVisibility);
      window.removeEventListener('blur', handleBlur);
      window.removeEventListener('focus', handleFocus);
      deactivateEco();
    };
  }, [isEnabled, activateEco, deactivateEco]);

  return {
    isEnabled,
    toggleEcoEnabled,
  };
}
