'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Strict 3-Tier RBAC & Immutable Audit Log Store
// ─────────────────────────────────────────────────────────
// Tiers:
//   • lider              -> Full administrative, server, RBAC & audit authority
//   • kidemli_moderator  -> Channel, kick/mute & tactical studio control (no server/role admin)
//   • uye_izleyici       -> Read-only communication & tactical view (blocked from destructive edits)

import { create } from 'zustand';
import { getMevaStorageEngine, STORE_PREFS } from '@/src/lib/storageEngine';
import { useNotificationStore } from '@/store/useNotificationStore';

export type RbacRole = 'lider' | 'kidemli_moderator' | 'uye_izleyici';

export type RbacPermissionKey =
  | 'manageRoles'
  | 'manageServer'
  | 'manageChannels'
  | 'kickOperators'
  | 'editTacticalBoard'
  | 'clearTacticalBoard'
  | 'manageStratbooks'
  | 'runMapVeto'
  | 'viewAuditLog'
  | 'clearAuditLog';

export type AuditSeverity = 'info' | 'warn' | 'critical';

export interface AuditLogEntry {
  id: string;
  ts: number;
  actorId: string;
  actorName: string;
  actorRole: RbacRole;
  action: string;
  target: string;
  severity: AuditSeverity;
}

export const RBAC_ROLE_META: Record<
  RbacRole,
  { label: string; shortLabel: string; badgeClass: string; desc: string }
> = {
  lider: {
    label: 'Lider',
    shortLabel: 'LİDER',
    badgeClass: 'bg-[#4D0B14] text-[#FF8A96] border-[#C82333]/70',
    desc: 'Tam Yetkili Kurucu · Rol Yönetimi, Sunucu Kurulumu ve Denetim Kaydı Erişimi',
  },
  kidemli_moderator: {
    label: 'Kıdemli Moderatör',
    shortLabel: 'KIDEMLİ MOD',
    badgeClass: 'bg-[#2B170A] text-[#F2B066] border-[#9E5E1E]/60',
    desc: 'Kanal, Operatör Denetimi, Harita Veto ve Taktik Tahtası Yönetimi',
  },
  uye_izleyici: {
    label: 'Üye / İzleyici',
    shortLabel: 'ÜYE / İZLEYİCİ',
    badgeClass: 'bg-[#171215] text-[#A8989B] border-[#38242A]',
    desc: 'Standart Katılım & Salt-Okunur Taktik İzleme (Kritik İşlemlere Kapalı)',
  },
};

export const RBAC_PERMISSION_MATRIX: Record<
  RbacRole,
  Record<RbacPermissionKey, boolean>
> = {
  lider: {
    manageRoles: true,
    manageServer: true,
    manageChannels: true,
    kickOperators: true,
    editTacticalBoard: true,
    clearTacticalBoard: true,
    manageStratbooks: true,
    runMapVeto: true,
    viewAuditLog: true,
    clearAuditLog: true,
  },
  kidemli_moderator: {
    manageRoles: false,
    manageServer: false,
    manageChannels: true,
    kickOperators: true,
    editTacticalBoard: true,
    clearTacticalBoard: true,
    manageStratbooks: true,
    runMapVeto: true,
    viewAuditLog: false,
    clearAuditLog: false,
  },
  uye_izleyici: {
    manageRoles: false,
    manageServer: false,
    manageChannels: false,
    kickOperators: false,
    editTacticalBoard: false,
    clearTacticalBoard: false,
    manageStratbooks: false,
    runMapVeto: false,
    viewAuditLog: false,
    clearAuditLog: false,
  },
};

export const RBAC_PERMISSION_LABELS: Record<RbacPermissionKey, string> = {
  manageRoles: 'Rol & Yetki Dağıtımı',
  manageServer: 'Sunucu Silme / Karargah Yönetimi',
  manageChannels: 'Kanal Kurma & Silme',
  kickOperators: 'Operatör Çıkarma / Susturma',
  editTacticalBoard: 'Taktik Haritada Çizim Yapma',
  clearTacticalBoard: 'Harita Çizimlerini Temizleme',
  manageStratbooks: 'Çoklu Stratbook Oluşturma / Silme',
  runMapVeto: 'Turnuva Harita Veto (Pick-Ban)',
  viewAuditLog: 'Lider Denetim Kaydını Görme',
  clearAuditLog: 'Denetim Kaydını Temizleme',
};

