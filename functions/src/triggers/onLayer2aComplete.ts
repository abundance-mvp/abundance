import * as functions from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import { identifyProduct } from '../ai-pipeline/layer2b/identifyProduct';
import { StructuredLogger } from '../monitoring/logger';

/**
 * Trigger: onLayer2aComplete (Layer 2a → Layer 2b transition)
 * Fires when item status changes to "layer2a_complete"
 * Executes Layer 2b processing (SerpAPI + Claude Haiku)
 */
export const onLayer2aComplete = functions.onDocumentUpdated(
  'items/{itemId}',
  async (event) => {
    const itemId = event.params.itemId;
    const before = event.data?.before.data();
    const after = event.data?.after.data();

    const logger = new StructuredLogger({
      itemId,
      userId: after?.userId,
      layer: '2b',
      operation: 'layer2b_product_identification',
    });

    if (!after) {
      logger.error('No after data for item', new Error('Missing after data'));
      return;
    }

    // Only trigger if status changed TO layer2a_complete
    if (before?.status === 'layer2a_complete' || after.status !== 'layer2a_complete') {
      return;
    }

    logger.info('Starting Layer 2b product identification');

    try {
      // Execute Layer 2b product identification
      const layer2bResult = await identifyProduct(
        {
          imageUrl: after.imageUrl,
          barcodeData: after.barcodeData || null,
        },
        itemId
      );

      // Update Firestore document with Layer 2b results
      await event.data?.after.ref.update({
        layer2b: layer2bResult,
        status: 'layer2b_complete',
        layer2bCompletedAt: admin.firestore.Timestamp.now(),
        updatedAt: admin.firestore.Timestamp.now(),
      });

      logger.info('Layer 2b complete', {
        source: layer2bResult.source,
        productName: layer2bResult.product.name,
        costSavings: layer2bResult.costSavings,
      });
    } catch (error) {
      logger.error('Layer 2b failed', error);

      // Update Firestore with error status
      await event.data?.after.ref.update({
        status: 'failed_layer2b',
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
