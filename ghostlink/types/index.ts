// ─────────────────────────────────────────────────────────
// GhostLink — Core Type Definitions (v2 — Full Interactive)
// ─────────────────────────────────────────────────────────

// ─── User & Profile ────────────────────────────────────

export type UserStatus = 'online' | 'in-game' | 'idle' | 'dnd' | 'offline';

export interface Profile {
  id: string;
  username: string;
  avatar_url: string | null;
  status: UserStatus;
  /** Custom status text e.g. "Playing Valorant" */
  activity: string | null;
  created_at: string;
}

// ─── Server ────────────────────────────────────────────

export interface Server {
  id: string;
  name: string;
  icon_url: string | null;
  owner_id: string;
  invite_code: string;
  created_at: string;
}

// ─── Channel Categories ────────────────────────────────

export interface ChannelCategory {
  id: string;
  server_id: string;
  name: string;
  position: number;
  is_collapsed: boolean;
}

// ─── Channels ──────────────────────────────────────────

export type ChannelType = 'text' | 'voice';

export interface Channel {
  id: string;
  server_id: string;
  category_id: string | null;
  name: string;
  type: ChannelType;
  position: number;
  created_at: string;
  game_id?: string;
  max_participants?: number;
  tags?: string[];
}

// ─── Messages ──────────────────────────────────────────

export interface Message {
  id: string;
  channel_id: string;
  author_id: string;
  content: string;
  created_at: string;
  /** Joined from profiles */
  author?: Profile;
}

// ─── Friends & 1v1 Direct Messages ─────────────────────

export type FriendStatus = 'pending' | 'accepted' | 'blocked';

export interface Friendship {
  id: string;
  user_id: string;
  friend_id: string;
  status: FriendStatus;
  friend?: Profile;
  created_at: string;
}

export interface DirectMessage {
  id: string;
  sender_id: string;
  recipient_id: string;
  content: string;
  created_at: string;
  sender?: Profile;
}

// ─── Server Members ────────────────────────────────────

export type MemberRole = 'owner' | 'admin' | 'member' | 'coach';

export interface ServerMember {
  server_id: string;
  user_id: string;
  role: MemberRole;
  joined_at: string;
  profile?: Profile;
}

// ─── WebRTC Signaling ──────────────────────────────────

export interface SignalPayload {
  type: 'offer' | 'answer' | 'ice-candidate';
  from_user_id: string;
  to_user_id: string;
  channel_id: string;
  data: string;
}

// ─── Voice Presence ────────────────────────────────────

export interface VoicePresence {
  user_id: string;
  username: string;
  avatar_url: string | null;
  is_muted: boolean;
  is_deafened: boolean;
  is_speaking: boolean;
}

// ─── Game-Boost Eco Mode ───────────────────────────────

export interface EcoModeState {
  /** Is eco mode currently engaged (game window focused) */
  isActive: boolean;
  /** Has the user enabled eco mode feature */
  isEnabled: boolean;
  /** CPU usage estimate percentage */
  cpuEstimate: number;
  /** Animations paused */
  animationsPaused: boolean;
}

// ─── Instant Scrim Link ────────────────────────────────

export interface ScrimRoom {
  /** Short unique room code (e.g. "xK3m9p") */
  code: string;
  /** Room name set by creator */
  name: string;
  /** Creator's user id */
  created_by: string;
  /** Optional password for protected rooms */
  password: string | null;
  /** Max participants (default 10) */
  max_participants: number;
  /** When the room was created (auto-expires after 4 hours) */
  created_at: number;
  /** Milliseconds until auto-expiry */
  ttl: number;
}

// ─── Voice Controls (shared UI contract) ───────────────

export interface VoiceControls {
  isMuted: boolean;
  isDeafened: boolean;
  isSpeaking?: boolean;
  connectionState: 'idle' | 'connecting' | 'connected' | 'error';
  toggleMute: () => void;
  toggleDeafen: () => void;
  leaveVoice: () => void;
}

// ─── Net-Guard Jitter Buffer ───────────────────────────

export interface NetGuardStats {
  /** Current jitter in ms */
  jitterMs: number;
  /** Packet loss percentage */
  packetLossPercent: number;
  /** Buffer size in ms (adaptive) */
  bufferSizeMs: number;
  /** Connection quality score 0-100 */
  qualityScore: number;
  /** Quality label */
  qualityLabel: 'Mükemmel' | 'İyi' | 'Orta' | 'Zayıf';
}

// ─── Slot Beacon & Duo-Link ────────────────────────────

export interface SlotBeacon {
  slotIndex: number;
  targetRole: string | null;
  beaconActive: boolean;
}

export interface DuoLinkState {
  partnerId: string | null;
  partnerName: string | null;
  isActive: boolean;
  isTransmitting: boolean;
}

// ─── Global Store ──────────────────────────────────────

export type MobileCockpitTab = 'chat' | 'voice' | 'mesh';

export interface AppState {
  // ── Current Selections ──
  activeServerId: string | null;
  activeChannelId: string | null;
  activeVoiceChannelId: string | null;

