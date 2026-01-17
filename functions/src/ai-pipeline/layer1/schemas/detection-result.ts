/**
 * Layer 1 Detection Result Schema for Gemini 3 Flash
 *
 * Defines the structure for object detection results including:
 * - Bounding boxes (box_2d format: [ymin, xmin, ymax, xmax] normalized 0-1000)
 * - Object labels and categories
 * - Multi-image grouping (same object across different angles)
 * - Confidence levels and attributes
 */

/**
 * Confidence level for object detection
 */
export type DetectionConfidence = 'high' | 'medium' | 'low';

/**
 * Bounding box in Gemini format: [ymin, xmin, ymax, xmax] normalized to 0-1000
 */
export type BoundingBox = [number, number, number, number];

/**
 * Optional attributes detected for an object
 */
export interface DetectedAttributes {
  color?: string;
  material?: string;
  condition?: string;
  brand?: string;
}

/**
 * Single detection from Layer 1
 */
export interface DetectedObject {
  /** UUID for grouping same object across images */
  groupId: string;

  /** Specific descriptive name (e.g., 'Apple Mac Mini M2') */
  label: string;

  /** High-level category (electronics, furniture, kitchen, etc.) */
  category: string;

  /** [ymin, xmin, ymax, xmax] normalized 0-1000 */
  box_2d: BoundingBox;

  /** Optional attributes */
  attributes?: DetectedAttributes;

  /** Which image this detection is from (0-indexed) */
  image_index: number;

  /** Detection confidence */
  confidence?: DetectionConfidence;
}

/**
 * Layer 1 detection response from Gemini 3 Flash
 */
export interface Layer1DetectionResponse {
  /** Detected objects array */
  objects: DetectedObject[];

  /** Explanation when no objects detected, or grouping logic for multi-image */
  reasoning?: string;
}

/**
 * Validation result for detection response
 */
export interface ValidationResult {
  valid: boolean;
  errors: string[];
}

/**
 * Validate a Layer 1 detection response
 */
export function validateDetectionResponse(response: Layer1DetectionResponse): ValidationResult {
  const errors: string[] = [];

  if (!response.objects || !Array.isArray(response.objects)) {
    errors.push('Response must contain an objects array');
    return { valid: false, errors };
  }

  for (let i = 0; i < response.objects.length; i++) {
    const obj = response.objects[i];
    const prefix = `objects[${i}]`;

    if (!obj.groupId || typeof obj.groupId !== 'string') {
      errors.push(`${prefix}.groupId is required and must be a string`);
    }
    if (!obj.label || typeof obj.label !== 'string') {
      errors.push(`${prefix}.label is required and must be a string`);
    }
    if (!obj.category || typeof obj.category !== 'string') {
      errors.push(`${prefix}.category is required and must be a string`);
    }
    if (!Array.isArray(obj.box_2d) || obj.box_2d.length !== 4) {
      errors.push(`${prefix}.box_2d must be an array of 4 numbers`);
    } else {
      for (let j = 0; j < 4; j++) {
        const val = obj.box_2d[j];
        if (typeof val !== 'number' || val < 0 || val > 1000) {
          errors.push(`${prefix}.box_2d[${j}] must be a number between 0 and 1000`);
        }
      }
    }
    if (typeof obj.image_index !== 'number' || obj.image_index < 0) {
      errors.push(`${prefix}.image_index is required and must be a non-negative number`);
    }
    if (obj.confidence && !['high', 'medium', 'low'].includes(obj.confidence)) {
      errors.push(`${prefix}.confidence must be 'high', 'medium', or 'low'`);
    }
  }

  return { valid: errors.length === 0, errors };
}

/**
 * JSON Schema for Gemini responseSchema
 */
export const LAYER1_DETECTION_SCHEMA = {
  type: 'object',
  properties: {
    objects: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          groupId: {
            type: 'string',
            description: 'UUID for grouping same object across images'
          },
          label: {
            type: 'string',
            description: 'Specific descriptive name (e.g., "Apple Mac Mini M2")'
          },
          category: {
            type: 'string',
            description: 'High-level category (electronics, furniture, kitchen, etc.)'
          },
          box_2d: {
            type: 'array',
            items: { type: 'integer' },
            minItems: 4,
            maxItems: 4,
            description: '[ymin, xmin, ymax, xmax] normalized 0-1000'
          },
          attributes: {
            type: 'object',
            properties: {
              color: { type: 'string' },
              material: { type: 'string' },
              condition: { type: 'string' },
              brand: { type: 'string' }
            }
          },
          image_index: {
            type: 'integer',
            description: 'Which image this detection is from (0-indexed)'
          },
          confidence: {
            type: 'string',
            enum: ['high', 'medium', 'low']
          }
        },
        required: ['groupId', 'label', 'category', 'box_2d', 'image_index']
      }
    },
    reasoning: {
      type: 'string',
      description: 'Explanation when no objects detected, or grouping logic for multi-image'
    }
  },
  required: ['objects']
};
