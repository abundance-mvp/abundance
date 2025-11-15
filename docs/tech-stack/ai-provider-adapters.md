# AI Provider Adapter Interfaces

**Created**: 2025-11-11
**Stage**: 4.3 - AI Pipeline Integration Scaffolding
**References**:
- docs/validation/RESEARCH-VALIDATION-stage-4.3.md
- docs/plans/PLAN-SUMMARY-stage-3.4.md (Layer 2a code examples)
- docs/plans/PLAN-SUMMARY-stage-3.5.md (Layer 2b code examples)
- docs/plans/PLAN-SUMMARY-stage-3.6.md (Layer 3 code examples)
**Status**: Draft

## Overview

This document defines the TypeScript interfaces for all AI provider adapters used in the computer vision pipeline. Each provider implements a standardized interface to enable dependency injection, mocking, and consistent error handling.

## Base Provider Interface

All providers extend this base interface:

```typescript
/**
 * Base interface for all AI provider adapters
 */
export interface AIProvider {
  /**
   * Initialize the provider with API credentials
   * @throws {ProviderInitializationError} If credentials are missing or invalid
   */
  initialize(): Promise<void>;

  /**
   * Get the provider name for logging and cost tracking
   */
  getProviderName(): string;

  /**
   * Estimate cost for a request (before making API call)
   * @param inputSize - Size of input (tokens, bytes, etc.)
   * @returns Estimated cost in USD
   */
  estimateCost(inputSize: number): number;
}
```

## Layer 2a: GeminiProvider (Attribute Extraction)

```typescript
import { GoogleGenerativeAI } from '@google/genai';

/**
 * Gemini 2.5 Flash-Lite provider for visual attribute extraction
 * Layer 2a: Photo → 10-15 structured attributes
 */
export interface IGeminiProvider extends AIProvider {
  /**
   * Extract visual attributes from a photo
   * @param imageUrl - Cloud Storage public URL or signed URL
   * @param prompt - System prompt with attribute schema
   * @returns Structured attributes with confidence scores
   * @throws {RateLimitError} If quota exceeded (429)
   * @throws {InvalidImageError} If image unreadable (400)
   */
  extractAttributes(
    imageUrl: string,
    prompt: string
  ): Promise<GeminiAttributeResponse>;
}

/**
 * Gemini API response structure
 */
export interface GeminiAttributeResponse {
  attributes: {
    item_type: string;
    brand?: string;
    size?: string;
    color?: string;
    material?: string;
    condition?: string;
    packaging_type?: string;
    text_visible?: string[];
    barcode_detected?: boolean;
    expiry_visible?: boolean;
    // ... up to 15 attributes
  };
  confidence_scores: {
    [key: string]: number; // 0.0-1.0 per attribute
  };
  usage: {
    input_tokens: number;
    output_tokens: number;
    total_cost_usd: number;
  };
  model: string; // "gemini-2.5-flash-lite"
  timestamp: string; // ISO 8601
}

/**
 * Implementation example (for reference)
 */
export class GeminiProvider implements IGeminiProvider {
  private client: GoogleGenerativeAI;
  private model: any;

  constructor(apiKey: string) {
    this.client = new GoogleGenerativeAI(apiKey);
  }

  async initialize(): Promise<void> {
    this.model = this.client.getGenerativeModel({
      model: 'gemini-2.5-flash-lite'
    });
  }

  getProviderName(): string {
    return 'Google Gemini 2.5 Flash-Lite';
  }

  estimateCost(inputSize: number): number {
    // $0.01 per 1M input tokens, $0.04 per 1M output tokens
    // Estimate: 1 image ~= 258 tokens, output ~= 100 tokens
    const inputCost = (inputSize / 1_000_000) * 0.01;
    const outputCost = (100 / 1_000_000) * 0.04;
    return inputCost + outputCost;
  }

  async extractAttributes(
    imageUrl: string,
    prompt: string
  ): Promise<GeminiAttributeResponse> {
    const result = await this.model.generateContent([
      prompt,
      {
        inlineData: {
          mimeType: 'image/jpeg',
          data: await this.fetchImageAsBase64(imageUrl)
        }
      }
    ]);

    const response = result.response;
    const text = response.text();

    // Parse JSON response
    const attributes = JSON.parse(text);

    // Calculate cost from usage metadata
    const usage = response.usageMetadata;
    const inputCost = (usage.promptTokenCount / 1_000_000) * 0.01;
    const outputCost = (usage.candidatesTokenCount / 1_000_000) * 0.04;

    return {
      attributes: attributes.attributes,
      confidence_scores: attributes.confidence_scores,
      usage: {
        input_tokens: usage.promptTokenCount,
        output_tokens: usage.candidatesTokenCount,
        total_cost_usd: inputCost + outputCost
      },
      model: 'gemini-2.5-flash-lite',
      timestamp: new Date().toISOString()
    };
  }

  private async fetchImageAsBase64(url: string): Promise<string> {
    // Implementation detail
    const fetch = (await import('node-fetch')).default;
    const response = await fetch(url);
    const buffer = await response.arrayBuffer();
    return Buffer.from(buffer).toString('base64');
  }
}
```

