// ─────────────────────────────────────────────────────────
// Meva HUD — Spatial Audio Engine Re-Export Bridge
// ─────────────────────────────────────────────────────────
// Canonical implementation lives in @/src/lib/audioEngine.

export {
  MevaAudioEngine as MevaSpatialAudioEngine,
  MevaAudioEngine,
  getMevaAudioEngine,
  percentToLogarithmicGain,
  SPATIAL_PAN_VALUES,
  EQ_PROFILE_CONFIGS,
  type SpatialPanPosition,
  type OperatorEqProfile,
  type EqPresetConfig,
  type SpectrumSnapshot,
  type CalloutCueType,
} from '@/src/lib/audioEngine';
