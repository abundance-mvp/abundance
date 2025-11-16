import { BarcodeProduct } from './OpenFoodFactsProvider';

export class RateLimitError extends Error {
  constructor(message: string, public status: number) {
    super(message);
    this.name = 'RateLimitError';
  }
  retryable = true;
}

export class QuotaExceededError extends Error {
  constructor(message: string, public status: number) {
    super(message);
    this.name = 'QuotaExceededError';
  }
  retryable = false;
}

export class UPCitemdbProvider {
  private readonly apiBaseUrl = 'https://api.upcitemdb.com/prod/trial/lookup';
  private readonly timeout = 2000; // 2 second timeout

  async lookup(barcode: string): Promise<BarcodeProduct | null> {
    const apiKey = process.env.UPCITEMDB_API_KEY;

    if (!apiKey) {
      throw new Error('UPCITEMDB_API_KEY environment variable not set');
    }

    const apiUrl = `${this.apiBaseUrl}?upc=${barcode}`;
    const startTime = Date.now();

    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), this.timeout);

      const response = await fetch(apiUrl, {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${apiKey}`,
          'Accept': 'application/json',
        },
        signal: controller.signal,
      });

      clearTimeout(timeoutId);
      const latency = Date.now() - startTime;

      if (!response.ok) {
        if (response.status === 404) {
          console.log(`[UPCitemdb] Barcode ${barcode} not found (404)`);
          return null;
        }
        if (response.status === 429) {
          throw new RateLimitError('UPCitemdb rate limit exceeded', response.status);
        }
        if (response.status === 403) {
          throw new QuotaExceededError('UPCitemdb quota exceeded', response.status);
        }
        throw new Error(`UPCitemdb API error: ${response.status}`);
      }

      const data = await response.json();

      // Check if product found
      if (data.code !== 'OK' || data.total === 0 || !data.items || data.items.length === 0) {
        console.log(`[UPCitemdb] Barcode ${barcode} not found (empty result)`);
        return null;
      }

      // Extract product data from first match
      const item = data.items[0];

      const product: BarcodeProduct = {
        found: true,
        source: 'upcitemdb',
        name: item.title || 'Unknown',
        brand: item.brand || 'Unknown',
        category: item.category || 'unknown',
        imageUrl: item.images && item.images.length > 0 ? item.images[0] : undefined,
        barcode: barcode,
        latency: latency,
      };

      console.log(`[UPCitemdb] ✅ Match found for ${barcode}: ${product.name} (${latency}ms)`);

      return product;
    } catch (error: any) {
      if (error.name === 'AbortError') {
        console.warn(`[UPCitemdb] Timeout after ${this.timeout}ms for barcode ${barcode}`);
        return null;
      }

      console.error(`[UPCitemdb] Error for ${barcode}:`, error.message);

      // Re-throw specific errors for retry logic
      if (error instanceof RateLimitError || error instanceof QuotaExceededError) {
        throw error;
      }

      return null; // Return null for other errors (triggers fallback)
    }
  }
}
