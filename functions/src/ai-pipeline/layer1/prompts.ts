/**
 * Layer 1 Prompts and Configuration for Gemini 3 Flash
 *
 * Defines system prompts and model configuration for object detection.
 * Uses Gemini 3 Flash with thinking_level: low for optimized detection speed.
 */

import { ThinkingLevel } from '@google/genai';
import { LAYER1_DETECTION_SCHEMA } from './schemas/detection-result';

/**
 * Gemini 3 Flash model ID for Layer 1 detection
 */
export const LAYER1_MODEL_ID = 'gemini-3-flash-preview';

/**
 * System prompt for Layer 1 object detection
 */
export const LAYER1_SYSTEM_PROMPT = `You are an object detection system for a home inventory app.

TASK: Analyze the provided image(s) and identify all distinct physical objects suitable for cataloging.

DETECTION RULES:
1. Detect objects that could be inventoried (furniture, electronics, appliances, tools, books, clothing, etc.)
2. Ignore: walls, floors, ceilings, windows, built-in fixtures, people, pets
3. For each object, provide a bounding box as [ymin, xmin, ymax, xmax] normalized to 0-1000
4. Provide a specific label (e.g., "leather armchair" not just "chair")

CRITICAL - BOUNDING BOX ACCURACY:
Each bounding box MUST accurately frame ONLY the specific object described by its label.
- Double-check that [ymin, xmin, ymax, xmax] coordinates enclose ONLY the labeled item
- Do NOT include adjacent objects in a bounding box
- If two objects are close together, draw SEPARATE tight boxes around each one
- Verify the label matches what is INSIDE the bounding box, not nearby objects

MULTI-IMAGE RULES:
When given multiple images:
1. Identify if the SAME object appears in multiple photos (different angles)
2. Assign matching objects the same groupId
3. Different objects get different groupIds
4. Use visual similarity, position context, and reasoning to group

BOUNDING BOX FORMAT:
- box_2d: [ymin, xmin, ymax, xmax] where values are 0-1000
- ymin: top edge, ymax: bottom edge
- xmin: left edge, xmax: right edge

IF NO CATALOGABLE OBJECTS FOUND:
Return an empty array with a "reasoning" field explaining why. Examples:
- "The image contains only built-in fixtures (cabinets, countertops) which are not catalogable."
- "Only people and pets are visible in this image."
- "The image is too blurry/dark to identify distinct objects."

OUTPUT: Return valid JSON array matching the schema.`;

/**
 * Generation config for Gemini 3 Flash Layer 1
 *
 * Property casing verified against @google/genai SDK types (2026-01-18):
 * - thinkingConfig (camelCase) - matches SDK GenerationConfig interface
 * - thinkingLevel (camelCase) - matches SDK ThinkingConfig interface
 * - ThinkingLevel enum values: LOW, MINIMAL, MEDIUM, HIGH
 *
 * @see node_modules/@google/genai/dist/genai.d.ts - GenerationConfig, ThinkingConfig
 */
export const LAYER1_GENERATION_CONFIG = {
  temperature: 0,  // Deterministic bounding boxes for consistent object detection
  topP: 0.95,
  maxOutputTokens: 4096,
  responseMimeType: 'application/json',
  responseSchema: LAYER1_DETECTION_SCHEMA,
  thinkingConfig: {
    thinkingLevel: ThinkingLevel.LOW  // Optimized for detection speed
  }
};

/**
 * Create an image part for Gemini API with medium resolution (cost optimization)
 *
 * @param imageBase64 - Base64-encoded image data
 * @param mimeType - Image MIME type (defaults to 'image/jpeg')
 * @returns Image part for Gemini content array
 */
export function createImagePart(imageBase64: string, mimeType: string = 'image/jpeg') {
  return {
    inlineData: {
      mimeType,
      data: imageBase64
    }
    // Note: mediaResolution is set at model level, not per-part in current SDK
  };
}

/**
 * Timeout configuration for Layer 1 operations
 */
export const LAYER1_TIMEOUTS = {
  /** Gemini Flash API timeout (30 seconds) */
  GEMINI_FLASH_TIMEOUT_MS: 30000,

  /** Max retries for transient failures */
  GEMINI_FLASH_MAX_RETRIES: 4,

  /** Per-image fetch timeout (10 seconds) */
  IMAGE_FETCH_TIMEOUT_MS: 10000,

  /** Per-crop operation timeout (5 seconds) */
  CROP_OPERATION_TIMEOUT_MS: 5000,

  /** Total function timeout (120 seconds) */
  FUNCTION_TIMEOUT_SECONDS: 120,

  /** Client-side max wait for detection results (45 seconds) */
  MAX_WAIT_FOR_DETECTION_MS: 45000
};
