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
 * Validate a single sweep crop entry from Firestore.
 *
 * Since Firestore is schemaless, crop fields could be any type.
 * Returns an error message if invalid, or null if valid.
 */
function validateSweepCrop(crop: unknown, index: number): string | null {
  if (typeof crop !== 'object' || crop === null) {
    return `sweepCrops[${index}] is not an object`;
  }
  const c = crop as Record<string, unknown>;

  if (typeof c.cropUrl !== 'string' || c.cropUrl.trim() === '') {
    return `sweepCrops[${index}].cropUrl must be a non-empty string`;
  }
  if (!Array.isArray(c.boundingBox) || c.boundingBox.length !== 4 ||
      !c.boundingBox.every((v: unknown) => typeof v === 'number' && isFinite(v as number))) {
    return `sweepCrops[${index}].boundingBox must be a 4-element array of finite numbers`;
  }
  if (typeof c.frameIndex !== 'number' || !Number.isInteger(c.frameIndex) || c.frameIndex < 0) {
    return `sweepCrops[${index}].frameIndex must be a non-negative integer`;
  }
  if (typeof c.groupId !== 'string' || c.groupId.trim() === '') {
    return `sweepCrops[${index}].groupId must be a non-empty string`;
  }
  return null;
}

/**
 * Validate session document before processing
 *
 * Checks:
 * 1. userId is a non-empty string
 * 2. For sweep mode: sweepCrops is a non-empty array with valid structure
 * 3. For single/burst mode: originalImageUrls is a non-empty array
 * 4. All URLs are from allowed storage buckets (SSRF prevention)
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

  const captureMode = sessionData.captureMode as string | undefined;

  if (captureMode === 'sweep') {
    // Sweep mode: validate sweepCrops instead of originalImageUrls
    if (!Array.isArray(sessionData.sweepCrops) || sessionData.sweepCrops.length === 0) {
      logger.error('Session validation failed', { reason: 'No sweep crops provided' });
      await sessionRef.update({
        status: 'failed',
        error: 'No sweep crops provided',
        errorCode: 'SWEEP_NO_CROPS',
        failedAt: FieldValue.serverTimestamp()
      });
      return { valid: false, errorCode: 'SWEEP_NO_CROPS', errorMessage: 'No sweep crops provided' };
    }

    // Structural validation of each crop (Firestore is schemaless)
    for (let i = 0; i < (sessionData.sweepCrops as unknown[]).length; i++) {
      const crop = (sessionData.sweepCrops as unknown[])[i];
      const cropError = validateSweepCrop(crop, i);
      if (cropError) {
        logger.error('Sweep crop validation failed', { reason: cropError, index: i });
        await sessionRef.update({
          status: 'failed',
          error: cropError,
          errorCode: 'INVALID_SWEEP_CROP',
          failedAt: FieldValue.serverTimestamp()
        });
        return { valid: false, errorCode: 'INVALID_SWEEP_CROP', errorMessage: cropError };
      }
    }

    // Cap sweep crops to prevent abuse and timeout
    const MAX_SWEEP_CROPS = 50;
    if ((sessionData.sweepCrops as unknown[]).length > MAX_SWEEP_CROPS) {
      logger.error('Session validation failed', { reason: 'Too many sweep crops', count: (sessionData.sweepCrops as unknown[]).length, limit: MAX_SWEEP_CROPS });
      await sessionRef.update({
        status: 'failed',
        error: `Too many sweep crops: ${(sessionData.sweepCrops as unknown[]).length} exceeds limit of ${MAX_SWEEP_CROPS}`,
        errorCode: 'SWEEP_TOO_MANY_CROPS',
        failedAt: FieldValue.serverTimestamp()
      });
      return { valid: false, errorCode: 'SWEEP_TOO_MANY_CROPS', errorMessage: 'Too many sweep crops' };
    }

    // Validate all sweep crop URLs are from allowed buckets
    for (const crop of sessionData.sweepCrops as SweepCropInfo[]) {
      const bucketName = extractBucketFromUrl(crop.cropUrl);
      if (!bucketName || !ALLOWED_BUCKETS.includes(bucketName)) {
        logger.error('Session validation failed', { reason: 'Unauthorized bucket in sweep crop', cropUrl: crop.cropUrl, bucketName });
        await sessionRef.update({
          status: 'failed',
          error: 'Unauthorized storage bucket in sweep crop',
          errorCode: 'UNAUTHORIZED_BUCKET',
          failedAt: FieldValue.serverTimestamp()
        });
        return { valid: false, errorCode: 'UNAUTHORIZED_BUCKET', errorMessage: 'Unauthorized bucket' };
      }
    }
  } else {
    // Single/Burst mode: validate originalImageUrls
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
  }

  return { valid: true };
}

/**
 * Capture mode enum
 */
type CaptureMode = 'single' | 'burst' | 'sweep';

/**
 * Sweep crop metadata from on-device EdgeTAM segmentation
 */