const STORAGE_RBAC_ROLES_KEY = 'meva_rbac_operator_roles';
const STORAGE_AUDIT_LOG_KEY = 'meva_rbac_audit_log';

interface RbacState {
  localUserId: string;
  localActorName: string;
  operatorRbacRoles: Record<string, RbacRole>;
  auditLogs: AuditLogEntry[];
  hydrated: boolean;

  hydrateRbac: () => Promise<void>;
  setLocalActorIdentity: (userId: string, actorName: string) => void;
  getEffectiveRole: (userId?: string) => RbacRole;
  hasPermission: (permission: RbacPermissionKey, userId?: string) => boolean;
  requirePermission: (
    permission: RbacPermissionKey,
    actionLabel: string,
    targetLabel?: string,
  ) => boolean;
  assignOperatorRole: (
    targetUserId: string,
    targetName: string,
    nextRole: RbacRole,
  ) => boolean;
  recordAudit: (entry: {
    action: string;
    target: string;
    severity?: AuditSeverity;
    actorId?: string;
    actorName?: string;
    actorRole?: RbacRole;
  }) => void;
  clearAuditLogs: () => boolean;
}

const DEFAULT_AUDIT_BOOT: AuditLogEntry = {
  id: 'audit-init',
  ts: 1762455600000,
  actorId: 'usr-local',
  actorName: 'Operatör',
  actorRole: 'lider',
  action: 'RBAC & Denetim Motoru Başlatıldı',
  target: 'Lider / Kıdemli Moderatör / Üye Matrisi',
  severity: 'info',
};

function persistRbacSnapshot(
  roles: Record<string, RbacRole>,
  logs: AuditLogEntry[],
): void {
  try {
    const storage = getMevaStorageEngine();
    storage.scheduleWrite(STORE_PREFS, STORAGE_RBAC_ROLES_KEY, roles);
    storage.scheduleWrite(STORE_PREFS, STORAGE_AUDIT_LOG_KEY, logs.slice(0, 120));
    void storage.flushPendingWrites();
  } catch {}
}

