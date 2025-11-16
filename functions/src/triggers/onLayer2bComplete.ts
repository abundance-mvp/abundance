import * as functions from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import { synthesizeMetadata } from '../ai-pipeline/layer3/synthesize';

/**
 * Trigger: onLayer2bComplete (Layer 2b → Layer 3 transition)
 * Fires when item status changes to "layer2b_complete"
 * Executes Layer 3 synthesis (Claude Sonnet 4.5)
 */
export const onLayer2bComplete = functions.onDocumentUpdated(
  'items/{itemId}',
  async (event) => {
    const itemId = event.params.itemId;
    const before = event.data?.before.data();
    const after = event.data?.after.data();

    if (!after) {
      console.error(`onLayer2bComplete: No after data for item ${itemId}`);
      return;
    }

    // Only trigger if status changed TO layer2b_complete
    if (before?.status === 'layer2b_complete' || after.status !== 'layer2b_complete') {
      return;
    }

    console.log(`[Layer 3] Starting synthesis for item ${itemId}`);

    try {
      // Validate Layer 2 data exists
      if (!after.layer2a || !after.layer2b) {
        throw new Error('Missing Layer 2a or 2b data');
      }

      // Execute Layer 3 synthesis
      const synthesizedMetadata = await synthesizeMetadata(
        {
          detectedLabel: after.detectedLabel || 'unknown',
          layer2a: after.layer2a,
          layer2b: after.layer2b,
        },
        itemId
      );

      // Update Firestore document with final metadata
      await event.data?.after.ref.update({
        metadata: synthesizedMetadata,
        status: 'complete',
        layer3CompletedAt: admin.firestore.Timestamp.now(),
        updatedAt: admin.firestore.Timestamp.now(),
      });

      console.log(`[Layer 3] ✅ Layer 3 complete for item ${itemId}:`, synthesizedMetadata.name);
    } catch (error) {
      console.error(`[Layer 3] ❌ Layer 3 failed for item ${itemId}:`, error);

      // Update Firestore with error status
      await event.data?.after.ref.update({
        status: 'failed_layer3',
        error: {
          message: error instanceof Error ? error.message : 'Unknown error',
          code: (error as any).code || 'UNKNOWN',
          type: error instanceof Error ? error.name : 'Error',
          timestamp: admin.firestore.Timestamp.now(),
        },
        updatedAt: admin.firestore.Timestamp.now(),
      });
    }
  }
);
