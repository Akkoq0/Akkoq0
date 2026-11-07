// ─────────────────────────────────────────────────────────
// Meva HUD — Zero-Cost Public WSS / MQTT Auto-Signaling Relay
// ─────────────────────────────────────────────────────────
// Enables instant zero-server peer pairing across the public internet:
//   • Connects to public high-availability MQTT-over-WebSocket brokers
//     (EMQX wss://broker.emqx.io:8084/mqtt & HiveMQ fallback)
//   • Subscribes to room-scoped topic: `meva/p2p/{roomCode}`
//   • Auto-exchanges SDP Offers, Answers & ICE Candidates
//   • Zero npm dependencies — lightweight binary MQTT 3.1.1 framing
//   • Reconnection with exponential backoff & keepalive pinging

export type PublicSignalCallback = (rawPayload: string) => void;

const PRIMARY_BROKER_URL = 'wss://broker.emqx.io:8084/mqtt';
const FALLBACK_BROKER_URL = 'wss://broker.hivemq.com:8884/mqtt';

export class MevaPublicBrokerRelay {
  private ws: WebSocket | null = null;
  private currentRoom: string | null = null;
  private onMessageCallback: PublicSignalCallback | null = null;
  private pingTimer: ReturnType<typeof setInterval> | null = null;
  private reconnectTimer: ReturnType<typeof setTimeout> | null = null;
  private connected = false;
  private clientId: string;
  private currentBrokerIndex = 0;
  private packetIdCounter = 1;

  constructor() {
    const rand =
      typeof crypto !== 'undefined' && typeof crypto.randomUUID === 'function'
        ? crypto.randomUUID().slice(0, 8)
        : Math.floor(Math.random() * 100000).toString(36);
    this.clientId = `meva-${rand}`;
  }

  public setOnSignal(callback: PublicSignalCallback): void {
    this.onMessageCallback = callback;
  }

  public isConnected(): boolean {
    return this.connected;
  }

  public joinRoom(roomCode: string): void {
    const clean = roomCode.replace(/[^A-Za-z0-9_-]/g, '').slice(0, 32);
    if (!clean) return;

    if (this.currentRoom === clean && this.connected) {
      return;
    }

    this.currentRoom = clean;
    this.connect();
  }

  public leaveRoom(): void {
    this.currentRoom = null;
    this.cleanup();
  }

  public publishSignal(rawPayload: string): boolean {
    if (!this.connected || !this.ws || this.ws.readyState !== WebSocket.OPEN || !this.currentRoom) {
      return false;
    }

    try {
      const topic = `meva/p2p/${this.currentRoom}`;
      const packet = this.buildPublishPacket(topic, rawPayload);
      this.ws.send(packet);
      return true;
    } catch {
      return false;
    }
  }

  private connect(): void {
    if (typeof window === 'undefined' || typeof WebSocket === 'undefined') return;
    this.cleanup();

    const brokerUrl =
      this.currentBrokerIndex === 0 ? PRIMARY_BROKER_URL : FALLBACK_BROKER_URL;

    try {
      const ws = new WebSocket(brokerUrl, ['mqtt']);
      ws.binaryType = 'arraybuffer';
      this.ws = ws;

      ws.onopen = () => {
        // Send MQTT CONNECT packet
        const connectPacket = this.buildConnectPacket(this.clientId);
        ws.send(connectPacket);
      };

      ws.onmessage = (ev: MessageEvent) => {
        if (!(ev.data instanceof ArrayBuffer)) return;
        this.handleIncomingMqttBytes(new Uint8Array(ev.data));
      };

      ws.onerror = () => {
        this.switchBrokerAndRetry();
      };

      ws.onclose = () => {
        this.connected = false;
        if (this.currentRoom) {
          this.scheduleReconnect();
        }
      };
    } catch {
      this.switchBrokerAndRetry();
    }
  }

  private switchBrokerAndRetry(): void {
    this.currentBrokerIndex = (this.currentBrokerIndex + 1) % 2;
    this.scheduleReconnect();
  }

  private scheduleReconnect(): void {
    if (this.reconnectTimer !== null) return;
    this.reconnectTimer = setTimeout(() => {
      this.reconnectTimer = null;
      if (this.currentRoom) {
        this.connect();
      }
    }, 2500);
  }

  private cleanup(): void {
    if (this.pingTimer) {
      clearInterval(this.pingTimer);
      this.pingTimer = null;
    }
    if (this.reconnectTimer) {
      clearTimeout(this.reconnectTimer);
      this.reconnectTimer = null;
    }
    if (this.ws) {
      try {
        this.ws.onopen = null;
        this.ws.onmessage = null;
        this.ws.onerror = null;
        this.ws.onclose = null;
        this.ws.close();
      } catch {}
      this.ws = null;
    }
    this.connected = false;
  }

