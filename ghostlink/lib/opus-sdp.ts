// ─────────────────────────────────────────────────────────
// Meva HUD — Opus 48kHz Tactical SDP & RTP Transport Optimizer
// ─────────────────────────────────────────────────────────
// Enforces fullband 48kHz Opus @ 96kbps, 10ms low-latency packet
// framing (ptime=10), In-Band Forward Error Correction (FEC), and
// Discontinuous Transmission (DTX) with zero external dependencies.

export const OPUS_TARGET_BITRATE = 96_000;
export const OPUS_SAMPLE_RATE = 48_000;

const OPUS_TACTICAL_PARAMS: Record<string, string> = {
  minptime: '10',
  useinbandfec: '1',
  usedtx: '1',
  maxaveragebitrate: String(OPUS_TARGET_BITRATE),
  maxplaybackrate: String(OPUS_SAMPLE_RATE),
  stereo: '0',
  'sprop-stereo': '0',
};

const SAFE_FMTP_KEY_RE = /^[a-z0-9-]+$/i;
const SAFE_FMTP_VAL_RE = /^[A-Za-z0-9._-]+$/;

/**
 * Rewrites SDP offer/answer to lock Opus 48kHz into ultra-low-latency
 * 10ms tactical framing with In-Band FEC & DTX enabled.
 * Sanitizes untrusted fmtp parameters to prevent SDP attribute/CRLF injection.
 */
export function tuneOpusSdp(sdp: string): string {
  if (!sdp) return sdp;

  const lines = sdp
    .replace(/[^\x20-\x7E\r\n]/g, '')
    .split(/\r?\n/);
  let opusPayloadType: string | null = null;

  for (const line of lines) {
    const match = /^a=rtpmap:(\d{1,3})\s+opus\/48000\/2/i.exec(line);
    if (match) {
      opusPayloadType = match[1];
      break;
    }
  }

  if (!opusPayloadType) return sdp;

  const fmtpPrefix = `a=fmtp:${opusPayloadType} `;
  let fmtpFound = false;
  let hasPtime = false;

  const updated = lines.map((line) => {
    if (/^a=ptime:/i.test(line)) {
      hasPtime = true;
      return 'a=ptime:10';
    }
    if (line.startsWith(fmtpPrefix)) {
      fmtpFound = true;
      const rawParams = line.slice(fmtpPrefix.length).split(';');
      const paramMap = new Map<string, string>();

      for (const pair of rawParams) {
        const eqIdx = pair.indexOf('=');
        if (eqIdx <= 0) continue;
        const k = pair.slice(0, eqIdx).trim().toLowerCase();
        const v = pair.slice(eqIdx + 1).trim();
        if (SAFE_FMTP_KEY_RE.test(k) && SAFE_FMTP_VAL_RE.test(v)) {
          paramMap.set(k, v);
        }
      }
      for (const [k, v] of Object.entries(OPUS_TACTICAL_PARAMS)) {
        paramMap.set(k, v);
      }

      const serialized = Array.from(paramMap.entries())
        .map(([k, v]) => `${k}=${v}`)
        .join(';');
      return `${fmtpPrefix}${serialized}`;
    }
    return line;
  });

  const finalLines: string[] = [];
  for (const line of updated) {
    finalLines.push(line);
    if (line.startsWith(`a=rtpmap:${opusPayloadType} `)) {
      if (!fmtpFound) {
        const serialized = Object.entries(OPUS_TACTICAL_PARAMS)
          .map(([k, v]) => `${k}=${v}`)
          .join(';');
        finalLines.push(`${fmtpPrefix}${serialized}`);
        fmtpFound = true;
      }
      if (!hasPtime) {
        finalLines.push('a=ptime:10');
        hasPtime = true;
      }
    }
  }

  return finalLines.join('\r\n');
}

/**
 * Configures outgoing audio RTCRtpSender for 96kbps Opus & high QoS priority.
 */
export async function configureOpusSender(pc: RTCPeerConnection): Promise<void> {
  for (const sender of pc.getSenders()) {
    if (sender.track?.kind !== 'audio') continue;
    try {
      const params = sender.getParameters();
      if (!params.encodings || params.encodings.length === 0) {
        params.encodings = [{}];
      }
      const enc = params.encodings[0] as RTCRtpEncodingParameters & {
        priority?: 'very-low' | 'low' | 'medium' | 'high';
        networkPriority?: 'very-low' | 'low' | 'medium' | 'high';
      };
      enc.maxBitrate = OPUS_TARGET_BITRATE;
      enc.priority = 'high';
      enc.networkPriority = 'high';
      await sender.setParameters(params);
    } catch {
      // Browser may not support DSCP priority hints; ignore safely
    }
  }
}

interface ExtendedRtpReceiver {
  jitterBufferTarget?: number | null;
  playoutDelayHint?: number;
}

/**
 * Applies adaptive jitter buffer target (in ms) on supported WebRTC receivers.
 */
export function applyAdaptiveReceiverBuffer(
  pc: RTCPeerConnection,
  targetMs: number,
): void {
  const clampedMs = Math.max(10, Math.min(150, targetMs));
  for (const receiver of pc.getReceivers()) {
    if (receiver.track?.kind !== 'audio') continue;
    const extReceiver = receiver as unknown as ExtendedRtpReceiver;
    try {
      if ('jitterBufferTarget' in receiver) {
        extReceiver.jitterBufferTarget = clampedMs;
      } else if ('playoutDelayHint' in receiver) {
        extReceiver.playoutDelayHint = clampedMs / 1000;
      }
    } catch {
      // Receiver hint unsupported on current user-agent
    }
  }
}
