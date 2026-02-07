/**
 * Firestore Trigger: Process capture sessions with Gemini 3 Flash
 *
 * Triggers when a capture session document is created with status="uploading"
 * and all images have been uploaded.
 *
 * Workflow:
 * 1. Fetch images from GCS temp bucket
 * 2. Call Gemini 3 Flash for object detection
 * 3. Parse detections and extract bounding boxes
 * 4. Crop objects with sharp
 * 5. Upload crops to permanent GCS bucket
 * 6. Update session document with results
 *
 * Deploy: firebase deploy --only functions:onSessionCreated
 */

import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { getStorage } from 'firebase-admin/storage';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import * as logger from 'firebase-functions/logger';
import { detectObjectsInImages, getEmptyResultReasoning } from '../ai-pipeline/layer1/layer1-service';
import { LAYER1_TIMEOUTS } from '../ai-pipeline/layer1/prompts';

/**
 * Session status enum
 */
type SessionStatus = 'uploading' | 'detecting' | 'detected' | 'failed';

/**
 * Validation result for session documents
 */
export interface ValidationResult {
  valid: boolean;
  errorCode?: string;
  errorMessage?: string;
}

/**
 * Allowed storage buckets for image URLs
 * These are the buckets where client-uploaded images are stored
 *
 * Includes:
 * - abundance-mvp.firebasestorage.app: Default Firebase Storage bucket (production)
 * - abundance-temp, etc: Legacy temp bucket names (may be used in dev/staging)
 */
const ALLOWED_BUCKETS = [
  'abundance-mvp.firebasestorage.app',  // Default Firebase Storage bucket
  'abundance-temp',
  'abundance-dev-temp',
  'abundance-staging-temp'
];

/**
 * Extract bucket name from various URL formats
 *
 * Supported formats:
 * - gs://bucket/path
 * - https://firebasestorage.googleapis.com[:port]/v0/b/{bucket}/o/{path}
 * - https://storage.googleapis.com[:port]/{bucket}/{path}
 *
 * Note: Anchored regex patterns prevent domain spoofing attacks
 * (e.g., evil-firebasestorage.googleapis.com.attacker.com)
 *
 * @param url - URL to extract bucket from
 * @returns Bucket name or null if not parseable
 */
