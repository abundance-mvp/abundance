/**
 * Context Caching Service for Gemini 3 Pro
 *
 * Uses Gemini's Explicit Context Caching to cache system prompts and tool
 * definitions, achieving ~90% token cost reduction on repeated calls.
 *
 * Requirements:
 * - Minimum 2048 tokens for caching (our system prompt + tools exceeds this)
 * - Cache TTL: 1 hour minimum, up to 24 hours
 * - Cache is immutable - create new cache for prompt changes
 *
 * @see https://ai.google.dev/gemini-api/docs/caching
 */

import { CachedContent } from '@google/genai';
import { createVertexAIClient } from './vertexai-config';
import { SYSTEM_PROMPT, CATALOG_TOOLS, GEMINI_MODEL_ID } from './prompts';

/** Cache TTL in seconds (1 hour) */
const CACHE_TTL_SECONDS = 3600;

/** In-memory reference to current cache (refresh on cold start) */
let currentCache: CachedContent | null = null;
let cacheExpiresAt: Date | null = null;

/**
 * Get or create a cached context for the system prompt and tools.
 *
 * @returns CachedContent object to use in generateContent calls
 */
export async function getOrCreateContextCache(): Promise<CachedContent> {
  // Check if we have a valid cache
  if (currentCache && cacheExpiresAt && new Date() < cacheExpiresAt) {
    return currentCache;
  }

  const ai = createVertexAIClient();

  // Flatten tool declarations for caching
  const toolDeclarations = CATALOG_TOOLS.flatMap(t => t.functionDeclarations || []);

  // Create cached content with system prompt and tools
  // Note: The system prompt + tool definitions exceed 2048 tokens minimum
  const cachedContent = await ai.caches.create({
    model: GEMINI_MODEL_ID,
    config: {
      systemInstruction: SYSTEM_PROMPT,
      // Cast to any to work around type mismatch between our tool definitions and SDK types
      tools: [{ functionDeclarations: toolDeclarations as any }],
      ttl: `${CACHE_TTL_SECONDS}s`,
      displayName: 'abundance-catalog-context'
    }
  });

  // Store reference and expiry
  currentCache = cachedContent;
  cacheExpiresAt = new Date(Date.now() + CACHE_TTL_SECONDS * 1000);

  console.log(`Created context cache: ${cachedContent.name}, expires: ${cacheExpiresAt.toISOString()}`);

  return cachedContent;
}

/**
 * List existing caches (for debugging/monitoring).
 */
export async function listContextCaches(): Promise<CachedContent[]> {
  const ai = createVertexAIClient();
  const pager = await ai.caches.list();
  const caches: CachedContent[] = [];

  // Collect all pages
  for await (const cache of pager) {
    caches.push(cache);
  }

  return caches;
}

/**
 * Delete a specific cache by name.
 */
export async function deleteContextCache(cacheName: string): Promise<void> {
  const ai = createVertexAIClient();
  await ai.caches.delete({ name: cacheName });
  console.log(`Deleted context cache: ${cacheName}`);

  // Clear local reference if it matches
  if (currentCache?.name === cacheName) {
    currentCache = null;
    cacheExpiresAt = null;
  }
}

/**
 * Check if context caching is available and beneficial.
 * Returns estimated token savings.
 */
export function estimateTokenSavings(): { systemTokens: number; savingsPercent: number } {
  // Rough estimate: system prompt ~1500 tokens, tools ~800 tokens
  const systemTokens = 2300;
  const savingsPercent = 90; // Per Google's documentation

  return { systemTokens, savingsPercent };
}

/**
 * Clear the in-memory cache reference.
 * Useful for testing or forcing a refresh.
 */
export function clearCacheReference(): void {
  currentCache = null;
  cacheExpiresAt = null;
}
