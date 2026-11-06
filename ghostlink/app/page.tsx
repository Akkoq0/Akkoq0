'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Main Industrial Command Shell
// ─────────────────────────────────────────────────────────

import { useEffect, useState, useCallback, useMemo } from 'react';
import { getSupabase } from '@/lib/supabase';
import { useAppStore } from '@/lib/store';
import { useThemeStore } from '@/store/useThemeStore';
import { useGameBoost } from '@/hooks/useGameBoost';
import { useWebRTC } from '@/hooks/useWebRTC';
import { GhostNavbar } from '@/components/layout/GhostNavbar';
import { TacticalSidebar } from '@/components/layout/TacticalSidebar';
import { StreamChatArea } from '@/components/chat/StreamChatArea';
import { PlayerRadarHUD } from '@/components/hud/PlayerRadarHUD';
import { MobileBottomNav } from '@/components/layout/MobileBottomNav';
import { ScrimModal } from '@/components/ScrimModal';
import { ThemeSettingsModal } from '@/components/ui/ThemeSettingsModal';
import { TacticalPlayerHUD } from '@/components/ui/TacticalPlayerHUD';
import { FriendsModal } from '@/components/ui/FriendsModal';
import type {
  Profile,
  Server,
  ChannelCategory,
  Channel,
  VoiceControls,
} from '@/types';

const DEFAULT_SERVERS: Server[] = [
  { id: 'srv-1', name: 'Valorant TR Pro', icon_url: null, owner_id: 'usr-1', invite_code: 'VALTR', created_at: new Date().toISOString() },
  { id: 'srv-2', name: 'CS2 Faceit Hub', icon_url: null, owner_id: 'usr-1', invite_code: 'CS2TR', created_at: new Date().toISOString() },
  { id: 'srv-3', name: 'Eternals Scrim', icon_url: null, owner_id: 'usr-1', invite_code: 'ETRNL', created_at: new Date().toISOString() },
];

const DEFAULT_CATEGORIES: Record<string, ChannelCategory[]> = {
  'srv-1': [
    { id: 'cat-1', server_id: 'srv-1', name: 'METİN KANALLARI', position: 0, is_collapsed: false },
    { id: 'cat-2', server_id: 'srv-1', name: 'SES FREKANSLARI', position: 1, is_collapsed: false },
  ],
  'srv-2': [
    { id: 'cat-3', server_id: 'srv-2', name: 'FACEIT LOBİ', position: 0, is_collapsed: false },
    { id: 'cat-4', server_id: 'srv-2', name: 'TAKIM SES', position: 1, is_collapsed: false },
  ],
  'srv-3': [
    { id: 'cat-5', server_id: 'srv-3', name: 'SCRIM KOORDİNASYON', position: 0, is_collapsed: false },
  ],
};

