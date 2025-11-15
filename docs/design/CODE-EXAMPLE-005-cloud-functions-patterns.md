# CODE-EXAMPLE-005: Cloud Functions Patterns (Node.js 20)

**Created**: 2025-11-10
**Stage**: 3.2 - Backend Implementation Research
**References**:
- docs/validation/RESEARCH-VALIDATION-stage-3.2.md (Cloud Functions verified)
- docs/design/CLOUD-FUNCTIONS-001-function-structure.md (function architecture)
- docs/tech-stack/TECH-STACK-MAP-001-abundance-tech-stack.md

---

## Overview

This document provides production-ready Cloud Functions examples using Node.js 20 runtime with async/await patterns, comprehensive error handling, and Cloud Logging integration. All examples follow Google Cloud best practices for 2nd generation Cloud Functions.

**Runtime**: Node.js 20 (2nd gen Cloud Functions)
**Verified**: 2025-11-10 (RESEARCH-VALIDATION-stage-3.2.md)

---

## Example 1: HTTP Endpoint (analyzeItem)

### Purpose
Receive cropped object image from iOS client, upload to GCS, trigger AI analysis pipeline.

### Function Code

```javascript
/**
 * analyzeItem - HTTP endpoint for analyzing catalog items
 *
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 * @returns {Promise<void>}
 */
const functions = require('firebase-functions/v2');
const admin = require('firebase-admin');
const { onRequest } = require('firebase-functions/v2/https');
const Joi = require('joi');

// Initialize Firebase Admin SDK (once per cold start)
if (!admin.apps.length) {
  admin.initializeApp();
}

const firestore = admin.firestore();
const storage = admin.storage();
const auth = admin.auth();

/**
 * Request validation schema
 */
const analyzeItemSchema = Joi.object({
  imageBase64: Joi.string().required().max(10 * 1024 * 1024), // 10MB max
  barcode: Joi.string().optional().allow(null),
  category: Joi.string().optional().allow(null)
});

/**
 * Verify Firebase Auth token from Authorization header
 */
async function verifyAuthToken(req) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    throw new Error('Missing or invalid Authorization header');
  }

  const idToken = authHeader.split('Bearer ')[1];

  try {
    const decodedToken = await auth.verifyIdToken(idToken);
    return decodedToken;
  } catch (error) {
    console.error('Token verification failed:', error);
    throw new Error('Invalid authentication token');
  }
}

/**
 * Main HTTP handler
 */
exports.analyzeItem = onRequest(
  {
    timeoutSeconds: 60,
    memory: '512MiB',
    maxInstances: 100,
    region: 'us-central1'
  },
  async (req, res) => {
    const startTime = Date.now();

    try {
      // 1. CORS headers (if needed for web client in future)
      res.set('Access-Control-Allow-Origin', '*');

      if (req.method === 'OPTIONS') {
        res.set('Access-Control-Allow-Methods', 'POST');
        res.set('Access-Control-Allow-Headers', 'Authorization, Content-Type');
        return res.status(204).send('');
      }

      // 2. Verify HTTP method
      if (req.method !== 'POST') {
        return res.status(405).json({
          error: 'Method not allowed',
          message: 'Only POST requests are supported'
        });
      }

      // 3. Verify authentication
      let decodedToken;
      try {
        decodedToken = await verifyAuthToken(req);
      } catch (error) {
        return res.status(401).json({
          error: 'Unauthorized',
          message: error.message
        });
      }

      const userId = decodedToken.uid;
      const isPremium = decodedToken.premium === true;

      console.log('analyzeItem invoked', {
        userId,
        isPremium,
        timestamp: new Date().toISOString()
      });

      // 4. Validate request body
      const { error: validationError, value } = analyzeItemSchema.validate(req.body);

      if (validationError) {
        return res.status(400).json({
          error: 'Bad request',
          message: validationError.details[0].message
        });
      }

      const { imageBase64, barcode, category } = value;

      // 5. Check premium status (only premium users can use AI analysis)
      if (!isPremium) {
        return res.status(403).json({
          error: 'Forbidden',
          message: 'Premium subscription required for AI analysis'
        });
      }

      // 6. Create Firestore document
      const itemRef = firestore.collection('items').doc();
      const itemId = itemRef.id;

      // 7. Upload image to Cloud Storage
      const imageBuffer = Buffer.from(imageBase64, 'base64');
      const fileName = `users/${userId}/items/${itemId}/cropped-object.jpg`;
      const file = storage.bucket().file(fileName);

      await file.save(imageBuffer, {
        metadata: {
          contentType: 'image/jpeg',
          metadata: {
            userId,
            itemId,
            uploadedAt: new Date().toISOString()
          }
        }
      });

      // 8. Generate download URL (persistent, token-based)
      const [downloadURL] = await file.getSignedUrl({
        action: 'read',
        expires: '03-01-2500' // Far future = persistent download URL
      });

      // 9. Create item document in Firestore
      const itemData = {
        userId,
        itemId,
        imageUrl: downloadURL,
        barcode: barcode || null,
        category: category || null,
        status: 'processing', // Will trigger onItemCreated → Layer 2a
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        aiMetadata: {
          layer1: {
            source: 'ios_vision_framework',
            processedAt: new Date().toISOString()
          },
          layer2a: null,
          layer2b: null,
          layer3: null
        }
      };

      await itemRef.set(itemData);

      // 10. Log success
      const duration = Date.now() - startTime;
      console.log('analyzeItem completed', {
        userId,
        itemId,
        duration,
        imageSize: imageBuffer.length
      });

      // 11. Return success response
      return res.status(200).json({
        itemId,
        status: 'processing',
        message: 'Item created successfully. AI analysis in progress.'
      });

    } catch (error) {
      // Error handling
      const duration = Date.now() - startTime;
      console.error('analyzeItem failed', {
        error: error.message,
        stack: error.stack,
        duration
      });

      return res.status(500).json({
        error: 'Internal server error',
        message: 'Failed to process item. Please try again.'
      });
    }
  }
);
```