## Layer 2b: ClaudeHaikuProvider (Parsing)

```typescript
import Anthropic from '@anthropic-ai/sdk';

/**
 * Claude Haiku 4.5 provider for text parsing
 * Layer 2b: Unstructured text → Structured JSON
 */
export interface IClaudeHaikuProvider extends AIProvider {
  /**
   * Parse unstructured text into structured data
   * @param text - Raw text from SerpAPI or barcode lookups
   * @param schema - JSON schema for expected output structure
   * @returns Parsed structured data
   * @throws {RateLimitError} If quota exceeded (429)
   * @throws {InvalidSchemaError} If JSON schema invalid (400)
   */
  parseText(text: string, schema: object): Promise<ClaudeParseResponse>;
}

/**
 * Claude Haiku API response structure
 */
export interface ClaudeParseResponse {
  parsed_data: {
    [key: string]: any; // Schema-compliant structured data
  };
  usage: {
    input_tokens: number;
    output_tokens: number;
    total_cost_usd: number;
  };
  model: string; // "claude-haiku-4.5"
  timestamp: string; // ISO 8601
}

/**
 * Implementation example (for reference)
 */
export class ClaudeHaikuProvider implements IClaudeHaikuProvider {
  private client: Anthropic;

  constructor(apiKey: string) {
    this.client = new Anthropic({ apiKey });
  }

  async initialize(): Promise<void> {
    // No initialization needed for Anthropic SDK
  }

  getProviderName(): string {
    return 'Anthropic Claude Haiku 4.5';
  }

  estimateCost(inputSize: number): number {
    // $0.80 per 1M input tokens, $4 per 1M output tokens
    const inputCost = (inputSize / 1_000_000) * 0.80;
    const outputCost = (200 / 1_000_000) * 4.0; // Estimate 200 tokens output
    return inputCost + outputCost;
  }

  async parseText(text: string, schema: object): Promise<ClaudeParseResponse> {
    const message = await this.client.messages.create({
      model: 'claude-haiku-4.5-20250110',
      max_tokens: 1024,
      messages: [{
        role: 'user',
        content: `Parse the following text into JSON matching this schema: ${JSON.stringify(schema)}\n\nText: ${text}`
      }]
    });

    const usage = message.usage;
    const inputCost = (usage.input_tokens / 1_000_000) * 0.80;
    const outputCost = (usage.output_tokens / 1_000_000) * 4.0;

    return {
      parsed_data: JSON.parse(message.content[0].text),
      usage: {
        input_tokens: usage.input_tokens,
        output_tokens: usage.output_tokens,
        total_cost_usd: inputCost + outputCost
      },
      model: 'claude-haiku-4.5',
      timestamp: new Date().toISOString()
    };
  }
}
```

