'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Open-Core & Meva Pro Esports License Modal
// ─────────────────────────────────────────────────────────

import React, { useEffect } from 'react';
import { useAppStore } from '@/lib/store';
import { PLATFORM_FEATURES, LicenseManager } from '@/src/core/subscription/licenseManager';
import { IconClose, IconShield, IconBolt } from '@/components/ui/MevaIcons';

interface MevaProLicenseModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const MevaProLicenseModal: React.FC<MevaProLicenseModalProps> = ({
  isOpen,
  onClose,
}) => {
  const subscriptionTier = useAppStore((s) => s.subscriptionTier);
  const setSubscriptionTier = useAppStore((s) => s.setSubscriptionTier);

  useEffect(() => {
    if (!isOpen) return;
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        e.preventDefault();
        onClose();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  const isPro = subscriptionTier === 'pro';
  const meta = LicenseManager.getTierMetadata(subscriptionTier);

  const toggleTier = () => {
    setSubscriptionTier(isPro ? 'community' : 'pro');
  };

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-5 exec-backdrop select-none font-sans"
      onClick={(e) => {
        e.preventDefault();
        onClose();
      }}
    >
      <div
        className="w-full max-w-2xl bg-[#0F080B]/98 border border-[#8F1622]/65 rounded-2xl shadow-[0_24px_80px_rgba(0,0,0,0.92)] flex flex-col max-h-[90vh] overflow-hidden"
        onClick={(e) => {
          e.preventDefault();
          e.stopPropagation();
        }}
      >
        {/* Header */}
        <div className="px-5 py-4 border-b border-[#2A1319] flex items-center justify-between bg-gradient-to-r from-[#220B12] via-[#100709] to-[#0A0507]">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-[#590C15]/40 border border-[#A61826]/70 flex items-center justify-center text-[#FF4655] shadow-sm">
              <IconShield size={20} />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h2 className="text-base font-extrabold text-[#FAF2EE] tracking-wide">
                  Meva HUD Lisans & E-Spor Paketi
                </h2>
                <span
                  className={`text-[10px] font-extrabold px-2 py-0.5 rounded-full border ${
                    isPro
                      ? 'bg-[#590C15]/60 text-[#F08C96] border-[#A61826]'
                      : 'bg-[#180A0E] text-[#9E8E91] border-[#2A1319]'
                  }`}
                >
                  {meta.badge}
                </span>
              </div>
              <p className="text-xs text-[#9E8E91] mt-0.5">
                Açık kaynak topluluk özgürlüğü + Espor kulüpleri için profesyonel koçluk araçları.
              </p>
            </div>
          </div>
          <button
            type="button"
            onClick={onClose}
            aria-label="Kapat"
            className="w-8 h-8 rounded-lg bg-[#180A0E] hover:bg-[#281016] border border-[#590C15]/45 text-[#A58D8E] hover:text-[#FAF2EE] flex items-center justify-center transition-colors"
          >
            <IconClose size={16} />
          </button>
        </div>

        {/* Current Status Banner */}
        <div className="p-4 mx-5 mt-4 rounded-xl bg-[#14080B] border border-[#2A1319] flex items-center justify-between gap-3">
          <div>
            <span className="text-[10px] font-bold uppercase tracking-wider text-[#8E7E81] block">
              Aktif Çalışma Modu
            </span>
            <span className="text-sm font-extrabold text-[#FAF2EE]">
              {meta.label}
            </span>
            <p className="text-xs text-[#9E8E91] mt-0.5">{meta.description}</p>
          </div>

          <button
            type="button"
            onClick={toggleTier}
            className={`px-4 py-2 rounded-xl text-xs font-extrabold transition-all flex items-center gap-1.5 shadow-md active:scale-95 ${
              isPro
                ? 'bg-[#1E0C12] hover:bg-[#2A1018] text-[#FAF2EE] border border-[#590C15]'
                : 'crimson-cta text-[#FAF2EE]'
            }`}
          >
            <IconBolt size={14} />
            <span>{isPro ? 'Topluluk Moduna Dön' : '⚡ Pro Modunu Aktif Et'}</span>
          </button>
        </div>

        {/* Comparison Table / Features */}
        <div className="flex-1 overflow-y-auto p-5 space-y-4">
          <span className="text-xs font-bold uppercase tracking-wider text-[#C4B2B5] block">
            Özellik Matrisi (Topluluk vs Meva Pro)
          </span>

          <div className="space-y-2.5">
            {PLATFORM_FEATURES.map((feat) => {
              const active = LicenseManager.canAccessFeature(feat.id, subscriptionTier);
              return (
                <div
                  key={feat.id}
                  className={`p-3.5 rounded-xl border transition-all flex items-start justify-between gap-3 ${
                    active
                      ? 'bg-[#160A0E] border-[#8F1622]/50'
                      : 'bg-[#100709] border-[#2A1319] opacity-75'
                  }`}
                >
                  <div className="min-w-0 flex-1">
                    <div className="flex items-center gap-2 mb-1">
                      <span className="text-xs font-extrabold text-[#FAF2EE]">
                        {feat.name}
                      </span>
                      {feat.isProOnly && (
                        <span className="text-[9px] font-bold px-1.5 py-0.5 rounded bg-[#400B13] text-[#F08C96] border border-[#7A131E]/60 uppercase">
                          PRO
                        </span>
                      )}
                    </div>
                    <p className="text-[11px] text-[#8E7E81] leading-relaxed">
                      {feat.description}
                    </p>
                  </div>

                  <div className="flex-shrink-0 pt-0.5">
                    {active ? (
                      <span className="text-xs font-extrabold text-emerald-400 bg-emerald-950/40 border border-emerald-800/50 px-2 py-0.5 rounded-md">
                        Aktif
                      </span>
                    ) : (
                      <span className="text-xs font-bold text-[#8E7E81] bg-[#180A0E] border border-[#2A1319] px-2 py-0.5 rounded-md">
                        Pro Gerektirir
                      </span>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* Footer */}
        <div className="px-5 py-3 border-t border-[#2A1319] bg-[#0A0507] flex items-center justify-between text-xs text-[#8E7E81]">
          <span>
            Temel ses ve taktik tahtası <strong className="text-[#FAF2EE]">daima ücretsiz ve açık kaynak</strong> kalır.
          </span>
          <button
            type="button"
            onClick={onClose}
            className="px-3.5 py-1.5 rounded-lg crimson-cta text-xs font-bold text-[#FAF2EE] active:scale-95 transition-all"
          >
            Tamam
          </button>
        </div>
      </div>
    </div>
  );
};
