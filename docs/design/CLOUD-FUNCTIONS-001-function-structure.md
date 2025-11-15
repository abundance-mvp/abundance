# CLOUD-FUNCTIONS-001: Cloud Functions Structure

**Created**: 2025-11-08
**Stage**: 2.3 - Backend Cloud Architecture
**Status**: Approved
**References**:
- docs/design/API-CONTRACTS-001-rest-endpoints.md (REST API specifications)
- docs/adr/ADR-007-api-architecture.md (REST API architecture decision)
- docs/tech-stack/DATA-MODEL-001-firestore-schema.md (Firestore data model)
- docs/validation/RESEARCH-VALIDATION-stage-2.3.md (Cloud Functions capabilities verified)

---

## Executive Summary

This document defines the complete Cloud Functions architecture for Abundance MVP (Phase 1). The function structure is organized into three categories:

1. **HTTP Endpoints** (8 functions): REST API for iOS client
2. **Firestore Triggers** (3 functions): AI pipeline orchestration
3. **Scheduled Jobs** (2 functions): Maintenance tasks

**Runtime**: Node.js 20 (2nd generation Cloud Functions)
**Region**: us-central1 (matches Firestore region)
**Free Tier Compliance**: 2 million invocations/month (verified sufficient for 5K users)

---

## Cloud Functions Configuration

**Generation**: 2nd generation (Cloud Functions v2)
**Runtime**: Node.js 20
**Region**: us-central1
**Environment Variables**: Set via `firebase functions:config:set`
**Logging**: Cloud Logging (automatic)
**Monitoring**: Cloud Monitoring (dashboards + alerts)

**Dependencies** (`package.json`):
```json
{
  "name": "abundance-functions",
  "engines": {
    "node": "20"
  },
  "dependencies": {
    "firebase-functions": "^5.0.0",
    "firebase-admin": "^12.0.0",
    "@google-cloud/vertexai": "^1.0.0",
    "@anthropic-ai/sdk": "^0.27.0",
    "axios": "^1.6.0",
    "stripe": "^14.0.0"
  }
}
```

---

## Category 1: HTTP Endpoints (REST API)

### Function 1: `api_health`

**Purpose**: Health check endpoint (no authentication required)

**HTTP Method**: GET
**Path**: `/api/v1/health`
**Authentication**: None

**Response**:
```json
{
  "status": "ok",
  "timestamp": "2025-11-08T12:00:00Z",
  "version": "1.0.0"
}
```

**Implementation**:
```javascript
const functions = require('firebase-functions/v2');

exports.api_health = functions.https.onRequest((req, res) => {
  res.status(200).json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});
```

---

### Function 2: `api_createItem`

**Purpose**: Create new catalog item (Layer 1 results from iOS)

**HTTP Method**: POST
**Path**: `/api/v1/items`
**Authentication**: Required (Firebase ID token)

**Request Body**:
```json
{
  "imageURL": "https://storage.googleapis.com/...",
  "layer1Result": {
    "detectedClass": "tent",
    "confidence": 0.87,
    "boundingBox": { "x": 100, "y": 200, "width": 300, "height": 400 }
  },
  "detectedBarcode": "012345678905"
}
```

**Response** (201 Created):
```json
{
  "itemId": "item_12345abc",
  "status": "processing"
}
```

**Implementation**:
```javascript
exports.api_createItem = functions.https.onCall(async (data, context) => {
  // Verify auth
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be signed in');
  }

  const userId = context.auth.uid;
  const { imageURL, layer1Result, detectedBarcode } = data;

  // Validate inputs
  if (!imageURL || !layer1Result) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
  }

  // Create Firestore document
  const itemRef = await admin.firestore().collection('items').add({
    userId,
    name: 'Untitled Item',
    category: 'uncategorized',
    imageURL,
    barcode: detectedBarcode || null,
    aiAnalysis: { layer1: layer1Result },
    status: 'processing',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    deletedAt: null
  });

  // Increment user's catalog count
  await admin.firestore().collection('users').doc(userId).update({
    catalogItemCount: admin.firestore.FieldValue.increment(1),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  });

  return { itemId: itemRef.id, status: 'processing' };
});
```

---

### Function 3: `api_getItem`

**Purpose**: Get single catalog item by ID

**HTTP Method**: GET
**Path**: `/api/v1/items/:itemId`
**Authentication**: Required (Firebase ID token)

