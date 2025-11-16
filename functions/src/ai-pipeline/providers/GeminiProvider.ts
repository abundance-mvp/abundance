import { GoogleGenAI } from '@google/genai';
import fetch from 'node-fetch';

/**
 * Gemini AI provider for attribute extraction (Layer 2a)
 * Uses @google/genai SDK with JSON Schema Mode
 */
export class GeminiProvider {
  private genAI: GoogleGenAI;

  constructor() {
    // Require API key
    const apiKey = process.env.GOOGLE_API_KEY;
    if (!apiKey) {
      throw new Error('GOOGLE_API_KEY environment variable is required');
    }

    this.genAI = new GoogleGenAI({ apiKey });
  }

  /**
   * Extract attributes from product image
   */
  async extractAttributes(
    imageUrl: string,
    userId: string,
    itemId: string
  ): Promise<any> {
    // Fetch image from Cloud Storage
    const imageResponse = await fetch(imageUrl);
    const arrayBuffer = await imageResponse.arrayBuffer();
    const base64Image = Buffer.from(arrayBuffer).toString('base64');

    // Retry logic with exponential backoff
    const maxRetries = 3;
    const baseDelay = 1000; // 1 second
    let lastError: Error | null = null;

    for (let attempt = 0; attempt < maxRetries; attempt++) {
      try {
        // Generate content with image using SDK API
        const result = await this.genAI.models.generateContent({
          model: 'gemini-2.5-flash-lite',
          contents: [
            {
              role: 'user',
              parts: [
                { text: this.getPrompt() },
                {
                  inlineData: {
                    mimeType: 'image/jpeg',
                    data: base64Image
                  }
                }
              ]
            }
          ],
          config: {
            temperature: 0.2,
            topP: 0.8,
            topK: 40,
            maxOutputTokens: 256,
            responseMimeType: 'application/json',
            responseSchema: this.getAttributeSchema()
          }
        });

        const text = result.text;
        if (!text) {
          throw new Error('No text response from Gemini API');
        }
        const attributes = JSON.parse(text);

        // Attach usage metadata
        const usage = result.usageMetadata;
        (attributes as any).usage = {
          inputTokens: usage?.promptTokenCount || 0,
          outputTokens: usage?.candidatesTokenCount || 0,
          totalTokens: usage?.totalTokenCount || 0
        };

        return attributes;
      } catch (error: any) {
        lastError = error;

        // Don't retry on permanent errors
        if (
          error.message.includes('400') ||
          error.message.includes('API key')
        ) {
          throw error;
        }

        // Calculate backoff delay
        if (attempt < maxRetries - 1) {
          const delay = Math.min(
            Math.pow(2, attempt) * baseDelay,
            60000 // Max 60 seconds
          );
          console.log(`Attempt ${attempt + 1} failed, retrying in ${delay}ms...`);
          await new Promise(resolve => setTimeout(resolve, delay));
        }
      }
    }

    throw new Error(`Max retries (${maxRetries}) exceeded: ${lastError?.message}`);
  }

  /**
   * Get JSON Schema for attribute extraction
   */
  private getAttributeSchema() {
    return {
      type: 'object',
      properties: {
        category: {
          type: 'string',
          description: 'Primary household item category',
          enum: ['camping', 'electronics', 'furniture', 'clothing', 'kitchenware', 'books', 'toys', 'sports', 'tools', 'other']
        },
        color: {
          type: 'string',
          description: 'Primary visible color'
        },
        material: {
          type: 'string',
          description: 'Primary material'
        },
        condition: {
          type: 'string',
          description: 'Visual condition assessment',
          enum: ['new', 'like-new', 'good', 'fair', 'poor']
        },
        confidence: {
          type: 'number',
          description: 'Overall confidence (0.0-1.0)',
          minimum: 0,
          maximum: 1
        }
      },
      required: ['category', 'color', 'condition']
    };
  }

  /**
   * Get extraction prompt
   */
  private getPrompt(): string {
    return `Analyze this product photo and extract the following attributes:

- category: Primary household item category (camping, electronics, furniture, clothing, kitchenware, books, toys, sports, tools, other)
- color: Primary visible color (e.g., red, blue, green, black, white)
- material: Primary material (e.g., metal, plastic, fabric, wood, glass)
- condition: Visual condition (new, like-new, good, fair, poor)
- confidence: Overall confidence in extraction (0.0-1.0)

Return structured JSON matching the schema. Required fields: category, color, condition.`;
  }
}