### Key Patterns

**✅ Async/Await**: All asynchronous operations use async/await (no callbacks)
**✅ Error Handling**: try/catch blocks with structured error responses
**✅ Auth Verification**: Firebase Auth token verification via `admin.auth().verifyIdToken()`
**✅ Request Validation**: Joi schema validation for request body
**✅ Structured Logging**: console.log with JSON objects (automatic Cloud Logging)
**✅ HTTP Status Codes**: 200 (success), 400 (bad request), 401 (unauthorized), 403 (forbidden), 500 (error)

### Testing

**Given**: Valid POST request with Firebase ID token and imageBase64
**When**: analyzeItem function is invoked
**Then**: Returns 200 with itemId, creates Firestore document with status="processing"

---

## Example 2: Firestore Trigger (onItemCreated)

### Purpose
Launch Layer 2a (Gemini attribute extraction) when new item is created.

### Function Code

```javascript
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { VertexAI } = require('@google-cloud/vertexai');

/**
 * Initialize Vertex AI client
 */
const vertexAI = new VertexAI({
  project: process.env.GCP_PROJECT_ID,
  location: 'us-central1'
});

/**
 * onItemCreated - Firestore trigger for Layer 2a (Gemini attribute extraction)
 *
 * Triggers when: items/{itemId} document is created
 * Action: Extract attributes (color, material, condition, category) via Gemini
 */
exports.onItemCreated = onDocumentCreated(
  {
    document: 'items/{itemId}',
    region: 'us-central1',
    memory: '512MiB',
    timeoutSeconds: 60
  },
  async (event) => {
    const snapshot = event.data;
    const itemId = event.params.itemId;

    if (!snapshot) {
      console.error('onItemCreated: No data in snapshot', { itemId });
      return;
    }

    const itemData = snapshot.data();
    const { userId, imageUrl, status } = itemData;

    // Only process if status is "processing" (avoid infinite loop)
    if (status !== 'processing') {
      console.log('onItemCreated: Skipping (status != processing)', { itemId, status });
      return;
    }

    console.log('onItemCreated: Starting Layer 2a', { itemId, userId });

    try {
      // 1. Call Gemini 2.5 Flash-Lite for attribute extraction
      const model = vertexAI.getGenerativeModel({
        model: 'gemini-2.5-flash-lite',
        generationConfig: {
          responseMimeType: 'application/json',
          responseSchema: {
            type: 'object',
            properties: {
              color: { type: 'string', description: 'Primary color of the object' },
              material: { type: 'string', description: 'Material (wood, metal, plastic, fabric, etc.)' },
              condition: { type: 'string', enum: ['new', 'like-new', 'good', 'fair', 'poor'] },
              category: { type: 'string', description: 'Category (furniture, electronics, clothing, etc.)' }
            },
            required: ['color', 'material', 'condition', 'category']
          }
        }
      });

      const prompt = `Analyze this household object image and extract its attributes:
