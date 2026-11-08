'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Interactive Walkthrough & Native Matrix Guide
// ─────────────────────────────────────────────────────────
// Clean, skip-friendly 3-step tour explaining:
//   1. 5-Player Live Tactical Matrix, Slot Beacons, Ducking & Duo-Link
//   2. P2P WebRTC Mesh Network & Radar (No central server, 11ms direct ping)
//   3. Native Server & Frequency Channel Architect (Build & Delete freely)

import React, { useState, useEffect, useCallback } from 'react';
import { useAppStore } from '@/lib/store';
import { getMevaStorageEngine, STORE_PREFS } from '@/src/lib/storageEngine';
import {
  IconClose,
  IconBolt,
  IconShield,
  IconVoiceWave,
  IconMapBoard,
  IconPlus,
  IconCheck,
} from '@/components/ui/MevaIcons';

interface InteractiveTourModalProps {
  isOpen: boolean;
  onClose: () => void;
  onOpenServerBuilder?: () => void;
}

export const InteractiveTourModal: React.FC<InteractiveTourModalProps> = ({
  isOpen,
  onClose,
  onOpenServerBuilder,
}) => {
  const [step, setStep] = useState<1 | 2 | 3>(1);
  const setShowChannelBuilderModal = useAppStore((s) => s.setShowChannelBuilderModal);

  const handleSkip = useCallback(() => {
    try {
      const storage = getMevaStorageEngine();
      storage.scheduleWrite(STORE_PREFS, 'tour_completed', true);
      void storage.flushPendingWrites();
    } catch {}
    onClose();
  }, [onClose]);

  useEffect(() => {
    if (!isOpen) return;
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') handleSkip();
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [isOpen, handleSkip]);

  if (!isOpen) return null;

  const handleFinishAndBuild = () => {
    handleSkip();
    if (onOpenServerBuilder) {
      onOpenServerBuilder();
    } else {
      setShowChannelBuilderModal(true);
    }
  };

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-3.5 sm:p-4 exec-backdrop select-none"
      onClick={handleSkip}
    >
      <div
        className="w-full max-w-xl bg-[#0D090B]/98 border border-[#8F1622]/55 rounded-2xl shadow-[0_24px_80px_rgba(0,0,0,0.88)] flex flex-col max-h-[92vh] overflow-hidden font-sans"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Top Header */}
        <div className="px-5 py-4 border-b border-[#2A1319] flex items-center justify-between bg-gradient-to-r from-[#1C0B10] via-[#0D090B] to-[#070607]">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-[#8F1622]/30 border border-[#C82333]/50 flex items-center justify-center text-[#F29AA3]">
              <IconBolt size={20} />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <span className="text-[10px] font-black tracking-widest text-[#C82333] uppercase">
                  MEVA KOKPİT REHBERİ
                </span>
                <span className="text-[10px] font-bold text-[#827376]">
                  Adım {step} / 3
                </span>
              </div>
              <h2 className="text-base font-extrabold text-[#F4EFF0] tracking-tight">
                {step === 1 && '1. Canlı Kadro Ses Matrisi & Akıllı Slot Beacon'}
                {step === 2 && '2. Uçtan Uca Doğrudan P2P Ağ Yapısı'}
                {step === 3 && '3. Komuta Mimarisi'}
              </h2>
              <p className="text-[11px] text-[#A8989B] font-medium mt-0.5">
                {step === 1 && '5\'li taktik kadronuzu kurun, eksik roller için sinyal bırakın.'}
                {step === 2 && 'Arada merkezi sunucu yok; gecikmesiz, güvenli ve şifreli ses iletişimi.'}
                {step === 3 && 'Kendi özel frekanslarınızı ve kanallarınızı saniyeler içinde inşa edin.'}
              </p>
            </div>
          </div>

          <button
            type="button"
            onClick={handleSkip}
            className="text-[11px] font-bold text-[#827376] hover:text-[#F4EFF0] px-2.5 py-1 rounded-lg hover:bg-[#1C0B10] border border-transparent hover:border-[#3D1820] transition-colors"
          >
            Turu Atla (Skip) ✕
          </button>
        </div>

        {/* Step Content */}
        <div className="p-6 overflow-y-auto space-y-4">
          {step === 1 && (
            <div className="space-y-4">
              <div className="p-4 rounded-xl bg-[#1C0B10]/50 border border-[#8F1622]/35 space-y-2">
                <div className="flex items-center gap-2 text-[#C82333] font-bold text-xs">
                  <IconVoiceWave size={16} />
                  <span>60 FPS ZERO-RE-RENDER SES MATRİSİ</span>
                </div>
                <p className="text-xs text-[#D8CBCE] leading-relaxed">
                  Meva HUD, oyun oynarken bilgisayarınıza sıfır donanım yükü bindirir. Ses dalgaları ve dBFS göstergeleri doğrudan DOM seviyesinde akar (%0 CPU/GPU dalgalanması).
                </p>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div className="p-3.5 rounded-xl bg-[#120A0D] border border-[#2A1319] space-y-1.5">
                  <div className="flex items-center gap-1.5 text-xs font-bold text-[#F4EFF0]">
                    <span className="text-amber-400">💡</span>
                    <span>Akıllı Boş Koltuk (Slot Beacon)</span>
                  </div>
                  <p className="text-[11.5px] text-[#A8989B] leading-normal">
                    Kadroda eksik olan rollere (örn: <em>Jungle</em> veya <em>AWP</em>) tek tıkla sinyal bırakın. Dışarıdaki oyuncular lobi keşfinde %98 uyumla doğrudan odaya çekilir.
                  </p>
                </div>

                <div className="p-3.5 rounded-xl bg-[#120A0D] border border-[#2A1319] space-y-1.5">
                  <div className="flex items-center gap-1.5 text-xs font-bold text-[#F4EFF0]">
                    <span className="text-[#C82333]">👑</span>
                    <span>%30 IGL Priority Ducking</span>
                  </div>
                  <p className="text-[11.5px] text-[#A8989B] leading-normal">
                    Takım kaptanı (IGL) konuştuğunda, arka plandaki tüm sesler otomatik %30 kısılır; kritik taktik çağrıları silah sesleri arasından net duyulur.
                  </p>
                </div>

                <div className="p-3.5 rounded-xl bg-[#120A0D] border border-[#2A1319] space-y-1.5">
                  <div className="flex items-center gap-1.5 text-xs font-bold text-cyan-300">
                    <span>🔗</span>
                    <span>Duo-Link (Özel Telsiz)</span>
                  </div>
                  <p className="text-[11.5px] text-[#A8989B] leading-normal">
                    Jungle & Mid gibi ikililer, <kbd className="px-1 py-0.5 rounded bg-[#1C0B10] text-[#F4EFF0] font-mono text-[10px]">B</kbd> tuşuna basarak diğer 3 kişiyi bölmeden kendi aralarında alt-telsiz görüşmesi yapabilir.
                  </p>
                </div>

                <div className="p-3.5 rounded-xl bg-[#120A0D] border border-[#2A1319] space-y-1.5">
                  <div className="flex items-center gap-1.5 text-xs font-bold text-red-400">
                    <span>📡</span>
                    <span>3D Akustik Sonar (Pulse)</span>
                  </div>
                  <p className="text-[11.5px] text-[#A8989B] leading-normal">
                    Klasik bildirimler yerine, oyuncunun kulaklığında soldan sağa süzülen 3D bir radar sinyali çalar ve kartını taktiksel bordo ışıkla titretir.
                  </p>
                </div>
              </div>
            </div>
          )}

          {step === 2 && (
            <div className="space-y-4">
              <div className="p-4 rounded-xl bg-[#1C0B10]/50 border border-[#8F1622]/35 space-y-2">
                <div className="flex items-center gap-2 text-[#C82333] font-bold text-xs">
                  <IconShield size={16} />
                  <span>UÇTAN UCA DOĞRUDAN P2P WEBRTC AĞI</span>
                </div>
                <p className="text-xs text-[#D8CBCE] leading-relaxed">
                  Meva&apos;da sesiniz üçüncü taraf merkezi bir sunucuya gitmez. Katılımcılar doğrudan uçtan uca (WebRTC DTLS-SRTP Mesh) birbirlerine bağlanır. Ping değeriniz 9–14ms ultra-düşük espor seviyesindedir.
                </p>
              </div>

              <div className="space-y-2.5">
                <div className="p-3 rounded-xl bg-[#120A0D] border border-[#2A1319] flex items-start gap-3">
                  <span className="text-emerald-400 font-bold text-sm">🔒</span>
                  <div>
                    <h4 className="text-xs font-bold text-[#F4EFF0]">ECDH P-256 + AES-256-GCM Kripto Kalkanı</h4>
                    <p className="text-[11.5px] text-[#A8989B] mt-0.5">
                      Her oturum için yerel donanımda benzersiz şifreleme anahtarları üretilir; harici kimse dinleyemez ve verileri manipüle edemez.
                    </p>
                  </div>
                </div>

                <div className="p-3 rounded-xl bg-[#120A0D] border border-[#2A1319] flex items-start gap-3">
                  <span className="text-cyan-400 font-bold text-sm">🌐</span>
                  <div>
                    <h4 className="text-xs font-bold text-[#F4EFF0]">CGNAT & Güvenlik Duvarı Geçişi (TURN Relay)</h4>
                    <p className="text-[11.5px] text-[#A8989B] mt-0.5">
                      Katı servis sağlayıcı veya kurumsal güvenlik duvarları arkasında olsanız bile Multi-STUN ve TLS 443 TURN yolları bağlantıyı kesintisiz korur.
                    </p>
                  </div>
                </div>
              </div>
            </div>
          )}

          {step === 3 && (
            <div className="space-y-4">
              <div className="p-4 rounded-xl bg-[#1C0B10]/50 border border-[#8F1622]/35 space-y-2">
                <div className="flex items-center gap-2 text-[#C82333] font-bold text-xs">
                  <IconPlus size={16} />
                  <span>ÖZGÜN KOMUTA FREKANSLARI MİMARI (HUB ARCHITECT)</span>
                </div>
                <p className="text-xs text-[#D8CBCE] leading-relaxed">
                  Sıfırdan kendi komuta merkezinizi kurun, dilediğiniz frekansları ekleyin ve yönetin. Hazır espor şablonları veya özel kanallarla takımınızı saniyeler içinde organize edin.
                </p>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-3 gap-2.5">
                <div className="p-3 rounded-xl bg-[#120A0D] border border-[#2A1319] text-center space-y-1">
                  <div className="text-xl">🎥</div>
                  <div className="text-xs font-bold text-[#F4EFF0]">YouTuber Hub</div>
                  <div className="text-[10.5px] text-[#827376]">LoL, CS2, Valo, PUBG ve Chill odaları</div>
                </div>

                <div className="p-3 rounded-xl bg-[#120A0D] border border-[#2A1319] text-center space-y-1">
                  <div className="text-xl">🏆</div>
                  <div className="text-xs font-bold text-[#F4EFF0]">Espor Karargahı</div>
                  <div className="text-[10.5px] text-[#827376]">Maç odaları, taktik koçluk ve yedek lobileri</div>
                </div>

                <div className="p-3 rounded-xl bg-[#120A0D] border border-[#2A1319] text-center space-y-1">
                  <div className="text-xl">⚡</div>
                  <div className="text-xs font-bold text-[#F4EFF0]">Serbest Agalar</div>
                  <div className="text-[10.5px] text-[#827376]">Sade, anında hazır oyun ve muhabbet odası</div>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Footer Navigation */}
        <div className="px-5 py-3.5 border-t border-[#2A1319] flex items-center justify-between bg-[#070607]">
          <div>
            {step > 1 ? (
              <button
                type="button"
                onClick={() => setStep((s) => (s - 1) as any)}
                className="px-3.5 py-1.5 rounded-xl text-xs font-bold text-[#827376] hover:text-[#F4EFF0] bg-[#120A0D] border border-[#2A1319] transition-colors"
              >
                ← Geri
              </button>
            ) : (
              <button
                type="button"
                onClick={handleSkip}
                className="px-3.5 py-1.5 rounded-xl text-xs font-bold text-[#827376] hover:text-[#F4EFF0] transition-colors"
              >
                Hızlı Geç (Skip)
              </button>
            )}
          </div>

          <div className="flex items-center gap-2">
            {step < 3 ? (
              <button
                type="button"
                onClick={() => setStep((s) => (s + 1) as any)}
                className="px-4 py-2 rounded-xl text-xs font-bold crimson-cta flex items-center gap-1.5 transition-all"
              >
                <span>İleri</span>
                <span>→</span>
              </button>
            ) : (
              <button
                type="button"
                onClick={handleFinishAndBuild}
                className="px-4 py-2 rounded-xl text-xs font-bold crimson-cta flex items-center gap-1.5 shadow-[0_0_16px_rgba(200,35,51,0.5)] transition-all"
              >
                <IconPlus size={14} />
                <span>Kendi Sunucunu Kur 🚀</span>
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};
