'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Esports Stratbook Preset Strategies Modal
// ─────────────────────────────────────────────────────────
// Curated competitive presets for LoL (Dignitas Jungle Route),
// Valorant (Bind & Breeze Pincers/Viper Walls), CS2 (Mirage & Inferno Smokes),
// and Dota 2 (7.33+ Twin Gate Gank & Farming Zones).

import React, { useState, useMemo } from 'react';
import {
  TacticalPresetStrat,
  TACTICAL_PRESET_STRATS,
  TacticalGameCategory,
  MAP_BLUEPRINTS,
  TacticalMapId,
} from './tacticalBlueprints';
import { IconClose } from '@/components/ui/MevaIcons';

interface TacticalPresetsModalProps {
  open: boolean;
  onClose: () => void;
  onApplyPreset: (preset: TacticalPresetStrat) => void;
  currentMapId: TacticalMapId;
}

export const TacticalPresetsModal: React.FC<TacticalPresetsModalProps> = ({
  open,
  onClose,
  onApplyPreset,
  currentMapId,
}) => {
  const [selectedFilter, setSelectedFilter] = useState<'all' | TacticalGameCategory>('all');
  const [searchQuery, setSearchQuery] = useState('');

  const filteredPresets = useMemo(() => {
    return TACTICAL_PRESET_STRATS.filter((p) => {
      if (selectedFilter !== 'all' && p.game !== selectedFilter) return false;
      if (!searchQuery) return true;
      const q = searchQuery.toLowerCase();
      return (
        p.title.toLowerCase().includes(q) ||
        p.description.toLowerCase().includes(q) ||
        p.tags.some((t) => t.toLowerCase().includes(q))
      );
    });
  }, [selectedFilter, searchQuery]);

  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-md animate-fadeIn">
      <div
        className="w-full max-w-3xl max-h-[85vh] flex flex-col rounded-2xl bg-[#0D090B] border border-[#8F1622]/40 shadow-[0_16px_50px_rgba(0,0,0,0.8)] overflow-hidden"
        role="dialog"
        aria-modal="true"
        aria-labelledby="preset-modal-title"
      >
        {/* Header */}
        <div className="p-4 sm:p-5 border-b border-[#241116] bg-gradient-to-r from-[#1C0B10] via-[#0D090B] to-[#070607] flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-[#8F1622]/20 border border-[#8F1622]/60 flex items-center justify-center text-xl shadow-[0_0_12px_rgba(143,22,34,0.3)]">
              📋
            </div>
            <div>
              <h2
                id="preset-modal-title"
                className="text-base sm:text-lg font-black text-[#FAF2EE] tracking-wide"
              >
                PRO STRATBOOK ŞABLONLARI
              </h2>
              <p className="text-xs text-[#9E8E91]">
                Profesyonel espor maçları, sis dizilimleri, orman rotaları ve anlık taktikler (2026 Meta)
              </p>
            </div>
          </div>
          <button
            type="button"
            onClick={onClose}
            aria-label="Kapat"
            className="w-8 h-8 rounded-xl bg-[#140A0D] hover:bg-[#220D13] border border-[#2C141A] text-[#9E8E91] hover:text-[#FAF2EE] flex items-center justify-center transition-colors"
          >
            <IconClose size={14} />
          </button>
        </div>

        {/* Filter Bar & Search */}
        <div className="p-3 sm:px-5 border-b border-[#1E0B11] bg-[#0A0608] flex flex-wrap items-center justify-between gap-2.5">
          {/* Game Category Filters */}
          <div className="flex items-center gap-1.5 overflow-x-auto">
            {[
              { id: 'all', label: 'TÜMÜ' },
              { id: 'lol', label: 'LEAGUE OF LEGENDS' },
              { id: 'valorant', label: 'VALORANT' },
              { id: 'cs2', label: 'COUNTER-STRIKE 2' },
              { id: 'dota2', label: 'DOTA 2' },
            ].map((f) => (
              <button
                key={f.id}
                type="button"
                onClick={() => setSelectedFilter(f.id as typeof selectedFilter)}
                className={`h-7 px-2.5 rounded-lg text-xs font-bold transition-all whitespace-nowrap border ${
                  selectedFilter === f.id
                    ? 'bg-[#8F1622] text-[#FAF2EE] border-[#FF4655] shadow-xs'
                    : 'bg-[#12080B] text-[#9E8E91] hover:text-[#FAF2EE] border-[#241116]'
                }`}
              >
                {f.label}
              </button>
            ))}
          </div>

          {/* Search Input */}
          <div className="relative w-full sm:w-56">
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Şablon veya etiket ara..."
              className="w-full h-7 pl-7 pr-3 text-xs bg-[#12080B] text-[#FAF2EE] placeholder-[#6E5E61] rounded-lg border border-[#241116] focus:border-[#C82333] focus:outline-none transition-colors"
            />
            <span className="absolute left-2 top-1.5 text-xs text-[#6E5E61]">🔍</span>
          </div>
        </div>

        {/* Presets List */}
        <div className="p-4 sm:p-5 overflow-y-auto max-h-[58vh] space-y-3 custom-scrollbar">
          {filteredPresets.length === 0 ? (
            <div className="text-center py-12 text-[#9E8E91]">
              <span className="text-3xl block mb-2">🔍</span>
              <p className="text-sm font-bold">Aranan kriterlere uygun şablon bulunamadı.</p>
              <p className="text-xs text-[#6E5E61] mt-1">Filtreleri veya arama kelimesini değiştirmeyi deneyin.</p>
            </div>
          ) : (
            filteredPresets.map((preset) => {
              const spec = MAP_BLUEPRINTS[preset.mapId as Exclude<TacticalMapId, 'custom'>];
              const isCurrentMap = preset.mapId === currentMapId;

              let gameBadgeBg = 'bg-blue-950/60 text-blue-300 border-blue-600/40';
              if (preset.game === 'valorant') gameBadgeBg = 'bg-rose-950/60 text-rose-300 border-rose-600/40';
              if (preset.game === 'cs2') gameBadgeBg = 'bg-amber-950/60 text-amber-300 border-amber-600/40';
              if (preset.game === 'dota2') gameBadgeBg = 'bg-purple-950/60 text-purple-300 border-purple-600/40';

              return (
                <div
                  key={preset.id}
                  className="p-3.5 sm:p-4 rounded-xl bg-[#12080B] border border-[#241116] hover:border-[#8F1622]/60 transition-all flex flex-col sm:flex-row sm:items-center justify-between gap-4 group hover:shadow-[0_4px_20px_rgba(143,22,34,0.15)]"
                >
                  <div className="flex-1 space-y-1.5">
                    <div className="flex items-center gap-2 flex-wrap">
                      <span className={`text-[10px] font-black uppercase px-2 py-0.5 rounded-md border ${gameBadgeBg}`}>
                        {preset.game.toUpperCase()}
                      </span>
                      <span className="text-[10px] font-bold px-2 py-0.5 rounded-md bg-[#1C0B10] text-[#F08C96] border border-[#8F1622]/40">
                        🗺️ {spec?.title || preset.mapId}
                      </span>
                      {isCurrentMap && (
                        <span className="text-[9.5px] font-extrabold px-1.5 py-0.5 rounded bg-emerald-950/80 text-emerald-300 border border-emerald-600/40">
                          Aktif Harita
                        </span>
                      )}
                    </div>

                    <h3 className="text-sm sm:text-base font-extrabold text-[#FAF2EE] group-hover:text-white transition-colors">
                      {preset.title}
                    </h3>
                    <p className="text-xs text-[#9E8E91] leading-relaxed">
                      {preset.description}
                    </p>

                    {/* Tags & Op Count */}
                    <div className="flex items-center gap-1.5 pt-1 flex-wrap">
                      {preset.tags.map((tag) => (
                        <span
                          key={tag}
                          className="text-[9px] font-bold px-1.5 py-0.5 rounded bg-[#180B10] text-[#B8AAAC] border border-[#2A1319]"
                        >
                          #{tag}
                        </span>
                      ))}
                      <span className="text-[9.5px] font-mono text-[#6E5E61] ml-auto">
                        {preset.operations.length} Taktiksel Katman
                      </span>
                    </div>
                  </div>

                  {/* Apply Button */}
                  <div className="flex-shrink-0 flex items-center justify-end">
                    <button
                      type="button"
                      onClick={() => onApplyPreset(preset)}
                      className="w-full sm:w-auto h-8 px-4 rounded-xl crimson-cta text-[#FAF2EE] font-black text-xs flex items-center justify-center gap-2 shadow-[0_0_12px_rgba(200,35,51,0.35)] hover:scale-102 active:scale-98 transition-all"
                    >
                      <span>Masaya Uygula</span>
                      <span>⚡</span>
                    </button>
                  </div>
                </div>
              );
            })
          )}
        </div>

        {/* Footer */}
        <div className="p-3 sm:px-5 border-t border-[#1E0B11] bg-[#0A0608] flex items-center justify-between text-xs text-[#6E5E61]">
          <span>💡 Şablon uygulandığında çizimler WebRTC mesh ağıyla tüm takıma canlı aktarılır.</span>
          <button
            type="button"
            onClick={onClose}
            className="px-3 h-7 rounded-lg bg-[#140A0D] text-[#B8AAAC] hover:text-[#FAF2EE] text-xs font-bold border border-[#241116] transition-colors"
          >
            Kapat
          </button>
        </div>
      </div>
    </div>
  );
};