## Layer 3: ClaudeSonnetProvider (Synthesis)

```typescript
/**
 * Claude Sonnet 4.5 provider for metadata synthesis
 * Layer 3: Multi-source data → Final unified metadata
 */
export interface IClaudeSonnetProvider extends AIProvider {
  /**
   * Synthesize data from multiple sources into final metadata
   * @param sources - Array of data from Layer 2a, Layer 2b providers
   * @param userContext - Optional user-provided context (notes, tags)
   * @returns Final unified metadata
   * @throws {RateLimitError} If quota exceeded (429)
   */
  synthesizeMetadata(
    sources: MetadataSource[],
    userContext?: UserContext
  ): Promise<ClaudeSynthesisResponse>;

  /**
   * Submit batch synthesis job (for cost savings)
   * @param items - Array of items to synthesize
   * @returns Batch job ID
   */
  submitBatch(items: MetadataSource[][]): Promise<string>;

  /**
   * Poll batch job status
   * @param jobId - Batch job ID from submitBatch()
   * @returns Job status and results (if complete)
   */
  pollBatchStatus(jobId: string): Promise<BatchJobStatus>;
}

/**
 * Metadata source from previous layers
 */
export interface MetadataSource {
  provider: string; // "gemini", "serpapi", "openfoodfacts", etc.
  data: object;
  confidence: number; // 0.0-1.0
  timestamp: string;
}

/**
 * User-provided context
 */
export interface UserContext {
  notes?: string;
  custom_tags?: string[];
  location?: string;
}

/**
 * Claude Sonnet API response structure
 */
export interface ClaudeSynthesisResponse {
  final_metadata: {
    name: string;
    category: string;
    brand?: string;
    quantity?: string;
    expiry_date?: string;
    storage_location?: string;
    tags: string[];
    confidence: number;
  };
  usage: {
    input_tokens: number;
    output_tokens: number;
    total_cost_usd: number;
  };
  model: string; // "claude-sonnet-4.5"
  timestamp: string; // ISO 8601
}

/**
 * Batch job status
 */
export interface BatchJobStatus {
  job_id: string;
  status: 'processing' | 'completed' | 'failed';
  progress?: number; // 0-100
  results?: ClaudeSynthesisResponse[];
  error?: string;
}

/**
 * Implementation example (for reference)
 */
export class ClaudeSonnetProvider implements IClaudeSonnetProvider {
  private client: Anthropic;

  constructor(apiKey: string) {
    this.client = new Anthropic({ apiKey });
  }

  async initialize(): Promise<void> {
    // No initialization needed
  }

  getProviderName(): string {
    return 'Anthropic Claude Sonnet 4.5';
  }

  estimateCost(inputSize: number): number {
    // $3 per 1M input tokens, $15 per 1M output tokens
    const inputCost = (inputSize / 1_000_000) * 3.0;
    const outputCost = (300 / 1_000_000) * 15.0; // Estimate 300 tokens output
    return inputCost + outputCost;
  }

  async synthesizeMetadata(
    sources: MetadataSource[],
    userContext?: UserContext
  ): Promise<ClaudeSynthesisResponse> {
    const prompt = this.buildSynthesisPrompt(sources, userContext);

    const message = await this.client.messages.create({
      model: 'claude-sonnet-4.5-20250110',
      max_tokens: 2048,
      messages: [{
        role: 'user',
        content: prompt
      }]
    });

    const usage = message.usage;
    const inputCost = (usage.input_tokens / 1_000_000) * 3.0;
    const outputCost = (usage.output_tokens / 1_000_000) * 15.0;

    return {
      final_metadata: JSON.parse(message.content[0].text),
      usage: {
        input_tokens: usage.input_tokens,
        output_tokens: usage.output_tokens,
        total_cost_usd: inputCost + outputCost
      },
      model: 'claude-sonnet-4.5',
      timestamp: new Date().toISOString()
    };
  }

  async submitBatch(items: MetadataSource[][]): Promise<string> {
    // Batch API implementation
    // POST to https://api.anthropic.com/v1/messages/batches
    // Returns batch_id
    throw new Error('Batch API not yet implemented');
  }

  async pollBatchStatus(jobId: string): Promise<BatchJobStatus> {
    // GET https://api.anthropic.com/v1/messages/batches/:batch_id
    throw new Error('Batch API not yet implemented');
  }

  private buildSynthesisPrompt(
    sources: MetadataSource[],
    userContext?: UserContext
  ): string {
    // Implementation detail
    return `Synthesize metadata from these sources:\n${JSON.stringify(sources, null, 2)}`;
  }
}
```

