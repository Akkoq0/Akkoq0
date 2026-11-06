// ─────────────────────────────────────────────────────────
// GhostLink — Voice Panel v2 (Net-Guard & Tactical VAD & Members)
// ─────────────────────────────────────────────────────────

'use client';

import { memo, useMemo } from 'react';
import { clsx } from 'clsx';
import { useAppStore } from '@/lib/store';
import { useWebRTC } from '@/hooks/useWebRTC';
import { useAuth } from '@/hooks/useAuth';
import { useHUDStore } from '@/store/useHUDStore';
import type { VoicePresence, Profile, UserStatus } from '@/types';

// ─── Status indicator dot ───────────────────────────────

const STATUS_COLORS: Record<UserStatus, string> = {
  'online': 'bg-gl-online',
  'in-game': 'bg-purple-500',
  'idle': 'bg-gl-idle',
  'dnd': 'bg-gl-dnd',
  'offline': 'bg-gray-500',
};

// ─── Single Participant in Voice (memoized) ─────────────

function ParticipantRow({ participant }: { participant: VoicePresence }) {
  const openHUD = useHUDStore((s) => s.openHUD);

  const handleOpen = () => {
    openHUD({
      id: participant.user_id,
      username: participant.username,
      avatar_url: participant.avatar_url,
      status: 'online',
      activity: '🏆 Sesli İletişim',
      created_at: new Date().toISOString(),
    });
  };

  return (
    <div
      onClick={handleOpen}
      className="flex items-center gap-2 rounded-md px-2 py-1.5 transition-colors hover:bg-gl-bg-hover/30 cursor-pointer"
      title="Taktik Oyuncu Künyesini Aç"
    >
      <div
        className={clsx(
          'relative h-8 w-8 flex-shrink-0 rounded-full bg-gl-bg-mid transition-all',
          participant.is_speaking && 'ring-2 ring-gl-voice-active animate-pulse-voice',
        )}
      >
        {participant.avatar_url ? (
          <img
            src={participant.avatar_url}
            alt={participant.username}
            className="h-full w-full rounded-full object-cover"
            loading="lazy"
          />
        ) : (
          <span className="flex h-full w-full items-center justify-center text-xs font-bold text-gl-text-secondary">
            {participant.username[0]?.toUpperCase()}
          </span>
        )}
      </div>

      <div className="flex-1 min-w-0">
        <span
          className={clsx(
            'truncate text-xs block',
            participant.is_speaking
              ? 'font-bold text-gl-voice-active'
              : 'text-gl-text-secondary font-medium',
          )}
        >
          {participant.username}
        </span>
      </div>

      {participant.is_muted && (
        <span className="text-gl-dnd text-xs" title="Mikrofon Kapalı">🔇</span>
      )}
      {participant.is_deafened && (
        <span className="text-gl-dnd text-xs" title="Sağırlaştırıldı">🚫</span>
      )}
    </div>
  );
}

const MemoizedParticipantRow = memo(ParticipantRow);

// ─── Online Member Row (memoized) ───────────────────────

function MemberRow({ member }: { member: Profile }) {
  const openHUD = useHUDStore((s) => s.openHUD);

  return (
    <div
      onClick={() => openHUD(member)}
      className="group flex items-center gap-2.5 rounded-lg px-2 py-1.5 transition-colors hover:bg-gl-bg-hover/40 cursor-pointer"
      title="Taktik Oyuncu Künyesini Aç"
    >
      <div className="relative h-8 w-8 flex-shrink-0">
        <div className="h-8 w-8 rounded-full bg-gl-bg-panel overflow-hidden border border-gl-border">
          {member.avatar_url ? (
            <img src={member.avatar_url} alt="" className="h-full w-full object-cover" />
          ) : (
            <span className="flex h-full w-full items-center justify-center text-xs font-semibold text-gl-text-muted">
              {member.username[0]?.toUpperCase()}
            </span>
          )}
        </div>
        <span
          className={clsx(
            'absolute -bottom-0.5 -right-0.5 h-3 w-3 rounded-full border-2 border-gl-bg-dark',
            STATUS_COLORS[member.status],
          )}
        />
      </div>

      <div className="min-w-0 flex-1">
        <p className="truncate text-xs font-semibold text-gl-text-primary group-hover:text-white">
          {member.username}
        </p>
        {member.activity ? (
          <p className="truncate text-xxs text-purple-400 font-medium">
            🎮 {member.activity}
          </p>
        ) : (
          <p className="truncate text-xxs text-gl-text-muted capitalize">
            {member.status === 'in-game' ? 'Oyunda' : member.status === 'online' ? 'Çevrimiçi' : 'Boşta'}
          </p>
        )}
      </div>
    </div>
  );
}

