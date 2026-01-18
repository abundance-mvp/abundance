# AI Error Handling Patterns

**Created**: 2025-11-11
**Stage**: 4.3 - AI Pipeline Integration Scaffolding
**References**:
- docs/validation/RESEARCH-VALIDATION-stage-4.3.md
- docs/plans/PLAN-SUMMARY-stage-3.4.md (Stage 3.4 error handling examples)
**Status**: Draft

## Overview

This document defines error handling patterns for all AI providers in the computer vision pipeline. Robust error handling is critical for production reliability, especially when dealing with external APIs that may experience transient failures, rate limits, or downtime.

## Error Taxonomy

### Permanent Errors (Do NOT Retry)

These errors indicate a problem with the request that won't be fixed by retrying:

| Error Type | HTTP Status | Examples | Recovery Action |
|------------|-------------|----------|-----------------|
| Authentication | 401 | Invalid API key | Alert admin, check credentials |
| Authorization | 403 | Quota exhausted (permanent) | Alert admin, upgrade plan |
| Bad Request | 400 | Malformed JSON, invalid image | Log error, move to dead letter queue |
| Not Found | 404 | Barcode not in database | Mark as "not found", skip provider |
| Invalid Image | 400 | Corrupt image, unsupported format | Alert user, request new photo |

### Transient Errors (Retry with Backoff)

These errors may resolve on retry:

| Error Type | HTTP Status | Examples | Recovery Action |
|------------|-------------|----------|-----------------|
| Rate Limit | 429 | Too many requests | Exponential backoff, respect Retry-After header |
| Server Error | 500-503 | Internal server error, service unavailable | Exponential backoff, max 3 retries |
| Timeout | 408 | Request timeout | Retry with longer timeout |
| Network Error | - | ECONNREFUSED, ETIMEDOUT | Retry with exponential backoff |

## Error Classes

### File: `functions/src/ai-pipeline/models/error-types.ts`

```typescript
/**
 * Base class for all AI provider errors
 */
export abstract class AIProviderError extends Error {
  public readonly provider: string;
  public readonly isRetryable: boolean;
  public readonly timestamp: Date;

  constructor(message: string, provider: string, isRetryable: boolean = false) {
    super(message);
    this.name = this.constructor.name;
    this.provider = provider;
    this.isRetryable = isRetryable;
    this.timestamp = new Date();
    Error.captureStackTrace(this, this.constructor);
  }
}

/**
 * Authentication error (401) - NOT retryable
 */
export class AuthenticationError extends AIProviderError {
  constructor(provider: string, message: string = 'Invalid API key') {
    super(message, provider, false);
  }
}

/**
 * Authorization error (403) - NOT retryable
 */
export class AuthorizationError extends AIProviderError {
  constructor(provider: string, message: string = 'Insufficient permissions') {
    super(message, provider, false);
  }
}

/**
 * Rate limit error (429) - Retryable
 */
export class RateLimitError extends AIProviderError {
  public readonly retryAfter: number; // Seconds

  constructor(provider: string, retryAfter: number = 60) {
    super(`Rate limit exceeded. Retry after ${retryAfter}s`, provider, true);
    this.retryAfter = retryAfter;
  }
}

/**
 * Server error (500-503) - Retryable
 */
export class ServerError extends AIProviderError {
  public readonly statusCode: number;

  constructor(provider: string, statusCode: number, message: string) {
    super(message, provider, true);
    this.statusCode = statusCode;
  }
}

/**
 * Bad request error (400) - NOT retryable
 */
export class BadRequestError extends AIProviderError {
  public readonly details?: any;

  constructor(provider: string, message: string, details?: any) {
    super(message, provider, false);
    this.details = details;
  }
}

/**
 * Invalid image error (400) - NOT retryable
 */
export class InvalidImageError extends AIProviderError {
  public readonly imageUrl: string;

  constructor(provider: string, imageUrl: string, reason: string) {
    super(`Invalid image ${imageUrl}: ${reason}`, provider, false);
    this.imageUrl = imageUrl;
  }
}

/**
 * Not found error (404) - NOT retryable
 */
export class NotFoundError extends AIProviderError {
  public readonly resource: string;

  constructor(provider: string, resource: string) {
    super(`Resource not found: ${resource}`, provider, false);
    this.resource = resource;
  }
}

/**
 * Timeout error - Retryable
 */
export class TimeoutError extends AIProviderError {
  public readonly timeoutMs: number;

  constructor(provider: string, timeoutMs: number) {
    super(`Request timed out after ${timeoutMs}ms`, provider, true);
    this.timeoutMs = timeoutMs;
  }
}

/**
 * Network error - Retryable
 */
export class NetworkError extends AIProviderError {
  public readonly code: string;

  constructor(provider: string, code: string, message: string) {
    super(message, provider, true);
    this.code = code;
  }
}

/**
 * Malformed response error - NOT retryable
 */
export class MalformedResponseError extends AIProviderError {
  public readonly responseText: string;

  constructor(provider: string, responseText: string, parseError: string) {
    super(`Malformed response: ${parseError}`, provider, false);
    this.responseText = responseText;
  }
}
```

