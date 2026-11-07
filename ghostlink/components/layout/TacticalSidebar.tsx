'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Luminous Channel Sidebar (TacticalSidebar)
// ─────────────────────────────────────────────────────────

import { memo } from 'react';
import { useAppStore } from '@/lib/store';
import { useVoiceSettingsStore } from '@/store/useVoiceSettingsStore';
import { cleanLabel } from '@/lib/format';
import { OperatorAvatar, SignalBars } from '@/components/ui/HudPrimitives';
import {
  IconChannelText,
  IconVoiceWave,
  IconClose,
  IconMic,
  IconMicOff,
  IconHeadphones,
  IconDeafen,
  IconDisconnect,
  IconSettingsGear,
  IconMapBoard,
} from '@/components/ui/MevaIcons';
import type { VoiceControls, VoicePresence } from '@/types';

interface TacticalSidebarProps {
  username?: string;
  voiceControls?: VoiceControls;
}

const ROOM_CAPACITY = 5;

const STANDBY_OCCUPANCY: Record<string, number> = {
  'ch-5': 0,
  'ch-6': 2,
};

const PEER_PING: Record<string, number> = {
  'usr-local': 9,
  'usr-1': 11,
  'usr-4': 12,
  'usr-2': 14,
  'usr-3': 13,
};

