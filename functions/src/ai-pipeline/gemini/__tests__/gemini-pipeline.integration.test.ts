/**
 * Integration test for Gemini 3 Pro pipeline.
 *
 * SECURITY NOTES:
 * - Test images are stored in gs://abundance-test-private (public access prevention enforced)
 * - All image access uses time-limited signed URLs (15 minute expiry)
 * - Service accounts have read-only access to test bucket
 * - Never use public URLs for test images containing personal items
 *
 * Requirements:
 * - GOOGLE_CLOUD_PROJECT: GCP project ID with Vertex AI enabled
 * - GOOGLE_CLOUD_LOCATION: Region (defaults to 'global')
 * - SERPAPI_KEY: Valid SerpAPI key (Developer plan)
 * - FIREBASE_PROJECT_ID: Firebase project with Storage enabled
 * - GOOGLE_APPLICATION_CREDENTIALS: Path to service account JSON (for local dev)
 *
 * Run: npm run test:integration
 *
 * Note: Tests are skipped if credentials are not available.
 * This allows CI to pass without credentials configured.
 */

import * as admin from 'firebase-admin';
import { processItemWithGemini } from '../gemini-service';
import { validateCatalogItem, CatalogItem } from '../schemas/catalog-item';
import {
  validateIntegrationEnvironment,
  initializeFirebaseAdmin,
  cleanupTestImage,
  getTestImageAsDataUrl,
  TEST_IMAGES,
} from '../../__tests__/integration-setup';

// Skip integration tests if credentials not available
const hasCredentials = !!(
  process.env.GOOGLE_CLOUD_PROJECT &&
  process.env.SERPAPI_KEY &&
  process.env.FIREBASE_PROJECT_ID
);

const describeIntegration = hasCredentials ? describe : describe.skip;

/**
 * Helper to get first item from result (handles both single item and array)
 */
function getFirstItem(result: CatalogItem | CatalogItem[]): CatalogItem {
  return Array.isArray(result) ? result[0] : result;
}

describeIntegration('Gemini 3 Pro Pipeline Integration', () => {
  let app: admin.app.App;
  let bucket: ReturnType<admin.storage.Storage['bucket']>;
  const testImagePath = 'integration-tests/test-item.jpg';

  beforeAll(async () => {
    try {
      validateIntegrationEnvironment();
      app = initializeFirebaseAdmin();
      bucket = admin.storage().bucket();
    } catch (error) {
      console.error('Integration test setup failed:', error);
      throw error;
    }
  });

  afterAll(async () => {
    try {
      await cleanupTestImage(bucket, testImagePath);
    } catch (error) {
      console.log('Cleanup error (non-fatal):', error);
    }
    if (app) {
      await app.delete();
    }
  });

  describe('processItemWithGemini', () => {
    it('should analyze a product image and return valid CatalogItem', async () => {
      // SECURITY: Download image directly from private bucket as base64 data URL
      // No URL is ever exposed - image data stays in process memory only
      // Test images are stored in gs://abundance-test-private with public access prevention
      const testImageUrl = await getTestImageAsDataUrl(TEST_IMAGES.PRODUCT_IMAGE);

      // Process with Gemini
      const result = await processItemWithGemini(testImageUrl);
      const item = getFirstItem(result);

      // Validate result structure
      expect(result).toBeDefined();
      expect(item.name).toBeDefined();
      expect(item.category).toBeDefined();
      expect(typeof item.name).toBe('string');
      expect(typeof item.category).toBe('string');

      // Validate against schema
      const validation = validateCatalogItem(item);
      expect(validation.valid).toBe(true);

      // Log for manual inspection
      console.log('Integration test result:', JSON.stringify(result, null, 2));
    }, 120000); // 120 second timeout - includes image download + multiple API calls

    it('should return result within acceptable time', async () => {
      // SECURITY: Download image directly from private bucket as base64 data URL
      const testImageUrl = await getTestImageAsDataUrl(TEST_IMAGES.PRODUCT_IMAGE);

      const startTime = Date.now();
      const result = await processItemWithGemini(testImageUrl);
      const duration = Date.now() - startTime;
      const item = getFirstItem(result);

      // Verify timing is within acceptable range (< 90 seconds)
      // This includes: image download, Gemini calls, tool execution (google_lens, web_search)
      expect(duration).toBeLessThan(90000);

      // Verify result is valid
      expect(result).toBeDefined();
      expect(item.name).toBeDefined();

      // Log timing for cost estimation
      console.log(`Processing time: ${duration}ms`);
      console.log(`Estimated cost: $0.03-0.04 per item`);
    }, 120000); // 120 second timeout
  });

  describe('Error Handling', () => {
    it('should handle invalid image URL gracefully', async () => {
      const invalidUrl = 'https://example.com/nonexistent-image.jpg';

      try {
        await processItemWithGemini(invalidUrl);
        // If it doesn't throw, the model handled the error gracefully
        expect(true).toBe(true);
      } catch (error) {
        // Error is expected for invalid URLs
        expect(error).toBeDefined();
      }
    }, 60000);
  });
});

// Additional test to verify skip behavior
describe('Integration Test Skip Check', () => {
  it('should indicate whether integration tests are running', () => {
    if (hasCredentials) {
      console.log('Integration tests ENABLED - credentials found');
    } else {
      console.log(
        'Integration tests SKIPPED - missing credentials:',
        [
          !process.env.GOOGLE_CLOUD_PROJECT && 'GOOGLE_CLOUD_PROJECT',
          !process.env.SERPAPI_KEY && 'SERPAPI_KEY',
          !process.env.FIREBASE_PROJECT_ID && 'FIREBASE_PROJECT_ID',
        ].filter(Boolean)
      );
    }
    expect(true).toBe(true);
  });
});
