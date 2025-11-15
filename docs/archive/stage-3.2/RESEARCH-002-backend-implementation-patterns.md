# Backend Implementation Patterns - Cloud Functions, Firestore, Vertex AI

**Created**: 2025-11-10
**Stage**: 3.2 - Backend Implementation Research
**Status**: Complete
**References**:
- docs/validation/RESEARCH-VALIDATION-stage-3.2.md (18 claims verified)
- docs/plans/2025-11-10-stage-3.2-backend-implementation-research.md
- docs/tech-stack/TECH-STACK-MAP-001-abundance-tech-stack.md

---

## Table of Contents

1. [Cloud Functions Best Practices](#cloud-functions-best-practices)
2. [Firestore Data Modeling Patterns](#firestore-data-modeling-patterns)
3. [Firebase Storage Integration](#firebase-storage-integration)
4. [Vertex AI Integration](#vertex-ai-integration)
5. [GCP Observability](#gcp-observability)
6. [Firebase Emulator Suite](#firebase-emulator-suite)

---

## Cloud Functions Best Practices

### Runtime: Node.js 20

**Verified**: Node.js 20 is production-ready (GA status) with faster cold starts than Python 3.11.

**Cold Start Performance**:
- Node.js 20: 200-1200ms
- Python 3.11: 300-1500ms

**Why Node.js 20**:
- Superior npm package ecosystem for Firebase/GCP integration
- Faster cold starts (critical for user-facing endpoints)
- Production-ready (GA), Node.js 18 deprecated
- Better async/await support with native TypeScript compilation

**Source**: cloud.google.com/functions/docs/concepts/nodejs-runtime

---

### HTTP Trigger Pattern

**Use Case**: REST API endpoints called by iOS client

**Pattern**: Express.js-style HTTP function handler

```typescript
import {onRequest} from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

export const analyzeItem = onRequest({
  cors: true,  // Enable CORS for iOS client
  memory: '256MiB',  // Minimum recommended (128MB insufficient)
  region: 'us-central1'
}, async (req, res) => {
  try {
    // 1. Verify Firebase Auth token
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({error: 'Unauthorized'});
    }

    const token = authHeader.split('Bearer ')[1];
    const decodedToken = await admin.auth().verifyIdToken(token);
    const userId = decodedToken.uid;

    // 2. Validate request body
    const {itemId, croppedImageUrl} = req.body;
    if (!itemId || !croppedImageUrl) {
      return res.status(400).json({error: 'Missing required fields: itemId, croppedImageUrl'});
    }

    // 3. Update Firestore (trigger downstream processing)
    await admin.firestore().collection('items').doc(itemId).update({
      status: 'processing',
      userId,
      croppedImageUrl,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // 4. Return 202 Accepted (async processing)
    return res.status(202).json({
      message: 'Analysis started',
      itemId,
      status: 'processing'
    });

  } catch (error) {
    console.error('Error in analyzeItem:', error);
    return res.status(500).json({error: 'Internal server error'});
  }
});
```

**Key Patterns**:
- **CORS enabled**: `cors: true` for iOS client access
- **Firebase Auth token verification**: Middleware pattern for authentication
- **Request validation**: Check required fields before processing
- **Async processing**: Return 202 Accepted immediately, process in background via Firestore trigger
- **Error handling**: try/catch with structured error responses

---

### Firestore Trigger Pattern

**Use Case**: Background processing triggered by Firestore document changes

**Pattern**: Document lifecycle triggers (onCreate, onUpdate, onDelete)

```typescript
import {onDocumentCreated, onDocumentUpdated} from 'firebase-functions/v2/firestore';
import {VertexAI} from '@google-cloud/vertexai';
import * as admin from 'firebase-admin';

// Trigger: onItemCreated (Layer 2a: Gemini attribute extraction)
export const onItemCreated = onDocumentCreated({
  document: 'items/{itemId}',
  region: 'us-central1',
  memory: '256MiB'
}, async (event) => {
  try {
    const itemId = event.params.itemId;
    const itemData = event.data?.data();

    if (!itemData) {
      console.error(`Item ${itemId} has no data`);
      return;
    }

    // 1. Avoid infinite loops (check if already processed)
    if (itemData.status !== 'processing') {
      console.log(`Item ${itemId} not in processing state (${itemData.status}), skipping`);
      return;
    }

    // 2. Call Vertex AI Gemini (Layer 2a)
    const attributes = await extractAttributes(itemData.croppedImageUrl);

    // 3. Update Firestore (trigger downstream Layer 2b)
    await event.data?.ref.update({
      status: 'layer2a_complete',
      layer2a: {
        attributes,
        timestamp: Date.now(),
        model: 'gemini-2.5-flash-lite'
      },
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    console.log(`Layer 2a complete for item ${itemId}`, attributes);

  } catch (error) {
    console.error(`Error in onItemCreated for item ${event.params.itemId}:`, error);

    // Mark item as failed
    await event.data?.ref.update({
      status: 'failed',
      error: {
        message: error instanceof Error ? error.message : 'Unknown error',
        timestamp: Date.now(),
        layer: '2a'
      }
    });
  }
});

// Trigger: onLayer2aComplete (Layer 2b: SerpAPI product identification)
export const onLayer2aComplete = onDocumentUpdated({
  document: 'items/{itemId}',
  region: 'us-central1',
  memory: '256MiB'
}, async (event) => {
  try {
    const itemId = event.params.itemId;
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();

    if (!afterData) {
      console.error(`Item ${itemId} has no data after update`);
      return;
    }

    // 1. Check if this is the Layer 2a → 2b transition
    if (beforeData?.status !== 'processing' || afterData.status !== 'layer2a_complete') {
      console.log(`Item ${itemId} not transitioning to Layer 2b, skipping`);
      return;
    }

    // 2. Generate signed URL for SerpAPI (1-hour expiration)
    const signedUrl = await generatePublicUrl(afterData.croppedImageUrl);

    // 3. Call SerpAPI Google Lens
    const productInfo = await searchProduct(signedUrl);

    // 4. Update Firestore (trigger downstream Layer 3)
    await event.data?.after.ref.update({
      status: 'layer2b_complete',
      layer2b: {
        product: productInfo,
        timestamp: Date.now(),
        provider: 'serpapi'
      },
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    console.log(`Layer 2b complete for item ${itemId}`, productInfo);

  } catch (error) {
    console.error(`Error in onLayer2aComplete for item ${event.params.itemId}:`, error);

    // Mark item as failed
    await event.data?.after.ref.update({
      status: 'failed',
      error: {
        message: error instanceof Error ? error.message : 'Unknown error',
        timestamp: Date.now(),
        layer: '2b'
      }
    });
  }
});
```

**Key Patterns**:
- **Avoid infinite loops**: Check status transitions before processing
- **Access document data**: `event.data.data()` for onCreate, `event.data.before.data()` / `event.data.after.data()` for onUpdate
- **Update document reference**: `event.data.ref.update(...)` for onCreate, `event.data.after.ref.update(...)` for onUpdate
- **Error handling**: Mark item as failed with error details in Firestore

---

### Scheduled Job Pattern

**Use Case**: Periodic maintenance tasks (cleanup, renewals, backups)

**Pattern**: Cloud Scheduler cron job

```typescript
import {onSchedule} from 'firebase-functions/v2/scheduler';
import * as admin from 'firebase-admin';

// Scheduled job: cleanupDeletedItems (daily 2am UTC)
export const cleanupDeletedItems = onSchedule({
  schedule: '0 2 * * *',  // Cron: daily at 2am UTC
  timeZone: 'UTC',
  region: 'us-central1',
  memory: '256MiB'
}, async (event) => {
  try {
    const ninetyDaysAgo = Date.now() - (90 * 24 * 60 * 60 * 1000);

    // 1. Query soft-deleted items older than 90 days
    const snapshot = await admin.firestore().collection('items')
      .where('deletedAt', '<', ninetyDaysAgo)
      .limit(500)  // Batch size limit
      .get();

    if (snapshot.empty) {
      console.log('No items to cleanup');
      return;
    }

    // 2. Batch delete Firestore documents (up to 500)
    const batch = admin.firestore().batch();
    snapshot.docs.forEach(doc => {
      batch.delete(doc.ref);
    });
    await batch.commit();

    // 3. Delete associated Cloud Storage files
    const bucket = admin.storage().bucket();
    for (const doc of snapshot.docs) {
      const itemId = doc.id;
      const [files] = await bucket.getFiles({prefix: `items/${itemId}/`});
      await Promise.all(files.map(file => file.delete()));
    }

    console.log(`Cleaned up ${snapshot.size} items and associated files`);

  } catch (error) {
    console.error('Error in cleanupDeletedItems:', error);
    // Alert monitoring (errors logged to Cloud Logging)
  }
});

// Scheduled job: checkSubscriptionExpiry (daily 6am UTC)
export const checkSubscriptionExpiry = onSchedule({
  schedule: '0 6 * * *',  // Cron: daily at 6am UTC
  timeZone: 'UTC',
  region: 'us-central1',
  memory: '256MiB'
}, async (event) => {
  try {
    const now = Date.now();

    // 1. Query expired subscriptions
    const snapshot = await admin.firestore().collection('subscriptions')
      .where('status', '==', 'active')
      .where('expiresAt', '<', now)
      .limit(500)
      .get();

    if (snapshot.empty) {
      console.log('No expired subscriptions');
      return;
    }

    // 2. Batch update subscriptions to expired status
    const batch = admin.firestore().batch();
    snapshot.docs.forEach(doc => {
      batch.update(doc.ref, {
        status: 'expired',
        expiredAt: admin.firestore.FieldValue.serverTimestamp()
      });
    });
    await batch.commit();

    // 3. Update user custom claims (remove premium status)
    for (const doc of snapshot.docs) {
      const userId = doc.data().userId;
      await admin.auth().setCustomUserClaims(userId, {premium: false});
    }

    console.log(`Expired ${snapshot.size} subscriptions`);

  } catch (error) {
    console.error('Error in checkSubscriptionExpiry:', error);
  }
});
```

**Key Patterns**:
- **Cron syntax**: `0 2 * * *` = daily at 2am UTC
- **Batch operations**: Process up to 500 documents per batch (Firestore limit)
- **Idempotency**: Safe to run multiple times (query filters prevent duplicate processing)
- **Cloud Storage cleanup**: Delete associated files when deleting Firestore documents

---

### Cold Start Optimization

**Verified**: 256MB memory minimum recommended (128MB insufficient)

**Strategy 1: Use 256MB Memory Minimum**

```typescript
export const analyzeItem = onRequest({
  memory: '256MiB',  // Minimum recommended for production
  cors: true
}, async (req, res) => {
  // Function implementation
});
```

**Why 256MB**:
- 128MB causes memory pressure during Node.js initialization
- 256MB allows efficient dependency loading (firebase-admin, @google-cloud/vertexai)
- Cold start improvement: 200-400ms faster than 128MB

**Strategy 2: Minimize Dependencies**

```json
// package.json - only essential dependencies
{
  "dependencies": {
    "firebase-admin": "^12.0.0",
    "firebase-functions": "^5.0.0",
    "@google-cloud/vertexai": "^1.0.0",
    "axios": "^1.6.0"
  }
}
```

**Avoid**:
- ❌ Lodash (use native JavaScript methods)
- ❌ Moment.js (use native Date or date-fns)
- ❌ Large utility libraries (bundle size bloat)

**Strategy 3: Use 2nd Gen Cloud Functions**

```typescript
// v2 imports (2nd gen, faster cold starts)
import {onRequest} from 'firebase-functions/v2/https';
import {onDocumentCreated} from 'firebase-functions/v2/firestore';

// ❌ Avoid v1 imports
// const functions = require('firebase-functions');
```

**2nd Gen Benefits**:
- Faster cold starts: 200-1200ms (vs v1: 500-2000ms)
- Better memory management
- Improved concurrency handling

**Strategy 4: Keep Functions Focused**

✅ **Good** (single responsibility):
```typescript
export const onItemCreated = onDocumentCreated('items/{itemId}', async (event) => {
  // Only Layer 2a processing
  await extractAttributes(...);
});

export const onLayer2aComplete = onDocumentUpdated('items/{itemId}', async (event) => {
  // Only Layer 2b processing
  await searchProduct(...);
});
```

❌ **Bad** (monolithic, large bundle):
```typescript
export const processItem = onDocumentCreated('items/{itemId}', async (event) => {
  // Layer 2a + 2b + 3 in one function (large bundle, slow cold start)
  await extractAttributes(...);
  await searchProduct(...);
  await synthesizeMetadata(...);
});
```

**Strategy 5: Warm Critical Functions**

```typescript
// Keep warm: Ping critical HTTP endpoints every 5 minutes
export const keepWarm = onSchedule('*/5 * * * *', async (event) => {
  const endpoints = [
    'https://us-central1-abundance-prod.cloudfunctions.net/analyzeItem',
    'https://us-central1-abundance-prod.cloudfunctions.net/getItem'
  ];

  await Promise.all(endpoints.map(url =>
    fetch(url, {
      method: 'GET',
      headers: {'X-Keep-Warm': 'true'}
    }).catch(err => console.log(`Keep-warm failed for ${url}:`, err))
  ));
});
```

**Trade-off**: Costs ~$0.50/month per function (2,016 invocations/week × $0.40/million = $0.81/month)

---

## Firestore Data Modeling Patterns

### Root Collection Design

**Verified**: Root collections recommended over subcollections for Abundance MVP

**Root Collections** (recommended):
```
users/{userId}
items/{itemId}
subscriptions/{subscriptionId}
```

**Why Root Collections**:
- ✅ Maximum query flexibility (query all items across users)
- ✅ Simpler security rules (top-level access control)
- ✅ Easier pagination (consistent cursor-based pagination)
- ✅ Better for analytics (query all items for insights)

**Subcollections** (defer to Phase 2+):
```
users/{userId}/items/{itemId}  // Nested under users
```

**Why NOT Subcollections for MVP**:
- ❌ Cannot query all items at once (requires collection group query)
- ❌ More complex security rules (nested access control)
- ❌ Harder to implement global features (showcase feed, marketplace)

**Denormalization Strategy**:

```typescript
// items/{itemId} document
interface CatalogItem {
  itemId: string;
  userId: string;  // Denormalized for ownership queries
  name: string;
  category: string;
  estimatedValue: number;
  photoUrls: string[];
  aiMetadata: {
    layer1: {/* on-device Vision */};
    layer2a: {/* Gemini attributes */};
    layer2b: {/* SerpAPI product */};
    layer3: {/* Claude synthesis */};
  };
  visibility: 'private' | 'showcase' | 'shared' | 'marketplace';
  createdAt: FirebaseFirestore.Timestamp;
  updatedAt: FirebaseFirestore.Timestamp;
}

// Query: Get all items for user
const userItems = await firestore.collection('items')
  .where('userId', '==', currentUserId)
  .orderBy('createdAt', 'desc')
  .limit(20)
  .get();

// Query: Get showcase feed (all users)
const showcaseItems = await firestore.collection('items')
  .where('visibility', '==', 'showcase')
  .orderBy('createdAt', 'desc')
  .limit(50)
  .get();
```

---

### Composite Index Creation

**VERIFIED**: Composite indexes are **NOT automatic** (must be created explicitly)

**Index Creation Workflow**:

**Step 1: Run Query in Development**

```typescript
// This query REQUIRES a composite index (userId + createdAt)
const query = firestore.collection('items')
  .where('userId', '==', currentUserId)
  .orderBy('createdAt', 'desc')
  .limit(20);

const snapshot = await query.get();

// Firestore error: "The query requires an index. You can create it here: [link]"
```

**Step 2: Click Link OR Add to firestore.indexes.json**

```json
{
  "indexes": [
    {
      "collectionGroup": "items",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "userId", "order": "ASCENDING"},
        {"fieldPath": "createdAt", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "items",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "userId", "order": "ASCENDING"},
        {"fieldPath": "category", "order": "ASCENDING"},
        {"fieldPath": "createdAt", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "items",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "visibility", "order": "ASCENDING"},
        {"fieldPath": "createdAt", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "items",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "userId", "order": "ASCENDING"},
        {"fieldPath": "status", "order": "ASCENDING"},
        {"fieldPath": "createdAt", "order": "DESCENDING"}
      ]
    }
  ],
  "fieldOverrides": []
}
```

**Step 3: Deploy Indexes**

```bash
firebase deploy --only firestore:indexes
```

**Step 4: Wait for Index Creation** (5-10 minutes)

- Check Cloud Console: Firestore → Indexes
- Status: "Building" → "Ready"

**Common Composite Indexes for Abundance**:
- `userId + createdAt` → User's items, newest first
- `userId + category + createdAt` → User's items by category
- `visibility + createdAt` → Showcase feed
- `userId + status + createdAt` → User's pending items

---

### Query Optimization Patterns

**Pattern 1: Cursor-Based Pagination**

**Verified**: Avoid offset-based pagination (billed for skipped documents)

❌ **BAD** (offset-based):
```typescript
// Skips first 20 documents (BILLED even though not returned!)
const snapshot = await firestore.collection('items')
  .where('userId', '==', currentUserId)
  .orderBy('createdAt', 'desc')
  .offset(20)  // AVOID!
  .limit(20)
  .get();
```

✅ **GOOD** (cursor-based):
```typescript
// First page
const firstQuery = firestore.collection('items')
  .where('userId', '==', currentUserId)
  .orderBy('createdAt', 'desc')
  .limit(20);
const firstSnapshot = await firstQuery.get();

// Save last document for next page
const lastVisible = firstSnapshot.docs[firstSnapshot.docs.length - 1];

// Next page (use last document as cursor)
const nextQuery = firestore.collection('items')
  .where('userId', '==', currentUserId)
  .orderBy('createdAt', 'desc')
  .startAfter(lastVisible)  // Cursor!
  .limit(20);
const nextSnapshot = await nextQuery.get();
```

**Pattern 2: Efficient Filtering**

```typescript
// ✅ Good: Indexed fields first, then filter
const query = firestore.collection('items')
  .where('userId', '==', currentUserId)  // Indexed
  .where('category', '==', 'furniture')  // Indexed
  .orderBy('createdAt', 'desc')
  .limit(20);
```

**Pattern 3: Limit Query Results**

```typescript
// Always use .limit() to prevent over-fetching
const query = firestore.collection('items')
  .where('userId', '==', currentUserId)
  .orderBy('createdAt', 'desc')
  .limit(100);  // Maximum items per query
```

---

### Batch Writes and Transactions

**Batch Writes** (up to 500 operations, no reads):

```typescript
async function createMultipleItems(userId: string, items: any[]) {
  const batch = firestore.batch();

  // Create multiple items atomically
  for (const item of items) {
    const itemRef = firestore.collection('items').doc();
    batch.set(itemRef, {
      ...item,
      userId,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
  }

  // Update user's item count
  const userRef = firestore.collection('users').doc(userId);
  batch.update(userRef, {
    itemCount: admin.firestore.FieldValue.increment(items.length)
  });

  await batch.commit();  // All or nothing
}
```

**Transactions** (read-modify-write, up to 10 seconds):

```typescript
async function incrementUsageCount(subscriptionId: string) {
  await firestore.runTransaction(async (transaction) => {
    // 1. Read subscription document
    const subRef = firestore.collection('subscriptions').doc(subscriptionId);
    const subDoc = await transaction.get(subRef);

    if (!subDoc.exists) {
      throw new Error('Subscription not found');
    }

    const data = subDoc.data();
    if (data?.status !== 'active') {
      throw new Error('Subscription not active');
    }

    // 2. Modify (increment usage count)
    transaction.update(subRef, {
      usageCount: admin.firestore.FieldValue.increment(1),
      lastUsedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // 3. Create audit log
    const auditRef = firestore.collection('audit_logs').doc();
    transaction.set(auditRef, {
      subscriptionId,
      action: 'item_analyzed',
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });
  });
}
```

---

### iOS Offline Persistence

**VERIFIED**: Offline persistence is **enabled by default** (no configuration needed)

**iOS Client** (no code needed):
```swift
// Offline persistence automatically enabled
let db = Firestore.firestore()

// Writes work offline (queued until online)
db.collection("items").addDocument(data: itemData) { error in
  // Completes immediately offline, syncs when online
}

// Reads work offline (cached data returned)
db.collection("items").whereField("userId", isEqualTo: currentUserId).getDocuments { snapshot, error in
  // Returns cached data if offline
}
```

**Conflict Resolution**: Last-write-wins (Firestore default)

---

## Firebase Storage Integration

### Upload Patterns from Cloud Functions

**Pattern 1: Direct Write** (Cloud Functions upload)

```typescript
async function uploadCroppedImage(itemId: string, imageBuffer: Buffer) {
  const bucket = admin.storage().bucket();
  const filePath = `items/${itemId}/cropped.jpg`;
  const file = bucket.file(filePath);

  await file.save(imageBuffer, {
    metadata: {
      contentType: 'image/jpeg',
      metadata: {
        itemId,
        uploadedBy: 'cloud-functions',
        layer: 'cropped'
      }
    }
  });

  console.log(`Uploaded cropped image: ${filePath}`);
  return filePath;
}
```

**Pattern 2: Signed URL Upload** (iOS client uses)

```typescript
async function generateUploadUrl(itemId: string, userId: string) {
  const bucket = admin.storage().bucket();
  const filePath = `users/${userId}/items/${itemId}/cropped.jpg`;
  const file = bucket.file(filePath);

  // Generate signed URL for iOS client upload
  const [url] = await file.getSignedUrl({
    version: 'v4',
    action: 'write',
    expires: Date.now() + 3600 * 1000,  // 1 hour
    contentType: 'image/jpeg'
  });

  return {url, filePath};
}
```

---

### Signed URL Generation

**VERIFIED**: 7-day maximum expiration (platform limit)

**Pattern 1: Time-Limited Signed URLs** (SerpAPI access)

```typescript
async function generatePublicUrl(filePath: string): Promise<string> {
  const bucket = admin.storage().bucket();
  const file = bucket.file(filePath);

  const [url] = await file.getSignedUrl({
    version: 'v4',  // Use v4 signing algorithm
    action: 'read',
    expires: Date.now() + 3600 * 1000  // 1 hour (within 7-day limit)
  });

  return url;
}

// Example: SerpAPI requires publicly accessible HTTPS URL
const croppedImageUrl = await generatePublicUrl(`items/${itemId}/cropped.jpg`);
const serpApiResponse = await axios.post('https://serpapi.com/search', {
  engine: 'google_lens',
  url: croppedImageUrl  // 1-hour signed URL
});
```

**Pattern 2: Token-Based Signed URLs** (iOS app persistent access)

```typescript
async function generatePersistentUrl(filePath: string): Promise<string> {
  const bucket = admin.storage().bucket();
  const file = bucket.file(filePath);

  const [url] = await file.getSignedUrl({
    version: 'v4',
    action: 'read',
    expires: Date.now() + (7 * 24 * 3600 * 1000)  // 7 days (maximum)
  });

  return url;
}
```

**Best Practice**: Generate signed URLs dynamically (avoid storing in Firestore, regenerate on demand)

---

### Lifecycle Policies

**Auto-Delete After 90 Days**

```typescript
async function configureLifecyclePolicy() {
  const bucket = admin.storage().bucket();

  await bucket.setLifecyclePolicy({
    rule: [
      {
        action: {type: 'Delete'},
        condition: {age: 90}  // Delete files older than 90 days
      }
    ]
  });

  console.log('Lifecycle policy configured: delete files after 90 days');
}
```

**Manual Deletion** (immediate cleanup)

```typescript
async function deleteItemImages(itemId: string) {
  const bucket = admin.storage().bucket();
  const [files] = await bucket.getFiles({prefix: `items/${itemId}/`});

  await Promise.all(files.map(file => file.delete()));

  console.log(`Deleted ${files.length} files for item ${itemId}`);
}
```

---

## Vertex AI Integration

### Gemini API Call Pattern

**VERIFIED**: Gemini 2.5 Flash-Lite, JSON Schema Mode supported

```typescript
import {VertexAI} from '@google-cloud/vertexai';

async function extractAttributes(croppedImageUrl: string) {
  // 1. Initialize Vertex AI client (ADC automatic in Cloud Functions)
  const vertexAI = new VertexAI({
    project: process.env.GCP_PROJECT_ID!,
    location: 'us-central1'
  });

  // 2. Get Gemini model
  const model = vertexAI.getGenerativeModel({
    model: 'gemini-2.5-flash-lite'
  });

  // 3. Define JSON schema for structured output
  const schema = {
    type: 'object',
    properties: {
      color: {type: 'string', description: 'Primary color of the object'},
      material: {type: 'string', description: 'Material type (wood, metal, fabric, etc)'},
      condition: {
        type: 'string',
        enum: ['excellent', 'good', 'fair', 'poor'],
        description: 'Physical condition assessment'
      },
      category: {
        type: 'string',
        description: 'Object category (furniture, electronics, clothing, etc)'
      }
    },
    required: ['color', 'material', 'condition', 'category']
  };

  // 4. Create prompt
  const prompt = `Analyze this cropped object image: ${croppedImageUrl}

Extract the following attributes as JSON:
- color: Primary color of the object
- material: Material type (wood, metal, fabric, plastic, etc)
- condition: Physical condition (excellent/good/fair/poor)
- category: Object category (furniture, electronics, clothing, kitchenware, etc)

Provide accurate, specific attributes based on visible characteristics.`;

  // 5. Call Gemini with JSON Schema Mode
  const result = await model.generateContent({
    contents: [{role: 'user', parts: [{text: prompt}]}],
    generationConfig: {
      responseMimeType: 'application/json',
      responseSchema: schema
    }
  });

  // 6. Parse JSON response
  const attributes = JSON.parse(result.response.text());

  return attributes;
}
```

---

### Authentication Pattern

**VERIFIED**: Application Default Credentials (ADC) automatic in Cloud Functions

```typescript
// ADC automatically uses Cloud Functions service account
const vertexAI = new VertexAI({
  project: process.env.GCP_PROJECT_ID,  // Automatically set in Cloud Functions
  location: 'us-central1'
});
// No credentials parameter needed!
```

**Service Account Permissions** (setup once):

```bash
# Grant Vertex AI User role to Cloud Functions service account
gcloud projects add-iam-policy-binding ${GCP_PROJECT_ID} \
  --member="serviceAccount:${GCP_PROJECT_ID}@appspot.gserviceaccount.com" \
  --role="roles/aiplatform.user"
```

---

### Rate Limiting and Retry Logic

**VERIFIED**: Exponential backoff with jitter recommended

```typescript
async function callVertexAIWithRetry<T>(fn: () => Promise<T>, maxRetries = 3): Promise<T> {
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      return await fn();

    } catch (error: any) {
      const isRetryable =
        error.code === 429 ||  // Quota exceeded
        error.code === 503 ||  // Service unavailable
        error.code === 500;    // Internal server error

      if (!isRetryable || attempt === maxRetries - 1) {
        throw error;  // Non-retryable or final attempt
      }

      // Exponential backoff with jitter
      const baseDelay = Math.pow(2, attempt) * 1000;  // 1s, 2s, 4s
      const jitter = Math.random() * 1000;  // 0-1s random
      const delay = baseDelay + jitter;

      console.log(`Vertex AI rate limit hit, retrying in ${delay}ms (attempt ${attempt + 1}/${maxRetries})`);
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }

  throw new Error('Unexpected: retry loop completed without return or throw');
}

// Usage
try {
  const attributes = await callVertexAIWithRetry(async () => {
    return await extractAttributes(croppedImageUrl);
  });
} catch (error) {
  console.error('Vertex AI failed after retries:', error);
  // Mark item as failed in Firestore
}
```

**Default Quota**: 300 requests/minute (can request increase via Cloud Console)

---

### Error Handling

```typescript
async function processLayer2a(itemId: string, croppedImageUrl: string) {
  try {
    // 1. Call Vertex AI with retry logic
    const attributes = await callVertexAIWithRetry(async () => {
      return await extractAttributes(croppedImageUrl);
    });

    // 2. Update Firestore with results
    await admin.firestore().collection('items').doc(itemId).update({
      status: 'layer2a_complete',
      layer2a: {
        attributes,
        timestamp: Date.now(),
        model: 'gemini-2.5-flash-lite'
      }
    });

    console.log(`Layer 2a complete for item ${itemId}`, attributes);

  } catch (error: any) {
    console.error(`Layer 2a failed for item ${itemId}:`, error);

    // 3. Categorize error
    let errorCategory = 'unknown';
    if (error.code === 429) errorCategory = 'quota_exceeded';
    else if (error.code === 503) errorCategory = 'service_unavailable';
    else if (error.code === 400) errorCategory = 'invalid_request';
    else if (error.message?.includes('timeout')) errorCategory = 'timeout';

    // 4. Mark item as failed in Firestore
    await admin.firestore().collection('items').doc(itemId).update({
      status: 'failed',
      error: {
        message: error.message,
        category: errorCategory,
        layer: '2a',
        timestamp: Date.now()
      }
    });

    // 5. Log structured error to Cloud Logging
    console.error(JSON.stringify({
      severity: 'ERROR',
      itemId,
      layer: '2a',
      errorCategory,
      message: error.message,
      stack: error.stack
    }));
  }
}
```

---

## GCP Observability

### Cloud Logging

**VERIFIED**: Cloud Logging is **automatic** (no setup required)

**Structured Logging**:

```typescript
// console.log() automatically sent to Cloud Logging
console.log('Processing item started', {itemId: 'abc123'});

// Structured logs with severity levels
console.log(JSON.stringify({
  severity: 'INFO',
  message: 'Layer 2a started',
  itemId: 'abc123',
  model: 'gemini-2.5-flash-lite'
}));

console.error(JSON.stringify({
  severity: 'ERROR',
  message: 'Layer 2a failed',
  itemId: 'abc123',
  errorCategory: 'quota_exceeded',
  stack: error.stack
}));
```

**Query Logs in Cloud Console**:

```
resource.type="cloud_function"
resource.labels.function_name="onItemCreated"
severity>=ERROR
```

---

### Cloud Monitoring Dashboards

**Recommended Metrics**:
- Function invocation count
- Error rate (%)
- P50, P95, P99 latency
- Memory usage
- Cold start frequency

**Create Dashboard via CLI**:

```bash
gcloud monitoring dashboards create --config-from-file=dashboard.json
```

---

### Alert Policies

**VERIFIED**: Budget alerts sent daily (use Cloud Monitoring for real-time tracking)

**Alert Policy 1: Budget Alert (50%)**

```yaml
displayName: "Budget Alert - 50% Actual Spend"
conditions:
  - displayName: "Actual spend >= 50% of budget"
    conditionThreshold:
      filter: "metric.type=\"billing.googleapis.com/project/cost\" resource.type=\"global\""
      comparison: "COMPARISON_GT"
      thresholdValue: 258.5  # 50% of $517 monthly budget
      duration: "0s"
notificationChannels:
  - projects/abundance-prod/notificationChannels/email-alerts
```

**Alert Policy 2: Error Rate >5%**

```yaml
displayName: "Cloud Functions - High Error Rate"
conditions:
  - displayName: "Error rate > 5% over 5 minutes"
    conditionThreshold:
      filter: "resource.type=\"cloud_function\" metric.type=\"cloudfunctions.googleapis.com/function/execution_count\" status!=\"ok\""
      comparison: "COMPARISON_GT"
      thresholdValue: 0.05  # 5%
      duration: "300s"  # 5 minutes
notificationChannels:
  - projects/abundance-prod/notificationChannels/email-alerts
```

**Alert Policy 3: Latency P95 >2s**

```yaml
displayName: "Cloud Functions - High Latency"
conditions:
  - displayName: "P95 latency > 2s over 5 minutes"
    conditionThreshold:
      filter: "resource.type=\"cloud_function\" metric.type=\"cloudfunctions.googleapis.com/function/execution_times\""
      aggregations:
        - alignmentPeriod: "300s"
          perSeriesAligner: "ALIGN_PERCENTILE_95"
      comparison: "COMPARISON_GT"
      thresholdValue: 2000  # 2s in milliseconds
      duration: "300s"
notificationChannels:
  - projects/abundance-prod/notificationChannels/email-alerts
```

---

## Firebase Emulator Suite

### Configuration

**Install Firebase CLI**:

```bash
npm install -g firebase-tools
```

**Initialize Emulators**:

```bash
firebase init emulators
```

**Configure firebase.json**:

```json
{
  "functions": [
    {
      "source": "functions",
      "codebase": "default",
      "ignore": [
        "node_modules",
        ".git",
        "firebase-debug.log",
        "firebase-debug.*.log"
      ]
    }
  ],
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "storage": {
    "rules": "storage.rules"
  },
  "emulators": {
    "auth": {
      "port": 9099
    },
    "functions": {
      "port": 5001
    },
    "firestore": {
      "port": 8080
    },
    "storage": {
      "port": 9199
    },
    "ui": {
      "enabled": true,
      "port": 4000
    },
    "singleProjectMode": true
  }
}
```

**Start Emulators**:

```bash
firebase emulators:start
```

**Emulator UI**: http://localhost:4000

---

### Cross-Product Integration Testing

**VERIFIED**: Cross-product integration testing supported

```typescript
import {initializeTestEnvironment} from '@firebase/rules-unit-testing';
import {readFileSync} from 'fs';

let testEnv: any;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'abundance-test',
    firestore: {
      rules: readFileSync('firestore.rules', 'utf8'),
      host: 'localhost',
      port: 8080
    },
    storage: {
      rules: readFileSync('storage.rules', 'utf8'),
      host: 'localhost',
      port: 9199
    }
  });
});

after(async () => {
  await testEnv.cleanup();
});

describe('Layer 2a: Gemini Attribute Extraction', () => {
  it('should trigger onItemCreated when new item is created', async () => {
    const firestore = testEnv.authenticatedContext('user1').firestore();

    // 1. Create item in Firestore emulator
    const itemRef = await firestore.collection('items').add({
      userId: 'user1',
      name: 'Test Item',
      croppedImageUrl: 'https://example.com/test.jpg',
      status: 'processing',
      createdAt: new Date()
    });

    // 2. Wait for onItemCreated trigger to fire
    await waitForCondition(async () => {
      const doc = await itemRef.get();
      return doc.data().status === 'layer2a_complete';
    }, 10000);

    // 3. Assert Firestore document updated
    const updatedDoc = await itemRef.get();
    const data = updatedDoc.data();

    expect(data.status).to.equal('layer2a_complete');
    expect(data.layer2a).to.exist;
    expect(data.layer2a.attributes).to.have.property('color');
    expect(data.layer2a.attributes).to.have.property('material');
  });
});

async function waitForCondition(conditionFn: () => Promise<boolean>, timeout: number): Promise<void> {
  const startTime = Date.now();
  while (Date.now() - startTime < timeout) {
    if (await conditionFn()) {
      return;
    }
    await new Promise(resolve => setTimeout(resolve, 500));
  }
  throw new Error('Condition not met within timeout');
}
```

---

### Hot Reload Setup

**VERIFIED**: TypeScript requires `tsc -w` for automatic code reload

**package.json**:

```json
{
  "scripts": {
    "build": "tsc",
    "watch": "tsc -w",
    "serve": "npm run build && firebase emulators:start --only functions",
    "dev": "concurrently \"npm run watch\" \"npm run serve\""
  },
  "devDependencies": {
    "typescript": "^5.0.0",
    "concurrently": "^8.0.0"
  }
}
```

**Run Development with Hot Reload**:

```bash
cd functions
npm run dev
```

**What Happens**:
1. `tsc -w` watches TypeScript files for changes
2. On save, TypeScript recompiles to JavaScript (functions/lib/)
3. Firebase Emulator detects JavaScript changes
4. Functions automatically reload (no restart needed)

---

## Summary

This document provides comprehensive backend implementation patterns for the Abundance MVP:

✅ **Cloud Functions**: Node.js 20, HTTP/Firestore/scheduled triggers, cold start optimization
✅ **Firestore**: Root collections, composite indexes, query optimization, batch writes
✅ **Firebase Storage**: Uploads, signed URLs (v4, 1-hour), lifecycle policies
✅ **Vertex AI**: Gemini 2.5 Flash-Lite, JSON Schema Mode, ADC authentication, retry logic
✅ **GCP Observability**: Cloud Logging (automatic), Cloud Monitoring dashboards, alert policies
✅ **Firebase Emulator Suite**: Local testing, cross-product integration, hot reload with TypeScript

All patterns verified per RESEARCH-VALIDATION-stage-3.2.md (18 claims verified, 2025-11-10).

---

**Created**: 2025-11-10
**Status**: Complete
**References**: RESEARCH-VALIDATION-stage-3.2.md, TECH-STACK-MAP-001, PLAN-SUMMARY-stage-2.3.md
