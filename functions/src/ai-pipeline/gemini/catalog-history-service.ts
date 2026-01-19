/**
 * Catalog History Service
 *
 * Service for managing catalog history in Firestore.
 * Enables session persistence by storing and retrieving previous catalog results.
 */

import { getFirestore, FieldValue, CollectionReference } from 'firebase-admin/firestore';
import {
  CatalogHistoryEntry,
  ToolCallRecord,
  CatalogResultSnapshot,
  CatalogMetadata
} from './schemas/catalog-history';
import { CatalogItem } from './schemas/catalog-item';

const HISTORY_COLLECTION = 'catalogHistory';
const MAX_HISTORY_ENTRIES = 10; // Keep last 10 entries per item (matches SPEC-PIPE-003)

/**
 * Input for saving a catalog history entry (without auto-generated fields)
 */
export interface SaveCatalogHistoryInput {
  model: string;
  imageUrls: string[];
  toolCalls: ToolCallRecord[];
  result: CatalogResultSnapshot;
  metadata: CatalogMetadata;
}

/**
 * Save a catalog result to history.
 *
 * @param itemId - The item document ID
 * @param entry - The history entry to save (without id and catalogedAt)
 * @returns The saved entry ID
 */
export async function saveCatalogHistory(
  itemId: string,
  entry: SaveCatalogHistoryInput
): Promise<string> {
  const db = getFirestore();
  const historyRef = db
    .collection('items')
    .doc(itemId)
    .collection(HISTORY_COLLECTION);

  // Add new entry with server timestamp
  const docRef = await historyRef.add({
    ...entry,
    catalogedAt: FieldValue.serverTimestamp()
  });

  // Cleanup old entries (keep only MAX_HISTORY_ENTRIES)
  await cleanupOldEntries(historyRef);

  return docRef.id;
}

/**
 * Get the most recent catalog history for an item.
 *
 * @param itemId - The item document ID
 * @param limit - Maximum entries to retrieve (default: 1)
 * @returns Array of history entries, newest first
 */
export async function getRecentCatalogHistory(
  itemId: string,
  limit: number = 1
): Promise<CatalogHistoryEntry[]> {
  const db = getFirestore();
  const snapshot = await db
    .collection('items')
    .doc(itemId)
    .collection(HISTORY_COLLECTION)
    .orderBy('catalogedAt', 'desc')
    .limit(limit)
    .get();

  return snapshot.docs.map(doc => ({
    id: doc.id,
    ...doc.data()
  } as CatalogHistoryEntry));
}

/**
 * Convert a CatalogItem to a CatalogResultSnapshot for storage.
 */
export function catalogItemToSnapshot(item: CatalogItem): CatalogResultSnapshot {
  return {
    name: item.name,
    brand: item.brand ?? null,
    model: item.model ?? null,
    category: item.category,
    subCategory: item.subCategory ?? null,
    confidence: item.confidence ?? 'medium',
    estimatedValue: item.estimatedValue ?? null,
    condition: item.condition ?? null
  };
}

/**
 * Format previous catalog history for inclusion in prompt.
 */
export function formatHistoryForPrompt(history: CatalogHistoryEntry[]): string {
  if (history.length === 0) {
    return '';
  }

  const latest = history[0];
  const result = latest.result;

  const lines = [
    'PREVIOUS CATALOG INFORMATION:',
    'This item was previously cataloged with the following information:',
    `- Name: ${result.name}`,
    `- Brand: ${result.brand || 'Unknown'}`,
    `- Model: ${result.model || 'Unknown'}`,
    `- Category: ${result.category}`,
    `- Confidence: ${result.confidence}`
  ];

  if (result.estimatedValue) {
    lines.push(`- Estimated Value: $${result.estimatedValue}`);
  }
  if (result.condition) {
    lines.push(`- Condition: ${result.condition}`);
  }

  lines.push('');
  lines.push('Previous tool calls:');
  for (const tc of latest.toolCalls) {
    lines.push(`- ${tc.name}: ${tc.success ? 'Success' : 'Failed'}`);
  }

  lines.push('');
  lines.push('Use this context to maintain consistency. If new images provide clearer information,');
  lines.push('you may update the identification, but explain why in your reasoning.');

  return lines.join('\n');
}

/**
 * Remove old history entries beyond MAX_HISTORY_ENTRIES.
 */
async function cleanupOldEntries(
  historyRef: CollectionReference
): Promise<void> {
  const snapshot = await historyRef
    .orderBy('catalogedAt', 'desc')
    .offset(MAX_HISTORY_ENTRIES)
    .get();

  if (snapshot.docs.length === 0) {
    return;
  }

  const batch = getFirestore().batch();
  for (const doc of snapshot.docs) {
    batch.delete(doc.ref);
  }

  await batch.commit();
}
