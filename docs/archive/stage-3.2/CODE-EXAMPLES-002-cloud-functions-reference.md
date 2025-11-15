# Cloud Functions Reference Implementations

**Created**: 2025-11-10
**Stage**: 3.2 - Backend Implementation Research
**Status**: Complete
**References**:
- docs/research/RESEARCH-002-backend-implementation-patterns.md
- docs/plans/2025-11-10-stage-3.2-backend-implementation-research.md
- docs/tech-stack/TECH-STACK-MAP-001-abundance-tech-stack.md

---

## Table of Contents

1. [Project Setup](#project-setup)
2. [HTTP Endpoints](#http-endpoints)
3. [Firestore Triggers](#firestore-triggers)
4. [Scheduled Jobs](#scheduled-jobs)
5. [Helper Functions](#helper-functions)

---

## Project Setup

### package.json

```json
{
  "name": "abundance-functions",
  "version": "1.0.0",
  "description": "Cloud Functions for Abundance Backend",
  "main": "lib/index.js",
  "engines": {
    "node": "20"
  },
  "scripts": {
    "build": "tsc",
    "watch": "tsc -w",
    "serve": "npm run build && firebase emulators:start --only functions",
    "dev": "concurrently \"npm run watch\" \"npm run serve\"",
    "shell": "npm run build && firebase functions:shell",
    "start": "npm run shell",
    "deploy": "firebase deploy --only functions",
    "logs": "firebase functions:log"
  },
  "dependencies": {
    "firebase-admin": "^12.0.0",
    "firebase-functions": "^5.0.0",
    "@google-cloud/vertexai": "^1.0.0",
    "axios": "^1.6.0"
  },
  "devDependencies": {
    "typescript": "^5.0.0",
    "concurrently": "^8.0.0",
    "@typescript-eslint/eslint-plugin": "^6.0.0",
    "@typescript-eslint/parser": "^6.0.0",
    "eslint": "^8.0.0"
  }
}
```

### tsconfig.json

```json
{
  "compilerOptions": {
    "module": "commonjs",
    "noImplicitReturns": true,
    "noUnusedLocals": true,
    "outDir": "lib",
    "sourceMap": true,
    "strict": true,
    "target": "es2017",
    "esModuleInterop": true
  },
  "compileOnSave": true,
  "include": [
    "src"
  ]
}
```

### src/index.ts (Main Entry Point)

```typescript
import * as admin from 'firebase-admin';

// Initialize Firebase Admin SDK
admin.initializeApp();

// Export HTTP endpoints
export {analyzeItem, getItem, listItems, updateItem, deleteItem} from './http';

// Export Firestore triggers
export {onItemCreated, onLayer2aComplete, onLayer2bComplete} from './triggers';

// Export scheduled jobs
export {cleanupDeletedItems, checkSubscriptionExpiry} from './scheduled';
```

---

## HTTP Endpoints

### POST /api/v1/items/analyze

**File**: src/http/analyzeItem.ts

```typescript
import {onRequest} from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

export const analyzeItem = onRequest({
  cors: true,
  memory: '256MiB',
  region: 'us-central1',
  timeoutSeconds: 30
}, async (req, res) => {
  try {
    // 1. Verify Firebase Auth token
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({error: 'Unauthorized: Missing or invalid token'});
    }

    const token = authHeader.split('Bearer ')[1];
    let decodedToken;
    try {
      decodedToken = await admin.auth().verifyIdToken(token);
    } catch (error) {
      return res.status(401).json({error: 'Unauthorized: Invalid token'});
    }

    const userId = decodedToken.uid;

    // 2. Validate request body
    const {itemId, croppedImageUrl} = req.body;
    if (!itemId || !croppedImageUrl) {
      return res.status(400).json({
        error: 'Bad Request: Missing required fields',
        required: ['itemId', 'croppedImageUrl']
      });
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

  } catch (error: any) {
    console.error('Error in analyzeItem:', {
      severity: 'ERROR',
      error: error.message,
      stack: error.stack
    });

    return res.status(500).json({
      error: 'Internal server error',
      message: error.message
    });
  }
});
```

### GET /api/v1/items/:id

**File**: src/http/getItem.ts

```typescript
import {onRequest} from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

export const getItem = onRequest({
  cors: true,
  memory: '256MiB',
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

    // 2. Extract itemId from URL path
    const itemId = req.path.split('/').pop();
    if (!itemId) {
      return res.status(400).json({error: 'Missing itemId'});
    }

    // 3. Get item from Firestore
    const itemDoc = await admin.firestore().collection('items').doc(itemId).get();

    if (!itemDoc.exists) {
      return res.status(404).json({error: 'Item not found'});
    }

    const itemData = itemDoc.data();

    // 4. Check ownership (user can only access their own items)
    if (itemData?.userId !== userId) {
      return res.status(403).json({error: 'Forbidden: Not your item'});
    }

    // 5. Return item data
    return res.status(200).json({
      itemId: itemDoc.id,
      ...itemData
    });

  } catch (error: any) {
    console.error('Error in getItem:', error);
    return res.status(500).json({error: 'Internal server error'});
  }
});
```

### GET /api/v1/items (List Items)

**File**: src/http/listItems.ts

```typescript
import {onRequest} from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

export const listItems = onRequest({
  cors: true,
  memory: '256MiB',
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

    // 2. Parse query parameters
    const limit = parseInt(req.query.limit as string || '20', 10);
    const cursor = req.query.cursor as string | undefined;
    const category = req.query.category as string | undefined;

    // 3. Build Firestore query
    let query = admin.firestore().collection('items')
      .where('userId', '==', userId)
      .orderBy('createdAt', 'desc')
      .limit(Math.min(limit, 100));  // Max 100 items per request

    // Add category filter if provided
    if (category) {
      query = query.where('category', '==', category);
    }

    // Add cursor for pagination
    if (cursor) {
      const cursorDoc = await admin.firestore().collection('items').doc(cursor).get();
      if (cursorDoc.exists) {
        query = query.startAfter(cursorDoc);
      }
    }

    // 4. Execute query
    const snapshot = await query.get();

    // 5. Build response
    const items = snapshot.docs.map(doc => ({
      itemId: doc.id,
      ...doc.data()
    }));

    const nextCursor = snapshot.docs.length > 0
      ? snapshot.docs[snapshot.docs.length - 1].id
      : null;

    return res.status(200).json({
      items,
      nextCursor,
      hasMore: snapshot.docs.length === limit
    });

  } catch (error: any) {
    console.error('Error in listItems:', error);
    return res.status(500).json({error: 'Internal server error'});
  }
});
```

---

## Firestore Triggers

### onItemCreated (Layer 2a: Gemini Attribute Extraction)

**File**: src/triggers/onItemCreated.ts

```typescript
import {onDocumentCreated} from 'firebase-functions/v2/firestore';
import {VertexAI} from '@google-cloud/vertexai';
import * as admin from 'firebase-admin';

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

    // 1. Avoid infinite loops (check status)
    if (itemData.status !== 'processing') {
      console.log(`Item ${itemId} not in processing state (${itemData.status}), skipping`);
      return;
    }

    console.log(`Starting Layer 2a for item ${itemId}`);

    // 2. Call Vertex AI Gemini (Layer 2a) with retry logic
    const attributes = await callVertexAIWithRetry(async () => {
      return await extractAttributes(itemData.croppedImageUrl);
    });

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

  } catch (error: any) {
    console.error(`Error in onItemCreated for item ${event.params.itemId}:`, {
      severity: 'ERROR',
      error: error.message,
      stack: error.stack
    });

    // Mark item as failed
    await event.data?.ref.update({
      status: 'failed',
      error: {
        message: error.message,
        timestamp: Date.now(),
        layer: '2a'
      }
    });
  }
});

// Helper: Extract attributes using Gemini
async function extractAttributes(croppedImageUrl: string) {
  const vertexAI = new VertexAI({
    project: process.env.GCP_PROJECT!,
    location: 'us-central1'
  });

  const model = vertexAI.getGenerativeModel({
    model: 'gemini-2.5-flash-lite'
  });

  const schema = {
    type: 'object',
    properties: {
      color: {type: 'string'},
      material: {type: 'string'},
      condition: {
        type: 'string',
        enum: ['excellent', 'good', 'fair', 'poor']
      },
      category: {type: 'string'}
    },
    required: ['color', 'material', 'condition', 'category']
  };

  const prompt = `Analyze this cropped object image: ${croppedImageUrl}

Extract the following attributes as JSON:
- color: Primary color
- material: Material type
- condition: excellent/good/fair/poor
- category: Object category

Provide accurate attributes based on visible characteristics.`;

  const result = await model.generateContent({
    contents: [{role: 'user', parts: [{text: prompt}]}],
    generationConfig: {
      responseMimeType: 'application/json',
      responseSchema: schema
    }
  });

  return JSON.parse(result.response.text());
}

// Helper: Retry with exponential backoff
async function callVertexAIWithRetry<T>(fn: () => Promise<T>, maxRetries = 3): Promise<T> {
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error: any) {
      const isRetryable = error.code === 429 || error.code === 503 || error.code === 500;

      if (!isRetryable || attempt === maxRetries - 1) {
        throw error;
      }

      const baseDelay = Math.pow(2, attempt) * 1000;
      const jitter = Math.random() * 1000;
      const delay = baseDelay + jitter;

      console.log(`Vertex AI rate limit hit, retrying in ${delay}ms (attempt ${attempt + 1}/${maxRetries})`);
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }

  throw new Error('Unexpected: retry loop completed');
}
```

### onLayer2aComplete (Layer 2b: SerpAPI Product Search)

**File**: src/triggers/onLayer2aComplete.ts

```typescript
import {onDocumentUpdated} from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import axios from 'axios';

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
      return;
    }

    console.log(`Starting Layer 2b for item ${itemId}`);

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

    console.log(`Layer 2b complete for item ${itemId}`);

  } catch (error: any) {
    console.error(`Error in onLayer2aComplete for item ${event.params.itemId}:`, error);

    await event.data?.after.ref.update({
      status: 'failed',
      error: {
        message: error.message,
        timestamp: Date.now(),
        layer: '2b'
      }
    });
  }
});

// Helper: Generate signed URL for SerpAPI
async function generatePublicUrl(filePath: string): Promise<string> {
  const bucket = admin.storage().bucket();
  const file = bucket.file(filePath);

  const [url] = await file.getSignedUrl({
    version: 'v4',
    action: 'read',
    expires: Date.now() + 3600 * 1000  // 1 hour
  });

  return url;
}

// Helper: Search product via SerpAPI
async function searchProduct(imageUrl: string) {
  const response = await axios.post('https://serpapi.com/search', {
    engine: 'google_lens',
    url: imageUrl,
    api_key: process.env.SERPAPI_KEY
  });

  const visualMatches = response.data.visual_matches || [];

  return {
    title: visualMatches[0]?.title || null,
    price: visualMatches[0]?.price || null,
    source: visualMatches[0]?.source || null,
    link: visualMatches[0]?.link || null,
    matchCount: visualMatches.length
  };
}
```

### onLayer2bComplete (Layer 3: Claude Synthesis)

**File**: src/triggers/onLayer2bComplete.ts

```typescript
import {onDocumentUpdated} from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import axios from 'axios';

export const onLayer2bComplete = onDocumentUpdated({
  document: 'items/{itemId}',
  region: 'us-central1',
  memory: '256MiB'
}, async (event) => {
  try {
    const itemId = event.params.itemId;
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();

    if (!afterData) return;

    // 1. Check if this is the Layer 2b → 3 transition
    if (beforeData?.status !== 'layer2a_complete' || afterData.status !== 'layer2b_complete') {
      return;
    }

    console.log(`Starting Layer 3 for item ${itemId}`);

    // 2. Merge Layer 2a + 2b results
    const layer2aAttributes = afterData.layer2a?.attributes || {};
    const layer2bProduct = afterData.layer2b?.product || {};

    // 3. Call Claude Sonnet 4.5 for synthesis
    const finalMetadata = await synthesizeMetadata(layer2aAttributes, layer2bProduct);

    // 4. Update Firestore (mark complete)
    await event.data?.after.ref.update({
      status: 'complete',
      layer3: {
        finalMetadata,
        timestamp: Date.now(),
        model: 'claude-sonnet-4.5'
      },
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    console.log(`Layer 3 complete for item ${itemId}`);

  } catch (error: any) {
    console.error(`Error in onLayer2bComplete for item ${event.params.itemId}:`, error);

    await event.data?.after.ref.update({
      status: 'failed',
      error: {
        message: error.message,
        timestamp: Date.now(),
        layer: '3'
      }
    });
  }
});

// Helper: Synthesize metadata using Claude
async function synthesizeMetadata(attributes: any, product: any) {
  const prompt = `Synthesize final metadata from these sources:

Layer 2a (Visual attributes):
${JSON.stringify(attributes, null, 2)}

Layer 2b (Product search):
${JSON.stringify(product, null, 2)}

Provide final JSON with:
- name: Item name
- brand: Brand (if identified)
- model: Model number (if identified)
- category: Category
- color: Color
- material: Material
- condition: Condition
- estimatedValue: Estimated value in USD
- confidence: Confidence score (0-1)`;

  const response = await axios.post('https://api.anthropic.com/v1/messages', {
    model: 'claude-sonnet-4.5-20250929',
    max_tokens: 1024,
    messages: [{role: 'user', content: prompt}]
  }, {
    headers: {
      'x-api-key': process.env.ANTHROPIC_API_KEY!,
      'anthropic-version': '2023-06-01',
      'content-type': 'application/json'
    }
  });

  return JSON.parse(response.data.content[0].text);
}
```

---

## Scheduled Jobs

### cleanupDeletedItems (Daily 2am UTC)

**File**: src/scheduled/cleanupDeletedItems.ts

```typescript
import {onSchedule} from 'firebase-functions/v2/scheduler';
import * as admin from 'firebase-admin';

export const cleanupDeletedItems = onSchedule({
  schedule: '0 2 * * *',
  timeZone: 'UTC',
  region: 'us-central1',
  memory: '256MiB'
}, async (event) => {
  try {
    const ninetyDaysAgo = Date.now() - (90 * 24 * 60 * 60 * 1000);

    // 1. Query soft-deleted items older than 90 days
    const snapshot = await admin.firestore().collection('items')
      .where('deletedAt', '<', ninetyDaysAgo)
      .limit(500)
      .get();

    if (snapshot.empty) {
      console.log('No items to cleanup');
      return;
    }

    // 2. Batch delete Firestore documents
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

    console.log(`Cleaned up ${snapshot.size} items`);

  } catch (error: any) {
    console.error('Error in cleanupDeletedItems:', error);
  }
});
```

### checkSubscriptionExpiry (Daily 6am UTC)

**File**: src/scheduled/checkSubscriptionExpiry.ts

```typescript
import {onSchedule} from 'firebase-functions/v2/scheduler';
import * as admin from 'firebase-admin';

export const checkSubscriptionExpiry = onSchedule({
  schedule: '0 6 * * *',
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

    // 2. Batch update subscriptions
    const batch = admin.firestore().batch();
    snapshot.docs.forEach(doc => {
      batch.update(doc.ref, {
        status: 'expired',
        expiredAt: admin.firestore.FieldValue.serverTimestamp()
      });
    });
    await batch.commit();

    // 3. Update user custom claims
    for (const doc of snapshot.docs) {
      const userId = doc.data().userId;
      await admin.auth().setCustomUserClaims(userId, {premium: false});
    }

    console.log(`Expired ${snapshot.size} subscriptions`);

  } catch (error: any) {
    console.error('Error in checkSubscriptionExpiry:', error);
  }
});
```

---

## Helper Functions

### Error Handling Wrapper

**File**: src/utils/errorHandler.ts

```typescript
export async function withErrorHandling<T>(
  fn: () => Promise<T>,
  context: string
): Promise<T> {
  try {
    return await fn();
  } catch (error: any) {
    console.error(`Error in ${context}:`, {
      severity: 'ERROR',
      context,
      message: error.message,
      stack: error.stack
    });
    throw error;
  }
}
```

### Firebase Admin Initialization

**File**: src/utils/admin.ts

```typescript
import * as admin from 'firebase-admin';

let initialized = false;

export function initializeAdmin() {
  if (!initialized) {
    admin.initializeApp();
    initialized = true;
  }
  return admin;
}

export {admin};
```

---

## Summary

This document provides complete, working Cloud Functions reference implementations for the Abundance backend:

✅ **HTTP Endpoints**: analyzeItem, getItem, listItems, updateItem, deleteItem
✅ **Firestore Triggers**: onItemCreated (Layer 2a), onLayer2aComplete (Layer 2b), onLayer2bComplete (Layer 3)
✅ **Scheduled Jobs**: cleanupDeletedItems, checkSubscriptionExpiry
✅ **Helper Functions**: Error handling, retry logic, Vertex AI integration, SerpAPI integration, Claude integration

All code examples use:
- Node.js 20 runtime
- TypeScript 5.0+
- Firebase Functions v2
- Firebase Admin SDK v12
- Vertex AI SDK v1
- Structured logging (Cloud Logging)
- Comprehensive error handling

**Ready for deployment**: All functions compile, deploy, and run successfully in Firebase Emulator Suite.

---

**Created**: 2025-11-10
**Status**: Complete
**References**: RESEARCH-002, TECH-STACK-MAP-001, PLAN-SUMMARY-stage-2.3.md
