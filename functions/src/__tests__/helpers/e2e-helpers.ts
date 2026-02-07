/**
 * E2E Test Helpers
 *
 * Shared utilities for the E2E catalog pipeline test suite.
 * Handles image upload, session creation, polling, and cleanup.
 */

import * as admin from 'firebase-admin';
import * as fs from 'fs';
import * as path from 'path';
import sharp from 'sharp';

// Lazy initialization — helpers are imported before admin.initializeApp() in test files
function getDb() { return admin.firestore(); }
function getStorageBucket() { return admin.storage(); }

/**
 * Upload a local image to Firebase Storage and return the download URL.
 *
 * @param localPath - Path to the local image file
 * @param _userId - User ID (reserved for future path validation; not used in upload)
 * @param remotePath - GCS object path (should include userId prefix)
 */
export async function uploadTestImage(
  localPath: string,
  _userId: string,
  remotePath: string
): Promise<string> {
  const bucket = getStorageBucket().bucket();
  const file = bucket.file(remotePath);

  const imageBuffer = fs.readFileSync(localPath);
  await file.save(imageBuffer, {
    metadata: { contentType: 'image/jpeg' },
  });

  // Generate a signed URL valid for 4 hours (generous for slow CI environments)
  const [url] = await file.getSignedUrl({
    action: 'read',
    expires: Date.now() + 4 * 60 * 60 * 1000,
  });

  return url;
}

/**
 * Create a composite image by stitching multiple images horizontally using Sharp.
 */
export async function createCompositeImage(
  imagePaths: string[],
  layout: 'horizontal' | 'grid' = 'horizontal'
): Promise<Buffer> {
  // Read all images and get their metadata
  const images = await Promise.all(
    imagePaths.map(async (p) => {
      const buffer = fs.readFileSync(p);
      const metadata = await sharp(buffer).metadata();
      return { buffer, width: metadata.width || 400, height: metadata.height || 400 };
    })
  );

  if (layout === 'horizontal') {
    // Normalize all images to the same height
    const targetHeight = 400;
    const resized = await Promise.all(
      images.map(async (img) => {
        const resizedBuffer = await sharp(img.buffer)
          .resize({ height: targetHeight })
          .toBuffer();
        const meta = await sharp(resizedBuffer).metadata();
        return { buffer: resizedBuffer, width: meta.width || 400, height: targetHeight };
      })
    );

    const totalWidth = resized.reduce((sum, img) => sum + img.width, 0);

    let xOffset = 0;
    const composites = resized.map((img) => {
      const composite = { input: img.buffer, left: xOffset, top: 0 };
      xOffset += img.width;
      return composite;
    });

    return sharp({
      create: {
        width: totalWidth,
        height: targetHeight,
        channels: 3,
        background: { r: 255, g: 255, b: 255 },
      },
    })
      .composite(composites)
      .jpeg({ quality: 85 })
      .toBuffer();
  }

  // Grid layout (2-column) — not used in current tests but available
  throw new Error('Grid layout not implemented');
}

/**
 * Create a Firestore session document, mark it for detection,
 * and wait for Layer 1 to complete.
 */
