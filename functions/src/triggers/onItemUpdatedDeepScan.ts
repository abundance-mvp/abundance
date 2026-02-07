/**
 * Firestore Trigger: Process deep scan requests with Gemini Pro
 *
 * Triggers when item document is updated with deepScanRequested=true and status="pending"
 * Uses Gemini Pro with enhanced prompting to find pricing, dimensions, product info, and market value.
 *
 * Guards:
 * - deepScanRequested === true
 * - status === 'pending'
 * - before.deepScanRequested !== true (prevents re-triggering on unrelated updates)
 *
 * Deploy: firebase deploy --only functions:onItemUpdatedDeepScan
 */

import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { defineSecret } from 'firebase-functions/params';
import * as admin from 'firebase-admin';
import { processItemWithGeminiPersistent } from '../ai-pipeline/gemini/gemini-service';
import { StructuredLogger } from '../monitoring/logger';

const serpApiKey = defineSecret('SERPAPI_KEY');

export const onItemUpdatedDeepScan = onDocumentUpdated(
  {
    document: 'items/{itemId}',
    secrets: [serpApiKey],
    region: 'us-central1',
    memory: '1GiB',
    timeoutSeconds: 180,
  },
  async (event) => {
    const itemId = event.params.itemId;
    const before = event.data?.before.data();
    const after = event.data?.after.data();

    if (!before || !after) {
      console.error('onItemUpdatedDeepScan: No document data');
      return;
    }

    // Guard: Only process deep scan requests
    if (after.deepScanRequested !== true) return;
    if (after.status !== 'pending') return;
    // Prevent re-triggering: only process if deepScanRequested just transitioned to true
    if (before.deepScanRequested === true) return;

    const logger = new StructuredLogger({
      itemId,
      operation: 'onItemUpdatedDeepScan',
    });

    logger.info('Deep scan triggered', {
      userId: after.userId,
      name: after.name,
    });

    // SERPAPI_KEY needed for product search tools
    process.env.SERPAPI_KEY = serpApiKey.value();

    try {
      // Resolve image URL
      const imageUrl = after.imageUrl || after.imagePath;
      if (!imageUrl) {
        throw new Error('Item has no image URL for deep scan');
      }

      // Read additional image URLs if present
      const additionalImageUrls = Array.isArray(after.additionalImageUrls)
        ? after.additionalImageUrls as string[]
        : [];

      // Process with Gemini Pro using enhanced deep scan prompt
      const result = await processItemWithGeminiPersistent(
        imageUrl,
        itemId,
        true, // Use context cache
        additionalImageUrls.length > 0 ? additionalImageUrls : undefined
      );

      // Extract deep scan fields from result
      // Cast to Record since Gemini may return extended fields beyond CatalogItem type
      const rawResult = Array.isArray(result) ? result[0] : result;
      const catalogItem = rawResult as unknown as Record<string, unknown>;

      const deepScanUpdate: Record<string, unknown> = {
        status: 'complete',
        deepScanCompletedAt: admin.firestore.FieldValue.serverTimestamp(),
        // Deep scan extended fields
        productUrl: catalogItem.productUrl ?? null,
        upcCode: catalogItem.upcCode ?? null,
        marketPriceRange: catalogItem.marketPriceRange ?? null,
        originalRetailPrice: catalogItem.originalRetailPrice ?? null,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      // Also update standard fields if better data found
      if (catalogItem.name) deepScanUpdate.name = catalogItem.name;
      if (catalogItem.dimensions) deepScanUpdate.dimensions = catalogItem.dimensions;
      if (catalogItem.estimatedValue) deepScanUpdate.estimatedValue = catalogItem.estimatedValue;

      await event.data!.after.ref.update(deepScanUpdate);

      logger.info('Deep scan completed', {
        productUrl: String(catalogItem.productUrl ?? 'none'),
        upcCode: String(catalogItem.upcCode ?? 'none'),
        marketPriceRange: String(catalogItem.marketPriceRange ?? 'none'),
      });

    } catch (error: unknown) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      logger.error('Deep scan failed', error as Error, { itemId });

      await event.data!.after.ref.update({
        status: 'failed',
        deepScanRequested: false,
        error: `Deep scan failed: ${errorMessage}`,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  }
);
