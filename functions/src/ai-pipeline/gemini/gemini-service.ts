/**
 * Gemini 3 Pro Service
 *
 * Orchestrates the Gemini 3 Pro API for item cataloging with tool calling support.
 * This is the main entry point for processing images through the AI pipeline.
 *
 * IMPORTANT: Gemini 3 requires thought_signature preservation for function calls.
 * See: https://cloud.google.com/vertex-ai/generative-ai/docs/thought-signatures
 */

import { Content, Part, FunctionCall, GenerateContentResponse, CachedContent } from '@google/genai';
import { createVertexAIClient } from './vertexai-config';
import { CatalogItem } from './schemas/catalog-item';
import { SYSTEM_PROMPT, CATALOG_TOOLS, GENERATION_CONFIG, GEMINI_MODEL_ID } from './prompts';
import { executeToolCall } from '../tools/tool-executor';
import {
  saveCatalogHistory,
  getRecentCatalogHistory,
  formatHistoryForPrompt,
  catalogItemToSnapshot
} from './catalog-history-service';
import { getOrCreateContextCache } from './context-cache-service';
import { ToolCallRecord } from './schemas/catalog-history';

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

    console.log(`Iteration ${iterations + 1}: Processing ${functionCalls.length} function call(s): ${functionCalls.map(c => c.name).join(', ')}`);

    // Execute tool calls and collect results
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

    // CRITICAL: Preserve the original model parts including thought_signature
    // Gemini 3 requires thought_signature for function calls, otherwise returns 400 error
    // See: https://cloud.google.com/vertex-ai/generative-ai/docs/thought-signatures
    const modelParts = getModelPartsWithThoughtSignature(response);
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

  if (iterations >= maxIterations) {
    console.warn(`Hit max iterations (${maxIterations}) - model may be stuck in tool-calling loop`);
  }

  const text = response.text;
  if (!text) {
    // Log response details for debugging
    const candidate = response.candidates?.[0];
    console.error('No text in response. Finish reason:', candidate?.finishReason);
    console.error('Response parts:', JSON.stringify(candidate?.content?.parts?.map(p => ({
      hasText: !!p.text,
      hasFunctionCall: !!p.functionCall,
      hasThought: !!p.thought
    })), null, 2));
    throw new Error(`No text response from Gemini after ${iterations} iterations`);
  }

  return JSON.parse(text) as CatalogItem | CatalogItem[];
}

/**
 * Extract model parts from response, preserving thought_signature for Gemini 3.
 *
 * Gemini 3 requires thought_signature to be passed back with function calls,
 * otherwise it returns a 400 error. The signature is attached to the first
 * functionCall part in parallel calls, and to each functionCall in sequential calls.
 *
 * @param response - The GenerateContentResponse from Gemini
 * @returns Array of Part objects with preserved thought_signature
 */
function getModelPartsWithThoughtSignature(response: GenerateContentResponse): Part[] {
  // Get parts directly from the response to preserve thought_signature
  const candidate = response.candidates?.[0];
  if (!candidate?.content?.parts) {
    return [];
  }

  // Return the original parts which include thought_signature
  // Filter to only include parts that have function calls or thought-related content
  return candidate.content.parts.filter(part =>
    part.functionCall || part.thought || part.thoughtSignature
  );
}

/**
 * Fetch an image from a URL and return it as base64.
 * Supports both HTTP(S) URLs and base64 data URLs.
 *
 * @param url - URL of the image to fetch, or base64 data URL (data:image/...;base64,...)
 * @returns Base64-encoded image data (without data URL prefix)
 * @throws Error if fetch fails or content type is not an image
 */
