'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Esports Keyboard Shortcuts & Tactical Cheatsheet
// ─────────────────────────────────────────────────────────

import React, { useEffect } from 'react';
import { IconClose } from '@/components/ui/MevaIcons';

interface ShortcutsHelpModalProps {
  isOpen: boolean;
  onClose: () => void;
}

interface ShortcutEntry {
  keys: string[];
  label: string;
  category: 'tactical' | 'voice' | 'canvas';
  description: string;
}

const SHORTCUTS: ShortcutEntry[] = [
  // Taktik & IGL
  { keys: ['C'], label: 'IGL Komut Çarkı', category: 'tactical', description: '8 yönlü hızlı taktik rotasyon ve infaz komut çarkını açar' },
  { keys: ['B'], label: 'Pro Stratbook Masası', category: 'tactical', description: 'İnteraktif 60 FPS radar harita ve taktik tahtasını açar' },
  { keys: ['O'], label: 'Mini HUD Overlay', category: 'tactical', description: 'Ekranı kaplamayan kompakt oyun içi ses şeridini açar' },
  { keys: ['Num 1-8'], label: 'Espor Soundboard', category: 'tactical', description: 'Spike, timeout, buzzer ve clutch ses efektlerini çalar' },

  // Ses & Telsiz
  { keys: ['M'], label: 'Mikrofon Sustur', category: 'voice', description: 'Mikrofon girişini anında susturur veya açar' },
  { keys: ['D'], label: 'Sağırlaştır (Deafen)', category: 'voice', description: 'Kulaklık ve gelen tüm telsiz seslerini kapatır' },
  { keys: ['Alt', 'B'], label: 'Duo-Link Telsiz', category: 'voice', description: 'Seçili operatör partneriyle ikili alt frekansa geçer' },

  // Harita & Gezinme
  { keys: ['Space', 'Sürükle'], label: 'Harita Kaydırma (Pan)', category: 'canvas', description: 'Taktik tahtasında tuvali serbestçe sürükler' },
  { keys: ['Tekerlek'], label: 'Harita Yakınlaştırma', category: 'canvas', description: 'Canvas üzerinde %60 - %250 arası yakınlaşır' },
  { keys: ['Ctrl', 'Z'], label: 'Geri Al (Undo)', category: 'canvas', description: 'Son çizilen taktik okunu veya pini geri alır' },
  { keys: ['Ctrl', 'Y'], label: 'İleri Al (Redo)', category: 'canvas', description: 'Geri alınan çizim işlemini yeniden uygular' },
  { keys: ['Esc'], label: 'Pencereleri Kapat', category: 'canvas', description: 'Tüm açık modal ve çekmeceleri kapatır' },
];

export const ShortcutsHelpModal: React.FC<ShortcutsHelpModalProps> = ({
  isOpen,
  onClose,
}) => {
  useEffect(() => {
    if (!isOpen) return;
    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
    };
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center exec-backdrop p-2 sm:p-4 font-sans select-none"
      onClick={(e) => {
        e.preventDefault();
        onClose();
      }}
    >
      <div
        className="w-full max-w-2xl bg-[#0B0608] border border-[#8F1622] rounded-2xl shadow-[0_24px_80px_rgba(0,0,0,0.95)] flex flex-col overflow-hidden"
        onClick={(e) => {
          e.preventDefault();
          e.stopPropagation();
        }}
      >
        {/* Header */}
        <div className="px-5 py-4 border-b border-[#241116] flex items-center justify-between bg-gradient-to-r from-[#1C0B10] to-[#0B0608]">
          <div className="flex items-center gap-2.5">
            <span className="w-9 h-9 rounded-xl bg-[#8F1622] text-white flex items-center justify-center text-lg font-bold shadow-md">
              ⌨️
            </span>
            <div>
              <h2 className="text-sm font-black text-white tracking-wide uppercase">
                Meva HUD Kısayol & Tuş Kombinasyonları
              </h2>
              <p className="text-[11px] text-[#A8989B]">
                Turnuva ve yayın esnasında hızlı erişim sağlayan espor kısayolları
              </p>
            </div>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="w-8 h-8 rounded-lg flex items-center justify-center bg-[#140A0D] text-[#8E7E81] hover:text-white border border-[#2A1319]"
          >
            <IconClose size={14} />
          </button>
        </div>

        {/* Body */}
        <div className="p-5 space-y-4 overflow-y-auto max-h-[70vh]">
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
            {SHORTCUTS.map((item, idx) => (
              <div
                key={idx}
                className="p-3 rounded-xl bg-[#12080B] border border-[#241116] flex items-start justify-between gap-3"
              >
                <div className="space-y-0.5 min-w-0">
                  <span className="text-xs font-black text-[#FAF2EE] block">
                    {item.label}
                  </span>
                  <p className="text-[10px] text-[#A8989B] leading-tight line-clamp-2">
                    {item.description}
                  </p>
                </div>

                <div className="flex items-center gap-1 flex-shrink-0">
                  {item.keys.map((k, kIdx) => (
                    <span
                      key={kIdx}
                      className="px-2 py-1 rounded-md bg-[#1C0B10] border border-[#8F1622]/60 text-[10.5px] font-mono font-black text-[#FAF2EE] shadow-xs"
                    >
                      {k}
                    </span>
                  ))}
                </div>
              </div>
            ))}
          </div>

          <div className="p-3 rounded-xl bg-[#180B10]/60 border border-[#8F1622]/40 text-center text-[10.5px] text-[#A8989B]">
            💡 İpucu: Oyun içindeyken bu pencereyi açmak için <strong className="text-white">?</strong> veya <strong className="text-white">F1</strong> tuşuna basabilirsiniz.
          </div>
        </div>

        {/* Footer */}
        <div className="p-4 border-t border-[#241116] flex items-center justify-end bg-[#0E070A]">
          <button
            type="button"
            onClick={onClose}
            className="px-4 py-2 rounded-xl bg-[#180B10] hover:bg-[#281016] border border-[#3C141E] text-xs font-bold text-[#FAF2EE]"
          >
            Anladım
          </button>
        </div>
      </div>
    </div>
  );
};
