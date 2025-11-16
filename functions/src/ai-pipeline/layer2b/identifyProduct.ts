import { BarcodeHybridLookup, BarcodeData } from './BarcodeHybridLookup';
import { SerpAPIProvider } from '../providers/SerpAPIProvider';
import { ClaudeHaikuProvider } from '../providers/ClaudeHaikuProvider';

export interface Layer2bResult {
  source: 'barcode' | 'serpapi';
  barcodeAPI?: string;
  barcode?: string;
  product: {
    name: string;
    brand: string;
    model?: string;
    variant?: string;
    category?: string;
    estimatedValue?: number;
    confidence?: number;
  };
  serpapi?: any;
  claudeParsed?: any;
  costSavings: number;
  latency: number;
}

export async function identifyProduct(
  itemData: { imageUrl: string; barcodeData: BarcodeData | null },
  itemId: string
): Promise<Layer2bResult> {
  const barcodeHybrid = new BarcodeHybridLookup();
  const serpAPI = new SerpAPIProvider();
  const claudeHaiku = new ClaudeHaikuProvider();

  // Decision Tree: Barcode-first strategy
  let layer2bResult: Layer2bResult | null = null;

  // Step 1: Check if barcode detected
  if (itemData.barcodeData && itemData.barcodeData.value) {
    console.log(`[Layer2b] Barcode detected for ${itemId}: ${itemData.barcodeData.value}`);

    // Try barcode hybrid lookup (OpenFoodFacts → UPCitemdb)
    const barcodeResult = await barcodeHybrid.lookup(itemData.barcodeData, itemId);

    if (barcodeResult) {
      // Barcode match found! Skip SerpAPI (cost savings)
      console.log(`[Layer2b] ✅ Barcode match found via ${barcodeResult.source} for ${itemId}`);

      layer2bResult = {
        source: 'barcode',
        barcodeAPI: barcodeResult.source,
        barcode: itemData.barcodeData.value,
        product: {
          name: barcodeResult.name,
          brand: barcodeResult.brand,
          category: barcodeResult.category,
        },
        costSavings: 0.016, // Saved $0.016 by skipping SerpAPI + Claude
        latency: barcodeResult.latency,
      };

      console.log(`[Layer2b] Cost savings: $0.016 (skipped SerpAPI + Claude)`);
      return layer2bResult;
    } else {
      console.log(`[Layer2b] Barcode ${itemData.barcodeData.value} not found, falling back to SerpAPI visual search`);
    }
  } else {
    console.log(`[Layer2b] No barcode detected for ${itemId}, using SerpAPI visual search`);
  }

  // Step 2: Fallback to SerpAPI visual search
  if (!itemData.imageUrl) {
    throw new Error('No image URL found for SerpAPI visual search');
  }

  console.log(`[Layer2b] Calling SerpAPI Google Lens for ${itemId}`);

  // Call SerpAPI with retry
  const serpAPIResponse = await serpAPI.searchWithRetry(itemData.imageUrl, itemId, 3);

  if (!serpAPIResponse.visual_matches || serpAPIResponse.visual_matches.length === 0) {
    throw new Error('No visual matches found in SerpAPI response');
  }

  console.log(`[Layer2b] SerpAPI returned ${serpAPIResponse.visual_matches.length} visual matches`);

  // Step 3: Parse with Claude Haiku
  console.log(`[Layer2b] Parsing SerpAPI results with Claude Haiku for ${itemId}`);

  const parsedProduct = await claudeHaiku.parse(serpAPIResponse.visual_matches, itemId);

  layer2bResult = {
    source: 'serpapi',
    barcode: itemData.barcodeData?.value,
    product: {
      name: `${parsedProduct.brand} ${parsedProduct.model} ${parsedProduct.variant || ''}`.trim(),
      brand: parsedProduct.brand,
      model: parsedProduct.model,
      variant: parsedProduct.variant,
      estimatedValue: parsedProduct.estimatedValue,
      confidence: parsedProduct.confidence,
    },
    serpapi: {
      matchCount: serpAPIResponse.visual_matches.length,
      topMatch: serpAPIResponse.visual_matches[0],
      latency: serpAPIResponse.latency,
    },
    claudeParsed: {
      brand: parsedProduct.brand,
      model: parsedProduct.model,
      variant: parsedProduct.variant,
      estimatedValue: parsedProduct.estimatedValue,
      confidence: parsedProduct.confidence,
      reasoning: parsedProduct.reasoning,
      tokensUsed: parsedProduct.tokensUsed,
      cost: parsedProduct.cost,
      latency: parsedProduct.latency,
    },
    costSavings: 0, // No savings (used SerpAPI + Claude)
    latency: serpAPIResponse.latency + parsedProduct.latency,
  };

  console.log(`[Layer2b] ✅ Visual search complete: ${layer2bResult.product.brand} ${layer2bResult.product.model}`);

  return layer2bResult;
}
