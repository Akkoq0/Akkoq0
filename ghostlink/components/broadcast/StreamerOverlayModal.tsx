'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Streamer Mode & OBS Studio Broadcast Configurator
// ─────────────────────────────────────────────────────────

import React, { useState, useMemo } from 'react';
import { useAppStore } from '@/lib/store';
import { IconClose } from '@/components/ui/MevaIcons';

interface StreamerOverlayModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const StreamerOverlayModal: React.FC<StreamerOverlayModalProps> = ({
  isOpen,
  onClose,
}) => {
  const activeScrim = useAppStore((s) => s.activeScrimRoom);
  const activeVoiceChannelId = useAppStore((s) => s.activeVoiceChannelId);

  const roomCode = activeScrim?.code || (activeVoiceChannelId ? 'ROOM-MAIN' : 'DEMO-LIVE');

  const [layout, setLayout] = useState<'bottom-bar' | 'side-dock'>('bottom-bar');
  const [showScore, setShowScore] = useState<boolean>(true);
  const [showTactics, setShowTactics] = useState<boolean>(true);
  const [streamerPrivacyActive, setStreamerPrivacyActive] = useState<boolean>(true);
  const [copied, setCopied] = useState<boolean>(false);

  const obsUrl = useMemo(() => {
    if (typeof window === 'undefined') return '';
    const base = window.location.origin;
    return `${base}/broadcast/${roomCode}?layout=${layout}&score=${showScore}&tactics=${showTactics}`;
  }, [roomCode, layout, showScore, showTactics]);

  const handleCopyLink = () => {
    if (navigator?.clipboard && obsUrl) {
      void navigator.clipboard.writeText(obsUrl);
      setCopied(true);
      setTimeout(() => setCopied(false), 2500);
    }
  };

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
        {/* Modal Header */}
        <div className="px-5 py-4 border-b border-[#241116] flex items-center justify-between bg-gradient-to-r from-[#1C0B10] to-[#0B0608]">
          <div className="flex items-center gap-2.5">
            <span className="w-9 h-9 rounded-xl bg-[#8F1622] text-white flex items-center justify-center text-lg font-bold shadow-md">
              🎥
            </span>
            <div>
              <h2 className="text-sm font-black text-white tracking-wide uppercase">
                Yayıncı & OBS Tarayıcı Kaynağı (Streamer HUD)
              </h2>
              <p className="text-[11px] text-[#A8989B]">
                OBS Studio, Streamlabs ve Twitch için şeffaf espor ses & taktik katmanı
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

        {/* Modal Body */}
        <div className="p-5 space-y-4 overflow-y-auto max-h-[75vh]">
          {/* OBS URL Generator Strip */}
          <div className="p-3.5 rounded-xl bg-[#12080B] border border-[#2E151C] space-y-2">
            <div className="flex items-center justify-between">
              <span className="text-[10px] font-black text-[#8E7E81] uppercase tracking-wider">
                OBS TARAYICI KAYNAĞI BAĞLANTISI (BROWSER SOURCE)
              </span>
              <span className="text-[10px] font-mono text-emerald-400">
                1920x1080 · ŞEFFAF ZEMİN
              </span>
            </div>
            <div className="flex items-center gap-2">
              <input
                type="text"
                readOnly
                value={obsUrl}
                className="flex-1 px-3 py-2 rounded-lg bg-[#070406] border border-[#2E151C] text-xs font-mono text-[#F4EFF0] focus:outline-hidden"
              />
              <button
                type="button"
                onClick={handleCopyLink}
                className={`px-4 py-2 rounded-lg text-xs font-black transition-all ${
                  copied
                    ? 'bg-emerald-600 text-white shadow-md'
                    : 'crimson-cta text-white active:scale-95'
                }`}
              >
                {copied ? '✓ Kopyalandı' : 'Linki Kopyala'}
              </button>
            </div>
            <p className="text-[10px] text-[#8E7E81] leading-relaxed">
              OBS Studio&apos;da &ldquo;+ Kaynaklar &gt; Tarayıcı&rdquo; ekleyin ve bu URL&apos;yi yapıştırın. Genişlik: 1920, Yükseklik: 1080 ayarlayarak yayına şeffaf olarak entegre edin.
            </p>
          </div>

          {/* Configuration Options */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3.5">
            {/* Layout Mode */}
            <div className="p-3 rounded-xl bg-[#12080B] border border-[#2E151C] space-y-2">
              <span className="text-[10px] font-black text-[#8E7E81] uppercase tracking-wider block">
                GÖRSEL YERLEŞİM (LAYOUT)
              </span>
              <div className="grid grid-cols-2 gap-2">
                <button
                  type="button"
                  onClick={() => setLayout('bottom-bar')}
                  className={`p-2.5 rounded-lg text-xs font-bold flex flex-col items-center justify-center gap-1 border transition-all ${
                    layout === 'bottom-bar'
                      ? 'crimson-cta text-white border-[#FF4655]'
                      : 'bg-[#070406] text-[#9E8E91] hover:text-white border-[#241116]'
                  }`}
                >
                  <span className="text-base">▃▃▃</span>
                  <span className="text-[10.5px]">Alt Yatay Şerit</span>
                </button>
                <button
                  type="button"
                  onClick={() => setLayout('side-dock')}
                  className={`p-2.5 rounded-lg text-xs font-bold flex flex-col items-center justify-center gap-1 border transition-all ${
                    layout === 'side-dock'
                      ? 'crimson-cta text-white border-[#FF4655]'
                      : 'bg-[#070406] text-[#9E8E91] hover:text-white border-[#241116]'
                  }`}
                >
                  <span className="text-base">▮</span>
                  <span className="text-[10.5px]">Yan Dikey Kadro</span>
                </button>
              </div>
            </div>

            {/* Elements Toggles */}
            <div className="p-3 rounded-xl bg-[#12080B] border border-[#2E151C] space-y-2">
              <span className="text-[10px] font-black text-[#8E7E81] uppercase tracking-wider block">
                GÖSTERİLECEK BİLEŞENLER
              </span>
              <div className="space-y-1.5">
                <label className="flex items-center justify-between text-xs text-[#FAF2EE] cursor-pointer">
                  <span>Espor Maç Skor Tablosu</span>
                  <input
                    type="checkbox"
                    checked={showScore}
                    onChange={(e) => setShowScore(e.target.checked)}
                    className="accent-[#C82333] w-4 h-4 rounded"
                  />
                </label>
                <label className="flex items-center justify-between text-xs text-[#FAF2EE] cursor-pointer">
                  <span>IGL Taktik & Çağrı Bandı</span>
                  <input
                    type="checkbox"
                    checked={showTactics}
                    onChange={(e) => setShowTactics(e.target.checked)}
                    className="accent-[#C82333] w-4 h-4 rounded"
                  />
                </label>
              </div>
            </div>
          </div>

          {/* Streamer Privacy Shield */}
          <div className="p-3.5 rounded-xl bg-[#1C0B10]/60 border border-[#8F1622]/50 flex items-center justify-between gap-3">
            <div className="flex items-center gap-2.5">
              <span className="text-xl">🛡️</span>
              <div>
                <span className="text-xs font-black text-[#FAF2EE] block">
                  Yayıncı Gizlilik Kalkanı (Anti-Stream Snipe)
                </span>
                <span className="text-[10px] text-[#A8989B]">
                  Oda şifreleri, IP adresleri ve davet linkleri yayında asla gösterilmez.
                </span>
              </div>
            </div>
            <button
              type="button"
              onClick={() => setStreamerPrivacyActive((p) => !p)}
              className={`px-3 py-1.5 rounded-lg text-xs font-bold border transition-colors ${
                streamerPrivacyActive
                  ? 'bg-emerald-950 text-emerald-300 border-emerald-500'
                  : 'bg-[#140A0D] text-[#8E7E81] border-[#2C141A]'
              }`}
            >
              {streamerPrivacyActive ? 'Korumalı' : 'Korumasız'}
            </button>
          </div>
        </div>

        {/* Modal Footer */}
        <div className="p-4 border-t border-[#241116] flex items-center justify-end bg-[#0E070A]">
          <button
            type="button"
            onClick={onClose}
            className="px-4 py-2 rounded-xl bg-[#180B10] hover:bg-[#281016] border border-[#3C141E] text-xs font-bold text-[#FAF2EE]"
          >
            Tamam
          </button>
        </div>
      </div>
    </div>
  );
};
