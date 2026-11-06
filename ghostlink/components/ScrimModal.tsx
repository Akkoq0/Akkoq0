'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Ephemeral P2P Scrim Command Modal
// ─────────────────────────────────────────────────────────

import { memo, useState, useCallback, useEffect } from 'react';
import { useAppStore } from '@/lib/store';
import { IconBolt, IconClose, IconShield } from '@/components/ui/MevaIcons';
import type { ScrimRoom } from '@/types';

function generateScrimCode(): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let code = '';
  for (let i = 0; i < 6; i++) {
    code += chars[Math.floor(Math.random() * chars.length)];
  }
  return code;
}

const SCRIM_TTL_MS = 2 * 60 * 60 * 1000;

export const ScrimModal = memo(function ScrimModal() {
  const showModal = useAppStore((s) => s.showScrimModal);
  const activeScrim = useAppStore((s) => s.activeScrimRoom);
  const setShowModal = useAppStore((s) => s.setShowScrimModal);
  const setActiveScrimRoom = useAppStore((s) => s.setActiveScrimRoom);
  const setActiveVoiceChannel = useAppStore((s) => s.setActiveVoiceChannel);

  const [teamName, setTeamName] = useState('');
  const [joinCode, setJoinCode] = useState('');
  const [copied, setCopied] = useState(false);
  const [mode, setMode] = useState<'create' | 'join'>('create');
  const [remainingMin, setRemainingMin] = useState<number>(0);

  useEffect(() => {
    if (!activeScrim) return;
    const calc = () =>
      Math.max(
        0,
        Math.round(
          (activeScrim.created_at + activeScrim.ttl - Date.now()) / 60000,
        ),
      );
    setRemainingMin(calc());
    const id = setInterval(() => setRemainingMin(calc()), 30000);
    return () => clearInterval(id);
  }, [activeScrim]);

  const handleCreate = useCallback(() => {
    const code = generateScrimCode();
    const room: ScrimRoom = {
      code,
      name: teamName.trim() || 'Taktik Scrim',
      created_by: 'usr-local',
      password: null,
      max_participants: 10,
      created_at: Date.now(),
      ttl: SCRIM_TTL_MS,
    };
    setActiveScrimRoom(room);
    setActiveVoiceChannel(`scrim-${code}`);
  }, [teamName, setActiveScrimRoom, setActiveVoiceChannel]);

  const handleJoin = useCallback(() => {
    const clean = joinCode.trim().toUpperCase();
    if (clean.length < 4) return;
    const room: ScrimRoom = {
      code: clean,
      name: `Scrim #${clean}`,
      created_by: 'usr-local',
      password: null,
      max_participants: 10,
      created_at: Date.now(),
      ttl: SCRIM_TTL_MS,
    };
    setActiveScrimRoom(room);
    setActiveVoiceChannel(`scrim-${clean}`);
    setShowModal(false);
  }, [joinCode, setActiveScrimRoom, setActiveVoiceChannel, setShowModal]);

  const handleCopyLink = useCallback(() => {
    if (!activeScrim) return;
    const url = `${window.location.origin}/scrim/${activeScrim.code}`;
    navigator.clipboard?.writeText(url);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  }, [activeScrim]);

  const handleDestroy = useCallback(() => {
    setActiveScrimRoom(null);
    setActiveVoiceChannel(null);
  }, [setActiveScrimRoom, setActiveVoiceChannel]);

  if (!showModal) return null;

  return (
    <div
      className="fixed inset-0 z-50 flex items-end sm:items-center justify-center bg-black/80 p-0 sm:p-4"
      onClick={() => setShowModal(false)}
    >
      <div
        className="w-full max-w-md rounded-none sm:rounded-md bg-[#080A0E] border-t sm:border border-white/[0.08] p-5 sm:p-6 shadow-2xl"
        onClick={(e) => e.stopPropagation()}
      >
        {/* ── Header ── */}
        <div className="flex items-center justify-between border-b border-white/[0.06] pb-4 mb-5">
          <div className="flex items-center gap-3">
            <div className="rounded-sm w-9 h-9 bg-[#0C0E12] border border-white/[0.08] flex items-center justify-center text-gl-accent">
              <IconBolt size={17} />
            </div>
            <div>
              <h2 className="font-mono text-xs font-bold tracking-[0.18em] uppercase text-gl-text-bright">
                GEÇİCİ P2P SCRIM FREKANSI
              </h2>
              <p className="text-[11px] font-mono text-gl-text-muted mt-0.5">
                Kayıtsız · DTLS-SRTP Şifreli Ses Köprüsü
              </p>
            </div>
          </div>
          <button
            onClick={() => setShowModal(false)}
            className="rounded-sm w-9 h-9 bg-[#0C0E12] border border-white/[0.06] flex items-center justify-center text-gl-text-normal hover:text-gl-text-bright"
            aria-label="Kapat"
          >
            <IconClose size={16} />
          </button>
        </div>

        {activeScrim ? (
          <div className="space-y-4">
            <div className="rounded-sm p-4 bg-[#0C0E12] border border-white/[0.08] space-y-3">
              <div className="flex items-center justify-between">
                <span className="text-xs font-mono font-bold text-gl-text-bright uppercase">
                  {activeScrim.name}
                </span>
                <span className="rounded-sm text-[10px] font-mono font-bold px-2 py-0.5 bg-gl-accent text-white">
                  AKTİF
                </span>
              </div>

              <div className="rounded-sm py-3 text-center bg-[#050608] border border-white/[0.06]">
                <p className="text-[10px] font-mono text-gl-text-muted uppercase tracking-widest mb-1">
                  FREKANS ERİŞİM KODU
                </p>
                <p className="text-2xl font-mono font-extrabold tracking-[0.3em] text-gl-accent">
                  {activeScrim.code}
                </p>
              </div>

              <div className="flex items-center justify-between text-[11px] font-mono text-gl-text-muted">
                <span>Kapasite: {activeScrim.max_participants} Operatör</span>
                <span>Kalan: {remainingMin} dk</span>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-2">
              <button
                onClick={handleCopyLink}
                className="rounded-sm min-h-[44px] bg-gl-accent hover:bg-gl-accent-hover text-white text-xs font-mono font-bold tracking-wider transition-colors"
              >
                {copied ? 'KOPYALANDI' : 'LİNKİ KOPYALA'}
              </button>
              <button
                onClick={handleDestroy}
                className="rounded-sm min-h-[44px] bg-[#0C0E12] hover:bg-gl-danger/20 text-gl-danger border border-gl-danger/40 text-xs font-mono font-bold tracking-wider transition-colors"
              >
                SONLANDIR
              </button>
            </div>
          </div>
        ) : (
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-1.5">
              <button
                onClick={() => setMode('create')}
                className={`rounded-sm min-h-[40px] font-mono text-[11px] font-bold uppercase border transition-colors ${
                  mode === 'create'
                    ? 'bg-[#12151C] text-gl-text-bright border-gl-accent/60'
                    : 'bg-[#0C0E12] text-gl-text-muted border-white/[0.05]'
                }`}
              >
                FREKANS AÇ
              </button>
              <button
                onClick={() => setMode('join')}
                className={`rounded-sm min-h-[40px] font-mono text-[11px] font-bold uppercase border transition-colors ${
                  mode === 'join'
                    ? 'bg-[#12151C] text-gl-text-bright border-gl-accent/60'
                    : 'bg-[#0C0E12] text-gl-text-muted border-white/[0.05]'
                }`}
              >
                KOD İLE GİR
              </button>
            </div>

            {mode === 'create' ? (
              <div className="space-y-4">
                <div>
                  <label className="block text-[11px] font-mono font-bold text-gl-text-normal uppercase mb-2">
                    KARŞILAŞMA / ANTRENMAN ADI
                  </label>
                  <input
                    type="text"
                    value={teamName}
                    onChange={(e) => setTeamName(e.target.value)}
                    placeholder="Örn: FUT vs BBL — Ascent"
                    maxLength={40}
                    className="rounded-sm w-full h-11 bg-[#050608] text-xs text-gl-text-bright px-3.5 border border-white/[0.08] focus:outline-none focus:border-gl-accent"
                  />
                </div>

                <div className="rounded-sm p-3 bg-[#0C0E12] border border-white/[0.05] flex items-center gap-2 text-xs font-mono text-gl-text-normal">
                  <IconShield size={14} className="text-gl-accent flex-shrink-0" />
                  <span>Opus 24kbps · 2 saat sonunda otomatik imha</span>
                </div>

                <button
                  onClick={handleCreate}
                  className="rounded-sm w-full min-h-[44px] bg-gl-accent hover:bg-gl-accent-hover text-white font-mono text-xs font-bold tracking-wider uppercase transition-colors"
                >
                  SCRIM FREKANSI ÜRET
                </button>
              </div>
            ) : (
              <div className="space-y-4">
                <div>
                  <label className="block text-[11px] font-mono font-bold text-gl-text-normal uppercase mb-2">
                    6 HANELİ ERİŞİM KODU
                  </label>
                  <input
                    type="text"
                    value={joinCode}
                    onChange={(e) => setJoinCode(e.target.value.toUpperCase())}
                    placeholder="X7K9M2"
                    maxLength={6}
                    className="rounded-sm w-full h-11 bg-[#050608] text-base font-mono font-bold tracking-[0.3em] text-center text-gl-text-bright px-3.5 border border-white/[0.08] focus:outline-none focus:border-gl-accent uppercase"
                  />
                </div>

                <button
                  onClick={handleJoin}
                  disabled={joinCode.trim().length < 4}
                  className="rounded-sm w-full min-h-[44px] bg-gl-accent hover:bg-gl-accent-hover disabled:opacity-40 text-white font-mono text-xs font-bold tracking-wider uppercase transition-colors"
                >
                  FREKANSA BAĞLAN
                </button>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
});
