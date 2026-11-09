/**
 * @file tacticalPresetManager.ts
 * @description Clean Domain Service for Tactical Playbook Export/Import & Preset Management.
 * Empowers esports teams to save, load, and share tactical playbooks (.strat.json).
 */

function safeJsonParse<T>(jsonString: string | null | undefined, fallback: T): T {
  if (!jsonString || typeof jsonString !== 'string') return fallback;
  try {
    return JSON.parse(jsonString) as T;
  } catch {
    return fallback;
  }
}

export interface TacticalMarker {
  id: string;
  x: number;
  y: number;
  tool: string;
  color: string;
  label?: string;
}

export interface TacticalPlaybook {
  schemaVersion: '1.0';
  id: string;
  title: string;
  gameId: string;
  mapId: string;
  author: string;
  createdAt: string;
  notes: string;
  markers: TacticalMarker[];
}

export class TacticalPresetManager {
  /**
   * Serializes a playbook into a downloadable portable JSON string.
   */
  public static exportPlaybookToJson(playbook: TacticalPlaybook): string {
    return JSON.stringify(playbook, null, 2);
  }

  /**
   * Parses and validates an imported JSON string into a structured playbook.
   */
  public static importPlaybookFromJson(
    jsonContent: string,
  ): TacticalPlaybook | null {
    const parsed = safeJsonParse<Partial<TacticalPlaybook> | null>(jsonContent, null);
    if (!parsed || typeof parsed !== 'object') return null;

    if (!parsed.title || !parsed.mapId || !Array.isArray(parsed.markers)) {
      return null;
    }

    return {
      schemaVersion: '1.0',
      id: parsed.id || `strat-${Date.now().toString(36)}`,
      title: String(parsed.title),
      gameId: parsed.gameId || 'cs2',
      mapId: String(parsed.mapId),
      author: parsed.author || 'Meva Operatörü',
      createdAt: parsed.createdAt || new Date().toISOString(),
      notes: parsed.notes || '',
      markers: parsed.markers as TacticalMarker[],
    };
  }
}
