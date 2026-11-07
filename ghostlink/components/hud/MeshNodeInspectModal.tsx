'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — P2P Mesh Node Deep Inspection Modal
// ─────────────────────────────────────────────────────────
// Opened when clicking a node in the 5-Operator P2P Mesh Topology.
// Displays real-time crypto, Opus codec fmtp, RTP packet counters,
// RTT/Jitter, and provides one-click ICE Restart or DSP Drawer jump.

import { memo } from 'react';
import type { NodeInspectTelemetry } from '@/src/lib/telemetryEngine';
import { getMevaWebRTCMesh } from '@/src/lib/webrtcMesh';
import { OperatorAvatar } from '@/components/ui/HudPrimitives';
import { IconClose, IconShield, IconBolt } from '@/components/ui/MevaIcons';

interface MeshNodeInspectModalProps {
  node: NodeInspectTelemetry | null;
  onClose: () => void;
  onOpenDspDrawer?: (nodeId: string) => void;
}

export const MeshNodeInspectModal = memo(function MeshNodeInspectModal({
  node,
  onClose,
  onOpenDspDrawer,
}: MeshNodeInspectModalProps) {
  if (!node) return null;

  const handleResetConnection = () => {
    void getMevaWebRTCMesh().resetPeerConnection(node.nodeId);
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
        {/* Header */}
        <div className="flex items-center justify-between border-b border-[#881A26]/20 pb-3.5">
          <div className="flex items-center gap-3">
            <OperatorAvatar name={node.callsign} status="online" size="md" />
            <div>
              <div className="flex items-center gap-2">
                <h3 className="text-sm font-extrabold text-[#F4EFF0]">
                  {node.callsign}
                </h3>
                <span className="rounded-md px-2 py-0.5 bg-[#7A121D]/30 border border-[#A61B29]/45 text-[10px] font-bold text-[#F08C96]">
                  {node.role}
                </span>
              </div>
              <p className="text-[11px] text-[#8E7F83] mt-0.5">
                {node.transport}
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

        {/* 4-Metric Live RTP Grid */}
        <div className="grid grid-cols-4 gap-2 text-center">
          <div className="rounded-xl p-2.5 bg-[#11090C]/90 border border-[#881A26]/20">
            <span className="block text-[9.5px] text-[#8E7F83]">RTT</span>
            <span className="block text-xs font-extrabold text-[#F08C96] mt-0.5">
              {node.rttMs} ms
            </span>
          </div>
          <div className="rounded-xl p-2.5 bg-[#11090C]/90 border border-[#881A26]/20">
            <span className="block text-[9.5px] text-[#8E7F83]">Jitter</span>
            <span className="block text-xs font-extrabold text-[#F4EFF0] mt-0.5">
              {node.jitterMs} ms
            </span>
          </div>
          <div className="rounded-xl p-2.5 bg-[#11090C]/90 border border-[#881A26]/20">
            <span className="block text-[9.5px] text-[#8E7F83]">Kayıp</span>
            <span className="block text-xs font-extrabold text-[#F4EFF0] mt-0.5">
              %{node.packetLossPercent}
            </span>
          </div>
          <div className="rounded-xl p-2.5 bg-[#11090C]/90 border border-[#881A26]/20">
            <span className="block text-[9.5px] text-[#8E7F83]">Bant</span>
            <span className="block text-xs font-extrabold text-[#F08C96] mt-0.5">
              {node.throughputKbps} kbps
            </span>
          </div>
        </div>

        {/* Crypto & Codec Inspection */}
        <div className="rounded-xl p-3.5 bg-[#0A0708] border border-[#881A26]/25 space-y-2.5 text-xs">
          <div className="flex items-center justify-between gap-2">
            <span className="text-[#8E7F83] flex items-center gap-1.5">
              <IconShield size={13} className="text-[#E35D6A]" />
              <span>Kripto Katmanı</span>
            </span>
            <span className="font-bold text-[#F4EFF0]">{node.cipherSuite}</span>
          </div>

          <div className="flex items-center justify-between gap-2">
            <span className="text-[#8E7F83]">Anahtar Parmak İzi</span>
            <code className="font-mono text-[11px] font-bold text-[#F08C96]">
              {node.fingerprint}
            </code>
          </div>

          <div className="flex items-center justify-between gap-2">
            <span className="text-[#8E7F83]">Ses Kodek</span>
            <span className="font-bold text-[#F4EFF0]">{node.codec}</span>
          </div>

          <div className="pt-1.5 border-t border-[#881A26]/15 flex items-center justify-between text-[11px]">
            <span className="text-[#8E7F83]">
              Paket: ↑{node.packetsSent} / ↓{node.packetsReceived}
            </span>
            <span className="font-semibold text-[#ED8793]">
              ICE: {node.iceState.toUpperCase()}
            </span>
          </div>
        </div>

        <div className="rounded-lg px-3 py-2 bg-[#11090C]/80 border border-[#881A26]/20 font-mono text-[10.5px] text-[#B8AAAC] truncate">
          fmtp: {node.fmtp}
        </div>

        {/* Actions */}
        <div className="grid grid-cols-2 gap-2">
          <button
            type="button"
            onClick={handleResetConnection}
            className="rounded-xl min-h-[40px] bg-[#120A0D] hover:bg-[#1E0C12] border border-[#881A26]/35 text-xs font-bold text-[#F4EFF0] flex items-center justify-center gap-1.5 transition-colors"
          >
            <IconBolt size={13} className="text-[#E35D6A]" />
            <span>ICE Yeniden Başlat</span>
          </button>
          {onOpenDspDrawer && (
            <button
              type="button"
              onClick={() => {
                const id = node.nodeId;
                onClose();
                onOpenDspDrawer(id);
              }}
              className="rounded-xl min-h-[40px] crimson-cta text-xs font-bold transition-all"
            >
              DSP & EQ Denetimi
            </button>
          )}
        </div>
      </div>
    </div>
  );
});
