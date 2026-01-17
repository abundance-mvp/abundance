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
import { createVertexAIClient } from '../gemini/vertexai-config';
import {
  LAYER1_MODEL_ID,
  LAYER1_SYSTEM_PROMPT,
  LAYER1_GENERATION_CONFIG,
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

  // Call Gemini 3 Flash for detection
  const detections = await callGeminiFlash(imageBase64s);

  // Validate response
  const validation = validateDetectionResponse(detections);
  if (!validation.valid) {
    console.error('Invalid detection response:', validation.errors);
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
 * Fetch image from GCS and return as base64
 */
async function fetchImageFromGCS(gcsUrl: string, storage: Storage): Promise<string> {
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
    console.error('No text response from Gemini Flash');
    return { objects: [], reasoning: 'No response from detection model' };
  }

  try {
    return JSON.parse(text) as Layer1DetectionResponse;
  } catch (error) {
    console.error('Failed to parse Gemini Flash response:', error);
    console.error('Raw response:', text);
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
        console.warn(`Skipping invalid bounding box for ${obj.label}:`, obj.box_2d);
        continue;
      }

      // Get image for this detection
      const imageBase64 = imageBase64s[obj.image_index];
      if (!imageBase64) {
        console.warn(`No image at index ${obj.image_index} for ${obj.label}`);
        continue;
      }

      try {
        // Get image dimensions
        const imageBuffer = Buffer.from(imageBase64, 'base64');
        const metadata = await sharpLib(imageBuffer).metadata();
        if (!metadata.width || !metadata.height) {
          console.warn(`Could not get image dimensions for ${obj.label}`);
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

        // Make file publicly readable (for iOS client to download)
        await file.makePublic();

        const publicUrl = `https://storage.googleapis.com/${bucket.name}/${cropPath}`;
        croppedUrls.push(publicUrl);

        boundingBoxes.push({
          imageIndex: obj.image_index,
          box_2d: obj.box_2d
        });

      } catch (error) {
        console.error(`Failed to crop object ${obj.label}:`, error);
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
