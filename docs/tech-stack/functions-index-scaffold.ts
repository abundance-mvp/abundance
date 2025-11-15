/**
 * Abundance MVP Cloud Functions
 *
 * Runtime: Node.js 20
 * Firebase Functions SDK: v5.0.0+
 * Firebase Admin SDK: v12.0.0+
 */

import * as admin from 'firebase-admin';
import { onRequest } from 'firebase-functions/v2/https';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { defineSecret } from 'firebase-functions/v2/params';

// Initialize Firebase Admin SDK
admin.initializeApp();

// Define secrets
const anthropicKey = defineSecret('ANTHROPIC_API_KEY');
const serpapiKey = defineSecret('SERPAPI_KEY');

// ========================================
// HTTP ENDPOINTS (8 functions)
// ========================================

/**
 * Health check endpoint (no auth required)
 * GET /api/health
 */
export const health = onRequest(
  { region: 'us-central1' },
  async (req, res) => {
    res.json({
      status: 'ok',
      timestamp: new Date().toISOString()
    });
  }
);

/**
 * Create catalog item (with Layer 1 results)
 * POST /api/items/analyze
 */
export const analyzeItem = onRequest(
  {
    region: 'us-central1',
    memory: '512MiB',
    timeoutSeconds: 60,
    secrets: [anthropicKey, serpapiKey]
  },
  async (req, res) => {
    // TODO: Implement (see CODE-EXAMPLE-005)
    res.status(501).json({ error: 'Not implemented' });
  }
);

/**
 * Get catalog item by ID
 * GET /api/items/:id
 */
export const getItem = onRequest(
  { region: 'us-central1' },
  async (req, res) => {
    // TODO: Implement
    res.status(501).json({ error: 'Not implemented' });
  }
);

/**
 * List user's catalog items (paginated)
 * GET /api/items?limit=50&offset=0
 */
export const listItems = onRequest(
  { region: 'us-central1' },
  async (req, res) => {
    // TODO: Implement
    res.status(501).json({ error: 'Not implemented' });
  }
);

/**
 * Update catalog item
 * PUT /api/items/:id
 */
export const updateItem = onRequest(
  { region: 'us-central1' },
  async (req, res) => {
    // TODO: Implement
    res.status(501).json({ error: 'Not implemented' });
  }
);

/**
 * Soft delete catalog item
 * DELETE /api/items/:id
 */
export const deleteItem = onRequest(
  { region: 'us-central1' },
  async (req, res) => {
    // TODO: Implement
    res.status(501).json({ error: 'Not implemented' });
  }
);

/**
 * Get user profile
 * GET /api/users/:id
 */
export const getUserProfile = onRequest(
  { region: 'us-central1' },
  async (req, res) => {
    // TODO: Implement
    res.status(501).json({ error: 'Not implemented' });
  }
);

/**
 * Stripe webhook (subscription lifecycle)
 * POST /api/subscriptions/webhook
 */
export const handleStripeWebhook = onRequest(
  { region: 'us-central1' },
  async (req, res) => {
    // TODO: Implement (Phase 2)
    res.status(501).json({ error: 'Not implemented - Phase 2' });
  }
);

// ========================================
// FIRESTORE TRIGGERS (3 functions)
// ========================================

/**
 * onItemCreated - Launch Layer 2a (Gemini attribute extraction)
 * Triggers when: items/{itemId} document is created
 */
export const onItemCreated = onDocumentCreated(
  {
    document: 'items/{itemId}',
    region: 'us-central1',
    memory: '512MiB',
    timeoutSeconds: 60,
    secrets: [anthropicKey]
  },
  async (event) => {
    // TODO: Implement (see CODE-EXAMPLE-005)
    console.log('onItemCreated triggered', event.params.itemId);
  }
);

/**
 * onLayer2aComplete - Launch Layer 2b (SerpAPI product ID)
 * Triggers when: item status changes to "layer2a_complete"
 */
export const onLayer2aComplete = onDocumentCreated(
  {
    document: 'items/{itemId}',
    region: 'us-central1',
    memory: '512MiB',
    timeoutSeconds: 60,
    secrets: [serpapiKey]
  },
  async (event) => {
    // TODO: Implement
    console.log('onLayer2aComplete triggered', event.params.itemId);
  }
);

/**
 * onLayer2bComplete - Launch Layer 3 (Claude synthesis)
 * Triggers when: item status changes to "layer2b_complete"
 */
export const onLayer2bComplete = onDocumentCreated(
  {
    document: 'items/{itemId}',
    region: 'us-central1',
    memory: '512MiB',
    timeoutSeconds: 60,
    secrets: [anthropicKey]
  },
  async (event) => {
    // TODO: Implement
    console.log('onLayer2bComplete triggered', event.params.itemId);
  }
);

// ========================================
// SCHEDULED JOBS (2 functions)
// ========================================

/**
 * cleanupDeletedItems - Daily cron job to delete old soft-deleted items
 * Schedule: Daily at 2:00 AM UTC
 */
export const cleanupDeletedItems = onSchedule(
  {
    schedule: '0 2 * * *', // Cron: Every day at 2:00 AM UTC
    timeZone: 'UTC',
    region: 'us-central1',
    memory: '256MiB',
    timeoutSeconds: 540 // 9 minutes
  },
  async (event) => {
    // TODO: Implement (see CODE-EXAMPLE-005)
    console.log('cleanupDeletedItems job triggered');
  }
);

/**
 * checkSubscriptionExpiry - Daily cron job to downgrade expired premium users
 * Schedule: Daily at 6:00 AM UTC
 */
export const checkSubscriptionExpiry = onSchedule(
  {
    schedule: '0 6 * * *', // Cron: Every day at 6:00 AM UTC
    timeZone: 'UTC',
    region: 'us-central1',
    memory: '256MiB',
    timeoutSeconds: 300
  },
  async (event) => {
    // TODO: Implement (Phase 2)
    console.log('checkSubscriptionExpiry job triggered');
  }
);