  // ── Data Caches ──
  servers: Server[];
  categories: ChannelCategory[];
  channels: Channel[];
  messages: Message[];
  voiceParticipants: VoicePresence[];
  onlineMembers: Profile[];
  friends: Friendship[];
  activeDMUserId: string | null;

  // ── Eco Mode ──
  ecoMode: EcoModeState;

  // ── Scrim & Lobby ──
  activeScrimRoom: ScrimRoom | null;
  showScrimModal: boolean;
  showLobbyGate: boolean;
  showChannelBuilderModal: boolean;
  showOnboardingModal: boolean;
  showTourModal: boolean;
  showStreamerOverlayModal: boolean;
  showSoundboardModal: boolean;
  showRadialCommandWheel: boolean;
  showVoiceClipBufferModal: boolean;
  showScrimScheduleModal: boolean;

  // ── Multi-Game Hub & Tag Filter ──
  selectedGameFilter: string; // 'all' | 'lol' | 'cs2' | 'valorant' | 'dota2' | 'chill'
  userPrimaryGame: string;
  userFavoriteGames: string[];
  userGameRoles: Record<string, string>;
  userCommunityTags: string[];

  // ── Meva Native Slot Beacons & Duo-Link ──
  slotBeacons: Record<number, SlotBeacon>;
  duoLink: DuoLinkState;
  activeSonarTargetId: string | null;

  // ── Net-Guard ──
  netGuard: NetGuardStats;

  // ── UI & Mobile Responsive State ──
  showUserSettings: boolean;
  showFriendsModal: boolean;
  collapsedCategories: Set<string>;
  isRadarOpen: boolean;
  isMobileSidebarOpen: boolean;
  isMobileRadarOpen: boolean;
  mobileTab: MobileCockpitTab;

  // ── Actions — Navigation ──
  setActiveServer: (id: string) => void;
  setActiveChannel: (id: string) => void;
  setActiveVoiceChannel: (id: string | null) => void;
  setActiveDMUser: (userId: string | null) => void;

  // ── Actions — Data ──
  setServers: (servers: Server[]) => void;
  removeServer: (serverId: string) => void;
  setCategories: (categories: ChannelCategory[]) => void;
  removeCategory: (categoryId: string) => void;
  setChannels: (channels: Channel[]) => void;
  addChannel: (channel: Channel) => void;
  removeChannel: (channelId: string) => void;
  addCategory: (category: ChannelCategory) => void;
  addMessage: (message: Message) => void;
  setMessages: (messages: Message[]) => void;
  setVoiceParticipants: (participants: VoicePresence[]) => void;
  setOnlineMembers: (members: Profile[]) => void;
  setFriends: (friends: Friendship[]) => void;
  addFriendRequest: (username: string) => void;
  acceptFriendRequest: (friendshipId: string) => void;
  removeFriend: (friendId: string) => void;

  // ── Actions — Eco Mode ──
  setEcoMode: (update: Partial<EcoModeState>) => void;
  toggleEcoEnabled: () => void;

  // ── Actions — Scrim & Lobby & Multi-Game ──
  setActiveScrimRoom: (room: ScrimRoom | null) => void;
  setShowScrimModal: (show: boolean) => void;
  setShowLobbyGate: (show: boolean) => void;
  setShowChannelBuilderModal: (show: boolean) => void;
  setShowOnboardingModal: (show: boolean) => void;
  setShowTourModal: (show: boolean) => void;
  setShowStreamerOverlayModal: (show: boolean) => void;
  setShowSoundboardModal: (show: boolean) => void;
  setShowRadialCommandWheel: (show: boolean) => void;
  setShowVoiceClipBufferModal: (show: boolean) => void;
  setShowScrimScheduleModal: (show: boolean) => void;
  setSelectedGameFilter: (filter: string) => void;
  setUserPrimaryGame: (gameId: string) => void;
  setUserFavoriteGames: (games: string[]) => void;
  setUserGameRole: (gameId: string, role: string) => void;
  setUserCommunityTags: (tags: string[]) => void;

  // ── Actions — Slot Beacons & Duo-Link ──
  setSlotBeacon: (slotIndex: number, targetRole: string | null) => void;
  clearSlotBeacon: (slotIndex: number) => void;
  setDuoLinkPartner: (partnerId: string | null, partnerName?: string | null) => void;
  setDuoLinkActive: (active: boolean) => void;
  triggerSonarPulse: (targetId: string, pan?: number) => void;

  // ── Actions — Net-Guard ──
  setNetGuard: (stats: Partial<NetGuardStats>) => void;

  // ── Actions — UI & Mobile ──
  toggleCategory: (categoryId: string) => void;
  setShowUserSettings: (show: boolean) => void;
  setShowFriendsModal: (show: boolean) => void;
  toggleRadar: () => void;
  setIsMobileSidebarOpen: (open: boolean) => void;
  setIsMobileRadarOpen: (open: boolean) => void;
  setMobileTab: (tab: MobileCockpitTab) => void;
}