const DEFAULT_CHANNELS: Record<string, Channel[]> = {
  'srv-1': [
    { id: 'ch-2', server_id: 'srv-1', category_id: 'cat-1', name: 'genel-sohbet', type: 'text', position: 0, created_at: new Date().toISOString() },
    { id: 'ch-3', server_id: 'srv-1', category_id: 'cat-1', name: 'scrim-arama', type: 'text', position: 1, created_at: new Date().toISOString() },
    { id: 'ch-vod', server_id: 'srv-1', category_id: 'cat-1', name: 'vod-notları', type: 'text', position: 2, created_at: new Date().toISOString() },
    { id: 'ch-1', server_id: 'srv-1', category_id: 'cat-1', name: 'turnuva-duyuru', type: 'text', position: 3, created_at: new Date().toISOString() },
    { id: 'ch-4', server_id: 'srv-1', category_id: 'cat-2', name: 'Taktik Lobi #1', type: 'voice', position: 4, created_at: new Date().toISOString() },
    { id: 'ch-5', server_id: 'srv-1', category_id: 'cat-2', name: 'Scrim Odası Alpha', type: 'voice', position: 5, created_at: new Date().toISOString() },
    { id: 'ch-6', server_id: 'srv-1', category_id: 'cat-2', name: 'Koç & Analiz Odası', type: 'voice', position: 6, created_at: new Date().toISOString() },
  ],
  'srv-2': [
    { id: 'ch-7', server_id: 'srv-2', category_id: 'cat-3', name: 'genel-sohbet', type: 'text', position: 0, created_at: new Date().toISOString() },
    { id: 'ch-3', server_id: 'srv-2', category_id: 'cat-3', name: 'scrim-arama', type: 'text', position: 1, created_at: new Date().toISOString() },
    { id: 'ch-vod', server_id: 'srv-2', category_id: 'cat-3', name: 'vod-notları', type: 'text', position: 2, created_at: new Date().toISOString() },
    { id: 'ch-8', server_id: 'srv-2', category_id: 'cat-4', name: 'Taktik Lobi #1', type: 'voice', position: 3, created_at: new Date().toISOString() },
    { id: 'ch-5', server_id: 'srv-2', category_id: 'cat-4', name: 'Scrim Odası Alpha', type: 'voice', position: 4, created_at: new Date().toISOString() },
    { id: 'ch-6', server_id: 'srv-2', category_id: 'cat-4', name: 'Koç & Analiz Odası', type: 'voice', position: 5, created_at: new Date().toISOString() },
  ],
  'srv-3': [
    { id: 'ch-9', server_id: 'srv-3', category_id: 'cat-5', name: 'genel-sohbet', type: 'text', position: 0, created_at: new Date().toISOString() },
    { id: 'ch-3', server_id: 'srv-3', category_id: 'cat-5', name: 'scrim-arama', type: 'text', position: 1, created_at: new Date().toISOString() },
    { id: 'ch-10', server_id: 'srv-3', category_id: 'cat-5', name: 'Taktik Lobi #1', type: 'voice', position: 2, created_at: new Date().toISOString() },
    { id: 'ch-5', server_id: 'srv-3', category_id: 'cat-5', name: 'Scrim Odası Alpha', type: 'voice', position: 3, created_at: new Date().toISOString() },
    { id: 'ch-6', server_id: 'srv-3', category_id: 'cat-5', name: 'Koç & Analiz Odası', type: 'voice', position: 4, created_at: new Date().toISOString() },
  ],
};

const DEFAULT_MEMBERS: Profile[] = [
  { id: 'usr-1', username: 'cNed', avatar_url: null, status: 'in-game', activity: 'Valorant — Radiant #14', created_at: new Date().toISOString() },
  { id: 'usr-2', username: 'woxic', avatar_url: null, status: 'in-game', activity: 'CS2 — Faceit Lvl 10', created_at: new Date().toISOString() },
  { id: 'usr-4', username: 'XANTARES', avatar_url: null, status: 'online', activity: 'Aim Botz Warmup', created_at: new Date().toISOString() },
  { id: 'usr-3', username: 'Alfajer', avatar_url: null, status: 'idle', activity: 'VOD İnceleme', created_at: new Date().toISOString() },
];