**Response** (200 OK):
```json
{
  "id": "item_12345abc",
  "userId": "firebase_user_abc123",
  "name": "Coleman Evanston 8-Person Tent",
  "category": "camping",
  "imageURL": "https://storage.googleapis.com/...",
  "aiAnalysis": { /* ... */ },
  "status": "complete",
  "createdAt": "2025-11-08T12:00:00Z"
}
```

**Implementation**:
```javascript
exports.api_getItem = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be signed in');
  }

  const userId = context.auth.uid;
  const { itemId } = data;

  const itemDoc = await admin.firestore().collection('items').doc(itemId).get();

  if (!itemDoc.exists) {
    throw new functions.https.HttpsError('not-found', 'Item not found');
  }

  const item = itemDoc.data();

  // Verify ownership
  if (item.userId !== userId) {
    throw new functions.https.HttpsError('permission-denied', 'Access denied');
  }

  return { id: itemDoc.id, ...item };
});
```

---

### Function 4: `api_listItems`

**Purpose**: List user's catalog items (paginated)

**HTTP Method**: GET
**Path**: `/api/v1/items?page=1&limit=50&category=camping`
**Authentication**: Required (Firebase ID token)

**Query Parameters**:
- `page` (optional, default: 1)
- `limit` (optional, default: 50, max: 100)
- `category` (optional filter)

**Response** (200 OK):
```json
{
  "items": [
    { "id": "item_123", "name": "Tent", /* ... */ },
    { "id": "item_456", "name": "Backpack", /* ... */ }
  ],
  "pagination": {
    "page": 1,
    "limit": 50,
    "total": 125,
    "hasMore": true
  }
}
```

**Implementation**:
```javascript
exports.api_listItems = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be signed in');
  }

  const userId = context.auth.uid;
  const { page = 1, limit = 50, category } = data;

  const pageLimit = Math.min(limit, 100);
  const offset = (page - 1) * pageLimit;

  let query = admin.firestore().collection('items')
    .where('userId', '==', userId)
    .where('deletedAt', '==', null)
    .orderBy('createdAt', 'desc');

  if (category) {
    query = query.where('category', '==', category);
  }

  const snapshot = await query.limit(pageLimit).offset(offset).get();

  // Get total count (separate query)
  let countQuery = admin.firestore().collection('items')
    .where('userId', '==', userId)
    .where('deletedAt', '==', null);

  if (category) {
    countQuery = countQuery.where('category', '==', category);
  }

  const countSnapshot = await countQuery.count().get();
  const total = countSnapshot.data().count;

  const items = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

  return {
    items,
    pagination: {
      page,
      limit: pageLimit,
      total,
      hasMore: offset + pageLimit < total
    }
  };
});
```

---

### Function 5: `api_updateItem`

**Purpose**: Update catalog item (user edits name, category, location)

**HTTP Method**: PUT
**Path**: `/api/v1/items/:itemId`
**Authentication**: Required (Firebase ID token)

**Request Body**:
```json
{
  "name": "Coleman Evanston Tent (Updated)",
  "category": "camping",
  "location": "Garage - Shelf 3"
}
```

**Response** (200 OK):
```json
{
  "itemId": "item_12345abc",
  "updated": true
}
```

**Implementation**:
```javascript
exports.api_updateItem = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be signed in');
  }

  const userId = context.auth.uid;
  const { itemId, name, category, location } = data;

  const itemDoc = await admin.firestore().collection('items').doc(itemId).get();

  if (!itemDoc.exists) {
    throw new functions.https.HttpsError('not-found', 'Item not found');
  }

  if (itemDoc.data().userId !== userId) {
    throw new functions.https.HttpsError('permission-denied', 'Access denied');
  }

  const updates = {};
  if (name !== undefined) updates.name = name;
  if (category !== undefined) updates.category = category;
  if (location !== undefined) updates.location = location;
  updates.updatedAt = admin.firestore.FieldValue.serverTimestamp();

  await admin.firestore().collection('items').doc(itemId).update(updates);

  return { itemId, updated: true };
});
```

---

### Function 6: `api_deleteItem`

**Purpose**: Soft delete catalog item

**HTTP Method**: DELETE
**Path**: `/api/v1/items/:itemId`
**Authentication**: Required (Firebase ID token)

**Response** (200 OK):
```json
{
  "itemId": "item_12345abc",
  "deleted": true
}
```

