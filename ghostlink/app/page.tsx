'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Main Industrial Command Shell
// ─────────────────────────────────────────────────────────

import { useEffect, useState, useCallback, useMemo } from 'react';
import { useAppStore } from '@/lib/store';
import { useThemeStore, sanitizeWallpaperUrl } from '@/store/useThemeStore';
import { useVoiceSettingsStore } from '@/store/useVoiceSettingsStore';
import { useGameBoost } from '@/hooks/useGameBoost';
import { useWebRTC } from '@/hooks/useWebRTC';
import { parseServerlessInviteHash } from '@/src/lib/webrtcMesh';
import { GhostNavbar } from '@/components/layout/GhostNavbar';
import { TacticalSidebar } from '@/components/layout/TacticalSidebar';
import { StreamChatArea } from '@/components/chat/StreamChatArea';
import { PlayerRadarHUD } from '@/components/hud/PlayerRadarHUD';
import { MobileBottomNav } from '@/components/layout/MobileBottomNav';
import { FloatingEsportDock } from '@/components/layout/FloatingEsportDock';
import { EsportHubView } from '@/components/esport/EsportHubView';
import { TacticalMapBoard, type TacticalMapId } from '@/components/tactical/TacticalMapBoard';
import type { MainNavViewMode } from '@/types/esport';
import { ScrimModal } from '@/components/ScrimModal';
import { ThemeSettingsModal } from '@/components/ui/ThemeSettingsModal';
import { MevaCommandSettingsModal } from '@/components/ui/MevaCommandSettingsModal';
import {
  OperatorContextMenu,
  type OperatorContextTarget,
} from '@/components/ui/OperatorContextMenu';
import { TacticalPlayerHUD } from '@/components/ui/TacticalPlayerHUD';
import { FriendsModal } from '@/components/ui/FriendsModal';
import { TacticalStratDrawer } from '@/components/tactical/TacticalStratDrawer';
import { MiniHudOverlay } from '@/components/hud/MiniHudOverlay';
import { LobbyGateModal } from '@/components/lobby/LobbyGateModal';
import { QuickChannelBuilderModal } from '@/components/modal/QuickChannelBuilderModal';
import { OnboardingModal } from '@/components/onboarding/OnboardingModal';
import { InteractiveTourModal } from '@/components/modal/InteractiveTourModal';
import { StreamerOverlayModal } from '@/components/broadcast/StreamerOverlayModal';
import { BroadcastSoundboardModal } from '@/components/audio/BroadcastSoundboardModal';
import { RadialCommandWheel } from '@/components/tactical/RadialCommandWheel';
import { VoiceClipBufferModal } from '@/components/audio/VoiceClipBufferModal';
import { ScrimScheduleModal } from '@/components/scrim/ScrimScheduleModal';
import { ShortcutsHelpModal } from '@/components/modal/ShortcutsHelpModal';
import { MevaProLicenseModal } from '@/components/modal/MevaProLicenseModal';
import { MobileCustomizerSheet } from '@/components/mobile/MobileCustomizerSheet';
import { MobileThumbCommandPill } from '@/components/mobile/MobileThumbCommandPill';
import { TacticalVoiceOverlay } from '@/components/hud/TacticalVoiceOverlay';
import { type TacticalRole } from '@/store/useHUDStore';
import { getMevaStorageEngine, STORE_PREFS } from '@/src/lib/storageEngine';
import { getMevaKeepAlive } from '@/lib/keepAlive';
import { useRBACStore } from '@/store/useRBACStore';
import { NotificationDrawer } from '@/components/notifications/NotificationDrawer';
import type {
  Profile,
  Server,
  ChannelCategory,
  Channel,
  VoiceControls,
} from '@/types';

const SEED_ISO = '2026-11-06T19:00:00.000Z';
const DEFAULT_MEMBERS: Profile[] = [];

