'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Voice VOD Clip Recorder Modal (30s Rolling Buffer)
// ─────────────────────────────────────────────────────────

import React, { useState } from 'react';
import { useAppStore } from '@/lib/store';
import { useRealtimeChat } from '@/hooks/useRealtimeChat';
import { getVoiceClipBuffer } from '@/src/lib/voiceClipRecorder';
import { playSyntheticEsportsSound } from '@/src/lib/esportsSoundboard';
import { IconClose } from '@/components/ui/MevaIcons';

interface VoiceClipBufferModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const VoiceClipBufferModal: React.FC<VoiceClipBufferModalProps> = ({
  isOpen,
  onClose,
}) => {
  const activeChannelId = useAppStore((s) => s.activeChannelId);
  const { sendMessage } = useRealtimeChat(activeChannelId);

  const [selectedSeconds, setSelectedSeconds] = useState<number>(30);
  const [downloadUrl, setDownloadUrl] = useState<string | null>(null);
  const [isExporting, setIsExporting] = useState<boolean>(false);
  const [toastMsg, setToastMsg] = useState<string | null>(null);

  const handleExportClip = () => {
    setIsExporting(true);
    setToastMsg(null);

    try {
      const buffer = getVoiceClipBuffer();
      const wavBlob = buffer.exportLastSecondsToWav(selectedSeconds);
      const url = URL.createObjectURL(wavBlob);
      setDownloadUrl(url);

      playSyntheticEsportsSound('tactical_ping', 0.8);

      // Trigger instant browser download
      const a = document.createElement('a');
      a.href = url;
      a.download = `Meva-Clutch-Clip-${selectedSeconds}s-${Date.now().toString(36)}.wav`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);

      setToastMsg(`✓ Son ${selectedSeconds} saniyelik ses klibi başarıyla indirildi.`);

      void sendMessage(`🎙️ [SES KLİBİ]: Son ${selectedSeconds} saniyelik takım iletişimi klip olarak kaydedildi.`);
    } catch (err) {
      console.error('[VoiceClip] Failed to export clip:', err);
    } finally {
      setIsExporting(false);
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
        className="w-full max-w-lg bg-[#0B0608] border border-[#8F1622] rounded-2xl shadow-[0_24px_80px_rgba(0,0,0,0.95)] flex flex-col overflow-hidden"
        onClick={(e) => {
          e.preventDefault();
          e.stopPropagation();
        }}
      >
        {/* Header */}
        <div className="px-5 py-4 border-b border-[#241116] flex items-center justify-between bg-gradient-to-r from-[#1C0B10] to-[#0B0608]">
          <div className="flex items-center gap-2.5">
            <span className="w-9 h-9 rounded-xl bg-[#8F1622] text-white flex items-center justify-center text-lg font-bold shadow-md">
              🎙️
            </span>
            <div>
              <h2 className="text-sm font-black text-white tracking-wide uppercase">
                Canlı Ses Klibi & VOD Replay (Buffer)
              </h2>
              <p className="text-[11px] text-[#A8989B]">
                Clutch anları ve önemli taktik komutları son 30-60 saniyeden klipleyin
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
        <div className="p-5 space-y-4">
          {/* Buffer Status Banner */}
          <div className="p-3.5 rounded-xl bg-[#12080B] border border-[#2E151C] flex items-center justify-between">
            <div className="flex items-center gap-2">
              <span className="w-2.5 h-2.5 rounded-full bg-emerald-500 animate-pulse" />
              <span className="text-xs font-black text-[#FAF2EE]">
                Döngüsel Ses Tamponu Aktif
              </span>
            </div>
            <span className="text-[10px] font-mono text-[#F08C96] px-2 py-0.5 rounded bg-black/60 border border-[#2E151C]">
              48kHz · 16-Bit PCM
            </span>
          </div>

          {/* Clip Duration Selector */}
          <div className="space-y-1.5">
            <span className="text-[10px] font-black text-[#8E7E81] uppercase tracking-wider block">
              KLİP UZUNLUĞU SEÇİN
            </span>
            <div className="grid grid-cols-3 gap-2">
              {[15, 30, 60].map((sec) => (
                <button
                  key={sec}
                  type="button"
                  onClick={() => setSelectedSeconds(sec)}
                  className={`py-3 rounded-xl text-xs font-black flex flex-col items-center justify-center gap-1 border transition-all ${
                    selectedSeconds === sec
                      ? 'crimson-cta text-white border-[#FF4655] shadow-md scale-102'
                      : 'bg-[#12080B] text-[#9E8E91] hover:text-white border-[#241116]'
                  }`}
                >
                  <span className="text-base">{sec === 15 ? '⚡' : sec === 30 ? '🔥' : '🎬'}</span>
                  <span>Son {sec} Saniye</span>
                </button>
              ))}
            </div>
          </div>

          {/* Action Trigger Button */}
          <button
            type="button"
            disabled={isExporting}
            onClick={handleExportClip}
            className="w-full py-3 rounded-xl crimson-cta text-xs font-black text-white flex items-center justify-center gap-2 shadow-[0_0_20px_rgba(200,35,51,0.5)] active:scale-98 transition-all"
          >
            <span>💾</span>
            <span>
              {isExporting ? 'Klip Paketleniyor...' : `Son ${selectedSeconds} Saniyelik Klibi Çıkar (.WAV)`}
            </span>
          </button>

          {/* Audio Preview if generated */}
          {downloadUrl && (
            <div className="p-3 rounded-xl bg-[#070406] border border-[#2E151C] space-y-2">
              <span className="text-[10px] font-black text-emerald-400 uppercase tracking-wider block">
                ÖNİZLEME OYNATICI
              </span>
              <audio controls src={downloadUrl} className="w-full h-8" />
            </div>
          )}

          {toastMsg && (
            <div className="p-2.5 rounded-lg bg-emerald-950/80 border border-emerald-500/50 text-[11px] font-bold text-emerald-300 text-center">
              {toastMsg}
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="p-4 border-t border-[#241116] flex items-center justify-end bg-[#0E070A]">
          <button
            type="button"
            onClick={onClose}
            className="px-4 py-2 rounded-xl bg-[#180B10] hover:bg-[#281016] border border-[#3C141E] text-xs font-bold text-[#FAF2EE]"
          >
            Kapat
          </button>
        </div>
      </div>
    </div>
  );
};
