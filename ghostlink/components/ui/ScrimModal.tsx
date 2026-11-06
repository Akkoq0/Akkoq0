// ─────────────────────────────────────────────────────────
// GhostLink — Instant Scrim Link Modal (Innovation #2)
// ─────────────────────────────────────────────────────────

'use client';

import { useState } from 'react';
import { useAppStore } from '@/lib/store';
import { useScrimLink } from '@/hooks/useScrimLink';
import { useAuth } from '@/hooks/useAuth';

export function ScrimModal() {
  const show = useAppStore((s) => s.showScrimModal);
  const setShow = useAppStore((s) => s.setShowScrimModal);
  const { user } = useAuth();
  const { createScrimRoom, activeScrimRoom, copyShareLink } = useScrimLink();

  const [roomName, setRoomName] = useState('ESL Scrim Match');
  const [maxParticipants, setMaxParticipants] = useState(10);
  const [copied, setCopied] = useState(false);

  if (!show) return null;

  const handleCreate = () => {
    createScrimRoom({
      name: roomName,
      creatorId: user?.id ?? 'guest_' + Math.random().toString(36).substring(7),
      maxParticipants,
    });
  };

  const handleCopy = async () => {
    const success = await copyShareLink();
    if (success) {
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/75 backdrop-blur-sm p-4">
      <div className="w-full max-w-md rounded-2xl border border-gl-border bg-gl-bg-panel p-6 shadow-2xl">
        {/* Header */}
        <div className="flex items-center justify-between pb-4 border-b border-gl-border">
          <div className="flex items-center gap-2">
            <span className="flex h-8 w-8 items-center justify-center rounded-lg bg-gl-idle/20 text-gl-idle font-bold">
              ⚡
            </span>
            <div>
              <h3 className="text-base font-bold text-gl-text-primary">Instant Scrim Link</h3>
              <p className="text-xxs text-gl-text-muted">$0 DB Maliyetli P2P Geçici Ses Odası</p>
            </div>
          </div>
          <button
            onClick={() => setShow(false)}
            className="text-gl-text-muted hover:text-gl-text-primary transition-colors text-lg"
          >
            ✕
          </button>
        </div>

        {/* Content */}
        {!activeScrimRoom ? (
          <div className="mt-4 space-y-4">
            <div>
              <label className="block text-xs font-semibold text-gl-text-secondary uppercase tracking-wider mb-1">
                Maç / Takım Başlığı
              </label>
              <input
                type="text"
                value={roomName}
                onChange={(e) => setRoomName(e.target.value)}
                placeholder="Örn: BBL vs FUT Scrim #1"
                className="w-full rounded-lg bg-gl-bg-hover px-3.5 py-2.5 text-sm text-gl-text-primary placeholder:text-gl-text-muted outline-none border border-gl-border focus:border-gl-accent transition-colors"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-gl-text-secondary uppercase tracking-wider mb-1">
                Kapasite (Kişi)
              </label>
              <select
                value={maxParticipants}
                onChange={(e) => setMaxParticipants(Number(e.target.value))}
                className="w-full rounded-lg bg-gl-bg-hover px-3.5 py-2.5 text-sm text-gl-text-primary outline-none border border-gl-border"
              >
                <option value={4}>2v2 (4 Kişi)</option>
                <option value={6}>3v3 (6 Kişi - Apex)</option>
                <option value={10}>5v5 (10 Kişi - CS2/Valorant)</option>
                <option value={12}>12 Kişi</option>
              </select>
            </div>

            <div className="rounded-lg bg-gl-bg-darkest p-3 text-xxs text-gl-text-secondary border border-gl-border/50">
              💡 <span className="font-semibold text-gl-text-primary">Nasıl Çalışır:</span> Veritabanına tek bir satır dahi yazılmaz. Oda sadece P2P WebRTC sinyali üzerinden var olur ve 4 saat sonra kendiliğinden kaybolur.
            </div>

            <button
              onClick={handleCreate}
              className="w-full rounded-lg bg-gl-idle hover:bg-amber-500 py-3 text-sm font-bold text-white transition-all shadow-lg shadow-gl-idle/20"
            >
              Hızlı Scrim Odası Oluştur
            </button>
          </div>
        ) : (
          <div className="mt-4 space-y-4">
            <div className="rounded-xl bg-gl-bg-darkest p-4 text-center border border-gl-border">
              <span className="text-xxs uppercase tracking-wider text-gl-online font-bold">Oda Hazır</span>
              <h4 className="text-lg font-bold text-gl-text-primary mt-0.5">{activeScrimRoom.name}</h4>
              <div className="mt-3 flex items-center justify-center gap-2 rounded-lg bg-gl-bg-hover px-3 py-2 border border-gl-border">
                <code className="text-xs font-mono text-gl-accent">
                  {typeof window !== 'undefined' ? `${window.location.origin}/scrim/${activeScrimRoom.code}` : activeScrimRoom.code}
                </code>
              </div>
            </div>

            <div className="flex gap-2">
              <button
                onClick={handleCopy}
                className="flex-1 rounded-lg bg-gl-accent hover:bg-gl-accent-hover py-2.5 text-xs font-bold text-white transition-all"
              >
                {copied ? '✓ Kopyalandı!' : 'Linki Kopyala ve Paylaş'}
              </button>
              <button
                onClick={() => setShow(false)}
                className="rounded-lg bg-gl-bg-hover hover:bg-gl-bg-active px-4 py-2.5 text-xs font-semibold text-gl-text-primary transition-all"
              >
                Kapat
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

