// ─────────────────────────────────────────────────────────
// Meva HUD — Ephemeral Scrim Frequency Room Client
// ─────────────────────────────────────────────────────────

'use client';

import { useMemo, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { useWebRTC } from '@/hooks/useWebRTC';
import { sanitizeScrimCode } from '@/hooks/useScrimLink';
import { OperatorAvatar, SignalBars } from '@/components/ui/HudPrimitives';
import {
  IconBolt,
  IconMic,
  IconMicOff,
  IconHeadphones,
  IconDeafen,
  IconDisconnect,
} from '@/components/ui/MevaIcons';

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

  const sessionUserId = useMemo(() => createSessionUserId(), []);

  const [username, setUsername] = useState('');
  const [hasJoined, setHasJoined] = useState(false);

  const cleanUsername = username
    .replace(/[\u0000-\u001F\u007F]/g, '')
    .trim()
    .slice(0, 24);

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
    <div className="flex h-[100dvh] w-screen items-center justify-center ambient-shell p-4 font-sans tabular-nums">
      <div className="w-full max-w-lg exec-modal rounded-2xl p-6">
        <div className="flex items-center gap-3.5 pb-4 border-b border-[#881A26]/20">
          <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-gradient-to-br from-[#591019]/50 to-[#0C0809] border border-[#881A26]/40 text-[#E35D6A]">
            <IconBolt size={20} />
          </div>
          <div>
            <span className="text-[11px] uppercase tracking-wider font-bold text-[#E35D6A]">
              Geçici P2P Scrim Frekansı
            </span>
            <h1 className="text-lg font-bold text-[#F4EFF0]">
              Frekans{' '}
              <span className="font-mono text-[#F08C96]">#{roomCode}</span>
            </h1>
          </div>
        </div>

        {!hasJoined ? (
          <div className="mt-5 space-y-4">
            <p className="text-xs text-[#B8AAAC] leading-relaxed">
              Hesap açmadan doğrudan DTLS-SRTP şifreli P2P ses frekansına
              bağlanın. Oyun içi çağrı kodunuzu girmeniz yeterlidir.
            </p>

            <div>
              <label className="block text-xs font-semibold text-[#C4B6BA] mb-1.5">
                Operatör Çağrı Adı (Nick)
              </label>
              <input
                type="text"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && handleEnter()}
                placeholder="Örn: XANTARES, cNed, woxic"
                maxLength={24}
                className="w-full rounded-xl bg-[#0A0708] px-3.5 py-2.5 text-sm text-[#F4EFF0] placeholder:text-[#786A6E] outline-none border border-[#881A26]/25 focus:border-[#B51D2C]/65 transition-colors"
                autoFocus
              />
            </div>

            <button
              type="button"
              onClick={handleEnter}
              disabled={cleanUsername.length < 2}
              className="w-full rounded-xl crimson-cta disabled:opacity-40 py-3 text-xs font-bold uppercase tracking-wider transition-all"
            >
              Doğrudan P2P Ses Odasına Bağlan
            </button>
          </div>
        ) : (
          <div className="mt-5 space-y-4">
            <div className="flex items-center justify-between rounded-xl bg-[#0D080A] p-3 border border-[#881A26]/25">
              <div className="flex items-center gap-2.5">
                <span className="h-2 w-2 rounded-full bg-[#C82333] shadow-[0_0_8px_rgba(200,35,51,0.75)]" />
                <span className="text-xs font-bold text-[#F4EFF0]">
                  {connectionState === 'connected'
                    ? 'DTLS-SRTP P2P Ses Aktif'
                    : 'Frekans Kuruluyor...'}
                </span>
              </div>
              <span className="flex items-center gap-2 text-[11px] text-[#ED8793] font-bold">
                <SignalBars score={netGuard.qualityScore} />
                <span>
                  %{netGuard.qualityScore} · {netGuard.jitterMs}ms
                </span>
              </span>
            </div>

            {/* Participants */}
            <div className="rounded-2xl bg-[#11090C]/90 p-4 border border-[#881A26]/25">
              <h2 className="text-xs font-bold uppercase tracking-wider text-[#8E7F83] mb-3">
                Frekans Operatörleri · {participants.length}
              </h2>
              <div className="space-y-1.5">
                {participants.map((p) => (
                  <div
                    key={p.user_id}
                    className="flex items-center justify-between text-xs text-[#F4EFF0] py-2 px-3 rounded-xl bg-[#090608] border border-[#881A26]/20"
                  >
                    <span className="font-semibold flex items-center gap-2.5">
                      <OperatorAvatar
                        name={p.username}
                        size="xs"
                        speaking={p.is_speaking && !p.is_muted}
                        status={p.is_muted ? 'dnd' : 'online'}
                      />
                      <span
                        className={
                          p.is_speaking && !p.is_muted ? 'text-[#F08C96]' : ''
                        }
                      >
                        {p.username}{' '}
                        {p.user_id === sessionUserId ? '(Sen)' : ''}
                      </span>
                    </span>
                    {p.is_muted ? (
                      <span className="text-[10px] font-bold text-[#F08C96]">
                        Sessiz
                      </span>
                    ) : (
                      <span className="text-[10px] font-semibold text-[#E35D6A]">
                        Opus 48kHz
                      </span>
                    )}
                  </div>
                ))}
              </div>
            </div>

            {/* Voice controls */}
            <div className="flex gap-2">
              <button
                type="button"
                onClick={toggleMute}
                className={`flex-1 rounded-xl py-2.5 text-xs font-bold transition-colors border flex items-center justify-center gap-1.5 ${
                  isMuted
                    ? 'bg-[#9E1B24]/25 border-[#9E1B24]/60 text-[#F27A82]'
                    : 'bg-[#1C1215] hover:bg-[#24171B] border-[#382328] text-[#F5EBE6]'
                }`}
              >
                {isMuted ? <IconMicOff size={14} /> : <IconMic size={14} />}
                <span>{isMuted ? 'Sesi Aç' : 'Sustur'}</span>
              </button>
              <button
                type="button"
                onClick={toggleDeafen}
                className={`flex-1 rounded-xl py-2.5 text-xs font-bold transition-colors border flex items-center justify-center gap-1.5 ${
                  isDeafened
                    ? 'bg-[#9E1B24]/25 border-[#9E1B24]/60 text-[#F27A82]'
                    : 'bg-[#1C1215] hover:bg-[#24171B] border-[#382328] text-[#F5EBE6]'
                }`}
              >
                {isDeafened ? (
                  <IconDeafen size={14} />
                ) : (
                  <IconHeadphones size={14} />
                )}
                <span>{isDeafened ? 'Kulaklık Aç' : 'Kulaklık Kapat'}</span>
              </button>
              <button
                type="button"
                onClick={handleLeaveAndExit}
                className="rounded-xl bg-gradient-to-b from-[#AE202A] to-[#87161E] hover:from-[#BF2530] hover:to-[#961922] border border-[#E12D39]/35 px-4 py-2.5 text-xs font-bold text-[#F5EBE6] transition-all flex items-center gap-1.5"
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