- Color: The primary color
- Material: What it's made of (wood, metal, plastic, fabric, glass, etc.)
- Condition: Rate the condition (new, like-new, good, fair, poor)
- Category: What type of object is this (furniture, electronics, clothing, kitchenware, decor, etc.)

Be specific and accurate. Return JSON only.`;

      const result = await model.generateContent({
        contents: [
          {
            role: 'user',
            parts: [
              { text: prompt },
              {
                inlineData: {
                  mimeType: 'image/jpeg',
                  data: imageUrl // Download URL from GCS
                }
              }
            ]
          }
        ]
      });

      const response = result.response;
      const attributes = JSON.parse(response.text());

      console.log('onItemCreated: Layer 2a completed', { itemId, attributes });

      // 2. Update Firestore with Layer 2a results
      await firestore.collection('items').doc(itemId).update({
        'aiMetadata.layer2a': {
          ...attributes,
          processedAt: new Date().toISOString(),
          model: 'gemini-2.5-flash-lite',
          cost: 0.001 // ~$0.001 per image (verified)
        },
        status: 'layer2a_complete' // Will trigger onLayer2aComplete → Layer 2b
      });

    } catch (error) {
      console.error('onItemCreated: Layer 2a failed', {
        itemId,
        error: error.message,
        stack: error.stack
      });

      // Mark item as failed
      await firestore.collection('items').doc(itemId).update({
        status: 'failed',
        errorMessage: `Layer 2a failed: ${error.message}`,
        failedAt: admin.firestore.FieldValue.serverTimestamp()
      });

      // Store in dead letter queue
      await firestore.collection('failedItems').doc(itemId).set({
        itemId,
        userId,
        layer: 'layer2a',
        errorMessage: error.message,
        errorStack: error.stack,
        failedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    }
  }
);
```

### Key Patterns

**✅ Firestore Trigger**: onDocumentCreated for 'items/{itemId}' path
**✅ Idempotency**: Check status !== "processing" to avoid infinite loops
**✅ Vertex AI SDK**: @google-cloud/vertexai for Gemini 2.5 Flash-Lite
**✅ JSON Schema Mode**: Structured output (color, material, condition, category)
**✅ Error Handling**: try/catch with dead letter queue (failedItems collection)
**✅ Status Updates**: status="layer2a_complete" triggers next function

### Testing

**Given**: Item created with status="processing"
**When**: onItemCreated trigger fires
**Then**: Gemini extracts attributes, Firestore updated with layer2a results, status="layer2a_complete"

---

## Example 3: Scheduled Job (cleanupDeletedItems)

### Purpose
Daily cron job to permanently delete soft-deleted items older than 90 days.

### Function Code

