import { GoogleGenAI } from '@google/genai';
import fetch from 'node-fetch';
import * as logger from 'firebase-functions/logger';

/**
 * Sweep mode labeling prompt.
 *
 * Unlike single/burst detection which must locate objects in a full scene,
 * sweep crops are already isolated by on-device EdgeTAM segmentation.
 * This prompt only needs to identify and label the pre-cropped object.
 */
const SWEEP_LABELING_PROMPT = `You are analyzing a pre-cropped image of a single household object.
The object has already been detected and cropped by on-device segmentation.

Identify the object and provide:
1. A specific product name or descriptive label (e.g., "Dyson V15 Cordless Vacuum", "Blue Ceramic Coffee Mug")
2. A high-level category
3. Key attributes (color, material, brand if visible, condition)

Be specific. If you can identify the brand or model, include it in the name.
If the crop is unclear or contains no identifiable object, set name to "Unknown Object".`;

/**
 * JSON Schema for sweep label response.
 */
const SWEEP_LABELING_SCHEMA = {
  type: 'object' as const,
  properties: {
    name: {
      type: 'string' as const,
      description: 'Specific product name or descriptive label',
    },
    category: {
      type: 'string' as const,
      description: 'High-level category',
      enum: [
        'electronics', 'furniture', 'clothing', 'kitchenware',
        'books', 'toys', 'sports', 'tools', 'camping',
        'decor', 'appliances', 'personal_care', 'other',
      ],
    },
    attributes: {
      type: 'object' as const,
      properties: {
        color: { type: 'string' as const },
        material: { type: 'string' as const },
        brand: { type: 'string' as const },
        condition: {
          type: 'string' as const,
          enum: ['new', 'like-new', 'good', 'fair', 'poor'],
        },
      },
    },
  },
  required: ['name', 'category'],
};

export interface SweepCropInfo {
  cropUrl: string;
  boundingBox: [number, number, number, number];
  frameIndex: number;
  groupId: string;
}

export interface SweepLabelResult {
  name: string;
  category: string;
  attributes?: Record<string, string>;
}

/**
 * Label pre-cropped objects using Gemini Flash.
 *
 * Sweep sessions provide already-cropped images from on-device EdgeTAM
 * segmentation. This skips bounding box detection entirely and only runs
 * the labeling step, making it ~50% cheaper per item than full detection.
 *
 * @param sweepCrops - Array of pre-cropped segment metadata from EdgeTAM
 * @returns Array of label results, one per crop (same order as input)
 */
export async function labelPrecroppedObjects(
  sweepCrops: SweepCropInfo[]
): Promise<SweepLabelResult[]> {
  const apiKey = process.env.GOOGLE_API_KEY;
  if (!apiKey) {
    throw new Error('GOOGLE_API_KEY environment variable is required');
  }

  const genAI = new GoogleGenAI({ apiKey });
  const results: SweepLabelResult[] = [];

  for (const crop of sweepCrops) {
    try {
      // Fetch crop image from GCS URL
      const imageResponse = await fetch(crop.cropUrl);
      if (!imageResponse.ok) {
        logger.warn(`Failed to fetch crop image: ${crop.cropUrl}`, {
          status: imageResponse.status,
        });
        results.push({ name: 'Unknown Object', category: 'other' });
        continue;
      }

      const contentType = imageResponse.headers.get('content-type') || 'image/jpeg';
      const arrayBuffer = await imageResponse.arrayBuffer();
      const base64Image = Buffer.from(arrayBuffer).toString('base64');

      const result = await genAI.models.generateContent({
        model: 'gemini-2.5-flash-lite',
        contents: [
          {
            role: 'user',
            parts: [
              { text: SWEEP_LABELING_PROMPT },
              {
                inlineData: {
                  mimeType: contentType,
                  data: base64Image,
                },
              },
            ],
          },
        ],
        config: {
          temperature: 0.2,
          topP: 0.8,
          maxOutputTokens: 256,
          responseMimeType: 'application/json',
          responseSchema: SWEEP_LABELING_SCHEMA,
        },
      });

      const text = result.text;
      if (!text) {
        logger.warn('Empty response from Gemini for crop', { groupId: crop.groupId });
        results.push({ name: 'Unknown Object', category: 'other' });
        continue;
      }

      const parsed = JSON.parse(text) as SweepLabelResult;
      results.push(parsed);

      logger.info('Sweep crop labeled', {
        groupId: crop.groupId,
        name: parsed.name,
        category: parsed.category,
        inputTokens: result.usageMetadata?.promptTokenCount || 0,
        outputTokens: result.usageMetadata?.candidatesTokenCount || 0,
      });
    } catch (error) {
      logger.error('Failed to label sweep crop', {
        groupId: crop.groupId,
        error: error instanceof Error ? error.message : String(error),
      });
      results.push({ name: 'Unknown Object', category: 'other' });
    }
  }

  return results;
}
