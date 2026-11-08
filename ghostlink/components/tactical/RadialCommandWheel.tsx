'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — IGL Tactical Radial Command Wheel (Bento Radial HUD)
// ─────────────────────────────────────────────────────────
// Quick tactical wheel for in-game squad leads (IGL) to dispatch
// instant squad rotations, site executes, and economy orders.

import React, { useState, useEffect } from 'react';
import { useAppStore } from '@/lib/store';
import { useRealtimeChat } from '@/hooks/useRealtimeChat';
import { playSyntheticEsportsSound } from '@/src/lib/esportsSoundboard';

interface RadialCommandWheelProps {
  isOpen: boolean;
  onClose: () => void;
}

interface CommandItem {
  id: string;
  label: string;
  shortText: string;
  icon: string;
  angle: number; // in degrees
}

const RADIAL_COMMANDS: CommandItem[] = [
  { id: 'a_exec', label: 'A Rush / Execute', shortText: 'A EXECUTE', icon: '🅰️', angle: 0 },
  { id: 'rotate', label: 'Hızlı Rotasyon', shortText: 'ROTATE NOW', icon: '🔄', angle: 45 },
  { id: 'mid_ctrl', label: 'Mid Kontrolü Al', shortText: 'MID CONTROL', icon: '🎯', angle: 90 },
  { id: 'need_drop', label: 'Drop / Silah Lazım', shortText: 'NEED WEAPON', icon: '💰', angle: 135 },
  { id: 'eco_save', label: 'Eko / Silah Sakla', shortText: 'SAVE / ECO', icon: '🛡️', angle: 180 },
  { id: 'fall_back', label: 'Geri Çekilin', shortText: 'FALL BACK', icon: '🏃', angle: 225 },
  { id: 'b_split', label: 'B Split Push', shortText: 'B SPLIT', icon: '🅱️', angle: 270 },
  { id: 'stack_site', label: 'Bölgeyi Stackle', shortText: 'STACK SITE', icon: '🧱', angle: 315 },
];

export const RadialCommandWheel: React.FC<RadialCommandWheelProps> = ({
  isOpen,
  onClose,
}) => {
  const activeChannelId = useAppStore((s) => s.activeChannelId);
  const { sendMessage } = useRealtimeChat(activeChannelId);

  const [hoveredCommand, setHoveredCommand] = useState<CommandItem | null>(null);

  const handleSelectCommand = (cmd: CommandItem) => {
    playSyntheticEsportsSound('tactical_ping', 0.9);
    void sendMessage(`📢 [IGL EMRI]: ${cmd.label.toUpperCase()}! Hızlı pozisyon alın.`);
    onClose();
  };

  useEffect(() => {
    if (!isOpen) return;
    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        onClose();
      }
    };
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  const RADIUS = 140;

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center exec-backdrop font-sans select-none"
      onClick={(e) => {
        e.preventDefault();
        onClose();
      }}
    >
      <div
        className="relative w-[380px] h-[380px] flex items-center justify-center"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Background Outer Ring & Crosshair */}
        <div className="absolute inset-4 rounded-full border border-[#8F1622]/40 bg-[#070607]/85 backdrop-blur-md shadow-[0_0_60px_rgba(200,35,51,0.35)]" />
        <div className="absolute inset-16 rounded-full border border-[#2E151C]" />

        {/* Center Target & Active Label Display */}
        <div
          onClick={onClose}
          className="relative z-20 w-24 h-24 rounded-full bg-[#160B10] border-2 border-[#8F1622] flex flex-col items-center justify-center text-center p-1.5 shadow-2xl cursor-pointer hover:border-[#FF4655] transition-all"
        >
          {hoveredCommand ? (
            <>
              <span className="text-xl">{hoveredCommand.icon}</span>
              <span className="text-[10px] font-black text-white leading-tight uppercase line-clamp-2">
                {hoveredCommand.shortText}
              </span>
            </>
          ) : (
            <>
              <span className="text-base text-[#C82333]">🎯</span>
              <span className="text-[9.5px] font-black text-[#A8989B] uppercase">
                IGL ÇARKI
              </span>
              <span className="text-[8px] text-[#8E7E81]">İptal için tıkla</span>
            </>
          )}
        </div>

        {/* Radial Command Wedges (8 Items around circle) */}
        {RADIAL_COMMANDS.map((cmd) => {
          // Calculate polar position (subtract 90 deg so angle 0 is at Top/North)
          const rad = ((cmd.angle - 90) * Math.PI) / 180;
          const x = RADIUS * Math.cos(rad);
          const y = RADIUS * Math.sin(rad);

          const isHovered = hoveredCommand?.id === cmd.id;

          return (
            <button
              key={cmd.id}
              type="button"
              onMouseEnter={() => {
                setHoveredCommand(cmd);
                playSyntheticEsportsSound('tactical_ping', 0.2);
              }}
              onMouseLeave={() => setHoveredCommand(null)}
              onClick={() => handleSelectCommand(cmd)}
              style={{
                transform: `translate(${x}px, ${y}px)`,
              }}
              className={`absolute z-20 px-2.5 py-1.5 rounded-xl border flex items-center gap-1.5 transition-all duration-150 ${
                isHovered
                  ? 'crimson-cta text-white border-[#FF4655] shadow-[0_0_20px_rgba(200,35,51,0.7)] scale-110'
                  : 'bg-[#12080B] hover:bg-[#1E0C13] border-[#2A1319] text-[#FAF2EE]'
              }`}
            >
              <span className="text-sm">{cmd.icon}</span>
              <span className="text-[10.5px] font-black tracking-tight whitespace-nowrap">
                {cmd.shortText}
              </span>
            </button>
          );
        })}
      </div>
    </div>
  );
};
