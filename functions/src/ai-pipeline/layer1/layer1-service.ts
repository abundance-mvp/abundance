/**
 * Layer 1 Detection Service
 *
 * Uses Gemini 3 Flash to detect objects in images and return bounding boxes.
 * Handles:
 * - Single image detection
 * - Multi-image batch detection with grouping
 * - Server-side cropping with sharp
 */

import { Storage } from 'firebase-admin/storage';
import * as logger from 'firebase-functions/logger';
import { createVertexAIClient } from '../gemini/vertexai-config';
import {
  LAYER1_MODEL_ID,
  LAYER1_SYSTEM_PROMPT,
  LAYER1_GENERATION_CONFIG,
  LAYER1_TIMEOUTS,
  createImagePart
} from './prompts';
import {
  Layer1DetectionResponse,
  DetectedObject,
  validateDetectionResponse
} from './schemas/detection-result';
import {
  boxToAbsolute,
  addPadding,
  isValidBoundingBox
} from './utils/bbox-converter';

/**
 * Retryable error codes from Gemini/Vertex AI API
 * These are transient errors that may succeed on retry
 */
const RETRYABLE_ERROR_CODES = [
  'UNAVAILABLE',
  'DEADLINE_EXCEEDED',
  'RESOURCE_EXHAUSTED',
  'INTERNAL',
  'UNKNOWN'
];

/**
 * Check if an error is retryable (transient failure)
 */
function isRetryableError(error: Error): boolean {
  return RETRYABLE_ERROR_CODES.some(code => error.message.includes(code));
}

/**
 * Sleep for specified milliseconds
 */
async function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

/**
 * Wraps a promise with a timeout
 *
 * @param promise - The promise to wrap
 * @param timeoutMs - Timeout in milliseconds
 * @param errorMessage - Error message if timeout is exceeded
 * @returns The promise result or throws timeout error
 */
function withTimeout<T>(
  promise: Promise<T>,
  timeoutMs: number,
  errorMessage: string
): Promise<T> {
  return Promise.race([
    promise,
    new Promise<T>((_, reject) => {
      setTimeout(() => reject(new Error(errorMessage)), timeoutMs);
    })
  ]);
}

/**
 * Call Gemini Flash with exponential backoff retry
 *
 * @param imageBase64s - Array of base64-encoded images
 * @param maxRetries - Maximum number of retry attempts (default from config)
 * @returns Detection response from Gemini
 * @throws Last error if all retries fail or non-retryable error
 */
export async function callGeminiFlashWithRetry(
  imageBase64s: string[],
  maxRetries: number = LAYER1_TIMEOUTS.GEMINI_FLASH_MAX_RETRIES
): Promise<Layer1DetectionResponse> {
  let lastError: Error | null = null;

  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      return await callGeminiFlash(imageBase64s);
    } catch (error) {
      lastError = error instanceof Error ? error : new Error(String(error));

      // If error is not retryable, fail immediately
      if (!isRetryableError(lastError)) {
        throw lastError;
      }

      logger.warn('Gemini Flash attempt failed', {
        attempt: attempt + 1,
        maxAttempts: maxRetries + 1,
        error: lastError.message
      });

      // Apply exponential backoff before next retry (except on last attempt)
      if (attempt < maxRetries) {
        const backoffMs = 1000 * Math.pow(2, attempt); // 1s, 2s, 4s
        logger.info('Retrying Gemini Flash', { backoffMs });
        await sleep(backoffMs);
      }
    }
  }

  throw lastError ?? new Error('Gemini Flash failed with unknown error');
}

// Dynamic import for sharp (ESM module)
let sharp: typeof import('sharp') | null = null;

async function getSharp() {
  if (!sharp) {
    sharp = (await import('sharp')).default;
  }
  return sharp;
}

/**
 * Result from Layer 1 detection including cropped images
 */
export interface Layer1Result {
  /** Original detection response from Gemini */
  detections: Layer1DetectionResponse;

  /** Cropped images keyed by groupId */
  crops: Map<string, CroppedObject>;
}

/**
 * Cropped object with metadata
 */
export interface CroppedObject {
  groupId: string;
  label: string;
  category: string;
  confidence?: string;
  attributes?: Record<string, string>;

  /** URLs to cropped images in GCS */
  croppedImageUrls: string[];

  /** Bounding boxes for each image */
  boundingBoxes: Array<{
    imageIndex: number;
    box_2d: [number, number, number, number];
  }>;
}

