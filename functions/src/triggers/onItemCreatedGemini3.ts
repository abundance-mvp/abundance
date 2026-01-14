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
 */

import * as functions from 'firebase-functions/v2/firestore';
import { handleItemCreated } from '../ai-pipeline/gemini';

export const onItemCreatedGemini3 = functions.onDocumentCreated(
  'items/{itemId}',
  async (event) => {
    if (!event.data) {
      console.error('onItemCreatedGemini3: No document data');
      return;
    }

    await handleItemCreated(event.data, {
      params: { itemId: event.params.itemId }
    });
  }
);
