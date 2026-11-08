// ─────────────────────────────────────────────────────────
// Meva HUD — Rolling Voice VOD Clip Buffer & WAV Exporter
// ─────────────────────────────────────────────────────────
// Keeps the last 30-60 seconds of tactical team communications
// in a circular memory ring buffer for instant 1-click clutch replay.

const SAMPLE_RATE = 48000;
const MAX_BUFFER_SECONDS = 60;
const MAX_SAMPLES = SAMPLE_RATE * MAX_BUFFER_SECONDS;

class VoiceClipRingBuffer {
  private buffer: Float32Array = new Float32Array(MAX_SAMPLES);
  private writeIndex: number = 0;
  private totalSamplesRecorded: number = 0;
  private isCapturing: boolean = false;

  public startCapturing() {
    this.isCapturing = true;
    this.writeIndex = 0;
    this.totalSamplesRecorded = 0;
  }

  public stopCapturing() {
    this.isCapturing = false;
  }

  public getStatus() {
    const recordedSec = Math.min(
      MAX_BUFFER_SECONDS,
      Math.round(this.totalSamplesRecorded / SAMPLE_RATE),
    );
    return {
      isCapturing: this.isCapturing,
      recordedSeconds: recordedSec,
      maxSeconds: MAX_BUFFER_SECONDS,
    };
  }

  /**
   * Appends audio PCM frames from WebAudio ScriptProcessor or AudioWorklet
   */
  public pushAudioData(samples: Float32Array) {
    for (let i = 0; i < samples.length; i++) {
      this.buffer[this.writeIndex] = samples[i];
      this.writeIndex = (this.writeIndex + 1) % MAX_SAMPLES;
    }
    this.totalSamplesRecorded += samples.length;
  }

  /**
   * Exports the last N seconds of recorded voice into a standard .wav Blob
   */
  public exportLastSecondsToWav(seconds: number = 30): Blob {
    const validSec = Math.min(MAX_BUFFER_SECONDS, Math.max(5, seconds));
    const sampleCount = Math.min(this.totalSamplesRecorded, validSec * SAMPLE_RATE);

    // If buffer is empty or fresh, generate a clean synthetic confirmation pulse
    const pcmData = new Float32Array(sampleCount > 0 ? sampleCount : SAMPLE_RATE * 3);

    if (sampleCount > 0) {
      let readIdx = (this.writeIndex - sampleCount + MAX_SAMPLES) % MAX_SAMPLES;
      for (let i = 0; i < sampleCount; i++) {
        pcmData[i] = this.buffer[readIdx];
        readIdx = (readIdx + 1) % MAX_SAMPLES;
      }
    } else {
      // Mock subtle tone so the audio file is always valid
      for (let i = 0; i < pcmData.length; i++) {
        pcmData[i] = Math.sin((2 * Math.PI * 440 * i) / SAMPLE_RATE) * 0.05;
      }
    }

    return encodePcmToWavBlob(pcmData, SAMPLE_RATE);
  }
}

/**
 * Pure TypeScript WAV file header encoder (RIFF/WAVE PCM 16-bit Mono/Stereo)
 */
export function encodePcmToWavBlob(samples: Float32Array, sampleRate: number): Blob {
  const buffer = new ArrayBuffer(44 + samples.length * 2);
  const view = new DataView(buffer);

  // RIFF Chunk Descriptor
  writeString(view, 0, 'RIFF');
  view.setUint32(4, 36 + samples.length * 2, true);
  writeString(view, 8, 'WAVE');

  // fmt sub-chunk
  writeString(view, 12, 'fmt ');
  view.setUint32(16, 16, true); // Subchunk1Size (16 for PCM)
  view.setUint16(20, 1, true); // AudioFormat (1 for PCM)
  view.setUint16(22, 1, true); // NumChannels (1 = Mono)
  view.setUint32(24, sampleRate, true); // SampleRate
  view.setUint32(28, sampleRate * 2, true); // ByteRate (SampleRate * NumChannels * BitsPerSample/8)
  view.setUint16(32, 2, true); // BlockAlign (NumChannels * BitsPerSample/8)
  view.setUint16(34, 16, true); // BitsPerSample (16 bits)

  // data sub-chunk
  writeString(view, 36, 'data');
  view.setUint32(40, samples.length * 2, true);

  // Write PCM 16-bit samples (clamped between -1.0 and 1.0)
  let offset = 44;
  for (let i = 0; i < samples.length; i++) {
    const s = Math.max(-1, Math.min(1, samples[i]));
    view.setInt16(offset, s < 0 ? s * 0x8000 : s * 0x7fff, true);
    offset += 2;
  }

  return new Blob([view], { type: 'audio/wav' });
}

function writeString(view: DataView, offset: number, string: string) {
  for (let i = 0; i < string.length; i++) {
    view.setUint8(offset + i, string.charCodeAt(i));
  }
}

// Global Singleton Instance
let ringBufferInstance: VoiceClipRingBuffer | null = null;

export function getVoiceClipBuffer(): VoiceClipRingBuffer {
  if (!ringBufferInstance) {
    ringBufferInstance = new VoiceClipRingBuffer();
    ringBufferInstance.startCapturing();
  }
  return ringBufferInstance;
}
