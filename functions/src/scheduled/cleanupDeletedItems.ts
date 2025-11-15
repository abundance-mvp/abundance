import * as functions from 'firebase-functions/v2/scheduler';
import * as admin from 'firebase-admin';

/**
 * Scheduled Job: cleanupDeletedItems
 * Runs daily at 2am UTC
 * Permanently deletes soft-deleted items older than 90 days
 *
 * References: ADR-008 (90-day grace period)
 */
export const cleanupDeletedItemsScheduled = functions.onSchedule(
  {
    schedule: '0 2 * * *', // Daily at 2am UTC
    timeZone: 'UTC',
  },
  async (event) => {
    console.log('[Cleanup] Starting cleanupDeletedItems job');
    try {
      await cleanupDeletedItems();
      console.log('[Cleanup] Completed cleanupDeletedItems job');
    } catch (error) {
      console.error('[Cleanup] Job failed:', error);
      throw error; // Re-throw to mark Cloud Scheduler execution as failed
    }
  }
);

/**
 * Cleanup logic (exported for testing)
 */
export async function cleanupDeletedItems(): Promise<void> {
  const db = admin.firestore();

  // Calculate cutoff date (90 days ago)
  const cutoffDate = new Date(Date.now() - 90 * 24 * 60 * 60 * 1000);
  const cutoffTimestamp = admin.firestore.Timestamp.fromDate(cutoffDate);

  console.log(`[Cleanup] Cutoff date: ${cutoffDate.toISOString()}`);

  // Query soft-deleted items older than 90 days
  const query = db
    .collection('items')
    .where('status', '==', 'deleted')
    .where('deletedAt', '<', cutoffTimestamp)
    .limit(100); // Process in batches

  const snapshot = await query.get();

  if (snapshot.empty) {
    console.log('[Cleanup] No items to delete');
    return;
  }

  console.log(`[Cleanup] Found ${snapshot.size} items to delete`);

  // Delete items in batch
  const batch = db.batch();
  snapshot.docs.forEach((doc) => {
    batch.delete(doc.ref);
  });

  await batch.commit();

  console.log(`[Cleanup] Permanently deleted ${snapshot.size} items`);
}