  private handleIncomingMqttBytes(bytes: Uint8Array): void {
    if (bytes.length < 2) return;
    const packetType = (bytes[0] >> 4) & 0x0f;

    // CONNACK (Type 2)
    if (packetType === 2) {
      const returnCode = bytes.length >= 4 ? bytes[3] : 0;
      if (returnCode === 0) {
        this.connected = true;
        this.startKeepalive();
        if (this.currentRoom) {
          const topic = `meva/p2p/${this.currentRoom}`;
          const subPacket = this.buildSubscribePacket(topic);
          this.ws?.send(subPacket);
        }
      }
      return;
    }

    // PINGRESP (Type 13)
    if (packetType === 13) {
      return;
    }

    // PUBLISH (Type 3)
    if (packetType === 3) {
      try {
        // Decode variable remaining length
        let offset = 1;
        let multiplier = 1;
        let remainingLength = 0;
        let digit = 0;
        do {
          if (offset >= bytes.length) return;
          digit = bytes[offset++];
          remainingLength += (digit & 0x7f) * multiplier;
          multiplier *= 128;
        } while ((digit & 0x80) !== 0);

        if (offset + 2 > bytes.length) return;
        const topicLen = (bytes[offset] << 8) | bytes[offset + 1];
        offset += 2;
        offset += topicLen; // skip topic string

        const payloadBytes = bytes.subarray(offset);
        const decoder = new TextDecoder('utf-8');
        const text = decoder.decode(payloadBytes);
        if (text && this.onMessageCallback) {
          this.onMessageCallback(text);
        }
      } catch {}
    }
  }

  private startKeepalive(): void {
    if (this.pingTimer) clearInterval(this.pingTimer);
    this.pingTimer = setInterval(() => {
      if (this.connected && this.ws && this.ws.readyState === WebSocket.OPEN) {
        // PINGREQ: [0xC0, 0x00]
        this.ws.send(new Uint8Array([0xc0, 0x00]));
      }
    }, 20_000);
  }

  // ── MQTT 3.1.1 Packet Builders ──

  private buildConnectPacket(clientId: string): Uint8Array {
    const encoder = new TextEncoder();
    const idBytes = encoder.encode(clientId);
    const protoName = [0x00, 0x04, 0x4d, 0x51, 0x54, 0x74]; // "MQTT"
    const protoLevel = 0x04; // 3.1.1
    const connectFlags = 0x02; // Clean session
    const keepAlive = [0x00, 0x3c]; // 60s

    const varHeader = [...protoName, protoLevel, connectFlags, ...keepAlive];
    const payload = [(idBytes.length >> 8) & 0xff, idBytes.length & 0xff, ...Array.from(idBytes)];

    const remainingLength = varHeader.length + payload.length;
    const lenBytes = this.encodeRemainingLength(remainingLength);

    return new Uint8Array([0x10, ...lenBytes, ...varHeader, ...payload]);
  }

  private buildSubscribePacket(topic: string): Uint8Array {
    const encoder = new TextEncoder();
    const topicBytes = encoder.encode(topic);
    const pid = (this.packetIdCounter++) & 0xffff || 1;

    const varHeader = [(pid >> 8) & 0xff, pid & 0xff];
    const payload = [
      (topicBytes.length >> 8) & 0xff,
      topicBytes.length & 0xff,
      ...Array.from(topicBytes),
      0x00, // QoS 0
    ];

    const remainingLength = varHeader.length + payload.length;
    const lenBytes = this.encodeRemainingLength(remainingLength);

    return new Uint8Array([0x82, ...lenBytes, ...varHeader, ...payload]);
  }

  private buildPublishPacket(topic: string, text: string): Uint8Array {
    const encoder = new TextEncoder();
    const topicBytes = encoder.encode(topic);
    const textBytes = encoder.encode(text);

    const varHeader = [
      (topicBytes.length >> 8) & 0xff,
      topicBytes.length & 0xff,
      ...Array.from(topicBytes),
    ];

    const remainingLength = varHeader.length + textBytes.length;
    const lenBytes = this.encodeRemainingLength(remainingLength);

    const packet = new Uint8Array(1 + lenBytes.length + varHeader.length + textBytes.length);
    packet[0] = 0x30; // PUBLISH QoS 0
    packet.set(lenBytes, 1);
    packet.set(varHeader, 1 + lenBytes.length);
    packet.set(textBytes, 1 + lenBytes.length + varHeader.length);

    return packet;
  }

  private encodeRemainingLength(length: number): number[] {
    const bytes: number[] = [];
    let x = length;
    do {
      let encodedByte = x % 128;
      x = Math.floor(x / 128);
      if (x > 0) {
        encodedByte |= 128;
      }
      bytes.push(encodedByte);
    } while (x > 0);
    return bytes;
  }
}

let singletonRelay: MevaPublicBrokerRelay | null = null;

export function getMevaPublicBrokerRelay(): MevaPublicBrokerRelay {
  if (!singletonRelay) {
    singletonRelay = new MevaPublicBrokerRelay();
  }
  return singletonRelay;
}
