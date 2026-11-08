'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Enterprise Esports Error Boundary
// ─────────────────────────────────────────────────────────
// Gracefully isolates and recovers from runtime component failures
// maintaining 100% platform uptime and Deep Espresso & Burgundy aesthetics.

import React, { Component, ErrorInfo, ReactNode } from 'react';

interface Props {
  children: ReactNode;
  fallbackTitle?: string;
}

interface State {
  hasError: boolean;
  error: Error | null;
  errorInfo: ErrorInfo | null;
}

export class MevaErrorBoundary extends Component<Props, State> {
  public state: State = {
    hasError: false,
    error: null,
    errorInfo: null,
  };

  public static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error, errorInfo: null };
  }

  public componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.error('[Meva ErrorBoundary] Caught exception:', error, errorInfo);
    this.setState({ errorInfo });
  }

  private handleReset = () => {
    this.setState({ hasError: false, error: null, errorInfo: null });
  };

  public render() {
    if (this.state.hasError) {
      return (
        <div className="w-full h-full min-h-[220px] rounded-2xl bg-[#0B0608] border border-[#8F1622]/60 p-6 flex flex-col items-center justify-center text-center select-none shadow-[0_20px_50px_rgba(0,0,0,0.9)]">
          <div className="w-12 h-12 rounded-full bg-[#1C0B10] border border-[#8F1622] flex items-center justify-center text-2xl mb-3">
            ⚠️
          </div>
          <h3 className="text-sm font-black text-[#FAF2EE] uppercase tracking-wider mb-1">
            {this.props.fallbackTitle || 'Modül Güvenlik Duvarı Devrede'}
          </h3>
          <p className="text-xs text-[#9E8E91] max-w-md mb-4 leading-relaxed">
            Bu bileşende beklenmedik bir durum algılandı ancak platformun geri kalanı kesintisiz çalışmaya devam ediyor.
          </p>
          {this.state.error && (
            <div className="w-full max-w-md px-3 py-2 bg-[#040203] rounded-lg border border-[#241116] text-[11px] font-mono text-[#F08C96] text-left overflow-x-auto mb-4">
              {this.state.error.message}
            </div>
          )}
          <button
            type="button"
            onClick={this.handleReset}
            className="h-8 px-4 rounded-xl crimson-cta text-xs font-black text-white shadow-lg transition-transform hover:scale-105"
          >
            Modülü Yeniden Başlat
          </button>
        </div>
      );
    }

    return this.props.children;
  }
}
