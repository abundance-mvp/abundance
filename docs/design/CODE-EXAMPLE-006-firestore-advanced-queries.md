# CODE-EXAMPLE-006: Firestore Advanced Queries

**Created**: 2025-11-10
**Stage**: 3.2 - Backend Implementation Research
**References**: CLOUD-FUNCTIONS-001, RESEARCH-VALIDATION-stage-3.2, CODE-EXAMPLE-005
**Status**: Complete

## Overview

Production-ready patterns for Firestore queries in the Abundance app backend. Covers composite indexes, pagination, batch operations, transactions, and query optimization strategies verified against Cloud Firestore documentation.

## 1. Composite Index Queries

### firestore.indexes.json

```json
{
  "indexes": [
    {
      "collectionGroup": "items",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "items",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "items",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "category", "order": "ASCENDING" },
        { "fieldPath": "estimatedValue", "order": "DESCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```

### Query Implementation

```javascript
const admin = require('firebase-admin');
const firestore = admin.firestore();

/**
 * Fetch user's items sorted by creation date (newest first)
 * Requires composite index: userId ASC + createdAt DESC
 *
 * @param {string} userId - Firebase Auth UID
 * @param {number} limit - Max results (default 20)
 * @returns {Promise<Array>} Array of item objects
 */
async function getUserItemsLatest(userId, limit = 20) {
  try {
    const snapshot = await firestore
      .collection('items')
      .where('userId', '==', userId)
      .orderBy('createdAt', 'desc')
      .limit(limit)
      .get();

    return snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
  } catch (error) {
    console.error({
      severity: 'ERROR',
      message: 'getUserItemsLatest failed',
      userId,
      error: error.message
    });
    throw error;
  }
}

/**
 * Fetch items by status (e.g., "processing", "complete", "failed")
 * Requires composite index: userId ASC + status ASC + createdAt DESC
 *
 * @param {string} userId - Firebase Auth UID
 * @param {string} status - Item status filter
 * @param {number} limit - Max results
 * @returns {Promise<Array>} Filtered items
 */
async function getUserItemsByStatus(userId, status, limit = 50) {
  try {
    const snapshot = await firestore
      .collection('items')
      .where('userId', '==', userId)
      .where('status', '==', status)
      .orderBy('createdAt', 'desc')
      .limit(limit)
      .get();

    return snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
  } catch (error) {
    console.error({
      severity: 'ERROR',
      message: 'getUserItemsByStatus failed',
      userId,
      status,
      error: error.message
    });
    throw error;
  }
}

/**
 * Fetch items by category, sorted by estimated value
 * Requires composite index: userId ASC + category ASC + estimatedValue DESC
 *
 * @param {string} userId - Firebase Auth UID
 * @param {string} category - Item category (e.g., "Electronics")
 * @param {number} limit - Max results
 * @returns {Promise<Array>} Items sorted by value
 */
async function getItemsByCategory(userId, category, limit = 20) {
  try {
    const snapshot = await firestore
      .collection('items')
      .where('userId', '==', userId)
      .where('category', '==', category)
      .orderBy('estimatedValue', 'desc')
      .limit(limit)
      .get();

    return snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
  } catch (error) {
    console.error({
      severity: 'ERROR',
      message: 'getItemsByCategory failed',
      userId,
      category,
      error: error.message
    });
    throw error;
  }
}
```

## 2. Cursor-Based Pagination

