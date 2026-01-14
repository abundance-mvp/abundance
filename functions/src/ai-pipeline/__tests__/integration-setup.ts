/**
 * Integration test setup for Gemini 3 Pro pipeline.
 *
 * IMPORTANT: Integration tests require:
 * 1. Real Firebase Storage (emulator doesn't support getSignedUrl)
 * 2. Valid API keys in environment variables
 * 3. Service account with storage.objectViewer and serviceAccountTokenCreator roles
 *
 * Run with: npm run test:integration
 *
 * Environment Variables Required:
 * - GOOGLE_CLOUD_PROJECT: GCP project ID with Vertex AI enabled
 * - SERPAPI_KEY: SerpAPI key (Developer plan recommended)
 * - FIREBASE_PROJECT_ID: Firebase project with Storage enabled
 * - GOOGLE_APPLICATION_CREDENTIALS: Path to service account JSON (optional for local dev)
 */

import * as admin from 'firebase-admin';
import * as path from 'path';

// Check for required environment variables
const requiredEnvVars = ['GOOGLE_CLOUD_PROJECT', 'SERPAPI_KEY', 'FIREBASE_PROJECT_ID'];

/**
 * Validates that all required environment variables are set.
 * Throws an error if any are missing.
 */
export function validateIntegrationEnvironment(): void {
  const missing = requiredEnvVars.filter((v) => !process.env[v]);
  if (missing.length > 0) {
    throw new Error(
      `Integration tests require environment variables: ${missing.join(', ')}\n` +
        'Create a .env.integration file or set them in your shell.\n' +
        'See .env.integration.example for template.'
    );
  }
}

/**
 * Initializes Firebase Admin SDK for integration tests.
 * Uses application default credentials in GCP or service account JSON locally.
 */
export function initializeFirebaseAdmin(): admin.app.App {
  // Use application default credentials for GCP environment
  // Or service account JSON for local development
  const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;

  if (admin.apps.length > 0) {
    return admin.apps[0]!;
  }

  const projectId = process.env.FIREBASE_PROJECT_ID;
  const storageBucket = `${projectId}.firebasestorage.app`;

  if (serviceAccountPath) {
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    const serviceAccount = require(path.resolve(serviceAccountPath));
    return admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      storageBucket,
    });
  }

  // Use ADC in GCP environment
  return admin.initializeApp({
    storageBucket,
  });
}

/**
 * Uploads a test image to Firebase Storage and returns a signed URL.
 * Signed URL is valid for 1 hour.
 */
export async function uploadTestImage(
  bucket: ReturnType<admin.storage.Storage['bucket']>,
  localPath: string,
  destinationPath: string
): Promise<string> {
  await bucket.upload(localPath, {
    destination: destinationPath,
    metadata: {
      contentType: 'image/jpeg',
    },
  });

  const file = bucket.file(destinationPath);
  const [signedUrl] = await file.getSignedUrl({
    action: 'read',
    expires: Date.now() + 60 * 60 * 1000, // 1 hour
  });

  return signedUrl;
}

/**
 * Cleans up a test image from Firebase Storage.
 * Silently ignores if the file doesn't exist.
 */
export async function cleanupTestImage(
  bucket: ReturnType<admin.storage.Storage['bucket']>,
  destinationPath: string
): Promise<void> {
  try {
    await bucket.file(destinationPath).delete();
  } catch (error) {
    // Ignore if file doesn't exist
    console.log(`Cleanup: ${destinationPath} not found, skipping`);
  }
}

/**
 * Private test bucket for integration tests.
 * SECURITY: This bucket has public access prevention enforced.
 * All access requires authenticated service accounts.
 */
export const TEST_BUCKET_NAME = 'abundance-test-private';

/**
 * Pre-uploaded test images in the private bucket.
 * These images are used for integration testing without exposing personal data.
 */
export const TEST_IMAGES = {
  PRODUCT_IMAGE: 'integration-tests/test-01-p1.jpg',
  OBJECT_1: 'integration-tests/test-01-p4_obj-1.png',
  OBJECT_2: 'integration-tests/test-01-p4_obj-2.png',
} as const;

/**
 * Downloads a test image from the private bucket and returns it as a base64 data URL.
 * SECURITY: Image data stays in memory, never exposed via public URL.
 *
 * This approach is more secure than signed URLs because:
 * - No URL is ever exposed or logged
 * - Image data is only in process memory
 * - No time-limited URL that could be captured/replayed
 *
 * @param imagePath - Path to the image within the test bucket
 * @returns Base64 data URL (data:image/jpeg;base64,...)
 */
export async function getTestImageAsDataUrl(imagePath: string): Promise<string> {
  const storage = admin.storage();
  const bucket = storage.bucket(TEST_BUCKET_NAME);
  const file = bucket.file(imagePath);

  const [buffer] = await file.download();
  const base64 = buffer.toString('base64');

  // Determine MIME type from file extension
  const ext = imagePath.split('.').pop()?.toLowerCase();
  const mimeType = ext === 'png' ? 'image/png' : 'image/jpeg';

  return `data:${mimeType};base64,${base64}`;
}

/**
 * @deprecated Use getTestImageAsDataUrl instead for better security.
 * Gets a time-limited signed URL for a test image in the private bucket.
 * SECURITY: Signed URLs expire after 15 minutes to minimize exposure.
 *
 * @param imagePath - Path to the image within the test bucket
 * @param expirationMinutes - URL expiration time in minutes (default: 15)
 * @returns Time-limited signed URL for authenticated access
 */
export async function getTestImageSignedUrl(
  imagePath: string,
  expirationMinutes: number = 15
): Promise<string> {
  const storage = admin.storage();
  const bucket = storage.bucket(TEST_BUCKET_NAME);
  const file = bucket.file(imagePath);

  const [signedUrl] = await file.getSignedUrl({
    action: 'read',
    expires: Date.now() + expirationMinutes * 60 * 1000,
  });

  return signedUrl;
}

/**
 * Creates a test item document structure for integration testing.
 */
export function createTestItemDocument(imageUrl: string, barcode?: string): Record<string, unknown> {
  return {
    userId: 'integration-test-user',
    imageUrl,
    status: 'pending',
    createdAt: new Date().toISOString(),
    layer1Result: {
      objects: [
        {
          label: 'bottle',
          confidence: 0.95,
          boundingBox: { x: 0, y: 0, width: 100, height: 200 },
        },
      ],
      detectedBarcode: barcode || null,
    },
  };
}
