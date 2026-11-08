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
import { getMevaStorageEngine } from '@/src/lib/storageEngine';
import { GhostNavbar } from '@/components/layout/GhostNavbar';
import { TacticalSidebar } from '@/components/layout/TacticalSidebar';
import { StreamChatArea } from '@/components/chat/StreamChatArea';
import { PlayerRadarHUD } from '@/components/hud/PlayerRadarHUD';
import { MobileBottomNav } from '@/components/layout/MobileBottomNav';
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
import { type TacticalRole } from '@/store/useHUDStore';
import { STORE_PREFS } from '@/src/lib/storageEngine';
import type {
  Profile,
  Server,
  ChannelCategory,
  Channel,
  VoiceControls,
} from '@/types';

const SEED_ISO = '2026-11-06T19:00:00.000Z';

const DEFAULT_SERVERS: Server[] = [
  {
    id: 'srv-1',
    name: '🎥 Yayıncı Topluluk Hub’ı',
    icon_url: null,
    owner_id: 'usr-1',
    invite_code: 'STREAM',
    created_at: SEED_ISO,
  },
  {
    id: 'srv-2',
    name: '🏆 Espor Scrim & Klan Hub',
    icon_url: null,
    owner_id: 'usr-1',
    invite_code: 'ESPOR',
    created_at: SEED_ISO,
  },
  {
    id: 'srv-3',
    name: '⚡ Hızlı Arkadaş Grubu',
    icon_url: null,
    owner_id: 'usr-1',
    invite_code: 'SQUAD',
    created_at: SEED_ISO,
  },
];

const DEFAULT_CATEGORIES: Record<string, ChannelCategory[]> = {
  'srv-1': [
    { id: 'cat-1-lobby', server_id: 'srv-1', name: '📌 LOBİ & SOHBET', position: 0, is_collapsed: false },
    { id: 'cat-1-moba', server_id: 'srv-1', name: '⚔️ MOBA [LoL / Dota / MLBB]', position: 1, is_collapsed: false },
    { id: 'cat-1-fps', server_id: 'srv-1', name: '🎯 TAKTİK FPS [CS2 / Valo]', position: 2, is_collapsed: false },
    { id: 'cat-1-br', server_id: 'srv-1', name: '🪂 BATTLE ROYALE [PUBG / Apex]', position: 3, is_collapsed: false },
    { id: 'cat-1-chill', server_id: 'srv-1', name: '☕ CHILL & MÜZİK', position: 4, is_collapsed: false },
  ],
  'srv-2': [
    { id: 'cat-2-match', server_id: 'srv-2', name: '🏆 MAÇ & TURNUVA ODALARI', position: 0, is_collapsed: false },
    { id: 'cat-2-coach', server_id: 'srv-2', name: '🧠 TAKTİK & KOÇLUK', position: 1, is_collapsed: false },
    { id: 'cat-2-warmup', server_id: 'srv-2', name: '⚡ YEDEK LOBİ & ISINMA', position: 2, is_collapsed: false },
  ],
  'srv-3': [
    { id: 'cat-3-chill', server_id: 'srv-3', name: '☕ CHILL / MUHABBET', position: 0, is_collapsed: false },
    { id: 'cat-3-play', server_id: 'srv-3', name: '🎮 ANA OYUN ODALARI', position: 1, is_collapsed: false },
  ],
};

