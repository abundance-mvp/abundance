export interface BarcodeProduct {
  found: boolean;
  source: string;
  name: string;
  brand: string;
  category?: string;
  imageUrl?: string;
  barcode: string;
  latency: number;
}

export class RateLimitError extends Error {
  constructor(message: string, public status: number, public retryAfter?: number) {
    super(message);
    this.name = 'RateLimitError';
  }
  retryable = true;
}

export class OpenFoodFactsProvider {
  private readonly apiBaseUrl = 'https://world.openfoodfacts.org/api/v0';
  private readonly timeout = 2000; // 2 second timeout

  async lookup(barcode: string): Promise<BarcodeProduct | null> {
    const apiUrl = `${this.apiBaseUrl}/product/${barcode}.json`;
    const startTime = Date.now();

    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), this.timeout);

      const response = await fetch(apiUrl, {
        method: 'GET',
        headers: {
          'User-Agent': 'Abundance-iOS/1.0 (contact@abundance.app)',
        },
        signal: controller.signal,
      });

      clearTimeout(timeoutId);
      const latency = Date.now() - startTime;

      // ✅ I6: Add rate limit detection
      if (response.status === 429) {
        const retryAfter = parseInt(response.headers.get('retry-after') || '60');
        console.warn(`[OpenFoodFacts] Rate limit exceeded, retry after ${retryAfter}s`);
        throw new RateLimitError(
          `OpenFoodFacts rate limit exceeded for barcode ${barcode}`,
          429,
          retryAfter
        );
      }

      if (!response.ok) {
        console.log(`[OpenFoodFacts] HTTP ${response.status} for barcode ${barcode}`);
        return null;
      }

      const data = await response.json();

      // Check if product found (status = 1 means found)
      if (data.status !== 1 || !data.product) {
        console.log(`[OpenFoodFacts] Barcode ${barcode} not found`);
        return null;
      }

      // Extract product data
      const product: BarcodeProduct = {
        found: true,
        source: 'openfoodfacts',
        name: data.product.product_name || data.product.generic_name || 'Unknown',
        brand: data.product.brands || 'Unknown',
        category: data.product.categories || 'food',
        imageUrl: data.product.image_url,
        barcode: barcode,
        latency: latency,
      };

      console.log(`[OpenFoodFacts] ✅ Match found for ${barcode}: ${product.name} (${latency}ms)`);

      return product;
    } catch (error: any) {
      if (error instanceof RateLimitError) {
        throw error;  // Re-throw rate limit errors for retry logic
      }

      if (error.name === 'AbortError') {
        console.warn(`[OpenFoodFacts] Timeout after ${this.timeout}ms for barcode ${barcode}`);
      } else {
        console.error(`[OpenFoodFacts] Error for ${barcode}:`, error.message);
      }
      return null; // Return null to trigger fallback
    }
  }
}
