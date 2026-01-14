/**
 * Barcode Lookup Tool
 *
 * Provides barcode lookup functionality using UPCitemdb API.
 * This is a lightweight tool for the AI pipeline, separate from
 * the full UPCitemdbProvider which includes rate limiting and error classes.
 */

export interface BarcodeResult {
  found: boolean;
  product?: {
    title: string;
    brand?: string;
    model?: string;
    description?: string;
  };
  barcode?: string;
}

interface UPCitemdbItem {
  ean?: string;
  title?: string;
  brand?: string;
  model?: string;
  description?: string;
}

interface UPCitemdbResponse {
  items?: UPCitemdbItem[] | null;
}

/**
 * Look up a barcode using UPCitemdb API.
 *
 * @param code - The barcode (UPC/EAN) to look up
 * @param symbology - Optional barcode symbology (unused, for future extension)
 * @returns BarcodeResult with product info if found, or not found status
 */
export async function lookupBarcode(
  code: string,
  symbology?: string
): Promise<BarcodeResult> {
  try {
    const url = `https://api.upcitemdb.com/prod/trial/lookup?upc=${encodeURIComponent(code)}`;

    const response = await fetch(url, {
      method: 'GET',
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'Abundance-App/1.0'
      }
    });

    if (!response.ok) {
      console.warn(`Barcode lookup failed for ${code}: HTTP ${response.status}`);
      return { found: false, barcode: code };
    }

    const data = await response.json() as UPCitemdbResponse;

    if (data.items && data.items.length > 0) {
      const item = data.items[0];
      return {
        found: true,
        product: {
          title: item.title || 'Unknown Product',
          brand: item.brand || undefined,
          model: item.model || undefined,
          description: item.description || undefined
        }
      };
    }

    return { found: false, barcode: code };

  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    console.warn(`Barcode lookup error for ${code}:`, message);
    return { found: false, barcode: code };
  }
}
