/**
 * Unit tests for onSessionCreated trigger validation
 *
 * Tests the validateSessionDocument function that ensures:
 * 1. userId is a non-empty string
 * 2. originalImageUrls is a non-empty array
 * 3. All URLs are from allowed storage buckets
 */

import { validateSessionDocument } from '../onSessionCreated';

// Mock firebase-admin/firestore
jest.mock('firebase-admin/firestore', () => ({
  getFirestore: jest.fn(),
  FieldValue: {
    serverTimestamp: jest.fn(() => 'MOCK_TIMESTAMP')
  }
}));

describe('onSessionCreated validation', () => {
  // Mock session document reference
  let mockSessionRef: {
    update: jest.Mock;
  };

  beforeEach(() => {
    mockSessionRef = {
      update: jest.fn().mockResolvedValue(undefined)
    };
    jest.clearAllMocks();
  });

  describe('validateSessionDocument', () => {
    describe('userId validation', () => {
      it('rejects missing userId', async () => {
        const sessionData = {
          originalImageUrls: ['gs://abundance-temp/test.jpg']
        };

        const result = await validateSessionDocument(
          sessionData,
          mockSessionRef as unknown as FirebaseFirestore.DocumentReference
        );

        expect(result.valid).toBe(false);
        expect(result.errorCode).toBe('INVALID_DOCUMENT');
        expect(result.errorMessage).toBe('Missing userId');
        expect(mockSessionRef.update).toHaveBeenCalledWith({
          status: 'failed',
          error: 'Invalid session document: missing userId',
          errorCode: 'INVALID_DOCUMENT',
          failedAt: 'MOCK_TIMESTAMP'
        });
      });

      it('rejects empty string userId', async () => {
        const sessionData = {
          userId: '',
          originalImageUrls: ['gs://abundance-temp/test.jpg']
        };

        const result = await validateSessionDocument(
          sessionData,
          mockSessionRef as unknown as FirebaseFirestore.DocumentReference
        );

        expect(result.valid).toBe(false);
        expect(result.errorCode).toBe('INVALID_DOCUMENT');
      });

      it('rejects whitespace-only userId', async () => {
        const sessionData = {
          userId: '   ',
          originalImageUrls: ['gs://abundance-temp/test.jpg']
        };

        const result = await validateSessionDocument(
          sessionData,
          mockSessionRef as unknown as FirebaseFirestore.DocumentReference
        );

        expect(result.valid).toBe(false);
        expect(result.errorCode).toBe('INVALID_DOCUMENT');
      });

      it('rejects non-string userId', async () => {
        const sessionData = {
          userId: 12345,
          originalImageUrls: ['gs://abundance-temp/test.jpg']
        };

        const result = await validateSessionDocument(
          sessionData,
          mockSessionRef as unknown as FirebaseFirestore.DocumentReference
        );

        expect(result.valid).toBe(false);
        expect(result.errorCode).toBe('INVALID_DOCUMENT');
      });

      it('accepts valid string userId', async () => {
        const sessionData = {
          userId: 'user-123',
          originalImageUrls: ['gs://abundance-temp/test.jpg']
        };

        const result = await validateSessionDocument(
          sessionData,
          mockSessionRef as unknown as FirebaseFirestore.DocumentReference
        );

        expect(result.valid).toBe(true);
        expect(mockSessionRef.update).not.toHaveBeenCalled();
      });
    });

    describe('originalImageUrls validation', () => {
      it('rejects missing originalImageUrls', async () => {
        const sessionData = {
          userId: 'user-123'
        };

        const result = await validateSessionDocument(
          sessionData,
          mockSessionRef as unknown as FirebaseFirestore.DocumentReference
        );

        expect(result.valid).toBe(false);
        expect(result.errorCode).toBe('NO_IMAGES');
        expect(result.errorMessage).toBe('No images provided');
        expect(mockSessionRef.update).toHaveBeenCalledWith({
          status: 'failed',
          error: 'No images provided',
          errorCode: 'NO_IMAGES',
          failedAt: 'MOCK_TIMESTAMP'
        });
      });

      it('rejects empty originalImageUrls array', async () => {
        const sessionData = {
          userId: 'user-123',
          originalImageUrls: []
        };

        const result = await validateSessionDocument(
          sessionData,
          mockSessionRef as unknown as FirebaseFirestore.DocumentReference
        );

        expect(result.valid).toBe(false);
        expect(result.errorCode).toBe('NO_IMAGES');
      });

      it('rejects non-array originalImageUrls', async () => {
        const sessionData = {
          userId: 'user-123',
          originalImageUrls: 'gs://abundance-temp/test.jpg'
        };

        const result = await validateSessionDocument(
          sessionData,
          mockSessionRef as unknown as FirebaseFirestore.DocumentReference
        );

        expect(result.valid).toBe(false);
        expect(result.errorCode).toBe('NO_IMAGES');
      });

      it('accepts valid originalImageUrls array', async () => {
        const sessionData = {
          userId: 'user-123',
          originalImageUrls: ['gs://abundance-temp/test.jpg']
        };

        const result = await validateSessionDocument(
          sessionData,
          mockSessionRef as unknown as FirebaseFirestore.DocumentReference
        );

        expect(result.valid).toBe(true);
      });
    });

    describe('bucket validation', () => {
      it('rejects URL from unauthorized bucket', async () => {
        const sessionData = {
          userId: 'user-123',
          originalImageUrls: ['gs://malicious-bucket/test.jpg']
        };

        const result = await validateSessionDocument(
          sessionData,
          mockSessionRef as unknown as FirebaseFirestore.DocumentReference
        );

        expect(result.valid).toBe(false);
        expect(result.errorCode).toBe('UNAUTHORIZED_BUCKET');
        expect(result.errorMessage).toBe('Unauthorized bucket');
        expect(mockSessionRef.update).toHaveBeenCalledWith({
          status: 'failed',
          error: 'Unauthorized storage bucket',
          errorCode: 'UNAUTHORIZED_BUCKET',
          failedAt: 'MOCK_TIMESTAMP'
        });
      });

      it('rejects if any URL is from unauthorized bucket', async () => {
        const sessionData = {
          userId: 'user-123',
          originalImageUrls: [
            'gs://abundance-temp/test1.jpg',
            'gs://malicious-bucket/test2.jpg',
            'gs://abundance-dev-temp/test3.jpg'
          ]
        };

        const result = await validateSessionDocument(
          sessionData,
          mockSessionRef as unknown as FirebaseFirestore.DocumentReference
        );

        expect(result.valid).toBe(false);
        expect(result.errorCode).toBe('UNAUTHORIZED_BUCKET');
      });

      it('accepts URL from abundance-temp bucket', async () => {
        const sessionData = {
          userId: 'user-123',
          originalImageUrls: ['gs://abundance-temp/users/user-123/uploads/image.jpg']
        };

        const result = await validateSessionDocument(
          sessionData,
          mockSessionRef as unknown as FirebaseFirestore.DocumentReference
        );

        expect(result.valid).toBe(true);
      });

      it('accepts URL from abundance-dev-temp bucket', async () => {
        const sessionData = {
          userId: 'user-123',
          originalImageUrls: ['gs://abundance-dev-temp/users/user-123/uploads/image.jpg']
        };

        const result = await validateSessionDocument(
          sessionData,
          mockSessionRef as unknown as FirebaseFirestore.DocumentReference
        );

        expect(result.valid).toBe(true);
      });

      it('accepts URL from abundance-staging-temp bucket', async () => {
        const sessionData = {
          userId: 'user-123',
          originalImageUrls: ['gs://abundance-staging-temp/users/user-123/uploads/image.jpg']
        };

        const result = await validateSessionDocument(
          sessionData,
          mockSessionRef as unknown as FirebaseFirestore.DocumentReference
        );

        expect(result.valid).toBe(true);
      });

      it('accepts URL from abundance-mvp.firebasestorage.app bucket (gs:// format)', async () => {
        const sessionData = {
          userId: 'user-123',
          originalImageUrls: ['gs://abundance-mvp.firebasestorage.app/users/user-123/items/image.jpg']
        };

        const result = await validateSessionDocument(
          sessionData,
          mockSessionRef as unknown as FirebaseFirestore.DocumentReference
        );

        expect(result.valid).toBe(true);
      });

      it('accepts multiple valid URLs from different allowed buckets', async () => {
        const sessionData = {
          userId: 'user-123',
          originalImageUrls: [
            'gs://abundance-temp/image1.jpg',
            'gs://abundance-dev-temp/image2.jpg',
            'gs://abundance-staging-temp/image3.jpg'
          ]
        };

        const result = await validateSessionDocument(
          sessionData,
          mockSessionRef as unknown as FirebaseFirestore.DocumentReference
        );

        expect(result.valid).toBe(true);
      });

      it('accepts Firebase Storage download URL from allowed bucket', async () => {
        const sessionData = {
          userId: 'user-123',
          originalImageUrls: [
            'https://firebasestorage.googleapis.com/v0/b/abundance-mvp.firebasestorage.app/o/users%2Fuser-123%2Fitems%2Ftest.jpg?alt=media&token=abc123'
          ]
        };

        const result = await validateSessionDocument(
          sessionData,
          mockSessionRef as unknown as FirebaseFirestore.DocumentReference
        );

        expect(result.valid).toBe(true);
      });

      it('accepts HTTPS storage.googleapis.com URL from allowed bucket', async () => {
        const sessionData = {
          userId: 'user-123',
          originalImageUrls: ['https://storage.googleapis.com/abundance-temp/test.jpg']
        };

        const result = await validateSessionDocument(
          sessionData,
          mockSessionRef as unknown as FirebaseFirestore.DocumentReference
        );

        expect(result.valid).toBe(true);
      });

      it('accepts Firebase Storage URL with :443 port from allowed bucket', async () => {
        const sessionData = {
          userId: 'user-123',
          originalImageUrls: [
            'https://firebasestorage.googleapis.com:443/v0/b/abundance-mvp.firebasestorage.app/o/users%2Fuser-123%2Fitems%2Ftest.jpg?alt=media&token=abc123'
          ]
        };

        const result = await validateSessionDocument(
          sessionData,
          mockSessionRef as unknown as FirebaseFirestore.DocumentReference
        );

        expect(result.valid).toBe(true);
      });

      it('accepts GCS URL with :443 port from allowed bucket', async () => {
        const sessionData = {
          userId: 'user-123',
          originalImageUrls: ['https://storage.googleapis.com:443/abundance-temp/test.jpg']
        };

        const result = await validateSessionDocument(
          sessionData,
          mockSessionRef as unknown as FirebaseFirestore.DocumentReference
        );

        expect(result.valid).toBe(true);
      });

      it('rejects malicious bucket name that contains allowed bucket as substring', async () => {
        // SECURITY: This tests that exact matching is used, not substring matching
        // "evil-abundance-mvp.firebasestorage.app" should NOT match "abundance-mvp.firebasestorage.app"
        const sessionData = {
          userId: 'user-123',
          originalImageUrls: [
            'https://firebasestorage.googleapis.com/v0/b/evil-abundance-mvp.firebasestorage.app/o/test.jpg?alt=media'
          ]
        };

        const result = await validateSessionDocument(
          sessionData,
          mockSessionRef as unknown as FirebaseFirestore.DocumentReference
        );

        expect(result.valid).toBe(false);
        expect(result.errorCode).toBe('UNAUTHORIZED_BUCKET');
      });

      it('rejects malicious bucket with allowed bucket name as suffix', async () => {
        // SECURITY: "attacker-abundance-temp" should NOT match "abundance-temp"
        const sessionData = {
          userId: 'user-123',
          originalImageUrls: ['gs://attacker-abundance-temp/test.jpg']
        };

        const result = await validateSessionDocument(
          sessionData,
          mockSessionRef as unknown as FirebaseFirestore.DocumentReference
        );

        expect(result.valid).toBe(false);
        expect(result.errorCode).toBe('UNAUTHORIZED_BUCKET');
      });

      it('rejects Firebase Storage URL from unauthorized bucket', async () => {
        const sessionData = {
          userId: 'user-123',
          originalImageUrls: [
            'https://firebasestorage.googleapis.com/v0/b/malicious-bucket.firebasestorage.app/o/test.jpg?alt=media'
          ]
        };

        const result = await validateSessionDocument(
          sessionData,
          mockSessionRef as unknown as FirebaseFirestore.DocumentReference
        );

        expect(result.valid).toBe(false);
        expect(result.errorCode).toBe('UNAUTHORIZED_BUCKET');
      });

      it('rejects URL with unparseable format', async () => {
        const sessionData = {
          userId: 'user-123',
          originalImageUrls: ['https://random-site.com/image.jpg']
        };

        const result = await validateSessionDocument(
          sessionData,
          mockSessionRef as unknown as FirebaseFirestore.DocumentReference
        );

        expect(result.valid).toBe(false);
        expect(result.errorCode).toBe('UNAUTHORIZED_BUCKET');
      });
    });

    describe('complete validation flow', () => {
      it('validates in correct order (userId first, then images, then buckets)', async () => {
        // Missing both userId and images - should fail on userId first
        const sessionData1: Record<string, unknown> = {};
        const result1 = await validateSessionDocument(
          sessionData1,
          mockSessionRef as unknown as FirebaseFirestore.DocumentReference
        );
        expect(result1.errorCode).toBe('INVALID_DOCUMENT');

        // Has userId but no images
        jest.clearAllMocks();
        const sessionData2 = { userId: 'user-123' };
        const result2 = await validateSessionDocument(
          sessionData2,
          mockSessionRef as unknown as FirebaseFirestore.DocumentReference
        );
        expect(result2.errorCode).toBe('NO_IMAGES');

        // Has userId and images but bad bucket
        jest.clearAllMocks();
        const sessionData3 = {
          userId: 'user-123',
          originalImageUrls: ['gs://bad-bucket/test.jpg']
        };
        const result3 = await validateSessionDocument(
          sessionData3,
          mockSessionRef as unknown as FirebaseFirestore.DocumentReference
        );
        expect(result3.errorCode).toBe('UNAUTHORIZED_BUCKET');
      });

      it('returns valid for fully valid session', async () => {
        const sessionData = {
          userId: 'user-abc-123',
          originalImageUrls: [
            'gs://abundance-temp/users/user-abc-123/uploads/image1.jpg',
            'gs://abundance-temp/users/user-abc-123/uploads/image2.jpg'
          ],
          captureMode: 'burst',
          status: 'uploading'
        };

        const result = await validateSessionDocument(
          sessionData,
          mockSessionRef as unknown as FirebaseFirestore.DocumentReference
        );

        expect(result.valid).toBe(true);
        expect(result.errorCode).toBeUndefined();
        expect(result.errorMessage).toBeUndefined();
        expect(mockSessionRef.update).not.toHaveBeenCalled();
      });
    });
  });
});
