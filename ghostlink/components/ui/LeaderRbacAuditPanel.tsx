'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Leader RBAC Control & Immutable Audit Log Panel
// ─────────────────────────────────────────────────────────
// Strict 3-tier Role-Based Access Control:
//   • Lider              (Full access + Audit Log + Role Admin)
//   • Kıdemli Moderatör  (Channels, Kick/Mute & Strat Studio)
//   • Üye / İzleyici     (Read-only participation & viewer mode)

import React, { useEffect, useMemo, useState } from 'react';
import { useAppStore } from '@/lib/store';
import {
  RBAC_PERMISSION_LABELS,
  RBAC_PERMISSION_MATRIX,
  RBAC_ROLE_META,
  useRBACStore,
  type AuditSeverity,
  type RbacPermissionKey,
  type RbacRole,
} from '@/store/useRBACStore';
import { ConfirmActionModal } from '@/components/ui/ConfirmActionModal';
import { IconShield } from '@/components/ui/MevaIcons';

const ORDERED_ROLES: RbacRole[] = ['lider', 'kidemli_moderator', 'uye_izleyici'];

function formatAuditClock(ts: number): string {
  try {
    const d = new Date(ts);
    const ms = String(d.getMilliseconds()).padStart(3, '0');
    return `${d.toLocaleTimeString('tr-TR', {
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
    })}.${ms}`;
  } catch {
    return '--:--:--.000';
  }
}

