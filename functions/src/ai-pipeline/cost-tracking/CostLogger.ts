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
      // C3: Log warning instead of throwing error for unknown models
      console.warn(`Unknown model: ${model}. Unable to calculate cost. Returning 0.`);
      return 0;
    }

    const inputCost = inputTokens * modelPricing.input;
    const outputCost = outputTokens * modelPricing.output;

    return inputCost + outputCost;
  }

  /**
   * Log barcode API usage to Firestore
   */
  async logBarcodeUsage(usage: {
    api: string;
    itemId: string;
    barcode: string;
    cost: number;
    found: boolean;
    latency: number;
  }): Promise<void> {
    const db = admin.firestore();
    const usageRef = db.collection('barcode_usage').doc();

    await usageRef.set({
      api: usage.api,
      itemId: usage.itemId,
      barcode: usage.barcode,
      cost: usage.cost,
      found: usage.found,
      latency: usage.latency,
      timestamp: admin.firestore.Timestamp.now(),
    });

    console.log(`[CostLogger] Logged barcode usage: ${usage.api}, cost: $${usage.cost.toFixed(6)}`);
  }

  /**
   * Log SerpAPI usage to Firestore
   */
  async logSerpAPIUsage(usage: {
    itemId: string;
    imageUrl: string;
    matchCount: number;
    latency: number;
    cost: number;
  }): Promise<void> {
    const db = admin.firestore();
    const usageRef = db.collection('serpapi_usage').doc();

    await usageRef.set({
      itemId: usage.itemId,
      imageUrl: usage.imageUrl,
      matchCount: usage.matchCount,
      latency: usage.latency,
      cost: usage.cost,
      timestamp: admin.firestore.Timestamp.now(),
    });

    console.log(`[CostLogger] Logged SerpAPI usage: item ${usage.itemId}, cost: $${usage.cost.toFixed(6)}`);
  }

  /**
   * Log Claude API usage to Firestore
   */
  async logClaudeUsage(usage: {
    model: string;
    itemId: string;
    userId: string;
    tokensUsed: { input: number; output: number; total: number };
    cost: number;
    latency: number;
  }): Promise<void> {
    const db = admin.firestore();
    const usageRef = db.collection('ai_usage').doc();

    await usageRef.set({
      service: usage.model,
      itemId: usage.itemId,
      userId: usage.userId,
      tokensUsed: usage.tokensUsed.total,
      tokensInput: usage.tokensUsed.input,
      tokensOutput: usage.tokensUsed.output,
      cost: usage.cost,
      timestamp: admin.firestore.Timestamp.now(),
    });

    console.log(`[CostLogger] Logged Claude usage: ${usage.model}, tokens: ${usage.tokensUsed.total}, cost: $${usage.cost.toFixed(6)}`);
  }
}
