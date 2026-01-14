/**
 * Gemini 3 Pro Service
 *
 * Orchestrates the Gemini 3 Pro API for item cataloging with tool calling support.
 * This is the main entry point for processing images through the AI pipeline.
 */

import { Content, Part, FunctionCall } from '@google/genai';
import { createVertexAIClient } from './vertexai-config';
import { CatalogItem } from './schemas/catalog-item';
import { SYSTEM_PROMPT, CATALOG_TOOLS, GENERATION_CONFIG, GEMINI_MODEL_ID } from './prompts';
import { executeToolCall } from '../tools/tool-executor';

/**
 * Process an image through Gemini 3 Pro and return catalog item(s).
 *
 * The function:
 * 1. Fetches the image from the provided URL
 * 2. Sends it to Gemini 3 Pro with tool declarations
 * 3. Handles the tool calling loop (barcode lookup, Google Lens, web search)
 * 4. Returns the final catalog item(s)
 *
 * @param imageUrl - Public URL of the image to process
 * @returns CatalogItem or array of CatalogItems
 * @throws Error if Vertex AI config is missing, image fetch fails, or Gemini returns no response
 */
export async function processItemWithGemini(
  imageUrl: string
): Promise<CatalogItem | CatalogItem[]> {
  const imageBase64 = await fetchImageBase64(imageUrl);

  // Gemini 3 models require Vertex AI (not API keys)
  const ai = createVertexAIClient();

  const toolDeclarations = CATALOG_TOOLS.flatMap(t => t.functionDeclarations || []);

  let contents: Content[] = [{
    role: 'user',
    parts: [
      { text: 'Analyze this image and create catalog entry(ies).' },
      {
        inlineData: {
          mimeType: 'image/jpeg',
          data: imageBase64
        }
      }
    ]
  }];

  let response = await ai.models.generateContent({
    model: GEMINI_MODEL_ID,
    contents,
    config: {
      systemInstruction: SYSTEM_PROMPT,
      // Cast to any to work around type mismatch between our tool definitions and SDK types
      tools: [{ functionDeclarations: toolDeclarations as any }],
      ...GENERATION_CONFIG
    }
  });

  let iterations = 0;
  const maxIterations = 10;

  while (iterations < maxIterations) {
    const functionCalls = response.functionCalls || [];

    if (functionCalls.length === 0) {
      break;
    }

    const toolResults = await Promise.all(
      functionCalls.map(async (call: FunctionCall) => {
        const name = call.name || '';
        const result = await executeToolCall(name, call.args || {}, imageUrl);
        return {
          functionResponse: {
            name,
            response: result as Record<string, unknown>
          }
        };
      })
    );

    const modelParts: Part[] = functionCalls.map((c: FunctionCall) => ({ functionCall: c }));
    const userParts: Part[] = toolResults.map(r => ({ functionResponse: r.functionResponse }));

    contents = [
      ...contents,
      { role: 'model', parts: modelParts },
      { role: 'user', parts: userParts }
    ];

    response = await ai.models.generateContent({
      model: GEMINI_MODEL_ID,
      contents,
      config: {
        systemInstruction: SYSTEM_PROMPT,
        tools: [{ functionDeclarations: toolDeclarations as any }],
        ...GENERATION_CONFIG
      }
    });

    iterations++;
  }

  const text = response.text;
  if (!text) {
    throw new Error('No text response from Gemini');
  }

  return JSON.parse(text) as CatalogItem | CatalogItem[];
}

/**
 * Fetch an image from a URL and return it as base64.
 *
 * @param url - URL of the image to fetch
 * @returns Base64-encoded image data
 * @throws Error if fetch fails or content type is not an image
 */
async function fetchImageBase64(url: string): Promise<string> {
  const response = await fetch(url);

  if (!response.ok) {
    throw new Error(`Failed to fetch image: ${response.status} ${response.statusText}`);
  }

  const contentType = response.headers.get('content-type') || '';
  if (!contentType.startsWith('image/')) {
    throw new Error(`Invalid content type: expected image/*, got ${contentType}`);
  }

  const buffer = await response.arrayBuffer();
  return Buffer.from(buffer).toString('base64');
}
