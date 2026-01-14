/**
 * Firestore Trigger: Process new items with Gemini 3 Pro
 *
 * Triggers when item document is created with status="pending"
 * Calls Gemini 3 Pro with tool calling for:
 * - Visual analysis
 * - Barcode lookup
 * - Google Lens search
 * - Web search for pricing
 *
 * Replaces: onItemCreated (old 4-layer pipeline)
 *
 * Authentication:
 * - Vertex AI: Uses Application Default Credentials (service account)
 * - SERPAPI_KEY: Required for Google Lens visual search
 *
 * Deploy: firebase deploy --only functions:onItemCreatedGemini3
 */

import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { defineSecret } from 'firebase-functions/params';
import { handleItemCreated } from '../ai-pipeline/gemini';

// Define secrets for 2nd gen Cloud Functions
// GOOGLE_API_KEY no longer needed - Vertex AI uses ADC
const serpApiKey = defineSecret('SERPAPI_KEY');

export const onItemCreatedGemini3 = onDocumentCreated(
  {
    document: 'items/{itemId}',
    secrets: [serpApiKey],
    region: 'us-central1',
    memory: '512MiB',
    timeoutSeconds: 120,
  },
  async (event) => {
    if (!event.data) {
      console.error('onItemCreatedGemini3: No document data');
      return;
    }

    // SERPAPI_KEY still needed for Google Lens tool
    process.env.SERPAPI_KEY = serpApiKey.value();

    // GOOGLE_CLOUD_PROJECT is automatically set in Cloud Functions
    // GOOGLE_CLOUD_LOCATION defaults to 'global' in vertexai-config.ts

    await handleItemCreated(event.data, {
      params: { itemId: event.params.itemId },
    });
  }
);
