# AI Retry Logic Templates

**Created**: 2025-11-11
**Stage**: 4.3 - AI Pipeline Integration Scaffolding
**References**:
- docs/validation/RESEARCH-VALIDATION-stage-4.3.md
- docs/tech-stack/ai-error-handling-patterns.md
- docs/plans/PLAN-SUMMARY-stage-3.4.md (exponential backoff examples)
**Status**: Draft

## Overview

This document provides reusable retry logic templates for all AI providers in the computer vision pipeline. These templates implement exponential backoff, rate limit handling, and circuit breaker patterns.

## Basic Exponential Backoff

### Template 1: Simple Retry with Backoff

```typescript
/**
 * Retry a function with exponential backoff
 * @param fn - Async function to retry
 * @param maxRetries - Maximum number of retry attempts (default: 3)
 * @param baseDelay - Base delay in milliseconds (default: 1000)
 * @returns Result of fn()
 */
async function retryWithBackoff<T>(
  fn: () => Promise<T>,
  maxRetries: number = 3,
  baseDelay: number = 1000
): Promise<T> {
  let lastError: Error;

  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error;

      // Calculate exponential backoff: 2^attempt * baseDelay
      // Attempt 0: 1s, Attempt 1: 2s, Attempt 2: 4s
      const delay = Math.pow(2, attempt) * baseDelay;

      // Cap at 60 seconds
      const cappedDelay = Math.min(delay, 60000);

      console.log(
        `Attempt ${attempt + 1}/${maxRetries} failed. ` +
        `Retrying in ${cappedDelay}ms...`
      );

      // Wait before next retry
      await new Promise(resolve => setTimeout(resolve, cappedDelay));
    }
  }

  throw new Error(`Max retries (${maxRetries}) exceeded: ${lastError.message}`);
}
```

**Usage:**

```typescript
const result = await retryWithBackoff(
  async () => {
    const response = await fetch('https://api.example.com/data');
    return response.json();
  },
  3,  // Max 3 retries
  1000 // Start with 1 second delay
);
```

## Rate Limit Handling

### Template 2: Retry with Rate Limit Detection

```typescript
/**
 * Retry with rate limit detection
 * Respects Retry-After header from 429 responses
 */
async function retryWithRateLimitHandling<T>(
  fn: () => Promise<T>,
  maxRetries: number = 5
): Promise<T> {
  let lastError: Error;

  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error;

      // Check if rate limit error (429)
      const isRateLimit =
        error.status === 429 ||
        error.statusCode === 429 ||
        error.message.includes('rate limit');

      if (!isRateLimit && attempt === 0) {
        // Not a rate limit error, don't retry
        throw error;
      }

      // Extract Retry-After header (in seconds)
      const retryAfter = error.headers?.['retry-after'] || 60;
      const delay = parseInt(retryAfter, 10) * 1000; // Convert to ms

      console.log(
        `Rate limit hit. Waiting ${delay / 1000}s before retry...`
      );

      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }

  throw new Error(`Max retries (${maxRetries}) exceeded: ${lastError.message}`);
}
```

**Usage:**

```typescript
const result = await retryWithRateLimitHandling(
  async () => {
    return await anthropicClient.messages.create({
      model: 'claude-haiku-4.5-20250110',
      max_tokens: 1024,
      messages: [{ role: 'user', content: 'Hello' }]
    });
  },
  5 // Allow up to 5 retries for rate limits
);
```

## Selective Retry

### Template 3: Retry Only Transient Errors

```typescript
/**
 * Error classification
 */
function isRetryableError(error: any): boolean {
  // Rate limit (429)
  if (error.status === 429 || error.statusCode === 429) {
    return true;
  }

  // Server errors (500-503)
  if (error.status >= 500 && error.status < 504) {
    return true;
  }

  // Network errors
  const retryableCodes = ['ECONNREFUSED', 'ETIMEDOUT', 'ENOTFOUND', 'ECONNRESET'];
  if (error.code && retryableCodes.includes(error.code)) {
    return true;
  }

  // Timeout errors
  if (error.message.includes('timeout')) {
    return true;
  }

  // Not retryable: 400, 401, 403, 404, etc.
  return false;
}

/**
 * Retry only transient errors
 */
async function retryTransientErrors<T>(
  fn: () => Promise<T>,
  maxRetries: number = 3,
  baseDelay: number = 1000
): Promise<T> {
  let lastError: Error;

  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error;

      // Don't retry permanent errors
      if (!isRetryableError(error)) {
        throw error;
      }

      const delay = Math.pow(2, attempt) * baseDelay;
      const cappedDelay = Math.min(delay, 60000);

      console.log(
        `Transient error: ${error.message}. ` +
        `Retrying in ${cappedDelay}ms...`
      );

      await new Promise(resolve => setTimeout(resolve, cappedDelay));
    }
  }

  throw lastError;
}
```

