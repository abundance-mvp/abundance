/**
 * Firestore Trigger: Create item from session detection
 *
 * Triggered when an item document is created from a session detection.
 * These items have a sessionId field and imageUrl pointing to cropped object.
 *
 * Workflow:
 * 1. Verify session reference and user ownership
 * 2. Process with Gemini 3 Pro for cataloging
 * 3. Update item document with catalog data
 *
 * Deploy: firebase deploy --only functions:onItemFromSession
 */

import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { defineSecret } from 'firebase-functions/params';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { processItemWithGemini } from '../ai-pipeline/gemini/gemini-service';
import { validateCatalogItem } from '../ai-pipeline/gemini/schemas/catalog-item';

const serpApiKey = defineSecret('SERPAPI_KEY');

export const onItemFromSession = onDocumentCreated(
  {
    document: 'items/{itemId}',
    secrets: [serpApiKey],
    region: 'us-central1',
    memory: '512MiB',
    timeoutSeconds: 120,
  },
  async (event) => {
    if (!event.data) {
      console.error('onItemFromSession: No document data');
      return;
    }

    const itemData = event.data.data();
    const itemId = event.params.itemId;

    // Only process items created from sessions
    if (!itemData.sessionId || !itemData.fromDetection) {
      // Let onItemCreatedGemini3 handle non-session items
      return;
    }

    // Skip if not in pending state
    if (itemData.status !== 'pending') {
      console.log(`Skipping item ${itemId} - status: ${itemData.status}`);
      return;
    }

    // Set SERPAPI_KEY for Google Lens tool
    process.env.SERPAPI_KEY = serpApiKey.value();

    const db = getFirestore();
    const itemRef = db.collection('items').doc(itemId);

    console.log({
      severity: 'INFO',
      message: 'Processing session item with Gemini 3 Pro',
      itemId,
      sessionId: itemData.sessionId,
      groupId: itemData.groupId,
      label: itemData.layer1Label
    });

    try {
      // Update status to processing
      await itemRef.update({
        status: 'processing',
        updatedAt: FieldValue.serverTimestamp()
      });

      // Process with Gemini 3 Pro
      // The imageUrl should point to the cropped object in GCS
      const additionalImageUrls = Array.isArray(itemData.additionalImageUrls)
        ? itemData.additionalImageUrls as string[]
        : [];
      const result = await processItemWithGemini(
        itemData.imageUrl,
        additionalImageUrls.length > 0 ? additionalImageUrls : undefined
      );

      // Validate result
      const catalogItems = Array.isArray(result) ? result : [result];
      for (const item of catalogItems) {
        const validation = validateCatalogItem(item);
        if (!validation.valid) {
          console.warn(`Validation warnings for ${itemId}:`, validation.errors);
        }
      }

      // Flatten catalog data to top-level fields
      const catalogItem = Array.isArray(result) ? result[0] : result;

      const flattenedUpdate: Record<string, unknown> = {
        status: 'complete',
        // Flatten catalog fields to top level, falling back to layer1 data
        name: catalogItem.name || itemData.layer1Label || null,
        category: catalogItem.category || itemData.layer1Category || null,
        subCategory: catalogItem.subCategory,
        brand: catalogItem.brand ?? null,
        model: catalogItem.model ?? null,
        color: catalogItem.color,
        condition: catalogItem.condition,
        dimensions: catalogItem.dimensions ?? null,
        quantity: catalogItem.quantity ?? 1,
        estimatedValue: catalogItem.estimatedValue ?? null,
        confidence: catalogItem.confidence,
        processingNotes: catalogItem.processingNotes ?? null,
        // Keep original catalog for backward compatibility
        catalog: result,
        completedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp()
      };

      await itemRef.update(flattenedUpdate);

      // Update session to mark this object as cataloged
      await db.collection('sessions').doc(itemData.sessionId).update({
        [`catalogedObjects.${itemData.groupId}`]: {
          itemId,
          catalogedAt: FieldValue.serverTimestamp()
        }
      });

      console.log({
        severity: 'INFO',
        message: 'Session item cataloged successfully',
        itemId,
        sessionId: itemData.sessionId,
        name: catalogItem.name,
        category: catalogItem.category
      });

    } catch (error: unknown) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      console.error({
        severity: 'ERROR',
        message: 'Session item cataloging failed',
        itemId,
        sessionId: itemData.sessionId,
        error: errorMessage
      });

      await itemRef.update({
        status: 'failed',
        error: errorMessage,
        // Preserve layer1 data as fallback display name on failure
        name: itemData.layer1Label || null,
        category: itemData.layer1Category || null,
        updatedAt: FieldValue.serverTimestamp()
      });
    }
  }
);
