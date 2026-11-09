/**
 * @file licenseManager.ts
 * @description Clean Domain Service for Open-Core Freemium & Meva Pro Licensing.
 * Defines feature tiers (Community Free vs Meva Pro Esports) without intrusive paywalls.
 */

export type SubscriptionTier = 'community' | 'pro';

export type ProFeatureId =
  | 'pro-analytics'      // Post-Match Comms Score, Talk-time distribution & Cross-talk detector
  | 'cloud-stratbook'    // Portable Playbook JSON import/export & cloud sync
  | 'streamer-matrix'    // OBS Virtual Audio submix & Streamer privacy shield
  | 'priority-relay'     // Low-latency dedicated TURN relay nodes
  | 'custom-badges';     // Clan verified badges & bespoke tactical callouts

export interface FeatureSpec {
  id: ProFeatureId;
  name: string;
  category: 'esports' | 'tactical' | 'broadcast' | 'network';
  description: string;
  isProOnly: boolean;
}

export const PLATFORM_FEATURES: ReadonlyArray<FeatureSpec> = [
  {
    id: 'pro-analytics',
    name: 'Espor Akustik & İletişim Koçluğu',
    category: 'esports',
    description: 'Konuşma süresi dengesi, ses çakışması (cross-talk) tespiti ve maç sonu iletişim skoru.',
    isProOnly: true,
  },
  {
    id: 'cloud-stratbook',
    name: 'Taşınabilir Taktik Playbook Yöneticisi',
    category: 'tactical',
    description: 'Takım stratejilerini .strat.json olarak dışa/içe aktarma ve bulutta saklama.',
    isProOnly: true,
  },
  {
    id: 'streamer-matrix',
    name: 'Yayıncı Gizlilik Kalkanı & OBS Submix',
    category: 'broadcast',
    description: 'Yayın esnasında sunucu davet kodlarını gizleme ve OBS ses şeritlerini ayrıştırma.',
    isProOnly: true,
  },
  {
    id: 'priority-relay',
    name: 'Öncelikli Espor TURN Röleleri',
    category: 'network',
    description: 'Katı NAT/güvenlik duvarı arkasındaki turnuva lobilerinde sıfır gecikmeli ses aktarımı.',
    isProOnly: true,
  },
  {
    id: 'custom-badges',
    name: 'Doğrulanmış Klan Rozetleri',
    category: 'esports',
    description: 'Takım logosu ve oyuncu rolleri için özel altın/kızıl elmas çerçeveler.',
    isProOnly: true,
  },
];

export class LicenseManager {
  /**
   * Evaluates if a given tier has access to a feature.
   */
  public static canAccessFeature(
    featureId: ProFeatureId,
    userTier: SubscriptionTier,
  ): boolean {
    if (userTier === 'pro') return true;
    const spec = PLATFORM_FEATURES.find((f) => f.id === featureId);
    return spec ? !spec.isProOnly : false;
  }

  /**
   * Returns human-readable label and badge for the current tier.
   */
  public static getTierMetadata(tier: SubscriptionTier): {
    label: string;
    badge: string;
    tone: 'free' | 'pro';
    description: string;
  } {
    if (tier === 'pro') {
      return {
        label: 'Meva Pro Espor',
        badge: '⚡ PRO',
        tone: 'pro',
        description: 'Turnuva ve espor kulüpleri için gelişmiş taktik ve akustik analiz paketi devrede.',
      };
    }
    return {
      label: 'Topluluk Sürümü (Açık Kaynak)',
      badge: 'OPEN SOURCE',
      tone: 'free',
      description: 'Sınırsız P2P ses, taktik harita masası ve uçtan uca şifreli şeffaf iletişim.',
    };
  }
}