interface SweepCropInfo {
  /** GCS URL of the pre-cropped image */
  cropUrl: string;
  /** Bounding box [ymin, xmin, ymax, xmax] normalized 0-1000 */
  boundingBox: [number, number, number, number];
  /** Index of the keyframe this crop came from */
  frameIndex: number;
  /** Deduplication group ID from on-device segment grouping */
  groupId: string;
  /** Optional 3D world position from ARKit, if available */
  worldPosition?: [number, number, number];
}

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
  /** Image URLs — required for single/burst, absent for sweep mode */
  originalImageUrls?: string[];
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
  failedAt?: FirebaseFirestore.Timestamp;
  processingStartedAt?: FirebaseFirestore.Timestamp;
  /** Sweep mode: pre-cropped segments from on-device EdgeTAM */
  sweepCrops?: SweepCropInfo[];
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
      imageCount: afterData.originalImageUrls?.length ?? 0,
      sweepCropCount: afterData.sweepCrops?.length ?? 0
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
      // Additionally, check processingStartedAt to guard against re-processing
      // a session that was claimed recently (within 5 minutes).
      const claimed = await db.runTransaction(async (tx) => {
        const snap = await tx.get(sessionRef);
        const data = snap.data();
        const currentStatus = data?.status;

        // Already completed or failed — don't reprocess
        if (currentStatus === 'detected' || currentStatus === 'failed') {
          return false;
        }

        // Guard against re-processing: if processingStartedAt is recent,
        // another function instance already claimed this session
        const processingStartedAt = data?.processingStartedAt?.toDate?.();
        if (processingStartedAt) {
          const ageMs = Date.now() - processingStartedAt.getTime();
          if (ageMs < 5 * 60 * 1000) {
            logger.info('Session recently claimed, skipping', { sessionId, ageMs });
            return false;
          }
        }

        // Claim: set processingStartedAt (and ensure status is 'detecting')
        tx.update(sessionRef, {
          status: 'detecting',
          processingStartedAt: FieldValue.serverTimestamp()
        });
        return true;
      });

      if (!claimed) {
        logger.info('Session already being processed, skipping duplicate', { sessionId });
        return;
      }

      // ── Sweep mode: skip detection, label pre-cropped segments ──
      // Note: sweepCrops structure, types, bucket URLs, and count limit are
      // validated by validateSessionDocument above.
      if (afterData.captureMode === 'sweep') {
        const sweepCrops = afterData.sweepCrops!;

        logger.info('Sweep session: labeling pre-cropped segments', {
          sessionId,
          cropCount: sweepCrops.length
        });

        // Label pre-cropped objects via Gemini Flash (no bounding box detection needed)
        const labels = await labelPrecroppedObjects(sweepCrops);

        // Construct detectedObjects from labels + sweep crop metadata
        const detectedObjects = labels.map((label, index) => ({
          groupId: sweepCrops[index].groupId,
          label: label.name,
          category: label.category,
          attributes: label.attributes || {},
          confidence: 'high' as const,
          croppedImageUrls: [sweepCrops[index].cropUrl],
          boundingBoxes: [{
            imageIndex: sweepCrops[index].frameIndex,
            box_2d: sweepCrops[index].boundingBox,
          }],
        }));

        await sessionRef.update({
          status: 'detected',
          detectedAt: FieldValue.serverTimestamp(),
          detectedObjects,
          reasoning: `Sweep mode: ${detectedObjects.length} objects labeled from ${sweepCrops.length} pre-cropped segments`
        });

        logger.info('Sweep session detection completed', {
          sessionId,
          objectCount: detectedObjects.length
        });

        return;
      }

      // ── Single/Burst mode: full detection pipeline ──

      // Get storage instance
      const storage = getStorage();

      // Run Layer 1 detection (originalImageUrls validated as non-empty above)
      const result = await detectObjectsInImages(
        afterData.originalImageUrls!,
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
        errorCode,
        failedAt: FieldValue.serverTimestamp()
      });
    }
  }
);

/**
 * Label result from Gemini Flash for a single pre-cropped object
 */
interface SweepLabelResult {
  /** Specific product name or descriptive label */
  name: string;
  /** High-level category (electronics, furniture, kitchen, etc.) */
  category: string;
  /** Optional attributes (color, brand, material, condition) */
  attributes?: Record<string, string>;
}

/**
 * Label pre-cropped objects using Gemini Flash (sweep mode).
 *
 * Sweep sessions provide already-cropped images from on-device EdgeTAM
 * segmentation. This function skips bounding box detection entirely and
 * only runs the labeling/identification step, making it ~50% cheaper
 * per item than the full single/burst detection pipeline.
 *
 * TODO: Wire up actual Gemini Flash call via layer1-service or
 * a dedicated sweep labeling prompt. Current implementation returns
 * placeholder labels to unblock pipeline integration.
 *
 * @param sweepCrops - Array of pre-cropped segment metadata from EdgeTAM
 * @returns Array of label results, one per crop (same order as input)
 */
async function labelPrecroppedObjects(
  sweepCrops: SweepCropInfo[]
): Promise<SweepLabelResult[]> {
  // TODO: Implement actual Gemini Flash labeling call
  // 1. Fetch crop images from GCS URLs (sweepCrops[i].cropUrl)
  // 2. Send to Gemini Flash with labeling-only prompt (no detection)
  // 3. Parse structured response into SweepLabelResult[]
  //
  // For now, return placeholder labels so the sweep pipeline routing
  // is fully wired end-to-end. Each crop gets a generic label that
  // will be replaced once the Gemini call is connected.
  logger.info('labelPrecroppedObjects: returning placeholder labels', {
    cropCount: sweepCrops.length
  });

  return sweepCrops.map((_crop, index) => ({
    name: `Sweep Object ${index + 1}`,
    category: 'Other',
    attributes: {}
  }));
}

/**
 * Determine error code from error type
 */
function determineErrorCode(error: unknown): string {
  if (error instanceof Error) {
    if (error.message.includes('timeout')) return 'TIMEOUT';
    if (error.message.includes('quota') || error.message.includes('RESOURCE_EXHAUSTED') || error.message.includes('429')) return 'QUOTA_EXCEEDED';
    if (error.message.includes('invalid')) return 'INVALID_INPUT';
    if (error.message.includes('permission')) return 'PERMISSION_DENIED';
    if (error.message.includes('not found')) return 'NOT_FOUND';
  }
  return 'INTERNAL_ERROR';
}
