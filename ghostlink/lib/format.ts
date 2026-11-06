// ─────────────────────────────────────────────────────────
// Meva HUD — Label formatting helpers
// ─────────────────────────────────────────────────────────

const LEADING_SYMBOLS = /^[^\w\sÇĞİÖŞÜçğıöşü#@-]+\s*/;

/** Strips leading emoji/symbol decorations from channel names. */
export function cleanLabel(raw: string): string {
  return raw.replace(LEADING_SYMBOLS, '').trim() || raw;
}

/** "Valorant TR Pro" → "VT" */
export function serverCode(name: string): string {
  const words = name.trim().split(/\s+/);
  return (words.length >= 2 ? words[0][0] + words[1][0] : name.slice(0, 2)).toUpperCase();
}
