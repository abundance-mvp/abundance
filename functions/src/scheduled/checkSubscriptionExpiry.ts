import * as functions from 'firebase-functions/v2/scheduler';
import * as admin from 'firebase-admin';

/**
 * Scheduled Job: checkSubscriptionExpiry
 * Runs daily at 6am UTC
 * Downgrades expired premium users to free tier
 */
export const checkSubscriptionExpiryScheduled = functions.onSchedule(
  {
    schedule: '0 6 * * *', // Daily at 6am UTC
    timeZone: 'UTC',
  },
  async (event) => {
    console.log('[Subscriptions] Starting checkSubscriptionExpiry job');
    await checkSubscriptionExpiry();
    console.log('[Subscriptions] Completed checkSubscriptionExpiry job');
  }
);

/**
 * Subscription expiry logic (exported for testing)
 */
export async function checkSubscriptionExpiry(): Promise<void> {
  const db = admin.firestore();
  const now = admin.firestore.Timestamp.now();

  console.log(`[Subscriptions] Checking for expired subscriptions as of ${now.toDate().toISOString()}`);

  // Query premium users with expired subscriptions
  const query = db
    .collection('users')
    .where('subscription.tier', '==', 'premium')
    .where('subscription.expiresAt', '<', now)
    .limit(100); // Process in batches

  const snapshot = await query.get();

  if (snapshot.empty) {
    console.log('[Subscriptions] No expired subscriptions');
    return;
  }

  console.log(`[Subscriptions] Found ${snapshot.size} expired subscriptions`);

  // Downgrade to free tier
  const batch = db.batch();
  snapshot.docs.forEach((doc) => {
    batch.update(doc.ref, {
      'subscription.tier': 'free',
      'subscription.downgradedAt': now,
      'subscription.previousTier': 'premium',
      updatedAt: now,
    });
  });

  await batch.commit();

  console.log(`[Subscriptions] Downgraded ${snapshot.size} users to free tier`);
}
