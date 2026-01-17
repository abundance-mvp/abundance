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
import { detectObjectsInImages, getEmptyResultReasoning } from '../ai-pipeline/layer1/layer1-service';
import { LAYER1_TIMEOUTS } from '../ai-pipeline/layer1/prompts';

/**
 * Session status enum
 */
type SessionStatus = 'uploading' | 'detecting' | 'detected' | 'failed';

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
      console.error('onSessionCreated: No document data');
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

    console.log(`Processing session ${sessionId}: ${afterData.captureMode} mode with ${afterData.originalImageUrls.length} images`);

    try {
      // Update status to detecting
      await sessionRef.update({
        status: 'detecting'
      });

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

        console.log(`Session ${sessionId}: Detected ${detectedObjects.length} objects`);
      } else {
        // No objects detected - include reasoning
        const reasoning = getEmptyResultReasoning(result.detections);

        await sessionRef.update({
          status: 'detected',
          detectedAt: FieldValue.serverTimestamp(),
          detectedObjects: [],
          reasoning
        });

        console.log(`Session ${sessionId}: No objects detected - ${reasoning}`);
      }

    } catch (error) {
      console.error(`Session ${sessionId} failed:`, error);

      // Update session with error
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      const errorCode = determineErrorCode(error);

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
