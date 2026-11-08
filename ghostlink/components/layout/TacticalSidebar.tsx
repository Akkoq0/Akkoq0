'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Multi-Game Community Channel Hub (TacticalSidebar)
// ─────────────────────────────────────────────────────────
// Features:
//   • Category-based multi-game architecture (LoL, CS2, Valo, Dota 2, Chill)
//   • Smart Tag-based Channel Recommendations (⚡ Sana Uygun %96 Eşleşme)
//   • Quick Game Filter Pills (Tümü, LoL, CS2, Valo, Dota, Chill)
//   • 1-Click Channel / Server Builder trigger (+ Ekle)
//   • 0ms Context-Aware Channel Switching & Zero-Re-Render design

import { memo, useMemo } from 'react';
import { useAppStore } from '@/lib/store';
import { useHUDStore } from '@/store/useHUDStore';
import { useVoiceSettingsStore } from '@/store/useVoiceSettingsStore';
import { cleanLabel } from '@/lib/format';
import {
  detectGameFromChannel,
  evaluateChannelMatch,
  getGameById,
  SUPPORTED_GAMES,
} from '@/src/lib/gameRegistry';
import {
  getRecommendedSquadPods,
  evaluatePodMatch,
  type UserTacticalProfile,
} from '@/src/lib/channelDiscoveryEngine';
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
  IconBolt,
  IconPlus,
  IconTrash,
  IconHelp,
} from '@/components/ui/MevaIcons';
import { getMevaStorageEngine, STORE_PREFS } from '@/src/lib/storageEngine';
import type { VoiceControls, VoicePresence, Channel } from '@/types';

interface TacticalSidebarProps {
  username?: string;
  voiceControls?: VoiceControls;
}

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

const GAME_FILTER_OPTIONS: Array<{ key: string; label: string }> = [
  { key: 'all', label: 'TÜMÜ' },
  { key: 'for-you', label: '⚡ SANA UYGUN' },
  { key: 'lol', label: 'LoL' },
  { key: 'cs2', label: 'CS2' },
  { key: 'valorant', label: 'VALO' },
  { key: 'dota2', label: 'DOTA2' },
  { key: 'pubg', label: 'PUBG' },
  { key: 'chill', label: 'CHILL' },
];

function SectionLabel({
  children,
  meta,
  onAdd,
}: {
  children: string;
  meta?: string;
  onAdd?: () => void;
}) {
  return (
    <div className="h-7 px-2 flex items-center justify-between">
      <span className="text-[11px] font-semibold tracking-wide text-[#8E7E81] truncate">
        {children}
      </span>
      <div className="flex items-center gap-1.5 flex-shrink-0">
        {meta && (
          <span className="text-[10px] font-semibold tabular-nums text-[#C82333]/85">
            {meta}
          </span>
        )}
        {onAdd && (
          <button
            type="button"
            onClick={onAdd}
            className="w-4 h-4 rounded flex items-center justify-center text-[#8E7E81] hover:text-[#FAF2EE] hover:bg-[#3B141C]"
            title="Kanal Ekle"
          >
            <IconPlus size={11} />
          </button>
        )}
      </div>
    </div>
  );
}

