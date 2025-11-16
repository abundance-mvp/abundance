import * as functions from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import { extractAttributesLayer2a } from '../ai-pipeline/layer2a/extractAttributes';

/**
 * Trigger: onItemCreated (Layer 1 → Layer 2a transition)
 * Fires when item document is created with status="pending"
 * Calls Gemini to extract attributes
 */
export const onItemCreated = functions.onDocumentCreated(
  'items/{itemId}',
  async (event) => {
    const itemId = event.params.itemId;
    const item = event.data?.data();

    if (!item) {
      console.error(`onItemCreated: No data for item ${itemId}`);
      return;
    }

    // Validate state
    if (item.status !== 'pending') {
      console.log(`onItemCreated: Skipping item ${itemId} (status: ${item.status})`);
      return;
    }

    // Validate required fields
    if (!item.imageUrl) {
      console.error(`onItemCreated: Missing imageUrl for item ${itemId}`);
      await event.data?.ref.update({
        status: 'failed_layer2a',
        error: {
          message: 'Missing imageUrl',
          timestamp: admin.firestore.Timestamp.now(),
        },
        updatedAt: admin.firestore.Timestamp.now(),
      });
      return;
    }

    console.log(`[Layer 2a] Processing item ${itemId}`);

    try {
      // Extract attributes using Gemini
      const attributes = await extractAttributesLayer2a(
        item.userId,
        itemId,
        item.imageUrl
      );

      // Store attributes in Firestore
      await event.data?.ref.update({
        status: 'layer2a_complete',
        'layer2a.category': attributes.category,
        'layer2a.color': attributes.color,
        'layer2a.material': attributes.material || null,
        'layer2a.condition': attributes.condition,
        'layer2a.confidence': attributes.confidence || null,
        'layer2a.model': 'gemini-2.5-flash-lite',
        layer2aCompletedAt: admin.firestore.Timestamp.now(),
        updatedAt: admin.firestore.Timestamp.now(),
      });

      console.log(`[Layer 2a] Complete for item ${itemId}`);
    } catch (error: any) {
      console.error(`[Layer 2a] Failed for item ${itemId}:`, error);

      await event.data?.ref.update({
        status: 'failed_layer2a',
        error: {
          message: error.message,
          timestamp: admin.firestore.Timestamp.now(),
        },
        updatedAt: admin.firestore.Timestamp.now(),
      });
    }
  }
);
