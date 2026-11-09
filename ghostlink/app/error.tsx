'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Global Error Boundary & Crash Recovery
// ─────────────────────────────────────────────────────────

import React, { useEffect } from 'react';
import { IconShield, IconBolt } from '@/components/ui/MevaIcons';

export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    // Log exception safely to console
    console.error('[MevaHUD:GlobalError]', error);
  }, [error]);

  return (
    <div className="flex h-screen w-screen items-center justify-center bg-[#070607] p-4 text-[#FAF2EE] select-none font-sans">
      <div className="w-full max-w-md rounded-2xl border border-[#8F1622]/60 bg-[#0F080B]/98 p-6 shadow-[0_24px_80px_rgba(0,0,0,0.92)] text-center space-y-4">
        <div className="mx-auto flex h-14 w-14 items-center justify-center rounded-2xl bg-[#590C15]/40 border border-[#A61826] text-[#FF4655] shadow-inner">
          <IconShield size={28} />
        </div>

        <div className="space-y-1">
          <h2 className="text-lg font-extrabold tracking-wide text-[#FAF2EE]">
            Komuta Merkezi Hatası Tespit Edildi
          </h2>
          <p className="text-xs text-[#9E8E91] leading-relaxed">
            Beklenmeyen bir arayüz istisnası oluştu. Taktik bağlantı ve yerel verileriniz koruma altında.
          </p>
        </div>

        {error?.message && (
          <div className="rounded-xl border border-[#2A1319] bg-[#14080B] p-3 text-left">
            <span className="text-[10px] font-mono font-bold uppercase text-[#8E7E81] block mb-1">
              Hata Kaydı
            </span>
            <p className="text-xs font-mono text-[#F08C96] break-all line-clamp-3">
              {error.message}
            </p>
          </div>
        )}

        <div className="flex gap-2.5 pt-2">
          <button
            type="button"
            onClick={() => reset()}
            className="flex-1 h-10 rounded-xl crimson-cta text-xs font-extrabold text-[#FAF2EE] shadow-md transition-all flex items-center justify-center gap-2 active:scale-95"
          >
            <IconBolt size={16} />
            <span>Sistemi Yeniden Başlat</span>
          </button>
          <button
            type="button"
            onClick={() => window.location.reload()}
            className="h-10 px-4 rounded-xl border border-[#2A1319] bg-[#180A0E] hover:bg-[#281016] text-xs font-bold text-[#A58D8E] hover:text-[#FAF2EE] transition-colors"
          >
            Yenile
          </button>
        </div>
      </div>
    </div>
  );
}