export const TacticalSidebar = memo(function TacticalSidebar({
  username = 'Operatör',
  voiceControls,
}: TacticalSidebarProps) {
  const servers = useAppStore((s) => s.servers);
  const activeServerId = useAppStore((s) => s.activeServerId);
  const categories = useAppStore((s) => s.categories);
  const channels = useAppStore((s) => s.channels);
  const activeChannelId = useAppStore((s) => s.activeChannelId);
  const activeVoiceChannelId = useAppStore((s) => s.activeVoiceChannelId);
  const activeDMUserId = useAppStore((s) => s.activeDMUserId);
  const voiceParticipants = useAppStore((s) => s.voiceParticipants);
  const qualityScore = useAppStore((s) => s.netGuard.qualityScore);
  const selectedGameFilter = useAppStore((s) => s.selectedGameFilter);
  const userPrimaryGame = useAppStore((s) => s.userPrimaryGame) as any;
  const userGameRoles = useAppStore((s) => s.userGameRoles);

  const setActiveServer = useAppStore((s) => s.setActiveServer);
  const setActiveChannel = useAppStore((s) => s.setActiveChannel);
  const setActiveVoiceChannel = useAppStore((s) => s.setActiveVoiceChannel);
  const setIsMobileSidebarOpen = useAppStore((s) => s.setIsMobileSidebarOpen);
  const setSelectedGameFilter = useAppStore((s) => s.setSelectedGameFilter);
  const setShowChannelBuilderModal = useAppStore(
    (s) => s.setShowChannelBuilderModal,
  );
  const setShowTourModal = useAppStore((s) => s.setShowTourModal);
  const removeServer = useAppStore((s) => s.removeServer);
  const removeChannel = useAppStore((s) => s.removeChannel);
  const setShowCommandSettingsModal = useVoiceSettingsStore(
    (s) => s.setShowCommandSettingsModal,
  );
  const setShowStratBoard = useVoiceSettingsStore((s) => s.setShowStratBoard);

  const activeServer = servers.find((s) => s.id === activeServerId) ?? servers[0];
  const activeVoiceChannel = channels.find((c) => c.id === activeVoiceChannelId);

  const voiceCapacity = activeVoiceChannel?.max_participants ?? 5;
  const squadCount = voiceParticipants.length;

  const slotBeacons = useAppStore((s) => s.slotBeacons);

  const userProfile: UserTacticalProfile = useMemo(
    () => ({
      primaryGame: userPrimaryGame,
      favoriteGames: [userPrimaryGame, 'lol', 'cs2', 'valorant', 'dota2'],
      gameRoles: userGameRoles,
      communityTags: ['tryhard', 'ranked', 'scrim'],
    }),
    [userPrimaryGame, userGameRoles],
  );

  const recommendedPods = useMemo(() => {
    const occMap = {
      ...STANDBY_OCCUPANCY,
      [activeVoiceChannelId ?? '']: squadCount,
    };
    return getRecommendedSquadPods(channels, userProfile, slotBeacons as any, occMap);
  }, [channels, userProfile, slotBeacons, activeVoiceChannelId, squadCount]);

  const voiceLabel = activeVoiceChannel
    ? cleanLabel(activeVoiceChannel.name)
    : activeVoiceChannelId?.startsWith('scrim-')
      ? `Scrim #${activeVoiceChannelId.slice(6)}`
      : 'Bağlı değil';

  // Filter channels based on quick filter pill
  const filteredChannels = useMemo(() => {
    if (selectedGameFilter === 'all') return channels;
    if (selectedGameFilter === 'for-you') {
      const recMap = new Map(recommendedPods.map((r) => [r.channelId, r]));
      const voiceChans = channels.filter((c) => c.type === 'voice');
      return [...voiceChans].sort((a, b) => {
        const scoreA = recMap.get(a.id)?.score ?? 0;
        const scoreB = recMap.get(b.id)?.score ?? 0;
        return scoreB - scoreA;
      });
    }
    return channels.filter((ch) => {
      const g = ch.game_id
        ? getGameById(ch.game_id)
        : detectGameFromChannel(ch.name, ch.tags);
      return g.id === selectedGameFilter;
    });
  }, [channels, selectedGameFilter, recommendedPods]);

  // Group channels by category
  const categorizedChannels = useMemo(() => {
    if (selectedGameFilter === 'for-you') {
      return [
        {
          categoryName: '⚡ SANA EN UYGUN FREKANSLAR',
          channels: filteredChannels,
        },
      ];
    }

    const map = new Map<string, { categoryName: string; channels: Channel[] }>();

    // 1. Existing categories
    categories.forEach((cat) => {
      map.set(cat.id, { categoryName: cat.name, channels: [] });
    });

    // 2. Put channels in matching category or default
    filteredChannels.forEach((ch) => {
      if (ch.category_id && map.has(ch.category_id)) {
        map.get(ch.category_id)!.channels.push(ch);
      } else {
        const fallbackKey = ch.type === 'voice' ? 'cat-v-general' : 'cat-t-general';
        if (!map.has(fallbackKey)) {
          map.set(fallbackKey, {
            categoryName: ch.type === 'voice' ? 'SES ODALARI' : 'METİN KANALLARI',
            channels: [],
          });
        }
        map.get(fallbackKey)!.channels.push(ch);
      }
    });

    return Array.from(map.values()).filter((g) => g.channels.length > 0);
  }, [categories, filteredChannels, selectedGameFilter]);

  // Smart Channel Recommendation Engine
  const recommendedChannel = useMemo(() => {
    if (
      recommendedPods.length > 0 &&
      recommendedPods[0].channelId !== activeVoiceChannelId
    ) {
      const top = recommendedPods[0];
      const ch = channels.find((c) => c.id === top.channelId);
      if (ch) {
        return { match: top, channel: ch };
      }
    }
    return null;
  }, [recommendedPods, channels, activeVoiceChannelId]);

  // Handle Channel Click with 0ms Context Update
  const handleSelectVoiceChannel = (channel: Channel) => {
    setActiveVoiceChannel(channel.id);
    const game = channel.game_id
      ? getGameById(channel.game_id)
      : detectGameFromChannel(channel.name, channel.tags);

    // Sync active game role if known
    const targetRole = userGameRoles[game.id] || game.roles[0]?.key || 'IGL';
    useHUDStore.getState().setOperatorRole('usr-local', targetRole);
  };

  if (servers.length === 0 || !activeServer) {
    return (
      <aside className="w-full lg:w-[264px] h-full flex flex-col justify-between overflow-hidden select-none titanium-module lg:rounded-xl font-sans p-4">
        <div className="flex-1 flex flex-col items-center justify-center text-center p-3">
          <div className="w-14 h-14 rounded-2xl bg-[#1C0B10] border border-[#8F1622]/50 flex items-center justify-center text-[#C82333] mb-3 shadow-[0_0_24px_rgba(200,35,51,0.3)] animate-pulse">
            <IconBolt size={26} />
          </div>
          <h3 className="text-sm font-extrabold text-[#F4EFF0] tracking-wide mb-1.5">
            Aktif Sunucu Yok
          </h3>
          <p className="text-[11.5px] text-[#A8989B] leading-relaxed mb-5">
            Taktiksel ses ve kanal altyapınızı kurmak için aşağıdaki butondan hazır şablonla veya sıfırdan sunucunuzu oluşturun.
          </p>

          <button
            type="button"
            onClick={() => setShowChannelBuilderModal(true)}
            className="w-full py-2.5 px-4 rounded-xl crimson-cta text-xs font-black text-[#F4EFF0] flex items-center justify-center gap-2 shadow-[0_0_18px_rgba(200,35,51,0.45)] transition-all active:scale-95"
          >
            <IconPlus size={15} />
            <span>[+] Kendi Sunucunu Kur</span>
          </button>
        </div>

        <div className="pt-3 border-t border-[#2A1319]">
          <button
            type="button"
            onClick={() => setShowTourModal(true)}
            className="w-full py-2 px-3 rounded-lg bg-[#140A0D] hover:bg-[#1E0D13] border border-[#2A1319] text-[#9E8E91] hover:text-[#F4EFF0] text-[11px] font-bold flex items-center justify-center gap-1.5 transition-colors"
          >
            <IconHelp size={13} className="text-[#C82333]" />
            <span>Meva İnteraktif Rehber</span>
          </button>
        </div>
      </aside>
    );
  }

  return (
    <aside className="w-full lg:w-[264px] h-full flex flex-col overflow-hidden select-none titanium-module lg:rounded-xl font-sans">
      {/* ── Top Header ── */}
      <div className="relative px-3.5 pt-3 pb-2.5 flex-shrink-0 bg-[linear-gradient(135deg,rgba(230,36,50,0.14)_0%,transparent_55%)]">
        <span
          aria-hidden
          className="pointer-events-none absolute inset-x-3 bottom-0 h-px horizon-divider opacity-80"
        />
        <div className="flex items-center justify-between gap-2">
          <div className="min-w-0">
            <h2 className="truncate text-[13.5px] font-extrabold text-[#FAF2EE]">
              {activeServer?.name ?? 'Valorant TR Pro'}
            </h2>
            <p className="mt-0.5 text-[10.5px] text-[#9E8881] truncate">
              Çok Oyunlu Komuta & Yayıncı Hub’ı
            </p>
          </div>
          <div className="flex items-center gap-1">
            <button
              type="button"
              onClick={() => setShowChannelBuilderModal(true)}
              className="rounded-lg h-7 px-2 bg-[#590C15]/40 hover:bg-[#8F1622] border border-[#8F1622]/50 text-[11px] font-bold text-[#F08C96] hover:text-[#FAF2EE] flex items-center gap-1 transition-colors"
              title="Yeni Kanal veya Sunucu Ekle"
            >
              <IconPlus size={12} />
              <span>Ekle</span>
            </button>
            <button
              type="button"
              onClick={() => {
                if (window.confirm(`"${activeServer.name}" sunucusunu ve tüm kanallarını silmek istediğinize emin misiniz?`)) {
                  removeServer(activeServer.id);
                  try {
                    const storage = getMevaStorageEngine();
                    const remaining = servers.filter((s) => s.id !== activeServer.id);
                    storage.scheduleWrite(STORE_PREFS, 'custom_servers', remaining);
                    void storage.flushPendingWrites();
                  } catch {}
                }
              }}
              className="rounded-lg h-7 px-1.5 bg-[#1C0F14] hover:bg-[#3B141C] border border-[#2E1218] text-[#8E7E81] hover:text-[#FF4655] flex items-center justify-center transition-colors"
              title="Sunucuyu Güvenle Sil (Delete Hub)"
            >
              <IconTrash size={12} />
            </button>
            <button
              type="button"
              onClick={() => setIsMobileSidebarOpen(false)}
              aria-label="Kapat"
              className="lg:hidden rounded-lg w-7 h-7 flex items-center justify-center bg-[#1C0F14] border border-[#3B1D25] text-[#B8A29B]"
            >
              <IconClose size={14} />
            </button>
          </div>
        </div>

        {/* Quick Game Filter Pills */}
        <div className="mt-2.5 flex items-center gap-1 overflow-x-auto no-scrollbar">
          {GAME_FILTER_OPTIONS.map((opt) => {
            const isSelected = selectedGameFilter === opt.key;
            return (
              <button
                key={opt.key}
                type="button"
                onClick={() => setSelectedGameFilter(opt.key)}
                className={`rounded-lg px-2 py-0.5 text-[10.5px] font-extrabold whitespace-nowrap transition-all border ${
                  isSelected
                    ? 'bg-[#8F1622] border-[#C82333] text-[#FAF2EE] shadow-sm'
                    : 'bg-[#14080B] border-[#2E1218] text-[#8E7E81] hover:text-[#C5B5B8]'
                }`}
              >
                {opt.label}
              </button>
            );
          })}
        </div>

        {/* 1-Tap Pod Spawner */}
        <div className="mt-2">
          <button
            type="button"
            onClick={() => setShowChannelBuilderModal(true)}
            className="w-full h-7 rounded-lg bg-[#200A11] hover:bg-[#380E1B] border border-[#591421] hover:border-[#C82333] text-[#FAF2EE] text-[10.5px] font-extrabold flex items-center justify-center gap-1.5 transition-all shadow-sm active:scale-98"
          >
            <IconPlus size={12} className="text-[#FF4655]" />
            <span>+ Yeni Frekans Aç (Live Squad Pod)</span>
          </button>
        </div>
      </div>

      {/* ── Scrollable Directory ── */}
      <nav className="flex-1 min-h-0 overflow-y-auto px-2 py-2.5 space-y-3.5">
        {/* Smart Channel Recommendation Card: "Sana Özel Katıl" Widget */}
        {recommendedChannel && recommendedChannel.channel && (
          <div className="rounded-xl p-3 bg-gradient-to-br from-[#450A15]/90 via-[#220B12]/95 to-[#12070A]/95 border border-[#C82333]/65 shadow-[0_4px_18px_rgba(200,35,51,0.22)]">
            <div className="flex items-center justify-between gap-1 mb-1.5">
              <span className="text-[9px] font-black uppercase tracking-wider text-[#FF5A6B] bg-[#590C15]/75 px-1.5 py-0.5 rounded border border-[#C82333]/50 flex items-center gap-1">
                <IconBolt size={10} className="text-[#FF4655]" />
                <span>SANA ÖZEL EŞLEŞME</span>
              </span>
              <span className="text-[10px] font-extrabold text-[#F08C96] tabular-nums">
                %{recommendedChannel.match.score}
              </span>
            </div>

            <div className="mb-2">
              <span className="text-[12.5px] font-extrabold text-[#FAF2EE] block truncate">
                #{cleanLabel(recommendedChannel.channel.name)}
              </span>
              <span className="text-[10px] text-[#E08C96] font-semibold block truncate mt-0.5">
                {recommendedChannel.match.badgeText}
              </span>
            </div>

            <button
              type="button"
              onClick={() =>
                handleSelectVoiceChannel(recommendedChannel.channel!)
              }
              className="w-full h-7 rounded-lg bg-[#8F1622] hover:bg-[#C82333] active:scale-98 text-[11px] font-extrabold text-[#FAF2EE] flex items-center justify-center gap-1.5 shadow-[0_0_10px_rgba(200,35,51,0.3)] transition-all"
            >
              <span>Hemen Katıl</span>
              <span className="text-xs">→</span>
            </button>
          </div>
        )}

        {/* Categorized Channel Sections */}
        {categorizedChannels.map((group, idx) => (
          <section key={idx} className="space-y-1">
            <SectionLabel
              onAdd={() => setShowChannelBuilderModal(true)}
              meta={group.categoryName.includes('SES') ? 'Opus 48k' : undefined}
            >
              {group.categoryName}
            </SectionLabel>

            <div className="space-y-1">
              {group.channels.map((channel) => {
                const isVoice = channel.type === 'voice';
                const isActive = isVoice
                  ? channel.id === activeVoiceChannelId
                  : channel.id === activeChannelId && !activeDMUserId;

                const cap = channel.max_participants ?? 5;
                const occ = isActive
                  ? squadCount
                  : (STANDBY_OCCUPANCY[channel.id] ?? 0);

                const game = channel.game_id
                  ? getGameById(channel.game_id)
                  : detectGameFromChannel(channel.name, channel.tags);

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
                      onClick={() =>
                        isVoice
                          ? handleSelectVoiceChannel(channel)
                          : setActiveChannel(channel.id)
                      }
                      className="w-full min-h-[40px] px-2.5 py-1.5 flex items-center justify-between gap-1.5 text-left"
                    >
                      <span className="flex items-center gap-2 min-w-0">
                        <span
                          className={`rounded-lg w-6 h-6 flex items-center justify-center flex-shrink-0 ${
                            isActive
                              ? 'crimson-cta text-[#F4EFF0]'
                              : 'bg-[#140A0D] text-[#8E7E81] border border-[#281318]'
                          }`}
                        >
                          {isVoice ? (
                            <IconVoiceWave size={13} />
                          ) : (
                            <IconChannelText size={13} />
                          )}
                        </span>
                        <span className="min-w-0">
                          <span
                            className={`truncate block text-[12.5px] ${
                              isActive
                                ? 'font-bold text-[#F4EFF0]'
                                : 'font-medium text-[#B8AAAC]'
                            }`}
                          >
                            {cleanLabel(channel.name)}
                          </span>
                        </span>
                      </span>

                      <div className="flex items-center gap-1.5 flex-shrink-0">
                        {game && (
                          <span
                            className="text-[9.5px] font-extrabold px-1 py-0.2 rounded border"
                            style={{
                              backgroundColor: game.badgeBg,
                              borderColor: `${game.color}55`,
                              color: game.color,
                            }}
                          >
                            {game.shortName}
                          </span>
                        )}
                        {isVoice && (
                          <div className="flex items-center gap-1">
                            {/* 5-Dot Mini Occupancy Meter */}
                            <div
                              className="flex items-center gap-0.5"
                              title={`Doluluk: ${occ}/${cap === 0 ? 5 : cap}`}
                            >
                              {Array.from({ length: 5 }).map((_, dIdx) => (
                                <span
                                  key={dIdx}
                                  className={`w-1.5 h-1.5 rounded-full transition-all ${
                                    dIdx < occ
                                      ? isActive
                                        ? 'bg-[#FF4655] shadow-[0_0_5px_#FF4655]'
                                        : 'bg-[#C82333]'
                                      : 'bg-[#2A131A]'
                                  }`}
                                />
                              ))}
                            </div>
                            <span
                              className={`rounded px-1 text-[10px] font-bold tabular-nums ${
                                isActive
                                  ? 'text-[#F08C96]'
                                  : occ > 0
                                    ? 'text-[#B8AAAC]'
                                    : 'text-[#6E5F62]'
                              }`}
                            >
                              {occ}/{cap === 0 ? '5' : cap}
                            </span>
                          </div>
                        )}
                        <button
                          type="button"
                          onClick={(e) => {
                            e.stopPropagation();
                            if (window.confirm(`"${cleanLabel(channel.name)}" kanalını silmek istediğinize emin misiniz?`)) {
                              removeChannel(channel.id);
                              try {
                                const storage = getMevaStorageEngine();
                                const remaining = channels.filter((c) => c.id !== channel.id);
                                storage.scheduleWrite(STORE_PREFS, 'custom_channels', remaining);
                                void storage.flushPendingWrites();
                              } catch {}
                            }
                          }}
                          className="opacity-0 group-hover:opacity-100 w-5 h-5 rounded flex items-center justify-center text-[#827376] hover:text-[#FF4655] hover:bg-[#2A0E16] transition-all ml-0.5 flex-shrink-0"
                          title="Kanalı Sil"
                        >
                          <IconTrash size={11} />
                        </button>
                      </div>
                    </button>

                    {/* Active Slot Beacon Indicator */}
                    {isVoice &&
                      isActive &&
                      Object.values(slotBeacons).some(Boolean) && (
                        <div className="px-2.5 pb-1">
                          <span className="text-[9px] font-black px-1.5 py-0.5 rounded bg-[#4A0D18] text-[#FF5A6B] border border-[#C82333]/50 animate-pulse flex items-center gap-1">
                            <span>⚡ BEACON:</span>
                            <span>
                              {Object.values(slotBeacons)
                                .map((b) => b?.targetRole)
                                .filter(Boolean)
                                .join(', ')}{' '}
                              Aranıyor
                            </span>
                          </span>
                        </div>
                      )}

                    {/* Affinity Score & 1-Tap Join Action */}
                    {isVoice &&
                      (() => {
                        const recMatch = recommendedPods.find(
                          (r) => r.channelId === channel.id,
                        );
                        if (
                          !recMatch ||
                          (selectedGameFilter !== 'for-you' &&
                            recMatch.score < 70)
                        ) {
                          return null;
                        }
                        return (
                          <div className="px-2.5 pb-2 pt-0.5 flex items-center justify-between gap-1.5 border-t border-[#261217]/60">
                            <span className="text-[9.5px] font-extrabold text-[#FF5A6B] truncate">
                              {recMatch.badgeText}
                            </span>
                            {!isActive && (
                              <button
                                type="button"
                                onClick={(e) => {
                                  e.stopPropagation();
                                  handleSelectVoiceChannel(channel);
                                }}
                                className="rounded-lg px-2 py-0.5 bg-[#8F1622] hover:bg-[#C82333] text-[9.5px] font-black text-[#FAF2EE] whitespace-nowrap active:scale-95 transition-all shadow-sm flex items-center gap-0.5"
                              >
                                <span>Hemen Katıl</span>
                                <span>→</span>
                              </button>
                            )}
                          </div>
                        );
                      })()}

                    {/* Active Voice Participants list */}
                    {isVoice && isActive && voiceParticipants.length > 0 && (
                      <ul className="px-2.5 pb-2 space-y-0.5">
                        {voiceParticipants.map((vp) => (
                          <VoiceParticipantRow key={vp.user_id} participant={vp} />
                        ))}
                      </ul>
                    )}

                    {/* Quick Tactical Board link */}
                    {isVoice && isActive && (
                      <div className="px-2.5 pb-2">
                        <button
                          type="button"
                          onClick={() => setShowStratBoard(true)}
                          className="rounded-lg w-full h-6 px-2 bg-[#190B10] hover:bg-[#7A121D]/35 border border-[#7A121D]/45 text-[10.5px] font-bold text-[#F08C96] flex items-center justify-center gap-1.5 transition-colors"
                        >
                          <IconMapBoard size={11} />
                          <span>Taktik Harita & Çizim ({game.shortName})</span>
                        </button>
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          </section>
        ))}
      </nav>

      {/* ── Single-Line Operator Status Strip ── */}
      <div className="relative h-14 px-3 flex items-center justify-between gap-2 bg-[#0A0708]/90 flex-shrink-0">
        <span
          aria-hidden
          className="pointer-events-none absolute inset-x-3 top-0 h-px horizon-divider opacity-70"
        />
        <div className="flex items-center gap-2 min-w-0">
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
            <span className="flex items-center gap-1.5 text-[10.5px] text-[#A5908A] min-w-0">
              <SignalBars score={qualityScore} />
              <span className="truncate tabular-nums">
                {voiceLabel} · {squadCount}/{voiceCapacity || '∞'}
              </span>
            </span>
          </div>
        </div>

        <div className="flex items-center gap-0.5 flex-shrink-0">
          {voiceControls && (
            <>
              <StripButton
                label={voiceControls.isMuted ? 'Mikrofonu aç' : 'Mikrofonu sustur'}
                danger={voiceControls.isMuted}
                onClick={voiceControls.toggleMute}
              >
                {voiceControls.isMuted ? (
                  <IconMicOff size={13} />
                ) : (
                  <IconMic size={13} />
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
                  <IconDeafen size={13} />
                ) : (
                  <IconHeadphones size={13} />
                )}
              </StripButton>
              {activeVoiceChannelId && (
                <StripButton
                  label="Ses odasından ayrıl"
                  danger
                  onClick={voiceControls.leaveVoice}
                >
                  <IconDisconnect size={13} />
                </StripButton>
              )}
            </>
          )}
          <StripButton
            label="Meva Komuta & DSP Ayarları"
            onClick={() => setShowCommandSettingsModal(true)}
          >
            <IconSettingsGear size={13} />
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
      className={`rounded-lg w-7 h-7 flex items-center justify-center transition-all ${
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
    <li className="h-6 pl-8 pr-1.5 flex items-center justify-between gap-1.5 text-[11.5px] rounded-lg hover:bg-white/[0.02] transition-colors">
      <span className="flex items-center gap-1.5 min-w-0">
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
        <IconMicOff size={11} className="text-[#E12D39] flex-shrink-0" />
      ) : (
        <span className="text-[10px] font-medium tabular-nums text-[#9B857F] flex-shrink-0">
          {PEER_PING[participant.user_id] ?? 12}ms
        </span>
      )}
    </li>
  );
});
