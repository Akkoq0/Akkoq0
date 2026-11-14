'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Enterprise Critical Action Confirmation Modal
// ─────────────────────────────────────────────────────────
// Replaces native window.confirm() with themed RBAC-guarded
// in-app confirmations for destructive / critical operations.

import React from 'react';
import { IconClose, IconShield } from '@/components/ui/MevaIcons';

export interface ConfirmActionModalProps {
  isOpen: boolean;
  title: string;
  description: string;
  confirmLabel?: string;
  cancelLabel?: string;
  danger?: boolean;
  onConfirm: () => void;
  onCancel: () => void;
}

export const ConfirmActionModal: React.FC<ConfirmActionModalProps> = ({
  isOpen,
  title,
  description,
  confirmLabel = 'Onayla ve Uygula',
  cancelLabel = 'Vazgeç',
  danger = true,
  onConfirm,
  onCancel,
}) => {
  if (!isOpen) return null;

  return (
    <div
      className="fixed inset-0 z-[70] flex items-center justify-center bg-black/80 backdrop-blur-xs p-4 select-none font-sans"
      onClick={(e) => {
        e.preventDefault();
        e.stopPropagation();
        onCancel();
      }}
    >
      <div
        onClick={(e) => {
          e.preventDefault();
          e.stopPropagation();
        }}
        className="w-full max-w-md rounded-2xl bg-[#0B0608] border border-[#8F1622]/75 shadow-[0_24px_80px_rgba(0,0,0,0.95)] overflow-hidden"
      >
        <div className="px-4 py-3.5 border-b border-[#241116] flex items-center justify-between bg-gradient-to-r from-[#240A10] via-[#12070A] to-[#0A0507]">
          <div className="flex items-center gap-2.5 min-w-0">
            <span className="w-8 h-8 rounded-xl bg-[#4D0D16]/70 border border-[#C82333]/50 text-[#FF6B79] flex items-center justify-center flex-shrink-0">
              <IconShield size={16} />
            </span>
            <h3 className="text-sm font-extrabold text-[#FAF2EE] truncate">
              {title}
            </h3>
          </div>
          <button
            type="button"
            onClick={(e) => {
              e.preventDefault();
              e.stopPropagation();
              onCancel();
            }}
            className="w-7 h-7 rounded-lg flex items-center justify-center bg-[#140A0D] hover:bg-[#220D13] text-[#9E8E91] hover:text-white border border-[#2C141A]"
            aria-label="Kapat"
          >
            <IconClose size={13} />
          </button>
        </div>

        <div className="p-4 space-y-4">
          <p className="text-xs leading-relaxed text-[#C4B6BA]">{description}</p>
          <div className="flex items-center justify-end gap-2 pt-1">
            <button
              type="button"
              onClick={(e) => {
                e.preventDefault();
                e.stopPropagation();
                onCancel();
              }}
              className="h-9 px-3.5 rounded-xl bg-[#140A0D] hover:bg-[#1E0E13] border border-[#2C141A] text-xs font-bold text-[#B8AAAC] hover:text-white transition-colors"
            >
              {cancelLabel}
            </button>
            <button
              type="button"
              onClick={(e) => {
                e.preventDefault();
                e.stopPropagation();
                onConfirm();
              }}
              className={`h-9 px-4 rounded-xl text-xs font-extrabold text-white transition-all active:scale-95 ${
                danger
                  ? 'crimson-cta shadow-[0_4px_16px_rgba(200,35,51,0.35)]'
                  : 'bg-[#7A1521] hover:bg-[#9E1B2A] border border-[#C82333]/60'
              }`}
            >
              {confirmLabel}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
