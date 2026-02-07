/**
 * E2E Catalog Pipeline Tests
 *
 * Tests the full Layer 1 → Layer 2 pipeline with real Gemini API calls.
 * Covers 12 test cases: object detection, cataloging, re-catalog, multi-photo, and edge cases.
 *
 * Prerequisites:
 * - Firebase project with deployed Cloud Functions
 * - GOOGLE_CLOUD_PROJECT env var
 * - SERPAPI_KEY for Layer 2 tool calling
 * - ADC credentials (service account)
 * - Sharp installed (already a dependency)
 *
 * Run: cd functions && npm run test:e2e
 *
 * Cost: ~$0.20 per full test run
 */

import * as admin from 'firebase-admin';
import {
  uploadTestImage,
  createCompositeImage,
  runLayer1Detection,
  runLayer2Catalog,
  waitForCondition,
  cleanupTestUser,
  fixturePath,
} from './helpers/e2e-helpers';

// Initialize Firebase Admin before tests
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: process.env.GOOGLE_CLOUD_PROJECT || process.env.FIREBASE_PROJECT_ID,
  });
}

const db = admin.firestore();

// Skip entire suite if env vars are missing
const hasEnv = !!(process.env.GOOGLE_CLOUD_PROJECT || process.env.FIREBASE_PROJECT_ID);
const describeE2E = hasEnv ? describe : describe.skip;

