// ─────────────────────────────────────────────────────────
// Meva HUD — Custom 404 Not Found Page
// ─────────────────────────────────────────────────────────

import Link from 'next/link';
import { IconShield, IconMevaMark } from '@/components/ui/MevaIcons';

export default function NotFound() {
  return (
    <div className="flex h-screen w-screen items-center justify-center bg-[#070607] p-4 text-[#FAF2EE] select-none font-sans">
      <div className="w-full max-w-md rounded-2xl border border-[#8F1622]/50 bg-[#0F080B]/98 p-6 shadow-[0_24px_80px_rgba(0,0,0,0.92)] text-center space-y-4">
        <div className="mx-auto flex h-14 w-14 items-center justify-center rounded-2xl bg-[#590C15]/40 border border-[#A61826] text-[#FF4655]">
          <IconMevaMark size={28} />
        </div>

        <div className="space-y-1">
          <span className="text-3xl font-black tracking-widest text-[#FF4655]">404</span>
          <h2 className="text-base font-extrabold tracking-wide text-[#FAF2EE]">
            Frekans Sinyali Bulunamadı
          </h2>
          <p className="text-xs text-[#9E8E91] leading-relaxed">
            Aradığınız taktik oda veya kanal koordinatı mevcut değil ya da kapatılmış.
          </p>
        </div>

        <div className="pt-2">
          <Link
            href="/"
            className="inline-flex h-10 w-full items-center justify-center gap-2 rounded-xl crimson-cta text-xs font-extrabold text-[#FAF2EE] shadow-md transition-all active:scale-95"
          >
            <IconShield size={16} />
            <span>Ana Komuta Masasına Dön</span>
          </Link>
        </div>
      </div>
    </div>
  );
}
