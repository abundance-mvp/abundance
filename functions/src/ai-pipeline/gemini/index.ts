/**
 * Gemini 3 Pro Pipeline - Public Exports
 *
 * Single entry point for the Gemini 3 Pro AI pipeline.
 * Replaces the previous 4-layer pipeline (Gemini Flash-Lite + Claude Haiku + Claude Sonnet).
 */

// Schema exports
export {
  CatalogItem,
  Condition,
  Confidence,
  validateCatalogItem,
  CATALOG_ITEM_SCHEMA
} from './schemas/catalog-item';

// Prompt/config exports
export {
  SYSTEM_PROMPT,
  CATALOG_TOOLS,
  GENERATION_CONFIG,
  GEMINI_MODEL_ID
} from './prompts';

// Service exports
export { processItemWithGemini, processItemWithGeminiPersistent } from './gemini-service';

// Orchestrator exports
export { handleItemCreated, logCosts } from './orchestrator';
