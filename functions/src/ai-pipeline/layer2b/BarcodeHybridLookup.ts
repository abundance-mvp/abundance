import { OpenFoodFactsProvider, RateLimitError as OFFRateLimitError } from '../providers/OpenFoodFactsProvider';
import { UPCitemdbProvider } from '../providers/UPCitemdbProvider';
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

  private isValidBarcode(barcode: string, type: string): boolean {
    // EAN-13: 13 digits
    if (type === 'EAN-13') return /^\d{13}$/.test(barcode);
    // UPC-A: 12 digits
    if (type === 'UPC-A') return /^\d{12}$/.test(barcode);
    // UPC-E: 8 digits
    if (type === 'UPC-E') return /^\d{8}$/.test(barcode);
    // CODE-128: alphanumeric, 1-48 chars
    if (type === 'CODE-128') return /^[\x20-\x7E]{1,48}$/.test(barcode);
    // Generic fallback: at least 8 characters
    return barcode.length >= 8;
  }

  async lookup(barcodeData: BarcodeData | null, itemId: string): Promise<BarcodeProduct | null> {
    if (!barcodeData || !barcodeData.value) {
      console.log(`[BarcodeHybrid] No barcode data for item ${itemId}`);
      return null;
    }

    const barcode = barcodeData.value;

    // Validate barcode format before making API calls
    if (!this.isValidBarcode(barcode, barcodeData.type)) {
      console.log(`[BarcodeHybrid] Invalid barcode format: ${barcode} (${barcodeData.type})`);
      return null;
    }

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
