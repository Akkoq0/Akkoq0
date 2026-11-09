'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Mobile Ergonomic Controls & Customizer Sheet
// ─────────────────────────────────────────────────────────
// Allows mobile players to customize thumb orientation (Right vs Left hand),
// Voice transmission mode (Open Mic VAD vs Floating Thumb PTT),
// and Interface compactness for competitive mobile esports.

import React from 'react';
import { useAppStore } from '@/lib/store';
import { IconClose } from '@/components/ui/MevaIcons';

export const MobileCustomizerSheet: React.FC = () => {
  const show = useAppStore((s) => s.showMobileCustomizer);
  const setShow = useAppStore((s) => s.setShowMobileCustomizer);
  const handMode = useAppStore((s) => s.mobileHandMode);
  const setHandMode = useAppStore((s) => s.setMobileHandMode);
  const density = useAppStore((s) => s.mobileDensity);
  const setDensity = useAppStore((s) => s.setMobileDensity);
  const voiceMode = useAppStore((s) => s.mobileVoiceMode);
  const setVoiceMode = useAppStore((s) => s.setMobileVoiceMode);
  const ecoEnabled = useAppStore((s) => s.ecoMode.isEnabled);
  const toggleEcoEnabled = useAppStore((s) => s.toggleEcoEnabled);
  const ecoCpu = useAppStore((s) => s.ecoMode.cpuEstimate);

  // Quick Action Bridges
  const setShowRadialWheel = useAppStore((s) => s.setShowRadialCommandWheel);
  const setShowSoundboard = useAppStore((s) => s.setShowSoundboardModal);
  const setShowScrim = useAppStore((s) => s.setShowScrimScheduleModal);

  if (!show) return null;

  return (
    <div
      className="fixed inset-0 z-50 flex items-end justify-center bg-black/80 backdrop-blur-sm animate-fadeIn"
      onClick={() => setShow(false)}
    >
      <div
        className="w-full max-w-lg rounded-t-3xl bg-[#0D090B] border-t border-x border-[#8F1622]/50 p-5 shadow-[0_-12px_40px_rgba(0,0,0,0.9)] max-h-[88vh] overflow-y-auto space-y-5"
        style={{ paddingBottom: 'calc(env(safe-area-inset-bottom, 20px) + 16px)' }}
        onClick={(e) => e.stopPropagation()}
        role="dialog"
        aria-modal="true"
        aria-labelledby="mobile-customizer-title"
      >
        {/* Grab Handle */}
        <div className="w-12 h-1.5 rounded-full bg-[#3B141E] mx-auto -mt-1" />

        {/* Header */}
        <div className="flex items-center justify-between border-b border-[#241116] pb-3">
          <div className="flex items-center gap-2.5">
            <span className="text-xl">📐</span>
            <div>
              <h2
                id="mobile-customizer-title"
                className="text-base font-black text-[#FAF2EE] tracking-wide"
              >
                MOBİL KONTROL & ERGONOMİ
              </h2>
              <p className="text-[11px] text-[#A8989B]">
                Tek elle başparmak erişimi, arayüz yoğunluğu ve ses modu
              </p>
            </div>
          </div>
          <button
            type="button"
            onClick={() => setShow(false)}
            aria-label="Kapat"
            className="w-8 h-8 rounded-xl bg-[#1C0B10] hover:bg-[#2E1218] border border-[#2E1218] text-[#9E8E91] hover:text-[#FAF2EE] flex items-center justify-center transition-colors"
          >
            <IconClose size={14} />
          </button>
        </div>

        {/* ── 1. ERGONOMİK EL SEÇİMİ (THUMB REACH) ── */}
        <div className="space-y-2">
          <span className="text-[11px] font-black uppercase tracking-wider text-[#E08C96] block">
            1. BAŞPARMAK KULLANIM ELİ
          </span>
          <div className="grid grid-cols-2 gap-2">
            <button
              type="button"
              onClick={() => setHandMode('right')}
              className={`p-3 rounded-2xl border text-left transition-all ${
                handMode === 'right'
                  ? 'bg-gradient-to-br from-[#2E1218] to-[#12070A] border-[#FF4655] shadow-[0_0_14px_rgba(200,35,51,0.3)]'
                  : 'bg-[#12080B] border-[#241116] text-[#9E8E91]'
              }`}
            >
              <div className="flex items-center justify-between mb-1">
                <span className="text-lg">👉</span>
                {handMode === 'right' && (
                  <span className="w-2 h-2 rounded-full bg-[#FF4655] animate-pulse" />
                )}
              </div>
              <span className="block text-xs font-black text-[#FAF2EE]">Sağ El Modu</span>
              <span className="block text-[10px] text-[#8E7E81] mt-0.5">
                Mikrofon ve ana tuşlar sağ alt köşeye hizalanır.
              </span>
            </button>

            <button
              type="button"
              onClick={() => setHandMode('left')}
              className={`p-3 rounded-2xl border text-left transition-all ${
                handMode === 'left'
                  ? 'bg-gradient-to-br from-[#2E1218] to-[#12070A] border-[#FF4655] shadow-[0_0_14px_rgba(200,35,51,0.3)]'
                  : 'bg-[#12080B] border-[#241116] text-[#9E8E91]'
              }`}
            >
              <div className="flex items-center justify-between mb-1">
                <span className="text-lg">👈</span>
                {handMode === 'left' && (
                  <span className="w-2 h-2 rounded-full bg-[#FF4655] animate-pulse" />
                )}
              </div>
              <span className="block text-xs font-black text-[#FAF2EE]">Sol El Modu</span>
              <span className="block text-[10px] text-[#8E7E81] mt-0.5">
                Mikrofon ve ana tuşlar sol alt köşeye hizalanır.
              </span>
            </button>
          </div>
        </div>

        {/* ── 2. MOBİL SES İLETİM MODU ── */}
        <div className="space-y-2">
          <span className="text-[11px] font-black uppercase tracking-wider text-[#E08C96] block">
            2. SES İLETİM VE MİKROFON MODU
          </span>
          <div className="grid grid-cols-2 gap-2">
            <button
              type="button"
              onClick={() => setVoiceMode('vad')}
              className={`p-3 rounded-2xl border text-left transition-all ${
                voiceMode === 'vad'
                  ? 'bg-gradient-to-br from-[#2E1218] to-[#12070A] border-[#22C55E] shadow-[0_0_14px_rgba(34,197,94,0.25)]'
                  : 'bg-[#12080B] border-[#241116] text-[#9E8E91]'
              }`}
            >
              <div className="flex items-center justify-between mb-1">
                <span className="text-lg">🎙️</span>
                {voiceMode === 'vad' && (
                  <span className="w-2 h-2 rounded-full bg-[#22C55E] animate-pulse" />
                )}
              </div>
              <span className="block text-xs font-black text-[#FAF2EE]">Açık Mikrofon (VAD)</span>
              <span className="block text-[10px] text-[#8E7E81] mt-0.5">
                Konuştuğunuzda otomatik iletir, tuşa basmanıza gerek kalmaz.
              </span>
            </button>

            <button
              type="button"
              onClick={() => setVoiceMode('ptt')}
              className={`p-3 rounded-2xl border text-left transition-all ${
                voiceMode === 'ptt'
                  ? 'bg-gradient-to-br from-[#2E1218] to-[#12070A] border-[#38BDF8] shadow-[0_0_14px_rgba(56,189,248,0.25)]'
                  : 'bg-[#12080B] border-[#241116] text-[#9E8E91]'
              }`}
            >
              <div className="flex items-center justify-between mb-1">
                <span className="text-lg">🔘</span>
                {voiceMode === 'ptt' && (
                  <span className="w-2 h-2 rounded-full bg-[#38BDF8] animate-pulse" />
                )}
              </div>
              <span className="block text-xs font-black text-[#FAF2EE]">Yüzen Başparmak PTT</span>
              <span className="block text-[10px] text-[#8E7E81] mt-0.5">
                Köşede daima hazır duran devasa bas-konuş tuşu.
              </span>
            </button>
          </div>
        </div>

        {/* ── 3. ARAYÜZ YOĞUNLUĞU (COMPACTNESS) ── */}
        <div className="space-y-2">
          <span className="text-[11px] font-black uppercase tracking-wider text-[#E08C96] block">
            3. ARAYÜZ VE SOHBET YOĞUNLUĞU
          </span>
          <div className="grid grid-cols-2 gap-2">
            <button
              type="button"
              onClick={() => setDensity('compact')}
              className={`p-3 rounded-2xl border text-left transition-all ${
                density === 'compact'
                  ? 'bg-gradient-to-br from-[#2E1218] to-[#12070A] border-[#FF4655] shadow-xs'
                  : 'bg-[#12080B] border-[#241116] text-[#9E8E91]'
              }`}
            >
              <span className="block text-xs font-black text-[#FAF2EE]">Kompakt Espor (Önerilen)</span>
              <span className="block text-[10px] text-[#8E7E81] mt-0.5">
                Daha daraltılmış kartlar, tek ekranda maksimum bilgi ve oyuncu.
              </span>
            </button>

            <button
              type="button"
              onClick={() => setDensity('comfortable')}
              className={`p-3 rounded-2xl border text-left transition-all ${
                density === 'comfortable'
                  ? 'bg-gradient-to-br from-[#2E1218] to-[#12070A] border-[#FF4655] shadow-xs'
                  : 'bg-[#12080B] border-[#241116] text-[#9E8E91]'
              }`}
            >
              <span className="block text-xs font-black text-[#FAF2EE]">Geniş / Rahat</span>
              <span className="block text-[10px] text-[#8E7E81] mt-0.5">
                Daha büyük dokunma hedefleri ve aralıklı kart görünümü.
              </span>
            </button>
          </div>
        </div>

        {/* ── 4. DONANIM VE OYUN OPTİMİZASYONU (ULTRA-LOW OVERHEAD) ── */}
        <div className="space-y-2 pt-1 border-t border-[#241116]">
          <span className="text-[11px] font-black uppercase tracking-wider text-[#E08C96] block">
            4. OYUN & DONANIM OPTİMİZASYONU (GAME BOOST)
          </span>
          <button
            type="button"
            onClick={toggleEcoEnabled}
            className={`w-full p-3.5 rounded-2xl border text-left transition-all flex items-center justify-between gap-3 ${
              ecoEnabled
                ? 'bg-gradient-to-r from-[#173822] to-[#0D1F13] border-emerald-500/80 shadow-[0_0_16px_rgba(16,185,129,0.25)]'
                : 'bg-[#140A0D] border-[#2C141A] text-[#9E8E91]'
            }`}
          >
            <div className="flex items-center gap-3 min-w-0">
              <span className="text-2xl">{ecoEnabled ? '⚡' : '💤'}</span>
              <div className="min-w-0">
                <span className="block text-xs font-black text-[#FAF2EE]">
                  {ecoEnabled ? 'Game-Boost & Eco Modu Aktif' : 'Game-Boost Kapalı'}
                </span>
                <span className="block text-[10px] text-[#A8989B] mt-0.5 leading-snug">
                  {ecoEnabled
                    ? `Oyunda ve arka planda CPU/GPU yükünü <%0.1 seviyesine kilitler, ısınmayı önler.`
                    : 'Açıldığında arka plandaki tüm animasyonları ve GPU filtrelerini dondurur.'}
                </span>
              </div>
            </div>
            <div className="flex flex-col items-end flex-shrink-0">
              <span
                className={`text-[9.5px] font-black px-2 py-0.5 rounded-full border ${
                  ecoEnabled
                    ? 'bg-emerald-950 text-emerald-300 border-emerald-500/50'
                    : 'bg-[#1C0D12] text-[#8E7E81] border-[#2E151C]'
                }`}
              >
                {ecoEnabled ? 'AKTİF • 0.1% CPU' : 'DEVRE DIŞI'}
              </span>
            </div>
          </button>
        </div>

        {/* ── 5. MOBİL HIZLI ARAÇLAR & KISAYOLLAR ── */}
        <div className="space-y-2 pt-1 border-t border-[#241116]">
          <span className="text-[11px] font-black uppercase tracking-wider text-[#E08C96] block">
            5. HIZLI KOMUTA ARAÇLARI
          </span>
          <div className="grid grid-cols-3 gap-2">
            <button
              type="button"
              onClick={() => {
                setShow(false);
                setShowRadialWheel(true);
              }}
              className="p-2.5 rounded-xl bg-[#140A0D] hover:bg-[#240F15] border border-[#2C141A] flex flex-col items-center gap-1 text-center"
            >
              <span className="text-base">🎯</span>
              <span className="text-[10px] font-bold text-[#FAF2EE]">IGL Çarkı</span>
            </button>

            <button
              type="button"
              onClick={() => {
                setShow(false);
                setShowSoundboard(true);
              }}
              className="p-2.5 rounded-xl bg-[#140A0D] hover:bg-[#240F15] border border-[#2C141A] flex flex-col items-center gap-1 text-center"
            >
              <span className="text-base">🎛️</span>
              <span className="text-[10px] font-bold text-[#FAF2EE]">Soundboard</span>
            </button>

            <button
              type="button"
              onClick={() => {
                setShow(false);
                setShowScrim(true);
              }}
              className="p-2.5 rounded-xl bg-[#140A0D] hover:bg-[#240F15] border border-[#2C141A] flex flex-col items-center gap-1 text-center"
            >
              <span className="text-base">📅</span>
              <span className="text-[10px] font-bold text-[#FAF2EE]">Turnuva</span>
            </button>
          </div>
        </div>

        {/* Action Button */}
        <button
          type="button"
          onClick={() => setShow(false)}
          className="w-full h-11 rounded-2xl crimson-cta text-sm font-black text-[#FAF2EE] shadow-[0_0_16px_rgba(200,35,51,0.4)] active:scale-98 transition-all flex items-center justify-center gap-2"
        >
          <span>Ayarları Kaydet ve Uygula</span>
          <span>✓</span>
        </button>
      </div>
    </div>
  );
};
