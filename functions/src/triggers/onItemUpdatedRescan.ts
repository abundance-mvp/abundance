/**
 * Firestore Trigger: Process item rescans with Gemini 3 Pro
 *
 * Triggers when an existing item document is updated with status="pending"
 * (transition from non-pending) WITHOUT deepScanRequested. This handles the
 * "Re-catalog" button flow where the user wants to re-process an item
 * through the standard AI pipeline.
 *
 * Guards:
 * - status === 'pending'
 * - before.status !== 'pending' (prevents re-triggering)
 * - deepScanRequested !== true (deep scans handled by onItemUpdatedDeepScan)
 *
 * Deploy: firebase deploy --only functions:onItemUpdatedRescan
 */

import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { defineSecret } from 'firebase-functions/params';
import { handleItemCreated } from '../ai-pipeline/gemini';

const serpApiKey = defineSecret('SERPAPI_KEY');

export const onItemUpdatedRescan = onDocumentUpdated(
  {
    document: 'items/{itemId}',
    secrets: [serpApiKey],
    region: 'us-central1',
    memory: '512MiB',
    timeoutSeconds: 120,
  },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();

    if (!before || !after) {
      console.error('onItemUpdatedRescan: No document data');
      return;
    }

    // Guard: Only process status transitions to pending (rescan requests)
    if (after.status !== 'pending') return;
    if (before.status === 'pending') return; // Already processing
    if (after.deepScanRequested === true) return; // Handled by onItemUpdatedDeepScan

    console.log(`onItemUpdatedRescan: Rescan triggered for item ${event.params.itemId}`);

    // SERPAPI_KEY needed for Google Lens tool
    process.env.SERPAPI_KEY = serpApiKey.value();

    await handleItemCreated(event.data!.after, {
      params: { itemId: event.params.itemId },
    });
  }
);