**Usage:**

```typescript
try {
  const result = await retryTransientErrors(
    async () => {
      return await geminiModel.generateContent(prompt);
    },
    3,
    1000
  );
} catch (error) {
  // This is a permanent error (400, 401, 404, etc.)
  console.error('Permanent error:', error);
  // Move to dead letter queue
}
```

## Circuit Breaker Pattern

### Template 4: Circuit Breaker for Provider Health

```typescript
/**
 * Circuit breaker states
 */
enum CircuitState {
  CLOSED = 'CLOSED',     // Normal operation
  OPEN = 'OPEN',         // Too many failures, reject immediately
  HALF_OPEN = 'HALF_OPEN' // Testing if service recovered
}

/**
 * Circuit breaker for API providers
 */
class CircuitBreaker {
  private state: CircuitState = CircuitState.CLOSED;
  private failureCount: number = 0;
  private successCount: number = 0;
  private lastFailureTime: number = 0;

  constructor(
    private failureThreshold: number = 5,      // Open after 5 failures
    private successThreshold: number = 2,      // Close after 2 successes
    private timeout: number = 60000            // Wait 60s before half-open
  ) {}

  async execute<T>(fn: () => Promise<T>): Promise<T> {
    // Reject immediately if circuit is OPEN
    if (this.state === CircuitState.OPEN) {
      const timeSinceFailure = Date.now() - this.lastFailureTime;

      // Try again after timeout
      if (timeSinceFailure >= this.timeout) {
        this.state = CircuitState.HALF_OPEN;
        this.successCount = 0;
        console.log('Circuit breaker: HALF_OPEN (testing recovery)');
      } else {
        throw new Error(
          `Circuit breaker is OPEN. Retry in ${
            (this.timeout - timeSinceFailure) / 1000
          }s`
        );
      }
    }

    try {
      const result = await fn();

      // Success
      this.onSuccess();
      return result;
    } catch (error) {
      // Failure
      this.onFailure();
      throw error;
    }
  }

  private onSuccess(): void {
    this.failureCount = 0;

    if (this.state === CircuitState.HALF_OPEN) {
      this.successCount++;

      // Close circuit after success threshold
      if (this.successCount >= this.successThreshold) {
        this.state = CircuitState.CLOSED;
        console.log('Circuit breaker: CLOSED (service recovered)');
      }
    }
  }

  private onFailure(): void {
    this.failureCount++;
    this.lastFailureTime = Date.now();

    // Open circuit after failure threshold
    if (this.failureCount >= this.failureThreshold) {
      this.state = CircuitState.OPEN;
      console.error(
        `Circuit breaker: OPEN (${this.failureCount} consecutive failures)`
      );
    }
  }

  getState(): CircuitState {
    return this.state;
  }
}
```

**Usage:**

```typescript
// Create circuit breaker for Gemini API
const geminiCircuitBreaker = new CircuitBreaker(
  5,      // Open after 5 failures
  2,      // Close after 2 successes
  60000   // Wait 60s before retry
);

// Use circuit breaker
try {
  const result = await geminiCircuitBreaker.execute(async () => {
    return await geminiModel.generateContent(prompt);
  });
} catch (error) {
  if (error.message.includes('Circuit breaker is OPEN')) {
    console.log('Gemini service is down, using fallback...');
    // Use fallback provider or queue for later
  } else {
    throw error;
  }
}
```

## Jitter for Load Distribution

### Template 5: Retry with Jitter

```typescript
/**
 * Add jitter to prevent thundering herd problem
 * When many clients retry at the same time, jitter spreads out the load
 */
function calculateDelayWithJitter(
  attempt: number,
  baseDelay: number = 1000,
  maxDelay: number = 60000,
  jitterFactor: number = 0.3 // 30% jitter
): number {
  // Base exponential backoff
  const exponentialDelay = Math.pow(2, attempt) * baseDelay;

  // Add random jitter: ±30% of delay
  const jitter = exponentialDelay * jitterFactor * (Math.random() - 0.5);
  const delayWithJitter = exponentialDelay + jitter;

  // Cap at max delay
  return Math.min(delayWithJitter, maxDelay);
}

/**
 * Retry with jitter
 */
async function retryWithJitter<T>(
  fn: () => Promise<T>,
  maxRetries: number = 3,
  baseDelay: number = 1000
): Promise<T> {
  let lastError: Error;

  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error;

      const delay = calculateDelayWithJitter(attempt, baseDelay);

      console.log(
        `Attempt ${attempt + 1}/${maxRetries} failed. ` +
        `Retrying in ${delay.toFixed(0)}ms (with jitter)...`
      );

      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }

  throw lastError;
}
```