**Implementation**:
```javascript
exports.api_deleteItem = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be signed in');
  }

  const userId = context.auth.uid;
  const { itemId } = data;

  const itemDoc = await admin.firestore().collection('items').doc(itemId).get();

  if (!itemDoc.exists) {
    throw new functions.https.HttpsError('not-found', 'Item not found');
  }

  if (itemDoc.data().userId !== userId) {
    throw new functions.https.HttpsError('permission-denied', 'Access denied');
  }

  // Soft delete
  await admin.firestore().collection('items').doc(itemId).update({
    deletedAt: admin.firestore.FieldValue.serverTimestamp(),
    status: 'deleted',
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  });

  // Decrement user's catalog count
  await admin.firestore().collection('users').doc(userId).update({
    catalogItemCount: admin.firestore.FieldValue.increment(-1),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  });

  return { itemId, deleted: true };
});
```

---

### Function 7: `api_getUser`

**Purpose**: Get user profile

**HTTP Method**: GET
**Path**: `/api/v1/users/:userId`
**Authentication**: Required (Firebase ID token)

**Response** (200 OK):
```json
{
  "userId": "firebase_user_abc123",
  "email": "user@example.com",
  "displayName": "John Doe",
  "subscriptionStatus": "premium",
  "catalogItemCount": 125,
  "createdAt": "2025-10-01T12:00:00Z"
}
```

**Implementation**:
```javascript
exports.api_getUser = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be signed in');
  }

  const userId = context.auth.uid;

  // Users can only access their own profile
  if (data.userId !== userId) {
    throw new functions.https.HttpsError('permission-denied', 'Access denied');
  }

  const userDoc = await admin.firestore().collection('users').doc(userId).get();

  if (!userDoc.exists) {
    throw new functions.https.HttpsError('not-found', 'User not found');
  }

  return userDoc.data();
});
```

---

### Function 8: `api_subscriptionWebhook`

**Purpose**: Stripe webhook handler (subscription created/updated/canceled)

**HTTP Method**: POST
**Path**: `/api/v1/subscriptions/webhook`
**Authentication**: Stripe signature verification

**Implementation**:
```javascript
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

exports.api_subscriptionWebhook = functions.https.onRequest(async (req, res) => {
  const sig = req.headers['stripe-signature'];
  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;

  let event;

  try {
    event = stripe.webhooks.constructEvent(req.rawBody, sig, webhookSecret);
  } catch (err) {
    console.error('Webhook signature verification failed:', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  // Handle subscription events
  switch (event.type) {
    case 'customer.subscription.created':
    case 'customer.subscription.updated':
      await handleSubscriptionUpdated(event.data.object);
      break;

    case 'customer.subscription.deleted':
      await handleSubscriptionDeleted(event.data.object);
      break;
  }

  res.status(200).json({ received: true });
});

async function handleSubscriptionUpdated(subscription) {
  const userId = subscription.metadata.userId;

  // Update Firestore subscription record
  await admin.firestore().collection('subscriptions').doc(subscription.id).set({
    userId,
    stripeCustomerId: subscription.customer,
    status: subscription.status,
    currentPeriodEnd: new Date(subscription.current_period_end * 1000),
    cancelAtPeriodEnd: subscription.cancel_at_period_end,
    createdAt: new Date(subscription.created * 1000),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  });

  // Update user profile
  await admin.firestore().collection('users').doc(userId).update({
    subscriptionStatus: 'premium',
    subscriptionExpiresAt: new Date(subscription.current_period_end * 1000),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  });

  // Set custom claim
  await admin.auth().setCustomUserClaims(userId, { premium: true });
}

async function handleSubscriptionDeleted(subscription) {
  const userId = subscription.metadata.userId;

  // Update Firestore subscription record
  await admin.firestore().collection('subscriptions').doc(subscription.id).update({
    status: 'canceled',
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  });

  // Downgrade user
  await admin.firestore().collection('users').doc(userId).update({
    subscriptionStatus: 'free',
    subscriptionExpiresAt: null,
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  });

  await admin.auth().setCustomUserClaims(userId, { premium: false });
}
```

---

## Category 2: Firestore Triggers (AI Pipeline)

### Function 9: `onItemCreated`

**Purpose**: Trigger Layer 2a (Gemini attribute extraction) when new item created

**Trigger**: Firestore onCreate (`items/{itemId}`)

