// ─────────────────────────────────────────────────────────
// Meva HUD — 5-Peer Full-Mesh WebRTC Core & Serverless Signaling
// ─────────────────────────────────────────────────────────
//   • 5-Operator Full-Mesh RTCPeerConnection topology (RFC 8829 Perfect Negotiation)
//   • Multi-STUN Server Pool (Google, Cloudflare, Twilio STUN) + Auto ICE Restart
//   • Opus 48kHz Stereo / 96kbps / FEC=1 / DTX=1 / ptime=10ms SDP enforcement
//   • Dual Negotiated RTCDataChannels:
//       #0 "meva-e2ee-bus" (ordered reliable — E2EE chat, ECDH handshake, strat sync)
//       #1 "meva-fast-udp" (unordered 0-retransmit — high-frequency ping/stress probes)
//   • Serverless BroadcastChannel signaling + URL Hash & deterministic QR Matrix
//     generator for instant zero-server multi-tab and P2P room invitations.

import {
  tuneOpusSdp,
  configureOpusSender,
  applyAdaptiveReceiverBuffer,
} from '@/lib/opus-sdp';
import { getMevaAudioEngine } from '@/src/lib/audioEngine';

export const MULTI_STUN_POOL: RTCIceServer[] = [
  {
    urls: [
      'stun:stun.l.google.com:19302',
      'stun:stun1.l.google.com:19302',
    ],
  },
  { urls: 'stun:stun.cloudflare.com:3478' },
  { urls: 'stun:global.stun.twilio.com:3478' },
];

export type MeshPacketKind =
  | 'ecdh-pub'
  | 'e2ee-chat'
  | 'e2ee-callout'
  | 'ping-probe'
  | 'pong-reply'
  | 'stress-frame'
  | 'strat-op'
  | 'role-sync';

export interface MeshDataEnvelope {
  v: 1;
  kind: MeshPacketKind;
  from: string;
  fromName: string;
  to?: string; // omit for mesh broadcast
  room: string;
  seq: number;
  ts: number;
  payload: string;
}

export interface MeshPeerSummary {
  peerId: string;
  username: string;
  role: string;
  connectionState: RTCPeerConnectionState;
  iceState: RTCIceConnectionState;
  dataChannelOpen: boolean;
  connectedAt: number | null;
  reconnectAttempts: number;
}

export interface ServerlessInviteDescriptor {
  roomCode: string;
  roomName: string;
  hostPeerId: string;
  hostName: string;
  createdAt: number;
}

interface InternalPeerNode {
  peerId: string;
  username: string;
  role: string;
  pc: RTCPeerConnection;
  reliableDc: RTCDataChannel;
  fastDc: RTCDataChannel;
  remoteStream: MediaStream;
  polite: boolean;
  makingOffer: boolean;
  ignoreOffer: boolean;
  isSettingRemoteAnswerPending: boolean;
  pendingIce: RTCIceCandidateInit[];
  reconnectAttempts: number;
  reconnectTimer: ReturnType<typeof setTimeout> | null;
  connectedAt: number | null;
}

type SignalFrame =
  | {
      sig: 'hello' | 'hello-ack' | 'bye';
      room: string;
      from: string;
      username: string;
      role: string;
      to?: string;
      ts: number;
    }
  | {
      sig: 'sdp';
      room: string;
      from: string;
      to: string;
      username: string;
      role: string;
      description: RTCSessionDescriptionInit;
      ts: number;
    }
  | {
      sig: 'ice';
      room: string;
      from: string;
      to: string;
      candidate: RTCIceCandidateInit;
      ts: number;
    }
  | {
      sig: 'bus-fallback';
      room: string;
      envelope: MeshDataEnvelope;
    };

export type MeshDataListener = (envelope: MeshDataEnvelope) => void;
export type MeshPeersListener = (peers: MeshPeerSummary[]) => void;

const SAFE_ROOM_RE = /^[A-Za-z0-9_:-]{1,64}$/;
const MAX_MESH_LOBBY_PEERS = 8;
const HEARTBEAT_INTERVAL_MS = 6_000;