function extractBucketFromUrl(url: string): string | null {
  // Format 1: gs://bucket/path
  const gsMatch = url.match(/^gs:\/\/([^/]+)\//);
  if (gsMatch) {
    return gsMatch[1];
  }

  // Format 2: https://firebasestorage.googleapis.com[:port]/v0/b/{bucket}/o/{path}
  // Anchored at start to prevent domain spoofing, optional port for production URLs
  const firebaseMatch = url.match(/^https:\/\/firebasestorage\.googleapis\.com(?::\d+)?\/v0\/b\/([^/]+)\/o\//);
  if (firebaseMatch) {
    return firebaseMatch[1];
  }

  // Format 3: https://storage.googleapis.com[:port]/{bucket}/{path}
  // Anchored at start to prevent domain spoofing, optional port for production URLs
  const gcsMatch = url.match(/^https:\/\/storage\.googleapis\.com(?::\d+)?\/([^/]+)\//);
  if (gcsMatch) {
    return gcsMatch[1];
  }

  return null;
}

/**
 * Validate session document before processing
 *
 * Checks:
 * 1. userId is a non-empty string
 * 2. originalImageUrls is a non-empty array
 * 3. All URLs are from allowed storage buckets
 *
 * @param sessionData - The session document data
 * @param sessionRef - Reference to the session document for updating on failure
 * @returns ValidationResult indicating if the document is valid
 */
export async function validateSessionDocument(
  sessionData: Record<string, unknown>,
  sessionRef: FirebaseFirestore.DocumentReference
): Promise<ValidationResult> {
  // Validate userId exists and is a non-empty string
  if (!sessionData.userId || typeof sessionData.userId !== 'string' || sessionData.userId.trim() === '') {
    logger.error('Session validation failed', { reason: 'Invalid or missing userId' });
    await sessionRef.update({
      status: 'failed',
      error: 'Invalid session document: missing userId',
      errorCode: 'INVALID_DOCUMENT',
      failedAt: FieldValue.serverTimestamp()
    });
    return { valid: false, errorCode: 'INVALID_DOCUMENT', errorMessage: 'Missing userId' };
  }

  // Validate originalImageUrls is a non-empty array
  if (!Array.isArray(sessionData.originalImageUrls) || sessionData.originalImageUrls.length === 0) {
    logger.error('Session validation failed', { reason: 'No images provided' });
    await sessionRef.update({
      status: 'failed',
      error: 'No images provided',
      errorCode: 'NO_IMAGES',
      failedAt: FieldValue.serverTimestamp()
    });
    return { valid: false, errorCode: 'NO_IMAGES', errorMessage: 'No images provided' };
  }

  // Validate all URLs are from allowed buckets
  // SECURITY: Use exact match to prevent bucket name spoofing
  // (e.g., "evil-abundance-mvp.firebasestorage.app" must NOT pass)
  for (const url of sessionData.originalImageUrls as string[]) {
    const bucketName = extractBucketFromUrl(url);
    if (!bucketName || !ALLOWED_BUCKETS.includes(bucketName)) {
      logger.error('Session validation failed', { reason: 'Unauthorized bucket', url, bucketName });
      await sessionRef.update({
        status: 'failed',
        error: 'Unauthorized storage bucket',
        errorCode: 'UNAUTHORIZED_BUCKET',
        failedAt: FieldValue.serverTimestamp()
      });
      return { valid: false, errorCode: 'UNAUTHORIZED_BUCKET', errorMessage: 'Unauthorized bucket' };
    }
  }

  return { valid: true };
}

/**
 * Capture mode enum
 */
type CaptureMode = 'single' | 'burst';

/**
 * Session document structure
 */
interface CaptureSession {
  id: string;
  userId: string;
  captureMode: CaptureMode;
  status: SessionStatus;
  createdAt: FirebaseFirestore.Timestamp;
  detectedAt?: FirebaseFirestore.Timestamp;
  originalImageUrls: string[];
  imagesUploaded?: number;
  expectedImageCount?: number;
  detectedObjects?: Array<{
    groupId: string;
    label: string;
    category: string;
    attributes: Record<string, string>;
    confidence: string;
    croppedImageUrls: string[];
    boundingBoxes: Array<{
      imageIndex: number;
      box_2d: [number, number, number, number];
    }>;
  }>;
  reasoning?: string;
  error?: string;
  errorCode?: string;
}

export const onSessionCreated = onDocumentUpdated(
  {
    document: 'sessions/{sessionId}',
    region: 'us-central1',
    memory: '1GiB',  // Need more memory for sharp image processing
    timeoutSeconds: LAYER1_TIMEOUTS.FUNCTION_TIMEOUT_SECONDS,
  },
  async (event) => {
    const beforeData = event.data?.before.data() as CaptureSession | undefined;
    const afterData = event.data?.after.data() as CaptureSession | undefined;

    if (!afterData) {
      logger.error('onSessionCreated: No document data');
      return;
    }

    // Only trigger when status changes to 'uploading' complete
    // (all images uploaded) or explicitly set to 'detecting'
    const imagesUploaded = afterData.imagesUploaded ?? 0;
    const shouldProcess =
      // Case 1: Status changed from uploading to detecting (client set ready)
      (beforeData?.status === 'uploading' && afterData.status === 'detecting') ||
      // Case 2: All expected images uploaded
      (afterData.status === 'uploading' &&
        imagesUploaded === afterData.expectedImageCount &&
        imagesUploaded > 0);

    if (!shouldProcess) {
      return;
    }

    const sessionId = event.params.sessionId;
    const db = getFirestore();
    const sessionRef = db.collection('sessions').doc(sessionId);

    logger.info('Processing session', {
      sessionId,
      captureMode: afterData.captureMode,
      imageCount: afterData.originalImageUrls.length
    });

    try {
      // Validate session document before processing
      const validation = await validateSessionDocument(
        afterData as unknown as Record<string, unknown>,
        sessionRef
      );
      if (!validation.valid) {
        logger.error('Session validation failed', {
          sessionId,
          errorCode: validation.errorCode,
          errorMessage: validation.errorMessage
        });
        return;
      }

      // Atomically claim processing to prevent duplicate execution
      // Both Case 1 (uploading→detecting) and Case 2 (all images uploaded) can fire
      // simultaneously for the same session. The transaction ensures only one wins.
      const claimed = await db.runTransaction(async (tx) => {
        const snap = await tx.get(sessionRef);
        const currentStatus = snap.data()?.status;
        if (currentStatus === 'detecting' || currentStatus === 'detected' || currentStatus === 'failed') {
          return false; // Already being processed or completed
        }
        tx.update(sessionRef, { status: 'detecting' });
        return true;
      });

      if (!claimed) {
        logger.info('Session already being processed, skipping duplicate', { sessionId });
        return;
      }

      // Get storage instance
      const storage = getStorage();

      // Run Layer 1 detection
      const result = await detectObjectsInImages(
        afterData.originalImageUrls,
        storage,
        afterData.userId,
        sessionId
      );

      // Convert crops map to array for Firestore
      const detectedObjects = Array.from(result.crops.values()).map(crop => ({
        groupId: crop.groupId,
        label: crop.label,
        category: crop.category,
        attributes: crop.attributes || {},
        confidence: crop.confidence || 'medium',
        croppedImageUrls: crop.croppedImageUrls,
        boundingBoxes: crop.boundingBoxes
      }));

      // Update session with results
      if (detectedObjects.length > 0) {
        await sessionRef.update({
          status: 'detected',
          detectedAt: FieldValue.serverTimestamp(),
          detectedObjects,
          reasoning: result.detections.reasoning || null
        });

        logger.info('Session detection completed', {
          sessionId,
          objectCount: detectedObjects.length
        });
      } else {
        // No objects detected - include reasoning
        const reasoning = getEmptyResultReasoning(result.detections);

        await sessionRef.update({
          status: 'detected',
          detectedAt: FieldValue.serverTimestamp(),
          detectedObjects: [],
          reasoning
        });

        logger.info('Session detection completed with no objects', {
          sessionId,
          reasoning
        });
      }

    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      const errorCode = determineErrorCode(error);

      logger.error('Session processing failed', {
        sessionId,
        error: errorMessage,
        errorCode
      });

      await sessionRef.update({
        status: 'failed',
        error: errorMessage,
        errorCode
      });
    }
  }
);

/**
 * Determine error code from error type
 */
function determineErrorCode(error: unknown): string {
  if (error instanceof Error) {
    if (error.message.includes('timeout')) return 'TIMEOUT';
    if (error.message.includes('quota')) return 'QUOTA_EXCEEDED';
    if (error.message.includes('invalid')) return 'INVALID_INPUT';
    if (error.message.includes('permission')) return 'PERMISSION_DENIED';
    if (error.message.includes('not found')) return 'NOT_FOUND';
  }
  return 'INTERNAL_ERROR';
}