**Implementation**:
```javascript
const { VertexAI } = require('@google-cloud/vertexai');

exports.onItemCreated = functions.firestore
  .document('items/{itemId}')
  .onCreate(async (snap, context) => {
    const item = snap.data();
    const itemId = context.params.itemId;

    try {
      // Call Gemini API (Layer 2a)
      const layer2aResult = await extractAttributes(item.imageURL);

      // Update item with Layer 2a results
      await snap.ref.update({
        'aiAnalysis.layer2a': layer2aResult,
        name: layer2aResult.productName || item.name,
        category: layer2aResult.category || item.category,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    } catch (error) {
      console.error('Layer 2a failed:', error);

      // Mark item as failed
      await snap.ref.update({
        status: 'failed',
        errorMessage: error.message,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    }
  });

async function extractAttributes(imageURL) {
  const vertex_ai = new VertexAI({ project: 'abundance-prod', location: 'us-central1' });

  const generativeModel = vertex_ai.preview.getGenerativeModel({
    model: 'gemini-2.0-flash-exp',
    generationConfig: {
      maxOutputTokens: 256,
      temperature: 0.2,
      responseMimeType: 'application/json',
      responseSchema: {
        type: 'object',
        properties: {
          productName: { type: 'string' },
          color: { type: 'string' },
          material: { type: 'string' },
          condition: { type: 'string', enum: ['new', 'excellent', 'good', 'fair', 'poor'] },
          category: { type: 'string' }
        }
      }
    }
  });

  const request = {
    contents: [{
      role: 'user',
      parts: [
        { fileData: { mimeType: 'image/jpeg', fileUri: imageURL } },
        { text: 'Extract: product name, color, material, condition, category.' }
      ]
    }]
  };

  const response = await generativeModel.generateContent(request);
  return JSON.parse(response.response.candidates[0].content.parts[0].text);
}
```

---

### Function 10: `onLayer2aComplete`

**Purpose**: Trigger Layer 2b (SerpAPI product identification) when Layer 2a completes

**Trigger**: Firestore onUpdate (`items/{itemId}` where `aiAnalysis.layer2a` is added)

**Implementation**:
```javascript
const axios = require('axios');

exports.onLayer2aComplete = functions.firestore
  .document('items/{itemId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Only trigger if Layer 2a just completed
    if (before.aiAnalysis?.layer2a || !after.aiAnalysis?.layer2a) {
      return;
    }

    const itemId = context.params.itemId;

    try {
      // Call SerpAPI (Layer 2b)
      const layer2bResult = await identifyProduct(after.imageURL, after.barcode);

      // Update item with Layer 2b results
      await change.after.ref.update({
        'aiAnalysis.layer2b': layer2bResult,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    } catch (error) {
      console.error('Layer 2b failed:', error);

      await change.after.ref.update({
        status: 'failed',
        errorMessage: error.message,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    }
  });

async function identifyProduct(imageURL, barcode) {
  if (barcode) {
    // Barcode lookup (Phase 2)
    return { productName: null, source: 'barcode', confidence: 0 };
  }

  // Google Lens visual search
  const response = await axios.get('https://serpapi.com/search', {
    params: {
      engine: 'google_lens',
      url: imageURL,
      api_key: process.env.SERPAPI_KEY
    }
  });

  const visualMatches = response.data.visual_matches || [];
  if (visualMatches.length === 0) {
    return { productName: null, source: 'visual', confidence: 0 };
  }

  return {
    productName: visualMatches[0].title,
    brand: visualMatches[0].brand || null,
    model: visualMatches[0].model || null,
    source: 'visual',
    confidence: visualMatches[0].position === 1 ? 0.92 : 0.75
  };
}
```

---

### Function 11: `onLayer2bComplete`

**Purpose**: Trigger Layer 3 (Claude synthesis) when Layer 2b completes

**Trigger**: Firestore onUpdate (`items/{itemId}` where `aiAnalysis.layer2b` is added)

**Implementation**:
```javascript
const Anthropic = require('@anthropic-ai/sdk');

exports.onLayer2bComplete = functions.firestore
  .document('items/{itemId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Only trigger if Layer 2b just completed
    if (before.aiAnalysis?.layer2b || !after.aiAnalysis?.layer2b) {
      return;
    }

    const itemId = context.params.itemId;

    try {
      // Call Claude API (Layer 3)
      const layer3Result = await synthesizeMetadata(after.aiAnalysis);

      // Update item with Layer 3 results and mark complete
      await change.after.ref.update({
        'aiAnalysis.layer3': layer3Result,
        status: 'complete',
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    } catch (error) {
      console.error('Layer 3 failed:', error);

      await change.after.ref.update({
        status: 'failed',
        errorMessage: error.message,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    }
  });

async function synthesizeMetadata(aiAnalysis) {
  const anthropic = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

  const prompt = `