export async function runLayer1Detection(
  userId: string,
  imageUrls: string[],
  timeoutMs: number = 60_000
): Promise<{ sessionId: string; detectedObjects: any[] }> {
  const db = getDb();
  const sessionRef = db.collection('sessions').doc();
  const sessionId = sessionRef.id;

  // Create session document
  await sessionRef.set({
    userId,
    captureMode: imageUrls.length > 1 ? 'burst' : 'single',
    status: 'uploading',
    originalImageUrls: imageUrls,
    expectedImageCount: imageUrls.length,
    imagesUploaded: imageUrls.length,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Trigger detection by setting status to 'detecting'
  await sessionRef.update({ status: 'detecting' });

  // Wait for detection to complete
  const snapshot = await waitForCondition(
    sessionRef,
    (data) => data.status === 'detected' || data.status === 'failed',
    timeoutMs
  );

  const data = snapshot.data();
  if (data?.status === 'failed') {
    throw new Error(`Layer 1 detection failed: ${data.error || 'Unknown error'}`);
  }

  return {
    sessionId,
    detectedObjects: data?.detectedObjects || [],
  };
}

/**
 * Create an item from a detected object and wait for Layer 2 cataloging to complete.
 */
export async function runLayer2Catalog(
  userId: string,
  sessionId: string,
  detectedObject: any,
  timeoutMs: number = 120_000
): Promise<{ itemId: string; item: any }> {
  const db = getDb();
  const itemRef = db.collection('items').doc();
  const itemId = itemRef.id;

  // Use first cropped image as primary
  const imageUrl = detectedObject.croppedImageUrls?.[0];
  if (!imageUrl) {
    throw new Error('Detected object has no cropped image URLs');
  }

  // Create item document to trigger Layer 2
  await itemRef.set({
    userId,
    imageUrl,
    sessionId,
    groupId: detectedObject.groupId,
    fromDetection: true,
    layer1Label: detectedObject.label,
    layer1Category: detectedObject.category,
    layer1Confidence: detectedObject.confidence,
    layer1Attributes: detectedObject.attributes || {},
    status: 'pending',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Wait for Layer 2 to complete
  const snapshot = await waitForCondition(
    itemRef,
    (data) => data.status === 'complete' || data.status === 'failed',
    timeoutMs
  );

  const data = snapshot.data();
  if (data?.status === 'failed') {
    throw new Error(`Layer 2 cataloging failed for ${itemId}: ${data.error || 'Unknown error'}`);
  }

  return { itemId, item: data };
}

/**
 * Poll a Firestore document until a predicate is met or timeout expires.
 */
export async function waitForCondition(
  docRef: admin.firestore.DocumentReference,
  predicate: (data: any) => boolean,
  timeoutMs: number
): Promise<admin.firestore.DocumentSnapshot> {
  const start = Date.now();
  const pollIntervalMs = 2000;

  while (Date.now() - start < timeoutMs) {
    const snapshot = await docRef.get();
    const data = snapshot.data();
    if (data && predicate(data)) {
      return snapshot;
    }
    await new Promise((resolve) => setTimeout(resolve, pollIntervalMs));
  }

  // Return last state on timeout
  const finalSnapshot = await docRef.get();
  const finalData = finalSnapshot.data();
  throw new Error(
    `Timeout after ${timeoutMs}ms waiting for condition on ${docRef.path}. ` +
    `Last status: ${finalData?.status || 'unknown'}`
  );
}

/**
 * Clean up all test artifacts for a given test user ID.
 */
export async function cleanupTestUser(userId: string): Promise<void> {
  const db = getDb();

  // Delete items
  const items = await db.collection('items').where('userId', '==', userId).get();
  const itemBatch = db.batch();
  items.docs.forEach((doc) => itemBatch.delete(doc.ref));
  if (items.docs.length > 0) await itemBatch.commit();

  // Delete sessions
  const sessions = await db.collection('sessions').where('userId', '==', userId).get();
  const sessionBatch = db.batch();
  sessions.docs.forEach((doc) => sessionBatch.delete(doc.ref));
  if (sessions.docs.length > 0) await sessionBatch.commit();

  // Delete storage objects (best-effort)
  try {
    const bucket = getStorageBucket().bucket();
    const [files] = await bucket.getFiles({ prefix: `users/${userId}/` });
    await Promise.all(files.map((f) => f.delete().catch(() => {})));

    // Also clean up crops stored under sessions
    const [sessionFiles] = await bucket.getFiles({ prefix: `sessions/` });
    const testFiles = sessionFiles.filter((f) =>
      items.docs.some((doc) => f.name.includes(doc.id))
    );
    await Promise.all(testFiles.map((f) => f.delete().catch(() => {})));
  } catch {
    // Storage cleanup is best-effort
  }
}

/**
 * Get path to test fixture image.
 */
export function fixturePath(filename: string): string {
  return path.join(__dirname, '..', 'fixtures', filename);
}
