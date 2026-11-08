'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Notification Center & Tactical Toast Drawer
// ─────────────────────────────────────────────────────────
// Real-time toast stack and slide-in drawer for IGL tactical orders,
// room invites, system audits, and P2P connection events.

import React, { useState } from 'react';
import { IconClose } from '@/components/ui/MevaIcons';

export interface MevaNotification {
  id: string;
  title: string;
  message: string;
  type: 'tactical' | 'invite' | 'system' | 'audit';
  time: string;
  read: boolean;
}

interface NotificationDrawerProps {
  isOpen: boolean;
  onClose: () => void;
}

export const NotificationDrawer: React.FC<NotificationDrawerProps> = ({ isOpen, onClose }) => {
  const [notifications, setNotifications] = useState<MevaNotification[]>([
    {
      id: 'notif-1',
      title: 'IGL Taktik Emri',
      message: 'Sihirdar Vadisi: Baron çukuru görüşü kuruldu. Aşama 2 (Mid Execute) başladı.',
      type: 'tactical',
      time: 'Az önce',
      read: false,
    },
    {
      id: 'notif-2',
      title: 'Duo-Link Frekansı Aktif',
      message: 'Operatör partnerinizle B tuşu alt-telsiz kanalı 96kbps Opus olarak eşleşti.',
      type: 'system',
      time: '3 dk önce',
      read: true,
    },
    {
      id: 'notif-3',
      title: 'P2P Mesh Güvenliği',
      message: 'ECDH P-256 oturum anahtarları başarıyla güncellendi.',
      type: 'audit',
      time: '12 dk önce',
      read: true,
    },
  ]);

  const markAllRead = () => {
    setNotifications((prev) => prev.map((n) => ({ ...n, read: true })));
  };

  const clearAll = () => {
    setNotifications([]);
  };

  if (!isOpen) return null;

  return (
    <div
      className="fixed inset-0 z-50 flex justify-end bg-black/60 select-none backdrop-blur-xs"
      onClick={(e) => {
        e.preventDefault();
        onClose();
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
            <h3 className="text-xs font-black text-white uppercase tracking-wider">BİLDİRİM MERKEZİ</h3>
          </div>
          <button
            type="button"
            onClick={(e) => {
              e.preventDefault();
              onClose();
            }}
            className="w-6 h-6 rounded-lg flex items-center justify-center text-[#8E7E81] hover:text-white"
          >
            <IconClose size={14} />
          </button>
        </div>

        {/* Action Pills */}
        <div className="px-4 py-2 bg-[#0E0609] border-b border-[#1E0B11] flex items-center justify-between text-[10px]">
          <button
            type="button"
            onClick={markAllRead}
            className="text-[#B8AAAC] hover:text-white font-bold"
          >
            Tümünü Okundu İşaretle
          </button>
          <button
            type="button"
            onClick={clearAll}
            className="text-red-400 hover:text-red-300 font-bold"
          >
            Temizle
          </button>
        </div>

        {/* Notification List */}
        <div className="flex-1 overflow-y-auto p-3 space-y-2">
          {notifications.length === 0 ? (
            <div className="text-center py-12 text-xs text-[#8E7E81]">Yeni bildirim bulunmuyor.</div>
          ) : (
            notifications.map((n) => (
              <div
                key={n.id}
                className={`p-3 rounded-xl border transition-all ${
                  !n.read
                    ? 'bg-[#150A0E] border-[#8F1622]/70 shadow-xs'
                    : 'bg-[#0E0609] border-[#1E0B11] opacity-75'
                }`}
              >
                <div className="flex items-center justify-between mb-1">
                  <span className="text-[11px] font-black text-white flex items-center gap-1.5">
                    <span>
                      {n.type === 'tactical' ? '🎯' : n.type === 'system' ? '⚡' : '🛡️'}
                    </span>
                    <span>{n.title}</span>
                  </span>
                  <span className="text-[9.5px] font-mono text-[#8E7E81]">{n.time}</span>
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
