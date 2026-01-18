/**
 * Backfill Migration: Flatten existing item catalog data
 *
 * Run once to migrate existing items from nested `catalog` field
 * to flattened top-level fields.
 *
 * Usage: firebase functions:call backfillFlattenedSchema --data '{}'
 */

import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions/v1';

interface CatalogItem {
  name: string;
  category: string;
  subCategory: string;
  brand: string | null;
  model: string | null;
  color: string;
  condition: string;
  dimensions: string | null;
  quantity: number;
  estimatedValue: number | null;
  confidence: string;
}

export const backfillFlattenedSchema = functions.https.onCall(async (data, context) => {
  // Require admin authentication
  if (!context.auth?.token.admin) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Admin access required for migration'
    );
  }

  const db = admin.firestore();
  const batchSize = 100;
  let totalMigrated = 0;
  let totalSkipped = 0;
  let lastDoc: admin.firestore.QueryDocumentSnapshot | undefined;

  console.log('[Migration] Starting backfill of flattened schema');

  while (true) {
    let query = db.collection('items')
      .where('catalog', '!=', null)
      .limit(batchSize);

    if (lastDoc) {
      query = query.startAfter(lastDoc);
    }

    const snapshot = await query.get();

    if (snapshot.empty) {
      break;
    }

    const batch = db.batch();
    let batchCount = 0;

    for (const doc of snapshot.docs) {
      const docData = doc.data();
      const catalog = docData.catalog as CatalogItem | CatalogItem[];

      // Handle both single item and array formats
      const catalogItem = Array.isArray(catalog) ? catalog[0] : catalog;

      if (!catalogItem) continue;

      // Skip if already migrated (has name field)
      if (docData.name) {
        totalSkipped++;
        continue;
      }

      batch.update(doc.ref, {
        name: catalogItem.name,
        category: catalogItem.category,
        subCategory: catalogItem.subCategory,
        brand: catalogItem.brand ?? null,
        model: catalogItem.model ?? null,
        color: catalogItem.color,
        condition: catalogItem.condition,
        dimensions: catalogItem.dimensions ?? null,
        quantity: catalogItem.quantity ?? 1,
        estimatedValue: catalogItem.estimatedValue ?? null,
        confidence: catalogItem.confidence,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });

      batchCount++;
      totalMigrated++;
    }

    if (batchCount > 0) {
      await batch.commit();
    }

    lastDoc = snapshot.docs[snapshot.docs.length - 1];

    console.log(`[Migration] Progress: ${totalMigrated} migrated, ${totalSkipped} skipped`);
  }

  console.log(`[Migration] Complete. Total migrated: ${totalMigrated}, skipped: ${totalSkipped}`);

  return {
    success: true,
    migratedCount: totalMigrated,
    skippedCount: totalSkipped
  };
});