const MemoizedMemberRow = memo(MemberRow);

// ─── Main Voice Panel ───────────────────────────────────

export function VoicePanel() {
  const activeVoiceChannelId = useAppStore((s) => s.activeVoiceChannelId);
  const channels = useAppStore((s) => s.channels);
  const onlineMembers = useAppStore((s) => s.onlineMembers);
  const ecoMode = useAppStore((s) => s.ecoMode);
  const { user, profile } = useAuth();

  const voiceChannelName =
    channels.find((c) => c.id === activeVoiceChannelId)?.name ?? 'Ses Kanalı';

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
    channelId: activeVoiceChannelId ?? '',
    userId: user?.id ?? 'guest_player',
    username: profile?.username ?? 'Esporcu',
    avatarUrl: profile?.avatar_url ?? null,
  });

  // Group members by status
  const inGameMembers = useMemo(() => onlineMembers.filter((m) => m.status === 'in-game'), [onlineMembers]);
  const activeMembers = useMemo(() => onlineMembers.filter((m) => m.status === 'online'), [onlineMembers]);
  const idleMembers = useMemo(() => onlineMembers.filter((m) => m.status === 'idle' || m.status === 'dnd'), [onlineMembers]);

  return (
    <aside className="flex w-64 flex-shrink-0 flex-col bg-gl-bg-dark border-l border-gl-border">
      {/* ── Active Voice HUD (If channel is selected) ── */}
      {activeVoiceChannelId ? (
        <div className="border-b border-gl-border bg-gl-bg-panel/40 p-3">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <span className="text-base text-gl-online">🔊</span>
              <div>
                <h4 className="text-xs font-bold text-gl-text-primary truncate max-w-[120px]">
                  {voiceChannelName}
                </h4>
                <p className="text-xxs text-gl-text-muted">P2P Ultra-Mesh Ses</p>
              </div>
            </div>

            <span
              className={clsx(
                'rounded-full px-2 py-0.5 text-xxs font-bold uppercase',
                connectionState === 'connected' ? 'bg-gl-online/20 text-gl-online' : 'bg-gl-idle/20 text-gl-idle',
              )}
            >
              {connectionState === 'connected' ? 'Bağlı' : 'Bekliyor'}
            </span>
          </div>

          {/* ⚡ Innovation #3: Tactical VAD & Net-Guard HUD */}
          {connectionState === 'connected' && (
            <div className="mt-2.5 rounded-lg bg-gl-bg-darkest/90 p-2 border border-gl-border/70 space-y-1.5">
              <div className="flex items-center justify-between text-xxs">
                <span className="text-gl-text-muted font-medium flex items-center gap-1">
                  🛡️ Net-Guard:
                </span>
                <span className={clsx(
                  'font-bold',
                  netGuard.qualityScore >= 80 ? 'text-gl-online' : netGuard.qualityScore >= 50 ? 'text-gl-idle' : 'text-gl-dnd'
                )}>
                  {netGuard.qualityLabel} ({netGuard.qualityScore}%)
                </span>
              </div>

              <div className="grid grid-cols-3 gap-1 text-center pt-1 border-t border-gl-border/30">
                <div className="rounded bg-gl-bg-hover/40 py-1">
                  <div className="text-xxs text-gl-text-muted">Jitter</div>
                  <div className="text-xs font-mono font-bold text-gl-text-primary">{netGuard.jitterMs}ms</div>
                </div>
                <div className="rounded bg-gl-bg-hover/40 py-1">
                  <div className="text-xxs text-gl-text-muted">Kayıp</div>
                  <div className="text-xs font-mono font-bold text-gl-text-primary">{netGuard.packetLossPercent}%</div>
                </div>
                <div className="rounded bg-gl-bg-hover/40 py-1">
                  <div className="text-xxs text-gl-text-muted">Buffer</div>
                  <div className="text-xs font-mono font-bold text-gl-text-primary">{netGuard.bufferSizeMs}ms</div>
                </div>
              </div>
            </div>
          )}

          {/* Voice Channel Active Users */}
          <div className="mt-2.5 space-y-0.5">
            <div className="text-xxs uppercase tracking-wider font-bold text-gl-text-muted px-1">
              Odadakiler ({participants.length})
            </div>
            {participants.length === 0 ? (
              <p className="text-xxs text-gl-text-muted italic px-1 py-1">Oda boş. İlk bağlanan sen ol!</p>
            ) : (
              participants.map((p) => <MemoizedParticipantRow key={p.user_id} participant={p} />)
            )}
          </div>

          {/* Voice Controls */}
          <div className="mt-3 pt-2.5 border-t border-gl-border/60">
            {connectionState === 'idle' ? (
              <button
                onClick={joinVoice}
                className="w-full rounded-lg bg-gl-online hover:bg-emerald-600 py-2 text-xs font-bold text-white transition-all shadow-md shadow-gl-online/20"
              >
                Sese Bağlan
              </button>
            ) : (
              <div className="flex items-center gap-1.5">
                <button
                  onClick={toggleMute}
                  className={clsx(
                    'flex-1 rounded-lg py-1.5 text-xs font-bold transition-all border',
                    isMuted
                      ? 'bg-gl-dnd/20 border-gl-dnd text-gl-dnd'
                      : 'bg-gl-bg-hover border-gl-border text-gl-text-primary hover:bg-gl-bg-active',
                  )}
                >
                  {isMuted ? '🔇 Susturuldu' : '🎤 Açık'}
                </button>

                <button
                  onClick={toggleDeafen}
                  className={clsx(
                    'flex-1 rounded-lg py-1.5 text-xs font-bold transition-all border',
                    isDeafened
                      ? 'bg-gl-dnd/20 border-gl-dnd text-gl-dnd'
                      : 'bg-gl-bg-hover border-gl-border text-gl-text-primary hover:bg-gl-bg-active',
                  )}
                >
                  {isDeafened ? '🚫 Sağır' : '🎧 Duyuyor'}
                </button>

                <button
                  onClick={leaveVoice}
                  className="rounded-lg bg-gl-dnd hover:bg-rose-700 px-3 py-1.5 text-xs font-bold text-white transition-all"
                  title="Ayrıl"
                >
                  ✕
                </button>
              </div>
            )}
          </div>
        </div>
      ) : null}

      {/* ── Discord-Style Member List ── */}
      <div className="flex-1 overflow-y-auto px-3 py-3 scrollbar-none space-y-4">
        {/* Game Boost Live Indicator (Innovation #1) */}
        {ecoMode.isActive && (
          <div className="rounded-lg bg-gl-online/10 border border-gl-online/30 p-2.5">
            <div className="flex items-center justify-between text-xxs font-bold text-gl-online">
              <span>⚡ GAME-BOOST AKTİF</span>
              <span>&lt; 1% CPU</span>
            </div>
            <p className="text-xxs text-gl-text-muted mt-1 leading-tight">
              Oyun pencereniz odakta. GhostLink arka planda sıfır FPS kaybı için donduruldu.
            </p>
          </div>
        )}

        {/* IN-GAME Category */}
        {inGameMembers.length > 0 && (
          <div>
            <h5 className="text-xxs font-bold uppercase tracking-wider text-purple-400 mb-1 px-1">
              OYUNDA — {inGameMembers.length}
            </h5>
            <div className="space-y-0.5">
              {inGameMembers.map((m) => (
                <MemoizedMemberRow key={m.id} member={m} />
              ))}
            </div>
          </div>
        )}

        {/* ONLINE Category */}
        <div>
          <h5 className="text-xxs font-bold uppercase tracking-wider text-gl-text-muted mb-1 px-1">
            ÇEVRİMİÇİ — {activeMembers.length}
          </h5>
          <div className="space-y-0.5">
            {activeMembers.map((m) => (
              <MemoizedMemberRow key={m.id} member={m} />
            ))}
          </div>
        </div>

        {/* IDLE / AFK Category */}
        {idleMembers.length > 0 && (
          <div>
            <h5 className="text-xxs font-bold uppercase tracking-wider text-gl-text-muted mb-1 px-1">
              BOŞTA — {idleMembers.length}
            </h5>
            <div className="space-y-0.5">
              {idleMembers.map((m) => (
                <MemoizedMemberRow key={m.id} member={m} />
              ))}
            </div>
          </div>
        )}
      </div>
    </aside>
  );
}