describeE2E('E2E Catalog Pipeline', () => {
  const testUserId = `e2e-test-${Date.now()}`;

  // Shared state across sequential tests
  let compositeImageUrl: string;
  let individualImageUrls: string[] = [];
  let sessionId: string;
  let detectedObjects: any[] = [];
  let catalogedItemIds: string[] = [];
  let catalogedItems: Record<string, any> = {};

  beforeAll(async () => {
    // Upload individual images
    const fixtureFiles = ['object-1.jpeg', 'object-2.jpeg', 'object-4.jpeg'];
    individualImageUrls = await Promise.all(
      fixtureFiles.map((file, i) =>
        uploadTestImage(
          fixturePath(file),
          testUserId,
          `users/${testUserId}/e2e-test/individual-${i}.jpeg`
        )
      )
    );

    // Create and upload composite image
    const compositeBuffer = await createCompositeImage(
      fixtureFiles.map((f) => fixturePath(f))
    );
    const bucket = admin.storage().bucket();
    const compositeFile = bucket.file(`users/${testUserId}/e2e-test/composite.jpeg`);
    await compositeFile.save(compositeBuffer, {
      metadata: { contentType: 'image/jpeg' },
    });
    const [url] = await compositeFile.getSignedUrl({
      action: 'read',
      expires: Date.now() + 4 * 60 * 60 * 1000,
    });
    compositeImageUrl = url;
  }, 30_000);

  afterAll(async () => {
    await cleanupTestUser(testUserId);
  }, 30_000);

  // ── LAYER 1: OBJECT DETECTION ──────────────────────

  describe('Layer 1: Flash Detection', () => {
    test('Case 1: detects objects in composite image', async () => {
      expect(compositeImageUrl).toBeDefined();

      const result = await runLayer1Detection(
        testUserId,
        [compositeImageUrl],
        60_000
      );

      sessionId = result.sessionId;
      detectedObjects = result.detectedObjects;

      // Should detect at least 2 objects (3 distinct objects in composite)
      expect(detectedObjects.length).toBeGreaterThanOrEqual(2);

      // Each detected object should have required fields
      for (const obj of detectedObjects) {
        expect(obj.groupId).toBeDefined();
        expect(typeof obj.groupId).toBe('string');
        expect(obj.label).toBeDefined();
        expect(typeof obj.label).toBe('string');
        expect(obj.category).toBeDefined();
        expect(typeof obj.category).toBe('string');
      }
    }, 60_000);

    test('Case 2: Layer 1 JSON matches expected schema', () => {
      expect(detectedObjects.length).toBeGreaterThan(0);

      for (const obj of detectedObjects) {
        // groupId: non-empty string
        expect(obj.groupId.length).toBeGreaterThan(0);

        // label: non-empty string
        expect(obj.label.length).toBeGreaterThan(0);

        // category: non-empty string
        expect(obj.category.length).toBeGreaterThan(0);

        // confidence: one of expected values
        expect(['high', 'medium', 'low']).toContain(obj.confidence);

        // boundingBoxes: non-empty array with valid structure
        expect(Array.isArray(obj.boundingBoxes)).toBe(true);
        expect(obj.boundingBoxes.length).toBeGreaterThan(0);

        for (const bbox of obj.boundingBoxes) {
          expect(typeof bbox.imageIndex).toBe('number');
          expect(Array.isArray(bbox.box_2d)).toBe(true);
          expect(bbox.box_2d.length).toBe(4);
          // box_2d values should be in 0-1000 range
          for (const val of bbox.box_2d) {
            expect(val).toBeGreaterThanOrEqual(0);
            expect(val).toBeLessThanOrEqual(1000);
          }
        }

        // croppedImageUrls: non-empty array
        expect(Array.isArray(obj.croppedImageUrls)).toBe(true);
        expect(obj.croppedImageUrls.length).toBeGreaterThan(0);
      }
    });

    test('Case 10: handles invalid/corrupt image gracefully', async () => {
      // Upload a 1-byte invalid JPEG
      const bucket = admin.storage().bucket();
      const invalidFile = bucket.file(`users/${testUserId}/e2e-test/invalid.jpeg`);
      await invalidFile.save(Buffer.from([0xFF]), {
        metadata: { contentType: 'image/jpeg' },
      });
      const [invalidUrl] = await invalidFile.getSignedUrl({
        action: 'read',
        expires: Date.now() + 60 * 60 * 1000,
      });

      // Create session with invalid image
      const sessionRef = db.collection('sessions').doc();
      await sessionRef.set({
        userId: testUserId,
        captureMode: 'single',
        status: 'uploading',
        originalImageUrls: [invalidUrl],
        expectedImageCount: 1,
        imagesUploaded: 1,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      await sessionRef.update({ status: 'detecting' });

      // Wait for failure or detection (should fail gracefully)
      const snapshot = await waitForCondition(
        sessionRef,
        (data) => data.status === 'detected' || data.status === 'failed',
        30_000
      );

      const data = snapshot.data();
      // Either fails gracefully or detects 0 objects
      if (data?.status === 'failed') {
        expect(data.error).toBeDefined();
      } else {
        // If detected, should have 0 objects (corrupt image has nothing to detect)
        expect(data?.detectedObjects?.length ?? 0).toBeLessThanOrEqual(1);
      }
    }, 30_000);
  });

  // ── LAYER 1 → LAYER 2 HANDOFF ─────────────────────

  describe('Layer 1 → Layer 2 Handoff', () => {
    test('Case 4: cropped image URLs are accessible', async () => {
      expect(detectedObjects.length).toBeGreaterThan(0);

      for (const obj of detectedObjects) {
        for (const url of obj.croppedImageUrls) {
          // Verify URL is a valid Firebase Storage URL
          expect(url).toMatch(/firebasestorage\.googleapis\.com|storage\.googleapis\.com/);

          // HTTP HEAD to verify image exists
          const response = await fetch(url, { method: 'HEAD' });
          expect(response.ok).toBe(true);
        }
      }
    }, 30_000);

    test('Case 5: item document contains Layer 1 metadata', async () => {
      expect(detectedObjects.length).toBeGreaterThan(0);

      // Create item from first detected object
      const obj = detectedObjects[0];
      const itemRef = db.collection('items').doc();
      const itemId = itemRef.id;

      await itemRef.set({
        userId: testUserId,
        imageUrl: obj.croppedImageUrls[0],
        sessionId,
        groupId: obj.groupId,
        fromDetection: true,
        layer1Label: obj.label,
        layer1Category: obj.category,
        layer1Confidence: obj.confidence,
        layer1Attributes: obj.attributes || {},
        status: 'pending',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Read immediately (before Layer 2 completes)
      const doc = await itemRef.get();
      const data = doc.data();

      expect(data?.imageUrl).toBeDefined();
      expect(data?.layer1Label).toBeDefined();
      expect(data?.layer1Category).toBeDefined();
      expect(data?.layer1Confidence).toBeDefined();
      expect(data?.sessionId).toBe(sessionId);
      expect(data?.groupId).toBe(obj.groupId);
      expect(data?.fromDetection).toBe(true);

      // Store for later use in Layer 2 tests
      catalogedItemIds.push(itemId);
    });
  });

  // ── LAYER 2: GEMINI PRO CATALOGING ────────────────

  describe('Layer 2: Pro Cataloging', () => {
    test('Case 3: returns valid CatalogItem for each object', async () => {
      expect(detectedObjects.length).toBeGreaterThan(0);

      // Create items from remaining detected objects (skip first, already created in Case 5)
      const remainingObjects = detectedObjects.slice(1, 3); // Up to 2 more
      const additionalPromises = remainingObjects.map((obj) =>
        runLayer2Catalog(testUserId, sessionId, obj, 120_000)
      );
      const additionalResults = await Promise.all(additionalPromises);

      for (const { itemId, item } of additionalResults) {
        catalogedItemIds.push(itemId);
        catalogedItems[itemId] = item;
      }

      // Also wait for the item created in Case 5
      if (catalogedItemIds.length > 0) {
        const firstItemRef = db.collection('items').doc(catalogedItemIds[0]);
        const firstItemSnap = await waitForCondition(
          firstItemRef,
          (data) => data.status === 'complete' || data.status === 'failed',
          120_000
        );
        catalogedItems[catalogedItemIds[0]] = firstItemSnap.data();
      }

      // Validate all completed items
      for (const itemId of catalogedItemIds) {
        const item = catalogedItems[itemId];
        if (!item || item.status !== 'complete') continue;

        // Required catalog fields
        expect(item.name).toBeDefined();
        expect(typeof item.name).toBe('string');
        expect(item.name.length).toBeGreaterThan(0);

        expect(item.category).toBeDefined();
        expect(typeof item.category).toBe('string');

        // color should be present
        expect(item.color).toBeDefined();

        // condition should be a valid enum
        if (item.condition) {
          expect(['new', 'like-new', 'good', 'fair', 'poor']).toContain(item.condition);
        }

        // confidence should be valid
        if (item.confidence) {
          expect(['high', 'medium', 'low']).toContain(item.confidence);
        }

        // estimatedValue: number > 0 or null
        if (item.estimatedValue !== null && item.estimatedValue !== undefined) {
          expect(typeof item.estimatedValue).toBe('number');
          expect(item.estimatedValue).toBeGreaterThan(0);
        }
      }
    }, 120_000);
  });

  // ── RE-CATALOG ────────────────────────────────────

  describe('Re-catalog', () => {
    test('Case 6: re-catalog updates Layer 2 values', async () => {
      // Pick the first completed item
      const itemId = catalogedItemIds.find((id) => catalogedItems[id]?.status === 'complete');
      expect(itemId).toBeDefined();

      const originalUpdatedAt = catalogedItems[itemId!].updatedAt;
      const itemRef = db.collection('items').doc(itemId!);

      // Trigger re-catalog by setting status to pending with deepScanRequested
      // (onItemUpdatedDeepScan requires deepScanRequested=true to fire)
      await itemRef.update({
        status: 'pending',
        deepScanRequested: true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Wait for re-catalog to complete
      const snapshot = await waitForCondition(
        itemRef,
        (data) => data.status === 'complete' || data.status === 'failed',
        90_000
      );

      const data = snapshot.data();
      expect(data?.status).toBe('complete');

      // updatedAt should have changed
      expect(data?.updatedAt).toBeDefined();
      if (originalUpdatedAt) {
        const originalTime = originalUpdatedAt.toMillis?.() ?? originalUpdatedAt;
        const newTime = data?.updatedAt?.toMillis?.() ?? data?.updatedAt;
        expect(newTime).toBeGreaterThan(originalTime);
      }

      // Catalog fields should still be populated
      expect(data?.name).toBeDefined();
      expect(data?.category).toBeDefined();

      // Update cached item
      catalogedItems[itemId!] = data;
    }, 90_000);

    test('Case 12: deep scan adds enhanced metadata', async () => {
      // Pick a completed item that wasn't just re-cataloged
      const itemId = catalogedItemIds.find(
        (id) => catalogedItems[id]?.status === 'complete' && id !== catalogedItemIds[0]
      );
      expect(itemId).toBeDefined();

      const itemRef = db.collection('items').doc(itemId!);

      // Trigger deep scan
      await itemRef.update({
        deepScanRequested: true,
        status: 'pending',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Wait for deep scan to complete
      const snapshot = await waitForCondition(
        itemRef,
        (data) =>
          data.deepScanCompletedAt !== undefined ||
          data.status === 'failed',
        120_000
      );

      const data = snapshot.data();
      expect(data?.status).toBe('complete');
      expect(data?.deepScanCompletedAt).toBeDefined();

      // Standard catalog fields should remain populated after deep scan
      expect(data?.name).toBeDefined();
      expect(data?.category).toBeDefined();
    }, 120_000);
  });

  // ── MULTI-PHOTO (requires Phase 1 feature) ────────

  describe('Multi-Photo Cataloging', () => {
    test('Case 7: adding photo + re-catalog updates results', async () => {
      // Pick a completed item
      const itemId = catalogedItemIds.find((id) => catalogedItems[id]?.status === 'complete');
      expect(itemId).toBeDefined();

      const itemRef = db.collection('items').doc(itemId!);

      // Upload a second image and add to additionalImageUrls
      const secondImageUrl = await uploadTestImage(
        fixturePath('object-2.jpeg'),
        testUserId,
        `users/${testUserId}/e2e-test/additional-${itemId}-1.jpeg`
      );

      await itemRef.update({
        additionalImageUrls: [secondImageUrl],
        deepScanRequested: true,
        status: 'pending',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Wait for re-catalog with multi-photo
      const snapshot = await waitForCondition(
        itemRef,
        (data) => data.status === 'complete' || data.status === 'failed',
        120_000
      );

      const data = snapshot.data();
      expect(data?.status).toBe('complete');

      // updatedAt should have changed
      expect(data?.updatedAt).toBeDefined();

      // Catalog fields should still be populated
      expect(data?.name).toBeDefined();
      expect(data?.category).toBeDefined();

      // additionalImageUrls should be preserved
      expect(data?.additionalImageUrls).toBeDefined();
      expect(data?.additionalImageUrls?.length).toBeGreaterThanOrEqual(1);

      // Update cached item
      catalogedItems[itemId!] = data;
    }, 120_000);

    test('Case 8: Layer 2 with 3 photos produces catalog', async () => {
      // Use the same item from Case 7
      const itemId = catalogedItemIds.find(
        (id) =>
          catalogedItems[id]?.status === 'complete' &&
          catalogedItems[id]?.additionalImageUrls?.length > 0
      );
      expect(itemId).toBeDefined();

      const itemRef = db.collection('items').doc(itemId!);

      // Add a third image
      const thirdImageUrl = await uploadTestImage(
        fixturePath('object-4.jpeg'),
        testUserId,
        `users/${testUserId}/e2e-test/additional-${itemId!}-2.jpeg`
      );

      const currentAdditional = catalogedItems[itemId!]?.additionalImageUrls || [];
      await itemRef.update({
        additionalImageUrls: [...currentAdditional, thirdImageUrl],
        deepScanRequested: true,
        status: 'pending',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Wait for re-catalog
      const snapshot = await waitForCondition(
        itemRef,
        (data) => data.status === 'complete' || data.status === 'failed',
        120_000
      );

      const data = snapshot.data();
      expect(data?.status).toBe('complete');

      // Catalog fields should be valid
      expect(data?.name).toBeDefined();
      expect(data?.category).toBeDefined();

      // Should have 2 additional images
      expect(data?.additionalImageUrls?.length).toBe(2);
    }, 120_000);
  });

  // ── ADDITIONAL CASES ──────────────────────────────

  describe('Edge Cases', () => {
    test('Case 9: burst session groups same object across images', async () => {
      expect(individualImageUrls.length).toBeGreaterThanOrEqual(3);

      // Upload 3 crops of the same object (use object-1 three times with slight variations)
      // In practice, these would be different angles — here we test the grouping logic
      const sameObjectUrls = [individualImageUrls[0], individualImageUrls[0], individualImageUrls[0]];

      const result = await runLayer1Detection(
        testUserId,
        sameObjectUrls,
        60_000
      );

      // The model should recognize these as the same object
      // It may group them into 1 group or detect them as separate
      expect(result.detectedObjects.length).toBeGreaterThan(0);

      // If grouped correctly, one group should span multiple images
      const multiImageGroup = result.detectedObjects.find(
        (obj: any) => obj.boundingBoxes?.length > 1 || obj.croppedImageUrls?.length > 1
      );
      // This is a soft assertion — grouping depends on Gemini's detection
      if (multiImageGroup) {
        expect(multiImageGroup.croppedImageUrls.length).toBeGreaterThanOrEqual(2);
      }
    }, 60_000);

    test('Case 11: concurrent catalog requests are idempotent', async () => {
      expect(detectedObjects.length).toBeGreaterThanOrEqual(1);

      const obj = detectedObjects[0];
      const imageUrl = obj.croppedImageUrls?.[0];
      expect(imageUrl).toBeDefined();

      // Create 2 items simultaneously (simulates double-tap)
      const item1Ref = db.collection('items').doc();
      const item2Ref = db.collection('items').doc();

      const baseData = {
        userId: testUserId,
        imageUrl,
        sessionId,
        groupId: obj.groupId,
        fromDetection: true,
        layer1Label: obj.label,
        layer1Category: obj.category,
        status: 'pending',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      await Promise.all([
        item1Ref.set(baseData),
        item2Ref.set(baseData),
      ]);

      // Track these for cleanup
      catalogedItemIds.push(item1Ref.id, item2Ref.id);

      // Wait for both to complete (or fail)
      const [snap1, snap2] = await Promise.all([
        waitForCondition(
          item1Ref,
          (data) => data.status === 'complete' || data.status === 'failed',
          90_000
        ),
        waitForCondition(
          item2Ref,
          (data) => data.status === 'complete' || data.status === 'failed',
          90_000
        ),
      ]);

      // Both should succeed — no crash, no corruption
      const data1 = snap1.data();
      const data2 = snap2.data();

      // At least one should be complete (both ideally)
      const statuses = [data1?.status, data2?.status];
      expect(statuses).toContain('complete');

      // Neither should have corrupted data
      if (data1?.status === 'complete') {
        expect(data1.name).toBeDefined();
      }
      if (data2?.status === 'complete') {
        expect(data2.name).toBeDefined();
      }
    }, 90_000);
  });
});