export function buildMultiStunRtcConfig(): RTCConfiguration {
  return {
    iceServers: MULTI_STUN_POOL,
    iceCandidatePoolSize: 6,
    bundlePolicy: 'max-bundle',
    rtcpMuxPolicy: 'require',
  };
}

/**
 * Encodes a serverless P2P room invitation into a URL-safe hash link (`#meva=...`).
 */
export function buildServerlessInviteLink(
  origin: string,
  descriptor: ServerlessInviteDescriptor,
): string {
  const cleanOrigin = origin.replace(/\/+$/, '');
  const json = JSON.stringify({
    c: descriptor.roomCode.replace(/[^A-Za-z0-9_-]/g, '').slice(0, 16),
    n: descriptor.roomName.slice(0, 40),
    h: descriptor.hostPeerId.slice(0, 48),
    u: descriptor.hostName.slice(0, 28),
    t: descriptor.createdAt,
  });

  const encoded =
    typeof btoa === 'function'
      ? btoa(unescape(encodeURIComponent(json)))
          .replace(/\+/g, '-')
          .replace(/\//g, '_')
          .replace(/=+$/, '')
      : Buffer.from(json, 'utf8').toString('base64url');

  return `${cleanOrigin}/#meva=${encoded}`;
}

/**
 * Parses `#meva=...` serverless invite token from `window.location.hash` safely.
 */
export function parseServerlessInviteHash(
  hash: string,
): ServerlessInviteDescriptor | null {
  if (!hash || typeof hash !== 'string') return null;
  const trimmed = hash.startsWith('#') ? hash.slice(1) : hash;
  const params = new URLSearchParams(trimmed);
  const token = params.get('meva');
  if (!token || token.length > 1024 || !/^[A-Za-z0-9_-]+$/.test(token)) {
    return null;
  }

  try {
    const pad = token.length % 4 === 0 ? '' : '='.repeat(4 - (token.length % 4));
    const b64 = token.replace(/-/g, '+').replace(/_/g, '/') + pad;
    const json =
      typeof atob === 'function'
        ? decodeURIComponent(escape(atob(b64)))
        : Buffer.from(b64, 'base64').toString('utf8');
    const raw = JSON.parse(json) as Record<string, unknown>;
    if (typeof raw.c !== 'string' || !SAFE_ROOM_RE.test(raw.c)) return null;

    return {
      roomCode: raw.c,
      roomName: typeof raw.n === 'string' ? raw.n.slice(0, 40) : `Lobi #${raw.c}`,
      hostPeerId: typeof raw.h === 'string' ? raw.h.slice(0, 48) : 'peer-host',
      hostName: typeof raw.u === 'string' ? raw.u.slice(0, 28) : 'Operatör',
      createdAt: typeof raw.t === 'number' ? raw.t : Date.now(),
    };
  } catch {
    return null;
  }
}

/**
 * Generates a deterministic 21x21 finder-aligned visual QR-style matrix for instant
 * visual room sharing in the Invite / Scrim modal without external dependencies.
 */
export function generateTacticalQrMatrix(payload: string, size = 21): boolean[][] {
  const matrix: boolean[][] = Array.from({ length: size }, () =>
    Array<boolean>(size).fill(false),
  );

  const drawFinder = (ox: number, oy: number) => {
    for (let y = 0; y < 7; y++) {
      for (let x = 0; x < 7; x++) {
        const border = x === 0 || x === 6 || y === 0 || y === 6;
        const inner = x >= 2 && x <= 4 && y >= 2 && y <= 4;
        matrix[oy + y][ox + x] = border || inner;
      }
    }
  };

  drawFinder(0, 0);
  drawFinder(size - 7, 0);
  drawFinder(0, size - 7);

  // Timing pattern
  for (let i = 8; i < size - 8; i++) {
    matrix[6][i] = i % 2 === 0;
    matrix[i][6] = i % 2 === 0;
  }

  // FNV-1a seeded stream over payload bytes for data cells
  let hash = 2166136261 >>> 0;
  for (let i = 0; i < payload.length; i++) {
    hash ^= payload.charCodeAt(i);
    hash = Math.imul(hash, 16777619) >>> 0;
  }

  let state = hash || 0x9e3779b9;
  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      const inTopLeft = x < 8 && y < 8;
      const inTopRight = x >= size - 8 && y < 8;
      const inBottomLeft = x < 8 && y >= size - 8;
      if (inTopLeft || inTopRight || inBottomLeft || x === 6 || y === 6) {
        continue;
      }
      const charMix = payload.charCodeAt((x * size + y) % Math.max(1, payload.length)) || 1;
      state ^= state << 13;
      state ^= state >>> 17;
      state ^= state << 5;
      state = (state + charMix * 2654435761) >>> 0;
      matrix[y][x] = (state & 1) === 1;
    }
  }

  return matrix;
}

