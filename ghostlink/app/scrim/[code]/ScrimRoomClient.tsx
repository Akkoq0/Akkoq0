// ─────────────────────────────────────────────────────────
// GhostLink — Scrim Room Client Component
// ─────────────────────────────────────────────────────────

'use client';

import { useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { useWebRTC } from '@/hooks/useWebRTC';
import { clsx } from 'clsx';

export default function ScrimRoomClient() {
  const params = useParams();
  const router = useRouter();
  const roomCode = (params?.code as string) || 'demo';

  const [username, setUsername] = useState('');
  const [hasJoined, setHasJoined] = useState(false);

  const {
    participants,
    isMuted,
    isDeafened,
    connectionState,
    netGuard,
    joinVoice,
    leaveVoice,
    toggleMute,
    toggleDeafen,
  } = useWebRTC({
    channelId: `scrim_${roomCode}`,
    userId: 'scrim_usr_' + Math.random().toString(36).substring(7),
    username: username || 'Oyuncu',
    avatarUrl: null,
    isScrim: true,
  });

  const handleEnter = async () => {
    if (!username.trim()) return;
    setHasJoined(true);
    await joinVoice();
  };

  const handleLeaveAndExit = () => {
    leaveVoice();
    router.push('/');
  };

  return (
    <div className="flex h-screen w-screen items-center justify-center bg-gl-bg-darkest p-4">
      <div className="w-full max-w-lg rounded-2xl border border-gl-border bg-gl-bg-panel p-6 shadow-2xl">
        <div className="flex items-center gap-3 pb-4 border-b border-gl-border">
          <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-gl-idle/20 text-gl-idle text-2xl font-bold">
            ⚡
          </div>
          <div>
            <span className="text-xxs uppercase tracking-wider font-bold text-gl-idle">Geçici Scrim Odası</span>
            <h2 className="text-xl font-bold text-gl-text-primary">Oda #{roomCode}</h2>
          </div>
        </div>

        {!hasJoined ? (
          <div className="mt-6 space-y-4">
            <p className="text-sm text-gl-text-secondary leading-relaxed">
              Bu odaya katılmak için hesap oluşturmanız gerekmez. Sadece oyun içi takma adınızı girin ve bağlanın.
            </p>

            <div>
              <label className="block text-xs font-semibold text-gl-text-secondary uppercase tracking-wider mb-1.5">
                Oyun İçi Takma Adın (Nick)
              </label>
              <input
                type="text"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && handleEnter()}
                placeholder="Örn: XANTARES, woxic"
                className="w-full rounded-xl bg-gl-bg-hover px-4 py-3 text-sm text-gl-text-primary placeholder:text-gl-text-muted outline-none border border-gl-border focus:border-gl-accent transition-colors"
                autoFocus
              />
            </div>

            <button
              onClick={handleEnter}
              disabled={!username.trim()}
              className="w-full rounded-xl bg-gl-online hover:bg-emerald-600 py-3 text-sm font-bold text-white transition-all shadow-lg shadow-gl-online/20 disabled:opacity-40"
            >
              Doğrudan Ses Odasına Bağlan
            </button>
          </div>
        ) : (
          <div className="mt-6 space-y-4">
            <div className="flex items-center justify-between rounded-xl bg-gl-bg-darkest p-3 border border-gl-border">
              <div className="flex items-center gap-2">
                <span className="h-2.5 w-2.5 rounded-full bg-gl-online animate-pulse" />
                <span className="text-xs font-bold text-gl-text-primary">
                  {connectionState === 'connected' ? 'P2P Ses İletişimi Aktif' : 'Bağlanıyor...'}
                </span>
              </div>
              <span className="text-xxs font-mono text-gl-text-muted">
                Net-Guard: {netGuard.qualityScore}% ({netGuard.jitterMs}ms)
              </span>
            </div>

            {/* Participants */}
            <div className="rounded-xl bg-gl-bg-hover/40 p-4 border border-gl-border/60">
              <h4 className="text-xs font-bold uppercase tracking-wider text-gl-text-muted mb-2">
                Odadaki Oyuncular ({participants.length})
              </h4>
              <div className="space-y-1.5">
                {participants.map((p) => (
                  <div key={p.user_id} className="flex items-center justify-between text-xs text-gl-text-primary">
                    <span className={clsx('font-semibold', p.is_speaking && 'text-gl-voice-active')}>
                      {p.username} {p.user_id.includes(username) ? '(Sen)' : ''}
                    </span>
                    {p.is_muted && <span className="text-xxs text-gl-dnd">Susturuldu</span>}
                  </div>
                ))}
              </div>
            </div>

            {/* Voice controls */}
            <div className="flex gap-2">
              <button
                onClick={toggleMute}
                className={clsx(
                  'flex-1 rounded-xl py-3 text-xs font-bold transition-all border',
                  isMuted ? 'bg-gl-dnd/20 border-gl-dnd text-gl-dnd' : 'bg-gl-bg-hover border-gl-border text-gl-text-primary'
                )}
              >
                {isMuted ? '🔇 Mikrofon Aç' : '🎤 Sustur'}
              </button>
              <button
                onClick={toggleDeafen}
                className={clsx(
                  'flex-1 rounded-xl py-3 text-xs font-bold transition-all border',
                  isDeafened ? 'bg-gl-dnd/20 border-gl-dnd text-gl-dnd' : 'bg-gl-bg-hover border-gl-border text-gl-text-primary'
                )}
              >
                {isDeafened ? '🚫 Kulaklık Aç' : '🎧 Sağırlaştır'}
              </button>
              <button
                onClick={handleLeaveAndExit}
                className="rounded-xl bg-gl-dnd hover:bg-rose-700 px-5 py-3 text-xs font-bold text-white transition-all"
              >
                Ayrıl
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