## Layer 2b: GoogleLensProvider (Visual Search)

```typescript
/**
 * SerpAPI Google Lens provider for visual search
 * Layer 2b: Photo → Product identification via visual search
 */
export interface IGoogleLensProvider extends AIProvider {
  /**
   * Perform visual search using Google Lens
   * @param imageUrl - Cloud Storage public URL
   * @returns Visual search results with product matches
   * @throws {RateLimitError} If quota exceeded (429)
   * @throws {InvalidImageError} If image unreadable (400)
   */
  visualSearch(imageUrl: string): Promise<GoogleLensResponse>;
}

/**
 * Google Lens (via SerpAPI) response structure
 */
export interface GoogleLensResponse {
  visual_matches: Array<{
    title: string;
    link: string;
    source: string;
    price?: string;
    thumbnail: string;
  }>;
  text_results?: Array<{
    text: string;
    confidence: number;
  }>;
  usage: {
    api_calls: number; // 1 call per request
    total_cost_usd: number; // $50/5000 searches = $0.01 per search
  };
  timestamp: string;
}

/**
 * Implementation example (for reference)
 */
export class GoogleLensProvider implements IGoogleLensProvider {
  private apiKey: string;
  private baseUrl = 'https://serpapi.com/search';

  constructor(apiKey: string) {
    this.apiKey = apiKey;
  }

  async initialize(): Promise<void> {
    // No initialization needed
  }

  getProviderName(): string {
    return 'SerpAPI Google Lens';
  }

  estimateCost(inputSize: number): number {
    // $50 per 5000 searches = $0.01 per search
    return 0.01;
  }

  async visualSearch(imageUrl: string): Promise<GoogleLensResponse> {
    const fetch = (await import('node-fetch')).default;

    const response = await fetch(`${this.baseUrl}?engine=google_lens&url=${encodeURIComponent(imageUrl)}&api_key=${this.apiKey}`);
    const data = await response.json();

    return {
      visual_matches: data.visual_matches || [],
      text_results: data.text_results || [],
      usage: {
        api_calls: 1,
        total_cost_usd: 0.01
      },
      timestamp: new Date().toISOString()
    };
  }
}
```

## Layer 2b: BarcodeProviders (Product Lookup)

