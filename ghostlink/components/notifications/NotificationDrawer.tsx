'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Notification Center & Tactical Toast Drawer
// ─────────────────────────────────────────────────────────
// Global top-right slide-in drawer connected to useNotificationStore
// for IGL tactical orders, room invites, RBAC audits & P2P telemetry.

import React from 'react';
import { IconClose } from '@/components/ui/MevaIcons';
import { useNotificationStore } from '@/store/useNotificationStore';

interface NotificationDrawerProps {
  isOpen?: boolean;
  onClose?: () => void;
}

export const NotificationDrawer: React.FC<NotificationDrawerProps> = ({
  isOpen,
  onClose,
}) => {
  const notifications = useNotificationStore((s) => s.notifications);
  const storeOpen = useNotificationStore((s) => s.isDrawerOpen);
  const closeDrawer = useNotificationStore((s) => s.closeDrawer);
  const markAllRead = useNotificationStore((s) => s.markAllRead);
  const markAsRead = useNotificationStore((s) => s.markAsRead);
  const removeNotification = useNotificationStore((s) => s.removeNotification);
  const clearAll = useNotificationStore((s) => s.clearAll);

  const visible = typeof isOpen === 'boolean' ? isOpen : storeOpen;
  const handleClose = () => {
    if (onClose) onClose();
    closeDrawer();
  };

  if (!visible) return null;

  return (
    <div
      className="fixed inset-0 z-[65] flex justify-end bg-black/60 select-none backdrop-blur-xs"
      onClick={(e) => {
        e.preventDefault();
        handleClose();
      }}
    >
      <div
        onClick={(e) => {
          e.preventDefault();
          e.stopPropagation();
        }}
        className="w-full max-w-sm h-full bg-[#0A0507] border-l border-[#8F1622]/60 shadow-[0_0_50px_rgba(0,0,0,0.9)] flex flex-col overflow-hidden"
      >
        {/* Header */}
        <div className="p-4 border-b border-[#241116] flex items-center justify-between bg-gradient-to-r from-[#1C0B10] to-[#0A0507]">
          <div className="flex items-center gap-2">
            <span className="text-base">🔔</span>
            <h3 className="text-xs font-black text-white uppercase tracking-wider">
              BİLDİRİM MERKEZİ
            </h3>
            <span className="px-1.5 py-0.5 rounded bg-[#2B0C13] text-[#F08C96] text-[10px] font-mono font-bold">
              {notifications.filter((n) => !n.read).length} okunmamış
            </span>
          </div>
          <button
            type="button"
            onClick={(e) => {
              e.preventDefault();
              e.stopPropagation();
              handleClose();
            }}
            aria-label="Bildirim Çekmecesini Kapat"
            className="w-6 h-6 rounded-lg flex items-center justify-center text-[#8E7E81] hover:text-white"
          >
            <IconClose size={14} />
          </button>
        </div>

        {/* Action Pills */}
        <div className="px-4 py-2 bg-[#0E0609] border-b border-[#1E0B11] flex items-center justify-between text-[10px]">
          <button
            type="button"
            onClick={(e) => {
              e.preventDefault();
              markAllRead();
            }}
            className="text-[#B8AAAC] hover:text-white font-bold"
          >
            Tümünü Okundu İşaretle
          </button>
          <button
            type="button"
            onClick={(e) => {
              e.preventDefault();
              clearAll();
            }}
            className="text-red-400 hover:text-red-300 font-bold"
          >
            Temizle
          </button>
        </div>

        {/* Notification List */}
        <div className="flex-1 overflow-y-auto p-3 space-y-2">
          {notifications.length === 0 ? (
            <div className="text-center py-12 text-xs text-[#8E7E81]">
              Yeni bildirim bulunmuyor.
            </div>
          ) : (
            notifications.map((n) => (
              <div
                key={n.id}
                onClick={(e) => {
                  e.preventDefault();
                  markAsRead(n.id);
                }}
                className={`p-3 rounded-xl border transition-all cursor-pointer ${
                  !n.read
                    ? 'bg-[#150A0E] border-[#8F1622]/70 shadow-xs'
                    : 'bg-[#0E0609] border-[#1E0B11] opacity-75'
                }`}
              >
                <div className="flex items-center justify-between gap-2 mb-1">
                  <span className="text-[11px] font-black text-white flex items-center gap-1.5 min-w-0 truncate">
                    <span>
                      {n.type === 'tactical'
                        ? '🎯'
                        : n.type === 'invite'
                          ? '⚡'
                          : n.type === 'audit'
                            ? '🛡️'
                            : '📡'}
                    </span>
                    <span className="truncate">{n.title}</span>
                  </span>
                  <div className="flex items-center gap-1.5 flex-shrink-0">
                    <span className="text-[9.5px] font-mono text-[#8E7E81]">
                      {n.time}
                    </span>
                    <button
                      type="button"
                      aria-label="Bildirimi kaldır"
                      onClick={(e) => {
                        e.preventDefault();
                        e.stopPropagation();
                        removeNotification(n.id);
                      }}
                      className="text-[#8E7E81] hover:text-white text-[10px] px-1"
                    >
                      ×
                    </button>
                  </div>
                </div>
                <p className="text-xs text-[#B8AAAC] leading-relaxed">{n.message}</p>
              </div>
            ))
          )}
        </div>
      </div>
    </div>
  );
};
