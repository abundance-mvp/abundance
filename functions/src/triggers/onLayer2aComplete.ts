import * as functions from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';

/**
 * Trigger: onLayer2aComplete (Layer 2a → Layer 2b transition)
 * Fires when item status changes to "layer2a_complete"
 * Schedules Layer 2b processing (SerpAPI + Claude Haiku)
 */
export const onLayer2aComplete = functions.onDocumentUpdated(
  'items/{itemId}',
  async (event) => {
    const itemId = event.params.itemId;
    const before = event.data?.before.data();
    const after = event.data?.after.data();

    if (!after) {
      console.error(`onLayer2aComplete: No after data for item ${itemId}`);
      return;
    }

    // Only trigger if status changed TO layer2a_complete
    if (before?.status === 'layer2a_complete' || after.status !== 'layer2a_complete') {
      return;
    }

    console.log(`[Layer 2b] Scheduling for item ${itemId}`);

    // Update status to layer2b_scheduled
    await event.data?.after.ref.update({
      status: 'layer2b_scheduled',
      layer2bScheduledAt: admin.firestore.Timestamp.now(),
      updatedAt: admin.firestore.Timestamp.now(),
    });

    console.log(`[Layer 2b] Scheduled for item ${itemId}`);
  }
);