Synthesize product metadata from AI analysis:

Layer 2a (Attributes): ${JSON.stringify(aiAnalysis.layer2a)}
Layer 2b (Product ID): ${JSON.stringify(aiAnalysis.layer2b)}

Provide:
1. Estimated market value (USD)
2. Confidence level (high/medium/low)
3. Reasoning

JSON format:
{
  "estimatedValue": number,
  "confidence": "high" | "medium" | "low",
  "reasoning": "string"
}
`;

  const message = await anthropic.messages.create({
    model: 'claude-sonnet-4-20250514',
    max_tokens: 512,
    messages: [{ role: 'user', content: prompt }]
  });

  return JSON.parse(message.content[0].text);
}
```

---

## Category 3: Scheduled Jobs

### Function 12: `cleanupDeletedItems`

**Purpose**: Hard delete soft-deleted items older than 90 days

**Schedule**: Daily at 2am UTC (`0 2 * * *`)

**Implementation**:
```javascript
exports.cleanupDeletedItems = functions.scheduler.onSchedule('0 2 * * *', async () => {
  const ninetyDaysAgo = new Date(Date.now() - 90 * 24 * 60 * 60 * 1000);

  const snapshot = await admin.firestore().collection('items')
    .where('deletedAt', '<', ninetyDaysAgo)
    .get();

  console.log(`Cleaning up ${snapshot.size} deleted items`);

  const batch = admin.firestore().batch();
  snapshot.docs.forEach(doc => batch.delete(doc.ref));

  await batch.commit();
});
```

---

### Function 13: `checkSubscriptionExpiry`

**Purpose**: Downgrade users with expired premium subscriptions

**Schedule**: Daily at 6am UTC (`0 6 * * *`)

**Implementation**:
```javascript
exports.checkSubscriptionExpiry = functions.scheduler.onSchedule('0 6 * * *', async () => {
  const now = new Date();

  const snapshot = await admin.firestore().collection('subscriptions')
    .where('status', '==', 'active')
    .where('currentPeriodEnd', '<', now)
    .get();

  console.log(`Found ${snapshot.size} expired subscriptions`);

  for (const doc of snapshot.docs) {
    const subscription = doc.data();

    // Downgrade user
    await admin.firestore().collection('users').doc(subscription.userId).update({
      subscriptionStatus: 'free',
      subscriptionExpiresAt: null,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    await admin.auth().setCustomUserClaims(subscription.userId, { premium: false });

    // Update subscription status
    await doc.ref.update({
      status: 'expired',
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
  }
});
```

---

## Free Tier Compliance

### Invocation Limits (Verified 2025-11-08)

**Free Tier**: 2 million invocations/month

**MVP Projection** (5,000 users @ Month 6):
- HTTP endpoints: 5,000 users × 30 sessions/month × 5 API calls = 750,000 invocations
- Firestore triggers: 5,000 users × 2.5 new items/month × 3 triggers = 37,500 invocations
- Scheduled jobs: 2 jobs × 30 days = 60 invocations
- **Total**: ~788,000 invocations/month (39% of free tier)

**Conclusion**: ✅ MVP stays within free tier

**Note**: Compute costs (vCPU-seconds, GiB-seconds) also apply but are minimal for MVP.

---

## Acceptance Criteria

- [x] ✅ 8 HTTP endpoints defined (health, CRUD items, user profile, Stripe webhook)
- [x] ✅ 3 Firestore triggers defined (Layer 2a → 2b → 3 AI pipeline)
- [x] ✅ 2 scheduled jobs defined (cleanup, subscription expiry)
- [x] ✅ Error handling patterns specified
- [x] ✅ Authentication verification implemented
- [x] ✅ Free tier compliance verified (788K invocations/month)

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-08 | 1.0 | Initial Cloud Functions structure, all endpoints defined | Cloud Backend Architect |

---

**This Cloud Functions architecture implements REST API (API-CONTRACTS-001), AI pipeline orchestration (DESIGN-004), and stays within free tier limits (verified for 5K users).**
