'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Hub Architect & Fast Frequency Spawner Modal
// ─────────────────────────────────────────────────────────
// Clean Code Architecture:
//   • Decoupled UI Presentation from Domain Logic via ServerArchitectService
//   • Business State & Actions encapsulated in useHubArchitect Hook (SRP)
//   • Modular sub-components with zero visual regression
//   • 100% Type-safe & Persistent across IndexedDB

import React from 'react';
import {
  COMMUNITY_SERVER_TEMPLATES,
  QUICK_CHANNEL_PRESETS,
  SUPPORTED_GAMES,
  type ServerTemplate,
  type QuickChannelPreset,
  type SupportedGameId,
} from '@/src/lib/gameRegistry';
import {
  IconClose,
  IconShield,
  IconVoiceWave,
  IconChannelText,
  IconBolt,
} from '@/components/ui/MevaIcons';
import { useHubArchitect } from '@/hooks/useHubArchitect';

interface HubArchitectModalProps {
  isOpen: boolean;
  onClose: () => void;
}

// ── Sub-Component: Server Templates ───────────────────────
const ServerTemplatesView: React.FC<{
  templates: ReadonlyArray<ServerTemplate>;
  onApply: (tmpl: ServerTemplate) => void;
}> = ({ templates, onApply }) => (
  <div className="space-y-4">
    <span className="text-xs font-bold uppercase tracking-wider text-[#C4B2B5] block">
      Hazır Topluluk Sunucu Şablonları (3 Temel Konsept)
    </span>
    <div className="space-y-3">
      {templates.map((tmpl) => (
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
            onClick={(e) => {
              e.preventDefault();
              onApply(tmpl);
            }}
            className="w-full sm:w-auto h-9 px-4 rounded-xl crimson-cta text-xs font-extrabold text-[#FAF2EE] whitespace-nowrap transition-all flex items-center justify-center gap-1.5 shadow-[0_0_12px_rgba(200,35,51,0.35)] active:scale-95"
          >
            <IconShield size={14} />
            <span>Bu Şablonla Kur</span>
          </button>
        </div>
      ))}
    </div>
  </div>
);

// ── Sub-Component: 1-Click Channel Pills ──────────────────
const QuickChannelPillsView: React.FC<{
  presets: ReadonlyArray<QuickChannelPreset>;
  onApplyPreset: (preset: QuickChannelPreset) => void;
}> = ({ presets, onApplyPreset }) => (
  <div>
    <div className="flex items-center justify-between mb-2.5">
      <span className="text-xs font-bold uppercase tracking-wider text-[#C4B2B5]">
        Tek Tıkla Hazır Kanallar (1-Click Pills)
      </span>
      <span className="text-[11px] text-[#A58D8E]">Tıkla & Başlat</span>
    </div>
    <div className="grid grid-cols-2 sm:grid-cols-3 gap-2.5">
      {presets.map((preset) => {
        const game = SUPPORTED_GAMES[preset.gameId];
        return (
          <button
            key={preset.id}
            type="button"
            onClick={(e) => {
              e.preventDefault();
              onApplyPreset(preset);
            }}
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
);

// ── Sub-Component: Custom Channel Form ────────────────────
const CustomChannelFormView: React.FC<{
  name: string;
  gameId: SupportedGameId;
  type: 'voice' | 'text';
  max: number;
  onNameChange: (val: string) => void;
  onGameChange: (gid: SupportedGameId) => void;
  onTypeChange: (type: 'voice' | 'text') => void;
  onMaxChange: (max: number) => void;
  onSubmit: (e: React.FormEvent) => void;
}> = ({
  name,
  gameId,
  type,
  max,
  onNameChange,
  onGameChange,
  onTypeChange,
  onMaxChange,
  onSubmit,
}) => (
  <div className="pt-4 border-t border-[#2A1319]">
    <span className="text-xs font-bold uppercase tracking-wider text-[#C4B2B5] block mb-3">
      Veya Özel Kanal Yapılandır
    </span>
    <form onSubmit={onSubmit} className="space-y-3.5">
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
        <div>
          <label className="text-[11px] font-semibold text-[#A58D8E] block mb-1">
            Kanal Adı
          </label>
          <input
            type="text"
            value={name}
            onChange={(e) => onNameChange(e.target.value)}
            placeholder="örn: tryhard-dereceli"
            className="w-full h-9 px-3 rounded-xl bg-[#14080B] border border-[#2A1319] focus:border-[#C82333] text-xs text-[#FAF2EE] outline-none"
          />
        </div>
        <div>
          <label className="text-[11px] font-semibold text-[#A58D8E] block mb-1">
            Oyun Tipi (18 Espor Oyunu)
          </label>
          <select
            value={gameId}
            onChange={(e) => onGameChange(e.target.value as SupportedGameId)}
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
                onTypeChange('voice');
              }}
              className={`flex-1 h-9 rounded-xl border text-xs font-bold flex items-center justify-center gap-1.5 transition-all ${
                type === 'voice'
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
                onTypeChange('text');
              }}
              className={`flex-1 h-9 rounded-xl border text-xs font-bold flex items-center justify-center gap-1.5 transition-all ${
                type === 'text'
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
            value={max}
            onChange={(e) => onMaxChange(parseInt(e.target.value, 10) || 0)}
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
);

// ── Main Presentational Modal ─────────────────────────────
export const HubArchitectModal: React.FC<HubArchitectModalProps> = ({ isOpen, onClose }) => {
  const {
    activeTab,
    setActiveTab,
    customName,
    setCustomName,
    customGame,
    handleGameChange,
    customType,
    setCustomType,
    customMax,
    setCustomMax,
    feedback,
    applyServerTemplate,
    applyPresetChannel,
    createCustomChannel,
  } = useHubArchitect(isOpen, onClose);

  if (!isOpen) return null;

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
            <ServerTemplatesView
              templates={COMMUNITY_SERVER_TEMPLATES}
              onApply={applyServerTemplate}
            />
          ) : (
            <>
              <QuickChannelPillsView
                presets={QUICK_CHANNEL_PRESETS}
                onApplyPreset={applyPresetChannel}
              />
              <CustomChannelFormView
                name={customName}
                gameId={customGame}
                type={customType}
                max={customMax}
                onNameChange={setCustomName}
                onGameChange={handleGameChange}
                onTypeChange={setCustomType}
                onMaxChange={setCustomMax}
                onSubmit={createCustomChannel}
              />
            </>
          )}
        </div>
      </div>
    </div>
  );
};

// Re-export for backwards compatibility
export const QuickChannelBuilderModal = HubArchitectModal;
