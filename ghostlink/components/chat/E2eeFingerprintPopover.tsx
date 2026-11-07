'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — ECDH P-256 & AES-256-GCM Key Fingerprint Modal/Popover
// ─────────────────────────────────────────────────────────

import { memo, useEffect, useState } from 'react';
import {
  getMevaCryptoEngine,
  type CryptoStatusSnapshot,
} from '@/src/lib/cryptoEngine';
import { IconClose, IconShield } from '@/components/ui/MevaIcons';

interface E2eeFingerprintPopoverProps {
  open: boolean;
  onClose: () => void;
}

export const E2eeFingerprintPopover = memo(function E2eeFingerprintPopover({
  open,
  onClose,
}: E2eeFingerprintPopoverProps) {
  const [status, setStatus] = useState<CryptoStatusSnapshot>(() =>
    getMevaCryptoEngine().getStatusSnapshot(),
  );
  const [copiedFp, setCopiedFp] = useState(false);

  useEffect(() => {
    if (!open) return;
    const engine = getMevaCryptoEngine();
    void engine.initialize();
    return engine.subscribeStatus(setStatus);
  }, [open]);

  if (!open) return null;

  const handleCopyFingerprint = async () => {
    try {
      await navigator.clipboard?.writeText(status.localFingerprint);
      setCopiedFp(true);
      setTimeout(() => setCopiedFp(false), 1800);
    } catch {}
  };

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center exec-backdrop p-4 font-sans tabular-nums"
      onClick={onClose}
    >
      <div
        className="w-full max-w-md rounded-2xl exec-modal p-5 space-y-4"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-center justify-between border-b border-[#881A26]/20 pb-3.5">
          <div className="flex items-center gap-2.5">
            <div className="rounded-xl w-9 h-9 bg-gradient-to-br from-[#591019]/50 to-[#0C0809] border border-[#881A26]/40 flex items-center justify-center text-[#E35D6A]">
              <IconShield size={16} />
            </div>
            <div>
              <h3 className="text-sm font-bold text-[#F4EFF0]">
                E2EE Anahtar Parmak İzi Doğrulaması
              </h3>
              <p className="text-[11px] text-[#8E7F83]">
                {status.cipherSuite}
              </p>
            </div>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="rounded-xl w-8 h-8 bg-[#120A0D] hover:bg-[#1B0D12] border border-[#881A26]/25 flex items-center justify-center text-[#9E8F93] hover:text-[#F4EFF0]"
            aria-label="Kapat"
          >
            <IconClose size={14} />
          </button>
        </div>

        {/* Local ECDH P-256 SHA-256 Fingerprint */}
        <div className="rounded-xl p-3.5 bg-[#0A0708] border border-[#881A26]/30 space-y-2">
          <div className="flex items-center justify-between">
            <span className="text-[10.5px] font-bold uppercase tracking-wider text-[#8E7F83]">
              Yerel Oturum Parmak İzi (SHA-256)
            </span>
            <span className="rounded-md px-2 py-0.5 bg-[#7A121D]/30 border border-[#A61B29]/45 text-[10px] font-bold text-[#F08C96]">
              DOĞRULANDI
            </span>
          </div>
          <div className="flex items-center justify-between gap-2">
            <code className="text-sm font-mono font-extrabold tracking-wider text-[#F4EFF0]">
              {status.localFingerprint}
            </code>
            <button
              type="button"
              onClick={handleCopyFingerprint}
              className="rounded-lg px-2.5 py-1 bg-[#160A0E] hover:bg-[#240D14] border border-[#881A26]/35 text-[11px] font-bold text-[#ED8793] transition-colors"
            >
              {copiedFp ? 'Kopyalandı' : 'Kopyala'}
            </button>
          </div>
        </div>

        {/* Crypto Packet Counters */}
        <div className="grid grid-cols-2 gap-2 text-center">
          <div className="rounded-xl p-2.5 bg-[#11090C]/90 border border-[#881A26]/20">
            <span className="block text-[10px] text-[#8E7F83]">
              Şifrelenen Paket (AES-GCM)
            </span>
            <span className="block text-sm font-extrabold text-[#F4EFF0] mt-0.5">
              {status.encryptedCount}
            </span>
          </div>
          <div className="rounded-xl p-2.5 bg-[#11090C]/90 border border-[#881A26]/20">
            <span className="block text-[10px] text-[#8E7F83]">
              Doğrulanan & Çözülen Paket
            </span>
            <span className="block text-sm font-extrabold text-[#F08C96] mt-0.5">
              {status.decryptedCount}
            </span>
          </div>
        </div>

        {/* Peer Sessions */}
        <div className="space-y-1.5 max-h-40 overflow-y-auto">
          <span className="block text-[10.5px] font-bold uppercase tracking-wider text-[#8E7F83]">
            Aktif ECDH P-256 Eşleşmeleri ({status.peerSessions.length})
          </span>
          {status.peerSessions.length === 0 ? (
            <p className="rounded-xl p-3 bg-[#11090C]/70 border border-[#881A26]/15 text-[11.5px] text-[#8E7F83]">
              Oda anahtarı (AES-256-GCM + 96-bit IV) aktif. Aynı ağda/tarayıcıda yeni
              bir sekme veya P2P operatörü katıldığında ikili ECDH P-256 parmak izi
              burada listelenir.
            </p>
          ) : (
            status.peerSessions.map((peer) => (
              <div
                key={peer.peerId}
                className="rounded-xl px-3 py-2 bg-[#11090C]/90 border border-[#881A26]/25 flex items-center justify-between text-xs"
              >
                <span className="font-bold text-[#F4EFF0] truncate">
                  {peer.peerName}
                </span>
                <code className="font-mono text-[11px] font-bold text-[#F08C96]">
                  {peer.fingerprint}
                </code>
              </div>
            ))
          )}
        </div>
      </div>
    </div>
  );
});