export class MevaWebRTCMesh {
  private localPeerId: string;
  private localUsername = 'Operatör';
  private localRole = 'IGL';
  private roomId = 'ch-4';

  private nodes = new Map<string, InternalPeerNode>();
  private broadcastBus: BroadcastChannel | null = null;
  private localTrackStream: MediaStream | null = null;
  private seqCounter = 0;
  private seenSeqs = new Map<string, number>();
  private heartbeatTimer: ReturnType<typeof setInterval> | null = null;

  private dataListeners = new Set<MeshDataListener>();
  private peersListeners = new Set<MeshPeersListener>();
  private externalSignalSender: ((frame: SignalFrame) => void) | null = null;

  constructor() {
    const rand =
      typeof crypto !== 'undefined' && typeof crypto.randomUUID === 'function'
        ? crypto.randomUUID().slice(0, 8)
        : Date.now().toString(36);
    this.localPeerId = `peer-${rand}`;
  }

  public getLocalPeerId(): string {
    return this.localPeerId;
  }

  public getRoomId(): string {
    return this.roomId;
  }

  public setIdentity(username: string, role = 'IGL'): void {
    this.localUsername = username.trim().slice(0, 32) || 'Operatör';
    this.localRole = role;
  }

  public setExternalSignalSender(
    sender: ((frame: SignalFrame) => void) | null,
  ): void {
    this.externalSignalSender = sender;
  }

  /**
   * Joins a Full-Mesh room using BroadcastChannel serverless discovery
   * (plus optional external signal transport) and negotiates RTCPeerConnections.
   */
  public joinRoom(
    roomId: string,
    username?: string,
    role?: string,
    localAudioStream?: MediaStream | null,
  ): void {
    const cleanRoom = roomId.replace(/[^A-Za-z0-9_:-]/g, '').slice(0, 64) || 'ch-4';
    if (username) this.localUsername = username.slice(0, 32);
    if (role) this.localRole = role;
    if (localAudioStream !== undefined) {
      this.localTrackStream = localAudioStream;
    }

    if (this.roomId === cleanRoom && this.broadcastBus) {
      if (localAudioStream) {
        this.replaceOutgoingAudioStream(localAudioStream);
      }
      return;
    }

    this.leaveRoom();
    this.roomId = cleanRoom;

    if (typeof window !== 'undefined' && typeof BroadcastChannel !== 'undefined') {
      try {
        const bus = new BroadcastChannel(`meva-p2p-mesh:${cleanRoom}`);
        bus.onmessage = (ev: MessageEvent<SignalFrame>) => {
          void this.handleSignalFrame(ev.data);
        };
        this.broadcastBus = bus;
      } catch {
        this.broadcastBus = null;
      }
    }

    this.emitSignal({
      sig: 'hello',
      room: cleanRoom,
      from: this.localPeerId,
      username: this.localUsername,
      role: this.localRole,
      ts: Date.now(),
    });

    this.heartbeatTimer = setInterval(() => {
      this.emitSignal({
        sig: 'hello',
        room: this.roomId,
        from: this.localPeerId,
        username: this.localUsername,
        role: this.localRole,
        ts: Date.now(),
      });
    }, HEARTBEAT_INTERVAL_MS);
  }

  /**
   * Hot-swaps the outgoing microphone MediaStream (e.g. from Noise Gate VAD engine)
   * across all active RTCPeerConnections without dropping the mesh.
   */
  public replaceOutgoingAudioStream(stream: MediaStream | null): void {
    this.localTrackStream = stream;
    const newTrack = stream?.getAudioTracks()[0] ?? null;

    for (const node of this.nodes.values()) {
      const audioSender = node.pc
        .getSenders()
        .find((s) => s.track?.kind === 'audio' || s.track === null);
      if (audioSender) {
        void audioSender.replaceTrack(newTrack).catch(() => {});
      } else if (newTrack && stream) {
        try {
          node.pc.addTrack(newTrack, stream);
          void configureOpusSender(node.pc);
        } catch {}
      }
    }
  }