## Error Handler Utility

### File: `functions/src/ai-pipeline/utils/error-handlers.ts`

```typescript
import {
  AIProviderError,
  AuthenticationError,
  AuthorizationError,
  RateLimitError,
  ServerError,
  BadRequestError,
  NotFoundError,
  TimeoutError,
  NetworkError
} from '../models/error-types';

/**
 * Classify error and convert to appropriate AIProviderError
 */
export function classifyError(error: any, provider: string): AIProviderError {
  // Already an AIProviderError
  if (error instanceof AIProviderError) {
    return error;
  }

  // HTTP errors
  if (error.status || error.statusCode) {
    const status = error.status || error.statusCode;

    switch (status) {
      case 401:
        return new AuthenticationError(provider, error.message);
      case 403:
        return new AuthorizationError(provider, error.message);
      case 429:
        const retryAfter = parseInt(error.headers?.['retry-after'] || '60', 10);
        return new RateLimitError(provider, retryAfter);
      case 400:
        return new BadRequestError(provider, error.message, error.details);
      case 404:
        return new NotFoundError(provider, error.message);
      case 408:
        return new TimeoutError(provider, 30000);
      case 500:
      case 502:
      case 503:
      case 504:
        return new ServerError(provider, status, error.message);
      default:
        return new BadRequestError(provider, `HTTP ${status}: ${error.message}`);
    }
  }

  // Network errors
  if (error.code) {
    switch (error.code) {
      case 'ECONNREFUSED':
      case 'ENOTFOUND':
      case 'ETIMEDOUT':
      case 'ECONNRESET':
        return new NetworkError(provider, error.code, error.message);
      default:
        return new BadRequestError(provider, error.message);
    }
  }

  // JSON parse errors
  if (error instanceof SyntaxError && error.message.includes('JSON')) {
    return new MalformedResponseError(provider, error.message, 'Invalid JSON');
  }

  // Unknown error
  return new BadRequestError(provider, error.message || 'Unknown error');
}

/**
 * Determine if error is retryable
 */
export function isRetryableError(error: AIProviderError): boolean {
  return error.isRetryable;
}

/**
 * Log error to Firestore (dead letter queue)
 */
export async function logErrorToDeadLetterQueue(
  firestore: admin.firestore.Firestore,
  itemId: string,
  userId: string,
  layer: string,
  error: AIProviderError
): Promise<void> {
  await firestore.collection('failedItems').add({
    item_id: itemId,
    user_id: userId,
    layer,
    provider: error.provider,
    error_name: error.name,
    error_message: error.message,
    is_retryable: error.isRetryable,
    timestamp: admin.firestore.Timestamp.now(),
    stack_trace: error.stack
  });
}

/**
 * Exponential backoff calculator
 */
export function calculateBackoffDelay(
  attempt: number,
  baseDelay: number = 1000,
  maxDelay: number = 60000
): number {
  // 2^attempt * baseDelay, capped at maxDelay
  const delay = Math.pow(2, attempt) * baseDelay;
  return Math.min(delay, maxDelay);
}

/**
 * Sleep utility for backoff
 */
export function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}
```

