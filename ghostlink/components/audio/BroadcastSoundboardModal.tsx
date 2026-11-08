'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Broadcast Soundboard Modal (Zero-Latency WebAudio)
// ─────────────────────────────────────────────────────────

import React, { useState, useEffect, useCallback } from 'react';
import { useAppStore } from '@/lib/store';
import { useRealtimeChat } from '@/hooks/useRealtimeChat';
import {
  ESPORTS_SOUNDS,
  EsportsSoundId,
  playSyntheticEsportsSound,
} from '@/src/lib/esportsSoundboard';
import { IconClose } from '@/components/ui/MevaIcons';

interface BroadcastSoundboardModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const BroadcastSoundboardModal: React.FC<BroadcastSoundboardModalProps> = ({
  isOpen,
  onClose,
}) => {
  const activeChannelId = useAppStore((s) => s.activeChannelId);
  const { sendMessage } = useRealtimeChat(activeChannelId);

  const [volume, setVolume] = useState<number>(0.85);
  const [broadcastToRoom, setBroadcastToRoom] = useState<boolean>(true);
  const [activeTriggerId, setActiveTriggerId] = useState<string | null>(null);

  const handlePlaySound = useCallback(
    (soundId: EsportsSoundId, label: string) => {
      setActiveTriggerId(soundId);
      playSyntheticEsportsSound(soundId, volume);

      if (broadcastToRoom) {
        void sendMessage(`🔊 [ESPOR SESİ]: ${label}`);
      }

      setTimeout(() => {
        setActiveTriggerId(null);
      }, 450);
    },
    [volume, broadcastToRoom, sendMessage],
  );

  // Keyboard shortcut listener (Num 1 - 8)
  useEffect(() => {
    if (!isOpen) return;

    const onKeyDown = (e: KeyboardEvent) => {
      if (e.target instanceof HTMLInputElement || e.target instanceof HTMLTextAreaElement) return;
      const numMatch = e.code.match(/^Numpad([1-8])$/);
      if (numMatch) {
        const idx = parseInt(numMatch[1], 10) - 1;
        const sound = ESPORTS_SOUNDS[idx];
        if (sound) {
          e.preventDefault();
          handlePlaySound(sound.id, sound.label);
        }
      }
    };

    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [isOpen, handlePlaySound]);

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
        className="w-full max-w-xl bg-[#0B0608] border border-[#8F1622] rounded-2xl shadow-[0_24px_80px_rgba(0,0,0,0.95)] flex flex-col overflow-hidden"
        onClick={(e) => {
          e.preventDefault();
          e.stopPropagation();
        }}
      >
        {/* Modal Header */}
        <div className="px-5 py-4 border-b border-[#241116] flex items-center justify-between bg-gradient-to-r from-[#1C0B10] to-[#0B0608]">
          <div className="flex items-center gap-2.5">
            <span className="w-9 h-9 rounded-xl bg-[#8F1622] text-white flex items-center justify-center text-lg font-bold shadow-md">
              🎛️
            </span>
            <div>
              <h2 className="text-sm font-black text-white tracking-wide uppercase">
                Espor Soundboard & Taktik Ses Efektleri
              </h2>
              <p className="text-[11px] text-[#A8989B]">
                Sıfır gecikmeli WebAudio DSP motoru · Numpad 1-8 kısayolları
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
        <div className="p-5 space-y-4">
          {/* Controls Bar */}
          <div className="p-3 rounded-xl bg-[#12080B] border border-[#2E151C] flex flex-wrap items-center justify-between gap-3">
            {/* Volume Slider */}
            <div className="flex items-center gap-2 min-w-[200px]">
              <span className="text-xs">🔊</span>
              <span className="text-[10px] font-black text-[#8E7E81] uppercase tracking-wider">
                SES DÜZEYİ:
              </span>
              <input
                type="range"
                min={0}
                max={1}
                step={0.05}
                value={volume}
                onChange={(e) => setVolume(parseFloat(e.target.value))}
                className="flex-1 accent-[#C82333] h-1.5 bg-[#070406] rounded cursor-pointer"
              />
              <span className="text-[10px] font-mono text-[#F08C96] w-8 text-right">
                %{Math.round(volume * 100)}
              </span>
            </div>

            {/* Broadcast Toggle */}
            <label className="flex items-center gap-2 text-xs text-[#FAF2EE] cursor-pointer">
              <input
                type="checkbox"
                checked={broadcastToRoom}
                onChange={(e) => setBroadcastToRoom(e.target.checked)}
                className="accent-[#C82333] w-4 h-4 rounded"
              />
              <span className="font-bold text-[11px]">
                {broadcastToRoom ? '📢 Odaya Sesli İlet' : '🎧 Sadece Kendime Çal'}
              </span>
            </label>
          </div>

          {/* Soundboard Grid (8 Slots) */}
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-2.5">
            {ESPORTS_SOUNDS.map((sound) => {
              const isTriggered = activeTriggerId === sound.id;
              return (
                <button
                  key={sound.id}
                  type="button"
                  onClick={() => handlePlaySound(sound.id, sound.label)}
                  className={`p-3 rounded-xl border flex flex-col items-center justify-center gap-1.5 transition-all active:scale-95 text-center ${
                    isTriggered
                      ? 'crimson-cta text-white border-[#FF4655] shadow-[0_0_16px_rgba(200,35,51,0.65)] scale-105'
                      : 'bg-[#12080B] hover:bg-[#1C0D12] border-[#2E151C] hover:border-[#8F1622]/60 text-[#F4EFF0]'
                  }`}
                >
                  <span className="text-2xl">{sound.icon}</span>
                  <span className="text-xs font-black line-clamp-1 leading-tight">
                    {sound.label}
                  </span>
                  <span className="text-[9px] font-mono px-1.5 py-0.5 rounded bg-black/50 text-[#F08C96] border border-[#2E151C]">
                    {sound.hotkey}
                  </span>
                </button>
              );
            })}
          </div>
        </div>

        {/* Modal Footer */}
        <div className="p-4 border-t border-[#241116] flex items-center justify-between bg-[#0E070A]">
          <span className="text-[10px] text-[#8E7E81]">
            💡 İpucu: NumPad tuşlarıyla oyun içindeyken sesleri anında çalabilirsiniz.
          </span>
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