```javascript
const { onSchedule } = require('firebase-functions/v2/scheduler');

/**
 * cleanupDeletedItems - Scheduled job to delete old soft-deleted items
 *
 * Schedule: Daily at 2:00 AM UTC
 * Action: Permanently delete items with deletedAt < 90 days ago
 */
exports.cleanupDeletedItems = onSchedule(
  {
    schedule: '0 2 * * *', // Cron: Every day at 2:00 AM UTC
    timeZone: 'UTC',
    region: 'us-central1',
    memory: '256MiB',
    timeoutSeconds: 540 // 9 minutes
  },
  async (event) => {
    console.log('cleanupDeletedItems: Starting cleanup job');

    try {
      // 1. Calculate 90-day threshold
      const ninetyDaysAgo = new Date();
      ninetyDaysAgo.setDate(ninetyDaysAgo.getDate() - 90);

      // 2. Query soft-deleted items older than 90 days
      const query = firestore
        .collection('items')
        .where('deletedAt', '<', admin.firestore.Timestamp.fromDate(ninetyDaysAgo))
        .limit(500); // Batch size (Firestore batch limit)

      const snapshot = await query.get();

      if (snapshot.empty) {
        console.log('cleanupDeletedItems: No items to delete');
        return;
      }

      console.log('cleanupDeletedItems: Found items to delete', {
        count: snapshot.size
      });

      // 3. Batch delete items (max 500 per batch)
      const batch = firestore.batch();

      snapshot.docs.forEach((doc) => {
        batch.delete(doc.ref);
      });

      await batch.commit();

      // 4. Delete associated images from Cloud Storage
      const deletePromises = snapshot.docs.map(async (doc) => {
        const itemId = doc.id;
        const userId = doc.data().userId;
        const fileName = `users/${userId}/items/${itemId}/cropped-object.jpg`;

        try {
          await storage.bucket().file(fileName).delete();
          console.log('cleanupDeletedItems: Deleted image', { fileName });
        } catch (error) {
          // Image may already be deleted (lifecycle policy), log and continue
          console.warn('cleanupDeletedItems: Failed to delete image', {
            fileName,
            error: error.message
          });
        }
      });

      await Promise.all(deletePromises);

      console.log('cleanupDeletedItems: Cleanup complete', {
        itemsDeleted: snapshot.size,
        imagesDeleted: deletePromises.length
      });

    } catch (error) {
      console.error('cleanupDeletedItems: Cleanup failed', {
        error: error.message,
        stack: error.stack
      });

      // Don't throw - allow cron to retry next day
    }
  }
);
```

### Key Patterns

**✅ Cloud Scheduler**: onSchedule with cron syntax ('0 2 * * *' = daily 2 AM UTC)
**✅ Batch Delete**: Firestore batch operations (max 500 documents)
**✅ Storage Cleanup**: Delete associated images from GCS
**✅ Error Resilience**: Don't throw errors (allow cron to retry next day)
**✅ Logging**: Structured logs for monitoring

### Testing

**Given**: 100 soft-deleted items with deletedAt < 90 days ago
**When**: cleanupDeletedItems cron job runs
**Then**: All 100 items deleted from Firestore, associated images deleted from GCS

---

## Deployment

### package.json

```json
{
  "name": "abundance-cloud-functions",
  "version": "1.0.0",
  "engines": {
    "node": "20"
  },
  "dependencies": {
    "firebase-admin": "^12.0.0",
    "firebase-functions": "^5.0.0",
    "@google-cloud/vertexai": "^1.0.0",
    "@anthropic-ai/sdk": "^0.20.0",
    "axios": "^1.6.0",
    "joi": "^17.11.0"
  },
  "devDependencies": {
    "jest": "^29.7.0",
    "supertest": "^6.3.0"
  }
}
```

### Deploy Commands

```bash
# Deploy all functions:
firebase deploy --only functions --project abundance-prod

# Deploy specific function:
firebase deploy --only functions:analyzeItem --project abundance-prod

# Deploy to staging:
firebase deploy --only functions --project abundance-staging
```

---

## References

- docs/validation/RESEARCH-VALIDATION-stage-3.2.md (Cloud Functions Node.js 20 verified)
- docs/design/CLOUD-FUNCTIONS-001-function-structure.md (function architecture)
- docs/tech-stack/TECH-STACK-MAP-001-abundance-tech-stack.md (technology stack)

---

**Status**: Production-ready code examples for Cloud Functions (Node.js 20, 2nd gen)
