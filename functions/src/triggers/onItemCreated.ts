import * as functions from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';

/**
 * Trigger: onItemCreated (Layer 1 → Layer 2a transition)
 * Fires when item document is created with status="pending"
 * Schedules Layer 2a processing (Gemini attribute extraction)
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

    console.log(`[Layer 2a] Scheduling for item ${itemId}`);

    // Update status to layer2a_scheduled
    // In Sprint 4-6, this will trigger Cloud Function to call Gemini
    await event.data?.ref.update({
      status: 'layer2a_scheduled',
      layer2aScheduledAt: admin.firestore.Timestamp.now(),
      updatedAt: admin.firestore.Timestamp.now(),
    });

    console.log(`[Layer 2a] Scheduled for item ${itemId}`);
  }
);
