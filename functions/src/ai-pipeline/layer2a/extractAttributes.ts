import { GeminiProvider } from '../providers/GeminiProvider';
import { CostLogger } from '../cost-tracking/CostLogger';

/**
 * Extract attributes from product image (Layer 2a)
 *
 * @param userId - User ID who owns the item
 * @param itemId - Item ID being processed
 * @param imageUrl - Cloud Storage URL of product image
 * @returns Extracted attributes
 */
export async function extractAttributesLayer2a(
  userId: string,
  itemId: string,
  imageUrl: string
): Promise<any> {
  const provider = new GeminiProvider();
  const logger = new CostLogger();

  const startTime = Date.now();

  // Extract attributes using Gemini
  const result = await provider.extractAttributes(imageUrl, userId, itemId);

  const latency = Date.now() - startTime;

  // Extract usage metadata
  const usage = result.usage;
  delete result.usage; // Remove from result

  // Calculate cost
  const cost = logger.calculateCost(
    'gemini-2.5-flash-lite',
    usage.inputTokens,
    usage.outputTokens
  );

  // Log cost to Firestore
  await logger.logCost({
    userId,
    itemId,
    provider: 'gemini',
    model: 'gemini-2.5-flash-lite',
    operation: 'layer2a_extraction',
    inputTokens: usage.inputTokens,
    outputTokens: usage.outputTokens,
    totalTokens: usage.totalTokens,
    cost,
    timestamp: new Date()
  });

  console.log(`Layer 2a complete for item ${itemId}: cost=$${cost.toFixed(6)}, latency=${latency}ms`);

  return result;
}
