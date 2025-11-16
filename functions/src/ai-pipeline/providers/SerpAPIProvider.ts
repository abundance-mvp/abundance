export class SerpAPIError extends Error {
  constructor(message: string, public status?: number) {
    super(message);
    this.name = 'SerpAPIError';
  }
}

export class InvalidAPIKeyError extends SerpAPIError {
  constructor(message: string, status: number) {
    super(message, status);
    this.name = 'InvalidAPIKeyError';
  }
  retryable = false;
}

export class RateLimitError extends SerpAPIError {
  constructor(message: string, status: number) {
    super(message, status);
    this.name = 'RateLimitError';
  }
  retryable = true;
}

export interface VisualMatch {
  position: number;
  title: string;
  link: string;
  source: string;
  price?: {
    value: string;
    extracted_value: number;
    currency: string;
  };
  thumbnail?: string;
}

export interface SerpAPIResponse {
  visual_matches: VisualMatch[];
  search_metadata?: any;
  search_information?: any;
  latency: number;
}

export class SerpAPIProvider {
  private readonly apiBaseUrl = 'https://serpapi.com/search';
  private readonly timeout = 10000; // 10 second timeout

  // ✅ Simple in-memory cache (valid for function lifetime)
  private cache: Map<string, { result: SerpAPIResponse; timestamp: number }> = new Map();
  private readonly cacheTTL = 3600000; // 1 hour

  private getCachedResult(imageUrl: string): SerpAPIResponse | null {
    const cached = this.cache.get(imageUrl);
    if (!cached) return null;

    const age = Date.now() - cached.timestamp;
    if (age > this.cacheTTL) {
      this.cache.delete(imageUrl);
      return null;
    }

    console.log(`[SerpAPI] ✅ Cache hit for ${imageUrl} (age: ${Math.round(age / 1000)}s)`);
    return cached.result;
  }

  private cacheResult(imageUrl: string, result: SerpAPIResponse): void {
    this.cache.set(imageUrl, {
      result,
      timestamp: Date.now(),
    });
  }

  async search(imageUrl: string, itemId: string): Promise<SerpAPIResponse> {
    // Check cache first
    const cachedResult = this.getCachedResult(imageUrl);
    if (cachedResult) {
      return cachedResult;
    }
    const apiKey = process.env.SERPAPI_API_KEY;

    if (!apiKey) {
      throw new Error('SERPAPI_API_KEY environment variable not set');
    }

    // Validate image URL (must be public HTTPS)
    if (!imageUrl.startsWith('https://')) {
      throw new Error(`Invalid image URL: must be HTTPS (got: ${imageUrl})`);
    }

    // Build API URL
    const apiUrl = new URL(this.apiBaseUrl);
    apiUrl.searchParams.set('engine', 'google_lens');
    apiUrl.searchParams.set('url', imageUrl);
    apiUrl.searchParams.set('api_key', apiKey);

    console.log(`[SerpAPI] Starting Google Lens search for item ${itemId}`);
    console.log(`[SerpAPI] Image URL: ${imageUrl}`);

    const startTime = Date.now();

    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), this.timeout);

      const response = await fetch(apiUrl.toString(), {
        method: 'GET',
        headers: {
          'Accept': 'application/json',
        },
        signal: controller.signal,
      });

      clearTimeout(timeoutId);
      const latency = Date.now() - startTime;

      // Handle HTTP errors
      if (!response.ok) {
        if (response.status === 403) {
          throw new InvalidAPIKeyError('SerpAPI API key invalid or expired', response.status);
        }
        if (response.status === 400) {
          throw new SerpAPIError('SerpAPI bad request (check image URL)', response.status);
        }
        if (response.status === 429) {
          throw new RateLimitError('SerpAPI rate limit exceeded (1,000/hour max)', response.status);
        }
        throw new Error(`SerpAPI API error: HTTP ${response.status}`);
      }

      const data = await response.json();

      // Validate response structure
      if (!data.visual_matches || !Array.isArray(data.visual_matches)) {
        console.warn(`[SerpAPI] No visual_matches array in response for item ${itemId}`);
        const emptyResult = {
          visual_matches: [],
          search_metadata: data.search_metadata,
          latency,
        };
        // Cache empty results too (avoid retrying failed searches)
        this.cacheResult(imageUrl, emptyResult);
        return emptyResult;
      }

      console.log(`[SerpAPI] ✅ Found ${data.visual_matches.length} visual matches for item ${itemId} (${latency}ms)`);

      const searchResult = {
        visual_matches: data.visual_matches,
        search_metadata: data.search_metadata,
        search_information: data.search_information,
        latency,
      };

      // Cache result before returning
      this.cacheResult(imageUrl, searchResult);
      return searchResult;
    } catch (error) {
      if (error instanceof Error && error.name === 'AbortError') {
        throw new SerpAPIError('SerpAPI request timed out after 10 seconds');
      }

      const message = error instanceof Error ? error.message : 'Unknown error';
      console.error(`[SerpAPI] Error for item ${itemId}:`, message);
      throw error;
    }
  }

  async searchWithRetry(imageUrl: string, itemId: string, maxRetries = 3): Promise<SerpAPIResponse> {
    let lastError: unknown;
    let delay = 1000; // Start with 1 second

    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await this.search(imageUrl, itemId);
      } catch (error) {
        lastError = error;

        // Don't retry on non-retryable errors
        if (error instanceof InvalidAPIKeyError) {
          console.error(`[SerpAPI] Non-retryable error, aborting: ${error.message}`);
          throw error;
        }

        // Retry on rate limits, timeouts, network errors
        if (attempt < maxRetries) {
          console.warn(`[SerpAPI] Retry attempt ${attempt}/${maxRetries} for item ${itemId} after ${delay}ms`);
          await new Promise(resolve => setTimeout(resolve, delay));
          delay *= 2; // Exponential backoff
        }
      }
    }

    console.error(`[SerpAPI] All ${maxRetries} retry attempts failed for item ${itemId}`);
    throw lastError;
  }
}
