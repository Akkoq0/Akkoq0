// ─────────────────────────────────────────────────────────
// Meva HUD — Ephemeral Scrim Frequency Room Client
// ─────────────────────────────────────────────────────────

'use client';

import { useMemo, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { useWebRTC } from '@/hooks/useWebRTC';
import { sanitizeScrimCode } from '@/hooks/useScrimLink';
import {
  IconBolt,
  IconMic,
  IconMicOff,
  IconHeadphones,
  IconDeafen,
  IconDisconnect,
} from '@/components/ui/MevaIcons';
import { clsx } from 'clsx';

function createSessionUserId(): string {
  if (typeof crypto !== 'undefined' && 'randomUUID' in crypto) {
    return `scrim_${crypto.randomUUID().slice(0, 12)}`;
  }
  return `scrim_${Date.now().toString(36)}`;
}

export default function ScrimRoomClient() {
  const params = useParams();
  const router = useRouter();
  const rawCode = typeof params?.code === 'string' ? params.code : 'DEMO';
  const roomCode = sanitizeScrimCode(rawCode).toUpperCase() || 'DEMO';

  // Stable CSPRNG user ID across re-renders
  const sessionUserId = useMemo(() => createSessionUserId(), []);

  const [username, setUsername] = useState('');
  const [hasJoined, setHasJoined] = useState(false);

  const cleanUsername = username
    .replace(/[\u0000-\u001F\u007F]/g, '')
    .trim()
    .slice(0, 24);

  // Only pass channelId once the operator explicitly joins
  const {
    participants,
    isMuted,
    isDeafened,
    connectionState,
    netGuard,
    leaveVoice,
    toggleMute,
    toggleDeafen,
  } = useWebRTC({
    channelId: hasJoined ? `scrim_${roomCode}` : '',
    userId: sessionUserId,
    username: cleanUsername || 'Operatör',
    avatarUrl: null,
    isScrim: true,
  });

  const handleEnter = () => {
    if (cleanUsername.length < 2) return;
    setHasJoined(true);
  };

  const handleLeaveAndExit = () => {
    leaveVoice();
    setHasJoined(false);
    router.push('/');
  };

  return (
    <div className="flex h-[100dvh] w-screen items-center justify-center bg-[#06070A] p-4 font-sans">
      <div className="w-full max-w-lg titanium-module hud-corners rounded-sm p-6 shadow-2xl">
        <div className="flex items-center gap-3.5 pb-4 border-b border-white/[0.06]">
          <div className="flex h-11 w-11 items-center justify-center rounded-sm bg-[#12151E] border border-[#F59E0B]/40 text-[#F59E0B]">
            <IconBolt size={20} />
          </div>
          <div>
            <span className="text-[11px] uppercase tracking-wider font-bold text-[#F59E0B]">
              Geçici P2P Scrim Frekansı
            </span>
            <h1 className="text-lg font-bold text-gl-text-bright">
              Oda{' '}
              <span className="font-mono text-[#10B981]">#{roomCode}</span>
            </h1>
          </div>
        </div>

        {!hasJoined ? (
          <div className="mt-5 space-y-4">
            <p className="text-xs text-gl-text-secondary leading-relaxed">
              Hesap açmadan doğrudan şifreli P2P ses frekansına bağlanın. Oyun
              içi çağrı kodunuzu (nick) girmeniz yeterlidir.
            </p>

            <div>
              <label className="block text-xs font-semibold text-gl-text-secondary mb-1.5">
                Operatör Çağrı Adı (Nick)
              </label>
              <input
                type="text"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && handleEnter()}
                placeholder="Örn: XANTARES, cNed, woxic"
                maxLength={24}
                className="w-full rounded-sm bg-[#06070A] px-3.5 py-2.5 text-sm text-gl-text-bright placeholder:text-gl-text-muted outline-none border border-white/[0.08] focus:border-[#F59E0B] transition-colors"
                autoFocus
              />
            </div>

            <button
              onClick={handleEnter}
              disabled={cleanUsername.length < 2}
              className="w-full rounded-sm bg-[#EF4444] hover:bg-[#F87171] py-3 text-xs font-bold uppercase tracking-wider text-white transition-colors disabled:opacity-40"
            >
              Doğrudan P2P Ses Odasına Bağlan
            </button>
          </div>
        ) : (
          <div className="mt-5 space-y-4">
            <div className="flex items-center justify-between rounded-sm bg-[#06070A] p-3 border border-white/[0.06]">
              <div className="flex items-center gap-2">
                <span className="h-2 w-2 rounded-full bg-[#10B981] animate-pulse" />
                <span className="text-xs font-bold text-gl-text-bright">
                  {connectionState === 'connected'
                    ? 'DTLS-SRTP P2P Ses Aktif'
                    : 'Frekans Kuruluyor...'}
                </span>
              </div>
              <span className="text-[11px] font-mono text-[#10B981] font-bold">
                %{netGuard.qualityScore} · {netGuard.jitterMs}ms
              </span>
            </div>

            {/* Participants */}
            <div className="rounded-sm bg-[#06070A]/80 p-4 border border-white/[0.06]">
              <h2 className="text-xs font-bold uppercase tracking-wider text-gl-text-muted mb-2.5">
                Frekans Operatörleri (
                <span className="font-mono">{participants.length}</span>)
              </h2>
              <div className="space-y-1.5">
                {participants.map((p) => (
                  <div
                    key={p.user_id}
                    className="flex items-center justify-between text-xs text-gl-text-bright py-1 px-2 rounded-sm bg-[#0C0E14] border border-white/[0.04]"
                  >
                    <span
                      className={clsx(
                        'font-semibold flex items-center gap-2',
                        p.is_speaking && 'text-[#10B981]',
                      )}
                    >
                      <span
                        className={clsx(
                          'w-1.5 h-1.5 rounded-full',
                          p.is_muted
                            ? 'bg-[#EF4444]'
                            : p.is_speaking
                              ? 'bg-[#10B981]'
                              : 'bg-[#F59E0B]',
                        )}
                      />
                      <span>
                        {p.username}{' '}
                        {p.user_id === sessionUserId ? '(Sen)' : ''}
                      </span>
                    </span>
                    {p.is_muted && (
                      <span className="text-[10px] font-bold text-[#EF4444]">
                        SUSTURULDU
                      </span>
                    )}
                  </div>
                ))}
              </div>
            </div>

            {/* Voice controls */}
            <div className="flex gap-2">
              <button
                onClick={toggleMute}
                className={clsx(
                  'flex-1 rounded-sm py-2.5 text-xs font-bold transition-colors border flex items-center justify-center gap-1.5',
                  isMuted
                    ? 'bg-[#EF4444]/15 border-[#EF4444]/50 text-[#EF4444]'
                    : 'bg-[#0C0E14] border-white/[0.08] text-gl-text-bright',
                )}
              >
                {isMuted ? <IconMicOff size={14} /> : <IconMic size={14} />}
                <span>{isMuted ? 'Sesi Aç' : 'Sustur'}</span>
              </button>
              <button
                onClick={toggleDeafen}
                className={clsx(
                  'flex-1 rounded-sm py-2.5 text-xs font-bold transition-colors border flex items-center justify-center gap-1.5',
                  isDeafened
                    ? 'bg-[#EF4444]/15 border-[#EF4444]/50 text-[#EF4444]'
                    : 'bg-[#0C0E14] border-white/[0.08] text-gl-text-bright',
                )}
              >
                {isDeafened ? (
                  <IconDeafen size={14} />
                ) : (
                  <IconHeadphones size={14} />
                )}
                <span>{isDeafened ? 'Kulaklık Aç' : 'Sağırlaştır'}</span>
              </button>
              <button
                onClick={handleLeaveAndExit}
                className="rounded-sm bg-[#EF4444] hover:bg-[#F87171] px-4 py-2.5 text-xs font-bold text-white transition-colors flex items-center gap-1.5"
              >
                <IconDisconnect size={14} />
                <span>Ayrıl</span>
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
