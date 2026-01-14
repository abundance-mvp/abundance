export interface GoogleLensResult {
  exact_matches: boolean;
  products: Array<{
    title: string;
    brand?: string;
    price?: number;
    source: string;
    link: string;
  }>;
}

interface SerpApiVisualMatch {
  position?: number;
  title?: string;
  brand?: string;
  source?: string;
  link?: string;
  price?: {
    extracted_value?: number;
    currency?: string;
  };
  exact_match?: boolean;
}

interface SerpApiResponse {
  visual_matches?: SerpApiVisualMatch[];
}

/**
 * Search Google Lens via SerpAPI for visual product matching.
 *
 * @param imageUrl - Public URL of the image to search
 * @returns GoogleLensResult with exact match status and up to 5 product matches
 * @throws Error if SERPAPI_KEY is not set or API request fails
 */
export async function searchGoogleLens(imageUrl: string): Promise<GoogleLensResult> {
  const apiKey = process.env.SERPAPI_KEY;

  if (!apiKey) {
    throw new Error('SERPAPI_KEY environment variable is required');
  }

  const url = new URL('https://serpapi.com/search');
  url.searchParams.set('engine', 'google_lens');
  url.searchParams.set('url', imageUrl);
  url.searchParams.set('api_key', apiKey);

  const response = await fetch(url.toString(), {
    method: 'GET',
    headers: { 'Accept': 'application/json' }
  });

  if (!response.ok) {
    throw new Error(`SerpAPI request failed: ${response.status} ${response.statusText}`);
  }

  const data = await response.json() as SerpApiResponse;
  const visualMatches = data.visual_matches || [];

  const hasExactMatch = visualMatches.some((m) => m.exact_match === true);

  const products = visualMatches.slice(0, 5).map((match) => ({
    title: match.title || 'Unknown Product',
    brand: extractBrand(match),
    price: match.price?.extracted_value,
    source: match.source || 'Unknown',
    link: match.link || ''
  }));

  return { exact_matches: hasExactMatch, products };
}

/**
 * Extract brand from match data.
 * First checks for explicit brand field, then looks for known brands in title.
 */
function extractBrand(match: SerpApiVisualMatch): string | undefined {
  if (match.brand) return match.brand;

  const title = match.title || '';
  const knownBrands = [
    'Nike', 'Adidas', 'Apple', 'Samsung', 'Sony', 'LG', 'Dell', 'HP',
    'Coleman', 'REI', 'Patagonia', 'North Face', 'IKEA', 'Cuisinart',
    'KitchenAid', 'Dyson', 'Bose', 'JBL', 'Canon', 'Nikon'
  ];

  for (const brand of knownBrands) {
    if (title.toLowerCase().includes(brand.toLowerCase())) {
      return brand;
    }
  }
  return undefined;
}