```typescript
/**
 * Base interface for barcode lookup providers
 */
export interface IBarcodeProvider extends AIProvider {
  /**
   * Lookup product by barcode/UPC
   * @param barcode - UPC/EAN barcode string
   * @returns Product information
   * @throws {NotFoundError} If barcode not in database (404)
   */
  lookupBarcode(barcode: string): Promise<BarcodeResponse>;
}

/**
 * Barcode lookup response structure
 */
export interface BarcodeResponse {
  product_name: string;
  brand?: string;
  category?: string;
  ingredients?: string[];
  nutrition?: {
    [key: string]: string; // "calories": "150", etc.
  };
  allergens?: string[];
  image_url?: string;
  usage: {
    api_calls: number;
    total_cost_usd: number;
  };
  provider: string; // "openfoodfacts" or "upcitemdb"
  timestamp: string;
}

/**
 * Open Food Facts provider (free, no API key)
 */
export class OpenFoodFactsProvider implements IBarcodeProvider {
  private baseUrl = 'https://world.openfoodfacts.org/api/v0/product';

  async initialize(): Promise<void> {
    // No initialization needed
  }

  getProviderName(): string {
    return 'Open Food Facts';
  }

  estimateCost(inputSize: number): number {
    return 0; // Free
  }

  async lookupBarcode(barcode: string): Promise<BarcodeResponse> {
    const fetch = (await import('node-fetch')).default;
    const response = await fetch(`${this.baseUrl}/${barcode}.json`);
    const data = await response.json();

    if (data.status === 0) {
      throw new Error(`Barcode not found: ${barcode}`);
    }

    const product = data.product;
    return {
      product_name: product.product_name || 'Unknown',
      brand: product.brands,
      category: product.categories,
      ingredients: product.ingredients_text?.split(',').map(s => s.trim()),
      nutrition: product.nutriments,
      allergens: product.allergens_tags,
      image_url: product.image_url,
      usage: {
        api_calls: 1,
        total_cost_usd: 0
      },
      provider: 'openfoodfacts',
      timestamp: new Date().toISOString()
    };
  }
}

/**
 * UPCitemdb provider (paid, $0.002 per call after 100 free/day)
 */
export class UPCitemdbProvider implements IBarcodeProvider {
  private apiKey: string;
  private baseUrl = 'https://api.upcitemdb.com/prod/trial/lookup';

  constructor(apiKey: string) {
    this.apiKey = apiKey;
  }

  async initialize(): Promise<void> {
    // No initialization needed
  }

  getProviderName(): string {
    return 'UPCitemdb';
  }

  estimateCost(inputSize: number): number {
    // Free for first 100/day, then $0.002 per call
    // Assume we're past free tier for cost estimation
    return 0.002;
  }

  async lookupBarcode(barcode: string): Promise<BarcodeResponse> {
    const fetch = (await import('node-fetch')).default;
    const response = await fetch(`${this.baseUrl}?upc=${barcode}`, {
      headers: {
        'Authorization': `Bearer ${this.apiKey}`
      }
    });
    const data = await response.json();

    if (!data.items || data.items.length === 0) {
      throw new Error(`Barcode not found: ${barcode}`);
    }

    const item = data.items[0];
    return {
      product_name: item.title,
      brand: item.brand,
      category: item.category,
      image_url: item.images?.[0],
      usage: {
        api_calls: 1,
        total_cost_usd: 0.002
      },
      provider: 'upcitemdb',
      timestamp: new Date().toISOString()
    };
  }
}
```

## Error Types

```typescript
/**
 * Provider initialization error
 */
export class ProviderInitializationError extends Error {
  constructor(provider: string, reason: string) {
    super(`Failed to initialize ${provider}: ${reason}`);
    this.name = 'ProviderInitializationError';
  }
}

/**
 * Rate limit exceeded error (429)
 */
export class RateLimitError extends Error {
  retryAfter: number; // Seconds

  constructor(provider: string, retryAfter: number) {
    super(`Rate limit exceeded for ${provider}. Retry after ${retryAfter}s`);
    this.name = 'RateLimitError';
    this.retryAfter = retryAfter;
  }
}

/**
 * Invalid image error (400)
 */
export class InvalidImageError extends Error {
  constructor(imageUrl: string, reason: string) {
    super(`Invalid image ${imageUrl}: ${reason}`);
    this.name = 'InvalidImageError';
  }
}

/**
 * Not found error (404)
 */
export class NotFoundError extends Error {
  constructor(resource: string) {
    super(`Resource not found: ${resource}`);
    this.name = 'NotFoundError';
  }
}
```

## Acceptance Criteria

- ✅ All provider interfaces defined with TypeScript types
- ✅ Method signatures documented with JSDoc comments
- ✅ Request/response types specified for each provider
- ✅ Error handling patterns defined with custom error classes
- ✅ Implementation examples provided (not just interfaces)
- ✅ All code uses current @google/genai SDK (not deprecated @google-cloud/vertexai)
- ✅ Cost estimation methods included for all providers

---

**Last Updated**: 2025-11-11
