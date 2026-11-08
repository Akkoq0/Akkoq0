'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Operator Onboarding & Tactical Lobby Gate
// ─────────────────────────────────────────────────────────
// Production-grade lobby gate:
//   • Operator Callsign & Tactical Role selection (IGL, AWP, ENTRY, SUPPORT, LURKER)
//   • One-click "Yeni Taktik Oda Kur" (MEVA-XXXX code generation)
//   • "Oda Koduyla Katıl" (input validation & instant mesh entry)
//   • IndexedDB persistence & zero-re-render atomic store hydration

import React, { useState, useEffect } from 'react';
import { useAppStore } from '@/lib/store';
import { useHUDStore, type TacticalRole } from '@/store/useHUDStore';
import { getMevaStorageEngine, STORE_PREFS } from '@/src/lib/storageEngine';
import {
  IconMevaMark,
  IconShield,
  IconClose,
} from '@/components/ui/MevaIcons';

interface LobbyGateModalProps {
  isOpen: boolean;
  onClose?: () => void;
  onJoinedRoom?: (roomCode: string, callsign: string, role: TacticalRole) => void;
}

const TACTICAL_ROLES: ReadonlyArray<{
  role: TacticalRole;
  label: string;
  desc: string;
  badgeClass: string;
}> = [
  {
    role: 'IGL',
    label: 'IGL',
    desc: 'Takım Lideri · Öncelikli Konuşma & Taktik Ducking',
    badgeClass: 'bg-[#3D0A14] text-[#E04856] border-[#7A121D]',
  },
  {
    role: 'AWP',
    label: 'AWP / Sniper',
    desc: 'Uzun Hat Nişancısı · Keskin Tiz DSP & Net İletişim',
    badgeClass: 'bg-[#2A180E] text-[#E68A4E] border-[#663A1E]',
  },
  {
    role: 'ENTRY',
    label: 'Entry Fragger',
    desc: 'İlk Temas Operatörü · Dengeli Dinamik EQ',
    badgeClass: 'bg-[#2A0E1A] text-[#D65D9E] border-[#5E1A38]',
  },
  {
    role: 'LURKER',
    label: 'Lurker / Flank',
    desc: 'Arka Hat Avcısı · 3D Mekansal Ses Önceliği',
    badgeClass: 'bg-[#121E2A] text-[#5DA5D6] border-[#1E435E]',
  },
  {
    role: 'COACH',
    label: 'Support / Koç',
    desc: 'Strateji Analisti · Düşük Gecikmeli İzleme Modu',
    badgeClass: 'bg-[#1A1A1E] text-[#A0A0A8] border-[#383842]',
  },
];