async function fetchImageBase64(url: string): Promise<string> {
  // Handle base64 data URLs directly (used for testing with private storage)
  if (url.startsWith('data:image/')) {
    const base64Match = url.match(/^data:image\/[^;]+;base64,(.+)$/);
    if (base64Match) {
      return base64Match[1];
    }
    throw new Error('Invalid data URL format');
  }

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

/**
 * Process an image with session persistence.
 * Uses previous catalog history for context continuity.
 *
 * @param imageUrl - Public URL of the image to process
 * @param itemId - Optional item ID for history lookup (enables persistence)
 * @param useContextCache - Whether to use cached system prompt (default: true)
 * @returns CatalogItem or array of CatalogItems
 */
export async function processItemWithGeminiPersistent(
  imageUrl: string,
  itemId?: string,
  useContextCache: boolean = true
): Promise<CatalogItem | CatalogItem[]> {
  const startTime = Date.now();
  const toolCallRecords: ToolCallRecord[] = [];
  let totalTokens = 0;

  // Get previous history if itemId provided
  let historyContext = '';
  if (itemId) {
    const history = await getRecentCatalogHistory(itemId, 1);
    historyContext = formatHistoryForPrompt(history);
  }

  const imageBase64 = await fetchImageBase64(imageUrl);
  const ai = createVertexAIClient();

  // Build user prompt with optional history context
  const userPrompt = historyContext
    ? `${historyContext}\n\nAnalyze this NEW image and update/confirm the catalog entry.`
    : 'Analyze this image and create catalog entry(ies).';

  let contents: Content[] = [{
    role: 'user',
    parts: [
      { text: userPrompt },
      { inlineData: { mimeType: 'image/jpeg', data: imageBase64 } }
    ]
  }];

  // Use context cache if enabled
  let cachedContent: CachedContent | undefined;
  if (useContextCache) {
    try {
      cachedContent = await getOrCreateContextCache();
    } catch (err) {
      console.warn('Context cache unavailable, falling back to inline config:', err);
    }
  }

  const toolDeclarations = CATALOG_TOOLS.flatMap(t => t.functionDeclarations || []);

  // Configure request - use cache or inline config
  const requestConfig = cachedContent
    ? { cachedContent: cachedContent.name }
    : {
        systemInstruction: SYSTEM_PROMPT,
        tools: [{ functionDeclarations: toolDeclarations as any }],
        ...GENERATION_CONFIG
      };

  let response = await ai.models.generateContent({
    model: GEMINI_MODEL_ID,
    contents,
    config: requestConfig
  });
  totalTokens += response.usageMetadata?.totalTokenCount ?? 0;

  let iterations = 0;
  const maxIterations = 10;

  while (iterations < maxIterations) {
    const functionCalls = response.functionCalls || [];

    if (functionCalls.length === 0) {
      break;
    }

    console.log(`Iteration ${iterations + 1}: Processing ${functionCalls.length} function call(s)`);

    const toolResults = await Promise.all(
      functionCalls.map(async (call: FunctionCall) => {
        const name = call.name || '';
        const args = call.args || {};
        let result: Record<string, unknown>;
        let success = true;

        try {
          result = await executeToolCall(name, args, imageUrl) as Record<string, unknown>;
        } catch (err) {
          result = { error: err instanceof Error ? err.message : 'Unknown error' };
          success = false;
        }

        // Record tool call for history
        toolCallRecords.push({ name, args, result, success });

        return {
          functionResponse: { name, response: result }
        };
      })
    );

    const modelParts = getModelPartsWithThoughtSignature(response);
    const userParts: Part[] = toolResults.map(r => ({ functionResponse: r.functionResponse }));

    contents = [
      ...contents,
      { role: 'model', parts: modelParts },
      { role: 'user', parts: userParts }
    ];

    response = await ai.models.generateContent({
      model: GEMINI_MODEL_ID,
      contents,
      config: requestConfig
    });
    totalTokens += response.usageMetadata?.totalTokenCount ?? 0;

    iterations++;
  }

  const text = response.text;
  if (!text) {
    throw new Error(`No text response from Gemini after ${iterations} iterations`);
  }

  const catalogResult = JSON.parse(text) as CatalogItem | CatalogItem[];
  const durationMs = Date.now() - startTime;

  // Save to history if itemId provided
  if (itemId) {
    const resultItem = Array.isArray(catalogResult) ? catalogResult[0] : catalogResult;
    await saveCatalogHistory(itemId, {
      model: GEMINI_MODEL_ID,
      imageUrls: [imageUrl],
      toolCalls: toolCallRecords,
      result: catalogItemToSnapshot(resultItem),
      metadata: {
        totalTokens,
        durationMs,
        usedContextCache: !!cachedContent
      }
    });
  }

  return catalogResult;
}