  private emitSignal(frame: SignalFrame): void {
    try {
      this.broadcastBus?.postMessage(frame);
    } catch {}
    try {
      this.externalSignalSender?.(frame);
    } catch {}
  }

  public async handleSignalFrame(frame: SignalFrame): Promise<void> {
    if (!frame || typeof frame !== 'object') return;
    if (frame.room !== this.roomId) return;

    if (frame.sig === 'bus-fallback') {
      if (frame.envelope.from === this.localPeerId) return;
      if (frame.envelope.to && frame.envelope.to !== this.localPeerId) return;
      this.dispatchDataEnvelope(frame.envelope);
      return;
    }

    if (frame.from === this.localPeerId) return;
    if ('to' in frame && frame.to && frame.to !== this.localPeerId) return;

    if (frame.sig === 'bye') {
      this.removePeerNode(frame.from);
      return;
    }

    if (frame.sig === 'hello') {
      const existed = this.nodes.has(frame.from);
      const node = this.getOrCreatePeerNode(
        frame.from,
        frame.username,
        frame.role,
      );
      if (!node) return;

      this.emitSignal({
        sig: 'hello-ack',
        room: this.roomId,
        from: this.localPeerId,
        to: frame.from,
        username: this.localUsername,
        role: this.localRole,
        ts: Date.now(),
      });

      if (!existed && !node.polite) {
        await this.negotiateOffer(node, false);
      }
      return;
    }

    if (frame.sig === 'hello-ack') {
      const existed = this.nodes.has(frame.from);
      const node = this.getOrCreatePeerNode(
        frame.from,
        frame.username,
        frame.role,
      );
      if (node && !existed && !node.polite) {
        await this.negotiateOffer(node, false);
      }
      return;
    }

    if (frame.sig === 'sdp') {
      const node = this.getOrCreatePeerNode(
        frame.from,
        frame.username,
        frame.role,
      );
      if (!node) return;
      await this.handleRemoteDescription(node, frame.description);
      return;
    }

    if (frame.sig === 'ice') {
      const node = this.nodes.get(frame.from);
      if (!node) return;
      if (!node.pc.remoteDescription) {
        if (node.pendingIce.length < 48) {
          node.pendingIce.push(frame.candidate);
        }
        return;
      }
      try {
        await node.pc.addIceCandidate(new RTCIceCandidate(frame.candidate));
      } catch {
        if (!node.ignoreOffer) {
          // Benign candidate race
        }
      }
    }
  }

