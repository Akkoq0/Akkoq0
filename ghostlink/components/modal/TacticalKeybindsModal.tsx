'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Tactical Hotkeys & Command Reference Modal
// ─────────────────────────────────────────────────────────

import React, { useEffect } from 'react';
import { IconClose, IconBolt } from '@/components/ui/MevaIcons';

interface TacticalKeybindsModalProps {
  isOpen: boolean;
  onClose: () => void;
}

interface KeybindRow {
  keyLabel: string;
  action: string;
  category: 'audio' | 'tactical' | 'navigation';
  description: string;
}

const KEYBINDS: KeybindRow[] = [
  {
    keyLabel: 'Space / CapsLock',
    action: 'Push-To-Talk (PTT)',
    category: 'audio',
    description: 'Mikrofonu yalnızca basılı tuttuğunuzda 8ms gecikmeyle yayına sokar.',
  },
  {
    keyLabel: 'B',
    action: 'Duo-Link Özel Frekans',
    category: 'audio',
    description: 'Eşleştiğiniz ikili operatörle (Duo) anlık özel telsiz fısıltısı.',
  },
  {
    keyLabel: 'M',
    action: 'Mikrofon Aç / Kapat',
    category: 'audio',
    description: 'Donanım mikrofon akışını anında susturur veya açar.',
  },
  {
    keyLabel: 'D',
    action: 'Sağırlaştır (Deafen)',
    category: 'audio',
    description: 'Gelen tüm sesleri ve anonsları anında susturur.',
  },
  {
    keyLabel: 'T',
    action: 'IGL Taktik Komut Çarkı',
    category: 'tactical',
    description: 'Hızlı taktik ve rota komutları için radyal tekerleği açar.',
  },
  {
    keyLabel: 'Ctrl + S',
    action: 'Stratbook Harita Masası',
    category: 'tactical',
    description: 'Canlı 2D taktik strateji ve çizim panosunu tam ekran açar.',
  },
  {
    keyLabel: '1 — 5',
    action: 'Slot Rol İşaretçileri',
    category: 'tactical',
    description: 'Lobi slotlarına hızlı rol ataması ve beacon sinyali gönderir.',
  },
  {
    keyLabel: '?',
    action: 'Taktik Kısayol Rehberi',
    category: 'navigation',
    description: 'Bu komuta merkezi kısayol referans panelini açar.',
  },
  {
    keyLabel: 'Esc',
    action: 'Paneli / Modalı Kapat',
    category: 'navigation',
    description: 'Açık modalları kapatır ve ana HUD kokpitine döner.',
  },
];

export const TacticalKeybindsModal: React.FC<TacticalKeybindsModalProps> = ({
  isOpen,
  onClose,
}) => {
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

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-5 exec-backdrop select-none font-sans"
      onClick={(e) => {
        e.preventDefault();
        onClose();
      }}
    >
      <div
        className="w-full max-w-xl bg-[#0F080B]/98 border border-[#8F1622]/60 rounded-2xl shadow-[0_24px_80px_rgba(0,0,0,0.92)] flex flex-col max-h-[85vh] overflow-hidden"
        onClick={(e) => {
          e.preventDefault();
          e.stopPropagation();
        }}
      >
        {/* Header */}
        <div className="px-5 py-4 border-b border-[#2A1319] flex items-center justify-between bg-gradient-to-r from-[#200B11] via-[#100709] to-[#0A0507]">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-[#590C15]/40 border border-[#A61826]/60 flex items-center justify-center text-[#FF4655] shadow-sm">
              <IconBolt size={20} />
            </div>
            <div>
              <h2 className="text-base font-extrabold text-[#FAF2EE] tracking-wide">
                Taktik Komuta & Tuş Kısayolları
              </h2>
              <p className="text-xs text-[#9E8E91] mt-0.5">
                Turnuva ve dereceli maçlarda sıfır gecikmeli hızlı kontrol kılavuzu.
              </p>
            </div>
          </div>
          <button
            type="button"
            onClick={(e) => {
              e.preventDefault();
              onClose();
            }}
            aria-label="Kapat"
            className="w-8 h-8 rounded-lg bg-[#180A0E] hover:bg-[#281016] border border-[#590C15]/45 text-[#A58D8E] hover:text-[#FAF2EE] flex items-center justify-center transition-colors"
          >
            <IconClose size={16} />
          </button>
        </div>

        {/* Content */}
        <div className="flex-1 overflow-y-auto p-5 space-y-3">
          {KEYBINDS.map((kb, idx) => (
            <div
              key={idx}
              className="p-3 rounded-xl bg-[#14080B] border border-[#2A1319] hover:border-[#8F1622]/80 transition-all flex items-center justify-between gap-3 shadow-sm"
            >
              <div className="min-w-0 flex-1">
                <div className="flex items-center gap-2 mb-0.5">
                  <span className="text-xs font-extrabold text-[#FAF2EE]">
                    {kb.action}
                  </span>
                  <span className="text-[10px] font-semibold px-1.5 py-0.5 rounded bg-[#200A10] text-[#E0858F] border border-[#590C15]/40 uppercase">
                    {kb.category}
                  </span>
                </div>
                <p className="text-[11px] text-[#8E7E81] truncate">{kb.description}</p>
              </div>

              <div className="flex-shrink-0">
                <kbd className="inline-block px-2.5 py-1 rounded-lg bg-[#1E0C12] border border-[#A61826]/50 text-xs font-mono font-bold text-[#FAF2EE] shadow-sm">
                  {kb.keyLabel}
                </kbd>
              </div>
            </div>
          ))}
        </div>

        {/* Footer */}
        <div className="px-5 py-3 border-t border-[#2A1319] bg-[#0A0507] flex items-center justify-between text-xs text-[#8E7E81]">
          <span>Kısayol paneline dilediğiniz an <strong className="text-[#FAF2EE] font-mono">?</strong> tuşuyla ulaşabilirsiniz.</span>
          <button
            type="button"
            onClick={onClose}
            className="px-3 py-1.5 rounded-lg crimson-cta text-xs font-bold text-[#FAF2EE] active:scale-95 transition-all"
          >
            Anladım
          </button>
        </div>
      </div>
    </div>
  );
};
