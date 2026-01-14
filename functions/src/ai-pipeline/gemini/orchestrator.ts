/**
 * Orchestrator for Gemini 3 Pro Pipeline
 *
 * Handles Firestore trigger events and coordinates the AI pipeline.
 * Called when item documents are created with status="pending".
 */

import * as admin from 'firebase-admin';
import { processItemWithGemini } from './gemini-service';
import { validateCatalogItem } from './schemas/catalog-item';

/**
 * Handle item creation - process with Gemini 3 Pro
 *
 * Called by Firestore trigger when item document is created
 * Extracts signed URL, calls Gemini, updates document with results
 *
 * @param snapshot - Firestore document snapshot
 * @param context - Event context with params
 */
export async function handleItemCreated(
  snapshot: admin.firestore.DocumentSnapshot,
  context: { params: { itemId: string } }
): Promise<void> {
  const itemId = context.params.itemId;
  const itemData = snapshot.data();

  if (!itemData) {
    console.error(`[Gemini3] No data for item ${itemId}`);
    return;
  }

  // Skip if not in pending state
  if (itemData.status !== 'pending') {
    console.log(`[Gemini3] Skipping item ${itemId} (status: ${itemData.status})`);
    return;
  }

  console.log({
    severity: 'INFO',
    message: 'Gemini 3 Pro pipeline started',
    itemId,
    userId: itemData.userId
  });

  try {
    // Get signed URL for image
    const imageUrl = await getSignedImageUrl(itemData.imagePath);

    // Process with Gemini 3 Pro
    const result = await processItemWithGemini(imageUrl);

    // Validate result
    const catalogItems = Array.isArray(result) ? result : [result];
    for (const item of catalogItems) {
      const validation = validateCatalogItem(item);
      if (!validation.valid) {
        console.warn(`[Gemini3] Validation warnings for ${itemId}:`, validation.errors);
      }
    }

    // Update Firestore with results
    await snapshot.ref.update({
      status: 'complete',
      catalog: result,
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    console.log({
      severity: 'INFO',
      message: 'Gemini 3 Pro pipeline completed',
      itemId,
      itemCount: Array.isArray(result) ? result.length : 1
    });

  } catch (error: unknown) {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    console.error({
      severity: 'ERROR',
      message: 'Gemini 3 Pro pipeline failed',
      itemId,
      error: errorMessage
    });

    await snapshot.ref.update({
      status: 'failed',
      error: errorMessage,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
  }
}

/**
 * Get signed URL for Cloud Storage image
 * Valid for 15 minutes
 */
async function getSignedImageUrl(imagePath: string): Promise<string> {
  const bucket = admin.storage().bucket();
  const file = bucket.file(imagePath);

  const [url] = await file.getSignedUrl({
    action: 'read',
    expires: Date.now() + 15 * 60 * 1000 // 15 minutes
  });

  return url;
}

/**
 * Log AI costs for monitoring
 */
export async function logCosts(
  itemId: string,
  toolsUsed: string[]
): Promise<void> {
  // Cost estimates based on COST-MODEL-001
  const toolCosts: Record<string, number> = {
    google_lens_search: 0.015,
    barcode_lookup: 0.005, // Amortized from monthly subscription
    web_search: 0.014
  };

  const geminiCost = 0.004; // ~$0.004 per item
  const totalToolCost = toolsUsed.reduce((sum, tool) => sum + (toolCosts[tool] || 0), 0);

  await admin.firestore().collection('aiCosts').add({
    itemId,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    gemini: geminiCost,
    tools: Object.fromEntries(toolsUsed.map(t => [t, toolCosts[t] || 0])),
    total: geminiCost + totalToolCost
  });
}