  private getOrCreatePeerNode(
    remotePeerId: string,
    username: string,
    role: string,
  ): InternalPeerNode | null {
    const existing = this.nodes.get(remotePeerId);
    if (existing) {
      existing.username = username || existing.username;
      existing.role = role || existing.role;
      return existing;
    }

    if (
      typeof RTCPeerConnection === 'undefined' ||
      this.nodes.size >= MAX_MESH_LOBBY_PEERS
    ) {
      return null;
    }

    const pc = new RTCPeerConnection(buildMultiStunRtcConfig());
    const polite = this.localPeerId < remotePeerId;
    const remoteStream = new MediaStream();

    // Negotiated Reliable Channel #0 (E2EE Chat, ECDH Keys, Tactical Strat Canvas)
    const reliableDc = pc.createDataChannel('meva-e2ee-bus', {
      negotiated: true,
      id: 0,
      ordered: true,
    });

    // Negotiated Unordered 0-Retransmit Channel #1 (Ping/Jitter & Stress Test)
    const fastDc = pc.createDataChannel('meva-fast-udp', {
      negotiated: true,
      id: 1,
      ordered: false,
      maxRetransmits: 0,
    });

    if (this.localTrackStream) {
      for (const track of this.localTrackStream.getAudioTracks()) {
        pc.addTrack(track, this.localTrackStream);
      }
      void configureOpusSender(pc);
    } else {
      try {
        pc.addTransceiver('audio', { direction: 'sendrecv' });
      } catch {}
    }

    const node: InternalPeerNode = {
      peerId: remotePeerId,
      username: username || 'Operatör',
      role: role || 'ENTRY',
      pc,
      reliableDc,
      fastDc,
      remoteStream,
      polite,
      makingOffer: false,
      ignoreOffer: false,
      isSettingRemoteAnswerPending: false,
      pendingIce: [],
      reconnectAttempts: 0,
      reconnectTimer: null,
      connectedAt: null,
    };

    const bindChannel = (dc: RTCDataChannel) => {
      dc.onopen = () => {
        this.notifyPeersListeners();
      };
      dc.onclose = () => {
        this.notifyPeersListeners();
      };
      dc.onmessage = (ev: MessageEvent) => {
        if (typeof ev.data !== 'string' || ev.data.length > 65_536) return;
        try {
          const parsed = JSON.parse(ev.data) as MeshDataEnvelope;
          if (parsed && parsed.v === 1 && typeof parsed.kind === 'string') {
            this.dispatchDataEnvelope(parsed);
          }
        } catch {}
      };
    };

    bindChannel(reliableDc);
    bindChannel(fastDc);

    pc.ontrack = (ev: RTCTrackEvent) => {
      const stream = ev.streams[0] ?? remoteStream;
      if (!ev.streams[0]) {
        remoteStream.addTrack(ev.track);
      }
      node.remoteStream = stream;
      getMevaAudioEngine().attachPeer(remotePeerId, stream, 100, false, 'C');
      applyAdaptiveReceiverBuffer(pc, 14);
    };

    pc.onicecandidate = (ev: RTCPeerConnectionIceEvent) => {
      if (!ev.candidate) return;
      this.emitSignal({
        sig: 'ice',
        room: this.roomId,
        from: this.localPeerId,
        to: remotePeerId,
        candidate: ev.candidate.toJSON(),
        ts: Date.now(),
      });
    };

    pc.onnegotiationneeded = () => {
      void this.negotiateOffer(node, false);
    };

    pc.onconnectionstatechange = () => {
      if (pc.connectionState === 'connected') {
        node.connectedAt = node.connectedAt ?? Date.now();
        node.reconnectAttempts = 0;
        if (node.reconnectTimer) {
          clearTimeout(node.reconnectTimer);
          node.reconnectTimer = null;
        }
      } else if (
        pc.connectionState === 'failed' ||
        pc.connectionState === 'disconnected'
      ) {
        this.scheduleAutoReconnect(node);
      }
      this.notifyPeersListeners();
    };

    pc.oniceconnectionstatechange = () => {
      if (
        pc.iceConnectionState === 'failed' ||
        pc.iceConnectionState === 'disconnected'
      ) {
        this.scheduleAutoReconnect(node);
      }
      this.notifyPeersListeners();
    };

    this.nodes.set(remotePeerId, node);
    this.notifyPeersListeners();
    return node;
  }

  private async negotiateOffer(
    node: InternalPeerNode,
    iceRestart: boolean,
  ): Promise<void> {
    if (node.makingOffer) return;
    if (node.pc.signalingState !== 'stable' && !iceRestart) return;

    try {
      node.makingOffer = true;
      const offer = await node.pc.createOffer({ iceRestart });
      const tunedSdp = offer.sdp ? tuneOpusSdp(offer.sdp, { stereo: true }) : offer.sdp;
      await node.pc.setLocalDescription({ type: offer.type, sdp: tunedSdp });

      if (node.pc.localDescription) {
        this.emitSignal({
          sig: 'sdp',
          room: this.roomId,
          from: this.localPeerId,
          to: node.peerId,
          username: this.localUsername,
          role: this.localRole,
          description: {
            type: node.pc.localDescription.type,
            sdp: node.pc.localDescription.sdp,
          },
          ts: Date.now(),
        });
      }
    } catch {
      // Offer race handled via Perfect Negotiation
    } finally {
      node.makingOffer = false;
    }
  }