## Retry Logic Pattern

### File: `functions/src/ai-pipeline/utils/retry-logic.ts`

```typescript
import {
  AIProviderError,
  classifyError,
  isRetryableError,
  calculateBackoffDelay,
  sleep
} from './error-handlers';

/**
 * Retry options
 */
export interface RetryOptions {
  maxRetries: number;      // Default: 3
  baseDelay: number;       // Default: 1000ms
  maxDelay: number;        // Default: 60000ms (60s)
  onRetry?: (attempt: number, error: AIProviderError) => void;
}

/**
 * Retry a function with exponential backoff
 */
export async function retryWithBackoff<T>(
  fn: () => Promise<T>,
  provider: string,
  options: Partial<RetryOptions> = {}
): Promise<T> {
  const {
    maxRetries = 3,
    baseDelay = 1000,
    maxDelay = 60000,
    onRetry
  } = options;

  let lastError: AIProviderError;

  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = classifyError(error, provider);

      // Don't retry non-retryable errors
      if (!isRetryableError(lastError)) {
        throw lastError;
      }

      // Don't sleep after last attempt
      if (attempt < maxRetries - 1) {
        const delay = calculateBackoffDelay(attempt, baseDelay, maxDelay);

        // Call onRetry callback if provided
        if (onRetry) {
          onRetry(attempt + 1, lastError);
        }

        console.log(
          `[${provider}] Attempt ${attempt + 1}/${maxRetries} failed. ` +
          `Retrying in ${delay}ms... Error: ${lastError.message}`
        );

        await sleep(delay);
      }
    }
  }

  throw new Error(
    `[${provider}] Max retries (${maxRetries}) exceeded. ` +
    `Last error: ${lastError.message}`
  );
}

/**
 * Retry with rate limit handling
 * Respects Retry-After header from 429 responses
 */
export async function retryWithRateLimitHandling<T>(
  fn: () => Promise<T>,
  provider: string,
  options: Partial<RetryOptions> = {}
): Promise<T> {
  const { maxRetries = 3, onRetry } = options;

  let lastError: AIProviderError;

  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = classifyError(error, provider);

      // Don't retry non-retryable errors
      if (!isRetryableError(lastError)) {
        throw lastError;
      }

      // Don't sleep after last attempt
      if (attempt < maxRetries - 1) {
        let delay: number;

        // Use Retry-After header for rate limit errors
        if (lastError instanceof RateLimitError) {
          delay = lastError.retryAfter * 1000; // Convert to milliseconds
        } else {
          delay = calculateBackoffDelay(attempt);
        }

        if (onRetry) {
          onRetry(attempt + 1, lastError);
        }

        console.log(
          `[${provider}] Rate limit hit. Waiting ${delay}ms before retry...`
        );

        await sleep(delay);
      }
    }
  }

  throw new Error(
    `[${provider}] Max retries (${maxRetries}) exceeded. ` +
    `Last error: ${lastError.message}`
  );
}
```

## Usage Examples

### Example 1: Gemini Provider with Retry

```typescript
import { retryWithBackoff } from '../utils/retry-logic';
import { logErrorToDeadLetterQueue } from '../utils/error-handlers';

export class GeminiProvider {
  async extractAttributes(imageUrl: string, prompt: string) {
    try {
      // Wrap API call with retry logic
      return await retryWithBackoff(
        async () => {
          const result = await this.model.generateContent([prompt, imageUrl]);
          return this.parseResponse(result);
        },
        'gemini',
        {
          maxRetries: 3,
          baseDelay: 1000,
          onRetry: (attempt, error) => {
            console.log(`Gemini retry attempt ${attempt}: ${error.message}`);
          }
        }
      );
    } catch (error) {
      // Log to dead letter queue if all retries failed
      if (error instanceof AIProviderError) {
        await logErrorToDeadLetterQueue(
          this.firestore,
          this.itemId,
          this.userId,
          '2a',
          error
        );
      }
      throw error;
    }
  }
}
```

