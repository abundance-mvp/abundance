import * as admin from 'firebase-admin';

interface CostLogEntry {
  userId: string;
  itemId: string;
  provider: string;
  model: string;
  operation: string;
  inputTokens: number;
  outputTokens: number;
  totalTokens: number;
  cost: number;
  timestamp: Date;
}

/**
 * Cost logging for AI API calls
 * Logs all API usage to Firestore costLogs collection
 */
export class CostLogger {
  /**
   * Log API call cost to Firestore
   */
  async logCost(entry: CostLogEntry): Promise<void> {
    const db = admin.firestore();
    await db.collection('costLogs').add({
      ...entry,
      timestamp: admin.firestore.Timestamp.fromDate(entry.timestamp)
    });
  }

  /**
   * Calculate cost per API call
   *
   * Pricing (as of 2025-11-15):
   * - Gemini 2.5 Flash-Lite: $0.10/1M input, $0.40/1M output
   */
  calculateCost(
    model: string,
    inputTokens: number,
    outputTokens: number
  ): number {
    const pricing: Record<string, { input: number; output: number }> = {
      'gemini-2.5-flash-lite': {
        input: 0.10 / 1_000_000,  // $0.10 per 1M tokens
        output: 0.40 / 1_000_000  // $0.40 per 1M tokens
      }
    };

    const modelPricing = pricing[model];
    if (!modelPricing) {
      throw new Error(`Unknown model: ${model}`);
    }

    const inputCost = inputTokens * modelPricing.input;
    const outputCost = outputTokens * modelPricing.output;

    return inputCost + outputCost;
  }
}