function SectionLabel({ children, meta }: { children: string; meta?: string }) {
  return (
    <div className="h-7 px-2 flex items-center justify-between">
      <span className="text-[11px] font-semibold tracking-wide text-[#8E7E81]">
        {children}
      </span>
      {meta && (
        <span className="text-[10.5px] font-semibold tabular-nums text-[#C82333]/85">
          {meta}
        </span>
      )}
    </div>
  );
}

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
  const voiceParticipants = useAppStore((s) => s.voiceParticipants);
  const qualityScore = useAppStore((s) => s.netGuard.qualityScore);

  const setActiveServer = useAppStore((s) => s.setActiveServer);
  const setActiveChannel = useAppStore((s) => s.setActiveChannel);
  const setActiveVoiceChannel = useAppStore((s) => s.setActiveVoiceChannel);
  const setIsMobileSidebarOpen = useAppStore((s) => s.setIsMobileSidebarOpen);
  const setShowCommandSettingsModal = useVoiceSettingsStore(
    (s) => s.setShowCommandSettingsModal,
  );
  const setShowStratBoard = useVoiceSettingsStore((s) => s.setShowStratBoard);

  const activeServer = servers.find((s) => s.id === activeServerId);
  const voiceChannels = channels.filter((c) => c.type === 'voice');
  const textChannels = channels.filter((c) => c.type === 'text').slice(0, 3);
  const activeVoiceChannel = channels.find((c) => c.id === activeVoiceChannelId);

  const voiceLabel = activeVoiceChannel
    ? cleanLabel(activeVoiceChannel.name)
    : activeVoiceChannelId?.startsWith('scrim-')
      ? `Scrim #${activeVoiceChannelId.slice(6)}`
      : 'Bağlı değil';

  const squadCount = Math.min(ROOM_CAPACITY, voiceParticipants.length);

  return (
    <aside className="w-full lg:w-[256px] h-full flex flex-col overflow-hidden select-none titanium-module lg:rounded-xl font-sans">
      {/* ── Header ── */}
      <div className="relative px-4 pt-3.5 pb-3 flex-shrink-0 bg-[linear-gradient(135deg,rgba(230,36,50,0.14)_0%,transparent_55%)]">
        <span
          aria-hidden
          className="pointer-events-none absolute inset-x-3 bottom-0 h-px horizon-divider opacity-80"
        />
        <div className="flex items-center justify-between gap-2">
          <div className="min-w-0">
            <h2 className="truncate text-[14px] font-extrabold text-[#FAF2EE]">
              {activeServer?.name ?? 'Valorant TR Pro'}
            </h2>
            <p className="mt-0.5 text-[11px] text-[#9E8881]">
              Doğrudan P2P komuta ağı
            </p>
          </div>
          <button
            type="button"
            onClick={() => setIsMobileSidebarOpen(false)}
            aria-label="Kapat"
            className="lg:hidden rounded-xl w-9 h-9 flex items-center justify-center bg-[#1C0F14] border border-[#3B1D25] text-[#B8A29B] hover:text-[#FAF2EE]"
          >
            <IconClose size={16} />
          </button>
        </div>

        {/* Mobile server switcher */}
        <div className="mt-3 flex lg:hidden gap-1.5 overflow-x-auto no-scrollbar">
          {servers.map((srv) => {
            const isActive = srv.id === activeServerId;
            return (
              <button
                type="button"
                key={srv.id}
                onClick={() => setActiveServer(srv.id)}
                className={`rounded-xl h-9 px-3.5 whitespace-nowrap text-[12px] font-bold border transition-all ${
                  isActive
                    ? 'crimson-cta text-[#FAF2EE]'
                    : 'bg-[#160C10] text-[#9E8881] border-[#301820]'
                }`}
              >
                {srv.name}
              </button>
            );
          })}
        </div>
      </div>

      {/* ── Scrollable Channel Directory ── */}
      <nav className="flex-1 min-h-0 overflow-y-auto px-2.5 py-3 space-y-4">
        <section>
          <SectionLabel meta="Opus 48kHz">Ses Odaları</SectionLabel>
          <div className="space-y-1.5">
            {voiceChannels.map((channel) => {
              const isActive = channel.id === activeVoiceChannelId;
              const occupancy = isActive
                ? squadCount
                : (STANDBY_OCCUPANCY[channel.id] ?? 0);

              return (
                <div
                  key={channel.id}
                  className={`rounded-xl border transition-all duration-150 ${
                    isActive
                      ? 'bg-[linear-gradient(160deg,rgba(128,18,30,0.22)_0%,rgba(11,8,10,0.78)_100%)] border-[#961826]/45'
                      : 'border-transparent hover:bg-[#170B0F]/70 hover:border-[#2C141A]'
                  }`}
                >
                  <button
                    type="button"
                    onClick={() => setActiveVoiceChannel(channel.id)}
                    className="w-full min-h-[44px] md:min-h-[40px] px-3 md:px-2.5 py-2 flex items-center justify-between gap-2 text-left"
                  >
                    <span className="flex items-center gap-2.5 min-w-0">
                      <span
                        className={`rounded-lg w-7 h-7 flex items-center justify-center flex-shrink-0 ${
                          isActive
                            ? 'crimson-cta text-[#F4EFF0]'
                            : 'bg-[#140A0D] text-[#8E7E81] border border-[#281318]'
                        }`}
                      >
                        <IconVoiceWave size={14} />
                      </span>
                      <span
                        className={`truncate text-[13px] ${
                          isActive
                            ? 'font-bold text-[#F4EFF0]'
                            : 'font-medium text-[#B8AAAC]'
                        }`}
                      >
                        {cleanLabel(channel.name)}
                      </span>
                    </span>
                    <span
                      className={`rounded-md px-2 py-0.5 text-[11px] font-bold tabular-nums flex-shrink-0 ${
                        isActive
                          ? 'bg-[#8F1622]/25 text-[#F08C96] border border-[#961826]/45'
                          : occupancy > 0
                            ? 'bg-[#180B10] text-[#B8AAAC]'
                            : 'text-[#6E5F62]'
                      }`}
                    >
                      {occupancy}/{ROOM_CAPACITY}
                    </span>
                  </button>

                  {isActive && voiceParticipants.length > 0 && (
                    <ul className="px-2.5 pb-2 space-y-0.5">
                      {voiceParticipants.map((vp) => (
                        <VoiceParticipantRow key={vp.user_id} participant={vp} />
                      ))}
                    </ul>
                  )}

                  {isActive &&
                    (channel.id === 'ch-5' ||
                      channel.id === 'ch-6' ||
                      channel.id.startsWith('scrim-')) && (
                      <div className="px-2.5 pb-2.5">
                        <button
                          type="button"
                          onClick={() => setShowStratBoard(true)}
                          className="rounded-lg w-full h-7 px-2.5 bg-[#190B10] hover:bg-[#7A121D]/35 border border-[#7A121D]/45 text-[11px] font-bold text-[#F08C96] flex items-center justify-center gap-1.5 transition-colors"
                        >
                          <IconMapBoard size={12} />
                          <span>Taktik Harita & Çizim Tahtası</span>
                        </button>
                      </div>
                    )}
                </div>
              );
            })}
          </div>
        </section>

        <section>
          <SectionLabel>Metin Kanalları</SectionLabel>
          <div className="space-y-1">
            {textChannels.map((channel) => {
              const isActive = channel.id === activeChannelId && !activeDMUserId;
              return (
                <button
                  type="button"
                  key={channel.id}
                  onClick={() => setActiveChannel(channel.id)}
                  className={`relative rounded-xl w-full min-h-[42px] md:min-h-[36px] px-3 md:px-2.5 flex items-center gap-2.5 text-[13px] transition-all duration-150 ${
                    isActive
                      ? 'bg-[linear-gradient(90deg,rgba(138,20,32,0.24)_0%,rgba(12,9,10,0.4)_100%)] text-[#F4EFF0] font-bold border border-[#8F1622]/40'
                      : 'text-[#B8AAAC] hover:text-[#F4EFF0] hover:bg-[#170B0F]/70 font-medium border border-transparent'
                  }`}
                >
                  {isActive && (
                    <span
                      aria-hidden
                      className="absolute left-0 top-1.5 bottom-1.5 w-[3px] rounded-full bg-[#C82333]"
                    />
                  )}
                  <IconChannelText
                    size={14}
                    className={isActive ? 'text-[#D63344]' : 'text-[#7D6E71]'}
                  />
                  <span className="truncate">{cleanLabel(channel.name)}</span>
                </button>
              );
            })}
          </div>
        </section>
      </nav>

      {/* ── Single-Line Status Strip ── */}
      <div className="relative h-14 px-3 flex items-center justify-between gap-2 bg-[#0A0708]/85 flex-shrink-0">
        <span
          aria-hidden
          className="pointer-events-none absolute inset-x-3 top-0 h-px horizon-divider opacity-70"
        />
        <div className="flex items-center gap-2.5 min-w-0">
          <OperatorAvatar
            name={username}
            status="online"
            size="sm"
            speaking={Boolean(voiceControls?.isSpeaking)}
          />
          <div className="min-w-0">
            <span className="block truncate text-[12px] font-semibold text-[#F7EEE9]">
              {username}
            </span>
            <span className="flex items-center gap-1.5 text-[11px] text-[#A5908A] min-w-0">
              <SignalBars score={qualityScore} />
              <span className="truncate tabular-nums">
                {voiceLabel} · {squadCount}/{ROOM_CAPACITY}
              </span>
            </span>
          </div>
        </div>

        <div className="flex items-center gap-1 flex-shrink-0">
          {voiceControls && (
            <>
              <StripButton
                label={voiceControls.isMuted ? 'Mikrofonu aç' : 'Mikrofonu sustur'}
                danger={voiceControls.isMuted}
                onClick={voiceControls.toggleMute}
              >
                {voiceControls.isMuted ? (
                  <IconMicOff size={14} />
                ) : (
                  <IconMic size={14} />
                )}
              </StripButton>
              <StripButton
                label={
                  voiceControls.isDeafened ? 'Kulaklığı aç' : 'Kulaklığı kapat'
                }
                danger={voiceControls.isDeafened}
                onClick={voiceControls.toggleDeafen}
              >
                {voiceControls.isDeafened ? (
                  <IconDeafen size={14} />
                ) : (
                  <IconHeadphones size={14} />
                )}
              </StripButton>
              {activeVoiceChannelId && (
                <StripButton
                  label="Ses odasından ayrıl"
                  danger
                  onClick={voiceControls.leaveVoice}
                >
                  <IconDisconnect size={14} />
                </StripButton>
              )}
            </>
          )}
          <StripButton
            label="Meva Komuta & DSP Ayarları"
            onClick={() => setShowCommandSettingsModal(true)}
          >
            <IconSettingsGear size={14} />
          </StripButton>
        </div>
      </div>
    </aside>
  );
});