export default function MevaHUDApp() {
  useGameBoost();

  // Client-side Codespaces & session keep-alive controller + RBAC hydration
  useEffect(() => {
    const keepAlive = getMevaKeepAlive();
    const stopKeepAlive = keepAlive.start(45_000);
    void useRBACStore.getState().hydrateRbac();
    return () => {
      stopKeepAlive();
    };
  }, []);

  const [user, setUser] = useState<Profile>({
    id: 'usr-local',
    username: 'Operatör',
    avatar_url: null,
    status: 'online',
    activity: 'Meva Command',
    created_at: SEED_ISO,
  });

  const [selectedPlayer, setSelectedPlayer] = useState<Profile | null>(null);
  const [radarContextTarget, setRadarContextTarget] =
    useState<OperatorContextTarget | null>(null);

  const activeServerId = useAppStore((s) => s.activeServerId);
  const activeVoiceChannelId = useAppStore((s) => s.activeVoiceChannelId);
  const isMobileSidebarOpen = useAppStore((s) => s.isMobileSidebarOpen);
  const isMobileRadarOpen = useAppStore((s) => s.isMobileRadarOpen);
  const showScrimModal = useAppStore((s) => s.showScrimModal);
  const showFriendsModal = useAppStore((s) => s.showFriendsModal);
  const showLobbyGate = useAppStore((s) => s.showLobbyGate);
  const setShowLobbyGate = useAppStore((s) => s.setShowLobbyGate);
  const showChannelBuilderModal = useAppStore((s) => s.showChannelBuilderModal);
  const setShowChannelBuilderModal = useAppStore(
    (s) => s.setShowChannelBuilderModal,
  );
  const showOnboardingModal = useAppStore((s) => s.showOnboardingModal);
  const setShowOnboardingModal = useAppStore((s) => s.setShowOnboardingModal);
  const showTourModal = useAppStore((s) => s.showTourModal);
  const setShowTourModal = useAppStore((s) => s.setShowTourModal);
  const showStreamerOverlayModal = useAppStore((s) => s.showStreamerOverlayModal);
  const setShowStreamerOverlayModal = useAppStore((s) => s.setShowStreamerOverlayModal);
  const showSoundboardModal = useAppStore((s) => s.showSoundboardModal);
  const setShowSoundboardModal = useAppStore((s) => s.setShowSoundboardModal);
  const showRadialCommandWheel = useAppStore((s) => s.showRadialCommandWheel);
  const setShowRadialCommandWheel = useAppStore((s) => s.setShowRadialCommandWheel);
  const showVoiceClipBufferModal = useAppStore((s) => s.showVoiceClipBufferModal);
  const setShowVoiceClipBufferModal = useAppStore((s) => s.setShowVoiceClipBufferModal);
  const showScrimScheduleModal = useAppStore((s) => s.showScrimScheduleModal);
  const setShowScrimScheduleModal = useAppStore((s) => s.setShowScrimScheduleModal);
  const showShortcutsHelpModal = useAppStore((s) => s.showShortcutsHelpModal);
  const setShowShortcutsHelpModal = useAppStore((s) => s.setShowShortcutsHelpModal);
  const showProLicenseModal = useAppStore((s) => s.showProLicenseModal);
  const setShowProLicenseModal = useAppStore((s) => s.setShowProLicenseModal);
  const miniHudActive = useVoiceSettingsStore((s) => s.miniHudActive);
  const showCommandSettingsModal = useVoiceSettingsStore(
    (s) => s.showCommandSettingsModal,
  );
  const showStratBoard = useVoiceSettingsStore((s) => s.showStratBoard);
  const showThemeModal = useThemeStore((s) => s.showThemeModal);

  const setServers = useAppStore((s) => s.setServers);
  const setActiveServer = useAppStore((s) => s.setActiveServer);
  const setCategories = useAppStore((s) => s.setCategories);
  const setChannels = useAppStore((s) => s.setChannels);
  const setActiveChannel = useAppStore((s) => s.setActiveChannel);
  const setActiveVoiceChannel = useAppStore((s) => s.setActiveVoiceChannel);
  const setOnlineMembers = useAppStore((s) => s.setOnlineMembers);
  const setIsMobileSidebarOpen = useAppStore((s) => s.setIsMobileSidebarOpen);
  const setIsMobileRadarOpen = useAppStore((s) => s.setIsMobileRadarOpen);

  const customWallpaper = useThemeStore((s) => s.customWallpaper);
  const safeWallpaper = useMemo(
    () => sanitizeWallpaperUrl(customWallpaper),
    [customWallpaper],
  );

  // 3-Pane Navigation State (Meva Sunucu | Esport Hub | Taktik Masası)
  const [activeView, setActiveView] = useState<MainNavViewMode>('cockpit');
  const [targetTacticalMapId, setTargetTacticalMapId] = useState<TacticalMapId | undefined>(undefined);
  const [touchStartX, setTouchStartX] = useState<number | null>(null);

  const viewIndex = activeView === 'cockpit' ? 0 : activeView === 'esport-hub' ? 1 : 2;

  const handleSelectView = useCallback((view: MainNavViewMode) => {
    setActiveView(view);
    if (view === 'tactical') {
      useVoiceSettingsStore.getState().setShowStratBoard(true);
    } else {
      useVoiceSettingsStore.getState().setShowStratBoard(false);
    }
  }, []);

  useEffect(() => {
    if (showStratBoard && activeView !== 'tactical') {
      setActiveView('tactical');
    }
  }, [showStratBoard, activeView]);

  const handleTouchStart = (e: React.TouchEvent) => {
    setTouchStartX(e.touches[0].clientX);
  };

  const handleTouchEnd = (e: React.TouchEvent) => {
    if (touchStartX === null) return;
    const diff = touchStartX - e.changedTouches[0].clientX;
    const threshold = 65;
    if (diff > threshold) {
      if (activeView === 'cockpit') handleSelectView('esport-hub');
      else if (activeView === 'esport-hub') handleSelectView('tactical');
    } else if (diff < -threshold) {
      if (activeView === 'tactical') handleSelectView('esport-hub');
      else if (activeView === 'esport-hub') handleSelectView('cockpit');
    }
    setTouchStartX(null);
  };

  useEffect(() => {
    useThemeStore.getState().applyCSSVariables();
    const storage = getMevaStorageEngine();
    void storage.hydrateAndBindStores();

    // Check saved operator identity from IndexedDB
    void storage
      .getRecord<{ callsign: string; role: TacticalRole }>(
        STORE_PREFS,
        'operator_identity',
      )
      .then((saved) => {
        if (saved?.callsign) {
          setUser((prev) => ({ ...prev, username: saved.callsign }));
        }
        // Clean boot: Do not hijack mobile with mandatory onboarding popup.
        // User starts directly in clean HUD and can access profile via topbar or mobile customizer.
      });

    // PWA Offline Service Worker Registration
    if (typeof window !== 'undefined') {
      (window as any).__toggleStratBoard = () => useVoiceSettingsStore.getState().toggleStratBoard();
      (window as any).__openStratBoard = () => useVoiceSettingsStore.getState().setShowStratBoard(true);
      if ('serviceWorker' in navigator) {
        window.addEventListener('load', () => {
          void navigator.serviceWorker.register('/sw.js').catch(() => {});
        });
      }
    }

    return () => {
      storage.disposeBindings();
    };
  }, [setShowOnboardingModal]);

  // Auto-join P2P room when opened via serverless URL Hash (#meva=...) or Query Param (?room=MEVA-XXXX)
  useEffect(() => {
    const consumeHashInvite = () => {
      if (typeof window === 'undefined') return;

      // 1. Check Query Param (?room=MEVA-XXXX)
      const params = new URLSearchParams(window.location.search);
      const queryRoom = params.get('room');
      if (queryRoom && /^MEVA-[A-Za-z0-9_-]+$/i.test(queryRoom)) {
        const upper = queryRoom.toUpperCase();
        useAppStore.getState().setActiveScrimRoom({
          code: upper,
          name: `Taktik Lobi ${upper}`,
          created_by: 'peer-remote',
          password: null,
          max_participants: 5,
          created_at: Date.now(),
          ttl: 3 * 60 * 60 * 1000,
        });
        useAppStore.getState().setActiveVoiceChannel(`scrim-${upper}`);
        return;
      }

      // 2. Check Serverless Hash (#meva=...)
      const invite = parseServerlessInviteHash(window.location.hash);
      if (!invite) return;
      useAppStore.getState().setActiveScrimRoom({
        code: invite.roomCode,
        name: invite.roomName,
        created_by: invite.hostPeerId,
        password: null,
        max_participants: 10,
        created_at: invite.createdAt,
        ttl: 2 * 60 * 60 * 1000,
      });
      useAppStore.getState().setActiveVoiceChannel(`scrim-${invite.roomCode}`);
    };
    consumeHashInvite();
    window.addEventListener('hashchange', consumeHashInvite);
    return () => window.removeEventListener('hashchange', consumeHashInvite);
  }, []);

  const isScrimVoice = activeVoiceChannelId?.startsWith('scrim-') ?? false;

  const {
    isMuted,
    isDeafened,
    isSpeaking,
    connectionState,
    leaveVoice,
    toggleMute,
    toggleDeafen,
  } = useWebRTC({
    channelId: activeVoiceChannelId ?? '',
    userId: user.id,
    username: user.username,
    avatarUrl: user.avatar_url,
    isScrim: isScrimVoice,
  });

  // Consolidated Global Keyboard Delegate (Escape + Tactical Hotkeys)
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        setSelectedPlayer(null);
        setRadarContextTarget(null);
        useAppStore.getState().setShowScrimModal(false);
        useAppStore.getState().setShowFriendsModal(false);
        useAppStore.getState().setShowLobbyGate(false);
        useAppStore.getState().setShowChannelBuilderModal(false);
        useAppStore.getState().setShowOnboardingModal(false);
        useAppStore.getState().setShowTourModal(false);
        useAppStore.getState().setShowStreamerOverlayModal(false);
        useAppStore.getState().setShowSoundboardModal(false);
        useAppStore.getState().setShowRadialCommandWheel(false);
        useAppStore.getState().setShowVoiceClipBufferModal(false);
        useAppStore.getState().setShowScrimScheduleModal(false);
        useAppStore.getState().setShowShortcutsHelpModal(false);
        useAppStore.getState().setShowProLicenseModal(false);
        useAppStore.getState().setIsMobileSidebarOpen(false);
        useAppStore.getState().setIsMobileRadarOpen(false);
        useThemeStore.getState().setShowThemeModal(false);
        useVoiceSettingsStore.getState().setShowCommandSettingsModal(false);
        useVoiceSettingsStore.getState().setShowStratBoard(false);
        return;
      }

      if (e.repeat || e.ctrlKey || e.metaKey || e.altKey) return;
      const target = e.target as HTMLElement | null;
      if (
        target &&
        (target.tagName === 'INPUT' ||
          target.tagName === 'TEXTAREA' ||
          target.tagName === 'SELECT' ||
          target.isContentEditable)
      ) {
        return;
      }

      const vState = useVoiceSettingsStore.getState();
      if (vState.showCommandSettingsModal) return;

      if (e.key.toLowerCase() === 'c' && !e.ctrlKey && !e.altKey && !e.metaKey) {
        const cur = useAppStore.getState().showRadialCommandWheel;
        useAppStore.getState().setShowRadialCommandWheel(!cur);
        return;
      }

      if ((e.key === '?' || e.code === 'F1') && !e.ctrlKey && !e.altKey && !e.metaKey) {
        e.preventDefault();
        const cur = useAppStore.getState().showShortcutsHelpModal;
        useAppStore.getState().setShowShortcutsHelpModal(!cur);
        return;
      }

      if (e.key.toLowerCase() === 'r' && !e.ctrlKey && !e.altKey && !e.metaKey) {
        useAppStore.getState().toggleRadar();
        return;
      }

      if (e.code === vState.keybinds.stratBoardKey || e.code === 'KeyM' || e.key.toLowerCase() === 'm') {
        handleSelectView(activeView === 'tactical' ? 'cockpit' : 'tactical');
      } else if (e.code === 'Digit1' && !e.ctrlKey && !e.altKey && !e.metaKey) {
        handleSelectView('cockpit');
      } else if (e.code === 'Digit2' && !e.ctrlKey && !e.altKey && !e.metaKey) {
        handleSelectView('esport-hub');
      } else if (e.code === 'Digit3' && !e.ctrlKey && !e.altKey && !e.metaKey) {
        handleSelectView('tactical');
      } else if (e.code === vState.keybinds.miniHudKey) {
        vState.toggleMiniHud();
      } else if (e.code === vState.keybinds.muteKey) {
        toggleMute();
      } else if (e.code === vState.keybinds.deafenKey) {
        toggleDeafen();
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [toggleMute, toggleDeafen, activeView, handleSelectView]);

  // Load clean state from IndexedDB (Zero mock data policy)
  useEffect(() => {
    let isCancelled = false;
    const storage = getMevaStorageEngine();

    Promise.all([
      storage.getRecord<Server[]>(STORE_PREFS, 'custom_servers'),
      storage.getRecord<ChannelCategory[]>(STORE_PREFS, 'custom_categories'),
      storage.getRecord<Channel[]>(STORE_PREFS, 'custom_channels'),
      storage.loadSessionRecoverySnapshot(),
    ]).then(([savedServers, savedCats, savedChans, recoveredSession]) => {
      if (isCancelled) return;
      if (savedServers && savedServers.length > 0) {
        if (savedCats && savedCats.length > 0) {
          setCategories(savedCats);
        }
        if (savedChans && savedChans.length > 0) {
          setChannels(savedChans);
        }
        setServers(savedServers);
        const restoredServerId =
          recoveredSession?.activeServerId &&
          savedServers.some((s) => s.id === recoveredSession.activeServerId)
            ? recoveredSession.activeServerId
            : savedServers[0].id;
        setActiveServer(restoredServerId);

        if (
          recoveredSession?.activeChannelId &&
          savedChans?.some((c) => c.id === recoveredSession.activeChannelId)
        ) {
          setActiveChannel(recoveredSession.activeChannelId);
        }
        if (
          recoveredSession?.activeVoiceChannelId &&
          savedChans?.some((c) => c.id === recoveredSession.activeVoiceChannelId)
        ) {
          setActiveVoiceChannel(recoveredSession.activeVoiceChannelId);
        }
      } else {
        // Purge mock data: leave state empty so [+] Kendi Sunucunu Kur button is shown
        setServers([]);
        setCategories([]);
        setChannels([]);
      }
      if (
        recoveredSession?.activeView &&
        (recoveredSession.activeView === 'cockpit' ||
          recoveredSession.activeView === 'esport-hub' ||
          recoveredSession.activeView === 'tactical')
      ) {
        setActiveView(recoveredSession.activeView);
        if (recoveredSession.activeView === 'tactical') {
          useVoiceSettingsStore.getState().setShowStratBoard(true);
        }
      }
      setOnlineMembers(DEFAULT_MEMBERS);
    });

    return () => {
      isCancelled = true;
    };
  }, [
    setServers,
    setActiveServer,
    setCategories,
    setChannels,
    setActiveChannel,
    setActiveVoiceChannel,
    setOnlineMembers,
  ]);

  const activeChannelId = useAppStore((s) => s.activeChannelId);

  useEffect(() => {
    useRBACStore.getState().setLocalActorIdentity(user.id, user.username);
  }, [user.id, user.username]);

  // IndexedDB instant session recovery persistence
  useEffect(() => {
    const storage = getMevaStorageEngine();
    storage.saveSessionRecoverySnapshot({
      activeServerId,
      activeChannelId,
      activeVoiceChannelId,
      activeView,
      updatedAt: Date.now(),
    });
  }, [activeServerId, activeChannelId, activeVoiceChannelId, activeView]);

  useEffect(() => {
    const handleFlush = () => {
      void getMevaStorageEngine().flushPendingWrites();
    };
    window.addEventListener('pagehide', handleFlush);
    window.addEventListener('beforeunload', handleFlush);
    return () => {
      window.removeEventListener('pagehide', handleFlush);
      window.removeEventListener('beforeunload', handleFlush);
    };
  }, []);

  const handleSelectPlayer = useCallback((member: Profile) => {
    setSelectedPlayer(member);
  }, []);

  const handleContextMenuPlayer = useCallback(
    (member: Profile, x: number, y: number) => {
      setRadarContextTarget({
        id: member.id,
        username: member.username,
        x,
        y,
      });
    },
    [],
  );



  const voiceControls = useMemo<VoiceControls>(
    () => ({
      isMuted,
      isDeafened,
      isSpeaking,
      connectionState,
      toggleMute,
      toggleDeafen,
      leaveVoice,
    }),
    [
      isMuted,
      isDeafened,
      isSpeaking,
      connectionState,
      toggleMute,
      toggleDeafen,
      leaveVoice,
    ],
  );

  return (
    <div
      className={`relative h-[100dvh] w-screen overflow-hidden select-none text-gl-text-normal flex flex-col ${
        safeWallpaper ? 'bg-gl-bg-darkest' : 'ambient-shell'
      }`}
      style={
        safeWallpaper
          ? {
              backgroundImage: `url("${safeWallpaper}")`,
              backgroundSize: 'cover',
              backgroundPosition: 'center',
            }
          : undefined
      }
    >
      {/* 1. TOP INDUSTRIAL COMMAND DECK */}
      <GhostNavbar />

      {/* 2. MAIN THREE-COLUMN WAR ROOM OR COMPACT IN-GAME MINI HUD */}
      {miniHudActive ? (
        <MiniHudOverlay username={user.username} voiceControls={voiceControls} />
      ) : (
        <div className="relative z-10 flex-1 flex flex-col overflow-hidden min-h-0">
          {/* ── 3-PANE 60 FPS SLIDING VIEWDECK (Meva Sunucu | Esport Hub | Taktik Masası) ── */}
          <div
            className="w-full flex-1 flex overflow-hidden min-h-0 relative"
            onTouchStart={handleTouchStart}
            onTouchEnd={handleTouchEnd}
          >
            <div
              className="flex w-full min-w-0 h-full transition-transform duration-350 ease-[cubic-bezier(0.16,1,0.3,1)] will-change-transform"
              style={{
                transform: `translate3d(-${viewIndex * 100}%, 0, 0)`,
              }}
            >
              {/* PANE 1: MEVA SUNUCU (SERVER HQ) */}
              <div className="w-full min-w-full max-w-full basis-full h-full flex overflow-hidden min-h-0 lg:p-2.5 lg:gap-2.5 flex-shrink-0">
                {/* Desktop Left Channel & Voice Hub */}
                <div className="hidden lg:flex h-full flex-shrink-0">
                  <TacticalSidebar
                    username={user.username}
                    voiceControls={voiceControls}
                  />
                </div>

                {/* Mobile & Tablet Left Drawer */}
                {isMobileSidebarOpen && (
                  <div
                    className="fixed inset-0 z-40 lg:hidden exec-backdrop flex"
                    onClick={() => setIsMobileSidebarOpen(false)}
                  >
                    <div
                      className="w-[86vw] max-w-[320px] h-full shadow-2xl"
                      onClick={(e) => e.stopPropagation()}
                    >
                      <TacticalSidebar
                        username={user.username}
                        voiceControls={voiceControls}
                      />
                    </div>
                  </div>
                )}

                {/* Center Tactical Bento Cockpit */}
                <StreamChatArea
                  userId={user.id}
                  username={user.username}
                  onSelectPlayer={handleSelectPlayer}
                  voiceControls={voiceControls}
                />

                {/* Desktop Right Squad Roster */}
                <div className="hidden lg:flex h-full flex-shrink-0">
                  <PlayerRadarHUD
                    onSelectPlayer={handleSelectPlayer}
                    onContextMenuPlayer={handleContextMenuPlayer}
                  />
                </div>

                {/* Mobile & Tablet Right Drawer */}
                {isMobileRadarOpen && (
                  <div
                    className="fixed inset-0 z-40 lg:hidden exec-backdrop flex justify-end"
                    onClick={() => setIsMobileRadarOpen(false)}
                  >
                    <div
                      className="w-[86vw] max-w-[320px] h-full shadow-2xl"
                      onClick={(e) => e.stopPropagation()}
                    >
                      <PlayerRadarHUD
                        onSelectPlayer={handleSelectPlayer}
                        onContextMenuPlayer={handleContextMenuPlayer}
                      />
                    </div>
                  </div>
                )}
              </div>

              {/* PANE 2: ESPORT HUB (HLTV / VLR.GG STYLE PLATFORM) */}
              <div className="w-full min-w-full max-w-full basis-full h-full flex flex-col overflow-hidden min-h-0 flex-shrink-0">
                <EsportHubView
                  onOpenTacticalMap={(mapId) => {
                    if (mapId) setTargetTacticalMapId(mapId as TacticalMapId);
                    handleSelectView('tactical');
                  }}
                />
              </div>

              {/* PANE 3: TAKTİKSEL STRATEJİ MASASI (EMBEDDED 60 FPS MAP STUDIO) */}
              <div className="w-full min-w-full max-w-full basis-full h-full flex flex-col overflow-hidden min-h-0 flex-shrink-0">
                <TacticalMapBoard
                  embedded
                  initialMapId={targetTacticalMapId}
                  onClose={() => handleSelectView('cockpit')}
                />
              </div>
            </div>
          </div>

          {/* ── MOBİL BAŞPARMAK HIZLI KOMUT KAPSÜLÜ (SAĞ / SOL EL ADAPTİF) ── */}
          <MobileThumbCommandPill
            activeView={activeView}
            voiceControls={voiceControls}
          />

          {/* ── ESTETİK FLOATING ESPORT DOCK (ALT FAY HATTI) ── */}
          <FloatingEsportDock
            activeView={activeView}
            onSelectView={handleSelectView}
            voiceControls={voiceControls}
          />
        </div>
      )}

      {/* 4. MODALS & OVERLAYS (Conditional Zero-Footprint Rendering) */}
      {showScrimModal && <ScrimModal />}
      {showThemeModal && <ThemeSettingsModal />}
      {showCommandSettingsModal && <MevaCommandSettingsModal />}
      {showStratBoard && activeView !== 'tactical' && <TacticalStratDrawer />}
      {showFriendsModal && <FriendsModal />}
      {showLobbyGate && (
        <LobbyGateModal
          isOpen={showLobbyGate}
          onClose={() => setShowLobbyGate(false)}
          onJoinedRoom={(_code, name) => {
            setUser((prev) => ({ ...prev, username: name }));
          }}
        />
      )}
      {showChannelBuilderModal && (
        <QuickChannelBuilderModal
          isOpen={showChannelBuilderModal}
          onClose={() => setShowChannelBuilderModal(false)}
        />
      )}
      {showOnboardingModal && (
        <OnboardingModal
          isOpen={showOnboardingModal}
          onClose={() => setShowOnboardingModal(false)}
          onCompleted={(callsign) => {
            setUser((prev) => ({ ...prev, username: callsign }));
          }}
        />
      )}
      {showTourModal && (
        <InteractiveTourModal
          isOpen={showTourModal}
          onClose={() => setShowTourModal(false)}
          onOpenServerBuilder={() => setShowChannelBuilderModal(true)}
        />
      )}
      {showStreamerOverlayModal && (
        <StreamerOverlayModal
          isOpen={showStreamerOverlayModal}
          onClose={() => setShowStreamerOverlayModal(false)}
        />
      )}
      {showSoundboardModal && (
        <BroadcastSoundboardModal
          isOpen={showSoundboardModal}
          onClose={() => setShowSoundboardModal(false)}
        />
      )}
      {showRadialCommandWheel && (
        <RadialCommandWheel
          isOpen={showRadialCommandWheel}
          onClose={() => setShowRadialCommandWheel(false)}
        />
      )}
      {showVoiceClipBufferModal && (
        <VoiceClipBufferModal
          isOpen={showVoiceClipBufferModal}
          onClose={() => setShowVoiceClipBufferModal(false)}
        />
      )}
      {showScrimScheduleModal && (
        <ScrimScheduleModal
          isOpen={showScrimScheduleModal}
          onClose={() => setShowScrimScheduleModal(false)}
          onLaunchVeto={() => useVoiceSettingsStore.getState().toggleStratBoard()}
        />
      )}
      {showShortcutsHelpModal && (
        <ShortcutsHelpModal
          isOpen={showShortcutsHelpModal}
          onClose={() => setShowShortcutsHelpModal(false)}
        />
      )}
      {showProLicenseModal && (
        <MevaProLicenseModal
          isOpen={showProLicenseModal}
          onClose={() => setShowProLicenseModal(false)}
        />
      )}
      {radarContextTarget && (
        <OperatorContextMenu
          target={radarContextTarget}
          onClose={() => setRadarContextTarget(null)}
          onOpenDspDrawer={(id) => {
            const found =
              id === 'usr-local'
                ? user
                : useAppStore
                    .getState()
                    .onlineMembers.find((m) => m.id === id);
            setSelectedPlayer(
              found ?? {
                id,
                username: id === 'usr-local' ? user.username : 'Operatör',
                avatar_url: null,
                status: 'in-game',
                activity: 'ENTRY',
                created_at: SEED_ISO,
              },
            );
          }}
          voiceControls={voiceControls}
        />
      )}
      {selectedPlayer && (
        <TacticalPlayerHUD
          player={selectedPlayer}
          onClose={() => setSelectedPlayer(null)}
        />
      )}
      <TacticalVoiceOverlay
        username={user.username}
        userId={user.id}
        voiceControls={voiceControls}
      />
      <MobileCustomizerSheet />
      <NotificationDrawer />
    </div>
  );
}
