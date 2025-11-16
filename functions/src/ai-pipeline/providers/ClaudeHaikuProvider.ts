import Anthropic from '@anthropic-ai/sdk';
import { VisualMatch } from './SerpAPIProvider';

export interface ParsedProduct {
  brand: string;
  model: string;
  variant?: string;
  estimatedValue: number;
  confidence: number;
  reasoning: string;
  tokensUsed: {
    input: number;
    output: number;
    total: number;
  };
  cost: number;
  latency: number;
}

export class ClaudeHaikuProvider {
  private anthropic: Anthropic;

  constructor() {
    const apiKey = process.env.ANTHROPIC_API_KEY;
    if (!apiKey) {
      throw new Error('ANTHROPIC_API_KEY environment variable not set');
    }

    this.anthropic = new Anthropic({ apiKey });
  }

  async parse(visualMatches: VisualMatch[], itemId: string): Promise<ParsedProduct> {
    const prompt = this.buildPrompt(visualMatches);
    const startTime = Date.now();

    try {
      const message = await this.anthropic.messages.create({
        model: 'claude-haiku-4-5-20250815',
        max_tokens: 512,
        temperature: 0.3,
        messages: [{
          role: 'user',
          content: prompt,
        }],
      });

      const latency = Date.now() - startTime;

      // Parse JSON response
      const responseText = message.content[0].type === 'text' ? message.content[0].text : '';
      const jsonMatch = responseText.match(/\{[\s\S]*\}/);

      if (!jsonMatch) {
        throw new Error('Failed to extract JSON from Claude Haiku response');
      }

      const parsed = JSON.parse(jsonMatch[0]);

      // Calculate cost (Haiku 4: $0.80/MTok input, $4.00/MTok output)
      const inputCost = message.usage.input_tokens * (0.80 / 1_000_000);
      const outputCost = message.usage.output_tokens * (4.00 / 1_000_000);
      const totalCost = inputCost + outputCost;

      return {
        brand: parsed.brand || 'Unknown',
        model: parsed.model || 'Unknown',
        variant: parsed.variant || undefined,
        estimatedValue: parsed.estimatedValue || 0,
        confidence: parsed.confidence || 0.5,
        reasoning: parsed.reasoning || '',
        tokensUsed: {
          input: message.usage.input_tokens,
          output: message.usage.output_tokens,
          total: message.usage.input_tokens + message.usage.output_tokens,
        },
        cost: totalCost,
        latency,
      };
    } catch (error: any) {
      console.error(`[ClaudeHaiku] Error parsing for item ${itemId}:`, error.message);
      throw error;
    }
  }

  private buildPrompt(visualMatches: VisualMatch[]): string {
    // ✅ Simplified prompt to reduce token usage (was ~200 tokens, now ~120 tokens)
    const matchesText = visualMatches.slice(0, 5).map((match, idx) => {
      return `${idx + 1}. ${match.title} - $${match.price?.value || 'N/A'}`;
    }).join('\n');

    return `Analyze these visual search results for a household item. Extract:
- Brand name
- Model name
- Variant (if applicable)
- Estimated value (USD, average if multiple prices)
- Confidence (0-1, based on result consistency)

Results:
${matchesText}

Return JSON:
{
  "brand": "string",
  "model": "string",
  "variant": "string or null",
  "estimatedValue": number,
  "confidence": number (0-1),
  "reasoning": "brief explanation"
}`;
  }
}
