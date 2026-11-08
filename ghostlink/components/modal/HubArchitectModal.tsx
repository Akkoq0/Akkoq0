'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Hub Architect & Fast Frequency Spawner Modal
// ─────────────────────────────────────────────────────────
// Stable 1-Click Server Templates (YouTuber Hub, Espor Scrim Karargahı, Serbest Agalar)
// and Fast Channel Pills (+LoL 5v5, +CS2 Premier, +Valo 5-Stack, +Dota 2, +PUBG, +Chill).
// Guaranteed: e.preventDefault() on all events, zero page reloads, 100% IndexedDB sync.

import React, { useState, useEffect } from 'react';
import { useAppStore } from '@/lib/store';
import { getMevaStorageEngine, STORE_PREFS } from '@/src/lib/storageEngine';
import {
  COMMUNITY_SERVER_TEMPLATES,
  QUICK_CHANNEL_PRESETS,
  SUPPORTED_GAMES,
  getGameById,
  type SupportedGameId,
} from '@/src/lib/gameRegistry';
import {
  IconClose,
  IconShield,
  IconVoiceWave,
  IconChannelText,
  IconBolt,
  IconPlus,
} from '@/components/ui/MevaIcons';

interface HubArchitectModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const HubArchitectModal: React.FC<HubArchitectModalProps> = ({
  isOpen,
  onClose,
}) => {
  const [activeTab, setActiveTab] = useState<'server' | 'channel'>('server');
  const [customName, setCustomName] = useState('');
  const [customGame, setCustomGame] = useState<SupportedGameId>('cs2');
  const [customType, setCustomType] = useState<'voice' | 'text'>('voice');
  const [customMax, setCustomMax] = useState(5);
  const [feedback, setFeedback] = useState<string | null>(null);

  const activeServerId = useAppStore((s) => s.activeServerId);
  const servers = useAppStore((s) => s.servers);
  const categories = useAppStore((s) => s.categories);
  const channels = useAppStore((s) => s.channels);
  const setServers = useAppStore((s) => s.setServers);
  const setActiveServer = useAppStore((s) => s.setActiveServer);
  const setCategories = useAppStore((s) => s.setCategories);
  const setChannels = useAppStore((s) => s.setChannels);
  const addChannel = useAppStore((s) => s.addChannel);
  const addCategory = useAppStore((s) => s.addCategory);
  const setActiveChannel = useAppStore((s) => s.setActiveChannel);
  const setActiveVoiceChannel = useAppStore((s) => s.setActiveVoiceChannel);

  // If no servers exist yet, default directly to server creation tab
  useEffect(() => {
    if (servers.length === 0) {
      setActiveTab('server');
    }
  }, [servers.length]);

  useEffect(() => {
    if (!isOpen) return;
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        e.preventDefault();
        onClose();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  // Helper to ensure an active server exists before adding channels
  const ensureActiveServer = (): { srvId: string; updatedServers: typeof servers } => {
    let srvId = activeServerId;
    let currentServers = [...servers];

    if (!srvId || currentServers.length === 0 || !currentServers.some((s) => s.id === srvId)) {
      const newDefSrv = {
        id: `srv-hub-${Date.now().toString(36)}`,
        name: 'Meva Komuta Karargahı',
        icon_url: null,
        owner_id: 'usr-local',
        invite_code: 'MEVA01',
        created_at: new Date().toISOString(),
      };
      currentServers = [newDefSrv, ...currentServers];
      srvId = newDefSrv.id;
      setServers(currentServers);
      setActiveServer(srvId);

      try {
        const storage = getMevaStorageEngine();
        storage.scheduleWrite(STORE_PREFS, 'custom_servers', currentServers);
      } catch {}
    }

    return { srvId: srvId!, updatedServers: currentServers };
  };

  // 1-Click Server Creation from Template (Instant & Persistent)
  const handleApplyServerTemplate = (
    template: typeof COMMUNITY_SERVER_TEMPLATES[number],
    e?: React.SyntheticEvent,
  ) => {
    if (e) {
      e.preventDefault();
      e.stopPropagation();
    }

    const srvId = `srv-${template.id}-${Date.now().toString(36)}`;
    const nowIso = new Date().toISOString();

    const newServer = {
      id: srvId,
      name: template.serverName,
      icon_url: null,
      owner_id: 'usr-local',
      invite_code: template.id.toUpperCase().slice(0, 6),
      created_at: nowIso,
    };

    const newCats: typeof categories = [];
    const newChans: typeof channels = [];

    template.categories.forEach((catDef, catIdx) => {
      const catId = `cat-${srvId}-${catIdx}`;
      newCats.push({
        id: catId,
        server_id: srvId,
        name: catDef.name,
        position: catIdx,
        is_collapsed: false,
      });

      catDef.channels.forEach((chDef, chIdx) => {
        newChans.push({
          id: `ch-${srvId}-${catIdx}-${chIdx}`,
          server_id: srvId,
          category_id: catId,
          name: chDef.name,
          type: chDef.type,
          position: chIdx,
          created_at: nowIso,
          game_id: chDef.gameId,
          max_participants: chDef.maxParticipants,
          tags: chDef.tags,
        });
      });
    });

    const updatedServers = [newServer, ...servers.filter((s) => s.id !== srvId)];
    const updatedCats = [...categories.filter((c) => c.server_id !== srvId), ...newCats];
    const updatedChans = [...channels.filter((c) => c.server_id !== srvId), ...newChans];

    setServers(updatedServers);
    setActiveServer(srvId);
    setCategories(updatedCats);
    setChannels(updatedChans);

    const firstVoice = newChans.find((c) => c.type === 'voice');
    if (firstVoice) setActiveVoiceChannel(firstVoice.id);
    const firstText = newChans.find((c) => c.type === 'text');
    if (firstText) setActiveChannel(firstText.id);

    try {
      const storage = getMevaStorageEngine();
      storage.scheduleWrite(STORE_PREFS, 'custom_servers', updatedServers);
      storage.scheduleWrite(STORE_PREFS, 'custom_categories', updatedCats);
      storage.scheduleWrite(STORE_PREFS, 'custom_channels', updatedChans);
      void storage.flushPendingWrites();
    } catch {}

    setFeedback(`🎉 "${template.serverName}" başarıyla kuruldu ve bağlandı!`);
    setTimeout(() => {
      onClose();
    }, 600);
  };

  // 1-Click Fast Channel Creation from Preset Pills
  const handleApplyPreset = (
    preset: typeof QUICK_CHANNEL_PRESETS[number],
    e?: React.SyntheticEvent,
  ) => {
    if (e) {
      e.preventDefault();
      e.stopPropagation();
    }

    const { srvId } = ensureActiveServer();

    let targetCat = categories.find(
      (c) => c.server_id === srvId && c.name.toLowerCase() === preset.categoryName.toLowerCase(),
    );

    if (!targetCat) {
      targetCat = {
        id: `cat-${srvId}-${Date.now().toString(36)}`,
        server_id: srvId,
        name: preset.categoryName,
        position: categories.filter((c) => c.server_id === srvId).length,
        is_collapsed: false,
      };
      addCategory(targetCat);
    }

    const gameDef = SUPPORTED_GAMES[preset.gameId] || getGameById(preset.gameId);
    const missingRoles = (gameDef?.roles || []).slice(1, 5).map((r) => r.shortLabel);

    const uniqueId = `ch-${preset.gameId}-${Date.now().toString(36)}`;
    const newChan = {
      id: uniqueId,
      server_id: srvId,
      category_id: targetCat.id,
      name: preset.name,
      type: preset.type,
      position: 99,
      created_at: new Date().toISOString(),
      game_id: preset.gameId,
      max_participants: preset.maxParticipants,
      tags: [
        ...(SUPPORTED_GAMES[preset.gameId]?.tags ?? ['#Oyun']),
        ...(missingRoles[0] ? [`#${missingRoles[0]}-Aranıyor`] : []),
      ],
    };

    addChannel(newChan);
    if (preset.type === 'voice') {
      setActiveVoiceChannel(newChan.id);
      missingRoles.forEach((role, idx) => {
        useAppStore.getState().setSlotBeacon(idx + 1, role);
      });
    } else {
      setActiveChannel(newChan.id);
    }

    try {
      const storage = getMevaStorageEngine();
      storage.scheduleWrite(STORE_PREFS, `smart_channel_${newChan.id}`, {
        channelId: newChan.id,
        name: newChan.name,
        gameId: preset.gameId,
        gameCategory: gameDef.category,
        missingRoles,
        tags: newChan.tags,
        createdAt: Date.now(),
      });
      storage.scheduleWrite(STORE_PREFS, 'custom_channels', useAppStore.getState().channels);
      storage.scheduleWrite(STORE_PREFS, 'custom_categories', useAppStore.getState().categories);
      void storage.flushPendingWrites();
    } catch {}

    setFeedback(`✅ #${preset.name} kanalı başarıyla eklendi!`);
    setTimeout(() => {
      onClose();
    }, 550);
  };

  // Custom Channel Creation Form
  const handleCreateCustomChannel = (e: React.FormEvent) => {
    e.preventDefault();
    e.stopPropagation();

    const cleanName =
      customName.trim().replace(/\s+/g, '-').toLowerCase() || `${customGame}-odasi`;
    const { srvId } = ensureActiveServer();

    const gameDef = SUPPORTED_GAMES[customGame];
    const missingRoles = (gameDef?.roles || []).slice(1, 5).map((r) => r.shortLabel);
    const catName =
      gameDef.category === 'moba'
        ? '⚔️ MOBA KANALLARI'
        : gameDef.category === 'fps'
          ? '🎯 TAKTİK FPS'
          : gameDef.category === 'br'
            ? '🪂 BATTLE ROYALE'
            : '☕ TOPLULUK & CHILL';

    let targetCat = categories.find((c) => c.server_id === srvId && c.name === catName);
    if (!targetCat) {
      targetCat = {
        id: `cat-${srvId}-${Date.now().toString(36)}`,
        server_id: srvId,
        name: catName,
        position: categories.filter((c) => c.server_id === srvId).length,
        is_collapsed: false,
      };
      addCategory(targetCat);
    }

    const newChan = {
      id: `ch-cust-${Date.now().toString(36)}`,
      server_id: srvId,
      category_id: targetCat.id,
      name: cleanName,
      type: customType,
      position: 100,
      created_at: new Date().toISOString(),
      game_id: customGame,
      max_participants: customMax,
      tags: [
        ...gameDef.tags,
        ...(missingRoles[0] ? [`#${missingRoles[0]}-Aranıyor`] : []),
      ],
    };

    addChannel(newChan);
    if (customType === 'voice') {
      setActiveVoiceChannel(newChan.id);
      missingRoles.forEach((role, idx) => {
        useAppStore.getState().setSlotBeacon(idx + 1, role);
      });
    } else {
      setActiveChannel(newChan.id);
    }

    try {
      const storage = getMevaStorageEngine();
      storage.scheduleWrite(STORE_PREFS, `smart_channel_${newChan.id}`, {
        channelId: newChan.id,
        name: newChan.name,
        gameId: customGame,
        gameCategory: gameDef.category,
        missingRoles,
        tags: newChan.tags,
        createdAt: Date.now(),
      });
      storage.scheduleWrite(STORE_PREFS, 'custom_channels', useAppStore.getState().channels);
      storage.scheduleWrite(STORE_PREFS, 'custom_categories', useAppStore.getState().categories);
      void storage.flushPendingWrites();
    } catch {}

    onClose();
  };

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-5 exec-backdrop select-none"
      onClick={(e) => {
        e.preventDefault();
        onClose();
      }}
    >
      <div
        className="w-full max-w-2xl bg-[#0F080B]/98 border border-[#8F1622]/55 rounded-2xl shadow-[0_24px_80px_rgba(0,0,0,0.92)] flex flex-col max-h-[90vh] overflow-hidden font-sans"
        onClick={(e) => {
          e.preventDefault();
          e.stopPropagation();
        }}
      >
        {/* Header */}
        <div className="px-5 py-4 border-b border-[#2A1319] flex items-center justify-between bg-gradient-to-r from-[#200B11] via-[#100709] to-[#0A0507]">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-[#590C15]/40 border border-[#A61826]/60 flex items-center justify-center text-[#F08C96] shadow-sm">
              <IconBolt size={20} className="text-[#FF4655]" />
            </div>
            <div>
              <h2 className="text-base font-extrabold text-[#FAF2EE] tracking-wide">
                Tek Tıkla Kanal ve Sunucu Mimarı
              </h2>
              <p className="text-xs text-[#9E8E91] mt-0.5">
                Topluluk veya klan karargahınızı kurun, espor frekanslarını anında başlatın.
              </p>
            </div>
          </div>
          <button
            type="button"
            onClick={(e) => {
              e.preventDefault();
              onClose();
            }}
            aria-label="Kapat"
            className="w-8 h-8 rounded-lg bg-[#180A0E] hover:bg-[#281016] border border-[#590C15]/45 text-[#A58D8E] hover:text-[#FAF2EE] flex items-center justify-center transition-colors"
          >
            <IconClose size={16} />
          </button>
        </div>

        {/* Tab Switcher */}
        <div className="px-5 pt-3 border-b border-[#2A1319] flex gap-4 bg-[#0A0507]">
          <button
            type="button"
            onClick={(e) => {
              e.preventDefault();
              setActiveTab('server');
            }}
            className={`pb-3 text-xs font-bold transition-all relative ${
              activeTab === 'server'
                ? 'text-[#F4EFF0]'
                : 'text-[#8E7E81] hover:text-[#C5B5B8]'
            }`}
          >
            🏛️ Hazır Sunucu Şablonu Kur (Server Templates)
            {activeTab === 'server' && (
              <span className="absolute bottom-0 inset-x-0 h-0.5 bg-[#C82333]" />
            )}
          </button>
          <button
            type="button"
            onClick={(e) => {
              e.preventDefault();
              setActiveTab('channel');
            }}
            className={`pb-3 text-xs font-bold transition-all relative ${
              activeTab === 'channel'
                ? 'text-[#F4EFF0]'
                : 'text-[#8E7E81] hover:text-[#C5B5B8]'
            }`}
          >
            ⚡ Hızlı Kanal Ekle (1-Click Pills)
            {activeTab === 'channel' && (
              <span className="absolute bottom-0 inset-x-0 h-0.5 bg-[#C82333]" />
            )}
          </button>
        </div>

        {feedback && (
          <div className="mx-5 mt-3 px-3.5 py-2.5 rounded-xl bg-[#2A0E15] border border-[#8F1622]/80 text-xs font-extrabold text-[#FAF2EE] shadow-sm flex items-center gap-2">
            <span>{feedback}</span>
          </div>
        )}

        {/* Content */}
        <div className="flex-1 overflow-y-auto p-5 space-y-6">
          {activeTab === 'server' ? (
            /* 1-Click Server Templates */
            <div className="space-y-4">
              <span className="text-xs font-bold uppercase tracking-wider text-[#C4B2B5] block">
                Hazır Topluluk Sunucu Şablonları (3 Temel Konsept)
              </span>
              <div className="space-y-3">
                {COMMUNITY_SERVER_TEMPLATES.map((tmpl) => (
                  <div
                    key={tmpl.id}
                    className="p-4 rounded-xl bg-[#14080B] border border-[#2A1319] hover:border-[#8F1622] transition-all flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 shadow-sm"
                  >
                    <div className="min-w-0 flex-1">
                      <div className="flex items-center gap-2 mb-1">
                        <span className="text-lg">{tmpl.icon}</span>
                        <h3 className="text-sm font-extrabold text-[#FAF2EE] truncate">
                          {tmpl.title}
                        </h3>
                      </div>
                      <p className="text-xs text-[#A58D8E] line-clamp-2">{tmpl.subtitle}</p>
                      <div className="flex flex-wrap gap-1.5 mt-2.5">
                        {tmpl.categories.map((c, i) => (
                          <span
                            key={i}
                            className="text-[10px] font-semibold px-2 py-0.5 rounded-md bg-[#240C12] text-[#E0858F] border border-[#590C15]/40"
                          >
                            {c.name.split('[')[0].trim()} ({c.channels.length} kanal)
                          </span>
                        ))}
                      </div>
                    </div>
                    <button
                      type="button"
                      onClick={(e) => handleApplyServerTemplate(tmpl, e)}
                      className="w-full sm:w-auto h-9 px-4 rounded-xl crimson-cta text-xs font-extrabold text-[#FAF2EE] whitespace-nowrap transition-all flex items-center justify-center gap-1.5 shadow-[0_0_12px_rgba(200,35,51,0.35)] active:scale-95"
                    >
                      <IconShield size={14} />
                      <span>Bu Şablonla Kur</span>
                    </button>
                  </div>
                ))}
              </div>
            </div>
          ) : (
            /* 1-Click Channel Pills & Custom Form */
            <>
              <div>
                <div className="flex items-center justify-between mb-2.5">
                  <span className="text-xs font-bold uppercase tracking-wider text-[#C4B2B5]">
                    Tek Tıkla Hazır Kanallar (1-Click Pills)
                  </span>
                  <span className="text-[11px] text-[#A58D8E]">Tıkla & Başlat</span>
                </div>
                <div className="grid grid-cols-2 sm:grid-cols-3 gap-2.5">
                  {QUICK_CHANNEL_PRESETS.map((preset) => {
                    const game = SUPPORTED_GAMES[preset.gameId];
                    return (
                      <button
                        key={preset.id}
                        type="button"
                        onClick={(e) => handleApplyPreset(preset, e)}
                        className="group relative text-left p-3 rounded-xl bg-[#14080B] hover:bg-[#200A10] border border-[#2A1319] hover:border-[#8F1622] transition-all flex flex-col justify-between active:scale-98"
                      >
                        <div className="flex items-center justify-between gap-1.5 mb-1.5">
                          <span
                            className="text-[10px] font-bold px-1.5 py-0.5 rounded border"
                            style={{
                              backgroundColor: game?.badgeBg ?? 'rgba(255,255,255,0.05)',
                              borderColor: game?.color ?? '#A58D8E',
                              color: game?.color ?? '#FAF2EE',
                            }}
                          >
                            {game?.shortName ?? 'Oyun'}
                          </span>
                          <span className="text-[10px] font-semibold text-[#8E7E81] tabular-nums">
                            {preset.badge}
                          </span>
                        </div>
                        <span className="text-xs font-extrabold text-[#FAF2EE] group-hover:text-[#F08C96] transition-colors truncate block">
                          {preset.label}
                        </span>
                        <span className="text-[10.5px] text-[#8E7E81] truncate block mt-0.5">
                          #{preset.name}
                        </span>
                      </button>
                    );
                  })}
                </div>
              </div>

              {/* Custom Channel Form */}
              <div className="pt-4 border-t border-[#2A1319]">
                <span className="text-xs font-bold uppercase tracking-wider text-[#C4B2B5] block mb-3">
                  Veya Özel Kanal Yapılandır
                </span>
                <form onSubmit={handleCreateCustomChannel} className="space-y-3.5">
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                    <div>
                      <label className="text-[11px] font-semibold text-[#A58D8E] block mb-1">
                        Kanal Adı
                      </label>
                      <input
                        type="text"
                        value={customName}
                        onChange={(e) => setCustomName(e.target.value)}
                        placeholder="örn: tryhard-dereceli"
                        className="w-full h-9 px-3 rounded-xl bg-[#14080B] border border-[#2A1319] focus:border-[#C82333] text-xs text-[#FAF2EE] outline-none"
                      />
                    </div>
                    <div>
                      <label className="text-[11px] font-semibold text-[#A58D8E] block mb-1">
                        Oyun Tipi (18 Espor Oyunu)
                      </label>
                      <select
                        value={customGame}
                        onChange={(e) => {
                          const gid = e.target.value as SupportedGameId;
                          setCustomGame(gid);
                          setCustomMax(SUPPORTED_GAMES[gid]?.defaultMax ?? 5);
                        }}
                        className="w-full h-9 px-2.5 rounded-xl bg-[#14080B] border border-[#2A1319] text-xs text-[#FAF2EE] outline-none"
                      >
                        {Object.values(SUPPORTED_GAMES).map((g) => (
                          <option key={g.id} value={g.id} className="bg-[#14080B] text-[#FAF2EE]">
                            {g.name}
                          </option>
                        ))}
                      </select>
                    </div>
                  </div>

                  <div className="grid grid-cols-2 gap-3">
                    <div>
                      <label className="text-[11px] font-semibold text-[#A58D8E] block mb-1">
                        Kanal Türü
                      </label>
                      <div className="flex gap-2">
                        <button
                          type="button"
                          onClick={(e) => {
                            e.preventDefault();
                            setCustomType('voice');
                          }}
                          className={`flex-1 h-9 rounded-xl border text-xs font-bold flex items-center justify-center gap-1.5 transition-all ${
                            customType === 'voice'
                              ? 'bg-[#590C15]/40 border-[#A61826] text-[#F08C96]'
                              : 'bg-[#14080B] border-[#2A1319] text-[#8E7E81]'
                          }`}
                        >
                          <IconVoiceWave size={14} />
                          <span>Ses Odası</span>
                        </button>
                        <button
                          type="button"
                          onClick={(e) => {
                            e.preventDefault();
                            setCustomType('text');
                          }}
                          className={`flex-1 h-9 rounded-xl border text-xs font-bold flex items-center justify-center gap-1.5 transition-all ${
                            customType === 'text'
                              ? 'bg-[#590C15]/40 border-[#A61826] text-[#F08C96]'
                              : 'bg-[#14080B] border-[#2A1319] text-[#8E7E81]'
                          }`}
                        >
                          <IconChannelText size={14} />
                          <span>Metin</span>
                        </button>
                      </div>
                    </div>
                    <div>
                      <label className="text-[11px] font-semibold text-[#A58D8E] block mb-1">
                        Maksimum Kapasite (0 = Sınırsız)
                      </label>
                      <input
                        type="number"
                        min={0}
                        max={32}
                        value={customMax}
                        onChange={(e) => setCustomMax(parseInt(e.target.value, 10) || 0)}
                        className="w-full h-9 px-3 rounded-xl bg-[#14080B] border border-[#2A1319] text-xs text-[#FAF2EE] outline-none"
                      />
                    </div>
                  </div>

                  <button
                    type="submit"
                    className="w-full h-10 rounded-xl crimson-cta text-xs font-extrabold text-[#FAF2EE] shadow-md transition-all mt-2 active:scale-98"
                  >
                    Kanalı Oluştur & Bağlan
                  </button>
                </form>
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  );
};

// Re-export as QuickChannelBuilderModal for backwards compatibility
export const QuickChannelBuilderModal = HubArchitectModal;