```javascript
/**
 * Fetch paginated items using cursor (startAfter)
 * Supports infinite scroll in iOS app
 *
 * @param {string} userId - Firebase Auth UID
 * @param {DocumentSnapshot|null} lastDocSnapshot - Last document from previous page
 * @param {number} pageSize - Items per page (default 20)
 * @returns {Promise<{items: Array, lastDoc: DocumentSnapshot}>}
 */
async function getItemsPaginated(userId, lastDocSnapshot = null, pageSize = 20) {
  try {
    let query = firestore
      .collection('items')
      .where('userId', '==', userId)
      .orderBy('createdAt', 'desc')
      .limit(pageSize);

    // If cursor provided, start after last document
    if (lastDocSnapshot) {
      query = query.startAfter(lastDocSnapshot);
    }

    const snapshot = await query.get();

    const items = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    // Return last document for next page
    const lastDoc = snapshot.docs[snapshot.docs.length - 1];

    return {
      items,
      lastDoc,
      hasMore: snapshot.docs.length === pageSize
    };
  } catch (error) {
    console.error({
      severity: 'ERROR',
      message: 'getItemsPaginated failed',
      userId,
      error: error.message
    });
    throw error;
  }
}

/**
 * Example: Cloud Function HTTP endpoint for pagination
 */
const functions = require('firebase-functions');

exports.listItems = functions.https.onRequest(async (req, res) => {
  try {
    const userId = req.user.uid; // From auth middleware
    const pageSize = parseInt(req.query.pageSize) || 20;
    const cursorId = req.query.cursor; // Document ID from previous page

    let lastDocSnapshot = null;
    if (cursorId) {
      lastDocSnapshot = await firestore.collection('items').doc(cursorId).get();
    }

    const result = await getItemsPaginated(userId, lastDocSnapshot, pageSize);

    res.json({
      items: result.items,
      nextCursor: result.lastDoc ? result.lastDoc.id : null,
      hasMore: result.hasMore
    });
  } catch (error) {
    console.error({
      severity: 'ERROR',
      message: 'listItems endpoint failed',
      error: error.message
    });
    res.status(500).json({ error: 'Internal server error' });
  }
});
```

## 3. Batch Write Operations

```javascript
/**
 * Batch update multiple items (max 500 documents per batch)
 * All writes succeed or fail atomically
 *
 * @param {Array<string>} itemIds - Item document IDs
 * @param {Object} updates - Fields to update
 * @returns {Promise<void>}
 */
async function batchUpdateItems(itemIds, updates) {
  try {
    // Firestore batch limit: 500 operations
    if (itemIds.length > 500) {
      throw new Error('Batch size exceeds 500 documents');
    }

    const batch = firestore.batch();

    itemIds.forEach(itemId => {
      const itemRef = firestore.collection('items').doc(itemId);
      batch.update(itemRef, {
        ...updates,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    });

    await batch.commit();

    console.log({
      severity: 'INFO',
      message: 'Batch update completed',
      itemCount: itemIds.length,
      updates
    });
  } catch (error) {
    console.error({
      severity: 'ERROR',
      message: 'batchUpdateItems failed',
      itemCount: itemIds.length,
      error: error.message
    });
    throw error;
  }
}

/**
 * Batch delete items (for bulk operations)
 *
 * @param {string} userId - Firebase Auth UID (for security)
 * @param {Array<string>} itemIds - Item document IDs to delete
 * @returns {Promise<void>}
 */
async function batchDeleteItems(userId, itemIds) {
  try {
    if (itemIds.length > 500) {
      throw new Error('Batch size exceeds 500 documents');
    }

    const batch = firestore.batch();

    // Verify ownership before deleting
    const verifyPromises = itemIds.map(itemId =>
      firestore.collection('items').doc(itemId).get()
    );
    const docs = await Promise.all(verifyPromises);

    docs.forEach((doc, index) => {
      if (!doc.exists) {
        throw new Error(`Item ${itemIds[index]} not found`);
      }
      if (doc.data().userId !== userId) {
        throw new Error(`Unauthorized: Item ${itemIds[index]} does not belong to user`);
      }
      batch.delete(doc.ref);
    });

    await batch.commit();

    console.log({
      severity: 'INFO',
      message: 'Batch delete completed',
      userId,
      itemCount: itemIds.length
    });
  } catch (error) {
    console.error({
      severity: 'ERROR',
      message: 'batchDeleteItems failed',
      userId,
      itemCount: itemIds.length,
      error: error.message
    });
    throw error;
  }
}

/**
 * Example: Mark all processing items as failed (cleanup job)
 */
async function cleanupStaleProcessingItems(maxAgeHours = 24) {
  try {
    const cutoffTime = new Date(Date.now() - maxAgeHours * 60 * 60 * 1000);

    const snapshot = await firestore
      .collection('items')
      .where('status', '==', 'processing')
      .where('createdAt', '<', cutoffTime)
      .limit(500)
      .get();

    if (snapshot.empty) {
      console.log('No stale items found');
      return;
    }

    const batch = firestore.batch();
    snapshot.docs.forEach(doc => {
      batch.update(doc.ref, {
        status: 'failed',
        error: 'Processing timeout',
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    });

    await batch.commit();

    console.log({
      severity: 'INFO',
      message: 'Cleaned up stale processing items',
      count: snapshot.docs.length,
      maxAgeHours
    });
  } catch (error) {
    console.error({
      severity: 'ERROR',
      message: 'cleanupStaleProcessingItems failed',
      error: error.message
    });
    throw error;
  }
}
```

