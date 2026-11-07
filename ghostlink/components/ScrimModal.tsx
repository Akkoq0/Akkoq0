'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Ephemeral P2P Scrim Command Modal (CSPRNG)
// ─────────────────────────────────────────────────────────

import { memo, useState, useCallback, useEffect, useRef } from 'react';
import { useAppStore } from '@/lib/store';
import {
  generateSecureScrimCode,
  sanitizeScrimCode,
} from '@/hooks/useScrimLink';
import { IconBolt, IconClose, IconShield } from '@/components/ui/MevaIcons';
import type { ScrimRoom } from '@/types';

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
  const copyTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    return () => {
      if (copyTimerRef.current) clearTimeout(copyTimerRef.current);
    };
  }, []);

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
    const code = generateSecureScrimCode(6);
    const cleanName =
      teamName.replace(/[\u0000-\u001F\u007F]/g, '').trim().slice(0, 40) ||
      'Taktik Scrim';

    const room: ScrimRoom = {
      code,
      name: cleanName,
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
    const clean = sanitizeScrimCode(joinCode).toUpperCase();
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

  const handleCopyLink = useCallback(async () => {
    if (!activeScrim) return;
    const safeCode = sanitizeScrimCode(activeScrim.code);
    const url = `${window.location.origin}/scrim/${encodeURIComponent(safeCode)}`;
    try {
      await navigator.clipboard?.writeText(url);
      setCopied(true);
      if (copyTimerRef.current) clearTimeout(copyTimerRef.current);
      copyTimerRef.current = setTimeout(() => setCopied(false), 2000);
    } catch {
      // Ignore clipboard permission rejection in restricted WebViews
    }
  }, [activeScrim]);

  const handleDestroy = useCallback(() => {
    setActiveScrimRoom(null);
    setActiveVoiceChannel('ch-4');
  }, [setActiveScrimRoom, setActiveVoiceChannel]);

  if (!showModal) return null;

  return (
    <div
      className="fixed inset-0 z-50 flex items-end sm:items-center justify-center exec-backdrop p-0 sm:p-4 font-sans tabular-nums"
      onClick={() => setShowModal(false)}
    >
      <div
        className="w-full max-w-md rounded-t-2xl sm:rounded-2xl exec-modal p-5 sm:p-6"
        onClick={(e) => e.stopPropagation()}
      >
        {/* ── Header ── */}
        <div className="flex items-center justify-between border-b border-[#881A26]/20 pb-4 mb-5">
          <div className="flex items-center gap-3">
            <div className="rounded-xl w-10 h-10 bg-gradient-to-br from-[#591019]/50 to-[#0C0809] border border-[#881A26]/40 flex items-center justify-center text-[#E35D6A]">
              <IconBolt size={18} />
            </div>
            <div>
              <h2 className="text-sm font-bold tracking-tight text-[#F4EFF0]">
                Geçici P2P Scrim Frekansı
              </h2>
              <p className="text-xs text-[#8E7F83] mt-0.5">
                Kayıtsız · DTLS-SRTP Şifreli Ses Köprüsü
              </p>
            </div>
          </div>
          <button
            type="button"
            onClick={() => setShowModal(false)}
            className="rounded-xl w-9 h-9 bg-[#120A0D] hover:bg-[#1B0D12] border border-[#881A26]/25 flex items-center justify-center text-[#9E8F93] hover:text-[#F4EFF0] transition-colors"
            aria-label="Kapat"
          >
            <IconClose size={16} />
          </button>
        </div>

        {activeScrim ? (
          <div className="space-y-4">
            <div className="rounded-2xl p-4 bg-[#11090C]/90 border border-[#881A26]/25 space-y-3.5">
              <div className="flex items-center justify-between">
                <span className="text-xs font-bold text-[#F4EFF0]">
                  {activeScrim.name}
                </span>
                <span className="rounded-full text-[10px] font-bold px-2.5 py-0.5 bg-[#7A121D]/30 text-[#F08C96] border border-[#A61B29]/45">
                  CANLI FREKANS
                </span>
              </div>

              <div className="rounded-xl py-3.5 text-center bg-[#090608] border border-[#881A26]/20">
                <p className="text-[10px] font-semibold text-[#8E7F83] uppercase tracking-wider mb-1">
                  Frekans Erişim Kodu
                </p>
                <p className="text-2xl font-mono font-extrabold tracking-[0.28em] text-[#F08C96]">
                  {activeScrim.code}
                </p>
              </div>

              <div className="flex items-center justify-between text-xs text-[#8E7F83]">
                <span>
                  Kapasite:{' '}
                  <strong className="text-[#F4EFF0]">
                    {activeScrim.max_participants}
                  </strong>{' '}
                  Operatör
                </span>
                <span>
                  Otomatik İmha:{' '}
                  <strong className="text-[#ED8793]">{remainingMin} dk</strong>
                </span>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-2">
              <button
                type="button"
                onClick={handleCopyLink}
                className="rounded-xl min-h-[44px] crimson-cta text-xs font-bold tracking-wide transition-all"
              >
                {copied ? 'Link Kopyalandı' : 'Davet Linkini Kopyala'}
              </button>
              <button
                type="button"
                onClick={handleDestroy}
                className="rounded-xl min-h-[44px] bg-[#120A0D] hover:bg-[#7A121D]/25 text-[#F08C96] border border-[#881A26]/40 text-xs font-bold tracking-wide transition-colors"
              >
                Frekansı Sonlandır
              </button>
            </div>
          </div>
        ) : (
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-1.5 p-1 rounded-xl bg-[#0A0708] border border-[#881A26]/20">
              <button
                type="button"
                onClick={() => setMode('create')}
                className={`rounded-lg min-h-[38px] text-xs font-bold transition-all ${
                  mode === 'create'
                    ? 'bg-gradient-to-b from-[#2A0E15] to-[#13090C] text-[#F4EFF0] border border-[#881A26]/40'
                    : 'text-[#8E7F83] hover:text-[#F4EFF0] border border-transparent'
                }`}
              >
                Frekans Aç
              </button>
              <button
                type="button"
                onClick={() => setMode('join')}
                className={`rounded-lg min-h-[38px] text-xs font-bold transition-all ${
                  mode === 'join'
                    ? 'bg-gradient-to-b from-[#2A0E15] to-[#13090C] text-[#F4EFF0] border border-[#881A26]/40'
                    : 'text-[#8E7F83] hover:text-[#F4EFF0] border border-transparent'
                }`}
              >
                Kod ile Gir
              </button>
            </div>

            {mode === 'create' ? (
              <div className="space-y-4">
                <div>
                  <label className="block text-xs font-semibold text-[#C4B6BA] mb-2">
                    Karşılaşma / Antrenman Adı
                  </label>
                  <input
                    type="text"
                    value={teamName}
                    onChange={(e) => setTeamName(e.target.value)}
                    placeholder="Örn: FUT vs BBL — Ascent"
                    maxLength={40}
                    className="rounded-xl w-full h-11 bg-[#0A0708] text-xs text-[#F4EFF0] placeholder:text-[#786A6E] px-3.5 border border-[#881A26]/25 focus:outline-none focus:border-[#B51D2C]/65 transition-colors"
                  />
                </div>

                <div className="rounded-xl p-3 bg-[#11090C]/90 border border-[#881A26]/20 flex items-center gap-2.5 text-xs text-[#C4B6BA]">
                  <IconShield
                    size={15}
                    className="text-[#E35D6A] flex-shrink-0"
                  />
                  <span>Opus 48kHz / 96kbps · 2 saat sonunda otomatik imha</span>
                </div>

                <button
                  type="button"
                  onClick={handleCreate}
                  className="rounded-xl w-full min-h-[44px] crimson-cta text-xs font-bold tracking-wide transition-all"
                >
                  Scrim Frekansı Üret
                </button>
              </div>
            ) : (
              <div className="space-y-4">
                <div>
                  <label className="block text-xs font-semibold text-[#C4B6BA] mb-2">
                    6 Haneli Scrim Erişim Kodu
                  </label>
                  <input
                    type="text"
                    value={joinCode}
                    onChange={(e) =>
                      setJoinCode(sanitizeScrimCode(e.target.value).toUpperCase())
                    }
                    placeholder="ÖRN: A7K9X2"
                    maxLength={8}
                    className="rounded-xl w-full h-12 bg-[#0A0708] text-center font-mono text-lg font-bold tracking-[0.28em] text-[#F08C96] placeholder:text-[#6E5F63] placeholder:tracking-normal placeholder:text-xs px-3.5 border border-[#881A26]/25 focus:outline-none focus:border-[#B51D2C]/65 transition-colors"
                  />
                </div>

                <button
                  type="button"
                  onClick={handleJoin}
                  disabled={sanitizeScrimCode(joinCode).length < 4}
                  className="rounded-xl w-full min-h-[44px] crimson-cta disabled:opacity-40 text-xs font-bold tracking-wide transition-all"
                >
                  Frekansa Bağlan
                </button>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
});