/**
 * Detect objects in images using Gemini 3 Flash
 *
 * @param imageUrls - Array of GCS URLs to original images
 * @param storage - Firebase Storage instance for reading/writing images
 * @param userId - User ID for storage path
 * @param sessionId - Session ID for organizing images
 * @returns Detection results with cropped images
 */
export async function detectObjectsInImages(
  imageUrls: string[],
  storage: Storage,
  userId: string,
  sessionId: string
): Promise<Layer1Result> {
  // Fetch images and convert to base64
  const imageBase64s = await Promise.all(
    imageUrls.map(url => fetchImageFromGCS(url, storage))
  );

  // Call Gemini 3 Flash for detection with retry logic
  const detections = await callGeminiFlashWithRetry(imageBase64s);

  // Validate response
  const validation = validateDetectionResponse(detections);
  if (!validation.valid) {
    logger.error('Invalid detection response', { errors: validation.errors });
    // Return empty result on validation failure
    return {
      detections: { objects: [], reasoning: 'Invalid response from detection model' },
      crops: new Map()
    };
  }

  // If no objects detected, return early
  if (detections.objects.length === 0) {
    return {
      detections,
      crops: new Map()
    };
  }

  // Crop objects and upload to GCS
  const crops = await cropAndUploadObjects(
    detections.objects,
    imageBase64s,
    storage,
    userId,
    sessionId
  );

  return {
    detections,
    crops
  };
}

/**
 * Fetch image from GCS and return as base64 with timeout enforcement
 */
async function fetchImageFromGCS(gcsUrl: string, storage: Storage): Promise<string> {
  const fetchPromise = (async (): Promise<string> => {
    // Parse GCS URL formats:
    // - gs://bucket/path
    // - https://storage.googleapis.com/bucket/path
    // - https://firebasestorage.googleapis.com/v0/b/{bucket}/o/{path}?alt=media&token=...
    let bucket: string;
    let path: string;

    if (gcsUrl.startsWith('gs://')) {
      const match = gcsUrl.match(/^gs:\/\/([^/]+)\/(.+)$/);
      if (!match) throw new Error(`Invalid GCS URL: ${gcsUrl}`);
      bucket = match[1];
      path = match[2];
    } else if (gcsUrl.includes('firebasestorage.googleapis.com')) {
      // Firebase Storage download URL format: /v0/b/{bucket}/o/{urlEncodedPath}
      const url = new URL(gcsUrl);
      const bucketMatch = url.pathname.match(/\/v0\/b\/([^/]+)\/o\/(.+)/);
      if (!bucketMatch) throw new Error(`Invalid Firebase Storage URL: ${gcsUrl}`);
      bucket = bucketMatch[1];
      path = decodeURIComponent(bucketMatch[2]);
    } else if (gcsUrl.includes('storage.googleapis.com')) {
      const url = new URL(gcsUrl);
      const pathParts = url.pathname.split('/').filter(Boolean);
      bucket = pathParts[0];
      path = pathParts.slice(1).join('/');
    } else {
      throw new Error(`Unsupported URL format: ${gcsUrl}`);
    }

    const file = storage.bucket(bucket).file(path);
    const [buffer] = await file.download();
    return buffer.toString('base64');
  })();

  return withTimeout(
    fetchPromise,
    LAYER1_TIMEOUTS.IMAGE_FETCH_TIMEOUT_MS,
    `Image fetch timeout after ${LAYER1_TIMEOUTS.IMAGE_FETCH_TIMEOUT_MS}ms: ${gcsUrl}`
  );
}

/**
 * Call Gemini 3 Flash for object detection
 */
async function callGeminiFlash(imageBase64s: string[]): Promise<Layer1DetectionResponse> {
  const ai = createVertexAIClient();

  // Build content array with all images
  const imageParts = imageBase64s.map((base64, index) => [
    { text: `Image ${index + 1}:` },
    createImagePart(base64)
  ]).flat();

  const userMessage = imageBase64s.length === 1
    ? 'Analyze this image and identify all catalogable objects.'
    : `Analyze these ${imageBase64s.length} images. Group the same object appearing in multiple images together.`;

  const contents = [{
    role: 'user' as const,
    parts: [
      { text: userMessage },
      ...imageParts
    ]
  }];

  const response = await ai.models.generateContent({
    model: LAYER1_MODEL_ID,
    contents,
    config: {
      systemInstruction: LAYER1_SYSTEM_PROMPT,
      ...LAYER1_GENERATION_CONFIG
    }
  });

  const text = response.text;
  if (!text) {
    logger.error('No text response from Gemini Flash');
    return { objects: [], reasoning: 'No response from detection model' };
  }

  try {
    return JSON.parse(text) as Layer1DetectionResponse;
  } catch (error) {
    logger.error('Failed to parse Gemini Flash response', {
      error: error instanceof Error ? error.message : String(error),
      responsePreview: text.substring(0, 500)
    });
    return { objects: [], reasoning: 'Failed to parse detection response' };
  }
}

