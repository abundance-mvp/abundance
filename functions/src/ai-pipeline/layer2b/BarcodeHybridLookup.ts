import { OpenFoodFactsProvider, RateLimitError as OFFRateLimitError } from '../providers/OpenFoodFactsProvider';
import { UPCitemdbProvider, RateLimitError as UPCRateLimitError } from '../providers/UPCitemdbProvider';
import { BarcodeProduct } from '../providers/OpenFoodFactsProvider';

export interface BarcodeData {
  value: string;
  type: string;
}

export class BarcodeHybridLookup {
  private openFoodFacts: OpenFoodFactsProvider;
  private upcitemdb: UPCitemdbProvider;

  constructor() {
    this.openFoodFacts = new OpenFoodFactsProvider();
    this.upcitemdb = new UPCitemdbProvider();
  }

  async lookup(barcodeData: BarcodeData | null, itemId: string): Promise<BarcodeProduct | null> {
    if (!barcodeData || !barcodeData.value) {
      console.log(`[BarcodeHybrid] No barcode data for item ${itemId}`);
      return null;
    }

    const barcode = barcodeData.value;

    console.log(`[BarcodeHybrid] Starting hybrid lookup for barcode ${barcode} (item ${itemId})`);

    // ✅ I6: Try OpenFoodFacts first with rate limit handling
    try {
      const openFoodResult = await this.openFoodFacts.lookup(barcode);

      if (openFoodResult) {
        console.log(`[BarcodeHybrid] ✅ OpenFoodFacts match for ${barcode}`);
        return openFoodResult;
      }
    } catch (error: any) {
      if (error instanceof OFFRateLimitError) {
        console.warn(`[BarcodeHybrid] OpenFoodFacts rate limited (${error.retryAfter}s), skipping to UPCitemdb`);
        // Continue to UPCitemdb fallback
      } else {
        console.warn(`[BarcodeHybrid] OpenFoodFacts lookup failed for ${barcode}:`, error.message);
      }
    }

    // Step 2: Try UPCitemdb (paid, all products)
    try {
      const upcitemdbResult = await this.upcitemdb.lookup(barcode);

      if (upcitemdbResult) {
        console.log(`[BarcodeHybrid] ✅ UPCitemdb match for ${barcode}`);
        return upcitemdbResult;
      }
    } catch (error: any) {
      console.error(`[BarcodeHybrid] UPCitemdb lookup failed for ${barcode}:`, error.message);
      // Continue to SerpAPI fallback
    }

    // Step 3: Return null to trigger SerpAPI visual search fallback
    console.log(`[BarcodeHybrid] Barcode ${barcode} not found in OpenFoodFacts or UPCitemdb, falling back to SerpAPI`);

    return null; // Null triggers SerpAPI visual search in Layer 2b orchestrator
  }
}