export default function MevaHUDApp() {
  useGameBoost();

  const [user, setUser] = useState<Profile>({
    id: 'usr-local',
    username: 'Operatör',
    avatar_url: null,
    status: 'online',
    activity: 'Meva Command',
    created_at: new Date().toISOString(),
  });

  const [selectedPlayer, setSelectedPlayer] = useState<Profile | null>(null);

  const activeServerId = useAppStore((s) => s.activeServerId);
  const activeVoiceChannelId = useAppStore((s) => s.activeVoiceChannelId);
  const isMobileSidebarOpen = useAppStore((s) => s.isMobileSidebarOpen);
  const isMobileRadarOpen = useAppStore((s) => s.isMobileRadarOpen);

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

  useEffect(() => {
    useThemeStore.getState().applyCSSVariables();
  }, []);

  useEffect(() => {
    setServers(DEFAULT_SERVERS);
    setActiveServer(DEFAULT_SERVERS[0].id);
    setOnlineMembers(DEFAULT_MEMBERS);
  }, [setServers, setActiveServer, setOnlineMembers]);

  useEffect(() => {
    const serverKey = activeServerId && DEFAULT_CHANNELS[activeServerId] ? activeServerId : 'srv-1';
    const fallbackCats = DEFAULT_CATEGORIES[serverKey] ?? DEFAULT_CATEGORIES['srv-1'];
    const fallbackChans = DEFAULT_CHANNELS[serverKey] ?? DEFAULT_CHANNELS['srv-1'];

    setCategories(fallbackCats);
    setChannels(fallbackChans);

    const firstText = fallbackChans.find((c) => c.type === 'text');
    if (firstText) setActiveChannel(firstText.id);

    const firstVoice = fallbackChans.find((c) => c.type === 'voice');
    if (firstVoice) setActiveVoiceChannel(firstVoice.id);
  }, [activeServerId, setCategories, setChannels, setActiveChannel, setActiveVoiceChannel]);

  const isScrimVoice = activeVoiceChannelId?.startsWith('scrim-') ?? false;

  const {
    isMuted,
    isDeafened,
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

  const handleSelectPlayer = useCallback((member: Profile) => {
    setSelectedPlayer(member);
  }, []);

  const voiceControls = useMemo<VoiceControls>(
    () => ({
      isMuted,
      isDeafened,
      connectionState,
      toggleMute,
      toggleDeafen,
      leaveVoice,
    }),
    [isMuted, isDeafened, connectionState, toggleMute, toggleDeafen, leaveVoice],
  );

  return (
    <div
      className="relative h-[100dvh] w-screen overflow-hidden select-none bg-gl-bg-darkest text-gl-text-normal flex flex-col"
      style={
        customWallpaper
          ? {
              backgroundImage: `url(${customWallpaper})`,
              backgroundSize: 'cover',
              backgroundPosition: 'center',
            }
          : undefined
      }
    >
      {/* 1. TOP INDUSTRIAL COMMAND DECK */}
      <GhostNavbar />

      {/* 2. MAIN THREE-COLUMN WAR ROOM (Spacious Floating Heavy-Duty Modules) */}
      <div className="relative z-10 flex-1 flex overflow-hidden min-h-0 md:p-2.5 md:gap-2.5">
        {/* Desktop Left Channel & Voice Hub */}
        <div className="hidden md:flex h-full flex-shrink-0">
          <TacticalSidebar
            username={user.username}
            voiceControls={voiceControls}
          />
        </div>

        {/* Mobile Left Drawer */}
        {isMobileSidebarOpen && (
          <div
            className="fixed inset-0 z-40 md:hidden bg-black/80 flex"
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
        <div className="hidden md:flex h-full flex-shrink-0">
          <PlayerRadarHUD onSelectPlayer={handleSelectPlayer} />
        </div>

        {/* Mobile Right Drawer */}
        {isMobileRadarOpen && (
          <div
            className="fixed inset-0 z-40 md:hidden bg-black/75 flex justify-end"
            onClick={() => setIsMobileRadarOpen(false)}
          >
            <div
              className="w-[86vw] max-w-[320px] h-full shadow-2xl"
              onClick={(e) => e.stopPropagation()}
            >
              <PlayerRadarHUD onSelectPlayer={handleSelectPlayer} />
            </div>
          </div>
        )}
      </div>

      {/* 3. MOBILE COMMAND DOCK */}
      <MobileBottomNav />

      {/* 4. MODALS & OVERLAYS */}
      <ScrimModal />
      <ThemeSettingsModal />
      <FriendsModal />
      <TacticalPlayerHUD
        player={selectedPlayer}
        onClose={() => setSelectedPlayer(null)}
      />
    </div>
  );
}