/**
 * Crop detected objects from images and upload to GCS
 */
async function cropAndUploadObjects(
  objects: DetectedObject[],
  imageBase64s: string[],
  storage: Storage,
  userId: string,
  sessionId: string
): Promise<Map<string, CroppedObject>> {
  const sharpLib = await getSharp();
  const crops = new Map<string, CroppedObject>();

  // Group objects by groupId
  const groupedObjects = new Map<string, DetectedObject[]>();
  for (const obj of objects) {
    const existing = groupedObjects.get(obj.groupId) || [];
    existing.push(obj);
    groupedObjects.set(obj.groupId, existing);
  }

  // Process each group
  for (const [groupId, groupObjects] of groupedObjects) {
    const firstObj = groupObjects[0];
    const croppedUrls: string[] = [];
    const boundingBoxes: Array<{ imageIndex: number; box_2d: [number, number, number, number] }> = [];

    for (const obj of groupObjects) {
      // Validate bounding box
      if (!isValidBoundingBox(obj.box_2d)) {
        logger.warn('Skipping invalid bounding box', {
          label: obj.label,
          box_2d: obj.box_2d
        });
        continue;
      }

      // Get image for this detection
      const imageBase64 = imageBase64s[obj.image_index];
      if (!imageBase64) {
        logger.warn('No image at index for detection', {
          imageIndex: obj.image_index,
          label: obj.label
        });
        continue;
      }

      try {
        // Get image dimensions
        const imageBuffer = Buffer.from(imageBase64, 'base64');
        const metadata = await sharpLib(imageBuffer).metadata();
        if (!metadata.width || !metadata.height) {
          logger.warn('Could not get image dimensions', { label: obj.label });
          continue;
        }

        // Convert to absolute coordinates with padding
        const absCoords = boxToAbsolute(obj.box_2d, metadata.width, metadata.height);
        const paddedCoords = addPadding(absCoords, 0.05, metadata.width, metadata.height);

        // Crop the image
        const croppedBuffer = await sharpLib(imageBuffer)
          .extract({
            left: paddedCoords.x1,
            top: paddedCoords.y1,
            width: paddedCoords.width,
            height: paddedCoords.height
          })
          .jpeg({ quality: 85 })
          .toBuffer();

        // Upload to GCS
        const cropPath = `users/${userId}/items/${groupId}_crop_${croppedUrls.length}.jpg`;
        const bucket = storage.bucket();
        const file = bucket.file(cropPath);

        await file.save(croppedBuffer, {
          metadata: {
            contentType: 'image/jpeg',
            metadata: {
              sessionId,
              groupId,
              label: obj.label,
              imageIndex: obj.image_index.toString()
            }
          }
        });

        // Generate signed URL with 24-hour expiration (security: no public access)
        const [signedUrl] = await file.getSignedUrl({
          action: 'read',
          expires: Date.now() + 24 * 60 * 60 * 1000, // 24 hours
          version: 'v4'
        });
        croppedUrls.push(signedUrl);

        boundingBoxes.push({
          imageIndex: obj.image_index,
          box_2d: obj.box_2d
        });

      } catch (error) {
        logger.error('Failed to crop object', {
          label: obj.label,
          groupId,
          error: error instanceof Error ? error.message : String(error)
        });
        // Continue with other crops
      }
    }

    // Only add to results if we got at least one crop
    if (croppedUrls.length > 0) {
      crops.set(groupId, {
        groupId,
        label: firstObj.label,
        category: firstObj.category,
        confidence: firstObj.confidence,
        attributes: firstObj.attributes as Record<string, string> | undefined,
        croppedImageUrls: croppedUrls,
        boundingBoxes
      });
    }
  }

  return crops;
}

/**
 * Get detection reasoning for empty results
 *
 * @param detections - Detection response
 * @returns Human-readable reasoning string
 */
export function getEmptyResultReasoning(detections: Layer1DetectionResponse): string {
  if (detections.reasoning) {
    return detections.reasoning;
  }
  return 'No catalogable objects were detected in the image.';
}
