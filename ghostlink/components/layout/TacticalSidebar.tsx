'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Left Tactical Command Sidebar (TacticalSidebar)
// ─────────────────────────────────────────────────────────
// Complete, zero-empty-space tactical navigation hub:
//   1. TAKTİK SES FREKANSLARI (with [5/5], [0/5], [2/5] & 96kbps Opus)
//   2. OPERASYON KANALLARI (#genel-sohbet, #scrim-arama, #vod-notları, #turnuva-duyuru)
//   3. DOĞRUDAN HATLAR (1V1) (cNed, woxic, XANTARES, Alfajer)
//   4. AKTİF KADRO DURUMU & MASTER SES KONSOLU
// Typography: Crisp Sans-Serif for labels/names; font-mono ONLY for numeric metrics.

import { memo, useState } from 'react';
import { useAppStore } from '@/lib/store';
import { cleanLabel } from '@/lib/format';
import { OperatorAvatar, SignalBars } from '@/components/ui/HudPrimitives';
import {
  IconChannelText,
  IconVoiceWave,
  IconSearch,
  IconClose,
  IconChevron,
  IconPlus,
  IconMic,
  IconMicOff,
  IconHeadphones,
  IconDeafen,
  IconDisconnect,
} from '@/components/ui/MevaIcons';
import type { VoiceControls, VoicePresence } from '@/types';

interface TacticalSidebarProps {
  username?: string;
  voiceControls?: VoiceControls;
}

const VOICE_ROOM_META: Record<
  string,
  { occupancy: string; bitrate: string; standbyPeers?: string[] }
> = {
  'ch-4': { occupancy: '5/5', bitrate: '96kbps Opus' },
  'ch-5': { occupancy: '0/5', bitrate: '96kbps Opus' },
  'ch-6': {
    occupancy: '2/5',
    bitrate: '96kbps Opus',
    standbyPeers: ['AimCoach_Mert', 'Analist_Kaan'],
  },
  'ch-8': { occupancy: '5/5', bitrate: '96kbps Opus' },
  'ch-10': { occupancy: '5/5', bitrate: '96kbps Opus' },
};

const TEXT_CHANNEL_BADGES: Record<string, string> = {
  'ch-2': 'CANLI',
  'ch-3': '3 SCRIM',
  'ch-vod': 'YENİ',
};

