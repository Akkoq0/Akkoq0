/**
 * @file proAnalyticsService.ts
 * @description Clean Domain Service for Esports Comms & Voice Telemetry Analytics.
 * Evaluates talk-time distribution, cross-talk speech collisions, and overall tactical clarity score.
 */

export interface OperatorCommsLog {
  operatorId: string;
  username: string;
  role: string;
  talkTimeSeconds: number;
  calloutsCount: number;
  interruptionsCount: number; // Instances where this operator spoke while someone else was speaking
}

export interface MatchCommsReport {
  sessionId: string;
  matchDurationSeconds: number;
  totalSpeechSeconds: number;
  clarityScore: number; // 0 to 100
  dominantSpeakerId: string | null;
  operators: OperatorCommsLog[];
  feedbackSummary: string[];
}

export class ProAnalyticsService {
  /**
   * Generates a comprehensive post-match acoustic & comms report.
   */
  public static generateMatchReport(
    sessionId: string,
    matchDurationSeconds: number,
    operators: OperatorCommsLog[],
  ): MatchCommsReport {
    const totalSpeechSeconds = operators.reduce((acc, op) => acc + op.talkTimeSeconds, 0);
    const totalInterruptions = operators.reduce((acc, op) => acc + op.interruptionsCount, 0);
    const totalCallouts = operators.reduce((acc, op) => acc + op.calloutsCount, 0);

    // Find dominant speaker
    let dominantSpeakerId: string | null = null;
    let maxTalk = 0;
    operators.forEach((op) => {
      if (op.talkTimeSeconds > maxTalk) {
        maxTalk = op.talkTimeSeconds;
        dominantSpeakerId = op.operatorId;
      }
    });

    // Calculate Clarity Score (0-100)
    // Base 85 points + Callout bonus - Interruption penalty - Comms imbalance penalty
    let clarityScore = 85;

    // Penalty for frequent speech collisions (interruption noise)
    const collisionPenalty = Math.min(25, totalInterruptions * 3);
    clarityScore -= collisionPenalty;

    // Bonus for high callout density
    const calloutBonus = Math.min(15, Math.floor(totalCallouts * 1.5));
    clarityScore += calloutBonus;

    // Check talk-time skew: if one person speaks >60% of total speech, minor penalty
    if (totalSpeechSeconds > 0 && maxTalk / totalSpeechSeconds > 0.6) {
      clarityScore -= 8;
    }

    clarityScore = Math.max(10, Math.min(100, Math.round(clarityScore)));

    // Generate actionable coach feedback
    const feedbackSummary: string[] = [];
    if (totalInterruptions > 4) {
      feedbackSummary.push('⚠️ Telsiz disiplini: Raunt ortasında aynı anda konuşmalar (cross-talk) yüksek. IGL Ducking ayarını aktif edin.');
    } else {
      feedbackSummary.push('✔ Telsiz temizliği: Ses çakışması minimum düzeyde, komutlar net iletildi.');
    }

    if (totalCallouts >= 5) {
      feedbackSummary.push('✔ Bilgi akışı: Taktik yer bildirimleri (callout) ve düşman sinyalleri dengeli paylaşıldı.');
    } else {
      feedbackSummary.push('ℹ️ Taktik eksiklik: Callout sıklığı düşük. Harita masası ve IGL çarkını daha sık kullanın.');
    }

    return {
      sessionId,
      matchDurationSeconds,
      totalSpeechSeconds,
      clarityScore,
      dominantSpeakerId,
      operators,
      feedbackSummary,
    };
  }
}