function StripButton({
  label,
  danger = false,
  onClick,
  children,
}: {
  label: string;
  danger?: boolean;
  onClick: () => void;
  children: React.ReactNode;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      aria-label={label}
      title={label}
      className={`rounded-lg w-8 h-8 flex items-center justify-center transition-all ${
        danger
          ? 'bg-[#9E1B24]/28 text-[#F69299] hover:bg-[#9E1B24]/45 border border-[#B8232E]/45'
          : 'text-[#A5908A] hover:text-[#F7EEE9] hover:bg-[#23161B] border border-transparent'
      }`}
    >
      {children}
    </button>
  );
}

const VoiceParticipantRow = memo(function VoiceParticipantRow({
  participant,
}: {
  participant: VoicePresence;
}) {
  const isSpeaking = participant.is_speaking && !participant.is_muted;
  return (
    <li className="h-7 pl-9 pr-1.5 flex items-center justify-between gap-2 text-[12px] rounded-lg hover:bg-white/[0.02] transition-colors">
      <span className="flex items-center gap-2 min-w-0">
        <span
          className={`w-1.5 h-1.5 rounded-full flex-shrink-0 transition-shadow ${
            participant.is_muted
              ? 'bg-[#B3222C]'
              : isSpeaking
                ? 'bg-[#E8B282] shadow-[0_0_8px_rgba(232,178,130,0.95)]'
                : 'bg-[#543F45]'
          }`}
        />
        <span
          className={`truncate ${
            isSpeaking
              ? 'text-[#FFF6F2] font-semibold'
              : 'text-[#D2BFB8] font-medium'
          }`}
        >
          {participant.username}
        </span>
      </span>
      {participant.is_muted ? (
        <IconMicOff size={12} className="text-[#E12D39] flex-shrink-0" />
      ) : (
        <span className="text-[11px] font-medium tabular-nums text-[#9B857F] flex-shrink-0">
          {PEER_PING[participant.user_id] ?? 12}ms
        </span>
      )}
    </li>
  );
});