export const LobbyGateModal: React.FC<LobbyGateModalProps> = ({
  isOpen,
  onClose,
  onJoinedRoom,
}) => {
  const [callsign, setCallsign] = useState('Operatör');
  const [selectedRole, setSelectedRole] = useState<TacticalRole>('IGL');
  const [roomInput, setRoomInput] = useState('');
  const [activeTab, setActiveTab] = useState<'create' | 'join'>('create');
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const setShowLobbyGate = useAppStore((s) => s.setShowLobbyGate);

  // Load saved identity from IndexedDB on initial mount
  useEffect(() => {
    let cancelled = false;
    async function loadSavedProfile() {
      try {
        const storage = getMevaStorageEngine();
        const saved = await storage.getRecord<{
          callsign: string;
          role: TacticalRole;
        }>(STORE_PREFS, 'operator_identity');
        if (!cancelled && saved) {
          if (saved.callsign) setCallsign(saved.callsign);
          if (saved.role) setSelectedRole(saved.role);
        }
      } catch {}
    }
    void loadSavedProfile();
    return () => {
      cancelled = true;
    };
  }, []);

  if (!isOpen) return null;

  const generateRoomCode = () => {
    const num = Math.floor(1000 + Math.random() * 9000);
    return `MEVA-${num}`;
  };

  const handleCreateRoom = async () => {
    const cleanName = callsign.trim().slice(0, 24) || 'Operatör';
    const roomCode = generateRoomCode();

    // Persist identity to IndexedDB
    const storage = getMevaStorageEngine();
    storage.scheduleWrite(STORE_PREFS, 'operator_identity', {
      callsign: cleanName,
      role: selectedRole,
    });

    useHUDStore.getState().setOperatorRole('usr-local', selectedRole);
    useAppStore.getState().setActiveVoiceChannel(`scrim-${roomCode}`);
    useAppStore.getState().setActiveScrimRoom({
      code: roomCode,
      name: `Taktik Lobi ${roomCode}`,
      created_by: 'usr-local',
      password: null,
      max_participants: 5,
      created_at: Date.now(),
      ttl: 3 * 60 * 60 * 1000,
    });

    onJoinedRoom?.(roomCode, cleanName, selectedRole);
    onClose?.();
  };

  const handleJoinRoom = async () => {
    const cleanName = callsign.trim().slice(0, 24) || 'Operatör';
    let code = roomInput.trim().toUpperCase();

    // Support full invite links or hash URLs
    if (code.includes('MEVA-')) {
      const match = code.match(/MEVA-\d{4}/);
      if (match) code = match[0];
    } else if (code.length === 4 && /^\d+$/.test(code)) {
      code = `MEVA-${code}`;
    }

    if (!code || code.length < 6) {
      setErrorMsg('Geçerli bir 6 haneli oda kodu girin (Örn: MEVA-8492)');
      return;
    }

    // Persist identity to IndexedDB
    const storage = getMevaStorageEngine();
    storage.scheduleWrite(STORE_PREFS, 'operator_identity', {
      callsign: cleanName,
      role: selectedRole,
    });

    useHUDStore.getState().setOperatorRole('usr-local', selectedRole);
    useAppStore.getState().setActiveVoiceChannel(`scrim-${code}`);
    useAppStore.getState().setActiveScrimRoom({
      code,
      name: `Taktik Lobi ${code}`,
      created_by: 'peer-remote',
      password: null,
      max_participants: 5,
      created_at: Date.now(),
      ttl: 3 * 60 * 60 * 1000,
    });

    onJoinedRoom?.(code, cleanName, selectedRole);
    onClose?.();
  };

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-5 exec-backdrop select-none font-sans tabular-nums"
      onClick={onClose}
    >
      <div
        className="relative w-full max-w-[480px] bg-[#0E090B] border border-[#2A1319] rounded-2xl shadow-2xl flex flex-col overflow-hidden"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header Bar */}
        <div className="h-14 px-5 border-b border-[#1E0F13] flex items-center justify-between bg-[linear-gradient(90deg,rgba(19,9,13,0.95)_0%,rgba(32,12,18,0.95)_100%)]">
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-lg bg-[#2E0B13] border border-[#7A121D]/60 flex items-center justify-center text-[#E04856]">
              <IconMevaMark size={18} />
            </div>
            <div>
              <div className="text-[14px] font-extrabold text-[#F5EBE6] tracking-tight">
                Meva Komuta Kapısı
              </div>
              <div className="text-[10.5px] font-medium text-[#8F7D80]">
                Operatör Kimliği & Gerçek Zamanlı P2P Lobi
              </div>
            </div>
          </div>
          <div className="flex items-center gap-1.5">
            <button
              type="button"
              onClick={() => {
                setShowLobbyGate(false);
                if (onClose) onClose();
              }}
              className="text-xs font-bold text-[#F08C96] hover:text-[#FAF2EE] px-2.5 py-1 rounded-lg bg-[#2A0910] hover:bg-[#4A0E18] border border-[#7A121D]/50 transition-all flex items-center gap-1"
            >
              <span>Hızlı Geç</span>
              <span>⏩</span>
            </button>
            {onClose && (
              <button
                type="button"
                onClick={onClose}
                aria-label="Pencereyi kapat"
                className="w-8 h-8 rounded-lg flex items-center justify-center text-[#8F7D80] hover:text-[#F5EBE6] hover:bg-[#1E0F13] transition-colors"
              >
                <IconClose size={16} />
              </button>
            )}
          </div>
        </div>

        {/* Modal Body */}
        <div className="p-5 flex flex-col gap-4 overflow-y-auto max-h-[80vh] no-scrollbar">
          {/* Section 1: Callsign */}
          <div className="flex flex-col gap-1.5">
            <label className="text-[11px] font-bold uppercase tracking-wider text-[#9E8E91]">
              Operatör Çağrı Adı (Callsign)
            </label>
            <input
              type="text"
              value={callsign}
              maxLength={24}
              onChange={(e) => setCallsign(e.target.value)}
              placeholder="Örn: Ghost_1, Commander..."
              className="h-10 px-3.5 rounded-xl bg-[#140C0E] border border-[#2A1319] text-[#F5EBE6] text-[13px] font-bold focus:border-[#C82333] focus:outline-none transition-colors"
            />
          </div>

          {/* Section 2: Tactical Role Selection */}
          <div className="flex flex-col gap-1.5">
            <label className="text-[11px] font-bold uppercase tracking-wider text-[#9E8E91]">
              Taktik Görev / Rol
            </label>
            <div className="grid grid-cols-1 gap-1.5">
              {TACTICAL_ROLES.map((r) => {
                const isSelected = selectedRole === r.role;
                return (
                  <button
                    key={r.role}
                    type="button"
                    onClick={() => setSelectedRole(r.role)}
                    className={`px-3 py-2 rounded-xl border text-left flex items-center justify-between transition-all ${
                      isSelected
                        ? 'bg-[#1C0B10] border-[#C82333] ring-1 ring-[#C82333]/40'
                        : 'bg-[#120A0D]/70 border-[#221015] hover:border-[#331820]'
                    }`}
                  >
                    <div className="flex items-center gap-2.5 min-w-0">
                      <span
                        className={`text-[10px] font-extrabold px-2 py-0.5 rounded border ${r.badgeClass}`}
                      >
                        {r.label}
                      </span>
                      <span className="text-[11.5px] text-[#A6989B] truncate">
                        {r.desc}
                      </span>
                    </div>
                    {isSelected && (
                      <span className="w-2 h-2 rounded-full bg-[#E04856] flex-shrink-0" />
                    )}
                  </button>
                );
              })}
            </div>
          </div>

          {/* Section 3: Tabs (Create Room / Join Room) */}
          <div className="pt-2 flex flex-col gap-3">
            <div className="grid grid-cols-2 p-1 rounded-xl bg-[#120A0D] border border-[#221015]">
              <button
                type="button"
                onClick={() => {
                  setActiveTab('create');
                  setErrorMsg(null);
                }}
                className={`h-8 rounded-lg text-[12px] font-extrabold transition-all ${
                  activeTab === 'create'
                    ? 'crimson-cta text-[#F5EBE6]'
                    : 'text-[#8F7D80] hover:text-[#F5EBE6]'
                }`}
              >
                Yeni Oda Kur
              </button>
              <button
                type="button"
                onClick={() => {
                  setActiveTab('join');
                  setErrorMsg(null);
                }}
                className={`h-8 rounded-lg text-[12px] font-extrabold transition-all ${
                  activeTab === 'join'
                    ? 'crimson-cta text-[#F5EBE6]'
                    : 'text-[#8F7D80] hover:text-[#F5EBE6]'
                }`}
              >
                Koda Göre Katıl
              </button>
            </div>

            {errorMsg && (
              <div className="px-3 py-2 rounded-lg bg-[#2E0B13] border border-[#7A121D] text-[#E04856] text-[11px] font-semibold">
                {errorMsg}
              </div>
            )}

            {activeTab === 'create' ? (
              <div className="flex flex-col gap-2">
                <div className="text-[11.5px] text-[#8F7D80] leading-relaxed">
                  Tek tıkla 5 operatörlük güvenli, uçtan uca şifreli taktik oda
                  oluşturun. Oda kodu otomatik üretilip panoya kopyalanabilir hale
                  getirilir.
                </div>
                <button
                  type="button"
                  onClick={handleCreateRoom}
                  className="h-11 rounded-xl crimson-cta text-[#F5EBE6] text-[13px] font-extrabold flex items-center justify-center gap-2 active:scale-[0.98] transition-transform"
                >
                  <IconShield size={16} />
                  <span>Taktik Odayı Kur & Giriş Yap</span>
                </button>
              </div>
            ) : (
              <div className="flex flex-col gap-2.5">
                <input
                  type="text"
                  value={roomInput}
                  onChange={(e) => {
                    setRoomInput(e.target.value);
                    setErrorMsg(null);
                  }}
                  placeholder="Oda Kodu girin (Örn: MEVA-8492)..."
                  className="h-10 px-3.5 rounded-xl bg-[#140C0E] border border-[#2A1319] text-[#F5EBE6] text-[13px] font-bold uppercase tracking-wider focus:border-[#C82333] focus:outline-none transition-colors"
                />
                <button
                  type="button"
                  onClick={handleJoinRoom}
                  className="h-11 rounded-xl crimson-cta text-[#F5EBE6] text-[13px] font-extrabold flex items-center justify-center gap-2 active:scale-[0.98] transition-transform"
                >
                  <IconShield size={16} />
                  <span>Odaya Doğrudan Bağlan</span>
                </button>
              </div>
            )}
          </div>
        </div>

        {/* Footer info */}
        <div className="px-5 py-3 border-t border-[#1E0F13] bg-[#0A0607] flex items-center justify-between text-[10.5px] text-[#69585B]">
          <span>Uçtan Uca DTLS-SRTP P2P Mesh</span>
          <span>Zero-Server Mimari</span>
        </div>
      </div>
    </div>
  );
};