const DEFAULT_CHANNELS: Record<string, Channel[]> = {
  'srv-1': [
    { id: 'ch-genel', server_id: 'srv-1', category_id: 'cat-1-lobby', name: 'genel-sohbet', type: 'text', position: 0, created_at: SEED_ISO, game_id: 'chill', max_participants: 0, tags: ['#Genel', '#Sohbet'] },
    { id: 'ch-yayin', server_id: 'srv-1', category_id: 'cat-1-lobby', name: 'yayin-bildirim', type: 'text', position: 1, created_at: SEED_ISO, game_id: 'chill', max_participants: 0, tags: ['#Yayın'] },
    { id: 'ch-lol-5v5', server_id: 'srv-1', category_id: 'cat-1-moba', name: 'lol-dereceli-5v5', type: 'voice', position: 2, created_at: SEED_ISO, game_id: 'lol', max_participants: 5, tags: ['#LoL', '#Dereceli-5v5'] },
    { id: 'ch-dota-5v5', server_id: 'srv-1', category_id: 'cat-1-moba', name: 'dota2-ranked', type: 'voice', position: 3, created_at: SEED_ISO, game_id: 'dota2', max_participants: 5, tags: ['#Dota2', '#Ranked'] },
    { id: 'ch-cs2-premier', server_id: 'srv-1', category_id: 'cat-1-fps', name: 'cs2-premier', type: 'voice', position: 4, created_at: SEED_ISO, game_id: 'cs2', max_participants: 5, tags: ['#CS2', '#Premier'] },
    { id: 'ch-valo-5stack', server_id: 'srv-1', category_id: 'cat-1-fps', name: 'valorant-5stack', type: 'voice', position: 5, created_at: SEED_ISO, game_id: 'valorant', max_participants: 5, tags: ['#Valorant', '#5Stack'] },
    { id: 'ch-pubg-squad', server_id: 'srv-1', category_id: 'cat-1-br', name: 'pubg-squad-erangel', type: 'voice', position: 6, created_at: SEED_ISO, game_id: 'pubg', max_participants: 4, tags: ['#PUBG', '#Squad'] },
    { id: 'ch-chill-music', server_id: 'srv-1', category_id: 'cat-1-chill', name: 'kahve-muhabbet', type: 'voice', position: 7, created_at: SEED_ISO, game_id: 'chill', max_participants: 0, tags: ['#Chill', '#Müzik'] },
  ],
  'srv-2': [
    { id: 'ch-scrim-1', server_id: 'srv-2', category_id: 'cat-2-match', name: 'scrim-oda-1-cs2', type: 'voice', position: 0, created_at: SEED_ISO, game_id: 'cs2', max_participants: 5, tags: ['#Scrim', '#CS2'] },
    { id: 'ch-scrim-2', server_id: 'srv-2', category_id: 'cat-2-match', name: 'scrim-oda-2-valo', type: 'voice', position: 1, created_at: SEED_ISO, game_id: 'valorant', max_participants: 5, tags: ['#Scrim', '#Valo'] },
    { id: 'ch-scrim-txt', server_id: 'srv-2', category_id: 'cat-2-match', name: 'scrim-chat', type: 'text', position: 2, created_at: SEED_ISO, game_id: 'cs2', max_participants: 0, tags: ['#Scrim'] },
    { id: 'ch-coach', server_id: 'srv-2', category_id: 'cat-2-coach', name: 'taktik-analiz-koc', type: 'voice', position: 3, created_at: SEED_ISO, game_id: 'cs2', max_participants: 10, tags: ['#Koç'] },
    { id: 'ch-isinma', server_id: 'srv-2', category_id: 'cat-2-warmup', name: 'isinma-dm', type: 'voice', position: 4, created_at: SEED_ISO, game_id: 'cs2', max_participants: 10, tags: ['#Isınma'] },
  ],
  'srv-3': [
    { id: 'ch-s3-chill', server_id: 'srv-3', category_id: 'cat-3-chill', name: 'kahve-muhabbet', type: 'voice', position: 0, created_at: SEED_ISO, game_id: 'chill', max_participants: 0, tags: ['#Chill'] },
    { id: 'ch-s3-txt', server_id: 'srv-3', category_id: 'cat-3-chill', name: 'sohbet', type: 'text', position: 1, created_at: SEED_ISO, game_id: 'chill', max_participants: 0, tags: ['#Sohbet'] },
    { id: 'ch-s3-valo', server_id: 'srv-3', category_id: 'cat-3-play', name: 'oyun-odasi-valo', type: 'voice', position: 2, created_at: SEED_ISO, game_id: 'valorant', max_participants: 5, tags: ['#Valorant'] },
    { id: 'ch-s3-lol', server_id: 'srv-3', category_id: 'cat-3-play', name: 'oyun-odasi-lol', type: 'voice', position: 3, created_at: SEED_ISO, game_id: 'lol', max_participants: 5, tags: ['#LoL'] },
  ],
};

const DEFAULT_MEMBERS: Profile[] = [];

export default function MevaHUDApp() {
  useGameBoost();

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
        } else {
          // 100% Optional / Skip-friendly dynamic onboarding wizard
          setShowOnboardingModal(true);
        }
      });

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

      if (e.code === vState.keybinds.stratBoardKey) {
        vState.toggleStratBoard();
      } else if (e.code === vState.keybinds.miniHudKey) {
        vState.toggleMiniHud();
      } else if (e.code === vState.keybinds.muteKey) {
        toggleMute();
      } else if (e.code === vState.keybinds.deafenKey) {
        toggleDeafen();
      }
    };

    window.addEventListener('keydown', handleKeyDown, { passive: true });
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [toggleMute, toggleDeafen]);

  useEffect(() => {
    setServers(DEFAULT_SERVERS);
    setActiveServer(DEFAULT_SERVERS[0].id);
    setOnlineMembers(DEFAULT_MEMBERS);
  }, [setServers, setActiveServer, setOnlineMembers]);

  useEffect(() => {
    const serverKey =
      activeServerId && DEFAULT_CHANNELS[activeServerId]
        ? activeServerId
        : 'srv-1';
    const fallbackCats =
      DEFAULT_CATEGORIES[serverKey] ?? DEFAULT_CATEGORIES['srv-1'];
    const fallbackChans =
      DEFAULT_CHANNELS[serverKey] ?? DEFAULT_CHANNELS['srv-1'];

    setCategories(fallbackCats);
    setChannels(fallbackChans);

    const firstText = fallbackChans.find((c) => c.type === 'text');
    if (firstText) setActiveChannel(firstText.id);

    const firstVoice = fallbackChans.find((c) => c.type === 'voice');
    if (firstVoice) setActiveVoiceChannel(firstVoice.id);
  }, [
    activeServerId,
    setCategories,
    setChannels,
    setActiveChannel,
    setActiveVoiceChannel,
  ]);

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
        <>
          <div className="relative z-10 flex-1 flex overflow-hidden min-h-0 lg:p-2.5 lg:gap-2.5">
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

          {/* 3. MOBILE COMMAND DOCK */}
          <MobileBottomNav />
        </>
      )}

      {/* 4. MODALS & OVERLAYS (Conditional Zero-Footprint Rendering) */}
      {showScrimModal && <ScrimModal />}
      {showThemeModal && <ThemeSettingsModal />}
      {showCommandSettingsModal && <MevaCommandSettingsModal />}
      {showStratBoard && <TacticalStratDrawer />}
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
    </div>
  );
}
