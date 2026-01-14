import { GoogleGenAI } from '@google/genai';

export interface WebSearchResult {
  prices: Array<{
    source: string;
    price: number;
    condition?: string;
  }>;
  raw?: string;
}

/**
 * Search the web for product pricing using Google Search Grounding.
 *
 * @param query - Search query for product pricing
 * @returns WebSearchResult with extracted prices from e-commerce sites
 * @throws Error if GOOGLE_API_KEY is not set
 */
export async function searchWeb(query: string): Promise<WebSearchResult> {
  const apiKey = process.env.GOOGLE_API_KEY;

  if (!apiKey) {
    throw new Error('GOOGLE_API_KEY environment variable is required');
  }

  const ai = new GoogleGenAI({ apiKey });

  try {
    const response = await ai.models.generateContent({
      model: 'gemini-3-pro-preview',
      contents: `Find current market prices for: ${query}

Search e-commerce sites (Amazon, eBay, Walmart, Target) and return pricing data.

Return JSON in this exact format:
{
  "prices": [
    { "source": "Amazon", "price": 99.99, "condition": "new" },
    { "source": "eBay", "price": 75.00, "condition": "used" }
  ]
}

Only include prices you found. If no prices found, return {"prices": []}`,
      config: {
        tools: [{ googleSearchRetrieval: {} }],
        temperature: 0.1,
        maxOutputTokens: 512
      }
    });

    const text = response.text || '';

    try {
      const jsonMatch = text.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        const parsed = JSON.parse(jsonMatch[0]);
        return { prices: parsed.prices || [] };
      }
      return { prices: [], raw: text };
    } catch {
      return { prices: [], raw: text };
    }

  } catch (error: any) {
    console.error('Web search error:', error.message);
    return { prices: [] };
  }
}
