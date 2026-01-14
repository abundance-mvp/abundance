import { createVertexAIClient } from '../gemini/vertexai-config';

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
 * @throws Error if Vertex AI is not configured
 */
export async function searchWeb(query: string): Promise<WebSearchResult> {
  // Gemini 3 models require Vertex AI (not API keys)
  const ai = createVertexAIClient();

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
        // Use googleSearch (not legacy googleSearchRetrieval) for Gemini 2.0+ models
        // See: https://cloud.google.com/vertex-ai/generative-ai/docs/grounding/grounding-with-google-search
        tools: [{ googleSearch: {} }],
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
