import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { createItem } from './items/createItem';
import { getItem } from './items/getItem';
import { listItems } from './items/listItems';

// Import triggers
import { onItemCreated } from './triggers/onItemCreated';
import { onLayer2aComplete } from './triggers/onLayer2aComplete';
import { onLayer2bComplete } from './triggers/onLayer2bComplete';
import { onItemCreatedGemini3 } from './triggers/onItemCreatedGemini3';

// Import scheduled jobs
import { cleanupDeletedItemsScheduled } from './scheduled/cleanupDeletedItems';
import { checkSubscriptionExpiryScheduled } from './scheduled/checkSubscriptionExpiry';

// Import migrations
import { backfillFlattenedSchema } from './migrations/backfillFlattenedSchema';

// Initialize Firebase Admin SDK
admin.initializeApp();

// Health check endpoint (no auth required)
export const health = functions.https.onRequest((req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    service: 'abundance-backend'
  });
});

// Get user profile (auth required)
export const getUserProfile = functions.https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be signed in'
    );
  }

  const userId = context.auth.uid;

  // Fetch user document from Firestore
  const userDoc = await admin.firestore().collection('users').doc(userId).get();

  if (!userDoc.exists) {
    throw new functions.https.HttpsError('not-found', 'User profile not found');
  }

  return userDoc.data();
});

// Create item endpoint
export const createItemHTTP = functions.https.onRequest(async (req, res) => {
  // Verify Firebase Auth token
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith("Bearer ")) {
    res
      .status(401)
      .json({
        error: { code: "unauthenticated", message: "User must be signed in" },
      });
    return;
  }

  try {
    const token = authHeader.split("Bearer ")[1];
    const decodedToken = await admin.auth().verifyIdToken(token);
    const userId = decodedToken.uid;

    const { imageUrl, layer1Result, detectedBarcode } = req.body;

    if (!imageUrl || !layer1Result) {
      res
        .status(400)
        .json({
          error: {
            code: "invalid-argument",
            message: "Missing required fields",
          },
        });
      return;
    }

    const itemId = await createItem(
      userId,
      imageUrl,
      layer1Result,
      detectedBarcode
    );

    res.status(201).json({
      itemId,
      status: "processing",
      createdAt: new Date().toISOString(),
      layer1Complete: true,
      layer2aScheduled: true,
      layer2bScheduled: true,
    });
  } catch (error) {
    console.error("Error creating item:", error);
    res
      .status(500)
      .json({ error: { code: "internal", message: "Internal server error" } });
  }
});

// Get item endpoint
export const getItemHTTP = functions.https.onRequest(async (req, res) => {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith("Bearer ")) {
    res
      .status(401)
      .json({
        error: { code: "unauthenticated", message: "User must be signed in" },
      });
    return;
  }

  try {
    const token = authHeader.split("Bearer ")[1];
    await admin.auth().verifyIdToken(token);

    const itemId = req.query.itemId as string;
    if (!itemId) {
      res
        .status(400)
        .json({
          error: { code: "invalid-argument", message: "Missing itemId" },
        });
      return;
    }

    const item = await getItem(itemId);
    if (!item) {
      res
        .status(404)
        .json({ error: { code: "not-found", message: "Item not found" } });
      return;
    }

    res.status(200).json(item);
  } catch (error) {
    console.error("Error getting item:", error);
    res
      .status(500)
      .json({ error: { code: "internal", message: "Internal server error" } });
  }
});

// List items endpoint
export const listItemsHTTP = functions.https.onRequest(async (req, res) => {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith("Bearer ")) {
    res
      .status(401)
      .json({
        error: { code: "unauthenticated", message: "User must be signed in" },
      });
    return;
  }

  try {
    const token = authHeader.split("Bearer ")[1];
    const decodedToken = await admin.auth().verifyIdToken(token);
    const userId = decodedToken.uid;

    const limit = parseInt(req.query.limit as string) || 20;
    const items = await listItems(userId, limit);

    res.status(200).json({ items });
  } catch (error) {
    console.error("Error listing items:", error);
    res
      .status(500)
      .json({ error: { code: "internal", message: "Internal server error" } });
  }
});

// Export Firestore triggers
export { onItemCreated, onLayer2aComplete, onLayer2bComplete, onItemCreatedGemini3 };

// Export scheduled jobs
export { cleanupDeletedItemsScheduled, checkSubscriptionExpiryScheduled };

// Export migrations
export { backfillFlattenedSchema };
