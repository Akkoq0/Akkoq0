// ─────────────────────────────────────────────────────────
// Meva HUD — Opus 48kHz Stereo Low-Latency SDP Optimizer
// ─────────────────────────────────────────────────────────
// Enforces fullband 48kHz Stereo Opus @ 96kbps, 10ms ultra-low-latency
// framing (ptime=10, minptime=10), In-Band Forward Error Correction (FEC),
// and Discontinuous Transmission (DTX) with SDP injection hardening.

export const OPUS_TARGET_BITRATE = 96_000;
export const OPUS_SAMPLE_RATE = 48_000;

export interface TuneOpusOptions {
  stereo?: boolean;
  bitrate?: number;
  ptimeMs?: 10 | 20;
}

const SAFE_FMTP_KEY_RE = /^[a-z0-9-]+$/i;
const SAFE_FMTP_VAL_RE = /^[A-Za-z0-9._-]+$/;

/**
 * Rewrites SDP offer/answer to lock Opus 48kHz Stereo @ 96kbps with
 * FEC=1, DTX=1, and 10ms framing (ptime=10), promoting Opus to first
 * codec priority on the m=audio media line.
 */
export function tuneOpusSdp(sdp: string, options: TuneOpusOptions = {}): string {
  if (!sdp) return sdp;

  const stereoFlag = options.stereo === false ? '0' : '1';
  const bitrate = Math.max(
    24_000,
    Math.min(256_000, options.bitrate ?? OPUS_TARGET_BITRATE),
  );
  const ptime = options.ptimeMs ?? 10;

  const tacticalParams: Record<string, string> = {
    minptime: String(ptime),
    useinbandfec: '1',
    usedtx: '1',
    stereo: stereoFlag,
    'sprop-stereo': stereoFlag,
    maxaveragebitrate: String(bitrate),
    maxplaybackrate: String(OPUS_SAMPLE_RATE),
  };

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
  let hasMaxPtime = false;

  const updated = lines.map((line) => {
    // Promote Opus payload type to primary position on m=audio line
    if (/^m=audio\s+/i.test(line) && opusPayloadType) {
      const tokens = line.trim().split(/\s+/);
      if (tokens.length > 4) {
        const header = tokens.slice(0, 3);
        const payloads = tokens.slice(3).filter((pt) => pt !== opusPayloadType);
        return [...header, opusPayloadType, ...payloads].join(' ');
      }
    }

    if (/^a=ptime:/i.test(line)) {
      hasPtime = true;
      return `a=ptime:${ptime}`;
    }
    if (/^a=maxptime:/i.test(line)) {
      hasMaxPtime = true;
      return 'a=maxptime:20';
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
        if (
          k !== '__proto__' &&
          k !== 'constructor' &&
          k !== 'prototype' &&
          SAFE_FMTP_KEY_RE.test(k) &&
          SAFE_FMTP_VAL_RE.test(v)
        ) {
          paramMap.set(k, v);
        }
      }
      for (const [k, v] of Object.entries(tacticalParams)) {
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
        const serialized = Object.entries(tacticalParams)
          .map(([k, v]) => `${k}=${v}`)
          .join(';');
        finalLines.push(`${fmtpPrefix}${serialized}`);
        fmtpFound = true;
      }
      if (!hasPtime) {
        finalLines.push(`a=ptime:${ptime}`);
        hasPtime = true;
      }
      if (!hasMaxPtime) {
        finalLines.push('a=maxptime:20');
        hasMaxPtime = true;
      }
    }
  }

  return finalLines.join('\r\n');
}

/**
 * Configures outgoing audio RTCRtpSender for 96kbps Opus & high DSCP QoS priority.
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
      // Ignore DSCP priority errors on unsupported engines
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