## 4. Transactions (Read-Modify-Write)

```javascript
/**
 * Increment user's item count atomically
 * Uses transaction to avoid race conditions
 *
 * @param {string} userId - Firebase Auth UID
 * @returns {Promise<number>} New item count
 */
async function incrementUserItemCount(userId) {
  const userRef = firestore.collection('users').doc(userId);

  try {
    const newCount = await firestore.runTransaction(async (transaction) => {
      const userDoc = await transaction.get(userRef);

      if (!userDoc.exists) {
        throw new Error('User document not found');
      }

      const currentCount = userDoc.data().itemCount || 0;
      const newCount = currentCount + 1;

      transaction.update(userRef, {
        itemCount: newCount,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });

      return newCount;
    });

    console.log({
      severity: 'INFO',
      message: 'User item count incremented',
      userId,
      newCount
    });

    return newCount;
  } catch (error) {
    console.error({
      severity: 'ERROR',
      message: 'incrementUserItemCount failed',
      userId,
      error: error.message
    });
    throw error;
  }
}

/**
 * Decrement user's item count atomically (when item deleted)
 *
 * @param {string} userId - Firebase Auth UID
 * @returns {Promise<number>} New item count
 */
async function decrementUserItemCount(userId) {
  const userRef = firestore.collection('users').doc(userId);

  try {
    const newCount = await firestore.runTransaction(async (transaction) => {
      const userDoc = await transaction.get(userRef);

      if (!userDoc.exists) {
        throw new Error('User document not found');
      }

      const currentCount = userDoc.data().itemCount || 0;
      const newCount = Math.max(0, currentCount - 1); // Prevent negative

      transaction.update(userRef, {
        itemCount: newCount,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });

      return newCount;
    });

    console.log({
      severity: 'INFO',
      message: 'User item count decremented',
      userId,
      newCount
    });

    return newCount;
  } catch (error) {
    console.error({
      severity: 'ERROR',
      message: 'decrementUserItemCount failed',
      userId,
      error: error.message
    });
    throw error;
  }
}

/**
 * Update item with retry logic (for contention scenarios)
 * Firestore automatically retries transactions up to 5 times
 *
 * @param {string} itemId - Item document ID
 * @param {Object} updates - Fields to update
 * @returns {Promise<Object>} Updated item data
 */
async function updateItemWithTransaction(itemId, updates) {
  const itemRef = firestore.collection('items').doc(itemId);

  try {
    const updatedData = await firestore.runTransaction(async (transaction) => {
      const itemDoc = await transaction.get(itemRef);

      if (!itemDoc.exists) {
        throw new Error('Item not found');
      }

      const currentData = itemDoc.data();
      const newData = {
        ...currentData,
        ...updates,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      };

      transaction.update(itemRef, newData);

      return newData;
    });

    console.log({
      severity: 'INFO',
      message: 'Item updated via transaction',
      itemId
    });

    return updatedData;
  } catch (error) {
    console.error({
      severity: 'ERROR',
      message: 'updateItemWithTransaction failed',
      itemId,
      error: error.message
    });
    throw error;
  }
}
```

## 5. Query Optimization Patterns

### Avoid Full Collection Scans

