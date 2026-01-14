import { CATALOG_ITEM_SCHEMA } from './schemas/catalog-item';

export const SYSTEM_PROMPT = `You are an expert product cataloger. Analyze the provided image and create detailed catalog entries.

WORKFLOW:
1. Examine the image carefully for:
   - Product type, category, and sub-category
   - Visible barcodes (if any)
   - Brand logos or text
   - Physical condition indicators
   - Size/dimension clues
   - Quantity (if multiple identical items)

2. If you see a barcode, use barcode_lookup to get product details.
   Always also use google_lens_search for verification and additional data.

3. Verify tool results against what you see:
   - Does the returned product match the image?
   - If mismatch, trust your visual analysis over tool results.

4. Once you have HIGH or MEDIUM confidence on product identity:
   - Use web_search to find current market prices
   - Search query format: "{brand} {model} {condition} price"

5. Return complete catalog entry(ies) with confidence level.

CONFIDENCE SCORING:
- "high": Google Lens returned exact_matches:true OR barcode lookup succeeded AND visual verification confirms
- "medium": Google Lens returned similar products but not exact, OR barcode lookup failed but Google Lens found likely match
- "low": Only related suggestions available, relying primarily on visual analysis

PRICING:
- Use SOLD prices when available (eBay sold listings)
- Apply condition multipliers to new retail price:
  - new: 1.0
  - like-new: 0.85
  - good: 0.65
  - fair: 0.45
  - poor: 0.25
- If no pricing found, set estimatedValue: null

OUTPUT FORMAT:
Return valid JSON matching the CatalogItem schema.`;

/**
 * Tool definition for Gemini function declarations
 */
interface ToolProperty {
  type: string;
  description: string;
  enum?: string[];
}

interface ToolParameters {
  type: string;
  properties: Record<string, ToolProperty>;
  required: string[];
}

interface FunctionDeclaration {
  name: string;
  description: string;
  parameters: ToolParameters;
}

interface Tool {
  functionDeclarations: FunctionDeclaration[];
}

export const CATALOG_TOOLS: Tool[] = [
  {
    functionDeclarations: [
      {
        name: 'google_lens_search',
        description: 'Search for product information using visual matching.',
        parameters: {
          type: 'object',
          properties: {
            image_url: {
              type: 'string',
              description: 'Public URL of the product image'
            }
          },
          required: ['image_url']
        }
      }
    ]
  },
  {
    functionDeclarations: [
      {
        name: 'barcode_lookup',
        description: 'Look up product information by barcode number.',
        parameters: {
          type: 'object',
          properties: {
            code: {
              type: 'string',
              description: 'The barcode number'
            },
            symbology: {
              type: 'string',
              enum: ['upc_a', 'upc_e', 'ean_13', 'ean_8', 'qr', 'code_128'],
              description: 'The barcode format (optional)'
            }
          },
          required: ['code']
        }
      }
    ]
  },
  {
    functionDeclarations: [
      {
        name: 'web_search',
        description: 'Search e-commerce sites for current pricing.',
        parameters: {
          type: 'object',
          properties: {
            query: {
              type: 'string',
              description: 'Search query'
            }
          },
          required: ['query']
        }
      }
    ]
  }
];

export const GENERATION_CONFIG = {
  temperature: 0.1,
  topP: 0.95,
  maxOutputTokens: 1024,
  responseMimeType: 'application/json',
  responseSchema: CATALOG_ITEM_SCHEMA
};

export const GEMINI_MODEL_ID = 'gemini-3-pro-preview';