export const TacticalSidebar = memo(function TacticalSidebar({
  username = 'Operatör',
  voiceControls,
}: TacticalSidebarProps) {
  const servers = useAppStore((s) => s.servers);
  const activeServerId = useAppStore((s) => s.activeServerId);
  const channels = useAppStore((s) => s.channels);
  const activeChannelId = useAppStore((s) => s.activeChannelId);
  const activeVoiceChannelId = useAppStore((s) => s.activeVoiceChannelId);
  const activeDMUserId = useAppStore((s) => s.activeDMUserId);
  const friends = useAppStore((s) => s.friends);
  const voiceParticipants = useAppStore((s) => s.voiceParticipants);
  const onlineMembers = useAppStore((s) => s.onlineMembers);
  const qualityScore = useAppStore((s) => s.netGuard.qualityScore);
  const jitterMs = useAppStore((s) => s.netGuard.jitterMs);

  const setActiveServer = useAppStore((s) => s.setActiveServer);
  const setActiveChannel = useAppStore((s) => s.setActiveChannel);
  const setActiveVoiceChannel = useAppStore((s) => s.setActiveVoiceChannel);
  const setActiveDMUser = useAppStore((s) => s.setActiveDMUser);
  const setShowFriendsModal = useAppStore((s) => s.setShowFriendsModal);
  const setIsMobileSidebarOpen = useAppStore((s) => s.setIsMobileSidebarOpen);

  const [query, setQuery] = useState('');
  const [collapsedSections, setCollapsedSections] = useState<
    Record<string, boolean>
  >({});

  const toggleSection = (key: string) =>
    setCollapsedSections((prev) => ({ ...prev, [key]: !prev[key] }));

  const activeServer = servers.find((s) => s.id === activeServerId);
  const acceptedFriends = friends.filter((f) => f.status === 'accepted');

  const q = query.trim().toLowerCase();
  const visibleChannels = q
    ? channels.filter((c) => c.name.toLowerCase().includes(q))
    : channels;

  const voiceChannels = visibleChannels.filter((c) => c.type === 'voice');
  const textChannels = visibleChannels.filter((c) => c.type === 'text');
  const activeVoiceChannel = channels.find(
    (c) => c.id === activeVoiceChannelId,
  );

  const voiceLabel = activeVoiceChannel
    ? cleanLabel(activeVoiceChannel.name)
    : activeVoiceChannelId?.startsWith('scrim-')
      ? `Scrim Odası #${activeVoiceChannelId.slice(6)}`
      : 'Taktik Lobi #1';

  return (
    <aside className="w-full md:w-[276px] h-full flex flex-col overflow-hidden select-none titanium-module md:rounded-sm font-sans">
      {/* ── 1. SERVER COMMAND HEADER & SEARCH ── */}
      <div className="p-3.5 border-b border-white/[0.06] space-y-2.5 flex-shrink-0">
        <div className="flex items-center justify-between gap-2">
          <div className="flex items-center gap-2.5 min-w-0">
            <span className="w-1.5 h-4 rounded-[1px] bg-[#EF4444] flex-shrink-0" />
            <div className="min-w-0">
              <h2 className="truncate font-sans font-bold text-[13px] tracking-wide text-gl-text-bright">
                {activeServer?.name ?? 'Valorant TR Pro'}
              </h2>
              <p className="text-[11px] text-gl-text-muted flex items-center gap-1.5">
                <span className="w-1.5 h-1.5 rounded-full bg-[#10B981]" />
                <span>Doğrudan P2P Komuta Ağı</span>
              </p>
            </div>
          </div>
          <button
            onClick={() => setIsMobileSidebarOpen(false)}
            aria-label="Kapat"
            className="md:hidden rounded-sm w-8 h-8 flex items-center justify-center bg-[#06070A] border border-white/[0.06] text-gl-text-normal hover:text-gl-text-bright"
          >
            <IconClose size={15} />
          </button>
        </div>

        {/* Mobile Server Switcher */}
        <div className="flex md:hidden gap-1.5 overflow-x-auto no-scrollbar">
          {servers.map((srv) => {
            const isActive = srv.id === activeServerId;
            return (
              <button
                key={srv.id}
                onClick={() => setActiveServer(srv.id)}
                className={`rounded-sm min-h-[34px] px-3 whitespace-nowrap font-sans text-xs font-semibold border transition-colors ${
                  isActive
                    ? 'bg-[#12151E] text-gl-text-bright border-[#EF4444]/60'
                    : 'bg-[#06070A] text-gl-text-muted border-white/[0.06]'
                }`}
              >
                {srv.name}
              </button>
            );
          })}
        </div>

        <label className="relative flex items-center">
          <IconSearch
            size={14}
            className="absolute left-3 text-gl-text-muted pointer-events-none"
          />
          <input
            type="search"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Frekans, kanal veya operatör filtrele..."
            aria-label="Kanal ara"
            className="rounded-sm w-full h-8 pl-9 pr-3 bg-[#06070A] border border-white/[0.06] focus:border-[#F59E0B]/60 text-xs font-sans text-gl-text-bright placeholder:text-gl-text-muted outline-none transition-colors"
          />
        </label>
      </div>

      {/* ── 2. SCROLLABLE FULL TACTICAL DIRECTORY ── */}
      <div className="flex-1 overflow-y-auto px-2.5 py-3 space-y-4">
        {/* SECTION A: TAKTİK SES FREKANSLARI */}
        <section className="space-y-1">
          <button
            onClick={() => toggleSection('voice')}
            className="w-full h-6 px-1.5 flex items-center justify-between text-[11px] font-sans font-bold uppercase tracking-wider text-gl-text-muted hover:text-gl-text-bright transition-colors"
          >
            <span className="flex items-center gap-1.5">
              <IconChevron
                size={11}
                className={`transition-transform duration-150 ${
                  collapsedSections['voice'] ? '-rotate-90' : ''
                }`}
              />
              <span>Taktik Ses Frekansları</span>
            </span>
            <span className="font-mono text-[10px] text-[#F59E0B]">
              96kbps Opus
            </span>
          </button>

          {!collapsedSections['voice'] && (
            <div className="space-y-1">
              {voiceChannels.map((channel) => {
                const isActive = channel.id === activeVoiceChannelId;
                const meta = VOICE_ROOM_META[channel.id] ?? {
                  occupancy: isActive ? '5/5' : '0/5',
                  bitrate: '96kbps Opus',
                };
                const displayOccupancy = isActive
                  ? `${Math.max(5, voiceParticipants.length)}/5`
                  : meta.occupancy;

                return (
                  <div
                    key={channel.id}
                    className={`rounded-sm border transition-colors ${
                      isActive
                        ? 'bg-[#12151E]/90 border-[#F59E0B]/40'
                        : 'bg-[#080A0F]/60 border-white/[0.04] hover:border-white/[0.1]'
                    }`}
                  >
                    <button
                      onClick={() => setActiveVoiceChannel(channel.id)}
                      className="relative w-full min-h-[38px] px-2.5 py-1.5 flex items-center justify-between gap-2 text-left"
                    >
                      {isActive && (
                        <span
                          aria-hidden
                          className="absolute left-0 top-1.5 bottom-1.5 w-[2px] bg-[#F59E0B]"
                        />
                      )}
                      <div className="flex items-center gap-2 min-w-0">
                        <IconVoiceWave
                          size={15}
                          className={
                            isActive ? 'text-[#F59E0B]' : 'text-gl-text-muted'
                          }
                        />
                        <div className="min-w-0">
                          <span
                            className={`block truncate text-[13px] ${
                              isActive
                                ? 'font-bold text-gl-text-bright'
                                : 'font-medium text-gl-text-normal'
                            }`}
                          >
                            {cleanLabel(channel.name)}
                          </span>
                          <span className="block font-mono text-[9px] text-gl-text-muted">
                            {meta.bitrate} · P2P Mesh
                          </span>
                        </div>
                      </div>

                      <span
                        className={`rounded-sm px-1.5 py-0.5 font-mono text-[10px] font-bold tabular-nums border ${
                          isActive
                            ? 'bg-[#10B981]/15 text-[#10B981] border-[#10B981]/35'
                            : displayOccupancy.startsWith('0')
                              ? 'bg-[#06070A] text-gl-text-muted border-white/[0.05]'
                              : 'bg-[#F59E0B]/15 text-[#F59E0B] border-[#F59E0B]/35'
                        }`}
                      >
                        [{displayOccupancy}]
                      </span>
                    </button>

                    {/* Active Voice Tree Operators */}
                    {isActive && voiceParticipants.length > 0 && (
                      <ul className="px-2.5 pb-2 pt-1 border-t border-white/[0.05] space-y-1">
                        {voiceParticipants.map((vp) => (
                          <VoiceTreeOperator
                            key={vp.user_id}
                            participant={vp}
                          />
                        ))}
                      </ul>
                    )}

                    {/* Standby Coach/Analyst Operators when not active */}
                    {!isActive && meta.standbyPeers && (
                      <ul className="px-2.5 pb-2 pt-1 border-t border-white/[0.04] space-y-1">
                        {meta.standbyPeers.map((peerName) => (
                          <li
                            key={peerName}
                            className="h-6 px-1.5 flex items-center justify-between text-xs text-gl-text-muted"
                          >
                            <span className="flex items-center gap-2 truncate">
                              <span className="w-1.5 h-1.5 rounded-full bg-[#F59E0B]" />
                              <span className="truncate font-medium">
                                {peerName}
                              </span>
                            </span>
                            <span className="font-mono text-[9px]">VOD</span>
                          </li>
                        ))}
                      </ul>
                    )}
                  </div>
                );
              })}
            </div>
          )}
        </section>

        {/* SECTION B: OPERASYON KANALLARI */}
        <section className="space-y-1 pt-2 border-t border-white/[0.05]">
          <button
            onClick={() => toggleSection('text')}
            className="w-full h-6 px-1.5 flex items-center justify-between text-[11px] font-sans font-bold uppercase tracking-wider text-gl-text-muted hover:text-gl-text-bright transition-colors"
          >
            <span className="flex items-center gap-1.5">
              <IconChevron
                size={11}
                className={`transition-transform duration-150 ${
                  collapsedSections['text'] ? '-rotate-90' : ''
                }`}
              />
              <span>Operasyon Kanalları</span>
            </span>
            <span className="font-mono text-[10px] text-gl-text-muted">
              {textChannels.length}
            </span>
          </button>

          {!collapsedSections['text'] && (
            <div className="space-y-0.5">
              {textChannels.map((channel) => {
                const isActive =
                  channel.id === activeChannelId && !activeDMUserId;
                const badge = TEXT_CHANNEL_BADGES[channel.id];
                return (
                  <button
                    key={channel.id}
                    onClick={() => setActiveChannel(channel.id)}
                    className={`relative rounded-sm w-full min-h-[34px] px-2.5 flex items-center justify-between gap-2 text-[13px] transition-colors ${
                      isActive
                        ? 'bg-[#12151E] text-gl-text-bright font-semibold'
                        : 'text-gl-text-normal hover:text-gl-text-bright hover:bg-[#12151E]/50 font-medium'
                    }`}
                  >
                    {isActive && (
                      <span
                        aria-hidden
                        className="absolute left-0 top-1.5 bottom-1.5 w-[2px] bg-[#EF4444]"
                      />
                    )}
                    <div className="flex items-center gap-2 min-w-0">
                      <IconChannelText
                        size={14}
                        className={
                          isActive ? 'text-[#EF4444]' : 'text-gl-text-muted'
                        }
                      />
                      <span className="truncate">
                        {cleanLabel(channel.name)}
                      </span>
                    </div>

                    {badge && (
                      <span
                        className={`rounded-sm px-1.5 py-0.2 text-[9px] font-semibold ${
                          isActive
                            ? 'bg-[#EF4444]/20 text-[#EF4444]'
                            : 'bg-white/[0.05] text-gl-text-muted'
                        }`}
                      >
                        {badge}
                      </span>
                    )}
                  </button>
                );
              })}
            </div>
          )}
        </section>

        {/* SECTION C: DOĞRUDAN HATLAR (1V1) */}
        <section className="space-y-1 pt-2 border-t border-white/[0.05]">
          <div className="h-6 px-1.5 flex items-center justify-between">
            <span className="text-[11px] font-sans font-bold uppercase tracking-wider text-gl-text-muted">
              Doğrudan Hatlar (1v1)
            </span>
            <button
              onClick={() => {
                setIsMobileSidebarOpen(false);
                setShowFriendsModal(true);
              }}
              aria-label="Operatör ekle"
              className="rounded-sm px-1.5 py-0.5 flex items-center gap-1 text-[10px] font-sans font-semibold text-[#F59E0B] hover:bg-[#12151E] transition-colors"
            >
              <IconPlus size={11} />
              <span>Ekle</span>
            </button>
          </div>

          <div className="space-y-0.5">
            {acceptedFriends.map((f) => {
              const friend = f.friend;
              if (!friend) return null;
              const isActive = activeDMUserId === friend.id;
              return (
                <button
                  key={f.id}
                  onClick={() => setActiveDMUser(friend.id)}
                  className={`relative rounded-sm w-full min-h-[38px] px-2.5 py-1 flex items-center justify-between gap-2 text-left transition-colors ${
                    isActive
                      ? 'bg-[#12151E] text-gl-text-bright'
                      : 'text-gl-text-normal hover:text-gl-text-bright hover:bg-[#12151E]/50'
                  }`}
                >
                  {isActive && (
                    <span
                      aria-hidden
                      className="absolute left-0 top-1.5 bottom-1.5 w-[2px] bg-[#EF4444]"
                    />
                  )}
                  <div className="flex items-center gap-2.5 min-w-0">
                    <OperatorAvatar
                      name={friend.username}
                      status={friend.status}
                      size="xs"
                    />
                    <div className="min-w-0">
                      <span className="block truncate text-[13px] font-semibold text-gl-text-bright">
                        {friend.username}
                      </span>
                      <span className="block truncate text-[10px] text-gl-text-muted">
                        {friend.activity ?? 'P2P Şifreli Hat'}
                      </span>
                    </div>
                  </div>
                  <span className="font-mono text-[10px] text-[#10B981]">
                    11ms
                  </span>
                </button>
              );
            })}
          </div>
        </section>
      </div>

      {/* ── 3. AKTİF KADRO DURUMU & MASTER SES KONSOLU ── */}
      <div className="bg-[#06070A] border-t border-white/[0.06] p-3 space-y-2.5 flex-shrink-0">
        {/* Squad Readiness & Link Quality Summary */}
        <div className="rounded-sm p-2.5 bg-[#0C0E14] border border-white/[0.06] space-y-2">
          <div className="flex items-center justify-between">
            <span className="text-[11px] font-sans font-bold text-gl-text-bright flex items-center gap-1.5">
              <span className="w-1.5 h-1.5 rounded-full bg-[#10B981] animate-pulse" />
              <span>Aktif Kadro Durumu</span>
            </span>
            <span className="font-mono text-[10px] font-bold text-[#10B981]">
              {onlineMembers.length + 1}/5 Hazır
            </span>
          </div>

          <div className="grid grid-cols-3 gap-1.5 pt-0.5 text-center">
            <div className="rounded-sm py-1 px-1 bg-[#06070A] border border-white/[0.04]">
              <span className="block text-[9px] text-gl-text-muted">CODEC</span>
              <span className="block font-mono text-[10px] font-bold text-[#F59E0B]">
                96kbps
              </span>
            </div>
            <div className="rounded-sm py-1 px-1 bg-[#06070A] border border-white/[0.04]">
              <span className="block text-[9px] text-gl-text-muted">GECİKME</span>
              <span className="block font-mono text-[10px] font-bold text-[#10B981]">
                11ms
              </span>
            </div>
            <div className="rounded-sm py-1 px-1 bg-[#06070A] border border-white/[0.04]">
              <span className="block text-[9px] text-gl-text-muted">JITTER</span>
              <span className="block font-mono text-[10px] font-bold text-gl-text-bright">
                {jitterMs}ms
              </span>
            </div>
          </div>
        </div>

        {/* Operator Deck & Master Hardware Audio Switches */}
        <div className="flex items-center justify-between gap-2 pt-0.5">
          <div className="flex items-center gap-2.5 min-w-0">
            <OperatorAvatar name={username} status="online" size="sm" />
            <div className="min-w-0">
              <span className="block truncate text-xs font-bold text-gl-text-bright">
                {username}
              </span>
              <span className="flex items-center gap-1.5 text-[10px] text-gl-text-muted truncate">
                <SignalBars score={qualityScore} />
                <span className="truncate">{voiceLabel}</span>
              </span>
            </div>
          </div>

          {voiceControls && (
            <div className="flex items-center gap-1 flex-shrink-0">
              <button
                onClick={voiceControls.toggleMute}
                aria-label={
                  voiceControls.isMuted ? 'Mikrofonu Aç' : 'Mikrofonu Sustur'
                }
                title={
                  voiceControls.isMuted ? 'Mikrofon Susturuldu' : 'Mikrofon Açık'
                }
                className={`rounded-sm w-8 h-8 flex items-center justify-center border transition-colors ${
                  voiceControls.isMuted
                    ? 'bg-[#EF4444]/15 text-[#EF4444] border-[#EF4444]/50'
                    : 'bg-[#0C0E14] text-gl-text-normal hover:text-gl-text-bright border-white/[0.06]'
                }`}
              >
                {voiceControls.isMuted ? (
                  <IconMicOff size={14} />
                ) : (
                  <IconMic size={14} />
                )}
              </button>

              <button
                onClick={voiceControls.toggleDeafen}
                aria-label={
                  voiceControls.isDeafened ? 'Kulaklığı Aç' : 'Kulaklığı Sustur'
                }
                title={
                  voiceControls.isDeafened
                    ? 'Kulaklık Susturuldu'
                    : 'Kulaklık Açık'
                }
                className={`rounded-sm w-8 h-8 flex items-center justify-center border transition-colors ${
                  voiceControls.isDeafened
                    ? 'bg-[#EF4444]/15 text-[#EF4444] border-[#EF4444]/50'
                    : 'bg-[#0C0E14] text-gl-text-normal hover:text-gl-text-bright border-white/[0.06]'
                }`}
              >
                {voiceControls.isDeafened ? (
                  <IconDeafen size={14} />
                ) : (
                  <IconHeadphones size={14} />
                )}
              </button>

              {activeVoiceChannelId && (
                <button
                  onClick={voiceControls.leaveVoice}
                  aria-label="Frekansı Kapat"
                  title="Ses Frekansından Ayrıl"
                  className="rounded-sm w-8 h-8 flex items-center justify-center bg-[#EF4444]/15 hover:bg-[#EF4444]/25 text-[#EF4444] border border-[#EF4444]/40 transition-colors"
                >
                  <IconDisconnect size={14} />
                </button>
              )}
            </div>
          )}
        </div>
      </div>
    </aside>
  );
});

const VoiceTreeOperator = memo(function VoiceTreeOperator({
  participant,
}: {
  participant: VoicePresence;
}) {
  const isSpeaking = participant.is_speaking && !participant.is_muted;
  return (
    <li className="h-6 px-1.5 rounded-sm flex items-center justify-between gap-2 text-xs">
      <div className="flex items-center gap-2 min-w-0">
        <span
          className={`w-1.5 h-1.5 rounded-full flex-shrink-0 ${
            participant.is_muted
              ? 'bg-[#EF4444]'
              : isSpeaking
                ? 'bg-[#10B981] shadow-[0_0_6px_#10B981]'
                : 'bg-[#F59E0B]'
          }`}
        />
        <span
          className={`truncate font-sans ${
            isSpeaking
              ? 'text-gl-text-bright font-semibold'
              : 'text-gl-text-normal font-medium'
          }`}
        >
          {participant.username}
        </span>
      </div>

      <div className="flex items-center gap-1 text-gl-text-muted flex-shrink-0">
        {participant.is_muted ? (
          <IconMicOff size={11} className="text-[#EF4444]" />
        ) : (
          <span className="font-mono text-[10px] text-[#10B981]">11ms</span>
        )}
      </div>
    </li>
  );
});