```javascript
/**
 * BAD: Full collection scan (no where clause)
 * This will fail in production when collection > 1000 docs
 */
async function getAllItemsBad() {
  // DON'T DO THIS
  const snapshot = await firestore.collection('items').get();
  return snapshot.docs.map(doc => doc.data());
}

/**
 * GOOD: Always filter by userId
 * Requires index: userId ASC + createdAt DESC
 */
async function getAllItemsGood(userId) {
  const snapshot = await firestore
    .collection('items')
    .where('userId', '==', userId)
    .orderBy('createdAt', 'desc')
    .limit(1000) // Hard limit for safety
    .get();

  return snapshot.docs.map(doc => ({
    id: doc.id,
    ...doc.data()
  }));
}
```

### Use .limit() for All Queries

```javascript
/**
 * Always specify limit to prevent excessive reads
 * Cloud Firestore charges per document read
 */
async function safeQuery(userId) {
  const snapshot = await firestore
    .collection('items')
    .where('userId', '==', userId)
    .limit(100) // Explicit limit prevents runaway costs
    .get();

  console.log({
    severity: 'INFO',
    message: 'Query executed',
    documentsRead: snapshot.size,
    userId
  });

  return snapshot.docs.map(doc => doc.data());
}
```

### Prefer Specific Fields Over Full Documents

```javascript
/**
 * Fetch only required fields (reduces bandwidth)
 * Note: Firestore charges same per-document read regardless of fields
 * But smaller payloads improve network performance
 */
async function getItemSummaries(userId) {
  const snapshot = await firestore
    .collection('items')
    .where('userId', '==', userId)
    .select('name', 'category', 'estimatedValue', 'createdAt')
    .limit(50)
    .get();

  return snapshot.docs.map(doc => ({
    id: doc.id,
    ...doc.data()
  }));
}
```

### Use CollectionGroup for Global Queries

```javascript
/**
 * Query across all items in subcollections
 * Requires collectionGroup index
 */
async function searchAllUserCollections(userId) {
  const snapshot = await firestore
    .collectionGroup('items') // Global query across all 'items' subcollections
    .where('userId', '==', userId)
    .where('status', '==', 'complete')
    .limit(100)
    .get();

  return snapshot.docs.map(doc => ({
    id: doc.id,
    path: doc.ref.path, // Full document path
    ...doc.data()
  }));
}
```

## 6. Index Deployment

### Deploy indexes to Firebase

```bash
# Deploy indexes to production
firebase deploy --only firestore:indexes --project abundance-prod

# Verify index status in Firebase Console
# https://console.firebase.google.com/project/abundance-prod/firestore/indexes
```

### Monitor Index Build Progress

```javascript
/**
 * Cloud Function: Check if required indexes exist
 * Run before deploying new query patterns
 */
exports.checkIndexes = functions.https.onRequest(async (req, res) => {
  try {
    // Attempt query that requires composite index
    const testQuery = await firestore
      .collection('items')
      .where('userId', '==', 'test')
      .orderBy('createdAt', 'desc')
      .limit(1)
      .get();

    res.json({
      status: 'OK',
      message: 'Required indexes exist',
      documentsRead: testQuery.size
    });
  } catch (error) {
    if (error.code === 9) {
      res.status(500).json({
        status: 'ERROR',
        message: 'Missing index',
        indexUrl: error.message // Firebase provides index creation URL
      });
    } else {
      res.status(500).json({ error: error.message });
    }
  }
});
```

## Cross-References

- **CODE-EXAMPLE-005**: See Cloud Functions HTTP endpoint patterns
- **CODE-EXAMPLE-007**: See how queries integrate with AI pipeline
- **TEST-EXAMPLE-003**: See unit tests for these query patterns
- **INFRASTRUCTURE-001**: See index deployment automation
- **RESEARCH-VALIDATION-stage-3.2**: Verified Firestore pricing model (per-document reads)

## Notes

- All queries use `async/await` (Node.js 20+)
- Composite indexes deployed via `firestore.indexes.json`
- Pagination uses cursor-based approach (better than offset/skip)
- Transactions automatically retry up to 5 times
- Batch operations limited to 500 documents per commit
- Always include `.limit()` to prevent excessive read costs
- Structured logging for all query operations
