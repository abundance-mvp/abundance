import * as functions from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import { synthesizeMetadata } from '../ai-pipeline/layer3/synthesize';
import { StructuredLogger } from '../monitoring/logger';

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

    const logger = new StructuredLogger({
      itemId,
      userId: after?.userId,
      layer: '3',
      operation: 'layer3_synthesis',
    });

    if (!after) {
      logger.error('No after data for item', new Error('Missing after data'));
      return;
    }

    // Only trigger if status changed TO layer2b_complete
    if (before?.status === 'layer2b_complete' || after.status !== 'layer2b_complete') {
      return;
    }

    logger.info('Starting Layer 3 synthesis');

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

      logger.info('Layer 3 complete', {
        name: synthesizedMetadata.name,
        category: synthesizedMetadata.category,
        confidence: synthesizedMetadata.confidence,
      });
    } catch (error: any) {
      logger.error('Layer 3 failed', error);

      // Update Firestore with error status
      await event.data?.after.ref.update({
        status: 'failed_layer3',
        error: {
          message: error.message,
          code: error.code || 'UNKNOWN',
          type: error.name || 'Error',
          timestamp: admin.firestore.Timestamp.now(),
        },
        updatedAt: admin.firestore.Timestamp.now(),
      });
    }
  }
);