### Example 2: Claude Provider with Rate Limit Handling

```typescript
import { retryWithRateLimitHandling } from '../utils/retry-logic';

export class ClaudeHaikuProvider {
  async parseText(text: string, schema: object) {
    return await retryWithRateLimitHandling(
      async () => {
        const message = await this.client.messages.create({
          model: 'claude-haiku-4.5-20250110',
          max_tokens: 1024,
          messages: [{ role: 'user', content: text }]
        });
        return this.parseResponse(message);
      },
      'claude-haiku',
      {
        maxRetries: 5, // More retries for rate limits
        onRetry: (attempt, error) => {
          console.log(`Claude retry ${attempt}: ${error.message}`);
        }
      }
    );
  }
}
```

### Example 3: SerpAPI with Fallback

```typescript
import { NotFoundError } from '../models/error-types';

export class GoogleLensProvider {
  async visualSearch(imageUrl: string) {
    try {
      return await retryWithBackoff(
        async () => {
          const response = await this.fetchSerpAPI(imageUrl);
          if (!response.visual_matches || response.visual_matches.length === 0) {
            throw new NotFoundError('serpapi', 'No visual matches found');
          }
          return response;
        },
        'serpapi',
        { maxRetries: 2 }
      );
    } catch (error) {
      if (error instanceof NotFoundError) {
        // Not found is okay, return empty results
        return { visual_matches: [], text_results: [] };
      }
      throw error;
    }
  }
}
```

## Dead Letter Queue Schema

### Firestore Collection: `/failedItems/{failedItemId}`

```typescript
interface FailedItem {
  item_id: string;           // Original item ID
  user_id: string;           // User who owns the item
  layer: string;             // "2a", "2b", "3"
  provider: string;          // "gemini", "claude-haiku", etc.
  error_name: string;        // Error class name
  error_message: string;     // Human-readable error message
  is_retryable: boolean;     // Whether error was retryable
  timestamp: Timestamp;      // When error occurred
  stack_trace?: string;      // Full stack trace for debugging
  retry_count: number;       // Number of retries attempted
  last_retry_at?: Timestamp; // When last retry occurred
}
```

## Monitoring & Alerts

### Query Failed Items

```typescript
// Get all failed items in last 24 hours
const oneDayAgo = admin.firestore.Timestamp.fromDate(
  new Date(Date.now() - 24 * 60 * 60 * 1000)
);

const failedItems = await firestore
  .collection('failedItems')
  .where('timestamp', '>=', oneDayAgo)
  .get();

console.log(`Failed items (24h): ${failedItems.size}`);
```

### Alert on High Error Rate

```typescript
// Alert if error rate > 5% in last hour
const oneHourAgo = admin.firestore.Timestamp.fromDate(
  new Date(Date.now() - 60 * 60 * 1000)
);

const [totalItems, failedItems] = await Promise.all([
  firestore.collection('items').where('created_at', '>=', oneHourAgo).get(),
  firestore.collection('failedItems').where('timestamp', '>=', oneHourAgo).get()
]);

const errorRate = failedItems.size / totalItems.size;

if (errorRate > 0.05) {
  console.error(`HIGH ERROR RATE: ${(errorRate * 100).toFixed(2)}%`);
  // Send alert via email/Slack
}
```

## Acceptance Criteria

- ✅ Error taxonomy documented (permanent vs. transient)
- ✅ Custom error classes defined with TypeScript
- ✅ Error classification utility implemented
- ✅ Exponential backoff pattern implemented
- ✅ Rate limit handling with Retry-After header
- ✅ Dead letter queue schema defined
- ✅ Usage examples for all providers
- ✅ Monitoring queries provided

---

**Last Updated**: 2025-11-11