export const LeaderRbacAuditPanel: React.FC = () => {
  const localUserId = useRBACStore((s) => s.localUserId);
  const localActorName = useRBACStore((s) => s.localActorName);
  const operatorRbacRoles = useRBACStore((s) => s.operatorRbacRoles);
  const auditLogs = useRBACStore((s) => s.auditLogs);
  const hydrateRbac = useRBACStore((s) => s.hydrateRbac);
  const assignOperatorRole = useRBACStore((s) => s.assignOperatorRole);
  const clearAuditLogs = useRBACStore((s) => s.clearAuditLogs);

  const onlineMembers = useAppStore((s) => s.onlineMembers);
  const [severityFilter, setSeverityFilter] = useState<'all' | AuditSeverity>('all');
  const [pendingConfirm, setPendingConfirm] = useState<{
    title: string;
    description: string;
    confirmLabel: string;
    danger?: boolean;
    onConfirm: () => void;
  } | null>(null);

  useEffect(() => {
    void hydrateRbac();
  }, [hydrateRbac]);

  const effectiveLocalRole: RbacRole = operatorRbacRoles[localUserId] ?? 'lider';
  const canViewAudit = RBAC_PERMISSION_MATRIX[effectiveLocalRole].viewAuditLog;

  const squadRoster = useMemo(() => {
    const base = [
      { id: localUserId, name: localActorName || 'Operatör', isSelf: true },
      ...onlineMembers
        .filter((m) => m.id !== localUserId)
        .map((m) => ({ id: m.id, name: m.username, isSelf: false })),
    ];
    return base;
  }, [localUserId, localActorName, onlineMembers]);

  const filteredAuditLogs = useMemo(() => {
    if (severityFilter === 'all') return auditLogs;
    return auditLogs.filter((log) => log.severity === severityFilter);
  }, [auditLogs, severityFilter]);

  const handleRoleChangeRequest = (
    targetId: string,
    targetName: string,
    nextRole: RbacRole,
  ) => {
    const current = operatorRbacRoles[targetId] ?? (targetId === localUserId ? 'lider' : 'uye_izleyici');
    if (current === nextRole) return;

    setPendingConfirm({
      title: 'RBAC Yetki Rolü Değiştirilsin mi?',
      description: `"${targetName}" operatörünün rolü "${RBAC_ROLE_META[current].label}" → "${RBAC_ROLE_META[nextRole].label}" olarak güncellenecek ve Denetim Kaydına (Audit Log) işlenecek.`,
      confirmLabel: 'Rolü Güncelle',
      danger: nextRole === 'uye_izleyici' || nextRole === 'lider',
      onConfirm: () => {
        assignOperatorRole(targetId, targetName, nextRole);
        setPendingConfirm(null);
      },
    });
  };

  return (
    <div className="space-y-4">
      {/* 1. Local Operator Active Tier Switcher */}
      <div className="rounded-xl p-4 bg-[#10080B] border border-[#8F1622]/45 space-y-3">
        <div className="flex items-center justify-between gap-2 flex-wrap">
          <div className="flex items-center gap-2">
            <IconShield size={15} className="text-[#F08C96]" />
            <div>
              <h3 className="text-xs font-extrabold text-[#F4EFF0]">
                Sıkı RBAC Erişim Kontrolü (3 Katmanlı Yetki Sistemi)
              </h3>
              <p className="text-[11px] text-[#8E7F83]">
                Aktif yerel yetki seviyenizi seçin veya diğer operatörlerin rollerini denetleyin.
              </p>
            </div>
          </div>
          <span
            className={`px-2 py-0.5 rounded-md border text-[10px] font-black uppercase ${RBAC_ROLE_META[effectiveLocalRole].badgeClass}`}
          >
            {RBAC_ROLE_META[effectiveLocalRole].label}
          </span>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-3 gap-2">
          {ORDERED_ROLES.map((roleKey) => {
            const meta = RBAC_ROLE_META[roleKey];
            const isSelected = effectiveLocalRole === roleKey;
            return (
              <button
                key={roleKey}
                type="button"
                onClick={(e) => {
                  e.preventDefault();
                  handleRoleChangeRequest(localUserId, localActorName || 'Operatör', roleKey);
                }}
                className={`p-2.5 rounded-xl border text-left transition-all ${
                  isSelected
                    ? 'bg-[#2C0B13] border-[#C82333] shadow-[0_0_12px_rgba(200,35,51,0.28)]'
                    : 'bg-[#090507] hover:bg-[#170B0F] border-[#261217]'
                }`}
              >
                <div className="flex items-center justify-between mb-1">
                  <span className="text-xs font-extrabold text-[#FAF2EE]">
                    {meta.label}
                  </span>
                  {isSelected && (
                    <span className="text-[9.5px] font-black text-[#F08C96]">AKTİF</span>
                  )}
                </div>
                <p className="text-[10.5px] text-[#8E7F83] leading-snug">{meta.desc}</p>
              </button>
            );
          })}
        </div>
      </div>

      {/* 2. Squad Operator Role Assignment Table */}
      <div className="rounded-xl p-4 bg-[#10080B] border border-[#2C141A] space-y-2.5">
        <div className="flex items-center justify-between">
          <span className="text-xs font-extrabold text-[#F4EFF0]">
            Kadro Rol Atamaları ({squadRoster.length})
          </span>
          <span className="text-[10px] text-[#8E7F83]">
            Yalnızca Lider değiştirebilir
          </span>
        </div>
        <div className="space-y-1.5 max-h-40 overflow-y-auto">
          {squadRoster.map((member) => {
            const mRole =
              operatorRbacRoles[member.id] ?? (member.isSelf ? 'lider' : 'uye_izleyici');
            return (
              <div
                key={member.id}
                className="flex items-center justify-between gap-2 px-3 py-2 rounded-lg bg-[#090507] border border-[#1E0B11]"
              >
                <div className="min-w-0 flex items-center gap-2">
                  <span className="text-xs font-bold text-[#FAF2EE] truncate">
                    {member.name}
                    {member.isSelf ? ' (Sen)' : ''}
                  </span>
                  <span
                    className={`px-1.5 py-0.5 rounded border text-[9.5px] font-bold ${RBAC_ROLE_META[mRole].badgeClass}`}
                  >
                    {RBAC_ROLE_META[mRole].shortLabel}
                  </span>
                </div>
                <div className="flex items-center gap-1 flex-shrink-0">
                  {ORDERED_ROLES.map((rk) => (
                    <button
                      key={rk}
                      type="button"
                      onClick={(e) => {
                        e.preventDefault();
                        handleRoleChangeRequest(member.id, member.name, rk);
                      }}
                      className={`px-2 py-1 rounded text-[10px] font-bold border transition-colors ${
                        mRole === rk
                          ? 'bg-[#8F1622] text-white border-[#C82333]'
                          : 'bg-[#140A0D] text-[#8E7F83] hover:text-white border-[#241116]'
                      }`}
                    >
                      {RBAC_ROLE_META[rk].shortLabel}
                    </button>
                  ))}
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* 3. Live RBAC Permission Matrix */}
      <div className="rounded-xl p-3.5 bg-[#0C0709] border border-[#241116] space-y-2">
        <span className="block text-[11px] font-extrabold text-[#F4EFF0] uppercase tracking-wider">
          Yetki Matrisi ({RBAC_ROLE_META[effectiveLocalRole].label})
        </span>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-1.5">
          {(Object.keys(RBAC_PERMISSION_LABELS) as RbacPermissionKey[]).map((perm) => {
            const allowed = RBAC_PERMISSION_MATRIX[effectiveLocalRole][perm];
            return (
              <div
                key={perm}
                className="flex items-center justify-between px-2.5 py-1.5 rounded-lg bg-[#12080B] border border-[#1E0B11] text-[10.5px]"
              >
                <span className="text-[#C4B6BA] truncate">{RBAC_PERMISSION_LABELS[perm]}</span>
                <span
                  className={`font-black flex-shrink-0 ml-2 ${
                    allowed ? 'text-emerald-400' : 'text-[#7D6E71]'
                  }`}
                >
                  {allowed ? '✓ YETKİLİ' : '✕ KAPALI'}
                </span>
              </div>
            );
          })}
        </div>
      </div>

      {/* 4. Leader Panel Immutable Audit Log */}
      <div className="rounded-xl p-4 bg-[#10080B] border border-[#8F1622]/45 space-y-3">
        <div className="flex items-center justify-between gap-2 flex-wrap">
          <div>
            <h4 className="text-xs font-extrabold text-[#FAF2EE] uppercase tracking-wider">
              Lider Denetim Kaydı (Audit Log)
            </h4>
            <p className="text-[10.5px] text-[#8E7F83]">
              Sunucu silme, harita temizleme, rol değişimi ve yetki ihlallerinin IndexedDB kaydı.
            </p>
          </div>
          {canViewAudit && (
            <button
              type="button"
              onClick={(e) => {
                e.preventDefault();
                setPendingConfirm({
                  title: 'Denetim Kaydını Sıfırla',
                  description:
                    'Mevcut tüm Denetim Kaydı (Audit Log) geçmişi arşivlenip temizlenecek. Bu kritik işlem kalıcı olarak kaydedilir.',
                  confirmLabel: 'Denetim Kaydını Sıfırla',
                  danger: true,
                  onConfirm: () => {
                    clearAuditLogs();
                    setPendingConfirm(null);
                  },
                });
              }}
              className="h-7 px-2.5 rounded-lg bg-[#1A0B10] hover:bg-[#3B141E] border border-[#6E1722] text-[10px] font-bold text-[#F08C96] hover:text-white"
            >
              Arşivle & Sıfırla
            </button>
          )}
        </div>

        {!canViewAudit ? (
          <div className="p-4 rounded-xl bg-[#090507] border border-[#3B141C] text-center space-y-1">
            <p className="text-xs font-bold text-[#F08C96]">
              🔒 Denetim Kaydı Yalnızca &ldquo;Lider&rdquo; Rolüne Açık
            </p>
            <p className="text-[11px] text-[#8E7F83]">
              Aktif rolünüz ({RBAC_ROLE_META[effectiveLocalRole].label}) hassas denetim günlüklerini görüntüleyemez.
            </p>
          </div>
        ) : (
          <>
            <div className="flex items-center gap-1.5 flex-wrap">
              {(
                [
                  { id: 'all', label: `Tümü (${auditLogs.length})` },
                  { id: 'critical', label: 'Kritik' },
                  { id: 'warn', label: 'Uyarı / Engel' },
                  { id: 'info', label: 'Bilgi' },
                ] as const
              ).map((f) => (
                <button
                  key={f.id}
                  type="button"
                  onClick={(e) => {
                    e.preventDefault();
                    setSeverityFilter(f.id);
                  }}
                  className={`px-2.5 py-1 rounded-lg text-[10px] font-bold border transition-colors ${
                    severityFilter === f.id
                      ? 'bg-[#8F1622] text-white border-[#C82333]'
                      : 'bg-[#090507] text-[#8E7F83] hover:text-white border-[#1E0B11]'
                  }`}
                >
                  {f.label}
                </button>
              ))}
            </div>

            <div className="space-y-1.5 max-h-56 overflow-y-auto pr-1">
              {filteredAuditLogs.map((entry) => (
                <div
                  key={entry.id}
                  className="p-2.5 rounded-lg bg-[#090507] border border-[#1E0B11] flex items-start justify-between gap-2 text-[11px]"
                >
                  <div className="min-w-0 space-y-0.5">
                    <div className="flex items-center gap-1.5 flex-wrap">
                      <span
                        className={`px-1.5 py-0.5 rounded text-[9px] font-black uppercase ${
                          entry.severity === 'critical'
                            ? 'bg-[#4D0B14] text-[#FF7A88]'
                            : entry.severity === 'warn'
                              ? 'bg-[#331B0A] text-amber-300'
                              : 'bg-[#141A22] text-sky-300'
                        }`}
                      >
                        {entry.severity}
                      </span>
                      <span className="font-bold text-[#FAF2EE]">{entry.action}</span>
                    </div>
                    <p className="text-[10.5px] text-[#8E7F83] truncate">
                      {entry.actorName} ({RBAC_ROLE_META[entry.actorRole]?.shortLabel ?? 'LİDER'}) · Hedef: {entry.target}
                    </p>
                  </div>
                  <code className="text-[9.5px] font-mono text-[#7D6E71] flex-shrink-0">
                    {formatAuditClock(entry.ts)}
                  </code>
                </div>
              ))}
            </div>
          </>
        )}
      </div>

      {pendingConfirm && (
        <ConfirmActionModal
          isOpen={true}
          title={pendingConfirm.title}
          description={pendingConfirm.description}
          confirmLabel={pendingConfirm.confirmLabel}
          danger={pendingConfirm.danger ?? true}
          onConfirm={pendingConfirm.onConfirm}
          onCancel={() => setPendingConfirm(null)}
        />
      )}
    </div>
  );
};