**Usage:**

```typescript
// Retry with jitter to avoid thundering herd
const result = await retryWithJitter(
  async () => {
    return await serpApiClient.visualSearch(imageUrl);
  },
  3,
  1000
);
```

## Generic Retry Wrapper

### Template 6: Configurable Retry Wrapper

```typescript
/**
 * Retry configuration options
 */
interface RetryConfig {
  maxRetries: number;           // Default: 3
  baseDelay: number;            // Default: 1000ms
  maxDelay: number;             // Default: 60000ms
  jitter: boolean;              // Default: true
  jitterFactor: number;         // Default: 0.3 (30%)
  retryableErrors?: (error: any) => boolean; // Custom retryable check
  onRetry?: (attempt: number, error: Error) => void; // Callback on retry
}

/**
 * Generic retry wrapper with full configuration
 */
async function retry<T>(
  fn: () => Promise<T>,
  config: Partial<RetryConfig> = {}
): Promise<T> {
  const {
    maxRetries = 3,
    baseDelay = 1000,
    maxDelay = 60000,
    jitter = true,
    jitterFactor = 0.3,
    retryableErrors = () => true,
    onRetry
  } = config;

  let lastError: Error;

  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error;

      // Check if error is retryable
      if (!retryableErrors(error)) {
        throw error;
      }

      // Don't delay after last attempt
      if (attempt < maxRetries - 1) {
        // Calculate delay
        let delay = Math.pow(2, attempt) * baseDelay;

        // Add jitter if enabled
        if (jitter) {
          const jitterAmount = delay * jitterFactor * (Math.random() - 0.5);
          delay += jitterAmount;
        }

        // Cap at max delay
        delay = Math.min(delay, maxDelay);

        // Call onRetry callback
        if (onRetry) {
          onRetry(attempt + 1, error);
        }

        await new Promise(resolve => setTimeout(resolve, delay));
      }
    }
  }

  throw lastError;
}
```

**Usage:**

```typescript
// Full configuration example
const result = await retry(
  async () => {
    return await anthropicClient.messages.create({
      model: 'claude-sonnet-4.5-20250110',
      max_tokens: 2048,
      messages: [{ role: 'user', content: prompt }]
    });
  },
  {
    maxRetries: 5,
    baseDelay: 2000,
    maxDelay: 120000,
    jitter: true,
    retryableErrors: (error) => {
      // Only retry rate limits and server errors
      return error.status === 429 || error.status >= 500;
    },
    onRetry: (attempt, error) => {
      console.log(`Claude retry ${attempt}: ${error.message}`);
      // Log to monitoring system
    }
  }
);
```

## Batch Retry

### Template 7: Retry Failed Items in Batch

```typescript
/**
 * Retry multiple failed items in parallel
 */
async function retryBatch<T, R>(
  items: T[],
  fn: (item: T) => Promise<R>,
  maxRetries: number = 3
): Promise<Array<{ item: T; result?: R; error?: Error }>> {
  const results = await Promise.all(
    items.map(async (item) => {
      try {
        const result = await retryWithBackoff(
          () => fn(item),
          maxRetries,
          1000
        );
        return { item, result };
      } catch (error) {
        return { item, error };
      }
    })
  );

  return results;
}
```

**Usage:**

```typescript
// Retry all failed items from dead letter queue
const failedItems = await firestore
  .collection('failedItems')
  .where('is_retryable', '==', true)
  .limit(100)
  .get();

const results = await retryBatch(
  failedItems.docs.map(doc => doc.data()),
  async (failedItem) => {
    // Retry processing
    return await processItem(failedItem.item_id);
  },
  3
);

// Log results
const succeeded = results.filter(r => r.result).length;
const failed = results.filter(r => r.error).length;
console.log(`Batch retry: ${succeeded} succeeded, ${failed} failed`);
```

## Acceptance Criteria

- ✅ Basic exponential backoff template provided
- ✅ Rate limit handling template with Retry-After
- ✅ Selective retry template (transient errors only)
- ✅ Circuit breaker pattern for provider health
- ✅ Jitter template for load distribution
- ✅ Generic configurable retry wrapper
- ✅ Batch retry template for failed items
- ✅ All templates include usage examples

---

**Last Updated**: 2025-11-11