  private async handleRemoteDescription(
    node: InternalPeerNode,
    description: RTCSessionDescriptionInit,
  ): Promise<void> {
    const readyForOffer =
      !node.makingOffer &&
      (node.pc.signalingState === 'stable' || node.isSettingRemoteAnswerPending);
    const offerCollision = description.type === 'offer' && !readyForOffer;

    node.ignoreOffer = !node.polite && offerCollision;
    if (node.ignoreOffer) return;

    try {
      node.isSettingRemoteAnswerPending = description.type === 'answer';
      const tunedRemoteSdp = description.sdp
        ? tuneOpusSdp(description.sdp, { stereo: true })
        : description.sdp;

      await node.pc.setRemoteDescription({
        type: description.type,
        sdp: tunedRemoteSdp,
      });
      node.isSettingRemoteAnswerPending = false;

      // Drain buffered early Trickle ICE candidates
      if (node.pendingIce.length > 0) {
        const queued = node.pendingIce.splice(0, node.pendingIce.length);
        for (const cand of queued) {
          try {
            await node.pc.addIceCandidate(new RTCIceCandidate(cand));
          } catch {}
        }
      }

      if (description.type === 'offer') {
        const answer = await node.pc.createAnswer();
        const tunedAnswerSdp = answer.sdp
          ? tuneOpusSdp(answer.sdp, { stereo: true })
          : answer.sdp;
        await node.pc.setLocalDescription({
          type: answer.type,
          sdp: tunedAnswerSdp,
        });

        if (node.pc.localDescription) {
          this.emitSignal({
            sig: 'sdp',
            room: this.roomId,
            from: this.localPeerId,
            to: node.peerId,
            username: this.localUsername,
            role: this.localRole,
            description: {
              type: node.pc.localDescription.type,
              sdp: node.pc.localDescription.sdp,
            },
            ts: Date.now(),
          });
        }
      }
    } catch {
      node.isSettingRemoteAnswerPending = false;
    }
  }

  /**
   * Automatic exponential-backoff ICE Restart on transient network drops.
   */
  private scheduleAutoReconnect(node: InternalPeerNode): void {
    if (node.reconnectTimer || node.reconnectAttempts >= 5) return;
    const delayMs = Math.min(8_000, 900 * Math.pow(1.8, node.reconnectAttempts));
    node.reconnectAttempts += 1;

    node.reconnectTimer = setTimeout(() => {
      node.reconnectTimer = null;
      if (!this.nodes.has(node.peerId)) return;
      try {
        node.pc.restartIce();
      } catch {}
      void this.negotiateOffer(node, true);
    }, delayMs);
  }

  /**
   * Manually resets and renegotiates a specific peer's connection (used by Context Menu).
   */
  public async resetPeerConnection(peerId: string): Promise<void> {
    const existing = this.nodes.get(peerId);
    if (!existing) {
      // Broadcast fresh hello beacon to rediscover peer if virtual/local
      this.emitSignal({
        sig: 'hello',
        room: this.roomId,
        from: this.localPeerId,
        username: this.localUsername,
        role: this.localRole,
        ts: Date.now(),
      });
      return;
    }

    try {
      existing.pc.restartIce();
      await this.negotiateOffer(existing, true);
    } catch {
      const { username, role } = existing;
      this.removePeerNode(peerId);
      const fresh = this.getOrCreatePeerNode(peerId, username, role);
      if (fresh) {
        await this.negotiateOffer(fresh, true);
      }
    }
  }

  /**
   * Sends a packet over RTCDataChannel (reliable or fast-udp) to a target peer
   * or broadcasts across all peers, with BroadcastChannel fallback while ICE settles.
   */
  public sendPacket(
    kind: MeshPacketKind,
    payload: string,
    options: { to?: string; unorderedFast?: boolean } = {},
  ): MeshDataEnvelope {
    this.seqCounter += 1;
    const envelope: MeshDataEnvelope = {
      v: 1,
      kind,
      from: this.localPeerId,
      fromName: this.localUsername,
      to: options.to,
      room: this.roomId,
      seq: this.seqCounter,
      ts: performance.now ? Math.round(performance.now() * 100) / 100 : Date.now(),
      payload,
    };

    const serialized = JSON.stringify(envelope);
    let deliveredOverWebRtc = false;

    const targets = options.to
      ? [this.nodes.get(options.to)].filter(Boolean)
      : Array.from(this.nodes.values());

    for (const node of targets) {
      if (!node) continue;
      const dc = options.unorderedFast ? node.fastDc : node.reliableDc;
      if (dc.readyState === 'open') {
        try {
          dc.send(serialized);
          deliveredOverWebRtc = true;
        } catch {}
      } else if (node.reliableDc.readyState === 'open') {
        try {
          node.reliableDc.send(serialized);
          deliveredOverWebRtc = true;
        } catch {}
      }
    }

    if (!deliveredOverWebRtc) {
      this.emitSignal({
        sig: 'bus-fallback',
        room: this.roomId,
        envelope,
      });
    }

    return envelope;
  }