export const useRBACStore = create<RbacState>((set, get) => ({
  localUserId: 'usr-local',
  localActorName: 'Operatör',
  operatorRbacRoles: {
    'usr-local': 'lider',
  },
  auditLogs: [DEFAULT_AUDIT_BOOT],
  hydrated: false,

  hydrateRbac: async () => {
    if (get().hydrated) return;
    try {
      const storage = getMevaStorageEngine();
      const [savedRoles, savedLogs] = await Promise.all([
        storage.getRecord<Record<string, RbacRole>>(STORE_PREFS, STORAGE_RBAC_ROLES_KEY),
        storage.getRecord<AuditLogEntry[]>(STORE_PREFS, STORAGE_AUDIT_LOG_KEY),
      ]);
      set((state) => ({
        operatorRbacRoles:
          savedRoles && typeof savedRoles === 'object'
            ? { 'usr-local': 'lider', ...savedRoles }
            : state.operatorRbacRoles,
        auditLogs:
          Array.isArray(savedLogs) && savedLogs.length > 0
            ? savedLogs
            : state.auditLogs,
        hydrated: true,
      }));
    } catch {
      set({ hydrated: true });
    }
  },

  setLocalActorIdentity: (userId, actorName) =>
    set((state) => {
      const nextRoles = { ...state.operatorRbacRoles };
      if (!nextRoles[userId]) {
        nextRoles[userId] = 'lider';
      }
      return {
        localUserId: userId,
        localActorName: actorName || state.localActorName,
        operatorRbacRoles: nextRoles,
      };
    }),

  getEffectiveRole: (userId) => {
    const state = get();
    const id = userId ?? state.localUserId;
    return state.operatorRbacRoles[id] ?? (id === state.localUserId ? 'lider' : 'uye_izleyici');
  },

  hasPermission: (permission, userId) => {
    const role = get().getEffectiveRole(userId);
    return RBAC_PERMISSION_MATRIX[role][permission];
  },

  requirePermission: (permission, actionLabel, targetLabel = 'Sistem') => {
    const state = get();
    const role = state.getEffectiveRole(state.localUserId);
    const allowed = RBAC_PERMISSION_MATRIX[role][permission];
    if (allowed) return true;

    state.recordAudit({
      action: `Yetkisiz İşlem Engellendi (${actionLabel})`,
      target: targetLabel,
      severity: 'warn',
    });

    useNotificationStore.getState().pushNotification({
      title: 'RBAC Yetki Engeli',
      message: `"${RBAC_ROLE_META[role].label}" rolü "${actionLabel}" işlemi için yetkili değil.`,
      type: 'audit',
    });
    return false;
  },

  assignOperatorRole: (targetUserId, targetName, nextRole) => {
    const state = get();
    const isSelfDemoSwitch = targetUserId === state.localUserId;
    if (!isSelfDemoSwitch && !state.requirePermission('manageRoles', 'Rol Değiştirme', targetName)) {
      return false;
    }

    const prevRole = state.getEffectiveRole(targetUserId);
    const updatedRoles = {
      ...state.operatorRbacRoles,
      [targetUserId]: nextRole,
    };

    const entry: AuditLogEntry = {
      id: `audit-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 6)}`,
      ts: Date.now(),
      actorId: state.localUserId,
      actorName: state.localActorName,
      actorRole: prevRole,
      action: `RBAC Rol Değişimi (${RBAC_ROLE_META[prevRole].shortLabel} → ${RBAC_ROLE_META[nextRole].shortLabel})`,
      target: targetName,
      severity: nextRole === 'lider' ? 'critical' : 'warn',
    };

    const updatedLogs = [entry, ...state.auditLogs].slice(0, 120);
    set({
      operatorRbacRoles: updatedRoles,
      auditLogs: updatedLogs,
    });
    persistRbacSnapshot(updatedRoles, updatedLogs);

    useNotificationStore.getState().pushNotification({
      title: 'RBAC Yetki Güncellendi',
      message: `${targetName} → ${RBAC_ROLE_META[nextRole].label}`,
      type: 'audit',
    });

    return true;
  },

  recordAudit: ({ action, target, severity = 'info', actorId, actorName, actorRole }) =>
    set((state) => {
      const effectiveRole = actorRole ?? state.getEffectiveRole(actorId ?? state.localUserId);
      const entry: AuditLogEntry = {
        id: `audit-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 6)}`,
        ts: Date.now(),
        actorId: actorId ?? state.localUserId,
        actorName: actorName ?? state.localActorName,
        actorRole: effectiveRole,
        action,
        target,
        severity,
      };
      const updatedLogs = [entry, ...state.auditLogs].slice(0, 120);
      persistRbacSnapshot(state.operatorRbacRoles, updatedLogs);
      return { auditLogs: updatedLogs };
    }),

  clearAuditLogs: () => {
    const state = get();
    if (!state.requirePermission('clearAuditLog', 'Denetim Kaydını Temizle', 'Audit Log')) {
      return false;
    }
    const resetEntry: AuditLogEntry = {
      id: `audit-${Date.now().toString(36)}`,
      ts: Date.now(),
      actorId: state.localUserId,
      actorName: state.localActorName,
      actorRole: state.getEffectiveRole(state.localUserId),
      action: 'Denetim Kaydı Lider Tarafından Arşivlenip Sıfırlandı',
      target: 'Audit Log',
      severity: 'critical',
    };
    const updatedLogs = [resetEntry];
    set({ auditLogs: updatedLogs });
    persistRbacSnapshot(state.operatorRbacRoles, updatedLogs);
    return true;
  },
}));