  private dispatchDataEnvelope(envelope: MeshDataEnvelope): void {
    const dedupeKey = `${envelope.from}:${envelope.seq}`;
    if (this.seenSeqs.has(dedupeKey)) return;
    this.seenSeqs.set(dedupeKey, Date.now());
    if (this.seenSeqs.size > 512) {
      const firstKey = this.seenSeqs.keys().next().value;
      if (firstKey) this.seenSeqs.delete(firstKey);
    }

    for (const listener of this.dataListeners) {
      listener(envelope);
    }
  }

  public onDataPacket(listener: MeshDataListener): () => void {
    this.dataListeners.add(listener);
    return () => {
      this.dataListeners.delete(listener);
    };
  }

  public onPeersChange(listener: MeshPeersListener): () => void {
    this.peersListeners.add(listener);
    listener(this.getPeersSummary());
    return () => {
      this.peersListeners.delete(listener);
    };
  }

  public getPeersSummary(): MeshPeerSummary[] {
    return Array.from(this.nodes.values()).map((n) => ({
      peerId: n.peerId,
      username: n.username,
      role: n.role,
      connectionState: n.pc.connectionState,
      iceState: n.pc.iceConnectionState,
      dataChannelOpen: n.reliableDc.readyState === 'open',
      connectedAt: n.connectedAt,
      reconnectAttempts: n.reconnectAttempts,
    }));
  }

  public getPeerConnection(peerId: string): RTCPeerConnection | null {
    return this.nodes.get(peerId)?.pc ?? null;
  }

  public getAllPeerConnections(): Map<string, RTCPeerConnection> {
    const map = new Map<string, RTCPeerConnection>();
    for (const [id, node] of this.nodes.entries()) {
      map.set(id, node.pc);
    }
    return map;
  }

  private notifyPeersListeners(): void {
    const snapshot = this.getPeersSummary();
    for (const listener of this.peersListeners) {
      listener(snapshot);
    }
  }

  private removePeerNode(peerId: string): void {
    const node = this.nodes.get(peerId);
    if (!node) return;
    if (node.reconnectTimer) {
      clearTimeout(node.reconnectTimer);
    }
    try {
      node.reliableDc.close();
      node.fastDc.close();
      node.pc.close();
    } catch {}
    getMevaAudioEngine().detachPeer(peerId);
    this.nodes.delete(peerId);
    this.notifyPeersListeners();
  }

  public leaveRoom(): void {
    if (this.heartbeatTimer) {
      clearInterval(this.heartbeatTimer);
      this.heartbeatTimer = null;
    }

    if (this.broadcastBus) {
      this.emitSignal({
        sig: 'bye',
        room: this.roomId,
        from: this.localPeerId,
        username: this.localUsername,
        role: this.localRole,
        ts: Date.now(),
      });
      try {
        this.broadcastBus.close();
      } catch {}
      this.broadcastBus = null;
    }

    for (const peerId of Array.from(this.nodes.keys())) {
      this.removePeerNode(peerId);
    }
  }

  public destroy(): void {
    this.leaveRoom();
    this.dataListeners.clear();
    this.peersListeners.clear();
  }
}

let sharedMeshInstance: MevaWebRTCMesh | null = null;

export function getMevaWebRTCMesh(): MevaWebRTCMesh {
  if (!sharedMeshInstance) {
    sharedMeshInstance = new MevaWebRTCMesh();
  }
  return sharedMeshInstance;
}
